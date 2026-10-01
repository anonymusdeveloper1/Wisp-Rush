extends Control
## Visual-QA fixture: the production Shop ARENAS tab - the card pager, focused on the equipped arena.
##
## Keep it alongside any redesign of that tab so the before and after are captured the same way.
##
## Usage:
##   tools/screenshot.sh res://tools/godot/render_arena_tab.tscn 90 540x960
const SHOP: PackedScene = preload("res://scenes/screens/shop_screen.tscn")


func _ready() -> void:
	var shop := SHOP.instantiate() as ShopScreen
	shop.setup({
		&"rift_points": 4200,
		&"owned_forms": SaveManagerService.VALID_FORM_IDS.duplicate(),
		&"equipped_form": "patchvile",
		&"owned_arena_skins": [SaveManagerService.DEFAULT_ARENA_SKIN_ID],
		&"equipped_arena_skin": SaveManagerService.DEFAULT_ARENA_SKIN_ID,
		&"bosses_defeated": 1,
		&"settings": {&"reduced_motion": false},
		&"store_available": false,
	}, ShopScreen.TAB_ARENAS)
	add_child(shop)
