class_name RunItemShopPage
extends VBoxContainer
## Purchasable pickup packs, owned stock and the single selected next-run starting boost: the ITEMS
## section of the Shop's SHOP page, which scrolls it with the other sections (owner 2026-10-05).

## Purchase intent only; Main saves the validated pack and re-reads the snapshot.
signal pack_requested(item_id: StringName, quantity: int)
## Selects one owned next-run boost; empty clears the selection without consuming a copy.
signal starting_item_selected(item_id: StringName)

const CATALOG: RunItemCatalog = preload("res://data/items/default_item_catalog.tres")
var _snapshot: Dictionary = {}
var _stock_labels: Dictionary[StringName, Label] = {}
var _buy_buttons: Dictionary[StringName, Array] = {}
var _boost_buttons: Dictionary[StringName, Button] = {}


func _ready() -> void:
	add_theme_constant_override(&"separation", 20)
	var caption: Label = _label("BUY COPIES WITH RP", 33, &"TitleLabel")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(caption)
	for item: RunItemData in CATALOG.get_shop_items():
		add_child(_build_card(item))
	_refresh()


## Refreshes affordability and stock after purchases without resetting the scroll position.
func setup(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if is_node_ready():
		_refresh()


func _build_card(item: RunItemData) -> Control:
	var card := PanelContainer.new()
	card.name = "Item_%s" % item.item_id
	card.theme_type_variation = &"PanelCard"
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	card.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 16)
	column.add_child(header)
	var icon := TextureRect.new()
	icon.texture = item.get_icon()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(128, 128)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(copy)
	copy.add_child(_label(item.display_name, 44, &"TitleLabel"))
	var stock: Label = _label("", 33, &"ValueLabel")
	stock.name = "Stock"
	copy.add_child(stock)
	_stock_labels[item.item_id] = stock
	var description: Label = _label(item.description, 33, &"")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	var packs := HBoxContainer.new()
	packs.add_theme_constant_override(&"separation", 12)
	column.add_child(packs)
	var buttons: Array[Button] = []
	for quantity: int in RunItemCatalog.PACK_SIZES:
		var button := Button.new()
		button.name = "Pack_%d" % quantity
		button.theme_type_variation = &"SecondaryButton"
		button.add_theme_font_size_override(&"font_size", 33)
		button.custom_minimum_size = Vector2(0, 110)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "×%d\n%s" % [quantity,
			RiftPoints.format(CATALOG.get_pack_price(item.item_id, quantity))]
		button.set_meta(SoundFx.BOUND_META, true)
		button.pressed.connect(func() -> void: pack_requested.emit(item.item_id, quantity))
		packs.add_child(button)
		buttons.append(button)
	_buy_buttons[item.item_id] = buttons
	if item.starting_boost:
		var boost := Button.new()
		boost.theme_type_variation = &"SecondaryButton"
		boost.custom_minimum_size.y = 96
		boost.add_theme_font_size_override(&"font_size", 33)
		boost.set_meta(SoundFx.BOUND_META, true)
		boost.pressed.connect(_on_boost_pressed.bind(item.item_id))
		column.add_child(boost)
		_boost_buttons[item.item_id] = boost
		column.add_child(_label("ONE COPY AT RUN START  •  %ds" % item.duration_seconds,
			22, &"CaptionLabel"))
	else:
		column.add_child(_label("DOUBLE TAP DURING PLAY TO USE ONE", 22, &"CaptionLabel"))
	return card


func _refresh() -> void:
	var stock: Dictionary = _snapshot.get(&"item_stock", {}) as Dictionary
	var balance: int = maxi(0, int(_snapshot.get(&"rift_points", 0)))
	var selected := StringName(str(_snapshot.get(&"next_run_item", "")))
	for item: RunItemData in CATALOG.get_shop_items():
		var count: int = int(stock.get(String(item.item_id), 0))
		_stock_labels[item.item_id].text = "OWNED ×%s" % RiftPoints.group_digits(count)
		var buttons: Array = _buy_buttons[item.item_id]
		for index: int in RunItemCatalog.PACK_SIZES.size():
			var button := buttons[index] as Button
			button.disabled = balance < CATALOG.get_pack_price(
				item.item_id, RunItemCatalog.PACK_SIZES[index])
		if item.starting_boost:
			var boost: Button = _boost_buttons[item.item_id]
			boost.text = "CANCEL NEXT-RUN BOOST" if selected == item.item_id else "USE NEXT RUN"
			boost.disabled = count <= 0 and selected != item.item_id


func _on_boost_pressed(item_id: StringName) -> void:
	var selected := StringName(str(_snapshot.get(&"next_run_item", "")))
	starting_item_selected.emit(&"" if selected == item_id else item_id)


func _label(text: String, font_size: int, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.add_theme_font_size_override(&"font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
