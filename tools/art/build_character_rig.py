#!/usr/bin/env python3
"""Build a playable character's rig scene from its part pack manifest.

A part pack (``assets/art/characters/playable/<id>/manifest.json``) describes every rig group as a
pivot, a tip, a rest transform *in the assembly frame* and a draw order. This tool turns that into
``scenes/player/visuals/<id>_visual.tscn``: one ``Node2D`` pivot per part carrying a ``Sprite2D``
offset so the pivot pixel sits on the node origin, parented and posed so the rig reproduces the
pack's assembly reference exactly.

Doing this by hand means converting ~66 absolute rest transforms into parent-relative ones and
inverting every pivot into a sprite offset, which is exactly the arithmetic a script should own.
Re-run it whenever the pack changes; the per-character motion lives in ``<id>_visual.gd`` and is
never touched here.

    python3 tools/art/build_character_rig.py ilyra

Requirements: Python 3.7+ and Pillow 9.5.
"""
import json
import math
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
ART = REPO / "assets/art/characters/playable"
SCENES = REPO / "scenes/player/visuals"
RIBBON_SCRIPT = "res://scenes/player/visuals/ribbon_chain.gd"

# Trailing cloth: a skinned mesh whose bones are driven passively by a ChainSpring. The value is the
# mesh cell size in texture pixels — smaller bends more smoothly and costs vertices.
RIBBONS: Dict[str, Dict[str, float]] = {
	"ilyra": {
		"braid_l": 40.0, "braid_r": 40.0,
		"sash_1": 38.0, "sash_2": 38.0, "sash_3": 38.0, "sash_4": 38.0,
	},
}
# Limbs are skinned the same way, but their bones are *posed* by the rig script rather than sprung.
# Any part carrying a `chain` in the manifest is one: a single painting that bends at real joints, so
# an elbow or knee never shows the seam two rotating cutouts must.
LIMB_CELL_SIZE: float = 30.0
# Textures that only ever feed a GPUParticles2D, so they get no node of their own.
PARTICLE_ONLY: Dict[str, List[str]] = {
	"ilyra": ["vfx_star", "vfx_mote", "vfx_petal", "vfx_streak"],
}
# Parts whose Sprite2D starts hidden; the rig script reveals them (expression swaps, effects).
HIDDEN: Dict[str, List[str]] = {
	"ilyra": [
		"head_blink", "head_focused", "head_joy", "head_pain",
		"hand_cup_l", "hand_cup_r", "fan_membrane_lit",
		"vfx_fan_arc", "vfx_ring", "vfx_bloom",
	],
}
# A sub-tree that exists once in the pack but twice on the character. The copy is mirrored in X and
# re-parented, so Ilyra's two identical fans come from one authored mechanism.
MIRRORED: Dict[str, List[Dict[str, str]]] = {
	"ilyra": [{"root": "fan_handle", "parent": "hand_grip_r", "suffix": "R"}],
}
# Everything about the scene that is not the part hierarchy: the root's tuning exports and the two
# particle emitters. Kept here so re-running the tool reproduces the whole scene, and so the only
# hand-written file per character stays its `<id>_visual.gd`.
RIG_ROOT: Dict[str, Dict[str, str]] = {
	"ilyra": {
		"class": "IlyraVisual",
		"script": "res://scenes/player/visuals/ilyra_visual.gd",
		"exports": "\n".join([
			"heading_frequency = 6.8",
			"heading_damping = 0.7",
			"settle_frequency = 4.0",
			"squash_amount = 0.8",
			"bounce_amount = 1.0",
			"aim_lean = 0.3",
		]),
		"trail_texture": "vfx_star.png",
		"trail_amount": "18",
		"trail_lifetime": "0.66",
		"dash_texture": "vfx_streak.png",
		"dash_amount": "10",
		"dash_lifetime": "0.42",
		"burst_texture": "vfx_petal.png",
		"burst_amount": "8",
		"burst_lifetime": "0.5",
	},
}

PARTICLE_BLOCK = """[sub_resource type="CanvasItemMaterial" id="CanvasItemMaterial_add"]
blend_mode = 1

[sub_resource type="Gradient" id="Gradient_trail"]
offsets = PackedFloat32Array(0, 0.28, 1)
colors = PackedColorArray(0.62, 0.95, 1, 0, 0.55, 0.85, 1, 0.85, 0.42, 0.4, 0.95, 0)

[sub_resource type="GradientTexture1D" id="GradientTexture_trail"]
gradient = SubResource("Gradient_trail")

[sub_resource type="ParticleProcessMaterial" id="ParticleProcessMaterial_trail"]
particle_flag_disable_z = true
emission_shape = 1
emission_sphere_radius = 190.0
direction = Vector3(0, 1, 0)
spread = 34.0
initial_velocity_min = 40.0
initial_velocity_max = 140.0
gravity = Vector3(0, 0, 0)
damping_min = 30.0
damping_max = 70.0
angle_min = -40.0
angle_max = 40.0
angular_velocity_min = -70.0
angular_velocity_max = 70.0
scale_min = 0.3
scale_max = 0.6
color_ramp = SubResource("GradientTexture_trail")

[sub_resource type="ParticleProcessMaterial" id="ParticleProcessMaterial_burst"]
particle_flag_disable_z = true
emission_shape = 1
emission_sphere_radius = 210.0
direction = Vector3(0, -1, 0)
spread = 180.0
initial_velocity_min = 180.0
initial_velocity_max = 420.0
gravity = Vector3(0, 0, 0)
damping_min = 240.0
damping_max = 420.0
angle_min = -180.0
angle_max = 180.0
angular_velocity_min = -220.0
angular_velocity_max = 220.0
scale_min = 0.4
scale_max = 0.85
color_ramp = SubResource("GradientTexture_trail")

[sub_resource type="ParticleProcessMaterial" id="ParticleProcessMaterial_dash"]
particle_flag_disable_z = true
emission_shape = 1
emission_sphere_radius = 140.0
direction = Vector3(0, 1, 0)
spread = 22.0
initial_velocity_min = 110.0
initial_velocity_max = 240.0
gravity = Vector3(0, 0, 0)
damping_min = 80.0
damping_max = 140.0
angle_min = 160.0
angle_max = 200.0
scale_min = 0.35
scale_max = 0.7
color_ramp = SubResource("GradientTexture_trail")
"""

Vec = Tuple[float, float]


class Transform:
	"""Minimal 2D affine transform: rotation then translation, matching Godot's Transform2D."""

	def __init__(self, rotation: float = 0.0, origin: Vec = (0.0, 0.0)) -> None:
		self.rotation = rotation
		self.origin = origin

	def inverse_times(self, other: "Transform") -> "Transform":
		"""Returns `self^-1 * other` — `other` expressed in this transform's frame."""
		rotation: float = other.rotation - self.rotation
		dx: float = other.origin[0] - self.origin[0]
		dy: float = other.origin[1] - self.origin[1]
		cos_a: float = math.cos(-self.rotation)
		sin_a: float = math.sin(-self.rotation)
		return Transform(rotation, (dx * cos_a - dy * sin_a, dx * sin_a + dy * cos_a))


def node_name(part: str) -> str:
	"""`arm_upper_ul` -> `ArmUpperUl`, so scenes read like the rest of the project."""
	return "".join(word.capitalize() for word in part.split("_"))


def build(character: str) -> Path:
	pack: Path = ART / character
	manifest = json.loads((pack / "manifest.json").read_text())
	parts: Dict[str, Dict] = manifest["parts"]
	skip: List[str] = PARTICLE_ONLY.get(character, [])
	ribbons: Dict[str, float] = RIBBONS.get(character, {})
	hidden: List[str] = HIDDEN.get(character, [])

	globals_: Dict[str, Transform] = {}
	for part, spec in parts.items():
		globals_[part] = Transform(
			math.radians(float(spec["rest_rotation_deg"])),
			(float(spec["rest_position"][0]), float(spec["rest_position"][1])),
		)

	children: Dict[Optional[str], List[str]] = {}
	for part, spec in parts.items():
		if part in skip:
			continue
		children.setdefault(spec.get("parent"), []).append(part)
	for bucket in children.values():
		bucket.sort(key=lambda p: (parts[p]["draw_order"], p))

	textures: Dict[str, str] = {}
	sizes: Dict[str, Tuple[int, int]] = {}
	for part, spec in parts.items():
		if part in skip:
			continue
		textures[part] = "res://assets/art/characters/playable/%s/%s" % (character, spec["file"])
		with Image.open(pack / spec["file"]) as art:
			sizes[part] = art.size

	lines: List[str] = []
	resources: List[str] = []
	used_ids: Dict[str, str] = {}

	def ext_id(path: str) -> str:
		if path not in used_ids:
			index = len(used_ids) + 1
			kind = "Script" if path.endswith(".gd") else "Texture2D"
			used_ids[path] = "%d_%s" % (index, Path(path).stem.replace(".", "_"))
			resources.append(
				'[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, used_ids[path])
			)
		return used_ids[path]

	def emit(
		part: str,
		parent_path: str,
		parent_part: Optional[str],
		mirror: str = "",
		mirror_root: Optional[Transform] = None,
	) -> None:
		spec = parts[part]
		name = node_name(part) + mirror
		# A mirrored copy is flipped once, at the top of its chain: the negative X scale then mirrors
		# every descendant's own local transform, which is exactly what the manifest's mirrored rest
		# entries describe.
		placed: Transform = mirror_root if mirror_root is not None else globals_[part]
		local = (
			globals_[parent_part].inverse_times(placed)
			if parent_part is not None
			else placed
		)
		width, height = sizes[part]
		pivot = spec["pivot"]
		offset = (width / 2.0 - pivot[0], height / 2.0 - pivot[1])
		chain: List = spec.get("chain", [])
		is_limb: bool = len(chain) >= 2
		is_ribbon: bool = part in ribbons or is_limb

		lines.append("")
		node_type = "Node2D"
		lines.append('[node name="%s" type="%s" parent="%s"]' % (name, node_type, parent_path))
		lines.append("unique_name_in_owner = true")
		if abs(local.origin[0]) > 1e-6 or abs(local.origin[1]) > 1e-6:
			lines.append("position = Vector2(%s, %s)" % (num(local.origin[0]), num(local.origin[1])))
		if abs(local.rotation) > 1e-6:
			lines.append("rotation = %s" % num(local.rotation))
		if mirror_root is not None:
			lines.append("scale = Vector2(-1, 1)")
		if is_ribbon:
			# The mesh is skinned to a bone chain: a limb uses the manifest's own joint chain, and
			# trailing cloth a straight line from its pivot to its tip. Either way the spine is in
			# texture pixels and its first point is the node origin.
			if is_limb:
				spine = ", ".join("%d, %d" % (point[0], point[1]) for point in chain)
				cell = LIMB_CELL_SIZE
			else:
				spine = straight_spine(spec["pivot"], spec["tip"])
				cell = ribbons[part]
			lines.append('script = ExtResource("%s")' % ext_id(RIBBON_SCRIPT))
			lines.append('texture = ExtResource("%s")' % ext_id(textures[part]))
			lines.append("spine = PackedVector2Array(%s)" % spine)
			lines.append("cell_size = %s" % num(cell))
			lines.append("mesh_z_index = %d" % spec["draw_order"])
			lines.append("phase_offset = %s" % num(hash_phase(part)))
		else:
			child_path = "%s/%s" % (parent_path, name)
			lines.append("")
			# No unique name: every part would claim "Sprite". The rig reaches them as `%Part/Sprite`.
			lines.append('[node name="Sprite" type="Sprite2D" parent="%s"]' % child_path)
			if part in hidden:
				lines.append("visible = false")
			lines.append("z_index = %d" % spec["draw_order"])
			if abs(offset[0]) > 1e-6 or abs(offset[1]) > 1e-6:
				lines.append("offset = Vector2(%s, %s)" % (num(offset[0]), num(offset[1])))
			lines.append('texture = ExtResource("%s")' % ext_id(textures[part]))
		for child in children.get(part, []):
			emit(child, "%s/%s" % (parent_path, name), part, mirror)

	roots: List[str] = children.get(None, [])
	for root in roots:
		emit(root, "MotionRoot/Body", None)
	mirrored: Dict[str, Dict] = {
		entry["part"]: entry for entry in manifest.get("assembly", {}).get("mirrored_instances", [])
	}
	for copy in MIRRORED.get(character, []):
		entry = mirrored.get(copy["root"])
		if entry is None:
			raise SystemExit("manifest has no mirrored instance for %r" % copy["root"])
		emit(
			copy["root"],
			"MotionRoot/Body/%s" % path_to(parts, copy["parent"]),
			copy["parent"],
			copy["suffix"],
			Transform(
				math.radians(float(entry["rest_rotation_deg"])),
				(float(entry["rest_position"][0]), float(entry["rest_position"][1])),
			),
		)

	# Silhouette bounds from the parts that are actually visible at rest: `design_size` is the height
	# the controller scales onto, and `preview_center` is what menus centre on. The rig test compares
	# both against `get_layer_bounds()`, so deriving them here removes a round of manual tuning.
	low_x, low_y, high_x, high_y = 1e9, 1e9, -1e9, -1e9
	for part in textures:
		if part in hidden:
			continue
		width, height = sizes[part]
		pivot = parts[part]["pivot"]
		transform = globals_[part]
		cos_a, sin_a = math.cos(transform.rotation), math.sin(transform.rotation)
		for cx in (-pivot[0], width - pivot[0]):
			for cy in (-pivot[1], height - pivot[1]):
				x = transform.origin[0] + cx * cos_a - cy * sin_a
				y = transform.origin[1] + cx * sin_a + cy * cos_a
				low_x, high_x = min(low_x, x), max(high_x, x)
				low_y, high_y = min(low_y, y), max(high_y, y)
	# The mirrored fan makes the silhouette symmetric about the rig's own axis.
	span_x = max(abs(low_x), abs(high_x))
	low_x, high_x = -span_x, span_x
	design_size = high_y - low_y
	centre = ((low_x + high_x) * 0.5, (low_y + high_y) * 0.5)

	root = RIG_ROOT[character]
	art_dir = "res://assets/art/characters/playable/%s" % character
	trail_id = ext_id("%s/%s" % (art_dir, root["trail_texture"]))
	dash_id = ext_id("%s/%s" % (art_dir, root["dash_texture"]))
	burst_id = ext_id("%s/%s" % (art_dir, root["burst_texture"]))
	script_id = ext_id(root["script"])

	header: List[str] = [
		"[gd_scene load_steps=%d format=3]" % (len(resources) + 8),
		"",
	] + resources + ["", PARTICLE_BLOCK]
	shell: List[str] = [
		'[node name="%s" type="Node2D"]' % root["class"],
		'script = ExtResource("%s")' % script_id,
		"design_size = %s" % num(design_size),
		"preview_center = Vector2(%s, %s)" % (num(centre[0]), num(centre[1])),
		root["exports"],
		"",
		'[node name="MotionRoot" type="Node2D" parent="."]',
		"unique_name_in_owner = true",
		"",
		'[node name="DashParticles" type="GPUParticles2D" parent="MotionRoot"]',
		"unique_name_in_owner = true",
		'material = SubResource("CanvasItemMaterial_add")',
		"position = Vector2(0, 120)",
		"emitting = false",
		"amount = %s" % root["dash_amount"],
		"lifetime = %s" % root["dash_lifetime"],
		"visibility_rect = Rect2(-1200, -1200, 2400, 2400)",
		"local_coords = false",
		'process_material = SubResource("ParticleProcessMaterial_dash")',
		'texture = ExtResource("%s")' % dash_id,
		"",
		'[node name="TrailParticles" type="GPUParticles2D" parent="MotionRoot"]',
		"unique_name_in_owner = true",
		'material = SubResource("CanvasItemMaterial_add")',
		"position = Vector2(0, 50)",
		"emitting = false",
		"amount = %s" % root["trail_amount"],
		"lifetime = %s" % root["trail_lifetime"],
		"visibility_rect = Rect2(-1200, -1200, 2400, 2400)",
		"local_coords = false",
		'process_material = SubResource("ParticleProcessMaterial_trail")',
		'texture = ExtResource("%s")' % trail_id,
		"",
		"",
		'[node name="AttackParticles" type="GPUParticles2D" parent="MotionRoot"]',
		"unique_name_in_owner = true",
		'material = SubResource("CanvasItemMaterial_add")',
		"position = Vector2(0, -160)",
		"emitting = false",
		"one_shot = true",
		"explosiveness = 0.9",
		"amount = %s" % root["burst_amount"],
		"lifetime = %s" % root["burst_lifetime"],
		"visibility_rect = Rect2(-1200, -1200, 2400, 2400)",
		"local_coords = false",
		'process_material = SubResource("ParticleProcessMaterial_burst")',
		'texture = ExtResource("%s")' % burst_id,
		"",
		'[node name="Body" type="Node2D" parent="MotionRoot"]',
		"unique_name_in_owner = true",
	]
	tail: List[str] = [
		"",
		'[node name="AnimationPlayer" type="AnimationPlayer" parent="."]',
		"unique_name_in_owner = true",
		"",
		'[node name="AnimationTree" type="AnimationTree" parent="."]',
		"unique_name_in_owner = true",
	]
	body = "\n".join(header + shell + lines + tail) + "\n"
	destination = SCENES / ("%s_visual.tscn" % character)
	destination.write_text(body)
	print("RIG: %d %s parts -> %s" % (len(textures), character, destination.relative_to(REPO)))
	print("  design_size=%s preview_center=(%s, %s)" % (
		num(design_size), num(centre[0]), num(centre[1])))
	return destination


def path_to(parts: Dict[str, Dict], part: str) -> str:
	"""Scene path of [param part] under `MotionRoot/Body`, from its manifest ancestry."""
	chain: List[str] = []
	cursor: Optional[str] = part
	while cursor is not None:
		chain.append(node_name(cursor))
		cursor = parts[cursor].get("parent")
	return "/".join(reversed(chain))


def straight_spine(pivot: List[int], tip: List[int], count: int = 5) -> str:
	points: List[str] = []
	for index in range(count):
		share: float = index / float(count - 1)
		points.append("%d, %d" % (
			round(pivot[0] + (tip[0] - pivot[0]) * share),
			round(pivot[1] + (tip[1] - pivot[1]) * share),
		))
	return ", ".join(points)


def hash_phase(part: str) -> float:
	"""Stable per-part sway phase so sibling ribbons never wave in unison."""
	return (sum(ord(c) for c in part) % 628) / 100.0


def num(value: float) -> str:
	text = "%.4f" % value
	text = text.rstrip("0").rstrip(".")
	return text if text not in ("", "-0") else "0"


def main(names: Optional[List[str]] = None) -> None:
	for name in names or list(RIBBONS):
		if not (ART / name / "manifest.json").exists():
			raise SystemExit("No part pack manifest for %r" % name)
		build(name)


if __name__ == "__main__":
	main(sys.argv[1:])
