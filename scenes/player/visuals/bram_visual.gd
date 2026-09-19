class_name BramVisual
extends PlayableCharacterVisual
## Bram, the Rift Knight: a compact armoured hero whose quality comes from weight, not from parts.
##
## He is deliberately quieter than a Mythic rig. Nothing orbits him and nothing streams constantly:
## a slow weight shift, a visor and reactor that breathe, and two cape panels that drag a beat behind
## him. What reads is anticipation — the shield comes up and the blade winds back before a dash, the
## dive leads shield-first with both limbs tucked, the landing compresses through both boots, and a
## kill is one clean cut with a single narrow arc.
##
## Presentation only: the rig never touches collision, damage or scoring.

## Rest angles of the two arms, measured from the rig's own down axis (+Y is behind the character).
const SHIELD_ARM_REST: float = -0.38
const BLADE_ARM_REST: float = 0.42
## Rest angle of the shield plate, which counter-rotates so it always faces the way he is going.
const SHIELD_REST: float = 0.38
const BLADE_REST: float = -0.9
## Dash pose: the shield arm points along the travel axis and the sword arm folds in behind it.
const SHIELD_DASH_ARM: float = -2.15
const BLADE_DASH_ARM: float = 0.2

## Smoothed accents; each state picks targets and everything eases toward them.
var _guard: float = 0.0
var _wind: float = 0.0
var _cut: float = 0.0
var _tuck: float = 0.0
var _plant: float = 0.0
var _salute: float = 0.0
var _glow: float = 0.0
## Weight shift: a slow lean from one boot to the other while he stands.
var _shift: float = 0.0

var _capes: Array[Node2D] = []
var _cape_springs: Array[ChainSpring] = []
var _leg_rest: PackedVector2Array = PackedVector2Array()

@onready var _helmet: Node2D = %Helmet
@onready var _visor: Sprite2D = %Visor
@onready var _torso: Sprite2D = %Torso
@onready var _chest_core: Sprite2D = %ChestCore
@onready var _arm_shield: Node2D = %ArmShield
@onready var _arm_shield_lower: Node2D = %ArmShieldLower
@onready var _shield: Sprite2D = %Shield
@onready var _arm_blade: Node2D = %ArmBlade
@onready var _arm_blade_lower: Node2D = %ArmBladeLower
@onready var _blade_arc: Sprite2D = %BladeArc
@onready var _leg_left: Node2D = %LegLeft
@onready var _leg_right: Node2D = %LegRight

var _helmet_rest: Vector2
var _torso_rest: Vector2
var _torso_scale: Vector2


func _ready() -> void:
	super()
	_capes = [%CapeLeft as Node2D, %CapeRight as Node2D]
	# One spring per panel, mirrored: a shared chain would bias the two halves apart.
	for index: int in _capes.size():
		var panel: Array[Node2D] = [_capes[index]]
		var spring := ChainSpring.new()
		spring.setup(panel, float(index) * 1.6)
		spring.stiffness = 76.0
		spring.damping = 10.0
		spring.lag_root = 0.42
		spring.lag_tip = 0.42
		spring.max_offset = 0.4
		spring.sway_root = 0.03
		spring.sway_tip = 0.03
		spring.sway_rate = 1.25
		_cape_springs.append(spring)
	_leg_rest = PackedVector2Array([_leg_left.position, _leg_right.position])
	_helmet_rest = _helmet.position
	_torso_rest = _torso.position
	_torso_scale = _torso.scale
	if _reduced_motion:
		_apply_reduced_pose()


func _update_secondary_motion(delta: float) -> void:
	if _reduced_motion:
		return
	var speed: float = get_speed()
	var brace: float = get_landing()
	var ease_rate: float = 1.0 - exp(-11.0 * delta)
	var guard_target: float = 0.0
	var wind_target: float = 0.0
	var cut_target: float = 0.0
	var tuck_target: float = 0.0
	var plant_target: float = 0.0
	var salute_target: float = 0.0
	var glow_target: float = 0.2 + speed * 0.25
	match _current_state:
		MOVE_FLY:
			guard_target = 0.2
		AIM_CHARGE:
			# Anticipation: the shield comes up and the blade winds back behind him.
			guard_target = 0.85
			wind_target = 1.0
			glow_target = 0.75
		DASH_START:
			guard_target = 1.0
			wind_target = 0.8
			tuck_target = 0.85
			glow_target = 0.65
		DASH_LOOP:
			# Shield-first, both limbs tucked in behind it.
			guard_target = 1.0
			tuck_target = 1.0
			glow_target = 0.5
		DASH_END:
			plant_target = 1.0
			guard_target = 0.45
			glow_target = 0.45
		ATTACK:
			cut_target = 1.0
			glow_target = 1.0
		HIT_REACTION:
			# He braces behind the shield instead of flailing.
			guard_target = 1.0
			tuck_target = 0.5
			glow_target = 0.15
		DEATH:
			plant_target = 1.0
			guard_target = 0.3
			glow_target = -0.7
		REVIVE_SPAWN:
			guard_target = 0.4
			glow_target = 0.85
		VICTORY:
			guard_target = 0.9
			salute_target = 0.8
			glow_target = 0.7
		CHARACTER_SELECTED:
			salute_target = 1.0
			glow_target = 0.8
		CHARACTER_UNLOCKED:
			# Shield planted, blade raised, one short flare from the reactor.
			guard_target = 1.0
			salute_target = 0.9
			plant_target = 0.5
			glow_target = 1.0
	_guard = lerpf(_guard, maxf(guard_target, brace * 0.5), ease_rate)
	_wind = lerpf(_wind, wind_target, ease_rate)
	_cut = lerpf(_cut, cut_target, 1.0 - exp(-24.0 * delta))
	_tuck = lerpf(_tuck, tuck_target, 1.0 - exp(-15.0 * delta))
	_plant = lerpf(_plant, maxf(plant_target, brace), 1.0 - exp(-19.0 * delta))
	_salute = lerpf(_salute, salute_target, ease_rate)
	_glow = lerpf(_glow, glow_target, ease_rate)
	# A slow, heavy weight shift is most of what he does while he stands still.
	_shift = sin(_time * TAU / 3.4)

	_update_arms(delta)
	_update_body()
	_update_capes(delta, speed)


func _update_arms(delta: float) -> void:
	var upper_rate: float = 1.0 - exp(-14.0 * delta)
	var lower_rate: float = 1.0 - exp(-9.0 * delta)
	# Shield arm: rises across the chest as he guards, then swings the plate out in front of him.
	var shield_upper: float = SHIELD_ARM_REST + _shift * 0.04 - _guard * 0.8 + _salute * 0.2
	var shield_lower: float = -_guard * 0.45
	# Tucking aims the whole arm along the travel axis so the dive leads shield-first.
	shield_upper = lerpf(shield_upper, SHIELD_DASH_ARM, _tuck)
	shield_lower = lerpf(shield_lower, -0.2, _tuck)
	_arm_shield.rotation = lerpf(_arm_shield.rotation, shield_upper, upper_rate)
	_arm_shield_lower.rotation = lerpf(_arm_shield_lower.rotation, shield_lower, lower_rate)
	# The plate counter-rotates so its face stays toward the threat instead of following the elbow.
	_shield.rotation = lerpf(
		_shield.rotation,
		SHIELD_REST - (_arm_shield.rotation - SHIELD_ARM_REST) - _arm_shield_lower.rotation,
		upper_rate
	)
	# Blade arm: winds back, then cuts through in one stroke.
	var blade_upper: float = (
		BLADE_ARM_REST - _shift * 0.04 + _wind * 0.75 - _cut * 1.85 - _salute * 1.15
	)
	var blade_lower: float = _wind * 0.4 - _cut * 0.7 - _salute * 0.3
	# The sword arm folds in behind the shield instead of trailing loose.
	blade_upper = lerpf(blade_upper, BLADE_DASH_ARM, _tuck)
	blade_lower = lerpf(blade_lower, 0.18, _tuck)
	_arm_blade.rotation = lerpf(_arm_blade.rotation, blade_upper, upper_rate)
	_arm_blade_lower.rotation = lerpf(_arm_blade_lower.rotation, blade_lower, lower_rate)
	# One narrow arc, shown only while the cut is live.
	_blade_arc.modulate.a = clampf(_cut * 1.2 - 0.15, 0.0, 1.0)
	_blade_arc.rotation = 0.5 - _cut * 1.1


func _update_body() -> void:
	var breath: float = sin(_time * TAU / 3.0)
	_torso.scale = Vector2(_torso_scale.x, _torso_scale.y * (1.0 + breath * 0.012))
	_torso.position = _torso_rest + Vector2(_shift * 3.0, 0.0)
	_helmet.position = _helmet_rest + Vector2(_shift * 4.0, breath * 2.0 + _plant * 7.0)
	_helmet.rotation = _shift * 0.035 + _guard * 0.06 - _salute * 0.05
	# Both boots take the impact: they compress and splay a little as he lands.
	_leg_left.position = _leg_rest[0] + Vector2(-_plant * 4.0, -_plant * 6.0)
	_leg_right.position = _leg_rest[1] + Vector2(_plant * 4.0, -_plant * 6.0)
	_leg_left.rotation = 0.06 + _shift * 0.03 + _plant * 0.16 - _tuck * 0.22
	_leg_right.rotation = -0.06 - _shift * 0.03 - _plant * 0.16 + _tuck * 0.22
	# Visor and reactor are drawn over their own painted pixels, so brightening them lights them up.
	var light: float = maxf(0.0, _glow)
	var lit := Color(1.0 + light * 0.9, 1.0 + light * 1.1, 1.0 + light * 1.2, 1.0)
	var dim: float = 1.0 + minf(0.0, _glow)
	_visor.modulate = lit * dim
	_chest_core.modulate = lit * dim
	_chest_core.scale = _torso_scale * (1.0 + light * 0.06)


func _update_capes(delta: float, speed: float) -> void:
	for index: int in _cape_springs.size():
		var outward: float = 1.0 if index == 0 else -1.0
		var spring: ChainSpring = _cape_springs[index]
		# The panels stream in behind him at speed and settle back when he stops.
		spring.bias = outward * (_tuck * 0.36 - _guard * 0.1) - speed * 0.16
		spring.sway_rate = lerpf(1.25, 4.4, speed)
		spring.step(delta, _time)


func _on_state_started(state_name: StringName) -> void:
	match state_name:
		DASH_END:
			for index: int in _cape_springs.size():
				_cape_springs[index].impulse(2.6 if index == 0 else -2.6)
		ATTACK:
			for index: int in _cape_springs.size():
				_cape_springs[index].impulse(-2.0 if index == 0 else 2.0)
		HIT_REACTION:
			for spring: ChainSpring in _cape_springs:
				spring.impulse(3.4)
		CHARACTER_UNLOCKED:
			for index: int in _cape_springs.size():
				_cape_springs[index].impulse(1.8 if index == 0 else -1.8)


func _apply_reduced_pose() -> void:
	if not is_node_ready() or _cape_springs.is_empty():
		return
	_guard = 0.0
	_wind = 0.0
	_cut = 0.0
	_tuck = 0.0
	_plant = 0.0
	_salute = 0.0
	_glow = 0.0
	_shift = 0.0
	_torso.position = _torso_rest
	_torso.scale = _torso_scale
	_helmet.position = _helmet_rest
	_helmet.rotation = 0.0
	_visor.modulate = Color.WHITE
	_chest_core.modulate = Color.WHITE
	_chest_core.scale = _torso_scale
	_arm_shield.rotation = SHIELD_ARM_REST
	_arm_shield_lower.rotation = 0.0
	_shield.rotation = SHIELD_REST
	_arm_blade.rotation = BLADE_ARM_REST
	_arm_blade_lower.rotation = 0.0
	_blade_arc.modulate.a = 0.0
	_leg_left.position = _leg_rest[0]
	_leg_right.position = _leg_rest[1]
	_leg_left.rotation = 0.06
	_leg_right.rotation = -0.06
	for spring: ChainSpring in _cape_springs:
		spring.bias = 0.0
		spring.reset()
