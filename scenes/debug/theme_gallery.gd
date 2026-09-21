extends Control
## Debug screen showing every Wisp theme type variation (redesign v1) on the menu background.
##
## Run: Godot --path . res://scenes/debug/theme_gallery.tscn, or capture it with
## tools/screenshot.sh res://scenes/debug/theme_gallery.tscn 20. Built in code so each sample
## reads as a usage example: set theme_type_variation, never per-node style/colour overrides.
## "Focused" samples draw their focus stylebox permanently so all variants can be compared.

const ICON_DIR := "res://assets/art/ui/system/"
const FORM_DIR := "res://assets/art/characters/forms/"
const MUTATION := "res://assets/art/ui/mutations/01_wide_reap.png"
const ORNAMENTS := "res://assets/ui/theme/ornaments/"

@onready var _rows: VBoxContainer = %Rows


func _ready() -> void:
	_add_title()
	_add_banner()
	_add_button_grid()
	_add_slots()
	_add_cards()
	_add_panels()
	_add_bars()


func _add_title() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	row.add_child(_label("THEME GALLERY", &"TitleLabel"))
	var caption := _label("default Button = SecondaryButton", &"CaptionLabel")
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(caption)
	_rows.add_child(row)


func _add_banner() -> void:
	var center := CenterContainer.new()
	var banner := _panel(&"PanelBanner")
	banner.custom_minimum_size = Vector2(640, 0)
	banner.add_child(load(ORNAMENTS + "banner_top.tscn").instantiate())
	var title := _label("CHOOSE AN UPGRADE", &"TitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(title)
	center.add_child(banner)
	_rows.add_child(center)


func _add_button_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 24)
	grid.add_theme_constant_override(&"v_separation", 14)
	for head: String in ["", "normal", "focused", "disabled"]:
		grid.add_child(_label(head, &"CaptionLabel"))
	var variants: Array[Array] = [
		[&"PrimaryButton", "PLAY"],
		[&"SecondaryButton", "FORMS"],
		[&"DangerButton", "RESET"],
	]
	for v: Array in variants:
		var name_label := _label(String(v[0]), &"CaptionLabel")
		name_label.custom_minimum_size = Vector2(170, 0)
		grid.add_child(name_label)
		for state: int in 3:
			var b := _button(v[0], v[1])
			if state == 1:
				_show_focus(b)
			elif state == 2:
				b.disabled = true
			grid.add_child(b)
	# Pressed row: one sample per variation (toggled on = pressed stylebox).
	grid.add_child(_label("pressed", &"CaptionLabel"))
	for v: Array in variants:
		var b := _button(v[0], v[1])
		b.toggle_mode = true
		b.button_pressed = true
		grid.add_child(b)
	_rows.add_child(grid)


func _button(variation: StringName, text: String) -> Button:
	var b := Button.new()
	b.theme_type_variation = variation
	b.text = text
	b.custom_minimum_size = Vector2(236, 0)
	# Keep the native button height inside grid/box rows (rows would otherwise stretch it).
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


func _add_slots() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var icons := ["06_pause.png", "15_settings.png", "16_home.png"]
	for i: int in 3:
		var b := Button.new()
		b.theme_type_variation = &"IconButton"
		b.icon = load(ICON_DIR + icons[i])
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if i == 1:
			_show_focus(b)
		elif i == 2:
			b.disabled = true
		row.add_child(b)
	var forms := ["01_void.png", "06_eclipse.png"]
	for i: int in 3:
		var s := Button.new()
		s.theme_type_variation = &"SlotButton"
		s.custom_minimum_size = Vector2(160, 160)
		s.icon = load(FORM_DIR + forms[i])
		s.expand_icon = true
		s.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.toggle_mode = true
		if i == 1:
			s.button_pressed = true
		elif i == 2:
			s.disabled = true
		row.add_child(s)
	_rows.add_child(row)


func _add_cards() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i: int in 2:
		var card := Button.new()
		card.theme_type_variation = &"CardButton"
		card.custom_minimum_size = Vector2(210, 290)
		card.icon = load(MUTATION)
		card.expand_icon = true
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.text = "Wide Reap"
		card.toggle_mode = true
		card.button_pressed = i == 1
		row.add_child(card)
	var stat := _panel(&"PanelCard")
	stat.custom_minimum_size = Vector2(210, 290)
	stat.add_child(load(ORNAMENTS + "card_top.tscn").instantiate())
	var stat_box := _vbox()
	stat_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_box.add_child(_centered(_label("124", &"ValueLabel")))
	stat_box.add_child(_centered(_label("PanelCard", &"CaptionLabel")))
	stat.add_child(stat_box)
	row.add_child(stat)
	var ring := _panel(&"PortraitRing")
	ring.custom_minimum_size = Vector2(290, 290)
	var portrait := TextureRect.new()
	portrait.texture = load(FORM_DIR + "06_eclipse.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.add_child(portrait)
	row.add_child(ring)
	_rows.add_child(row)


func _add_panels() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	var crest := _panel(&"PanelCrest")
	crest.custom_minimum_size = Vector2(470, 330)
	crest.add_child(load(ORNAMENTS + "crest_top.tscn").instantiate())
	crest.add_child(load(ORNAMENTS + "crest_bottom.tscn").instantiate())
	var crest_box := _vbox()
	crest_box.alignment = BoxContainer.ALIGNMENT_CENTER
	crest_box.add_child(_centered(_label("PanelCrest · today's best", &"CaptionLabel")))
	crest_box.add_child(_centered(_label("8,420", &"AmberValueLabel")))
	crest.add_child(crest_box)
	row.add_child(crest)

	var right := _vbox()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override(&"separation", 30)
	var plain := PanelContainer.new()
	plain.add_child(load(ORNAMENTS + "amber_top.tscn").instantiate())
	var plain_box := _vbox()
	plain_box.add_child(_label("PanelContainer (default)", &""))
	plain_box.add_child(_label("Body text 30 px · caption muted", &"CaptionLabel"))
	plain.add_child(plain_box)
	right.add_child(plain)
	var plates := HBoxContainer.new()
	plates.add_theme_constant_override(&"separation", 16)
	var rift_points := _panel(&"PanelPlate")
	var rift_points_row := HBoxContainer.new()
	var rift_points_icon := TextureRect.new()
	rift_points_icon.texture = load(ICON_DIR + "02_soul_shards.png")
	rift_points_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rift_points_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rift_points_icon.custom_minimum_size = Vector2(44, 44)
	rift_points_row.add_child(rift_points_icon)
	var rift_points_value := _label(RiftPoints.format(320), &"ValueLabel")
	rift_points_value.add_theme_font_size_override(&"font_size", 40)
	rift_points_row.add_child(rift_points_value)
	rift_points.add_child(rift_points_row)
	plates.add_child(rift_points)
	var best := _panel(&"PanelPlate")
	var best_value := _label("12,480", &"AmberValueLabel")
	best_value.add_theme_font_size_override(&"font_size", 40)
	best.add_child(best_value)
	plates.add_child(best)
	right.add_child(plates)
	row.add_child(right)
	_rows.add_child(row)


func _add_bars() -> void:
	var bars: Array[Array] = [[&"", 65.0], [&"BossProgressBar", 40.0], [&"SlimProgressBar", 70.0]]
	for b: Array in bars:
		var bar := ProgressBar.new()
		bar.theme_type_variation = b[0]
		bar.value = b[1]
		bar.show_percentage = false
		_rows.add_child(_named_row(String(b[0]) if b[0] != &"" else "ProgressBar", bar))
	var slider := HSlider.new()
	slider.value = 55.0
	_rows.add_child(_named_row("HSlider", slider))
	_rows.add_child(_named_row("HSeparator", HSeparator.new()))


# ------------------------------------------------------------------------ helpers

func _label(text: String, variation: StringName) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


func _panel(variation: StringName) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p


func _vbox() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return v


func _centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _named_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)
	var l := _label(label_text, &"CaptionLabel")
	l.custom_minimum_size = Vector2(260, 0)
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	return row


## Draws the control's focus stylebox on top every frame, as Godot does for the focus owner.
func _show_focus(c: Control) -> void:
	c.draw.connect(func() -> void:
		c.draw_style_box(c.get_theme_stylebox(&"focus"), Rect2(Vector2.ZERO, c.size)))
