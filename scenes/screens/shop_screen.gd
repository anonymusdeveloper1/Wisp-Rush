class_name ShopScreen
extends Control
## The Shop: the one place Rift Points are spent. Three tabs - CHARACTERS, ARENAS, NO ADS.
##
## Each RP tab is a FocusCarousel of cards that behaves like the old Forms picker (owner reference
## 2026-09-13): swipe or tap a side card to browse, locked items stay previewable, one description
## line and a single main button. The button reads BUY • price, NEED n RP, the gate reason, EQUIP or
## EQUIPPED (spec story_and_endless/04). NO ADS is the ADR-0012 Remove Ads panel with no Rift Points
## anywhere: its buttons stay disabled until a real store is connected. The screen only emits
## intent; Main runs purchases and equips through SaveManager, store purchases through Monetisation.
## Styling comes from theme type variations: the tab bar is a NavBar of toggle NavButtons.

## Asks Main to buy the cosmetic `item_id` of `kind` (a SaveManagerService.KIND_* value).
signal purchase_requested(kind: StringName, item_id: StringName)
## Asks Main to equip an owned cosmetic.
signal equip_requested(kind: StringName, item_id: StringName)
## Asks Main to buy a real-money product; only possible while the store is available.
signal store_purchase_requested(product_id: StringName)
## Asks Main to restore earlier store purchases.
signal restore_requested
## The player switched tabs; Main remembers the last tab for the session.
signal tab_changed(tab: StringName)
## The player left the Shop.
signal back_requested

## The CHARACTERS tab; its id keeps the older "wisps" name (sessions and fixtures refer to it).
const TAB_WISPS: StringName = &"wisps"
const TAB_ARENAS: StringName = &"arenas"
const TAB_NO_ADS: StringName = &"no_ads"
const TABS: Array[StringName] = [TAB_WISPS, TAB_ARENAS, TAB_NO_ADS]

const RP_ICON: Texture2D = preload("res://assets/art/ui/system/02_soul_shards.png")
const LOCK_ICON: Texture2D = preload("res://assets/art/ui/system/17_lock.png")
const OWNED_ICON: Texture2D = preload("res://assets/art/ui/system/10_forms.png")
const REAPER_ICON: Texture2D = preload("res://assets/art/ui/system/18_reaper.png")
## Brightness of an unowned item's visual, so ownership reads at a glance on every card.
## Badge colour per collectible tier; [constant FormData.Tier.STANDARD] shows no badge at all.
## Arena gallery: columns of thumbnails, and the height of one tile's art.
##
## Arenas are places, not collectibles. Thirty of them in the one-at-a-time card carousel meant
## thirty swipes and a picture of a picture; the gallery shows them as the art they are, grouped by
## tier, and tapping one opens it full-bleed the way it will actually look in a run
## (owner decision 2026-09-20).
## Three across, and the art is drawn at the thumbnails' own portrait shape (282x502). A landscape
## tile cropped every arena down to its empty floor, which is the one part they all share.
const ARENA_COLUMNS: int = 3
const ARENA_TILE_HEIGHT: float = 500.0
## Caption size on a tile; the default is sized for a full-width card, not a third of one.
const ARENA_TILE_FONT_SIZE: int = 22
## Tier accent for an arena section header, indexed by [enum ArenaSkinData.Tier].
const ARENA_TIER_COLOURS: Array[Color] = [
	Color(0.47, 0.59, 0.65),
	Color(0.43, 0.78, 0.90),
	Palette.WARNING_AMBER,
	Palette.RIFT_MAGENTA,
]

const TIER_COLOURS: Dictionary[FormData.Tier, Color] = {
	FormData.Tier.LEGENDARY: Palette.WARNING_AMBER,
	FormData.Tier.MYTHIC: Palette.RIFT_MAGENTA,
}

const LOCKED_VISUAL_BRIGHTNESS: float = 0.42
## Card text sizes in the 1080-wide design space.
const CARD_NAME_SIZE: int = 44
const CARD_STATE_SIZE: int = 34
const STATE_ICON_SIZE := Vector2(48, 48)
## Soft halo in the form's own tint behind its portrait.
const PORTRAIT_GLOW_ALPHA: float = 0.42
const LOCKED_GLOW_ALPHA: float = 0.14
## ARENAS cards get their thumbnail and scenery grade only within this many cards of the focused
## one; the rest keep an empty card frame until the carousel scrolls near (30 grade materials built
## at once stalled the Shop's first frame on device, owner report 2026-09-16).
const ARENA_VISUAL_RADIUS: int = 2
## Share of a CHARACTERS card's picture area a rigged character and a single-image form fill.
## How many cards either side of the focused one are built as live, animated characters.
## Every other card shows its still portrait. A live card holds its character's whole menu
## frame set, and a texture costs its full uncompressed size in VRAM whatever it cost on
## disk, so building all of them at once is what a whole-frame roster cannot afford
## (docs/guides/character_sprite_frames.md §9c).
const LIVE_CARD_RADIUS: int = 1
const CHARACTER_FILL: float = 0.94
const PORTRAIT_FILL: float = 0.9

@export var form_catalog: FormCatalog
@export var endless_catalog: EndlessCatalog

var _snapshot: Dictionary = {}
var _tab: StringName = TAB_WISPS
## Tab whose cards are currently in the carousel; empty until the first build.
var _built_tab: StringName = &""
## Previewed item per RP tab; an absent tab follows its equipped item.
var _selected_ids: Dictionary[StringName, StringName] = {}
var _items: Array[Resource] = []
var _pending_feedback: Array = []
## True while the screen itself moves the carousel, so that move is not mistaken for a player pick.
var _syncing: bool = false
var _glow_texture: GradientTexture2D
## Live character previews of the CHARACTERS cards by form id (rigs and animated portraits alike).
var _character_previews: Dictionary[StringName, PlayableCharacterPreview] = {}
var _tab_buttons: Dictionary[StringName, Button] = {}
## ARENAS card indices whose thumbnail is filled, and the card index they were last filled around.
## One scenery grade material per scenery, shared by every card that shows it.
var _scenery_materials: Dictionary[ArenaSceneryData, ShaderMaterial] = {}

@onready var _balance_label: Label = %BalanceLabel
@onready var _carousel_page: Control = %CarouselPage
@onready var _carousel: FocusCarousel = %Carousel
@onready var _dots: PageDots = %Dots
@onready var _tier_label: Label = %TierLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _requirement_label: Label = %RequirementLabel
@onready var _arena_page: ScrollContainer = %ArenaPage
@onready var _arena_list: VBoxContainer = %ArenaList
@onready var _arena_peek: Control = %ArenaPeek
@onready var _peek_art: TextureRect = %PeekArt
@onready var _peek_name: Label = %PeekName
@onready var _peek_tier: Label = %PeekTier
@onready var _peek_description: Label = %PeekDescription
@onready var _peek_requirement: Label = %PeekRequirement
@onready var _peek_action: Button = %PeekAction
@onready var _peek_back: Button = %PeekBack
@onready var _no_ads_page: Control = %NoAdsPage
@onready var _offer_status: Label = %OfferStatus
@onready var _offer_strike: ColorRect = %OfferStrike
@onready var _restore_button: Button = %RestoreButton
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _action_button: Button = %ActionButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	assert(form_catalog != null and endless_catalog != null)
	# The offer emblem is Home's NO ADS glyph, not currency art: Remove Ads carries no Rift Points.
	_offer_strike.color = Palette.WARNING_AMBER
	# Main plays the purchase, equip or error sound for these, so SoundFx must not add a click.
	# BOUND_META rather than SKIP_META, which would also drop UiJuice's press dip.
	for button: Button in [_action_button, _restore_button]:
		button.set_meta(SoundFx.BOUND_META, true)
	_tab_buttons = {
		TAB_WISPS: %WispsTab as Button,
		TAB_ARENAS: %ArenasTab as Button,
		TAB_NO_ADS: %NoAdsTab as Button,
	}
	var group := ButtonGroup.new()
	for tab: StringName in TABS:
		var tab_button: Button = _tab_buttons[tab]
		tab_button.toggle_mode = true
		tab_button.button_group = group
		tab_button.pressed.connect(_on_tab_pressed.bind(tab))
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_action_button.pressed.connect(_on_action_pressed)
	_restore_button.pressed.connect(func() -> void: restore_requested.emit())
	_peek_action.pressed.connect(_on_action_pressed)
	_peek_back.pressed.connect(_close_arena_peek)
	_carousel.selection_changed.connect(_on_carousel_selection_changed)
	_carousel.activated.connect(func(_index: int) -> void: _on_action_pressed())
	_rebuild()
	if not _pending_feedback.is_empty():
		show_feedback(str(_pending_feedback[0]), bool(_pending_feedback[1]))
		_pending_feedback.clear()
	print("[Shop] ready | tab=%s store=%s" % [_tab, _store_available()])


func _process(_delta: float) -> void:
	_dots.position_value = _carousel.get_scroll()


## Shows `tab` for a save snapshot. Safe before `_ready` (Main sets screens up before adding them).
##
## Reads `rift_points`, `owned_*` / `equipped_*` for characters and arena skins,
## `bosses_defeated`, `rift_levels`, `ads_removed` and `settings`, plus `store_available`, which
## Main adds because the store is not part of the save.
func setup(snapshot: Dictionary, tab: StringName) -> void:
	_snapshot = snapshot.duplicate(true)
	_tab = tab if tab in TABS else TAB_WISPS
	if is_node_ready():
		_rebuild()


## The tab on screen.
func get_tab() -> StringName:
	return _tab


## The id previewed on the current RP tab, or empty on NO ADS.
func get_selected_id() -> StringName:
	return _selected_id(_tab) if _tab != TAB_NO_ADS else &""


## Shows a short purchase, equip or restore result. Safe before `_ready`.
func show_feedback(message: String, success: bool) -> void:
	if not is_node_ready():
		_pending_feedback = [message, success]
		return
	_feedback_label.text = message
	_feedback_label.modulate = Palette.SOUL_CYAN if success else Palette.WARNING_AMBER


func _on_tab_pressed(tab: StringName) -> void:
	if tab == _tab:
		return
	_tab = tab
	_feedback_label.text = ""
	_rebuild()
	tab_changed.emit(tab)


func _rebuild() -> void:
	for tab: StringName in TABS:
		_tab_buttons[tab].set_pressed_no_signal(tab == _tab)
	var rp_tab: bool = _tab != TAB_NO_ADS
	var gallery: bool = _tab == TAB_ARENAS
	_carousel_page.visible = rp_tab and not gallery
	_arena_page.visible = gallery
	_no_ads_page.visible = not rp_tab
	if not gallery:
		_close_arena_peek()
	if rp_tab and _built_tab != _tab:
		_build_cards()
	elif rp_tab and not _selected_ids.has(_tab):
		# A snapshot can arrive after the cards were built (fixtures add the screen before setting it
		# up). Until the player browses this tab, its carousel follows the equipped item.
		_focus_selected_card()
	if rp_tab:
		_sync_live_cards()
	_refresh()
	if rp_tab:
		_carousel.grab_focus.call_deferred()


func _build_cards() -> void:
	_built_tab = _tab
	_items = _items_for(_tab)
	_character_previews.clear()
	if _tab == TAB_ARENAS:
		_built_tab = _tab
		_build_arena_gallery()
		return
	var cards: Array[Control] = []
	for item: Resource in _items:
		cards.append(_build_card(item))
	_syncing = true
	_carousel.set_cards(cards, _index_of(_selected_id(_tab)))
	_syncing = false
	_sync_live_cards()
	_dots.count = _items.size()


func _items_for(tab: StringName) -> Array[Resource]:
	var items: Array[Resource] = []
	match tab:
		TAB_WISPS:
			items.assign(form_catalog.load_forms())
		TAB_ARENAS:
			for skin: ArenaSkinData in endless_catalog.skins:
				if skin != null:
					items.append(skin)
	return items


## Moves the carousel to this tab's selected item without reporting it as a player pick.
func _focus_selected_card() -> void:
	_syncing = true
	_carousel.select(_index_of(_selected_id(_tab)), false)
	_syncing = false


func _on_carousel_selection_changed(index: int) -> void:
	if _syncing or index < 0 or index >= _items.size():
		return
	_selected_ids[_tab] = _item_id(_items[index])
	_feedback_label.text = ""
	_sync_live_cards()
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_balance_label.text = RiftPoints.format(_balance())
	if _tab == TAB_NO_ADS:
		_refresh_no_ads()
		return
	if _tab == TAB_ARENAS:
		_refresh_arena_gallery()
		return
	var hollow := PackedInt32Array()
	for index: int in _items.size():
		_refresh_card(_carousel.get_card(index), _items[index])
		if not _owns(_items[index]):
			hollow.append(index)
	_dots.hollow = hollow
	var selected_index: int = _index_of(_selected_id(_tab))
	if selected_index >= _items.size():
		_apply_tier(null)
		_description_label.text = ""
		_action_button.text = "EQUIPPED"
		_action_button.disabled = true
		return
	var item: Resource = _items[selected_index]
	_apply_tier(item)
	_description_label.text = str(item.get(&"description"))
	var price: int = _price(item)
	var gate: String = _gate_reason(item)
	_action_button.icon = null
	if _owns(item):
		var equipped: bool = _is_equipped(item)
		_requirement_label.text = "EQUIPPED" if equipped else "OWNED  ·  READY TO EQUIP"
		_action_button.text = "EQUIPPED" if equipped else "EQUIP"
		_action_button.disabled = equipped
	elif not gate.is_empty():
		_requirement_label.text = "LOCKED"
		_action_button.icon = LOCK_ICON
		_action_button.text = gate
		_action_button.disabled = true
	elif _balance() < price:
		_requirement_label.text = "LOCKED  ·  %s" % RiftPoints.format(price)
		_action_button.text = "NEED %s" % RiftPoints.format(price - _balance())
		_action_button.disabled = true
	else:
		_requirement_label.text = "READY TO BUY"
		_action_button.text = "BUY  •  %s" % RiftPoints.format(price)
		_action_button.disabled = false


## Builds the arena gallery: one section per tier, thumbnails two across inside it.
func _build_arena_gallery() -> void:
	for child: Node in _arena_list.get_children():
		child.queue_free()
	var sections: Dictionary[int, GridContainer] = {}
	for item: Resource in _items:
		var skin := item as ArenaSkinData
		if skin == null:
			continue
		var tier: int = int(skin.tier)
		if not sections.has(tier):
			sections[tier] = _add_arena_section(tier)
		sections[tier].add_child(_build_arena_tile(skin))
	_refresh_arena_gallery()


## A tier heading with its count, and the grid the tier's tiles go into.
func _add_arena_section(tier: int) -> GridContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 16)
	_arena_list.add_child(header)
	var title := Label.new()
	title.text = ArenaSkinData.TIER_NAMES[clampi(tier, 0, ArenaSkinData.TIER_NAMES.size() - 1)]
	title.theme_type_variation = &"CaptionLabel"
	title.add_theme_color_override(&"font_color", ARENA_TIER_COLOURS[
		clampi(tier, 0, ARENA_TIER_COLOURS.size() - 1)
	])
	header.add_child(title)
	var rule := Control.new()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(rule)
	var count := Label.new()
	count.name = "Count"
	count.theme_type_variation = &"CaptionLabel"
	header.add_child(count)
	var grid := GridContainer.new()
	grid.columns = ARENA_COLUMNS
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 18)
	_arena_list.add_child(grid)
	return grid


## One tile: the arena's own thumbnail, its name, and what it costs or that you own it.
func _build_arena_tile(skin: ArenaSkinData) -> Control:
	var tile := Button.new()
	tile.name = "Tile_%s" % skin.skin_id
	# Flat on purpose: a gallery tile is the arena's own art, not a card. The ornate card frame is
	# the collectible signifier that made thirty places look like thirty trading cards, and its
	# bottom trim sat right where the price has to go.
	tile.flat = true
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size = Vector2(0, ARENA_TILE_HEIGHT + 96.0)
	tile.pressed.connect(_on_arena_tile_pressed.bind(skin))
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 6)
	tile.add_child(column)
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = skin.thumbnail
	art.custom_minimum_size = Vector2(0, ARENA_TILE_HEIGHT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art)
	var name_label := Label.new()
	name_label.text = skin.display_name
	name_label.theme_type_variation = &"CaptionLabel"
	name_label.add_theme_font_size_override(&"font_size", ARENA_TILE_FONT_SIZE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# A three-column tile is narrower than the longest arena name, so the name shrinks to fit
	# rather than spilling over its neighbour.
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(name_label)
	var state := Label.new()
	state.name = "State"
	state.theme_type_variation = &"CaptionLabel"
	state.add_theme_font_size_override(&"font_size", ARENA_TILE_FONT_SIZE)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(state)
	return tile


## Ownership, price and lock state on every tile, plus the tier counts.
func _refresh_arena_gallery() -> void:
	var owned_per_tier: Dictionary[int, int] = {}
	var total_per_tier: Dictionary[int, int] = {}
	for item: Resource in _items:
		var skin := item as ArenaSkinData
		if skin == null:
			continue
		var tier: int = int(skin.tier)
		total_per_tier[tier] = total_per_tier.get(tier, 0) + 1
		var tile := _arena_list.find_child("Tile_%s" % skin.skin_id, true, false) as Button
		if tile == null:
			continue
		var art := tile.find_child("Art", true, false) as CanvasItem
		var state := tile.find_child("State", true, false) as Label
		var owns: bool = _owns(skin)
		if owns:
			owned_per_tier[tier] = owned_per_tier.get(tier, 0) + 1
		if art != null:
			var shade: float = 1.0 if owns else LOCKED_VISUAL_BRIGHTNESS
			art.modulate = Color(shade, shade, shade, 1.0)
		if state == null:
			continue
		var gate: String = _gate_reason(skin)
		if _is_equipped(skin):
			state.text = "EQUIPPED"
			state.add_theme_color_override(&"font_color", Palette.SOUL_CYAN)
		elif owns:
			state.text = "OWNED"
			state.add_theme_color_override(&"font_color", Palette.SOUL_CYAN)
		elif not gate.is_empty():
			state.text = gate
			state.add_theme_color_override(&"font_color", Palette.WARNING_AMBER)
		else:
			state.text = RiftPoints.format(_price(skin))
			state.add_theme_color_override(&"font_color", Palette.WARNING_AMBER)
	var section: int = 0
	for child: Node in _arena_list.get_children():
		var count := child.find_child("Count", true, false) as Label
		if count == null:
			continue
		var tier: int = section
		section += 1
		count.text = "%d / %d" % [owned_per_tier.get(tier, 0), total_per_tier.get(tier, 0)]
	if _arena_peek.visible:
		_refresh_arena_peek()


func _on_arena_tile_pressed(skin: ArenaSkinData) -> void:
	_selected_ids[_tab] = skin.skin_id
	_feedback_label.text = ""
	_open_arena_peek()


## The peek: the arena filling the screen the way a run will show it, with its own buy/equip.
func _open_arena_peek() -> void:
	_arena_peek.visible = true
	_refresh_arena_peek()


func _close_arena_peek() -> void:
	if not _arena_peek.visible:
		return
	_arena_peek.visible = false
	_refresh()


## Closes the peek before the Shop itself handles Back, so Android back steps out one level at a
## time instead of leaving the screen from under an open preview.
func handle_back() -> bool:
	if _arena_peek.visible:
		_close_arena_peek()
		return true
	return false


func _refresh_arena_peek() -> void:
	var index: int = _index_of(_selected_id(_tab))
	if index >= _items.size():
		_close_arena_peek()
		return
	var skin := _items[index] as ArenaSkinData
	if skin == null:
		return
	_peek_art.texture = skin.load_background()
	_peek_name.text = skin.display_name
	_peek_tier.text = skin.get_tier_name()
	_peek_tier.add_theme_color_override(&"font_color", ARENA_TIER_COLOURS[
		clampi(int(skin.tier), 0, ARENA_TIER_COLOURS.size() - 1)
	])
	_peek_description.text = skin.description
	var price: int = _price(skin)
	var gate: String = _gate_reason(skin)
	_peek_action.icon = null
	if _owns(skin):
		var equipped: bool = _is_equipped(skin)
		_peek_requirement.text = "EQUIPPED" if equipped else "OWNED  ·  READY TO EQUIP"
		_peek_action.text = "EQUIPPED" if equipped else "EQUIP"
		_peek_action.disabled = equipped
	elif not gate.is_empty():
		_peek_requirement.text = "LOCKED"
		_peek_action.icon = LOCK_ICON
		_peek_action.text = gate
		_peek_action.disabled = true
	elif _balance() < price:
		_peek_requirement.text = "LOCKED  ·  %s" % RiftPoints.format(price)
		_peek_action.text = "NEED %s" % RiftPoints.format(price - _balance())
		_peek_action.disabled = true
	else:
		_peek_requirement.text = "READY TO BUY"
		_peek_action.text = "BUY  •  %s" % RiftPoints.format(price)
		_peek_action.disabled = false


func _refresh_no_ads() -> void:
	var ads_removed: bool = bool(_snapshot.get(&"ads_removed", false))
	var store: bool = _store_available()
	if ads_removed:
		_offer_status.text = "ADS REMOVED  •  THANK YOU"
		_action_button.text = "OWNED"
		_action_button.disabled = true
	elif not store:
		_offer_status.text = "THE STORE IS NOT OPEN YET"
		_action_button.text = "COMING SOON"
		_action_button.disabled = true
	else:
		_offer_status.text = "ONE-TIME PURCHASE"
		_action_button.text = "BUY"
		_action_button.disabled = false
	_action_button.icon = null
	_restore_button.disabled = not store
	_ensure_no_ads_focus.call_deferred()


## Focuses BUY, or BACK when BUY is disabled - only when focus is missing or on a disabled button,
## so a refresh after RESTORE never yanks keyboard or controller focus away from the player.
func _ensure_no_ads_focus() -> void:
	if not is_inside_tree() or _tab != TAB_NO_ADS:
		return
	var owner_control: Control = get_viewport().gui_get_focus_owner()
	var owner_button := owner_control as BaseButton
	if (
		owner_control != null
		and is_ancestor_of(owner_control)
		and owner_control.is_visible_in_tree()
		and (owner_button == null or not owner_button.disabled)
	):
		return
	if _action_button.disabled:
		_back_button.grab_focus()
	else:
		_action_button.grab_focus()


func _on_action_pressed() -> void:
	var driver: Button = _peek_action if _arena_peek.visible else _action_button
	if driver.disabled:
		return
	if _tab == TAB_NO_ADS:
		store_purchase_requested.emit(MonetisationService.PRODUCT_REMOVE_ADS)
		return
	var index: int = _index_of(_selected_id(_tab))
	if index >= _items.size():
		return
	var item: Resource = _items[index]
	if _owns(item):
		equip_requested.emit(_kind(item), _item_id(item))
	else:
		purchase_requested.emit(_kind(item), _item_id(item))


# ------------------------------------------------------------------------ item model

func _kind(item: Resource) -> StringName:
	if item is ArenaSkinData:
		return SaveManagerService.KIND_ARENA_SKIN
	return SaveManagerService.KIND_FORM


func _item_id(item: Resource) -> StringName:
	if item is ArenaSkinData:
		return (item as ArenaSkinData).skin_id
	return (item as FormData).form_id


## Shows the focused character's collectible tier above its description. Ordinary characters and
## every non-character tab show nothing, and the badge never replaces price or ownership state.
func _apply_tier(item: Resource) -> void:
	var form := item as FormData
	var label: String = form.get_tier_name() if form != null else ""
	_tier_label.text = label
	_tier_label.visible = not label.is_empty()
	if form != null:
		_tier_label.modulate = TIER_COLOURS.get(form.tier, Palette.TEXT_MUTED)


func _price(item: Resource) -> int:
	return maxi(0, int(item.get(&"price")))


func _owned_ids(kind: StringName) -> Array:
	var key: StringName = &"owned_forms"
	match kind:
		SaveManagerService.KIND_ARENA_SKIN:
			key = &"owned_arena_skins"
	var owned: Variant = _snapshot.get(key, [])
	return owned as Array if owned is Array else []


func _equipped_id(tab: StringName) -> StringName:
	match tab:
		TAB_ARENAS:
			return StringName(str(_snapshot.get(
				&"equipped_arena_skin", endless_catalog.default_skin_id
			)))
	return StringName(str(_snapshot.get(&"equipped_form", "void")))


func _selected_id(tab: StringName) -> StringName:
	return _selected_ids.get(tab, _equipped_id(tab)) as StringName


func _owns(item: Resource) -> bool:
	return String(_item_id(item)) in _owned_ids(_kind(item))


func _is_equipped(item: Resource) -> bool:
	match _kind(item):
		SaveManagerService.KIND_ARENA_SKIN:
			return _item_id(item) == _equipped_id(TAB_ARENAS)
	return _item_id(item) == _equipped_id(TAB_WISPS)


## Why an unowned item cannot be bought yet, as the button text; empty when nothing gates it.
func _gate_reason(item: Resource) -> String:
	if item is FormData and (item as FormData).requires_boss_victory:
		if int(_snapshot.get(&"bosses_defeated", 0)) <= 0:
			return "BEAT A BOSS FIRST"
	return ""


func _index_of(item_id: StringName) -> int:
	for index: int in _items.size():
		if _item_id(_items[index]) == item_id:
			return index
	return 0


func _balance() -> int:
	return maxi(0, int(_snapshot.get(&"rift_points", 0)))


func _store_available() -> bool:
	return bool(_snapshot.get(&"store_available", false))


func _reduced_motion() -> bool:
	var settings: Variant = _snapshot.get(&"settings", {})
	return settings is Dictionary and bool((settings as Dictionary).get(&"reduced_motion", false))


func _equipped_form_tint() -> Color:
	return form_catalog.get_form(_equipped_id(TAB_WISPS)).tint


# ------------------------------------------------------------------------ cards

## One portrait card: name on top, the item's visual in the middle, its state at the bottom.
## Builds a character card for the carousel. Arenas do not come through here any more: they are a
## gallery of their own art now (see [method _build_arena_gallery]).
func _build_card(item: Resource) -> Control:
	var card := Button.new()
	card.theme_type_variation = &"CardButton"
	card.name = "Card_%s" % _item_id(item)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, 34)
	margin.add_theme_constant_override(&"margin_top", 44)
	margin.add_theme_constant_override(&"margin_bottom", 40)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	margin.add_child(column)

	var name_label := Label.new()
	name_label.theme_type_variation = &"TitleLabel"
	name_label.add_theme_font_size_override(&"font_size", CARD_NAME_SIZE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = str(item.get(&"display_name"))
	column.add_child(name_label)

	var visual := MarginContainer.new()
	visual.name = "Visual"
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(visual)
	_add_form_visual(visual, item as FormData)

	var state_row := HBoxContainer.new()
	state_row.alignment = BoxContainer.ALIGNMENT_CENTER
	state_row.add_theme_constant_override(&"separation", 10)
	column.add_child(state_row)
	var state_icon := TextureRect.new()
	state_icon.name = "StateIcon"
	state_icon.custom_minimum_size = STATE_ICON_SIZE
	state_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	state_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	state_row.add_child(state_icon)
	var state_label := Label.new()
	state_label.name = "State"
	state_label.theme_type_variation = &"CaptionLabel"
	state_label.add_theme_font_size_override(&"font_size", CARD_STATE_SIZE)
	state_row.add_child(state_label)
	return card


## Builds the still card. Only the focused card and its neighbours are then brought to life by
## [method _sync_live_cards]; the rest keep this portrait, which costs one shared texture instead of
## a character's whole menu frame set.
func _add_form_visual(visual: Control, form: FormData) -> void:
	if _glow_texture == null:
		_glow_texture = _portrait_glow_texture()
	var glow := _texture_rect(_glow_texture, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	glow.name = "Glow"
	glow.self_modulate = Color(form.tint, 1.0)
	visual.add_child(glow)
	var portrait := _texture_rect(form.texture, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	portrait.name = "Portrait"
	visual.add_child(portrait)


## Brings the focused card and its [constant LIVE_CARD_RADIUS] neighbours to life and puts every
## other card back to its still portrait. Called whenever the carousel moves, so walking the roster
## never holds more than a few characters' menu frames at once.
func _sync_live_cards() -> void:
	if _tab != TAB_WISPS:
		return
	var centre: int = _index_of(_selected_id(_tab))
	for index: int in _items.size():
		var form := _items[index] as FormData
		if form == null:
			continue
		# A single-image Wisp form counts too: it idles on the shared base rig, so a live card
		# animates it just as a character's own scene animates a character.
		var wanted: bool = absi(index - centre) <= LIVE_CARD_RADIUS
		var live: bool = _character_previews.has(form.form_id)
		if wanted == live:
			continue
		if wanted:
			_wake_card(index, form)
		else:
			_sleep_card(index, form)


## Replaces a card's still portrait with a live character.
func _wake_card(index: int, form: FormData) -> void:
	var visual: Control = _card_visual(index)
	if visual == null:
		return
	var preview := PlayableCharacterPreview.new()
	preview.name = "LivePortrait"
	preview.fill_ratio = CHARACTER_FILL
	preview.set_reduced_motion(_reduced_motion())
	visual.add_child(preview)
	if not preview.set_form(form, true):
		visual.remove_child(preview)
		preview.queue_free()
		return
	_character_previews[form.form_id] = preview
	var portrait := visual.get_node_or_null(^"Portrait") as CanvasItem
	if portrait != null:
		portrait.visible = false
	_refresh_card(_carousel.get_card(index), form)


## Frees a card's live character and shows its still portrait again.
func _sleep_card(index: int, form: FormData) -> void:
	var preview: PlayableCharacterPreview = _character_previews.get(form.form_id)
	_character_previews.erase(form.form_id)
	if preview != null and is_instance_valid(preview):
		preview.queue_free()
	var visual: Control = _card_visual(index)
	if visual == null:
		return
	var portrait := visual.get_node_or_null(^"Portrait") as CanvasItem
	if portrait != null:
		portrait.visible = true
	_refresh_card(_carousel.get_card(index), form)


func _card_visual(index: int) -> Control:
	var card: Control = _carousel.get_card(index)
	return null if card == null else card.find_child("Visual", true, false) as Control


func _texture_rect(texture: Texture2D, stretch: TextureRect.StretchMode) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = stretch
	return rect


func _refresh_card(card: Control, item: Resource) -> void:
	if card == null:
		return
	var owned: bool = _owns(item)
	var visual := card.find_child("LivePortrait", true, false) as CanvasItem
	if visual == null:
		visual = card.find_child("Portrait", true, false) as CanvasItem
	var state_icon := card.find_child("StateIcon", true, false) as TextureRect
	var state_label := card.find_child("State", true, false) as Label
	var glow := card.find_child("Glow", true, false) as CanvasItem
	var brightness: float = 1.0 if owned else LOCKED_VISUAL_BRIGHTNESS
	if visual != null:
		visual.modulate = Color(brightness, brightness, brightness, 1.0)
	if glow != null:
		glow.modulate.a = PORTRAIT_GLOW_ALPHA if owned else LOCKED_GLOW_ALPHA
	var gate: String = _gate_reason(item)
	if _is_equipped(item) and owned:
		state_icon.texture = OWNED_ICON
		state_label.text = "EQUIPPED"
	elif owned:
		state_icon.texture = OWNED_ICON
		state_label.text = "OWNED"
	elif not gate.is_empty():
		state_icon.texture = REAPER_ICON if item is FormData else LOCK_ICON
		state_label.text = "BOSS" if item is FormData else "ENDLESS"
	else:
		state_icon.texture = RP_ICON
		state_label.text = RiftPoints.format(_price(item))


## Radial white-to-clear halo, tinted per card through self_modulate.
func _portrait_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture
