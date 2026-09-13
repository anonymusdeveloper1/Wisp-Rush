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
## Emitted when a swipe mid-flight turns the live dash. [param previous_dash_id] is the leg that just
## ended without touching a wall, so GameWorld can resolve its kills; `dash_started` follows.
signal dash_redirected(world_position: Vector2, previous_dash_id: int)
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
## Distance from the Wisp's centre to the aim arrow, in collision radii.
const ARROW_DISTANCE: float = 2.15
## Aim arrow size, in collision radii. It carries a dark outline so it reads on Frozen Choir's pale
## ice as well as on dark basalt, where the bright head does the work.
const ARROW_SCALE: float = 1.3
## Aim arrow pulse: amount of scale swing and its rate in radians per second.
const ARROW_PULSE_AMOUNT: float = 0.08
const ARROW_PULSE_RATE: float = 11.0
## A drag shorter than this fraction of the swipe threshold is too noisy to point an arrow.
const ARROW_MIN_DRAG_SHARE: float = 0.5

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
## Extra invulnerability seconds granted by the Soul Sanctum's Warded Soul node.
var _bonus_invulnerability: float = 0.0
## Whether the aim arrow is drawn while aiming.
var _aim_arrow_enabled: bool = true
## A swipe released while the Wisp could not act, and the physics time it has left to fire.
## Counted down with `delta`, not the wall clock, so hit-stop and frame hitches stretch it exactly
## as they stretch the hurt and reform reactions it is waiting out.
var _buffered_swipe: Vector2 = Vector2.ZERO
var _buffer_remaining: float = 0.0
## Seconds since the current dash (or redirect) launched, driving the launch burst.
var _dash_elapsed: float = 0.0
## Chain momentum as a fraction of dash speed, built by fast redirects.
var _momentum: float = 0.0
## Tick of the most recent landing, for measuring how quickly the next dash followed.
var _last_landing_msec: int = -1
## Clock for the aim arrow pulse.
var _arrow_time: float = 0.0
## Frozen Choir: design-space px/s the Wisp slides along its resting edge. Zero disables drift.
var _edge_drift_speed: float = 0.0
## Current slide direction along the edge; flips at the corners.
var _edge_drift_sign: float = 1.0
## Playable floor as a screen-space polygon. Empty falls back to the legacy rectangle.
var _play_polygon: PackedVector2Array = PackedVector2Array()
## Index of the polygon edge the Wisp is resting on, tracked by identity rather than by distance:
## the dash casts from that edge and must exclude it, and float tolerance is not reliable there.
var _resting_edge: int = -1
## Inward normal of the edge the active dash is travelling toward, carried out of the cast so the
## impact reports the wall it actually hit instead of re-guessing from where it stopped.
var _dash_target_normal: Vector2 = Vector2.UP
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
@onready var _aim_arrow: Node2D = %AimArrow
@onready var _aim_arrow_glow: Polygon2D = %Glow
@onready var _aim_arrow_head: Polygon2D = %Head
@onready var _impact_burst: Sprite2D = %ImpactBurst


func _ready() -> void:
	assert(tuning != null, "WispPlayer requires PlayerTuning")
	_health.health_changed.connect(_on_health_changed)
	_health.depleted.connect(_on_health_depleted)
	_health.configure(tuning.maximum_health)
	_state_time_remaining = tuning.spawn_duration
	_sprite.play(&"reform")
	_aim_arrow.visible = false
	_impact_burst.visible = false
	_apply_cosmetic_form()
	_reduced_motion = _read_reduced_motion()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.canceled:
			_cancel_pointer(touch.index)
		elif touch.pressed:
			_begin_pointer(touch.position, touch.index)
		else:
			_end_pointer(touch.position, touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_update_pointer(drag.position, drag.index)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			# On a phone, touches reach us first as EMULATED mouse events (the emulated press arrives
			# before the touch press, so it owns the pointer). A system-cancelled touch therefore
			# shows up here as a cancelled mouse release, and must be dropped, not treated as a swipe.
			if button.canceled:
				_cancel_pointer(MOUSE_POINTER)
			elif button.pressed:
				_begin_pointer(button.position, MOUSE_POINTER)
			else:
				_end_pointer(button.position, MOUSE_POINTER)
	elif event is InputEventMouseMotion and _active_pointer == MOUSE_POINTER:
		var motion := event as InputEventMouseMotion
		_update_pointer(motion.position, MOUSE_POINTER)


func _process(delta: float) -> void:
	if _aim_arrow.visible:
		_arrow_time += delta
		var pulse: float = 1.0 + sin(_arrow_time * ARROW_PULSE_RATE) * (
			0.0 if _reduced_motion else ARROW_PULSE_AMOUNT
		)
		_aim_arrow.scale = Vector2.ONE * _player_radius * ARROW_SCALE * pulse
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
			_apply_edge_drift(delta)
		State.WINDUP:
			_state_time_remaining -= delta
			if _state_time_remaining <= 0.0:
				_begin_dash_motion()
		State.DASHING:
			_process_keyboard_flow()
			if state == State.DASHING:
				_advance_dash(delta)
		State.WALL_IMPACT:
			_process_keyboard_flow()
			if state == State.WALL_IMPACT:
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
	_consume_buffered_swipe(delta)
	_refresh_held_aim()
	_sync_form_visual()


## Resolves an arbitrary direction into one normalized, inward, first-edge dash.
func request_dash(direction: Vector2) -> void:
	# WALL_IMPACT is accepted too: a swipe cancels the landing lock instead of being thrown away.
	if state != State.WAITING_AT_EDGE and state != State.AIMING and state != State.WALL_IMPACT:
		return
	if not _arena_initialized or direction.is_zero_approx():
		return

	var resolved: Dictionary = _resolve_dash(direction)
	_dash_direction = resolved[&"direction"] as Vector2
	_dash_target = resolved[&"target"] as Vector2
	_dash_target_normal = resolved[&"normal"] as Vector2
	if position.distance_squared_to(_dash_target) <= 1.0:
		_hide_aim_preview()
		return

	_dash_id += 1
	_update_momentum_for_launch()
	state = State.WINDUP
	_state_time_remaining = tuning.windup_duration
	# The pointer is NOT cleared here. `_end_pointer` already clears it for the swipe that caused this
	# dash; clearing it again threw away a second touch in progress when the buffer fired.
	_hide_aim_preview()
	_sprite.rotation = _dash_direction.angle()
	_sprite.play(&"charge")
	_sprite.scale = _base_sprite_scale
	dash_started.emit(_dash_direction, _dash_id)


## Teleports a live dash to a new origin and re-aims it at the arena edge, same direction.
##
## Used by the Shattered Rift's void portals. Returns false unless a dash is actually in flight,
## so nothing can teleport a resting or aiming Wisp.
func teleport_dash_to(world_position: Vector2) -> bool:
	if state != State.DASHING:
		return false
	global_position = world_position
	var recast: Dictionary = _resolve_dash(_dash_direction)
	_dash_target = recast[&"target"] as Vector2
	_dash_target_normal = recast[&"normal"] as Vector2
	return true


## Applies the playable floor as a polygon. Empty restores the legacy rectangle behaviour.
func set_arena_polygon(polygon: PackedVector2Array) -> void:
	_play_polygon = polygon
	if polygon.size() < 3:
		_resting_edge = -1
		return
	if state == State.WAITING_AT_EDGE or state == State.AIMING or state == State.SPAWNING:
		_snap_to_polygon_edge()
	elif not DashGeometry.is_inside_polygon_slack(position, polygon, _player_radius):
		# A mid-dash floor change (Ember Hollow contracts as a level runs) can leave the Wisp
		# outside; pull it back in and re-cast so it is not chasing a stale target.
		position = DashGeometry.clamp_to_polygon(position, polygon, 1.0)
		if state == State.DASHING:
			var recast: Dictionary = _resolve_dash(_dash_direction)
			_dash_target = recast[&"target"] as Vector2
			_dash_target_normal = recast[&"normal"] as Vector2


## World-space point this dash is currently travelling toward.
func get_dash_target() -> Vector2:
	return _dash_target


## Adds permanent invulnerability seconds from the Soul Sanctum.
##
## Held as a runtime field rather than written into `tuning`, because PlayerTuning is a shared
## Resource: mutating it would leak the bonus into every later run and into the .tres on disk.
func set_bonus_invulnerability(seconds: float) -> void:
	_bonus_invulnerability = maxf(0.0, seconds)


## Shows or hides the direction arrow drawn beside the Wisp while aiming.
##
## The arrow replaced the full aim line (owner decision): it shows where the dash will go without
## drawing across the playfield. On by default; toggled by AIM ARROW in Settings.
func set_aim_arrow_enabled(enabled: bool) -> void:
	_aim_arrow_enabled = enabled
	if not enabled:
		_hide_aim_preview()


## Whether the direction arrow is currently shown, for tests.
func is_aim_arrow_visible() -> bool:
	return _aim_arrow.visible


## World-space heading the aim arrow is pointing, for tests.
func get_aim_arrow_direction() -> Vector2:
	return Vector2.RIGHT.rotated(_aim_arrow.rotation)


## Current chain momentum, as a fraction of dash speed.
func get_momentum() -> float:
	return _momentum


## Dash speed right now in px/s, including launch burst, momentum and run modifiers.
func get_current_dash_speed() -> float:
	return (
		tuning.dash_speed * _dash_speed_multiplier * _viewport_scale
		* (1.0 + _momentum) * _launch_burst()
	)


## Whether a released swipe is waiting for the Wisp to be able to act.
func has_buffered_swipe() -> bool:
	return _buffer_remaining > 0.0


## Turns a live dash toward [param direction] from wherever the Wisp is right now.
##
## Mid-dash redirect (owner decision, GDD §5.1): a dash no longer has to run wall to wall. The leg
## that just ended is announced with `dash_redirected` so its kills still score, then a fresh dash
## id launches with its own burst, so enemies passed on the first leg can be hit again.
func redirect_dash(direction: Vector2) -> bool:
	if state != State.DASHING or direction.is_zero_approx():
		return false
	# Mid-flight the Wisp is on open floor, not resting on any edge.
	_resting_edge = -1
	var resolved: Dictionary = _resolve_dash(direction)
	var target: Vector2 = resolved[&"target"] as Vector2
	if position.distance_squared_to(target) <= 1.0:
		_hide_aim_preview()
		return false
	var previous_dash_id: int = _dash_id
	dash_redirected.emit(global_position, previous_dash_id)
	_dash_id += 1
	_dash_direction = resolved[&"direction"] as Vector2
	_dash_target = target
	_dash_target_normal = resolved[&"normal"] as Vector2
	_dash_elapsed = 0.0
	_add_momentum()
	_hide_aim_preview()
	var faces_left: bool = _dash_direction.x < 0.0
	_sprite.play(&"dash_left" if faces_left else &"dash_right")
	_sprite.rotation = _dash_direction.angle() - (PI if faces_left else 0.0)
	_sprite.scale = _base_sprite_scale
	dash_started.emit(_dash_direction, _dash_id)
	return true


## Sets the Frozen Choir slide, in design-space px/s. Zero restores normal resting behaviour.
func set_edge_drift(design_speed: float) -> void:
	_edge_drift_speed = maxf(0.0, design_speed)


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
	_aim_arrow.scale = Vector2.ONE * _player_radius * ARROW_SCALE

	if not _arena_initialized:
		position = Vector2(_play_bounds.get_center().x, _play_bounds.end.y)
		_arena_initialized = true
		if _play_polygon.size() >= 3:
			_snap_to_polygon_edge()
	elif _play_polygon.size() >= 3:
		position = DashGeometry.clamp_to_polygon(position, _play_polygon, 1.0)
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
	_buffer_remaining = 0.0
	_hide_aim_preview()
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
	_last_landing_msec = Time.get_ticks_msec()
	# Stopped against a crystal in open floor: not resting on any wall edge.
	_resting_edge = -1
	state = State.WALL_IMPACT
	_state_time_remaining = tuning.wall_impact_duration
	_sprite.rotation = 0.0
	_sprite.play(&"wall_impact")
	_play_impact_feedback(impact_normal)
	obstacle_impacted.emit(global_position, impact_normal, _dash_id)
	focus_started.emit(tuning.focus_duration, tuning.focus_world_speed)
	return true


## Resolves a raw swipe into a legal dash: inward direction, landing point and impact normal.
##
## The single resolver for both [method request_dash] and the aim preview, so the line can never
## promise a landing the dash will not take. Uses the polygon floor when one is supplied and falls
## back to the legacy rectangle otherwise.
func _resolve_dash(direction: Vector2) -> Dictionary:
	if _play_polygon.size() >= 3:
		var aim: Vector2 = DashGeometry.reflect_inward_polygon(
			direction,
			position,
			_play_polygon,
			maxf(1.0, _player_radius * 0.2),
		)
		# Exclude the resting edge only while actually standing on it, so a stale index (after a
		# crystal stop, a resize or a shrink) can never hide a real wall.
		var exclude: int = -1
		if _resting_edge >= 0 and _resting_edge < _play_polygon.size():
			var edge_start: Vector2 = _play_polygon[_resting_edge]
			var edge_end: Vector2 = _play_polygon[(_resting_edge + 1) % _play_polygon.size()]
			if DashGeometry.distance_to_segment(position, edge_start, edge_end) <= maxf(
				2.0, _player_radius * 0.25
			):
				exclude = _resting_edge
		var hit: Dictionary = DashGeometry.cast_polygon(
			position, aim, _play_polygon, 1.0, exclude
		)
		if not hit.is_empty():
			return {
				&"direction": aim,
				&"target": hit[&"point"] as Vector2,
				&"normal": hit[&"normal"] as Vector2,
			}
		# No wall beyond the edge underfoot: allow the resting edge back in rather than swallow
		# the swipe, which is how a dash silently does nothing.
		var fallback: Dictionary = DashGeometry.cast_polygon(position, aim, _play_polygon, 1.0)
		if not fallback.is_empty():
			return {
				&"direction": aim,
				&"target": fallback[&"point"] as Vector2,
				&"normal": fallback[&"normal"] as Vector2,
			}
		return {&"direction": aim, &"target": position, &"normal": Vector2.UP}

	var rect_aim: Vector2 = DashGeometry.reflect_inward(
		direction,
		position,
		_play_bounds,
		maxf(1.0, _player_radius * 0.2),
	)
	var rect_target: Vector2 = DashGeometry.ray_to_rect_edge(position, rect_aim, _play_bounds)
	return {
		&"direction": rect_aim,
		&"target": rect_target,
		&"normal": DashGeometry.inward_edge_normal(rect_target, _play_bounds),
	}


## Moves the Wisp onto the nearest polygon edge and records which edge that is.
func _snap_to_polygon_edge() -> void:
	if _play_polygon.size() < 3:
		return
	position = DashGeometry.nearest_polygon_point(position, _play_polygon)
	_resting_edge = DashGeometry.nearest_polygon_edge(position, _play_polygon)


## Slides the resting Wisp along its edge so a Rift can make footing unreliable.
##
## Only the tangent moves - the Wisp stays locked to its edge, so the dash model is untouched.
func _apply_edge_drift(delta: float) -> void:
	if _edge_drift_speed <= 0.0 or not _arena_initialized:
		return
	if _play_polygon.size() >= 3:
		_apply_polygon_edge_drift(delta)
		return
	var bounds: Rect2 = _play_bounds
	if bounds.size.x <= 1.0 or bounds.size.y <= 1.0:
		return
	# Pick the tangent of whichever edge the Wisp is currently resting against.
	var to_left: float = absf(global_position.x - bounds.position.x)
	var to_right: float = absf(global_position.x - bounds.end.x)
	var to_top: float = absf(global_position.y - bounds.position.y)
	var to_bottom: float = absf(global_position.y - bounds.end.y)
	var nearest: float = minf(minf(to_left, to_right), minf(to_top, to_bottom))
	var tangent := Vector2.RIGHT if (nearest == to_top or nearest == to_bottom) else Vector2.DOWN
	var step: float = _edge_drift_speed * _viewport_scale * _edge_drift_sign * delta
	var moved: Vector2 = global_position + tangent * step
	var clamped: Vector2 = moved.clamp(bounds.position, bounds.end)
	if not clamped.is_equal_approx(moved):
		_edge_drift_sign = -_edge_drift_sign
	global_position = clamped


## Slides the resting Wisp along the polygon edge it is standing on.
##
## Walks the edge tangent and hands off to the neighbouring edge at a vertex, so the Wisp follows
## the painted wall around a corner instead of bouncing off an invisible axis.
func _apply_polygon_edge_drift(delta: float) -> void:
	if _resting_edge < 0:
		_resting_edge = DashGeometry.nearest_polygon_edge(position, _play_polygon)
		if _resting_edge < 0:
			return
	var count: int = _play_polygon.size()
	var start: Vector2 = _play_polygon[_resting_edge]
	var end: Vector2 = _play_polygon[(_resting_edge + 1) % count]
	var edge: Vector2 = end - start
	if edge.is_zero_approx():
		return
	var step: float = _edge_drift_speed * _viewport_scale * delta
	var along: float = (position - start).dot(edge.normalized()) + step * _edge_drift_sign
	var length: float = edge.length()
	if along > length:
		# Carry the overshoot onto the next edge rather than stopping at the vertex.
		_resting_edge = (_resting_edge + 1) % count
		position = _play_polygon[_resting_edge]
		return
	if along < 0.0:
		_resting_edge = (_resting_edge - 1 + count) % count
		position = _play_polygon[(_resting_edge + 1) % count]
		return
	position = start + edge.normalized() * along


func _take_damage(safe_edge_position: Vector2) -> bool:
	_active_pointer = INVALID_POINTER
	# A hit breaks the chain, just as it breaks the combo - including the landing it would chain from.
	_momentum = 0.0
	_last_landing_msec = -1
	_buffer_remaining = 0.0
	velocity = Vector2.ZERO
	_hide_aim_preview()
	global_position = safe_edge_position
	_snap_to_nearest_edge()
	_invulnerability_remaining = tuning.invulnerability_duration + _bonus_invulnerability
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
	# A touch is tracked in every live state, not only at rest. Refusing it mid-dash used to lose
	# the whole swipe, because the matching release was then ignored as well.
	if state == State.DEAD or state == State.VICTORY:
		return
	_active_pointer = pointer_id
	_drag_start = screen_position
	_drag_current = screen_position
	if state == State.WAITING_AT_EDGE:
		state = State.AIMING


func _update_pointer(screen_position: Vector2, pointer_id: int) -> void:
	if pointer_id != _active_pointer:
		return
	_drag_current = screen_position
	var drag_vector: Vector2 = _drag_current - _drag_start
	if drag_vector.length() >= _minimum_swipe_distance() * ARROW_MIN_DRAG_SHARE:
		_aim_direction = drag_vector.normalized()
		_update_aim_preview(_aim_direction)


func _end_pointer(screen_position: Vector2, pointer_id: int) -> void:
	if pointer_id != _active_pointer:
		return
	_drag_current = screen_position
	_active_pointer = INVALID_POINTER
	var drag_vector: Vector2 = _drag_current - _drag_start
	if drag_vector.length() < _minimum_swipe_distance():
		_hide_aim_preview()
		if state == State.AIMING:
			_enter_waiting()
		return
	_act_on_swipe(drag_vector)


## Routes a completed swipe to whatever the Wisp can do right now, buffering it when it can't.
func _act_on_swipe(drag_vector: Vector2) -> void:
	match state:
		State.WAITING_AT_EDGE, State.AIMING, State.WALL_IMPACT:
			request_dash(drag_vector)
		State.DASHING:
			redirect_dash(drag_vector)
		State.WINDUP:
			_retarget_windup(drag_vector)
		State.SPAWNING, State.HURT:
			_buffered_swipe = drag_vector
			_buffer_remaining = tuning.input_buffer_window
			_hide_aim_preview()
		_:
			_hide_aim_preview()


## Fires a buffered swipe as soon as the Wisp can act on it, or drops it once it goes stale.
func _consume_buffered_swipe(delta: float) -> void:
	if _buffer_remaining <= 0.0:
		return
	if state == State.SPAWNING or state == State.HURT:
		_buffer_remaining -= delta
		return
	var swipe: Vector2 = _buffered_swipe
	_buffer_remaining = 0.0
	_act_on_swipe(swipe)


## Re-aims a dash still in its windup, before it has moved.
##
## No redirect is announced and no momentum is added: nothing has been swept yet, so this is the
## same dash pointed somewhere else. Buffering it instead fired a zero-length redirect on the launch
## tick, which scored an empty leg and handed out free momentum.
func _retarget_windup(direction: Vector2) -> void:
	if state != State.WINDUP or direction.is_zero_approx():
		return
	var resolved: Dictionary = _resolve_dash(direction)
	var target: Vector2 = resolved[&"target"] as Vector2
	_hide_aim_preview()
	if position.distance_squared_to(target) <= 1.0:
		return
	_dash_direction = resolved[&"direction"] as Vector2
	_dash_target = target
	_dash_target_normal = resolved[&"normal"] as Vector2
	_sprite.rotation = _dash_direction.angle()


## Keeps the arrow truthful while a finger is held.
##
## The resolved direction changes as the Wisp flies, lands and turns, so it is recomputed every tick
## rather than only on drag events. Otherwise the arrow kept pointing a raw direction through the
## landing lock, and vanished at rest while a release would still dash.
func _refresh_held_aim() -> void:
	if _active_pointer == INVALID_POINTER:
		return
	if state == State.DEAD or state == State.VICTORY:
		_hide_aim_preview()
		return
	var drag: Vector2 = _drag_current - _drag_start
	if drag.length() >= _minimum_swipe_distance() * ARROW_MIN_DRAG_SHARE:
		_update_aim_preview(drag.normalized())


## Drops a touch the system cancelled (notification shade, app switch) without acting on it.
##
## A cancel arrives as a release; treating it as one would now redirect a live dash.
func _cancel_pointer(pointer_id: int) -> void:
	if pointer_id != _active_pointer:
		return
	_active_pointer = INVALID_POINTER
	_hide_aim_preview()
	if state == State.AIMING:
		_enter_waiting()


## Keyboard parity for desktop QA: Space redirects mid-dash or cancels the landing lock.
func _process_keyboard_flow() -> void:
	if _active_pointer != INVALID_POINTER or not Input.is_action_just_pressed(ACTION_DASH):
		return
	var keyboard_direction := Input.get_vector(
		ACTION_MOVE_LEFT,
		ACTION_MOVE_RIGHT,
		ACTION_MOVE_UP,
		ACTION_MOVE_DOWN,
	)
	if state == State.DASHING:
		# Only redirect along a direction the player is actually holding, never a stale aim.
		if not keyboard_direction.is_zero_approx():
			redirect_dash(keyboard_direction)
	elif state == State.WALL_IMPACT:
		request_dash(_aim_direction if keyboard_direction.is_zero_approx() else keyboard_direction)


## Chained launches build momentum; a slow restart lets it drain back to zero.
func _update_momentum_for_launch() -> void:
	var quick: bool = (
		_last_landing_msec >= 0
		and Time.get_ticks_msec() - _last_landing_msec <= int(tuning.momentum_window * 1000.0)
	)
	if quick:
		_add_momentum()
	else:
		_momentum = 0.0


func _add_momentum() -> void:
	_momentum = minf(tuning.momentum_max, _momentum + tuning.momentum_step)


## Launch burst multiplier for the current moment of the dash, easing from the peak to 1.0.
func _launch_burst() -> float:
	var decay: float = maxf(0.001, tuning.launch_burst_decay)
	return 1.0 + (tuning.launch_burst_multiplier - 1.0) * exp(-_dash_elapsed / decay)


func _minimum_swipe_distance() -> float:
	return tuning.minimum_swipe_distance * maxf(0.75, _viewport_scale)


func _update_aim_preview(direction: Vector2) -> void:
	var resolved: Dictionary = _resolve_dash(direction)
	var resolved_direction: Vector2 = resolved[&"direction"] as Vector2
	var target: Vector2 = resolved[&"target"] as Vector2
	# The Wisp still leans into the aim even with the arrow off: that is feel, not a readout. Never
	# while dashing, though - there the sprite's rotation shows the live heading.
	# Lean only at rest: in windup, flight, the landing lock or a reaction, rotation belongs to that
	# pose (the charge, the dash heading, the hurt flinch).
	if state == State.WAITING_AT_EDGE or state == State.AIMING:
		_sprite.rotation = clampf(resolved_direction.angle(), -0.42, 0.42)
	if (
		not _aim_arrow_enabled
		or resolved_direction.is_zero_approx()
		or position.distance_squared_to(target) <= 1.0
	):
		_hide_aim_preview()
		return
	# The arrow shows the RESOLVED direction, so an outward swipe off a wall points back inward
	# exactly as the dash will travel.
	_aim_arrow.position = resolved_direction * _player_radius * ARROW_DISTANCE
	_aim_arrow.rotation = resolved_direction.angle()
	if not _aim_arrow.visible:
		_arrow_time = 0.0
	_aim_arrow.visible = true


func _hide_aim_preview() -> void:
	_aim_arrow.visible = false


func _begin_dash_motion() -> void:
	state = State.DASHING
	_dash_elapsed = 0.0
	var faces_left: bool = _dash_direction.x < 0.0
	_sprite.play(&"dash_left" if faces_left else &"dash_right")
	_sprite.rotation = _dash_direction.angle() - (PI if faces_left else 0.0)


func _advance_dash(delta: float) -> void:
	var previous_global_position: Vector2 = global_position
	var remaining_distance: float = position.distance_to(_dash_target)
	_dash_elapsed += delta
	var speed: float = get_current_dash_speed()
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
	_last_landing_msec = Time.get_ticks_msec()
	state = State.WALL_IMPACT
	_state_time_remaining = tuning.wall_impact_duration
	# The normal comes from the cast that chose this landing, not from re-deriving it here: on a
	# polygon, "nearest edge to where I stopped" is not always the edge I hit.
	var inward_normal: Vector2 = _dash_target_normal
	if _play_polygon.size() >= 3:
		_resting_edge = DashGeometry.nearest_polygon_edge(position, _play_polygon)
	else:
		inward_normal = DashGeometry.inward_edge_normal(position, _play_bounds)
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
	_aim_arrow_glow.color = Color(_cosmetic_tint.r, _cosmetic_tint.g, _cosmetic_tint.b, 0.5)
	_aim_arrow_head.color = Color(_cosmetic_tint.lightened(0.6), 0.95)
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
	# A finger held down through the landing is NOT forgotten: releasing it must still dash.
	_sprite.rotation = 0.0
	_sprite.scale = _base_sprite_scale
	_sprite.play(&"idle")
	_breath_time = 0.0
	_reduced_motion = _read_reduced_motion()
	_hide_aim_preview()


func _snap_to_nearest_edge() -> void:
	if _play_polygon.size() >= 3:
		_snap_to_polygon_edge()
		return
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
