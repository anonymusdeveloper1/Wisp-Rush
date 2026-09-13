class_name ReaperBoss
extends Node2D
## Runs the Reaper's deterministic three-phase attacks, exposed core and victory dissolve.

## Emitted when the one-based phase changes.
signal phase_changed(phase: int)
## Requests a small world-space Soul Wisp formation after Teleport Hunt arrival.
signal summon_requested(world_positions: PackedVector2Array)
## Emitted after configuration and each valid exposed-core hit.
signal health_changed(current_health: int, maximum_health: int)
## Emitted after the final dissolve with the authored encounter rewards.
signal defeated(world_position: Vector2, score_reward: int, shard_reward: int)

enum Phase { SCYTHE_SWEEP = 1, TELEPORT_HUNT = 2, DEATH_CORRIDORS = 3 }
enum CycleState { INTRO, RECOVERY, WARNING, ATTACKING, EXPOSED, DEFEATED }

const SOURCE_FRAME_SIZE: float = 444.0
## Amber marks where/when an attack lands: an outlined band that blinks faster toward the strike.
const WARNING_COLOR: Color = Palette.WARNING_AMBER
## Magenta marks the supernatural execution: a solid band with a soul-white core that never blinks.
const DANGER_COLOR: Color = Palette.RIFT_MAGENTA
## Soul-white reticle over the exposed core the Wisp should strike.
const EXPOSED_COLOR: Color = Palette.SOUL_WHITE
## Overbright sprite modulate for the brief flash toward soul white when a hit lands.
const HIT_FLASH_MODULATE: Color = Color(1.9, 2.0, 2.05, 1.0)
const HIT_FLASH_DURATION: float = 0.14
## Length of the soul-white reticle burst that confirms a core hit (shorter than any recovery).
const HIT_CONFIRM_DURATION: float = 0.22
## Share of a warning after which the amber guide stops blinking and holds solid.
const WARNING_HOLD_START: float = 0.85
const SWEEP_START_ANGLE: float = -1.35
const SWEEP_END_ANGLE: float = 1.35
## Radians of executed sweep drawn trailing behind the blade.
const SWEEP_TRAIL_ARC: float = 1.1
const SWEEP_ARC_POINTS: int = 15

## Balance and reward values for this boss.
@export var tuning: ReaperTuning

var phase: Phase = Phase.SCYTHE_SWEEP
var cycle_state: CycleState = CycleState.INTRO
var _arena_rect: Rect2 = Rect2()
## Painted floor in screen space; empty keeps rectangle-only behaviour.
var _arena_polygon: PackedVector2Array = PackedVector2Array()
var _target_position: Vector2 = Vector2.ZERO
var _last_edge_position: Vector2 = Vector2.ZERO
var _viewport_scale: float = 1.0
var _maximum_health: int = 6
var _current_health: int = 6
var _encounter_index: int = 0
var _timing_multiplier: float = 1.0
var _state_remaining: float = 0.0
var _state_duration: float = 1.0
var _last_dash_id: int = -1
var _sweep_angle: float = -1.3
var _teleport_points := PackedVector2Array()
var _true_teleport_index: int = 0
var _safe_diagonal_forward: bool = true
var _random := RandomNumberGenerator.new()
var _base_sprite_scale: Vector2 = Vector2.ONE

static var _warning_band: GradientTexture2D
static var _danger_band: GradientTexture2D

@onready var _shadow: Sprite2D = %Shadow
@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _warning_ring: Sprite2D = %WarningRing
@onready var _core_ring: Sprite2D = %CoreRing
@onready var _sweep_arc: Line2D = %SweepArc
@onready var _lane_a: Line2D = %LaneA
@onready var _lane_b: Line2D = %LaneB
@onready var _teleport_false: Sprite2D = %TeleportFalse
@onready var _teleport_true: Sprite2D = %TeleportTrue


func _ready() -> void:
	assert(tuning != null, "ReaperBoss requires ReaperTuning")
	for line: Line2D in [_sweep_arc, _lane_a, _lane_b]:
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.default_color = Color.WHITE
	for glow: Sprite2D in [_core_ring, _warning_ring, _teleport_false, _teleport_true]:
		glow.material = VfxPool.get_additive_material()
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_hide_attack_guides()
	_core_ring.visible = false
	_sprite.play(&"idle")
	_apply_visual_scale()


func _physics_process(delta: float) -> void:
	if cycle_state == CycleState.DEFEATED:
		return
	_state_remaining = maxf(0.0, _state_remaining - delta)
	match cycle_state:
		CycleState.INTRO:
			_update_intro()
		CycleState.RECOVERY:
			_update_recovery()
		CycleState.WARNING:
			_update_warning(delta)
		CycleState.ATTACKING:
			_update_attack(delta)
		CycleState.EXPOSED:
			_update_exposed()


## Configures arena scale, encounter difficulty and deterministic phase variants.
## Applies a boss variant's atlas, tuning and colours. Call before configure().
##
## Every Rift boss shares this phase machine; only presentation and tuning differ (ADR-0010).
## A variant with no `frames` keeps the scene's own animation set, which is how the base Reaper
## and its Ascended recolour both work.
func configure_variant(data: BossData) -> void:
	if data == null:
		return
	if data.tuning != null:
		tuning = data.tuning
	# add_child() runs _ready() synchronously, so the @onready nodes are already resolved here.
	if data.frames != null:
		_sprite.sprite_frames = data.frames
	_sprite.modulate = data.tint
	_warning_ring.modulate = data.accent
	_core_ring.modulate = data.accent


func configure(
	arena_rect: Rect2,
	target_position: Vector2,
	encounter_index: int,
	seed: int,
	) -> void:
	_arena_rect = arena_rect
	_target_position = target_position
	_last_edge_position = target_position
	_encounter_index = maxi(0, encounter_index)
	_random.seed = seed
	_viewport_scale = maxf(0.1, arena_rect.size.x / tuning.design_width)
	_maximum_health = tuning.base_health + _encounter_index * tuning.health_per_encounter
	# Preserve three equal phase bands even as encounters gain health.
	_maximum_health = maxi(6, int(ceil(float(_maximum_health) / 3.0)) * 3)
	_current_health = _maximum_health
	_timing_multiplier = maxf(
		tuning.minimum_timing_multiplier,
		1.0 - float(_encounter_index) * tuning.speedup_per_encounter,
	)
	global_position = arena_rect.get_center()
	phase = Phase.SCYTHE_SWEEP
	cycle_state = CycleState.INTRO
	_set_state_timer(tuning.intro_duration)
	_sprite.play(&"arrival")
	_apply_visual_scale()
	health_changed.emit(_current_health, _maximum_health)
	phase_changed.emit(int(phase))
	print(
		"[Reaper] encounter=%d health=%d timing=%.2f"
		% [_encounter_index + 1, _maximum_health, _timing_multiplier]
	)


## Updates the live Wisp position used by attacks and teleport placement.
func set_target_position(world_position: Vector2) -> void:
	_target_position = world_position


## Updates live arena bounds and visual scale without resetting encounter health or phase.
## Applies the painted floor, so the boss and its teleport marks stay on the stone.
func set_arena_polygon(polygon: PackedVector2Array) -> void:
	_arena_polygon = polygon
	if polygon.size() >= 3:
		global_position = _onto_floor(global_position)


## Moves a boss-owned point onto the floor polygon, when one is set.
##
## Teleport Hunt picks destinations from the bounding rectangle's edges, which sit in the lava on
## an oval arena. The attack grammar stays rectangle-authored; only the resulting point is made
## legal, so every boss variant keeps its tuned timing and silhouette.
func _onto_floor(point: Vector2) -> Vector2:
	if _arena_polygon.size() < 3:
		return point
	var margin: float = tuning.core_radius * _viewport_scale
	if DashGeometry.is_inside_polygon(point, _arena_polygon):
		var boundary: Vector2 = DashGeometry.nearest_polygon_point(point, _arena_polygon)
		if point.distance_to(boundary) >= margin:
			return point
	return DashGeometry.clamp_to_polygon(point, _arena_polygon, margin)


func set_arena_rect(arena_rect: Rect2) -> void:
	_arena_rect = arena_rect
	_viewport_scale = maxf(0.1, arena_rect.size.x / tuning.design_width)
	global_position = Vector2(
		clampf(global_position.x, arena_rect.position.x, arena_rect.end.x),
		clampf(global_position.y, arena_rect.position.y, arena_rect.end.y),
	)
	_apply_visual_scale()


## Updates the most recent Wisp edge used by Teleport Hunt placement.
func set_last_edge_position(world_position: Vector2) -> void:
	_last_edge_position = world_position


## Skips only the introductory hold; gameplay phase warnings remain unskippable.
func skip_intro() -> void:
	if cycle_state == CycleState.INTRO:
		_state_remaining = 0.0


## Returns the current health.
func get_current_health() -> int:
	return _current_health


## Returns encounter-scaled maximum health.
func get_maximum_health() -> int:
	return _maximum_health


## Returns whether the core currently accepts one hit from a new dash identifier.
func is_core_exposed() -> bool:
	return cycle_state == CycleState.EXPOSED


## Returns the current one-based phase.
func get_phase() -> int:
	return int(phase)


## Returns current circle dangers as world x/y/radius triples.
func get_dangerous_circles() -> Array[Vector3]:
	var result: Array[Vector3] = []
	if cycle_state != CycleState.ATTACKING:
		return result
	if phase == Phase.SCYTHE_SWEEP:
		var centre: Vector2 = global_position + Vector2.RIGHT.rotated(_sweep_angle) * (
			tuning.sweep_radius * _viewport_scale
		)
		result.append(Vector3(centre.x, centre.y, tuning.sweep_blade_radius * _viewport_scale))
	elif phase == Phase.TELEPORT_HUNT:
		result.append(
			Vector3(
				global_position.x,
				global_position.y,
				tuning.core_radius * 1.65 * _viewport_scale,
			)
		)
	return result


## Returns active death corridors as pairs of world-space line points.
func get_dangerous_lanes() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if cycle_state != CycleState.ATTACKING or phase != Phase.DEATH_CORRIDORS:
		return result
	for line: Line2D in [_lane_a, _lane_b]:
		result.append(PackedVector2Array([to_global(line.points[0]), to_global(line.points[1])]))
	return result


## Returns the viewport-scaled half width of active death corridors.
func get_lane_radius() -> float:
	return tuning.lane_radius * _viewport_scale


## Applies one exposed-core hit per dash; boss damage is intentionally capped at one.
func try_dash_hit(
	segment_start: Vector2,
	segment_end: Vector2,
	corridor_radius: float,
	_damage: int,
	dash_id: int,
	) -> bool:
	if not is_core_exposed() or dash_id == _last_dash_id:
		return false
	var hit_distance: float = DashGeometry.distance_to_segment(
		global_position,
		segment_start,
		segment_end,
	)
	if hit_distance > corridor_radius + tuning.core_radius * _viewport_scale:
		return false
	_last_dash_id = dash_id
	_current_health -= 1
	health_changed.emit(_current_health, _maximum_health)
	if _current_health <= 0:
		_begin_defeat()
	else:
		_core_ring.visible = false
		var next_phase: Phase = _phase_for_health()
		var phase_broken: bool = next_phase != phase
		if phase_broken:
			phase = next_phase
			phase_changed.emit(int(phase))
		_begin_recovery(tuning.recovery_duration)
		# Recovery resets the pose, so the reaction plays after it: a full recoil when a phase
		# breaks, otherwise a short stagger. Both return to idle when they finish.
		_sprite.play(&"hit" if phase_broken else &"stagger")
		_play_hit_flash()
	return true


func _update_intro() -> void:
	var progress: float = 1.0 - _timer_progress()
	_sprite.modulate.a = lerpf(0.1, 1.0, progress)
	_warning_ring.visible = true
	_warning_ring.modulate.a = lerpf(0.35, 0.85, VfxPool.countdown_blink(progress))
	_warning_ring.rotation += 0.018
	if _state_remaining <= 0.0:
		_sprite.modulate = Color.WHITE
		_warning_ring.visible = false
		_begin_recovery(0.35)


func _update_recovery() -> void:
	_sprite.position.y = sin(Time.get_ticks_msec() * 0.0025) * 8.0 * _viewport_scale
	if _state_remaining > 0.0:
		return
	match phase:
		Phase.SCYTHE_SWEEP:
			_begin_scythe_warning()
		Phase.TELEPORT_HUNT:
			_begin_teleport_warning()
		Phase.DEATH_CORRIDORS:
			_begin_corridor_warning()


func _update_warning(delta: float) -> void:
	var progress: float = 1.0 - _timer_progress()
	var blink: float = 1.0 if progress >= WARNING_HOLD_START else VfxPool.countdown_blink(progress)
	var alpha: float = lerpf(0.4, 1.0, blink)
	match phase:
		Phase.SCYTHE_SWEEP:
			_sweep_arc.modulate.a = alpha
		Phase.TELEPORT_HUNT:
			_teleport_false.modulate.a = alpha * 0.5
			_teleport_true.modulate.a = alpha
			_teleport_false.rotation -= delta * 1.1
			_teleport_true.rotation += delta * 1.8
		Phase.DEATH_CORRIDORS:
			_lane_a.modulate.a = alpha
			_lane_b.modulate.a = alpha
	if _state_remaining <= 0.0:
		_begin_attack()


func _update_attack(delta: float) -> void:
	match phase:
		Phase.SCYTHE_SWEEP:
			var progress: float = 1.0 - _timer_progress()
			_sweep_angle = lerpf(SWEEP_START_ANGLE, SWEEP_END_ANGLE, progress)
			_sprite.rotation = sin(progress * PI) * 0.2
			_set_sweep_arc(maxf(SWEEP_START_ANGLE, _sweep_angle - SWEEP_TRAIL_ARC), _sweep_angle)
		Phase.DEATH_CORRIDORS:
			# Near-solid flicker: the execution never blinks the way its warning did.
			_lane_a.modulate.a = 0.9 + sin(Time.get_ticks_msec() * 0.02) * 0.1
			_lane_b.modulate.a = _lane_a.modulate.a
		Phase.TELEPORT_HUNT:
			_sprite.rotation += delta * 2.0
	if _state_remaining <= 0.0:
		_begin_exposed()


func _update_exposed() -> void:
	var pulse: float = 0.9 + sin(Time.get_ticks_msec() * 0.014) * 0.13
	_core_ring.scale = _base_sprite_scale * pulse
	if _state_remaining <= 0.0:
		_core_ring.visible = false
		_begin_recovery(tuning.recovery_duration)


func _begin_scythe_warning() -> void:
	cycle_state = CycleState.WARNING
	_set_state_timer(tuning.warning_duration)
	_hide_attack_guides()
	_sprite.play(&"windup")
	SoundFx.play(&"reaper_windup")
	# The band is as wide as the blade's danger circle, so it shows exactly where it will pass.
	_show_guide(_sweep_arc, false, tuning.sweep_blade_radius * 2.0 * _viewport_scale)
	_set_sweep_arc(SWEEP_START_ANGLE, SWEEP_END_ANGLE)


func _begin_teleport_warning() -> void:
	cycle_state = CycleState.WARNING
	_set_state_timer(tuning.warning_duration)
	_hide_attack_guides()
	_sprite.play(&"vanish")
	SoundFx.play(&"reaper_appear", 1.5, -8.0)
	var inset: Vector2 = _arena_rect.size * Vector2(0.22, 0.25)
	var first: Vector2 = Vector2(
		clampf(_last_edge_position.x, _arena_rect.position.x + inset.x, _arena_rect.end.x - inset.x),
		_arena_rect.position.y + inset.y,
	)
	var second: Vector2 = _arena_rect.position + _arena_rect.size - (
		first - _arena_rect.position
	)
	_teleport_points = PackedVector2Array([_onto_floor(first), _onto_floor(second)])
	_true_teleport_index = _random.randi_range(0, 1)
	_teleport_false.global_position = _teleport_points[1 - _true_teleport_index]
	_teleport_true.global_position = _teleport_points[_true_teleport_index]
	_teleport_false.visible = true
	_teleport_true.visible = true


func _begin_corridor_warning() -> void:
	cycle_state = CycleState.WARNING
	_set_state_timer(tuning.warning_duration)
	_hide_attack_guides()
	_sprite.play(&"cast")
	SoundFx.play(&"reaper_windup")
	_safe_diagonal_forward = _random.randf() >= 0.5
	var width: float = _arena_rect.size.x
	var height: float = _arena_rect.size.y
	var lane_one := PackedVector2Array()
	var lane_two := PackedVector2Array()
	if _safe_diagonal_forward:
		lane_one = PackedVector2Array([
			Vector2(-width * 0.5, height * 0.15),
			Vector2(width * 0.15, -height * 0.5),
		])
		lane_two = PackedVector2Array([
			Vector2(-width * 0.15, height * 0.5),
			Vector2(width * 0.5, -height * 0.15),
		])
	else:
		lane_one = PackedVector2Array([
			Vector2(-width * 0.5, -height * 0.15),
			Vector2(width * 0.15, height * 0.5),
		])
		lane_two = PackedVector2Array([
			Vector2(-width * 0.15, -height * 0.5),
			Vector2(width * 0.5, height * 0.15),
		])
	_lane_a.points = lane_one
	_lane_b.points = lane_two
	for line: Line2D in [_lane_a, _lane_b]:
		_show_guide(line, false, tuning.lane_radius * 2.0 * _viewport_scale)


func _begin_attack() -> void:
	cycle_state = CycleState.ATTACKING
	match phase:
		Phase.SCYTHE_SWEEP:
			_set_state_timer(tuning.sweep_duration)
			_sweep_angle = SWEEP_START_ANGLE
			_show_guide(_sweep_arc, true, _sweep_arc.width)
			_set_sweep_arc(SWEEP_START_ANGLE, SWEEP_START_ANGLE)
			_sprite.play(&"strike")
			SoundFx.play(&"reaper_sweep")
		Phase.TELEPORT_HUNT:
			_set_state_timer(tuning.teleport_attack_duration)
			global_position = _teleport_points[_true_teleport_index]
			_teleport_false.visible = false
			_teleport_true.visible = false
			_sprite.modulate = Color.WHITE
			_sprite.play(&"appear")
			SoundFx.play(&"reaper_appear", 1.2, -5.0)
			summon_requested.emit(_make_summon_line())
		Phase.DEATH_CORRIDORS:
			_set_state_timer(tuning.corridor_duration)
			for line: Line2D in [_lane_a, _lane_b]:
				_show_guide(line, true, line.width)
			_sprite.play(&"strike")
			SoundFx.play(&"reaper_sweep")


func _begin_exposed() -> void:
	cycle_state = CycleState.EXPOSED
	_set_state_timer(tuning.exposed_duration)
	_hide_attack_guides()
	_sprite.rotation = 0.0
	_sprite.play(&"exposed")
	_core_ring.visible = true
	_core_ring.modulate = EXPOSED_COLOR


func _begin_recovery(duration: float) -> void:
	cycle_state = CycleState.RECOVERY
	_set_state_timer(duration)
	_hide_attack_guides()
	_core_ring.visible = false
	_sprite.rotation = 0.0
	_sprite.modulate = Color.WHITE
	_sprite.play(&"idle")


func _begin_defeat() -> void:
	cycle_state = CycleState.DEFEATED
	_hide_attack_guides()
	_core_ring.visible = false
	_sprite.rotation = 0.0
	_sprite.play(&"defeated")
	SoundFx.play(&"reaper_defeat")
	_sprite.modulate = HIT_FLASH_MODULATE
	var dissolve: Tween = create_tween().set_parallel(true)
	dissolve.tween_property(_sprite, "scale", _base_sprite_scale * 1.35, 0.75)
	dissolve.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.75)
	dissolve.tween_property(_warning_ring, "scale", _base_sprite_scale * 2.5, 0.75)
	dissolve.tween_property(_warning_ring, "modulate:a", 0.0, 0.75)
	_warning_ring.visible = true
	dissolve.chain().tween_callback(
		func() -> void:
			defeated.emit(global_position, tuning.score_reward, tuning.shard_reward)
			queue_free()
	)


func _phase_for_health() -> Phase:
	var band: int = _maximum_health / 3
	if _current_health > band * 2:
		return Phase.SCYTHE_SWEEP
	if _current_health > band:
		return Phase.TELEPORT_HUNT
	return Phase.DEATH_CORRIDORS


func _make_summon_line() -> PackedVector2Array:
	var direction: Vector2 = (_target_position - global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	var tangent := Vector2(-direction.y, direction.x)
	var spacing: float = 105.0 * _viewport_scale
	return PackedVector2Array([
		global_position - tangent * spacing,
		global_position + direction * spacing * 1.2,
		global_position + tangent * spacing,
	])


func _hide_attack_guides() -> void:
	_sweep_arc.visible = false
	_lane_a.visible = false
	_lane_b.visible = false
	_teleport_false.visible = false
	_teleport_true.visible = false


func _set_state_timer(base_duration: float) -> void:
	_state_duration = maxf(0.01, base_duration * _timing_multiplier)
	_state_remaining = _state_duration


func _timer_progress() -> float:
	return _state_remaining / maxf(_state_duration, 0.01)


func _apply_visual_scale() -> void:
	if not is_node_ready() or tuning == null:
		return
	_base_sprite_scale = Vector2.ONE * (
		tuning.sprite_diameter * _viewport_scale / SOURCE_FRAME_SIZE
	)
	_sprite.scale = _base_sprite_scale
	_shadow.scale = Vector2(_base_sprite_scale.x * 0.95, _base_sprite_scale.y * 0.4)
	_warning_ring.scale = _base_sprite_scale * 1.15
	_core_ring.scale = _base_sprite_scale
	_teleport_false.scale = _base_sprite_scale * 0.85
	_teleport_true.scale = _base_sprite_scale * 0.95


## Shows `line` as an amber warning outline or a magenta execution band of `width` pixels.
func _show_guide(line: Line2D, danger: bool, width: float) -> void:
	line.texture = _get_band_texture(danger)
	line.width = width
	line.modulate.a = 1.0
	line.visible = true


func _set_sweep_arc(from_angle: float, to_angle: float) -> void:
	var radius: float = tuning.sweep_radius * _viewport_scale
	var points := PackedVector2Array()
	points.resize(SWEEP_ARC_POINTS)
	for index: int in SWEEP_ARC_POINTS:
		var weight: float = float(index) / float(SWEEP_ARC_POINTS - 1)
		points[index] = Vector2.RIGHT.rotated(lerpf(from_angle, to_angle, weight)) * radius
	_sweep_arc.points = points


func _play_hit_flash() -> void:
	_sprite.modulate = HIT_FLASH_MODULATE
	var flash: Tween = create_tween().set_parallel(true)
	flash.tween_property(_sprite, "modulate", Color.WHITE, HIT_FLASH_DURATION)
	# A soul-white reticle burst confirms the core hit, since the dark silhouette barely brightens.
	_core_ring.visible = true
	_core_ring.modulate = EXPOSED_COLOR
	_core_ring.scale = _base_sprite_scale
	flash.tween_property(_core_ring, "scale", _base_sprite_scale * 1.6, HIT_CONFIRM_DURATION)
	flash.tween_property(_core_ring, "modulate:a", 0.0, HIT_CONFIRM_DURATION)
	flash.chain().tween_callback(
		func() -> void: _core_ring.visible = cycle_state == CycleState.EXPOSED
	)


func _on_sprite_animation_finished() -> void:
	if cycle_state == CycleState.RECOVERY and _sprite.animation in [&"hit", &"stagger"]:
		_sprite.play(&"idle")


## Returns the shared band texture mapped across a Line2D's width (v runs edge to edge).
static func _get_band_texture(danger: bool) -> GradientTexture2D:
	if _warning_band == null:
		var edge := Color(WARNING_COLOR, 0.95)
		var fill := Color(WARNING_COLOR, 0.14)
		_warning_band = _make_band_texture(
			PackedFloat32Array([0.0, 0.12, 0.22, 0.78, 0.88, 1.0]),
			PackedColorArray([edge, edge, fill, fill, edge, edge]),
		)
		var rim := Color(DANGER_COLOR, 0.6)
		var body := Color(DANGER_COLOR, 0.92)
		var core := Color(Palette.SOUL_WHITE, 1.0)
		_danger_band = _make_band_texture(
			PackedFloat32Array([0.0, 0.25, 0.43, 0.5, 0.57, 0.75, 1.0]),
			PackedColorArray([rim, body, body, core, body, body, rim]),
		)
	return _danger_band if danger else _warning_band


static func _make_band_texture(
		offsets: PackedFloat32Array,
		colors: PackedColorArray,
	) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 4
	texture.height = 64
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	return texture
