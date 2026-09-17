class_name EndlessCatalog
extends Resource
## The Endless floor template, its arena skins, the default skin and Endless tuning (ADR-0014).

## Native size of every arena background; the floor template's UV space is this canvas.
const BACKGROUND_SIZE := Vector2i(941, 1672)
## Art-side source of `floor_polygon`; read only by `validate()` when it is present (not exported).
const TEMPLATE_JSON_PATH: String = "res://concept_art/wisp_rush_endless_v1/floor_template.json"
## Largest per-coordinate difference allowed between `floor_polygon` and the template JSON.
const TEMPLATE_TOLERANCE: float = 1e-4
## Background pixels the painted rim may sit beyond the template (`rim_tolerance_px` of the
## template JSON). Scenery light, motion and particles must stay this far outside the floor.
const RIM_TOLERANCE_PX: float = 48.0
## Largest mask value (0-1) accepted on the floor after lossy import; the source PNG holds exact 0.
const MASK_FLOOR_TOLERANCE: float = 6.0 / 255.0
## Mask texels between floor samples checked by `validate(true)`.
const MASK_SAMPLE_STEP: int = 6

## The one playable floor every skin shares, in background UV space (`polygon_uv` of the template).
@export var floor_polygon: PackedVector2Array = PackedVector2Array()
## Every arena skin, in Shop order.
@export var skins: Array[ArenaSkinData] = []
## Skin every save owns and falls back to.
@export var default_skin_id: StringName = &""
## Boss cadence, per-cycle difficulty and the daily pool.
@export var tuning: EndlessTuning


## The skin with `skin_id`, or the default when the id is unknown.
func get_skin(skin_id: StringName) -> ArenaSkinData:
	var fallback: ArenaSkinData = null
	for skin: ArenaSkinData in skins:
		if skin == null:
			continue
		if skin.skin_id == skin_id:
			return skin
		if skin.skin_id == default_skin_id:
			fallback = skin
	if fallback == null and not skins.is_empty():
		fallback = skins[0]
	return fallback


## Deterministic skin for a YYYY-MM-DD date from every non-placeholder skin, ignoring ownership;
## placeholder skins only when no real skin exists.
func get_arena_of_the_day(date_key: String) -> ArenaSkinData:
	var pool: Array[ArenaSkinData] = []
	for skin: ArenaSkinData in skins:
		if skin != null and not skin.placeholder:
			pool.append(skin)
	if pool.is_empty():
		for skin: ArenaSkinData in skins:
			if skin != null:
				pool.append(skin)
	if pool.is_empty():
		return null
	return pool[posmod(ChallengeTracker.get_daily_seed(date_key), pool.size())]


## The floor polygon grown by `RIM_TOLERANCE_PX`, in background-texture pixels: the keep-out zone
## no scenery light, motion, set piece or particle may touch.
func get_ambience_keep_out() -> PackedVector2Array:
	var pixels := PackedVector2Array()
	for point: Vector2 in floor_polygon:
		pixels.append(point * Vector2(BACKGROUND_SIZE))
	var grown: Array[PackedVector2Array] = Geometry2D.offset_polygon(
		pixels, RIM_TOLERANCE_PX, Geometry2D.JOIN_ROUND
	)
	return grown[0] if not grown.is_empty() else pixels


## Whether a scenery region (background UV) stays clear of the floor plus rim tolerance.
func is_region_clear_of_floor(region_uv: Rect2) -> bool:
	var size := Vector2(BACKGROUND_SIZE)
	var rect := Rect2(region_uv.position * size, region_uv.size * size)
	var corners := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	return Geometry2D.intersect_polygons(corners, get_ambience_keep_out()).is_empty()


## Whether a point in background pixels lies outside the floor plus rim tolerance.
func is_point_clear_of_floor(point_px: Vector2) -> bool:
	return not Geometry2D.is_point_in_polygon(point_px, get_ambience_keep_out())


## Scenery placement failures of one skin: set-piece centre, shooting-star region, every particle
## emission point and its drift path outside the floor + rim tolerance; with `check_mask`, the
## mask's R, G and B are ~0 on the floor (loads the small mask image).
func validate_scenery(scenery: ArenaSceneryData, check_mask: bool = true) -> PackedStringArray:
	var failures := PackedStringArray()
	var canvas := Vector2(BACKGROUND_SIZE)
	var keep_out: PackedVector2Array = get_ambience_keep_out()
	if scenery.piece_kind != ArenaSceneryData.PieceKind.NONE \
			and Geometry2D.is_point_in_polygon(scenery.piece_center_uv * canvas, keep_out):
		failures.append("set piece centre %s is on the floor" % scenery.piece_center_uv)
	if scenery.streak_interval > 0.0 and not is_region_clear_of_floor(scenery.streak_region_uv):
		failures.append("shooting-star region %s overlaps the floor" % scenery.streak_region_uv)
	for emitter: ArenaParticleEmitter in scenery.emitters:
		if emitter == null:
			continue
		for point: Vector2 in emitter.points_uv:
			var origin: Vector2 = point * canvas
			var clear: bool = not Geometry2D.is_point_in_polygon(origin, keep_out)
			for sample: Vector2 in emitter.get_path_samples(origin):
				if clear and Geometry2D.is_point_in_polygon(sample, keep_out):
					clear = false
			if not clear:
				failures.append("particles %s from %s reach the floor" % [emitter.emitter_name, point])
				break
	if check_mask and scenery.mask != null:
		failures.append_array(_validate_mask_floor(scenery.mask))
	return failures


## Returns template, id, default-skin (present and free), background-size, placeholder, scenery
## (tier, mask, keep-out) and tuning authoring failures. `check_backgrounds` loads every full-size
## background and scenery mask: pass false where that memory matters (no runtime code calls this).
func validate(check_backgrounds: bool = true) -> PackedStringArray:
	var failures := PackedStringArray()
	if floor_polygon.size() < 3:
		failures.append("floor polygon needs at least three points")
	for point: Vector2 in floor_polygon:
		if point.x < 0.0 or point.x > 1.0 or point.y < 0.0 or point.y > 1.0:
			failures.append("floor polygon point %s is outside UV space" % point)
			break
	failures.append_array(_validate_template())
	if tuning == null:
		failures.append("tuning is missing")
	if skins.is_empty():
		failures.append("catalog has no skins")
	var seen: Dictionary[StringName, bool] = {}
	for skin: ArenaSkinData in skins:
		if skin == null:
			failures.append("catalog has an empty skin slot")
			continue
		if seen.has(skin.skin_id):
			failures.append("duplicate skin id %s" % skin.skin_id)
		seen[skin.skin_id] = true
		for failure: String in skin.validate(check_backgrounds):
			failures.append("%s: %s" % [skin.skin_id, failure])
		if skin.scenery != null:
			for failure: String in validate_scenery(skin.scenery, check_backgrounds):
				failures.append("%s: %s" % [skin.skin_id, failure])
	if not seen.has(default_skin_id):
		failures.append("default skin %s is not in the catalog" % default_skin_id)
	elif get_skin(default_skin_id).price != 0:
		failures.append("default skin %s is not free" % default_skin_id)
	return failures


## Mask texels well inside the floor must hold no light, motion or scenery weight.
func _validate_mask_floor(mask: Texture2D) -> PackedStringArray:
	var failures := PackedStringArray()
	var image: Image = mask.get_image()
	if image == null:
		failures.append("scenery mask has no image data")
		return failures
	if image.is_compressed():
		image.decompress()
	var centre := Vector2.ZERO
	for point: Vector2 in floor_polygon:
		centre += point / float(floor_polygon.size())
	# Shrink toward the centre so texels straddling the edge are not counted as floor.
	var texel := Vector2(1.0 / image.get_width(), 1.0 / image.get_height())
	var floor_uv := PackedVector2Array()
	for point: Vector2 in floor_polygon:
		floor_uv.append(point + (centre - point).normalized() * texel.length() * 3.0)
	for y: int in range(0, image.get_height(), MASK_SAMPLE_STEP):
		for x: int in range(0, image.get_width(), MASK_SAMPLE_STEP):
			var uv: Vector2 = (Vector2(x, y) + Vector2(0.5, 0.5)) * texel
			if not Geometry2D.is_point_in_polygon(uv, floor_uv):
				continue
			var value: Color = image.get_pixel(x, y)
			if maxf(value.r, maxf(value.g, value.b)) > MASK_FLOOR_TOLERANCE:
				failures.append("scenery mask is not empty on the floor at %s (%s)" % [uv, value])
				return failures
	return failures


func _validate_template() -> PackedStringArray:
	var failures := PackedStringArray()
	if not FileAccess.file_exists(TEMPLATE_JSON_PATH):
		return failures
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEMPLATE_JSON_PATH))
	if not parsed is Dictionary or not (parsed as Dictionary).get("polygon_uv") is Array:
		failures.append("floor template JSON has no polygon_uv")
		return failures
	var points: Array = (parsed as Dictionary)["polygon_uv"] as Array
	if points.size() != floor_polygon.size():
		failures.append("floor polygon has %d points, the template %d" % [
			floor_polygon.size(), points.size(),
		])
		return failures
	for index: int in points.size():
		var pair: Array = points[index] as Array
		var expected := Vector2(float(pair[0]), float(pair[1]))
		if (
			absf(floor_polygon[index].x - expected.x) > TEMPLATE_TOLERANCE
			or absf(floor_polygon[index].y - expected.y) > TEMPLATE_TOLERANCE
		):
			failures.append("floor polygon point %d differs from the template" % index)
	return failures
