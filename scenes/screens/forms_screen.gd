class_name FormsScreen
extends Control
## Collection screen for previewing, purchasing and equipping gameplay-neutral Wisp forms.
##
## Redesign v1 layout (handoff board panel 4): header (Home IconButton, "FORMS" banner, shard
## plate), selected-form preview in a PortraitRing beside a detail card, a 3x2 SlotButton grid
## (toggled slot = magenta selection) and one persistent PrimaryButton action at the bottom.
## Locked forms stay previewable; lock state, price and the Reaper gate are always shown with an
## icon plus text, never by colour alone. Styling comes from the project theme variations.

## Requests a validated purchase through Main and SaveManager.
signal purchase_requested(form_id: StringName)
## Requests an owned form equip through Main and SaveManager.
signal equip_requested(form_id: StringName)
## Requests return to the Home screen.
signal back_requested

const SHARD_ICON: Texture2D = preload("res://assets/art/ui/system/02_soul_shards.png")
const LOCK_ICON: Texture2D = preload("res://assets/art/ui/system/17_lock.png")
const FORMS_ICON: Texture2D = preload("res://assets/art/ui/system/10_forms.png")
## Idle breathing of the preview portrait (style guide: 2-3 % scale), off with reduced motion.
const PULSE_AMOUNT: float = 0.02
const PULSE_SPEED: float = 2.2
## Native collection slot height and preview ring size (1080-wide design space, short phones).
const SLOT_BASE_HEIGHT: float = 300.0
const RING_BASE_SIZE: float = 420.0
## Taller phones grow the slots and ring by a share of the spare height, up to these caps; the
## rest goes to the spacers so the action button stays at the bottom.
const SLOT_MAX_GROW: float = 100.0
const RING_MAX_GROW: float = 60.0
const SLOT_GROW_SHARE: float = 0.25
const RING_GROW_SHARE: float = 0.15

@export var catalog: FormCatalog

var _forms: Array[FormData] = []
var _balance: int = 0
var _owned: Array[String] = ["void"]
var _equipped: StringName = &"void"
var _bosses_defeated: int = 0
var _selected_form_id: StringName = &""
var _animation_time: float = 0.0
## True once a form was picked explicitly; until then the preview follows the equipped form.
var _has_user_selection: bool = false

@onready var _safe_margin: MarginContainer = $SafeMargin
@onready var _content: VBoxContainer = %Content
@onready var _preview_ring: PanelContainer = %PreviewRing
@onready var _balance_label: Label = %BalanceLabel
@onready var _preview: TextureRect = %Preview
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _price_row: HBoxContainer = %PriceRow
@onready var _price_label: Label = %PriceLabel
@onready var _state_icon: TextureRect = %StateIcon
@onready var _requirement_label: Label = %RequirementLabel
@onready var _action_button: Button = %ActionButton
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _back_button: Button = %BackButton
@onready var _form_buttons: Array[Button] = [
	%FormButton0,
	%FormButton1,
	%FormButton2,
	%FormButton3,
	%FormButton4,
	%FormButton5,
]


func _ready() -> void:
	assert(catalog != null, "FormsScreen requires a FormCatalog")
	_forms = catalog.load_forms()
	assert(_forms.size() == _form_buttons.size(), "FormsScreen requires six forms")
	for index: int in _form_buttons.size():
		var button: Button = _form_buttons[index]
		button.pressed.connect(_select_form.bind(_forms[index].form_id))
	_action_button.pressed.connect(_on_action_pressed)
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_preview.resized.connect(func() -> void: _preview.pivot_offset = _preview.size * 0.5)
	set_process(not _is_reduced_motion())
	if _selected_form_id.is_empty():
		_selected_form_id = _equipped
	_refresh()
	# Deferred: autowrap labels only report their real height after the first layout pass.
	_fit_layout.call_deferred()
	# Deferred so a setup() right after add_child moves focus to the equipped form's slot.
	_focus_selected_slot.call_deferred()
	print("[Forms] ready | collection=%d" % _forms.size())


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_fit_layout.call_deferred()


func _process(delta: float) -> void:
	_animation_time += delta
	var pulse: float = 1.0 + sin(_animation_time * PULSE_SPEED) * PULSE_AMOUNT
	_preview.scale = Vector2.ONE * pulse


## Refreshes balance, ownership, equip and boss-gate state from a persistent snapshot.
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
		_refresh()


## Selects any valid form for preview, including locked forms.
func select_form(form_id: StringName) -> void:
	_select_form(form_id)


## Returns the currently previewed persistent identifier for tests and screen coordination.
func get_selected_form_id() -> StringName:
	return _selected_form_id


## Presents a short purchase/equip result without owning persistence decisions.
func show_feedback(message: String, success: bool) -> void:
	_feedback_label.text = message
	_feedback_label.modulate = Palette.SOUL_CYAN if success else Palette.WARNING_AMBER


func _select_form(form_id: StringName) -> void:
	if catalog.get_form(form_id).form_id != form_id:
		return
	_selected_form_id = form_id
	_has_user_selection = true
	if is_node_ready():
		_refresh()


## Grows slots and the preview ring into the spare height of tall phones (1917-2340 design px).
func _fit_layout() -> void:
	_apply_flexible_sizes(0.0, 0.0)
	var margins: int = (
		_safe_margin.get_theme_constant(&"margin_top")
		+ _safe_margin.get_theme_constant(&"margin_bottom")
	)
	var spare: float = maxf(0.0, size.y - margins - _content.get_combined_minimum_size().y)
	_apply_flexible_sizes(
		minf(spare * SLOT_GROW_SHARE, SLOT_MAX_GROW),
		minf(spare * RING_GROW_SHARE, RING_MAX_GROW),
	)


func _apply_flexible_sizes(slot_grow: float, ring_grow: float) -> void:
	for button: Button in _form_buttons:
		button.custom_minimum_size.y = SLOT_BASE_HEIGHT + slot_grow
	_preview_ring.custom_minimum_size = Vector2.ONE * (RING_BASE_SIZE + ring_grow)


func _refresh() -> void:
	if not is_node_ready():
		return
	var selected: FormData = catalog.get_form(_selected_form_id)
	_preview.texture = selected.texture
	_name_label.text = selected.display_name
	_name_label.modulate = selected.tint
	_description_label.text = selected.description
	_balance_label.text = "%d" % _balance
	_feedback_label.text = ""
	for index: int in _forms.size():
		_refresh_slot(_form_buttons[index], _forms[index])
	var is_owned: bool = String(selected.form_id) in _owned
	_price_row.visible = not is_owned
	_price_label.text = "%d" % selected.price
	_action_button.icon = null
	if is_owned:
		var is_equipped: bool = selected.form_id == _equipped
		_state_icon.texture = FORMS_ICON
		_requirement_label.text = "EQUIPPED" if is_equipped else "OWNED  ·  READY TO EQUIP"
		_action_button.text = "EQUIPPED" if is_equipped else "EQUIP"
		_action_button.disabled = is_equipped
	elif _is_boss_locked(selected):
		_state_icon.texture = LOCK_ICON
		_requirement_label.text = "LOCKED  ·  DEFEAT THE REAPER"
		_action_button.icon = LOCK_ICON
		_action_button.text = "REAPER REQUIRED"
		_action_button.disabled = true
	elif _balance < selected.price:
		_state_icon.texture = LOCK_ICON
		_requirement_label.text = "LOCKED  ·  %d MORE SHARDS NEEDED" % (selected.price - _balance)
		_action_button.icon = SHARD_ICON
		_action_button.text = "CLAIM  %d" % selected.price
		_action_button.disabled = true
	else:
		_state_icon.texture = SHARD_ICON
		_requirement_label.text = "READY TO CLAIM"
		_action_button.icon = SHARD_ICON
		_action_button.text = "CLAIM  %d" % selected.price
		_action_button.disabled = false


## Portrait, name, state line and lock badge of one collection slot.
func _refresh_slot(button: Button, form: FormData) -> void:
	var owned: bool = String(form.form_id) in _owned
	var state: String = "OWNED"
	if form.form_id == _equipped:
		state = "EQUIPPED"
	elif not owned:
		state = "REAPER" if _is_boss_locked(form) else "%d" % form.price
	button.icon = form.texture
	button.text = "%s\n%s" % [form.display_name, state]
	button.tooltip_text = "%s  ·  %s" % [form.display_name, "OWNED" if owned else "LOCKED"]
	button.set_pressed_no_signal(form.form_id == _selected_form_id)
	(button.get_node(^"LockBadge") as TextureRect).visible = not owned


func _focus_selected_slot() -> void:
	if is_inside_tree():
		_form_buttons[_index_of(_selected_form_id)].grab_focus()


func _is_boss_locked(form: FormData) -> bool:
	return form.requires_boss_victory and _bosses_defeated <= 0


func _index_of(form_id: StringName) -> int:
	for index: int in _forms.size():
		if _forms[index].form_id == form_id:
			return index
	return 0


func _is_reduced_motion() -> bool:
	var save_manager := get_node_or_null(^"/root/SaveManager") as SaveManagerService
	if save_manager == null:
		return false
	return bool(save_manager.get_settings().get(&"reduced_motion", false))


func _on_action_pressed() -> void:
	var selected: FormData = catalog.get_form(_selected_form_id)
	if String(selected.form_id) in _owned:
		equip_requested.emit(selected.form_id)
	else:
		purchase_requested.emit(selected.form_id)
