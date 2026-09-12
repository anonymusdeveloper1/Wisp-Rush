extends SceneTree
## End-to-end profile check across Home, Forms, Daily, gameplay identity and Results.

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = 0
	# Main resolves /root/SaveManager, so drive the real autoload with isolated test paths.
	var save_manager := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager == null:
		push_error("main_progression_flow: SaveManager autoload is missing")
		quit(1)
		return
	var test_save := "user://wisp_rush_main_progression_test.json"
	var test_temp := "user://wisp_rush_main_progression_test.tmp.json"
	var test_backup := "user://wisp_rush_main_progression_test.backup.json"
	save_manager.configure_storage_paths(test_save, test_temp, test_backup)
	save_manager.reload()
	save_manager.reset_save()
	save_manager.add_soul_shards(500)

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
		push_error("main_progression_flow: Home did not open")
	else:
		home.forms_requested.emit()
	await process_frame
	var forms := main.get_child(0) as FormsScreen
	if forms == null:
		failures += 1
		push_error("main_progression_flow: Forms did not open")
	else:
		forms.select_form(&"ash")
		forms.purchase_requested.emit(&"ash")
		await process_frame
		forms.equip_requested.emit(&"ash")
		await process_frame
		var snapshot: Dictionary = save_manager.get_snapshot()
		if "ash" not in snapshot[&"owned_forms"] or snapshot[&"equipped_form"] != "ash":
			failures += 1
			push_error("main_progression_flow: Ash did not purchase and equip persistently")
		forms.back_requested.emit()
	await process_frame
	home = main.get_child(0) as HomeScreen
	if home != null:
		home.daily_requested.emit()
	await process_frame
	var daily := main.get_child(0) as DailyScreen
	var date_key: String = ChallengeTracker.get_date_key()
	if daily == null:
		failures += 1
		push_error("main_progression_flow: Daily did not open")
	else:
		var daily_play := daily.get_node("Margin/Content/PlayButton") as Button
		daily_play.pressed.emit()
	await process_frame
	var game := main.get_child(0) as GameWorld
	if game == null or game.run_seed != ChallengeTracker.get_daily_seed(date_key):
		failures += 1
		push_error("main_progression_flow: Daily run did not preserve today's seed")
	else:
		var form_sprite := game.get_node_or_null(
			"WorldContent/PlayerLayer/WispPlayer/FormSprite"
		) as Sprite2D
		if form_sprite == null or form_sprite.texture != CATALOG.get_form(&"ash").texture:
			failures += 1
			push_error("main_progression_flow: equipped Ash form was not applied in gameplay")
		game.run_ended.emit({
			&"score": 700,
			&"kills": 2,
			&"highest_combo": 2,
			&"wave": 1,
			&"multi_kill_dashes": 0,
			&"rapid_ricochets": 0,
			&"bosses": 0,
			&"soul_shards": 1,
			&"daily_date": date_key,
			&"is_daily": true,
		})
	await process_frame
	var final_snapshot: Dictionary = save_manager.get_snapshot()
	if date_key not in (final_snapshot[&"daily_state"] as Dictionary)[&"completed_dates"]:
		failures += 1
		push_error("main_progression_flow: daily completion was not persisted")
	if int(final_snapshot[&"best_score"]) != 700:
		failures += 1
		push_error("main_progression_flow: best score was not persisted")
	if not main.get_child(0) is ResultsScreen:
		failures += 1
		push_error("main_progression_flow: completed run did not open Results")
	if failures == 0:
		print("main_progression_flow: forms, daily run and persistent Results passed")

	main.queue_free()
	await process_frame
	# Detach first so the autoload's exit-save lands in the test file, then delete the test files.
	root.remove_child(save_manager)
	for path: String in [test_save, test_temp, test_backup]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_manager.free()
	quit(failures)
