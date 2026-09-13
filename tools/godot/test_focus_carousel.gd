extends SceneTree
## FocusCarousel: layout, focus visuals, swipe-and-snap, flick, tap, keys, clamping - through real input.
##
## Mouse events go through `root.push_input(event, true)`: viewport coordinates, routed by Godot's
## real GUI hit-testing. `Input.parse_input_event` cannot be used for GUI here - a headless test has a
## 0x0 window, so window-space positions are scaled by ~0.03 and land on nothing.

var _failures: int = 0
var _carousel: FocusCarousel
var _changes: Array[int] = []
var _activations: Array[int] = []


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("focus_carousel: %s" % message)


func _run() -> void:
	var host := Control.new()
	host.size = Vector2(1080, 1920)
	root.add_child(host)
	_carousel = FocusCarousel.new()
	_carousel.position = Vector2(0, 300)
	_carousel.size = Vector2(1080, 1200)
	host.add_child(_carousel)
	var cards: Array[Control] = []
	for index: int in 5:
		var card := Button.new()
		card.theme_type_variation = &"CardButton"
		card.add_child(Label.new())
		cards.append(card)
	_carousel.set_cards(cards, 2)
	_carousel.selection_changed.connect(func(index: int) -> void: _changes.append(index))
	_carousel.activated.connect(func(index: int) -> void: _activations.append(index))
	await process_frame

	_check_layout()
	await _check_swipe_snaps()
	await _check_short_drag_returns()
	await _check_flick_advances()
	await _check_tap_side_and_focused()
	await _check_rapid_double_tap_browses()
	await _check_cancelled_releases_do_not_tap()
	await _check_hold_then_release_is_not_a_flick()
	await _check_clamping_and_keys()
	await _check_replacing_cards()

	if _failures == 0:
		print("focus_carousel: layout, snap, flick, tap, double tap, cancel, hold, rubber band, keys, clamping and card replacement OK")
	quit(_failures)


func _check_layout() -> void:
	var focused: Control = _carousel.get_card(2)
	var left: Control = _carousel.get_card(1)
	if not (focused as Button).button_pressed:
		_fail("the focused card is not in its selected (pressed) state")
	if (left as Button).button_pressed:
		_fail("a side card is shown as selected")
	if focused.scale.x <= left.scale.x:
		_fail("the focused card is not larger than its neighbour")
	if focused.modulate.r <= left.modulate.r:
		_fail("the focused card is not brighter than its neighbour")
	if focused.z_index <= left.z_index:
		_fail("the focused card is not drawn above its neighbour")
	var centre_x: float = focused.position.x + focused.size.x * 0.5
	if absf(centre_x - _carousel.size.x * 0.5) > 1.0:
		_fail("the focused card is not centred (%.1f)" % centre_x)
	# Neighbours must peek in from the sides, not sit fully off-screen or fully overlapped.
	var left_drawn_right: float = left.position.x + left.pivot_offset.x * (1.0 - left.scale.x) \
		+ left.size.x * left.scale.x
	if left_drawn_right <= 0.0 or left_drawn_right >= focused.position.x + focused.size.x * 0.5:
		_fail("the left neighbour does not peek in beside the focused card")
	if focused.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("a card still takes mouse input, which would swallow swipes")
	if _carousel.get_focus_card_size().y > _carousel.size.y:
		_fail("the focused card is taller than the carousel")


func _check_swipe_snaps() -> void:
	_changes.clear()
	var pitch: float = _carousel.get_focus_card_size().x * _carousel.pitch_share
	# Drag left by 1.3 card pitches, slowly: must land exactly one card further right... or two.
	await _drag(Vector2(540, 600), Vector2(540 - pitch * 1.3, 600), 20)
	await _settle()
	if _carousel.get_selected_index() != 3:
		_fail("a 1.3-card drag snapped to %d, expected 3" % _carousel.get_selected_index())
	if _changes != [3]:
		_fail("selection_changed fired %s, expected [3]" % str(_changes))
	if not is_equal_approx(_carousel.get_scroll(), 3.0):
		_fail("the carousel did not settle exactly on the card (%.3f)" % _carousel.get_scroll())


func _check_short_drag_returns() -> void:
	_changes.clear()
	var pitch: float = _carousel.get_focus_card_size().x * _carousel.pitch_share
	# Flicks have their own check; switch them off so headless frame timing cannot make this flaky.
	var flick_speed: float = _carousel.flick_speed
	_carousel.flick_speed = 20.0
	await _drag(Vector2(540, 600), Vector2(540 + pitch * 0.3, 600), 20)
	await _settle()
	_carousel.flick_speed = flick_speed
	if _carousel.get_selected_index() != 3 or not _changes.is_empty():
		_fail("a short slow drag changed the selection")


func _check_flick_advances() -> void:
	_changes.clear()
	# Fast, short swipe to the right: must move one card left despite travelling under half a pitch.
	await _drag(Vector2(540, 600), Vector2(700, 600), 2)
	await _settle()
	if _carousel.get_selected_index() != 2:
		_fail("a flick did not advance one card (at %d)" % _carousel.get_selected_index())


func _check_tap_side_and_focused() -> void:
	_changes.clear()
	_activations.clear()
	var right: Control = _carousel.get_card(3)
	var right_point: Vector2 = _carousel.global_position + right.position + right.size * 0.5
	# Aim at the part of the neighbour that is visible past the focused card.
	right_point.x = minf(right_point.x + right.size.x * 0.3, _carousel.global_position.x + 1070.0)
	await _tap(right_point)
	await _settle()
	if _carousel.get_selected_index() != 3:
		_fail("tapping a side card did not focus it")
	if not _activations.is_empty():
		_fail("tapping a side card activated it instead of focusing it")
	var focused: Control = _carousel.get_card(3)
	await _tap(_carousel.global_position + focused.position + focused.size * 0.5)
	if _activations != [3]:
		_fail("tapping the focused card did not activate it (%s)" % str(_activations))


func _check_rapid_double_tap_browses() -> void:
	_carousel.select(1, false)
	await process_frame
	_activations.clear()
	# Two quick taps on the right peek strip: browse two cards, never activate the one sliding in.
	var strip := Vector2(_carousel.global_position.x + 1070.0, _carousel.global_position.y + 600.0)
	await _tap(strip)
	await _tap(strip)
	await _settle()
	if _carousel.get_selected_index() != 3:
		_fail("a rapid double tap on the peek strip landed on %d, expected 3" % _carousel.get_selected_index())
	if not _activations.is_empty():
		_fail("a rapid double tap activated the card sliding in (%s)" % str(_activations))


func _check_cancelled_releases_do_not_tap() -> void:
	await _settle()
	_activations.clear()
	var centre: Vector2 = _carousel.global_position + _carousel.size * 0.5
	# Android cancelled touch: the emulated release arrives with canceled set.
	_mouse_button(centre, true)
	await process_frame
	var cancelled := _release_event(centre)
	cancelled.canceled = true
	root.push_input(cancelled, true)
	await process_frame
	# App focus lost mid-press: the release may never arrive, and a late one must not tap.
	_mouse_button(centre, true)
	await process_frame
	root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_mouse_button(centre, false)
	await process_frame
	# Focus lost mid-swipe: the carousel must snap to a card instead of freezing between two.
	_mouse_button(centre, true)
	await process_frame
	for step: int in 6:
		_move_to(centre + Vector2(-40.0 * float(step + 1), 0))
		await process_frame
	root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _settle()
	if not _carousel.is_settled():
		_fail("losing app focus mid-swipe left the carousel unsettled at %.3f" % _carousel.get_scroll())
	centre = _carousel.global_position + _carousel.size * 0.5
	# A vertical drag that ends back over the focused card is not a tap either.
	_mouse_button(centre, true)
	await process_frame
	_move_to(centre + Vector2(0, 160))
	await process_frame
	_move_to(centre)
	await process_frame
	_mouse_button(centre, false)
	await process_frame
	if not _activations.is_empty():
		_fail("a cancelled, focus-lost or dragged press activated the card (%s)" % str(_activations))
	# A real tap still works afterwards: the press state was reset.
	await _tap(centre)
	if _activations != [_carousel.get_selected_index()]:
		_fail("a normal tap stopped activating after cancelled presses (%s)" % str(_activations))


func _check_hold_then_release_is_not_a_flick() -> void:
	_carousel.select(2, false)
	await process_frame
	_changes.clear()
	var origin: Vector2 = _carousel.global_position
	# Fast short swipe (flick speed), then the finger stops before lifting: must snap back.
	_mouse_button(origin + Vector2(540, 600), true)
	_move_to(origin + Vector2(620, 600))
	await process_frame
	_move_to(origin + Vector2(700, 600))
	await process_frame
	await create_timer(0.25).timeout
	_mouse_button(origin + Vector2(700, 600), false)
	await process_frame
	await _settle()
	if _carousel.get_selected_index() != 2 or not _changes.is_empty():
		_fail("drag, hold and release still flicked to %d" % _carousel.get_selected_index())


func _check_clamping_and_keys() -> void:
	_carousel.select(-5)
	if _carousel.get_selected_index() != 0:
		_fail("selecting below zero did not clamp")
	_carousel.select(99)
	if _carousel.get_selected_index() != 4:
		_fail("selecting past the end did not clamp")
	# A drag past the last card overshoots, damped by the rubber band, then settles back on it.
	_carousel.select(4, false)
	await process_frame
	var pitch: float = _carousel.get_focus_card_size().x * _carousel.pitch_share
	var origin: Vector2 = _carousel.global_position
	var max_scroll: float = 0.0
	_mouse_button(origin + Vector2(700, 600), true)
	for step: int in 20:
		_move_to(origin + Vector2(lerpf(700.0, 100.0, float(step + 1) / 20.0), 600))
		await process_frame
		max_scroll = maxf(max_scroll, _carousel.get_scroll())
	if max_scroll <= 4.01:
		_fail("dragging past the end did not overshoot (max scroll %.3f)" % max_scroll)
	if max_scroll >= 4.0 + (600.0 / pitch) * 0.35 + 0.01:
		_fail("dragging past the end was not damped by the rubber band (max scroll %.3f)" % max_scroll)
	_mouse_button(origin + Vector2(100, 600), false)
	await process_frame
	await _settle()
	if _carousel.get_selected_index() != 4 or not is_equal_approx(_carousel.get_scroll(), 4.0):
		_fail("dragging past the end left the selection off the last card")
	_carousel.grab_focus()
	await _key(KEY_LEFT)
	if _carousel.get_selected_index() != 3:
		_fail("the left key did not move focus")
	_activations.clear()
	await _key(KEY_ENTER)
	if _activations != [3]:
		_fail("ui_accept did not activate the focused card")


func _check_replacing_cards() -> void:
	var fresh: Array[Control] = []
	for index: int in 3:
		fresh.append(Button.new())
	_carousel.set_cards(fresh, 1)
	await process_frame
	var buttons: int = 0
	for child: Node in _carousel.get_children():
		if child is Button:
			buttons += 1
	if buttons != 3:
		_fail("replacing cards left %d buttons, expected 3" % buttons)
	if _carousel.get_selected_index() != 1:
		_fail("replacing cards did not apply the requested selection")


# --------------------------------------------------------------------------- input helpers

func _drag(from: Vector2, to: Vector2, steps: int) -> void:
	var origin: Vector2 = _carousel.global_position
	_mouse_button(origin + from, true)
	for step: int in steps:
		var point: Vector2 = from.lerp(to, float(step + 1) / float(steps))
		var motion := InputEventMouseMotion.new()
		motion.position = origin + point
		motion.global_position = origin + point
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion, true)
		await process_frame
	_mouse_button(origin + to, false)
	await process_frame


func _tap(point: Vector2) -> void:
	_mouse_button(point, true)
	await process_frame
	_mouse_button(point, false)
	await process_frame


func _move_to(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)


func _release_event(point: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = point
	event.global_position = point
	return event


func _mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event, true)


func _key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _settle() -> void:
	for _frame: int in 120:
		if _carousel.is_settled():
			return
		await process_frame
