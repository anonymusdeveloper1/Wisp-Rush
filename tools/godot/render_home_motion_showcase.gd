extends SceneTree
## Visual-QA fixture: the Home screen over time, to check the hero float, orbit and living background.
##
## Usage:
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 540x1170 --write-movie logs/frames/frame.png \
##     --quit-after 150 --script res://tools/godot/render_home_motion_showcase.gd
## MovieWriter runs at a fixed 60 FPS; compare frames ~25 apart to see the motion.

const HOME_SCENE: PackedScene = preload("res://scenes/screens/home_screen.tscn")
const FORMS: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _init() -> void:
	call_deferred(&"_build")


func _build() -> void:
	var home := HOME_SCENE.instantiate() as HomeScreen
	home.setup({
		&"best_score": 48210,
		&"soul_shards": 5670,
		&"selected_rift": "ember_hollow",
		&"rift_levels": {"ember_hollow": 2},
		&"settings": {&"reduced_motion": false},
	}, FORMS.get_form(&"frost"))
	root.add_child(home)
