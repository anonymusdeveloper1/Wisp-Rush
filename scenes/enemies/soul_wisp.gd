class_name SoulWispEnemy
extends EnemyActor
## One-hit enemy that gently steers toward the Wisp to create readable early chain lines.

var _movement_direction: Vector2 = Vector2.UP


func _on_became_active() -> void:
	var desired: Vector2 = (_target_position - global_position).normalized()
	if not desired.is_zero_approx():
		_movement_direction = desired


func _advance_active(scaled_delta: float) -> void:
	if not movement_enabled:
		return
	var desired_direction: Vector2 = (_target_position - global_position).normalized()
	if not desired_direction.is_zero_approx():
		var angle_delta: float = wrapf(
			desired_direction.angle() - _movement_direction.angle(),
			-PI,
			PI,
		)
		var turn: float = clampf(
			angle_delta,
			-tuning.turn_speed * scaled_delta,
			tuning.turn_speed * scaled_delta,
		)
		_movement_direction = _movement_direction.rotated(turn).normalized()
	position += _movement_direction * tuning.movement_speed * _viewport_scale * scaled_delta
	_sprite.rotation = clampf(_movement_direction.x * 0.18, -0.18, 0.18)
	_clamp_to_arena()
