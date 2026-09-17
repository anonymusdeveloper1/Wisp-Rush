extends SceneTree
## Live check of Main's cover-then-build screen changes, the kept Home and the run prewarm.
##
## Headless runs switch screens instantly by default, so this test turns transitions on and asserts:
## a request never builds at once (the veil covers first, the old screen stays current); the new
## screen then becomes `get_child(0)`, glides in from the right (from the left returning Home) and
## settles; the old screen is freed, or only detached for Home; Home is one instance across visits;
## a second request while covering wins (the first screen is never built); PLAY builds the run held
## and frozen beneath the run loading screen (moved onto a CanvasLayer above the run's HUD), then
## reveals it running; and a
## run being left is freed.

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
## Frames to wait for a change to settle; generous for slow CI machines.
const SETTLE_FRAMES: int = 600

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var save_manager := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager == null:
		push_error("screen_transitions: SaveManager autoload is missing")
		quit(1)
		return
	var test_save := "user://wisp_rush_transitions_test.json"
	var test_temp := "user://wisp_rush_transitions_test.tmp.json"
	var test_backup := "user://wisp_rush_transitions_test.backup.json"
	save_manager.configure_storage_paths(test_save, test_temp, test_backup)
	save_manager.reload()
	save_manager.reset_save()
	save_manager.mark_tutorial_completed()

	var main: Node = MAIN_SCENE.instantiate()
	main.set(&"transitions_enabled", true)
	root.add_child(main)
	for _frame: int in SETTLE_FRAMES:
		if main.get_child_count() > 0 and main.get_child(0) is HomeScreen:
			break
		await process_frame
	await _settle(main)
	var home := main.get_child(0) as HomeScreen
	if home == null:
		_fail("Main did not open Home")
		await _finish(main, save_manager, [test_save, test_temp, test_backup])
		return

	await _check_forward_and_back(main, home)
	if not is_instance_valid(home) or main.get_child(0) != home:
		_fail("Home was not kept across visits; skipping the remaining checks")
		await _finish(main, save_manager, [test_save, test_temp, test_backup])
		return
	await _check_latest_request_wins(main, home)
	await _check_run_prewarm(main, home)

	if _failures == 0:
		print("screen_transitions: cover-then-build, kept Home, latest request, run prewarm OK")
	await _finish(main, save_manager, [test_save, test_temp, test_backup])


func _check_forward_and_back(main: Node, home: HomeScreen) -> void:
	home.trials_requested.emit()
	await process_frame
	if main.get_child(0) != home:
		_fail("Trials was built at the request instead of under the cover")
	if not bool(main.call(&"is_navigating")):
		_fail("Main should report a pending change while the veil covers")
	var trials: TrialsScreen = await _wait_for_screen(main, &"TrialsScreen") as TrialsScreen
	if trials == null:
		_fail("Trials did not become the current screen")
		return
	if main.get_child_count() != 1:
		_fail("only the current screen may be a regular child")
	if home.get_parent() != null:
		_fail("Home should be detached (kept) once Trials is built under the cover")
	if trials.position.x <= 0.0:
		_fail("Trials should glide in from the right, got x=%.1f" % trials.position.x)
	await _settle(main)
	if not is_instance_valid(home):
		_fail("Home was freed; Main must keep one instance")
		return
	if not is_zero_approx(trials.position.x):
		_fail("Trials did not settle at its rest position")

	trials.back_requested.emit()
	var back_home: Node = await _wait_for_screen(main, &"HomeScreen")
	if back_home != home:
		_fail("Back did not re-show the same Home instance")
	elif home.position.x >= 0.0:
		_fail("returning Home should glide in from the left, got x=%.1f" % home.position.x)
	await _settle(main)
	if is_instance_valid(trials):
		_fail("Trials was not freed after the change back Home")
	if not is_zero_approx(home.position.x):
		_fail("Home did not return to its rest position, x=%.1f" % home.position.x)


## A second request while the veil is still covering wins; the first screen is never built.
func _check_latest_request_wins(main: Node, home: HomeScreen) -> void:
	home.daily_requested.emit()
	await process_frame
	home.statistics_requested.emit()
	var built_daily: bool = false
	for _frame: int in SETTLE_FRAMES:
		await process_frame
		if main.get_child(0) is DailyScreen:
			built_daily = true
		if not bool(main.call(&"is_navigating")):
			break
	if built_daily:
		_fail("the superseded Daily request was still built")
	var statistics := main.get_child(0) as StatisticsScreen
	if statistics == null:
		_fail("the latest request (Statistics) did not win")
		return
	await _settle(main)
	if main.get_child_count(true) != 3:
		_fail("a change left %d children (expected the screen, the veil and the loading cover)" % main.get_child_count(true))
	statistics.back_requested.emit()
	await _wait_for_screen(main, &"HomeScreen")
	await _settle(main)


## PLAY: the run is built held and frozen beneath the run loading screen, then revealed running.
func _check_run_prewarm(main: Node, home: HomeScreen) -> void:
	home.play_requested.emit()
	var loading: Node = await _wait_for_screen(main, &"LoadingScreen")
	if loading == null:
		_fail("PLAY did not open the run loading screen")
		return
	var game: GameWorld = null
	for _frame: int in SETTLE_FRAMES:
		await process_frame
		game = main.get_child(0) as GameWorld
		if game != null:
			break
	if game == null:
		_fail("the run was not prewarmed beneath the loading screen")
		return
	var hud := game.get_node("HUD") as CanvasLayer
	var cover := loading.get_parent() as CanvasLayer if is_instance_valid(loading) else null
	if cover == null or cover.layer <= hud.layer:
		_fail("the loading screen should stay up on a CanvasLayer above the run's HUD while it warms")
	if game.process_mode != Node.PROCESS_MODE_DISABLED or not game.is_start_held():
		_fail("a prewarming run must be frozen and held")
	await _settle(main)
	if main.get_child(0) != game:
		_fail("the prewarmed run was not the one revealed")
		return
	if is_instance_valid(loading):
		_fail("the run loading screen was not freed after the reveal")
	if game.process_mode != Node.PROCESS_MODE_INHERIT or game.is_start_held():
		_fail("the revealed run did not start")
	if not is_zero_approx(game.position.x):
		_fail("GameWorld must not glide; its arena works in screen space")

	game.home_requested.emit()
	await process_frame
	if main.get_child(0) != game:
		_fail("leaving the run should cover it before Home is shown")
	await _wait_for_screen(main, &"HomeScreen")
	await _settle(main)
	if is_instance_valid(game):
		_fail("the left run was not freed")


## Waits until the current screen (child 0) is a node of `type_name`; returns it or null.
func _wait_for_screen(main: Node, type_name: StringName) -> Node:
	for _frame: int in SETTLE_FRAMES:
		if main.get_child_count() > 0 and main.get_child(0).is_class(type_name):
			return main.get_child(0)
		if main.get_child_count() > 0:
			var script := main.get_child(0).get_script() as Script
			if script != null and script.get_global_name() == type_name:
				return main.get_child(0)
		await process_frame
	return null


func _settle(main: Node) -> void:
	for _frame: int in SETTLE_FRAMES:
		await process_frame
		if not bool(main.call(&"is_navigating")):
			break
	# Two more frames so queue_free on the released screen completes.
	await process_frame
	await process_frame


func _fail(message: String) -> void:
	_failures += 1
	push_error("screen_transitions: %s" % message)


func _finish(main: Node, save_manager: SaveManagerService, paths: Array[String]) -> void:
	main.queue_free()
	await process_frame
	root.remove_child(save_manager)
	for path: String in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_manager.free()
	quit(_failures)
