extends SceneTree
## Live checks that each Rift's rule twist actually changes the run, not just the data.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORMS: FormCatalog = preload("res://data/forms/default_catalog.tres")

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	await _check_baseline()
	await _check_boss_rush()
	await _check_shrinking_floor()
	await _check_drift()
	await _check_portals()
	await _check_split_chain_reaction()
	for rift_id: StringName in [
		&"obsidian_garden", &"shattered_rift", &"ember_hollow", &"frozen_choir", &"reapers_court",
	]:
		await _check_polygon_playfield(rift_id)
	if _failures == 0:
		print("rift_rules: baseline, boss rush, shrinking floor and drift verified live")
	quit(_failures)


## Builds a live run in one Rift and returns it once the arena has settled.
func _start(rift_id: StringName) -> GameWorld:
	# A previous check can leave the tree paused: killing enough enemies awards XP, the upgrade
	# picker pauses the tree, and freeing that GameWorld does not unpause it (in the real game Main
	# does). Every later check would then run frozen and time out waiting for the Wisp to rest.
	paused = false
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.tutorial_enabled = false
	game.run_seed = 7
	game.auto_pause_on_focus_loss = false
	game.configure_run_profile(FORMS.get_form(&"void"), "", CATALOG.get_rift(rift_id), 1)
	root.add_child(game)
	await create_timer(0.6).timeout
	return game


func _player(game: GameWorld) -> WispPlayer:
	return game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer


func _fail(message: String) -> void:
	_failures += 1
	push_error("rift_rules: %s" % message)


func _check_baseline() -> void:
	var game: GameWorld = await _start(&"obsidian_garden")
	# The baseline backdrop must still be the original arena art.
	var backdrop := game.get_node("FullBleedBackground") as TextureRect
	if backdrop.texture == null:
		_fail("baseline rift has no backdrop")
	if game.get_boss_wave_interval() != 4:
		_fail("baseline boss cadence changed, expected 4 waves")
	if not is_equal_approx(game.get_arena_shrink(), 1.0):
		_fail("baseline arena should not shrink")
	game.queue_free()
	await process_frame


func _check_boss_rush() -> void:
	var game: GameWorld = await _start(&"reapers_court")
	# Twice the boss cadence, twice the payout.
	if game.get_boss_wave_interval() != 2:
		_fail("boss rush did not halve the boss cadence, got %d"
			% game.get_boss_wave_interval())
	if not is_equal_approx(game.get_reward_multiplier(), 2.0):
		_fail("boss rush did not double rewards, got %f" % game.get_reward_multiplier())
	game.queue_free()
	await process_frame


func _check_shrinking_floor() -> void:
	var game: GameWorld = await _start(&"ember_hollow")
	var full: Rect2 = game.get_arena_rect()
	# Drive the rule directly to the last wave of the level rather than waiting ~66 s.
	game.debug_apply_rift_rules(4)
	var shrunk: Rect2 = game.get_arena_rect()
	# Compare area, not both axes: ARENA_MIN_VIEWPORT_FRACTION can already pin one axis at its
	# floor, so at some aspect ratios only the other axis is free to contract.
	var full_area: float = full.size.x * full.size.y
	var shrunk_area: float = shrunk.size.x * shrunk.size.y
	if shrunk_area >= full_area:
		_fail("ember hollow floor did not contract: %s -> %s" % [full.size, shrunk.size])
	if shrunk.size.x > full.size.x or shrunk.size.y > full.size.y:
		_fail("ember hollow floor grew on an axis: %s -> %s" % [full.size, shrunk.size])
	if game.get_arena_shrink() >= 1.0:
		_fail("ember hollow shrink factor did not drop")
	# The Wisp must still be inside the contracted floor, not stranded outside it.
	var player: WispPlayer = _player(game)
	# A grown Rect2 would be satisfied by a Wisp standing on painted lava inside the bounding box,
	# so this must test the landing polygon the Wisp is actually confined to.
	if not DashGeometry.is_inside_polygon_slack(
		player.global_position, game.get_landing_polygon(), 4.0
	):
		_fail("the Wisp was left outside the contracted floor at %s" % player.global_position)
	game.queue_free()
	await process_frame


## Killing a splitter must never produce more splitters.
##
## Reproduces a bug found on device: split children were spawned through the Rift roster remap, and
## Ember Hollow maps soul_wisp -> cinder_shade while Cinder Shade splits into soul_wisp. Every death
## therefore spawned two more splitters, the wave never cleared, and the score ran past 900 million.
func _check_split_chain_reaction() -> void:
	var game: GameWorld = await _start(&"ember_hollow")
	# Ember Hollow's own waves legitimately field Cinder Shades, so silence the director first:
	# otherwise director-spawned splitters would be mistaken for split children.
	game.debug_quiet_arena()
	await process_frame
	if game.debug_enemy_layer_count() != 0:
		_fail("the arena did not empty, got %d enemies" % game.debug_enemy_layer_count())

	var centre: Vector2 = game.get_arena_rect().get_center()
	var parent: EnemyActor = game.debug_spawn_enemy(&"cinder_shade", centre)
	if parent == null:
		_fail("could not spawn a cinder shade")
		game.queue_free()
		await process_frame
		return
	var expected_children: int = parent.tuning.split_count
	if expected_children <= 0:
		_fail("the cinder shade under test does not split")

	parent.state = EnemyActor.State.ACTIVE
	parent.try_direct_hit(99, 9001)
	await process_frame
	await process_frame

	var children: Array[EnemyActor] = _live_enemies(game)
	if children.size() != expected_children:
		_fail("splitting produced %d children, expected %d" % [
			children.size(), expected_children,
		])
	for child: EnemyActor in children:
		if child.tuning != null and child.tuning.split_count > 0:
			_fail("a split child is itself a splitter — chain reaction")

	# Kill every generation repeatedly; the population must reach zero, not grow.
	var event: int = 20000
	for _round: int in 8:
		for actor: EnemyActor in _live_enemies(game):
			actor.state = EnemyActor.State.ACTIVE
			event += 1
			actor.try_direct_hit(99, event)
		await process_frame
		await process_frame
	# Count live enemies only: dissolving corpses linger in the layer for their dissolve duration.
	if _live_enemies(game).size() != 0:
		_fail("the split population never died out: %d still live"
			% _live_enemies(game).size())
	game.queue_free()
	await process_frame


## Enemies currently alive in the arena.
func _live_enemies(game: GameWorld) -> Array[EnemyActor]:
	var result: Array[EnemyActor] = []
	for child: Node in game.get_node("WorldContent/EnemyLayer").get_children():
		if child is EnemyActor and (child as EnemyActor).state != EnemyActor.State.DYING:
			result.append(child as EnemyActor)
	return result


## Every dash in every Rift must land on that Rift's painted floor, never past it.
##
## This is the test that proves the polygon is live. A game still running on the bounding
## rectangle would land dashes out in the lava at the corners and fail here.
func _check_polygon_playfield(rift_id: StringName) -> void:
	var game: GameWorld = await _start(rift_id)
	game.debug_quiet_arena()
	var player: WispPlayer = _player(game)
	var floor: PackedVector2Array = game.get_arena_polygon()
	var landing: PackedVector2Array = game.get_landing_polygon()
	if floor.size() < 3 or landing.size() < 3:
		_fail("%s is not running on a polygon floor" % rift_id)
		game.queue_free()
		await process_frame
		return

	# The landing polygon must sit inside the floor, or the inset went the wrong way.
	for point: Vector2 in landing:
		if not DashGeometry.is_inside_polygon_slack(point, floor, 1.0):
			_fail("%s landing polygon pokes outside the floor at %s" % [rift_id, point])
			break

	# The bounding rect must NOT have become the design scale: that would resize the hitbox.
	var rect: Rect2 = game.get_arena_rect()
	var bounds: Rect2 = DashGeometry.polygon_bounds(floor)
	if is_equal_approx(rect.size.x, bounds.size.x):
		_fail("%s arena rect was replaced by the polygon bounds" % rift_id)

	var directions: int = 8
	var landed: int = 0
	for step: int in directions:
		await _wait_until_resting(player)
		if player.state != WispPlayer.State.WAITING_AT_EDGE:
			_fail("%s: Wisp did not come to rest before dash %d" % [rift_id, step])
			break
		var start: Vector2 = player.global_position
		# Resting must itself be on the wall.
		if player.global_position.distance_to(
			DashGeometry.nearest_polygon_point(player.global_position, landing)
		) > 3.0:
			_fail("%s: resting Wisp is not on the wall" % rift_id)
		var aim: Vector2 = Vector2.RIGHT.rotated(TAU * float(step) / float(directions))
		player.request_dash(aim)
		var target: Vector2 = player.get_dash_target()
		if not DashGeometry.is_inside_polygon_slack(target, landing, 3.0):
			_fail("%s: dash %d targets %s, off the landing polygon" % [rift_id, step, target])
		await _wait_until_resting(player)
		if player.global_position.distance_to(start) < 1.0:
			# A reflected aim may legitimately be a no-op only if the swipe was swallowed.
			_fail("%s: dash %d did not move the Wisp" % [rift_id, step])
			continue
		if not DashGeometry.is_inside_polygon_slack(player.global_position, landing, 3.0):
			_fail("%s: dash %d ended off the floor at %s" % [
				rift_id, step, player.global_position,
			])
		else:
			landed += 1
	if landed < directions - 1:
		_fail("%s: only %d of %d dashes landed on the floor" % [rift_id, landed, directions])

	# Enemies placed anywhere must end up on the floor.
	var corner: Vector2 = rect.position + Vector2(rect.size.x * 0.02, rect.size.y * 0.02)
	var enemy: EnemyActor = game.debug_spawn_enemy(&"soul_wisp", corner)
	if enemy != null:
		# Containment runs in the movement step, so the probe enemy must be allowed to move.
		enemy.movement_enabled = true
		enemy.state = EnemyActor.State.ACTIVE
		for _frame: int in 6:
			await physics_frame
		if not DashGeometry.is_inside_polygon_slack(enemy.global_position, floor, 2.0):
			_fail("%s: an enemy stayed off the floor at %s" % [rift_id, enemy.global_position])
	game.queue_free()
	await process_frame


func _wait_until_resting(player: WispPlayer) -> void:
	for _wait: int in 80:
		if player.state == WispPlayer.State.WAITING_AT_EDGE:
			return
		await create_timer(0.03).timeout


func _check_portals() -> void:
	var game: GameWorld = await _start(&"shattered_rift")
	var portals: PackedVector2Array = game.get_portal_positions()
	if portals.size() != 2:
		_fail("shattered rift did not build a portal pair, got %d" % portals.size())
		game.queue_free()
		await process_frame
		return
	var floor: PackedVector2Array = game.get_arena_polygon()
	if floor.size() < 3:
		_fail("shattered rift has no floor polygon")
	for point: Vector2 in portals:
		if not DashGeometry.is_inside_polygon(point, floor):
			_fail("a portal sits off the painted floor at %s" % point)

	# A dash straight through a portal mouth must come out at its pair, still travelling.
	var player: WispPlayer = _player(game)
	player.request_dash((portals[0] - player.global_position).normalized())
	await create_timer(0.12).timeout
	var moved: bool = false
	for _frame: int in 40:
		await process_frame
		if player.global_position.distance_to(portals[1]) < 260.0:
			moved = true
			break
	if not moved:
		_fail("a dash through the entrance portal never arrived at its pair")
	# Baseline Rifts must have no portals at all.
	game.queue_free()
	await process_frame
	var plain: GameWorld = await _start(&"obsidian_garden")
	if plain.get_portal_positions().size() != 0:
		_fail("a non-portal rift built portals")
	plain.queue_free()
	await process_frame


func _check_drift() -> void:
	var game: GameWorld = await _start(&"frozen_choir")
	var player: WispPlayer = _player(game)
	# Silence the waves so a hit cannot interrupt the resting state and quietly skip this check.
	game.debug_quiet_arena()
	for _wait: int in 40:
		if player.state == WispPlayer.State.WAITING_AT_EDGE:
			break
		await create_timer(0.05).timeout
	if player.state != WispPlayer.State.WAITING_AT_EDGE:
		_fail("the Wisp never came to rest, so drift could not be measured (state %d)"
			% player.state)
		game.queue_free()
		await process_frame
		return
	var before: Vector2 = player.global_position
	await create_timer(0.5).timeout
	if player.global_position.distance_to(before) < 1.0:
		_fail("frozen choir did not slide the resting Wisp")
	# Drift must follow the painted wall, not wander into the floor or off it.
	var landing: PackedVector2Array = game.get_landing_polygon()
	var boundary: Vector2 = DashGeometry.nearest_polygon_point(player.global_position, landing)
	if player.global_position.distance_to(boundary) > 3.0:
		_fail("drift left the wall: %.1f px from the landing polygon"
			% player.global_position.distance_to(boundary))
	game.queue_free()
	await process_frame
