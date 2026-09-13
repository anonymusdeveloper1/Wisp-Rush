class_name CinderShadeEnemy
extends EnemyActor
## Ember shade that drifts at the Wisp and splits into two smaller shades when cut.
##
## The split itself is GameWorld's job: it reads `tuning.split_kind` and `split_count` from the
## `killed` signal, because only GameWorld owns the enemy layer and the scene registry.

## Sideways wobble amplitude, as a fraction of forward speed.
const WOBBLE_AMOUNT: float = 0.35
const WOBBLE_RATE: float = 3.4

var _movement_direction: Vector2 = Vector2.UP
var _wobble_time: float = 0.0


func _on_became_active() -> void:
	var desired: Vector2 = (_target_position - global_position).normalized()
	if not desired.is_zero_approx():
		_movement_direction = desired


func _advance_active(scaled_delta: float) -> void:
	if not movement_enabled:
		return
	_wobble_time += scaled_delta
	var desired: Vector2 = (_target_position - global_position).normalized()
	if not desired.is_zero_approx():
		var angle_delta: float = wrapf(
			desired.angle() - _movement_direction.angle(),
			-PI,
			PI,
		)
		var turn: float = clampf(
			angle_delta,
			-tuning.turn_speed * scaled_delta,
			tuning.turn_speed * scaled_delta,
		)
		_movement_direction = _movement_direction.rotated(turn).normalized()
	# Embers drift rather than track cleanly, so the line you plan has to lead them a little.
	var wobble: Vector2 = _movement_direction.orthogonal() * (
		sin(_wobble_time * WOBBLE_RATE) * WOBBLE_AMOUNT
	)
	var step: Vector2 = (_movement_direction + wobble).normalized()
	position += step * tuning.movement_speed * _viewport_scale * scaled_delta
	_sprite.rotation = sin(_wobble_time * WOBBLE_RATE) * 0.14
	_clamp_to_arena()
