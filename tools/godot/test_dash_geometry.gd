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
	_check_polygon_helpers()
	_check_on_boundary_dashes()
	if _failures == 0:
		print("dash_geometry: rect and polygon checks passed")
	quit(_failures)


## Polygon playfield helpers, added when the arena stopped being a shared rectangle.
func _check_polygon_helpers() -> void:
	# A square polygon must agree with the rectangle maths it replaces.
	var square := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(100.0, 0.0), Vector2(100.0, 100.0), Vector2(0.0, 100.0),
	])
	_check_vector(
		DashGeometry.ray_to_polygon_edge(Vector2(50.0, 50.0), Vector2.RIGHT, square),
		Vector2(100.0, 50.0),
		"polygon right edge",
	)
	_check_vector(
		DashGeometry.ray_to_polygon_edge(Vector2(50.0, 50.0), Vector2.UP, square),
		Vector2(50.0, 0.0),
		"polygon top edge",
	)
	# A ray must never land behind its origin.
	_check_vector(
		DashGeometry.ray_to_polygon_edge(Vector2(10.0, 50.0), Vector2.LEFT, square),
		Vector2(0.0, 50.0),
		"polygon near edge forward only",
	)
	# Degenerate input returns the origin rather than exploding.
	_check_vector(
		DashGeometry.ray_to_polygon_edge(Vector2(50.0, 50.0), Vector2.ZERO, square),
		Vector2(50.0, 50.0),
		"polygon zero direction",
	)
	_check_vector(
		DashGeometry.ray_to_polygon_edge(
			Vector2(50.0, 50.0), Vector2.RIGHT, PackedVector2Array()
		),
		Vector2(50.0, 50.0),
		"empty polygon",
	)

	if not DashGeometry.is_inside_polygon(Vector2(50.0, 50.0), square):
		_fail("centre should be inside the polygon")
	if DashGeometry.is_inside_polygon(Vector2(-5.0, 50.0), square):
		_fail("a point outside was reported inside")

	_check_vector(
		DashGeometry.nearest_polygon_point(Vector2(-20.0, 50.0), square),
		Vector2(0.0, 50.0),
		"nearest boundary point",
	)
	_check_vector(
		DashGeometry.polygon_centroid(square), Vector2(50.0, 50.0), "polygon centroid"
	)

	# The inward normal must point into the shape from whichever edge is nearest.
	_check_vector(
		DashGeometry.polygon_inward_normal(Vector2(2.0, 50.0), square),
		Vector2.RIGHT,
		"inward normal from the left edge",
	)
	_check_vector(
		DashGeometry.polygon_inward_normal(Vector2(50.0, 98.0), square),
		Vector2.UP,
		"inward normal from the bottom edge",
	)

	# Resting on the left wall, an outward aim must come back inward.
	var reflected: Vector2 = DashGeometry.reflect_inward_polygon(
		Vector2.LEFT, Vector2(1.0, 50.0), square, 3.0
	)
	if reflected.x <= 0.0:
		_fail("an outward aim at the wall was not reflected inward, got %s" % reflected)
	# From open floor the aim is preserved.
	_check_vector(
		DashGeometry.reflect_inward_polygon(Vector2.LEFT, Vector2(50.0, 50.0), square, 3.0),
		Vector2.LEFT,
		"open-floor aim preserved",
	)

	# Clamping pulls an outside point in and keeps the requested inset.
	var clamped: Vector2 = DashGeometry.clamp_to_polygon(Vector2(-30.0, 50.0), square, 10.0)
	if not DashGeometry.is_inside_polygon(clamped, square):
		_fail("clamping left the point outside, got %s" % clamped)
	if clamped.x < 9.0:
		_fail("clamping did not honour the inset, got %s" % clamped)

	# UV mapping and bounds, used to turn a baked floor into screen space.
	var mapped: PackedVector2Array = DashGeometry.polygon_from_uv(
		PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0)]),
		Rect2(10.0, 20.0, 200.0, 400.0),
	)
	_check_vector(mapped[0], Vector2(10.0, 20.0), "uv origin")
	_check_vector(mapped[2], Vector2(210.0, 420.0), "uv far corner")
	var bounds: Rect2 = DashGeometry.polygon_bounds(square)
	_check_vector(bounds.position, Vector2.ZERO, "polygon bounds position")
	_check_vector(bounds.size, Vector2(100.0, 100.0), "polygon bounds size")

	# Every baked Rift polygon must be usable: closed, in UV range, and containing its centroid.
	var catalog := load("res://data/rifts/default_catalog.tres") as RiftCatalog
	for rift: RiftData in catalog.load_rifts():
		if not rift.has_floor_polygon():
			_fail("%s has no baked floor polygon" % rift.rift_id)
			continue
		var screen: PackedVector2Array = DashGeometry.polygon_from_uv(
			rift.floor_polygon, Rect2(0.0, 0.0, 1080.0, 1920.0)
		)
		var centre: Vector2 = DashGeometry.polygon_centroid(screen)
		if not DashGeometry.is_inside_polygon(centre, screen):
			_fail("%s polygon does not contain its own centroid" % rift.rift_id)
		# A dash from the centre must reach a wall in every direction.
		for step: int in 8:
			var angle: float = TAU * float(step) / 8.0
			var landing: Vector2 = DashGeometry.ray_to_polygon_edge(
				centre, Vector2.RIGHT.rotated(angle), screen
			)
			if landing.distance_to(centre) < 1.0:
				_fail("%s: a dash at %.2f rad found no wall" % [rift.rift_id, angle])
		var area: float = DashGeometry.polygon_bounds(screen).get_area()
		if area < 1080.0 * 1920.0 * 0.15:
			_fail("%s floor polygon is implausibly small" % rift.rift_id)


func _fail(message: String) -> void:
	_failures += 1
	push_error("dash_geometry: %s" % message)


func _check_vector(actual: Vector2, expected: Vector2, label: String) -> void:
	if not actual.is_equal_approx(expected):
		_failures += 1
		push_error("dash_geometry: %s expected %s, got %s" % [label, expected, actual])


func _check_float(actual: float, expected: float, label: String) -> void:
	if not is_equal_approx(actual, expected):
		_failures += 1
		push_error("dash_geometry: %s expected %f, got %f" % [label, expected, actual])


## The riskiest case: resolving a dash from a point EXACTLY on the boundary.
##
## The Wisp rests on the wall, so every swipe casts from the boundary. Three things can go wrong
## there and all three are silent: the cast lands on the edge underfoot (zero-length dash, swipe
## swallowed), the reflection folds about the wrong plane (dash leaves the floor), and containment
## is undefined on the boundary. This sweeps every edge of every real Rift against a direction fan.
func _check_on_boundary_dashes() -> void:
	var catalog := load("res://data/rifts/default_catalog.tres") as RiftCatalog
	var screen_rect := Rect2(0.0, 0.0, 1080.0, 1920.0)
	# Only absorbs float error; the resting edge is excluded by identity, not by distance.
	var skip: float = 1.0
	var directions: int = 16

	for rift: RiftData in catalog.load_rifts():
		var polygon: PackedVector2Array = DashGeometry.polygon_from_uv(
			rift.floor_polygon, screen_rect
		)
		if polygon.size() < 3:
			_fail("%s has no usable polygon" % rift.rift_id)
			continue
		# Winding must be consistent, or edge normals point the wrong way.
		if is_zero_approx(DashGeometry.polygon_signed_area(polygon)):
			_fail("%s polygon has zero area" % rift.rift_id)
			continue

		for edge: int in polygon.size():
			var start: Vector2 = polygon[edge]
			var end: Vector2 = polygon[(edge + 1) % polygon.size()]
			var origin: Vector2 = (start + end) * 0.5
			var normal: Vector2 = DashGeometry.polygon_edge_normal(polygon, edge)

			# The edge normal must point into the shape.
			var probe: Vector2 = origin + normal * 6.0
			if not DashGeometry.is_inside_polygon_slack(probe, polygon, 1.0):
				_fail("%s edge %d normal points outward" % [rift.rift_id, edge])
				continue

			for step: int in directions:
				var angle: float = TAU * float(step) / float(directions)
				var aim: Vector2 = Vector2.RIGHT.rotated(angle)
				# Resolve exactly as the player will: reflect an outward swipe, then cast.
				var resolved: Vector2 = DashGeometry.reflect_inward_polygon(
					aim, origin, polygon, skip
				)
				if resolved.dot(normal) < -0.01:
					_fail("%s edge %d: resolved aim still points out of the floor"
						% [rift.rift_id, edge])
					break
				var hit: Dictionary = DashGeometry.cast_polygon(
					origin, resolved, polygon, skip, edge
				)
				if hit.is_empty():
					_fail("%s edge %d: no wall found from the boundary" % [rift.rift_id, edge])
					break
				# The landing must be forward and on a different edge than the one underfoot.
				if float(hit[&"distance"]) <= skip:
					_fail("%s edge %d: dash landed on itself (%.2f px)"
						% [rift.rift_id, edge, float(hit[&"distance"])])
					break
				if int(hit[&"edge"]) == edge:
					_fail("%s edge %d: dash hit the edge it started on" % [rift.rift_id, edge])
					break
				# And it must be on the floor, not past it.
				if not DashGeometry.is_inside_polygon_slack(
					hit[&"point"] as Vector2, polygon, 1.0
				):
					_fail("%s edge %d: landing is off the floor" % [rift.rift_id, edge])
					break

	# The inset polygon must never come back empty, even squeezed hard.
	for rift: RiftData in catalog.load_rifts():
		var polygon: PackedVector2Array = DashGeometry.polygon_from_uv(
			rift.floor_polygon, screen_rect
		)
		for inset: float in [20.0, 80.0, 400.0, 2000.0]:
			var shrunk: PackedVector2Array = DashGeometry.inset_polygon(polygon, inset)
			if shrunk.size() < 3:
				_fail("%s inset by %.0f produced an empty polygon" % [rift.rift_id, inset])