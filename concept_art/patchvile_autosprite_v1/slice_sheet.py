"""Slice AutoSprite's Patchvile sheets into the numbered frames the packer reads.

    python concept_art/patchvile_autosprite_v1/slice_sheet.py

Every sheet in `raw/` is AutoSprite's export, unchanged: a 5 x 5 grid of 256 px cells, read left
to right, top to bottom, with a transparent background. Each kept cell becomes
`<folder>/<state>_NN.png` with the colour under alpha 0 zeroed. Nothing is moved or rescaled here -
the cells are already registered (the feet sit on one row in every cell of a sheet) - and
`tools/art/extract_playable_characters.py` does the one fit and resample onto the game's sheets.

The wall sheets end on a near-copy of their first cell, so their 25th cell is dropped and the loop
is 24 frames; the storefront ends on a deliberate still hold and keeps all 25. The dash is a one-shot
attack (owner, 2026-09-24): the sheet flies left in one pose from the first cell to the sixth, winds
the dagger up and back (06-08), slashes with a painted flash (09, the contact frame), throws the arc
and its streaks (10-11) and holds the follow-through from 12. Eight cells are kept - the flight pose,
the windup, the slash, arc, streaks and the first held follow-through - and each is turned a quarter
clockwise so the flight, drawn to the left, points up: the rig turns a dash frame by the flight
angle plus 90 degrees, which lines its up axis with the flight. (The first dash sheet, which
launched from the right-wall pose, was deleted on 2026-09-25.) `wall_top` and
`wall_left` are not sliced: the packer flips `wall_bottom` and `wall_right` for them. The storefront's
first cell is also written as `idle_hover_00.png`, the portrait.
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
COLUMNS = 5
ROWS = 5
CELL = 256
## state: (raw sheet, output folder, cells kept in order, degrees to turn each - PIL, anticlockwise)
SHEETS = {
	"storefront_idle": ("raw/storefront_idle_sheet.png", "frames/storefront", list(range(25)), 0),
	"wall_bottom": ("raw/wall_bottom_sheet.png", "frames", list(range(24)), 0),
	"wall_right": ("raw/wall_right_sheet.png", "frames", list(range(24)), 0),
	"dash_loop": ("raw/dash_attack_sheet.png", "frames", [5, 6, 7, 8, 9, 10, 11, 12], -90),
}


def _step(a: np.ndarray, b: np.ndarray) -> float:
	"""Mean colour change between two frames, weighted by alpha."""
	fa = a[:, :, :3] * (a[:, :, 3:] / 255.0)
	fb = b[:, :, :3] * (b[:, :, 3:] / 255.0)
	return float(np.abs(fa - fb).mean())


def slice_sheet(state: str, sheet_path: str, folder: str, cells: list, turn: int) -> None:
	sheet = Image.open(ROOT / sheet_path).convert("RGBA")
	if sheet.size != (COLUMNS * CELL, ROWS * CELL):
		raise SystemExit("%s is %s, expected %dx%d" % (
			sheet_path, sheet.size, COLUMNS * CELL, ROWS * CELL))
	out = ROOT / folder
	out.mkdir(parents=True, exist_ok=True)
	frames = []
	for number, index in enumerate(cells):
		row, column = divmod(index, COLUMNS)
		frame = sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))
		if turn:
			frame = frame.rotate(turn)
		pixels = np.array(frame)
		if pixels[:, :, 3].max() == 0:
			raise SystemExit("%s cell %d is empty" % (state, index))
		pixels[pixels[:, :, 3] == 0, :3] = 0
		Image.fromarray(pixels, "RGBA").save(out / ("%s_%02d.png" % (state, number)), optimize=True)
		frames.append(pixels.astype(float))
	steps = [_step(frames[i], frames[i + 1]) for i in range(len(frames) - 1)]
	print("SLICED: %-16s %2d frames -> %s  (step mean %.2f, max %.2f; seam back to 00: %.2f)" % (
		state, len(cells), out.relative_to(ROOT), float(np.mean(steps)), max(steps),
		_step(frames[-1], frames[0])))


def main() -> None:
	for state, (sheet_path, folder, cells, turn) in SHEETS.items():
		slice_sheet(state, sheet_path, folder, cells, turn)
	portrait = ROOT / "frames/storefront/storefront_idle_00.png"
	Image.open(portrait).save(ROOT / "frames/idle_hover_00.png", optimize=True)


if __name__ == "__main__":
	main()
