class_name NoxenVisual
extends PlayableCharacterVisual
## Noxen, the Veilflame: a handless cloak-creature that turns its silhouette into the weapon.
##
## His two cloak fins work like Rook's wings, the hood and mask lag like Morrow's head, the flame
## horns flicker independently, and two skinned root-flame ribbons trail behind the body. During a
## dash the fins fold into a narrow spear; at contact they snap forward as a cutting crescent. The
## rig is presentation only and never changes movement, collision, damage or scoring.

const IDLE_PERIOD: float = 2.7

var _fin_l_rest: float = 0.0
var _fin_r_rest: float = 0.0
var _fin_l_position: Vector2 = Vector2.ZERO
var _fin_r_position: Vector2 = Vector2.ZERO
var _fin_scale_rest: Vector2 = Vector2.ONE
var _hood_rest: Vector2 = Vector2.ZERO
var _mask_rest: Vector2 = Vector2.ZERO
var _cloak_rest_position: Vector2 = Vector2.ZERO
var _cloak_rest_scale: Vector2 = Vector2.ONE
var _core_rest_scale: Vector2 = Vector2.ONE
var _flame_l_rest: float = 0.0
var _flame_r_rest: float = 0.0
var _flame_scale_rest: Vector2 = Vector2.ONE

var _fold: float = 0.0
var _slice: float = 0.0
var _charge: float = 0.0
var _flinch: float = 0.0
var _celebrate: float = 0.0
var _front_flap: ChainSpring = ChainSpring.new()
var _flame_springs: Array[ChainSpring] = []
var _ribbons: Array[RibbonChain] = []

@onready var _rear_cloak: Node2D = %RearCloak
@onready var _hood: Node2D = %Hood
@onready var _mask: Node2D = %Mask
@onready var _fin_l: Node2D = %CloakFinL
@onready var _fin_r: Node2D = %CloakFinR
@onready var _flame_l: Node2D = %VeilflameL
@onready var _flame_r: Node2D = %VeilflameR
@onready var _core: Node2D = %ChestCore
@onready var _shadow_tail: Node2D = %ShadowTail
@onready var _burst: GPUParticles2D = %AttackParticles


func _ready() -> void:
	super()
	_fin_l_rest = _fin_l.rotation
	_fin_r_rest = _fin_r.rotation
	_fin_l_position = _fin_l.position
	_fin_r_position = _fin_r.position
	_fin_scale_rest = _fin_l.scale
	_hood_rest = _hood.position
	_mask_rest = _mask.position
	_cloak_rest_position = _rear_cloak.position
	_cloak_rest_scale = _rear_cloak.scale
	_core_rest_scale = _core.scale
	_flame_l_rest = _flame_l.rotation
	_flame_r_rest = _flame_r.rotation
	_flame_scale_rest = _flame_l.scale

	var flap_joint: Array[Node2D] = [%FrontFlap as Node2D]
	_front_flap.setup(flap_joint, 0.4)
	_front_flap.stiffness = 82.0
	_front_flap.damping = 9.5
	_front_flap.lag_root = 0.48
	_front_flap.lag_tip = 0.48
	_front_flap.max_offset = 0.34
	_front_flap.sway_root = 0.035
	_front_flap.sway_tip = 0.035
	_front_flap.sway_rate = 1.8

	for index: int in 2:
		var spring := ChainSpring.new()
		var joint: Array[Node2D] = [_flame_l if index == 0 else _flame_r]
		spring.setup(joint, float(index) * 1.7)
		spring.stiffness = 72.0
		spring.damping = 8.5
		spring.lag_root = 0.6
		spring.lag_tip = 0.6
		spring.max_offset = 0.28
		spring.sway_root = 0.065
		spring.sway_tip = 0.065
		spring.sway_rate = 3.4 + float(index) * 0.25
		_flame_springs.append(spring)

	_ribbons = [%RootRibbonL as RibbonChain, %RootRibbonR as RibbonChain]
	for index: int in _ribbons.size():
		var spring: ChainSpring = _ribbons[index].spring
		spring.stiffness = 48.0
		spring.damping = 7.5
		spring.softening = 0.46
		spring.lag_root = 0.38
		spring.lag_tip = 0.94
		spring.max_offset = 0.64
		spring.sway_root = 0.04
		spring.sway_tip = 0.2
		spring.sway_rate = 1.7 + float(index) * 0.3
	if _reduced_motion:
		_apply_reduced_pose()


func _update_secondary_motion(delta: float) -> void:
	if _reduced_motion:
		return
	var speed: float = get_speed()
	var brace: float = get_landing()
	var ease: float = 1.0 - exp(-12.0 * delta)
	var fold_target: float = 0.0
	var slice_target: float = 0.0
	var charge_target: float = speed * 0.35
	var flinch_target: float = 0.0
	var celebrate_target: float = 0.0
	match _current_state:
		AIM_CHARGE:
			fold_target = 0.18
			charge_target = 0.8
		DASH_START, DASH_LOOP:
			fold_target = 1.0
			charge_target = 1.0
		ATTACK:
			fold_target = 0.25
			slice_target = 1.0
			charge_target = 1.25
		DASH_END:
			fold_target = -0.16
			charge_target = 0.6
		HIT_REACTION:
			fold_target = 0.48
			flinch_target = 1.0
		DEATH:
			fold_target = 0.72
			charge_target = -0.7
		VICTORY, CHARACTER_SELECTED:
			fold_target = -0.2
			charge_target = 0.9
			celebrate_target = 0.75
		CHARACTER_UNLOCKED:
			fold_target = -0.32
			charge_target = 1.3
			celebrate_target = 1.0
	_fold = lerpf(_fold, fold_target, ease)
	_slice = lerpf(_slice, slice_target, 1.0 - exp(-19.0 * delta))
	_charge = lerpf(_charge, charge_target, 1.0 - exp(-9.0 * delta))
	_flinch = lerpf(_flinch, flinch_target, 1.0 - exp(-20.0 * delta))
	_celebrate = lerpf(_celebrate, celebrate_target, ease)

	# Fins breathe like a cloak at rest, fold behind the body for a fast dash, then snap forward in
	# opposite directions at contact. Landing spreads both fins toward the wall as a handless brace.
	var beat: float = sin(_time * TAU / IDLE_PERIOD)
	var flutter: float = sin(_time * 4.2) * (0.035 + speed * 0.025)
	var brace_flare: float = brace * 0.34
	_fin_l.rotation = _fin_l_rest - _fold * 0.66 + _slice * 0.62 - brace_flare + flutter
	_fin_r.rotation = _fin_r_rest + _fold * 0.66 - _slice * 0.62 + brace_flare - flutter
	var spear_shift := Vector2(76.0 * _fold + 38.0 * _slice, -28.0 * _fold - 92.0 * _slice)
	_fin_l.position = _fin_l_position + spear_shift
	_fin_r.position = _fin_r_position + Vector2(-spear_shift.x, spear_shift.y)
	var span: float = 1.0 - _fold * 0.16 + _slice * 0.14 + brace * 0.06
	_fin_l.scale = _fin_scale_rest * Vector2(span, 1.0 + _slice * 0.08)
	_fin_r.scale = _fin_scale_rest * Vector2(span, 1.0 + _slice * 0.08)

	# The layered body inhales slowly. The hood follows turns and impacts a fraction behind the fins,
	# while the mask stays readable and looks into a sideways charge.
	_rear_cloak.scale = _cloak_rest_scale * Vector2(1.0 + beat * 0.014, 1.0 - beat * 0.012)
	_rear_cloak.position = _cloak_rest_position + Vector2(
		0.0, sin(_time * TAU / IDLE_PERIOD - 0.5) * 3.0 + _flinch * 12.0
	)
	_hood.position = _hood_rest + Vector2(
		clampf(movement_direction.x, -1.0, 1.0) * speed * 7.0,
		sin(_time * 1.45 - 0.7) * 2.5 + _flinch * 7.0
	)
	_hood.rotation = clampf(movement_direction.x, -1.0, 1.0) * (0.045 + speed * 0.04) - _flinch * 0.12
	_mask.position = _mask_rest + Vector2(0.0, sin(_time * 1.2 + 0.4) * 1.8)
	_mask.rotation = -_hood.rotation * 0.32

	# The core is the anticipation/readability anchor: it swells before launch and flashes at the cut.
	var core_pulse: float = sin(_time * 5.0) * 0.035
	var core_scale: float = 1.0 + core_pulse + maxf(0.0, _charge) * 0.2 + _slice * 0.16
	_core.scale = _core_rest_scale * core_scale
	var light: float = 1.0 + maxf(0.0, _charge) * 0.42
	var fade: float = 1.0 + minf(0.0, _charge) * 0.7
	_core.modulate = Color(light, light, light, fade)

	# Flames remain two separate living accents. During the spear pose they stretch into forward
	# blades; on selection they fan apart, giving the storefront a readable flourish.
	var flame_stretch: float = 1.0 + speed * 0.16 + maxf(0.0, _charge) * 0.08
	var flame_span: float = 1.0 - _fold * 0.18 + _celebrate * 0.16
	_flame_l.scale = _flame_scale_rest * Vector2(flame_span, flame_stretch)
	_flame_r.scale = _flame_scale_rest * Vector2(flame_span, flame_stretch)
	for index: int in _flame_springs.size():
		var spring: ChainSpring = _flame_springs[index]
		spring.bias = (-0.1 if index == 0 else 0.1) * (_fold - _celebrate)
		spring.sway_rate = lerpf(3.4 + float(index) * 0.25, 11.0, speed)
		spring.step(delta, _time)

	_front_flap.bias = speed * 0.12 - brace * 0.15
	_front_flap.step(delta, _time)
	_shadow_tail.rotation = sin(_time * 1.3) * 0.025 - _flinch * 0.08
	for index: int in _ribbons.size():
		var ribbon_spring: ChainSpring = _ribbons[index].spring
		ribbon_spring.straighten = speed * 0.92
		ribbon_spring.bias = (0.08 if index == 0 else -0.08) * (_fold + _slice)
		ribbon_spring.sway_tip = lerpf(0.2, 0.07, speed)
		ribbon_spring.sway_rate = lerpf(1.7 + float(index) * 0.3, 10.0 + float(index), speed)
		_ribbons[index].step(delta, _time)


func _on_state_started(state_name: StringName) -> void:
	match state_name:
		DASH_START:
			_front_flap.impulse(-3.0)
			_impulse_ribbons(-4.0, 4.0)
		ATTACK:
			_front_flap.impulse(5.0)
			_impulse_ribbons(7.0, -7.0)
			_burst.restart()
			_burst.emitting = true
		DASH_END:
			_front_flap.impulse(4.0)
			_impulse_ribbons(5.5, -5.5)
		HIT_REACTION:
			_front_flap.impulse(-5.0)
			_impulse_ribbons(-6.0, 6.0)
		CHARACTER_SELECTED, CHARACTER_UNLOCKED:
			_front_flap.impulse(2.5)
			_impulse_ribbons(-4.5, 4.5)
			_burst.restart()
			_burst.emitting = true


func _impulse_ribbons(left: float, right: float) -> void:
	if _ribbons.size() < 2:
		return
	_ribbons[0].spring.impulse(left)
	_ribbons[1].spring.impulse(right)


func _apply_reduced_pose() -> void:
	if not is_node_ready() or _ribbons.is_empty():
		return
	_fin_l.rotation = _fin_l_rest
	_fin_r.rotation = _fin_r_rest
	_fin_l.position = _fin_l_position
	_fin_r.position = _fin_r_position
	_fin_l.scale = _fin_scale_rest
	_fin_r.scale = _fin_scale_rest
	_rear_cloak.position = _cloak_rest_position
	_rear_cloak.scale = _cloak_rest_scale
	_hood.position = _hood_rest
	_hood.rotation = 0.0
	_mask.position = _mask_rest
	_mask.rotation = 0.0
	_core.scale = _core_rest_scale
	_core.modulate = Color.WHITE
	_shadow_tail.rotation = 0.0
	_flame_l.rotation = _flame_l_rest
	_flame_r.rotation = _flame_r_rest
	_flame_l.scale = _flame_scale_rest
	_flame_r.scale = _flame_scale_rest
	_front_flap.reset()
	for spring: ChainSpring in _flame_springs:
		spring.reset()
	for ribbon: RibbonChain in _ribbons:
		ribbon.spring.reset()
