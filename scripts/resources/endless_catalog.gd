class_name EndlessCatalog
extends Resource
## The Endless arenas' shared floor, the arenas themselves, the default one, Endless tuning and the
## enemy mixes and bosses Endless waves draw from.
##
## Every arena is painted to one contract (docs/guides/arena_art.md, ADR-0017): one canvas, the
## floor in the same place, so the floor lives here once and an arena can never change play.

## Native size of every arena background; `floor_rect` and `floor_polygon` are UV of this canvas.
## 941x1672 is the Quarry Titan as delivered - the contract's safe zone without its bleed. The
## contract canvas is 1080x2400; when the arena is re-delivered at that size, this and the floor
## move with it (the guide has the conversion).
const BACKGROUND_SIZE := Vector2i(941, 1672)
## Background pixels the painted rim may sit beyond the template (`rim_tolerance_px` of the
## template JSON). Scenery light, motion and particles must stay this far outside the floor.
const RIM_TOLERANCE_PX: float = 48.0
## Largest mask value (0-1) accepted on the floor after lossy import; the source PNG holds exact 0.
const MASK_FLOOR_TOLERANCE: float = 6.0 / 255.0
## Mask texels between floor samples checked by `validate(true)`.
const MASK_SAMPLE_STEP: int = 6

## The rectangle formations, hazards and the playfield's scale are laid out over, in background UV
## (the role `GameWorld.ARENA_FLOOR_UV` plays for the neutral arena). For a rectangular floor it is
## the floor.
@export var floor_rect: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
## The walls: the painted floor every arena shares, in background UV space.
@export var floor_polygon: PackedVector2Array = PackedVector2Array()
## Every arena skin, in Shop order.
@export var skins: Array[ArenaSkinData] = []
## Skin every save owns and falls back to.
@export var default_skin_id: StringName = &""
## Boss cadence, per-cycle difficulty and the daily pool.
@export var tuning: EndlessTuning
## Enemy mixes Endless waves draw from, in pick order; each brings its boss to the boss pool.
@export var rosters: Array[EndlessRoster] = []


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


## Every enemy mix, in pick order.
func get_rosters() -> Array[EndlessRoster]:
	return rosters.duplicate()


## The mixes with these ids, in the given order; unknown ids are skipped.
func get_rosters_by_id(roster_ids: Array[StringName]) -> Array[EndlessRoster]:
	var found: Array[EndlessRoster] = []
	for roster_id: StringName in roster_ids:
		for roster: EndlessRoster in rosters:
			if roster != null and roster.roster_id == roster_id:
				found.append(roster)
				break
	return found


## Bosses Endless may send: every mix's boss, in pick order, no repeats.
func get_boss_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for roster: EndlessRoster in rosters:
		if roster != null and roster.boss_id not in ids:
			ids.append(roster.boss_id)
	return ids


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


## Returns floor, id, default-skin (present and free), background-size, placeholder, scenery
## (tier, mask, keep-out), roster and tuning authoring failures. `check_backgrounds` loads every full-size
## background and scenery mask: pass false where that memory matters (no runtime code calls this).
func validate(check_backgrounds: bool = true) -> PackedStringArray:
	var failures := PackedStringArray()
	if floor_polygon.size() < 3:
		failures.append("floor polygon needs at least three points")
	for point: Vector2 in floor_polygon:
		if point.x < 0.0 or point.x > 1.0 or point.y < 0.0 or point.y > 1.0:
			failures.append("floor polygon point %s is outside UV space" % point)
			break
	if not Rect2(0.0, 0.0, 1.0, 1.0).encloses(floor_rect) or floor_rect.has_area() == false:
		failures.append("floor rect %s is not inside UV space" % floor_rect)
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
	var roster_ids: Dictionary[StringName, bool] = {}
	for roster: EndlessRoster in rosters:
		if roster == null:
			failures.append("catalog has an empty roster slot")
			continue
		if roster_ids.has(roster.roster_id):
			failures.append("duplicate roster id %s" % roster.roster_id)
		roster_ids[roster.roster_id] = true
		for failure: String in roster.validate():
			failures.append("%s: %s" % [roster.roster_id, failure])
	if tuning != null:
		for roster_id: StringName in tuning.daily_roster_ids:
			if not roster_ids.has(roster_id):
				failures.append("daily roster %s is not in the catalog" % roster_id)
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

