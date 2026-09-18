@tool
class_name ChainSpring
extends RefCounted
## Follow-through for a chain of pivots: tails, ribbons, scarves and bone segments.
##
## Every joint springs toward its rest angle plus a sway wave that travels down the chain. When a
## joint's parent turns in the world, the joint keeps part of its old world angle (lag) and the
## spring brings it back, so appendages trail behind turns and overshoot slightly before they
## settle. It is presentation only and knows nothing about gameplay.

## Longest integration step in seconds; longer frames are split so stiff springs stay stable.
const MAX_STEP: float = 1.0 / 120.0

## Joint stiffness in 1/s².
var stiffness: float = 90.0
## Joint damping in 1/s.
var damping: float = 11.0
## Share of the stiffness the last joint keeps (0..1): lower values make tips lazier.
var softening: float = 0.55
## Share of a parent's world turn each joint keeps as lag, at the root.
var lag_root: float = 0.35
## Share of a parent's world turn each joint keeps as lag, at the tip.
var lag_tip: float = 0.85
## Largest bend away from rest per joint, in radians.
var max_offset: float = 0.6
## Fastest lag a turn may add, in rad/s, so a very fast turn whips without snapping. It is a rate,
## not a per-frame cap, so the whip looks the same at 30, 60 and 120 fps.
var max_lag_rate: float = 13.0
## Sway wave amplitude at the root, in radians.
var sway_root: float = 0.03
## Sway wave amplitude at the tip, in radians.
var sway_tip: float = 0.14
## Sway wave speed in rad/s.
var sway_rate: float = 2.2
## Phase step between joints, so the wave travels down the chain.
var sway_phase_step: float = 0.9
## Fraction (0..1) of the rest curl removed, so a fast chain streams out straighter behind.
var straighten: float = 0.0
## Extra constant bend added to every joint (radians), scaled toward the tip.
var bias: float = 0.0

var _joints: Array[Node2D] = []
var _rest_angles: PackedFloat32Array = PackedFloat32Array()
var _offsets: PackedFloat32Array = PackedFloat32Array()
var _velocities: PackedFloat32Array = PackedFloat32Array()
var _parent_angles: PackedFloat32Array = PackedFloat32Array()
var _phase_offset: float = 0.0


## Takes over [param joints], root first; each joint's current rotation becomes its rest angle.
func setup(joints: Array[Node2D], phase_offset: float = 0.0) -> void:
	_joints = joints.duplicate()
	_phase_offset = phase_offset
	var count: int = _joints.size()
	_rest_angles.resize(count)
	_offsets.resize(count)
	_velocities.resize(count)
	_parent_angles.resize(count)
	for index: int in count:
		_rest_angles[index] = _joints[index].rotation
		_offsets[index] = 0.0
		_velocities[index] = 0.0
		_parent_angles[index] = _parent_world_angle(index)


## Advances the chain by [param delta] seconds at animation time [param time].
func step(delta: float, time: float) -> void:
	var count: int = _joints.size()
	if count == 0 or delta <= 0.0:
		return
	for index: int in count:
		# Lag: keep part of the parent's world turn since last frame, as a free pendulum would.
		var parent_angle: float = _parent_world_angle(index)
		var turned: float = wrapf(parent_angle - _parent_angles[index], -PI, PI)
		_parent_angles[index] = parent_angle
		var share: float = _share(index)
		var lag_limit: float = max_lag_rate * delta
		_offsets[index] -= clampf(
			turned * lerpf(lag_root, lag_tip, share), -lag_limit, lag_limit
		)
		var target: float = _target_offset(index, share, time)
		var joint_stiffness: float = stiffness * lerpf(1.0, softening, share)
		var remaining: float = minf(delta, 0.1)
		while remaining > 0.0:
			var dt: float = minf(remaining, MAX_STEP)
			remaining -= dt
			var acceleration: float = (
				(target - _offsets[index]) * joint_stiffness - _velocities[index] * damping
			)
			_velocities[index] += acceleration * dt
			_offsets[index] += _velocities[index] * dt
		_offsets[index] = clampf(_offsets[index], -max_offset, max_offset)
		_joints[index].rotation = _rest_angles[index] + _offsets[index]


## Kicks every joint by [param angular_velocity] (rad/s), scaled toward the tip, e.g. on an impact.
func impulse(angular_velocity: float) -> void:
	for index: int in _joints.size():
		_velocities[index] += angular_velocity * lerpf(0.4, 1.0, _share(index))


## Returns the chain to its rest pose at once (Reduced Motion, respawn).
func reset() -> void:
	for index: int in _joints.size():
		_offsets[index] = 0.0
		_velocities[index] = 0.0
		_joints[index].rotation = _rest_angles[index]
		_parent_angles[index] = _parent_world_angle(index)


## Current bend of joint [param index] away from rest, in radians (for tests and debugging).
func get_offset(index: int) -> float:
	return _offsets[index] if index >= 0 and index < _offsets.size() else 0.0


## Number of joints in the chain.
func get_joint_count() -> int:
	return _joints.size()


func _share(index: int) -> float:
	var count: int = _joints.size()
	return 0.0 if count <= 1 else float(index) / float(count - 1)


func _target_offset(index: int, share: float, time: float) -> float:
	var wave: float = sin(time * sway_rate - float(index) * sway_phase_step + _phase_offset)
	var sway: float = wave * lerpf(sway_root, sway_tip, share)
	# The root joint's rest angle aims the whole chain; only inner joints carry the painted curl.
	var curl: float = 0.0 if index == 0 else -_rest_curl(index) * straighten
	return sway + curl + bias * lerpf(0.5, 1.0, share)


func _rest_curl(index: int) -> float:
	return wrapf(_rest_angles[index], -PI, PI)


func _parent_world_angle(index: int) -> float:
	var parent := _joints[index].get_parent() as Node2D
	return parent.global_rotation if parent != null and parent.is_inside_tree() else 0.0
