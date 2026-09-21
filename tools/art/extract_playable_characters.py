#!/usr/bin/env python3
"""Extract layered playable-character art from approved transparent source sheets.

The generated sources stay under ``concept_art/wisp_rush_playable_characters_v1/assets/``. Runtime
PNGs are deterministic fixed-cell extracts with isolated-alpha cleanup, so the game never uses a
complete concept sheet. Each run also writes a QA contact sheet per character to
``logs/playable_characters/<id>_parts.png`` and prints the ribbon spines the rigs use.

Requirements: Python 3.7+, Pillow 9.5, numpy 1.21 and scipy 1.7.

    python3 tools/art/extract_playable_characters.py              # every character
    python3 tools/art/extract_playable_characters.py rook morrow  # only these
    python3 tools/art/extract_playable_characters.py ilyra           # a whole-pose pack
    python3 tools/art/extract_playable_characters.py verdant_shade   # a packed sheet pack
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

## Widest texture every device is guaranteed to accept; each packed sheet stays inside it.
MAX_TEXTURE = 4096
## How close to a frame's border a detached piece has to sit, as a share of the frame, to count as
## severed rather than as part of the character. See `strip_clipped_fragments`.
CLIP_MARGIN_SHARE = 0.05
## Transparent gutter around every packed cell, in sheet pixels.
##
## Without it a frame whose art reaches its cell edge bleeds into its neighbour: the canvas texture
## filter samples half a texel outside the atlas region, so the player sees a sliver of a *different*
## frame stuck to the edge of the current one. Verdant Shade's first pack measured a 0 px margin on
## some cells and did exactly that on the phone. Eight pixels is more than any linear tap or the
## importer's `fix_alpha_border` expansion can reach.
CELL_PADDING = 8

Box = Tuple[int, int, int, int]
Polygon = List[Tuple[int, int]]

# Source packs are versioned: v1 characters keep their original sheet (and therefore byte-identical
# output), while later packs point at their own approved rig source. `tools/art/make_rig_source.py`
# builds these transparent sheets from the opaque approved references.
## Empty since 2026-09-20: the two characters that used a rig source sheet (Ilyra, Bram) were
## retired, and Noxen ships as a per-file part pack. Kept as the seam for the next sheet pack.
SOURCE_SHEETS: Dict[str, Path] = {}

# Newer packs ship one transparent PNG per rig group plus a `manifest.json` of pivots, so there is
# nothing to cut: the art is ingested verbatim (re-cropping would invalidate every pivot) and only
# checked. `tools/art/build_character_rig.py` turns the same manifest into the rig scene.
PART_PACKS: Dict[str, Path] = {
	"noxen": REPO / "concept_art/noxen_v1/parts/noxen",
}
# Parts that bend on a bone chain at runtime; their spine runs straight from pivot to tip, because
# the pack authors every hanging part vertically at rest.
PACK_RIBBONS: Dict[str, List[str]] = {
	"noxen": ["root_ribbon_l", "root_ribbon_r"],
}

# A pose pack is a different kind of input: not parts of a rig, but one finished painting per
# animation state. Nothing is cut - the approved PNGs are copied byte for byte - and the extractor
# only measures where the figure sits inside each equally sized canvas, so the runtime can put every
# pose on the same anchor at the same apparent height (`CharacterPoseSheet`).
POSE_PACKS: Dict[str, Dict[str, object]] = {
	"ilyra": {
		"source": REPO / "concept_art/ilyra_2_sprite_test/final_sprites",
		"sheet": REPO / "data/characters/ilyra_poses.tres",
		"poses": [
			"idle_hover", "idle_blink", "move_fly_00", "move_fly_01", "aim_charge",
			"dash_start_00", "dash_start_01", "dash_loop_00", "dash_loop_01_attack", "dash_end",
			"hit_reaction", "death", "revive_spawn", "victory",
			"character_selected", "character_unlocked",
			"wall_bottom", "wall_top", "wall_left", "wall_right",
		],
	},
}

# Apparent-height corrections, measured by matching the character's head across the pack (normalized
# cross-correlation over scale and rotation, seeded from the idle pose) and rounded to 1 %. Only a
# pose the generator drew at a different size gets one: `wall_top` is painted inside extra padding at
# 0.84 of the pack's size, the single deviation the pack's own review notes call out.
POSE_SCALES: Dict[str, Dict[str, float]] = {
	"ilyra": {"wall_top": 1.19},
}
# Authored drawing offsets, in pixels, for a pose the pack frames wrongly. Empty is the normal
# answer and the measured one for `ilyra`: the pack paints every pose from one camera with the
# character's feet toward the bottom of the canvas, so the canvas centre already *is* the anchor.
# Chasing each pose's silhouette box instead would be worse than doing nothing, because that box
# moves with the pose - a crouch lowers the head while the feet stay put - and following it lifts
# a crouching character off the surface she is crouching on. Every pose's measured drift is
# written into the sheet so a review can see what is left and author a correction here.
POSE_OFFSETS: Dict[str, Dict[str, Tuple[float, float]]] = {
	"ilyra": {},
}
# Alpha above which a pixel counts as the painted figure rather than its glow.
POSE_CORE_ALPHA: int = 200

# Ornaments are the loose pieces that drift around a character rather than being painted into
# her: her own crown shards, sparkles and chest gem, plus the slash she cuts with. They go into
# an `ornaments/` sub-folder so nothing confuses them with the poses.
#
# The detached kit ships two files under swapped names - `dash_slash.png` is a pair of small
# sparkles and `sparkle_pair.png` is the big slash arc - so the intake renames them on the way
# in rather than carrying the mistake into the game.
ORNAMENT_PACKS: Dict[str, Dict[str, object]] = {
	"ilyra": {
		"source": REPO / "concept_art/ilyra_2_sprite_test/detached_parts/sprites/secondary_motion",
		"parts": {
			"sparkle_small.png": "sparkle_00.png",
			"sparkle_large.png": "sparkle_01.png",
			"sparkle_twin.png": "dash_slash.png",
			"crown_center.png": "crown_center.png",
			"crown_shard_l.png": "crown_side_a.png",
			"crown_shard_r.png": "crown_side_b.png",
			"chest_gem_glow.png": "chest_gem_glow.png",
			"slash_arc.png": "sparkle_pair.png",
		},
	},
}

# Ilyra 2's figure cut into body parts. Same verbatim copy as the ornaments, into its own
# sub-folder. NOTHING LOADS THESE RIGHT NOW: the jointed menu puppet built from them was reverted on
# 2026-09-20 (DEVLOG) in favour of more registered frames. Kept because the intake is deterministic
# and the parts are the material if part-level motion is revisited. Each limb carries gold caps at
# its joints, so shoulder, elbow and wrist are findable by colour rather than by eye.
PUPPET_PACKS: Dict[str, Dict[str, object]] = {
	"ilyra": {
		"source": REPO / "concept_art/ilyra_2_sprite_test/detached_parts/sprites",
		"parts": {
			"upper_body": [
				"head", "torso",
				"upper_arm_00", "upper_arm_01", "upper_arm_02", "upper_arm_03",
				"forearm_00", "forearm_01", "forearm_02", "forearm_03",
				"hand_grip_a", "hand_grip_b", "hand_relaxed_a", "hand_relaxed_b",
			],
			"lower_body": [
				"waist_armor", "underskirt", "hip_flap_a", "hip_flap_b",
				"upper_leg_a", "upper_leg_b", "lower_leg_boot_a", "lower_leg_boot_b",
			],
			"secondary_motion": ["fan_open_a", "fan_open_b", "braid_a", "braid_b"],
		},
	},
}

# Whole frames of a menu loop, copied verbatim onto their own stable canvas.
FRAME_PACKS: Dict[str, Dict[str, object]] = {
	"ilyra": {
		"source": REPO / "concept_art/ilyra_2_sprite_test/detached_parts/storefront_frames",
		"folder": "storefront",
		"frames": [
			"storefront_welcome.png",
			"storefront_blink.png",
			"storefront_flourish.png",
			"storefront_settle.png",
		],
	},
}

# A sheet pack is the whole-frame character intake (docs/guides/character_sprite_frames.md): one
# numbered PNG per frame in, packed atlas sheets plus ready-made `SpriteFrames` out. The pack's own
# JSON is the authority for row order, frame counts, fps and looping, so nothing is retyped here and
# a mismatch is an error rather than a silent truncation.
#
# Two sheets, not one: the split is the memory split the Shop needs - `menu` is all Home and a Shop
# card ever load, `run` is all a run ever loads. It was three until the animation set was cut to
# five on 2026-09-20 and the reaction sheet had nothing left on it.
SHEET_PACKS: Dict[str, Dict[str, object]] = {
	"verdant_shade": {
		"source": REPO / "concept_art/verdant_shade_sprite_v1/frames/verdant_shade",
		"manifest": REPO
		/ "concept_art/verdant_shade_sprite_v1/sheets/verdant_shade_sprite_sheet.json",
		# Cells are smaller than the delivered frames on purpose: the character draws at ~230 px in a
		# run and ~520 px on a Shop card, so 512 and 724 are downscaled once, here, deterministically.
		# The menu cell was 576 and cost a 3552 px square, ~50 MB to upload the first time a Shop
		# card woke it - owner saw a half-second hitch on the phone. She draws at ~520 px on a card,
		# so 512 is still about 1:1 and the sheet drops to 3168 px.
		"cells": {"run": 384, "menu": 448},
		# Looping animations play this much faster than the pack authored them. Owner feedback on
		# the phone, 2026-09-20: the idles read as steps rather than motion. It is a compromise, not
		# a fix - a 12-frame loop is simply few - and the real answer is more frames per loop. The
		# one-shots are deliberately NOT scaled: their rates are matched to the state lengths in
		# `PlayableCharacterVisual.STATE_LENGTHS`, so speeding them up would end them early.
		"loop_fps_scale": 1.4,
		"columns": {"run": 8, "menu": 6},
		# Five animations, and no more (owner, 2026-09-20): the dash - which is also the attack -
		# the three wall loops the player spends most of a run looking at, and one storefront idle
		# for Home and the Shop card. Every other state resolves onto one of these in
		# `WholeFrameCharacterVisual._target_animation`. The cut frames are still in the pack, so
		# restoring one is a name in this list and a re-pack.
		"sheets": {
			"run": ["dash_loop", "wall_bottom", "wall_top", "wall_left"],
			"menu": ["storefront_idle"],
		},
		# Which sheets each generated `SpriteFrames` draws from, and where that resource is written.
		"resources": {
			"gameplay": (["run"], REPO / "data/characters/verdant_shade_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/verdant_shade_menu.tres"),
		},
		# Menu frames live in their own sub-folder of the pack.
		"menu_source": "storefront",
		# This pack's frames are cut from phase atlases and the cut catches a sliver of the
		# neighbouring cell; see `strip_floating_strays`. OFF by default and enabled only here,
		# because on a clean pack the same rule would amputate anything the character legitimately
		# floats above itself - Void's flame plumes lose their tips to it.
		"strip_strays": True,
	},
	"void": {
		"source": REPO / "concept_art/void_wisp_sprite_v1/frames/void_wisp",
		"manifest": REPO / "concept_art/void_wisp_sprite_v1/sheets/void_wisp_sprite_sheet.json",
		"cells": {"run": 384, "menu": 448},
		"columns": {"run": 8, "menu": 6},
		# Five animations, and no more (owner, 2026-09-20): the dash - which is also the attack -
		# the three wall loops the player spends most of a run looking at, and one storefront idle
		# for Home and the Shop card. Every other state resolves onto one of these in
		# `WholeFrameCharacterVisual._target_animation`. The cut frames are still in the pack, so
		# restoring one is a name in this list and a re-pack.
		"sheets": {
			"run": ["dash_loop", "wall_bottom", "wall_top", "wall_left"],
			"menu": ["storefront_idle"],
		},
		"resources": {
			"gameplay": (["run"], REPO / "data/characters/void_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/void_menu.tres"),
		},
		"menu_source": "storefront",
		# The pack registers to 0.5 px; its loops play at the authored rate until the owner says
		# otherwise on a device. It does need de-clipping: 21 of its frames draw the character
		# larger than the 512 canvas and the top edge severs the crystal above its head.
		"loop_fps_scale": 1.0,
		"strip_clipped": True,
	},
	"eclipse": {
		"source": REPO / "concept_art/eclipse_wisp_sprite_v1/frames/eclipse_wisp",
		"manifest": REPO
		/ "concept_art/eclipse_wisp_sprite_v1/sheets/eclipse_wisp_sprite_sheet.json",
		"cells": {"run": 384, "menu": 448},
		"columns": {"run": 8, "menu": 6},
		# Five animations, and no more (owner, 2026-09-20): the dash - which is also the attack -
		# the three wall loops the player spends most of a run looking at, and one storefront idle
		# for Home and the Shop card. Every other state resolves onto one of these in
		# `WholeFrameCharacterVisual._target_animation`. The cut frames are still in the pack, so
		# restoring one is a name in this list and a re-pack.
		"sheets": {
			"run": ["dash_loop", "wall_bottom", "wall_top", "wall_left"],
			"menu": ["storefront_idle"],
		},
		"resources": {
			"gameplay": (["run"], REPO / "data/characters/eclipse_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/eclipse_menu.tres"),
		},
		"menu_source": "storefront",
		# The cleanest pack of the three: registered to 0.5 px and not one frame reaches a border,
		# so neither cleanup is enabled. Its orbiting moon beads are detached by design and must be
		# left alone - `strip_clipped` would be the thing that ate them.
		"loop_fps_scale": 1.0,
	},
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


def ingest_pose_pack(name: str) -> None:
	"""Copies an approved whole-pose sprite pack into the runtime folder and measures its anchors.

	Every pose is one finished painting on the same square canvas, so there is nothing to cut: the
	PNGs are copied byte for byte. What the runtime cannot know is that the figure is framed a little
	differently in each one, so this also writes a `CharacterPoseSheet` holding, per pose, the drawing
	offset that puts its silhouette back on the collision-centre anchor and the scale that keeps its
	apparent height constant.
	"""
	spec = POSE_PACKS[name]
	source: Path = spec["source"]  # type: ignore[assignment]
	poses: List[str] = list(spec["poses"])  # type: ignore[arg-type]
	scales: Dict[str, float] = POSE_SCALES.get(name, {})
	authored: Dict[str, Tuple[float, float]] = POSE_OFFSETS.get(name, {})
	out_dir = OUTPUT / name
	out_dir.mkdir(parents=True, exist_ok=True)
	outputs: Dict[str, Image.Image] = {}
	offsets: List[Tuple[float, float]] = []
	drifts: List[Tuple[float, float]] = []
	problems: List[str] = []
	frame_size: Optional[int] = None
	for pose in poses:
		art_path = source / (pose + ".png")
		if not art_path.exists():
			raise FileNotFoundError(art_path)
		art = Image.open(art_path)
		if art.mode != "RGBA":
			problems.append("%s is %s, not RGBA" % (pose, art.mode))
		art = art.convert("RGBA")
		if art.width != art.height:
			problems.append("%s is %dx%d, not square" % (pose, art.width, art.height))
		if frame_size is None:
			frame_size = art.width
		elif art.width != frame_size:
			problems.append("%s is %d px, but the pack is %d px" % (pose, art.width, frame_size))
		alpha = np.asarray(art.getchannel("A"))
		if alpha.max() == 0:
			problems.append("%s is fully transparent" % pose)
			drifts.append((0.0, 0.0))
		else:
			drifts.append(silhouette_drift(alpha))
		offsets.append(authored.get(pose, (0.0, 0.0)))
		shutil.copyfile(art_path, out_dir / (pose + ".png"))
		outputs[pose] = art
	for pose in authored:
		if pose not in outputs:
			problems.append("authored offset for unknown pose %s" % pose)
	if problems:
		raise SystemExit("Pose pack %s failed verification:\n  %s" % (name, "\n  ".join(problems)))
	sheet_path: Path = spec["sheet"]  # type: ignore[assignment]
	write_pose_sheet(sheet_path, poses, offsets, drifts, scales, float(frame_size or 0))
	contact = make_contact(name, outputs, {})
	print("PLAYABLE ART: %d %s poses (sprite pack) -> %s" % (len(outputs), name, out_dir))
	print("  SHEET: %s" % sheet_path.relative_to(REPO))
	for pose, offset, drift in zip(poses, offsets, drifts):
		scale = scales.get(pose, 1.0)
		print("    %-20s drift (%+5.1f, %+5.1f)  offset (%+.0f, %+.0f)  scale %.2f" % (
			pose, drift[0], drift[1], offset[0], offset[1], scale,
		))
	print("  CONTACT: %s" % contact)


def clear_invisible_rgb(art: Image.Image) -> Image.Image:
	"""Zeroes the colour under fully transparent pixels.

	The generator leaves the whole painting's colour behind alpha 0. It is invisible on its own, but
	Godot's importer runs `fix_alpha_border`, which bleeds edge colour outward - and it bleeds far
	cleaner from a transparent region that carries nothing than from one carrying a stale silhouette.
	The project's v3 part pack holds the same rule ("zero RGB below alpha 0").
	"""
	pixels = np.array(art)
	pixels[pixels[:, :, 3] == 0, :3] = 0
	return Image.fromarray(pixels, "RGBA")


def ingest_ornaments(name: str) -> None:
	"""Copies a character's loose ornaments into `<id>/ornaments/`, renaming the mislabelled ones."""
	spec = ORNAMENT_PACKS[name]
	source: Path = spec["source"]  # type: ignore[assignment]
	parts: Dict[str, str] = spec["parts"]  # type: ignore[assignment]
	out_dir = OUTPUT / name / "ornaments"
	out_dir.mkdir(parents=True, exist_ok=True)
	outputs: Dict[str, Image.Image] = {}
	for target in sorted(parts):
		art_path = source / parts[target]
		if not art_path.exists():
			raise FileNotFoundError(art_path)
		art = clear_invisible_rgb(Image.open(art_path).convert("RGBA"))
		if np.asarray(art.getchannel("A")).max() == 0:
			raise SystemExit("Ornament %s is fully transparent" % target)
		art.save(out_dir / target, optimize=True)
		outputs[target[:-4]] = art
	contact = make_contact("%s_ornaments" % name, outputs, {})
	print("PLAYABLE ART: %d %s ornaments -> %s" % (len(outputs), name, out_dir))
	for target in sorted(parts):
		if target != parts[target]:
			print("    %-20s <- %s (renamed)" % (target, parts[target]))
	print("  CONTACT: %s" % contact)


def ingest_puppet(name: str) -> None:
	"""Copies a menu puppet's body parts into `<id>/puppet/`, colour cleared under alpha 0."""
	spec = PUPPET_PACKS[name]
	source: Path = spec["source"]  # type: ignore[assignment]
	groups: Dict[str, List[str]] = spec["parts"]  # type: ignore[assignment]
	out_dir = OUTPUT / name / "puppet"
	out_dir.mkdir(parents=True, exist_ok=True)
	outputs: Dict[str, Image.Image] = {}
	for group in sorted(groups):
		for file in groups[group]:
			art_path = source / group / ("%s.png" % file)
			if not art_path.exists():
				raise FileNotFoundError(art_path)
			art = clear_invisible_rgb(Image.open(art_path).convert("RGBA"))
			art.save(out_dir / ("%s.png" % file), optimize=True)
			outputs[file] = art
	contact = make_contact("%s_puppet" % name, outputs, {})
	print("PLAYABLE ART: %d %s puppet parts -> %s" % (len(outputs), name, out_dir))
	print("  CONTACT: %s" % contact)


def ingest_frames(name: str) -> None:
	"""Copies a menu loop's frames verbatim; their equal canvas is what keeps the pivot stable."""
	spec = FRAME_PACKS[name]
	source: Path = spec["source"]  # type: ignore[assignment]
	frames: List[str] = list(spec["frames"])  # type: ignore[arg-type]
	out_dir = OUTPUT / name / str(spec["folder"])
	out_dir.mkdir(parents=True, exist_ok=True)
	outputs: Dict[str, Image.Image] = {}
	size: Optional[Tuple[int, int]] = None
	for frame in frames:
		art_path = source / frame
		if not art_path.exists():
			raise FileNotFoundError(art_path)
		art = Image.open(art_path).convert("RGBA")
		if size is None:
			size = art.size
		elif art.size != size:
			raise SystemExit("Frame %s is %s, but the loop is %s" % (frame, art.size, size))
		shutil.copyfile(art_path, out_dir / frame)
		outputs[frame[:-4]] = art
	contact = make_contact("%s_%s" % (name, spec["folder"]), outputs, {})
	print("PLAYABLE ART: %d %s %s frames (%dx%d) -> %s" % (
		len(outputs), name, spec["folder"], size[0], size[1], out_dir,
	))
	print("  CONTACT: %s" % contact)


def silhouette_drift(alpha: np.ndarray) -> Tuple[float, float]:
	"""How far a pose's painted silhouette sits from the canvas centre, in pixels.

	Recorded for review and for the anchor checks, not corrected: the box around the *opaque* pixels
	moves with the pose (a crouch lowers the head but leaves the feet), so following it would drag a
	crouching character off the surface she is crouching on. `+ 0.0` normalises a negative zero.
	"""
	ys, xs = np.nonzero(alpha > POSE_CORE_ALPHA)
	centre = (alpha.shape[1] - 1) / 2.0
	return (
		round((float(xs.min()) + float(xs.max())) / 2.0 - centre, 1) + 0.0,
		round((float(ys.min()) + float(ys.max())) / 2.0 - centre, 1) + 0.0,
	)


def write_pose_sheet(
	path: Path,
	poses: List[str],
	offsets: List[Tuple[float, float]],
	drifts: List[Tuple[float, float]],
	scales: Dict[str, float],
	frame_size: float,
) -> None:
	"""Writes the measured anchors as the `CharacterPoseSheet` the game loads."""
	names = ", ".join('"%s"' % pose for pose in poses)
	points = ", ".join("%g, %g" % offset for offset in offsets)
	measured = ", ".join("%g, %g" % drift for drift in drifts)
	sizes = ", ".join("%g" % scales.get(pose, 1.0) for pose in poses)
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_text(
		'[gd_resource type="Resource" script_class="CharacterPoseSheet" load_steps=2 format=3]\n'
		"\n"
		'[ext_resource type="Script" path="res://scripts/resources/character_pose_sheet.gd" id="1"]\n'
		"\n"
		"[resource]\n"
		'script = ExtResource("1")\n'
		+ "pose_names = PackedStringArray(%s)\n" % names
		+ "pose_offsets = PackedVector2Array(%s)\n" % points
		+ "pose_drifts = PackedVector2Array(%s)\n" % measured
		+ "pose_scales = PackedFloat32Array(%s)\n" % sizes
		+ "frame_size = %g\n" % frame_size,
		encoding="utf-8",
		# The repo mandates LF; on Windows the default would translate these to CRLF.
		newline="\n",
	)


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


def strip_floating_strays(art: Image.Image) -> Tuple[Image.Image, int]:
	"""Removes anything drawn entirely above the body: it is the cell above, not this frame.

	The Verdant Shade pack's frames are cut out of phase atlases, and the cut takes a sliver of the
	neighbouring cell with it - a band of flame tips floating over the character's head, clearly
	severed. The owner saw it in a run and in the Shop. It is the *source* that is wrong (recorded as
	a follow-up against `concept_art/verdant_shade_sprite_v1/build_sprite_pack.py`); this is the
	intake refusing to carry the mistake into the game.

	The rule is narrow on purpose. Only a connected piece lying **wholly above the top of the largest
	piece** is dropped, so the leaves this character legitimately scatters around itself - in `death`
	and `revive_spawn` especially - are kept, and so is a body that runs off the canvas edge.
	"""
	pixels = np.asarray(art).copy()
	solid = pixels[:, :, 3] > 8
	labels, count = ndimage.label(solid)
	if count < 2:
		return art, 0
	sizes = ndimage.sum(solid, labels, range(1, count + 1))
	body = int(np.argmax(sizes)) + 1
	top = int(np.nonzero(labels == body)[0].min())
	strays: List[int] = []
	for index in range(1, count + 1):
		if index == body:
			continue
		rows = np.nonzero(labels == index)[0]
		if rows.max() < top:
			strays.append(index)
	if not strays:
		return art, 0
	mask = np.isin(labels, strays)
	pixels[mask] = 0
	return Image.fromarray(pixels, "RGBA"), int(mask.sum())


def strip_clipped_fragments(art: Image.Image) -> Tuple[Image.Image, int]:
	"""Removes a detached piece that the frame edge has cut through.

	A different defect from `strip_floating_strays`. Void's pack draws the character larger than its
	512 canvas in the dash, move and attack frames, so the crystal above its head is severed by the
	top edge: what is left is a flat-cut sliver that floats over the wisp in a run. The pixels are
	gone and cannot be recovered here, and a missing crystal reads better than a guillotined one.

	Only pieces that are BOTH detached from the body AND hugging the frame border go. A floating orb
	that sits clear of the border is the character's own design and stays - `move_fly_00` keeps a
	105 px orb and loses a 2,336 px severed one. The body is never removed, even when it runs off
	the edge.
	"""
	pixels = np.asarray(art).copy()
	solid = pixels[:, :, 3] > 8
	labels, count = ndimage.label(solid)
	if count < 2:
		return art, 0
	sizes = ndimage.sum(solid, labels, range(1, count + 1))
	body = int(np.argmax(sizes)) + 1
	# A margin, not the exact edge: the pack re-centres each frame's silhouette after cutting it, so
	# a severed piece ends up a few pixels short of the border it was cut by.
	margin = max(4, int(round(min(pixels.shape[0], pixels.shape[1]) * CLIP_MARGIN_SHARE)))
	clipped: List[int] = []
	for index in range(1, count + 1):
		if index == body:
			continue
		rows, columns = np.nonzero(labels == index)
		if (rows.min() < margin or rows.max() >= pixels.shape[0] - margin
				or columns.min() < margin or columns.max() >= pixels.shape[1] - margin):
			clipped.append(index)
	if not clipped:
		return art, 0
	mask = np.isin(labels, clipped)
	pixels[mask] = 0
	return Image.fromarray(pixels, "RGBA"), int(mask.sum())


def _sheet_pack_rows(spec: Dict[str, object]) -> Dict[str, Dict[str, object]]:
	"""Row order, frame count, fps and looping, read from the pack's own manifest."""
	manifest = json.loads(Path(str(spec["manifest"])).read_text(encoding="utf-8"))
	return {str(row["state"]): row for row in manifest["rows"]}


def ingest_sheet_pack(name: str) -> None:
	"""Packs a whole-frame character into atlas sheets and generates its `SpriteFrames`."""
	spec = SHEET_PACKS[name]
	source = Path(str(spec["source"]))
	menu_source = source / str(spec["menu_source"])
	rows = _sheet_pack_rows(spec)
	cells: Dict[str, int] = spec["cells"]  # type: ignore[assignment]
	columns: Dict[str, int] = spec["columns"]  # type: ignore[assignment]
	sheets: Dict[str, List[str]] = spec["sheets"]  # type: ignore[assignment]
	out_dir = OUTPUT / name
	out_dir.mkdir(parents=True, exist_ok=True)

	strip = bool(spec.get("strip_strays", False))  # type: ignore[union-attr]
	declip = bool(spec.get("strip_clipped", False))  # type: ignore[union-attr]
	placed: Dict[str, List[Tuple[str, int, int, int]]] = {}
	stripped: Dict[str, int] = {}
	drifts: List[Tuple[float, float]] = []
	frames_seen: List[str] = []
	preview: Dict[str, Image.Image] = {}
	for sheet, members in sheets.items():
		cell, wide = cells[sheet], columns[sheet]
		folder = menu_source if sheet == "menu" else source
		grid: List[Tuple[str, str, int, int]] = []
		row_index = 0
		for state in members:
			if state not in rows:
				raise SystemExit("%s: %s is not in the manifest" % (name, state))
			count = int(rows[state]["frames"])
			for frame in range(count):
				grid.append((state, "%s_%02d.png" % (state, frame),
							 row_index + frame // wide, frame % wide))
			row_index += (count + wide - 1) // wide
		pitch = cell + CELL_PADDING * 2
		size = (wide * pitch, row_index * pitch)
		if max(size) > MAX_TEXTURE:
			raise SystemExit("%s %s sheet would be %dx%d, over the %d px floor" % (
				name, sheet, size[0], size[1], MAX_TEXTURE))
		canvas = Image.new("RGBA", size, (0, 0, 0, 0))
		placed[sheet] = []
		for state, file, row, column in grid:
			art_path = folder / file
			if not art_path.exists() and folder is menu_source:
				# The menu sheet may carry a gameplay animation as well - the storefront idle test
				# puts `idle_hover` on it - and those frames live in the pack root.
				art_path = source / file
			if not art_path.exists():
				raise FileNotFoundError(art_path)
			art = Image.open(art_path).convert("RGBA")
			if art.width != art.height:
				raise SystemExit("%s is %s; a frame must be square" % (file, art.size))
			if strip:
				art, removed = strip_floating_strays(art)
				if removed:
					stripped[state] = stripped.get(state, 0) + removed
			if declip:
				art, removed = strip_clipped_fragments(art)
				if removed:
					stripped[state] = stripped.get(state, 0) + removed
			art = clear_invisible_rgb(art.resize((cell, cell), Image.LANCZOS))
			x, y = column * pitch + CELL_PADDING, row * pitch + CELL_PADDING
			canvas.paste(art, (x, y))
			placed[sheet].append((state, x, y, cell))
			# The anchor is the cell centre by construction; this records what is left so a review can
			# see it, exactly as the whole-pose packs do.
			drifts.append(silhouette_drift(np.asarray(art)[:, :, 3]))
			frames_seen.append(file[:-4])
			if file.endswith("_00.png"):
				preview[state] = art
		sheet_path = out_dir / ("%s_%s.png" % (name, sheet))
		canvas.save(sheet_path, optimize=True)
		print("PLAYABLE ART: %s %s sheet %dx%d, %d frames (%d px cells, %d px gutter) -> %s" % (
			name, sheet, size[0], size[1], len(placed[sheet]), cell, CELL_PADDING, sheet_path))

	# A standalone portrait, so the HUD icon and an unfocused Shop card never pull a whole sheet
	# into memory just to show one still.
	portrait = clear_invisible_rgb(
		Image.open(source / "idle_hover_00.png").convert("RGBA").resize(
			(cells["run"], cells["run"]), Image.LANCZOS))
	portrait.save(out_dir / ("%s_portrait.png" % name), optimize=True)
	print("PLAYABLE ART: %s portrait %dx%d -> %s" % (
		name, cells["run"], cells["run"], out_dir / ("%s_portrait.png" % name)))

	worst = max(drifts, key=lambda d: abs(d[0]) + abs(d[1]))
	print("  ANCHOR: worst residual drift %s px over %d frames" % (worst, len(drifts)))
	if stripped:
		total = sum(stripped.values())
		print("  CLEANUP: removed %d source pixels across %d states" % (
			total, len(stripped)))
		for state in sorted(stripped, key=lambda k: -stripped[k]):
			print("    %-22s %6d px" % (state, stripped[state]))
	scale = float(spec.get("loop_fps_scale", 1.0))  # type: ignore[union-attr]
	for key in dict(spec["resources"]):  # type: ignore[arg-type]
		members, path = dict(spec["resources"])[key]  # type: ignore[index]
		_write_sprite_frames(name, key, list(members), placed, rows, Path(str(path)), scale)
	write_pose_sheet(REPO / ("data/characters/%s_frames.tres" % name), frames_seen,
					 [(0.0, 0.0)] * len(frames_seen), drifts, {}, float(cells["run"]))
	print("  CONTACT: %s" % make_contact(name, preview, {}))


def _write_sprite_frames(
	name: str, key: str, members: List[str],
	placed: Dict[str, List[Tuple[str, int, int, int]]],
	rows: Dict[str, Dict[str, object]], path: Path, loop_scale: float = 1.0,
) -> None:
	"""Writes one `SpriteFrames` whose every frame is an `AtlasTexture` into the packed sheets."""
	textures: List[str] = []
	atlases: List[str] = []
	animations: Dict[str, List[str]] = {}
	for index, sheet in enumerate(members):
		ident = "%d_%s" % (index + 1, sheet)
		resource = (OUTPUT / name / ("%s_%s.png" % (name, sheet))).relative_to(REPO).as_posix()
		textures.append(
			'[ext_resource type="Texture2D" path="res://%s" id="%s"]' % (resource, ident))
		for order, (state, x, y, cell) in enumerate(placed[sheet]):
			atlas = "AtlasTexture_%s_%03d" % (sheet, order)
			atlases.append(
				'[sub_resource type="AtlasTexture" id="%s"]\n' % atlas
				+ 'atlas = ExtResource("%s")\n' % ident
				+ "region = Rect2(%d, %d, %d, %d)\n" % (x, y, cell, cell))
			animations.setdefault(state, []).append(atlas)
	blocks: List[str] = []
	for state, frames in animations.items():
		listed = ", ".join(
			'{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % atlas for atlas in frames)
		looping = bool(rows[state]["loop"])
		speed = float(rows[state]["fps"]) * (loop_scale if looping else 1.0)
		blocks.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.4g\n}' % (
			listed, "true" if looping else "false", state, speed))
	steps = len(textures) + len(atlases) + 1
	text = ('[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % steps
			+ "\n".join(textures) + "\n\n"
			+ "\n".join(atlases) + "\n"
			+ "[resource]\nanimations = [%s]\n" % ", ".join(blocks))
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_bytes(text.replace("\n", chr(10)).encode("utf-8"))
	print("  FRAMES: %s (%d animations, %d atlas regions, loops x%.2f) -> %s" % (
		key, len(animations), len(atlases), loop_scale, path.relative_to(REPO)))


def main(names: Optional[List[str]] = None) -> None:
	known: List[str] = list(CHARACTERS)
	known += [n for n in PART_PACKS if n not in known]
	known += [n for n in POSE_PACKS if n not in known]
	known += [n for n in SHEET_PACKS if n not in known]
	for name in names or known:
		if name in SHEET_PACKS:
			ingest_sheet_pack(name)
		elif name in PART_PACKS:
			ingest_pack(name)
		elif name in POSE_PACKS:
			ingest_pose_pack(name)
			if name in ORNAMENT_PACKS:
				ingest_ornaments(name)
			if name in PUPPET_PACKS:
				ingest_puppet(name)
			if name in FRAME_PACKS:
				ingest_frames(name)
		elif name in CHARACTERS:
			extract_character(name)
		else:
			raise SystemExit("Unknown character %r (known: %s)" % (name, ", ".join(known)))


if __name__ == "__main__":
	main(sys.argv[1:])
