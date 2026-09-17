class_name TutorialGhostHand
extends Node2D
## Code-drawn placeholder ghost hand that demonstrates a swipe (press, drag trail, release) or a tap.
##
## PLACEHOLDER ART (ROADMAP M6): a glowing fingertip with a faint finger stem, a fading drag trail
## and an expanding release ring, all from `Palette`. It emits the drag as it moves so the tutorial
## director can show the real aim arrow and release the real dash. It also draws a focus ring around
## a HUD element. Reduced Motion keeps the gesture (it is information) but drops the trail, glow
## pulse and ring growth. Positions are screen (canvas) coordinates.

## The drag moved; [param drag_vector] runs from the press point to the fingertip.
signal aim_changed(drag_vector: Vector2)
## The finger lifted after dragging [param drag_vector].
signal released(drag_vector: Vector2)
## The finger lifted from a tap (`play_tap`) at [param point].
signal tapped(point: Vector2)

enum Step { IDLE, PRESS, DRAG, HOLD, RELEASE }

## Fingertip radius in design px.
const TIP_RADIUS: float = 30.0
## Glow halo radii (multiples of the tip radius) and their alphas.
const GLOW_RADII: Array[float] = [1.8, 2.6]
const GLOW_ALPHAS: Array[float] = [0.28, 0.12]
## Finger stem: offset of its far end from the tip (down-right, a right index finger) and width.
const STEM_OFFSET := Vector2(34.0, 96.0)
const STEM_WIDTH: float = 44.0
const STEM_ALPHA: float = 0.32
## Press: the tip shrinks from this scale onto the screen.
const PRESS_SCALE: float = 1.5
## Trail: sampled points kept, width and head alpha.
const TRAIL_POINTS: int = 24
const TRAIL_WIDTH: float = 16.0
const TRAIL_ALPHA: float = 0.55
## Release ring: radius growth (tip radii) and outline width.
const RING_START: float = 1.0
const RING_END: float = 3.2
const RING_WIDTH: float = 5.0
## Focus ring: padding around the HUD rect, outline width and pulse rate (Hz).
const FOCUS_PADDING: float = 14.0
const FOCUS_WIDTH: float = 5.0
const FOCUS_PULSE_RATE: float = 1.6

## Reduced Motion: no trail, no glow pulse, no ring growth; the gesture itself still plays.
var reduced_motion: bool = false

var _step: Step = Step.IDLE
var _start: Vector2 = Vector2.ZERO
var _drag: Vector2 = Vector2.ZERO
var _tip: Vector2 = Vector2.ZERO
var _durations: Dictionary[int, float] = {}
var _elapsed: float = 0.0
var _alpha: float = 1.0
var _trail: PackedVector2Array = PackedVector2Array()
var _focus_rect: Rect2 = Rect2()
var _pulse_time: float = 0.0
## The gesture is a tap that runs in real time (the world is in slow motion under the upgrade tray).
var _tap: bool = false


func _process(delta: float) -> void:
	_pulse_time += delta
	if _step != Step.IDLE:
		_advance(delta)
	if _step != Step.IDLE or _focus_rect.has_area() or not _trail.is_empty():
		queue_redraw()


func _draw() -> void:
	if _focus_rect.has_area():
		_draw_focus()
	if _step == Step.IDLE:
		return
	if not reduced_motion and _trail.size() >= 2:
		var colours := PackedColorArray()
		for index: int in _trail.size():
			var share: float = float(index + 1) / float(_trail.size())
			colours.append(Color(Palette.SOUL_CYAN, TRAIL_ALPHA * share * _alpha * _fade()))
		draw_polyline_colors(_trail, colours, TRAIL_WIDTH, true)
	if _step == Step.RELEASE:
		var progress: float = _progress()
		var radius: float = TIP_RADIUS * (
			RING_END if reduced_motion else lerpf(RING_START, RING_END, progress)
		)
		draw_arc(_tip, radius, 0.0, TAU, 48, Color(Palette.SOUL_WHITE, (1.0 - progress) * _alpha),
			RING_WIDTH, true)
		return
	var scale_now: float = 1.0
	if _step == Step.PRESS:
		scale_now = lerpf(PRESS_SCALE, 1.0, _ease(_progress()))
	var glow_pulse: float = 1.0 if reduced_motion else 0.85 + 0.15 * sin(_pulse_time * TAU * 2.0)
	var appear: float = _ease(_progress()) if _step == Step.PRESS else 1.0
	var stem_colour := Color(Palette.SOUL_WHITE, STEM_ALPHA * _alpha * appear)
	draw_line(_tip, _tip + STEM_OFFSET, stem_colour, STEM_WIDTH, true)
	draw_circle(_tip + STEM_OFFSET, STEM_WIDTH * 0.5, stem_colour, true, -1.0, true)
	for index: int in GLOW_RADII.size():
		draw_circle(_tip, TIP_RADIUS * GLOW_RADII[index] * scale_now * glow_pulse,
			Color(Palette.SOUL_CYAN, GLOW_ALPHAS[index] * _alpha * appear), true, -1.0, true)
	draw_circle(_tip, TIP_RADIUS * scale_now, Color(Palette.SOUL_WHITE, 0.92 * _alpha * appear),
		true, -1.0, true)
	draw_arc(_tip, TIP_RADIUS * scale_now, 0.0, TAU, 40, Color(Palette.SOUL_CYAN, _alpha * appear),
		3.0, true)


## Plays one swipe from [param from] along [param drag] (screen px): press, drag, hold, release.
## [param alpha] dims the hint version. Restarts cleanly when a swipe is already playing.
func play_swipe(
	from: Vector2,
	drag: Vector2,
	press_seconds: float,
	drag_seconds: float,
	hold_seconds: float,
	release_seconds: float,
	alpha: float = 1.0,
) -> void:
	_tap = false
	_start = from
	_drag = drag
	_tip = from
	_alpha = clampf(alpha, 0.0, 1.0)
	_durations = {
		Step.PRESS: maxf(0.0, press_seconds),
		Step.DRAG: maxf(0.01, drag_seconds),
		Step.HOLD: maxf(0.0, hold_seconds),
		Step.RELEASE: maxf(0.01, release_seconds),
	}
	_trail.clear()
	_enter(Step.PRESS)
	visible = true


## Plays one tap at [param point] (screen px): press, hold, release; emits `tapped` at lift. Runs in
## real time, so it reads the same while the world is in slow motion (the upgrade card tray).
func play_tap(
	point: Vector2,
	press_seconds: float,
	hold_seconds: float,
	release_seconds: float,
	alpha: float = 1.0,
) -> void:
	play_swipe(point, Vector2.ZERO, press_seconds, 0.0, hold_seconds, release_seconds, alpha)
	_tap = true


## Stops any gesture at once (the player took over, or the lesson moved on).
func stop() -> void:
	_step = Step.IDLE
	_trail.clear()
	queue_redraw()


## Whether the finger is still down (press, drag or hold); the release ring does not count.
func is_gesturing() -> bool:
	return _step == Step.PRESS or _step == Step.DRAG or _step == Step.HOLD


## Current fingertip position, for tests.
func get_tip_position() -> Vector2:
	return _tip


## Draws a focus ring around [param rect] (screen px); an empty rect clears it.
func set_focus_rect(rect: Rect2) -> void:
	if rect == _focus_rect:
		return
	_focus_rect = rect
	queue_redraw()


func _advance(delta: float) -> void:
	_elapsed += delta / maxf(Engine.time_scale, 0.01) if _tap else delta
	match _step:
		Step.DRAG:
			_tip = _start + _drag * _ease(_progress())
			_push_trail()
			if not _tap:
				aim_changed.emit(_tip - _start)
		Step.HOLD:
			_push_trail()
	if _elapsed < _durations.get(_step, 0.0):
		return
	match _step:
		Step.PRESS:
			_enter(Step.DRAG)
		Step.DRAG:
			_tip = _start + _drag
			if not _tap:
				aim_changed.emit(_drag)
			_enter(Step.HOLD)
		Step.HOLD:
			_enter(Step.RELEASE)
			if _tap:
				tapped.emit(_start)
			else:
				released.emit(_drag)
		Step.RELEASE:
			stop()


func _enter(step: Step) -> void:
	_step = step
	_elapsed = 0.0
	# A zero-length step passes on the next frame, so every step still gets one draw.


func _push_trail() -> void:
	if reduced_motion:
		return
	_trail.append(_tip)
	while _trail.size() > TRAIL_POINTS:
		_trail.remove_at(0)


func _progress() -> float:
	return clampf(_elapsed / maxf(_durations.get(_step, 0.01), 0.001), 0.0, 1.0)


func _fade() -> float:
	return 1.0 - _progress() if _step == Step.RELEASE else 1.0


func _draw_focus() -> void:
	var rect: Rect2 = _focus_rect.grow(FOCUS_PADDING)
	var wave: float = sin(_pulse_time * TAU * FOCUS_PULSE_RATE)
	var pulse: float = 1.0 if reduced_motion else 0.6 + 0.4 * wave
	draw_rect(rect, Color(Palette.SOUL_CYAN, 0.9 * pulse), false, FOCUS_WIDTH, true)


static func _ease(value: float) -> float:
	return value * value * (3.0 - 2.0 * value)
