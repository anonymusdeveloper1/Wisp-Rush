#!/usr/bin/env python3
"""Pack playable-character art: the whole-frame sheet packs (docs/guides/character_creation.md).

Runtime PNGs and `SpriteFrames` are generated, so the game never uses a complete concept sheet. Each
run also writes a QA contact sheet per character to ``logs/playable_characters/<id>_parts.png``.
The layered-rig intake (fixed-cell layer cuts, part packs, ribbon spines) was removed with Morrow,
the last bone rig, on 2026-10-05 (owner).

Requirements: Python 3.7+, Pillow 9.5 and numpy 1.21.

    python3 tools/art/extract_playable_characters.py              # every character
    python3 tools/art/extract_playable_characters.py patchvile     # only these
    python3 tools/art/extract_playable_characters.py scarlet         # a packed sheet pack
"""
import json
import shutil
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from PIL import Image, ImageDraw


REPO = Path(__file__).resolve().parents[2]
OUTPUT = REPO / "assets/art/characters/playable"
CONTACTS = REPO / "logs/playable_characters"

## Widest texture every device is guaranteed to accept; each packed sheet stays inside it.
MAX_TEXTURE = 4096
## Transparent gutter around every packed cell, in sheet pixels.
##
## Without it a frame whose art reaches its cell edge bleeds into its neighbour: the canvas texture
## filter samples half a texel outside the atlas region, so the player sees a sliver of a *different*
## frame stuck to the edge of the current one. A character pack once measured a 0 px margin on some
## cells and did exactly that on the phone. Eight pixels is more than any linear tap or the
## importer's `fix_alpha_border` expansion can reach.
CELL_PADDING = 8
## The flips a sheet pack's `derive` may ask for: `flip_v` turns a floor loop into a ceiling one,
## `flip_h` one side wall into the other.
FLIPS = {"flip_v": Image.FLIP_TOP_BOTTOM, "flip_h": Image.FLIP_LEFT_RIGHT}

## The roster size (owner, 2026-09-24; restored 2026-09-26): every AutoSprite character has
## Patchvile's pixel count and every character is the same size. In its 256 px frames the whole figure
## stands 194 px tall, measured on the first storefront frame from its highest point (hood, hair,
## crown) to its feet. AutoSprite keeps the proportions of the uploaded first frame exactly (his dash
## upload filled 77.2 % of its width, the frame 77.3 %), so Codex draws every first frame at that
## size. A pack with `"roster_scale": True` is then packed at Patchvile's exact scale instead of
## fitting its own frames, so the same pixel count means the same size and the same detail on screen.
ROSTER_STANDING = 194
## Cell px per source px at Patchvile's scale. His `fit` made these: his largest run animation spans
## 188 source px and his storefront 223, each filled to 92 % of its cell (256 and 448 px). The run
## factor serves the dash sheet too, as his `fit_match` does.
ROSTER_RUN_FACTOR = 0.92 * 256 / 188
ROSTER_MENU_FACTOR = 0.92 * 448 / 223
## How far a character's standing height may sit from ROSTER_STANDING (or a pack's own `standing`,
## Scarlet's), as a share: past the first it warns, past the second the pack is refused.
ROSTER_STANDING_WARN = 0.05
ROSTER_STANDING_LIMIT = 0.10

Box = Tuple[int, int, int, int]

# A pose pack is a different kind of input: not parts of a rig, but one finished painting per
# animation state. Nothing is cut - the approved PNGs are copied byte for byte - and the extractor
# only measures where the figure sits inside each equally sized canvas, so the runtime can put every
# pose on the same anchor at the same apparent height (`CharacterPoseSheet`).
## Empty since 2026-09-26: Ilyra, its only user, was removed (Scarlet replaced her). Kept as the seam
## for the next pose pack.
POSE_PACKS: Dict[str, Dict[str, object]] = {}

# Apparent-height corrections, measured by matching the character's head across the pack (normalized
# cross-correlation over scale and rotation, seeded from the idle pose) and rounded to 1 %. Only a
# pose the generator drew at a different size gets one: `wall_top` is painted inside extra padding at
# 0.84 of the pack's size, the single deviation the pack's own review notes call out.
POSE_SCALES: Dict[str, Dict[str, float]] = {}
# Authored drawing offsets, in pixels, for a pose the pack frames wrongly. Empty is the normal
# answer and the measured one for Ilyra, its last user: her pack painted every pose from one camera with the
# character's feet toward the bottom of the canvas, so the canvas centre already *is* the anchor.
# Chasing each pose's silhouette box instead would be worse than doing nothing, because that box
# moves with the pose - a crouch lowers the head while the feet stay put - and following it lifts
# a crouching character off the surface she is crouching on. Every pose's measured drift is
# written into the sheet so a review can see what is left and author a correction here.
POSE_OFFSETS: Dict[str, Dict[str, Tuple[float, float]]] = {}
# Alpha above which a pixel counts as the painted figure rather than its glow.
POSE_CORE_ALPHA: int = 200

# Ornaments are the loose pieces that drift around a character rather than being painted into
# her: her own crown shards, sparkles and chest gem, plus the slash she cuts with. They go into
# an `ornaments/` sub-folder so nothing confuses them with the poses.
#
# The detached kit ships two files under swapped names - `dash_slash.png` is a pair of small
# sparkles and `sparkle_pair.png` is the big slash arc - so the intake renames them on the way
# in rather than carrying the mistake into the game.
## Empty since 2026-09-26: Ilyra, its only user, was removed (Scarlet replaced her). Kept as the seam
## for the next ornament pack.
ORNAMENT_PACKS: Dict[str, Dict[str, object]] = {}

# A figure cut into body parts, copied verbatim like the ornaments into its own sub-folder. Ilyra 2's
# was the only one, and nothing loaded it after the jointed menu puppet built from it was reverted on
# 2026-09-20 (DEVLOG).
## Empty since 2026-09-26: Ilyra, its only user, was removed (Scarlet replaced her). Kept as the seam
## for the next puppet pack.
PUPPET_PACKS: Dict[str, Dict[str, object]] = {}

# Whole frames of a menu loop, copied verbatim onto their own stable canvas.
## Empty since 2026-09-26: Ilyra, its only user, was removed (Scarlet replaced her). Kept as the seam
## for the next frame pack.
FRAME_PACKS: Dict[str, Dict[str, object]] = {}

# A sheet pack is the whole-frame character intake (docs/guides/character_creation.md): one
# numbered PNG per frame in, packed atlas sheets plus ready-made `SpriteFrames` out. The pack's own
# JSON is the authority for row order, frame counts, fps and looping, so nothing is retyped here and
# a mismatch is an error rather than a silent truncation.
#
# Two sheets, not one: the split is the memory split the Shop needs - `menu` is all Home and a Shop
# card ever load, `run` is all a run ever loads. It was three until the animation set was cut to
# five on 2026-09-20 and the reaction sheet had nothing left on it.
SHEET_PACKS: Dict[str, Dict[str, object]] = {
	"verdant_shade": {
		# All AutoSprite (owner, 2026-09-25), the second character on the recipe after Patchvile: the
		# storefront, the floor, the right wall, the ceiling and the dash attack.
		"source": REPO / "concept_art/verdant_shade_autosprite_v1/frames",
		"manifest": REPO / "concept_art/verdant_shade_autosprite_v1/verdant_shade_sprite_sheet.json",
		# The owner generated the ceiling as its own sheet (today's pose, the flames gripping it), so
		# only the left wall is derived: the right wall mirrored, which the visual mirrors back on the
		# right wall.
		"derive": {"wall_left": ("wall_right", "flip_h")},
		# Patchvile's layout: 256 px run cells for 256 px frames, the dash on its own 336 px sheet at the
		# walls' pixel scale, the storefront on 448 px menu cells.
		"cells": {"run": 256, "dash": 336, "menu": 448},
		"columns": {"run": 8, "dash": 8, "menu": 5},
		"sheets": {
			"run": ["wall_bottom", "wall_top", "wall_left"],
			"dash": ["dash_loop"],
			"menu": ["storefront_idle"],
		},
		"resources": {
			"gameplay": (["run", "dash"], REPO / "data/characters/verdant_shade_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/verdant_shade_menu.tres"),
		},
		"menu_source": "storefront",
		"loop_fps_scale": 1.0,
		# Patchvile's pixel size: packed at his exact scale (docs/guides/character_creation.md §4).
		"roster_scale": True,
		# The loose leaves beside the right-wall pose, which the dash throws off (`DashParticles`).
		"particles": {
			"source": REPO / "concept_art/verdant_shade_autosprite_v1/particles",
			"parts": ["leaf_a", "leaf_b", "leaf_c", "leaf_d"],
			"cell": 48,
			"file": "verdant_shade_leaves.png",
		},
	},
	"patchvile": {
		# All AutoSprite (owner, 2026-09-23): the storefront, the floor, the right wall and the dash
		# attack. The manifest in the AutoSprite pack lists every row.
		"source": REPO / "concept_art/patchvile_autosprite_v1/frames",
		# Two generations instead of four (owner, 2026-09-23): the ceiling is the floor upside down,
		# and the left wall is the right wall mirrored - which the visual mirrors back on the right
		# wall, so the right wall shows AutoSprite's art exactly as generated.
		"derive": {"wall_top": ("wall_bottom", "flip_v"), "wall_left": ("wall_right", "flip_h")},
		"manifest": REPO / "concept_art/patchvile_autosprite_v1/patchvile_sprite_sheet.json",
		# AutoSprite delivers 256 px frames, so a 384 run cell would only enlarge them - and 76 of them
		# at 384 made a 3200 x 4000 sheet that loaded in twice the others' time. At 256 the sheet is
		# about the size of everyone else's. His scene's `design_size` is 256 to match.
		# The dash attack's extended lunge is as wide as its whole 256 px frame, so at the walls' scale
		# it needs ~321 px: it gets its own sheet of 336 px cells, drawn at the walls' pixel scale
		# (`fit_match`), so he stays one size and only the dash frames carry the extra room.
		"cells": {"run": 256, "dash": 336, "menu": 448},
		# The walls are 24 frames and the storefront 25, so the sheets are wider than the contract's.
		"columns": {"run": 8, "dash": 8, "menu": 5},
		"sheets": {
			"run": ["wall_bottom", "wall_top", "wall_left"],
			"dash": ["dash_loop"],
			"menu": ["storefront_idle"],
		},
		"resources": {
			"gameplay": (["run", "dash"], REPO / "data/characters/patchvile_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/patchvile_menu.tres"),
		},
		"menu_source": "storefront",
		"loop_fps_scale": 1.0,
		# The generator drew him at ~65% of his canvas, against 85-94% for the shipped characters,
		# and off centre; `fit_sheet_frames` scales and centres each sheet (owner, 2026-09-23).
		"fit": {"run": 0.92, "dash": 0.92, "menu": 0.92},
		"fit_match": {"dash": "run"},
		# Scraps of his costume his dash throws off (`DashParticles`), one strip the particles pick
		# a random cell from: four of Codex's ornaments, kept in the pack when the rest of that
		# rejected draft was deleted (2026-09-25). Only ever seen this small.
		"particles": {
			"source": REPO / "concept_art/patchvile_autosprite_v1/particles",
			"parts": ["cross_button", "stitched_patch", "bandage_ribbon", "scarf_tassel"],
			"cell": 96,
			"file": "patchvile_scraps.png",
		},
	},
	"mothmere": {
		# All AutoSprite (owner, 2026-09-25): the storefront, the floor, the right wall and the dash
		# attack, from first frames that keep the outline his Codex images carry (GDD §14 #49).
		"source": REPO / "concept_art/mothmere_autosprite_v1/frames",
		"manifest": REPO / "concept_art/mothmere_autosprite_v1/mothmere_sprite_sheet.json",
		# Patchvile's recipe: the ceiling is the floor upside down and the left wall the right wall
		# mirrored, which the visual mirrors back on the right wall.
		"derive": {"wall_top": ("wall_bottom", "flip_v"), "wall_left": ("wall_right", "flip_h")},
		# Patchvile's layout: 256 px run cells for 256 px frames, the dash on its own 336 px sheet at the
		# walls' pixel scale, the storefront on 448 px menu cells.
		"cells": {"run": 256, "dash": 336, "menu": 448},
		"columns": {"run": 8, "dash": 8, "menu": 5},
		"sheets": {
			"run": ["wall_bottom", "wall_top", "wall_left"],
			"dash": ["dash_loop"],
			"menu": ["storefront_idle"],
		},
		"resources": {
			"gameplay": (["run", "dash"], REPO / "data/characters/mothmere_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/mothmere_menu.tres"),
		},
		"menu_source": "storefront",
		"loop_fps_scale": 1.0,
		# Patchvile's pixel size: packed at his exact scale (docs/guides/character_creation.md §4).
		"roster_scale": True,
	},
	"scarlet": {
		# All AutoSprite (owner, 2026-09-26): the storefront, the floor, the right wall and the dash
		# attack, sliced and cleaned (the fan's rib gaps, the reap's black tips) by the pack's slicer.
		"source": REPO / "concept_art/scarlet_autosprite_v1/frames",
		"manifest": REPO / "concept_art/scarlet_autosprite_v1/scarlet_sprite_sheet.json",
		# Patchvile's recipe: the ceiling is the floor upside down and the left wall the right wall
		# mirrored, which the visual mirrors back on the right wall.
		"derive": {"wall_top": ("wall_bottom", "flip_v"), "wall_left": ("wall_right", "flip_h")},
		# Patchvile's layout: 256 px run cells for 256 px frames, the dash on its own 336 px sheet at the
		# walls' pixel scale, the storefront on 448 px menu cells.
		"cells": {"run": 256, "dash": 336, "menu": 448},
		"columns": {"run": 8, "dash": 8, "menu": 5},
		"sheets": {
			"run": ["wall_bottom", "wall_top", "wall_left"],
			"dash": ["dash_loop"],
			"menu": ["storefront_idle"],
		},
		"resources": {
			"gameplay": (["run", "dash"], REPO / "data/characters/scarlet_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/scarlet_menu.tres"),
		},
		"menu_source": "storefront",
		"loop_fps_scale": 1.0,
		# Patchvile's pixel size: packed at his exact scale (docs/guides/character_creation.md §4).
		"roster_scale": True,
		# The one exception to ROSTER_STANDING: her sheets were made with her standing 166 px (fan top
		# to feet). Her scene draws her 1.16x larger (`art_scale` 1.38, `menu_art_scale` 1.45), so she is
		# the same size as everyone on screen (owner, 2026-09-26, GDD §14 #54).
		"standing": 166,
		# Her own pieces (the pack's slicer cuts them from her frames): the reap crescent her dash
		# throws off (`DashParticles`) and her crown diamond trailing behind (`TrailParticles`).
		"particles": [
			{
				"source": REPO / "concept_art/scarlet_autosprite_v1/particles",
				"parts": ["reap_arc_a", "reap_arc_b"],
				"cell": 96,
				"file": "scarlet_reap_arcs.png",
			},
			{
				"source": REPO / "concept_art/scarlet_autosprite_v1/particles",
				"parts": ["crown_diamond"],
				"cell": 24,
				"file": "scarlet_diamond.png",
			},
		],
	},
	"rook": {
		# All AutoSprite (owner, 2026-09-27), replacing his bone rig: the storefront, the floor, the right
		# wall, his own ceiling and the dash attack, sliced and cleaned (the white AutoSprite's background
		# remover left in his gaps) by the pack's slicer.
		"source": REPO / "concept_art/rook_autosprite_v1/frames",
		"manifest": REPO / "concept_art/rook_autosprite_v1/rook_sprite_sheet.json",
		# His own ceiling sheet (GDD §14 #55), so only the left wall is derived: the right wall mirrored,
		# which the visual mirrors back on the right wall.
		"derive": {"wall_left": ("wall_right", "flip_h")},
		# At Patchvile's scale his walls do not fit a 256 px cell: the floor spans 239 source px (wing
		# tip to tail) and the right wall's tail swing 256, which is 299 and 321 cell px. So his run
		# sheet has the dash's 336 px cells; his scene's `design_size` is 336 and its `art_scale` grows
		# by 336/256 to match, so he is drawn at the same size as everyone else.
		"cells": {"run": 336, "dash": 336, "menu": 448},
		"columns": {"run": 8, "dash": 8, "menu": 5},
		"sheets": {
			"run": ["wall_bottom", "wall_top", "wall_left"],
			"dash": ["dash_loop"],
			"menu": ["storefront_idle"],
		},
		"resources": {
			"gameplay": (["run", "dash"], REPO / "data/characters/rook_gameplay.tres"),
			"menu": (["menu"], REPO / "data/characters/rook_menu.tres"),
		},
		"menu_source": "storefront",
		"loop_fps_scale": 1.0,
		# Patchvile's pixel size: packed at his exact scale (docs/guides/character_creation.md §4).
		"roster_scale": True,
		# His dash look is kept from the rig (owner, 2026-09-27): the streak his dash throws off
		# (`DashParticles`) and the dust mote of his trail and his ring (`TrailParticles`, `Aura`), the two
		# effect pieces the rig cut from its sheet, copied into the pack unchanged. One piece a strip, each
		# at its own size.
		"particles": [
			{
				"source": REPO / "concept_art/rook_autosprite_v1/particles",
				"parts": ["dash_streak"],
				"cell": 312,
				"file": "rook_dash_streak.png",
			},
			{
				"source": REPO / "concept_art/rook_autosprite_v1/particles",
				"parts": ["wing_dust"],
				"cell": 188,
				"file": "rook_wing_dust.png",
			},
		],
	},
}

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


def _union_box(boxes: List[Box]) -> Box:
	return (min(b[0] for b in boxes), min(b[1] for b in boxes),
			max(b[2] for b in boxes), max(b[3] for b in boxes))


def fit_sheet_frames(
	frames: Dict[str, List[Image.Image]], fill: float,
) -> Dict[str, Tuple[float, Tuple[float, float]]]:
	"""One scale for a whole sheet and one centre per animation, from the art's own bounds.

	The scale makes the largest animation's combined bounds fill `fill` of the frame; each
	animation's combined bounds are then centred. Both are constant across a loop, so a loop keeps
	its registration exactly and the character keeps one size across every animation on the sheet.
	Frames delivered on different canvas sizes come from different packs, drawn at different
	sizes, so each canvas size gets its own scale.
	"""
	unions: Dict[str, Box] = {}
	for state, arts in frames.items():
		unions[state] = _union_box([art.getchannel("A").getbbox() for art in arts])
	widths = {state: arts[0].width for state, arts in frames.items()}
	fits: Dict[str, Tuple[float, Tuple[float, float]]] = {}
	for width in sorted(set(widths.values())):
		members = [state for state in frames if widths[state] == width]
		largest = max(max(unions[s][2] - unions[s][0], unions[s][3] - unions[s][1]) for s in members)
		scale = fill * width / float(largest)
		for state in members:
			b = unions[state]
			fits[state] = (scale, ((b[0] + b[2]) / 2.0, (b[1] + b[3]) / 2.0))
	return fits


def _check_roster_standing(name: str, storefront: Path, expected: int = ROSTER_STANDING) -> None:
	"""Measures the first storefront frame against the roster size and warns, or refuses the pack.

	A character drawn smaller or larger than Patchvile in its 256 px frames would come out at a
	different size and detail from everyone else, because a roster pack is not fitted.
	"""
	art = Image.open(storefront).convert("RGBA")
	box = art.getchannel("A").getbbox()
	standing = box[3] - box[1]
	share = standing / float(expected) - 1.0
	line = "  ROSTER CHECK: %s stands %d px in its %d px frame (roster %d, %+.0f %%)" % (
		name, standing, art.height, expected, share * 100.0)
	if abs(share) > ROSTER_STANDING_LIMIT:
		raise SystemExit(line + " - refused: redraw the first frames at the roster size "
						 "(docs/guides/character_creation.md §3)")
	print(line + (" - WARNING: off the roster size" if abs(share) > ROSTER_STANDING_WARN else " - ok"))


def fit_frame(art: Image.Image, scale: float, centre: Tuple[float, float], cell: int) -> Image.Image:
	"""Scales `art` about `centre`, puts `centre` on the cell centre and resamples to `cell` once.

	Resampled premultiplied, so the zeroed colour under alpha 0 cannot darken the silhouette edge.
	"""
	factor = scale * cell / float(art.width)
	half = cell / 2.0
	matrix = (1.0 / factor, 0.0, centre[0] - half / factor,
			  0.0, 1.0 / factor, centre[1] - half / factor)
	fitted = art.convert("RGBa").transform(
		(cell, cell), Image.AFFINE, matrix, resample=Image.BICUBIC).convert("RGBA")
	box = fitted.getchannel("A").getbbox()
	if box is None or box[0] == 0 or box[1] == 0 or box[2] == cell or box[3] == cell:
		raise SystemExit("fit pushed the art to the cell edge (%s in %d px)" % (box, cell))
	return fitted


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

	# Packed at Patchvile's scale rather than fitted (ROSTER_*); `fit` and `fit_match` then do not apply.
	roster = bool(spec.get("roster_scale", False))  # type: ignore[union-attr]
	if roster:
		_check_roster_standing(name, menu_source / "storefront_idle_00.png",
							   int(spec.get("standing", ROSTER_STANDING)))  # type: ignore[call-overload]
	fills: Dict[str, float] = dict(spec.get("fit", {}))  # type: ignore[call-overload]
	# A sheet listed here takes another sheet's pixel scale (source px to sheet px) instead of its
	# own fit, so a character packed across two cell sizes stays one size; it must come after the
	# sheet it matches in `sheets`.
	matches: Dict[str, str] = dict(spec.get("fit_match", {}))  # type: ignore[call-overload]
	# Scale per sheet, per delivered frame size (see `fit_sheet_frames`).
	sheet_scales: Dict[str, Dict[int, float]] = {}
	state_folders: Dict[str, Path] = dict(spec.get("state_folders", {}))  # type: ignore[call-overload]
	derive: Dict[str, Tuple[str, str]] = dict(spec.get("derive", {}))  # type: ignore[call-overload]
	placed: Dict[str, List[Tuple[str, int, int, int]]] = {}
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
		cleaned: List[Image.Image] = []
		for state, file, row, column in grid:
			# A derived state reads another state's frames and flips them.
			origin, flip = derive.get(state, (state, ""))
			read_file = origin + file[len(state):]
			art_path = Path(str(state_folders.get(origin, folder))) / read_file
			if not art_path.exists() and folder is menu_source:
				# The menu sheet may carry a gameplay animation as well - the storefront idle test
				# puts `idle_hover` on it - and those frames live in the pack root.
				art_path = source / read_file
			if not art_path.exists():
				raise FileNotFoundError(art_path)
			art = Image.open(art_path).convert("RGBA")
			if flip:
				art = art.transpose(FLIPS[flip])
			if art.width != art.height:
				raise SystemExit("%s is %s; a frame must be square" % (file, art.size))
			cleaned.append(art)
		fits: Dict[str, Tuple[float, Tuple[float, float]]] = {}
		if roster:
			# Patchvile's scale, not a fit: each animation is still centred on its own bounds.
			factor = ROSTER_MENU_FACTOR if sheet == "menu" else ROSTER_RUN_FACTOR
			by_state_r: Dict[str, List[Image.Image]] = {}
			for (state, _file, _row, _column), art in zip(grid, cleaned):
				by_state_r.setdefault(state, []).append(art)
			for state, arts in by_state_r.items():
				union = _union_box([a.getchannel("A").getbbox() for a in arts])
				fits[state] = (factor * arts[0].width / float(cell),
							   ((union[0] + union[2]) / 2.0, (union[1] + union[3]) / 2.0))
			sheet_scales[sheet] = {by_state_r[s][0].width: fits[s][0] for s in fits}
			print("  ROSTER: %s sheet at Patchvile's scale, %.3f cell px per source px" % (sheet, factor))
		elif sheet in fills:
			by_state: Dict[str, List[Image.Image]] = {}
			for (state, _file, _row, _column), art in zip(grid, cleaned):
				by_state.setdefault(state, []).append(art)
			fits = fit_sheet_frames(by_state, fills[sheet])
			if sheet in matches:
				reference = matches[sheet]
				fits = {state: (sheet_scales[reference][by_state[state][0].width]
								* cells[reference] / float(cell), centre)
						for state, (_scale, centre) in fits.items()}
			sheet_scales[sheet] = {by_state[s][0].width: fits[s][0] for s in fits}
			for width, scale in sorted(sheet_scales[sheet].items()):
				print("  FIT: %s sheet, %d px frames x%.3f, each animation centred" % (
					sheet, width, scale))
		for (state, file, row, column), art in zip(grid, cleaned):
			if state in fits:
				art = clear_invisible_rgb(fit_frame(art, fits[state][0], fits[state][1], cell))
			else:
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
	portrait_art = Image.open(source / "idle_hover_00.png").convert("RGBA")
	portrait_scale = sheet_scales.get("run", {}).get(portrait_art.width)
	if portrait_scale is not None:
		box = portrait_art.getchannel("A").getbbox()
		portrait = clear_invisible_rgb(fit_frame(
			portrait_art, portrait_scale, ((box[0] + box[2]) / 2.0, (box[1] + box[3]) / 2.0),
			cells["run"]))
	else:
		portrait = clear_invisible_rgb(
			portrait_art.resize((cells["run"], cells["run"]), Image.LANCZOS))
	portrait.save(out_dir / ("%s_portrait.png" % name), optimize=True)
	print("PLAYABLE ART: %s portrait %dx%d -> %s" % (
		name, cells["run"], cells["run"], out_dir / ("%s_portrait.png" % name)))

	worst = max(drifts, key=lambda d: abs(d[0]) + abs(d[1]))
	print("  ANCHOR: worst residual drift %s px over %d frames" % (worst, len(drifts)))
	scale = float(spec.get("loop_fps_scale", 1.0))  # type: ignore[union-attr]
	for key in dict(spec["resources"]):  # type: ignore[arg-type]
		members, path = dict(spec["resources"])[key]  # type: ignore[index]
		_write_sprite_frames(name, key, list(members), placed, rows, Path(str(path)), scale)
	# One strip, or a list of them when a character's two emitters each throw their own pieces.
	strips = spec.get("particles", [])  # type: ignore[union-attr]
	for strip in (strips if isinstance(strips, list) else [strips]):
		_write_particle_strip(name, dict(strip), out_dir)  # type: ignore[arg-type]
	write_pose_sheet(REPO / ("data/characters/%s_frames.tres" % name), frames_seen,
					 [(0.0, 0.0)] * len(frames_seen), drifts, {}, float(cells["run"]))
	print("  CONTACT: %s" % make_contact(name, preview, {}))


def _write_particle_strip(name: str, spec: Dict[str, object], out_dir: Path) -> None:
	"""A horizontal strip of loose pieces for a particle emitter, one centred piece per cell."""
	cell = int(spec["cell"])  # type: ignore[arg-type]
	parts: List[str] = list(spec["parts"])  # type: ignore[arg-type]
	strip = Image.new("RGBA", (cell * len(parts), cell), (0, 0, 0, 0))
	for index, part in enumerate(parts):
		art = Image.open(Path(str(spec["source"])) / ("%s.png" % part)).convert("RGBA")
		art = art.crop(art.getchannel("A").getbbox())
		fit = (cell - 8) / float(max(art.size))
		art = art.resize((max(1, round(art.width * fit)), max(1, round(art.height * fit))), Image.LANCZOS)
		strip.alpha_composite(art, (index * cell + (cell - art.width) // 2, (cell - art.height) // 2))
	strip = clear_invisible_rgb(strip)
	strip.save(out_dir / str(spec["file"]), optimize=True)
	print("PLAYABLE ART: %s particle strip %dx%d, %d pieces -> %s" % (
		name, strip.width, strip.height, len(parts), out_dir / str(spec["file"])))


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
	known: List[str] = list(POSE_PACKS)
	known += [n for n in SHEET_PACKS if n not in known]
	for name in names or known:
		if name in SHEET_PACKS:
			ingest_sheet_pack(name)
		elif name in POSE_PACKS:
			ingest_pose_pack(name)
			if name in ORNAMENT_PACKS:
				ingest_ornaments(name)
			if name in PUPPET_PACKS:
				ingest_puppet(name)
			if name in FRAME_PACKS:
				ingest_frames(name)
		else:
			raise SystemExit("Unknown character %r (known: %s)" % (name, ", ".join(known)))


if __name__ == "__main__":
	main(sys.argv[1:])
