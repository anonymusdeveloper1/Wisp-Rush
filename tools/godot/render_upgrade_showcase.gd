extends SceneTree
## Visual-QA fixture that slides up a deterministic three-card upgrade tray over a live arena, with
## two level-ups banked (UPGRADE READY ×2).
##
## Usage:
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 540x960 --write-movie logs/frames/frame.png \
##     --quit-after 60 --script res://tools/godot/render_upgrade_showcase.gd

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 715
	# Capture windows can lose focus; the fixture must not open the pause menu over the tray.
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await process_frame
	await process_frame
	game.debug_quiet_arena()
	for kind: StringName in [&"soul_wisp", &"shard_wraith", &"soul_wisp"]:
		var uv := Vector2(game._random.randf_range(0.2, 0.8), game._random.randf_range(0.2, 0.55))
		game.spawn_scripted_enemy(kind, uv)
	game._run_progression.add_experience(game._run_progression.get_xp_threshold())
	game._run_progression.add_experience(roundi(game._run_progression.get_xp_threshold() * 1.32))
	game._open_upgrade_tray()
