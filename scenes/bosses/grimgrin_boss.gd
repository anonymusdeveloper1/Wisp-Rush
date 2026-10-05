class_name GrimgrinBoss
extends BossActor
## Grimgrin, the Hollow Ronin: the melee boss of the new set (owner's design,
## docs/specs/enemies_v2/boss_melee.md; system doc docs/systems/grimgrin_boss.md).
##
## He lives on the arena's four walls. After a short, random rest his eyes and glow flare (the
## warning), then he dashes to a random point on another wall, swiping as he flies. His flight does not
## hurt the Wisp: it is the time to hit him, and he glows the whole flight (owner, 2026-09-27).
## Sometimes his dash is the fast attack instead (owner, 2026-09-28): a longer, crimson warning, then a
## fast flight in which he cannot be hit and touching him hurts the Wisp, even while it dashes.
## Sometimes he dashes to the Wisp's wall instead and plants both katanas: the wall rots from his
## blades outward (the warning), then the whole wall is deadly for a moment. In the second half he
## sometimes flares and marks the Wisp (Death's Grin): the next wall it lands on rots at once. Regular
## enemies spawn at random during the fight. He can be hit on his walls and in his slow flight, and a
## hit while both katanas are planted counts double. All the numbers are in [GrimgrinTuning].
##
## Frames come from the owner's six AutoSprite sheets, packed by
## `concept_art/grimgrin_autosprite_v1/pack_grimgrin.py`: floor animations stand on a feet line,
## wall animations hold on to a wall on their right, and [BossSpriteLayout] says where those lines are.

enum State { INTRO, REST, WARN, DASH, PLANT, DEFEATED }
## The arena's four walls, as the sides of its rectangle.
enum Wall { FLOOR, CEILING, LEFT, RIGHT }

const FLOOR_IDLE: StringName = &"floor_idle"
const WALL_IDLE: StringName = &"wall_idle"
const PLANT_FLOOR: StringName = &"plant_floor"
const PLANT_WALL: StringName = &"plant_wall"
const DASH: StringName = &"dash"
const DEATH: StringName = &"death"
## The frame of each planting where both blades are in (the packer's cells 11 and 13).
const PLANT_FLOOR_STAB_FRAME: int = 6
const PLANT_WALL_STAB_FRAME: int = 4
## The dash frames played over one flight, from the flight pose through the slash to its end pose.
const DASH_FLIGHT_FRAMES: int = 18
## Share of a flight where the slash lands (the sheet's cell 12 of the 18 played).
const DASH_SLASH_PROGRESS: float = 0.66
## Share of a wall kept free at each end, as a share of his standing height, so he never sits in a
## corner: along a floor his katanas spread wide, along a side wall his hanging body is tall.
const FLOOR_ALONG_EXTENT: float = 0.45
const WALL_ALONG_EXTENT: float = 0.62
## His colours: the crimson of his cloak for the rot and the mark, the orange of his glow.
const ROT_DARK := Color(0.29, 0.02, 0.05)
const ROT_BODY := Color(0.58, 0.04, 0.1)
const ROT_VEIN := Color(1.0, 0.32, 0.18)
const GLOW_COLOR := Color(1.0, 0.55, 0.14)
## The crimson his glow flares before and during his fast attack, instead of the orange.
const FAST_GLOW_COLOR := Color(1.0, 0.1, 0.16)
const HIT_FLASH_MODULATE := Color(2.0, 2.0, 2.0, 1.0)
const HIT_FLASH_DURATION: float = 0.14
## Seconds a finished rot takes to fade away.
const ROT_FADE: float = 0.3
## Seconds his flare lasts when he grins, and when he appears.
const GRIN_FLARE: float = 0.7
const APPEAR_DURATION: float = 0.35
## Seconds his death holds its last frame before he dissolves, and the dissolve.
const DEATH_HOLD: float = 0.45
const DISSOLVE: float = 0.6

@export var tuning: GrimgrinTuning
@export var layout: BossSpriteLayout

var state: State = State.INTRO
var _arena_rect: Rect2 = Rect2(0.0, 0.0, 1080.0, 1920.0)
var _viewport_scale: float = 1.0
var _scale: float = 1.0
var _player_radius: float = 38.0
var _has_player_radius: bool = false
var _target: Vector2 = Vector2.ZERO
var _last_edge: Vector2 = Vector2.ZERO
var _random := RandomNumberGenerator.new()
var _maximum_health: int = 12
var _health: int = 12
var _phase: int = 1
var _wall: Wall = Wall.FLOOR
var _wall_t: float = 0.5
var _state_remaining: float = 0.0
var _dash_from: Vector2 = Vector2.ZERO
var _dash_to: Vector2 = Vector2.ZERO
var _dash_wall: Wall = Wall.FLOOR
var _dash_t: float = 0.5
var _dash_duration: float = 0.3
var _dash_elapsed: float = 0.0
var _dash_is_ill: bool = false
var _dash_is_fast: bool = false
var _dash_slashed: bool = false
var _ill_cooldown: float = 0.0
var _fast_cooldown: float = 0.0
var _grin_cooldown: float = 0.0
var _spawn_remaining: float = 0.0
var _last_dash_id: int = -1
var _planted: bool = false
var _stabbed: bool = false
## Each rotting wall: {wall, origin (t along it), elapsed, spread, deadly, from_plant}.
var _rots: Array[Dictionary] = []
var _mark_remaining: float = 0.0
var _flare: float = 0.0
var _flare_length: float = GRIN_FLARE
var _warn_is_ill: bool = false
var _warn_is_fast: bool = false
var _time: float = 0.0
var _defeat_elapsed: float = 0.0
var _dissolving: bool = false

static var _glow_texture: GradientTexture2D

@onready var _glow: Sprite2D = %Glow
@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _effects: Node2D = %Effects


func _ready() -> void:
	assert(tuning != null and layout != null, "GrimgrinBoss needs its tuning and layout")
	_glow.texture = _get_glow_texture()
	_glow.modulate = Color(GLOW_COLOR, 0.0)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	_effects.top_level = true
	_effects.global_position = Vector2.ZERO
	_effects.draw.connect(_on_effects_draw)
	_sprite.animation_finished.connect(_on_animation_finished)


func configure(
	arena_rect: Rect2,
	target_position: Vector2,
	encounter_index: int,
	seed: int,
	health_override: int = 0,
	) -> void:
	_random.seed = seed
	_target = target_position
	_last_edge = target_position
	_apply_rect(arena_rect)
	_maximum_health = tuning.base_health + maxi(0, encounter_index) * tuning.health_per_encounter
	if health_override > 0:
		_maximum_health = health_override
	_health = _maximum_health
	_phase = 1
	_ill_cooldown = tuning.first_ill_wall_delay
	_fast_cooldown = tuning.first_fast_attack_delay
	_grin_cooldown = 0.0
	_spawn_remaining = _random.randf_range(tuning.spawn_interval_min, tuning.spawn_interval_max)
	# He appears on a wall away from the Wisp, not on its wall.
	var start: Array = _pick_landing(_wall_of(target_position), false)
	_wall = start[0]
	_wall_t = start[1]
	global_position = _body_centre(_wall, _wall_t)
	state = State.INTRO
	_state_remaining = tuning.intro_duration
	_play_wall_pose()
	_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(_sprite, "modulate:a", 1.0, APPEAR_DURATION)
	_start_flare(GRIN_FLARE)
	health_changed.emit(_health, _maximum_health)
	phase_changed.emit(_phase)
	print("[Grimgrin] encounter=%d health=%d wall=%d" % [encounter_index + 1, _maximum_health, _wall])


func set_target_position(world_position: Vector2) -> void:
	_target = world_position


func set_arena_rect(arena_rect: Rect2) -> void:
	_apply_rect(arena_rect)
	if state == State.DASH:
		_dash_to = _body_centre(_dash_wall, _dash_t)
	elif state != State.DEFEATED or not _dissolving:
		global_position = _body_centre(_wall, _wall_t)
		_orient_current()


## The Wisp landed on a wall: a Death's Grin mark turns that wall ill at once.
func set_last_edge_position(world_position: Vector2) -> void:
	_last_edge = world_position
	if _mark_remaining > 0.0 and state != State.DEFEATED:
		_mark_remaining = 0.0
		var wall: Wall = _wall_of(world_position)
		_add_rot(wall, _t_on(wall, world_position),
			tuning.grin_rot_spread_duration, tuning.grin_rot_deadly_duration, false)


func set_player_radius(radius: float) -> void:
	_player_radius = maxf(1.0, radius)
	_has_player_radius = true


func skip_intro() -> void:
	if state == State.INTRO:
		_state_remaining = 0.0


func get_intro_progress() -> float:
	if state != State.INTRO:
		return 1.0
	return 1.0 - clampf(_state_remaining / maxf(tuning.intro_duration, 0.001), 0.0, 1.0)


func get_current_health() -> int:
	return _health


func get_maximum_health() -> int:
	return _maximum_health


## He can be hit on his walls and in his slow flight (owner, 2026-09-27), never in his fast attack
## (owner, 2026-09-28), and his death is out of reach.
func is_core_exposed() -> bool:
	return state != State.DEFEATED and not (state == State.DASH and _dash_is_fast)


func get_phase() -> int:
	return _phase


func get_phase_name(phase: int) -> String:
	return "DEATH'S GRIN" if phase >= 2 else "WALL TO WALL"


## Whether both katanas are in the wall, when a hit counts double.
func is_planted() -> bool:
	return _planted


## Whether the Wisp carries a Death's Grin mark.
func is_marking() -> bool:
	return _mark_remaining > 0.0


## Whether his fast attack is coming (its crimson warning) or under way.
func is_fast_attack() -> bool:
	return (state == State.WARN and _warn_is_fast) or (state == State.DASH and _dash_is_fast)


## His fast attack: touching him in it hurts the Wisp, even while it dashes (owner, 2026-09-28).
## Nothing else on his body is a danger.
func get_dangerous_circles() -> Array[Vector3]:
	var result: Array[Vector3] = []
	if state == State.DASH and _dash_is_fast:
		result.append(Vector3(global_position.x, global_position.y, _danger_radius()))
	return result


func get_wall() -> Wall:
	return _wall


## Every wall whose rot has finished spreading is deadly along its whole length.
func get_dangerous_lanes() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for rot: Dictionary in _rots:
		if _rot_is_deadly(rot):
			var ends: PackedVector2Array = _wall_ends(rot[&"wall"] as Wall)
			result.append(ends)
	return result


func get_lane_radius() -> float:
	return _player_radius * tuning.rot_lane_ratio


func try_dash_hit(
	segment_start: Vector2,
	segment_end: Vector2,
	corridor_radius: float,
	_damage: int,
	dash_id: int,
	) -> bool:
	if not is_core_exposed() or dash_id == _last_dash_id:
		return false
	var distance: float = DashGeometry.distance_to_segment(global_position, segment_start, segment_end)
	if distance > corridor_radius + _hit_radius():
		return false
	_last_dash_id = dash_id
	_health = maxi(0, _health - (tuning.planted_hit_value if _planted else 1))
	health_changed.emit(_health, _maximum_health)
	_play_hit_flash()
	if _health <= 0:
		_begin_defeat()
	elif _phase == 1 and float(_health) <= float(_maximum_health) * tuning.second_half_health:
		_phase = 2
		phase_changed.emit(_phase)
	return true


func get_victory_duration() -> float:
	return tuning.victory_duration


func get_experience_reward() -> int:
	return tuning.experience_reward


func get_defeat_name() -> String:
	return "GRIMGRIN"


func _physics_process(delta: float) -> void:
	_time += delta
	_flare = maxf(0.0, _flare - delta)
	_update_rots(delta)
	if _mark_remaining > 0.0:
		_mark_remaining = maxf(0.0, _mark_remaining - delta)
	match state:
		State.INTRO:
			_update_rest(delta, true)
		State.REST:
			_update_rest(delta, false)
		State.WARN:
			_update_warning(delta)
		State.DASH:
			_update_dash(delta)
		State.PLANT:
			_update_plant()
		State.DEFEATED:
			_update_defeat(delta)
	if state != State.DEFEATED and state != State.INTRO:
		_update_spawns(delta)
		_ill_cooldown = maxf(0.0, _ill_cooldown - delta)
		_fast_cooldown = maxf(0.0, _fast_cooldown - delta)
		_grin_cooldown = maxf(0.0, _grin_cooldown - delta)
	_update_glow()
	_effects.queue_redraw()


# --- States ---------------------------------------------------------------------------------------

func _update_rest(delta: float, intro: bool) -> void:
	if _is_floor_type(_wall):
		# On a floor or a ceiling he faces the Wisp.
		_sprite.flip_h = _target.x < global_position.x
	_state_remaining -= delta
	if _state_remaining > 0.0:
		return
	if not intro and _phase >= 2 and _grin_cooldown <= 0.0 and _mark_remaining <= 0.0 \
			and _random.randf() < tuning.grin_chance:
		_grin()
		return
	var go_ill: bool = _ill_cooldown <= 0.0 and _random.randf() < tuning.ill_wall_chance
	# Sometimes the dash is his fast attack instead (owner, 2026-09-28); an ill-wall dash stays slow.
	var go_fast: bool = not go_ill and _fast_cooldown <= 0.0 \
			and _random.randf() < tuning.fast_attack_chance
	_begin_warning(go_ill, go_fast)


func _begin_rest(duration: float) -> void:
	state = State.REST
	_state_remaining = duration
	_play_wall_pose()


func _grin() -> void:
	_grin_cooldown = tuning.grin_cooldown
	_mark_remaining = tuning.grin_mark_duration
	_start_flare(GRIN_FLARE)
	SoundFx.play(&"reaper_windup")
	_begin_rest(GRIN_FLARE)


## The warning before every dash: he holds his wall while his eyes and glow flare (owner, 2026-09-27);
## before his fast attack the flare is crimson and holds longer (owner, 2026-09-28).
func _begin_warning(ill: bool, fast: bool = false) -> void:
	state = State.WARN
	_warn_is_ill = ill
	_warn_is_fast = fast
	_state_remaining = _warning_duration()


func _update_warning(delta: float) -> void:
	if _is_floor_type(_wall):
		_sprite.flip_h = _target.x < global_position.x
	_state_remaining -= delta
	if _state_remaining <= 0.0:
		_begin_dash(_warn_is_ill, _warn_is_fast)


func _warning_duration() -> float:
	return tuning.fast_warning_duration if _warn_is_fast else tuning.dash_warning_duration


func _begin_dash(ill: bool, fast: bool = false) -> void:
	var target_wall: Wall
	var target_t: float
	var wisp_wall: Wall = _wall_of(_last_edge)
	if ill:
		target_wall = wisp_wall
		target_t = _ill_landing_t(wisp_wall)
	else:
		var landing: Array = _pick_landing(_wall, true)
		target_wall = landing[0]
		target_t = landing[1]
	state = State.DASH
	_dash_is_ill = ill
	_dash_is_fast = fast
	_dash_wall = target_wall
	_dash_t = target_t
	_dash_from = global_position
	_dash_to = _body_centre(target_wall, target_t)
	var speed: float = maxf(1.0, (tuning.fast_dash_speed if fast else tuning.dash_speed) * _viewport_scale)
	_dash_duration = maxf(0.18, _dash_from.distance_to(_dash_to) / speed)
	_dash_elapsed = 0.0
	_dash_slashed = false
	if ill:
		_ill_cooldown = tuning.ill_wall_cooldown
	if fast:
		_fast_cooldown = tuning.fast_attack_cooldown
	_sprite.play(DASH)
	_sprite.pause()
	_sprite.frame = 0
	_orient_dash()


func _update_dash(delta: float) -> void:
	_dash_elapsed += delta
	var progress: float = clampf(_dash_elapsed / _dash_duration, 0.0, 1.0)
	global_position = _dash_from.lerp(_dash_to, progress)
	_sprite.frame = mini(DASH_FLIGHT_FRAMES - 1, int(progress * float(DASH_FLIGHT_FRAMES)))
	if not _dash_slashed and progress >= DASH_SLASH_PROGRESS:
		_dash_slashed = true
		SoundFx.play(&"reaper_sweep")
	if progress < 1.0:
		return
	_wall = _dash_wall
	_wall_t = _dash_t
	global_position = _dash_to
	if _dash_is_ill:
		_begin_plant()
	else:
		_begin_rest(_random.randf_range(tuning.rest_min, tuning.rest_max))


func _begin_plant() -> void:
	state = State.PLANT
	_stabbed = false
	_planted = false
	_orient_wall(PLANT_FLOOR if _is_floor_type(_wall) else PLANT_WALL)
	_sprite.play(PLANT_FLOOR if _is_floor_type(_wall) else PLANT_WALL)


func _update_plant() -> void:
	var stab: int = PLANT_FLOOR_STAB_FRAME if _is_floor_type(_wall) else PLANT_WALL_STAB_FRAME
	if not _stabbed and _sprite.frame >= stab:
		_stabbed = true
		_planted = true
		SoundFx.play(&"reaper_sweep")
		_add_rot(_wall, _wall_t, tuning.rot_spread_duration, tuning.rot_deadly_duration, true)
		return
	if _stabbed and not _has_plant_rot():
		_planted = false
		_begin_rest(_random.randf_range(tuning.rest_min, tuning.rest_max) * 0.5)


func _begin_defeat() -> void:
	state = State.DEFEATED
	_planted = false
	_mark_remaining = 0.0
	_rots.clear()
	_defeat_elapsed = 0.0
	_dissolving = false
	global_position = _body_centre(_wall, _wall_t)
	_orient_wall(DEATH)
	_sprite.play(DEATH)
	SoundFx.play(&"reaper_defeat")


func _update_defeat(delta: float) -> void:
	if _dissolving or _sprite.is_playing():
		return
	_defeat_elapsed += delta
	if _defeat_elapsed < DEATH_HOLD:
		return
	_dissolving = true
	var dissolve: Tween = create_tween()
	dissolve.tween_property(_sprite, "modulate:a", 0.0, DISSOLVE)
	dissolve.tween_callback(
		func() -> void:
			defeated.emit(global_position, tuning.score_reward, tuning.rp_reward)
			queue_free()
	)


func _update_spawns(delta: float) -> void:
	_spawn_remaining -= delta
	if _spawn_remaining > 0.0:
		return
	_spawn_remaining = _random.randf_range(tuning.spawn_interval_min, tuning.spawn_interval_max)
	var count: int = tuning.second_half_spawn_count if _phase >= 2 else tuning.spawn_count
	if count > 0:
		spawn_requested.emit(count, tuning.max_live_enemies)


func _on_animation_finished() -> void:
	# One-shots hold their last frame: the planting until its rot ends, the death until it dissolves.
	pass


# --- The rot --------------------------------------------------------------------------------------

func _add_rot(wall: Wall, origin: float, spread: float, deadly: float, from_plant: bool) -> void:
	_rots.append({
		&"wall": wall,
		&"origin": clampf(origin, 0.0, 1.0),
		&"elapsed": 0.0,
		&"spread": maxf(0.05, spread),
		&"deadly": maxf(0.05, deadly),
		&"from_plant": from_plant,
	})


func _update_rots(delta: float) -> void:
	for index: int in range(_rots.size() - 1, -1, -1):
		var rot: Dictionary = _rots[index]
		rot[&"elapsed"] = float(rot[&"elapsed"]) + delta
		if float(rot[&"elapsed"]) >= float(rot[&"spread"]) + float(rot[&"deadly"]) + ROT_FADE:
			_rots.remove_at(index)


func _rot_is_deadly(rot: Dictionary) -> bool:
	var elapsed: float = rot[&"elapsed"]
	var spread: float = rot[&"spread"]
	return elapsed >= spread and elapsed < spread + float(rot[&"deadly"])


func _has_plant_rot() -> bool:
	for rot: Dictionary in _rots:
		if rot[&"from_plant"] and float(rot[&"elapsed"]) < float(rot[&"spread"]) + float(rot[&"deadly"]):
			return true
	return false


## The stretch of the wall a rot covers, as [from, to] along it.
func _rot_cover(rot: Dictionary) -> Vector2:
	var origin: float = rot[&"origin"]
	var share: float = clampf(float(rot[&"elapsed"]) / float(rot[&"spread"]), 0.0, 1.0)
	var reach: float = maxf(origin, 1.0 - origin) * share
	return Vector2(maxf(0.0, origin - reach), minf(1.0, origin + reach))


# --- Walls and placement --------------------------------------------------------------------------

func _apply_rect(arena_rect: Rect2) -> void:
	_arena_rect = arena_rect
	_viewport_scale = maxf(0.1, arena_rect.size.x / tuning.design_width)
	_scale = tuning.standing_height * _viewport_scale / maxf(1.0, layout.standing_height)
	if not _has_player_radius:
		_player_radius = clampf(arena_rect.size.x * 0.05, 30.0, 70.0)
	if is_node_ready():
		_sprite.scale = Vector2.ONE * _scale
		_glow.scale = Vector2.ONE * (tuning.standing_height * _viewport_scale * 1.6 / 64.0)


func _is_floor_type(wall: Wall) -> bool:
	return wall == Wall.FLOOR or wall == Wall.CEILING


## Inward normal of a wall, pointing into the arena.
func _normal(wall: Wall) -> Vector2:
	match wall:
		Wall.FLOOR:
			return Vector2.UP
		Wall.CEILING:
			return Vector2.DOWN
		Wall.LEFT:
			return Vector2.RIGHT
	return Vector2.LEFT


func _wall_ends(wall: Wall) -> PackedVector2Array:
	var r: Rect2 = _arena_rect
	match wall:
		Wall.FLOOR:
			return PackedVector2Array([Vector2(r.position.x, r.end.y), r.end])
		Wall.CEILING:
			return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y)])
		Wall.LEFT:
			return PackedVector2Array([r.position, Vector2(r.position.x, r.end.y)])
	return PackedVector2Array([Vector2(r.end.x, r.position.y), r.end])


func _wall_point(wall: Wall, t: float) -> Vector2:
	var ends: PackedVector2Array = _wall_ends(wall)
	return ends[0].lerp(ends[1], t)


func _body_depth(wall: Wall) -> float:
	return (layout.floor_body_depth if _is_floor_type(wall) else layout.wall_body_depth) * _scale


func _body_centre(wall: Wall, t: float) -> Vector2:
	return _wall_point(wall, t) + _normal(wall) * _body_depth(wall)


## The wall nearest [param point].
func _wall_of(point: Vector2) -> Wall:
	var r: Rect2 = _arena_rect
	var distances: Array[float] = [
		absf(r.end.y - point.y), absf(point.y - r.position.y),
		absf(point.x - r.position.x), absf(r.end.x - point.x),
	]
	var best: int = 0
	for index: int in distances.size():
		if distances[index] < distances[best]:
			best = index
	return best as Wall


func _t_on(wall: Wall, point: Vector2) -> float:
	var ends: PackedVector2Array = _wall_ends(wall)
	var along: Vector2 = ends[1] - ends[0]
	return clampf((point - ends[0]).dot(along) / maxf(1.0, along.length_squared()), 0.0, 1.0)


## Share of [param wall] kept free at each end so he fits.
func _margin(wall: Wall) -> float:
	var ends: PackedVector2Array = _wall_ends(wall)
	var extent: float = (FLOOR_ALONG_EXTENT if _is_floor_type(wall) else WALL_ALONG_EXTENT)
	extent *= layout.standing_height * _scale
	return clampf(extent / maxf(1.0, ends[0].distance_to(ends[1])), 0.0, 0.45)


## A random landing on a wall other than [param avoid_wall] (when [param other_wall]), away from the
## Wisp. Returns [wall, t].
func _pick_landing(avoid_wall: Wall, other_wall: bool) -> Array:
	var clearance: float = tuning.landing_clearance * layout.standing_height * _scale
	var best: Array = [Wall.CEILING, 0.5]
	var best_distance: float = -1.0
	for _attempt: int in 8:
		var wall: Wall = _random.randi_range(0, 3) as Wall
		if wall == avoid_wall:
			wall = ((int(wall) + 1 + _random.randi_range(0, 2)) % 4) as Wall
		if not other_wall and wall == avoid_wall:
			continue
		var margin: float = _margin(wall)
		var t: float = _random.randf_range(margin, 1.0 - margin)
		var distance: float = _body_centre(wall, t).distance_to(_target)
		if distance >= clearance:
			return [wall, t]
		if distance > best_distance:
			best_distance = distance
			best = [wall, t]
	return best


## Where on the Wisp's wall he lands to plant: on the far side of the Wisp, clear of it.
func _ill_landing_t(wall: Wall) -> float:
	var margin: float = _margin(wall)
	var ends: PackedVector2Array = _wall_ends(wall)
	var length: float = maxf(1.0, ends[0].distance_to(ends[1]))
	var gap: float = tuning.landing_clearance * layout.standing_height * _scale / length
	var wisp_t: float = _t_on(wall, _last_edge)
	if wisp_t > 0.5:
		var high: float = wisp_t - gap
		return _random.randf_range(margin, maxf(margin, high)) if high > margin else margin
	var low: float = wisp_t + gap
	return _random.randf_range(minf(low, 1.0 - margin), 1.0 - margin) if low < 1.0 - margin else 1.0 - margin


func _hit_radius() -> float:
	return tuning.hit_radius_ratio * tuning.standing_height * _viewport_scale


func _danger_radius() -> float:
	return tuning.fast_danger_ratio * tuning.standing_height * _viewport_scale


# --- Drawing --------------------------------------------------------------------------------------

func _play_wall_pose() -> void:
	var animation: StringName = FLOOR_IDLE if _is_floor_type(_wall) else WALL_IDLE
	_orient_wall(animation)
	_sprite.play(animation)


func _orient_current() -> void:
	if state == State.DASH:
		_orient_dash()
	else:
		_orient_wall(_sprite.animation)


## Puts a floor or wall animation on his wall: the feet or the grip on the wall line.
func _orient_wall(animation: StringName) -> void:
	var normal: Vector2 = _normal(_wall)
	var floor_drawn: bool = animation in [FLOOR_IDLE, PLANT_FLOOR, DEATH]
	var contact: float = layout.floor_contact_depth if floor_drawn else layout.wall_contact_depth
	_sprite.rotation = 0.0
	_sprite.flip_h = false
	_sprite.flip_v = false
	_sprite.scale = Vector2.ONE * _scale
	if floor_drawn and not _is_floor_type(_wall):
		# His death is drawn on a floor: on a side wall it turns so he collapses against the wall.
		_sprite.rotation = -PI * 0.5 if _wall == Wall.RIGHT else PI * 0.5
	elif floor_drawn:
		_sprite.flip_v = _wall == Wall.CEILING
		_sprite.flip_h = _target.x < global_position.x
	else:
		_sprite.flip_h = _wall == Wall.LEFT
	_sprite.position = normal * (contact * _scale - _body_depth(_wall))


## His flight is drawn flying left: turned toward the flight, mirrored when it goes right so he never
## flies upside down.
func _orient_dash() -> void:
	var direction: Vector2 = (_dash_to - _dash_from).normalized()
	if direction.is_zero_approx():
		direction = Vector2.LEFT
	_sprite.position = Vector2.ZERO
	_sprite.flip_v = false
	_sprite.scale = Vector2.ONE * _scale
	if direction.x > 0.0:
		_sprite.flip_h = true
		_sprite.rotation = direction.angle()
	else:
		_sprite.flip_h = false
		_sprite.rotation = direction.angle() - PI


func _play_hit_flash() -> void:
	_sprite.modulate = Color(HIT_FLASH_MODULATE, _sprite.modulate.a)
	create_tween().tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, _sprite.modulate.a),
		HIT_FLASH_DURATION)


func _start_flare(seconds: float) -> void:
	_flare = seconds
	_flare_length = maxf(0.01, seconds)


## His glow says what he is doing: a flare that fades (appearing, Death's Grin), a flare that builds
## before a dash (the warning), a steady bright glow in flight (hit him now), a faint one while planted.
## Before and during his fast attack the flare and the glow are crimson, not orange: it cannot be hit.
func _update_glow() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time * 18.0)
	var strength: float = _flare / _flare_length
	var fast: bool = is_fast_attack()
	if state == State.WARN:
		var built: float = 1.0 - clampf(_state_remaining / maxf(0.01, _warning_duration()), 0.0, 1.0)
		strength = maxf(strength, lerpf(0.45, 1.0, built))
	elif state == State.DASH:
		strength = maxf(strength, 0.85)
	var alpha: float = strength * (0.55 + 0.35 * pulse)
	if _planted:
		alpha = maxf(alpha, 0.22 + 0.12 * pulse)
	if state == State.DEFEATED:
		alpha = 0.0
		strength = 0.0
	_glow.modulate = Color(FAST_GLOW_COLOR if fast else GLOW_COLOR, alpha)
	if strength > 0.0:
		# His eyes flare: the whole figure warms toward his glow while it lasts, or reddens before and
		# during the fast attack.
		var warm: float = strength * (0.35 + 0.25 * pulse)
		if fast:
			_sprite.self_modulate = Color(1.0 + warm, 1.0 - warm * 0.35, 1.0 - warm * 0.35)
		else:
			_sprite.self_modulate = Color(1.0 + warm, 1.0 + warm * 0.45, 1.0 - warm * 0.2)
	else:
		_sprite.self_modulate = Color.WHITE


func _on_effects_draw() -> void:
	var grid: float = maxf(2.0, roundf(4.0 * _viewport_scale))
	for rot: Dictionary in _rots:
		_draw_rot(rot, grid)
	if _mark_remaining > 0.0:
		_draw_mark(grid)


## A rotting wall, drawn on the pixel grid along the wall line: dark crimson rot with bright veins.
## While it spreads it is dimmer and flickers; once deadly it is full and pulses; then it fades.
func _draw_rot(rot: Dictionary, grid: float) -> void:
	var wall: Wall = rot[&"wall"]
	var ends: PackedVector2Array = _wall_ends(wall)
	var along: Vector2 = (ends[1] - ends[0]).normalized()
	var normal: Vector2 = _normal(wall)
	var length: float = ends[0].distance_to(ends[1])
	var cover: Vector2 = _rot_cover(rot)
	var elapsed: float = rot[&"elapsed"]
	var spread: float = rot[&"spread"]
	var deadly_end: float = spread + float(rot[&"deadly"])
	var alpha: float = 0.55 + 0.2 * sin(_time * 22.0)
	var vein_boost: float = 0.4
	if elapsed >= spread and elapsed < deadly_end:
		alpha = 1.0
		vein_boost = 0.75 + 0.25 * sin(_time * 16.0)
	elif elapsed >= deadly_end:
		alpha = clampf(1.0 - (elapsed - deadly_end) / ROT_FADE, 0.0, 1.0)
	var depth: float = _player_radius * 1.15
	var first: int = int(floor(cover.x * length / grid))
	var last: int = int(ceil(cover.y * length / grid))
	var front_low: int = first + 2
	var front_high: int = last - 2
	var growing: bool = elapsed < spread
	for cell: int in range(first, last):
		var seed: int = cell * 92821 + int(wall) * 131
		var height: float = depth * (0.45 + 0.55 * float((seed >> 3) % 17) / 16.0)
		var cells: int = maxi(1, int(round(height / grid)))
		for step: int in cells:
			var point: Vector2 = ends[0] + along * (float(cell) * grid) + normal * (float(step) * grid)
			var colour: Color = ROT_BODY if step < cells - 1 else ROT_DARK
			if ((seed + step * 7) % 11) == 0:
				colour = ROT_DARK
			if step == 0:
				colour = ROT_VEIN.lerp(ROT_BODY, 1.0 - vein_boost)
			if growing and (cell <= front_low or cell >= front_high):
				colour = ROT_VEIN
			colour.a = alpha
			_effects.draw_rect(_cell_rect(point, along, normal, grid), colour)


## The Death's Grin mark: a crimson ring of pixels around the Wisp and his grin above it.
func _draw_mark(grid: float) -> void:
	var centre: Vector2 = _target
	var pulse: float = 0.6 + 0.4 * sin(_time * 12.0)
	var fade: float = clampf(_mark_remaining / 0.4, 0.0, 1.0)
	var radius: float = _player_radius * 1.55
	var ring := Color(ROT_BODY.lerp(ROT_VEIN, pulse * 0.6), fade)
	for index: int in 20:
		var angle: float = TAU * float(index) / 20.0 + _time * 1.5
		var point: Vector2 = centre + Vector2.RIGHT.rotated(angle) * radius
		_effects.draw_rect(Rect2(_snap(point, grid) - Vector2.ONE * grid, Vector2.ONE * grid * 2.0), ring)
	# His grin: two eyes and a row of jagged teeth, in his glow colour.
	var top: Vector2 = _snap(centre + Vector2(0.0, -radius - grid * 5.0), grid)
	var glow := Color(GLOW_COLOR, fade * (0.75 + 0.25 * pulse))
	var dark := Color(0.05, 0.02, 0.04, fade * 0.85)
	_effects.draw_rect(Rect2(top + Vector2(-grid * 5.0, -grid * 3.0), Vector2(grid * 10.0, grid * 6.0)), dark)
	_effects.draw_rect(Rect2(top + Vector2(-grid * 3.0, -grid * 2.0), Vector2(grid * 2.0, grid * 2.0)), glow)
	_effects.draw_rect(Rect2(top + Vector2(grid, -grid * 2.0), Vector2(grid * 2.0, grid * 2.0)), glow)
	for tooth: int in 7:
		var x: float = -grid * 3.5 + float(tooth) * grid
		var y: float = grid * (1.0 if tooth % 2 == 0 else 1.5)
		_effects.draw_rect(Rect2(top + Vector2(x, y), Vector2(grid, grid)), glow)


func _cell_rect(point: Vector2, along: Vector2, normal: Vector2, grid: float) -> Rect2:
	var corner: Vector2 = point
	var size := Vector2(absf(along.x) * grid + absf(normal.x) * grid, absf(along.y) * grid + absf(normal.y) * grid)
	if normal.x < 0.0:
		corner.x -= grid
	if normal.y < 0.0:
		corner.y -= grid
	return Rect2(_snap(corner, grid), size)


func _snap(point: Vector2, grid: float) -> Vector2:
	return Vector2(roundf(point.x / grid) * grid, roundf(point.y / grid) * grid)


static func _get_glow_texture() -> GradientTexture2D:
	if _glow_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
		_glow_texture = GradientTexture2D.new()
		_glow_texture.gradient = gradient
		_glow_texture.fill = GradientTexture2D.FILL_RADIAL
		_glow_texture.fill_from = Vector2(0.5, 0.5)
		_glow_texture.fill_to = Vector2(1.0, 0.5)
		_glow_texture.width = 64
		_glow_texture.height = 64
	return _glow_texture
