extends SceneTree
## Live-scene check for the integrated dash, single-target and three-target lessons.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = 0
	var completion_count: Array[int] = [0]
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = true
	game.tutorial_completed.connect(func() -> void: completion_count[0] += 1)
	root.add_child(game)
	await create_timer(0.55).timeout
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	player.request_dash(Vector2.UP)
	await create_timer(1.2).timeout
	player.request_dash(Vector2.DOWN)
	await create_timer(1.2).timeout
	player.request_dash(Vector2.UP)
	await create_timer(0.9).timeout
	if not game.is_tutorial_complete() or completion_count[0] != 1:
		failures += 1
		push_error("tutorial_flow: expected all three lessons to complete once")
	if game.get_total_kills() < 4 or game.get_highest_combo() < 3:
		failures += 1
		push_error("tutorial_flow: tutorial targets did not produce the expected chain")
	if failures == 0:
		print("tutorial_flow: wall dash → single slice → triple reap passed")
	game.queue_free()
	quit(failures)
