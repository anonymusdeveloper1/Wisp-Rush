extends Node
## Visual-QA fixture: one character in the production GameWorld, slowed during a diagonal dash.
##
## Usage (WISP_CHARACTER picks the form, default veyra):
##   WISP_CHARACTER=morrow tools/screenshot.sh \
##     res://tools/godot/render_character_gameplay_showcase.tscn 120 540x960

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _ready() -> void:
	var form_id := StringName(OS.get_environment("WISP_CHARACTER"))
	if form_id.is_empty():
		form_id = &"veyra"
	var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(ENDLESS_CATALOG.default_skin_id)
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 717
	game.auto_pause_on_focus_loss = false
	game.configure_run(RunProfile.tutorial(ENDLESS_CATALOG, skin, FORM_CATALOG.get_form(form_id)))
	add_child(game)
	for _frame: int in 48:
		await get_tree().process_frame
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	if player != null:
		Engine.time_scale = 0.18
		player.request_dash(Vector2(-0.26, -1.0).normalized())


func _exit_tree() -> void:
	Engine.time_scale = 1.0
