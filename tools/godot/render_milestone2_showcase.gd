extends SceneTree
## Visual-QA fixture that composes the Milestone 2 roster in the production arena.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = true
	game.run_seed = 714
	# --write-movie windows lose focus; keep the roster animating instead of auto-pausing.
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await process_frame
	await process_frame
	game._tutorial_overlay.visible = false
	game._wave_label.text = "RIFT 05  •  FIELD GUIDE"
	game._instruction_label.text = "THREE SOULS  •  THREE HAZARDS"
	game._instruction_label.visible = true
	game._instruction_label.modulate.a = 1.0

	var enemy_points: Array[Vector2] = [
		Vector2(270.0, 540.0),
		Vector2(540.0, 700.0),
		Vector2(810.0, 540.0),
	]
	var enemy_kinds: Array[StringName] = [&"soul_wisp", &"shard_wraith", &"bone_mote"]
	for index: int in enemy_kinds.size():
		var enemy: EnemyActor = game._spawn_enemy(enemy_kinds[index], enemy_points[index], false)
		enemy.state = EnemyActor.State.ACTIVE
		enemy._arrival_ring.visible = false
		enemy._sprite.modulate = Color.WHITE

	var hazard_points: Array[Vector2] = [
		Vector2(270.0, 1120.0),
		Vector2(540.0, 1280.0),
		Vector2(810.0, 1120.0),
	]
	var hazard_kinds: Array[StringName] = [&"split_crystal", &"spike_bloom", &"blade_ring"]
	for index: int in hazard_kinds.size():
		var hazard: HazardActor = game._spawn_hazard(hazard_kinds[index], hazard_points[index])
		hazard.state = HazardActor.State.ACTIVE
		hazard._warning.visible = false
		hazard._sprite.modulate = Color.WHITE
		hazard._on_became_active()
