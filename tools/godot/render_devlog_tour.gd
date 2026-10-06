extends SceneTree
## Devlog footage: drives the real game (Main) through a scripted tour while MovieWriter records it.
##
## Usage (repo root; a real window, not headless):
##   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 \
##     --write-movie "$PWD/video/footage/tour_menus.avi" \
##     --script res://tools/godot/render_devlog_tour.gd -- tour=menus
## Tours:
##   menus — boot loading screen → Home → Shop CHARACTERS, then its SHOP page → Home →
##           PLAY → run loading screen → an Endless run on SIMULATION played by the bot.
## Options: tour=menus
##   rift_points=<balance, default 4200>  run_seconds=<Endless play time, default 14>
##   quality=<MJPEG quality 0-1, default 0.9>  plus devlog_bot.gd options (hold, redirects, survive…)
## Uses its own isolated save (user://test_runs/devlog_tour*.json), reset at start. Navigation runs
## through Main's real handlers, so the cover-then-build veil, glides and loading screens are the
## ones players see. The event log next to the movie marks each tour step (`step`) and bot events.

const DevlogBot = preload("res://tools/godot/devlog_bot.gd")
const Clip = preload("res://tools/godot/render_gameplay_clip.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
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
	save_manager.add_rift_points(DevlogBot.option_int(_options, "rift_points", 4200))


func _tour_menus() -> void:
	var home := _current() as HomeScreen
	await _hold(1.6)

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
	_step(&"shop_deals")
	shop._on_tab_pressed(ShopScreen.TAB_SHOP)
	await _hold(1.6)
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
