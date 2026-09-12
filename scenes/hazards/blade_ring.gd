class_name BladeRing
extends HazardActor
## Fixed rotating ring whose four visible blade tips are dangerous while its centre remains safe.

var _blade_angle: float = 0.0


func _advance_hazard(scaled_delta: float) -> void:
	_blade_angle = fposmod(_blade_angle + tuning.rotation_speed * scaled_delta, TAU)
	_sprite.rotation = _blade_angle


func get_dangerous_circles() -> Array[Vector3]:
	var circles: Array[Vector3] = []
	if state != State.ACTIVE:
		return circles
	var orbit_radius: float = tuning.orbit_radius * _viewport_scale
	var blade_radius: float = tuning.blade_radius * _viewport_scale
	for blade_index: int in 4:
		var point: Vector2 = global_position + Vector2.RIGHT.rotated(
			_blade_angle + float(blade_index) * PI * 0.5
		) * orbit_radius
		circles.append(Vector3(point.x, point.y, blade_radius))
	return circles
