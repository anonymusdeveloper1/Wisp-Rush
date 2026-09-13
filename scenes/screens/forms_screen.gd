class_name FormsScreen
extends Control
## Wisp picker: a portrait card carousel of the six gameplay-neutral forms, buy or equip below.
##
## Owner reference (2026-09-13): a focus card picker - the selected card is larger, lifted and
## framed, its neighbours peek in dimmed, one description line sits underneath and a single main
## action is at the bottom. Swipe or tap a side card to browse; tapping the focused card runs the
## action. Locked forms stay previewable; lock state, price and the Reaper gate are always shown
## with text as well as colour. Styling comes from the project theme variations.

## Requests a validated purchase through Main and SaveManager.
signal purchase_requested(form_id: StringName)
## Requests an owned form equip through Main and SaveManager.
signal equip_requested(form_id: StringName)
## Requests return to the Home screen.
signal back_requested

const SHARD_ICON: Texture2D = preload("res://assets/art/ui/system/02_soul_shards.png")
const LOCK_ICON: Texture2D = preload("res://assets/art/ui/system/17_lock.png")
const FORMS_ICON: Texture2D = preload("res://assets/art/ui/system/10_forms.png")
const REAPER_ICON: Texture2D = preload("res://assets/art/ui/system/18_reaper.png")
## Brightness of a locked form's portrait, so ownership reads at a glance on every card.
const LOCKED_PORTRAIT_BRIGHTNESS: float = 0.42
## Card text sizes in the 1080-wide design space.
const CARD_NAME_SIZE: int = 44
const CARD_STATE_SIZE: int = 34
const STATE_ICON_SIZE := Vector2(48, 48)
## Soft halo in the form's own tint behind its portrait, so each card carries the form's colour.
const PORTRAIT_GLOW_ALPHA: float = 0.42
const LOCKED_GLOW_ALPHA: float = 0.14

@export var catalog: FormCatalog

var _forms: Array[FormData] = []
var _balance: int = 0
var _owned: Array[String] = ["void"]
var _equipped: StringName = &"void"
var _bosses_defeated: int = 0
var _selected_form_id: StringName = &""
## True once a form was picked explicitly; until then the carousel follows the equipped form.
var _has_user_selection: bool = false
var _pending_feedback: Array = []
## True while the screen itself moves the carousel, so that move is not mistaken for a player pick.
var _syncing: bool = false
var _glow_texture: GradientTexture2D

@onready var _carousel: FocusCarousel = %Carousel
@onready var _dots: PageDots = %Dots
@onready var _balance_label: Label = %BalanceLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _requirement_label: Label = %RequirementLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _action_button: Button = %ActionButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	assert(catalog != null, "FormsScreen requires a FormCatalog")
	_forms = catalog.load_forms()
	_action_button.pressed.connect(_on_action_pressed)
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_carousel.selection_changed.connect(_on_carousel_selection_changed)
	_carousel.activated.connect(func(_index: int) -> void: _on_action_pressed())
	_dots.count = _forms.size()
	var cards: Array[Control] = []
	for form: FormData in _forms:
		cards.append(_build_card(form))
	if _selected_form_id.is_empty():
		_selected_form_id = _equipped
	_carousel.set_cards(cards, _index_of(_selected_form_id))
	_refresh()
	if not _pending_feedback.is_empty():
		show_feedback(str(_pending_feedback[0]), bool(_pending_feedback[1]))
		_pending_feedback.clear()
	_carousel.grab_focus.call_deferred()
	print("[Forms] ready | collection=%d" % _forms.size())


func _process(_delta: float) -> void:
	_dots.position_value = _carousel.get_scroll()


## Refreshes balance, ownership, equip and boss-gate state from a persistent snapshot.
##
## Safe before or after the screen enters the tree (Main configures screens straight after
## instancing them, while @onready references are still null).
func setup(balance: int, owned: Array, equipped: StringName, bosses_defeated: int) -> void:
	_balance = maxi(0, balance)
	_owned.clear()
	for value: Variant in owned:
		var form_id: String = str(value)
		if form_id not in _owned:
			_owned.append(form_id)
	if "void" not in _owned:
		_owned.push_front("void")
	_equipped = equipped if String(equipped) in _owned else &"void"
	_bosses_defeated = maxi(0, bosses_defeated)
	if not _has_user_selection:
		_selected_form_id = _equipped
	if is_node_ready():
		_syncing = true
		_carousel.select(_index_of(_selected_form_id), false)
		_syncing = false
		_refresh()


## Selects any valid form for preview, including locked forms.
func select_form(form_id: StringName) -> void:
	if catalog.get_form(form_id).form_id != form_id:
		return
	_selected_form_id = form_id
	_has_user_selection = true
	if is_node_ready():
		_carousel.select(_index_of(form_id))
		_refresh()


## Returns the currently previewed persistent identifier for tests and screen coordination.
func get_selected_form_id() -> StringName:
	return _selected_form_id


## Presents a short purchase/equip result without owning persistence decisions.
func show_feedback(message: String, success: bool) -> void:
	if not is_node_ready():
		_pending_feedback = [message, success]
		return
	_feedback_label.text = message
	_feedback_label.modulate = Palette.SOUL_CYAN if success else Palette.WARNING_AMBER


func _on_carousel_selection_changed(index: int) -> void:
	if _syncing or index < 0 or index >= _forms.size():
		return
	_selected_form_id = _forms[index].form_id
	_has_user_selection = true
	_feedback_label.text = ""
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	var selected: FormData = catalog.get_form(_selected_form_id)
	_balance_label.text = "%d" % _balance
	_description_label.text = selected.description
	var hollow := PackedInt32Array()
	for index: int in _forms.size():
		_refresh_card(_carousel.get_card(index), _forms[index])
		if String(_forms[index].form_id) not in _owned:
			hollow.append(index)
	_dots.hollow = hollow
	var is_owned: bool = String(selected.form_id) in _owned
	_action_button.icon = null
	if is_owned:
		var is_equipped: bool = selected.form_id == _equipped
		_requirement_label.text = "YOUR ACTIVE FORM" if is_equipped else "OWNED  ·  READY TO EQUIP"
		_action_button.text = "EQUIPPED" if is_equipped else "EQUIP"
		_action_button.disabled = is_equipped
	elif _is_boss_locked(selected):
		_requirement_label.text = "LOCKED  ·  DEFEAT THE REAPER"
		_action_button.icon = LOCK_ICON
		_action_button.text = "REAPER REQUIRED"
		_action_button.disabled = true
	elif _balance < selected.price:
		_requirement_label.text = "LOCKED  ·  %d MORE SHARDS NEEDED" % (selected.price - _balance)
		_action_button.icon = SHARD_ICON
		_action_button.text = "CLAIM  %d" % selected.price
		_action_button.disabled = true
	else:
		_requirement_label.text = "READY TO CLAIM"
		_action_button.icon = SHARD_ICON
		_action_button.text = "CLAIM  %d" % selected.price
		_action_button.disabled = false


## One portrait card: name on top, the form in the middle, its ownership state at the bottom.
func _build_card(form: FormData) -> Control:
	var card := Button.new()
	card.theme_type_variation = &"CardButton"
	card.name = "Card_%s" % form.form_id
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
	name_label.name = "Name"
	name_label.theme_type_variation = &"TitleLabel"
	name_label.add_theme_font_size_override(&"font_size", CARD_NAME_SIZE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = form.display_name
	column.add_child(name_label)

	var portrait_area := MarginContainer.new()
	portrait_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(portrait_area)
	if _glow_texture == null:
		_glow_texture = _portrait_glow_texture()
	var glow := TextureRect.new()
	glow.name = "Glow"
	glow.texture = _glow_texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.self_modulate = Color(form.tint, 1.0)
	portrait_area.add_child(glow)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = form.texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_area.add_child(portrait)

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


func _refresh_card(card: Control, form: FormData) -> void:
	if card == null:
		return
	var owned: bool = String(form.form_id) in _owned
	var portrait := card.find_child("Portrait", true, false) as TextureRect
	var state_icon := card.find_child("StateIcon", true, false) as TextureRect
	var state_label := card.find_child("State", true, false) as Label
	var glow := card.find_child("Glow", true, false) as TextureRect
	var brightness: float = 1.0 if owned else LOCKED_PORTRAIT_BRIGHTNESS
	portrait.modulate = Color(brightness, brightness, brightness, 1.0)
	glow.modulate.a = PORTRAIT_GLOW_ALPHA if owned else LOCKED_GLOW_ALPHA
	if form.form_id == _equipped:
		state_icon.texture = FORMS_ICON
		state_label.text = "EQUIPPED"
	elif owned:
		state_icon.texture = FORMS_ICON
		state_label.text = "OWNED"
	elif _is_boss_locked(form):
		state_icon.texture = REAPER_ICON
		state_label.text = "REAPER"
	else:
		state_icon.texture = SHARD_ICON
		state_label.text = "%d" % form.price


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


func _is_boss_locked(form: FormData) -> bool:
	return form.requires_boss_victory and _bosses_defeated <= 0


func _index_of(form_id: StringName) -> int:
	for index: int in _forms.size():
		if _forms[index].form_id == form_id:
			return index
	return 0


func _on_action_pressed() -> void:
	if _action_button.disabled:
		return
	var selected: FormData = catalog.get_form(_selected_form_id)
	if String(selected.form_id) in _owned:
		equip_requested.emit(selected.form_id)
	else:
		purchase_requested.emit(selected.form_id)
