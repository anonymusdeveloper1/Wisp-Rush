#!/usr/bin/env python3
"""Extract layered playable-character art from approved transparent source sheets.

The generated sources stay under ``concept_art/wisp_rush_playable_characters_v1/assets/``. Runtime
PNGs are deterministic fixed-cell extracts with isolated-alpha cleanup, so the game never uses a
complete concept sheet. Each run also writes a QA contact sheet per character to
``logs/playable_characters/<id>_parts.png`` and prints the ribbon spines the rigs use.

Requirements: Python 3.7+, Pillow 9.5 and numpy 1.21.

    python3 tools/art/extract_playable_characters.py              # every character
    python3 tools/art/extract_playable_characters.py rook morrow  # only these
"""
import sys
from collections import deque
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


REPO = Path(__file__).resolve().parents[2]
SOURCES = REPO / "concept_art/wisp_rush_playable_characters_v1/assets"
OUTPUT = REPO / "assets/art/characters/playable"
CONTACTS = REPO / "logs/playable_characters"

Box = Tuple[int, int, int, int]

# Fixed cells are intentional: each generated sheet is an approved source artifact, not a runtime
# atlas. `min_area` removes the detached colour specks the generator leaves between painted parts.
# Cell order follows the generation prompts in GENERATION_PROMPT.md.
CHARACTERS: Dict[str, Dict[str, Tuple[Box, int]]] = {
	"veyra": {
		"preview": ((20, 0, 430, 570), 700),
		"outer_body": ((450, 0, 815, 525), 900),
		"core": ((845, 75, 1100, 500), 700),
		"eyes": ((1130, 225, 1435, 430), 700),
		"left_fin": ((45, 545, 330, 805), 700),
		"right_fin": ((385, 545, 680, 805), 700),
		# The halo cell holds two arc groups; each half floats on its own in the rig.
		"halo_left": ((670, 505, 905, 810), 260),
		"halo_right": ((905, 505, 1100, 810), 260),
		"tail_a": ((1080, 500, 1448, 810), 700),
		"tail_b": ((20, 775, 355, 1086), 700),
		"tail_c": ((370, 775, 800, 1086), 700),
		"soul_spark": ((845, 825, 1050, 1045), 350),
	},
	"rook": {
		"preview": ((0, 25, 540, 448), 900),
		"shadow_body": ((530, 35, 725, 450), 900),
		"skull": ((785, 55, 1060, 415), 900),
		# "Left"/"right" are Rook's own sides: he faces the camera, so his left wing is on screen right.
		"wing_frame_left": ((1075, 50, 1448, 450), 900),
		"wing_frame_right": ((20, 445, 380, 830), 900),
		"membrane_left": ((400, 450, 740, 800), 900),
		"membrane_right": ((745, 450, 1085, 800), 900),
		"foot_right": ((1100, 530, 1266, 765), 900),
		"foot_left": ((1266, 530, 1440, 765), 900),
		"tail_segment": ((50, 830, 340, 1010), 900),
		"tail_fin": ((460, 805, 705, 1050), 900),
		"dash_streak": ((760, 830, 1100, 1030), 700),
		"wing_dust": ((1175, 830, 1375, 1015), 700),
	},
	"morrow": {
		"preview": ((25, 0, 415, 490), 900),
		"cloak_body": ((425, 75, 830, 470), 900),
		"hood": ((830, 75, 1165, 455), 900),
		"mask": ((1195, 125, 1430, 425), 900),
		"front_flap": ((60, 485, 380, 805), 900),
		"hand_left": ((455, 485, 735, 790), 900),
		"hand_right": ((815, 485, 1095, 790), 900),
		"rune_stone": ((1175, 485, 1430, 765), 700),
		"scarf_a": ((100, 775, 345, 1086), 900),
		"scarf_b": ((605, 775, 805, 1086), 900),
		"rune_fragment": ((960, 850, 1090, 1025), 700),
		"cloth_wisp": ((1200, 835, 1405, 1050), 700),
	},
}

# Ribbon layers bend on a bone chain. The spine runs from the attachment root (given as a fraction
# of the extracted image) to the geodesically farthest painted pixel.
RIBBONS: Dict[str, Dict[str, Tuple[float, float]]] = {
	"veyra": {"tail_a": (0.05, 0.12), "tail_b": (0.08, 0.1), "tail_c": (0.06, 0.1)},
	"morrow": {"scarf_a": (0.62, 0.03), "scarf_b": (0.55, 0.03)},
}
SPINE_POINTS = 5


def label_components(mask: np.ndarray) -> Tuple[np.ndarray, List[int]]:
	"""Label 8-connected seed pixels using row runs; returns labels and component areas."""
	h, w = mask.shape
	labels = np.zeros((h, w), dtype=np.int32)
	parent: List[int] = [0]
	areas: List[int] = [0]
	next_label = 0
	for y in range(h):
		x = 0
		while x < w:
			if not mask[y, x]:
				x += 1
				continue
			x0 = x
			while x < w and mask[y, x]:
				x += 1
			x1 = x
			neighbours = set()
			if y > 0:
				neighbours.update(int(value) for value in labels[y - 1, max(0, x0 - 1):min(w, x1 + 1)] if value)
			if not neighbours:
				next_label += 1
				parent.append(next_label)
				areas.append(0)
				label = next_label
			else:
				label = min(neighbours)
				for other in neighbours:
					root = other
					while parent[root] != root:
						root = parent[root]
					parent[other] = label
					parent[root] = label
			labels[y, x0:x1] = label

	def find(value: int) -> int:
		while parent[value] != value:
			parent[value] = parent[parent[value]]
			value = parent[value]
		return value

	for value in range(1, next_label + 1):
		parent[value] = find(value)
	for y in range(h):
		for x in range(w):
			value = int(labels[y, x])
			if value:
				root = parent[value]
				labels[y, x] = root
				areas[root] += 1
	return labels, areas


def extract_part(sheet: Image.Image, box: Box, min_area: int) -> Image.Image:
	part = sheet.crop(box).convert("RGBA")
	alpha = np.asarray(part.getchannel("A"))
	labels, areas = label_components(alpha >= 24)
	kept_ids = [index for index, area in enumerate(areas) if index and area >= min_area]
	if not kept_ids:
		raise RuntimeError("No painted component survived in cell %s" % (box,))
	seed = np.isin(labels, kept_ids).astype(np.uint8) * 255
	# Re-attach the soft outer glow without re-introducing remote generation speckles.
	grown = Image.fromarray(seed, "L").filter(ImageFilter.MaxFilter(31))
	clean_alpha = Image.composite(part.getchannel("A"), Image.new("L", part.size), grown)
	part.putalpha(clean_alpha)
	content = clean_alpha.point(lambda value: 255 if value >= 3 else 0).getbbox()
	if content is None:
		raise RuntimeError("Empty output for cell %s" % (box,))
	left = max(0, content[0] - 8)
	top = max(0, content[1] - 8)
	right = min(part.width, content[2] + 8)
	bottom = min(part.height, content[3] + 8)
	return part.crop((left, top, right, bottom))


def ribbon_spine(art: Image.Image, root_hint: Tuple[float, float], count: int) -> List[Tuple[float, float]]:
	"""Centre line of a ribbon, root first, as `count` points in image pixels.

	Pixels are grouped by geodesic distance from the root; each distance band's centroid lies on the
	ribbon's centre line even where the painted ribbon curls back on itself.
	"""
	step = 3
	alpha = np.asarray(art.getchannel("A"))[::step, ::step]
	mask = alpha >= 60
	h, w = mask.shape
	root_x = min(w - 1, int(root_hint[0] * w))
	root_y = min(h - 1, int(root_hint[1] * h))
	ys, xs = np.nonzero(mask)
	nearest = int(np.argmin((xs - root_x) ** 2 + (ys - root_y) ** 2))
	start = (int(ys[nearest]), int(xs[nearest]))
	distance = np.full(mask.shape, -1, dtype=np.int32)
	distance[start] = 0
	queue = deque([start])
	while queue:
		y, x = queue.popleft()
		for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			ny, nx = y + dy, x + dx
			if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and distance[ny, nx] < 0:
				distance[ny, nx] = distance[y, x] + 1
				queue.append((ny, nx))
	longest = int(distance.max())
	points: List[Tuple[float, float]] = []
	for index in range(count):
		centre = longest * index / (count - 1)
		band = np.abs(distance - centre) <= max(1.0, longest / (count * 3.0))
		band &= distance >= 0
		by, bx = np.nonzero(band)
		points.append(((float(bx.mean()) + 0.5) * step, (float(by.mean()) + 0.5) * step))
	return points


def make_contact(name: str, outputs: Dict[str, Image.Image], spines: Dict[str, List]) -> Path:
	cell_w, cell_h = 340, 330
	rows = (len(outputs) + 3) // 4
	canvas = Image.new("RGBA", (cell_w * 4, cell_h * rows), (12, 15, 29, 255))
	draw = ImageDraw.Draw(canvas)
	for index, (part, art) in enumerate(outputs.items()):
		row, column = divmod(index, 4)
		thumb = art.copy()
		thumb.thumbnail((cell_w - 30, cell_h - 50), Image.Resampling.LANCZOS)
		x = column * cell_w + (cell_w - thumb.width) // 2
		y = row * cell_h + 28 + (cell_h - 45 - thumb.height) // 2
		canvas.alpha_composite(thumb, (x, y))
		label = "%s %dx%d" % (part, art.width, art.height)
		draw.text((column * cell_w + 10, row * cell_h + 8), label, fill=(236, 241, 255, 255))
		if part in spines:
			ratio = thumb.width / art.width
			line = [(x + px * ratio, y + py * ratio) for px, py in spines[part]]
			draw.line(line, fill=(255, 220, 60, 255), width=2)
			for px, py in line:
				draw.ellipse((px - 3, py - 3, px + 3, py + 3), fill=(255, 90, 60, 255))
	CONTACTS.mkdir(parents=True, exist_ok=True)
	path = CONTACTS / ("%s_parts.png" % name)
	canvas.convert("RGB").save(path)
	return path


def extract_character(name: str) -> None:
	source = SOURCES / ("%s_rig_source.png" % name)
	if not source.exists():
		raise FileNotFoundError(source)
	out_dir = OUTPUT / name
	out_dir.mkdir(parents=True, exist_ok=True)
	sheet = Image.open(source).convert("RGBA")
	outputs: Dict[str, Image.Image] = {}
	for part, (box, min_area) in CHARACTERS[name].items():
		art = extract_part(sheet, box, min_area)
		art.save(out_dir / (part + ".png"), optimize=True)
		outputs[part] = art
	spines: Dict[str, List] = {}
	for part, hint in RIBBONS.get(name, {}).items():
		spines[part] = ribbon_spine(outputs[part], hint, SPINE_POINTS)
	contact = make_contact(name, outputs, spines)
	print("PLAYABLE ART: %d %s layers -> %s" % (len(outputs), name, out_dir))
	for part, points in spines.items():
		# Paste into the rig scene's RibbonChain `spine` (texture pixels, origin top-left).
		values = ", ".join("%d, %d" % (round(px), round(py)) for px, py in points)
		print("  SPINE %s/%s: PackedVector2Array(%s)" % (name, part, values))
	print("  CONTACT: %s" % contact)


def main(names: Optional[List[str]] = None) -> None:
	for name in names or list(CHARACTERS):
		if name not in CHARACTERS:
			raise SystemExit("Unknown character %r (known: %s)" % (name, ", ".join(CHARACTERS)))
		extract_character(name)


if __name__ == "__main__":
	main(sys.argv[1:])
