class_name RunItemHud
extends Control
## Ward inventory hint and icon/seconds indicators for the five timed pickup effects.

const TIMED_IDS: Array[StringName] = [RunItemCatalog.RIFT_MAGNET,
	RunItemCatalog.FORTUNE_STAR, RunItemCatalog.STILLGLASS,
	RunItemCatalog.REAPERS_EDGE, RunItemCatalog.ECHO_WISP]
var _stock_box: VBoxContainer
var _stock_label: Label
var _hint: Label
var _effects: HBoxContainer
var _board_hint: Label
var _cells: Dictionary[StringName, VBoxContainer] = {}
var _seconds: Dictionary[StringName, Label] = {}
var _icons: Dictionary[StringName, TextureRect] = {}
var _catalog: RunItemCatalog = preload("res://data/items/default_item_catalog.tres")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stock_box = VBoxContainer.new()
	_stock_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stock_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_stock_box)
	var ward := TextureRect.new()
	ward.texture = _catalog.get_item(RunItemCatalog.SOUL_WARD).get_icon()
	ward.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ward.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ward.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ward.custom_minimum_size = Vector2(72, 72)
	ward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stock_box.add_child(ward)
	_stock_label = _label(33)
	_stock_box.add_child(_stock_label)
	_hint = _label(22)
	_hint.text = "DOUBLE TAP"
	_stock_box.add_child(_hint)
	_board_hint = _label(22)
	add_child(_board_hint)
	_effects = HBoxContainer.new()
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effects.add_theme_constant_override(&"separation", 12)
	_effects.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_effects)
	for item_id: StringName in TIMED_IDS:
		var cell := VBoxContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_constant_override(&"separation", 0)
		_effects.add_child(cell)
		_cells[item_id] = cell
		var icon := TextureRect.new()
		icon.texture = _catalog.get_item(item_id).get_icon()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		_icons[item_id] = icon
		var seconds: Label = _label(22)
		cell.add_child(seconds)
		_seconds[item_id] = seconds
		cell.visible = false


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"ValueLabel"
	label.add_theme_font_size_override(&"font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Lays indicators out inside the ordinary HUD, or below the board's top hardware.
func fit(view: Vector2, safe: Vector4, floor_rect: Rect2, board: bool) -> void:
	if not is_node_ready():
		return
	_stock_box.position = Vector2(safe.x, safe.y + 130.0)
	_stock_box.size = Vector2(132, 150)
	_stock_box.visible = not board
	_effects.position = Vector2(view.x * 0.5 - 190.0,
		floor_rect.position.y + 10.0 if board else safe.y + 14.0)
	_effects.size = Vector2(380, 86)
	_board_hint.visible = board
	_board_hint.position = Vector2(view.x * 0.5 - 320.0, floor_rect.end.y + 10.0)
	_board_hint.size = Vector2(640, 26)
	for icon: TextureRect in _icons.values():
		icon.custom_minimum_size = Vector2.ONE * 64.0


## Refreshes stock and remaining seconds without rebuilding any controls.
func refresh(effects: RunItems, stock: int, ward_active: bool) -> void:
	if not is_node_ready():
		return
	_stock_label.text = "×%s" % RiftPoints.group_digits(stock)
	_hint.text = "PROTECTED" if ward_active else "DOUBLE TAP"
	_hint.visible = stock > 0 or ward_active
	_board_hint.text = "WARD ACTIVE" if ward_active else "WARD ×%s  •  DOUBLE TAP" % (
		RiftPoints.group_digits(stock)) if stock > 0 else "WARD ×0"
	for item_id: StringName in TIMED_IDS:
		var left: float = effects.get_remaining(item_id)
		_cells[item_id].visible = left > 0.0
		_seconds[item_id].text = "%ds" % int(ceil(left))


## Counter location for the tutorial's focus ring.
func get_stock_rect() -> Rect2:
	return _stock_box.get_global_rect()
