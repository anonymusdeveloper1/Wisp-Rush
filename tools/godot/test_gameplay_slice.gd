extends SceneTree
## Live-scene check that launches through a scripted target line and verifies kills, combo and landing.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 1
	var profile := RunProfile.new()
	profile.mode = RunProfile.MODE_TUTORIAL
	game.configure_run(profile)
	root.add_child(game)
	await process_frame
	for y: float in [0.3, 0.5, 0.7]:
		game.spawn_scripted_enemy(&"hooded_scribe", Vector2(0.5, y))
	await create_timer(0.9).timeout
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	player.request_dash(Vector2.UP)
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
	game._scripted = false
	# The one arena is a board with its own pause button (ADR-0024, ADR-0027).
	var board := game.get_node("ArenaVisual") as ArenaVisual
	var resume_button := game.get_node(
		"HUD/PauseOverlay/Center/Panel/Margin/Choices/ResumeButton"
	) as Button
	board.hud_pause_pressed.emit()
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
