extends SceneTree
## Cinder Shade split config, Warden shield arc and Rift Spawn tether-only damage.

const CINDER: PackedScene = preload("res://scenes/enemies/cinder_shade.tscn")
const WARDEN: PackedScene = preload("res://scenes/enemies/warden.tscn")
const RIFT_SPAWN: PackedScene = preload("res://scenes/enemies/rift_spawn.tscn")
const CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const ARENA := Rect2(0, 0, 1080, 1920)


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var failures: int = 0

	# --- Cinder Shade: split is data, and its children are a real registered kind.
	var cinder := CINDER.instantiate() as EnemyActor
	root.add_child(cinder)
	if cinder.tuning.split_kind != &"soul_wisp" or cinder.tuning.split_count != 2:
		failures += 1
		push_error("rift_enemies: cinder shade split config is wrong")
	if cinder.tuning.split_scale >= 1.0:
		failures += 1
		push_error("rift_enemies: split children are not smaller than the parent")

	# --- Warden: blocks a dash into the shield, damages one that arrives from behind.
	var warden := WARDEN.instantiate() as WardenEnemy
	root.add_child(warden)
	warden.set_arena_rect(ARENA)
	warden.set_viewport_width(ARENA.size.x)
	warden.global_position = ARENA.get_center()
	_force_active(warden)
	if warden.tuning.shield_arc_degrees <= 0.0:
		failures += 1
		push_error("rift_enemies: warden has no shield arc")
	var centre: Vector2 = warden.global_position
	var reach: float = warden.get_collision_radius() + 400.0
	# Warden faces DOWN before it has a target, so a dash travelling UP arrives into the plate.
	var into_shield: bool = warden.try_dash_hit(
		centre + Vector2(0, reach), centre - Vector2(0, reach), 8.0, 1, 101
	)
	if into_shield:
		failures += 1
		push_error("rift_enemies: warden took damage through its shield")
	if not warden.is_blocking():
		failures += 1
		push_error("rift_enemies: warden did not register a block")
	var from_behind: bool = warden.try_dash_hit(
		centre - Vector2(0, reach), centre + Vector2(0, reach), 8.0, 1, 102
	)
	if not from_behind:
		failures += 1
		push_error("rift_enemies: warden ignored a hit from behind")

	# --- Rift Spawn: the tether is the weak point, the bodies are not.
	var spawn := RIFT_SPAWN.instantiate() as RiftSpawnEnemy
	root.add_child(spawn)
	spawn.set_arena_rect(ARENA)
	spawn.set_viewport_width(ARENA.size.x)
	spawn.global_position = ARENA.get_center()
	_force_active(spawn)
	var ends: PackedVector2Array = spawn.get_tether_endpoints()
	if ends.size() != 2 or ends[0].distance_to(ends[1]) <= 1.0:
		failures += 1
		push_error("rift_enemies: rift spawn has no tether span")
	# A dash crossing the midpoint cuts the tether.
	var mid: Vector2 = ends[0].lerp(ends[1], 0.5)
	var across: Vector2 = (ends[1] - ends[0]).orthogonal().normalized() * 300.0
	if not spawn.try_dash_hit(mid - across, mid + across, 6.0, 1, 201):
		failures += 1
		push_error("rift_enemies: cutting the tether did not damage the pair")
	# A dash far outside the pair must miss entirely.
	var spawn2 := RIFT_SPAWN.instantiate() as RiftSpawnEnemy
	root.add_child(spawn2)
	spawn2.set_arena_rect(ARENA)
	spawn2.set_viewport_width(ARENA.size.x)
	spawn2.global_position = ARENA.get_center()
	_force_active(spawn2)
	var far: Vector2 = spawn2.global_position + Vector2(0, 900)
	if spawn2.try_dash_hit(far - Vector2(400, 0), far + Vector2(400, 0), 6.0, 1, 202):
		failures += 1
		push_error("rift_enemies: a distant dash damaged the tethered pair")

	# --- Every substituted kind must be a real enemy the world can spawn.
	var known: Array[StringName] = [
		&"soul_wisp", &"shard_wraith", &"bone_mote",
		&"cinder_shade", &"warden", &"rift_spawn",
		&"echo", &"slag_hulk", &"frost_wisp", &"court_shade",
	]
	# Each Rift past the baseline must actually field a different roster.
	var baseline := CATALOG.get_rift(&"obsidian_garden")
	for rift: RiftData in CATALOG.load_rifts():
		if rift.rift_id == baseline.rift_id:
			continue
		var differs: bool = false
		for base: StringName in [&"soul_wisp", &"shard_wraith", &"bone_mote"]:
			if rift.substitute_enemy(base) != baseline.substitute_enemy(base):
				differs = true
		if not differs:
			failures += 1
			push_error("rift_enemies: %s fields the baseline roster" % rift.rift_id)
	for rift: RiftData in CATALOG.load_rifts():
		for base: StringName in [&"soul_wisp", &"shard_wraith", &"bone_mote"]:
			var resolved: StringName = rift.substitute_enemy(base)
			if resolved not in known:
				failures += 1
				push_error("rift_enemies: %s maps %s to unknown kind %s" % [
					rift.rift_id, base, resolved,
				])

	# THE INVARIANT: a splitter's children must never themselves split, once the Rift's roster
	# remap is taken into account. Ember Hollow maps soul_wisp -> cinder_shade, and Cinder Shade
	# splits into soul_wisp, so remapping the child would spawn two more splitters per death —
	# an unbounded chain reaction that ran the score to hundreds of millions on device.
	var tunings: Dictionary = {
		&"soul_wisp": load("res://data/enemies/soul_wisp.tres") as EnemyTuning,
		&"shard_wraith": load("res://data/enemies/shard_wraith.tres") as EnemyTuning,
		&"bone_mote": load("res://data/enemies/bone_mote.tres") as EnemyTuning,
		&"cinder_shade": load("res://data/enemies/cinder_shade.tres") as EnemyTuning,
		&"warden": load("res://data/enemies/warden.tres") as EnemyTuning,
		&"rift_spawn": load("res://data/enemies/rift_spawn.tres") as EnemyTuning,
		&"echo": load("res://data/enemies/echo.tres") as EnemyTuning,
		&"slag_hulk": load("res://data/enemies/slag_hulk.tres") as EnemyTuning,
		&"frost_wisp": load("res://data/enemies/frost_wisp.tres") as EnemyTuning,
		&"court_shade": load("res://data/enemies/court_shade.tres") as EnemyTuning,
	}
	for rift: RiftData in CATALOG.load_rifts():
		for kind: StringName in tunings:
			var tuning := tunings[kind] as EnemyTuning
			if tuning == null or tuning.split_count <= 0 or tuning.split_kind.is_empty():
				continue
			# Children are spawned with the roster remap disabled, so the literal kind must be safe.
			var child := tunings.get(tuning.split_kind) as EnemyTuning
			if child == null:
				failures += 1
				push_error("rift_enemies: %s splits into unknown kind %s" % [
					kind, tuning.split_kind,
				])
			elif child.split_count > 0:
				failures += 1
				push_error("rift_enemies: %s splits into %s, which also splits" % [
					kind, tuning.split_kind,
				])
			# NOTE: `split_kind` here is deliberately checked literally. Several Rifts remap the
			# base kinds onto splitters (Ember Hollow maps soul_wisp -> cinder_shade), which is
			# exactly why GameWorld spawns split children with the roster remap disabled. That
			# runtime behaviour is asserted live in test_rift_rules.gd.

	if failures == 0:
		print("rift_enemies: split config, shield arc, tether damage, rosters and the no-chain-reaction invariant validated")
	quit(failures)


## Skips the arrival telegraph so hit tests run against a live enemy.
func _force_active(enemy: EnemyActor) -> void:
	enemy.state = EnemyActor.State.ACTIVE
