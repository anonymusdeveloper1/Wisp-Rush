extends SceneTree
## Live pickup collection, timed effects, expiry, pause, projectile banishment and Ward gestures.

const GAME: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error("pickup_effects: %s" % message)


func _run() -> void:
	var game := GAME.instantiate() as GameWorld
	var profile := RunProfile.new()
	profile.mode = RunProfile.MODE_TUTORIAL
	game.configure_run(profile)
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await create_timer(0.6).timeout
	var player: WispPlayer = game._player
	var items: RunItems = game.get_run_items()
	var baseline: float = player.get_dash_corridor_radius()
	_check(game.get_node_or_null(^"RunProgression") == null, "XP component is still live")
	_check(game.get_node_or_null(^"HUD/UpgradeTray") == null, "upgrade tray is still live")
	_check(player.get_maximum_health() == 1 and player.dash_damage == 1, "fresh baseline")
	game.spawn_scripted_item(RunItemCatalog.REAPERS_EDGE, player.global_position)
	await physics_frame
	await physics_frame
	_check(items.is_active(RunItemCatalog.REAPERS_EDGE), "touch pickup did not activate")
	_check(is_equal_approx(player.get_dash_corridor_radius(), baseline * 2.0), "Edge corridor")
	items.advance(4.0)
	game.activate_item(RunItemCatalog.REAPERS_EDGE)
	_check(is_equal_approx(items.get_remaining(RunItemCatalog.REAPERS_EDGE), 10), "refresh timer")
	_check(is_equal_approx(player.get_dash_corridor_radius(), baseline * 2.0), "Edge stacked")
	game.activate_item(RunItemCatalog.FORTUNE_STAR)
	_check(game._apply_item_score_bonus(100) == 200, "Star score multiplier")
	game.set_rush_enabled(true)
	game._rush_remaining = 2.0
	_check(game._apply_item_score_bonus(100) == roundi(200 * game.feel_tuning.score_multiplier),
		"Star/RUSH score multiplication")
	game.set_rush_enabled(false)
	# Contacts are checked separately below; live targets near the bomb must not kill the fixture.
	player.set_damage_immune(true)
	# A regular kill can drop an item and RP independently, without collecting either twice.
	game._run_items.catalog = game._run_items.catalog.duplicate() as RunItemCatalog
	game._run_items.catalog.drop_chance = 1.0
	game._scripted = false
	var dropper: EnemyActor = game.spawn_scripted_enemy(&"hooded_scribe", Vector2(0.4, 0.3))
	dropper.tuning = dropper.tuning.duplicate() as EnemyTuning
	dropper.tuning.shard_drop_chance = 1.0
	await create_timer(0.8).timeout
	dropper.try_direct_hit(1, -777)
	var item_drops: int = 0
	var rp_drops: int = 0
	for child: Node in game._pickup_layer.get_children():
		if child is RunItemPickup:
			item_drops += 1
		elif child is SoulShardPickup:
			rp_drops += 1
	_check(item_drops == 1 and rp_drops == 1, "independent item/RP drop rolls")
	game._scripted = true
	game._run_items.catalog.drop_chance = 0.1
	game._spawn_rp_pickup(game.arena_to_world(Vector2(0.15, 0.15)))
	game.activate_item(RunItemCatalog.RIFT_MAGNET)
	_check(game._get_pickup_attraction_radius() > game._arena_rect.size.y, "Magnet radius")
	await create_timer(0.9).timeout
	_check(game.get_rp_collected() > 0, "Magnet did not collect distant RP")
	game.place_player(Vector2(0.5, 1.0))
	var enemy: EnemyActor = game.spawn_scripted_enemy(&"hooded_scribe", Vector2(0.5, 0.3))
	game.activate_item(RunItemCatalog.STILLGLASS)
	_check(is_equal_approx(enemy._world_speed, 0.55), "existing enemy slowdown")
	var later: EnemyActor = game.spawn_scripted_enemy(&"claw_ghost", Vector2(0.7, 0.3))
	_check(is_equal_approx(later._world_speed, 0.55), "new enemy slowdown")
	var shot := EnemyProjectile.new()
	shot.setup(enemy.tuning, null, game.arena_to_world(Vector2(0.2, 0.2)),
		game.arena_to_world(Vector2(0.8, 0.2)), game._arena_rect.size.x / 1080.0)
	game._on_enemy_projectile_fired(shot)
	_check(is_equal_approx(shot._world_speed, 0.55), "new projectile slowdown")
	var left: float = items.get_remaining(RunItemCatalog.STILLGLASS)
	paused = true
	await create_timer(0.15, true).timeout
	_check(is_equal_approx(left, items.get_remaining(RunItemCatalog.STILLGLASS)), "paused timer")
	paused = false
	items.advance(11.0)
	_check(not items.is_active(RunItemCatalog.STILLGLASS), "timer did not expire")
	_check(is_equal_approx(player.get_dash_corridor_radius(), baseline), "Edge did not restore")
	_check(game._apply_item_score_bonus(100) == 100, "Star did not restore")
	_check(is_equal_approx(enemy._world_speed, 1), "enemy speed did not restore")
	_check(is_equal_approx(shot._world_speed, 1), "shot speed did not restore")
	game.clear_scripted_arena()
	await process_frame
	var origin: Vector2 = game.get_player_position() + Vector2(0, -80)
	var nearby: EnemyActor = game.debug_spawn_enemy(&"hooded_scribe", origin)
	var far: EnemyActor = game.spawn_scripted_enemy(&"hooded_scribe", Vector2(0.2, 0.2))
	await create_timer(0.8).timeout
	shot = EnemyProjectile.new()
	shot.setup(nearby.tuning, null, origin, origin + Vector2.RIGHT * 100, 1.0)
	game._on_enemy_projectile_fired(shot)
	shot.mode = EnemyProjectile.Mode.MARK
	game.activate_item(RunItemCatalog.BANISH_BOMB)
	_check(nearby.state == EnemyActor.State.DYING, "Bomb missed nearby enemy")
	_check(far.state == EnemyActor.State.ACTIVE, "Bomb killed distant enemy")
	_check(shot.mode == EnemyProjectile.Mode.FADING, "Bomb did not banish wall projectile")
	game.clear_scripted_arena()
	await create_timer(0.5).timeout
	game.activate_item(RunItemCatalog.ECHO_WISP)
	var first: EnemyActor = game.spawn_scripted_enemy(&"hooded_scribe", Vector2(0.3, 0.3))
	var second: EnemyActor = game.spawn_scripted_enemy(&"hooded_scribe", Vector2(0.4, 0.3))
	var third: EnemyActor = game.spawn_scripted_enemy(&"hooded_scribe", Vector2(0.8, 0.3))
	await create_timer(0.8).timeout
	game._on_player_dash_started(Vector2.UP, 700)
	first.try_direct_hit(1, 700)
	_check(second.state == EnemyActor.State.DYING, "Echo did not strike another enemy")
	_check(third.state == EnemyActor.State.ACTIVE, "Echo recursively struck twice")
	game.clear_scripted_arena()
	await process_frame
	player.set_damage_immune(false)
	game.spawn_scripted_item(RunItemCatalog.SOUL_WARD, player.global_position)
	await physics_frame
	await physics_frame
	_check(game.get_soul_ward_stock() == 1 and not player.has_soul_ward(), "Ward auto-activated")
	player._begin_pointer(player.global_position, 0)
	player._end_pointer(player.global_position, 0)
	_check(not player.has_soul_ward(), "single tap activated Ward")
	player._begin_pointer(player.global_position, 0)
	player._end_pointer(player.global_position, 0)
	_check(player.has_soul_ward() and game.get_soul_ward_stock() == 0, "double tap Ward")
	game.set_soul_ward_stock(2)
	_check(not game.activate_soul_ward() and game.get_soul_ward_stock() == 2, "active Ward spent")
	player.set_damage_immune(true)
	_check(not player.take_hazard_damage(player.global_position), "RUSH immunity failed")
	_check(player.has_soul_ward(), "RUSH consumed Ward")
	player.set_damage_immune(false)
	_check(player.take_hazard_damage(player.global_position), "Ward did not block hit")
	_check(player.get_current_health() == 1 and not player.has_soul_ward(), "Ward health/break")
	_check(not player.take_hazard_damage(player.global_position), "Ward escape immunity")
	await create_timer(1.0).timeout
	_check(player.take_hazard_damage(player.global_position), "escape immunity never expired")
	_check(player.get_current_health() == 0, "next unprotected hit not fatal")
	game.queue_free()
	await process_frame
	print("pickup_effects: seven live effects, pause, expiry and double-tap shield checked")
	quit(_failures)
