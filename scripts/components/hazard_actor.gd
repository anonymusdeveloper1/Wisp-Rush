class_name HazardActor
extends Node2D
## Shared arrival, scaling, focus and collision-query contract for sparse arena hazards.

## Common arrival lifecycle; subclasses define ACTIVE-state cycles and geometry.
enum State { TELEGRAPH, ACTIVE }

const SOURCE_FRAME_SIZE: float = 362.0

## Collision, timing and visual values for this hazard instance.
@export var tuning: HazardTuning
## Optional sprite shown while the arrival warning plays (an amber-rimmed or closed variant).
@export var telegraph_texture: Texture2D
## Optional sprite shown once ACTIVE; without it the scene's own Sprite texture returns.
@export var active_texture: Texture2D

var state: State = State.TELEGRAPH
var _world_speed: float = 1.0
var _viewport_scale: float = 1.0
var _arrival_remaining: float = 0.0
var _base_sprite_scale: Vector2 = Vector2.ONE
var _scene_texture: Texture2D

@onready var _sprite: Sprite2D = %Sprite
@onready var _warning: Sprite2D = %Warning
@onready var _shadow: Sprite2D = %Shadow


func _ready() -> void:
	assert(tuning != null, "%s requires HazardTuning" % name)
	_arrival_remaining = tuning.arrival_telegraph
	_sprite.modulate.a = 0.2
	_scene_texture = _sprite.texture
	if telegraph_texture != null:
		_sprite.texture = telegraph_texture
	_warning.visible = true
	_warning.material = VfxPool.get_additive_material()
	_apply_visual_scale()


func _physics_process(delta: float) -> void:
	if state == State.TELEGRAPH:
		_update_arrival(delta)
	else:
		_advance_hazard(delta * _world_speed)


## Applies a 0.05–1.0 Wisp Focus multiplier to hazard simulation.
func set_world_speed(multiplier: float) -> void:
	_world_speed = clampf(multiplier, 0.05, 1.0)


## Rescales design-coordinate art and collision to the live viewport width.
func set_viewport_width(viewport_width: float) -> void:
	_viewport_scale = maxf(0.1, viewport_width / tuning.design_width)
	_apply_visual_scale()


## Returns whether this active hazard stops a dash instead of taking damage.
func blocks_dash() -> bool:
	return false


## Returns the live solid radius used by dash-blocking hazards.
func get_blocking_radius() -> float:
	return tuning.blocking_radius * _viewport_scale if state == State.ACTIVE else 0.0


## Returns current dangerous circles as world x/y/radius triples.
func get_dangerous_circles() -> Array[Vector3]:
	return []


## Returns this hazard's authored wave threat cost.
func get_threat_cost() -> int:
	return tuning.threat_cost


## Subclass hook for active cycle/rotation; delta already includes Wisp Focus.
func _advance_hazard(_scaled_delta: float) -> void:
	pass


## Subclass hook fired when the arrival warning completes; the base swaps in the active art.
func _on_became_active() -> void:
	_sprite.texture = active_texture if active_texture != null else _scene_texture


func _update_arrival(delta: float) -> void:
	_arrival_remaining -= delta * _world_speed
	var progress: float = 1.0 - clampf(
		_arrival_remaining / maxf(tuning.arrival_telegraph, 0.001),
		0.0,
		1.0,
	)
	_sprite.modulate.a = lerpf(0.2, 1.0, progress)
	# Amber ring claims the area and blinks faster as the hazard lands.
	_warning.modulate.a = lerpf(0.45, 1.0, VfxPool.countdown_blink(progress))
	_warning.scale = _base_sprite_scale * lerpf(0.5, 1.4, progress)
	if _arrival_remaining <= 0.0:
		state = State.ACTIVE
		_sprite.modulate = Color.WHITE
		_warning.visible = false
		_on_became_active()


func _apply_visual_scale() -> void:
	if not is_node_ready() or tuning == null:
		return
	_base_sprite_scale = Vector2.ONE * (
		tuning.sprite_diameter * _viewport_scale / SOURCE_FRAME_SIZE
	)
	_sprite.scale = _base_sprite_scale
	_shadow.scale = Vector2(_base_sprite_scale.x * 0.9, _base_sprite_scale.y * 0.45)
	_warning.scale = _base_sprite_scale
