extends SceneTree
## Verifies Milestone 4 systems: settings persistence and screen, statistics rows, VFX pooling,
## shake/reduced motion, lifecycle auto-pause, back handling, restart confirmation and cleanup.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/screens/settings_screen.tscn")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var save_manager := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager == null:
		push_error("m4_systems: SaveManager autoload is missing")
		quit(1)
		return
	var test_paths: Array[String] = [
		"user://wisp_rush_m4_test.json",
		"user://wisp_rush_m4_test.tmp.json",
		"user://wisp_rush_m4_test.backup.json",
	]
	save_manager.configure_storage_paths(test_paths[0], test_paths[1], test_paths[2])
	save_manager.reload()
	save_manager.reset_save()

	# Settings API: validation, persistence, signal and tutorial replay.
	var emitted: Array[Dictionary] = []
	save_manager.settings_changed.connect(
		func(settings: Dictionary) -> void: emitted.append(settings)
	)
	save_manager.update_settings({&"music_volume": 2.0, &"reduced_motion": true, &"screen_shake": 0.5})
	var stored: Dictionary = save_manager.reload()[&"settings"] as Dictionary
	if (
		not is_equal_approx(float(stored[&"music_volume"]), 1.0)
		or not bool(stored[&"reduced_motion"])
		or not is_equal_approx(float(stored[&"screen_shake"]), 0.5)
		or emitted.is_empty()
	):
		failures += 1
		push_error("m4_systems: settings were not clamped, persisted and announced")
	save_manager.mark_tutorial_completed()
	if not bool(save_manager.get_snapshot()[&"tutorial_completed"]):
		failures += 1
		push_error("m4_systems: tutorial completion was not persisted")

	# Settings screen: reset starts disarmed, back closes the panel, slider saves are debounced.
	var settings_screen := SETTINGS_SCENE.instantiate() as SettingsScreen
	root.add_child(settings_screen)
	await process_frame
	(settings_screen.get_node("%ResetButton") as Button).pressed.emit()
	if not (settings_screen.get_node("%ResetConfirmButton") as Button).disabled:
		failures += 1
		push_error("m4_systems: progress reset was armed immediately")
	if not settings_screen.handle_back():
		failures += 1
		push_error("m4_systems: back did not close the reset panel first")
	(settings_screen.get_node("%SfxSlider") as HSlider).value = 0.25
	await create_timer(0.7).timeout
	if not is_equal_approx(float(save_manager.get_settings()[&"sfx_volume"]), 0.25):
		failures += 1
		push_error("m4_systems: slider change was not saved after the debounce")
	settings_screen.queue_free()
	await process_frame

	# Statistics rows.
	var rows: Array[PackedStringArray] = StatisticsScreen.build_rows({
		&"best_score": 1200,
		&"play_time_seconds": 3725.0,
		&"owned_forms": ["void", "ash"],
	})
	if rows[0][1] != "001200" or rows[7][1] != "1h 02m" or rows[9][1] != "2 / 6":
		failures += 1
		push_error("m4_systems: statistics rows are wrong: %s" % [rows])

	# VFX pool recycles instead of growing.
	var pool := VfxPool.new()
	root.add_child(pool)
	await process_frame
	var texture := PlaceholderTexture2D.new()
	for index: int in VfxPool.POOL_SIZE + 5:
		pool.play(texture, Vector2(float(index), 0.0))
	if pool.get_child_count() != VfxPool.POOL_SIZE or pool.get_active_count() != VfxPool.POOL_SIZE:
		failures += 1
		push_error("m4_systems: VFX pool grew or lost effects")
	pool.queue_free()

	# GameWorld: shake settings, lifecycle pause, back handling and restart confirmation.
	save_manager.update_settings({&"reduced_motion": false, &"screen_shake": 0.0})
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 4242
	root.add_child(game)
	await process_frame
	game.add_trauma(1.0)
	if game.get_trauma() != 0.0:
		failures += 1
		push_error("m4_systems: shake strength 0 still accumulated trauma")
	save_manager.update_settings({&"screen_shake": 1.0, &"reduced_motion": true})
	if not is_equal_approx(game.get_shake_strength(), GameWorld.REDUCED_MOTION_SHAKE):
		failures += 1
		push_error("m4_systems: reduced motion did not scale shake")
	game.add_trauma(0.5)
	await process_frame
	if root.canvas_transform.origin == Vector2.ZERO:
		failures += 1
		push_error("m4_systems: trauma produced no view offset")
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if not paused or not (game.get_node("%PauseOverlay") as Control).visible:
		failures += 1
		push_error("m4_systems: focus loss did not open the pause overlay")
	game.handle_back()
	if paused:
		failures += 1
		push_error("m4_systems: back did not resume the paused run")
	game._score = 50
	game.handle_back()
	(game.get_node("%RestartButton") as Button).pressed.emit()
	if not (game.get_node("%ConfirmOverlay") as Control).visible:
		failures += 1
		push_error("m4_systems: restart of a meaningful run skipped confirmation")
	var restart_seen: Array[bool] = [false]
	game.restart_requested.connect(func() -> void: restart_seen[0] = true)
	(game.get_node("%ConfirmYesButton") as Button).pressed.emit()
	if not restart_seen[0] or paused:
		failures += 1
		push_error("m4_systems: confirmed restart did not resume and request a new run")
	game.queue_free()
	await process_frame
	if root.canvas_transform.origin != Vector2.ZERO or not is_equal_approx(Engine.time_scale, 1.0):
		failures += 1
		push_error("m4_systems: shake offset or hit-stop leaked past GameWorld")

	if not DebugOverlay.build_report(self).begins_with("FPS"):
		failures += 1
		push_error("m4_systems: debug overlay report is malformed")

	if failures == 0:
		print("m4_systems: settings, statistics, VFX pool, feel, lifecycle and confirmations passed")
	root.remove_child(save_manager)
	for path: String in test_paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_manager.free()
	quit(failures)
