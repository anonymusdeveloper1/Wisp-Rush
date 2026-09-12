class_name BoneMoteEnemy
extends EnemyActor
## Three-hit heavy enemy that telegraphs and charges the Wisp's most recent edge position.

enum MovePhase { DRIFTING, WINDUP, CHARGING, RECOVERING }

var _move_phase: MovePhase = MovePhase.DRIFTING
var _phase_remaining: float = 0.0
var _charge_direction: Vector2 = Vector2.UP


func _on_became_active() -> void:
	_phase_remaining = tuning.action_interval


func _advance_active(scaled_delta: float) -> void:
	if not movement_enabled:
		return
	_phase_remaining -= scaled_delta
	match _move_phase:
		MovePhase.DRIFTING:
			var direction: Vector2 = (_target_position - global_position).normalized()
			position += direction * tuning.movement_speed * _viewport_scale * scaled_delta
			_sprite.rotation = sin(Time.get_ticks_msec() * 0.002) * 0.08
			if _phase_remaining <= 0.0:
				_move_phase = MovePhase.WINDUP
				_phase_remaining = tuning.action_telegraph
		MovePhase.WINDUP:
			var pulse: float = 0.92 + sin(_phase_remaining * 30.0) * 0.1
			_sprite.scale = _base_sprite_scale * pulse
			_show_action_telegraph(
				1.0 - _phase_remaining / maxf(tuning.action_telegraph, 0.001)
			)
			if _phase_remaining <= 0.0:
				_hide_action_telegraph()
				_charge_direction = (_last_edge_position - global_position).normalized()
				if _charge_direction.is_zero_approx():
					_charge_direction = (_target_position - global_position).normalized()
				_move_phase = MovePhase.CHARGING
				_phase_remaining = tuning.action_duration
				_sprite.scale = _base_sprite_scale
		MovePhase.CHARGING:
			position += (
				_charge_direction
				* tuning.movement_speed
				* tuning.action_speed_multiplier
				* _viewport_scale
				* scaled_delta
			)
			_sprite.rotation = _charge_direction.angle() + PI * 0.5
			if _phase_remaining <= 0.0:
				_move_phase = MovePhase.RECOVERING
				_phase_remaining = 0.45
		MovePhase.RECOVERING:
			if _phase_remaining <= 0.0:
				_move_phase = MovePhase.DRIFTING
				_phase_remaining = tuning.action_interval
	_clamp_to_arena()
