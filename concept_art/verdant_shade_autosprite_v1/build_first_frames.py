"""Convert Shade's approved in-game poses into AutoSprite first frames drawn like Patchvile.

    python concept_art/verdant_shade_autosprite_v1/build_first_frames.py

The poses are the ones the game shows today (owner, 2026-09-25: "the positions are good"), taken
from the approved Codex pack (`concept_art/verdant_shade_sprite_v1/`, deleted 2026-09-25); the five
frames used are kept in `sources/`:

    storefront   idle_hover_00   the front pose the menu video was generated from
    wall_bottom  wall_bottom_00  the floor crouch
    wall_right   wall_left_00    mirrored: the recipe generates the right wall and derives the left
    dash_attack  dash_loop_01    the dive, drawn face down (the slicer turns the sheet 180 degrees)
    wall_top     wall_top_00     OPTIONAL - today's own ceiling pose, only if the owner wants a fifth
                                 sheet instead of the floor flipped (the recipe's default)

Each becomes a first frame on Patchvile's rules (owner, 2026-09-25: "keep it like patchvile";
docs/guides/character_creation.md §3): the art at AutoSprite's 256 x 256 frame resolution,
delivered 4x nearest at 1024; **no outline**; up to 256 colours with soft edges, as AutoSprite's own
paletted export draws him; and the roster size - standing, Shade is 194 px from the flame-horn tips
to the tail tip in the 256 frame (every visible pixel, as the packer's ROSTER CHECK measures), and
every pose uses that one scale. Two source defects are repaired on the way: the floor frame carries
slivers of a neighbouring atlas cell above its head, and the wall frame carries one at the top and
has its tail cut flat by the canvas bottom, so the tail is finished to a point.

Only files inside this folder are written.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import distance_transform_edt, label

HERE = Path(__file__).resolve().parent
FRAMES = HERE / "sources"
## name: (source frame, mirror it, drop source components lying entirely above this row)
SOURCES = {
	"storefront": ("idle_hover_00.png", False, 0),
	"wall_bottom": ("wall_bottom_00.png", False, 110),
	"wall_right": ("wall_left_00.png", True, 40),
	"dash_attack": ("dash_loop_01.png", False, 0),
	"wall_top": ("wall_top_00.png", False, 0),
}
REQUIRED = ["storefront", "wall_bottom", "wall_right", "dash_attack"]
OPTIONAL = ["wall_top"]
NATIVE_SIZE = 256
DELIVERY_SIZE = 1024
## Patchvile's pixel count: standing, 194 px of the 256 px frame.
ROSTER_STANDING = 194
MIN_MARGIN = 15
## AutoSprite exports a paletted PNG: 256 entries, transparency levels included.
COLOURS = 256
## Coverage below this after reduction is dust from the painted glow, not art. Patchvile's
## faintest pixel is alpha 2.
FAINT = 3
## Source components smaller than this (source px) are specks, not art.
MIN_SOURCE_COMPONENT = 30
## How far (source px) the painted glow reaches past the art it belongs to.
GLOW_REACH = 12
## Separate pieces smaller than this (source px, glow included) are dust. The smallest real piece,
## a floating leaf, is several hundred.
DUST = 60
## How far a finished tail tip hooks, in native px per step squared (see `taper_cut_bottom`).
TAIL_HOOK = 0.12


def _runs(row: np.ndarray) -> list[tuple[int, int]]:
	"""Contiguous (first, last) column runs of a mask row."""
	runs: list[tuple[int, int]] = []
	for x in np.where(row)[0]:
		if runs and x == runs[-1][1] + 1:
			runs[-1] = (runs[-1][0], x)
		else:
			runs.append((x, x))
	return runs


def keep_only(pixels: np.ndarray, kept: np.ndarray) -> None:
	"""Clears every drawn part not in `kept`, together with its soft glow.

	`kept` marks the solid art (alpha > 40) that stays. A faint glow pixel belongs to whichever art
	is nearest, so a dropped sliver takes its glow with it, and glow further than GLOW_REACH from
	anything kept is dust.
	"""
	dropped = (pixels[:, :, 3] > 40) & ~kept
	near_kept = distance_transform_edt(~kept)
	near_dropped = distance_transform_edt(~dropped) if dropped.any() else np.full(kept.shape, np.inf)
	pixels[~kept & ((near_kept > GLOW_REACH) | (near_dropped < near_kept))] = 0


def taper_cut_bottom(pixels: np.ndarray, scale: float) -> np.ndarray:
	"""Finish a flame tail cut flat by the source canvas bottom into a hooked point.

	Works on the painted source, so the tip keeps the painting's soft edges when it is reduced.
	The widest run on the cut row is the tail; other strands the cut caught are dropped. The tail
	is ended a few rows above the cut (the last rows flare where the canvas clipped them) and
	continued as a narrowing tip that keeps its drift and hooks a little further the same way, like
	the other flame tips. Each new row reuses the tail's pixels squeezed to the narrower width, so
	the bright core stays in the middle and the glow at its edges.
	"""
	solid = pixels[:, :, 3] >= 128
	last = int(np.where(solid.any(axis=1))[0].max())
	tail = max(_runs(solid[last]), key=lambda run: run[1] - run[0])
	components, _count = label(pixels[:, :, 3] > 40)
	keep = components[last, tail[0]]
	kept = components > 0
	step_rows = max(1, int(round(1.0 / scale)))
	# Fragments of the other strands the canvas cut: anything but the tail that lives only in the
	# bottom few rows of the art.
	bottom = last - 30 * step_rows
	for index in np.unique(components[bottom : last + 1]):
		if index and index != keep and np.where(components == index)[0].min() >= bottom:
			kept &= components != index
	keep_only(pixels, kept)
	start = last - 3 * step_rows
	base = max(_runs(solid[start]), key=lambda run: run[1] - run[0])
	previous = max(_runs(solid[start - 6 * step_rows]), key=lambda run: run[1] - run[0])
	width = base[1] - base[0] + 1
	centre = (base[0] + base[1]) / 2.0
	drift = (centre - (previous[0] + previous[1]) / 2.0) / (6.0 * step_rows)
	hook = (TAIL_HOOK if drift >= 0 else -TAIL_HOOK) * scale
	# The tail plus a thin soft edge: a wider band would drag the glow of the cut rows sideways.
	halo = int(round(1.5 / scale))
	# Near the cut the painting's glow smears sideways off the clipped edge; faint pixels there that
	# are not hugging solid art are that smear, not glow.
	zone = slice(start - 12 * step_rows, start + 1)
	far = distance_transform_edt(pixels[:, :, 3] < 128)[zone] > halo
	pixels[zone][far & (pixels[zone][:, :, 3] < 128)] = 0
	source_row = pixels[start, max(0, base[0] - halo) : base[1] + halo + 1].copy()
	length = max(3, int(round(width * 1.1)))
	grown = np.zeros((pixels.shape[0] + length + 4, pixels.shape[1], 4), dtype=np.uint8)
	grown[: start + 1] = pixels[: start + 1]
	# The rows below the cut-off point, beside the tail too, are replaced by the tip.
	for step in range(1, length + 1):
		t = step / float(length)
		w = max(1, int(round(len(source_row) * (1.0 - t) ** 1.15)))
		centre += drift + hook * step
		x0 = int(round(centre - (w - 1) / 2.0))
		pick = np.linspace(0, len(source_row) - 1, w).round().astype(int)
		grown[start + step, max(0, x0) : x0 + w] = source_row[pick][max(0, -x0) :]
	return grown


def load_source(name: str, scale: float) -> Image.Image:
	"""The source frame, mirrored if asked, with atlas slivers and specks removed and a cut tail
	finished."""
	file, mirror, stray_above = SOURCES[name]
	image = Image.open(FRAMES / file).convert("RGBA")
	if mirror:
		image = image.transpose(Image.FLIP_LEFT_RIGHT)
	pixels = np.array(image)
	components, count = label(pixels[:, :, 3] > 40)
	kept = np.zeros(components.shape, dtype=bool)
	for index in range(1, count + 1):
		ys, _xs = np.where(components == index)
		if len(ys) >= MIN_SOURCE_COMPONENT and ys.max() >= stray_above:
			kept |= components == index
	keep_only(pixels, kept)
	if pixels[-1, :, 3].max() >= 128:
		pixels = taper_cut_bottom(pixels, scale)
	# Last, isolated dust: any separate piece too small to be a leaf or a flame wisp.
	pieces, count = label(pixels[:, :, 3] > 0, structure=np.ones((3, 3), dtype=bool))
	sizes = np.bincount(pieces.ravel())
	pixels[(pieces > 0) & (sizes[pieces] < DUST)] = 0
	return Image.fromarray(pixels, "RGBA")


def reduce(source: Image.Image, scale: float) -> np.ndarray:
	"""Area-reduces the art by `scale`, drops glow dust and quantizes it the way AutoSprite exports."""
	box = source.getchannel("A").getbbox()
	cropped = source.crop(box)
	size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
	arr = np.asarray(cropped, dtype=np.float32)
	premult = np.rint(arr[:, :, :3] * (arr[:, :, 3:4] / 255)).astype(np.uint8)
	colour = np.asarray(Image.fromarray(premult, "RGB").resize(size, Image.Resampling.BOX), dtype=np.float32)
	alpha = np.asarray(Image.fromarray(arr[:, :, 3].astype(np.uint8), "L").resize(size, Image.Resampling.BOX))
	straight = np.clip(np.rint(colour / np.maximum(alpha[:, :, None] / 255.0, 1 / 255.0)), 0, 255)
	small = np.dstack([straight.astype(np.uint8), alpha])
	small[small[:, :, 3] < FAINT] = 0
	pieces, _count = label(small[:, :, 3] > 0, structure=np.ones((3, 3), dtype=bool))
	small[(pieces > 0) & (np.bincount(pieces.ravel())[pieces] < 3)] = 0
	quantized = Image.fromarray(small, "RGBA").quantize(
		colors=COLOURS, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
	result = np.array(quantized)
	result[result[:, :, 3] == 0] = 0
	return result


def place(name: str, art: np.ndarray) -> tuple[np.ndarray, list[int], list[int]]:
	"""Centres the art on the 256 canvas and checks the margins."""
	ys, xs = np.where(art[:, :, 3] > 0)
	art = art[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]
	if max(art.shape[:2]) > NATIVE_SIZE - 2 * MIN_MARGIN:
		raise SystemExit(f"{name}: {art.shape[1]}x{art.shape[0]} breaks the {MIN_MARGIN} px margin")
	canvas = np.zeros((NATIVE_SIZE, NATIVE_SIZE, 4), dtype=np.uint8)
	x0 = (NATIVE_SIZE - art.shape[1]) // 2
	y0 = (NATIVE_SIZE - art.shape[0]) // 2
	canvas[y0 : y0 + art.shape[0], x0 : x0 + art.shape[1]] = art
	bounds = [x0, y0, x0 + art.shape[1], y0 + art.shape[0]]
	margin = [bounds[0], bounds[1], NATIVE_SIZE - bounds[2], NATIVE_SIZE - bounds[3]]
	return canvas, bounds, margin


def roster_scale(first_guess: float) -> float:
	"""The source-to-frame scale at which the storefront stands exactly ROSTER_STANDING px."""
	best = first_guess
	for step in range(-40, 41):
		scale = first_guess * (1.0 + step * 0.0015)
		art = reduce(load_source("storefront", scale), scale)
		ys = np.where(art[:, :, 3].any(axis=1))[0]
		if ys.max() - ys.min() + 1 == ROSTER_STANDING:
			return scale
		if abs(ys.max() - ys.min() + 1 - ROSTER_STANDING) < 1:
			best = scale
	return best


def make_review(frames: dict[str, Image.Image]) -> None:
	order = REQUIRED + OPTIONAL
	review = Image.new("RGBA", (len(order) * 1024, 1024 + 256 + 88), (40, 43, 55, 255))
	draw = ImageDraw.Draw(review)
	font = ImageFont.load_default()
	for col, name in enumerate(order):
		review.alpha_composite(frames[name].resize((1024, 1024), Image.Resampling.NEAREST), (col * 1024, 0))
		review.alpha_composite(frames[name], (col * 1024 + 384, 1024 + 28))
		label_text = name + ("  (optional)" if name in OPTIONAL else "")
		draw.text((col * 1024 + 16, 1024 + 8), label_text, fill="white", font=font)
		draw.text((col * 1024 + 384, 1024 + 256 + 38), "native 256 px", fill="white", font=font)
	review.convert("RGB").save(HERE / "review_first_frames.png")


def main() -> None:
	plain = Image.open(FRAMES / SOURCES["storefront"][0]).convert("RGBA").getchannel("A").getbbox()
	scale = roster_scale(ROSTER_STANDING / float(plain[3] - plain[1]))
	frames: dict[str, Image.Image] = {}
	report: dict[str, dict] = {}
	for name in SOURCES:
		canvas, bounds, margin = place(name, reduce(load_source(name, scale), scale))
		assert min(margin) >= MIN_MARGIN, (name, margin)
		frames[name] = Image.fromarray(canvas, "RGBA")
		visible = canvas[canvas[:, :, 3] > 0]
		file, mirror, _ = SOURCES[name]
		report[name] = {
			"source": "sources/" + file,
			"mirrored": mirror,
			"alpha_bounds_native": bounds,
			"height_native": bounds[3] - bounds[1],
			"edge_margins_native": margin,
			"alpha_bounds_delivered": [n * 4 for n in bounds],
			"colours": int(len(np.unique(visible.reshape(-1, 4), axis=0))),
			"alpha_levels": int(len(np.unique(visible[:, 3]))),
		}
		out = ("optional_" if name in OPTIONAL else "") + name + "_first_frame.png"
		frames[name].resize((DELIVERY_SIZE, DELIVERY_SIZE), Image.Resampling.NEAREST).save(HERE / out)
		print("%-12s -> %-38s height %3d px, margins %s, %d colours, %d alpha levels" % (
			name, out, report[name]["height_native"], margin, report[name]["colours"],
			report[name]["alpha_levels"]))
	make_review(frames)
	(HERE / "first_frames_metadata.json").write_text(json.dumps({
		"rules": "Patchvile's: 256 px frame resolution delivered 4x nearest, no outline, up to 256 colours "
				 "with soft edges (AutoSprite's paletted export), 194 px standing",
		"scale_source_to_native": scale,
		"standing_native": report["storefront"]["height_native"],
		"frames": report,
	}, indent=2) + "\n")


if __name__ == "__main__":
	main()
