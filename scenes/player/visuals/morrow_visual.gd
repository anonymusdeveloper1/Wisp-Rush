class_name MorrowVisual
extends PlayableCharacterVisual
## Morrow, the Runebound: a calm hooded caster whose hands and runes float around him.
##
## The cloak breathes, the masked hood nods and tilts a beat behind the body, each floating hand
## drifts on its own slow orbit, three rune stones circle him (passing behind and in front) while
## turning against their orbit, and two skinned scarves trail every move. Motion stays small and
## unhurried so he never reads as an enemy.

## Rune orbit radii and centre in rig pixels. The ring is tilted toward the viewer: its near half
## passes below the mask (over the collar) and its far half behind the hood, so no rune ever
## crosses the face.
const RUNE_ORBIT: Vector2 = Vector2(176.0, 88.0)
const RUNE_ORBIT_CENTRE: Vector2 = Vector2(0.0, -118.0)

var _cloak_rest_scale: Vector2
var _head_rest: Vector2
var _hand_left_rest: Vector2
var _hand_right_rest: Vector2
var _rune_scale: Vector2
var _runes: Array[Node2D] = []
var _scarves: Array[RibbonChain] = []
var _flap: ChainSpring = ChainSpring.new()
var _orbit_angle: float = 0.0
## Smoothed state accents.
var _orbit_speed: float = 0.45
var _reach: float = 0.0
var _pull_back: float = 0.0
var _raise: float = 0.0
var _flinch: float = 0.0
var _rune_glow: float = 0.0
var _mask_tilt: float = 0.0

@onready var _cloak: Sprite2D = %CloakBody
@onready var _head: Node2D = %Head
@onready var _mask: Sprite2D = %Mask
@onready var _hand_left: Node2D = %HandLeft
@onready var _hand_right: Node2D = %HandRight


func _ready() -> void:
	super()
	_cloak_rest_scale = _cloak.scale
	_head_rest = _head.position
	_hand_left_rest = _hand_left.position
	_hand_right_rest = _hand_right.position
	_runes = [%Rune0 as Node2D, %Rune1 as Node2D, %Rune2 as Node2D]
	_rune_scale = _runes[0].scale
	_scarves = [%ScarfLeft as RibbonChain, %ScarfRight as RibbonChain]
	for index: int in _scarves.size():
		var spring: ChainSpring = _scarves[index].spring
		spring.stiffness = 55.0
		spring.damping = 8.0
		spring.softening = 0.5
		spring.lag_root = 0.35
		spring.lag_tip = 0.9
		spring.max_offset = 0.55
		spring.sway_rate = 1.6 + index * 0.25
	var flap_joint: Array[Node2D] = [%FrontFlap as Node2D]
	_flap.setup(flap_joint, 0.4)
	_flap.stiffness = 80.0
	_flap.damping = 9.0
	_flap.lag_root = 0.45
	_flap.lag_tip = 0.45
	_flap.max_offset = 0.3
	_flap.sway_root = 0.02
	_flap.sway_tip = 0.02
	_flap.sway_rate = 1.4
	_place_runes()
	if _reduced_motion:
		_apply_reduced_pose()


func _update_secondary_motion(delta: float) -> void:
	if _reduced_motion:
		return
	var speed: float = get_speed()
	var brace: float = get_landing()
	var ease_rate: float = 1.0 - exp(-9.0 * delta)
	var orbit_target: float = lerpf(0.45, 1.7, speed)
	var reach_target: float = 0.0
	var raise_target: float = 0.0
	var flinch_target: float = 0.0
	var glow_target: float = speed * 0.35
	var tilt_target: float = 0.0
	match _current_state:
		AIM_CHARGE:
			# Pre-attack: both hands come up, the runes wind in and the mask turns to the aim.
			raise_target = 0.75
			orbit_target = 2.2
			glow_target = 0.75
			tilt_target = clampf(movement_direction.x, -1.0, 1.0) * 0.14
		DASH_START:
			reach_target = -0.4
			glow_target = 0.6
		ATTACK:
			reach_target = 1.0
			orbit_target = 3.4
			glow_target = 1.0
			tilt_target = -0.1
		DASH_END:
			reach_target = 0.15
			tilt_target = 0.06
		HIT_REACTION:
			flinch_target = 1.0
			tilt_target = 0.22
		DEATH:
			flinch_target = 0.6
			orbit_target = 0.1
			glow_target = -0.5
		VICTORY, CHARACTER_SELECTED:
			raise_target = 1.0
			orbit_target = 2.4
			glow_target = 0.8
		CHARACTER_UNLOCKED:
			raise_target = 1.2
			orbit_target = 3.2
			glow_target = 1.0
	_orbit_speed = lerpf(_orbit_speed, orbit_target, 1.0 - exp(-4.0 * delta))
	# Landing: the hands swing forward under him to meet the wall.
	_reach = lerpf(_reach, maxf(reach_target, brace * 0.75), 1.0 - exp(-16.0 * delta))
	_pull_back = lerpf(_pull_back, speed, ease_rate)
	_raise = lerpf(_raise, raise_target, ease_rate)
	_flinch = lerpf(_flinch, flinch_target, 1.0 - exp(-18.0 * delta))
	_rune_glow = lerpf(_rune_glow, glow_target, ease_rate)
	_mask_tilt = lerpf(_mask_tilt, tilt_target, ease_rate)

	# Cloak breathing and a head that follows the body a beat late.
	var breath: float = sin(_time * TAU / 3.2)
	_cloak.scale = _cloak_rest_scale * Vector2(1.0 + breath * 0.01, 1.0 + breath * 0.02)
	var nod: float = sin(_time * TAU / 3.2 - 0.7)
	_head.position = _head_rest + Vector2(0.0, nod * 3.0 + _flinch * 8.0)
	_head.rotation = sin(_time * 0.55) * 0.03 + clampf(movement_direction.x, -1.0, 1.0) * 0.05 * speed
	_mask.rotation = sin(_time * 0.7 + 0.4) * 0.05 + _mask_tilt

	# Hands: independent slow orbits; pulled back in flight, thrust forward on a kill, raised to cheer.
	var left_drift := Vector2(cos(_time * 0.9) * 13.0, sin(_time * 1.3) * 17.0)
	var right_drift := Vector2(cos(_time * 1.1 + 2.0) * 13.0, sin(_time * 0.8 + 1.0) * 17.0)
	var back := Vector2(34.0, 70.0) * _pull_back
	# A kill pushes both hands forward beside the hood, never across the mask.
	var reach := Vector2(28.0, -84.0) * _reach
	var raise := Vector2(-14.0, -70.0 + sin(_time * 7.0) * 10.0) * _raise
	var flinch := Vector2(22.0, -36.0) * _flinch
	# Offsets are authored for the left hand; the right hand mirrors them across the body.
	var mirror := Vector2(-1.0, 1.0)
	var shared: Vector2 = back + reach + raise
	_hand_left.position = _hand_left_rest + left_drift + shared + flinch * mirror
	_hand_right.position = _hand_right_rest + right_drift + shared * mirror + flinch
	_hand_left.rotation = sin(_time * 1.2) * 0.1 + _reach * 0.3 - _raise * 0.2
	_hand_right.rotation = -sin(_time * 1.05 + 0.6) * 0.1 - _reach * 0.3 + _raise * 0.2

	# Runes circle slowly, faster in flight and on a kill. The angle is never wrapped: each rune's
	# counter-spin is a fraction of it, and wrapping would make that spin jump once per lap.
	_orbit_angle += delta * _orbit_speed
	_place_runes()

	# Scarves and the front flap trail every move.
	_flap.bias = -speed * 0.12
	_flap.step(delta, _time)
	for index: int in _scarves.size():
		var spring: ChainSpring = _scarves[index].spring
		spring.straighten = speed * 0.85 * (1.0 - brace * 0.6)
		spring.sway_tip = lerpf(0.12, 0.09, speed)
		spring.sway_rate = lerpf(1.6 + index * 0.25, 8.0 + index, speed)
		_scarves[index].step(delta, _time)


func _on_state_started(state_name: StringName) -> void:
	match state_name:
		DASH_END:
			_flap.impulse(2.0)
			for index: int in _scarves.size():
				_scarves[index].spring.impulse(2.5 if index == 0 else -2.5)
		ATTACK:
			for index: int in _scarves.size():
				_scarves[index].spring.impulse(-3.0 if index == 0 else 3.0)
		HIT_REACTION:
			_flap.impulse(-4.0)
			for scarf: RibbonChain in _scarves:
				scarf.spring.impulse(4.0)


func _place_runes() -> void:
	for index: int in _runes.size():
		var angle: float = _orbit_angle + index * TAU / _runes.size()
		var depth: float = sin(angle)
		var rune: Node2D = _runes[index]
		rune.position = RUNE_ORBIT_CENTRE + Vector2(cos(angle) * RUNE_ORBIT.x, depth * RUNE_ORBIT.y)
		# The near half of the orbit passes in front of Morrow, the far half behind him.
		rune.z_index = 1 if depth > 0.0 else -1
		var glow: float = maxf(0.0, _rune_glow)
		rune.scale = _rune_scale * (0.86 + depth * 0.14) * (1.0 + glow * 0.18)
		rune.rotation = -_orbit_angle * 0.55 + index * 0.9 + sin(_time * 1.3 + index) * 0.08
		var light: float = 0.92 + glow * 0.45 + minf(0.0, _rune_glow) * 0.6
		rune.modulate = Color(light, light, light, 0.78 + depth * 0.22)


func _apply_reduced_pose() -> void:
	if not is_node_ready() or _scarves.is_empty():
		return
	_cloak.scale = _cloak_rest_scale
	_head.position = _head_rest
	_head.rotation = 0.0
	_mask.rotation = 0.0
	_hand_left.position = _hand_left_rest
	_hand_right.position = _hand_right_rest
	_hand_left.rotation = 0.0
	_hand_right.rotation = 0.0
	_rune_glow = 0.0
	_place_runes()
	_flap.reset()
	for scarf: RibbonChain in _scarves:
		scarf.spring.reset()
