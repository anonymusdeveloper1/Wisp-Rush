class_name SoulShardPickup
extends Node2D
## Rift Points pickup (a soul shard) collected by dash sweeps or short-range attraction to the Wisp.
##
## GameWorld's auto-collect sweep (`sweep_to`) flies every floor shard to the Wisp at wave and boss
## changes and before the run ends; every path collects through `collected` exactly once.

## Emitted once when the shard reaches or is swept by the player.
signal collected(amount: int)

const SOURCE_FRAME_SIZE: float = 362.0
const COLLECT_RADIUS_DESIGN: float = 30.0
const ATTRACTION_SPEED_DESIGN: float = 520.0
const LIFETIME: float = 14.0

var _target: Node2D
var _viewport_scale: float = 1.0
var _attraction_radius: float = 150.0
var _remaining: float = LIFETIME
var _collected: bool = false
## Auto-collect sweep: start position, elapsed and total seconds; `_sweep_seconds` < 0 = not sweeping.
var _sweep_from: Vector2 = Vector2.ZERO
var _sweep_elapsed: float = 0.0
var _sweep_seconds: float = -1.0
var _auto_collected: bool = false

@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	var final_scale: Vector2 = Vector2.ONE * (96.0 * _viewport_scale / SOURCE_FRAME_SIZE)
	_sprite.scale = final_scale
	var appear_tween: Tween = create_tween()
	_sprite.scale = Vector2.ZERO
	appear_tween.tween_property(_sprite, "scale", final_scale, 0.2).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if _collected:
		return
	_sprite.rotation += delta * 1.8
	if is_sweeping():
		_advance_sweep(delta)
		return
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	if not is_instance_valid(_target):
		return
	var distance: float = global_position.distance_to(_target.global_position)
	if distance <= _attraction_radius * _viewport_scale:
		global_position = global_position.move_toward(
			_target.global_position,
			ATTRACTION_SPEED_DESIGN * _viewport_scale * delta,
		)
	if global_position.distance_to(_target.global_position) <= COLLECT_RADIUS_DESIGN * _viewport_scale:
		_collect()


## Configures target, attraction distance and viewport scaling for this dropped shard.
func configure(target: Node2D, attraction_radius: float, viewport_width: float) -> void:
	_target = target
	_attraction_radius = maxf(0.0, attraction_radius)
	_viewport_scale = maxf(0.1, viewport_width / 1080.0)
	if is_node_ready():
		_sprite.scale = Vector2.ONE * (96.0 * _viewport_scale / SOURCE_FRAME_SIZE)


## Updates attraction distance after Soul Hunger changes level.
func set_attraction_radius(attraction_radius: float) -> void:
	_attraction_radius = maxf(0.0, attraction_radius)


## Starts the auto-collect sweep (GDD §5.6): normal attraction and the lifetime stop, the shard eases to
## [param target] over [param seconds] and then collects through `collected`, exactly once. Returns
## false when the shard is already collected or already sweeping, so callers can count new flights.
func sweep_to(target: Node2D, seconds: float) -> bool:
	if _collected or is_sweeping():
		return false
	_target = target
	_auto_collected = true
	_sweep_from = global_position
	_sweep_elapsed = 0.0
	_sweep_seconds = maxf(0.01, seconds)
	return true


## Whether an auto-collect sweep is carrying this shard to the Wisp.
func is_sweeping() -> bool:
	return _sweep_seconds > 0.0 and not _collected


## Whether a sweep or `collect_now` took this shard (its collector plays one chime run instead of a
## sound per shard).
func is_auto_collected() -> bool:
	return _auto_collected


## Collects at once (e.g. right before the run summary is built); returns whether it counted now.
func collect_now() -> bool:
	if _collected:
		return false
	_auto_collected = true
	_collect()
	return true


## Collects when a swept dash segment reaches this shard; returns whether it connected.
func try_dash_collect(segment_start: Vector2, segment_end: Vector2, corridor_radius: float) -> bool:
	if _collected:
		return false
	var distance: float = DashGeometry.distance_to_segment(
		global_position,
		segment_start,
		segment_end,
	)
	if distance > corridor_radius + COLLECT_RADIUS_DESIGN * _viewport_scale:
		return false
	_collect()
	return true


func _advance_sweep(delta: float) -> void:
	_sweep_elapsed += delta
	var progress: float = minf(1.0, _sweep_elapsed / _sweep_seconds)
	# Ease in: the shard lifts off gently, then snaps into the Wisp.
	var eased: float = progress * progress
	var destination: Vector2 = _sweep_from
	if is_instance_valid(_target):
		destination = _target.global_position
	global_position = _sweep_from.lerp(destination, eased)
	if progress >= 1.0:
		_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	collected.emit(1)
	var collect_tween: Tween = create_tween().set_parallel(true)
	collect_tween.tween_property(_sprite, "scale", _sprite.scale * 1.5, 0.15)
	collect_tween.tween_property(_sprite, "modulate:a", 0.0, 0.15)
	collect_tween.chain().tween_callback(queue_free)
