extends SceneTree
## Verifies Grimgrin: his frames, walls, the warning and the harmless, hittable flight, the ill wall's
## rot, double hits while planted, the second half and Death's Grin, the random spawns, and his defeat
## rewards.

const GRIMGRIN_SCENE: PackedScene = preload("res://scenes/bosses/grimgrin_boss.tscn")
const ARENA := Rect2(174.0, 419.0, 730.0, 1089.0)
const ANIMATIONS: Array[StringName] = [
	&"floor_idle", &"wall_idle", &"plant_floor", &"plant_wall", &"dash", &"death",
]

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("grimgrin_boss: %s" % message)


## Waits physics frames until [param condition] holds, at most [param seconds].
func _wait_until(condition: Callable, seconds: float) -> bool:
	var frames: int = int(seconds * 60.0)
	for _frame: int in frames:
		if condition.call():
			return true
		await physics_frame
	return condition.call()


func _run() -> void:
	var healths: Array[Vector2i] = []
	var phases: Array[int] = []
	var spawns: Array[Vector2i] = []
	var rewards: Array[Vector2i] = []
	var boss := GRIMGRIN_SCENE.instantiate() as GrimgrinBoss
	root.add_child(boss)
	boss.health_changed.connect(func(current: int, maximum: int) -> void: healths.append(Vector2i(current, maximum)))
	boss.phase_changed.connect(func(phase: int) -> void: phases.append(phase))
	boss.spawn_requested.connect(func(count: int, cap: int) -> void: spawns.append(Vector2i(count, cap)))
	boss.defeated.connect(
		func(_position: Vector2, score: int, rp: int) -> void: rewards.append(Vector2i(score, rp))
	)
	var frames: SpriteFrames = (boss.get_node("%Sprite") as AnimatedSprite2D).sprite_frames
	for animation: StringName in ANIMATIONS:
		if not frames.has_animation(animation):
			_fail("frames miss %s" % animation)
	if frames.get_frame_count(&"dash") != GrimgrinBoss.DASH_FLIGHT_FRAMES:
		_fail("the dash has %d frames, not %d" % [frames.get_frame_count(&"dash"), GrimgrinBoss.DASH_FLIGHT_FRAMES])

	var floor_wisp := Vector2(ARENA.get_center().x, ARENA.end.y - 40.0)
	boss.set_player_radius(36.0)
	boss.configure(ARENA, floor_wisp, 0, 4242)
	if boss.get_maximum_health() != 12 or boss.get_current_health() != 12 or healths.is_empty():
		_fail("the first encounter does not start at 12 health")
	if boss.get_wall() == GrimgrinBoss.Wall.FLOOR:
		_fail("he appeared on the Wisp's wall")
	if not boss.get_dangerous_circles().is_empty() or not boss.get_dangerous_lanes().is_empty():
		_fail("he is dangerous before he moves")
	if not boss.is_core_exposed():
		_fail("he cannot be hit on his wall")
	boss.set_physics_process(false)

	# The warning: after his rest he holds his wall, flaring, then dashes.
	var start_wall: int = boss.get_wall()
	boss.state = GrimgrinBoss.State.REST
	boss._state_remaining = 0.0
	boss._ill_cooldown = 100.0
	# No fast attack in this test: the checks below hit him at moments it would make him unhittable.
	boss._fast_cooldown = 1000.0
	boss._physics_process(1.0 / 60.0)
	if boss.state != GrimgrinBoss.State.WARN:
		_fail("he dashed without the warning")
	for _step: int in int(boss.tuning.dash_warning_duration * 60.0) + 2:
		boss._physics_process(1.0 / 60.0)
	if boss.state != GrimgrinBoss.State.DASH:
		_fail("the warning did not end in a dash")

	# His flight: harmless to the Wisp, and a hit lands; he lands on another wall.
	if not boss.get_dangerous_circles().is_empty():
		_fail("his dash hurts the Wisp")
	var centre: Vector2 = boss.global_position
	if not boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 20.0, 1, 1):
		_fail("a Wisp dash missed him mid-flight")
	for _step: int in 400:
		if boss.state != GrimgrinBoss.State.DASH:
			break
		boss._physics_process(1.0 / 60.0)
	if boss.state != GrimgrinBoss.State.REST or not boss.get_dangerous_circles().is_empty():
		_fail("the dash did not end in a harmless rest")
	if boss.get_wall() == start_wall:
		_fail("the dash landed on the wall it left")
	if not ARENA.grow(boss.tuning.standing_height).has_point(boss.global_position):
		_fail("he landed outside the arena at %s" % boss.global_position)

	# A hit on his wall counts one; the same Wisp dash never hits twice.
	centre = boss.global_position
	if not boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 20.0, 1, 2):
		_fail("a crossing dash missed him on his wall")
	if boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 20.0, 1, 2):
		_fail("one dash hit him twice")
	if boss.get_current_health() != 10:
		_fail("a hit in flight and one on his wall did not count one each (health %d)" % boss.get_current_health())

	# The ill wall: he goes to the Wisp's wall, plants, the wall rots, then it is deadly.
	boss.set_physics_process(true)
	boss.set_target_position(floor_wisp)
	boss.set_last_edge_position(floor_wisp)
	boss._begin_dash(true)
	if not await _wait_until(func() -> bool: return boss.state == GrimgrinBoss.State.PLANT, 5.0):
		_fail("the ill-wall dash never planted")
	if boss.get_wall() != GrimgrinBoss.Wall.FLOOR:
		_fail("the ill wall is not the Wisp's wall")
	# His height in this arena: a landing keeps more than that between him and the Wisp.
	var height: float = boss.tuning.standing_height * ARENA.size.x / boss.tuning.design_width
	if boss.global_position.distance_to(floor_wisp) < height:
		_fail("he planted on top of the Wisp")
	if not await _wait_until(func() -> bool: return boss.is_planted(), 2.0):
		_fail("both katanas never went in")
	if not boss.get_dangerous_lanes().is_empty():
		_fail("the rot was deadly while it spread")
	var health_before: int = boss.get_current_health()
	centre = boss.global_position
	boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 20.0, 1, 3)
	if boss.get_current_health() != health_before - boss.tuning.planted_hit_value:
		_fail("a hit while planted did not count %d" % boss.tuning.planted_hit_value)
	if not await _wait_until(func() -> bool: return not boss.get_dangerous_lanes().is_empty(), 2.5):
		_fail("the rotted wall never turned deadly")
	else:
		var lane: PackedVector2Array = boss.get_dangerous_lanes()[0]
		if not is_equal_approx(lane[0].y, ARENA.end.y) or not is_equal_approx(lane[1].y, ARENA.end.y):
			_fail("the deadly lane is not the floor")
		if absf(lane[0].x - lane[1].x) < ARENA.size.x - 1.0:
			_fail("the deadly lane does not cover the whole wall")
		if boss.get_lane_radius() <= 0.0:
			_fail("the deadly lane has no width")
	if not await _wait_until(func() -> bool: return boss.state == GrimgrinBoss.State.REST, 3.0):
		_fail("he never left his planted pose")
	if boss.is_planted() or not boss.get_dangerous_lanes().is_empty():
		_fail("the ill wall outlasted its time")

	# The second half: at half health, phase two.
	boss.set_physics_process(false)
	var dash_id: int = 10
	while boss.get_current_health() > 6:
		dash_id += 1
		centre = boss.global_position
		boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 20.0, 1, dash_id)
	if boss.get_phase() != 2 or phases.back() != 2:
		_fail("the second half never started")

	# Death's Grin: the mark, then the next wall the Wisp lands on rots at once.
	boss._grin()
	if not boss.is_marking():
		_fail("Death's Grin did not mark the Wisp")
	var left_landing := Vector2(ARENA.position.x, ARENA.get_center().y)
	boss.set_last_edge_position(left_landing)
	if boss.is_marking():
		_fail("the mark outlasted the landing")
	for _step: int in int((boss.tuning.grin_rot_spread_duration + 0.1) * 60.0):
		boss._physics_process(1.0 / 60.0)
	var left_deadly: bool = false
	for lane: PackedVector2Array in boss.get_dangerous_lanes():
		if is_equal_approx(lane[0].x, ARENA.position.x) and is_equal_approx(lane[1].x, ARENA.position.x):
			left_deadly = true
	if not left_deadly:
		_fail("the marked landing wall did not turn deadly")

	# Random spawns, two at a time in the second half, with the live cap.
	spawns.clear()
	boss.state = GrimgrinBoss.State.REST
	boss._state_remaining = 100.0
	for _step: int in int(boss.tuning.spawn_interval_max * 60.0) + 10:
		boss._physics_process(1.0 / 60.0)
	if spawns.is_empty() or spawns[0] != Vector2i(boss.tuning.second_half_spawn_count, boss.tuning.max_live_enemies):
		_fail("no second-half spawn request (%s)" % [spawns])

	# Defeat: the death plays out and the rewards arrive.
	var tuning: GrimgrinTuning = boss.tuning
	boss.set_physics_process(true)
	while boss.get_current_health() > 0:
		dash_id += 1
		boss.state = GrimgrinBoss.State.REST
		centre = boss.global_position
		boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 20.0, 1, dash_id)
	if boss.state != GrimgrinBoss.State.DEFEATED or not boss.get_dangerous_lanes().is_empty():
		_fail("his defeat left him dangerous")
	if not await _wait_until(func() -> bool: return not rewards.is_empty(), 5.0):
		_fail("his defeat never paid out")
	elif rewards[0] != Vector2i(tuning.score_reward, tuning.rp_reward):
		_fail("wrong defeat rewards %s" % rewards[0])

	# Later encounters are tougher.
	var harder := GRIMGRIN_SCENE.instantiate() as GrimgrinBoss
	root.add_child(harder)
	harder.configure(ARENA, floor_wisp, 1, 7)
	if harder.get_maximum_health() != 15:
		_fail("the second encounter does not start at 15 health")
	harder.queue_free()

	if _failures == 0:
		print("grimgrin_boss: frames, walls, dash, ill wall, double hits, Death's Grin, spawns and defeat passed")
	quit(_failures)
