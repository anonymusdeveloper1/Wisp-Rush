extends SceneTree
## Wall splash: plays on impact, sits on the wall, sprays into the floor, and nothing highlights the wall.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORMS: FormCatalog = preload("res://data/forms/default_catalog.tres")

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("wall_splash: %s" % message)


func _run() -> void:
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 3
	game.auto_pause_on_focus_loss = false
	game.configure_run_profile(FORMS.get_form(&"void"), "", RIFTS.get_rift(&"ember_hollow"), 1)
	root.add_child(game)
	await create_timer(0.6).timeout
	game.debug_quiet_arena()

	var splash: WallSplashFx = game.get_wall_splash_fx()
	var player := game.get_node("WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	var floor: PackedVector2Array = game.get_arena_polygon()
	if splash == null:
		_fail("the game has no wall splash effect")
		quit(_failures)
		return

	# Owner request: no wall highlight of any kind. The old rectangle flash node must be gone, and
	# the splash must not draw lines along the wall.
	if game.get_node_or_null("WallFlash") != null:
		_fail("the old WallFlash highlight node still exists")
	for child: Node in splash.get_children():
		if child is Line2D:
			_fail("the splash draws a line along the wall")
			break
	if splash.get_emitters().size() != WallSplashFx.EMITTER_POOL_SIZE:
		_fail("expected %d pooled emitters, found %d" % [
			WallSplashFx.EMITTER_POOL_SIZE, splash.get_emitters().size(),
		])

	for _wait: int in 60:
		if player.state == WispPlayer.State.WAITING_AT_EDGE:
			break
		await create_timer(0.03).timeout
	var before: Array[bool] = []
	for emitter: CPUParticles2D in splash.get_emitters():
		before.append(emitter.emitting)
	player.request_dash(Vector2(0.55, -1.0))

	var fired: CPUParticles2D = null
	for _wait: int in 80:
		await create_timer(0.02).timeout
		for emitter: CPUParticles2D in splash.get_emitters():
			if emitter.emitting:
				fired = emitter
		if fired != null:
			break
	if fired == null:
		_fail("hitting the wall did not play a splash")
	else:
		var origin: Vector2 = splash.get_last_origin()
		# The splash sits on the wall surface, closer to the wall than the Wisp's own centre.
		if floor.size() >= 3:
			var wall_gap: float = origin.distance_to(
				DashGeometry.nearest_polygon_point(origin, floor)
			)
			var wisp_gap: float = player.global_position.distance_to(
				DashGeometry.nearest_polygon_point(player.global_position, floor)
			)
			if wall_gap >= wisp_gap:
				_fail("the splash is not pushed onto the wall (%.1f px vs Wisp %.1f px)"
					% [wall_gap, wisp_gap])
			# Droplets must spray back into the floor, never through the wall.
			var into_floor: Vector2 = (DashGeometry.polygon_centroid(floor) - origin).normalized()
			if fired.direction.dot(into_floor) <= 0.0:
				_fail("droplets spray out through the wall")

	# Reduced Motion must produce a smaller splash than the full one.
	var full: int = _amount_for(splash, false)
	var calm: int = _amount_for(splash, true)
	if calm >= full:
		_fail("Reduced Motion did not shrink the splash (%d vs %d droplets)" % [calm, full])

	if splash.play(Vector2.ZERO, Vector2.ZERO, 1.0, Color.WHITE, 1080.0, false):
		_fail("a splash played with no wall normal")

	if _failures == 0:
		print("wall_splash: plays on impact, on the wall, into the floor, no wall highlight")
	game.queue_free()
	await process_frame
	quit(_failures)


## Droplet count a splash would emit, read back from the emitter it just used.
func _amount_for(splash: WallSplashFx, reduced_motion: bool) -> int:
	splash.play(Vector2(500, 500), Vector2.UP, 1.0, Color.WHITE, 1080.0, reduced_motion, 20.0)
	var newest: CPUParticles2D = null
	for emitter: CPUParticles2D in splash.get_emitters():
		if emitter.global_position.is_equal_approx(splash.get_last_origin()):
			newest = emitter
	return newest.amount if newest != null else -1
