class_name StatisticsScreen
extends Control
## Lifetime statistics read from the persistent SaveManager snapshot.
##
## The first RECORD_COUNT rows of `build_rows` (best score, highest wave, longest chain) are shown
## as PanelCard tiles; the rest are CaptionLabel/ValueLabel rows in the lifetime panel.
## All styling comes from the project theme (redesign v1).

## Requests return to the Home screen.
signal back_requested

## Characters the collection row counts against.
const FORM_COUNT: int = FormCatalog.REQUIRED_FORM_COUNT
## Leading rows of `build_rows` shown as record tiles instead of list rows.
const RECORD_COUNT: int = 3
## Opacity of the void-charcoal shade over the menu background.
const SHADE_ALPHA: float = 0.4
const TILE_VALUE_FONT_SIZE: int = 52
const ROW_NAME_FONT_SIZE: int = 30
const ROW_VALUE_FONT_SIZE: int = 42
const _CARD_ORNAMENT: PackedScene = preload("res://assets/ui/theme/ornaments/card_top.tscn")

var _snapshot: Dictionary = {}

@onready var _shade: ColorRect = %Shade
@onready var _margin: MarginContainer = %Margin
@onready var _records_row: HBoxContainer = %RecordsRow
@onready var _grid: GridContainer = %StatsGrid
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_shade.color = Color(Palette.VOID_CHARCOAL, SHADE_ALPHA)
	_apply_safe_area()
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_rebuild()
	_back_button.grab_focus()
	print("[Statistics] ready")


## Supplies the persistent snapshot to display.
func setup(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if is_node_ready():
		_rebuild()


## Returns the displayed rows as `[name, value]` pairs for `snapshot`.
static func build_rows(snapshot: Dictionary) -> Array[PackedStringArray]:
	var owned_forms: Array = snapshot.get(&"owned_forms", ["void"]) as Array
	return [
		PackedStringArray(["BEST SCORE", "%06d" % int(snapshot.get(&"best_score", 0))]),
		PackedStringArray(["HIGHEST WAVE", "%02d" % int(snapshot.get(&"highest_wave", 1))]),
		PackedStringArray(["LONGEST SOUL CHAIN", "×%d" % int(snapshot.get(&"highest_combo", 0))]),
		PackedStringArray(["RUNS", str(int(snapshot.get(&"total_runs", 0)))]),
		PackedStringArray([
			"ENDLESS BEST SCORE", "%06d" % int(snapshot.get(&"endless_best_score", 0)),
		]),
		PackedStringArray([
			"ENDLESS BEST WAVE", "%02d" % int(snapshot.get(&"endless_best_wave", 0)),
		]),
		PackedStringArray(["ENDLESS RUNS", str(int(snapshot.get(&"endless_runs", 0)))]),
		PackedStringArray(["SOULS REAPED", str(int(snapshot.get(&"total_kills", 0)))]),
		PackedStringArray(["MULTI-REAP DASHES", str(int(snapshot.get(&"total_multi_kills", 0)))]),
		PackedStringArray(["REAPERS VANQUISHED", str(int(snapshot.get(&"bosses_defeated", 0)))]),
		PackedStringArray([
			"TIME IN THE RIFT",
			format_play_time(int(float(snapshot.get(&"play_time_seconds", 0.0)))),
		]),
		PackedStringArray(["RIFT POINTS", RiftPoints.format(int(snapshot.get(&"rift_points", 0)))]),
		PackedStringArray(["CHARACTERS COLLECTED", "%d / %d" % [owned_forms.size(), FORM_COUNT]]),
	]


## Formats whole seconds as `Xh YYm` or `Ym ZZs`.
static func format_play_time(seconds: int) -> String:
	var safe_seconds: int = maxi(0, seconds)
	var hours: int = safe_seconds / 3600
	var minutes: int = (safe_seconds % 3600) / 60
	if hours > 0:
		return "%dh %02dm" % [hours, minutes]
	return "%dm %02ds" % [minutes, safe_seconds % 60]


func _rebuild() -> void:
	for container: Container in [_records_row, _grid]:
		for child: Node in container.get_children():
			container.remove_child(child)
			child.queue_free()
	var rows: Array[PackedStringArray] = build_rows(_snapshot)
	for index: int in rows.size():
		if index < RECORD_COUNT:
			# The best score is the headline reward number, so it gets the amber treatment.
			_records_row.add_child(_make_tile(rows[index], index == 0))
		else:
			_grid.add_child(_make_row_label(rows[index][0], &"CaptionLabel", ROW_NAME_FONT_SIZE))
			var value: Label = _make_row_label(rows[index][1], &"ValueLabel", ROW_VALUE_FONT_SIZE)
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_grid.add_child(value)


func _make_tile(row: PackedStringArray, amber: bool) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.theme_type_variation = &"PanelCard"
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(_CARD_ORNAMENT.instantiate())
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 4)
	var value := Label.new()
	value.text = row[1]
	value.theme_type_variation = &"AmberValueLabel" if amber else &"ValueLabel"
	value.add_theme_font_size_override(&"font_size", TILE_VALUE_FONT_SIZE)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	var caption := Label.new()
	caption.text = row[0]
	caption.theme_type_variation = &"CaptionLabel"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(caption)
	tile.add_child(box)
	return tile


func _make_row_label(text: String, variation: StringName, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	return label


## Grows Margin by the device's safe-area insets (notches, home indicator) on phones.
func _apply_safe_area() -> void:
	if not OS.has_feature("mobile"):
		return
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return
	var to_view: Vector2 = get_viewport_rect().size / Vector2(window_size)
	var insets: Dictionary[StringName, float] = {
		&"margin_left": float(safe_area.position.x) * to_view.x,
		&"margin_top": float(safe_area.position.y) * to_view.y,
		&"margin_right": float(window_size.x - safe_area.end.x) * to_view.x,
		&"margin_bottom": float(window_size.y - safe_area.end.y) * to_view.y,
	}
	for key: StringName in insets:
		var base: int = _margin.get_theme_constant(key)
		_margin.add_theme_constant_override(key, base + maxi(0, roundi(insets[key])))
