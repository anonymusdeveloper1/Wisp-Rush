"""Convert the owner's Codex images of Scarlet into AutoSprite first frames at her own height.

    python concept_art/scarlet_autosprite_v1/build_first_frames.py

The four sources (owner, 2026-09-26) are kept unchanged in `sources/`:

    storefront   storefront.png    front view, standing
    wall_bottom  wall_bottom.png   the floor crouch
    wall_right   wall_right.png    clinging to a wall on her right
    dash_attack  dash_attack.png   the side-on flight, flying left

They are 1254 px images whose pixels are not on a clean grid. Each becomes a first frame on the
recipe's rules (docs/guides/character_creation.md §3): the art at AutoSprite's 256 x 256 frame
resolution, delivered 4x nearest at 1024, which is Patchvile's pixel size; up to 256 colours with
soft edges, as AutoSprite's own paletted export draws a frame; no outline (the sources have none:
their edge pixels are as bright as the inside). Her height is her own (owner, 2026-09-26): standing,
she is 166 px from the top of her fan to her feet in the 256 frame, every visible pixel counted, as
the packer's ROSTER CHECK measures.

Codex drew the four poses at different scales, so each pose is scaled so her head matches the
storefront's (owner, 2026-09-26): the pose keeps its own height (a crouch is shorter than standing),
only her size is matched. The fan then differs in size between poses; the owner accepted that.
Two background-remover leftovers are cleaned, as for Mothmere: the faint haze around the figure,
and the body's alpha of 253 instead of solid.

Only files inside this folder are written.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import distance_transform_edt, label

HERE = Path(__file__).resolve().parent
SOURCES = HERE / "sources"
NAMES = ["storefront", "wall_bottom", "wall_right", "dash_attack"]
NATIVE_SIZE = 256
DELIVERY_SIZE = 1024
## Scarlet's height (owner, 2026-09-26): standing, 166 px of the 256 px frame, fan top to feet.
STANDING = 166
## Each pose's size against the storefront, so her head is the same size in every pose. Measured on
## the sources (px): the crown's middle diamond is 106 tall on the storefront and the floor, 86 on
## the right wall and 77 in the dash; on the right wall its width (46 vs 58), the eye spacing (47 vs
## 55) and an eye's width (31 vs 37) agree (0.82 on average); in the dash the earrings measure 0.72.
POSE_SCALE = {"storefront": 1.0, "wall_bottom": 1.0, "wall_right": 1.0 / 0.8225, "dash_attack": 1.0 / 0.725}
MIN_MARGIN = 15
## AutoSprite exports a paletted PNG: 256 entries, transparency levels included.
COLOURS = 256
## Source alpha at or above this is the body (the background remover left it at 253): made solid.
SOLID = 240
## Source alpha at or above this is drawn art; everything fainter is edge softness or haze.
ART = 40
## Drawn pieces smaller than this (source px) are specks, not art.
MIN_PIECE = 30
## How far (source px) edge softness reaches past the art it belongs to; fainter pixels further out
## are the background remover's haze.
EDGE_REACH = 6
## Coverage below this after reduction is haze, not art. Patchvile's faintest pixel is alpha 2.
FAINT = 3


def load_source(name: str) -> Image.Image:
	"""The source image with its haze cleared and its body made solid."""
	pixels = np.array(Image.open(SOURCES / f"{name}.png").convert("RGBA"))
	alpha = pixels[:, :, 3]
	pieces, count = label(alpha >= ART, structure=np.ones((3, 3), dtype=bool))
	sizes = np.bincount(pieces.ravel())
	art = (pieces > 0) & (sizes[pieces] >= MIN_PIECE)
	pixels[~art & (distance_transform_edt(~art) > EDGE_REACH)] = 0
	pixels[:, :, 3][pixels[:, :, 3] >= SOLID] = 255
	return Image.fromarray(pixels, "RGBA")


def reduce(source: Image.Image, scale: float) -> np.ndarray:
	"""Area-reduces the art by `scale`, drops haze and quantizes it the way AutoSprite exports."""
	cropped = source.crop(source.getchannel("A").getbbox())
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
	# The octree averages alpha inside a colour cluster, leaving the body at 254; Patchvile's
	# AutoSprite frames draw it solid.
	result[:, :, 3][result[:, :, 3] >= SOLID] = 255
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


def standing_scale(storefront: Image.Image) -> float:
	"""The source-to-frame scale at which the storefront stands exactly STANDING px."""
	box = storefront.getchannel("A").getbbox()
	first_guess = STANDING / float(box[3] - box[1])
	best, best_error = first_guess, float("inf")
	for step in range(-40, 41):
		scale = first_guess * (1.0 + step * 0.0015)
		art = reduce(storefront, scale)
		ys = np.where(art[:, :, 3].any(axis=1))[0]
		error = abs(ys.max() - ys.min() + 1 - STANDING)
		if error < best_error:
			best, best_error = scale, error
		if error == 0:
			break
	return best


def make_review(frames: dict[str, Image.Image]) -> None:
	review = Image.new("RGBA", (len(NAMES) * 1024, 1024 + 256 + 88), (40, 43, 55, 255))
	draw = ImageDraw.Draw(review)
	font = ImageFont.load_default()
	for col, name in enumerate(NAMES):
		review.alpha_composite(frames[name].resize((1024, 1024), Image.Resampling.NEAREST), (col * 1024, 0))
		review.alpha_composite(frames[name], (col * 1024 + 384, 1024 + 28))
		draw.text((col * 1024 + 16, 1024 + 8), name, fill="white", font=font)
		draw.text((col * 1024 + 384, 1024 + 256 + 38), "native 256 px", fill="white", font=font)
	review.convert("RGB").save(HERE / "review_first_frames.png")


def main() -> None:
	sources = {name: load_source(name) for name in NAMES}
	scale = standing_scale(sources["storefront"])
	frames: dict[str, Image.Image] = {}
	report: dict[str, dict] = {}
	for name in NAMES:
		canvas, bounds, margin = place(name, reduce(sources[name], scale * POSE_SCALE[name]))
		frames[name] = Image.fromarray(canvas, "RGBA")
		visible = canvas[canvas[:, :, 3] > 0]
		report[name] = {
			"source": f"sources/{name}.png",
			"pose_scale": POSE_SCALE[name],
			"alpha_bounds_native": bounds,
			"height_native": bounds[3] - bounds[1],
			"width_native": bounds[2] - bounds[0],
			"edge_margins_native": margin,
			"alpha_bounds_delivered": [n * 4 for n in bounds],
			"colours": int(len(np.unique(visible.reshape(-1, 4), axis=0))),
			"alpha_levels": int(len(np.unique(visible[:, 3]))),
		}
		out = f"{name}_first_frame.png"
		frames[name].resize((DELIVERY_SIZE, DELIVERY_SIZE), Image.Resampling.NEAREST).save(HERE / out)
		print("%-12s -> %-30s %3d x %3d px, margins %s, %d colours, %d alpha levels" % (
			name, out, report[name]["width_native"], report[name]["height_native"], margin,
			report[name]["colours"], report[name]["alpha_levels"]))
	make_review(frames)
	(HERE / "first_frames_metadata.json").write_text(json.dumps({
		"rules": "The recipe's: 256 px frame resolution delivered 4x nearest (Patchvile's pixel size), "
				 "up to 256 colours with soft edges (AutoSprite's paletted export), no outline; her own "
				 "height, 166 px standing, and each pose scaled so her head matches the storefront's "
				 "(owner, 2026-09-26)",
		"scale_source_to_native": scale,
		"standing_native": report["storefront"]["height_native"],
		"frames": report,
	}, indent=2) + "\n")


if __name__ == "__main__":
	main()
