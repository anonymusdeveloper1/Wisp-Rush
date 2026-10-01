"""Build the CHAINED COLOSSUS 3D arena's model from the owner's Meshy file (GDD §14 #68, ADR-0023).

    "D:/Blender/blender.exe" --background --factory-startup --python concept_art/arenas_v2/chained_colossus_3d/build_colossus.py

Reads `source/Meshy_AI_Chained_Titan_s_Gameb_0930163022_texture.blend` (the owner's model, unchanged:
one mesh, the colossus holding the arena board, three 2048 px textures) and writes, never to be
hand-edited:

- `assets/art/environment/arenas/chained_colossus_3d/chained_colossus.glb` - the model with fewer
  triangles and a two-bone rig (`root`, `head`) whose head bone turns the hood and face;
- `assets/art/environment/arenas/chained_colossus_3d/chained_colossus_layout.tres` - a
  `ModelArenaLayout`: the playable floor, the eye, and where the flames and skulls sit;
- `model_report.json` here - the measurements, for review.

Everything is measured on the full-resolution mesh: rays cast at the model's front (it faces -Y in
Blender) find the flat floor plane, its inner rectangle, the silhouette and the board's outline; the
eye is the teal patch of the colour texture on the hood. Blender is Z-up and Godot Y-up: a Blender
point (x, y, z) is (x, z, -y) in the game.
"""
import json
import os

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SOURCE = os.path.join(HERE, "source", "Meshy_AI_Chained_Titan_s_Gameb_0930163022_texture.blend")
OUT_DIR = os.path.join(REPO, "assets", "art", "environment", "arenas", "chained_colossus_3d")
GLB = os.path.join(OUT_DIR, "chained_colossus.glb")
LAYOUT = os.path.join(OUT_DIR, "chained_colossus_layout.tres")
REPORT = os.path.join(HERE, "model_report.json")

## Share of the triangles kept (the source has 337,015; a phone draws the rest every frame).
DECIMATE_RATIO = 0.25
## The floor is kept at full detail: its large flat triangles would otherwise collapse first and
## smear its tiles and emblem. Its vertices (within PROTECT_MARGIN of the floor, on its plane) are
## left out of the decimation's vertex group, and this factor makes collapsing them costly.
PROTECT_MARGIN = 0.01
PROTECT_FACTOR = 1000.0
## Grid step of the front ray casts, in model units (the model is 1.9 tall).
STEP = 0.004
## Front-facing hits within this depth of the floor plane count as floor.
FLOOR_TOLERANCE = 0.006
## The head bone moves vertices inside this ellipsoid around the head's centre fully, and none
## beyond OUTER times it; radii in model units (x, y, z).
HEAD_RADII = Vector((0.20, 0.24, 0.22))
HEAD_OUTER = 1.55
## Below this height band nothing follows the head (the board's top and the chest stay put).
HEAD_FLOOR_BAND = (0.46, 0.56)
## Flames are spawned no closer than this to each other, and never within MARGIN of the floor, nor
## in the band BELOW it under the floor (flames rise, and would climb over its bottom edge).
FLAME_SPACING = 0.03
FLAME_FLOOR_MARGIN = 0.035
FLAME_BELOW_FLOOR = 0.2
## No flames start within this distance (x and z) of the eye, so the fire never hides the face.
FLAME_EYE_CLEAR = 0.14
## The glowing skulls, placed where the owner's image has them: pixels of that 941 x 1672 image
## and its floor there (left, top, right, bottom), mapped onto this model's floor. Depth: in front
## of the board's frame.
SKULLS_IMAGE_PX = ((55, 375), (228, 565), (715, 553), (853, 873), (717, 1100), (233, 1030))
IMAGE_FLOOR_PX = (290, 470, 665, 1290)
SKULL_DEPTH = -0.34


def to_godot(p):
	return (p[0], p[2], -p[1])


def fmt(v):
	return "%.5f" % v


def front_depth_map(bvh):
	"""Front hit depth (Blender y) and normal y per grid cell, and the grid's axes."""
	xs = np.arange(-0.5, 0.5 + 1e-9, STEP)
	zs = np.arange(0.95, -0.95 - 1e-9, -STEP)
	depth = np.full((len(zs), len(xs)), np.nan)
	normal_y = np.full((len(zs), len(xs)), np.nan)
	for j, z in enumerate(zs):
		for i, x in enumerate(xs):
			loc, nor, _index, _dist = bvh.ray_cast(Vector((x, -3.0, z)), Vector((0.0, 1.0, 0.0)), 10.0)
			if loc is not None:
				depth[j, i] = loc.y
				normal_y[j, i] = nor.y
	return xs, zs, depth, normal_y


def measure_floor(xs, zs, depth, normal_y):
	"""The flat floor plane's depth and its inner rectangle (left, right, bottom, top)."""
	band = (zs > -0.6) & (zs < 0.2)
	values = depth[band][normal_y[band] < -0.95]
	hist, edges = np.histogram(values, bins=np.arange(-0.45, 0.0, 0.002))
	floor_y = float(edges[np.argmax(hist)] + 0.001)
	is_floor = np.abs(depth - floor_y) < FLOOR_TOLERANCE
	# Runs of floor cells through the floor's middle, row by row and column by column; ropes and
	# brackets cut some runs short, so the typical run end is the frame's inner edge.
	centre_i = int(np.argmax(is_floor.sum(axis=0)))
	lefts, rights = [], []
	for j in range(len(zs)):
		if not is_floor[j, centre_i]:
			continue
		a = b = centre_i
		while a > 0 and is_floor[j, a - 1]:
			a -= 1
		while b < len(xs) - 1 and is_floor[j, b + 1]:
			b += 1
		lefts.append(xs[a])
		rights.append(xs[b])
	centre_j = int(np.argmax(is_floor.sum(axis=1)))
	tops, bottoms = [], []
	for i in range(len(xs)):
		if not is_floor[centre_j, i]:
			continue
		a = b = centre_j
		while a > 0 and is_floor[a - 1, i]:
			a -= 1
		while b < len(zs) - 1 and is_floor[b + 1, i]:
			b += 1
		tops.append(zs[a])
		bottoms.append(zs[b])
	rect = (
		float(np.percentile(lefts, 25)), float(np.percentile(rights, 75)),
		float(np.percentile(bottoms, 25)), float(np.percentile(tops, 75)),
	)
	return floor_y, rect


def base_color_pixels(obj):
	"""The colour texture as an (h, w, 4) array, row 0 at the bottom (v = 0)."""
	mat = obj.data.materials[0]
	image = None
	for node in mat.node_tree.nodes:
		if node.type == "BSDF_PRINCIPLED":
			link = node.inputs["Base Color"].links
			if link and link[0].from_node.type == "TEX_IMAGE":
				image = link[0].from_node.image
	if image is None:
		raise SystemExit("no base colour texture on %s" % mat.name)
	w, h = image.size
	pixels = np.empty(w * h * 4, dtype=np.float32)
	image.pixels.foreach_get(pixels)
	return pixels.reshape((h, w, 4)), image.name


def find_eye(obj, bvh, pixels):
	"""Centre of the teal eye on the hood, from the colour under front rays over the head."""
	mesh = obj.data
	uv = mesh.uv_layers.active.data
	h, w = pixels.shape[:2]
	hits = []
	for z in np.arange(0.5, 0.92, STEP):
		for x in np.arange(-0.25, 0.3, STEP):
			loc, _nor, index, _dist = bvh.ray_cast(Vector((x, -3.0, z)), Vector((0.0, 1.0, 0.0)), 10.0)
			if loc is None:
				continue
			poly = mesh.polygons[index]
			if len(poly.vertices) != 3:
				continue
			a, b, c = (mesh.vertices[v].co for v in poly.vertices)
			ua, ub, uc = (Vector((uv[l].uv[0], uv[l].uv[1], 0.0)) for l in poly.loop_indices)
			t = barycentric_transform(loc, a, b, c, ua, ub, uc)
			px = min(w - 1, max(0, int(t.x % 1.0 * w)))
			py = min(h - 1, max(0, int(t.y % 1.0 * h)))
			r, g, bl, _a = pixels[py, px]
			if r < 0.3 and g > 0.45 and bl > 0.45 and g - r > 0.25:
				hits.append(loc.copy())
	if not hits:
		raise SystemExit("no teal eye found on the hood")
	centre = sum(hits, Vector()) / len(hits)
	return centre, len(hits)


def head_centre(bvh, xs, zs, depth, eye):
	"""Centre of the hood: its middle at the eye's height, halfway between front and back."""
	j = int(np.argmin(np.abs(zs - (eye.z + 0.12))))
	i = int(np.argmin(np.abs(xs - eye.x)))
	a = b = i
	while a > 0 and not np.isnan(depth[j, a - 1]):
		a -= 1
	while b < len(xs) - 1 and not np.isnan(depth[j, b + 1]):
		b += 1
	x = float((xs[a] + xs[b]) * 0.5)
	z = float(eye.z + 0.06)
	front = bvh.ray_cast(Vector((x, -3.0, z)), Vector((0.0, 1.0, 0.0)), 10.0)[0]
	back = bvh.ray_cast(Vector((x, 3.0, z)), Vector((0.0, -1.0, 0.0)), 10.0)[0]
	y = (front.y + back.y) * 0.5 if front is not None and back is not None else eye.y + 0.2
	return Vector((x, y, z))


def flame_points(xs, zs, depth, floor_rect, eye):
	"""Points along the model's silhouette and the board's outline, away from the floor and eye."""
	hit = ~np.isnan(depth)
	board = hit & (np.nan_to_num(depth, nan=1.0) < -0.2)
	points = []
	left, right, bottom, top = floor_rect
	taken = set()
	for j in range(1, len(zs) - 1):
		for i in range(1, len(xs) - 1):
			if not hit[j, i]:
				continue
			edge = not (hit[j - 1, i] and hit[j + 1, i] and hit[j, i - 1] and hit[j, i + 1])
			outline = board[j, i] and not (
				board[j - 1, i] and board[j + 1, i] and board[j, i - 1] and board[j, i + 1])
			if not (edge or outline):
				continue
			x, z = float(xs[i]), float(zs[j])
			if (left - FLAME_FLOOR_MARGIN < x < right + FLAME_FLOOR_MARGIN
					and bottom - FLAME_BELOW_FLOOR < z < top + FLAME_FLOOR_MARGIN):
				continue
			if abs(x - eye.x) < FLAME_EYE_CLEAR and abs(z - eye.z) < FLAME_EYE_CLEAR:
				continue
			key = (int(x / FLAME_SPACING), int(z / FLAME_SPACING))
			if key in taken:
				continue
			taken.add(key)
			points.append((x, float(depth[j, i]) - 0.01, z))
	return points


def skull_points(floor_rect):
	left, right, bottom, top = floor_rect
	fl, ft, fr, fb = IMAGE_FLOOR_PX
	result = []
	for px, py in SKULLS_IMAGE_PX:
		u = (px - fl) / (fr - fl)
		v = (py - ft) / (fb - ft)
		result.append((left + u * (right - left), SKULL_DEPTH, top - v * (top - bottom)))
	return result


def head_weight(co, centre):
	d = Vector(((co.x - centre.x) / HEAD_RADII.x, (co.y - centre.y) / HEAD_RADII.y,
		(co.z - centre.z) / HEAD_RADII.z)).length
	near = 1.0 - min(1.0, max(0.0, (d - 1.0) / (HEAD_OUTER - 1.0)))
	near = near * near * (3.0 - 2.0 * near)
	lo, hi = HEAD_FLOOR_BAND
	band = min(1.0, max(0.0, (co.z - lo) / (hi - lo)))
	band = band * band * (3.0 - 2.0 * band)
	return near * band


def build_rig(obj, pivot, head_top):
	arm_data = bpy.data.armatures.new("ColossusRig")
	rig = bpy.data.objects.new("ColossusRig", arm_data)
	bpy.context.scene.collection.objects.link(rig)
	bpy.ops.object.select_all(action="DESELECT")
	rig.select_set(True)
	bpy.context.view_layer.objects.active = rig
	bpy.ops.object.mode_set(mode="EDIT")
	root = arm_data.edit_bones.new("root")
	root.head = (pivot.x, pivot.y, -0.9)
	root.tail = (pivot.x, pivot.y, pivot.z)
	head = arm_data.edit_bones.new("head")
	head.head = pivot
	head.tail = head_top
	head.parent = root
	bpy.ops.object.mode_set(mode="OBJECT")
	return rig


def write_layout(floor_y, floor_rect, eye, points, skulls):
	left, right, bottom, top = floor_rect
	floor_rect_g = (left, bottom, right - left, top - bottom)

	def vec3_array(values):
		flat = []
		for p in values:
			flat.extend(fmt(c) for c in to_godot(p))
		return "PackedVector3Array(%s)" % ", ".join(flat)

	eye_g = to_godot(eye)
	text = "\n".join([
		'[gd_resource type="Resource" script_class="ModelArenaLayout" load_steps=2 format=3]',
		"",
		'[ext_resource type="Script" path="res://scripts/resources/model_arena_layout.gd" id="1_script"]',
		"",
		"[resource]",
		'script = ExtResource("1_script")',
		"floor_rect = Rect2(%s)" % ", ".join(fmt(v) for v in floor_rect_g),
		"floor_z = %s" % fmt(-floor_y),
		"eye = Vector3(%s)" % ", ".join(fmt(v) for v in eye_g),
		'head_bone = &"head"',
		"flame_points = %s" % vec3_array(points),
		"skull_points = %s" % vec3_array(skulls),
		"",
	])
	with open(LAYOUT, "w", encoding="utf-8", newline="\n") as handle:
		handle.write(text)


def main():
	bpy.ops.wm.open_mainfile(filepath=SOURCE)
	obj = bpy.data.objects["Mesh_0"]
	obj.name = "Colossus"
	source_tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
	bvh = BVHTree.FromObject(obj, bpy.context.evaluated_depsgraph_get())

	xs, zs, depth, normal_y = front_depth_map(bvh)
	floor_y, floor_rect = measure_floor(xs, zs, depth, normal_y)
	pixels, texture_name = base_color_pixels(obj)
	eye, eye_hits = find_eye(obj, bvh, pixels)
	centre = head_centre(bvh, xs, zs, depth, eye)
	pivot = Vector((centre.x, centre.y, HEAD_FLOOR_BAND[1]))
	head_top = Vector((centre.x, centre.y, float(np.nanmax(np.where(~np.isnan(depth), zs[:, None], np.nan)))))
	points = flame_points(xs, zs, depth, floor_rect, eye)
	skulls = skull_points(floor_rect)

	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	left, right, bottom, top = floor_rect
	free = obj.vertex_groups.new(name="decimate")
	protected = 0
	for vertex in obj.data.vertices:
		co = vertex.co
		on_floor = (left - PROTECT_MARGIN < co.x < right + PROTECT_MARGIN
			and bottom - PROTECT_MARGIN < co.z < top + PROTECT_MARGIN
			and abs(co.y - floor_y) < PROTECT_MARGIN)
		if on_floor:
			protected += 1
		else:
			free.add([vertex.index], 1.0, "REPLACE")
	decimate = obj.modifiers.new("Decimate", "DECIMATE")
	decimate.decimate_type = "COLLAPSE"
	decimate.ratio = DECIMATE_RATIO
	decimate.use_collapse_triangulate = True
	decimate.vertex_group = free.name
	decimate.vertex_group_factor = PROTECT_FACTOR
	bpy.ops.object.modifier_apply(modifier=decimate.name)
	leftover = obj.vertex_groups.get("decimate")
	if leftover is not None:
		obj.vertex_groups.remove(leftover)
	tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)

	head_group = obj.vertex_groups.new(name="head")
	root_group = obj.vertex_groups.new(name="root")
	moving = 0
	for vertex in obj.data.vertices:
		weight = head_weight(vertex.co, centre)
		if weight > 0.0:
			head_group.add([vertex.index], weight, "REPLACE")
			moving += 1
		if weight < 1.0:
			root_group.add([vertex.index], 1.0 - weight, "REPLACE")

	rig = build_rig(obj, pivot, head_top)
	obj.parent = rig
	armature = obj.modifiers.new("Rig", "ARMATURE")
	armature.object = rig

	os.makedirs(OUT_DIR, exist_ok=True)
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	rig.select_set(True)
	bpy.context.view_layer.objects.active = rig
	bpy.ops.export_scene.gltf(
		filepath=GLB, export_format="GLB", use_selection=True, export_apply=False,
		export_animations=False, export_skins=True, export_yup=True, export_materials="EXPORT",
		export_image_format="AUTO",
	)
	write_layout(floor_y, floor_rect, eye, points, skulls)

	left, right, bottom, top = floor_rect
	report = {
		"source": os.path.relpath(SOURCE, REPO).replace("\\", "/"),
		"source_triangles": source_tris,
		"triangles": tris,
		"decimate_ratio": DECIMATE_RATIO,
		"floor_vertices_protected": protected,
		"floor_plane_blender_y": round(floor_y, 4),
		"floor_rect_blender_xz": {"left": round(left, 4), "right": round(right, 4),
			"bottom": round(bottom, 4), "top": round(top, 4)},
		"floor_size": [round(right - left, 4), round(top - bottom, 4)],
		"eye_blender": [round(c, 4) for c in eye],
		"eye_texture": texture_name,
		"eye_samples": eye_hits,
		"head_centre_blender": [round(c, 4) for c in centre],
		"head_pivot_blender": [round(c, 4) for c in pivot],
		"head_vertices": moving,
		"flame_points": len(points),
		"skull_points": len(skulls),
		"glb": os.path.relpath(GLB, REPO).replace("\\", "/"),
		"glb_bytes": os.path.getsize(GLB),
	}
	with open(REPORT, "w", encoding="utf-8", newline="\n") as handle:
		json.dump(report, handle, indent=2)
		handle.write("\n")
	print("COLOSSUS:", json.dumps(report))


main()
