"""Slice AutoSprite's Mothmere sheets into the numbered frames the packer reads.

    python concept_art/mothmere_autosprite_v1/slice_sheet.py

Every sheet in `raw/` is the owner's AutoSprite PNG export, unchanged (2026-09-25; the owner's
`sheet/` folder: storefront_idle, floor, right_side, dash_attack): 256 px cells, five to a row, read
left to right, top to bottom, transparent. Each kept cell becomes
`<folder>/<state>_NN.png` with the colour under alpha 0 zeroed. Nothing is moved or rescaled here;
`tools/art/extract_playable_characters.py` packs them at Patchvile's scale.

Which cells, and why:
- **Storefront:** all 22 filled cells. The last is one ordinary step from the first (0.61, against
  0.35-0.61 between the calm cells around it), so the loop closes without a repeat.
- **Floor:** all 18 filled cells of its 4-row sheet (its seam, 0.98, is an ordinary step).
- **Right wall:** all 23 filled cells (its seam, 0.53, is an ordinary step).
- **Dash:** a one-shot attack (owner, 2026-09-25: "one hit ... he swings the weapon and a red reap
  appears"), eight cells: the flight pose (07), the wind-up (08, 09), the swing starting (11), the
  full red reap over the top (12, the contact frame), the reap sweeping round and thinning (13, 15)
  and the end of the swing (19), which holds until the wall. The sheet flies to the left, so each
  cell is turned a quarter clockwise and the flight points up, as Patchvile's is: the rig turns a
  dash frame by the flight angle plus 90 degrees, which lines its up axis with the flight.

`wall_top` and `wall_left` are not sliced: the packer flips `wall_bottom` and mirrors `wall_right`
for them. The storefront's first cell is also written as `idle_hover_00.png`, the portrait.
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
COLUMNS = 5
CELL = 256
## state: (raw sheet, output folder, cells kept in order, degrees to turn each - PIL, anticlockwise)
SHEETS = {
	"storefront_idle": ("raw/storefront_idle_sheet.png", "frames/storefront", list(range(22)), 0),
	"wall_bottom": ("raw/wall_bottom_sheet.png", "frames", list(range(18)), 0),
	"wall_right": ("raw/wall_right_sheet.png", "frames", list(range(23)), 0),
	"dash_loop": ("raw/dash_attack_sheet.png", "frames", [7, 8, 9, 11, 12, 13, 15, 19], -90),
}


def _cell(sheet: Image.Image, index: int) -> Image.Image:
	row, column = divmod(index, COLUMNS)
	return sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))


def _step(a: np.ndarray, b: np.ndarray) -> float:
	"""Mean colour change between two frames, weighted by alpha."""
	fa = a[:, :, :3] * (a[:, :, 3:] / 255.0)
	fb = b[:, :, :3] * (b[:, :, 3:] / 255.0)
	return float(np.abs(fa - fb).mean())


def slice_sheet(state: str, sheet_path: str, folder: str, cells: list, turn: int) -> None:
	sheet = Image.open(ROOT / sheet_path).convert("RGBA")
	if sheet.width != COLUMNS * CELL or sheet.height % CELL:
		raise SystemExit("%s is %s, expected %d wide and whole %d px rows" % (
			sheet_path, sheet.size, COLUMNS * CELL, CELL))
	out = ROOT / folder
	out.mkdir(parents=True, exist_ok=True)
	frames = []
	for number, index in enumerate(cells):
		if index >= COLUMNS * (sheet.height // CELL):
			raise SystemExit("%s has no cell %d" % (sheet_path, index))
		frame = _cell(sheet, index)
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
