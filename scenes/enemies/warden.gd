class_name WardenEnemy
extends EnemyActor
## Armoured guardian whose frontal shield arc blocks dash damage, so it must be cut from behind.
##
## The shield turns slowly toward the Wisp: the skill is reading where the plate is pointing and
## planning a line that arrives outside `tuning.shield_arc_degrees` of it.

## How much slower the shield turns than the body drifts, so flanking stays possible.
const SHIELD_TURN_SCALE: float = 0.45

var _facing: Vector2 = Vector2.DOWN
var _blocked_flash: float = 0.0


func _on_became_active() -> void:
	var desired: Vector2 = (_target_position - global_position).normalized()
	if not desired.is_zero_approx():
		_facing = desired


func _advance_active(scaled_delta: float) -> void:
	if not movement_enabled:
		return
	var desired: Vector2 = (_target_position - global_position).normalized()
	if not desired.is_zero_approx():
		var angle_delta: float = wrapf(desired.angle() - _facing.angle(), -PI, PI)
		var turn_rate: float = tuning.turn_speed * SHIELD_TURN_SCALE * scaled_delta
		_facing = _facing.rotated(clampf(angle_delta, -turn_rate, turn_rate)).normalized()
	position += _facing * tuning.movement_speed * _viewport_scale * scaled_delta
	# The sprite's shield plate is drawn facing down, so rotate from DOWN.
	_sprite.rotation = _facing.angle() - Vector2.DOWN.angle()
	if _blocked_flash > 0.0:
		_blocked_flash = maxf(0.0, _blocked_flash - scaled_delta)
	_clamp_to_arena()


## Blocks any dash whose approach lands inside the shield arc; other angles damage normally.
func try_dash_hit(
		segment_start: Vector2,
		segment_end: Vector2,
		corridor_radius: float,
		damage: int,
		damage_event_id: int,
	) -> bool:
	if state == State.ACTIVE and tuning.shield_arc_degrees > 0.0:
		var approach: Vector2 = (segment_end - segment_start).normalized()
		if not approach.is_zero_approx():
			# The dash strikes the shield when it travels *into* the plate, i.e. against the facing.
			var incoming: Vector2 = -approach
			var half_arc: float = deg_to_rad(tuning.shield_arc_degrees) * 0.5
			if absf(incoming.angle_to(_facing)) <= half_arc:
				var hit_radius: float = get_collision_radius() + corridor_radius
				var distance: float = DashGeometry.distance_to_segment(
					global_position,
					segment_start,
					segment_end,
				)
				if distance <= hit_radius:
					_on_shield_blocked()
				return false
	return super.try_dash_hit(
		segment_start,
		segment_end,
		corridor_radius,
		damage,
		damage_event_id,
	)


## Whether the shield is currently deflecting, for feedback and tests.
func is_blocking() -> bool:
	return _blocked_flash > 0.0


func _on_shield_blocked() -> void:
	_blocked_flash = 0.25
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(&"blocked"):
		_sprite.play(&"blocked")
