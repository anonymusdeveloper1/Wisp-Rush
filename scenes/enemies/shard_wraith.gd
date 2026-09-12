class_name ShardWraithEnemy
extends EnemyActor
## Two-hit crystal enemy that telegraphs short angular darts between fast steering passes.

enum MovePhase { TRACKING, WINDUP, DARTING }

var _move_phase: MovePhase = MovePhase.TRACKING
var _phase_remaining: float = 0.0
var _movement_direction: Vector2 = Vector2.UP
var _dart_direction: Vector2 = Vector2.UP
var _angular_sign: float = 1.0


func _on_became_active() -> void:
	_angular_sign = -1.0 if int(absf(global_position.x + global_position.y)) % 2 == 0 else 1.0
	_movement_direction = (_target_position - global_position).normalized()
	_phase_remaining = tuning.action_interval


func _advance_active(scaled_delta: float) -> void:
	if not movement_enabled:
		return
	_phase_remaining -= scaled_delta
	match _move_phase:
		MovePhase.TRACKING:
			_track_angularly(scaled_delta)
			if _phase_remaining <= 0.0:
				_move_phase = MovePhase.WINDUP
				_phase_remaining = tuning.action_telegraph
		MovePhase.WINDUP:
			_sprite.rotation += 5.0 * _angular_sign * scaled_delta
			var pulse: float = 1.0 + sin(_phase_remaining * 34.0) * 0.08
			_sprite.scale = _base_sprite_scale * pulse
			_show_action_telegraph(
				1.0 - _phase_remaining / maxf(tuning.action_telegraph, 0.001)
			)
			if _phase_remaining <= 0.0:
				_hide_action_telegraph()
				_move_phase = MovePhase.DARTING
				_phase_remaining = tuning.action_duration
				var direct: Vector2 = (_target_position - global_position).normalized()
				_dart_direction = direct.rotated(_angular_sign * 0.34).normalized()
				_sprite.scale = _base_sprite_scale
		MovePhase.DARTING:
			position += (
				_dart_direction
				* tuning.movement_speed
				* tuning.action_speed_multiplier
				* _viewport_scale
				* scaled_delta
			)
			_sprite.rotation = _dart_direction.angle() + PI * 0.5
			if _phase_remaining <= 0.0:
				_move_phase = MovePhase.TRACKING
				_phase_remaining = tuning.action_interval
				_angular_sign *= -1.0
	_clamp_to_arena()


func _track_angularly(scaled_delta: float) -> void:
	var desired: Vector2 = (_target_position - global_position).normalized().rotated(
		_angular_sign * 0.62
	)
	if not desired.is_zero_approx():
		var angle_delta: float = wrapf(desired.angle() - _movement_direction.angle(), -PI, PI)
		_movement_direction = _movement_direction.rotated(
			clampf(angle_delta, -tuning.turn_speed * scaled_delta, tuning.turn_speed * scaled_delta)
		).normalized()
	position += _movement_direction * tuning.movement_speed * _viewport_scale * scaled_delta
	_sprite.rotation = _movement_direction.angle() + PI * 0.5
