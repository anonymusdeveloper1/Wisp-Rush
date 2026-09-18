extends Control
## Visual-QA fixture: the production Shop CHARACTERS tab focused on one character.
##
## Every character is owned so the cards show full brightness; WISP_CHARACTER picks the focused and
## equipped one (default veyra). Its card plays the selected flourish when the Shop opens.
##
## Usage:
##   WISP_CHARACTER=rook tools/screenshot.sh \
##     res://tools/godot/render_character_select_showcase.tscn 70 540x960

const SHOP_SCENE: PackedScene = preload("res://scenes/screens/shop_screen.tscn")


func _ready() -> void:
	var focused: String = OS.get_environment("WISP_CHARACTER")
	if focused.is_empty():
		focused = "veyra"
	var shop := SHOP_SCENE.instantiate() as ShopScreen
	shop.setup({
		&"rift_points": 1250,
		&"owned_forms": SaveManagerService.VALID_FORM_IDS.duplicate(),
		&"equipped_form": focused,
		&"owned_dash_styles": ["soul"],
		&"equipped_dash_style": "soul",
		&"owned_arena_skins": ["astral_observatory"],
		&"equipped_arena_skin": "astral_observatory",
		&"bosses_defeated": 1,
		&"settings": {&"reduced_motion": false},
		&"store_available": false,
	}, ShopScreen.TAB_WISPS)
	add_child(shop)
