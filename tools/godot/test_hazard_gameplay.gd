extends SceneTree
## Live-scene check that a warned split crystal truncates a real player dash without damage.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = 0
	var impacts: Array[Vector2] = []
	var wall_impacts: Array[Vector2] = []
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = true
	game.run_seed = 713
	root.add_child(game)
	await create_timer(0.8).timeout

	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	player.obstacle_impacted.connect(
		func(position: Vector2, _normal: Vector2, _dash_id: int) -> void: impacts.append(position)
	)
	player.wall_impacted.connect(
		func(position: Vector2, _normal: Vector2, _dash_id: int) -> void: wall_impacts.append(position)
	)
	game._spawn_hazard(&"split_crystal", game._arena_rect.get_center())
	await create_timer(0.75).timeout
	player.request_dash(Vector2.UP)
	await create_timer(0.45).timeout

	if impacts.size() != 1 or not wall_impacts.is_empty():
		failures += 1
		push_error("hazard_gameplay: crystal did not exclusively resolve the dash")
	elif impacts[0].y <= game._arena_rect.get_center().y:
		failures += 1
		push_error("hazard_gameplay: dash crossed the crystal before impact")
	if player.get_current_health() != player.get_maximum_health():
		failures += 1
		push_error("hazard_gameplay: blocking crystal incorrectly dealt damage")
	if failures == 0:
		print("hazard_gameplay: active split crystal truncated a live dash")
	game.queue_free()
	quit(failures)
