extends SceneTree
## Verifies that all eight run mutations change their promised live gameplay behavior.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 712
	root.add_child(game)
	await create_timer(0.8).timeout
	# Real runs never teach any more (2026-09-15): stop the waves the lesson used to hold back.
	game.debug_quiet_arena()

	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	var progression := game.get_node("RunProgression") as RunProgression
	var pickup_layer := game.get_node("WorldContent/PickupLayer") as Node2D
	var effects_layer := game.get_node("WorldContent/EffectsLayer") as Node2D

	# No permanent power (ADR-0013): with the Sanctum gone a run starts from the no-bonus baseline.
	if (
		player.get_maximum_health() != 3
		or not is_equal_approx(player.get_blade_width_multiplier(), 1.0)
		or not is_equal_approx(player.get_dash_speed_multiplier(), 1.0)
		or not is_equal_approx(game._get_pickup_attraction_radius(), 150.0)
		or progression.get_total_mutation_levels() != 0
	):
		failures += 1
		push_error("mutation_effects: a fresh run did not start from the no-bonus baseline")

	# Soul Hunger, Wide Reap and Void Velocity feed the live dash and scoring values.
	progression._levels[&"soul_hunger"] = 2
	progression._levels[&"wide_reap"] = 2
	progression._levels[&"void_velocity"] = 2
	game._update_player_mutation_stats()
	if (
		player.dash_damage != 3
		or not is_equal_approx(player.get_blade_width_multiplier(), 1.54)
		or not is_equal_approx(player.get_dash_speed_multiplier(), 1.2)
		or game._apply_velocity_score_bonus(100) != 110
	):
		failures += 1
		push_error("mutation_effects: dash damage, width, speed or score scaling failed")
	if not is_equal_approx(game._get_pickup_attraction_radius(), 220.0):
		failures += 1
		push_error("mutation_effects: Soul Hunger attraction radius failed")

	# Soul Hunger must also attract a real dropped Rift Points shard from beyond the base radius.
	var shard_start: Vector2 = player.global_position + Vector2(200.0, 0.0)
	game._spawn_rp_pickup(shard_start)
	await create_timer(0.12).timeout
	var shard := pickup_layer.get_child(0) as SoulShardPickup
	if shard.global_position.distance_to(player.global_position) >= 200.0:
		failures += 1
		push_error("mutation_effects: Soul Hunger did not attract a live shard")

	# Soul Vessel adds a fragment and Reaper's Gift restores the missing fragment.
	if not player.take_contact_damage(player.global_position):
		failures += 1
		push_error("mutation_effects: could not establish damaged health state")
	progression._levels[&"soul_vessel"] = 1
	game._on_mutation_applied(&"soul_vessel", 1)
	if player.get_maximum_health() != 4 or player.get_current_health() != 3:
		failures += 1
		push_error("mutation_effects: Soul Vessel maximum-health change failed")
	progression._levels[&"reapers_gift"] = 5
	game._kill_streak = 18
	game._try_reapers_gift()
	if player.get_current_health() != 4 or game._kill_streak != 0:
		failures += 1
		push_error("mutation_effects: Reaper's Gift streak heal failed")

	# Death Pulse damages an active enemy and creates its visible area effect.
	progression._levels[&"death_pulse"] = 1
	var pulse_enemy: EnemyActor = game._spawn_enemy(&"soul_wisp", game._arena_rect.get_center(), false)
	await create_timer(0.7).timeout
	game._release_death_pulse(pulse_enemy.global_position, 31)
	if pulse_enemy.state != EnemyActor.State.DYING or effects_layer.get_child_count() != 1:
		failures += 1
		push_error("mutation_effects: Death Pulse damage or effect failed")

	# Cold Wake slows every active enemy crossed by the dash corridor.
	progression._levels[&"soul_hunger"] = 0
	progression._levels[&"cold_wake"] = 1
	game._update_player_mutation_stats()
	var bone: EnemyActor = game._spawn_enemy(&"bone_mote", game._arena_rect.get_center(), false)
	await create_timer(0.7).timeout
	game._on_player_dash_segment_swept(
		bone.global_position - Vector2(180.0, 0.0),
		bone.global_position + Vector2(180.0, 0.0),
		51,
		10.0,
	)
	if not bone.is_slowed() or bone.get_current_health() != 2:
		failures += 1
		push_error("mutation_effects: Cold Wake slow or damage interaction failed")

	# Soul Link propagates one lethal dash event to the nearest active enemy.
	progression._levels[&"soul_link"] = 1
	var link_origin: Vector2 = game._arena_rect.get_center() + Vector2(-120.0, 180.0)
	var first: EnemyActor = game._spawn_enemy(&"soul_wisp", link_origin, false)
	var second: EnemyActor = game._spawn_enemy(&"soul_wisp", link_origin + Vector2(100.0, 0.0), false)
	await create_timer(0.7).timeout
	game._link_remaining_by_event[71] = 1
	first.try_direct_hit(1, 71)
	if first.state != EnemyActor.State.DYING or second.state != EnemyActor.State.DYING:
		failures += 1
		push_error("mutation_effects: Soul Link did not chain to the nearest enemy")

	paused = false
	if failures == 0:
		print("mutation_effects: all eight mutation behaviors passed")
	game.queue_free()
	quit(failures)
