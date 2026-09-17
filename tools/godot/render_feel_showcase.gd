extends SceneTree
## Devlog footage: scripted "feel" shots in a quiet tutorial arena, recorded by MovieWriter.
##
## Shots (default order below). The Wisp rests on the left wall and dashes across, so a line of
## enemies runs through the middle of the frame and the top and bottom stay free for titles:
## - `rings`: the aim arrow sweeps onto a line of enemies, so the rings light one by one with the ×N count.
## - `assist`: one off-line drag, first with AIM ASSIST off, then on (the arrow bends to more hits).
## - `finisher`: a long line (`finisher_kills`, default 8) sliced in one dash; slow motion at the fifth kill.
## - `five`: exactly five enemies on a diagonal, so the slow motion lands on the last kill.
## - `rush`: an almost full meter, then the devlog bot keeps slicing spawned clusters while RUSH runs.
##
## Usage (repo root; a real window, not headless):
##   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 \
##     --write-movie "$PWD/video/footage/feel_showcase.avi" \
##     --script res://tools/godot/render_feel_showcase.gd -- skin=world_tree_crown \
##     events="$PWD/video/footage/feel_showcase.events.jsonl"
## Options: `shots=` (comma list, default every shot above), `skin=` (Endless skin id, default
## world_tree_crown), `kind=` (enemy kind, default soul_wisp), `finisher_kills=` (default 8),
## `rush_seconds=` (movie seconds after RUSH starts, default 7), `quality=` (MJPEG, default 0.85),
## `events=` (JSON-lines log). The log marks `shot_start` / `shot_end` per shot (with the Wisp's
## viewport position), `sweep_start`, `lit`, `assist_off`, `assist_on`, `release`, `kill` (its `index`
## in the dash and the enemy's viewport position), `multi_kill` and `rush_started`, all in movie
## seconds: cut on those. Tooling only; it drives WispPlayer and GameWorld internals on purpose.

const DevlogBot = preload("res://tools/godot/devlog_bot.gd")
const Clip = preload("res://tools/godot/render_gameplay_clip.gd")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const FPS: float = 60.0
const DRAG_LENGTH: float = 240.0
const ALL_SHOTS: PackedStringArray = ["rings", "assist", "finisher", "five", "rush"]
## Where the Wisp rests (arena uv, snapped to the nearest wall): the left wall, a little above centre.
const LEFT_WALL := Vector2(0.0, 0.46)
## Real milliseconds to wait at most for audio synthesis before starting anyway.
const AUDIO_WAIT_MSEC: int = 8000
## Movie seconds to wait at most for spawned enemies to become hittable.
const SPAWN_WAIT_SECONDS: float = 3.0

var _options: Dictionary = {}
var _events: FileAccess
var _game: GameWorld
var _player: WispPlayer
var _bot: DevlogBot
var _kind: StringName = &"soul_wisp"
var _random := RandomNumberGenerator.new()


func _init() -> void:
	_options = DevlogBot.parse_options(OS.get_cmdline_user_args())
	ProjectSettings.set_setting(
		"editor/movie_writer/mjpeg_quality",
		clampf(DevlogBot.option_float(_options, "quality", 0.85), 0.1, 1.0),
	)
	call_deferred(&"_run")


func _run() -> void:
	_events = Clip.open_event_log(str(_options.get("events", "")))
	_kind = StringName(str(_options.get("kind", "soul_wisp")))
	_random.seed = 29
	var audio: AudioService = SoundFx.audio()
	var wait_started: int = Time.get_ticks_msec()
	while audio != null and not audio.is_ready():
		if Time.get_ticks_msec() - wait_started > AUDIO_WAIT_MSEC:
			push_warning("render_feel_showcase: audio not ready after 8 s; recording without it")
			break
		await process_frame
	if audio != null:
		audio.start_music()

	var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(
		StringName(str(_options.get("skin", "world_tree_crown")))
	)
	_game = GAME_WORLD_SCENE.instantiate() as GameWorld
	_game.run_seed = 29
	_game.auto_pause_on_focus_loss = false
	_game.configure_run(RunProfile.tutorial(ENDLESS_CATALOG, skin, FORM_CATALOG.get_form(&"void")))
	root.add_child(_game)
	_player = _game._player
	_game.set_experience_enabled(false)
	_game.set_rush_enabled(false)
	_game.enemy_defeated.connect(
		func(world_position: Vector2, dash_kill_index: int) -> void:
			_log(&"kill", {
				"index": dash_kill_index,
				"x": snappedf(world_position.x, 0.1), "y": snappedf(world_position.y, 0.1),
			})
	)
	await _wait(0.6)

	var shots: PackedStringArray = str(_options.get("shots", ",".join(ALL_SHOTS))).split(",", false)
	for shot: String in shots:
		match shot.strip_edges():
			"rings":
				await _shot_rings()
			"assist":
				await _shot_assist()
			"finisher":
				await _shot_finisher()
			"five":
				await _shot_five()
			"rush":
				await _shot_rush()
			_:
				push_warning("render_feel_showcase: unknown shot %s" % shot)
	print("[feel] done | movie_seconds=%.2f" % _now())
	if _events != null:
		_events.close()
	Engine.time_scale = 1.0
	quit(0)


## Arrow sweeps from 24° off onto a line of three enemies, holds on ×3, then slices them.
func _shot_rings() -> void:
	var direction: Vector2 = await _reset_with_line(
		Vector2.RIGHT.rotated(deg_to_rad(4.0)), [0.3, 0.52, 0.74]
	)
	_log_shot_start("rings")
	await _hold_aim(direction.rotated(deg_to_rad(-24.0)), 0.5)
	_log(&"sweep_start")
	var sweep_frames: int = int(1.3 * FPS)
	var last_lit: int = -1
	for frame: int in sweep_frames:
		var t: float = float(frame + 1) / float(sweep_frames)
		var eased: float = 1.0 - pow(1.0 - t, 2.0)
		var aim: Vector2 = direction.rotated(deg_to_rad(-24.0 * (1.0 - eased)))
		_player.preview_aim(aim * DRAG_LENGTH)
		var lit: int = _hits_along(_player.get_assisted_direction(aim))
		if lit != last_lit:
			_log(&"lit", {"count": lit})
			last_lit = lit
		await process_frame
	await _hold_aim(direction, 0.9)
	await _release(direction, 1.4)
	_log(&"shot_end", {"shot": "rings"})


## The same off-line drag twice: AIM ASSIST off (fewer lit), then on (the arrow bends to all three).
func _shot_assist() -> void:
	var direction := Vector2.RIGHT.rotated(deg_to_rad(-5.0))
	var layouts: Array = [[0.34, 0.58, 0.82], [0.4, 0.64, 0.88], [0.28, 0.5, 0.72]]
	var picked_offset: float = 0.0
	for layout: Array in layouts:
		direction = await _reset_with_line(Vector2.RIGHT.rotated(deg_to_rad(-5.0)), layout)
		picked_offset = _find_assist_offset(direction)
		if picked_offset != 0.0:
			break
	if picked_offset == 0.0:
		push_warning("render_feel_showcase: no drag where the assist adds hits; using 8°")
		picked_offset = 8.0
	var drag: Vector2 = direction.rotated(deg_to_rad(picked_offset))
	_log_shot_start("assist", {"offset_degrees": picked_offset})
	_player.set_aim_assist_enabled(false)
	_log(&"assist_off", {"lit": _hits_along(drag)})
	await _hold_aim(drag, 1.8)
	_player.set_aim_assist_enabled(true)
	_log(&"assist_on", {"lit": _hits_along(_player.get_assisted_direction(drag))})
	await _hold_aim(drag, 1.8)
	await _release(drag, 1.4)
	_log(&"shot_end", {"shot": "assist"})


## A long line sliced in one dash; the finisher slows time at the fifth kill.
func _shot_finisher() -> void:
	var kills: int = clampi(DevlogBot.option_int(_options, "finisher_kills", 8), 5, 10)
	var direction: Vector2 = await _reset_with_line(
		Vector2.RIGHT.rotated(deg_to_rad(-3.0)), _spread(kills, 0.16, 0.9)
	)
	_log_shot_start("finisher", {"enemies": kills})
	await _hold_aim(direction, 1.1)
	await _release(direction, 2.6)
	_log(&"shot_end", {"shot": "finisher"})


## Exactly five enemies on a down-right diagonal: the finisher's slow motion lands on the last kill.
func _shot_five() -> void:
	var direction: Vector2 = await _reset_with_line(
		Vector2.RIGHT.rotated(deg_to_rad(24.0)), _spread(5, 0.2, 0.84), Vector2(0.0, 0.24)
	)
	_log_shot_start("five", {"enemies": 5})
	await _hold_aim(direction, 1.0)
	await _release(direction, 2.4)
	_log(&"shot_end", {"shot": "five"})


## RUSH from an almost full meter: one slice fills it, then the bot keeps playing on spawned clusters.
func _shot_rush() -> void:
	var direction: Vector2 = await _reset_with_line(Vector2.RIGHT.rotated(deg_to_rad(-6.0)), [0.35, 0.6])
	_game.set_rush_enabled(true)
	_game.set_rush_meter(_game.feel_tuning.meter_max - 1.0)
	_log_shot_start("rush")
	_bot = DevlogBot.new(_game, {"hold": "0.22", "redirects": "1", "survive": "1"}, FPS, 29)
	_bot.event_logged.connect(_log)
	await _hold_aim(direction, 0.6)
	_log(&"release")
	_player.perform_swipe(direction * DRAG_LENGTH)
	var rush_seen_at: float = -1.0
	var until: float = _now() + 12.0
	while _now() < until:
		await process_frame
		if rush_seen_at < 0.0 and _game.is_rush_active():
			rush_seen_at = _now()
			until = rush_seen_at + DevlogBot.option_float(_options, "rush_seconds", 7.0)
		if _game.debug_live_enemy_count() <= 1 and _player.state != WispPlayer.State.DASHING:
			_spawn_cluster()
		_bot.step(_now())
	_log(&"shot_end", {"shot": "rush", "rush_count": _game.get_rush_count()})


## Clears the arena, parks the Wisp on the wall nearest [param wall_uv] and spawns enemies at
## [param fractions] of the way along [param wish]'s resolved dash; returns that resolved direction once
## they are hittable.
func _reset_with_line(wish: Vector2, fractions: Array, wall_uv: Vector2 = LEFT_WALL) -> Vector2:
	_player.cancel_active_aim()
	_game.clear_scripted_arena()
	while not _player.place_at_edge(_game.arena_to_world(wall_uv)):
		await process_frame
	await _wait(0.25)
	var resolved: Dictionary = _player._resolve_dash(wish)
	var target: Vector2 = resolved[&"target"] as Vector2
	var origin: Vector2 = _player.global_position
	for fraction: Variant in fractions:
		_game.debug_spawn_enemy(_kind, origin.lerp(target, float(fraction)))
	await _wait_until_hittable(fractions.size())
	return resolved[&"direction"] as Vector2


## [param count] fractions from [param from] to [param to], evenly spaced.
func _spread(count: int, from: float, to: float) -> Array:
	var fractions: Array = []
	for index: int in count:
		fractions.append(lerpf(from, to, float(index) / float(maxi(count - 1, 1))))
	return fractions


func _spawn_cluster() -> void:
	var origin: Vector2 = _player.global_position
	var wish := Vector2.RIGHT.rotated(_random.randf_range(-0.7, 0.7))
	if origin.x > _game.get_arena_rect().get_center().x:
		wish = -wish
	var target: Vector2 = _player._resolve_dash(wish)[&"target"] as Vector2
	var count: int = _random.randi_range(3, 4)
	for index: int in count:
		_game.debug_spawn_enemy(_kind, origin.lerp(target, lerpf(0.3, 0.8, float(index) / float(count - 1))))


func _wait_until_hittable(count: int) -> void:
	var until: float = _now() + SPAWN_WAIT_SECONDS
	while _now() < until:
		var active: int = 0
		for child: Node in _game._enemy_layer.get_children():
			if child is EnemyActor and (child as EnemyActor).is_contact_active():
				active += 1
		if active >= count:
			return
		await process_frame
	push_warning("render_feel_showcase: enemies not all active after %.1f s" % SPAWN_WAIT_SECONDS)


## Smallest drag offset (degrees, either side, 3°–14°) where the raw drag misses at least one enemy
## the assisted dash slices; 0 when none does.
func _find_assist_offset(direction: Vector2) -> float:
	for step: int in range(3, 15):
		for sign_value: float in [1.0, -1.0]:
			var degrees: float = float(step) * sign_value
			var drag: Vector2 = direction.rotated(deg_to_rad(degrees))
			var raw: int = _hits_along(drag)
			var assisted: int = _hits_along(_player.get_assisted_direction(drag))
			if assisted > raw and raw >= 1:
				return degrees
	return 0.0


## Enemies a dash in [param direction] from the Wisp would slice right now.
func _hits_along(direction: Vector2) -> int:
	var origin: Vector2 = _player.global_position
	var target: Vector2 = _player._resolve_dash(direction)[&"target"] as Vector2
	var corridor: float = _player.get_dash_corridor_radius()
	var hits: int = 0
	for child: Node in _game._enemy_layer.get_children():
		if child is EnemyActor and (child as EnemyActor).would_dash_hit(origin, target, corridor):
			hits += 1
	return hits


func _hold_aim(direction: Vector2, seconds: float) -> void:
	var until: float = _now() + seconds
	while _now() < until:
		_player.preview_aim(direction * DRAG_LENGTH)
		await process_frame


func _release(direction: Vector2, tail_seconds: float) -> void:
	_log(&"release")
	var kills_before: int = _game.get_total_kills()
	_player.perform_swipe(direction * DRAG_LENGTH)
	await _wait(tail_seconds)
	_log(&"multi_kill", {"kills": _game.get_total_kills() - kills_before})


func _wait(seconds: float) -> void:
	var until: float = _now() + seconds
	while _now() < until:
		await process_frame


func _log_shot_start(shot: String, fields: Dictionary = {}) -> void:
	fields["shot"] = shot
	fields["wisp_x"] = snappedf(_player.global_position.x, 0.1)
	fields["wisp_y"] = snappedf(_player.global_position.y, 0.1)
	_log(&"shot_start", fields)


func _log(event: StringName, fields: Dictionary = {}) -> void:
	Clip.write_event(_events, event, fields, _now(), 0.0)


func _now() -> float:
	return Clip.movie_seconds(FPS)
