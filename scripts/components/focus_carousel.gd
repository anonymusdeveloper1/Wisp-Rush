class_name FocusCarousel
extends Control
## Portrait card picker: one large focused card in the centre, its neighbours peeking in dimmed.
##
## Shared by the Forms and Rift Map screens (owner reference: a focus card picker where the selected
## card is bigger, lifted and framed). Screens supply the cards; this component owns layout, motion
## and input. Swipe sideways to move between cards and release to snap; a flick advances one card;
## tapping a side card focuses it; tapping the focused card emits `activated`. Left/right keys and
## ui_accept work when it has keyboard focus.
##
## Input is read from mouse events only. On a phone Godot delivers every touch as an emulated mouse
## event first (`emulate_mouse_from_touch`), so handling screen-touch events as well would act twice.

## The focused card changed, by swipe, tap, key or `select()`.
signal selection_changed(index: int)
## The already-focused card was tapped, or ui_accept was pressed.
signal activated(index: int)

## Width of the focused card as a fraction of the carousel's width.
@export_range(0.3, 0.95, 0.01) var focus_width_share: float = 0.64
## When the carousel is taller than the card needs, the card widens up to this share of the width,
## so spare height becomes a bigger card rather than empty space. At or below focus_width_share
## the card keeps its preferred width.
@export_range(0.0, 0.95, 0.01) var max_width_share: float = 0.0
## Card height divided by card width.
@export_range(0.8, 2.5, 0.01) var card_aspect: float = 1.46
## When there is still spare height with the card at its widest, it grows taller up to this
## height-to-width ratio. At or below card_aspect the card keeps card_aspect exactly.
@export_range(0.0, 2.5, 0.01) var max_card_aspect: float = 0.0
## Distance between neighbouring card centres, as a fraction of the focused card's width.
@export_range(0.4, 1.4, 0.01) var pitch_share: float = 0.9
## Scale of a card one step away from focus.
@export_range(0.4, 1.0, 0.01) var side_scale: float = 0.8
## Brightness of a card one step away from focus.
@export_range(0.1, 1.0, 0.01) var side_brightness: float = 0.5
## How far the focused card rises above its neighbours, as a fraction of its height.
@export_range(0.0, 0.2, 0.005) var lift_share: float = 0.035
## Snap speed toward the target card; higher settles faster.
@export_range(1.0, 60.0, 0.5) var snap_speed: float = 13.0
## Movement, in pixels and in any direction, below which a press and release counts as a tap.
## Sideways movement past it starts a swipe; any other movement past it just cancels the tap.
@export_range(2.0, 80.0, 1.0) var tap_slop: float = 22.0
## Release speed, in cards per second, that turns a short drag into a one-card flick.
@export_range(0.5, 20.0, 0.1) var flick_speed: float = 2.4

## A finger held still longer than this before release has stopped: the release is not a flick.
const FLICK_IDLE_MSEC: int = 80

var _cards: Array[Control] = []
var _selected: int = 0
## Continuous scroll position in card indices; integer values are fully focused cards.
var _scroll: float = 0.0
var _pressing: bool = false
var _moved: bool = false
## The pointer strayed past tap_slop without swiping, so the release must not count as a tap.
var _tap_void: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _press_scroll: float = 0.0
var _last_motion_msec: int = 0
var _last_motion_x: float = 0.0
## Recent drag velocity in cards per second, used to detect a flick on release.
var _velocity: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	resized.connect(_layout)
	_layout()


func _notification(what: int) -> void:
	# When the app loses focus mid-press (a call, a notification shade, app switch) the viewport
	# drops mouse focus and the release never reaches this control, so end the press here rather
	# than leave the carousel frozen between cards.
	match what:
		NOTIFICATION_EXIT_TREE, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_cancel_press()
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_cancel_press()


func _process(delta: float) -> void:
	if _pressing:
		return
	var target: float = float(_selected)
	if is_equal_approx(_scroll, target):
		set_process(false)
		return
	# Exponential approach: frame-rate independent, and it can never overshoot.
	_scroll = lerpf(_scroll, target, 1.0 - exp(-snap_speed * delta))
	if absf(_scroll - target) < 0.0015:
		_scroll = target
	_layout()


func _gui_input(event: InputEvent) -> void:
	if _cards.is_empty():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed:
			_begin_press(button.position)
		elif _pressing:
			# A cancelled touch (system gesture, overlay) is not the player lifting a finger, so it
			# must never buy a form or start a run.
			if button.canceled:
				_cancel_press()
			else:
				_end_press(button.position)
		accept_event()
	elif event is InputEventMouseMotion and _pressing:
		_drag_to((event as InputEventMouseMotion).position)
		accept_event()
	elif event.is_action_pressed(&"ui_left"):
		select(_selected - 1)
		accept_event()
	elif event.is_action_pressed(&"ui_right"):
		select(_selected + 1)
		accept_event()
	elif event.is_action_pressed(&"ui_accept"):
		activated.emit(_selected)
		accept_event()


## Replaces the cards. They become children of the carousel and are laid out by it.
##
## Cards should not take mouse input themselves - the carousel needs every press to tell a swipe
## from a tap - so their mouse filter is set to ignore. A card that is a BaseButton is switched to
## toggle mode and shows its pressed style while focused, which is how the theme's CardButton
## renders the magenta selection frame.
func set_cards(cards: Array[Control], selected_index: int = 0) -> void:
	for old: Control in _cards:
		if is_instance_valid(old) and old.get_parent() == self:
			remove_child(old)
			old.queue_free()
	_cards = cards.duplicate()
	for card: Control in _cards:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE
		_ignore_mouse_recursive(card)
		if card is BaseButton:
			(card as BaseButton).toggle_mode = true
		add_child(card)
	_selected = clampi(selected_index, 0, maxi(0, _cards.size() - 1))
	_scroll = float(_selected)
	_layout()


## Focuses a card. Out-of-range indices clamp to the ends; nothing wraps.
func select(index: int, animate: bool = true) -> void:
	if _cards.is_empty():
		return
	var clamped: int = clampi(index, 0, _cards.size() - 1)
	var changed: bool = clamped != _selected
	_selected = clamped
	if not animate:
		_scroll = float(_selected)
	_layout()
	set_process(true)
	if changed:
		selection_changed.emit(_selected)


## Index of the focused card.
func get_selected_index() -> int:
	return _selected


## Number of cards currently in the carousel.
func get_card_count() -> int:
	return _cards.size()


## Card at index, or null when the index is out of range.
func get_card(index: int) -> Control:
	return _cards[index] if index >= 0 and index < _cards.size() else null


## Continuous scroll position, for page indicators that follow a drag.
func get_scroll() -> float:
	return _scroll


## Whether the carousel has come to rest on its focused card.
func is_settled() -> bool:
	return not _pressing and is_equal_approx(_scroll, float(_selected))


## Screen-space size the focused card is given, for screens that size card contents to it.
func get_focus_card_size() -> Vector2:
	# Tallest card the carousel allows, keeping room for the lift.
	var max_height: float = size.y * (1.0 - lift_share * 2.0 - 0.02)
	var widest: float = size.x * maxf(focus_width_share, max_width_share)
	var width: float = minf(widest, max_height / card_aspect)
	var height: float = width * card_aspect
	if max_card_aspect > card_aspect:
		height = minf(max_height, width * max_card_aspect)
	return Vector2(width, height)


func _begin_press(local_position: Vector2) -> void:
	_pressing = true
	_moved = false
	_tap_void = false
	_press_position = local_position
	_press_scroll = _scroll
	_last_motion_x = local_position.x
	_last_motion_msec = Time.get_ticks_msec()
	_velocity = 0.0
	set_process(false)


func _drag_to(local_position: Vector2) -> void:
	var dx: float = local_position.x - _press_position.x
	if absf(dx) > tap_slop:
		_moved = true
	elif local_position.distance_to(_press_position) > tap_slop:
		_tap_void = true
	if not _moved:
		return
	var pitch: float = maxf(1.0, get_focus_card_size().x * pitch_share)
	var raw: float = _press_scroll - dx / pitch
	# Rubber band past either end instead of a hard stop.
	var last: float = float(_cards.size() - 1)
	if raw < 0.0:
		raw *= 0.35
	elif raw > last:
		raw = last + (raw - last) * 0.35
	var now: int = Time.get_ticks_msec()
	var elapsed: float = maxf(0.001, float(now - _last_motion_msec) / 1000.0)
	var instant: float = -(local_position.x - _last_motion_x) / pitch / elapsed
	_velocity = lerpf(_velocity, instant, 0.5)
	_last_motion_x = local_position.x
	_last_motion_msec = now
	_scroll = raw
	_layout()


func _end_press(local_position: Vector2) -> void:
	_pressing = false
	if _moved:
		var target: int = roundi(_scroll)
		# A quick flick moves at least one card even if the drag was short. Velocity is only
		# sampled on motion, so a finger that stopped before lifting must not count as one.
		var idle_msec: int = Time.get_ticks_msec() - _last_motion_msec
		var is_flick: bool = idle_msec <= FLICK_IDLE_MSEC and absf(_velocity) >= flick_speed
		if is_flick and target == roundi(_press_scroll):
			target += 1 if _velocity > 0.0 else -1
		select(target)
		set_process(true)
		return
	if _tap_void:
		set_process(true)
		return
	var hit: int = _card_at_rest(local_position)
	if hit < 0:
		set_process(true)
		return
	if hit == _selected:
		activated.emit(hit)
	else:
		select(hit)
	set_process(true)


## Ends a press without treating it as a tap: a swipe in progress snaps to the nearest card.
func _cancel_press() -> void:
	if not _pressing:
		return
	_pressing = false
	_velocity = 0.0
	if _moved:
		select(roundi(_scroll))
	set_process(true)


## Index of the card under a local point in the resting layout for the current selection.
##
## Taps are judged against where cards will rest, not where they are mid-slide: otherwise a quick
## second tap on a peeking card lands on the card still sliding in from that spot - which is already
## selected - and activates it (buying a form or starting a run) instead of browsing one further.
func _card_at_rest(local_position: Vector2) -> int:
	var card_size: Vector2 = get_focus_card_size()
	var pitch: float = card_size.x * pitch_share
	var centre: Vector2 = size * 0.5
	var best: int = -1
	var best_distance: int = 1000
	for index: int in _cards.size():
		var steps: int = absi(index - _selected)
		if float(steps) >= 2.5:
			continue
		var distance: float = minf(float(steps), 1.0)
		var scaled: Vector2 = card_size * lerpf(1.0, side_scale, distance)
		var lift: float = card_size.y * lift_share * (1.0 - distance)
		var card_centre := Vector2(centre.x + float(index - _selected) * pitch, centre.y - lift)
		# The card nearest focus is drawn on top, so it wins where cards overlap.
		if Rect2(card_centre - scaled * 0.5, scaled).has_point(local_position) and steps < best_distance:
			best = index
			best_distance = steps
	return best


func _layout() -> void:
	if _cards.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var card_size: Vector2 = get_focus_card_size()
	var pitch: float = card_size.x * pitch_share
	var centre: Vector2 = size * 0.5
	for index: int in _cards.size():
		var card: Control = _cards[index]
		var offset: float = float(index) - _scroll
		var distance: float = minf(absf(offset), 1.0)
		var card_scale: float = lerpf(1.0, side_scale, distance)
		card.size = card_size
		card.pivot_offset = card_size * 0.5
		card.scale = Vector2.ONE * card_scale
		var lift: float = card_size.y * lift_share * (1.0 - distance)
		card.position = Vector2(
			centre.x + offset * pitch - card_size.x * 0.5,
			centre.y - card_size.y * 0.5 - lift,
		)
		var brightness: float = lerpf(1.0, side_brightness, distance)
		card.modulate = Color(brightness, brightness, brightness, 1.0)
		# Nearest card on top; far cards hidden so they never catch a stray tap off-screen.
		card.z_index = 10 - roundi(absf(offset) * 2.0)
		card.visible = absf(offset) < 2.5
		if card is BaseButton:
			(card as BaseButton).set_pressed_no_signal(index == _selected)


func _ignore_mouse_recursive(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_recursive(child)
