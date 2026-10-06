extends SceneTree
## Endless catalog (ADR-0027: one arena, SIMULATION): the catalog validates, the save's arena ids match
## it, the arena's scene loads as a board `ArenaVisual` whose fitted floor is on every portrait screen,
## the arena of the day, the rules' scene (Endless and neutral) and save sanitizing of every retired
## arena.
##
##     Godot --headless --path . --script res://tools/godot/test_endless_catalog.gd

const CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const DEFAULT_SKIN_ID: StringName = &"sci_fi_simulation_v1"
## Portrait screens (design px) the arena is fitted to, and the HUD's safe top used for them.
const VIEWS: Array[Vector2] = [
	Vector2(1080.0, 2340.0), Vector2(1080.0, 2400.0), Vector2(1080.0, 1920.0), Vector2(1200.0, 1920.0),
	Vector2(1440.0, 1920.0),
]
const SAFE_TOP: float = 125.0
## Arena ids retired over time, each of which a save may still name.
const RETIRED_IDS: Array[String] = [
	"astral_observatory", "placeholder_void_slate", "quarry_titan", "stitched_doll_jungle",
	"stitchwarden_vigil", "chained_colossus", "chained_colossus_3d", "zoom_arena_3d", "board_01",
	"board_01_light",
]

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	for failure: String in CATALOG.validate():
		_fail(failure)
	_check_skins()
	_check_scene()
	_check_arena_of_the_day()
	_check_rules()
	_check_saves()
	if _failures == 0:
		print("endless_catalog: %d arena, scene, daily arena, rules and saves validated" % (
			CATALOG.skins.size()
		))
	quit(_failures)


func _check_skins() -> void:
	if CATALOG.default_skin_id != DEFAULT_SKIN_ID:
		_fail("default arena is %s" % CATALOG.default_skin_id)
	var save_ids: Array[String] = []
	for skin: ArenaSkinData in CATALOG.skins:
		save_ids.append(String(skin.skin_id))
	if save_ids != [String(DEFAULT_SKIN_ID)]:
		_fail("the catalog should hold only %s, it holds %s" % [DEFAULT_SKIN_ID, save_ids])
	if save_ids != SaveManagerService.VALID_ARENA_SKIN_IDS:
		_fail("SaveManagerService.VALID_ARENA_SKIN_IDS %s does not match the catalog %s" % [
			SaveManagerService.VALID_ARENA_SKIN_IDS, save_ids,
		])


## The arena's scene loads as a board `ArenaVisual`; fitted to each portrait screen its floor is on
## screen and is the rect it reports.
func _check_scene() -> void:
	var skin: ArenaSkinData = CATALOG.get_skin(DEFAULT_SKIN_ID)
	var scene: PackedScene = skin.load_visual_scene() if skin != null else null
	var node: Node = scene.instantiate() if scene != null else null
	var visual := node as ArenaVisual
	if visual == null:
		_fail("%s: its scene is not an ArenaVisual" % DEFAULT_SKIN_ID)
		if node != null:
			node.free()
		return
	root.add_child(visual)
	if not visual.has_board_hud():
		_fail("%s does not draw the HUD" % DEFAULT_SKIN_ID)
	for view: Vector2 in VIEWS:
		var floor_rect: Rect2 = visual.fit(view, SAFE_TOP)
		if not Rect2(Vector2.ZERO, view).encloses(floor_rect) or not floor_rect.has_area():
			_fail("floor %s is not on a %s screen" % [floor_rect, view])
		if floor_rect != visual.get_floor_rect():
			_fail("fit() and get_floor_rect() disagree on %s" % view)
	visual.free()


func _check_arena_of_the_day() -> void:
	var day: int = int(Time.get_unix_time_from_datetime_string("2026-01-01T00:00:00"))
	for offset: int in 30:
		var key: String = Time.get_date_string_from_unix_time(day + offset * 86400)
		var skin: ArenaSkinData = CATALOG.get_arena_of_the_day(key)
		if skin == null or skin.skin_id != DEFAULT_SKIN_ID:
			_fail("the arena of the day for %s is not %s" % [key, DEFAULT_SKIN_ID])
			return


## Endless rules give the arena's scene; the neutral arena (no profile) plays on it too.
func _check_rules() -> void:
	var skin: ArenaSkinData = CATALOG.get_skin(DEFAULT_SKIN_ID)
	var no_rosters: Array[EndlessRoster] = []
	var no_bosses: Array[StringName] = []
	var rules := EndlessArenaRules.new(CATALOG, skin, no_rosters, no_bosses)
	var scene: PackedScene = rules.get_visual_scene()
	if scene == null or scene.resource_path != skin.visual_scene_path:
		_fail("EndlessArenaRules does not give the arena's scene")
	var neutral: PackedScene = ArenaRules.new().get_visual_scene()
	if neutral == null or neutral.resource_path != skin.visual_scene_path:
		_fail("the neutral arena does not play on %s" % DEFAULT_SKIN_ID)


## A save that owned or equipped any retired arena keeps working: SIMULATION is all that is left.
func _check_saves() -> void:
	var test_root: String = "user://test_runs/endless_catalog_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_root)
	var save_path: String = test_root + "/save.json"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"schema_version": SaveManagerService.SCHEMA_VERSION,
		"owned_arena_skins": RETIRED_IDS,
		"equipped_arena_skin": "board_01",
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
	if manager.equip_cosmetic(SaveManagerService.KIND_ARENA_SKIN, &"quarry_titan"):
		_fail("equip accepted a retired arena")
	manager.queue_free()


func _fail(message: String) -> void:
	_failures += 1
	push_error("endless_catalog: %s" % message)
