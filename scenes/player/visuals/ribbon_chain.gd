@tool
class_name RibbonChain
extends Node2D
## A painted ribbon (tail, scarf) that bends smoothly: a skinned Polygon2D on its own Bone2D chain.
##
## The node's origin is the ribbon's attachment root. At `_ready` it builds a Skeleton2D whose bones
## follow [member spine] and a grid-mesh Polygon2D weighted along that spine, so bending the bones
## deforms the painted texture with no gaps between segments. [member spring] drives the bones; the
## owning rig tunes it per state. Presentation only: no collision, no gameplay reads.

## Painted ribbon layer (an extracted, transparent PNG).
@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild_if_ready()
## Centre line in texture pixels (origin top-left), root first; printed by
## `tools/art/extract_playable_characters.py`. One bone is built per segment.
@export var spine: PackedVector2Array = PackedVector2Array():
	set(value):
		spine = value
		_rebuild_if_ready()
## Grid cell size in texture pixels; smaller cells bend more smoothly and cost more vertices.
@export_range(8.0, 128.0, 1.0) var cell_size: float = 36.0:
	set(value):
		cell_size = value
		_rebuild_if_ready()
## Canvas order of the painted mesh relative to its siblings.
@export var mesh_z_index: int = 0:
	set(value):
		mesh_z_index = value
		if _polygon != null:
			_polygon.z_index = value
## Sway phase offset in radians, so sibling ribbons never wave in unison.
@export var phase_offset: float = 0.0

## Follow-through springs for this ribbon's bones; tune its public fields from the owning rig.
var spring: ChainSpring = ChainSpring.new()

var _skeleton: Skeleton2D
var _polygon: Polygon2D
var _bones: Array[Node2D] = []


func _ready() -> void:
	_rebuild()


## Advances the ribbon's springs; call once per frame from the owning rig.
func step(delta: float, time: float) -> void:
	if not Engine.is_editor_hint():
		spring.step(delta, time)


## The generated bone chain, root first (tests and debugging).
func get_bones() -> Array[Node2D]:
	return _bones.duplicate()


## The generated skinned mesh (tests and debugging).
func get_mesh() -> Polygon2D:
	return _polygon


## Current world-space position of the ribbon tip (the last spine point).
func get_tip_global_position() -> Vector2:
	if _bones.is_empty():
		return global_position
	var last := _bones[_bones.size() - 1] as Bone2D
	return last.to_global(Vector2(last.get_length(), 0.0))


func _rebuild_if_ready() -> void:
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	for child: Node in [_skeleton, _polygon]:
		if child != null:
			remove_child(child)
			child.queue_free()
	_skeleton = null
	_polygon = null
	_bones.clear()
	if texture == null or spine.size() < 2:
		spring.setup([] as Array[Node2D])
		return
	var root: Vector2 = spine[0]
	_skeleton = Skeleton2D.new()
	_skeleton.name = "Skeleton"
	add_child(_skeleton)
	var parent: Node2D = _skeleton
	var parent_angle: float = 0.0
	for index: int in spine.size() - 1:
		var segment: Vector2 = spine[index + 1] - spine[index]
		var bone := Bone2D.new()
		bone.name = "Bone%d" % index
		# Pivots own no child bones at the tip, so Godot must not auto-measure them.
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(maxf(1.0, segment.length()))
		bone.set_bone_angle(0.0)
		var local_start: Vector2 = spine[index] - root
		if index > 0:
			local_start = Vector2(spine[index].distance_to(spine[index - 1]), 0.0)
		var angle: float = segment.angle()
		bone.position = local_start
		bone.rotation = wrapf(angle - parent_angle, -PI, PI)
		bone.rest = bone.transform
		parent.add_child(bone)
		_bones.append(bone)
		parent = bone
		parent_angle = angle
	_polygon = _build_mesh(root)
	add_child(_polygon)
	_polygon.skeleton = _polygon.get_path_to(_skeleton)
	spring.setup(_bones, phase_offset)


func _build_mesh(root: Vector2) -> Polygon2D:
	var size: Vector2 = texture.get_size()
	var columns: int = maxi(1, ceili(size.x / cell_size))
	var rows: int = maxi(1, ceili(size.y / cell_size))
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for row: int in rows + 1:
		for column: int in columns + 1:
			var pixel := Vector2(size.x * column / columns, size.y * row / rows)
			points.append(pixel - root)
			uvs.append(pixel)
	var cells: Array = []
	for row: int in rows:
		for column: int in columns:
			var top_left: int = row * (columns + 1) + column
			var bottom_left: int = top_left + columns + 1
			cells.append(PackedInt32Array([top_left, top_left + 1, bottom_left + 1, bottom_left]))
	var mesh := Polygon2D.new()
	mesh.name = "Mesh"
	mesh.texture = texture
	mesh.polygon = points
	mesh.uv = uvs
	mesh.polygons = cells
	mesh.z_index = mesh_z_index
	var weights: Array[PackedFloat32Array] = _skin_weights(points, root)
	for index: int in _bones.size():
		mesh.add_bone(_skeleton.get_path_to(_bones[index]), weights[index])
	return mesh


## Linear-blend weights along the spine: each vertex follows the segment nearest to it and blends
## with the neighbouring bone across a joint, so joints bend without creases.
func _skin_weights(points: PackedVector2Array, root: Vector2) -> Array[PackedFloat32Array]:
	var bone_count: int = spine.size() - 1
	var weights: Array[PackedFloat32Array] = []
	for bone_index: int in bone_count:
		var column := PackedFloat32Array()
		column.resize(points.size())
		weights.append(column)
	for vertex: int in points.size():
		var pixel: Vector2 = points[vertex] + root
		var best_segment: int = 0
		var best_t: float = 0.0
		var best_distance: float = INF
		for segment: int in bone_count:
			var a: Vector2 = spine[segment]
			var b: Vector2 = spine[segment + 1]
			var ab: Vector2 = b - a
			var t: float = clampf((pixel - a).dot(ab) / maxf(0.001, ab.length_squared()), 0.0, 1.0)
			var distance: float = pixel.distance_squared_to(a + ab * t)
			if distance < best_distance:
				best_distance = distance
				best_segment = segment
				best_t = t
		var own: float = 1.0
		if best_t < 0.5 and best_segment > 0:
			var blend: float = 0.5 - best_t
			weights[best_segment - 1][vertex] = blend
			own = 1.0 - blend
		elif best_t > 0.5 and best_segment < bone_count - 1:
			var blend_next: float = best_t - 0.5
			weights[best_segment + 1][vertex] = blend_next
			own = 1.0 - blend_next
		weights[best_segment][vertex] = own
	return weights
