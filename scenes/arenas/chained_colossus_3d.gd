extends ModelArenaVisual
## CHAINED COLOSSUS 3D: the owner's model of a hooded stone colossus holding the arena board,
## live in 3D above a night sea of clouds (owner 2026-09-30, GDD §14 #68, ADR-0023).
##
## The model and its layout are built by
## concept_art/arenas_v2/chained_colossus_3d/build_colossus.py. This script adds what the owner's
## image shows around it, made in Godot: the sky and moon (`arena_night_sky.gdshader`), banks of
## cloud (`arena_cloud_bank.gdshader`), two far arches in the clouds, stone shards floating around
## the board, blue ghost fire along the model's outline (`ghost_flame.gdshader`), glowing skulls
## (`ghost_skull.gdshader`) and the glowing eye (`ghost_glow.gdshader`), which pulses with the
## head's breath. Nothing is drawn over the floor. Pausable with the run; Reduced Motion holds
## everything still.

const NIGHT_SKY: Shader = preload("res://assets/shaders/arena_night_sky.gdshader")
const CLOUD_BANK: Shader = preload("res://assets/shaders/arena_cloud_bank.gdshader")
const GHOST_FLAME: Shader = preload("res://assets/shaders/ghost_flame.gdshader")
const GHOST_SKULL: Shader = preload("res://assets/shaders/ghost_skull.gdshader")
const GHOST_GLOW: Shader = preload("res://assets/shaders/ghost_glow.gdshader")

## Model units from the camera to the sky quad.
const SKY_DISTANCE: float = 40.0
## Cloud banks, far to near: model units behind the floor, the band of the screen they fill (top
## and bottom as shares of its height), coverage, drift (units per second), opacity, and the share
## of the band over which its bottom fades out (0 where the band reaches below the screen).
const CLOUD_BANKS: Array[Array] = [
	[9.0, 0.16, 0.42, 0.62, 0.01, 0.45, 0.35],
	[6.0, 0.52, 1.06, 0.46, 0.015, 0.85, 0.0],
	[3.0, 0.64, 1.06, 0.5, 0.025, 0.95, 0.0],
	[1.2, 0.8, 1.08, 0.55, 0.035, 1.0, 0.0],
]
## Arches in the clouds, where the owner's image has its ruins: screen position (shares of its width
## and height, the arch's foot), height as a share of the screen's height, units behind the floor.
const RUINS: Array[Array] = [
	[0.1, 0.76, 0.085, 4.0],
	[0.9, 0.84, 0.07, 5.0],
]
## Far away and hazed by the fog, the arches are flat silhouettes, unlit.
const RUIN_COLOR := Color(0.27, 0.32, 0.41)
## Floating shards: how many, their size range (model units, before stretching), and the rects
## (model x, y) they float in, left of, right of and under the board.
const SHARD_COUNT: int = 26
const SHARD_SIZE := Vector2(0.016, 0.042)
const SHARD_REGIONS: Array[Rect2] = [
	Rect2(-0.5, -0.85, 0.2, 1.15),
	Rect2(0.2, -0.85, 0.17, 0.85),
	Rect2(-0.45, -0.95, 0.8, 0.28),
]
## Shards keep this far (model units) from the floor on every side.
const SHARD_FLOOR_MARGIN: float = 0.08
const SHARD_DEPTH := Vector2(-0.15, 0.32)
const SHARD_BOB := Vector2(0.008, 0.016)
const SHARD_BOB_RATE := Vector2(0.5, 0.9)
const SHARD_COLOR := Color(0.44, 0.45, 0.48)
## Flames: how many at once, seconds each lives, the size of one tongue (model units).
const FLAME_AMOUNT: int = 170
const FLAME_LIFETIME: float = 1.4
const FLAME_SIZE := Vector2(0.07, 0.15)
## A skull's quad (model units; the flame trails up from the skull in its top half), and how far
## and how fast it bobs.
const SKULL_SIZE := Vector2(0.11, 0.17)
const SKULL_BOB := Vector3(0.01, 0.018, 0.0)
const SKULL_BOB_RATE := Vector2(0.6, 0.9)
## The eye's glow: its quad's size and how far in front of the eye it floats (model units).
const EYE_GLOW_SIZE: float = 0.09
const EYE_GLOW_LIFT: float = 0.02
## The depth fog starts this far behind the floor and is full this far behind it.
const FOG_BEGIN_BEHIND: float = 1.0
const FOG_END_BEHIND: float = 12.0

var _timed_materials: Array[ShaderMaterial] = []
var _sky: MeshInstance3D
var _sky_material: ShaderMaterial
var _banks: Array[MeshInstance3D] = []
var _ruins: Array[MeshInstance3D] = []
var _shards: MultiMesh
var _shard_rest: Array[Transform3D] = []
var _shard_bob: PackedVector3Array = PackedVector3Array()
var _flames: GPUParticles3D
var _skulls: Array[MeshInstance3D] = []
var _skull_rest: PackedVector3Array = PackedVector3Array()
var _eye_material: ShaderMaterial

@onready var _environment: WorldEnvironment = %Environment


func _ready() -> void:
	super()
	var effects := Node3D.new()
	effects.name = "Effects"
	_world.add_child(effects)
	_build_sky()
	_build_clouds(effects)
	_build_ruins(effects)
	_build_shards(effects)
	_build_flames(effects)
	_build_skulls(effects)
	_build_eye_glow()
	_apply_reduced_motion()
	_update_motion()


func _process(delta: float) -> void:
	super(delta)
	if not _reduced_motion:
		_update_motion()


func _after_fit(_view_size: Vector2) -> void:
	var height: float = 2.0 * SKY_DISTANCE * _tan_half_fov * 1.02
	(_sky.mesh as QuadMesh).size = Vector2(height * _port_size.x / _port_size.y, height)
	_sky_material.set_shader_parameter(&"aspect", _port_size.x / _port_size.y)
	for i: int in _banks.size():
		var bank: Array = CLOUD_BANKS[i]
		var distance: float = _floor_distance() + float(bank[0])
		var top_left: Vector3 = _plane_point(Vector2(-0.05, float(bank[1])) * _port_size, distance)
		var bottom_right: Vector3 = _plane_point(Vector2(1.05, float(bank[2])) * _port_size, distance)
		var size := Vector2(bottom_right.x - top_left.x, top_left.y - bottom_right.y)
		(_banks[i].mesh as QuadMesh).size = size
		_banks[i].position = (top_left + bottom_right) * 0.5
		(_banks[i].material_override as ShaderMaterial).set_shader_parameter(&"quad_size", size)
	for i: int in _ruins.size():
		var ruin: Array = RUINS[i]
		var distance: float = _floor_distance() + float(ruin[3])
		var foot: Vector3 = _plane_point(Vector2(float(ruin[0]), float(ruin[1])) * _port_size, distance)
		var per_pixel: float = 2.0 * distance * _tan_half_fov / _port_size.y
		_ruins[i].position = foot
		_ruins[i].scale = Vector3.ONE * float(ruin[2]) * _port_size.y * per_pixel


func _camera_moved() -> void:
	# The fog is measured from the camera, so it follows the camera through a zoom.
	var distance: float = _camera.position.z - layout.floor_z
	var environment: Environment = _environment.environment
	environment.fog_depth_begin = distance + FOG_BEGIN_BEHIND
	environment.fog_depth_end = distance + FOG_END_BEHIND


func _apply_reduced_motion() -> void:
	super()
	if _flames != null:
		_flames.speed_scale = 0.0 if _reduced_motion else 1.0


func _update_motion() -> void:
	for material: ShaderMaterial in _timed_materials:
		material.set_shader_parameter(&"scene_time", _time)
	for i: int in _shard_rest.size():
		var bob: Vector3 = _shard_bob[i]
		var rest: Transform3D = _shard_rest[i]
		var lift: float = bob.x * sin(_time * bob.y + bob.z)
		var turn := Basis(Vector3.UP, 0.15 * sin(_time * bob.y * 0.5 + bob.z))
		_shards.set_instance_transform(i, Transform3D(turn * rest.basis, rest.origin + Vector3.UP * lift))
	for i: int in _skulls.size():
		var phase: float = float(i) * 1.9
		_skulls[i].position = _skull_rest[i] + Vector3(
			SKULL_BOB.x * sin(_time * SKULL_BOB_RATE.x + phase),
			SKULL_BOB.y * sin(_time * SKULL_BOB_RATE.y + phase * 0.7), 0.0)
	if _eye_material != null and breath_period > 0.0:
		_eye_material.set_shader_parameter(&"pulse", 0.5 - 0.5 * cos(TAU * _time / breath_period))


func _floor_uniforms(material: ShaderMaterial) -> void:
	var rect: Rect2 = layout.floor_rect
	material.set_shader_parameter(&"floor_rect", Vector4(rect.position.x, rect.position.y, rect.end.x, rect.end.y))
	material.set_shader_parameter(&"floor_z", layout.floor_z)


func _build_sky() -> void:
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = NIGHT_SKY
	_sky = MeshInstance3D.new()
	_sky.name = "Sky"
	_sky.mesh = QuadMesh.new()
	_sky.material_override = _sky_material
	_sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sky.position = Vector3(0.0, 0.0, -SKY_DISTANCE)
	_camera.add_child(_sky)
	_timed_materials.append(_sky_material)


func _build_clouds(parent: Node3D) -> void:
	for i: int in CLOUD_BANKS.size():
		var bank: Array = CLOUD_BANKS[i]
		var material := ShaderMaterial.new()
		material.shader = CLOUD_BANK
		material.set_shader_parameter(&"coverage", float(bank[3]))
		material.set_shader_parameter(&"drift", float(bank[4]))
		material.set_shader_parameter(&"opacity", float(bank[5]))
		material.set_shader_parameter(&"bottom_fade", float(bank[6]))
		material.set_shader_parameter(&"seed", float(i) * 3.7)
		var quad := MeshInstance3D.new()
		quad.name = "Clouds%d" % i
		quad.mesh = QuadMesh.new()
		quad.material_override = material
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(quad)
		_banks.append(quad)
		_timed_materials.append(material)


func _build_ruins(parent: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = RUIN_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i: int in RUINS.size():
		var ruin := MeshInstance3D.new()
		ruin.name = "Ruin%d" % i
		ruin.mesh = _ruin_mesh()
		ruin.material_override = material
		ruin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ruin)
		_ruins.append(ruin)


## An arch's flat silhouette, about one unit tall with its foot at the origin: two pillars with caps
## under a round arch.
func _ruin_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spring: float = 0.6
	var rects: Array[Rect2] = [
		Rect2(-0.42, 0.0, 0.17, spring), Rect2(0.25, 0.0, 0.17, spring),
		Rect2(-0.46, spring - 0.04, 0.25, 0.06), Rect2(0.21, spring - 0.04, 0.25, 0.06),
	]
	for rect: Rect2 in rects:
		var a := Vector3(rect.position.x, rect.position.y, 0.0)
		var b := Vector3(rect.end.x, rect.position.y, 0.0)
		var c := Vector3(rect.end.x, rect.end.y, 0.0)
		var d := Vector3(rect.position.x, rect.end.y, 0.0)
		for vertex: Vector3 in [a, c, b, a, d, c]:
			tool.add_vertex(vertex)
	const SEGMENTS: int = 12
	for k: int in SEGMENTS:
		var a0: float = PI * float(k) / float(SEGMENTS)
		var a1: float = PI * float(k + 1) / float(SEGMENTS)
		var inner0 := Vector3(cos(a0) * 0.25, spring + sin(a0) * 0.25, 0.0)
		var inner1 := Vector3(cos(a1) * 0.25, spring + sin(a1) * 0.25, 0.0)
		var outer0 := Vector3(cos(a0) * 0.42, spring + sin(a0) * 0.42, 0.0)
		var outer1 := Vector3(cos(a1) * 0.42, spring + sin(a1) * 0.42, 0.0)
		for vertex: Vector3 in [inner0, outer1, outer0, inner0, inner1, outer1]:
			tool.add_vertex(vertex)
	return tool.commit()


func _build_shards(parent: Node3D) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 7
	var keep_out: Rect2 = layout.floor_rect.grow(SHARD_FLOOR_MARGIN)
	var material := StandardMaterial3D.new()
	material.albedo_color = SHARD_COLOR
	material.roughness = 0.95
	var mesh := _shard_mesh()
	mesh.surface_set_material(0, material)
	_shards = MultiMesh.new()
	_shards.transform_format = MultiMesh.TRANSFORM_3D
	_shards.mesh = mesh
	var placed: Array[Transform3D] = []
	var tries: int = 0
	while placed.size() < SHARD_COUNT and tries < SHARD_COUNT * 40:
		tries += 1
		var region: Rect2 = SHARD_REGIONS[random.randi_range(0, SHARD_REGIONS.size() - 1)]
		var point := Vector2(
			random.randf_range(region.position.x, region.end.x),
			random.randf_range(region.position.y, region.end.y))
		if keep_out.has_point(point):
			continue
		var size: float = random.randf_range(SHARD_SIZE.x, SHARD_SIZE.y)
		var basis := Basis.from_euler(Vector3(
			random.randf_range(-0.3, 0.3), random.randf_range(0.0, TAU), random.randf_range(-0.35, 0.35)))
		basis = basis.scaled(Vector3(size, size * random.randf_range(1.4, 2.2), size))
		placed.append(Transform3D(basis, Vector3(point.x, point.y,
			random.randf_range(SHARD_DEPTH.x, SHARD_DEPTH.y))))
		_shard_bob.append(Vector3(random.randf_range(SHARD_BOB.x, SHARD_BOB.y),
			random.randf_range(SHARD_BOB_RATE.x, SHARD_BOB_RATE.y), random.randf_range(0.0, TAU)))
	_shards.instance_count = placed.size()
	for i: int in placed.size():
		_shards.set_instance_transform(i, placed[i])
	_shard_rest = placed
	var instance := MultiMeshInstance3D.new()
	instance.name = "Shards"
	instance.multimesh = _shards
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


## A rough crystal one unit across: a ring of five points between a top and a bottom point, faceted.
func _shard_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0.05, 0.5, 0.0)
	var bottom := Vector3(-0.04, -0.5, 0.02)
	var ring: Array[Vector3] = []
	for i: int in 5:
		var angle: float = TAU * float(i) / 5.0
		var radius: float = 0.5 if i % 2 == 0 else 0.38
		ring.append(Vector3(cos(angle) * radius, 0.06 * float(i % 3) - 0.04, sin(angle) * radius))
	for i: int in 5:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 5]
		for vertex: Vector3 in [top, a, b, bottom, b, a]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	return tool.commit()


func _build_flames(parent: Node3D) -> void:
	var points: PackedVector3Array = layout.flame_points
	if points.is_empty():
		return
	var image := Image.create_empty(points.size(), 1, false, Image.FORMAT_RGBF)
	for i: int in points.size():
		image.set_pixel(i, 0, Color(points[i].x, points[i].y, points[i].z))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	process.emission_point_texture = ImageTexture.create_from_image(image)
	process.emission_point_count = points.size()
	process.direction = Vector3.UP
	process.spread = 18.0
	process.initial_velocity_min = 0.01
	process.initial_velocity_max = 0.04
	process.gravity = Vector3(0.0, 0.06, 0.0)
	process.scale_min = 0.7
	process.scale_max = 1.4
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.45))
	scale_curve.add_point(Vector2(0.3, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.25))
	var scale_texture := CurveTexture.new()
	scale_texture.curve = scale_curve
	process.scale_curve = scale_texture
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.6, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.6, 1.0, 0.95, 0.0), Color(0.75, 1.0, 0.95, 0.75),
		Color(0.35, 0.95, 0.85, 0.55), Color(0.1, 0.6, 0.6, 0.0),
	])
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	process.color_ramp = ramp_texture
	var material := ShaderMaterial.new()
	material.shader = GHOST_FLAME
	_floor_uniforms(material)
	var quad := QuadMesh.new()
	quad.size = FLAME_SIZE
	quad.material = material
	_flames = GPUParticles3D.new()
	_flames.name = "Flames"
	_flames.amount = FLAME_AMOUNT
	_flames.lifetime = FLAME_LIFETIME
	_flames.preprocess = FLAME_LIFETIME
	_flames.randomness = 0.5
	_flames.process_material = process
	_flames.draw_pass_1 = quad
	_flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flames.visibility_aabb = AABB(Vector3(-1.0, -1.5, -1.0), Vector3(2.0, 3.0, 2.0))
	parent.add_child(_flames)
	_timed_materials.append(material)


func _build_skulls(parent: Node3D) -> void:
	for i: int in layout.skull_points.size():
		var material := ShaderMaterial.new()
		material.shader = GHOST_SKULL
		_floor_uniforms(material)
		var quad := QuadMesh.new()
		quad.size = SKULL_SIZE
		var skull := MeshInstance3D.new()
		skull.name = "Skull%d" % i
		skull.mesh = quad
		skull.material_override = material
		skull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# The skull is drawn in the quad's lower half; lift the quad so the skull sits on the point.
		var rest: Vector3 = layout.skull_points[i] + Vector3(0.0, SKULL_SIZE.y * 0.25, 0.0)
		skull.position = rest
		parent.add_child(skull)
		_skulls.append(skull)
		_skull_rest.append(rest)
		_timed_materials.append(material)


func _build_eye_glow() -> void:
	_eye_material = ShaderMaterial.new()
	_eye_material.shader = GHOST_GLOW
	var quad := QuadMesh.new()
	quad.size = Vector2(EYE_GLOW_SIZE, EYE_GLOW_SIZE)
	var glow := MeshInstance3D.new()
	glow.name = "EyeGlow"
	glow.mesh = quad
	glow.material_override = _eye_material
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not _attach_to_head(glow, layout.eye + Vector3(0.0, 0.0, EYE_GLOW_LIFT)):
		glow.position = layout.eye + Vector3(0.0, 0.0, EYE_GLOW_LIFT)
		_model.add_child(glow)
