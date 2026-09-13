class_name SanctumScreen
extends Control
## Soul Sanctum: the permanent upgrade tree bought with Soul Shards.
##
## Rows are generated from the SanctumCatalog, so re-costing or re-shaping the tree is a data
## change. The screen only reports intent; Main performs the purchase through SaveManager.

## The player left the Sanctum.
signal back_requested
## The player asked to buy one more level of a node.
signal purchase_requested(node_id: StringName)

const SLOT_SIZE := Vector2(132, 132)

## Ordered tree of permanent upgrades.
@export var catalog: SanctumCatalog

var _levels: Dictionary = {}
var _shards: int = 0
var _selected_id: StringName = &""
## Pending feedback message when show_feedback() ran before the node entered the tree.
var _pending_feedback: Array = []
var _group: ButtonGroup = ButtonGroup.new()

@onready var _list: VBoxContainer = %NodeList
@onready var _shard_count: Label = %ShardCount
@onready var _feedback: Label = %Feedback
@onready var _back_button: Button = %BackButton
@onready var _buy_button: Button = %BuyButton


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_buy_button.pressed.connect(_on_buy_pressed)
	_apply()
	if not _pending_feedback.is_empty():
		show_feedback(str(_pending_feedback[0]), bool(_pending_feedback[1]))
		_pending_feedback.clear()


## Rebuilds the tree from the player's shard balance and purchased levels.
##
## Safe before or after the screen enters the tree; see RiftMapScreen.setup() for why.
func setup(shards: int, levels: Dictionary) -> void:
	_shards = maxi(0, shards)
	_levels = levels.duplicate()
	if is_node_ready():
		_apply()


func _apply() -> void:
	_shard_count.text = str(_shards)
	_build_rows()
	_refresh_buy_button()


## Currently highlighted node, for tests and for the purchase caller.
func get_selected_node_id() -> StringName:
	return _selected_id


## Shows a transient result message under the tree.
func show_feedback(message: String, success: bool) -> void:
	if not is_node_ready():
		_pending_feedback = [message, success]
		return
	_feedback.text = message
	_feedback.theme_type_variation = &"AmberValueLabel" if success else &"CaptionLabel"
	if success:
		_feedback.add_theme_font_size_override(&"font_size", 30)


func _build_rows() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	if catalog == null:
		push_error("SanctumScreen has no SanctumCatalog")
		return
	var nodes: Array[SanctumNode] = catalog.load_nodes()
	if _selected_id.is_empty() and not nodes.is_empty():
		_selected_id = nodes[0].node_id
	for node: SanctumNode in nodes:
		_list.add_child(_build_row(node))


func _build_row(node: SanctumNode) -> Control:
	var level: int = int(_levels.get(String(node.node_id), 0))
	var unlocked: bool = catalog.is_unlocked(node, _levels)
	var maxed: bool = level >= node.max_level

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)

	var slot := Button.new()
	slot.theme_type_variation = &"SlotButton"
	slot.toggle_mode = true
	slot.button_group = _group
	slot.custom_minimum_size = SLOT_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.disabled = not unlocked or maxed
	slot.button_pressed = node.node_id == _selected_id
	if node.icon != null:
		slot.icon = node.icon
		slot.expand_icon = true
	else:
		slot.text = "%d/%d" % [level, node.max_level]
	slot.pressed.connect(_on_slot_pressed.bind(node.node_id))
	row.add_child(slot)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override(&"separation", 8)

	var title := Label.new()
	title.theme_type_variation = &"ValueLabel"
	title.add_theme_font_size_override(&"font_size", 36)
	title.text = "%s  %d/%d" % [node.display_name, level, node.max_level]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(title)

	var body := Label.new()
	body.theme_type_variation = &"CaptionLabel"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not unlocked:
		var required: SanctumNode = catalog.get_node_by_id(node.prerequisite_id)
		var required_name: String = required.display_name if required != null else "?"
		body.text = "SEALED — MASTER %s FIRST" % required_name
	elif maxed:
		body.text = "AWAKENED — %s" % node.get_next_description(node.max_level)
	else:
		body.text = "%s   •   %d SHARDS" % [
			node.get_next_description(level), node.get_cost(level),
		]
	info.add_child(body)

	row.add_child(info)
	row.modulate = Color.WHITE if unlocked else Color(1.0, 1.0, 1.0, 0.45)
	return row


func _refresh_buy_button() -> void:
	if catalog == null:
		return
	var node: SanctumNode = catalog.get_node_by_id(_selected_id)
	if node == null:
		_buy_button.disabled = true
		_buy_button.text = "AWAKEN"
		return
	var level: int = int(_levels.get(String(_selected_id), 0))
	var cost: int = node.get_cost(level)
	if cost < 0:
		_buy_button.disabled = true
		_buy_button.text = "%s AWAKENED" % node.display_name
	elif not catalog.is_unlocked(node, _levels):
		_buy_button.disabled = true
		_buy_button.text = "SEALED"
	else:
		_buy_button.disabled = _shards < cost
		_buy_button.text = "AWAKEN — %d" % cost


func _on_slot_pressed(node_id: StringName) -> void:
	_selected_id = node_id
	_feedback.text = ""
	_refresh_buy_button()


func _on_buy_pressed() -> void:
	if not _selected_id.is_empty():
		purchase_requested.emit(_selected_id)
