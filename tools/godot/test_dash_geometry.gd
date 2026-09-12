extends SceneTree
## Command-line checks for exact edge intersections, inward reflection and swept distance.

var _failures: int = 0


func _init() -> void:
	var bounds := Rect2(10.0, 20.0, 100.0, 200.0)
	_check_vector(
		DashGeometry.ray_to_rect_edge(Vector2(60.0, 120.0), Vector2.RIGHT, bounds),
		Vector2(110.0, 120.0),
		"right edge",
	)
	_check_vector(
		DashGeometry.ray_to_rect_edge(Vector2(60.0, 120.0), Vector2(-1.0, -2.0), bounds),
		Vector2(10.0, 20.0),
		"corner intersection",
	)
	_check_vector(
		DashGeometry.reflect_inward(Vector2.LEFT, Vector2(10.0, 80.0), bounds, 0.5),
		Vector2.RIGHT,
		"left-edge reflection",
	)
	_check_float(
		DashGeometry.distance_to_segment(Vector2(5.0, 3.0), Vector2.ZERO, Vector2(10.0, 0.0)),
		3.0,
		"segment distance",
	)
	if _failures == 0:
		print("dash_geometry: 4 checks passed")
	quit(_failures)


func _check_vector(actual: Vector2, expected: Vector2, label: String) -> void:
	if not actual.is_equal_approx(expected):
		_failures += 1
		push_error("dash_geometry: %s expected %s, got %s" % [label, expected, actual])


func _check_float(actual: float, expected: float, label: String) -> void:
	if not is_equal_approx(actual, expected):
		_failures += 1
		push_error("dash_geometry: %s expected %f, got %f" % [label, expected, actual])
