#!/usr/bin/env python3
"""Extract Noxen's approved detached-part sheet into a versioned rig source pack.

The generated sheet is deliberately arranged as twelve isolated groups, but the paintings do not
sit on a mathematically perfect grid. These authored regions therefore stay explicit: re-running
this script produces the same tight RGBA cut-outs, pivots and assembly manifest every time.

    python concept_art/noxen_v1/extract_parts.py
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Tuple

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage


ROOT = Path(__file__).resolve().parent
SHEET = ROOT / "noxen_parts_sheet.png"
OUTPUT = ROOT / "parts" / "noxen"
PADDING = 8

Box = Tuple[int, int, int, int]

# (source region, global rest position, parent, draw order, pivot kind)
PARTS: Dict[str, Tuple[Box, Tuple[int, int], str | None, int, str]] = {
	"rear_cloak": ((20, 0, 425, 395), (0, 10), None, 10, "center"),
	"hood": ((425, 0, 820, 365), (0, -215), "rear_cloak", 45, "center"),
	"mask": ((820, 45, 1110, 345), (0, -205), "hood", 52, "center"),
	"chest_core": ((1110, 45, 1425, 345), (0, -42), "rear_cloak", 56, "center"),
	"cloak_fin_l": ((20, 350, 415, 735), (-125, -5), "rear_cloak", 24, "top_inner_l"),
	"cloak_fin_r": ((420, 350, 815, 735), (125, -5), "rear_cloak", 24, "top_inner_r"),
	"front_flap": ((820, 350, 1080, 735), (0, 112), "rear_cloak", 40, "top"),
	"shadow_tail": ((1100, 350, 1425, 750), (0, 178), "rear_cloak", 8, "top"),
	"veilflame_l": ((40, 690, 365, 1086), (-115, -385), "hood", 16, "bottom"),
	"veilflame_r": ((430, 690, 770, 1086), (115, -385), "hood", 16, "bottom"),
	"root_ribbon_l": ((800, 690, 1115, 1086), (-66, 320), "shadow_tail", 13, "top"),
	"root_ribbon_r": ((1120, 690, 1448, 1086), (66, 320), "shadow_tail", 13, "top"),
}


def tight_crop(sheet: Image.Image, region: Box) -> Image.Image:
	"""Crop one authored region to visible pixels while retaining a small antialiasing gutter."""
	cut = sheet.crop(region)
	# A few neighbouring wisps cross the loose authoring boxes. They always enter through the box
	# edge; the intended component and its detached accent sparks do not. Removing edge-connected
	# islands keeps those sparks while preventing a shard from one cell leaking into another part.
	alpha = np.asarray(cut.getchannel("A"))
	labels, count = ndimage.label(alpha >= 3)
	keep = np.zeros_like(alpha, dtype=bool)
	for label in range(1, count + 1):
		ys, xs = np.nonzero(labels == label)
		if xs.size == 0:
			continue
		touches_edge = xs.min() == 0 or ys.min() == 0 or xs.max() == cut.width - 1 or ys.max() == cut.height - 1
		if not touches_edge:
			keep[ys, xs] = True
	clean_alpha = np.where(keep, alpha, 0).astype(np.uint8)
	cut.putalpha(Image.fromarray(clean_alpha, mode="L"))
	bounds = cut.getchannel("A").point(lambda value: 255 if value >= 3 else 0).getbbox()
	if bounds is None:
		raise RuntimeError("empty Noxen source region %r" % (region,))
	left = max(0, bounds[0] - PADDING)
	top = max(0, bounds[1] - PADDING)
	right = min(cut.width, bounds[2] + PADDING)
	bottom = min(cut.height, bounds[3] + PADDING)
	return cut.crop((left, top, right, bottom))


def pivot_for(size: Tuple[int, int], kind: str) -> Tuple[int, int]:
	w, h = size
	if kind == "top":
		return (w // 2, min(h - 1, 14))
	if kind == "bottom":
		return (w // 2, max(0, h - 14))
	if kind == "top_inner_l":
		return (max(0, w - 42), min(h - 1, 28))
	if kind == "top_inner_r":
		return (min(w - 1, 42), min(h - 1, 28))
	return (w // 2, h // 2)


def make_vfx() -> Dict[str, Image.Image]:
	"""Small cyan marks used by the rig's bounded trail, dash and state-change emitters."""
	results: Dict[str, Image.Image] = {}

	mote = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
	draw = ImageDraw.Draw(mote)
	draw.ellipse((6, 6, 42, 42), fill=(33, 193, 255, 28))
	draw.polygon(((24, 5), (30, 20), (43, 24), (30, 28), (24, 43), (18, 28), (5, 24), (18, 20)), fill=(136, 239, 255, 220))
	draw.ellipse((20, 20, 28, 28), fill=(245, 255, 255, 255))
	results["vfx_mote"] = mote

	streak = Image.new("RGBA", (96, 28), (0, 0, 0, 0))
	draw = ImageDraw.Draw(streak)
	draw.polygon(((2, 14), (78, 5), (94, 14), (78, 23)), fill=(40, 199, 255, 62))
	draw.polygon(((16, 14), (78, 10), (92, 14), (78, 18)), fill=(174, 246, 255, 225))
	results["vfx_streak"] = streak

	shard = Image.new("RGBA", (44, 68), (0, 0, 0, 0))
	draw = ImageDraw.Draw(shard)
	draw.polygon(((22, 2), (39, 30), (24, 66), (6, 34)), fill=(51, 196, 255, 96))
	draw.polygon(((22, 8), (31, 31), (22, 56), (13, 32)), fill=(201, 250, 255, 238))
	results["vfx_shard"] = shard
	return results


def main() -> None:
	if not SHEET.exists():
		raise FileNotFoundError(SHEET)
	OUTPUT.mkdir(parents=True, exist_ok=True)
	sheet = Image.open(SHEET).convert("RGBA")
	manifest_parts: Dict[str, Dict] = {}

	for name, (region, rest, parent, order, pivot_kind) in PARTS.items():
		art = tight_crop(sheet, region)
		filename = name + ".png"
		art.save(OUTPUT / filename, optimize=True)
		pivot = pivot_for(art.size, pivot_kind)
		spec: Dict = {
			"file": filename,
			"pivot": list(pivot),
			"rest_position": list(rest),
			"rest_rotation_deg": 0,
			"draw_order": order,
			"parent": parent,
			"assembly_visible": True,
		}
		if name.startswith("root_ribbon"):
			spec["tip"] = [art.width // 2, max(0, art.height - 8)]
		manifest_parts[name] = spec

	for name, art in make_vfx().items():
		filename = name + ".png"
		art.save(OUTPUT / filename, optimize=True)
		manifest_parts[name] = {
			"file": filename,
			"pivot": [art.width // 2, art.height // 2],
			"rest_position": [0, 0],
			"rest_rotation_deg": 0,
			"draw_order": 0,
			"parent": None,
			"assembly_visible": False,
		}

	manifest = {
		"character": "noxen",
		"canvas": {"reference_height_px": 1086},
		"coordinate_system": "Godot 2D: +x right, +y down; rest positions are relative to collision centre",
		"parts": manifest_parts,
		"assembly": {
			"canvas_size": [900, 1180],
			"collision_centre": [450, 540],
			"alternate_layers_hidden": ["vfx_mote", "vfx_streak", "vfx_shard"],
			"mirrored_instances": [],
		},
	}
	(OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print("NOXEN SOURCE: %d rig parts + 3 VFX -> %s" % (len(PARTS), OUTPUT))


if __name__ == "__main__":
	main()
