extends SceneTree
## Visual-QA fixture: a Wisp dashing into a Rift wall, captured while the wall splash plays.
##
## Usage (optional rift id after `--`, default ember_hollow):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 540x960 --write-movie logs/frames/frame.png \
##     --quit-after 72 --script res://tools/godot/render_wall_splash_showcase.gd -- frozen_choir
## MovieWriter runs at a fixed 60 FPS; the impact lands around frame 60.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORMS: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var rift_id: StringName = &"ember_hollow"
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if not user_args.is_empty():
		rift_id = StringName(user_args[0])
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = false
	game.run_seed = 91
	game.auto_pause_on_focus_loss = false
	game.configure_run_profile(FORMS.get_form(&"void"), "", RIFTS.get_rift(rift_id), 1)
	root.add_child(game)
	for _frame: int in 30:
		await process_frame
	# Empty arena so the splash reads clearly.
	game.debug_quiet_arena()
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	for _frame: int in 12:
		await process_frame
	player.request_dash(Vector2(0.55, -1.0))
