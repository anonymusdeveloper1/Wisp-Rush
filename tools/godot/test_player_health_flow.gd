extends SceneTree
## Live-scene check for contact, i-frames, safe reform, death dissolve and the run summary.
##
## The summary GameWorld emits on death must carry `rp_collected` and `rp_performance` (spec 01),
## the performance bonus must come from the scene's wired `EconomyTuning`, and every Trial and
## challenge metric must be a real summary key, so a renamed key or a lost export cannot pay 0.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const SOUL_WISP_SCENE: PackedScene = preload("res://scenes/enemies/soul_wisp.tscn")
## Score and pickups planted before the killing hit, so the summary values are not all zero.
const PLANTED_SCORE: int = 1234
const PLANTED_RP_COLLECTED: int = 7


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = _check_performance_points()
	var summaries: Array[Dictionary] = []
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_ended.connect(func(summary: Dictionary) -> void: summaries.append(summary))
	root.add_child(game)
	await create_timer(0.5).timeout
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	var enemy_layer := game.get_node("WorldContent/EnemyLayer") as Node2D
	for child: Node in enemy_layer.get_children():
		child.queue_free()
	await process_frame
	var enemy := SOUL_WISP_SCENE.instantiate() as SoulWispEnemy
	enemy.movement_enabled = false
	enemy_layer.add_child(enemy)
	enemy.global_position = player.global_position
	enemy.set_viewport_width(root.size.x)
	await create_timer(0.7).timeout
	if player.get_current_health() != 2:
		failures += 1
		push_error("player_health_flow: active enemy contact did not remove one fragment")
	if player.take_contact_damage(player.global_position):
		failures += 1
		push_error("player_health_flow: invulnerability did not reject an immediate second hit")
	await create_timer(1.0).timeout
	if not player.take_contact_damage(player.global_position):
		failures += 1
	await create_timer(1.0).timeout
	game._score = PLANTED_SCORE
	game._rp_collected = PLANTED_RP_COLLECTED
	if not player.take_contact_damage(player.global_position):
		failures += 1
	await create_timer(0.7).timeout
	if player.get_current_health() != 0 or player.state != WispPlayer.State.DEAD:
		failures += 1
		push_error("player_health_flow: third separated hit did not enter DEAD")
	if summaries.size() != 1:
		failures += 1
		push_error("player_health_flow: death dissolve did not emit one run summary")
	else:
		failures += _check_summary(game, summaries[0])
	if failures == 0:
		print("player_health_flow: contact → i-frames → death → summary with Rift Points passed")
	game.queue_free()
	quit(failures)


## The live summary's Rift Points keys and metric names.
func _check_summary(game: GameWorld, summary: Dictionary) -> int:
	var failures: int = 0
	if game.economy_tuning == null:
		failures += 1
		push_error("player_health_flow: game_world.tscn lost its economy_tuning export")
	if not summary.has(&"rp_collected") or not summary.has(&"rp_performance"):
		failures += 1
		push_error("player_health_flow: summary lacks rp_collected / rp_performance: %s" % summary)
		return failures
	if int(summary[&"score"]) != PLANTED_SCORE:
		failures += 1
		push_error("player_health_flow: summary score %s, expected %d" % [
			summary[&"score"], PLANTED_SCORE,
		])
	if int(summary[&"rp_collected"]) != PLANTED_RP_COLLECTED:
		failures += 1
		push_error("player_health_flow: summary rp_collected %s, expected %d" % [
			summary[&"rp_collected"], PLANTED_RP_COLLECTED,
		])
	if game.economy_tuning != null:
		var expected: int = game.economy_tuning.get_performance_points(PLANTED_SCORE)
		if expected <= 0 or int(summary[&"rp_performance"]) != expected:
			failures += 1
			push_error("player_health_flow: summary rp_performance %s, expected %d" % [
				summary[&"rp_performance"], expected,
			])
	var metrics: Array[StringName] = TrialCatalog.VALID_METRICS.duplicate()
	for definition: Dictionary in ChallengeTracker._POOL:
		metrics.append(definition[&"metric"] as StringName)
	for metric: StringName in metrics:
		if not summary.has(metric):
			failures += 1
			push_error("player_health_flow: Trial/challenge metric %s is not a summary key" % metric)
	return failures


## `EconomyTuning.get_performance_points`: floor division, never negative, divisor clamped to 1.
func _check_performance_points() -> int:
	var failures: int = 0
	var tuning := EconomyTuning.new()
	tuning.score_per_rift_point = 200
	var cases: Dictionary[int, int] = {0: 0, -5: 0, 199: 0, 200: 1, 399: 1, 400: 2, 401: 2}
	for score: int in cases:
		if tuning.get_performance_points(score) != cases[score]:
			failures += 1
			push_error("player_health_flow: get_performance_points(%d) = %d at 200, expected %d" % [
				score, tuning.get_performance_points(score), cases[score],
			])
	tuning.score_per_rift_point = 0
	if tuning.get_performance_points(50) != 50:
		failures += 1
		push_error("player_health_flow: a zero score_per_rift_point was not clamped to 1")
	return failures
