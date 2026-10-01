"""Slice and clean AutoSprite's Rook sheets into the numbered frames the packer reads.

    python concept_art/rook_autosprite_v1/slice_sheet.py

Every sheet in `raw/` is the owner's AutoSprite PNG export, unchanged (2026-09-27; the owner's
`Desktop/Rook/Sprites/` folder: Rook-storefront_idle, Rook-floor, Rook-wall_right, Rook-ceiling,
Rook-dash_attack, renamed to `<state>_sheet.png`): 256 px cells, five to a row, read left to right,
top to bottom, transparent. Each kept cell becomes `<folder>/<state>_NN.png`, cleaned (below), with
the colour under alpha 0 zeroed. Nothing is moved or rescaled here; `tools/art/extract_playable_characters.py`
packs them at Patchvile's scale.

Cleaning (the owner asked for the white parts AutoSprite's background remover missed to be removed,
frame by frame, 2026-09-27). Only these pixels change, and only to transparent:
- **The gaps.** AutoSprite left the white background in the gaps between his parts: between the wing
  and the back, the hip and the tail, the head and the wings, the toes, inside the tail's curl and
  the blade's notch. In his first frames those places are transparent. A gap is a piece of near-white
  (every channel 225 or more, red no more than 11 above blue; half-transparent pieces from 200) that is
  12 px or more, or smaller and touching the transparent outside, unless its 1 px rim is bone (his
  bone is warm beige, red 15 or more above blue: 50 % of the rim for a big piece, 30 % for a small one)
  or bright purple glow (35 %: his eyes have white cores). Every half-transparent near-white pixel
  goes too: the faint white halo along his outline.
- **The blend around a gap.** Light, low-saturation, non-bone pixels up to 2 px around an opaque gap
  (white mixed into the dark body).
- **Specks left in a cleaned pocket.** Light pieces of at most 10 px whose rim is at least half
  transparent and touches the pocket (the leftover was dithered with cream), and any piece of at most
  4 px left alone next to it.
- **By eye** (`BY_EYE`, `ERASE`): small pieces the rule keeps because they look like a highlight but
  are leftovers, and single cream pixels of the leftover stuck to the body, each checked in a zoomed
  before/after of its frame.

Kept on purpose: the white cores of his eyes, the bright highlights on bone, claws and the tail blade's
rim, and the thin bone line through his wing (dash).

Which cells: every filled cell of the four loops - storefront 23, floor 17, right wall 20, ceiling 19.
The dash is a one-shot attack (owner, 2026-09-27: he pushes, dives in and swings his tail blade),
eight of its 24 cells, picked by the owner: the flight pose (03), the push (05), the dive (07), the
tail raised (08), the tail swinging round to the front (09, the contact frame), and the swing held
(11, 14, 17), which holds until the wall. Cells 18-23 fly back to the flight pose and are not used.
The sheet flies to the left, so each dash cell is turned a quarter clockwise and the flight points
up, as Scarlet's is.
`wall_top` is his own ceiling sheet (GDD §14 #55), not the floor flipped; `wall_left` is not sliced: the
packer mirrors `wall_right`. The storefront's first cell is also written as `idle_hover_00.png`, the
portrait. Before/after sheets of every frame, over magenta, are written to `review/`.
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
	"storefront_idle": ("storefront_idle", "frames/storefront", list(range(23)), 0),
	"wall_bottom": ("wall_bottom", "frames", list(range(17)), 0),
	"wall_right": ("wall_right", "frames", list(range(20)), 0),
	"wall_top": ("wall_top", "frames", list(range(19)), 0),
	"dash_loop": ("dash_attack", "frames", [3, 5, 7, 8, 9, 11, 14, 17], -90),
}
## Every raw sheet, for the review (the dash is reviewed before its cells are picked).
RAW_SHEETS = ["storefront_idle", "wall_bottom", "wall_right", "wall_top", "dash_attack"]
## A near-white piece this big (px) is a gap unless its rim is bone or glow.
BIG = 12
## Rim shares that keep a piece: bright purple glow (an eye), bone (big piece, small piece).
GLOW_RIM = 0.35
BONE_RIM_BIG = 0.5
BONE_RIM_SMALL = 0.3
## Light specks left in a cleaned pocket, and lone pieces next to it (px).
MAX_SPECK = 10
MAX_ISLAND = 4
## Leftovers the rule keeps, decided by eye: (raw sheet, cell) -> points; the kept near-white piece
## within 4 px of each point is a gap.
BY_EYE = {
	("storefront_idle", 4): [(95, 146)],
	("wall_bottom", 4): [(94, 134)], ("wall_bottom", 5): [(95, 134)],
	("wall_bottom", 8): [(77, 158)], ("wall_bottom", 9): [(77, 163)],
	("wall_bottom", 12): [(112, 214)], ("wall_bottom", 13): [(112, 214), (72, 166)],
	("wall_right", 7): [(210, 56)],
	("dash_attack", 4): [(105, 158), (101, 165)], ("dash_attack", 5): [(98, 165)],
	("dash_attack", 6): [(97, 167)], ("dash_attack", 19): [(188, 125)],
}
## Single cream pixels of the leftover stuck to the body, decided by eye: (raw sheet, cell) -> (x, y).
ERASE = {
	("wall_top", 0): [(96, 151)],
	("wall_top", 1): [(96, 154)],
	("wall_top", 5): [(88, 142)],
	("dash_attack", 0): [(201, 80), (198, 82), (201, 82), (202, 82), (199, 83), (200, 83), (211, 84),
						 (206, 85), (204, 111), (199, 115), (199, 116)],
	("dash_attack", 1): [(211, 84), (206, 85), (197, 86), (197, 87), (204, 111), (199, 115)],
	("dash_attack", 2): [(211, 84), (206, 85), (204, 111), (199, 115)],
	("dash_attack", 3): [(198, 82), (198, 83), (211, 84), (204, 110), (203, 116), (199, 174)],
	("dash_attack", 4): [(178, 119), (178, 120)],
	("dash_attack", 7): [(242, 117), (241, 118), (240, 119)],
	("dash_attack", 19): [(200, 125), (201, 125)],
	("dash_attack", 20): [(208, 84), (209, 84), (190, 86)],
	("dash_attack", 21): [(197, 85), (198, 85), (197, 86)],
	("dash_attack", 22): [(197, 85), (198, 85), (197, 86), (203, 111), (185, 151)],
	("dash_attack", 23): [(199, 84), (197, 85), (198, 85), (206, 85)],
}
EIGHT = np.ones((3, 3))


def _disk(radius: int) -> np.ndarray:
	return np.array([[x * x + y * y <= radius * radius + radius for x in range(-radius, radius + 1)]
					 for y in range(-radius, radius + 1)])


def _channels(pixels: np.ndarray):
	a = pixels.astype(int)
	r, g, b, alpha = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
	lum = 0.299 * r + 0.587 * g + 0.114 * b
	low = a[:, :, :3].min(axis=2)
	high = a[:, :, :3].max(axis=2)
	return r, g, b, alpha, lum, low, high


def gaps(pixels: np.ndarray):
	"""The white left in the gaps, and the near-white kept as eyes and highlights."""
	r, g, b, alpha, lum, low, high = _channels(pixels)
	white = (alpha > 0) & (r - b < 12) & ((low >= 225) | ((alpha < 128) & (low >= 200)))
	bone = (alpha >= 128) & (r - b >= 15) & (lum >= 140) & ~white
	glow = (alpha >= 128) & (b - g >= 50) & (lum >= 110) & ~white
	pieces, count = ndimage.label(white, structure=EIGHT)
	gap = np.zeros_like(white)
	for piece in range(1, count + 1):
		here = pieces == piece
		rim = ndimage.binary_dilation(here, structure=_disk(1)) & ~here & ~white
		size = max(1, int(rim.sum()))
		bone_share = (rim & bone).sum() / size
		glow_share = (rim & glow).sum() / size
		if glow_share >= GLOW_RIM:
			continue
		if here.sum() >= BIG:
			if bone_share < BONE_RIM_BIG:
				gap |= here
		elif (rim & (alpha == 0)).any() and bone_share < BONE_RIM_SMALL:
			gap |= here
	gap |= white & (alpha < 128)
	return gap, white & ~gap


def by_eye(kept: np.ndarray, points: list) -> np.ndarray:
	"""The kept pieces near the points decided by eye."""
	pieces, count = ndimage.label(kept, structure=EIGHT)
	out = np.zeros_like(kept)
	for x, y in points:
		near = set(np.unique(pieces[max(0, y - 4):y + 5, max(0, x - 4):x + 5])) - {0}
		if not near:
			raise SystemExit("no kept piece near %d, %d" % (x, y))
		for piece in near:
			out |= pieces == piece
	return out


def blend(pixels: np.ndarray, gap: np.ndarray, kept: np.ndarray):
	"""Light blend pixels up to 2 px around the opaque gaps, and those gaps."""
	r, g, b, alpha, lum, low, high = _channels(pixels)
	light = (alpha > 0) & (lum >= 140) & (high - low <= 60) & (r - b < 12) & ~kept
	pieces, count = ndimage.label(gap, structure=EIGHT)
	solid = np.zeros_like(gap)
	for piece in range(1, count + 1):
		here = pieces == piece
		if (alpha[here] >= 128).sum() >= 4:
			solid |= here
	grown = solid.copy()
	out = np.zeros_like(gap)
	for _ in range(2):
		step = ndimage.binary_dilation(grown, structure=EIGHT) & light & ~gap & ~out
		out |= step
		grown |= step
	return out, solid


def specks(pixels: np.ndarray, pocket: np.ndarray) -> np.ndarray:
	"""Light pieces of at most MAX_SPECK px standing mostly in a cleaned pocket."""
	r, g, b, alpha, lum, low, high = _channels(pixels)
	pieces, count = ndimage.label((alpha > 0) & (lum >= 150), structure=EIGHT)
	sizes = np.bincount(pieces.ravel())
	out = np.zeros_like(pocket)
	for piece in range(1, count + 1):
		if sizes[piece] > MAX_SPECK:
			continue
		here = pieces == piece
		rim = ndimage.binary_dilation(here, structure=EIGHT) & ~here
		if (rim & pocket).any() and (rim & (alpha == 0)).sum() >= 0.5 * rim.sum():
			out |= here
	return out


def islands(pixels: np.ndarray, pocket: np.ndarray) -> np.ndarray:
	"""Pieces of at most MAX_ISLAND px left alone next to a cleaned pocket."""
	pieces, count = ndimage.label(pixels[:, :, 3] > 0, structure=EIGHT)
	sizes = np.bincount(pieces.ravel())
	near = ndimage.binary_dilation(pocket, structure=EIGHT)
	out = np.zeros_like(pocket)
	for piece in range(1, count + 1):
		if sizes[piece] <= MAX_ISLAND and (near & (pieces == piece)).any():
			out |= pieces == piece
	return out


def clean(sheet: str, cell: int, pixels: np.ndarray) -> tuple[np.ndarray, int]:
	"""The frame with AutoSprite's leftovers made transparent, and how many pixels changed."""
	gap, kept = gaps(pixels)
	decided = by_eye(kept, BY_EYE.get((sheet, cell), []))
	gap, kept = gap | decided, kept & ~decided
	rim, solid = blend(pixels, gap, kept)
	cleaned = pixels.copy()
	cleaned[gap | rim] = 0
	pocket = solid | rim
	for _ in range(2):
		loose = specks(cleaned, pocket)
		cleaned[loose] = 0
		pocket |= loose
	for x, y in ERASE.get((sheet, cell), []):
		if cleaned[y, x, 3] == 0:
			raise SystemExit("%s cell %d: %d, %d is already clear" % (sheet, cell, x, y))
		cleaned[y, x] = 0
		pocket[y, x] = True
	alone = islands(cleaned, pocket)
	cleaned[alone] = 0
	return cleaned, int((cleaned[:, :, 3] != pixels[:, :, 3]).sum())


def _cell(sheet: Image.Image, index: int) -> Image.Image:
	row, column = divmod(index, COLUMNS)
	return sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))


def _load(sheet: str) -> Image.Image:
	image = Image.open(ROOT / "raw" / ("%s_sheet.png" % sheet)).convert("RGBA")
	if image.width != COLUMNS * CELL or image.height % CELL:
		raise SystemExit("%s is %s, expected %d wide and whole %d px rows" % (
			sheet, image.size, COLUMNS * CELL, CELL))
	return image


def _step(a: np.ndarray, b: np.ndarray) -> float:
	"""Mean colour change between two frames, weighted by alpha."""
	fa = a[:, :, :3] * (a[:, :, 3:] / 255.0)
	fb = b[:, :, :3] * (b[:, :, 3:] / 255.0)
	return float(np.abs(fa - fb).mean())


def slice_sheet(state: str, sheet: str, folder: str, cells: list, turn: int) -> None:
	image = _load(sheet)
	out = ROOT / folder
	out.mkdir(parents=True, exist_ok=True)
	frames = []
	changed = []
	for number, index in enumerate(cells):
		before = np.array(_cell(image, index))
		if before[:, :, 3].max() == 0:
			raise SystemExit("%s cell %d is empty" % (sheet, index))
		after, count = clean(sheet, index, before)
		changed.append(count)
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


def review(sheet: str) -> None:
	"""Every filled cell of a raw sheet, before and after, over magenta so transparency shows."""
	image = _load(sheet)
	cells = [index for index in range(COLUMNS * (image.height // CELL))
			 if np.array(_cell(image, index))[:, :, 3].max() > 0]
	pairs = 3
	rows = (len(cells) + pairs - 1) // pairs
	page = Image.new("RGB", (pairs * (2 * CELL + 12), rows * (CELL + 20)), (30, 30, 36))
	draw = ImageDraw.Draw(page)
	for slot, index in enumerate(cells):
		before = np.array(_cell(image, index))
		after, count = clean(sheet, index, before)
		x, y = (slot % pairs) * (2 * CELL + 12), (slot // pairs) * (CELL + 20)
		for side, pixels in enumerate((before, after)):
			backing = Image.new("RGBA", (CELL, CELL), (200, 40, 160, 255))
			backing.alpha_composite(Image.fromarray(pixels, "RGBA"))
			page.paste(backing.convert("RGB"), (x + side * (CELL + 2), y + 18))
		draw.text((x + 4, y + 3), "%s cell %02d - before | after (%d px)" % (sheet, index, count), fill=(255, 255, 0))
	(ROOT / "review").mkdir(exist_ok=True)
	page.save(ROOT / "review" / ("cleanup_%s.png" % sheet), optimize=True)


def main() -> None:
	for state, (sheet, folder, cells, turn) in SHEETS.items():
		slice_sheet(state, sheet, folder, cells, turn)
	for sheet in RAW_SHEETS:
		review(sheet)
	portrait = ROOT / "frames/storefront/storefront_idle_00.png"
	Image.open(portrait).save(ROOT / "frames/idle_hover_00.png", optimize=True)


if __name__ == "__main__":
	main()
