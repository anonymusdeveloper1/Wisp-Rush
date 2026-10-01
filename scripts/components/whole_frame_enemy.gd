class_name WholeFrameEnemy
extends EnemyActor
## An Enemies v2 enemy drawn from the owner's AutoSprite sheets: a `move` loop and an `attack` that
## plays once (owner, 2026-09-28; docs/systems/enemies.md).
##
## It moves around the Wisp and attacks when it can (owner, 2026-09-27: enemies go around the Wisp on
## the sides, and when one gets close it attacks; an attack that reaches the Wisp kills it, even
## mid-dash). One of three attacks, set per scene:
## - [constant Attack.SWIPE] (Claw Ghost): closes in and, this near, swipes; the swipe's reach in front
##   of it kills during [member strike_frames].
## - [constant Attack.LUNGE] (Root Mask): closes to a short distance and lunges at where the Wisp was
##   when the lunge starts; its body kills while it flies ([member strike_frames]).
## - [constant Attack.SHOT] (Bone Witch, Hooded Scribe, Stone Golem): keeps its distance and, on
##   [member release_frame], looses an [EnemyProjectile] that the run owns from then on.
## A melee wind-up glows (the characters' attack outline shader, in the warning amber) so the strike
## never comes unannounced. A stationary enemy (the Tutorial's targets) never moves and never attacks.
##
## The kill is a slice: the frame on screen splits along the cut of the dash that killed it, and the
## halves drift apart and fade (owner's Enemies v2 notes: a kill must feel like slicing).
##
## The sprite's scale comes from the frames' `body_size` metadata (written by the packer,
## `concept_art/enemies_v2_autosprite_v1/pack_enemies.py`): [member EnemyTuning.sprite_diameter] is
## the body's longer side on screen at the design width.

enum Attack { SWIPE, LUNGE, SHOT }
enum Phase { MOVE, ATTACK }

const MOVE: StringName = &"move"
const ATTACK: StringName = &"attack"
const ATTACK_SHADER: Shader = preload("res://assets/shaders/character_attack.gdshader")
const SLICE_SHADER: Shader = preload("res://assets/shaders/enemy_slice.gdshader")
## Colour of a melee wind-up's glow: warnings are amber (Enemies v2 colour rule).
const WARNING_GLOW := Color("#F3A847")
## Seconds the slice's halves take to drift apart and fade.
const SLICE_SECONDS: float = 0.32
## How far each half drifts, as a share of the body's longer side on screen.
const SLICE_SPREAD: float = 0.16
## Angle a melee enemy keeps off the straight line to the Wisp while still far, so it comes round
## the side (owner: they go around the Wisp on the sides).
const FLANK_ANGLE: float = 0.6
## Share of the kept distance a shooter tolerates before it closes in or backs off.
const KEEP_SLACK: float = 0.15

@export var attack: Attack = Attack.SWIPE
## First and last frame of `attack` in which a strike kills (a swipe's reach, a lunge's flight).
@export var strike_frames: Vector2i = Vector2i(12, 15)
## The frame of `attack` that looses a shot.
@export var release_frame: int = 16
## Where the shot leaves, in frame pixels from the body's middle, as drawn (before mirroring).
@export var release_offset: Vector2 = Vector2.ZERO
## Whether the art's attack faces right; the sprite mirrors so the attack faces the Wisp.
@export var faces_right: bool = true
## Whether the move frames are drawn from above, facing down (Root Mask): the body turns to where it
## crawls, and the attack (drawn from the side) is upright.
@export var top_down_move: bool = false
## The shot's picture (shooters only).
@export var projectile_texture: Texture2D

var _phase: Phase = Phase.MOVE
var _cooldown: float = 0.0
var _move_direction: Vector2 = Vector2.DOWN
## Which side a melee enemy flanks, or a shooter circles, the Wisp on: +1 or -1.
var _side: float = 1.0
var _attack_direction: Vector2 = Vector2.RIGHT
var _lunge_from: Vector2 = Vector2.ZERO
var _lunge_to: Vector2 = Vector2.ZERO
var _lunging: bool = false
var _released: bool = false
var _glow: ShaderMaterial
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	_random.randomize()
	_side = -1.0 if _random.randf() < 0.5 else 1.0
	if attack != Attack.SHOT:
		_glow = ShaderMaterial.new()
		_glow.shader = ATTACK_SHADER
		_glow.set_shader_parameter(&"glow_color", WARNING_GLOW)
		_sprite.material = _glow


## The circle a strike kills in right now, while it strikes.
func get_attack_circles() -> Array[Vector3]:
	var result: Array[Vector3] = []
	if state != State.ACTIVE or _phase != Phase.ATTACK or attack == Attack.SHOT:
		return result
	if not _is_striking():
		return result
	var centre: Vector2 = global_position
	if attack == Attack.SWIPE:
		centre += _attack_direction * tuning.strike_reach * _viewport_scale
	result.append(Vector3(centre.x, centre.y, tuning.strike_radius * _viewport_scale))
	return result


## Whether the enemy is in its attack, for tools.
func is_attacking() -> bool:
	return _phase == Phase.ATTACK


func _loop_animation() -> StringName:
	return MOVE


func _frame_scale() -> Vector2:
	var body: Vector2 = Vector2(256.0, 256.0)
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_meta(&"body_size"):
		body = _sprite.sprite_frames.get_meta(&"body_size")
	return Vector2.ONE * (tuning.sprite_diameter * _viewport_scale / maxf(1.0, maxf(body.x, body.y)))


func _on_became_active() -> void:
	var toward: Vector2 = (_target_position - global_position).normalized()
	if not toward.is_zero_approx():
		_move_direction = toward
	# The first attack waits a moment after arriving, never on the arrival frame.
	_cooldown = tuning.action_interval * _random.randf_range(0.5, 0.9)
	_face_toward(_target_position)


func _advance_active(scaled_delta: float) -> void:
	_sprite.speed_scale = _world_speed * _slow_multiplier
	if not movement_enabled:
		return
	_cooldown = maxf(0.0, _cooldown - scaled_delta)
	if _phase == Phase.ATTACK:
		_advance_attack()
	else:
		_advance_move(scaled_delta)
		if _cooldown <= 0.0 and _in_attack_range():
			_begin_attack()
	var before: Vector2 = position
	_clamp_to_arena()
	if _phase == Phase.MOVE and not position.is_equal_approx(before):
		# Pressed against the wall while circling: circle the other way.
		_side = -_side
	_update_glow()


func _advance_move(scaled_delta: float) -> void:
	var to_target: Vector2 = _target_position - global_position
	var distance: float = to_target.length()
	var toward: Vector2 = to_target / distance if distance > 0.001 else Vector2.DOWN
	var desired: Vector2
	var keep: float = tuning.keep_distance * _viewport_scale
	if keep > 0.0:
		var around: Vector2 = toward.orthogonal() * _side
		if distance > keep * (1.0 + KEEP_SLACK):
			desired = (toward + around * 0.6).normalized()
		elif distance < keep * (1.0 - KEEP_SLACK):
			desired = (-toward + around * 0.6).normalized()
		else:
			desired = around
	else:
		var near: float = tuning.attack_range * _viewport_scale * 2.0
		desired = toward.rotated(FLANK_ANGLE * _side if distance > near else 0.0)
	var turn: float = wrapf(desired.angle() - _move_direction.angle(), -PI, PI)
	var limit: float = tuning.turn_speed * scaled_delta
	_move_direction = _move_direction.rotated(clampf(turn, -limit, limit)).normalized()
	position += _move_direction * tuning.movement_speed * _viewport_scale * scaled_delta
	if top_down_move:
		_sprite.flip_h = false
		_sprite.rotation = _move_direction.angle() - PI * 0.5
	else:
		_sprite.rotation = 0.0
		_face_toward(_target_position)


func _in_attack_range() -> bool:
	return global_position.distance_to(_target_position) <= tuning.attack_range * _viewport_scale


func _begin_attack() -> void:
	_phase = Phase.ATTACK
	_released = false
	_lunging = false
	_sprite.rotation = 0.0
	var toward: Vector2 = _target_position - global_position
	_attack_direction = toward.normalized() if not toward.is_zero_approx() else Vector2.RIGHT
	_face_toward(_target_position)
	_sprite.play(ATTACK)
	_sprite.frame = 0


func _advance_attack() -> void:
	var frame: int = _sprite.frame
	match attack:
		Attack.SWIPE:
			if frame < strike_frames.x:
				# Until the swipe comes, it turns to follow the Wisp; then it is committed.
				var toward: Vector2 = _target_position - global_position
				if not toward.is_zero_approx():
					_attack_direction = toward.normalized()
				_face_toward(_target_position)
		Attack.LUNGE:
			if frame < strike_frames.x:
				_face_toward(_target_position)
			elif frame <= strike_frames.y:
				if not _lunging:
					_start_lunge()
				var span: float = float(strike_frames.y - strike_frames.x + 1)
				var progress: float = (float(frame - strike_frames.x) + _sprite.frame_progress) / span
				position = _lunge_from.lerp(_lunge_to, clampf(progress, 0.0, 1.0))
		Attack.SHOT:
			if not _released and frame >= release_frame:
				_release_shot()


## The lunge leaves now for where the Wisp is now, as far as its reach carries.
func _start_lunge() -> void:
	_lunging = true
	var toward: Vector2 = _target_position - global_position
	if not toward.is_zero_approx():
		_attack_direction = toward.normalized()
	_face_toward(_target_position)
	_lunge_from = global_position
	var reach: float = minf(toward.length(), tuning.strike_reach * _viewport_scale)
	_lunge_to = _lunge_from + _attack_direction * reach


func _release_shot() -> void:
	_released = true
	if projectile_fired.get_connections().is_empty():
		return
	var offset: Vector2 = release_offset * _base_sprite_scale
	if _sprite.flip_h:
		offset.x = -offset.x
	var shot := EnemyProjectile.new()
	shot.setup(tuning, projectile_texture, global_position + offset, _target_position, _viewport_scale)
	projectile_fired.emit(shot)


func _is_striking() -> bool:
	var frame: int = _sprite.frame
	return _sprite.animation == ATTACK and frame >= strike_frames.x and frame <= strike_frames.y


## Mirrors the sprite so its attack faces [param point].
func _face_toward(point: Vector2) -> void:
	var right: bool = point.x >= global_position.x
	_sprite.flip_h = right != faces_right


## The melee wind-up glows brighter until the strike, flashes on it, then goes out.
func _update_glow() -> void:
	if _glow == null:
		return
	var outline: float = 0.0
	var flash: float = 0.0
	if _phase == Phase.ATTACK and _sprite.animation == ATTACK:
		var frame: int = _sprite.frame
		if frame < strike_frames.x:
			var share: float = (float(frame) + _sprite.frame_progress) / maxf(1.0, float(strike_frames.x))
			outline = lerpf(0.35, 1.0, clampf(share, 0.0, 1.0))
		elif frame <= strike_frames.y:
			outline = 1.0
			flash = 0.35
	_glow.set_shader_parameter(&"outline", outline)
	_glow.set_shader_parameter(&"flash", flash)


func _end_attack() -> void:
	_phase = Phase.MOVE
	_lunging = false
	_cooldown = tuning.action_interval * _random.randf_range(0.85, 1.15)
	_sprite.play(MOVE)
	_update_glow()


func _on_sprite_animation_finished() -> void:
	if state == State.ACTIVE and _sprite.animation == ATTACK:
		_end_attack()


## A hit that does not kill: a white flash (every Enemies v2 enemy dies in one hit, owner 2026-09-28).
func _on_survived_hit() -> void:
	_play_hit_flash()
	_sprite.modulate = HIT_FLASH_MODULATE
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, HIT_FLASH_DURATION)


## The slice: the frame on screen splits along the cut into two halves that drift apart and fade.
func _play_death() -> void:
	_phase = Phase.MOVE
	if _glow != null:
		_glow.set_shader_parameter(&"outline", 0.0)
	var frames: SpriteFrames = _sprite.sprite_frames
	var texture: Texture2D = frames.get_frame_texture(_sprite.animation, _sprite.frame) if frames != null else null
	var cut: Vector2 = _last_hit_direction.rotated(-_sprite.rotation)
	var normal: Vector2 = _last_hit_direction.orthogonal()
	var body: float = tuning.sprite_diameter * _viewport_scale
	_sprite.visible = false
	var tween: Tween = create_tween().set_parallel(true)
	for side: float in [-1.0, 1.0]:
		var half := Sprite2D.new()
		half.texture = texture
		half.flip_h = _sprite.flip_h
		half.rotation = _sprite.rotation
		half.scale = _sprite.scale
		var slice := ShaderMaterial.new()
		slice.shader = SLICE_SHADER
		slice.set_shader_parameter(&"cut_direction", cut)
		slice.set_shader_parameter(&"side", side)
		half.material = slice
		add_child(half)
		tween.tween_property(half, "position", normal * side * body * SLICE_SPREAD, SLICE_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(half, "rotation", half.rotation + side * 0.3, SLICE_SECONDS)
		tween.tween_property(half, "modulate:a", 0.0, SLICE_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_arrival_ring.visible = false
	_show_hit_flash()
	tween.tween_property(_hit_flash, "scale", _effect_scale * 1.3, SLICE_SECONDS * 0.6)
	tween.tween_property(_hit_flash, "modulate:a", 0.0, SLICE_SECONDS * 0.6)
	tween.chain().tween_callback(queue_free)
