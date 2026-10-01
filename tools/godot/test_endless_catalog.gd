extends SceneTree
## Endless catalog (ADR-0017, ADR-0020, ADR-0021, ADR-0023, docs/guides/arena_art.md): the arenas,
## their backgrounds and Shop thumbnails, each arena's measured floor against the floor the game uses
## for it (the shared one, or its own), layered and 3D arenas' scenes and fitted floors, the arena of
## the day, the rules' floor and save sanitizing of the thirty arenas retired on 2026-09-23.
##
##     Godot --headless --path . --script res://tools/godot/test_endless_catalog.gd

const CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
## Each arena's art manifest, whose `floor_rect_px` the catalog's floor must match.
const ARENA_MANIFEST: String = "res://concept_art/arenas_v2/%s/arena.json"
const DEFAULT_SKIN_ID: StringName = &"quarry_titan"
## UV difference allowed between the catalog floor and the measured one (well under a pixel).
const FLOOR_TOLERANCE: float = 1e-3
## Largest Shop thumbnail width; the full background is only for cards near the focus.
const MAX_THUMBNAIL_WIDTH: int = 400
## Portrait screens (design px) an arena scene is fitted to, the first the owner's phone, and the
## HUD's safe top used for them.
const LAYERED_VIEWS: Array[Vector2] = [
	Vector2(1080.0, 2340.0), Vector2(1080.0, 2400.0), Vector2(1080.0, 1920.0), Vector2(1200.0, 1920.0),
]
const LAYERED_SAFE_TOP: float = 125.0
## The painted arena used to compare the Vigil's revised, narrower floor on the owner's phone.
const COMPARISON_ARENA_ID: StringName = &"stitched_doll_jungle"
const VIGIL_ID: StringName = &"stitchwarden_vigil"
## The 3D arena whose floor is "a little bigger" than the Vigil's (owner, GDD §14 #68), and how much
## bigger at most, so "a little" stays true.
const COLOSSUS_3D_ID: StringName = &"chained_colossus_3d"
const COLOSSUS_3D_MAX_GROWTH: float = 1.25
## The zoom test arena (owner, GDD §14 #69): it opens with a zoom, and once zoomed in its floor fills
## the screen under the HUD, so it is bigger than the Colossus 3D's on every screen.
const ZOOM_ARENA_ID: StringName = &"zoom_arena_3d"
## The board arenas (owner 2026-10-02, ADR-0024): they draw the run's HUD in their own frame.
const BOARD_IDS: Array[StringName] = [&"board_01", &"board_01_light"]

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	for failure: String in CATALOG.validate():
		_fail(failure)
	_check_skins()
	_check_floor()
	_check_layered()
	_check_arena_of_the_day()
	_check_rules()
	_check_saves()
	if _failures == 0:
		print("endless_catalog: %d arena(s), floor, backgrounds, daily arena, rules and saves validated" % (
			CATALOG.skins.size()
		))
	quit(_failures)


func _check_skins() -> void:
	if CATALOG.default_skin_id != DEFAULT_SKIN_ID:
		_fail("default skin is %s" % CATALOG.default_skin_id)
	if CATALOG.get_skin(DEFAULT_SKIN_ID) == null or CATALOG.get_skin(DEFAULT_SKIN_ID).price != 0:
		_fail("the default arena is missing or not free")
	var save_ids: Array[String] = []
	for skin: ArenaSkinData in CATALOG.skins:
		save_ids.append(String(skin.skin_id))
		if skin.placeholder:
			_fail("%s is a placeholder" % skin.skin_id)
		var background: Texture2D = skin.load_background()
		if background == null or Vector2i(background.get_size()) != EndlessCatalog.BACKGROUND_SIZE:
			_fail("%s background is not %s" % [skin.skin_id, EndlessCatalog.BACKGROUND_SIZE])
		if skin.thumbnail == null or skin.thumbnail.get_width() > MAX_THUMBNAIL_WIDTH:
			_fail("%s needs a small Shop thumbnail" % skin.skin_id)
	if save_ids != SaveManagerService.VALID_ARENA_SKIN_IDS:
		_fail("SaveManagerService.VALID_ARENA_SKIN_IDS %s does not match the catalog %s" % [
			SaveManagerService.VALID_ARENA_SKIN_IDS, save_ids,
		])


## Every arena's painted floor must be exactly where the game puts the walls: the shared floor, or the
## arena's own when it brings one (ADR-0020).
func _check_floor() -> void:
	var bounds := Rect2(CATALOG.floor_polygon[0], Vector2.ZERO)
	for point: Vector2 in CATALOG.floor_polygon:
		bounds = bounds.expand(point)
	if not CATALOG.floor_rect.grow(FLOOR_TOLERANCE).encloses(bounds):
		_fail("floor polygon %s leaves the floor rect %s" % [bounds, CATALOG.floor_rect])
	var canvas := Vector2(EndlessCatalog.BACKGROUND_SIZE)
	for skin: ArenaSkinData in CATALOG.skins:
		var path: String = ARENA_MANIFEST % skin.skin_id
		if not FileAccess.file_exists(path):
			_fail("%s has no art manifest at %s" % [skin.skin_id, path])
			continue
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
		var px: Array = manifest["floor_rect_px"] as Array
		var measured := Rect2(
			Vector2(float(px[0]), float(px[1])) / canvas,
			Vector2(float(px[2]) - float(px[0]), float(px[3]) - float(px[1])) / canvas,
		)
		var expected: Rect2 = skin.floor_rect if skin.has_own_floor() else CATALOG.floor_rect
		var delta: Vector4 = Vector4(
			measured.position.x - expected.position.x, measured.position.y - expected.position.y,
			measured.size.x - expected.size.x, measured.size.y - expected.size.y,
		).abs()
		if maxf(maxf(delta.x, delta.y), maxf(delta.z, delta.w)) > FLOOR_TOLERANCE:
			_fail("%s paints its floor at %s, the game puts it at %s" % [
				skin.skin_id, measured, expected,
			])


## An arena scene loads as an `ArenaVisual`; fitted to each phone its floor is on screen and is the
## rect it reports. On the owner's phone the Vigil's revised floor is smaller than the Stitched Doll
## Jungle's painted floor, cover-scaled the way GameWorld draws it; on every 1080-wide phone the 3D
## Colossus's floor is a little bigger than the Vigil's (on the tablet shape the colossus's tall head
## leaves less room, so it is not checked there).
func _check_layered() -> void:
	var floors: Dictionary[StringName, Array] = {}
	for skin: ArenaSkinData in CATALOG.skins:
		if not skin.has_visual_scene():
			continue
		var scene: PackedScene = skin.load_visual_scene()
		var node: Node = scene.instantiate() if scene != null else null
		var visual := node as ArenaVisual
		if visual == null:
			_fail("%s: its scene is not an ArenaVisual" % skin.skin_id)
			if node != null:
				node.free()
			continue
		root.add_child(visual)
		var fitted: Array[Rect2] = []
		for view: Vector2 in LAYERED_VIEWS:
			var floor_rect: Rect2 = visual.fit(view, LAYERED_SAFE_TOP)
			if not Rect2(Vector2.ZERO, view).encloses(floor_rect) or not floor_rect.has_area():
				_fail("%s: floor %s is not on a %s screen" % [skin.skin_id, floor_rect, view])
			if floor_rect != visual.get_floor_rect():
				_fail("%s: fit() and get_floor_rect() disagree" % skin.skin_id)
			fitted.append(floor_rect)
		floors[skin.skin_id] = fitted
		if visual.has_intro() != (skin.skin_id == ZOOM_ARENA_ID):
			_fail("%s: has_intro() is %s" % [skin.skin_id, visual.has_intro()])
		if visual.has_board_hud() != (skin.skin_id in BOARD_IDS):
			_fail("%s: has_board_hud() is %s" % [skin.skin_id, visual.has_board_hud()])
		if visual.has_intro():
			var ended: Array[bool] = [false]
			visual.intro_finished.connect(func() -> void: ended[0] = true, CONNECT_ONE_SHOT)
			visual.play_intro()
			visual.skip_intro()
			if not ended[0] or visual.get_drawn_floor_rect() != visual.get_floor_rect():
				_fail("%s: a skipped intro does not end on the play floor" % skin.skin_id)
		var owner_floor: Rect2 = visual.fit(LAYERED_VIEWS[0], LAYERED_SAFE_TOP)
		var comparison: ArenaSkinData = CATALOG.get_skin(COMPARISON_ARENA_ID)
		if skin.skin_id == VIGIL_ID and comparison != null and comparison.skin_id == COMPARISON_ARENA_ID \
				and comparison.has_own_floor():
			var canvas := Vector2(EndlessCatalog.BACKGROUND_SIZE)
			var cover: float = maxf(LAYERED_VIEWS[0].x / canvas.x, LAYERED_VIEWS[0].y / canvas.y)
			var painted: Vector2 = comparison.floor_rect.size * canvas * cover
			if owner_floor.size.x >= painted.x or owner_floor.size.y >= painted.y:
				_fail("%s: floor %s is not smaller than %s's %s" % [
					skin.skin_id, owner_floor.size, COMPARISON_ARENA_ID, painted,
				])
		visual.free()
	if floors.has(ZOOM_ARENA_ID) and floors.has(COLOSSUS_3D_ID):
		for i: int in LAYERED_VIEWS.size():
			var zoomed: Rect2 = floors[ZOOM_ARENA_ID][i]
			if zoomed.size.y <= (floors[COLOSSUS_3D_ID][i] as Rect2).size.y:
				_fail("%s: zoomed-in floor %s on %s is not bigger than the Colossus 3D's" % [
					ZOOM_ARENA_ID, zoomed.size, LAYERED_VIEWS[i],
				])
	if floors.has(COLOSSUS_3D_ID) and floors.has(VIGIL_ID):
		for i: int in LAYERED_VIEWS.size():
			if LAYERED_VIEWS[i].x != 1080.0:
				continue
			var colossus: Rect2 = floors[COLOSSUS_3D_ID][i]
			var vigil: Rect2 = floors[VIGIL_ID][i]
			var growth: float = colossus.size.y / vigil.size.y
			if colossus.size.x <= vigil.size.x or growth <= 1.0 or growth > COLOSSUS_3D_MAX_GROWTH:
				_fail("%s: floor %s on %s is not a little bigger than the Vigil's %s" % [
					COLOSSUS_3D_ID, colossus.size, LAYERED_VIEWS[i], vigil.size,
				])


func _check_arena_of_the_day() -> void:
	var day: int = int(Time.get_unix_time_from_datetime_string("2026-01-01T00:00:00"))
	for offset: int in 60:
		var key: String = Time.get_date_string_from_unix_time(day + offset * 86400)
		var skin: ArenaSkinData = CATALOG.get_arena_of_the_day(key)
		if skin == null or not skin in CATALOG.skins:
			_fail("no arena of the day for %s" % key)
			return


func _check_rules() -> void:
	var skin: ArenaSkinData = CATALOG.get_skin(DEFAULT_SKIN_ID)
	var no_rosters: Array[EndlessRoster] = []
	var no_bosses: Array[StringName] = []
	var rules := EndlessArenaRules.new(CATALOG, skin, no_rosters, no_bosses)
	if rules.get_floor_polygon() != CATALOG.floor_polygon:
		_fail("an arena changed the floor polygon")
	if rules.get_floor_rect_uv() != CATALOG.floor_rect:
		_fail("EndlessArenaRules does not lay the playfield over the catalog's floor rect")
	if rules.get_background() == null:
		_fail("EndlessArenaRules does not load the background")
	if rules.get_visual_scene() != null:
		_fail("a painted arena gave a layered scene")
	if ArenaRules.new().get_floor_rect_uv().has_area():
		_fail("the neutral arena must fall back to GameWorld.ARENA_FLOOR_UV")
	for own: ArenaSkinData in CATALOG.skins:
		if not own.has_own_floor():
			continue
		var own_rules := EndlessArenaRules.new(CATALOG, own, no_rosters, no_bosses)
		if own_rules.get_floor_rect_uv() != own.floor_rect or own_rules.get_floor_polygon().size() != 4:
			_fail("%s does not lay the playfield over its own floor" % own.skin_id)
		if own.has_visual_scene() and own_rules.get_visual_scene() == null:
			_fail("%s does not give its layered scene" % own.skin_id)


## A save that owned or equipped any of the retired arenas keeps working: only the default is left.
func _check_saves() -> void:
	var test_root: String = "user://test_runs/endless_catalog_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_root)
	var save_path: String = test_root + "/save.json"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"schema_version": SaveManagerService.SCHEMA_VERSION,
		"owned_arena_skins": ["astral_observatory", "aurora_throne", "placeholder_void_slate"],
		"equipped_arena_skin": "aurora_throne",
	}))
	file.close()
	var manager := SaveManagerService.new()
	manager.configure_storage_paths(save_path, test_root + "/save.tmp.json", test_root + "/save.backup.json")
	root.add_child(manager)
	manager.reload()
	var snapshot: Dictionary = manager.get_snapshot()
	var owned: Array = snapshot[&"owned_arena_skins"] as Array
	if owned != [String(DEFAULT_SKIN_ID)] or snapshot[&"equipped_arena_skin"] != String(DEFAULT_SKIN_ID):
		_fail("save sanitizing kept a retired arena: %s / %s" % [
			owned, snapshot[&"equipped_arena_skin"],
		])
	if manager.equip_cosmetic(SaveManagerService.KIND_ARENA_SKIN, &"aurora_throne"):
		_fail("equip accepted a retired arena")
	manager.queue_free()


func _fail(message: String) -> void:
	_failures += 1
	push_error("endless_catalog: %s" % message)
