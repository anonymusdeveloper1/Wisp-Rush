extends SceneTree
## Live-scene check for Home, pause, results and fast restart (tutorial marked completed first).

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = 0
	# Main resolves /root/SaveManager, so drive the real autoload with isolated test paths.
	var save_manager := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager == null:
		push_error("game_flow: SaveManager autoload is missing")
		quit(1)
		return
	var test_save := "user://wisp_rush_game_flow_test.json"
	var test_temp := "user://wisp_rush_game_flow_test.tmp.json"
	var test_backup := "user://wisp_rush_game_flow_test.backup.json"
	save_manager.configure_storage_paths(test_save, test_temp, test_backup)
	save_manager.reload()
	save_manager.reset_save()
	# First launch opens the Tutorial screen; this check starts from Home.
	save_manager.mark_tutorial_completed()
	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	# Main boots through the Loading screen; wait until Home is shown.
	for _frame: int in 600:
		if main.get_child_count() > 0 and main.get_child(0) is HomeScreen:
			break
		await process_frame
	var home := main.get_child(0) as HomeScreen
	if home == null:
		failures += 1
		push_error("game_flow: main did not open Home")
	else:
		home.play_requested.emit()
	await process_frame
	var game := main.get_child(0) as GameWorld
	if game == null:
		failures += 1
		push_error("game_flow: Play did not open GameWorld")
	else:
		var pause_button := game.get_node("HUD/SafeHud/PauseButton") as Button
		var home_button := game.get_node(
			"HUD/PauseOverlay/Center/Panel/Margin/Choices/HomeButton"
		) as Button
		pause_button.pressed.emit()
		home_button.pressed.emit()
		await process_frame
		if main.get_child_count() != 1 or not main.get_child(0) is HomeScreen:
			failures += 1
			push_error("game_flow: paused Home action did not restore one Home screen")
	var second_home := main.get_child(0) as HomeScreen
	if second_home != null:
		second_home.play_requested.emit()
	await process_frame
	var second_game := main.get_child(0) as GameWorld
	if second_game == null:
		failures += 1
		push_error("game_flow: second Play did not open GameWorld")
	else:
		second_game.run_ended.emit({&"score": 345, &"kills": 7, &"highest_combo": 4, &"wave": 1})
	await process_frame
	var results := main.get_child(0) as ResultsScreen
	if results == null:
		failures += 1
		push_error("game_flow: run end did not open Results")
	else:
		var score_label := results.get_node(
			"SafeMargin/Center/Panel/Margin/Content/ScoreValue"
		) as Label
		if score_label.text != "000345":
			failures += 1
			push_error("game_flow: Results did not display run score")
		var restart_button := results.get_node(
			"SafeMargin/Center/Panel/Margin/Content/RestartButton"
		) as Button
		restart_button.pressed.emit()
	await process_frame
	var restarted_game := main.get_child(0) as GameWorld
	if restarted_game == null:
		failures += 1
		push_error("game_flow: restart did not open a fresh run")
	if failures == 0:
		print("game_flow: Home → Pause/Home → Results → Restart passed")
	main.queue_free()
	await process_frame
	# Detach first so the autoload's exit-save lands in the test file, then delete the test files.
	root.remove_child(save_manager)
	for path: String in [test_save, test_temp, test_backup]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_manager.free()
	quit(failures)
