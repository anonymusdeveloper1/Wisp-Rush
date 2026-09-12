class_name WispPlayer
extends CharacterBody2D
## Converts swipe, mouse and keyboard aim into an exact edge-to-edge Wisp dash.
##
## Owns the player state machine and presentation. It emits authoritative swept segments upward;
## collision targets and run rules remain the GameWorld's responsibility.

## Emitted when a valid dash enters its short windup.
signal dash_started(direction: Vector2, dash_id: int)
## Emitted for every authoritative movement segment while dashing.
signal dash_segment_swept(
	start: Vector2,
	end: Vector2,
	dash_id: int,
	corridor_radius: float,
)
## Emitted when a dash stops at its precomputed arena edge.
signal wall_impacted(world_position: Vector2, inward_normal: Vector2, dash_id: int)
## Requests run-local enemy and hazard slowdown without slowing input or UI.
signal focus_started(duration: float, world_speed: float)
## Emitted when an indestructible obstacle truncates an active dash.
signal obstacle_impacted(world_position: Vector2, impact_normal: Vector2, dash_id: int)
## Emitted whenever the visible Soul Fragment count changes.
signal health_changed(current_health: int, maximum_health: int)
## Emitted after one valid enemy contact removes a Soul Fragment.
signal damaged(current_health: int, maximum_health: int)
## Emitted once after the zero-health death dissolve finishes.
signal died

## Complete player state vocabulary defined by GDD §5.1.
enum State {
	SPAWNING,
	WAITING_AT_EDGE,
	AIMING,
	WINDUP,
	DASHING,
	WALL_IMPACT,
	HURT,
	DEAD,
	VICTORY,
}

const ACTION_MOVE_LEFT: StringName = &"move_left"
const ACTION_MOVE_RIGHT: StringName = &"move_right"
const ACTION_MOVE_UP: StringName = &"move_up"
const ACTION_MOVE_DOWN: StringName = &"move_down"
const ACTION_DASH: StringName = &"dash"
const INVALID_POINTER: int = -99
const MOUSE_POINTER: int = -1
const SOURCE_FRAME_SIZE: float = 362.0
const FORM_SOURCE_SIZE: float = 512.0
## Idle breathing while waiting at an edge: a 2.5 % scale swing over a slow cycle (STYLE_GUIDE).
const IDLE_BREATH_AMOUNT: float = 0.025
const IDLE_BREATH_PERIOD: float = 2.6

## Gesture, movement and presentation values for this Wisp instance.
@export var tuning: PlayerTuning
## Damage applied by a base dash before run upgrades.
@export_range(1, 100, 1) var dash_damage: int = 1

## Current authoritative movement/input state; external systems should observe signals for events.
var state: State = State.SPAWNING
var _arena_rect: Rect2 = Rect2()
var _play_bounds: Rect2 = Rect2()
var _arena_initialized: bool = false
var _active_pointer: int = INVALID_POINTER
var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO
var _aim_direction: Vector2 = Vector2.UP
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_target: Vector2 = Vector2.ZERO
var _dash_id: int = 0
var _blade_width_multiplier: float = 1.0
var _dash_speed_multiplier: float = 1.0
var _player_radius: float = 32.0
var _viewport_scale: float = 1.0
var _state_time_remaining: float = 0.0
var _invulnerability_remaining: float = 0.0
var _invulnerability_elapsed: float = 0.0
var _death_reported: bool = false
var _base_sprite_scale: Vector2 = Vector2.ONE
var _impact_tween: Tween
var _cosmetic_texture: Texture2D
var _cosmetic_tint: Color = Palette.SOUL_CYAN
var _breath_time: float = 0.0
var _reduced_motion: bool = false

@onready var _health: HealthComponent = %HealthComponent
@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _form_sprite: Sprite2D = %FormSprite
@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _aim_line: Line2D = %AimLine
@onready var _impact_point: Polygon2D = %ImpactPoint
@onready var _impact_burst: Sprite2D = %ImpactBurst


func _ready() -> void:
	assert(tuning != null, "WispPlayer requires PlayerTuning")
	_health.health_changed.connect(_on_health_changed)
	_health.depleted.connect(_on_health_depleted)
	_health.configure(tuning.maximum_health)
	_state_time_remaining = tuning.spawn_duration
	_sprite.play(&"reform")
	_aim_line.visible = false
	_impact_point.visible = false
	_impact_burst.visible = false
	_apply_cosmetic_form()
	_reduced_motion = _read_reduced_motion()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_pointer(touch.position, touch.index)
		else:
			_end_pointer(touch.position, touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_update_pointer(drag.position, drag.index)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_begin_pointer(button.position, MOUSE_POINTER)
			else:
				_end_pointer(button.position, MOUSE_POINTER)
	elif event is InputEventMouseMotion and _active_pointer == MOUSE_POINTER:
		var motion := event as InputEventMouseMotion
		_update_pointer(motion.position, MOUSE_POINTER)


func _process(delta: float) -> void:
	if _reduced_motion or (state != State.WAITING_AT_EDGE and state != State.AIMING):
		return
	_breath_time += delta
	var breath: float = 1.0 + sin(_breath_time * TAU / IDLE_BREATH_PERIOD) * IDLE_BREATH_AMOUNT
	_sprite.scale = _base_sprite_scale * breath
	_sync_form_visual()


func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	match state:
		State.SPAWNING:
			_state_time_remaining -= delta
			if _state_time_remaining <= 0.0:
				_enter_waiting()
		State.WAITING_AT_EDGE, State.AIMING:
			_process_keyboard_aim()
		State.WINDUP:
			_state_time_remaining -= delta
			if _state_time_remaining <= 0.0:
				_begin_dash_motion()
		State.DASHING:
			_advance_dash(delta)
		State.WALL_IMPACT:
			_state_time_remaining -= delta
			if _state_time_remaining <= 0.0:
				_enter_waiting()
		State.HURT:
			_state_time_remaining -= delta
			if _state_time_remaining <= 0.0:
				_enter_waiting()
		State.DEAD:
			_state_time_remaining -= delta
			if _state_time_remaining <= 0.0 and not _death_reported:
				_death_reported = true
				died.emit()
		State.VICTORY:
			_state_time_remaining -= delta
			if _state_time_remaining <= 0.0:
				_enter_waiting()
	_sync_form_visual()


## Resolves an arbitrary direction into one normalized, inward, first-edge dash.
func request_dash(direction: Vector2) -> void:
	if state != State.WAITING_AT_EDGE and state != State.AIMING:
		return
	if not _arena_initialized or direction.is_zero_approx():
		return

	_dash_direction = DashGeometry.reflect_inward(
		direction,
		position,
		_play_bounds,
		maxf(1.0, _player_radius * 0.2),
	)
	_dash_target = DashGeometry.ray_to_rect_edge(position, _dash_direction, _play_bounds)
	if position.distance_squared_to(_dash_target) <= 1.0:
		return

	_dash_id += 1
	state = State.WINDUP
	_state_time_remaining = tuning.windup_duration
	_active_pointer = INVALID_POINTER
	_hide_aim_preview()
	_sprite.rotation = _dash_direction.angle()
	_sprite.play(&"charge")
	_sprite.scale = _base_sprite_scale
	dash_started.emit(_dash_direction, _dash_id)


## Applies the live viewport rectangle and safely rescales/repositions the Wisp.
func set_arena_rect(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	_arena_rect = rect
	_viewport_scale = rect.size.x / tuning.design_width
	_player_radius = clampf(
		rect.size.x * tuning.radius_viewport_ratio,
		tuning.minimum_radius,
		tuning.maximum_radius,
	)
	# The art extends slightly beyond its gameplay circle; this keeps it readable at physical edges.
	_play_bounds = rect.grow(-_player_radius * 1.35)
	var circle := _collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = _player_radius

	var visual_diameter: float = _player_radius * 3.35
	_base_sprite_scale = Vector2.ONE * (visual_diameter / SOURCE_FRAME_SIZE)
	_sprite.scale = _base_sprite_scale
	_impact_burst.scale = Vector2.ONE * (_player_radius * 3.8 / SOURCE_FRAME_SIZE)
	_aim_line.width = clampf(_player_radius * 0.11, 2.0, 6.0)
	_impact_point.scale = Vector2.ONE * clampf(_player_radius / 32.0, 0.7, 1.45)

	if not _arena_initialized:
		position = Vector2(_play_bounds.get_center().x, _play_bounds.end.y)
		_arena_initialized = true
	else:
		position = Vector2(
			clampf(position.x, _play_bounds.position.x, _play_bounds.end.x),
			clampf(position.y, _play_bounds.position.y, _play_bounds.end.y),
		)
		if state != State.DASHING and state != State.WINDUP:
			_snap_to_nearest_edge()
	if state == State.AIMING:
		_update_aim_preview(_aim_direction)


## Cancels an unresolved gesture, used before pausing or replacing the game screen.
func cancel_active_aim() -> void:
	_active_pointer = INVALID_POINTER
	if state == State.AIMING:
		_enter_waiting()


## Returns the live collision radius in viewport pixels for debug and encounter spacing.
func get_collision_radius() -> float:
	return _player_radius


## Returns the current number of Soul Fragments.
func get_current_health() -> int:
	return _health.get_current_health()


## Returns the run's current maximum number of Soul Fragments.
func get_maximum_health() -> int:
	return _health.maximum_health


## Applies run-local dash damage, corridor-width and speed mutation results.
func set_run_combat_modifiers(damage: int, blade_width: float, dash_speed: float) -> void:
	dash_damage = maxi(1, damage)
	_blade_width_multiplier = clampf(blade_width, 1.0, 2.5)
	_dash_speed_multiplier = clampf(dash_speed, 1.0, 1.5)


## Applies a persistent form to presentation only; combat geometry and tuning never change.
func set_cosmetic_form(texture: Texture2D, tint: Color) -> void:
	_cosmetic_texture = texture
	_cosmetic_tint = tint
	if is_node_ready():
		_apply_cosmetic_form()


## Returns the current run-local damaging-corridor multiplier.
func get_blade_width_multiplier() -> float:
	return _blade_width_multiplier


## Returns the current run-local dash-speed multiplier.
func get_dash_speed_multiplier() -> float:
	return _dash_speed_multiplier


## Adds maximum Soul Fragments and restores a separate clamped amount.
func increase_maximum_health(amount: int, heal_amount: int) -> void:
	if amount <= 0:
		return
	_health.configure(_health.maximum_health + amount, false)
	_health.heal(heal_amount)


## Restores clamped Soul Fragments and returns whether health changed.
func heal(amount: int) -> bool:
	return _health.heal(amount)


## Plays a non-interactive boss-victory pulse before returning to edge-ready input.
func play_victory(duration: float) -> void:
	if state == State.DEAD or _health.is_depleted():
		return
	state = State.VICTORY
	_state_time_remaining = maxf(0.1, duration)
	_active_pointer = INVALID_POINTER
	velocity = Vector2.ZERO
	_hide_aim_preview()
	_sprite.rotation = 0.0
	_sprite.play(&"victory")


## Returns whether ordinary enemy contact may currently damage the Wisp.
func is_vulnerable() -> bool:
	if _health.is_depleted() or _invulnerability_remaining > 0.0:
		return false
	return state in [State.WAITING_AT_EDGE, State.AIMING, State.WINDUP]


## Applies one contact hit and reforms at the safe world-space edge selected by GameWorld.
func take_contact_damage(safe_edge_position: Vector2) -> bool:
	if not is_vulnerable():
		return false
	return _take_damage(safe_edge_position)


## Applies one telegraphed hazard hit, including while dashing, then reforms safely.
func take_hazard_damage(safe_edge_position: Vector2) -> bool:
	if (
		_health.is_depleted()
		or _invulnerability_remaining > 0.0
		or state in [State.SPAWNING, State.HURT, State.DEAD, State.VICTORY]
	):
		return false
	return _take_damage(safe_edge_position)


## Stops an active dash at an indestructible obstacle and enters normal impact recovery.
func interrupt_dash_at(world_position: Vector2, impact_normal: Vector2) -> bool:
	if state != State.DASHING:
		return false
	global_position = world_position
	velocity = Vector2.ZERO
	state = State.WALL_IMPACT
	_state_time_remaining = tuning.wall_impact_duration
	_sprite.rotation = 0.0
	_sprite.play(&"wall_impact")
	_play_impact_feedback(impact_normal)
	obstacle_impacted.emit(global_position, impact_normal, _dash_id)
	focus_started.emit(tuning.focus_duration, tuning.focus_world_speed)
	return true


func _take_damage(safe_edge_position: Vector2) -> bool:
	_active_pointer = INVALID_POINTER
	velocity = Vector2.ZERO
	_hide_aim_preview()
	global_position = safe_edge_position
	_snap_to_nearest_edge()
	_invulnerability_remaining = tuning.invulnerability_duration
	_invulnerability_elapsed = 0.0
	if not _health.apply_damage(1):
		return false
	if not _health.is_depleted():
		state = State.HURT
		_state_time_remaining = tuning.hurt_duration
		_sprite.rotation = 0.0
		_sprite.scale = _base_sprite_scale
		_sprite.play(&"hurt")
	damaged.emit(_health.get_current_health(), _health.maximum_health)
	return true


func _process_keyboard_aim() -> void:
	if _active_pointer != INVALID_POINTER:
		return
	var keyboard_direction := Input.get_vector(
		ACTION_MOVE_LEFT,
		ACTION_MOVE_RIGHT,
		ACTION_MOVE_UP,
		ACTION_MOVE_DOWN,
	)
	if not keyboard_direction.is_zero_approx():
		_aim_direction = keyboard_direction.normalized()
		state = State.AIMING
		_update_aim_preview(_aim_direction)
	elif state == State.AIMING:
		state = State.WAITING_AT_EDGE
		_hide_aim_preview()
	if Input.is_action_just_pressed(ACTION_DASH):
		request_dash(_aim_direction)


func _begin_pointer(screen_position: Vector2, pointer_id: int) -> void:
	if _active_pointer != INVALID_POINTER:
		return
	if state != State.WAITING_AT_EDGE and state != State.AIMING:
		return
	_active_pointer = pointer_id
	_drag_start = screen_position
	_drag_current = screen_position
	state = State.AIMING


func _update_pointer(screen_position: Vector2, pointer_id: int) -> void:
	if pointer_id != _active_pointer or state != State.AIMING:
		return
	_drag_current = screen_position
	var drag_vector: Vector2 = _drag_current - _drag_start
	if drag_vector.length() >= _minimum_swipe_distance():
		_aim_direction = drag_vector.normalized()
		_update_aim_preview(_aim_direction)


func _end_pointer(screen_position: Vector2, pointer_id: int) -> void:
	if pointer_id != _active_pointer:
		return
	_drag_current = screen_position
	_active_pointer = INVALID_POINTER
	var drag_vector: Vector2 = _drag_current - _drag_start
	if drag_vector.length() >= _minimum_swipe_distance():
		request_dash(drag_vector)
	else:
		_enter_waiting()


func _minimum_swipe_distance() -> float:
	return tuning.minimum_swipe_distance * maxf(0.75, _viewport_scale)


func _update_aim_preview(direction: Vector2) -> void:
	var resolved_direction: Vector2 = DashGeometry.reflect_inward(
		direction,
		position,
		_play_bounds,
		maxf(1.0, _player_radius * 0.2),
	)
	var target: Vector2 = DashGeometry.ray_to_rect_edge(position, resolved_direction, _play_bounds)
	_aim_line.points = PackedVector2Array([Vector2.ZERO, to_local(target)])
	_aim_line.visible = true
	_impact_point.position = to_local(target)
	_impact_point.visible = true
	_sprite.rotation = clampf(resolved_direction.angle(), -0.42, 0.42)


func _hide_aim_preview() -> void:
	_aim_line.visible = false
	_impact_point.visible = false


func _begin_dash_motion() -> void:
	state = State.DASHING
	var faces_left: bool = _dash_direction.x < 0.0
	_sprite.play(&"dash_left" if faces_left else &"dash_right")
	_sprite.rotation = _dash_direction.angle() - (PI if faces_left else 0.0)


func _advance_dash(delta: float) -> void:
	var previous_global_position: Vector2 = global_position
	var remaining_distance: float = position.distance_to(_dash_target)
	var speed: float = tuning.dash_speed * _dash_speed_multiplier * _viewport_scale
	var step_distance: float = speed * delta
	velocity = _dash_direction * speed
	if step_distance >= remaining_distance:
		position = _dash_target
	else:
		position += _dash_direction * step_distance
	var corridor_radius: float = (
		(_player_radius + tuning.blade_bonus * _viewport_scale) * _blade_width_multiplier
	)
	dash_segment_swept.emit(
		previous_global_position,
		global_position,
		_dash_id,
		corridor_radius,
	)
	if state != State.DASHING:
		return
	if step_distance >= remaining_distance:
		_finish_dash()


func _finish_dash() -> void:
	velocity = Vector2.ZERO
	state = State.WALL_IMPACT
	_state_time_remaining = tuning.wall_impact_duration
	var inward_normal: Vector2 = DashGeometry.inward_edge_normal(position, _play_bounds)
	_sprite.rotation = 0.0
	_sprite.play(&"wall_impact")
	_play_impact_feedback(inward_normal)
	wall_impacted.emit(global_position, inward_normal, _dash_id)
	focus_started.emit(tuning.focus_duration, tuning.focus_world_speed)


func _play_impact_feedback(inward_normal: Vector2) -> void:
	if _impact_tween != null and _impact_tween.is_valid():
		_impact_tween.kill()
	_impact_burst.visible = true
	_impact_burst.modulate = Color(_cosmetic_tint.r, _cosmetic_tint.g, _cosmetic_tint.b, 0.9)
	_impact_burst.rotation = inward_normal.angle()
	_impact_burst.scale = Vector2.ONE * (_player_radius * 2.4 / SOURCE_FRAME_SIZE)
	var squash: Vector2 = Vector2(_base_sprite_scale.x * 1.18, _base_sprite_scale.y * 0.78)
	if absf(inward_normal.x) > 0.5:
		squash = Vector2(_base_sprite_scale.x * 0.78, _base_sprite_scale.y * 1.18)
	_sprite.scale = squash
	_impact_tween = create_tween().set_parallel(true)
	_impact_tween.tween_property(
		_impact_burst,
		"scale",
		Vector2.ONE * (_player_radius * 4.5 / SOURCE_FRAME_SIZE),
		tuning.wall_impact_duration,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_impact_tween.tween_property(
		_impact_burst,
		"modulate:a",
		0.0,
		tuning.wall_impact_duration,
	)
	_impact_tween.tween_property(
		_sprite,
		"scale",
		_base_sprite_scale,
		tuning.wall_impact_duration,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_impact_tween.chain().tween_callback(func() -> void: _impact_burst.visible = false)


func _update_invulnerability(delta: float) -> void:
	if state == State.DEAD:
		return
	if _invulnerability_remaining <= 0.0:
		_sprite.modulate = Color.WHITE
		return
	_invulnerability_remaining = maxf(0.0, _invulnerability_remaining - delta)
	_invulnerability_elapsed += delta
	if _invulnerability_remaining <= 0.0:
		_sprite.modulate = Color.WHITE
	else:
		var pulse: float = 0.52 + sin(_invulnerability_elapsed * 28.0) * 0.24
		_sprite.modulate = Color(Palette.SOUL_WHITE, pulse)


func _apply_cosmetic_form() -> void:
	_form_sprite.texture = _cosmetic_texture
	_form_sprite.visible = _cosmetic_texture != null
	_sprite.visible = _cosmetic_texture == null
	_aim_line.default_color = Color(
		_cosmetic_tint.r,
		_cosmetic_tint.g,
		_cosmetic_tint.b,
		0.72,
	)
	_impact_point.color = Color(
		_cosmetic_tint.r,
		_cosmetic_tint.g,
		_cosmetic_tint.b,
		0.9,
	)
	_sync_form_visual()


func _sync_form_visual() -> void:
	if not is_node_ready() or not _form_sprite.visible:
		return
	_form_sprite.rotation = _sprite.rotation
	_form_sprite.scale = _sprite.scale * (SOURCE_FRAME_SIZE / FORM_SOURCE_SIZE)
	_form_sprite.modulate = Color(1.0, 1.0, 1.0, _sprite.modulate.a)


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	health_changed.emit(current_health, maximum_health)


func _on_health_depleted() -> void:
	_enter_dead()


func _enter_dead() -> void:
	state = State.DEAD
	_state_time_remaining = tuning.death_duration
	_death_reported = false
	_active_pointer = INVALID_POINTER
	velocity = Vector2.ZERO
	_hide_aim_preview()
	if _impact_tween != null and _impact_tween.is_valid():
		_impact_tween.kill()
	_impact_burst.visible = false
	_sprite.rotation = 0.0
	_sprite.scale = _base_sprite_scale
	_sprite.modulate = Color.WHITE
	_sprite.play(&"dead")
	var death_tween: Tween = create_tween().set_parallel(true)
	death_tween.tween_property(
		_sprite,
		"scale",
		_base_sprite_scale * 1.28,
		tuning.death_duration,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	death_tween.tween_property(_sprite, "modulate:a", 0.0, tuning.death_duration)


func _enter_waiting() -> void:
	if _health.is_depleted() or state == State.DEAD:
		return
	state = State.WAITING_AT_EDGE
	_active_pointer = INVALID_POINTER
	_sprite.rotation = 0.0
	_sprite.scale = _base_sprite_scale
	_sprite.play(&"idle")
	_breath_time = 0.0
	_reduced_motion = _read_reduced_motion()
	_hide_aim_preview()


func _snap_to_nearest_edge() -> void:
	var left_distance: float = absf(position.x - _play_bounds.position.x)
	var right_distance: float = absf(_play_bounds.end.x - position.x)
	var top_distance: float = absf(position.y - _play_bounds.position.y)
	var bottom_distance: float = absf(_play_bounds.end.y - position.y)
	var nearest: float = minf(minf(left_distance, right_distance), minf(top_distance, bottom_distance))
	if is_equal_approx(nearest, left_distance):
		position.x = _play_bounds.position.x
	elif is_equal_approx(nearest, right_distance):
		position.x = _play_bounds.end.x
	elif is_equal_approx(nearest, top_distance):
		position.y = _play_bounds.position.y
	else:
		position.y = _play_bounds.end.y


func _read_reduced_motion() -> bool:
	var save_manager := get_node_or_null(^"/root/SaveManager") as SaveManagerService
	if save_manager == null:
		return false
	return bool(save_manager.get_settings().get(&"reduced_motion", false))
