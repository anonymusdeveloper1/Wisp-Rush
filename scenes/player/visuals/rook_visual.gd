class_name RookVisual
extends PlayableCharacterVisual
## Rook, the Bonewing: powerful wing beats at rest, a glide in flight, folded wings in a dash.
##
## Each wing is a bone frame over its membrane on one shoulder pivot. A beat raises and lowers the
## wing and foreshortens it at the top of the stroke; the body lifts on every downstroke. The tail
## is a springy chain of armoured segments ending in the crescent fin, and the feet dangle and lag.

## Seconds per wing beat at rest, in slow flight and in a celebration.
const BEAT_PERIOD_IDLE: float = 0.82
const BEAT_PERIOD_FLY: float = 0.52
const BEAT_PERIOD_CHEER: float = 0.4

var _wing_left_rest: float = 0.0
var _wing_right_rest: float = 0.0
var _wing_scale_rest: Vector2
var _body_rest: Vector2
var _skull_rest: Vector2
var _shadow_rest_scale: Vector2
var _beat_phase: float = 0.0
## Smoothed wing controls: stroke amplitude (rad), fold (0 open .. 1 folded), sweep back (rad).
var _beat_amount: float = 0.3
var _fold: float = 0.0
var _sweep: float = 0.0
var _flare: float = 0.0
var _tail: ChainSpring = ChainSpring.new()
var _feet: Array[ChainSpring] = []

@onready var _body: Node2D = %Body
@onready var _skull: Node2D = %Skull
@onready var _shadow_body: Sprite2D = %ShadowBody
@onready var _wing_left: Node2D = %WingLeft
@onready var _wing_right: Node2D = %WingRight


func _ready() -> void:
	super()
	_wing_left_rest = _wing_left.rotation
	_wing_right_rest = _wing_right.rotation
	_wing_scale_rest = _wing_right.scale
	_body_rest = _body.position
	_skull_rest = _skull.position
	_shadow_rest_scale = _shadow_body.scale
	var joints: Array[Node2D] = [
		%TailSegment0 as Node2D,
		%TailSegment1 as Node2D,
		%TailSegment2 as Node2D,
		%TailFin as Node2D,
	]
	_tail.setup(joints, 0.6)
	_tail.stiffness = 120.0
	_tail.damping = 10.0
	_tail.softening = 0.45
	_tail.lag_root = 0.35
	_tail.lag_tip = 0.8
	_tail.max_offset = 0.55
	_tail.sway_rate = 3.2
	_tail.sway_phase_step = 0.8
	for path: NodePath in [^"%FootLeft", ^"%FootRight"]:
		var foot := ChainSpring.new()
		var joint: Array[Node2D] = [get_node(path) as Node2D]
		foot.setup(joint, 1.3 if path == ^"%FootLeft" else 0.0)
		foot.stiffness = 160.0
		foot.damping = 12.0
		foot.lag_root = 0.6
		foot.lag_tip = 0.6
		foot.max_offset = 0.5
		foot.sway_root = 0.06
		foot.sway_tip = 0.06
		foot.sway_rate = TAU / BEAT_PERIOD_IDLE
		_feet.append(foot)
	if _reduced_motion:
		_apply_reduced_pose()


func _update_secondary_motion(delta: float) -> void:
	if _reduced_motion:
		return
	var speed: float = get_speed()
	var brace: float = get_landing()
	var ease_rate: float = 1.0 - exp(-12.0 * delta)
	var period: float = lerpf(BEAT_PERIOD_IDLE, BEAT_PERIOD_FLY, clampf(speed * 2.5, 0.0, 1.0))
	var amount_target: float = lerpf(0.34, 0.26, clampf(speed * 2.5, 0.0, 1.0))
	var fold_target: float = 0.0
	var sweep_target: float = 0.0
	var flare_target: float = 0.0
	match _current_state:
		DASH_START:
			# Wings tuck in hard for the launch.
			amount_target = 0.03
			fold_target = 0.55
			sweep_target = 1.0
		DASH_LOOP:
			# A stoop, not a glide: wings folded tight along the dive line.
			amount_target = 0.03
			fold_target = 0.5
			sweep_target = 1.0
		ATTACK:
			amount_target = 0.02
			fold_target = -0.08
			sweep_target = 0.45
			flare_target = 1.0
		AIM_CHARGE:
			# Pre-attack: wings cocked high, one slow beat, ready to stoop.
			amount_target = 0.16
			sweep_target = -0.5
			flare_target = 0.25
			period = BEAT_PERIOD_IDLE * 1.15
		DASH_END:
			amount_target = 0.18
			sweep_target = -0.35
		HIT_REACTION:
			amount_target = 0.08
			sweep_target = -0.6
			fold_target = 0.2
		DEATH:
			amount_target = 0.0
			sweep_target = 0.9
			fold_target = 0.5
		VICTORY, CHARACTER_SELECTED, CHARACTER_UNLOCKED:
			amount_target = 0.48
			period = BEAT_PERIOD_CHEER
			sweep_target = -0.1
			flare_target = 0.4
	# Wings flare forward to catch the wall an instant before his feet touch it.
	_beat_amount = lerpf(_beat_amount, amount_target, ease_rate)
	_fold = lerpf(_fold, lerpf(fold_target, -0.14, brace), ease_rate)
	_sweep = lerpf(_sweep, lerpf(sweep_target, -0.5, brace), ease_rate)
	_flare = lerpf(_flare, flare_target, 1.0 - exp(-18.0 * delta))

	_beat_phase = fmod(_beat_phase + delta * TAU / period, TAU)
	# A quick, strong downstroke and a slower recovery.
	var stroke: float = sin(_beat_phase) + 0.28 * sin(2.0 * _beat_phase)
	# The downstroke is fastest at phase 0, so the body rises most there.
	var lift: float = maxf(0.0, cos(_beat_phase))
	var trembling: float = sin(_time * 31.0) * 0.012 * speed
	# Positive stroke lowers the wings (downstroke); the screen-right wing turns clockwise to lower.
	var wing_angle: float = stroke * _beat_amount + _sweep + trembling
	_wing_right.rotation = _wing_right_rest + wing_angle
	_wing_left.rotation = _wing_left_rest - wing_angle
	# Foreshortening at the top of the stroke, a fold that narrows the span, a flare that widens it.
	var span: float = (1.0 - _fold * 0.45) * (1.0 + _flare * 0.12) * (1.0 - absf(stroke) * 0.05)
	var height: float = (1.0 - maxf(0.0, -stroke) * 0.14 * _beat_amount / 0.34) * (1.0 - _fold * 0.12)
	_wing_right.scale = _wing_scale_rest * Vector2(span, height)
	_wing_left.scale = _wing_scale_rest * Vector2(span, height)

	# The body lifts on each downstroke; the skull nods a beat later.
	var beat_share: float = clampf(_beat_amount / 0.34, 0.0, 1.4)
	_body.position = _body_rest + Vector2(0.0, -lift * 9.0 * beat_share + 4.0)
	var nod: float = sin(_beat_phase - 0.9)
	_skull.position = _skull_rest + Vector2(0.0, nod * 2.5 * beat_share)
	_skull.rotation = sin(_time * 0.9) * 0.03 + _flare * -0.08
	var breath: float = sin(_time * TAU / 2.4)
	_shadow_body.scale = _shadow_rest_scale * Vector2(1.0 + breath * 0.02, 1.0 - breath * 0.012)
	_skull.modulate = Color(1.0 + _flare * 0.3, 1.0 + _flare * 0.2, 1.0 + _flare * 0.35)

	# Tail: springy in the air, streaming straight in a dash.
	_tail.straighten = speed * 0.85 * (1.0 - brace * 0.6)
	_tail.sway_root = lerpf(0.05, 0.02, speed)
	_tail.sway_tip = lerpf(0.16, 0.06, speed)
	_tail.sway_rate = lerpf(TAU / period * 0.5, 14.0, speed)
	_tail.step(delta, _time)
	for foot: ChainSpring in _feet:
		foot.sway_rate = TAU / period
		foot.bias = speed * 0.35 - brace * 1.0
		foot.step(delta, _time)


func _on_state_started(state_name: StringName) -> void:
	match state_name:
		DASH_START:
			_tail.impulse(-3.0)
		DASH_END:
			_tail.impulse(5.0)
			for foot: ChainSpring in _feet:
				foot.impulse(4.0)
		ATTACK:
			_tail.impulse(-7.0)
		HIT_REACTION:
			_tail.impulse(8.0)
		CHARACTER_SELECTED, CHARACTER_UNLOCKED:
			_tail.impulse(-5.0)


func _apply_reduced_pose() -> void:
	if not is_node_ready() or _feet.is_empty():
		return
	_wing_right.rotation = _wing_right_rest
	_wing_left.rotation = _wing_left_rest
	_wing_right.scale = _wing_scale_rest
	_wing_left.scale = _wing_scale_rest
	_body.position = _body_rest
	_skull.position = _skull_rest
	_skull.rotation = 0.0
	_skull.modulate = Color.WHITE
	_shadow_body.scale = _shadow_rest_scale
	_tail.reset()
	for foot: ChainSpring in _feet:
		foot.reset()
