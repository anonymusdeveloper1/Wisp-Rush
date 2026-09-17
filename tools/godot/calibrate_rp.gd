extends SceneTree
## Rift Points calibration (not a pass/fail test): scripted bot runs that log score, `rp_collected`
## and `rp_performance`, so `EconomyTuning.score_per_rift_point` can be checked against the
## 35–45 RP median early-run target (GDD §14 #16, docs/systems/shop.md).
##
## Usage:
##   WISP_ISOLATED_SAVE=1 Godot --headless --path . --script res://tools/godot/calibrate_rp.gd
## Runs, in Obsidian Garden level 1 like a new player: the tutorial run (a novice bot finishes the
## lesson, then plays on), three novice runs (aims at a random enemy with a wide aim error and a
## slow rhythm) and three steady runs (picks the line through the most enemies). No bot dodges, so
## these approximate early play only; device play is the real calibration. The game runs at
## TIME_SCALE with hit-stop off (Reduced Motion) so the batch finishes in minutes.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const RIFT_CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const TIME_SCALE: float = 4.0
## Game seconds after which a run that is still alive is ended and reported as capped.
const RUN_CAP_SECONDS: float = 300.0
const DIRECTION_SAMPLES: int = 32

var _summary: Dictionary = {}


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var results: Array[Dictionary] = []
	results.append(await _play(&"tutorial", 101, true))
	for seed_value: int in [211, 223, 227]:
		results.append(await _play(&"novice", seed_value, false))
	for seed_value: int in [307, 311, 313]:
		results.append(await _play(&"steady", seed_value, false))
	for result: Dictionary in results:
		var line: String = "calibrate_rp: %-8s seed=%d | %5.1fs wave=%d score=%d kills=%d"
		line += " | rp_collected=%d rp_performance=%d total=%d%s"
		print(line % [
			result[&"bot"], result[&"seed"], result[&"seconds"], result[&"wave"], result[&"score"],
			result[&"kills"], result[&"rp_collected"], result[&"rp_performance"],
			int(result[&"rp_collected"]) + int(result[&"rp_performance"]),
			"  (capped)" if result[&"capped"] else "",
		])
	Engine.time_scale = 1.0
	quit(0)


func _play(bot: StringName, seed_value: int, _tutorial: bool) -> Dictionary:
	_summary = {}
	Engine.time_scale = 1.0
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = seed_value
	game.auto_pause_on_focus_loss = false
	game.configure_run(RunProfile.story(
		RIFT_CATALOG.get_rift(&"obsidian_garden"), 1, {}, FORM_CATALOG.get_form(&"void")
	))
	game.run_ended.connect(func(summary: Dictionary) -> void: _summary = summary)
	root.add_child(game)
	await process_frame
	# Hit-stop writes Engine.time_scale; Reduced Motion turns it off so the speed-up holds.
	game._reduced_motion = true
	Engine.time_scale = TIME_SCALE
	var random := RandomNumberGenerator.new()
	random.seed = seed_value * 7 + 3
	var player: WispPlayer = game._player
	var upgrade_tray := game.get_node("HUD/UpgradeTray") as UpgradeTray
	var elapsed: float = 0.0
	var rest: float = 0.0
	var last_usec: int = Time.get_ticks_usec()
	while _summary.is_empty() and elapsed < RUN_CAP_SECONDS:
		await process_frame
		var now_usec: int = Time.get_ticks_usec()
		var step: float = float(now_usec - last_usec) / 1000000.0 * Engine.time_scale
		last_usec = now_usec
		elapsed += step
		if upgrade_tray.is_open():
			upgrade_tray.choose_index(random.randi_range(0, 2))
			continue
		if player.state != WispPlayer.State.WAITING_AT_EDGE:
			rest = 0.0
			continue
		rest += step
		var patience: float = random.randf_range(0.6, 1.2) if bot != &"steady" else 0.3
		if rest < patience:
			continue
		rest = 0.0
		var direction: Vector2 = (
			_best_line(game, player) if bot == &"steady" else _novice_aim(game, player, random)
		)
		player.request_dash(direction)
	var capped: bool = _summary.is_empty()
	var summary: Dictionary = _summary.duplicate()
	if capped:
		summary = {
			&"score": game.get_score(), &"wave": game.get_current_wave(),
			&"kills": game.get_total_kills(), &"rp_collected": game.get_rp_collected(),
			&"rp_performance": game.get_rp_performance(),
		}
	Engine.time_scale = 1.0
	game.queue_free()
	await process_frame
	return {
		&"bot": bot, &"seed": seed_value, &"seconds": elapsed, &"capped": capped,
		&"score": int(summary.get(&"score", 0)), &"wave": int(summary.get(&"wave", 1)),
		&"kills": int(summary.get(&"kills", 0)),
		&"rp_collected": int(summary.get(&"rp_collected", 0)),
		&"rp_performance": int(summary.get(&"rp_performance", 0)),
	}


func _active_enemies(game: GameWorld) -> Array[EnemyActor]:
	var enemies: Array[EnemyActor] = []
	for child: Node in game._enemy_layer.get_children():
		if child is EnemyActor and (child as EnemyActor).is_contact_active():
			enemies.append(child as EnemyActor)
	return enemies


## A novice: aims at one random enemy with up to ±25° of error, or anywhere on an empty floor.
func _novice_aim(game: GameWorld, player: WispPlayer, random: RandomNumberGenerator) -> Vector2:
	var enemies: Array[EnemyActor] = _active_enemies(game)
	if enemies.is_empty():
		return Vector2.RIGHT.rotated(random.randf() * TAU)
	var target: EnemyActor = enemies[random.randi_range(0, enemies.size() - 1)]
	var aim: Vector2 = (target.global_position - player.global_position).normalized()
	return aim.rotated(deg_to_rad(random.randf_range(-25.0, 25.0)))


## A steady player: the sampled line whose dash corridor crosses the most active enemies.
func _best_line(game: GameWorld, player: WispPlayer) -> Vector2:
	var enemies: Array[EnemyActor] = _active_enemies(game)
	var best: Vector2 = (game.get_arena_rect().get_center() - player.global_position).normalized()
	var best_hits: int = 0
	for index: int in DIRECTION_SAMPLES:
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(DIRECTION_SAMPLES))
		var resolved: Dictionary = player._resolve_dash(direction)
		var target: Vector2 = resolved[&"target"] as Vector2
		var hits: int = 0
		var reach: float = player.get_collision_radius() * player.get_blade_width_multiplier()
		for enemy: EnemyActor in enemies:
			var gap: float = DashGeometry.distance_to_segment(
				enemy.global_position, player.global_position, target
			)
			if gap <= reach + enemy.get_collision_radius():
				hits += 1
		if hits > best_hits:
			best_hits = hits
			best = resolved[&"direction"] as Vector2
	return best
