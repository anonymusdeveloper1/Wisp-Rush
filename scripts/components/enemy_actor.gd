class_name EnemyActor
extends Node2D
## Shared telegraph, health, swept-hit, focus, slow and dissolve behavior for regular enemies.

## Emitted once after lethal damage, before the dissolve releases this enemy.
signal killed(
	enemy: EnemyActor,
	world_position: Vector2,
	score_reward: int,
	experience_reward: int,
	damage_event_id: int,
)

## Shared lifecycle states; subclasses own behavior only while ACTIVE.
enum State { TELEGRAPH, ACTIVE, DYING }

const SOURCE_FRAME_SIZE: float = 362.0
## Overbright sprite modulate for the brief flash toward soul white when a hit lands.
const HIT_FLASH_MODULATE: Color = Color(1.9, 2.0, 2.05, 1.0)
const HIT_FLASH_DURATION: float = 0.12
## Share of the dissolve spent collapsing toward the core before bursting outward.
const DISSOLVE_INWARD_SHARE: float = 0.3
## Scale an enemy pops in from as its telegraph resolves.
const ARRIVAL_POP_SCALE: float = 0.72
## Seconds the arrival pop takes to settle.
const ARRIVAL_POP_DURATION: float = 0.22

## Movement, collision, durability and reward values for this archetype.
@export var tuning: EnemyTuning
## Whether ACTIVE-state movement advances; deterministic tutorial targets disable it.
@export var movement_enabled: bool = true

var state: State = State.TELEGRAPH
var _health: int = 1
var _target_position: Vector2 = Vector2.ZERO
var _last_edge_position: Vector2 = Vector2.ZERO
var _world_speed: float = 1.0
var _viewport_scale: float = 1.0
var _arena_rect: Rect2 = Rect2()
## Painted floor as a screen-space polygon. Empty keeps the legacy rectangle containment.
var _arena_polygon: PackedVector2Array = PackedVector2Array()
var _base_sprite_scale: Vector2 = Vector2.ONE

var _telegraph_remaining: float = 0.0
var _slow_remaining: float = 0.0
var _slow_multiplier: float = 1.0
var _last_damage_event_id: int = -1
var _flash_tween: Tween
var _arrival_tween: Tween

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _arrival_ring: Sprite2D = %ArrivalRing
@onready var _hit_flash: Sprite2D = %HitFlash


func _ready() -> void:
	assert(tuning != null, "%s requires EnemyTuning" % name)
	_health = tuning.maximum_health
	_telegraph_remaining = tuning.telegraph_duration
	_target_position = position
	_last_edge_position = position
	_sprite.modulate.a = 0.22
	_sprite.play(&"idle")
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_arrival_ring.visible = true
	_hit_flash.visible = false
	_hit_flash.material = VfxPool.get_additive_material()
	_arrival_ring.material = VfxPool.get_additive_material()
	_apply_visual_scale()


func _physics_process(delta: float) -> void:
	_update_slow(delta)
	match state:
		State.TELEGRAPH:
			_update_telegraph(delta)
		State.ACTIVE:
			_advance_active(delta * _world_speed * _slow_multiplier)


## Updates the steering target chosen by the owning run system.
func set_target_position(world_position: Vector2) -> void:
	_target_position = world_position


## Updates the most recent Wisp landing used by predictive enemy actions.
func set_last_edge_position(world_position: Vector2) -> void:
	_last_edge_position = world_position


## Applies a 0.05–1.0 run-local simulation multiplier such as Wisp Focus.
func set_world_speed(multiplier: float) -> void:
	_world_speed = clampf(multiplier, 0.05, 1.0)


## Rescales design-coordinate movement, collision and art to the live viewport width.
func set_viewport_width(viewport_width: float) -> void:
	_viewport_scale = maxf(0.1, viewport_width / tuning.design_width)
	_apply_visual_scale()


## Supplies live bounds used to keep mobile enemies readable inside the arena.
## Applies the painted floor as a polygon, so enemies stay off the lava and the ice pillars.
func set_arena_polygon(polygon: PackedVector2Array) -> void:
	_arena_polygon = polygon


func set_arena_rect(rect: Rect2) -> void:
	_arena_rect = rect
	set_viewport_width(rect.size.x)


## Applies a temporary enemy-local speed reduction such as Cold Wake.
func apply_slow(duration: float, multiplier: float) -> void:
	_slow_remaining = maxf(_slow_remaining, duration)
	_slow_multiplier = minf(_slow_multiplier, clampf(multiplier, 0.1, 1.0))


## Returns whether this enemy currently participates in player contact checks.
func is_contact_active() -> bool:
	return state == State.ACTIVE


## Returns the live collision radius in viewport pixels.
func get_collision_radius() -> float:
	return tuning.collision_radius * _viewport_scale


## Returns the current health for shield/heavy-enemy feedback and tests.
func get_current_health() -> int:
	return _health


## Returns this archetype's authored wave threat cost.
func get_threat_cost() -> int:
	return tuning.threat_cost


## Returns the 0.0–1.0 chance of dropping one run Soul Shard.
func get_shard_drop_chance() -> float:
	return tuning.shard_drop_chance


## Returns whether an enemy-local slow such as Cold Wake is currently active.
func is_slowed() -> bool:
	return _slow_remaining > 0.0 and _slow_multiplier < 1.0


## Applies one swept dash hit; returns whether the corridor connected.
func try_dash_hit(
		segment_start: Vector2,
		segment_end: Vector2,
		corridor_radius: float,
		damage: int,
		damage_event_id: int,
	) -> bool:
	if state != State.ACTIVE or damage_event_id == _last_damage_event_id:
		return false
	var hit_radius: float = get_collision_radius() + corridor_radius
	var distance: float = DashGeometry.distance_to_segment(
		global_position,
		segment_start,
		segment_end,
	)
	if distance > hit_radius:
		return false
	return try_direct_hit(damage, damage_event_id)


## Applies a non-geometric mutation hit while preserving one-hit-per-event protection.
func try_direct_hit(damage: int, damage_event_id: int) -> bool:
	if state != State.ACTIVE or damage_event_id == _last_damage_event_id or damage <= 0:
		return false
	_last_damage_event_id = damage_event_id
	_health -= damage
	if _health <= 0:
		_die(damage_event_id)
	else:
		_on_survived_hit()
	return true


## Subclass hook for ACTIVE movement; delta already includes focus and local slow multipliers.
func _advance_active(_scaled_delta: float) -> void:
	pass


## Subclass hook fired when the arrival telegraph becomes ACTIVE.
func _on_became_active() -> void:
	pass


## Subclass hook for non-lethal shield/heavy hit feedback.
func _on_survived_hit() -> void:
	_sprite.play(&"hit")
	_play_hit_flash()
	_sprite.modulate = HIT_FLASH_MODULATE
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, HIT_FLASH_DURATION)


## Shows the amber action warning under the enemy; `progress` runs 0–1 across the windup.
func _show_action_telegraph(progress: float) -> void:
	_arrival_ring.visible = true
	_arrival_ring.modulate.a = lerpf(0.6, 1.0, VfxPool.countdown_blink(progress, 2.0))
	_arrival_ring.scale = _base_sprite_scale * lerpf(1.35, 1.0, clampf(progress, 0.0, 1.0))


## Hides the action warning once the telegraphed move executes.
func _hide_action_telegraph() -> void:
	_arrival_ring.visible = false


## Keeps the enemy centre inside a readable five-percent viewport margin.
func _clamp_to_arena() -> void:
	if _arena_rect.size.x <= 0.0 or _arena_rect.size.y <= 0.0:
		return
	var margin: float = maxf(get_collision_radius(), _arena_rect.size.x * 0.05)
	if _arena_polygon.size() >= 3:
		# Containment runs at physics rate for up to MAX_LIVE_ENEMIES, so only pay for the polygon
		# test when the enemy has actually left the floor.
		if not DashGeometry.is_inside_polygon(position, _arena_polygon):
			position = DashGeometry.clamp_to_polygon(position, _arena_polygon, margin)
		return
	position = Vector2(
		clampf(position.x, _arena_rect.position.x + margin, _arena_rect.end.x - margin),
		clampf(position.y, _arena_rect.position.y + margin, _arena_rect.end.y - margin),
	)


func _update_telegraph(delta: float) -> void:
	_telegraph_remaining -= delta * _world_speed
	var progress: float = 1.0 - clampf(
		_telegraph_remaining / maxf(tuning.telegraph_duration, 0.001),
		0.0,
		1.0,
	)
	_sprite.modulate.a = lerpf(0.22, 1.0, progress)
	# The amber ring converges on the spawn point and blinks faster as the enemy arrives.
	_arrival_ring.modulate.a = lerpf(0.55, 1.0, VfxPool.countdown_blink(progress))
	_arrival_ring.scale = _base_sprite_scale * lerpf(1.6, 0.9, progress)
	if _telegraph_remaining <= 0.0:
		state = State.ACTIVE
		_arrival_ring.visible = false
		_sprite.modulate = Color.WHITE
		_play_arrival_pop()
		_on_became_active()


## Snaps the enemy into existence with a short overshoot as the telegraph resolves.
##
## Purely presentational: collision uses `get_collision_radius()`, which is unaffected by the
## sprite scale, so the pop can never change when a dash connects.
func _play_arrival_pop() -> void:
	if _arrival_tween != null and _arrival_tween.is_valid():
		_arrival_tween.kill()
	_sprite.scale = _base_sprite_scale * ARRIVAL_POP_SCALE
	_arrival_tween = create_tween()
	_arrival_tween.tween_property(
		_sprite,
		"scale",
		_base_sprite_scale,
		ARRIVAL_POP_DURATION,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_slow(delta: float) -> void:
	if _slow_remaining <= 0.0:
		return
	_slow_remaining = maxf(0.0, _slow_remaining - delta)
	if _slow_remaining <= 0.0:
		_slow_multiplier = 1.0


func _die(damage_event_id: int) -> void:
	state = State.DYING
	killed.emit(
		self,
		global_position,
		tuning.score_reward,
		tuning.experience_reward,
		damage_event_id,
	)
	_sprite.rotation = 0.0
	_sprite.play(&"dissolve")
	_arrival_ring.visible = false
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_show_hit_flash()
	_sprite.modulate = HIT_FLASH_MODULATE
	# STYLE_GUIDE motion: the silhouette breaks inward toward its core, then dissolves outward.
	var inward_time: float = tuning.dissolve_duration * DISSOLVE_INWARD_SHARE
	var outward_time: float = tuning.dissolve_duration - inward_time
	var dissolve_tween: Tween = create_tween()
	dissolve_tween.tween_property(
		_sprite,
		"scale",
		_base_sprite_scale * 0.82,
		inward_time,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dissolve_tween.parallel().tween_property(
		_hit_flash,
		"scale",
		_base_sprite_scale * 0.6,
		inward_time,
	)
	dissolve_tween.tween_property(
		_sprite,
		"scale",
		_base_sprite_scale * 1.22,
		outward_time,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dissolve_tween.parallel().tween_property(
		_sprite,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		outward_time,
	)
	dissolve_tween.parallel().tween_property(
		_hit_flash,
		"scale",
		_base_sprite_scale * 1.55,
		outward_time,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dissolve_tween.parallel().tween_property(_hit_flash, "modulate:a", 0.0, outward_time)
	dissolve_tween.tween_callback(queue_free)


func _play_hit_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_show_hit_flash()
	_flash_tween = create_tween().set_parallel(true)
	_flash_tween.tween_property(_hit_flash, "scale", _base_sprite_scale * 1.15, 0.16)
	_flash_tween.tween_property(_hit_flash, "modulate:a", 0.0, 0.16)


## Resets the additive soul-white impact star over the sprite.
func _show_hit_flash() -> void:
	_hit_flash.visible = true
	_hit_flash.modulate = Color(Palette.SOUL_WHITE, 0.95)
	_hit_flash.scale = _base_sprite_scale * 0.75


func _on_sprite_animation_finished() -> void:
	# The one-frame hit reaction returns to the idle loop instead of freezing on its last frame.
	if state == State.ACTIVE and _sprite.animation == &"hit":
		_sprite.play(&"idle")


func _apply_visual_scale() -> void:
	if not is_node_ready() or tuning == null:
		return
	_base_sprite_scale = Vector2.ONE * (
		tuning.sprite_diameter * _viewport_scale / SOURCE_FRAME_SIZE
	)
	_sprite.scale = _base_sprite_scale
	_arrival_ring.scale = _base_sprite_scale
	_hit_flash.scale = _base_sprite_scale
