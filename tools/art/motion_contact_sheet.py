#!/usr/bin/env python3
"""Tile frames of `render_character_motion.tscn` into contact sheets cropped around the player.

Reads `logs/motion/<id>/frame*.png` (MovieWriter output) and `logs/motion/<id>/motion.log` (the
fixture's `[Motion]` lines) and writes `logs/motion/<id>_<first>-<last>.png` sheets for review.

    python3 tools/art/motion_contact_sheet.py rook                 # default frame windows
    python3 tools/art/motion_contact_sheet.py rook 100-140 1       # frames 100..140, every frame
"""
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[2]
CROP = 300
COLUMNS = 8
WINDOWS = [(36, 90, 2), (106, 140, 1), (156, 236, 2), (238, 296, 2), (298, 368, 3), (366, 440, 2)]
LINE = re.compile(r"\[Motion\] frame=(\d+) pos=([-\d.]+),([-\d.]+) state=(\w+) visual=(\S+) heading=([-\d.]+)")


def load_track(folder: Path) -> dict:
	track = {}
	for line in (folder / "motion.log").read_text().splitlines():
		match = LINE.search(line)
		if match:
			track[int(match.group(1))] = (
				float(match.group(2)), float(match.group(3)), match.group(4), match.group(5),
			)
	return track


def sheet(name: str, first: int, last: int, step: int) -> Path:
	folder = REPO / "logs/motion" / name
	frames = sorted(folder.glob("frame*.png"))
	track = load_track(folder)
	picks = [n for n in range(first, last + 1, step) if n - 1 < len(frames) and n in track]
	rows = (len(picks) + COLUMNS - 1) // COLUMNS
	canvas = Image.new("RGB", (COLUMNS * CROP, rows * (CROP + 18)), (0, 0, 0))
	draw = ImageDraw.Draw(canvas)
	for index, number in enumerate(picks):
		# MovieWriter numbers files from 0 while the fixture counts physics frames from 1.
		image = Image.open(frames[number - 1]).convert("RGB")
		scale = image.width / 1080.0
		x, y, state, visual = track[number]
		box = (
			int(x * scale - CROP / 2), int(y * scale - CROP / 2),
			int(x * scale + CROP / 2), int(y * scale + CROP / 2),
		)
		row, column = divmod(index, COLUMNS)
		canvas.paste(image.crop(box), (column * CROP, row * (CROP + 18) + 18))
		draw.text((column * CROP + 4, row * (CROP + 18) + 3), "%d %s %s" % (number, state[:6], visual), fill=(255, 230, 90))
	out = REPO / "logs/motion" / ("%s_%03d-%03d.png" % (name, first, last))
	canvas.save(out)
	return out


def main() -> None:
	name = sys.argv[1] if len(sys.argv) > 1 else "veyra"
	windows = WINDOWS
	if len(sys.argv) > 2:
		first, last = (int(part) for part in sys.argv[2].split("-"))
		windows = [(first, last, int(sys.argv[3]) if len(sys.argv) > 3 else 1)]
	for first, last, step in windows:
		print(sheet(name, first, last, step))


if __name__ == "__main__":
	main()
