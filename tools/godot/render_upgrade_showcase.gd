extends SceneTree
## Visual-QA fixture that opens a deterministic three-card mutation choice over the arena.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = true
	game.run_seed = 715
	root.add_child(game)
	await process_frame
	await process_frame
	game._tutorial_overlay.visible = false
	game._run_progression.add_experience(game._run_progression.get_xp_threshold())
	game._open_upgrade_selection()
