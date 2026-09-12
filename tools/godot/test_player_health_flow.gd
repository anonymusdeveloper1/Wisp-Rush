extends SceneTree
## Live-scene check for contact, i-frames, safe reform, death dissolve and run summary.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const SOUL_WISP_SCENE: PackedScene = preload("res://scenes/enemies/soul_wisp.tscn")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = 0
	var summaries: Array[Dictionary] = []
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = false
	game.run_ended.connect(func(summary: Dictionary) -> void: summaries.append(summary))
	root.add_child(game)
	await create_timer(0.5).timeout
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	var enemy_layer := game.get_node("WorldContent/EnemyLayer") as Node2D
	for child: Node in enemy_layer.get_children():
		child.queue_free()
	await process_frame
	var enemy := SOUL_WISP_SCENE.instantiate() as SoulWispEnemy
	enemy.movement_enabled = false
	enemy_layer.add_child(enemy)
	enemy.global_position = player.global_position
	enemy.set_viewport_width(root.size.x)
	await create_timer(0.7).timeout
	if player.get_current_health() != 2:
		failures += 1
		push_error("player_health_flow: active enemy contact did not remove one fragment")
	if player.take_contact_damage(player.global_position):
		failures += 1
		push_error("player_health_flow: invulnerability did not reject an immediate second hit")
	await create_timer(1.0).timeout
	if not player.take_contact_damage(player.global_position):
		failures += 1
	await create_timer(1.0).timeout
	if not player.take_contact_damage(player.global_position):
		failures += 1
	await create_timer(0.7).timeout
	if player.get_current_health() != 0 or player.state != WispPlayer.State.DEAD:
		failures += 1
		push_error("player_health_flow: third separated hit did not enter DEAD")
	if summaries.size() != 1:
		failures += 1
		push_error("player_health_flow: death dissolve did not emit one run summary")
	if failures == 0:
		print("player_health_flow: contact → i-frames → death → summary passed")
	game.queue_free()
	quit(failures)
