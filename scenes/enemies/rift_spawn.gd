class_name RiftSpawnEnemy
extends EnemyActor
## Tethered pair whose only weak point is the energy tether strung between its two bodies.
##
## The bodies themselves are immune, so the dash line has to be planned to cross the space
## *between* them rather than to hit either one.

## Points sampled along the tether when testing a dash; enough for a smooth hit band.
const TETHER_SAMPLES: int = 9

var _movement_direction: Vector2 = Vector2.DOWN
var _spin: float = 0.0

@onready var _tether: Line2D = %Tether
@onready var _body_b: Sprite2D = %BodyB


func _on_became_active() -> void:
	var desired: Vector2 = (_target_position - global_position).normalized()
	if not desired.is_zero_approx():
		_movement_direction = desired


func _advance_active(scaled_delta: float) -> void:
	if not movement_enabled:
		return
	_spin += scaled_delta * tuning.turn_speed * 0.35
	var desired: Vector2 = (_target_position - global_position).normalized()
	if not desired.is_zero_approx():
		var angle_delta: float = wrapf(desired.angle() - _movement_direction.angle(), -PI, PI)
		var turn: float = clampf(
			angle_delta,
			-tuning.turn_speed * scaled_delta,
			tuning.turn_speed * scaled_delta,
		)
		_movement_direction = _movement_direction.rotated(turn).normalized()
	position += _movement_direction * tuning.movement_speed * _viewport_scale * scaled_delta
	_update_tether()
	_clamp_to_arena()


## World-space endpoints of the tether: the pair's two bodies.
func get_tether_endpoints() -> PackedVector2Array:
	var offset: Vector2 = Vector2.RIGHT.rotated(_spin) * _half_length()
	return PackedVector2Array([global_position - offset, global_position + offset])


## Damages the pair only when the dash crosses the tether, never when it clips a body.
func try_dash_hit(
		segment_start: Vector2,
		segment_end: Vector2,
		corridor_radius: float,
		damage: int,
		damage_event_id: int,
	) -> bool:
	if state != State.ACTIVE or damage_event_id == _last_damage_event_id:
		return false
	var ends: PackedVector2Array = get_tether_endpoints()
	var hit_radius: float = corridor_radius + get_collision_radius() * 0.35
	for index: int in TETHER_SAMPLES:
		var t: float = float(index) / float(TETHER_SAMPLES - 1)
		var point: Vector2 = ends[0].lerp(ends[1], t)
		if DashGeometry.distance_to_segment(point, segment_start, segment_end) <= hit_radius:
			return try_direct_hit(damage, damage_event_id)
	return false


func _half_length() -> float:
	return tuning.tether_length * 0.5 * _viewport_scale


func _update_tether() -> void:
	var offset: Vector2 = Vector2.RIGHT.rotated(_spin) * _half_length()
	_body_b.position = offset
	_sprite.position = -offset
	_body_b.scale = _sprite.scale
	if _tether != null:
		_tether.points = PackedVector2Array([-offset, offset])
		_tether.width = maxf(4.0, 10.0 * _viewport_scale)
