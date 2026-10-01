"""Slice AutoSprite's Shade sheets into the numbered frames the packer reads.

    python concept_art/verdant_shade_autosprite_v1/slice_sheet.py

Every sheet in `raw/` is AutoSprite's export, unchanged (owner, 2026-09-25): a 5 x 5 grid of 256 px
cells, read left to right, top to bottom, transparent. This export fills fewer than 25 cells - the
storefront, the floor and the dash 24, the ceiling 23 and the right wall 21 - and the rest are empty.
Each kept cell becomes `<folder>/<state>_NN.png` with the colour under alpha 0 zeroed. Nothing is
moved or rescaled here; `tools/art/extract_playable_characters.py` packs them at Patchvile's scale.

Which cells, and why:
- **Storefront, right wall, ceiling:** every filled cell. Their last cell is one ordinary step from
  the first, so the loop closes without a repeat.
- **Floor:** 23 of 24. Its last cell nearly repeats the first (mean change 0.66 against 2.72 between
  neighbours), so it is dropped, as Patchvile's walls drop their repeat.
- **Dash:** a one-shot attack (owner, #40), eight cells: the flight pose (03, 04), the draw-in with
  the tail lit (05), the burst opening (11), the full burst (12, the contact frame), and the
  follow-through (13, 14, 16), whose last frame holds until the wall. Cells 06-09 swing the body
  upright, face on, as if standing, and reach the cell edge; 06, 10 and 21 carry white glare blobs.
  None of those are kept. The sheet draws the flight with the face at the bottom and the horns at
  the top, and the rig flies a dash frame toward its top, so the face trailed (owner, 2026-09-25:
  "he has to attack with his face in front"). Each dash cell is turned 180 degrees, so the face
  leads and the horns and flames stream behind. Shade is symmetric, so nothing else changes.

`wall_left` is not sliced: the packer mirrors `wall_right` for it. The ceiling is AutoSprite's own
sheet (the owner generated it), so it is not the floor flipped. The storefront's first cell is also
written as `idle_hover_00.png`, the portrait. The four loose leaves beside the right-wall pose in its
first cell are cut out to `particles/leaf_a..d.png`, the pieces Shade's dash throws off.
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation, label

ROOT = Path(__file__).resolve().parent
COLUMNS = 5
ROWS = 5
CELL = 256
## state: (raw sheet, output folder, cells kept in order, degrees to turn each - PIL, anticlockwise)
SHEETS = {
	"storefront_idle": ("raw/storefront_idle_sheet.png", "frames/storefront", list(range(24)), 0),
	"wall_bottom": ("raw/wall_bottom_sheet.png", "frames", list(range(23)), 0),
	"wall_right": ("raw/wall_right_sheet.png", "frames", list(range(21)), 0),
	"wall_top": ("raw/wall_top_sheet.png", "frames", list(range(23)), 0),
	"dash_loop": ("raw/dash_attack_sheet.png", "frames", [3, 4, 5, 11, 12, 13, 14, 16], 180),
}
## The loose leaves beside the right-wall pose in its first cell: their boxes in cell pixels.
LEAVES = {
	"leaf_a": (63, 71, 72, 89),
	"leaf_b": (59, 109, 68, 125),
	"leaf_c": (104, 46, 116, 59),
	"leaf_d": (157, 154, 169, 169),
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
	if sheet.size != (COLUMNS * CELL, ROWS * CELL):
		raise SystemExit("%s is %s, expected %dx%d" % (
			sheet_path, sheet.size, COLUMNS * CELL, ROWS * CELL))
	out = ROOT / folder
	out.mkdir(parents=True, exist_ok=True)
	frames = []
	for number, index in enumerate(cells):
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


def cut_leaves() -> None:
	"""Each loose leaf with its own soft edge, and nothing of its neighbours."""
	cell = np.array(_cell(Image.open(ROOT / "raw/wall_right_sheet.png").convert("RGBA"), 0))
	pieces, _count = label(cell[:, :, 3] > 40, structure=np.ones((3, 3), dtype=bool))
	out = ROOT / "particles"
	out.mkdir(exist_ok=True)
	for name, (x0, y0, x1, y1) in LEAVES.items():
		ids = np.unique(pieces[y0:y1, x0:x1])
		ids = ids[ids > 0]
		own = binary_dilation(np.isin(pieces, ids), iterations=2)
		leaf = cell.copy()
		leaf[~own] = 0
		leaf = leaf[y0 - 2 : y1 + 2, x0 - 2 : x1 + 2]
		Image.fromarray(leaf, "RGBA").save(out / ("%s.png" % name), optimize=True)
	print("LEAVES: %d particle pieces -> particles/" % len(LEAVES))


def main() -> None:
	for state, (sheet_path, folder, cells, turn) in SHEETS.items():
		slice_sheet(state, sheet_path, folder, cells, turn)
	portrait = ROOT / "frames/storefront/storefront_idle_00.png"
	Image.open(portrait).save(ROOT / "frames/idle_hover_00.png", optimize=True)
	cut_leaves()


if __name__ == "__main__":
	main()
