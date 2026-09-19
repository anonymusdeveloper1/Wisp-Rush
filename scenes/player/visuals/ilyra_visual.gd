class_name IlyraVisual
extends PlayableCharacterVisual
## Ilyra, the Astral Dancer: a Mythic rig built on skinned limbs rather than cut-out segments.
##
## Her torso, four arms and two legs are each one painting stretched over a three-bone chain
## ([RibbonChain]), so a shoulder, elbow, wrist, knee or ankle bends the paint instead of rotating a
## separate piece over its neighbour — which is what used to open seams at the joints. The parts that
## hang off a limb (hands, boots, head, skirt, sashes) are re-parented onto the bone that carries
## them at [method _ready], so they follow the deformation exactly.
##
## Motion is built out of chains: each joint eases at a slower rate than the one above it, so a
## gesture starts at the shoulder and arrives at the hand a couple of frames later, and that stagger
## is what reads as dance. Her waist twists against her chest, each fan opens and closes by rotating
## five ribs about one rivet, and five registered head paintings carry blinks and expression.
##
## Presentation only: the rig never touches collision, damage or scoring.

## Head paintings, in the order [member _heads] stores them.
enum Face { NEUTRAL, BLINK, FOCUSED, JOY, PAIN }

## Arm order everywhere in this script: her upper-left, upper-right, lower-left, lower-right. The
## upper pair carries the fans; the lower pair dances free.
const ARM_COUNT: int = 4
## Odd indices are her right side, where an authored angle is mirrored.
const ARM_SIDE: Array[float] = [1.0, -1.0, 1.0, -1.0]
## Bones per limb chain: shoulder/elbow/wrist, hip/knee/ankle, hips/waist/chest.
const JOINTS: int = 3
## How far a fan's ribs close toward the rivet when it folds (0 = shut, 1 = fully spread).
const FAN_SHUT: float = 0.12
## Where a fan's handle butt should sit in its hand's own frame: down the palm, not at the wrist.
##
## The part pack places each fan near its hand rather than in it — the handle's butt ends about 57 px
## past her fist — and draws the handle *over* the hand, so the fist reads as floating behind the
## thing it holds. The rig seats the handle in the palm and lifts the gripping hand in front of it.
const FAN_GRIP_IN_PALM: float = 45.0
## How far up the handle from its butt her fist closes. A grip holds a shaft part-way along, with the
## butt emerging on the far side of the fist — seating the butt itself in the palm reads as a fan
## balanced on top of her hand rather than held through it.
const FAN_GRIP_ABOVE_BUTT: float = 38.0
## Canvas order for a hand that is holding something, above the handle it wraps.
const GRIP_HAND_Z: int = 69
## Landing hold per arm — upper-left, upper-right, lower-left, lower-right — as
## (shoulder, elbow, wrist) offsets. Deliberately asymmetric: a climber takes the surface with one
## side and counterbalances with the other, which is what reads as *holding on* rather than standing
## to attention. Left arms bite, right arms swing free.
const GRIP_POSE: Array[Vector3] = [
	Vector3(1.15, -1.05, -0.55),
	Vector3(-0.6, 0.4, 0.25),
	Vector3(1.8, -1.55, -0.85),
	Vector3(0.3, 0.6, 0.35),
]
## How far each knee draws up on a landing. One leg folds under her and the other stays long, the
## way a climber's does; a matched pair reads as a curtsy.
const GRIP_KNEE: Array[float] = [1.4, 0.65]
## States where she is resting against a surface rather than flying at one.
const RESTING_STATES: Array[StringName] = [IDLE_HOVER, MOVE_FLY, AIM_CHARGE, DASH_END]
## Per-arm trail through a dash. Limbs stream behind at slightly different angles instead of
## collapsing onto one axis, so the dive reads as a body hurtling rather than an arrow.
const DASH_TRAIL: Array[float] = [0.34, 0.16, -0.22, -0.4]
## How a leg folds when she meets a surface: hip forward, knee back hard, ankle forward again.
const LEG_BEND: Array[float] = [0.34, -0.52, 0.28]
## How a torso twist distributes along hips, waist and chest.
const TORSO_TWIST: Array[float] = [1.0, -0.6, 0.35]
## Seconds a blink holds, and the range between blinks.
const BLINK_HOLD: float = 0.1
const BLINK_GAP: Vector2 = Vector2(2.6, 6.4)
## Which bone of which limb each hanging part rides. Re-parenting onto the bone is what keeps a hand
## on the end of a bending arm and the skirt on a twisting waist.
const BONE_RIDERS: Dictionary[StringName, Array] = {
	&"Torso": [
		[&"SkirtPanel1", &"SkirtPanel2", &"SkirtPanel3", &"SkirtPanel4", &"SkirtPanel5",
			&"SkirtPanel6", &"Sash1", &"Sash2", &"Sash3", &"Sash4", &"LegL", &"LegR"],
		[&"HeartGlow", &"HeartCore"],
		[&"HeadNeutral", &"HeadBlink", &"HeadFocused", &"HeadJoy", &"HeadPain", &"HairBack",
			&"ShoulderOrnamentL", &"ShoulderOrnamentR", &"ArmUl", &"ArmUr", &"ArmLl", &"ArmLr"],
	],
	&"ArmUl": [[], [], [&"HandGripL"]],
	&"ArmUr": [[], [], [&"HandGripR"]],
	&"ArmLl": [[], [], [&"HandOpenL", &"HandCupL"]],
	&"ArmLr": [[], [], [&"HandOpenR", &"HandCupR"]],
	&"LegL": [[], [], [&"BootL"]],
	&"LegR": [[], [], [&"BootR"]],
}

## Smoothed accents; each state picks targets and every part reads them at its own rate.
var _gather: float = 0.0
var _spread: float = 0.0
var _fold: float = 0.0
var _slash: float = 0.0
var _guard: float = 0.0
var _glow: float = 0.0
var _crown_rise: float = 1.0
var _orbit_speed: float = 0.5
var _orbit_angle: float = 0.0
var _twist: float = 0.0
var _brace: float = 0.0
var _bloom_amount: float = 0.0
## Reach: the lower hands stretch out and take hold of whatever surface she has landed on.
var _grip: float = 0.0
## The dash itself is her attack, so the fans stay out as blades and cut the whole way through.
var _cut: float = 0.0
## The dash's sweep, eased slower than the cut so the arcs grow into it instead of popping open.
var _sweep: float = 0.0

## Per-joint offsets from the authored rest pose, mirrored on application so the two sides stay
## symmetric without ever storing a signed angle. Indexed `arm * JOINTS + joint`.
var _arm_delta: PackedFloat32Array = PackedFloat32Array()
var _arm_bones: Array[Node2D] = []
var _arm_rest: PackedFloat32Array = PackedFloat32Array()
var _leg_bones: Array[Node2D] = []
var _leg_rest: PackedFloat32Array = PackedFloat32Array()
var _torso_bones: Array[Node2D] = []
var _torso_rest: PackedFloat32Array = PackedFloat32Array()

var _fan_ribs: Array[Node2D] = []
var _fan_rib_rest: PackedFloat32Array = PackedFloat32Array()
var _fan_membranes: Array[Node2D] = []
var _fan_membrane_scales: PackedVector2Array = PackedVector2Array()
var _fan_lit: Array[CanvasItem] = []
var _fan_arcs: Array[CanvasItem] = []
var _arc_rest_scale: PackedVector2Array = PackedVector2Array()
var _skirt: Array[Node2D] = []
var _skirt_springs: Array[ChainSpring] = []
var _ribbons: Array[RibbonChain] = []
var _braids: Array[RibbonChain] = []
var _crowns: Array[Node2D] = []
var _crown_rest: PackedVector2Array = PackedVector2Array()
var _crown_rest_rotation: PackedFloat32Array = PackedFloat32Array()
var _crown_centre: Vector2 = Vector2.ZERO
var _heads: Array[CanvasItem] = []
var _face: Face = Face.NEUTRAL
var _blink_timer: float = 0.0
var _blink_hold: float = 0.0

var _core_scale: Vector2 = Vector2.ONE
var _glow_scale: Vector2 = Vector2.ONE
var _ring_scale: Vector2 = Vector2.ONE

@onready var _torso: RibbonChain = %Torso
@onready var _heart_core: Node2D = %HeartCore
@onready var _heart_glow: CanvasItem = %HeartGlow
@onready var _ring: Node2D = %VfxRing
@onready var _bloom: Node2D = %VfxBloom
@onready var _burst: GPUParticles2D = %AttackParticles


func _ready() -> void:
	super()
	_mount_riders()
	var arms: Array[RibbonChain] = [%ArmUl, %ArmUr, %ArmLl, %ArmLr]
	_arm_bones = _collect_bones(arms)
	_arm_rest = _capture_rest(_arm_bones)
	_arm_delta.resize(_arm_bones.size())
	var legs: Array[RibbonChain] = [%LegL, %LegR]
	_leg_bones = _collect_bones(legs)
	_leg_rest = _capture_rest(_leg_bones)
	_torso_bones = _collect_bones([_torso] as Array[RibbonChain])
	_torso_rest = _capture_rest(_torso_bones)
	# Both fans come from one authored mechanism, so the ribs interleave: left a..e, then right a..e.
	_fan_ribs = [
		%FanRibA, %FanRibB, %FanRibC, %FanRibD, %FanRibE,
		%FanRibAR, %FanRibBR, %FanRibCR, %FanRibDR, %FanRibER,
	]
	_fan_rib_rest.resize(_fan_ribs.size())
	for index: int in _fan_ribs.size():
		_fan_rib_rest[index] = _fan_ribs[index].rotation
	_seat_fan(%FanHandle as Node2D, %HandGripL as Node2D)
	_seat_fan(%FanHandleR as Node2D, %HandGripR as Node2D)
	_fan_membranes = [%FanMembrane, %FanMembraneR]
	for membrane: Node2D in _fan_membranes:
		_fan_membrane_scales.append(membrane.scale)
	_fan_lit = [_sprite(%FanMembraneLit), _sprite(%FanMembraneLitR)]
	_fan_arcs = [_sprite(%VfxFanArc), _sprite(%VfxFanArcR)]
	for arc: CanvasItem in _fan_arcs:
		_arc_rest_scale.append((arc as Node2D).scale)
	_skirt = [%SkirtPanel1, %SkirtPanel2, %SkirtPanel3, %SkirtPanel4, %SkirtPanel5, %SkirtPanel6]
	# One spring per panel: they are siblings, not a chain, so each keeps its own rest fan-out and
	# only the sway phase steps across them, which is what makes the hem breathe as a wave.
	for index: int in _skirt.size():
		var panel: Array[Node2D] = [_skirt[index]]
		var spring := ChainSpring.new()
		spring.setup(panel, float(index) * 0.8)
		spring.stiffness = 70.0
		spring.damping = 9.0
		spring.lag_root = 0.5
		spring.lag_tip = 0.5
		spring.max_offset = 0.5
		spring.sway_root = 0.06
		spring.sway_tip = 0.06
		spring.sway_rate = 1.5
		_skirt_springs.append(spring)
	_ribbons = [%Sash1, %Sash2, %Sash3, %Sash4]
	for index: int in _ribbons.size():
		var spring: ChainSpring = _ribbons[index].spring
		spring.stiffness = 52.0
		spring.damping = 8.0
		spring.softening = 0.5
		spring.lag_root = 0.32
		spring.lag_tip = 0.92
		spring.max_offset = 0.55
		spring.sway_rate = 1.5 + index * 0.3
	_braids = [%BraidL, %BraidR]
	for index: int in _braids.size():
		var spring: ChainSpring = _braids[index].spring
		spring.stiffness = 64.0
		spring.damping = 9.5
		spring.softening = 0.55
		spring.lag_root = 0.38
		spring.lag_tip = 0.88
		spring.max_offset = 0.5
		spring.sway_rate = 1.2 + index * 0.35
	_crowns = [%CrownStar, %CrownShardL, %CrownShardR]
	for crown: Node2D in _crowns:
		_crown_rest.append(crown.position)
		_crown_rest_rotation.append(crown.rotation)
		_crown_centre += crown.position
	_crown_centre /= float(_crowns.size())
	_heads = [
		_sprite(%HeadNeutral), _sprite(%HeadBlink), _sprite(%HeadFocused),
		_sprite(%HeadJoy), _sprite(%HeadPain),
	]
	_core_scale = _heart_core.scale
	_glow_scale = (_heart_glow as Node2D).scale
	_ring_scale = _ring.scale
	_blink_timer = randf_range(BLINK_GAP.x, BLINK_GAP.y)
	_show_face(Face.NEUTRAL)
	_update_effects(0.0)
	if _reduced_motion:
		_apply_reduced_pose()


## Moves every hanging part onto the bone that actually carries it.
##
## The generated scene parents a part to the limb *node*, which is the limb's root. That is right for
## a rigid cutout but wrong for a skinned one: a hand parented to the arm's root would stay put while
## the elbow bends under it. Re-parenting keeps the global transform, and the bones are still at
## their rest pose here, so each part lands with exactly the local offset it was authored with.
func _mount_riders() -> void:
	for limb_name: StringName in BONE_RIDERS:
		var limb := get_node_or_null(NodePath("%" + limb_name)) as RibbonChain
		if limb == null:
			continue
		var bones: Array[Node2D] = limb.get_bones()
		var per_bone: Array = BONE_RIDERS[limb_name]
		for bone_index: int in per_bone.size():
			if bone_index >= bones.size():
				continue
			for rider_name: StringName in per_bone[bone_index]:
				var rider := get_node_or_null(NodePath("%" + rider_name)) as Node2D
				if rider != null:
					rider.reparent(bones[bone_index], true)


## Flattens every limb's bones into one array indexed `limb * JOINTS + joint`.
func _collect_bones(limbs: Array[RibbonChain]) -> Array[Node2D]:
	var bones: Array[Node2D] = []
	for limb: RibbonChain in limbs:
		var own: Array[Node2D] = limb.get_bones()
		for joint: int in JOINTS:
			bones.append(own[joint] if joint < own.size() else limb)
	return bones


func _capture_rest(bones: Array[Node2D]) -> PackedFloat32Array:
	var rest := PackedFloat32Array()
	rest.resize(bones.size())
	for index: int in bones.size():
		rest[index] = bones[index].rotation
	return rest


## Moves [param fan] so its handle ends in [param hand]'s palm, and draws the hand in front of it.
##
## The handle's butt is its own local `(0, length)` turned by the fan's rotation in the hand's frame;
## solving for the position that lands it on the palm keeps whatever angle the pack authored, so the
## fan still points the way it was designed to.
func _seat_fan(fan: Node2D, hand: Node2D) -> void:
	var handle: Sprite2D = fan.get_node(^"Sprite") as Sprite2D
	if handle == null or handle.texture == null:
		return
	# Distance from the rivet (the part's pivot) down to the butt of the handle, then back up the
	# shaft to the point her fingers actually close on.
	var length: float = handle.texture.get_height() * 0.5 + handle.offset.y
	var held: Vector2 = Vector2(0.0, length - FAN_GRIP_ABOVE_BUTT).rotated(fan.rotation)
	fan.position = Vector2(0.0, FAN_GRIP_IN_PALM) - held
	var grip: Sprite2D = hand.get_node(^"Sprite") as Sprite2D
	if grip != null:
		grip.z_index = GRIP_HAND_Z


## The Sprite2D a generated part node draws with; the pivot node carries the transform.
func _sprite(pivot: Node) -> CanvasItem:
	return pivot.get_node(^"Sprite") as CanvasItem


func _update_secondary_motion(delta: float) -> void:
	if _reduced_motion:
		return
	var speed: float = get_speed()
	var ease_rate: float = 1.0 - exp(-10.0 * delta)
	var gather_target: float = 0.0
	var spread_target: float = 0.0
	var fold_target: float = 0.0
	var slash_target: float = 0.0
	var cut_target: float = 0.0
	var guard_target: float = 0.0
	var glow_target: float = 0.18 + speed * 0.3
	var orbit_target: float = 0.5
	var rise_target: float = 1.0
	var face: Face = Face.NEUTRAL
	match _current_state:
		MOVE_FLY:
			spread_target = 0.14
			orbit_target = 0.9
		AIM_CHARGE:
			# The free hands cup around the heart while the fan arms cock outward and the ring closes.
			gather_target = 0.9
			spread_target = 0.3
			glow_target = 0.85
			orbit_target = 1.9
			face = Face.FOCUSED
		DASH_START:
			# She winds the fans back and opens them as blades: the dash is the attack.
			fold_target = 0.55
			cut_target = 0.7
			glow_target = 0.7
			orbit_target = 2.4
			face = Face.FOCUSED
		DASH_LOOP:
			# A spearhead that cuts: arms drawn onto the travel axis, both fans held out as edges.
			fold_target = 0.7
			cut_target = 1.0
			glow_target = 0.55
			orbit_target = 2.6
			face = Face.FOCUSED
		DASH_END:
			spread_target = 0.9
			glow_target = 0.5
		ATTACK:
			slash_target = 1.0
			cut_target = 1.0
			spread_target = 0.35
			glow_target = 1.0
			orbit_target = 3.2
			face = Face.FOCUSED
		HIT_REACTION:
			guard_target = 1.0
			glow_target = 0.2
			face = Face.PAIN
		DEATH:
			fold_target = 1.0
			gather_target = 0.8
			glow_target = -0.6
			orbit_target = 0.1
			rise_target = 0.05
			face = Face.PAIN
		REVIVE_SPAWN:
			spread_target = 0.5
			glow_target = 0.95
			orbit_target = 2.0
			face = Face.JOY
		VICTORY, CHARACTER_SELECTED:
			spread_target = 1.0
			glow_target = 0.8
			orbit_target = 2.2
			face = Face.JOY
		CHARACTER_UNLOCKED:
			# The Mythic flourish is a radial dance pose, not a particle burst.
			spread_target = 1.3
			glow_target = 1.0
			orbit_target = 3.0
			face = Face.JOY
	_brace = get_landing()
	_gather = lerpf(_gather, gather_target, ease_rate)
	_spread = lerpf(_spread, maxf(spread_target, _brace * 0.7), 1.0 - exp(-14.0 * delta))
	_fold = lerpf(_fold, maxf(fold_target - _brace * 0.5, 0.0), 1.0 - exp(-16.0 * delta))
	_slash = lerpf(_slash, slash_target, 1.0 - exp(-16.0 * delta))
	_cut = lerpf(_cut, cut_target, 1.0 - exp(-14.0 * delta))
	_sweep = lerpf(_sweep, cut_target, 1.0 - exp(-7.0 * delta))
	_guard = lerpf(_guard, guard_target, 1.0 - exp(-18.0 * delta))
	_glow = lerpf(_glow, glow_target, ease_rate)
	_crown_rise = lerpf(_crown_rise, rise_target, 1.0 - exp(-6.0 * delta))
	_orbit_speed = lerpf(_orbit_speed, orbit_target, 1.0 - exp(-4.0 * delta))
	# She holds on for as long as she is against a wall, not just while arriving at one.
	#
	# `get_landing()` only rises during the last moments of a *live dash* — `WispPlayer` returns 0 the
	# instant the dash ends — so driving the hold from it alone put the pose in flight and dropped it
	# by the time she was actually standing there. What matters at rest is the surface she is on: the
	# floor's inward normal points up, a side wall's is sideways and a ceiling's points down, so this
	# reads 0 on the floor and 1 on anything she has to hold onto.
	var cling: float = 0.0
	if _current_state in RESTING_STATES:
		cling = clampf(1.0 - surface_normal.dot(Vector2.UP), 0.0, 1.0)
	_grip = lerpf(_grip, maxf(_brace, cling), 1.0 - exp(-13.0 * delta))
	var bloom_target: float = 1.0 if _current_state in [REVIVE_SPAWN, CHARACTER_UNLOCKED] else 0.0
	_bloom_amount = lerpf(_bloom_amount, bloom_target, 1.0 - exp(-7.0 * delta))

	_update_face(delta, face)
	_update_arms(delta, speed)
	_update_legs(delta)
	_update_torso(delta, speed)
	_update_fans(delta)
	_update_core()
	_orbit_angle += delta * _orbit_speed
	_place_crown()
	_update_cloth(delta, speed)
	_update_effects(delta)


## One painting at a time. Blinks only interrupt her calm face, so a wince or a grin is never cut.
func _update_face(delta: float, wanted: Face) -> void:
	if _blink_hold > 0.0:
		_blink_hold -= delta
	else:
		_blink_timer -= delta
		if _blink_timer <= 0.0 and wanted == Face.NEUTRAL:
			_blink_hold = BLINK_HOLD
			_blink_timer = randf_range(BLINK_GAP.x, BLINK_GAP.y)
	var shown: Face = Face.BLINK if (_blink_hold > 0.0 and wanted == Face.NEUTRAL) else wanted
	if shown != _face:
		_show_face(shown)


func _show_face(face: Face) -> void:
	_face = face
	for index: int in _heads.size():
		_heads[index].visible = index == int(face)


## Four arms, three bones each. The shoulder leads, the elbow follows and the wrist arrives last: the
## falling ease rates are the whole trick, and the paint bends with them instead of splitting.
func _update_arms(delta: float, speed: float) -> void:
	var rates: Array[float] = [
		1.0 - exp(-13.0 * delta), 1.0 - exp(-9.0 * delta), 1.0 - exp(-6.5 * delta),
	]
	for arm: int in ARM_COUNT:
		var upper_pair: bool = arm < 2
		var mirrored: bool = arm % 2 == 1
		var phase: float = float(arm) * 1.15 + (0.0 if upper_pair else PI)
		# Her resting choreography: two waves at different rates so the loop never reads as a metronome.
		var shoulder: float = sin(_time * 1.35 + phase) * 0.30 + sin(_time * 0.62 + phase * 0.5) * 0.14
		var elbow: float = sin(_time * 1.1 + phase + 0.7) * 0.26
		var wrist: float = sin(_time * 0.95 + phase + 1.4) * 0.22
		if upper_pair:
			# The fan arms follow the strike through, a beat behind the free hands.
			var cross: float = _slash * (1.5 if arm == 0 else 1.05)
			shoulder += _spread * 0.45 - cross + _guard * 0.18
			elbow += _spread * 0.32 - _slash * 0.8
			wrist += _spread * 0.2 - _slash * 0.5
		else:
			# The free hands lead an attack: they punch out along the travel axis before the fans move.
			shoulder += (
				_spread * 0.55 - _gather * 0.72 - _slash * 1.5 + _guard * (0.55 if mirrored else -0.3)
			)
			elbow += _gather * 1.05 + _spread * 0.28 - _slash * 1.25 + _guard * 0.4
			wrist += _gather * 0.5 + _spread * 0.2 - _slash * 0.55
		# Landing: she takes hold of the surface rather than standing on it — see [constant GRIP_POSE].
		var hold: Vector3 = GRIP_POSE[arm]
		shoulder = lerpf(shoulder, hold.x, _grip)
		elbow = lerpf(elbow, hold.y, _grip)
		wrist = lerpf(wrist, hold.z, _grip)
		# Folding streams every limb behind her, each at its own angle.
		shoulder = lerpf(shoulder, DASH_TRAIL[arm], _fold)
		elbow = lerpf(elbow, DASH_TRAIL[arm] * 0.5, _fold)
		wrist = lerpf(wrist, DASH_TRAIL[arm] * 0.3, _fold)
		var side: float = ARM_SIDE[arm]
		var targets: Array[float] = [shoulder, elbow, wrist]
		for joint: int in JOINTS:
			var index: int = arm * JOINTS + joint
			_arm_delta[index] = lerpf(_arm_delta[index], targets[joint], rates[joint])
			_arm_bones[index].rotation = _arm_rest[index] + _arm_delta[index] * side
	# At speed the fan arms tip toward the heading so the dive keeps reading forward.
	var tip: float = clampf(movement_direction.x, -1.0, 1.0) * speed * 0.12
	_arm_bones[0].rotation += tip
	_arm_bones[JOINTS].rotation += tip
	# Her left hand closes on whatever she holds — the surface on a landing, her heart while charging.
	# The right stays open as the counterweight, which is what makes the hold read as one-sided.
	var biting: bool = _grip > 0.45 or _gather > 0.5
	var counter: bool = _gather > 0.5
	_sprite(%HandCupL).visible = biting
	_sprite(%HandOpenL).visible = not biting
	_sprite(%HandCupR).visible = counter
	_sprite(%HandOpenR).visible = not counter


## Knees and ankles fold as she meets a wall, then push back up.
func _update_legs(delta: float) -> void:
	var rate: float = 1.0 - exp(-15.0 * delta)
	# The hold folds her legs too, not just the moment of arrival: `_brace` is zero once the dash ends,
	# so keying the knees off it alone left her standing straight-legged against the wall.
	var bend: float = maxf(maxf(_brace, _grip), _fold * 0.3)
	for leg: int in 2:
		var side: float = 1.0 if leg == 0 else -1.0
		# One leg folds under her and the other stays long; a matched pair reads as a curtsy.
		var reach: float = bend * lerpf(1.0, GRIP_KNEE[leg], _grip)
		for joint: int in JOINTS:
			var index: int = leg * JOINTS + joint
			_leg_bones[index].rotation = lerpf(
				_leg_bones[index].rotation,
				_leg_rest[index] + reach * LEG_BEND[joint] * side,
				rate
			)


## The waist twists against the chest. This is the dancer's counter-rotation, and most of why she
## reads as moving rather than swaying: everything below the waist follows it a beat late.
func _update_torso(delta: float, speed: float) -> void:
	var twist_target: float = (
		sin(_time * 0.72) * 0.07
		+ clampf(movement_direction.x, -1.0, 1.0) * speed * 0.09
		- _gather * 0.05
		+ _guard * 0.12
		+ _grip * 0.3
	)
	_twist = lerpf(_twist, twist_target, 1.0 - exp(-7.0 * delta))
	var breath: float = sin(_time * TAU / 2.6) * 0.02
	for joint: int in JOINTS:
		if joint >= _torso_bones.size():
			break
		_torso_bones[joint].rotation = lerpf(
			_torso_bones[joint].rotation,
			_torso_rest[joint] + (_twist + breath) * TORSO_TWIST[joint],
			1.0 - exp(-9.0 * delta)
		)


## A fan is five ribs and a membrane on one rivet: closing it rotates every rib home and collapses
## the cloth, so the fold is a mechanism rather than a cross-fade between two paintings.
func _update_fans(delta: float) -> void:
	var rate: float = 1.0 - exp(-14.0 * delta)
	for index: int in _fan_ribs.size():
		# The two fans breathe against each other, half a beat apart.
		var fan: int = index / 5
		var breathe: float = 0.08 + sin(_time * 0.85 + float(fan) * PI) * 0.08
		# Folding narrows them, but a cut holds them open: she slices with the blades, not a closed fan.
		var open: float = lerpf(1.0 - breathe, FAN_SHUT, _fold) + _spread * 0.12 + _slash * 0.2
		open = lerpf(open, 0.85, _cut)
		_fan_ribs[index].rotation = lerpf(
			_fan_ribs[index].rotation, _fan_rib_rest[index] * open, rate
		)
	for index: int in _fan_membranes.size():
		var base: Vector2 = _fan_membrane_scales[index]
		var narrow: float = lerpf(1.0, FAN_SHUT + 0.06, _fold)
		_fan_membranes[index].scale = Vector2(base.x * narrow, base.y)
		# The cloth lights up through the whole cut, and an arc trails each blade while she is cutting.
		_fan_lit[index].modulate.a = clampf(maxf(_slash, _cut * 0.7) * 1.4 - 0.2, 0.0, 1.0)
		var arc: float = maxf(_slash, _cut)
		_fan_arcs[index].modulate.a = clampf(arc * 1.6 - 0.25, 0.0, 1.0)
		_fan_arcs[index].visible = arc > 0.05
		# The blade sweeps ahead of her as she travels, so the edge leads the dive.
		var lead: float = -1.0 if index == 0 else 1.0
		var arc_node: Node2D = _fan_arcs[index] as Node2D
		arc_node.rotation = lerpf(arc_node.rotation, _cut * 0.8 * lead, rate)
		# A dash is one wide sweep she travels inside, not two small flicks: the arcs stretch out
		# along the travel axis until they read as a single edge carried across the arena.
		arc_node.scale = _arc_rest_scale[index] * Vector2(
			1.0 + _sweep * 1.5, 1.0 + _sweep * 0.6
		)


func _update_core() -> void:
	var glow: float = maxf(0.0, _glow)
	var pulse: float = 0.92 + sin(_time * 2.4) * 0.07 + glow * 0.3
	_heart_core.scale = _core_scale * pulse
	(_heart_glow as Node2D).scale = _glow_scale * (0.8 + glow * 0.8)
	_heart_glow.modulate.a = clampf(0.25 + glow * 0.75 + minf(0.0, _glow), 0.0, 1.0)


func _place_crown() -> void:
	for index: int in _crowns.size():
		var angle: float = _orbit_angle + float(index) * TAU / float(_crowns.size())
		var depth: float = sin(angle)
		var crown: Node2D = _crowns[index]
		var drift := Vector2(cos(angle) * 26.0, depth * 12.0)
		# The ring lifts clear of her head at rest and settles onto her as she dies.
		crown.position = _crown_centre.lerp(_crown_rest[index], _crown_rise) + drift * _crown_rise
		crown.rotation = _crown_rest_rotation[index] - _orbit_angle * 0.4
		var glow: float = maxf(0.0, _glow)
		crown.scale = Vector2.ONE * (0.9 + depth * 0.08) * (1.0 + glow * 0.16)
		var light: float = 0.9 + glow * 0.5 + minf(0.0, _glow) * 0.8
		crown.modulate = Color(light, light, light, clampf(_crown_rise, 0.0, 1.0))


## Skirt, sashes and braids: the same accents on different delays, so nothing moves in unison.
func _update_cloth(delta: float, speed: float) -> void:
	for index: int in _skirt_springs.size():
		# Her left panels rest at positive angles and her right at negative ones, so `outward` is the
		# sign that opens a panel away from the body; folding drives every panel back toward zero.
		var outward: float = 1.0 if index < 3 else -1.0
		var spring: ChainSpring = _skirt_springs[index]
		# A single-joint chain halves `bias`, so these are twice the angle they read as.
		spring.bias = outward * (_spread * 0.5 - _gather * 0.44 - _fold * 1.0) - speed * 0.06
		spring.sway_rate = lerpf(1.5, 5.5, speed)
		spring.step(delta, _time)
	for index: int in _ribbons.size():
		var spring: ChainSpring = _ribbons[index].spring
		spring.straighten = speed * 0.9 * (1.0 - _brace * 0.5)
		spring.sway_tip = lerpf(0.14, 0.09, speed)
		spring.sway_rate = lerpf(1.5 + index * 0.3, 8.0 + index, speed)
		_ribbons[index].step(delta, _time)
	for index: int in _braids.size():
		var spring: ChainSpring = _braids[index].spring
		spring.straighten = speed * 0.8
		spring.sway_tip = lerpf(0.12, 0.08, speed)
		spring.sway_rate = lerpf(1.2 + index * 0.35, 7.0 + index, speed)
		_braids[index].step(delta, _time)


## The charge ring and the unlock bloom. Scale and fade are written every frame even while hidden:
## setting them only on the frame one appears makes the reveal a snap, which the rig's smoothness
## check rightly rejects, so `_ready` settles them here too.
func _update_effects(delta: float) -> void:
	_ring.scale = _ring_scale * lerpf(1.5, 0.45, _gather)
	_ring.rotation += delta * 1.6
	(_ring.get_node(^"Sprite") as CanvasItem).modulate.a = clampf(_gather * 0.9, 0.0, 1.0)
	_ring.visible = _gather > 0.02
	_bloom.scale = Vector2.ONE * lerpf(0.6, 1.8, _bloom_amount)
	(_bloom.get_node(^"Sprite") as CanvasItem).modulate.a = _bloom_amount * 0.75
	_bloom.visible = _bloom_amount > 0.02


func _on_state_started(state_name: StringName) -> void:
	match state_name:
		DASH_END:
			for index: int in _ribbons.size():
				_ribbons[index].spring.impulse(3.0 if index % 2 == 0 else -3.0)
			for index: int in _braids.size():
				_braids[index].spring.impulse(2.6 if index == 0 else -2.6)
			for index: int in _skirt_springs.size():
				_skirt_springs[index].impulse(2.2 if index < 3 else -2.2)
		ATTACK:
			# A Mythic kill throws a ring of star fragments as the hands punch through.
			if not _reduced_motion and is_visible_in_tree() and not _preview_mode:
				_burst.restart()
				_burst.emitting = true
			for index: int in _ribbons.size():
				_ribbons[index].spring.impulse(-3.6 if index % 2 == 0 else 3.6)
			for index: int in _skirt_springs.size():
				_skirt_springs[index].impulse(-1.8 if index < 3 else 1.8)
		HIT_REACTION:
			for ribbon: RibbonChain in _ribbons:
				ribbon.spring.impulse(4.2)
			for braid: RibbonChain in _braids:
				braid.spring.impulse(-4.0)
			for spring: ChainSpring in _skirt_springs:
				spring.impulse(3.4)
		CHARACTER_UNLOCKED:
			if not _reduced_motion and is_visible_in_tree():
				_burst.restart()
				_burst.emitting = true
			for index: int in _ribbons.size():
				_ribbons[index].spring.impulse(2.4 if index % 2 == 0 else -2.4)


func _apply_reduced_pose() -> void:
	if not is_node_ready() or _skirt_springs.is_empty():
		return
	_gather = 0.0
	_spread = 0.0
	_fold = 0.0
	_slash = 0.0
	_guard = 0.0
	_glow = 0.0
	_crown_rise = 1.0
	_twist = 0.0
	_brace = 0.0
	_grip = 0.0
	_bloom_amount = 0.0
	_blink_hold = 0.0
	_show_face(Face.NEUTRAL)
	for index: int in _arm_bones.size():
		_arm_delta[index] = 0.0
		_arm_bones[index].rotation = _arm_rest[index]
	for index: int in _leg_bones.size():
		_leg_bones[index].rotation = _leg_rest[index]
	for index: int in _torso_bones.size():
		_torso_bones[index].rotation = _torso_rest[index]
	_sprite(%HandCupL).visible = false
	_sprite(%HandCupR).visible = false
	_sprite(%HandOpenL).visible = true
	_sprite(%HandOpenR).visible = true
	for index: int in _fan_ribs.size():
		_fan_ribs[index].rotation = _fan_rib_rest[index]
	_sweep = 0.0
	_cut = 0.0
	for index: int in _fan_membranes.size():
		_fan_membranes[index].scale = _fan_membrane_scales[index]
		_fan_lit[index].modulate.a = 0.0
		_fan_arcs[index].visible = false
		(_fan_arcs[index] as Node2D).scale = _arc_rest_scale[index]
	_burst.emitting = false
	_update_core()
	_update_effects(0.0)
	for spring: ChainSpring in _skirt_springs:
		spring.bias = 0.0
		spring.reset()
	for ribbon: RibbonChain in _ribbons:
		ribbon.spring.reset()
	for braid: RibbonChain in _braids:
		braid.spring.reset()
	_place_crown()
