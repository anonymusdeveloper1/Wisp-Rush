class_name DashGeometry
extends RefCounted
## Pure geometry helpers for exact edge landings and swept dash collision.

const EPSILON: float = 0.0001


## Returns the first point where a ray from [param origin] reaches [param bounds].
static func ray_to_rect_edge(origin: Vector2, direction: Vector2, bounds: Rect2) -> Vector2:
	var ray_direction: Vector2 = direction.normalized()
	if ray_direction.is_zero_approx():
		return origin

	var travel_distance: float = INF
	if ray_direction.x > EPSILON:
		travel_distance = minf(
			travel_distance,
			(bounds.end.x - origin.x) / ray_direction.x,
		)
	elif ray_direction.x < -EPSILON:
		travel_distance = minf(
			travel_distance,
			(bounds.position.x - origin.x) / ray_direction.x,
		)
	if ray_direction.y > EPSILON:
		travel_distance = minf(
			travel_distance,
			(bounds.end.y - origin.y) / ray_direction.y,
		)
	elif ray_direction.y < -EPSILON:
		travel_distance = minf(
			travel_distance,
			(bounds.position.y - origin.y) / ray_direction.y,
		)

	if is_inf(travel_distance) or travel_distance < 0.0:
		return origin
	var result: Vector2 = origin + ray_direction * travel_distance
	return Vector2(
		clampf(result.x, bounds.position.x, bounds.end.x),
		clampf(result.y, bounds.position.y, bounds.end.y),
	)


## Reflects components that point out of a touched edge, then normalizes the result.
static func reflect_inward(
		direction: Vector2,
		origin: Vector2,
		bounds: Rect2,
		edge_threshold: float,
	) -> Vector2:
	var result: Vector2 = direction
	if origin.x <= bounds.position.x + edge_threshold and result.x < 0.0:
		result.x = -result.x
	elif origin.x >= bounds.end.x - edge_threshold and result.x > 0.0:
		result.x = -result.x
	if origin.y <= bounds.position.y + edge_threshold and result.y < 0.0:
		result.y = -result.y
	elif origin.y >= bounds.end.y - edge_threshold and result.y > 0.0:
		result.y = -result.y

	if result.is_zero_approx():
		result = bounds.get_center() - origin
	return result.normalized()


## Returns the inward-facing normal of the nearest edge to [param point].
static func inward_edge_normal(point: Vector2, bounds: Rect2) -> Vector2:
	var closest_distance: float = absf(point.x - bounds.position.x)
	var normal: Vector2 = Vector2.RIGHT
	var right_distance: float = absf(bounds.end.x - point.x)
	if right_distance < closest_distance:
		closest_distance = right_distance
		normal = Vector2.LEFT
	var top_distance: float = absf(point.y - bounds.position.y)
	if top_distance < closest_distance:
		closest_distance = top_distance
		normal = Vector2.DOWN
	var bottom_distance: float = absf(bounds.end.y - point.y)
	if bottom_distance < closest_distance:
		normal = Vector2.UP
	return normal


## Returns the shortest pixel distance from [param point] to [param start]–[param end].
static func distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var length_squared: float = segment.length_squared()
	if length_squared <= EPSILON:
		return point.distance_to(start)
	var ratio: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)
