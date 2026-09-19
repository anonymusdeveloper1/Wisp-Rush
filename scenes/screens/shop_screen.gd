class_name ShopScreen
extends Control
## The Shop: the one place Rift Points are spent. Four tabs - CHARACTERS, DASHES, ARENAS, NO ADS.
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
const TAB_DASHES: StringName = &"dashes"
const TAB_ARENAS: StringName = &"arenas"
const TAB_NO_ADS: StringName = &"no_ads"
const TABS: Array[StringName] = [TAB_WISPS, TAB_DASHES, TAB_ARENAS, TAB_NO_ADS]

const RP_ICON: Texture2D = preload("res://assets/art/ui/system/02_soul_shards.png")
const LOCK_ICON: Texture2D = preload("res://assets/art/ui/system/17_lock.png")
const OWNED_ICON: Texture2D = preload("res://assets/art/ui/system/10_forms.png")
const REAPER_ICON: Texture2D = preload("res://assets/art/ui/system/18_reaper.png")
const DASH_TRAIL_SHORT: Texture2D = preload("res://assets/art/vfx/01_dash_trail_short.png")
const DASH_TRAIL_LONG: Texture2D = preload("res://assets/art/vfx/02_dash_trail_long.png")
## Brightness of an unowned item's visual, so ownership reads at a glance on every card.
## Badge colour per collectible tier; [constant FormData.Tier.STANDARD] shows no badge at all.
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
## Seconds per pulse of the animated dash preview (static under Reduced Motion).
const DASH_PREVIEW_PERIOD: float = 1.2
## Share of a CHARACTERS card's picture area a rigged character and a single-image form fill.
const CHARACTER_FILL: float = 0.94
const PORTRAIT_FILL: float = 0.9

@export var form_catalog: FormCatalog
@export var dash_style_catalog: DashStyleCatalog
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
var _preview_time: float = 0.0
## Trail and burst nodes of the DASHES cards, animated in `_process`.
var _dash_previews: Array[CanvasItem] = []
## Live character previews of the CHARACTERS cards by form id (rigs and animated portraits alike).
var _character_previews: Dictionary[StringName, PlayableCharacterPreview] = {}
var _tab_buttons: Dictionary[StringName, Button] = {}
## ARENAS card indices whose thumbnail is filled, and the card index they were last filled around.
var _arena_filled: Dictionary[int, bool] = {}
var _arena_centre: int = -1
## One scenery grade material per scenery, shared by every card that shows it.
var _scenery_materials: Dictionary[ArenaSceneryData, ShaderMaterial] = {}

@onready var _balance_label: Label = %BalanceLabel
@onready var _carousel_page: Control = %CarouselPage
@onready var _carousel: FocusCarousel = %Carousel
@onready var _dots: PageDots = %Dots
@onready var _tier_label: Label = %TierLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _requirement_label: Label = %RequirementLabel
@onready var _no_ads_page: Control = %NoAdsPage
@onready var _offer_status: Label = %OfferStatus
@onready var _offer_strike: ColorRect = %OfferStrike
@onready var _restore_button: Button = %RestoreButton
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _action_button: Button = %ActionButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	assert(form_catalog != null and dash_style_catalog != null and endless_catalog != null)
	# The offer emblem is Home's NO ADS glyph, not currency art: Remove Ads carries no Rift Points.
	_offer_strike.color = Palette.WARNING_AMBER
	# Main plays the purchase, equip or error sound for these, so SoundFx must not add a click.
	# BOUND_META rather than SKIP_META, which would also drop UiJuice's press dip.
	for button: Button in [_action_button, _restore_button]:
		button.set_meta(SoundFx.BOUND_META, true)
	_tab_buttons = {
		TAB_WISPS: %WispsTab as Button,
		TAB_DASHES: %DashesTab as Button,
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
	_carousel.selection_changed.connect(_on_carousel_selection_changed)
	_carousel.activated.connect(func(_index: int) -> void: _on_action_pressed())
	_rebuild()
	if not _pending_feedback.is_empty():
		show_feedback(str(_pending_feedback[0]), bool(_pending_feedback[1]))
		_pending_feedback.clear()
	print("[Shop] ready | tab=%s store=%s" % [_tab, _store_available()])


func _process(delta: float) -> void:
	_dots.position_value = _carousel.get_scroll()
	if _built_tab == TAB_ARENAS and _carousel_page.visible:
		_fill_arena_visuals(roundi(_carousel.get_scroll()))
	if _dash_previews.is_empty() or _reduced_motion():
		return
	_preview_time = fmod(_preview_time + delta, DASH_PREVIEW_PERIOD)
	var wave: float = 0.5 + 0.5 * sin(_preview_time / DASH_PREVIEW_PERIOD * TAU)
	for index: int in _dash_previews.size():
		var preview: CanvasItem = _dash_previews[index]
		if is_instance_valid(preview):
			# Even entries are trails, odd entries bursts: the burst flares as the trail fades.
			var phase: float = wave if index % 2 == 0 else 1.0 - wave
			preview.modulate.a = lerpf(0.35, 1.0, phase)


## Shows `tab` for a save snapshot. Safe before `_ready` (Main sets screens up before adding them).
##
## Reads `rift_points`, `owned_*` / `equipped_*` for forms, dash styles and arena skins,
## `bosses_defeated`, `rift_levels`, `ads_removed` and `settings`, plus `store_available`, which
## Main adds because the store is not part of the save.
func setup(snapshot: Dictionary, tab: StringName) -> void:
	var previous: Dictionary = _snapshot
	_snapshot = snapshot.duplicate(true)
	_tab = tab if tab in TABS else TAB_WISPS
	if is_node_ready():
		_rebuild()
		_celebrate_character_changes(previous)


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
	_carousel_page.visible = rp_tab
	_no_ads_page.visible = not rp_tab
	if rp_tab and _built_tab != _tab:
		_build_cards()
	elif rp_tab and not _selected_ids.has(_tab):
		# A snapshot can arrive after the cards were built (fixtures add the screen before setting it
		# up). Until the player browses this tab, its carousel follows the equipped item.
		_focus_selected_card()
	_refresh()
	if rp_tab:
		_carousel.grab_focus.call_deferred()


func _build_cards() -> void:
	_built_tab = _tab
	_items = _items_for(_tab)
	_dash_previews.clear()
	_character_previews.clear()
	_arena_filled.clear()
	_arena_centre = -1
	var cards: Array[Control] = []
	for item: Resource in _items:
		cards.append(_build_card(item))
	_syncing = true
	_carousel.set_cards(cards, _index_of(_selected_id(_tab)))
	_syncing = false
	_dots.count = _items.size()
	_play_selected_character_preview()
	if _tab == TAB_ARENAS:
		_fill_arena_visuals(_index_of(_selected_id(_tab)))


func _items_for(tab: StringName) -> Array[Resource]:
	var items: Array[Resource] = []
	match tab:
		TAB_WISPS:
			items.assign(form_catalog.load_forms())
		TAB_DASHES:
			for style: DashStyleData in dash_style_catalog.styles:
				if style != null:
					items.append(style)
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
	_refresh()
	_play_selected_character_preview()


func _refresh() -> void:
	if not is_node_ready():
		return
	_balance_label.text = RiftPoints.format(_balance())
	if _tab == TAB_NO_ADS:
		_refresh_no_ads()
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
	if _action_button.disabled:
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
	if item is DashStyleData:
		return SaveManagerService.KIND_DASH_STYLE
	if item is ArenaSkinData:
		return SaveManagerService.KIND_ARENA_SKIN
	return SaveManagerService.KIND_FORM


func _item_id(item: Resource) -> StringName:
	if item is DashStyleData:
		return (item as DashStyleData).style_id
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
		SaveManagerService.KIND_DASH_STYLE:
			key = &"owned_dash_styles"
		SaveManagerService.KIND_ARENA_SKIN:
			key = &"owned_arena_skins"
	var owned: Variant = _snapshot.get(key, [])
	return owned as Array if owned is Array else []


func _equipped_id(tab: StringName) -> StringName:
	match tab:
		TAB_DASHES:
			return StringName(str(_snapshot.get(
				&"equipped_dash_style", DashStyleCatalog.DEFAULT_STYLE_ID
			)))
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
		SaveManagerService.KIND_DASH_STYLE:
			return _item_id(item) == _equipped_id(TAB_DASHES)
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
	if item is FormData:
		_add_form_visual(visual, item as FormData)
	elif item is DashStyleData:
		_add_dash_visual(visual, item as DashStyleData)
	elif item is ArenaSkinData:
		_add_arena_visual(visual, column, item as ArenaSkinData)

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


## Every character card is alive: a rigged character plays its own rig, a single-image form idles
## on the shared rig. Both react when their card comes into focus.
func _add_form_visual(visual: Control, form: FormData) -> void:
	if _glow_texture == null:
		_glow_texture = _portrait_glow_texture()
	var glow := _texture_rect(_glow_texture, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	glow.name = "Glow"
	glow.self_modulate = Color(form.tint, 1.0)
	visual.add_child(glow)
	var preview := PlayableCharacterPreview.new()
	preview.name = "Portrait"
	preview.fill_ratio = CHARACTER_FILL if form.visual_scene != null else PORTRAIT_FILL
	preview.set_reduced_motion(_reduced_motion())
	visual.add_child(preview)
	if preview.set_form(form, true):
		_character_previews[form.form_id] = preview
	else:
		visual.remove_child(preview)
		preview.queue_free()
		var portrait := _texture_rect(form.texture, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		portrait.name = "Portrait"
		visual.add_child(portrait)


func _play_selected_character_preview() -> void:
	if _tab != TAB_WISPS:
		return
	var preview: PlayableCharacterPreview = _character_previews.get(_selected_id(_tab))
	if preview != null:
		preview.play_selected.call_deferred()


## After Main re-reads the save: a character bought just now plays its unlock flourish, one equipped
## just now its selected flourish.
func _celebrate_character_changes(previous: Dictionary) -> void:
	if previous.is_empty() or _built_tab != TAB_WISPS:
		return
	var before: Variant = previous.get(&"owned_forms", [])
	var owned_before: Array = before as Array if before is Array else []
	for form_id: Variant in _owned_ids(SaveManagerService.KIND_FORM):
		if form_id in owned_before:
			continue
		var bought: PlayableCharacterPreview = _character_previews.get(StringName(str(form_id)))
		if bought != null:
			bought.play_unlocked.call_deferred()
			return
	var equipped_before := StringName(str(previous.get(&"equipped_form", "void")))
	var equipped_now: StringName = _equipped_id(TAB_WISPS)
	if equipped_now != equipped_before:
		var equipped: PlayableCharacterPreview = _character_previews.get(equipped_now)
		if equipped != null:
			equipped.play_selected.call_deferred()


## A long trail with the launch burst at its head, in the style's tints (SOUL: the form's tint).
func _add_dash_visual(visual: Control, style: DashStyleData) -> void:
	var trail_tint: Color = _equipped_form_tint() if style.uses_form_tint else style.trail_tint
	var burst_tint: Color = _equipped_form_tint() if style.uses_form_tint else style.burst_tint
	var stack := Control.new()
	stack.name = "Portrait"
	visual.add_child(stack)
	var trail := _texture_rect(DASH_TRAIL_LONG, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	trail.set_anchors_preset(Control.PRESET_FULL_RECT)
	trail.self_modulate = trail_tint
	stack.add_child(trail)
	var burst := _texture_rect(DASH_TRAIL_SHORT, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	burst.set_anchors_preset(Control.PRESET_FULL_RECT)
	burst.anchor_left = 0.45
	burst.self_modulate = burst_tint
	stack.add_child(burst)
	_dash_previews.append(trail)
	_dash_previews.append(burst)


## An empty thumbnail frame, filled by `_fill_arena_visuals` once the card is near the focus,
## labelled with the skin's tier and where it plays.
func _add_arena_visual(visual: Control, column: VBoxContainer, skin: ArenaSkinData) -> void:
	var thumbnail := _texture_rect(null, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	thumbnail.name = "Portrait"
	visual.add_child(thumbnail)
	var where := Label.new()
	where.theme_type_variation = &"CaptionLabel"
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where.text = "%s  ·  PLAYS IN ENDLESS" % skin.get_tier_name()
	column.add_child(where)


## Fills the ARENAS cards within ARENA_VISUAL_RADIUS of [param centre]: the skin's small thumbnail
## (never the full-size background) with its static scenery grade (the animation plays only in a run).
func _fill_arena_visuals(centre: int) -> void:
	if centre == _arena_centre or _items.is_empty():
		return
	_arena_centre = centre
	var first: int = maxi(0, centre - ARENA_VISUAL_RADIUS)
	var last: int = mini(_items.size() - 1, centre + ARENA_VISUAL_RADIUS)
	for index: int in range(first, last + 1):
		var skin := _items[index] as ArenaSkinData
		var card: Control = _carousel.get_card(index)
		if skin == null or card == null or _arena_filled.has(index):
			continue
		var thumbnail := card.find_child("Portrait", true, false) as TextureRect
		if thumbnail == null:
			continue
		_arena_filled[index] = true
		thumbnail.texture = skin.thumbnail
		if skin.scenery != null:
			if not _scenery_materials.has(skin.scenery):
				_scenery_materials[skin.scenery] = ArenaAmbience.create_material(skin.scenery)
			thumbnail.material = _scenery_materials[skin.scenery]


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
	var visual := card.find_child("Portrait", true, false) as CanvasItem
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
