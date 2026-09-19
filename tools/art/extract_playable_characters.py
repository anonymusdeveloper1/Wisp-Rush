#!/usr/bin/env python3
"""Extract layered playable-character art from approved transparent source sheets.

The generated sources stay under ``concept_art/wisp_rush_playable_characters_v1/assets/``. Runtime
PNGs are deterministic fixed-cell extracts with isolated-alpha cleanup, so the game never uses a
complete concept sheet. Each run also writes a QA contact sheet per character to
``logs/playable_characters/<id>_parts.png`` and prints the ribbon spines the rigs use.

Requirements: Python 3.7+, Pillow 9.5, numpy 1.21 and scipy 1.7.

    python3 tools/art/extract_playable_characters.py              # every character
    python3 tools/art/extract_playable_characters.py rook morrow  # only these
"""
import json
import shutil
import sys
from collections import deque
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage


REPO = Path(__file__).resolve().parents[2]
SOURCES = REPO / "concept_art/wisp_rush_playable_characters_v1/assets"
OUTPUT = REPO / "assets/art/characters/playable"
CONTACTS = REPO / "logs/playable_characters"

Box = Tuple[int, int, int, int]
Polygon = List[Tuple[int, int]]

# Source packs are versioned: v1 characters keep their original sheet (and therefore byte-identical
# output), while later packs point at their own approved rig source. `tools/art/make_rig_source.py`
# builds these transparent sheets from the opaque approved references.
SOURCE_SHEETS: Dict[str, Path] = {
	"bram": REPO / "concept_art/wisp_rush_playable_characters_v2/assets/bram_rig_source.png",
}

# Newer packs ship one transparent PNG per rig group plus a `manifest.json` of pivots, so there is
# nothing to cut: the art is ingested verbatim (re-cropping would invalidate every pivot) and only
# checked. `tools/art/build_character_rig.py` turns the same manifest into the rig scene.
PART_PACKS: Dict[str, Path] = {
	"ilyra": REPO / "concept_art/wisp_rush_playable_characters_v3/parts/ilyra",
}
# Parts that bend on a bone chain at runtime; their spine runs straight from pivot to tip, because
# the pack authors every hanging part vertically at rest.
PACK_RIBBONS: Dict[str, List[str]] = {
	"ilyra": ["braid_l", "braid_r", "sash_1", "sash_2", "sash_3", "sash_4"],
}

# Some approved sheets isolate a part only inside a turnaround pose (Ilyra's torso sits between four
# arms and two braids). A mask polygon, in sheet pixels, cuts that silhouette out before the usual
# component cleanup runs; the painted pixels inside it are never altered.
# Some approved sheets isolate a part only inside a turnaround pose. A mask polygon, in sheet pixels,
# cuts that silhouette out before the usual component cleanup runs; the painted pixels inside it are
# never altered. (Ilyra needed this for her v2 torso; she ships from a per-file pack now.)
MASKS: Dict[str, Dict[str, Polygon]] = {
}

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
	# Bram's separated-components row carries every rig group he needs. His two effect layers are cut
	# from the action poses, where a high `min_area` keeps the painted arc and drops the knight
	# fragments that share the cell.
	"bram": {
		"preview": ((20, 26, 640, 767), 1500),
		"helmet": ((30, 787, 171, 943), 900),
		# Visor and chest gem are drawn again over their own painted pixels, so brightening their
		# modulate lights them up without a second additive shape showing at rest.
		"visor": ((58, 870, 137, 910), 200),
		"torso": ((259, 795, 414, 989), 900),
		"chest_core": ((316, 830, 359, 883), 200),
		"arm_upper_left": ((427, 797, 519, 884), 500),
		"arm_lower_left": ((427, 876, 519, 982), 500),
		"arm_upper_right": ((524, 792, 620, 880), 500),
		"arm_lower_right": ((524, 872, 620, 982), 500),
		"shield": ((629, 790, 795, 971), 900),
		"blade": ((803, 782, 908, 978), 700),
		"leg_left": ((920, 794, 1018, 975), 700),
		"leg_right": ((1071, 792, 1170, 975), 700),
		"cape_left": ((1178, 777, 1339, 968), 900),
		"cape_right": ((1353, 777, 1509, 968), 900),
		"blade_arc": ((1062, 442, 1124, 622), 800),
		"dash_streak": ((985, 575, 1068, 655), 600),
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
	"""Label 8-connected regions of [param mask]; returns labels and area per label (index 0 unused)."""
	labels, count = ndimage.label(mask, structure=np.ones((3, 3), dtype=int))
	if count == 0:
		return labels, [0]
	areas: List[int] = np.bincount(labels.ravel(), minlength=count + 1).tolist()
	areas[0] = 0
	return labels, areas


def extract_part(
	sheet: Image.Image, box: Box, min_area: int, mask: Optional[Polygon] = None
) -> Image.Image:
	part = sheet.crop(box).convert("RGBA")
	if mask is not None:
		# Cut the authored silhouette out of the pose before cleanup, in cell-local pixels.
		local = [(x - box[0], y - box[1]) for x, y in mask]
		stencil = Image.new("L", part.size, 0)
		ImageDraw.Draw(stencil).polygon(local, fill=255)
		part.putalpha(Image.composite(part.getchannel("A"), Image.new("L", part.size), stencil))
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
	# A speck closer to the root hint than the ribbon body would strand the walk on a few pixels
	# (Ilyra's braids carry a loose hair wisp above the clasp), so only the painted body is walked.
	labels, areas = label_components(mask)
	bodies: List[int] = [index for index in range(1, len(areas)) if areas[index] > 0]
	if bodies:
		mask = labels == max(bodies, key=lambda index: areas[index])
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


def ingest_pack(name: str) -> None:
	"""Copies a per-file part pack into the runtime folder, verifying it and printing ribbon spines.

	The pack's `manifest.json` gives each part's pivot in its own pixel space, so the PNGs are copied
	byte for byte: trimming or padding them here would silently move every joint in the rig.
	"""
	source: Path = PART_PACKS[name]
	manifest_path: Path = source / "manifest.json"
	if not manifest_path.exists():
		raise FileNotFoundError(manifest_path)
	manifest = json.loads(manifest_path.read_text())
	parts: Dict = manifest["parts"]
	out_dir = OUTPUT / name
	out_dir.mkdir(parents=True, exist_ok=True)
	outputs: Dict[str, Image.Image] = {}
	problems: List[str] = []
	for part in sorted(parts):
		spec = parts[part]
		art_path: Path = source / spec["file"]
		if not art_path.exists():
			raise FileNotFoundError(art_path)
		art = Image.open(art_path)
		if art.mode != "RGBA":
			problems.append("%s is %s, not RGBA" % (part, art.mode))
		art = art.convert("RGBA")
		if np.asarray(art.getchannel("A")).max() == 0:
			problems.append("%s is fully transparent" % part)
		pivot = spec["pivot"]
		if not (0 <= pivot[0] < art.width and 0 <= pivot[1] < art.height):
			problems.append("%s pivot %s falls outside %s" % (part, pivot, art.size))
		shutil.copyfile(art_path, out_dir / spec["file"])
		outputs[part] = art
	if problems:
		raise SystemExit("Pack %s failed verification:\n  %s" % (name, "\n  ".join(problems)))
	shutil.copyfile(manifest_path, out_dir / "manifest.json")
	outputs["preview"] = build_pack_preview(name, source, out_dir)
	spines: Dict[str, List] = {}
	for part in PACK_RIBBONS.get(name, []):
		spec = parts[part]
		spines[part] = straight_spine(spec["pivot"], spec["tip"], SPINE_POINTS)
	contact = make_contact(name, outputs, spines)
	print("PLAYABLE ART: %d %s parts (pack) -> %s" % (len(outputs), name, out_dir))
	for part, points in spines.items():
		values = ", ".join("%d, %d" % (round(px), round(py)) for px, py in points)
		print("  SPINE %s/%s: PackedVector2Array(%s)" % (name, part, values))
	print("  CONTACT: %s" % contact)


def build_pack_preview(name: str, source: Path, out_dir: Path) -> Image.Image:
	"""Derives the character's portrait from the pack's assembly reference.

	`FormData.texture` is the HUD portrait and the Shop card art. A part pack has no single picture of
	the character, but its assembly reference is exactly one: every part composited into the neutral
	rest pose on transparent. Trimming that to content gives a portrait that always matches the rig.
	"""
	assembly: Path = source.parent.parent / "assembly" / ("%s_assembly_reference.png" % name)
	if not assembly.exists():
		raise FileNotFoundError(assembly)
	art = Image.open(assembly).convert("RGBA")
	content = art.getchannel("A").point(lambda value: 255 if value >= 3 else 0).getbbox()
	if content is None:
		raise RuntimeError("assembly reference for %s is empty" % name)
	art = art.crop((
		max(0, content[0] - 8), max(0, content[1] - 8),
		min(art.width, content[2] + 8), min(art.height, content[3] + 8),
	))
	art.save(out_dir / "preview.png", optimize=True)
	return art


def straight_spine(pivot: List[int], tip: List[int], count: int) -> List[Tuple[float, float]]:
	"""Evenly spaced centre line from pivot to tip, for a part authored straight at rest."""
	return [
		(
			pivot[0] + (tip[0] - pivot[0]) * index / float(count - 1),
			pivot[1] + (tip[1] - pivot[1]) * index / float(count - 1),
		)
		for index in range(count)
	]


def extract_character(name: str) -> None:
	source = SOURCE_SHEETS.get(name, SOURCES / ("%s_rig_source.png" % name))
	if not source.exists():
		raise FileNotFoundError(source)
	out_dir = OUTPUT / name
	out_dir.mkdir(parents=True, exist_ok=True)
	sheet = Image.open(source).convert("RGBA")
	masks: Dict[str, Polygon] = MASKS.get(name, {})
	outputs: Dict[str, Image.Image] = {}
	for part, (box, min_area) in CHARACTERS[name].items():
		art = extract_part(sheet, box, min_area, masks.get(part))
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
	known: List[str] = list(CHARACTERS) + [n for n in PART_PACKS if n not in CHARACTERS]
	for name in names or known:
		if name in PART_PACKS:
			ingest_pack(name)
		elif name in CHARACTERS:
			extract_character(name)
		else:
			raise SystemExit("Unknown character %r (known: %s)" % (name, ", ".join(known)))


if __name__ == "__main__":
	main(sys.argv[1:])
