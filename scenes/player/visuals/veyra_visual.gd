class_name VeyraVisual
extends PlayableCharacterVisual
## Veyra, the Last Wisp: soft hover, pulsing core, fluttering fins, floating halo and three tails.
##
## The tails are skinned [RibbonChain] meshes: they trail behind a dash, stream straighter at speed,
## lag and whip on turns and settle with overshoot. Fins sweep back while dashing and flinch on a
## hit; the eyes blink at rest and squeeze on a hit; the core flares on every dash kill.

## States that sweep the fins back, hold the eyes open, and make the halo flare.
const DASH_STATES: Array[StringName] = [DASH_START, DASH_LOOP, ATTACK]
const BUSY_STATES: Array[StringName] = [HIT_REACTION, DEATH]
const FLOURISH_STATES: Array[StringName] = [VICTORY, CHARACTER_SELECTED, CHARACTER_UNLOCKED]
## Seconds between blinks at rest (a little random around this), and one blink's length.
const BLINK_INTERVAL: float = 3.4
const BLINK_TIME: float = 0.13

var _body_rest: Vector2
var _core_rest_scale: Vector2
var _eyes_rest_scale: Vector2
var _outer_rest_scale: Vector2
var _left_fin_rest: float = 0.0
var _right_fin_rest: float = 0.0
var _halo_left_rest: Vector2
var _halo_right_rest: Vector2
var _tails: Array[RibbonChain] = []
## Smoothed state accents, each eased toward the playing state's target.
var _fin_sweep: float = 0.0
var _eye_open: float = 1.0
var _core_boost: float = 0.0
var _halo_spread: float = 0.0
var _halo_spin: float = 0.0
var _blink_clock: float = 0.0
var _next_blink: float = BLINK_INTERVAL

@onready var _body: Node2D = %Body
@onready var _outer_body: Sprite2D = %OuterBody
@onready var _core: Sprite2D = %Core
@onready var _eyes: Sprite2D = %Eyes
@onready var _left_fin: Node2D = %LeftFin
@onready var _right_fin: Node2D = %RightFin
@onready var _halo_left: Node2D = %HaloLeft
@onready var _halo_right: Node2D = %HaloRight


func _ready() -> void:
	super()
	_body_rest = _body.position
	_core_rest_scale = _core.scale
	_eyes_rest_scale = _eyes.scale
	_outer_rest_scale = _outer_body.scale
	_left_fin_rest = _left_fin.rotation
	_right_fin_rest = _right_fin.rotation
	_halo_left_rest = _halo_left.position
	_halo_right_rest = _halo_right.position
	_tails = [%TailLeft as RibbonChain, %TailMiddle as RibbonChain, %TailRight as RibbonChain]
	for index: int in _tails.size():
		var spring: ChainSpring = _tails[index].spring
		spring.stiffness = 70.0 - index * 6.0
		spring.damping = 9.5
		spring.softening = 0.5
		spring.lag_root = 0.25
		spring.lag_tip = 0.6
		spring.max_offset = 0.45
		spring.sway_rate = 2.3 - index * 0.2
	if _reduced_motion:
		_apply_reduced_pose()


func _update_secondary_motion(delta: float) -> void:
	if _reduced_motion:
		return
	var speed: float = get_speed()
	var dashing: bool = _current_state in DASH_STATES
	var brace: float = get_landing()
	var ease_rate: float = 1.0 - exp(-14.0 * delta)

	# State accents.
	var sweep_target: float = 0.0
	var eye_target: float = 1.0
	var boost_target: float = 0.0
	var spread_target: float = 0.0
	match _current_state:
		DASH_START, DASH_LOOP:
			# Knifed back along the body: she dives rather than flutters.
			sweep_target = 0.85
			eye_target = 0.78
			boost_target = 0.45
		ATTACK:
			sweep_target = 0.7
			eye_target = 0.68
			boost_target = 1.0
		AIM_CHARGE:
			# Pre-attack: fins flare forward and the core winds up.
			sweep_target = -0.34
			eye_target = 0.9
			boost_target = 0.6
		DASH_END:
			sweep_target = -0.25
			eye_target = 0.75
		HIT_REACTION:
			sweep_target = -0.45
			eye_target = 0.2
		DEATH:
			sweep_target = 0.4
			eye_target = 0.05
			boost_target = -0.6
		VICTORY, CHARACTER_SELECTED:
			boost_target = 0.7
			spread_target = 1.0
		CHARACTER_UNLOCKED:
			boost_target = 1.0
			spread_target = 1.4
	# Just before the wall the fins swing forward and catch it, so she lands on her feet.
	_fin_sweep = lerpf(_fin_sweep, sweep_target - brace * 1.15, ease_rate)
	_core_boost = lerpf(_core_boost, boost_target, ease_rate)
	_halo_spread = lerpf(_halo_spread, spread_target, 1.0 - exp(-7.0 * delta))

	# Blink at rest (a quick close and open); busy states postpone the next blink. The blink feeds the
	# smoothed openness, so a dash or hit that starts mid-blink opens the eyes over a few frames.
	var blink: float = 1.0
	if dashing or _current_state in BUSY_STATES:
		_blink_clock = minf(_blink_clock, _next_blink * 0.5)
	else:
		_blink_clock += delta
	if _blink_clock >= _next_blink:
		var t: float = (_blink_clock - _next_blink) / BLINK_TIME
		if t >= 1.0:
			_blink_clock = 0.0
			_next_blink = BLINK_INTERVAL + fmod(_time * 7.31, 1.6)
		else:
			blink = 1.0 - sin(t * PI) * 0.9
	_eye_open = lerpf(_eye_open, eye_target * blink, 1.0 - exp(-30.0 * delta))
	_eyes.scale = Vector2(_eyes_rest_scale.x, _eyes_rest_scale.y * clampf(_eye_open, 0.05, 1.0))

	# Flame breathing and core pulse.
	var hover: float = sin(_time * TAU / 1.8)
	var energy: float = 0.5 + 0.5 * sin(_time * (4.2 + speed * 2.6))
	_body.position = _body_rest + Vector2(0.0, hover * 2.5 * (1.0 - speed * 0.6))
	var breath: float = sin(_time * TAU / 2.3)
	_outer_body.scale = _outer_rest_scale * Vector2(1.0 + breath * 0.012, 1.0 - breath * 0.018)
	var core_scale: float = lerpf(0.965, 1.05, energy) * (1.0 + maxf(0.0, _core_boost) * 0.14)
	_core.scale = _core_rest_scale * core_scale
	var glow: float = clampf(0.92 + energy * 0.08 + _core_boost * 0.35, 0.3, 1.5)
	var core_alpha: float = clampf(0.9 + energy * 0.1, 0.0, 1.0)
	_core.self_modulate = Color(glow, glow, minf(glow + 0.04, 1.6), core_alpha)

	# Fins flutter faster with speed and sweep back while dashing.
	var fin_rate: float = lerpf(3.1, 11.0, speed)
	var fin_amount: float = lerpf(0.08, 0.16, speed) * (1.0 - clampf(_fin_sweep, 0.0, 0.6))
	var flutter: float = sin(_time * fin_rate)
	if _current_state in FLOURISH_STATES:
		flutter = sin(_time * 13.0)
		fin_amount = 0.26
	_left_fin.rotation = _left_fin_rest - _fin_sweep - flutter * fin_amount
	_right_fin.rotation = _right_fin_rest + _fin_sweep + flutter * fin_amount

	# Halo fragments float on their own phases and spread and spin during flourishes.
	_halo_spin += delta * lerpf(0.0, 3.2, clampf(_halo_spread, 0.0, 1.0))
	var float_left := Vector2(sin(_time * 1.3) * 3.0, sin(_time * 2.1) * 5.0)
	var float_right := Vector2(sin(_time * 1.1 + 1.7) * 3.0, sin(_time * 1.9 + 0.8) * 5.0)
	var spread := Vector2(18.0, -14.0) * _halo_spread
	_halo_left.position = _halo_left_rest + float_left + Vector2(-spread.x, spread.y)
	_halo_right.position = _halo_right_rest + float_right + spread
	_halo_left.rotation = sin(_time * 0.9) * 0.06 - sin(_halo_spin) * 0.25 * _halo_spread
	_halo_right.rotation = -sin(_time * 0.8 + 1.1) * 0.06 + sin(_halo_spin) * 0.25 * _halo_spread

	# Tails stream straighter and flutter at speed; turns and impacts come through the springs.
	for index: int in _tails.size():
		var spring: ChainSpring = _tails[index].spring
		spring.straighten = speed * 0.85 * (1.0 - brace * 0.7)
		spring.sway_root = lerpf(0.03, 0.05, speed)
		spring.sway_tip = lerpf(0.13, 0.08, speed)
		spring.sway_rate = lerpf(2.3 - index * 0.2, 9.0 + index, speed)
		_tails[index].step(delta, _time)


func _on_state_started(state_name: StringName) -> void:
	match state_name:
		DASH_END:
			for index: int in _tails.size():
				_tails[index].spring.impulse(3.2 if index % 2 == 0 else -3.2)
		ATTACK:
			for index: int in _tails.size():
				_tails[index].spring.impulse(-4.5 + index * 4.5)
		HIT_REACTION:
			for tail: RibbonChain in _tails:
				tail.spring.impulse(6.0)
		CHARACTER_SELECTED, CHARACTER_UNLOCKED:
			for index: int in _tails.size():
				_tails[index].spring.impulse(4.0 - index * 4.0)


func _apply_reduced_pose() -> void:
	if not is_node_ready() or _tails.is_empty():
		return
	_body.position = _body_rest
	_outer_body.scale = _outer_rest_scale
	_core.scale = _core_rest_scale
	_core.self_modulate = Color.WHITE
	_eyes.scale = _eyes_rest_scale
	_left_fin.rotation = _left_fin_rest
	_right_fin.rotation = _right_fin_rest
	_halo_left.position = _halo_left_rest
	_halo_right.position = _halo_right_rest
	_halo_left.rotation = 0.0
	_halo_right.rotation = 0.0
	for tail: RibbonChain in _tails:
		tail.spring.reset()
