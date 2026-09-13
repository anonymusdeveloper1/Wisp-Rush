extends SceneTree
## Movement flow, driven through the engine's real input pipeline.
##
## Events go through `Input.parse_input_event`, so viewport routing, GUI consumption and touch-to-mouse
## emulation all apply exactly as on a device. Calling the player's `_unhandled_input` directly would
## skip all of that and could hide a HUD control swallowing touches.
##
## Covers the behaviour that made fast play feel delayed - swipes started mid-dash or held through a
## landing were silently discarded - plus redirect, the landing-lock cancel, windup retargeting,
## buffering, launch burst, momentum, the arrow, cancelled touches, and the review findings.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORMS: FormCatalog = preload("res://data/forms/default_catalog.tres")
const SWIPE_LENGTH: float = 240.0
const TOUCH_ORIGIN := Vector2(540, 1100)

var _failures: int = 0
var _game: GameWorld
var _player: WispPlayer


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("movement: %s" % message)


func _run() -> void:
	await _check_swipe_during_dash_redirects()
	await _check_redirect_scoring_is_not_farmable()
	await _check_finger_held_through_landing()
	await _check_landing_lock_cancel_and_momentum()
	await _check_windup_retargets_without_redirect()
	await _check_launch_burst_moves_faster()
	await _check_buffering()
	await _check_buffer_does_not_eat_next_touch()
	await _check_arrow_shows_resolved_direction()
	await _check_cancelled_touches()
	await _check_dead_rejects_input()
	_check_lane_blind_spot()
	if _failures == 0:
		print("movement: all flow, scoring, arrow and cancellation checks passed")
	quit(_failures)


# --------------------------------------------------------------------------- scenarios

## THE bug: a swipe that starts and ends while the Wisp is dashing must redirect, not vanish.
func _check_swipe_during_dash_redirects() -> void:
	await _start()
	var redirected: Array[int] = []
	_player.dash_redirected.connect(
		func(_position: Vector2, previous: int) -> void: redirected.append(previous)
	)
	await _wait_resting()
	_swipe(_inward_aim())
	if not await _wait_state(WispPlayer.State.DASHING):
		_fail("the first dash never started")
		await _stop()
		return
	var first_heading: Vector2 = (_player.get_dash_target() - _player.global_position).normalized()
	# Give the first leg a pending kill, so resolution is proven rather than trivially absent.
	var leg: int = _player._dash_id
	_game._kills_by_dash[leg] = 2
	var multi_before: int = _game.get_multi_kill_dashes()
	_swipe(first_heading.orthogonal())
	await physics_frame
	if redirected.is_empty():
		_fail("a swipe made mid-dash was discarded instead of redirecting")
	elif _player.state != WispPlayer.State.DASHING:
		_fail("redirecting did not keep the Wisp dashing (state %d)" % _player.state)
	else:
		var heading: Vector2 = (_player.get_dash_target() - _player.global_position).normalized()
		if absf(heading.dot(first_heading)) > 0.95:
			_fail("the redirect did not change the heading")
		if _game._kills_by_dash.has(leg):
			_fail("the redirected leg's kills were never resolved")
		if _game.get_multi_kill_dashes() != multi_before + 1:
			_fail("the redirected leg's double kill did not score as a multi-kill")
		if not DashGeometry.is_inside_polygon_slack(
			_player.get_dash_target(), _game.get_landing_polygon(), 3.0
		):
			_fail("the redirected dash targets a point off the floor")
	await _stop()


## Review finding 1: mid-air legs must not be marked as rapid wall ricochets.
func _check_redirect_scoring_is_not_farmable() -> void:
	await _start()
	await _wait_resting()
	_swipe(_inward_aim())
	await _wait_state(WispPlayer.State.WALL_IMPACT)
	# A legitimate rapid launch off the wall...
	_swipe(_inward_aim())
	await _wait_state(WispPlayer.State.DASHING)
	# ...followed by redirects in open air, each well inside the rapid window.
	for _turn: int in 2:
		var heading: Vector2 = (_player.get_dash_target() - _player.global_position).normalized()
		_swipe(heading.orthogonal())
		await physics_frame
		if _game._rapid_redirect_dashes.has(_player._dash_id):
			_fail("a mid-air redirect leg was marked as a rapid ricochet")
			break
	await _stop()


## A finger pressed during a dash and still held when the Wisp lands must dash on release.
func _check_finger_held_through_landing() -> void:
	await _start()
	await _wait_resting()
	_swipe(_inward_aim())
	await _wait_state(WispPlayer.State.DASHING)
	_touch(TOUCH_ORIGIN, true)
	if not await _wait_resting():
		_fail("the Wisp never landed after the first dash")
		await _stop()
		return
	var aim: Vector2 = _inward_aim()
	_drag(TOUCH_ORIGIN + aim * SWIPE_LENGTH)
	await physics_frame
	# Review finding 5: the arrow must be showing at rest while the finger is still down.
	if not _player.is_aim_arrow_visible():
		_fail("the arrow vanished at rest while a held swipe would still dash")
	_touch(TOUCH_ORIGIN + aim * SWIPE_LENGTH, false)
	await physics_frame
	if _player.state != WispPlayer.State.WINDUP and _player.state != WispPlayer.State.DASHING:
		_fail("a finger held through the landing was forgotten (state %d)" % _player.state)
	await _stop()


## A swipe during the landing lock launches at once, and fast chains build momentum.
func _check_landing_lock_cancel_and_momentum() -> void:
	await _start()
	await _wait_resting()
	_swipe(_inward_aim())
	var expected: float = 0.0
	for chain: int in 3:
		if not await _wait_state(WispPlayer.State.WALL_IMPACT):
			_fail("dash %d never reached a wall" % chain)
			break
		_swipe(_inward_aim())
		await physics_frame
		if _player.state == WispPlayer.State.WALL_IMPACT:
			_fail("a swipe during the landing lock was not honoured on chain %d" % chain)
			break
		expected = minf(_player.tuning.momentum_max, expected + _player.tuning.momentum_step)
		if not is_equal_approx(_player.get_momentum(), expected):
			_fail("momentum after chain %d is %.3f, expected %.3f" % [
				chain, _player.get_momentum(), expected,
			])
	await _wait_resting()
	await create_timer(_player.tuning.momentum_window + 0.2).timeout
	_swipe(_inward_aim())
	await physics_frame
	if not is_zero_approx(_player.get_momentum()):
		_fail("a slow restart kept momentum at %.3f" % _player.get_momentum())
	await _wait_resting()
	_player._momentum = _player.tuning.momentum_max
	_player.take_contact_damage(_player.global_position)
	if not is_zero_approx(_player.get_momentum()):
		_fail("taking damage did not reset momentum")
	await _stop()


## Review finding 3: a swipe during the windup re-aims the dash; it is not a zero-length redirect.
func _check_windup_retargets_without_redirect() -> void:
	await _start()
	var redirects: Array[int] = []
	_player.dash_redirected.connect(
		func(_position: Vector2, previous: int) -> void: redirects.append(previous)
	)
	await _wait_resting()
	var first: Vector2 = _inward_aim()
	_swipe(first)
	if _player.state != WispPlayer.State.WINDUP:
		_fail("a swipe at rest did not enter the windup (state %d)" % _player.state)
		await _stop()
		return
	var momentum_before: float = _player.get_momentum()
	var second: Vector2 = first.rotated(0.6)
	_swipe(second)
	if not redirects.is_empty():
		_fail("a swipe during the windup was treated as a mid-air redirect")
	if not is_equal_approx(_player.get_momentum(), momentum_before):
		_fail("retargeting a windup handed out free momentum")
	var expected: Vector2 = DashGeometry.reflect_inward_polygon(
		second, _player.position, _game.get_landing_polygon(),
		maxf(1.0, _player.get_collision_radius() * 0.2),
	)
	var heading: Vector2 = (_player.get_dash_target() - _player.position).normalized()
	if heading.dot(expected) < 0.98:
		_fail("the windup dash did not take the new swipe's heading")
	await _stop()


## The launch burst must show up in the actual per-tick motion, not just in the formula.
func _check_launch_burst_moves_faster() -> void:
	await _start()
	await _wait_resting()
	await create_timer(_player.tuning.momentum_window + 0.1).timeout
	_swipe(_inward_aim())
	if not await _wait_state(WispPlayer.State.DASHING):
		_fail("the burst dash never started")
		await _stop()
		return
	var steps: Array[float] = []
	var previous: Vector2 = _player.global_position
	while _player.state == WispPlayer.State.DASHING and steps.size() < 8:
		await physics_frame
		steps.append(_player.global_position.distance_to(previous))
		previous = _player.global_position
	if steps.size() < 6:
		_fail("the dash was too short to measure the burst (%d ticks)" % steps.size())
	elif steps[0] <= steps[4] * 1.07:
		_fail("launch ticks move %.1f px vs %.1f px later: no burst" % [steps[0], steps[4]])
	await _stop()


## Swipes released during a reaction are remembered, then dropped once stale.
func _check_buffering() -> void:
	await _start()
	await _wait_resting()
	_player.take_contact_damage(_player.global_position)
	if _player.state != WispPlayer.State.HURT:
		_fail("could not put the Wisp into its hurt reaction")
		await _stop()
		return
	_swipe(_inward_aim())
	if not _player.has_buffered_swipe():
		_fail("a swipe during the hurt reaction was not buffered")
	await _wait_until(func() -> bool: return _player.state != WispPlayer.State.HURT, 1.0)
	await physics_frame
	if _player.state != WispPlayer.State.WINDUP and _player.state != WispPlayer.State.DASHING:
		_fail("the buffered swipe did not fire once the hurt reaction ended (state %d)"
			% _player.state)

	await _wait_resting()
	var short: PlayerTuning = _player.tuning.duplicate() as PlayerTuning
	short.input_buffer_window = 0.02
	_player.tuning = short
	_player._invulnerability_remaining = 0.0
	_player.take_contact_damage(_player.global_position)
	_swipe(_inward_aim())
	await _wait_until(func() -> bool: return _player.state != WispPlayer.State.HURT, 1.0)
	await physics_frame
	if _player.state == WispPlayer.State.WINDUP or _player.state == WispPlayer.State.DASHING:
		_fail("a stale buffered swipe still fired")
	await _stop()


## Review finding 2: when a buffered swipe fires, a second touch already in progress must survive.
func _check_buffer_does_not_eat_next_touch() -> void:
	await _start()
	await _wait_resting()
	_player.take_contact_damage(_player.global_position)
	var first: Vector2 = _inward_aim()
	_swipe(first)
	# A second finger goes down before the reaction ends and is still down when the buffer fires.
	_touch(TOUCH_ORIGIN, true, 1)
	await _wait_until(func() -> bool: return _player.state != WispPlayer.State.HURT, 1.0)
	await physics_frame
	var second: Vector2 = first.rotated(0.8)
	_drag(TOUCH_ORIGIN + second * SWIPE_LENGTH, 1)
	_touch(TOUCH_ORIGIN + second * SWIPE_LENGTH, false, 1)
	await physics_frame
	var expected: Vector2 = DashGeometry.reflect_inward_polygon(
		second, _player.position, _game.get_landing_polygon(),
		maxf(1.0, _player.get_collision_radius() * 0.2),
	)
	var heading: Vector2 = (_player.get_dash_target() - _player.position).normalized()
	if heading.dot(expected) < 0.95:
		_fail("the second touch was thrown away when the buffered swipe fired")
	await _stop()


## The arrow shows the RESOLVED heading: an outward swipe off the wall points back into the floor.
func _check_arrow_shows_resolved_direction() -> void:
	await _start()
	if _player.get_node_or_null("AimLine") != null:
		_fail("the old full aim line node still exists")
	await _wait_resting()
	var outward: Vector2 = -_inward_aim()
	_touch(TOUCH_ORIGIN, true)
	_drag(TOUCH_ORIGIN + outward * SWIPE_LENGTH)
	await physics_frame
	var expected: Vector2 = DashGeometry.reflect_inward_polygon(
		outward, _player.position, _game.get_landing_polygon(),
		maxf(1.0, _player.get_collision_radius() * 0.2),
	)
	if not _player.is_aim_arrow_visible():
		_fail("the arrow is not shown while aiming")
	else:
		var shown: Vector2 = _player.get_aim_arrow_direction()
		if shown.dot(expected) < 0.98:
			_fail("the arrow points %s, not the resolved heading %s" % [shown, expected])
		if shown.dot(outward) > 0.9:
			_fail("the arrow shows the raw outward swipe instead of the bounced heading")
	_touch(TOUCH_ORIGIN + outward * SWIPE_LENGTH, false)
	await physics_frame
	if _player.is_aim_arrow_visible():
		_fail("the arrow stayed visible after the swipe was released")

	await _wait_resting()
	_player.set_aim_arrow_enabled(false)
	_touch(TOUCH_ORIGIN, true)
	_drag(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH)
	await physics_frame
	if _player.is_aim_arrow_visible():
		_fail("the arrow showed while AIM ARROW is off")
	_touch(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH, false)

	# cancel_active_aim (pause, screen change) must clear the pointer, the buffer and the arrow.
	await _wait_resting()
	_player.set_aim_arrow_enabled(true)
	_touch(TOUCH_ORIGIN, true)
	_drag(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH)
	await physics_frame
	_player.cancel_active_aim()
	if _player.is_aim_arrow_visible() or _player.has_buffered_swipe():
		_fail("cancel_active_aim left the arrow or a buffer behind")
	_touch(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH, false)
	await physics_frame
	if _player.state == WispPlayer.State.WINDUP or _player.state == WispPlayer.State.DASHING:
		_fail("a swipe cancelled by cancel_active_aim still dashed on release")
	await _stop()


## Review finding 6: a system-cancelled touch must never act, at rest or mid-dash.
func _check_cancelled_touches() -> void:
	await _start()
	await _wait_resting()
	_touch(TOUCH_ORIGIN, true)
	_drag(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH)
	_cancel(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH)
	await physics_frame
	if _player.state == WispPlayer.State.WINDUP or _player.state == WispPlayer.State.DASHING:
		_fail("a cancelled touch at rest dashed")

	await _wait_resting()
	var redirects: Array[int] = []
	_player.dash_redirected.connect(
		func(_position: Vector2, previous: int) -> void: redirects.append(previous)
	)
	_swipe(_inward_aim())
	await _wait_state(WispPlayer.State.DASHING)
	var heading: Vector2 = (_player.get_dash_target() - _player.global_position).normalized()
	_touch(TOUCH_ORIGIN, true)
	_drag(TOUCH_ORIGIN + heading.orthogonal() * SWIPE_LENGTH)
	_cancel(TOUCH_ORIGIN + heading.orthogonal() * SWIPE_LENGTH)
	await physics_frame
	if not redirects.is_empty():
		_fail("a cancelled touch redirected a live dash")
	await _stop()


func _check_dead_rejects_input() -> void:
	await _start()
	await _wait_resting()
	_player.state = WispPlayer.State.DEAD
	_touch(TOUCH_ORIGIN, true)
	_drag(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH)
	await physics_frame
	if _player.is_aim_arrow_visible():
		_fail("a dead Wisp showed an aim arrow")
	_touch(TOUCH_ORIGIN + _inward_aim() * SWIPE_LENGTH, false)
	await _stop()


## Review finding 7: a fast dash passing near a corridor lane's END must still register.
func _check_lane_blind_spot() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	var lane_start := Vector2(0, 0)
	var lane_end := Vector2(100, 0)
	# Vertical pass at x = 115: 15 px from the lane's end, never crossing it, both endpoints far out.
	var t: float = game._segment_lane_entry_t(
		Vector2(115, 40), Vector2(115, -40), lane_start, lane_end, 20.0
	)
	if is_inf(t):
		_fail("a dash passing within the radius of a lane's end was not detected")
	elif absf(t - 0.5) > 0.05:
		_fail("near-miss entry reported at t = %.2f, expected about 0.5" % t)
	# And a clean miss must still be a miss.
	var miss: float = game._segment_lane_entry_t(
		Vector2(160, 40), Vector2(160, -40), lane_start, lane_end, 20.0
	)
	if not is_inf(miss):
		_fail("a dash well clear of the lane was reported as entering it")
	game.free()


# --------------------------------------------------------------------------- helpers

func _start() -> void:
	paused = false
	_game = GAME_WORLD_SCENE.instantiate() as GameWorld
	_game.tutorial_enabled = false
	_game.run_seed = 11
	_game.auto_pause_on_focus_loss = false
	_game.configure_run_profile(
		FORMS.get_form(&"void"), "", RIFTS.get_rift(&"obsidian_garden"), 1
	)
	root.add_child(_game)
	await create_timer(0.3).timeout
	_game.debug_quiet_arena()
	_player = _game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer


func _stop() -> void:
	if is_instance_valid(_game):
		_game.queue_free()
	await process_frame


## A swipe aimed from the Wisp toward the middle of the floor, so it always resolves inward.
func _inward_aim() -> Vector2:
	var centre: Vector2 = DashGeometry.polygon_centroid(_game.get_landing_polygon())
	var aim: Vector2 = centre - _player.global_position
	return Vector2.UP if aim.is_zero_approx() else aim.normalized()


func _swipe(direction: Vector2, index: int = 0) -> void:
	var end: Vector2 = TOUCH_ORIGIN + direction.normalized() * SWIPE_LENGTH
	_touch(TOUCH_ORIGIN, true, index)
	_drag(end, index)
	_touch(end, false, index)


func _touch(position: Vector2, pressed: bool, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	_send(event)


func _drag(position: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	_send(event)


func _cancel(position: Vector2, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = false
	event.canceled = true
	_send(event)


## Routes an event through the real input pipeline and processes it immediately.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wait_resting() -> bool:
	return await _wait_state(WispPlayer.State.WAITING_AT_EDGE)


func _wait_state(target: WispPlayer.State) -> bool:
	return await _wait_until(func() -> bool: return _player.state == target, 1.5)


func _wait_until(condition: Callable, timeout: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await physics_frame
	return bool(condition.call())
