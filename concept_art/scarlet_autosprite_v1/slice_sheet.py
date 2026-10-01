"""Slice and clean AutoSprite's Scarlet sheets into the numbered frames the packer reads.

    python concept_art/scarlet_autosprite_v1/slice_sheet.py

Every sheet in `raw/` is the owner's AutoSprite PNG export, unchanged (2026-09-26; the owner's
`Sprite Sheets/` folder: storefront_idle, wall_bottom, wall_right, dash_attack): 256 px cells, five
to a row, read left to right, top to bottom, transparent. Each kept cell becomes
`<folder>/<state>_NN.png`, cleaned (below), with the colour under alpha 0 zeroed. Nothing is moved or
rescaled here; `tools/art/extract_playable_characters.py` packs them at Patchvile's scale.

Cleaning (the owner asked for the frames to be cleaned, 2026-09-26). Only these pixels change, and
only to transparent:
- **Between the fan's ribs.** Her first frames show the fan's inner ribs with see-through gaps, but
  AutoSprite filled the gaps with light grey or white in most frames (floor ~200 px a frame). The
  fan's wood is found by colour (brown ribs and guards; every piece of 40 px or more), the rib area
  is that wood closed over its gaps, and inside it every light, non-blue pixel that is not part of a
  solid area goes. "Solid" is what survives an opening with a 5 px disk (her body, the fan's paper),
  grown by 2 px, so her hair, skin and costume are never touched: the gaps are 1-4 px stripes.
- **The reap's tips (dash).** Pieces under 150 px that are apart from her body and from the pale
  reap: dark ones (mean luminance under 80) go whole, and the near-black pixels (every channel under
  50) of the others go - the black streaks AutoSprite left where the reap thins out, some fading
  into blue. Her floating diamonds are such pieces too, but they are cyan and gold, with no
  near-black pixels. A streak that touches the fan joins her body's piece, so any run of 5 or more
  near-black pixels goes as well: her eyes are the only other near-black in these frames, 1-3 px.
- **Specks between the ribs.** Dark pieces of at most 4 px inside the rib area, apart from her body.

Which cells, and why:
- **Storefront:** all 25 cells. The last is not a repeat of the first: its seam (1.02) is larger
  than the smallest step between neighbours (0.12), so the loop closes on an ordinary step.
- **Floor:** all 24 filled cells of its sheet (the 25th cell is empty; seam 1.82, smallest step 0.56).
- **Right wall:** all 25 cells (seam 1.12, smallest step 0.20).
- **Dash:** a one-shot attack (owner, 2026-09-26: she swings her fan and an airy blue reap follows
  it), eight cells: the flight pose (07, like the uploaded first frame), the wind-up (09), the swing
  (10, 11), the full reap (12, the contact frame), the reap sweeping on (15), the reap fading (19)
  and the end of the swing (22), which holds until the wall. The sheet flies to the left, so each cell is turned a quarter clockwise and
  the flight points up, as Patchvile's and Mothmere's are.

`wall_top` and `wall_left` are not sliced: the packer flips `wall_bottom` and mirrors `wall_right`
for them. The storefront's first cell is also written as `idle_hover_00.png`, the portrait. A
before/after sheet of the cleaning is written to `review_cleanup.png`.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parent
COLUMNS = 5
CELL = 256
## state: (raw sheet, output folder, cells kept in order, degrees to turn each - PIL, anticlockwise)
SHEETS = {
	"storefront_idle": ("raw/storefront_idle_sheet.png", "frames/storefront", list(range(25)), 0),
	"wall_bottom": ("raw/wall_bottom_sheet.png", "frames", list(range(24)), 0),
	"wall_right": ("raw/wall_right_sheet.png", "frames", list(range(25)), 0),
	"dash_loop": ("raw/dash_attack_sheet.png", "frames", [7, 9, 10, 11, 12, 15, 19, 22], -90),
}
## A piece of fan wood smaller than this (px) is costume trim or a boot, not the fan.
MIN_WOOD = 40
## Dark pieces apart from her body smaller than this (px) at the reap's tips are streaks.
MAX_STREAK = 150
## Dark pieces between the ribs of at most this size (px) are specks.
MAX_SPECK = 4
## A run of near-black this long (px) in a dash frame is a streak even when it touches the fan.
MIN_RUN = 5


def _disk(radius: int) -> np.ndarray:
	return np.array([[x * x + y * y <= radius * radius + radius for x in range(-radius, radius + 1)]
					 for y in range(-radius, radius + 1)])


def _channels(pixels: np.ndarray):
	a = pixels.astype(int)
	r, g, b, alpha = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
	lum = 0.299 * r + 0.587 * g + 0.114 * b
	sat = a[:, :, :3].max(axis=2) - a[:, :, :3].min(axis=2)
	return r, g, b, alpha, lum, sat


def _fan_zone(pixels: np.ndarray):
	"""The fan's wood, and the rib area: that wood closed over the gaps between the ribs."""
	r, g, b, alpha, lum, sat = _channels(pixels)
	wood = (alpha > 200) & (r > 90) & (r < 215) & (g > 45) & (g < 155) & (b < 115) & (r > b + 35) & (sat >= 55)
	pieces, count = ndimage.label(wood, structure=np.ones((3, 3)))
	sizes = np.bincount(pieces.ravel())
	sizes[0] = 0
	fan = np.isin(pieces, np.nonzero(sizes >= MIN_WOOD)[0])
	return fan, ndimage.binary_closing(fan, structure=_disk(3)) & ~fan


def _solid(pixels: np.ndarray, fan: np.ndarray) -> np.ndarray:
	"""Her body and the fan's paper: whatever is wider than the gaps between the ribs, grown by 2 px."""
	content = (pixels[:, :, 3] > 128) & ~fan
	return ndimage.binary_dilation(ndimage.binary_opening(content, structure=_disk(2)), structure=_disk(2))


def rib_gaps(pixels: np.ndarray) -> np.ndarray:
	"""Light grey or white filled into the gaps between the fan's ribs."""
	r, g, b, alpha, lum, sat = _channels(pixels)
	fan, zone = _fan_zone(pixels)
	light = (lum >= 140) & ~((b > r + 40) & (g > r)) & ~((lum < 95) & (b >= r))
	return (alpha > 0) & zone & light & ~_solid(pixels, fan)


def rib_specks(pixels: np.ndarray) -> np.ndarray:
	"""Tiny dark specks between the fan's ribs, apart from her body."""
	r, g, b, alpha, lum, sat = _channels(pixels)
	fan, zone = _fan_zone(pixels)
	dark = (alpha > 0) & zone & (lum < 90) & ~_solid(pixels, fan)
	pieces, count = ndimage.label(dark, structure=np.ones((3, 3)))
	sizes = np.bincount(pieces.ravel())
	sizes[0] = MAX_SPECK + 1
	return sizes[pieces] <= MAX_SPECK


def reap_streaks(pixels: np.ndarray) -> np.ndarray:
	"""Small dark pieces apart from her body and from the pale reap: the reap's black tips."""
	r, g, b, alpha, lum, sat = _channels(pixels)
	reap = (alpha > 0) & (lum > 175) & (b >= r - 8) & (sat < 110)
	rest = (alpha > 0) & ~reap
	pieces, count = ndimage.label(rest, structure=np.ones((3, 3)))
	if count == 0:
		return np.zeros_like(rest)
	sizes = np.bincount(pieces.ravel())
	sizes[0] = 0
	body = sizes.argmax()
	near_black = (alpha > 0) & (pixels[:, :, :3].max(axis=2) < 50)
	streak = np.zeros_like(rest)
	for piece in range(1, count + 1):
		if piece == body or sizes[piece] >= MAX_STREAK:
			continue
		here = pieces == piece
		streak |= here if lum[here].mean() < 80 else here & near_black
	# A streak can touch the fan and so join her body's piece: longer runs of near-black go too. Her
	# eyes are the only other near-black in these frames, 1-3 px.
	runs, run_count = ndimage.label(near_black, structure=np.ones((3, 3)))
	run_sizes = np.bincount(runs.ravel())
	run_sizes[0] = 0
	streak |= run_sizes[runs] >= MIN_RUN
	return streak


def clean(state: str, pixels: np.ndarray) -> tuple[np.ndarray, int]:
	"""The frame with AutoSprite's leftovers made transparent, and how many pixels changed."""
	remove = rib_gaps(pixels)
	cleaned = pixels.copy()
	cleaned[remove] = 0
	specks = rib_specks(cleaned)
	remove |= specks
	cleaned[specks] = 0
	if state == "dash_loop":
		streaks = reap_streaks(cleaned)
		remove |= streaks
		cleaned[streaks] = 0
	return cleaned, int(remove.sum())


def _cell(sheet: Image.Image, index: int) -> Image.Image:
	row, column = divmod(index, COLUMNS)
	return sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))


def _step(a: np.ndarray, b: np.ndarray) -> float:
	"""Mean colour change between two frames, weighted by alpha."""
	fa = a[:, :, :3] * (a[:, :, 3:] / 255.0)
	fb = b[:, :, :3] * (b[:, :, 3:] / 255.0)
	return float(np.abs(fa - fb).mean())


def slice_sheet(state: str, sheet_path: str, folder: str, cells: list, turn: int) -> list:
	sheet = Image.open(ROOT / sheet_path).convert("RGBA")
	if sheet.width != COLUMNS * CELL or sheet.height % CELL:
		raise SystemExit("%s is %s, expected %d wide and whole %d px rows" % (
			sheet_path, sheet.size, COLUMNS * CELL, CELL))
	out = ROOT / folder
	out.mkdir(parents=True, exist_ok=True)
	frames = []
	pairs = []
	changed = []
	for number, index in enumerate(cells):
		if index >= COLUMNS * (sheet.height // CELL):
			raise SystemExit("%s has no cell %d" % (sheet_path, index))
		before = np.array(_cell(sheet, index))
		if before[:, :, 3].max() == 0:
			raise SystemExit("%s cell %d is empty" % (state, index))
		after, count = clean(state, before)
		changed.append(count)
		pairs.append((before, after))
		frame = Image.fromarray(after, "RGBA")
		if turn:
			frame = frame.rotate(turn)
		pixels = np.array(frame)
		pixels[pixels[:, :, 3] == 0, :3] = 0
		Image.fromarray(pixels, "RGBA").save(out / ("%s_%02d.png" % (state, number)), optimize=True)
		frames.append(pixels.astype(float))
	steps = [_step(frames[i], frames[i + 1]) for i in range(len(frames) - 1)]
	print("SLICED: %-16s %2d frames -> %s  (step mean %.2f, max %.2f; seam back to 00: %.2f; "
		  "cleaned %d px, most %d in one frame)" % (
		state, len(cells), out.relative_to(ROOT), float(np.mean(steps)), max(steps),
		_step(frames[-1], frames[0]), sum(changed), max(changed)))
	return pairs


def _review(picks: list) -> None:
	"""Before and after of the most-cleaned frame of each sheet, on magenta so transparency shows."""
	tiles = []
	for state, (before, after) in picks:
		row = []
		for pixels in (before, after):
			backing = Image.new("RGBA", (CELL, CELL), (200, 40, 160, 255))
			backing.alpha_composite(Image.fromarray(pixels, "RGBA"))
			row.append(backing.convert("RGB").resize((CELL * 3, CELL * 3), Image.Resampling.NEAREST))
		tiles.append((state, row))
	sheet = Image.new("RGB", (len(tiles) * (CELL * 3 + 16), 2 * (CELL * 3 + 28)), (30, 30, 36))
	draw = ImageDraw.Draw(sheet)
	for column, (state, row) in enumerate(tiles):
		x = column * (CELL * 3 + 16)
		for line, tile in enumerate(row):
			y = line * (CELL * 3 + 28)
			sheet.paste(tile, (x, y + 24))
			draw.text((x + 4, y + 6), "%s - %s" % (state, "before" if line == 0 else "after"), fill=(255, 255, 0))
	sheet.save(ROOT / "review_cleanup.png", optimize=True)


def main() -> None:
	picks = []
	dash = []
	for state, (sheet_path, folder, cells, turn) in SHEETS.items():
		pairs = slice_sheet(state, sheet_path, folder, cells, turn)
		most = max(pairs, key=lambda pair: int((pair[0] != pair[1]).any(axis=2).sum()))
		picks.append((state, most))
		if state == "dash_loop":
			dash = [after for _before, after in pairs]
	_review(picks)
	portrait = ROOT / "frames/storefront/storefront_idle_00.png"
	Image.open(portrait).save(ROOT / "frames/idle_hover_00.png", optimize=True)
	_cut_particles(dash)


def _save_piece(name: str, pixels: np.ndarray, mask: np.ndarray) -> None:
	piece = np.zeros_like(pixels)
	piece[mask] = pixels[mask]
	ys, xs = np.nonzero(mask)
	piece = piece[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
	out = ROOT / "particles"
	out.mkdir(exist_ok=True)
	Image.fromarray(piece, "RGBA").save(out / ("%s.png" % name), optimize=True)
	print("PARTICLE: %-14s %3d x %3d px" % (name, piece.shape[1], piece.shape[0]))


def _cut_particles(dash: list) -> None:
	"""Her own pieces for the dash particles (the approved plan: Ilyra's effects, in her blue, from
	her own frames): the pale reap crescent of the full-reap and the sweeping frames, and her middle
	crown diamond where it floats free of her hair and the fan (right wall, cell 08)."""
	for name, frame in (("reap_arc_a", dash[4]), ("reap_arc_b", dash[5])):
		r, g, b, alpha, lum, sat = _channels(frame)
		pale = (alpha > 0) & (lum > 175) & (b >= r - 8) & (sat < 110)
		pieces, count = ndimage.label(pale, structure=np.ones((3, 3)))
		sizes = np.bincount(pieces.ravel())
		sizes[0] = 0
		_save_piece(name, frame, pieces == sizes.argmax())
	wall = np.array(_cell(Image.open(ROOT / "raw/wall_right_sheet.png").convert("RGBA"), 8))
	pieces, count = ndimage.label(wall[:, :, 3] > 0, structure=np.ones((3, 3)))
	sizes = np.bincount(pieces.ravel())
	sizes[0] = 0
	small = [piece for piece in range(1, count + 1) if 20 <= sizes[piece] <= 200]
	_save_piece("crown_diamond", wall, pieces == max(small, key=lambda piece: sizes[piece]))


if __name__ == "__main__":
	main()
