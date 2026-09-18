extends Control
## Visual-QA fixture: the production Home screen with one character equipped.
##
## Usage (WISP_CHARACTER picks the form, default veyra):
##   WISP_CHARACTER=rook tools/screenshot.sh \
##     res://tools/godot/render_character_home_showcase.tscn 90 540x960

const HOME_SCENE: PackedScene = preload("res://scenes/screens/home_screen.tscn")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _ready() -> void:
	var form_id := StringName(OS.get_environment("WISP_CHARACTER"))
	if form_id.is_empty():
		form_id = &"veyra"
	var home := HOME_SCENE.instantiate() as HomeScreen
	home.setup({
		&"rift_points": 1250,
		&"ads_removed": false,
		&"settings": {&"reduced_motion": false},
	}, FORM_CATALOG.get_form(form_id))
	add_child(home)
