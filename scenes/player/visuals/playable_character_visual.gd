class_name PlayableCharacterVisual
extends Node2D
## Shared presentation-only contract for an animated playable character.
##
## The owning [WispPlayer] stays authoritative for movement, damage and collision; this node only
## mirrors it. Whole-body motion (hover, squash and stretch, recoil, flourishes) is an
## AnimationPlayer library built at runtime and blended by an AnimationTree state machine. Heading
## is a damped spring, so turns ease in and overshoot a little instead of snapping. Each
## character's rig adds its own secondary motion (wings, ribbons, hands) in
## [method _update_secondary_motion].
##
## The rig is authored facing up: -Y is forward, +Y is behind (tails, trails), X is sideways.

## Emitted when the AnimationTree starts a new state (tests and debug overlays).
signal visual_state_changed(state_name: StringName)

const IDLE_HOVER: StringName = &"idle_hover"
const MOVE_FLY: StringName = &"move_fly"
const AIM_CHARGE: StringName = &"aim_charge"
const DASH_START: StringName = &"dash_start"
const DASH_LOOP: StringName = &"dash_loop"
const DASH_END: StringName = &"dash_end"
const ATTACK: StringName = &"attack"
const HIT_REACTION: StringName = &"hit_reaction"
const DEATH: StringName = &"death"
const REVIVE_SPAWN: StringName = &"revive_spawn"
const VICTORY: StringName = &"victory"
const CHARACTER_SELECTED: StringName = &"character_selected"
const CHARACTER_UNLOCKED: StringName = &"character_unlocked"

## The complete animation vocabulary every character supports.
const STATES: Array[StringName] = [
	IDLE_HOVER,
	MOVE_FLY,
	AIM_CHARGE,
	DASH_START,
	DASH_LOOP,
	DASH_END,
	ATTACK,
	HIT_REACTION,
	DEATH,
	REVIVE_SPAWN,
	VICTORY,
	CHARACTER_SELECTED,
	CHARACTER_UNLOCKED,
]
## Seamless loops; every other state is a one-shot that returns to the newest requested loop.
const LOOPS: Array[StringName] = [IDLE_HOVER, MOVE_FLY, AIM_CHARGE, DASH_LOOP, VICTORY]
## One-shots that start at once even while another one-shot plays (impacts, hits, a new dash).
const INTERRUPTS: Array[StringName] = [DEATH, HIT_REACTION, REVIVE_SPAWN, DASH_END, DASH_START]
## States that point the character's forward axis along its movement.
const HEADING_STATES: Array[StringName] = [DASH_START, DASH_LOOP, ATTACK]
## States that emit the movement trail and, for [constant DASH_PARTICLE_STATES], the dash accent.
const TRAIL_STATES: Array[StringName] = [MOVE_FLY, DASH_START, DASH_LOOP, ATTACK]
const DASH_PARTICLE_STATES: Array[StringName] = [DASH_START, DASH_LOOP, ATTACK]
## Cross-fade into action states, and the longer one into calm loops so landings settle.
const BLEND_TIME: float = 0.075
const SETTLE_BLEND_TIME: float = 0.14
## Longest integration step for the heading spring, in seconds.
const MAX_STEP: float = 1.0 / 120.0
## Seconds each state's animation runs; the loops are authored to repeat seamlessly.
const STATE_LENGTHS: Dictionary[StringName, float] = {
	IDLE_HOVER: 1.8,
	MOVE_FLY: 0.7,
	AIM_CHARGE: 0.52,
	DASH_START: 0.12,
	DASH_LOOP: 0.32,
	DASH_END: 0.17,
	ATTACK: 0.24,
	HIT_REACTION: 0.32,
	DEATH: 0.5,
	REVIVE_SPAWN: 0.58,
	VICTORY: 0.9,
	CHARACTER_SELECTED: 0.62,
	CHARACTER_UNLOCKED: 0.9,
}
## Single-key tracks for whatever a state leaves at rest.
const REST_POSITION: Array = [[0.0, Vector2.ZERO]]
const REST_SCALE: Array = [[0.0, Vector2.ONE]]
const REST_ROTATION: Array = [[0.0, 0.0]]
const REST_MODULATE: Array = [[0.0, Color.WHITE]]

## Animation libraries and state machines are identical for every rig with the same motion strengths,
## and hold no playback state, so they are built once and shared (the Shop builds nine rigs at once).
static var _shared_libraries: Dictionary[String, AnimationLibrary] = {}
## One machine for every rig: the state list and blend times are the same for all of them.
static var _shared_machines: Dictionary[StringName, AnimationNodeStateMachine] = {}
static var _shared_lengths: Dictionary[String, Dictionary] = {}

## Authored full-character height in rig pixels; it maps onto the controller's visual diameter.
@export_range(64.0, 2048.0, 1.0) var design_size: float = 512.0
## Rig-space point menus center on: the middle of the whole silhouette, tails and halo included.
@export var preview_center: Vector2 = Vector2.ZERO
## Strength of the shared squash and stretch (1 = elastic Veyra; a calm character uses less).
@export_range(0.0, 2.0, 0.01) var squash_amount: float = 1.0
## Strength of the shared bobs, lunges and recoils.
@export_range(0.0, 2.0, 0.01) var bounce_amount: float = 1.0
## Rotation that turns the authored forward axis (-Y) onto a movement direction's angle.
@export var forward_rotation_offset: float = PI * 0.5
## Heading spring while dashing: natural frequency in Hz and damping ratio (below 1 overshoots).
@export_range(0.5, 20.0, 0.1) var heading_frequency: float = 6.5
## Damping ratio of the dash heading spring.
@export_range(0.1, 2.0, 0.01) var heading_damping: float = 0.72
## Spring that returns the body upright at rest; quick enough that landing from a dive (upside
## down) rights the character in about a fifth of a second.
@export_range(0.5, 20.0, 0.1) var settle_frequency: float = 4.2
## Damping ratio of the upright spring.
@export_range(0.1, 2.0, 0.01) var settle_damping: float = 0.86
## Largest lean, in radians, toward a sideways aim while the finger is held.
@export_range(0.0, 1.5, 0.01) var aim_lean: float = 0.26
## Largest lean, in radians, toward a slow sideways move (the Frozen Choir edge drift).
@export_range(0.0, 1.5, 0.01) var move_lean: float = 0.28
## Emission share of the movement trail at full speed and when drifting slowly.
@export_range(0.0, 1.0, 0.01) var trail_ratio_fast: float = 1.0
## Emission share while drifting slowly.
@export_range(0.0, 1.0, 0.01) var trail_ratio_slow: float = 0.4

## Single-image forms only: the picture shown by the scene's optional %FormImage sprite, so every
## form in a menu gets the shared body motion even without a rig of its own.
@export var portrait_texture: Texture2D:
	set(value):
		portrait_texture = value
		if is_node_ready():
			_apply_portrait()

## Latest movement direction reported by the controller (unit length).
var movement_direction: Vector2 = Vector2.UP
## Latest movement amount reported by the controller: 0 at rest, 1 dashing.
var movement_amount: float = 0.0
## Inward normal of the wall the character stands on (its feet point the other way).
var surface_normal: Vector2 = Vector2.UP
## 0 in open flight, 1 at wall contact: the character turns its feet toward the wall as it arrives.
var landing: float = 0.0

## Smoothed movement amount (0..1) and accumulated animation time for rigs.
var _speed: float = 0.0
var _time: float = 0.0
var _gameplay_state: StringName = IDLE_HOVER
## Last state the controller requested, so a one-shot fires once per controller event.
var _last_request: StringName = &""
var _desired_state: StringName = IDLE_HOVER
var _current_state: StringName = &""
var _one_shot_remaining: float = 0.0
var _one_shot_state: StringName = &""
var _reduced_motion: bool = false
var _preview_mode: bool = false
var _heading: float = 0.0
var _heading_velocity: float = 0.0
var _heading_target: float = 0.0
var _animation_lengths: Dictionary[StringName, float] = {}
var _playback: AnimationNodeStateMachinePlayback

@onready var _motion_root: Node2D = %MotionRoot
## Optional movement trail and dash-only accent; a rig may have either, both or neither.
@onready var _trail_particles := get_node_or_null(^"%TrailParticles") as GPUParticles2D
@onready var _dash_particles := get_node_or_null(^"%DashParticles") as GPUParticles2D
@onready var _animation_player: AnimationPlayer = %AnimationPlayer
@onready var _animation_tree: AnimationTree = %AnimationTree


func _ready() -> void:
	_apply_portrait()
	_build_animations()
	_build_state_machine()
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = not _reduced_motion
	_playback = _animation_tree.get(&"parameters/playback") as AnimationNodeStateMachinePlayback
	if _playback != null:
		_playback.start(IDLE_HOVER, true)
	_current_state = IDLE_HOVER
	if _reduced_motion:
		_reset_motion_root()
	_apply_visibility()


## Hidden rigs cost nothing: the Shop leaves the character cards in the tree while another tab shows.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready():
		_apply_visibility()


func _process(delta: float) -> void:
	_time += delta
	if _one_shot_remaining > 0.0:
		_one_shot_remaining = maxf(0.0, _one_shot_remaining - delta)
		if _one_shot_remaining <= 0.0 and _one_shot_state != DEATH:
			_finish_one_shot()
	var speed_target: float = 0.0 if _preview_mode else clampf(movement_amount, 0.0, 1.0)
	_speed = lerpf(_speed, speed_target, 1.0 - exp(-10.0 * delta))
	_update_heading(delta)
	_update_secondary_motion(delta)


## Mirrors the controller each frame; never reads or writes gameplay collision.
##
## [param visual_height] is the controller's drawn size in its own units and [param alpha] its
## fade. [param direction] is the dash, drift or aim direction; [param speed_amount] runs from 0 at
## rest to 1 dashing. [param wall_normal] is the inward normal of the wall the character stands on,
## and [param landing_progress] how near a live dash is to its wall (see [member landing]).
func sync_controller(
		visual_height: float,
		alpha: float,
		gameplay_state: StringName,
		direction: Vector2,
		speed_amount: float,
		wall_normal: Vector2 = Vector2.UP,
		landing_progress: float = 0.0,
	) -> void:
	if not direction.is_zero_approx():
		movement_direction = direction.normalized()
	movement_amount = clampf(speed_amount, 0.0, 1.5)
	if not wall_normal.is_zero_approx():
		surface_normal = wall_normal.normalized()
	landing = clampf(landing_progress, 0.0, 1.0)
	scale = Vector2.ONE * (visual_height / maxf(1.0, design_size))
	modulate.a = alpha
	_gameplay_state = gameplay_state if gameplay_state in STATES else IDLE_HOVER
	request_state(_gameplay_state)


## Requests a standard state. One-shots finish before the newest requested loop returns, except the
## [constant INTERRUPTS] states, which start at once. Repeating the same request (the controller
## calls this every frame) never restarts a one-shot.
func request_state(state_name: StringName) -> void:
	if state_name not in STATES:
		state_name = IDLE_HOVER
	var new_request: bool = state_name != _last_request
	_last_request = state_name
	_desired_state = state_name
	var busy: bool = _one_shot_remaining > 0.0
	if state_name == DEATH:
		if new_request:
			_one_shot_remaining = 0.0
			_one_shot_state = DEATH
			_travel(DEATH, true)
		return
	if state_name in LOOPS:
		if not busy and _one_shot_state != DEATH:
			_travel(state_name)
		return
	if not new_request or (busy and state_name not in INTERRUPTS):
		return
	if _one_shot_state == DEATH and state_name != REVIVE_SPAWN:
		return
	_play_one_shot(state_name)


## Plays the character's dash-contact attack accent, then returns to its controller-requested loop.
## Ignored once the character is dying, so a kill on the fatal frame cannot cut the death short.
func play_attack() -> void:
	if _one_shot_state == DEATH:
		return
	_play_one_shot(ATTACK)


## Plays the selection flourish used by Home and the Shop preview.
func play_character_selected() -> void:
	_desired_state = IDLE_HOVER
	_play_one_shot(CHARACTER_SELECTED)


## Plays the stronger flourish shown when the character is bought.
func play_character_unlocked() -> void:
	_desired_state = IDLE_HOVER
	_play_one_shot(CHARACTER_UNLOCKED)


## Configures a menu preview: upright, no trails, idle between flourishes.
func set_preview_mode(enabled: bool) -> void:
	_preview_mode = enabled
	_heading = 0.0
	_heading_velocity = 0.0
	_heading_target = 0.0
	rotation = 0.0
	movement_amount = 0.0
	_speed = 0.0
	_desired_state = IDLE_HOVER
	_update_particles()


## Reduced Motion keeps readable poses and heading but stills loops, secondary motion and particles.
func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if not is_node_ready():
		return
	_animation_tree.active = not enabled and is_visible_in_tree()
	if enabled:
		_reset_motion_root()
		_apply_reduced_pose()
	_update_particles()


## Authored animation vocabulary, exposed for fixtures and character validation.
func get_animation_states() -> Array[StringName]:
	return STATES.duplicate()


## State currently playing in the AnimationTree, exposed for integration tests and debug fixtures.
func get_current_visual_state() -> StringName:
	return _current_state


## Full-height design basis used by [PlayableCharacterPreview].
func get_design_size() -> float:
	return design_size


## Length in seconds of one state's animation (0 for an unknown state).
func get_state_length(state_name: StringName) -> float:
	return _animation_lengths.get(state_name, 0.0)


## Smoothed movement amount, 0 at rest to 1 at full dash (secondary motion reads this).
func get_speed() -> float:
	return _speed


## How near a live dash is to its wall, 0 in open flight to 1 at contact (rigs brace with it).
func get_landing() -> float:
	return landing


## Rig-space box around every drawn layer in the current pose; sizing tests and fixtures compare it
## with [member design_size] and [member preview_center].
func get_layer_bounds() -> Rect2:
	var bounds := Rect2()
	var first: bool = true
	var to_rig: Transform2D = get_global_transform().affine_inverse()
	for node: Node in find_children("*", "Node2D", true, false):
		var corners := PackedVector2Array()
		if node is Sprite2D and (node as Sprite2D).texture != null:
			var rect: Rect2 = (node as Sprite2D).get_rect()
			corners = PackedVector2Array([
				rect.position, Vector2(rect.end.x, rect.position.y),
				rect.end, Vector2(rect.position.x, rect.end.y),
			])
		elif node is Polygon2D:
			corners = (node as Polygon2D).polygon
		else:
			continue
		var xform: Transform2D = to_rig * (node as Node2D).get_global_transform()
		for corner: Vector2 in corners:
			var point: Vector2 = xform * corner
			if first:
				bounds = Rect2(point, Vector2.ZERO)
				first = false
			else:
				bounds = bounds.expand(point)
	return bounds


## Extension point: per-character bones, ribbons, orbiters and material parameters.
func _update_secondary_motion(_delta: float) -> void:
	pass


## Extension point: a state just started (impulses for wings, ribbons, particles).
func _on_state_started(_state_name: StringName) -> void:
	pass


## Extension point: settle every procedural part at rest for Reduced Motion.
func _apply_reduced_pose() -> void:
	pass


## Feet on the wall: the body's up axis is the wall's inward normal, so a character resting on a
## side wall stands sideways and one under the ceiling hangs from it.
func get_standing_heading() -> float:
	return surface_normal.angle() + forward_rotation_offset


## Tilt toward [param direction] away from standing, clamped to [param limit] radians.
func _lean_toward(direction: Vector2, limit: float) -> float:
	if direction.is_zero_approx():
		return 0.0
	return clampf(angle_difference(surface_normal.angle(), direction.angle()), -limit, limit)


func _update_heading(delta: float) -> void:
	var frequency: float = settle_frequency
	var damping: float = settle_damping
	var standing: float = get_standing_heading()
	if _preview_mode:
		_heading_target = 0.0
	elif _gameplay_state in HEADING_STATES:
		# Dive head-first, then turn the feet toward the wall over the last moments of the flight.
		var dive: float = movement_direction.angle() + forward_rotation_offset
		_heading_target = dive + angle_difference(dive, standing) * smoothstep(0.0, 1.0, landing)
		frequency = heading_frequency
		damping = heading_damping
	elif _gameplay_state == DASH_END:
		# Landed: plant the feet while the impact squash plays.
		_heading_target = standing
		frequency = heading_frequency
		damping = heading_damping
	elif _gameplay_state == DEATH:
		# Hold the heading while dissolving, so a death never spins the character.
		frequency = heading_frequency
		damping = heading_damping
	elif _gameplay_state == MOVE_FLY:
		_heading_target = standing + _lean_toward(movement_direction, move_lean)
	elif _gameplay_state == AIM_CHARGE:
		_heading_target = standing + _lean_toward(movement_direction, aim_lean)
	else:
		_heading_target = standing
	var omega: float = TAU * frequency
	var remaining: float = minf(delta, 0.1)
	while remaining > 0.0:
		var step: float = minf(remaining, MAX_STEP)
		remaining -= step
		var error: float = wrapf(_heading_target - _heading, -PI, PI)
		var acceleration: float = (
			omega * omega * error - 2.0 * damping * omega * _heading_velocity
		)
		_heading_velocity += acceleration * step
		_heading = wrapf(_heading + _heading_velocity * step, -PI, PI)
	rotation = _heading


func _finish_one_shot() -> void:
	var finished: StringName = _one_shot_state
	if _desired_state not in LOOPS and _desired_state != finished:
		_play_one_shot(_desired_state)
		return
	_travel(_desired_state if _desired_state in LOOPS else _fallback_loop())


## Loop that fits the controller when a one-shot ends without a newer loop request.
func _fallback_loop() -> StringName:
	if _gameplay_state in LOOPS:
		return _gameplay_state
	return DASH_LOOP if _gameplay_state == DASH_START else IDLE_HOVER


func _play_one_shot(state_name: StringName) -> void:
	if state_name not in STATES:
		return
	if state_name in LOOPS:
		_travel(state_name)
		return
	var length: float = get_state_length(state_name)
	if state_name == _current_state and _one_shot_remaining > 0.0:
		# A multi-kill reports several contacts in one frame: hold the accent instead of snapping its
		# timeline back to the start for every enemy.
		_one_shot_remaining = maxf(_one_shot_remaining, length * 0.65)
		return
	_one_shot_state = state_name
	_one_shot_remaining = length
	_travel(state_name, true)


func _travel(state_name: StringName, restart: bool = false) -> void:
	if _playback == null:
		_current_state = state_name
		return
	if state_name == _current_state:
		if not restart:
			return
		_playback.start(state_name, true)
	else:
		_playback.travel(state_name)
	_current_state = state_name
	_update_particles()
	_on_state_started(state_name)
	visual_state_changed.emit(state_name)


func _apply_visibility() -> void:
	var shown: bool = is_visible_in_tree()
	set_process(shown)
	_animation_tree.active = shown and not _reduced_motion
	_update_particles()


func _update_particles() -> void:
	var live: bool = is_visible_in_tree() and not _preview_mode and not _reduced_motion
	if _trail_particles != null:
		_trail_particles.emitting = live and _current_state in TRAIL_STATES
		_trail_particles.amount_ratio = (
			trail_ratio_fast if _current_state in DASH_PARTICLE_STATES else trail_ratio_slow
		)
	if _dash_particles != null:
		_dash_particles.emitting = live and _current_state in DASH_PARTICLE_STATES


func _apply_portrait() -> void:
	var image := get_node_or_null(^"%FormImage") as Sprite2D
	if image != null:
		image.texture = portrait_texture


func _reset_motion_root() -> void:
	_motion_root.position = Vector2.ZERO
	_motion_root.rotation = 0.0
	_motion_root.scale = Vector2.ONE
	_motion_root.modulate = Color.WHITE


func _build_state_machine() -> void:
	var cached: AnimationNodeStateMachine = _shared_machines.get(&"all")
	if cached != null:
		_animation_tree.tree_root = cached
		return
	var machine := AnimationNodeStateMachine.new()
	for state_name: StringName in STATES:
		var animation_node := AnimationNodeAnimation.new()
		animation_node.animation = state_name
		machine.add_node(state_name, animation_node)
	# Direct edges keep reactions responsive and still cross-fade instead of snapping through idle.
	for from_state: StringName in STATES:
		for to_state: StringName in STATES:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			var settles: bool = to_state in [IDLE_HOVER, MOVE_FLY, AIM_CHARGE, VICTORY]
			transition.xfade_time = SETTLE_BLEND_TIME if settles else BLEND_TIME
			machine.add_transition(from_state, to_state, transition)
	_animation_tree.tree_root = machine
	_shared_machines[&"all"] = machine


func _build_animations() -> void:
	if _animation_player.has_animation_library(&""):
		_animation_player.remove_animation_library(&"")
	var key: String = "%.2f|%.2f" % [squash_amount, bounce_amount]
	var library: AnimationLibrary = _shared_libraries.get(key)
	if library == null:
		library = AnimationLibrary.new()
		var lengths: Dictionary[StringName, float] = {}
		for state_name: StringName in STATES:
			var animation: Animation = _make_animation(state_name)
			library.add_animation(state_name, animation)
			lengths[state_name] = animation.length
		_shared_libraries[key] = library
		_shared_lengths[key] = lengths
	_animation_lengths.assign(_shared_lengths[key])
	_animation_player.add_animation_library(&"", library)


## Shared whole-body motion. Squash and stretch act on the travel axis (local Y): a dash stretches
## the body long and thin, an impact flattens it against the wall, then it overshoots and settles.
func _make_animation(state_name: StringName) -> Animation:
	var animation := Animation.new()
	var keys: Dictionary[StringName, Array] = _body_keys(state_name)
	animation.length = STATE_LENGTHS.get(state_name, 0.5)
	animation.loop_mode = (
		Animation.LOOP_LINEAR if state_name in LOOPS else Animation.LOOP_NONE
	)
	var positions: Array = []
	for key: Array in keys.get(&"position", REST_POSITION):
		positions.append([key[0], (key[1] as Vector2) * bounce_amount])
	var scales: Array = []
	for key: Array in keys.get(&"scale", REST_SCALE):
		scales.append([key[0], Vector2.ONE + ((key[1] as Vector2) - Vector2.ONE) * squash_amount])
	_add_track(animation, ^"MotionRoot:position", positions)
	_add_track(animation, ^"MotionRoot:scale", scales)
	_add_track(animation, ^"MotionRoot:rotation", keys.get(&"rotation", REST_ROTATION))
	_add_track(animation, ^"MotionRoot:modulate", keys.get(&"modulate", REST_MODULATE))
	return animation


func _body_keys(state_name: StringName) -> Dictionary[StringName, Array]:
	match state_name:
		IDLE_HOVER:
			return {
				&"position": [
					[0.0, Vector2(0, 0)], [0.45, Vector2(0, -7)], [0.9, Vector2(0, 0)],
					[1.35, Vector2(0, 7)], [1.8, Vector2(0, 0)],
				],
				&"scale": [
					[0.0, Vector2(1.0, 1.0)], [0.45, Vector2(0.985, 1.02)], [0.9, Vector2(1.0, 1.0)],
					[1.35, Vector2(1.015, 0.985)], [1.8, Vector2(1.0, 1.0)],
				],
				&"rotation": [[0.0, -0.02], [0.9, 0.02], [1.8, -0.02]],
			}
		MOVE_FLY:
			return {
				&"position": [[0.0, Vector2(0, 0)], [0.35, Vector2(0, -5)], [0.7, Vector2(0, 0)]],
				&"scale": [
					[0.0, Vector2(1.02, 0.98)], [0.35, Vector2(0.97, 1.04)], [0.7, Vector2(1.02, 0.98)],
				],
				&"rotation": [[0.0, -0.03], [0.35, 0.03], [0.7, -0.03]],
			}
		AIM_CHARGE:
			# Pre-attack: the body coils back along its own axis and shivers, ready to be released.
			return {
				&"position": [
					[0.0, Vector2(0, 6)], [0.18, Vector2(0, 13)], [0.34, Vector2(0, 10)],
					[0.52, Vector2(0, 6)],
				],
				&"scale": [
					[0.0, Vector2(1.07, 0.93)], [0.18, Vector2(1.16, 0.85)],
					[0.34, Vector2(1.12, 0.89)], [0.52, Vector2(1.07, 0.93)],
				],
				&"rotation": [[0.0, -0.02], [0.18, 0.025], [0.34, -0.015], [0.52, -0.02]],
			}
		DASH_START:
			# Deep coil, then the body snaps into the blade profile it cuts with.
			return {
				&"position": [[0.0, Vector2(0, 4)], [0.05, Vector2(0, 11)], [0.12, Vector2(0, -8)]],
				&"scale": [
					[0.0, Vector2(1.06, 0.93)], [0.05, Vector2(1.24, 0.78)], [0.12, Vector2(0.78, 1.3)],
				],
			}
		DASH_LOOP:
			# A dive, not a float: long and thin along the travel axis, leading edge first.
			return {
				&"position": [[0.0, Vector2(0, -8)], [0.16, Vector2(0, -6)], [0.32, Vector2(0, -8)]],
				&"scale": [
					[0.0, Vector2(0.8, 1.27)], [0.16, Vector2(0.84, 1.22)], [0.32, Vector2(0.8, 1.27)],
				],
				&"rotation": [[0.0, -0.03], [0.16, 0.03], [0.32, -0.03]],
			}
		DASH_END:
			# Feet hit the wall: the body compresses over them, then pushes back up to a stand.
			return {
				&"position": [
					[0.0, Vector2(0, -6)], [0.05, Vector2(0, 9)], [0.11, Vector2(0, -3)],
					[0.17, Vector2(0, 0)],
				],
				&"scale": [
					[0.0, Vector2(0.84, 1.2)], [0.05, Vector2(1.28, 0.74)], [0.11, Vector2(0.93, 1.08)],
					[0.17, Vector2(1.0, 1.0)],
				],
			}
		ATTACK:
			return {
				&"position": [
					[0.0, Vector2(0, -6)], [0.06, Vector2(0, -16)], [0.15, Vector2(0, -3)],
					[0.24, Vector2(0, -6)],
				],
				&"scale": [
					[0.0, Vector2(0.86, 1.18)], [0.06, Vector2(0.78, 1.3)], [0.15, Vector2(1.06, 0.95)],
					[0.24, Vector2(0.87, 1.16)],
				],
				&"rotation": [[0.0, 0.0], [0.07, -0.12], [0.16, 0.09], [0.24, 0.0]],
				&"modulate": [
					[0.0, Color.WHITE], [0.05, Color(1.35, 1.35, 1.4)], [0.24, Color.WHITE],
				],
			}
		HIT_REACTION:
			return {
				&"position": [
					[0.0, Vector2(0, 0)], [0.05, Vector2(-16, 4)], [0.12, Vector2(11, -2)],
					[0.21, Vector2(-5, 1)], [0.32, Vector2(0, 0)],
				],
				&"scale": [
					[0.0, Vector2(1.0, 1.0)], [0.05, Vector2(1.16, 0.84)], [0.14, Vector2(0.94, 1.06)],
					[0.32, Vector2(1.0, 1.0)],
				],
				&"rotation": [[0.0, 0.0], [0.06, -0.2], [0.17, 0.1], [0.32, 0.0]],
				&"modulate": [
					[0.0, Color.WHITE], [0.05, Color(1.0, 0.55, 0.7)], [0.32, Color.WHITE],
				],
			}
		DEATH:
			# Fits inside the controller's death fade (PlayerTuning.death_duration): flare, then fold in.
			return {
				&"position": [[0.0, Vector2(0, 0)], [0.12, Vector2(0, -8)], [0.5, Vector2(0, -24)]],
				&"scale": [
					[0.0, Vector2(1.0, 1.0)], [0.1, Vector2(1.22, 1.16)], [0.5, Vector2(0.32, 0.4)],
				],
				&"rotation": [[0.0, 0.0], [0.12, -0.1], [0.5, 0.5]],
				&"modulate": [
					[0.0, Color.WHITE], [0.1, Color(1.35, 1.35, 1.45, 1.0)],
					[0.3, Color(0.72, 0.86, 1.0, 0.75)], [0.5, Color(0.35, 0.15, 0.65, 0.0)],
				],
			}
		REVIVE_SPAWN:
			return {
				&"position": [[0.0, Vector2(0, 14)], [0.34, Vector2(0, -6)], [0.58, Vector2(0, 0)]],
				&"scale": [
					[0.0, Vector2(0.2, 0.36)], [0.34, Vector2(1.12, 0.92)], [0.46, Vector2(0.96, 1.05)],
					[0.58, Vector2(1.0, 1.0)],
				],
				&"modulate": [
					[0.0, Color(0.5, 0.75, 1.0, 0.0)], [0.24, Color(1.2, 1.25, 1.3, 0.9)],
					[0.58, Color.WHITE],
				],
			}
		VICTORY:
			return {
				&"position": [[0.0, Vector2(0, 0)], [0.45, Vector2(0, -16)], [0.9, Vector2(0, 0)]],
				&"scale": [
					[0.0, Vector2(1.04, 0.96)], [0.2, Vector2(0.95, 1.08)], [0.45, Vector2(1.08, 1.08)],
					[0.9, Vector2(1.04, 0.96)],
				],
				&"rotation": [[0.0, -0.05], [0.45, 0.05], [0.9, -0.05]],
			}
		CHARACTER_SELECTED:
			return {
				&"position": [
					[0.0, Vector2(0, 0)], [0.1, Vector2(0, 5)], [0.3, Vector2(0, -26)],
					[0.48, Vector2(0, 3)], [0.62, Vector2(0, 0)],
				],
				&"scale": [
					[0.0, Vector2(1.0, 1.0)], [0.1, Vector2(1.1, 0.9)], [0.28, Vector2(0.92, 1.1)],
					[0.48, Vector2(1.1, 0.91)], [0.62, Vector2(1.0, 1.0)],
				],
				&"rotation": [[0.0, 0.0], [0.22, -0.08], [0.4, 0.06], [0.62, 0.0]],
			}
		CHARACTER_UNLOCKED:
			return {
				&"position": [[0.0, Vector2(0, 16)], [0.36, Vector2(0, -30)], [0.9, Vector2(0, 0)]],
				&"scale": [
					[0.0, Vector2(0.55, 0.7)], [0.36, Vector2(1.22, 1.22)], [0.58, Vector2(0.94, 1.06)],
					[0.9, Vector2(1.0, 1.0)],
				],
				&"rotation": [[0.0, -0.22], [0.36, 0.12], [0.58, -0.04], [0.9, 0.0]],
				&"modulate": [
					[0.0, Color(1.6, 1.6, 1.7, 0.4)], [0.36, Color(1.35, 1.35, 1.4)], [0.9, Color.WHITE],
				],
			}
	return {}


func _add_track(animation: Animation, path: NodePath, keys: Array) -> void:
	var track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, path)
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	animation.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	for key: Array in keys:
		animation.track_insert_key(track, key[0] as float, key[1])

