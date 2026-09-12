extends SceneTree
## Visual-QA fixture that starts the Reaper encounter in the production arena.
##
## Usage (renders frames; inspect a mid-intro and a later phase frame):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 540x960 --write-movie logs/frames/frame.png \
##     --quit-after 300 --script res://tools/godot/render_reaper_showcase.gd

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = false
	game.run_seed = 714
	# --write-movie windows lose focus; keep the fight running instead of auto-pausing.
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await process_frame
	await process_frame
	game._wave_director.suspend_for_boss()
	game._start_boss_encounter()
