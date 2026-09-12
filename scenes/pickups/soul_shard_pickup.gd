class_name SoulShardPickup
extends Node2D
## Run-currency pickup collected by dash sweeps or short-range attraction to the Wisp.

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
	_remaining -= delta
	_sprite.rotation += delta * 1.8
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


func _collect() -> void:
	if _collected:
		return
	_collected = true
	collected.emit(1)
	var collect_tween: Tween = create_tween().set_parallel(true)
	collect_tween.tween_property(_sprite, "scale", _sprite.scale * 1.5, 0.15)
	collect_tween.tween_property(_sprite, "modulate:a", 0.0, 0.15)
	collect_tween.chain().tween_callback(queue_free)
