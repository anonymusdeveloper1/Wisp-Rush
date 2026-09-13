extends SceneTree
## Visual-QA fixture: the Wisp resting on a wall while a swipe is held, showing the direction arrow.
##
## Usage (optional rift id after `--`, default obsidian_garden):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 540x960 --write-movie logs/frames/frame.png \
##     --quit-after 60 --script res://tools/godot/render_aim_arrow_showcase.gd -- ember_hollow

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORMS: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _init() -> void:
	call_deferred(&"_build_showcase")


func _build_showcase() -> void:
	var rift_id: StringName = &"obsidian_garden"
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if not user_args.is_empty():
		rift_id = StringName(user_args[0])
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = false
	game.run_seed = 5
	game.auto_pause_on_focus_loss = false
	game.configure_run_profile(FORMS.get_form(&"void"), "", RIFTS.get_rift(rift_id), 1)
	root.add_child(game)
	for _frame: int in 30:
		await process_frame
	game.debug_quiet_arena()
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	for _frame: int in 6:
		await process_frame
	# Hold a swipe up and to the left without releasing, so the arrow stays up.
	var start := Vector2(540, 1200)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = start
	press.pressed = true
	player._unhandled_input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = start + Vector2(-0.45, -1.0).normalized() * 260.0
	player._unhandled_input(drag)
