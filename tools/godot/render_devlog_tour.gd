extends SceneTree
## Devlog footage: drives the real game (Main) through a scripted tour while MovieWriter records it.
##
## Usage (repo root; a real window, not headless):
##   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 \
##     --write-movie "$PWD/video/footage/tour_menus.avi" \
##     --script res://tools/godot/render_devlog_tour.gd -- tour=menus
## Tours:
##   menus — boot loading screen → Home → Rift Map cards → Shop WISPS/DASHES/ARENAS (to the Mythic
##           cards) → Home → PLAY → run loading screen → an Endless run on `skin` played by the bot.
##   story — boot → Home → Rift Map (Obsidian Garden, then the locked Shattered Rift) → ENTER →
##           the level-1 run until the boss falls → Results (CLEARED, SHATTERED RIFT OPEN) →
##           ENTER SHATTERED RIFT → its loading screen and the first seconds of that run.
## Options: tour=menus|story  skin=<arena skin to own and equip, default aurora_throne>
##   rift_points=<balance, default 4200>  run_seconds=<Endless play time, default 14>
##   story_cap=<max movie seconds for the story run, default 150>  next_seconds=<default 8>
##   quality=<MJPEG quality 0-1, default 0.9>  plus devlog_bot.gd options (hold, redirects, survive…)
## Uses its own isolated save (user://test_runs/devlog_tour*.json), reset at start. Navigation runs
## through Main's real handlers, so the cover-then-build veil, glides and loading screens are the
## ones players see. The event log next to the movie marks each tour step (`step`) and bot events.

const DevlogBot = preload("res://tools/godot/devlog_bot.gd")
const Clip = preload("res://tools/godot/render_gameplay_clip.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const FPS: float = 60.0
const SAVE_PATH: String = "user://test_runs/devlog_tour.json"
const TEMP_PATH: String = "user://test_runs/devlog_tour.tmp.json"
const BACKUP_PATH: String = "user://test_runs/devlog_tour.backup.json"
## Movie seconds to wait at most for a screen to become current.
const SCREEN_TIMEOUT: float = 20.0

var _options: Dictionary = {}
var _main: Node
var _bot: DevlogBot
var _bot_game: GameWorld
var _events: FileAccess
var _aborted: bool = false


func _init() -> void:
	_options = DevlogBot.parse_options(OS.get_cmdline_user_args())
	ProjectSettings.set_setting(
		"editor/movie_writer/mjpeg_quality",
		clampf(DevlogBot.option_float(_options, "quality", 0.9), 0.1, 1.0),
	)
	call_deferred(&"_run")


func _run() -> void:
	_events = Clip.open_event_log(str(_options.get("events", "")))
	var save_manager := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager == null:
		push_error("render_devlog_tour: SaveManager autoload is missing")
		quit(1)
		return
	_prepare_save(save_manager)

	_main = MAIN_SCENE.instantiate()
	_main.child_entered_tree.connect(_on_main_child_entered)
	root.add_child(_main)
	_step(&"boot")
	var awaited_1: Node = await _wait_for(HomeScreen)
	if awaited_1 == null:
		_abort("Main never showed Home")
		return

	match str(_options.get("tour", "menus")):
		"story":
			await _tour_story()
		_:
			await _tour_menus()

	_step(&"end")
	if _events != null:
		_events.close()
	Engine.time_scale = 1.0
	quit(1 if _aborted else 0)


func _prepare_save(save_manager: SaveManagerService) -> void:
	save_manager.configure_storage_paths(SAVE_PATH, TEMP_PATH, BACKUP_PATH)
	save_manager.reload()
	save_manager.reset_save()
	save_manager.mark_tutorial_completed()
	var skin_id := StringName(str(_options.get("skin", "aurora_throne")))
	var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(skin_id)
	if skin != null and skin.skin_id == skin_id:
		# Grant exactly the price, so the purchase leaves a zero balance before the shown one.
		save_manager.add_rift_points(skin.price)
		save_manager.purchase_cosmetic(SaveManagerService.KIND_ARENA_SKIN, skin_id, skin.price, true)
		save_manager.equip_cosmetic(SaveManagerService.KIND_ARENA_SKIN, skin_id)
	save_manager.add_rift_points(DevlogBot.option_int(_options, "rift_points", 4200))


func _tour_menus() -> void:
	var home := _current() as HomeScreen
	await _hold(1.6)

	_step(&"rift_map")
	home.rift_map_requested.emit()
	var rift_map := await _wait_for(RiftMapScreen) as RiftMapScreen
	if rift_map == null:
		_abort("Rift Map did not open")
		return
	await _hold(1.2)
	for index: int in [1, 2, 0]:
		rift_map._carousel.select(index, true)
		await _hold(1.0)
	rift_map.back_requested.emit()
	await _wait_for(HomeScreen)
	await _hold(1.0)

	_step(&"shop")
	home.shop_requested.emit()
	var shop := await _wait_for(ShopScreen) as ShopScreen
	if shop == null:
		_abort("Shop did not open")
		return
	await _hold(1.2)
	for index: int in [1, 2]:
		shop._carousel.select(index, true)
		await _hold(0.8)
	_step(&"shop_dashes")
	shop._on_tab_pressed(ShopScreen.TAB_DASHES)
	await _hold(1.0)
	for index: int in [1, 2, 3]:
		shop._carousel.select(index, true)
		await _hold(0.7)
	_step(&"shop_arenas")
	shop._on_tab_pressed(ShopScreen.TAB_ARENAS)
	await _hold(1.2)
	for index: int in [1, 2, 3, 4, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]:
		shop._carousel.select(index, true)
		await _hold(0.45)
	_step(&"shop_mythic")
	for index: int in [24, 25, 26, 27, 28, 29]:
		shop._carousel.select(index, true)
		await _hold(1.3)
	shop.back_requested.emit()
	await _wait_for(HomeScreen)
	await _hold(0.9)

	_step(&"play")
	home.play_requested.emit()
	var awaited_2: Node = await _wait_for(LoadingScreen, false)
	if awaited_2 == null:
		_abort("PLAY did not open the run loading screen")
		return
	_step(&"run_loading")
	var game := await _wait_for(GameWorld) as GameWorld
	if game == null:
		_abort("the Endless run never started")
		return
	_step(&"run")
	await _hold(DevlogBot.option_float(_options, "run_seconds", 14.0))


func _tour_story() -> void:
	var home := _current() as HomeScreen
	await _hold(1.0)

	_step(&"rift_map")
	home.rift_map_requested.emit()
	var rift_map := await _wait_for(RiftMapScreen) as RiftMapScreen
	if rift_map == null:
		_abort("Rift Map did not open")
		return
	await _hold(1.4)
	_step(&"rift_locked")
	rift_map._carousel.select(1, true)
	await _hold(1.8)
	rift_map._carousel.select(0, true)
	await _hold(1.1)

	_step(&"enter")
	rift_map._on_enter_pressed()
	var awaited_3: Node = await _wait_for(LoadingScreen, false)
	if awaited_3 == null:
		_abort("ENTER did not open the run loading screen")
		return
	var game := await _wait_for(GameWorld) as GameWorld
	if game == null:
		_abort("the story run never started")
		return
	_step(&"story_run")
	var cap: float = DevlogBot.option_float(_options, "story_cap", 150.0)
	var started: float = _now()
	while not (_current() is ResultsScreen):
		if _now() - started > cap:
			_abort("the story run did not end within %.0f s" % cap)
			return
		await _frame()

	_step(&"results")
	var results := _current() as ResultsScreen
	await _hold(6.5)
	_step(&"enter_next")
	results._on_primary_pressed()
	var awaited_4: Node = await _wait_for(LoadingScreen, false)
	if awaited_4 == null:
		_abort("the Results primary action did not open a run loading screen")
		return
	var awaited_5: Node = await _wait_for(GameWorld)
	if awaited_5 == null:
		_abort("the next Rift never started")
		return
	_step(&"next_run")
	await _hold(DevlogBot.option_float(_options, "next_seconds", 8.0))


## The current screen: Main's first regular child.
func _current() -> Node:
	return _main.get_child(0) if _main.get_child_count() > 0 else null


## Waits until a [param type] screen is current (and, with [param settled], Main has finished
## navigating); null on timeout. The run loading screen never settles: Main hands over to the
## prewarmed run while still navigating, so wait for it unsettled.
func _wait_for(type: Variant, settled: bool = true) -> Node:
	var started: float = _now()
	while _now() - started < SCREEN_TIMEOUT and not _aborted:
		var screen: Node = _current()
		if is_instance_of(screen, type) and not (settled and bool(_main.call(&"is_navigating"))):
			return screen
		await _frame()
	return null


func _hold(seconds: float) -> void:
	var until: float = _now() + seconds
	while _now() < until:
		await _frame()


## One movie frame; plays the current run with the bot when one is live.
func _frame() -> void:
	await process_frame
	var game := _current() as GameWorld
	if game == null or bool(_main.call(&"is_navigating")):
		return
	if game != _bot_game:
		_bot_game = game
		_bot = DevlogBot.new(game, _options, FPS, int(_now() * 1000.0))
		_bot.event_logged.connect(_log)
	_bot.step(_now())


func _on_main_child_entered(node: Node) -> void:
	var game := node as GameWorld
	if game != null:
		# The capture window may lose focus; a focus-loss pause would put the pause menu on film.
		game.auto_pause_on_focus_loss = false


func _step(step_name: StringName) -> void:
	print("[tour] %.2f %s" % [_now(), step_name])
	_log(&"step", {"name": step_name})


func _log(event: StringName, fields: Dictionary = {}) -> void:
	if _events != null and _events.is_open():
		Clip.write_event(_events, event, fields, _now(), 0.0)


func _now() -> float:
	return Clip.movie_seconds(FPS)


func _abort(reason: String) -> void:
	push_error("render_devlog_tour: " + reason)
	_log(&"abort", {"reason": reason})
	_aborted = true
