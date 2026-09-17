class_name VfxPool
extends Node2D
## Pooled one-shot sprite effects (slices, trails, bursts) with no per-effect node allocation.
##
## `play()` reuses a hidden Sprite2D, animates scale and alpha manually in `_process` and hides it
## when done. When every sprite is busy, the effect closest to finishing is recycled.
## Effects blend additively by default: the redesign VFX sheet is authored for additive/screen
## blending, so glows stay luminous on the charcoal floor instead of reading as flat stickers.
## The static helpers are shared by other glow sprites (enemy hit flashes, Reaper reticle).

const POOL_SIZE: int = 24

## Whether pooled effects use the shared additive material; set before the pool enters the tree.
@export var additive_blend: bool = true

var _sprites: Array[Sprite2D] = []
var _elapsed := PackedFloat32Array()
var _duration := PackedFloat32Array()
var _start_alpha := PackedFloat32Array()
var _start_scale := PackedVector2Array()
var _end_scale := PackedVector2Array()
## Flight effects move from `_flight_from` to `_flight_to`; `_flying` marks those slots.
var _flight_from := PackedVector2Array()
var _flight_to := PackedVector2Array()
var _flying := PackedByteArray()

static var _additive_material: CanvasItemMaterial


func _ready() -> void:
	for index: int in POOL_SIZE:
		var sprite := Sprite2D.new()
		sprite.visible = false
		if additive_blend:
			sprite.material = get_additive_material()
		add_child(sprite)
		_sprites.append(sprite)
	_elapsed.resize(POOL_SIZE)
	_duration.resize(POOL_SIZE)
	_start_alpha.resize(POOL_SIZE)
	_start_scale.resize(POOL_SIZE)
	_end_scale.resize(POOL_SIZE)
	_flight_from.resize(POOL_SIZE)
	_flight_to.resize(POOL_SIZE)
	_flying.resize(POOL_SIZE)


func _process(delta: float) -> void:
	for slot: int in POOL_SIZE:
		if _duration[slot] <= 0.0:
			continue
		_elapsed[slot] += delta
		var progress: float = minf(1.0, _elapsed[slot] / _duration[slot])
		var eased: float = 1.0 - (1.0 - progress) * (1.0 - progress)
		var sprite: Sprite2D = _sprites[slot]
		sprite.scale = _start_scale[slot].lerp(_end_scale[slot], eased)
		if _flying[slot] != 0:
			# A flight stays visible until it lands, then fades in its last fifth.
			sprite.global_position = _flight_from[slot].lerp(_flight_to[slot], progress * progress)
			sprite.modulate.a = _start_alpha[slot] * minf(1.0, (1.0 - progress) * 5.0)
		else:
			sprite.modulate.a = _start_alpha[slot] * (1.0 - progress)
		if progress >= 1.0:
			_duration[slot] = 0.0
			sprite.visible = false


## Plays `texture` at `world_position`, easing from `start_scale` to `end_scale` while fading out
## over `duration` seconds. Returns the pool slot used.
func play(
		texture: Texture2D,
		world_position: Vector2,
		rotation_radians: float = 0.0,
		start_scale: Vector2 = Vector2.ONE,
		end_scale: Vector2 = Vector2.ONE,
		duration: float = 0.25,
		tint: Color = Color.WHITE,
	) -> int:
	var slot: int = _claim_slot()
	var sprite: Sprite2D = _sprites[slot]
	sprite.texture = texture
	sprite.global_position = world_position
	sprite.rotation = rotation_radians
	sprite.scale = start_scale
	sprite.modulate = tint
	sprite.visible = true
	_elapsed[slot] = 0.0
	_duration[slot] = maxf(0.01, duration)
	_start_alpha[slot] = tint.a
	_start_scale[slot] = start_scale
	_end_scale[slot] = end_scale
	_flying[slot] = 0
	return slot


## Plays `texture` flying from `from_position` to `to_position` (canvas coordinates) over `duration`
## seconds, easing in and scaling from `start_scale` to `end_scale`. Used by RUSH soul orbs.
func play_flight(
		texture: Texture2D,
		from_position: Vector2,
		to_position: Vector2,
		start_scale: Vector2 = Vector2.ONE,
		end_scale: Vector2 = Vector2.ONE,
		duration: float = 0.3,
		tint: Color = Color.WHITE,
	) -> int:
	var slot: int = play(texture, from_position, 0.0, start_scale, end_scale, duration, tint)
	_flight_from[slot] = from_position
	_flight_to[slot] = to_position
	_flying[slot] = 1
	return slot


## Returns how many pooled effects are currently playing.
func get_active_count() -> int:
	var count: int = 0
	for slot: int in _duration.size():
		if _duration[slot] > 0.0:
			count += 1
	return count


## Hides every effect immediately.
func clear() -> void:
	for slot: int in _sprites.size():
		_duration[slot] = 0.0
		_sprites[slot].visible = false


## Returns the one shared additive-blend material; sharing it keeps 2D batching intact.
static func get_additive_material() -> CanvasItemMaterial:
	if _additive_material == null:
		_additive_material = CanvasItemMaterial.new()
		_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive_material


## Returns a 0–1 blink for telegraphs that speeds up as `progress` (0–1) nears the event, so
## warnings communicate *when* as well as *where*. Starts fully lit.
static func countdown_blink(progress: float, cycles: float = 3.0) -> float:
	var clamped: float = clampf(progress, 0.0, 1.0)
	return 0.5 + 0.5 * cos(clamped * clamped * TAU * cycles)


func _claim_slot() -> int:
	var recycled_slot: int = 0
	var highest_progress: float = -1.0
	for slot: int in POOL_SIZE:
		if _duration[slot] <= 0.0:
			return slot
		var progress: float = _elapsed[slot] / _duration[slot]
		if progress > highest_progress:
			highest_progress = progress
			recycled_slot = slot
	return recycled_slot
