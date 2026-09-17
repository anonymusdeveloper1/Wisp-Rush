class_name ArenaAmbience
extends Control
## Living scenery of Legendary and Mythic Endless skins: drives the scenery shader on the painted
## background and spawns the skin's glow particles.
##
## `configure(scenery, background)` puts `arena_scenery.gdshader` on the background TextureRect
## (grade, emissive light on the painting's own lights, distortion, set piece, sweep, shooting
## stars) and adds one CPUParticles2D per `ArenaParticleEmitter` in background-pixel space. Each
## frame it turns the time-based parts (breathing, flicker, flares, colour cycling, corona rotation,
## swirl phase, sweep and streak positions) into shader values; per-pixel work stays in the shader.
## The mask keeps everything off the floor + rim tolerance and particles fade by it too, so nothing
## covers the playfield, telegraphs or enemies (GDD §8). Pausable: time, particles and flares freeze
## with the run. Reduced Motion (`set_active(false)`) keeps the static grade and a steady glow only:
## no distortion, particles, flares, sweeps or streaks. Shop thumbnails use
## `create_material(scenery)` for the same static look without this node.

## Shortest time between two lightning-like flashes of one arena, in seconds (no strobing).
const MIN_FLASH_INTERVAL: float = 6.0
## Flare and shooting-star waits are randomised within ±this share of their interval.
const FLARE_JITTER: float = 0.3
## Background-texture size every UV, pixel and speed in the scenery data is authored against.
const TEXTURE_SIZE := Vector2(941.0, 1672.0)
## Shader array length: zone id 0 (no zone) plus `ArenaSceneryData.MAX_ZONES`.
const ZONE_SLOTS: int = 8
## Particle simulation rate (interpolated), enough for slow drifting sprites.
const PARTICLE_FPS: int = 30
## Share of a particle's life spent fading in and out.
const PARTICLE_FADE_SHARE: float = 0.2
## Pixel size of the generated soft-dot sprite.
const SOFT_DOT_SIZE: int = 64
const SCENERY_SHADER: Shader = preload("res://assets/shaders/arena_scenery.gdshader")
const PARTICLE_SHADER: Shader = preload("res://assets/shaders/arena_scenery_particles.gdshader")
const SPARKLE_TEXTURE: Texture2D = preload("res://assets/art/vfx/12_collectible_sparkle.png")

static var _soft_dot: GradientTexture2D

## True: cover-scale like GameWorld's backdrop. False: fit inside the rect like a Shop thumbnail.
var cover: bool = true

var _scenery: ArenaSceneryData
var _background: CanvasItem
var _material: ShaderMaterial
var _active: bool = true
var _time: float = 0.0
var _last_flash: float = -MIN_FLASH_INTERVAL
var _noise := FastNoiseLite.new()
var _random := RandomNumberGenerator.new()
var _zone_light := PackedVector4Array()
var _flare_wait := PackedFloat32Array()
var _flare_age := PackedFloat32Array()
var _piece_flare_wait: float = 0.0
var _piece_flare_age: float = -1.0
var _piece_flare_angle: float = 0.0
var _streak_wait: float = 0.0
var _streak_age: float = -1.0
var _streak_start := Vector2.ZERO
var _streak_heading: float = 0.0
var _particle_space: Node2D
var _particles: Array[CPUParticles2D] = []
var _particle_material_cache: Array[ShaderMaterial] = []
var _last_image_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise.frequency = 1.0
	_particle_space = Node2D.new()
	_particle_space.name = "ParticleSpace"
	add_child(_particle_space)
	resized.connect(_layout)
	if _scenery != null:
		_build_particles()
	_layout()
	_refresh_processing()


func _process(delta: float) -> void:
	_time += delta
	_update_uniforms(delta)
	_sync_particle_rect()


## Shows `scenery` on `background` (the TextureRect drawing the skin's painting). A null scenery
## removes the material this layer added and every particle.
func configure(scenery: ArenaSceneryData, background: CanvasItem = null) -> void:
	if _background != null and is_instance_valid(_background) and _background.material == _material:
		_background.material = null
	_clear_particles()
	_scenery = scenery
	_background = background
	_material = null
	_time = 0.0
	_last_flash = -MIN_FLASH_INTERVAL
	if _scenery == null:
		_refresh_processing()
		return
	_random.seed = hash(_scenery.resource_path) if not _scenery.resource_path.is_empty() else 1
	_material = create_material(_scenery)
	if _background != null:
		_background.material = _material
	var zone_count: int = mini(_scenery.zones.size(), ZONE_SLOTS - 1)
	_zone_light = _static_zone_light(_scenery)
	_flare_wait.resize(zone_count)
	_flare_age.resize(zone_count)
	for index: int in zone_count:
		_flare_wait[index] = _next_wait(_scenery.zones[index].flare_interval)
		_flare_age[index] = -1.0
	_piece_flare_wait = _next_wait(_scenery.flare_interval)
	_piece_flare_age = -1.0
	_streak_wait = _next_wait(_scenery.streak_interval) * 0.5
	_streak_age = -1.0
	if is_node_ready():
		_build_particles()
	_layout()
	_refresh_processing()
	_update_uniforms(0.0)


## Turns motion on or off. Off (Reduced Motion) keeps the static grade and a steady glow.
func set_active(active: bool) -> void:
	_active = active
	for particles: CPUParticles2D in _particles:
		particles.emitting = active
		particles.visible = active
	_refresh_processing()
	_update_uniforms(0.0)


## Whether the scenery animates (false under Reduced Motion or without scenery).
func is_animating() -> bool:
	return is_processing()


## The shader material on the background (null without scenery).
func get_scenery_material() -> ShaderMaterial:
	return _material


## The particle nodes of the current scenery, one per emitter.
func get_particles() -> Array[CPUParticles2D]:
	return _particles


## Screen-space rectangle the background image occupies (cover or fit).
func get_image_rect() -> Rect2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Rect2()
	var scale_x: float = size.x / TEXTURE_SIZE.x
	var scale_y: float = size.y / TEXTURE_SIZE.y
	var image_scale: float = maxf(scale_x, scale_y) if cover else minf(scale_x, scale_y)
	var image_size: Vector2 = TEXTURE_SIZE * image_scale
	return Rect2((size - image_size) * 0.5, image_size)


## A scenery material with every static value set and motion off: the Reduced Motion look, used
## as-is by Shop thumbnails.
static func create_material(scenery: ArenaSceneryData) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SCENERY_SHADER
	material.set_shader_parameter(&"scenery_mask", scenery.mask)
	material.set_shader_parameter(&"scenery_zone_ids", scenery.mask)
	material.set_shader_parameter(&"motion", 0.0)
	material.set_shader_parameter(&"scenery_saturation", scenery.scenery_saturation)
	material.set_shader_parameter(&"scenery_contrast", scenery.scenery_contrast)
	material.set_shader_parameter(&"scenery_exposure", scenery.scenery_exposure)
	material.set_shader_parameter(&"shadow_lift", _color_vector(scenery.shadow_lift, scenery.shadow_lift_amount))
	material.set_shader_parameter(
		&"highlight_lift", _color_vector(scenery.highlight_lift, scenery.highlight_lift_amount)
	)
	material.set_shader_parameter(&"floor_saturation", minf(scenery.floor_saturation, ArenaSceneryData.MAX_FLOOR_SATURATION))
	var alt := PackedVector4Array()
	var fx := PackedVector4Array()
	var rates := PackedVector4Array()
	var warp := PackedVector4Array()
	var warp_mode := PackedVector4Array()
	for slot: int in ZONE_SLOTS:
		var zone: ArenaSceneryZone = scenery.zones[slot - 1] \
			if slot > 0 and slot <= scenery.zones.size() else null
		if zone == null:
			# Packed arrays are values in GDScript: append to each one directly.
			alt.append(Vector4.ZERO)
			fx.append(Vector4.ZERO)
			rates.append(Vector4.ZERO)
			warp.append(Vector4.ZERO)
			warp_mode.append(Vector4.ZERO)
			continue
		alt.append(_color_vector(zone.light_alt_color, zone.color_shift))
		fx.append(Vector4(zone.twinkle, zone.travel, zone.travel_cycles, zone.color_shift_cycles))
		rates.append(Vector4(zone.twinkle_hz, zone.travel_hz, zone.color_shift_hz, zone.sweep_weight))
		warp.append(Vector4(zone.warp_px, zone.warp_hz, zone.warp_cycles, 0.0))
		var weights := Vector4.ZERO
		if zone.warp_mode != ArenaSceneryZone.WarpMode.NONE:
			weights[zone.warp_mode - 1] = 1.0
		warp_mode.append(weights)
	material.set_shader_parameter(&"zone_light", _static_zone_light(scenery))
	material.set_shader_parameter(&"zone_alt", alt)
	material.set_shader_parameter(&"zone_fx", fx)
	material.set_shader_parameter(&"zone_rates", rates)
	material.set_shader_parameter(&"zone_warp", warp)
	material.set_shader_parameter(&"zone_warp_mode", warp_mode)
	material.set_shader_parameter(&"piece_kind", int(scenery.piece_kind))
	var centre: Vector2 = scenery.piece_center_uv * TEXTURE_SIZE
	material.set_shader_parameter(
		&"piece_shape", Vector4(centre.x, centre.y, scenery.piece_radius_px, scenery.piece_extent_px)
	)
	material.set_shader_parameter(&"piece_color", _color_vector(scenery.piece_color, 1.0))
	material.set_shader_parameter(&"flare_color", _color_vector(scenery.flare_color, 1.0))
	material.set_shader_parameter(&"piece_params", _piece_params(scenery, 0.0))
	material.set_shader_parameter(&"sweep_color", _color_vector(scenery.sweep_color, 1.0))
	material.set_shader_parameter(&"streak_color", _color_vector(scenery.streak_color, 1.0))
	material.set_shader_parameter(
		&"streak_shape", Vector4(scenery.streak_length_px, scenery.streak_width_px, 0.0, 0.0)
	)
	return material


## Zone light values with no animation: base colour at base level.
static func _static_zone_light(scenery: ArenaSceneryData) -> PackedVector4Array:
	var values := PackedVector4Array()
	values.resize(ZONE_SLOTS)
	for index: int in mini(scenery.zones.size(), ZONE_SLOTS - 1):
		var zone: ArenaSceneryZone = scenery.zones[index]
		if zone != null:
			values[index + 1] = _color_vector(zone.light_color, zone.light_strength)
	return values


static func _piece_params(scenery: ArenaSceneryData, time: float) -> Vector4:
	match scenery.piece_kind:
		ArenaSceneryData.PieceKind.CORONA:
			return Vector4(
				scenery.piece_rays, fmod(time * scenery.piece_speed, TAU * 100.0),
				scenery.piece_strength, scenery.piece_ray_sharpness
			)
		ArenaSceneryData.PieceKind.SWIRL:
			# Phase 0.5 is the unrotated painting (the still look).
			var phase: float = fmod(0.5 + time * scenery.piece_speed, 1.0)
			return Vector4(scenery.piece_swirl_radians, phase, scenery.piece_strength, 0.0)
	return Vector4.ZERO


static func _color_vector(color: Color, w: float) -> Vector4:
	return Vector4(color.r, color.g, color.b, w)


func _update_uniforms(delta: float) -> void:
	if _material == null:
		return
	var moving: bool = _active and is_processing()
	_material.set_shader_parameter(&"motion", 1.0 if moving else 0.0)
	_material.set_shader_parameter(&"scenery_time", _time)
	if not moving:
		_material.set_shader_parameter(&"zone_light", _static_zone_light(_scenery))
		_material.set_shader_parameter(&"piece_params", _piece_params(_scenery, 0.0))
		_material.set_shader_parameter(&"piece_flare", Vector4.ZERO)
		_material.set_shader_parameter(&"sweep", Vector4.ZERO)
		_material.set_shader_parameter(&"streak", Vector4.ZERO)
		return
	for index: int in _flare_age.size():
		var zone: ArenaSceneryZone = _scenery.zones[index]
		if zone == null:
			continue
		var level: float = zone.light_strength
		level *= 1.0 + zone.breathe * sin(TAU * zone.breathe_hz * _time + float(index) * 1.7)
		level *= 1.0 + zone.flicker * _noise.get_noise_2d(_time * zone.flicker_hz, float(index) * 31.0) * 1.6
		level += zone.flare_boost * _advance_zone_flare(index, zone, delta)
		var cycle: float = zone.hue_cycle * (0.5 + 0.5 * sin(TAU * zone.hue_cycle_hz * _time))
		var tint: Color = zone.light_color.lerp(zone.light_alt_color, cycle)
		_zone_light[index + 1] = _color_vector(tint, maxf(level, 0.0))
	_material.set_shader_parameter(&"zone_light", _zone_light)
	_material.set_shader_parameter(&"piece_params", _piece_params(_scenery, _time))
	_material.set_shader_parameter(&"piece_flare", _advance_piece_flare(delta))
	_material.set_shader_parameter(&"sweep", _sweep_values())
	_material.set_shader_parameter(&"streak", _advance_streak(delta))


## Flare envelope 0-1 of zone `index`; lightning-like flashes share `MIN_FLASH_INTERVAL`.
func _advance_zone_flare(index: int, zone: ArenaSceneryZone, delta: float) -> float:
	if zone.flare_interval <= 0.0 or zone.flare_boost <= 0.0:
		return 0.0
	if _flare_age[index] >= 0.0:
		_flare_age[index] += delta
		var envelope: float = _envelope(_flare_age[index], zone.flare_rise, zone.flare_fade)
		if _flare_age[index] > zone.flare_rise + zone.flare_fade:
			_flare_age[index] = -1.0
		return envelope
	_flare_wait[index] -= delta
	if _flare_wait[index] > 0.0:
		return 0.0
	_flare_wait[index] = _next_wait(zone.flare_interval)
	if zone.flare_is_flash:
		if _time - _last_flash < MIN_FLASH_INTERVAL:
			return 0.0
		_last_flash = _time
	_flare_age[index] = 0.0
	return 0.0


func _advance_piece_flare(delta: float) -> Vector4:
	var scenery: ArenaSceneryData = _scenery
	if scenery.piece_kind != ArenaSceneryData.PieceKind.CORONA or scenery.flare_interval <= 0.0:
		return Vector4.ZERO
	var rise: float = scenery.flare_interval * 0.12
	var fade: float = scenery.flare_interval * 0.3
	if _piece_flare_age < 0.0:
		_piece_flare_wait -= delta
		if _piece_flare_wait <= 0.0:
			_piece_flare_wait = _next_wait(scenery.flare_interval)
			_piece_flare_age = 0.0
			_piece_flare_angle = _random.randf_range(-PI, PI)
		return Vector4.ZERO
	_piece_flare_age += delta
	var envelope: float = _envelope(_piece_flare_age, rise, fade)
	if _piece_flare_age > rise + fade:
		_piece_flare_age = -1.0
	var length: float = scenery.flare_length_px * (0.6 + 0.4 * envelope)
	return Vector4(
		_piece_flare_angle, envelope * scenery.flare_boost, length, deg_to_rad(scenery.flare_width_degrees)
	)


func _sweep_values() -> Vector4:
	var scenery: ArenaSceneryData = _scenery
	if scenery.sweep_strength <= 0.0:
		return Vector4.ZERO
	var angle: float = deg_to_rad(scenery.sweep_angle_degrees)
	var direction := Vector2.from_angle(angle)
	# The band crosses the whole canvas: from the lowest to the highest corner projection.
	var low: float = INF
	var high: float = -INF
	for corner: Vector2 in [Vector2.ZERO, Vector2(TEXTURE_SIZE.x, 0.0), TEXTURE_SIZE, Vector2(0.0, TEXTURE_SIZE.y)]:
		low = minf(low, corner.dot(direction))
		high = maxf(high, corner.dot(direction))
	var cycle: float = fmod(_time, scenery.sweep_period) / scenery.sweep_period
	if cycle > scenery.sweep_duty:
		return Vector4.ZERO
	var margin: float = scenery.sweep_width_px * 2.0
	var centre: float = lerpf(low - margin, high + margin, cycle / scenery.sweep_duty)
	return Vector4(angle, centre, scenery.sweep_width_px, scenery.sweep_strength)


func _advance_streak(delta: float) -> Vector4:
	var scenery: ArenaSceneryData = _scenery
	if scenery.streak_interval <= 0.0:
		return Vector4.ZERO
	if _streak_age < 0.0:
		_streak_wait -= delta
		if _streak_wait > 0.0:
			return Vector4.ZERO
		_streak_wait = _next_wait(scenery.streak_interval)
		_streak_age = 0.0
		_streak_heading = deg_to_rad(
			_random.randf_range(scenery.streak_angle_degrees.x, scenery.streak_angle_degrees.y)
		)
		var region := Rect2(scenery.streak_region_uv.position * TEXTURE_SIZE, scenery.streak_region_uv.size * TEXTURE_SIZE)
		var travel: Vector2 = Vector2.from_angle(_streak_heading) * scenery.streak_speed_px * scenery.streak_duration
		# Start where the whole flight stays inside the region when it can.
		var start_min: Vector2 = region.position - travel.min(Vector2.ZERO)
		var start_max: Vector2 = region.end - travel.max(Vector2.ZERO)
		_streak_start = Vector2(
			_random.randf_range(minf(start_min.x, start_max.x), maxf(start_min.x, start_max.x)),
			_random.randf_range(minf(start_min.y, start_max.y), maxf(start_min.y, start_max.y)),
		)
	_streak_age += delta
	if _streak_age > scenery.streak_duration:
		_streak_age = -1.0
		return Vector4.ZERO
	var head: Vector2 = _streak_start + Vector2.from_angle(_streak_heading) * scenery.streak_speed_px * _streak_age
	var level: float = sin(PI * _streak_age / scenery.streak_duration) * scenery.streak_strength
	return Vector4(head.x, head.y, _streak_heading, level)


func _envelope(age: float, rise: float, fade: float) -> float:
	if age < rise:
		return smoothstep(0.0, rise, age)
	return 1.0 - smoothstep(0.0, fade, age - rise)


func _next_wait(interval: float) -> float:
	if interval <= 0.0:
		return 0.0
	return interval * _random.randf_range(1.0 - FLARE_JITTER, 1.0 + FLARE_JITTER)


func _build_particles() -> void:
	_clear_particles()
	if _scenery == null:
		return
	for emitter: ArenaParticleEmitter in _scenery.emitters:
		if emitter == null or emitter.points_uv.is_empty():
			continue
		var particles := CPUParticles2D.new()
		particles.name = "Particles_%s" % emitter.emitter_name.to_snake_case()
		particles.local_coords = true
		particles.amount = emitter.amount
		particles.lifetime = emitter.lifetime
		particles.preprocess = emitter.lifetime
		particles.fixed_fps = PARTICLE_FPS
		particles.fract_delta = true
		particles.randomness = 1.0
		particles.use_fixed_seed = true
		particles.seed = emitter.random_seed
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
		var points := PackedVector2Array()
		for point: Vector2 in emitter.points_uv:
			points.append(point * TEXTURE_SIZE)
		particles.emission_points = points
		particles.direction = emitter.direction
		particles.spread = emitter.spread_degrees
		particles.gravity = emitter.gravity_px
		particles.initial_velocity_min = emitter.speed_px.x
		particles.initial_velocity_max = emitter.speed_px.y
		particles.texture = _soft_dot_texture() if emitter.sprite == ArenaParticleEmitter.Sprite.SOFT_DOT \
			else SPARKLE_TEXTURE
		var texture_width: float = float(particles.texture.get_width())
		particles.scale_amount_min = emitter.size_px.x / texture_width
		particles.scale_amount_max = emitter.size_px.y / texture_width
		if emitter.spin_degrees > 0.0:
			particles.angular_velocity_min = -emitter.spin_degrees
			particles.angular_velocity_max = emitter.spin_degrees
			particles.angle_min = -180.0
			particles.angle_max = 180.0
		particles.color_ramp = _color_ramp(emitter)
		var material := ShaderMaterial.new()
		material.shader = PARTICLE_SHADER
		material.set_shader_parameter(&"scenery_mask", _scenery.mask)
		material.set_shader_parameter(&"additive", 1.0 if emitter.additive else 0.0)
		particles.material = material
		particles.emitting = _active
		particles.visible = _active
		_particle_space.add_child(particles)
		_particles.append(particles)
		_particle_material_cache.append(material)
	_last_image_rect = Rect2()
	_sync_particle_rect()


func _clear_particles() -> void:
	for particles: CPUParticles2D in _particles:
		particles.queue_free()
	_particles.clear()
	_particle_material_cache.clear()


## Colour over life: fade in, optional brightness pulses, fade out; colour blends to `end_color`.
func _color_ramp(emitter: ArenaParticleEmitter) -> Gradient:
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array([0.0, PARTICLE_FADE_SHARE])
	var colors := PackedColorArray([
		Color(emitter.color, 0.0), Color(emitter.color, emitter.alpha),
	])
	var steps: int = emitter.pulses * 2
	for step: int in steps:
		var along: float = lerpf(PARTICLE_FADE_SHARE, 1.0 - PARTICLE_FADE_SHARE, float(step + 1) / float(steps + 1))
		var dim: float = 0.3 if step % 2 == 0 else 1.0
		offsets.append(along)
		colors.append(Color(emitter.color.lerp(emitter.end_color, along), emitter.alpha * dim))
	offsets.append(1.0 - PARTICLE_FADE_SHARE)
	colors.append(Color(emitter.end_color, emitter.alpha))
	offsets.append(1.0)
	colors.append(Color(emitter.end_color, 0.0))
	gradient.offsets = offsets
	gradient.colors = colors
	return gradient


func _sync_particle_rect() -> void:
	if _particle_space == null or _particles.is_empty():
		return
	var image: Rect2 = get_image_rect()
	var global_rect: Rect2 = get_global_transform() * image
	if global_rect.is_equal_approx(_last_image_rect):
		return
	_last_image_rect = global_rect
	_particle_space.position = image.position
	_particle_space.scale = image.size / TEXTURE_SIZE
	var rect := Vector4(global_rect.position.x, global_rect.position.y, global_rect.size.x, global_rect.size.y)
	for material: ShaderMaterial in _particle_material_cache:
		material.set_shader_parameter(&"image_rect", rect)


func _layout() -> void:
	if not is_node_ready():
		return
	_last_image_rect = Rect2()
	_sync_particle_rect()


func _refresh_processing() -> void:
	set_process(_active and _scenery != null and is_node_ready())


static func _soft_dot_texture() -> GradientTexture2D:
	if _soft_dot == null:
		var gradient := Gradient.new()
		# Bright core with a soft halo, so a small particle still reads as light.
		gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.6, 1.0])
		gradient.colors = PackedColorArray([
			Color.WHITE, Color(1.0, 1.0, 1.0, 0.8), Color(1.0, 1.0, 1.0, 0.25), Color(1.0, 1.0, 1.0, 0.0),
		])
		_soft_dot = GradientTexture2D.new()
		_soft_dot.gradient = gradient
		_soft_dot.fill = GradientTexture2D.FILL_RADIAL
		_soft_dot.fill_from = Vector2(0.5, 0.5)
		_soft_dot.fill_to = Vector2(1.0, 0.5)
		_soft_dot.width = SOFT_DOT_SIZE
		_soft_dot.height = SOFT_DOT_SIZE
	return _soft_dot
