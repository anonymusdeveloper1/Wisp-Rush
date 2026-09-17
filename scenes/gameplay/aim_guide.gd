class_name AimGuide
extends Node2D
## The ×N combo count shown just past the aim arrow while two or more enemies are lit.
##
## Owned and fed by GameWorld from `WispPlayer.aim_preview_changed`. The owner kept the arrow and the
## lit-enemy rings but removed the dash-path line (2026-09-15), so nothing is drawn along the path;
## the path is still tracked because it decides the count. Static: Reduced Motion needs no case.
## Fewest lit enemies that show the count label.
const COUNT_MIN: int = 2
## Count label font size in design px (ValueLabel variation, size override only).
const COUNT_FONT_SIZE: int = 44
## How far past the arrow tip along the aim, and to its side, the label sits (design px).
const COUNT_AHEAD_OFFSET: float = 60.0
const COUNT_SIDE_OFFSET: float = 58.0
## Keeps the label this far inside the arena rect (design px).
const COUNT_EDGE_MARGIN: float = 12.0

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _count: int = 0
var _showing: bool = false
var _draw_scale: float = 1.0
var _count_label: Label
## Count the label text was last built for, so a steady aim does not rebuild the string every tick.
var _label_count: int = -1


func _ready() -> void:
	visible = false
	_count_label = Label.new()
	_count_label.name = "CountLabel"
	_count_label.theme_type_variation = &"ValueLabel"
	_count_label.add_theme_font_size_override(&"font_size", COUNT_FONT_SIZE)
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.visible = false
	add_child(_count_label)


## Shows the path [param from]→[param to] with [param count] lit enemies. [param bounds] keeps the
## count label on screen; [param draw_scale] is the viewport width / design width.
func show_path(from: Vector2, to: Vector2, count: int, bounds: Rect2, draw_scale: float) -> void:
	_from = from
	_to = to
	_count = count
	_draw_scale = maxf(0.5, draw_scale)
	_showing = true
	visible = true
	_update_count_label(bounds)


## Hides the count label.
func clear() -> void:
	if not _showing:
		return
	_showing = false
	_count = 0
	visible = false
	if _count_label != null:
		_count_label.visible = false


## Whether the path is currently shown, for tools.
func is_showing() -> bool:
	return _showing


## Lit-enemy count of the shown path (0 when hidden), for tools.
func get_count() -> int:
	return _count if _showing else 0


## Where the shown path ends: the landing, or the first dash-blocking hazard.
func get_end_point() -> Vector2:
	return _to


## The count label's text ("" when hidden), for tools.
func get_count_text() -> String:
	return _count_label.text if _count_label != null and _count_label.visible else ""


func _update_count_label(bounds: Rect2) -> void:
	if _count_label == null:
		return
	if _count < COUNT_MIN:
		_count_label.visible = false
		return
	if _label_count != _count:
		_label_count = _count
		_count_label.text = "×%d" % _count
		_count_label.reset_size()
	var direction: Vector2 = (_to - _from).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	# Sit just past the arrow tip, on the side facing the arena centre, so a wall never clips it.
	var side: Vector2 = direction.orthogonal()
	if bounds.has_area() and side.dot(bounds.get_center() - _from) < 0.0:
		side = -side
	var centre: Vector2 = (
		_from + direction * COUNT_AHEAD_OFFSET * _draw_scale + side * COUNT_SIDE_OFFSET * _draw_scale
	)
	var half: Vector2 = _count_label.size * 0.5
	if bounds.has_area():
		var margin: float = COUNT_EDGE_MARGIN * _draw_scale
		centre = centre.clamp(
			bounds.position + half + Vector2.ONE * margin,
			bounds.end - half - Vector2.ONE * margin,
		)
	_count_label.position = centre - half
	_count_label.visible = true
