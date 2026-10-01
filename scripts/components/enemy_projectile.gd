class_name EnemyProjectile
extends Node2D
## A shot fired by an Enemies v2 shooter, and the mark a wall shot leaves (owner, 2026-09-28).
##
## Which kind it is follows from the shooter's [EnemyTuning]:
## - **straight** (the Stone Golem): flies at where the Wisp was when it was fired and breaks on the
##   wall;
## - **homing** ([member EnemyTuning.homing_duration] > 0, the Hooded Scribe): turns toward the Wisp
##   for that long, then fades away without reaching it (owner: "it follows you for 2 or 3 seconds
##   ... and then it disappears");
## - **wall mark** ([member EnemyTuning.wall_mark_radius] > 0, the Bone Witch): flies straight and,
##   where it hits the wall, leaves a purple mark the Wisp must not touch for
##   [member EnemyTuning.wall_mark_duration] seconds.
##
## Touching a shot or a mark kills the Wisp, even mid-dash: `GameWorld` checks
## [method get_danger_circle] and calls [method on_hit_player]. It never damages anything itself.
## The mark is drawn in code on the pixel grid, like Grimgrin's rot.

enum Mode { FLYING, MARK, FADING }

## Seconds a shot or a mark takes to fade out, harmless.
const FADE_SECONDS: float = 0.18
## A shot that has hit nothing after this long fades out anyway.
const MAX_FLIGHT_SECONDS: float = 6.0
## Side of one pixel cell of the mark at the design width.
const MARK_CELL: float = 4.0
const DESIGN_WIDTH: float = 1080.0
## The mark's colours: dark rim, purple body, light pulse.
const MARK_DARK := Color("#4A1766")
const MARK_BODY := Color("#8E3BC4")
const MARK_LIGHT := Color("#D69BFF")

var mode: Mode = Mode.FLYING

var _tuning: EnemyTuning
var _sprite: Sprite2D
var _direction: Vector2 = Vector2.RIGHT
var _target: Vector2 = Vector2.ZERO
var _homing_left: float = 0.0
var _flight_time: float = 0.0
var _viewport_scale: float = 1.0
var _world_speed: float = 1.0
var _arena_rect: Rect2 = Rect2()
var _arena_polygon: PackedVector2Array = PackedVector2Array()
var _mark_left: float = 0.0
## Whether this shot became a wall mark, so its fade-out still draws the mark.
var _became_mark: bool = false
var _fade_left: float = 0.0
var _time: float = 0.0


## Aims a new shot from [param from] at [param toward] with [param tuning]'s speed, size and kind.
func setup(
		tuning: EnemyTuning,
		texture: Texture2D,
		from: Vector2,
		toward: Vector2,
		viewport_scale: float,
	) -> void:
	_tuning = tuning
	_viewport_scale = maxf(0.1, viewport_scale)
	position = from
	_target = toward
	var aim: Vector2 = toward - from
	_direction = aim.normalized() if not aim.is_zero_approx() else Vector2.DOWN
	_homing_left = tuning.homing_duration
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	if texture != null:
		var longest: float = maxf(1.0, maxf(texture.get_width(), texture.get_height()))
		_sprite.scale = Vector2.ONE * (tuning.projectile_size * _viewport_scale / longest)
	_sprite.rotation = _direction.angle()
	add_child(_sprite)


## The Wisp's live position, which a homing shot turns toward.
func set_target_position(world_position: Vector2) -> void:
	_target = world_position


## Wisp Focus slows shots with the rest of the world.
func set_world_speed(multiplier: float) -> void:
	_world_speed = clampf(multiplier, 0.05, 1.0)


## The floor the shot flies over; leaving it is hitting the wall.
func set_arena(rect: Rect2, polygon: PackedVector2Array) -> void:
	_arena_rect = rect
	_arena_polygon = polygon


## The circle that kills the Wisp, as world x/y/radius; radius zero while it is harmless (fading).
func get_danger_circle() -> Vector3:
	match mode:
		Mode.FLYING:
			return Vector3(global_position.x, global_position.y, _tuning.projectile_radius * _viewport_scale)
		Mode.MARK:
			return Vector3(global_position.x, global_position.y, _tuning.wall_mark_radius * _viewport_scale)
	return Vector3(global_position.x, global_position.y, 0.0)


## Whether this is a wall mark rather than a shot in flight.
func is_mark() -> bool:
	return mode == Mode.MARK


## The shot reached the Wisp: a shot is spent; a mark stays for its time.
func on_hit_player() -> void:
	if mode == Mode.FLYING:
		_begin_fade()


func _physics_process(delta: float) -> void:
	var scaled: float = delta * _world_speed
	_time += delta
	match mode:
		Mode.FLYING:
			_fly(scaled)
		Mode.MARK:
			_mark_left -= scaled
			queue_redraw()
			if _mark_left <= 0.0:
				_begin_fade()
		Mode.FADING:
			_fade_left -= delta
			modulate.a = clampf(_fade_left / FADE_SECONDS, 0.0, 1.0)
			queue_redraw()
			if _fade_left <= 0.0:
				queue_free()


func _fly(scaled: float) -> void:
	_flight_time += scaled
	if _tuning.homing_duration > 0.0:
		if _homing_left <= 0.0:
			_begin_fade()
			return
		_homing_left -= scaled
		var wanted: Vector2 = (_target - global_position).normalized()
		if not wanted.is_zero_approx():
			var turn: float = wrapf(wanted.angle() - _direction.angle(), -PI, PI)
			var limit: float = _tuning.homing_turn_rate * scaled
			_direction = _direction.rotated(clampf(turn, -limit, limit)).normalized()
	position += _direction * _tuning.projectile_speed * _viewport_scale * scaled
	_sprite.rotation = _direction.angle()
	if not _inside_floor(position):
		_hit_wall()
	elif _flight_time >= MAX_FLIGHT_SECONDS:
		_begin_fade()


func _inside_floor(point: Vector2) -> bool:
	if _arena_polygon.size() >= 3:
		return DashGeometry.is_inside_polygon(point, _arena_polygon)
	if _arena_rect.has_area():
		return _arena_rect.has_point(point)
	return true


## The shot left the floor: it breaks there, or a wall shot leaves its mark on the wall.
func _hit_wall() -> void:
	if _arena_polygon.size() >= 3:
		position = DashGeometry.nearest_polygon_point(position, _arena_polygon)
	elif _arena_rect.has_area():
		position = position.clamp(_arena_rect.position, _arena_rect.end)
	if _tuning.wall_mark_radius > 0.0 and _tuning.wall_mark_duration > 0.0:
		mode = Mode.MARK
		_became_mark = true
		_mark_left = _tuning.wall_mark_duration
		_sprite.visible = false
		queue_redraw()
		return
	_begin_fade()


func _begin_fade() -> void:
	if mode == Mode.FADING:
		return
	mode = Mode.FADING
	_fade_left = FADE_SECONDS


## The wall mark: a disc of purple cells on the pixel grid, a dark rim and a light pulse inside.
func _draw() -> void:
	if not _became_mark:
		return
	var cell: float = maxf(2.0, roundf(MARK_CELL * _viewport_scale))
	var radius: float = _tuning.wall_mark_radius * _viewport_scale
	var cells: int = int(ceil(radius / cell))
	var pulse: float = 0.5 + 0.5 * sin(_time * 9.0)
	for row: int in range(-cells, cells + 1):
		for column: int in range(-cells, cells + 1):
			var offset := Vector2(column, row) * cell
			var distance: float = offset.length()
			if distance > radius:
				continue
			var share: float = distance / maxf(1.0, radius)
			var colour: Color = MARK_BODY
			if share > 0.82:
				colour = MARK_DARK
			elif share < 0.35 + 0.15 * pulse:
				colour = MARK_BODY.lerp(MARK_LIGHT, 0.5 + 0.5 * pulse)
			elif ((row * 7 + column * 13) & 7) == 0:
				colour = MARK_DARK
			draw_rect(Rect2(offset - Vector2.ONE * cell * 0.5, Vector2.ONE * cell), colour)
