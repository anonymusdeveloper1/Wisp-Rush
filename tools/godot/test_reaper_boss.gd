extends SceneTree
## Verifies Reaper warnings, three phase geometries, exposed-core gate and victory rewards.

const REAPER_SCENE: PackedScene = preload("res://scenes/bosses/reaper_boss.tscn")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var summons: Array[PackedVector2Array] = []
	var rewards: Array[Vector2i] = []
	var boss := REAPER_SCENE.instantiate() as ReaperBoss
	root.add_child(boss)
	boss.summon_requested.connect(
		func(points: PackedVector2Array) -> void: summons.append(points)
	)
	boss.defeated.connect(
		func(_position: Vector2, score: int, shards: int) -> void:
			rewards.append(Vector2i(score, shards))
	)
	boss.configure(Rect2(0.0, 0.0, 1080.0, 1920.0), Vector2(540.0, 1840.0), 0, 99)
	if boss.get_current_health() != 6 or boss.get_phase() != ReaperBoss.Phase.SCYTHE_SWEEP:
		failures += 1
		push_error("reaper_boss: initial health or phase failed")

	boss._begin_scythe_warning()
	if not boss.get_dangerous_circles().is_empty():
		failures += 1
		push_error("reaper_boss: scythe warning became dangerous early")
	boss._begin_attack()
	if boss.get_dangerous_circles().size() != 1:
		failures += 1
		push_error("reaper_boss: scythe attack geometry missing")
	boss._begin_exposed()
	var centre: Vector2 = boss.global_position
	if not boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 10.0, 5, 10):
		failures += 1
		push_error("reaper_boss: exposed core rejected a crossing dash")
	if boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 10.0, 5, 10):
		failures += 1
		push_error("reaper_boss: same dash damaged twice")
	boss._begin_exposed()
	boss.try_dash_hit(centre - Vector2(200.0, 0.0), centre + Vector2(200.0, 0.0), 10.0, 1, 11)
	if boss.get_phase() != ReaperBoss.Phase.TELEPORT_HUNT:
		failures += 1
		push_error("reaper_boss: phase two health transition failed")

	boss._begin_teleport_warning()
	if not boss.get_dangerous_circles().is_empty():
		failures += 1
	boss._begin_attack()
	if boss.get_dangerous_circles().size() != 1 or summons.size() != 1 or summons[0].size() != 3:
		failures += 1
		push_error("reaper_boss: Teleport Hunt arrival or summon failed")
	centre = boss.global_position
	for dash_id: int in [12, 13]:
		boss._begin_exposed()
		boss.try_dash_hit(
			centre - Vector2(200.0, 0.0),
			centre + Vector2(200.0, 0.0),
			10.0,
			1,
			dash_id,
		)
	if boss.get_phase() != ReaperBoss.Phase.DEATH_CORRIDORS:
		failures += 1
		push_error("reaper_boss: phase three health transition failed")

	boss._begin_corridor_warning()
	if not boss.get_dangerous_lanes().is_empty():
		failures += 1
		push_error("reaper_boss: warned lanes became dangerous early")
	boss._begin_attack()
	if boss.get_dangerous_lanes().size() != 2 or boss.get_lane_radius() <= 0.0:
		failures += 1
		push_error("reaper_boss: death-corridor geometry missing")
	for dash_id: int in [14, 15]:
		boss._begin_exposed()
		boss.try_dash_hit(
			boss.global_position - Vector2(200.0, 0.0),
			boss.global_position + Vector2(200.0, 0.0),
			10.0,
			1,
			dash_id,
		)
	await create_timer(0.8).timeout
	if rewards.size() != 1 or rewards[0] != Vector2i(1500, 25):
		failures += 1
		push_error("reaper_boss: defeat reward signal failed")

	var harder := REAPER_SCENE.instantiate() as ReaperBoss
	root.add_child(harder)
	harder.configure(Rect2(0.0, 0.0, 1080.0, 1920.0), Vector2(540.0, 1840.0), 1, 99)
	if harder.get_maximum_health() != 9:
		failures += 1
		push_error("reaper_boss: recurring encounter health scaling failed")
	if failures == 0:
		print("reaper_boss: three phases, hit gate, rewards and escalation passed")
	quit(failures)
