"""Check the owner's Codex images of Rook against the first-frame rules and deliver them as the first frames.

    python concept_art/rook_autosprite_v1/build_first_frames.py

The five sources (owner, 2026-09-27; the owner's `Desktop/Rook/Codex Generated/`) are kept unchanged
in `sources/`:

    storefront   storefront.png    front view, sitting, wings folded round him
    wall_bottom  wall_bottom.png   the floor crouch
    wall_right   wall_right.png    clinging to a wall on his right
    wall_top     wall_top.png      hanging from the ceiling like a bat (his own ceiling, owner)
    dash_attack  dash_attack.png   the side-on flight, flying left

Unlike Mothmere's and Scarlet's, these already meet every rule of the recipe
(docs/guides/character_creation.md §3): 1024 x 1024, transparent, exact 4 x 4 blocks of a 256 px
art grid, at most 256 colours, at least 60 px (15 art px) of margin, and the storefront standing
exactly 776 px (194 art px, the roster size). So nothing is converted: each is checked and copied
byte for byte as `<state>_first_frame.png`. They carry a dark outline around the bone; the owner
chose to keep it (2026-09-27), as for Mothmere. Rook gets his own ceiling animation instead of the
floor flipped (owner, 2026-09-27), so there are five first frames.

Only files inside this folder are written.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
SOURCES = HERE / "sources"
NAMES = ["storefront", "wall_bottom", "wall_right", "wall_top", "dash_attack"]
DELIVERY_SIZE = 1024
BLOCK = 4
## The roster size: standing, 194 art px, 776 px on the 1024 first frame (every visible pixel).
STANDING = 776
MIN_MARGIN = 60
COLOURS = 256


def check(name: str) -> dict:
	"""Measures one source against the rules; stops on the first rule it breaks."""
	image = Image.open(SOURCES / f"{name}.png")
	pixels = np.array(image.convert("RGBA"))
	if image.size != (DELIVERY_SIZE, DELIVERY_SIZE):
		raise SystemExit(f"{name}: {image.size}, expected {DELIVERY_SIZE}²")
	small = pixels[::BLOCK, ::BLOCK]
	if not np.array_equal(np.repeat(np.repeat(small, BLOCK, 0), BLOCK, 1), pixels):
		raise SystemExit(f"{name}: not exact {BLOCK} x {BLOCK} blocks")
	visible = pixels[pixels[:, :, 3] > 0]
	colours = int(len(np.unique(visible.reshape(-1, 4), axis=0)))
	if colours > COLOURS:
		raise SystemExit(f"{name}: {colours} colours, the limit is {COLOURS}")
	if pixels[0, 0, 3] != 0:
		raise SystemExit(f"{name}: the background is not transparent")
	ys, xs = np.nonzero(pixels[:, :, 3] > 0)
	bounds = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
	margins = [bounds[0], bounds[1], DELIVERY_SIZE - bounds[2], DELIVERY_SIZE - bounds[3]]
	if min(margins) < MIN_MARGIN:
		raise SystemExit(f"{name}: margins {margins}, the minimum is {MIN_MARGIN}")
	height = bounds[3] - bounds[1]
	if name == "storefront" and height != STANDING:
		raise SystemExit(f"{name}: stands {height} px, the roster size is {STANDING}")
	return {
		"source": f"sources/{name}.png",
		"alpha_bounds_delivered": bounds,
		"height_delivered": height,
		"width_delivered": bounds[2] - bounds[0],
		"edge_margins_delivered": margins,
		"colours": colours,
		"alpha_levels": int(len(np.unique(visible[:, 3]))),
	}


def make_review(names: list[str]) -> None:
	review = Image.new("RGBA", (len(names) * 1024, 1024 + 40), (40, 43, 55, 255))
	draw = ImageDraw.Draw(review)
	font = ImageFont.load_default()
	for col, name in enumerate(names):
		review.alpha_composite(Image.open(HERE / f"{name}_first_frame.png").convert("RGBA"), (col * 1024, 40))
		draw.text((col * 1024 + 16, 12), name, fill="white", font=font)
	review.convert("RGB").save(HERE / "review_first_frames.png")


def main() -> None:
	report = {}
	for name in NAMES:
		report[name] = check(name)
		shutil.copyfile(SOURCES / f"{name}.png", HERE / f"{name}_first_frame.png")
		r = report[name]
		print("%-12s -> %-30s %3d x %3d px, margins %s, %d colours" % (
			name, f"{name}_first_frame.png", r["width_delivered"], r["height_delivered"],
			r["edge_margins_delivered"], r["colours"]))
	make_review(NAMES)
	(HERE / "first_frames_metadata.json").write_text(json.dumps({
		"rules": "The recipe's: 1024 px, exact 4x4 blocks of a 256 px art grid, up to 256 colours, "
				 "transparent, 60 px margins, 776 px standing (the roster size); copied unchanged. The "
				 "outline the sources carry is kept and the ceiling is his own (owner, 2026-09-27)",
		"standing_delivered": report["storefront"]["height_delivered"],
		"frames": report,
	}, indent=2) + "\n")


if __name__ == "__main__":
	main()
