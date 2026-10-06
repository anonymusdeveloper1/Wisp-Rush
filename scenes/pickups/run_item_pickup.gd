class_name RunItemPickup
extends Node2D
## One physical item drop, collected once by a passing dash or touching the Wisp.

## A known item reached the Wisp; emitted at most once.
signal collected(item_id: StringName)
const DRAWN_SIZE: float = 128.0
const COLLECT_RADIUS: float = 30.0
var _item: RunItemData
var _target: WispPlayer
var _scale: float = 1.0
var _remaining: float = 14.0
var _collected: bool = false
var _time: float = 0.0
@onready var _sprite: Sprite2D = %Sprite


## Supplies item identity, the player, viewport width and floor lifetime before the node is added.
func configure(item: RunItemData, target: WispPlayer, width: float, lifetime: float) -> void:
	_item = item
	_target = target
	_scale = maxf(0.1, width / 1080.0)
	_remaining = lifetime
	if is_node_ready():
		_apply_art()


func _ready() -> void:
	_apply_art()


func _apply_art() -> void:
	if _item != null:
		_sprite.texture = _item.get_icon()
		_sprite.scale = Vector2.ONE * (DRAWN_SIZE * _scale / 256.0)


func _physics_process(delta: float) -> void:
	if _collected or get_tree().paused:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	_time += delta
	_sprite.position.y = roundf(sin(_time * 3.0)) * 4.0 * _scale
	if is_instance_valid(_target) and _target.get_current_health() > 0:
		if global_position.distance_to(_target.global_position) <= COLLECT_RADIUS * _scale:
			_collect()


## Collects only when this live dash reaches the pickup's collision area.
func try_dash_collect(from: Vector2, to: Vector2, radius: float) -> bool:
	if _collected or _item == null:
		return false
	if DashGeometry.distance_to_segment(global_position, from, to) > radius + COLLECT_RADIUS * _scale:
		return false
	_collect()
	return true


func _collect() -> void:
	if _collected or _item == null:
		return
	_collected = true
	collected.emit(_item.item_id)
	queue_free()
