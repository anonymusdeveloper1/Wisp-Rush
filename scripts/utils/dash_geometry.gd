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


## Signed area of [param polygon]; the sign tells us its winding order.
##
## Winding is the only reliable way to orient edge normals. Deriving them by comparing against the
## centroid fails on any arena where an edge's nearest interior point is not toward the middle, and
## the generated floors are not guaranteed convex.
static func polygon_signed_area(polygon: PackedVector2Array) -> float:
	if polygon.size() < 3:
		return 0.0
	var total: float = 0.0
	for index: int in polygon.size():
		var current: Vector2 = polygon[index]
		var next: Vector2 = polygon[(index + 1) % polygon.size()]
		total += current.x * next.y - next.x * current.y
	return total * 0.5


## Inward-facing unit normal of the [param index]th edge of [param polygon].
static func polygon_edge_normal(polygon: PackedVector2Array, index: int) -> Vector2:
	if polygon.size() < 3:
		return Vector2.ZERO
	var count: int = polygon.size()
	var edge: Vector2 = polygon[(index + 1) % count] - polygon[index % count]
	if edge.is_zero_approx():
		return Vector2.ZERO
	var normal: Vector2 = edge.orthogonal().normalized()
	# With a positive signed area, orthogonal() points out of the shape, so flip it.
	return -normal if polygon_signed_area(polygon) > 0.0 else normal


## Casts a ray and reports the boundary point, the edge it hit and how far it travelled.
##
## The Wisp rests exactly on the edge it casts from, so that edge must be excluded or every dash
## lands on itself. It is excluded by IDENTITY via [param exclude_edge], not by distance: a
## distance-based skip would also discard legitimate short dashes into a nearby corner, which is
## how a swipe ends up silently swallowed. [param skip_distance] stays small and only absorbs float
## error. Returns an empty Dictionary when nothing is hit.
static func cast_polygon(
		origin: Vector2,
		direction: Vector2,
		polygon: PackedVector2Array,
		skip_distance: float = 1.0,
		exclude_edge: int = -1,
	) -> Dictionary:
	var ray_direction: Vector2 = direction.normalized()
	if ray_direction.is_zero_approx() or polygon.size() < 3:
		return {}
	var nearest: float = INF
	var hit_edge: int = -1
	for index: int in polygon.size():
		if index == exclude_edge:
			continue
		var start: Vector2 = polygon[index]
		var end: Vector2 = polygon[(index + 1) % polygon.size()]
		var travel: float = _ray_segment_distance(origin, ray_direction, start, end)
		if travel > maxf(skip_distance, EPSILON) and travel < nearest:
			nearest = travel
			hit_edge = index
	if hit_edge < 0:
		return {}
	return {
		&"point": origin + ray_direction * nearest,
		&"edge": hit_edge,
		&"distance": nearest,
		&"normal": polygon_edge_normal(polygon, hit_edge),
	}


## Returns the first point where a ray from [param origin] reaches the [param polygon] boundary.
##
## Polygon counterpart of [method ray_to_rect_edge]. Returns [param origin] when nothing is hit,
## matching the rectangle version, so callers keep their existing degenerate-dash guard.
static func ray_to_polygon_edge(
		origin: Vector2,
		direction: Vector2,
		polygon: PackedVector2Array,
		skip_distance: float = 1.0,
		exclude_edge: int = -1,
	) -> Vector2:
	var hit: Dictionary = cast_polygon(
		origin, direction, polygon, skip_distance, exclude_edge
	)
	return hit.get(&"point", origin) as Vector2


## Distance along a unit ray to a segment, or -1 when they do not cross.
static func _ray_segment_distance(
		origin: Vector2,
		ray_direction: Vector2,
		start: Vector2,
		end: Vector2,
	) -> float:
	var edge: Vector2 = end - start
	var denominator: float = ray_direction.cross(edge)
	if absf(denominator) <= EPSILON:
		return -1.0
	var offset: Vector2 = start - origin
	var travel: float = offset.cross(edge) / denominator
	var edge_ratio: float = offset.cross(ray_direction) / denominator
	if travel < 0.0 or edge_ratio < 0.0 or edge_ratio > 1.0:
		return -1.0
	return travel


## Whether [param point] lies inside [param polygon].
static func is_inside_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, polygon)


## Tolerant containment: inside, or within [param slack] pixels of the boundary.
##
## `Geometry2D.is_point_in_polygon` is undefined exactly on the boundary, which is where the Wisp
## always stands, so every player-facing containment question must allow slack.
static func is_inside_polygon_slack(
		point: Vector2,
		polygon: PackedVector2Array,
		slack: float,
	) -> bool:
	if polygon.size() < 3:
		return false
	if is_inside_polygon(point, polygon):
		return true
	return point.distance_to(nearest_polygon_point(point, polygon)) <= maxf(slack, 0.0)


## Shrinks [param polygon] inward by [param inset] pixels.
##
## `Geometry2D.offset_polygon` can return nothing at all for a small arena and a large inset, which
## would leave the Wisp with no legal place to stand. Falls back to scaling about the centroid, and
## finally to the original, so the result is never empty.
static func inset_polygon(polygon: PackedVector2Array, inset: float) -> PackedVector2Array:
	if polygon.size() < 3 or inset <= 0.0:
		return polygon
	var offsets: Array[PackedVector2Array] = Geometry2D.offset_polygon(polygon, -inset)
	var best := PackedVector2Array()
	for candidate: PackedVector2Array in offsets:
		if candidate.size() >= 3 and absf(polygon_signed_area(candidate)) > absf(
			polygon_signed_area(best)
		):
			best = candidate
	if best.size() >= 3:
		return best
	# Uniform shrink about the centroid: crude, but always non-empty and always inside.
	var centre: Vector2 = polygon_centroid(polygon)
	var bounds: Rect2 = polygon_bounds(polygon)
	var span: float = maxf(1.0, minf(bounds.size.x, bounds.size.y) * 0.5)
	var factor: float = clampf(1.0 - inset / span, 0.2, 1.0)
	var scaled := PackedVector2Array()
	for point: Vector2 in polygon:
		scaled.append(centre + (point - centre) * factor)
	return scaled


## Returns the closest point on the [param polygon] boundary to [param point].
static func nearest_polygon_point(point: Vector2, polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return point
	var best: Vector2 = polygon[0]
	var best_distance: float = INF
	for index: int in polygon.size():
		var start: Vector2 = polygon[index]
		var end: Vector2 = polygon[(index + 1) % polygon.size()]
		var candidate: Vector2 = _closest_point_on_segment(point, start, end)
		var distance: float = point.distance_squared_to(candidate)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## Returns the inward-facing normal of the [param polygon] edge nearest [param point].
static func polygon_inward_normal(point: Vector2, polygon: PackedVector2Array) -> Vector2:
	var index: int = nearest_polygon_edge(point, polygon)
	return Vector2.ZERO if index < 0 else polygon_edge_normal(polygon, index)


## Index of the [param polygon] edge nearest [param point], or -1 for a degenerate polygon.
static func nearest_polygon_edge(point: Vector2, polygon: PackedVector2Array) -> int:
	if polygon.size() < 3:
		return -1
	var best_index: int = -1
	var best_distance: float = INF
	for index: int in polygon.size():
		var start: Vector2 = polygon[index]
		var end: Vector2 = polygon[(index + 1) % polygon.size()]
		var distance: float = distance_to_segment(point, start, end)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


## Reflects a direction that points out of the nearest [param polygon] edge back inward.
static func reflect_inward_polygon(
		direction: Vector2,
		origin: Vector2,
		polygon: PackedVector2Array,
		edge_threshold: float,
	) -> Vector2:
	if polygon.size() < 3:
		return direction.normalized()
	var result: Vector2 = direction
	var boundary: Vector2 = nearest_polygon_point(origin, polygon)
	# Only reflect while actually resting against a wall; a dash from open floor keeps its aim.
	if origin.distance_to(boundary) <= edge_threshold or not is_inside_polygon(origin, polygon):
		var normal: Vector2 = polygon_inward_normal(origin, polygon)
		if not normal.is_zero_approx() and result.dot(normal) < 0.0:
			# bounce() takes the plane NORMAL and flips only the component along it, so the
			# tangential part is preserved exactly as the rectangle version preserved the
			# non-offending axis.
			result = result.bounce(normal)
	if result.is_zero_approx():
		result = polygon_centroid(polygon) - origin
	return result.normalized()


## Moves [param point] inside [param polygon], keeping [param inset] pixels clear of the wall.
static func clamp_to_polygon(
		point: Vector2,
		polygon: PackedVector2Array,
		inset: float,
	) -> Vector2:
	if polygon.size() < 3:
		return point
	var result: Vector2 = point
	if not is_inside_polygon(result, polygon):
		result = nearest_polygon_point(result, polygon)
	if inset <= 0.0:
		return result
	var boundary: Vector2 = nearest_polygon_point(result, polygon)
	var gap: float = result.distance_to(boundary)
	if gap >= inset:
		return result
	# Push along the inward normal rather than toward the centroid, so long thin arenas do not
	# pull everything to the middle.
	var normal: Vector2 = polygon_inward_normal(result, polygon)
	if normal.is_zero_approx():
		return result
	var pushed: Vector2 = boundary + normal * inset
	return pushed if is_inside_polygon(pushed, polygon) else result


## Average of the [param polygon] vertices.
static func polygon_centroid(polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return Vector2.ZERO
	var total: Vector2 = Vector2.ZERO
	for point: Vector2 in polygon:
		total += point
	return total / float(polygon.size())


## Maps a [param uv] polygon onto [param rect], for turning a baked floor into screen space.
static func polygon_from_uv(uv: PackedVector2Array, rect: Rect2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in uv:
		result.append(rect.position + point * rect.size)
	return result


## Axis-aligned bounding box of [param polygon]; callers that genuinely want a rect use this.
static func polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var minimum: Vector2 = polygon[0]
	var maximum: Vector2 = polygon[0]
	for point: Vector2 in polygon:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


static func _closest_point_on_segment(point: Vector2, start: Vector2, end: Vector2) -> Vector2:
	var segment: Vector2 = end - start
	var length_squared: float = segment.length_squared()
	if length_squared <= EPSILON:
		return start
	var ratio: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * ratio
