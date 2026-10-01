extends SceneTree
## Visual-QA fixture: a Wisp dashing into an arena wall, captured while the wall splash plays.
##
## Usage (optional arena skin id after `--`, default the Endless default skin):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 540x960 --write-movie logs/frames/frame.png \
##     --quit-after 72 --script res://tools/godot/render_wall_splash_showcase.gd
## MovieWriter runs at a fixed 60 FPS; the impact lands around frame 60.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const ENDLESS: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const FORMS: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var skin_id: StringName = ENDLESS.default_skin_id
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if not user_args.is_empty():
		skin_id = StringName(user_args[0])
	var no_rosters: Array[EndlessRoster] = []
	var reaper_only: Array[StringName] = [&"reaper"]
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 91
	game.auto_pause_on_focus_loss = false
	game.configure_run(RunProfile.endless(
		ENDLESS, ENDLESS.get_skin(skin_id), no_rosters, reaper_only,
		FORMS.get_form(FormCatalog.DEFAULT_FORM_ID)
	))
	root.add_child(game)
	for _frame: int in 30:
		await process_frame
	# Empty arena so the splash reads clearly.
	game.debug_quiet_arena()
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	for _frame: int in 12:
		await process_frame
	player.request_dash(Vector2(0.55, -1.0))
