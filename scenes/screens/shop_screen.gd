class_name ShopScreen
extends Control
## The Shop (owner 2026-10-05, GDD §14 #78, ADR-0028): the back button and the Rift Points balance
## at the top, and a bottom navigation between two pages, CHARACTERS and SHOP.
##
## CHARACTERS is a FocusCarousel of character cards that behaves like the old Forms picker (owner
## reference 2026-09-13): swipe or tap a side card to browse, locked characters stay previewable,
## one description line and a single main button that reads BUY • price, NEED n RP, the gate reason,
## EQUIP or EQUIPPED. SHOP is one scrolling list of the deals: NO ADS (the ADR-0012 Remove Ads offer
## and Restore), ITEMS (pickup packs and the next-run boost, bought with Rift Points) and RIFT
## POINTS (packs sold for real money); it scrolls by swiping, with no scroll bar drawn. Real-money
## buttons stay disabled until a real store is connected. The screen only emits intent; Main runs
## purchases and equips through SaveManager, store purchases through Monetisation. Styling comes
## from theme type variations: the bottom navigation is a NavBar of toggle NavButtons.

## Asks Main to buy the cosmetic `item_id` of `kind` (a SaveManagerService.KIND_* value).
signal purchase_requested(kind: StringName, item_id: StringName)
## Asks Main to persist a pickup pack purchase.
signal item_pack_requested(item_id: StringName, quantity: int)
## Selects or clears the owned starting boost for the next run.
signal starting_item_selected(item_id: StringName)
## Asks Main to equip an owned cosmetic.
signal equip_requested(kind: StringName, item_id: StringName)
## Asks Main to buy a real-money product (Remove Ads or a Rift Points pack); only possible while the
## store is available.
signal store_purchase_requested(product_id: StringName)
## Asks Main to restore earlier store purchases.
signal restore_requested
## The player switched pages; Main remembers the last one for the session.
signal tab_changed(tab: StringName)
## The player left the Shop.
signal back_requested

## The CHARACTERS page; its id keeps the older "wisps" name (sessions and fixtures refer to it).
const TAB_WISPS: StringName = &"wisps"
## The SHOP page: NO ADS, ITEMS and RIFT POINTS.
const TAB_SHOP: StringName = &"shop"
const TABS: Array[StringName] = [TAB_WISPS, TAB_SHOP]

const RP_ICON: Texture2D = preload("res://assets/ui/theme/icons/icon_currency.tres")
const LOCK_ICON: Texture2D = preload("res://assets/ui/theme/icons/icon_lock.tres")
const OWNED_ICON: Texture2D = preload("res://assets/art/ui/system/10_forms.png")
const REAPER_ICON: Texture2D = preload("res://assets/art/ui/system/18_reaper.png")

## Brightness of an unowned character's visual, so ownership reads at a glance on every card.
const LOCKED_VISUAL_BRIGHTNESS: float = 0.42
## Card text sizes in the 1080-wide design space.
const CARD_NAME_SIZE: int = 44
const CARD_STATE_SIZE: int = 33
const STATE_ICON_SIZE := Vector2(48, 48)
## Soft halo in the form's own tint behind its portrait.
const PORTRAIT_GLOW_ALPHA: float = 0.42
const LOCKED_GLOW_ALPHA: float = 0.14
## How many cards either side of the focused one are built live (an animated character). Every other
## card shows its still portrait. A live card holds a character's whole menu frame set, and a
## texture costs its full uncompressed size in VRAM whatever it cost on disk, so building all of
## them at once is what the roster cannot afford.
const LIVE_CARD_RADIUS: int = 1
## Share of a CHARACTERS card's picture area a live character fills.
const CHARACTER_FILL: float = 0.94
## A Rift Points pack card's picture size, in design pixels.
const PACK_ICON_SIZE := Vector2(176, 176)

@export var form_catalog: FormCatalog
## The Rift Points packs the SHOP page sells.
@export var rift_points_packs: RiftPointsPackCatalog

var _snapshot: Dictionary = {}
var _tab: StringName = TAB_WISPS
## Whether the character cards are in the carousel yet.
var _cards_built: bool = false
## The character the player is previewing; absent means the equipped one.
var _selected_ids: Dictionary[StringName, StringName] = {}
var _items: Array[Resource] = []
var _pending_feedback: Array = []
## True while the screen itself moves the carousel, so that move is not mistaken for a player pick.
var _syncing: bool = false
var _glow_texture: GradientTexture2D
## Live character previews of the CHARACTERS cards by form id (rigs and animated portraits alike).
var _character_previews: Dictionary[StringName, PlayableCharacterPreview] = {}
var _tab_buttons: Dictionary[StringName, Button] = {}
## Each Rift Points pack card's buy button, by product id.
var _pack_buttons: Dictionary[StringName, Button] = {}
## The price label of each Rift Points pack card, by product id.
var _pack_prices: Dictionary[StringName, Label] = {}

@onready var _balance_label: Label = %BalanceLabel
@onready var _carousel_page: Control = %CarouselPage
@onready var _carousel: FocusCarousel = %Carousel
@onready var _dots: PageDots = %Dots
@onready var _description_label: Label = %DescriptionLabel
@onready var _requirement_label: Label = %RequirementLabel
@onready var _action_button: Button = %ActionButton
@onready var _shop_page: ScrollContainer = %ShopPage
@onready var _item_page: RunItemShopPage = %ItemsPage
@onready var _pack_grid: GridContainer = %RiftPointPacks
@onready var _offer_status: Label = %OfferStatus
@onready var _offer_strike: ColorRect = %OfferStrike
@onready var _offer_buy_button: Button = %OfferBuyButton
@onready var _restore_button: Button = %RestoreButton
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	assert(form_catalog != null and rift_points_packs != null)
	# The offer emblem is Home's NO ADS glyph, not currency art: Remove Ads carries no Rift Points.
	_offer_strike.color = Palette.WARNING_AMBER
	_tab_buttons = {TAB_WISPS: %WispsTab as Button, TAB_SHOP: %ShopTab as Button}
	var group := ButtonGroup.new()
	for tab: StringName in TABS:
		var tab_button: Button = _tab_buttons[tab]
		tab_button.toggle_mode = true
		tab_button.button_group = group
		tab_button.pressed.connect(_on_tab_pressed.bind(tab))
	_build_pack_cards()
	_pass_touches_to_scroll(_shop_page)
	# Main plays the purchase, equip or error sound for these, so SoundFx must not add a click.
	# BOUND_META rather than SKIP_META, which would also drop UiJuice's press dip.
	for button: Button in [_action_button, _offer_buy_button, _restore_button]:
		button.set_meta(SoundFx.BOUND_META, true)
	for button: Button in _pack_buttons.values():
		button.set_meta(SoundFx.BOUND_META, true)
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_action_button.pressed.connect(_on_action_pressed)
	_offer_buy_button.pressed.connect(
		func() -> void: store_purchase_requested.emit(MonetisationService.PRODUCT_REMOVE_ADS))
	_restore_button.pressed.connect(func() -> void: restore_requested.emit())
	_carousel.selection_changed.connect(_on_carousel_selection_changed)
	_carousel.activated.connect(func(_index: int) -> void: _on_action_pressed())
	_item_page.pack_requested.connect(
		func(id: StringName, quantity: int) -> void: item_pack_requested.emit(id, quantity))
	_item_page.starting_item_selected.connect(
		func(id: StringName) -> void: starting_item_selected.emit(id))
	_rebuild()
	if not _pending_feedback.is_empty():
		show_feedback(str(_pending_feedback[0]), bool(_pending_feedback[1]))
		_pending_feedback.clear()
	print("[Shop] ready | tab=%s store=%s" % [_tab, _store_available()])


func _process(_delta: float) -> void:
	_dots.position_value = _carousel.get_scroll()


## Shows the page `tab` for a save snapshot. Safe before `_ready` (Main sets screens up before
## adding them). An unknown tab (an older session's ARENAS, ITEMS or NO ADS) opens SHOP, which holds
## them.
##
## Reads `rift_points`, `owned_forms` / `equipped_form`, `bosses_defeated`, `ads_removed`, the item
## stock and `settings`, plus `store_available`, which Main adds because the store is not part of
## the save.
func setup(snapshot: Dictionary, tab: StringName) -> void:
	_snapshot = snapshot.duplicate(true)
	_tab = tab if tab in TABS else TAB_SHOP
	if is_node_ready():
		_rebuild()


## The page on screen.
func get_tab() -> StringName:
	return _tab


## The character previewed on CHARACTERS, or empty on SHOP.
func get_selected_id() -> StringName:
	return _selected_id() if _tab == TAB_WISPS else &""


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
	var characters: bool = _tab == TAB_WISPS
	_carousel_page.visible = characters
	_shop_page.visible = not characters
	if characters and not _cards_built:
		_build_cards()
	elif characters and not _selected_ids.has(TAB_WISPS):
		# A snapshot can arrive after the cards were built (fixtures add the screen before setting
		# it up). Until the player browses, the carousel follows the equipped character.
		_focus_selected_card()
	if characters:
		_sync_live_cards()
	_refresh()
	if characters:
		_carousel.grab_focus.call_deferred()


func _build_cards() -> void:
	_cards_built = true
	_items.assign(form_catalog.load_forms())
	_character_previews.clear()
	var cards: Array[Control] = []
	for item: Resource in _items:
		cards.append(_build_card(item as FormData))
	_syncing = true
	_carousel.set_cards(cards, _index_of(_selected_id()))
	_syncing = false
	_sync_live_cards()
	_dots.count = _items.size()


## Moves the carousel to the selected character without reporting it as a player pick.
func _focus_selected_card() -> void:
	_syncing = true
	_carousel.select(_index_of(_selected_id()), false)
	_syncing = false


func _on_carousel_selection_changed(index: int) -> void:
	if _syncing or index < 0 or index >= _items.size():
		return
	_selected_ids[TAB_WISPS] = (_items[index] as FormData).form_id
	_feedback_label.text = ""
	_sync_live_cards()
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_balance_label.text = RiftPoints.format(_balance())
	if _tab == TAB_SHOP:
		_refresh_shop()
		return
	var hollow := PackedInt32Array()
	for index: int in _items.size():
		_refresh_card(_carousel.get_card(index), _items[index] as FormData)
		if not _owns(_items[index] as FormData):
			hollow.append(index)
	_dots.hollow = hollow
	var selected_index: int = _index_of(_selected_id())
	if selected_index >= _items.size():
		_description_label.text = ""
		_action_button.text = "EQUIPPED"
		_action_button.disabled = true
		return
	var form := _items[selected_index] as FormData
	_description_label.text = form.description
	var price: int = maxi(0, form.price)
	var gate: String = _gate_reason(form)
	_action_button.icon = null
	if _owns(form):
		var equipped: bool = form.form_id == _equipped_id()
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


## The SHOP page: the Remove Ads offer, the item packs and the Rift Points packs.
func _refresh_shop() -> void:
	var ads_removed: bool = bool(_snapshot.get(&"ads_removed", false))
	var store: bool = _store_available()
	if ads_removed:
		_offer_status.text = "ADS REMOVED  •  THANK YOU"
		_offer_buy_button.text = "OWNED"
		_offer_buy_button.disabled = true
	elif not store:
		_offer_status.text = "THE STORE IS NOT OPEN YET"
		_offer_buy_button.text = "COMING SOON"
		_offer_buy_button.disabled = true
	else:
		var offer_price: String = _store_price(MonetisationService.PRODUCT_REMOVE_ADS)
		_offer_status.text = (
			"ONE-TIME PURCHASE" if offer_price.is_empty() else "ONE-TIME PURCHASE  •  %s" % offer_price
		)
		_offer_buy_button.text = "BUY"
		_offer_buy_button.disabled = false
	_restore_button.disabled = not store
	_item_page.setup(_snapshot)
	for button: Button in _pack_buttons.values():
		button.text = "BUY" if store else "COMING SOON"
		button.disabled = not store
	# Once Google Play answers, its own localized price replaces the placeholder (ADR-0030).
	for pack: RiftPointsPack in rift_points_packs.packs:
		if pack != null and _pack_prices.has(pack.product_id):
			var price: String = _store_price(pack.product_id)
			_pack_prices[pack.product_id].text = pack.price_label if price.is_empty() else price


## The store's price for a product, from the snapshot Main adds (`store_prices`), or empty.
func _store_price(product_id: StringName) -> String:
	var prices: Variant = _snapshot.get(&"store_prices", {})
	return str((prices as Dictionary).get(product_id, "")) if prices is Dictionary else ""


func _on_action_pressed() -> void:
	if _action_button.disabled or _tab != TAB_WISPS:
		return
	var index: int = _index_of(_selected_id())
	if index >= _items.size():
		return
	var form := _items[index] as FormData
	if _owns(form):
		equip_requested.emit(SaveManagerService.KIND_FORM, form.form_id)
	else:
		purchase_requested.emit(SaveManagerService.KIND_FORM, form.form_id)


# ------------------------------------------------------------------------ Rift Points packs

## Lets a touch swipe that starts on a card or button scroll the SHOP page, as in Settings (owner
## 2026-10-05: the Shop did not scroll on phones): every control under it that would stop the
## touch passes it on instead. Buttons still press on a tap.
func _pass_touches_to_scroll(node: Node) -> void:
	for child: Node in node.get_children():
		var control := child as Control
		if control != null and control.mouse_filter == Control.MOUSE_FILTER_STOP:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_touches_to_scroll(child)


## One card per pack: its picture, the Rift Points it gives, its price and a buy button.
func _build_pack_cards() -> void:
	for pack: RiftPointsPack in rift_points_packs.packs:
		if pack == null:
			continue
		var card := PanelContainer.new()
		card.name = "Pack_%s" % pack.product_id
		card.theme_type_variation = &"PanelCard"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.add_theme_constant_override(&"separation", 12)
		card.add_child(column)
		var icon := TextureRect.new()
		icon.texture = pack.icon if pack.icon != null else RP_ICON
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = PACK_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(icon)
		var amount := Label.new()
		amount.theme_type_variation = &"TitleLabel"
		amount.add_theme_font_size_override(&"font_size", 44)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.text = RiftPoints.format(pack.rift_points)
		column.add_child(amount)
		var price := Label.new()
		price.theme_type_variation = &"CaptionLabel"
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.text = pack.price_label
		column.add_child(price)
		_pack_prices[pack.product_id] = price
		var buy := Button.new()
		buy.name = "Buy"
		buy.theme_type_variation = &"PrimaryButton"
		buy.text = "COMING SOON"
		buy.disabled = true
		buy.pressed.connect(func() -> void: store_purchase_requested.emit(pack.product_id))
		column.add_child(buy)
		_pack_buttons[pack.product_id] = buy
		_pack_grid.add_child(card)


# ------------------------------------------------------------------------ character model

func _owned_ids() -> Array:
	var owned: Variant = _snapshot.get(&"owned_forms", [])
	return owned as Array if owned is Array else []


func _equipped_id() -> StringName:
	return StringName(str(_snapshot.get(&"equipped_form", String(FormCatalog.DEFAULT_FORM_ID))))


func _selected_id() -> StringName:
	return _selected_ids.get(TAB_WISPS, _equipped_id()) as StringName


func _owns(form: FormData) -> bool:
	return String(form.form_id) in _owned_ids()


## Why an unowned character cannot be bought yet, as the button text; empty when nothing gates it.
func _gate_reason(form: FormData) -> String:
	if form.requires_boss_victory and int(_snapshot.get(&"bosses_defeated", 0)) <= 0:
		return "BEAT A BOSS FIRST"
	return ""


func _index_of(form_id: StringName) -> int:
	for index: int in _items.size():
		if (_items[index] as FormData).form_id == form_id:
			return index
	return 0


func _balance() -> int:
	return maxi(0, int(_snapshot.get(&"rift_points", 0)))


func _store_available() -> bool:
	return bool(_snapshot.get(&"store_available", false))


func _reduced_motion() -> bool:
	var settings: Variant = _snapshot.get(&"settings", {})
	return settings is Dictionary and bool((settings as Dictionary).get(&"reduced_motion", false))


# ------------------------------------------------------------------------ cards

## One portrait card: name on top, the character in the middle, its state at the bottom.
func _build_card(item: FormData) -> Control:
	var card := Button.new()
	card.theme_type_variation = &"CardButton"
	card.name = "Card_%s" % item.form_id
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
	name_label.text = item.display_name
	column.add_child(name_label)

	var visual := MarginContainer.new()
	visual.name = "Visual"
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(visual)
	_add_form_visual(visual, item)

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
	var centre: int = _index_of(_selected_id())
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


func _refresh_card(card: Control, item: FormData) -> void:
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
	if item.form_id == _equipped_id() and owned:
		state_icon.texture = OWNED_ICON
		state_label.text = "EQUIPPED"
	elif owned:
		state_icon.texture = OWNED_ICON
		state_label.text = "OWNED"
	elif not gate.is_empty():
		state_icon.texture = REAPER_ICON
		state_label.text = "BOSS"
	else:
		state_icon.texture = RP_ICON
		state_label.text = RiftPoints.format(maxi(0, item.price))


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
