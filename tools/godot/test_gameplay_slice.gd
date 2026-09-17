extends SceneTree
## Live-scene check that launches through the training line and verifies kills, combo and landing.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 1
	root.add_child(game)
	await create_timer(0.9).timeout
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	player.request_dash(Vector2(-0.3, -1.0))
	await create_timer(1.0).timeout

	var failures: int = 0
	if game.get_score() <= 0:
		failures += 1
		push_error("gameplay_slice: expected the first dash to score")
	if game.get_combo() < 2:
		failures += 1
		push_error("gameplay_slice: expected a multi-kill combo")
	if player.state != WispPlayer.State.WAITING_AT_EDGE:
		failures += 1
		push_error("gameplay_slice: player did not settle at an edge")
	var upgrade_tray := game.get_node("HUD/UpgradeTray") as UpgradeTray
	if upgrade_tray.is_open():
		upgrade_tray.choose_index(0)
		await process_frame
	var pause_button := game.get_node("HUD/SafeHud/PauseButton") as Button
	var resume_button := game.get_node(
		"HUD/PauseOverlay/Center/Panel/Margin/Choices/ResumeButton"
	) as Button
	pause_button.pressed.emit()
	if not paused:
		failures += 1
		push_error("gameplay_slice: Pause button did not pause the tree")
	resume_button.pressed.emit()
	if paused:
		failures += 1
		push_error("gameplay_slice: Resume button did not resume the tree")
	if failures == 0:
		print("gameplay_slice: passed | score=%d combo=%d" % [game.get_score(), game.get_combo()])
	game.queue_free()
	quit(failures)
