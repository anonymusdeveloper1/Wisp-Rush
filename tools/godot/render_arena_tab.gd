extends Control
## Visual-QA fixture: the production Shop ARENAS tab, with a mixed ownership snapshot.
##
## Three skins owned and one equipped, so the owned / equipped / priced states all appear at once.
## Used to review the arena browsing layout; keep it alongside any redesign of that tab so the
## before and after are captured the same way.
##
## Usage:
##   tools/screenshot.sh res://tools/godot/render_arena_tab.tscn 90 540x960
const SHOP: PackedScene = preload("res://scenes/screens/shop_screen.tscn")
func _ready() -> void:
	var shop := SHOP.instantiate() as ShopScreen
	shop.setup({
		&"rift_points": 4200,
		&"owned_forms": SaveManagerService.VALID_FORM_IDS.duplicate(),
		&"equipped_form": "verdant_shade",
		&"owned_arena_skins": ["astral_observatory", "bamboo_deck", "cold_forge"],
		&"equipped_arena_skin": "astral_observatory",
		&"bosses_defeated": 1,
		&"settings": {&"reduced_motion": false},
		&"store_available": false,
	}, ShopScreen.TAB_ARENAS)
	add_child(shop)
	# WISP_ARENA_PEEK=<skin_id> opens that arena's full-bleed preview, so the board captures the
	# second level of the gallery as well as the grid.
	var peek: String = OS.get_environment("WISP_ARENA_PEEK")
	if peek.is_empty():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var tile := shop.find_child("Tile_%s" % peek, true, false) as Button
	if tile == null:
		push_warning("render_arena_tab: no tile for %s" % peek)
		return
	tile.emit_signal(&"pressed")
