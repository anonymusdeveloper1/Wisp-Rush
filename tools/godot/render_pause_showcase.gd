extends SceneTree
## Visual-QA fixture: a live run with the pause menu open, optionally with an overlay on top.
##
## Usage (user args after `--`: nothing = pause menu, `confirm` = abandon-run confirmation,
## `settings` = in-run Settings overlay):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 540x960 --write-movie logs/frames/frame.png \
##     --quit-after 30 --script res://tools/godot/render_pause_showcase.gd -- confirm

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = false
	game.run_seed = 714
	root.add_child(game)
	await process_frame
	await process_frame
	game.handle_back()
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if "confirm" in user_args:
		game._score = 120
		game._on_home_button_pressed()
	elif "settings" in user_args:
		game._open_settings_overlay()
