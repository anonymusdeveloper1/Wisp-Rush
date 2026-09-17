extends RefCounted
## Devlog capture bot: plays a live GameWorld like a steady player so MovieWriter can record it.
##
## Shared by `render_gameplay_clip.gd` (a bare run) and `render_devlog_tour.gd` (the real Main flow);
## the host calls [method step] once per frame. The bot aims at the line through the most enemies and
## holds the aim arrow (lit targets, ×N) before multi-kills, redirects mid-dash when a clearly better
## line opens, looks at upgrade cards before picking one, and with `survive` refills Soul Fragments
## after hits so a run keeps going. Tooling only; it reads GameWorld/WispPlayer internals on purpose.
##
## Options (strings, as parsed from `key=value` command-line arguments):
##   hold=<seconds the aim arrow shows before a multi-kill dash>  redirects=0|1  survive=0|1
##   boss_at=<seconds after the bot starts to call a boss, 0 = normal cadence>  boss_health=<hits>
##   dash_speed=<px/s override for before/after shots; the player's tuning is duplicated, never saved>

## Emitted for moments worth cutting to: multi_kill, redirect, rush_started, boss_start,
## boss_defeated, hit, upgrade, run_ended.
signal event_logged(event: StringName, fields: Dictionary)

## Directions sampled when the bot looks for the line through the most enemies.
const DIRECTION_SAMPLES: int = 90
## Drag length handed to the swipe API: well past the minimum swipe distance.
const DRAG_LENGTH: float = 240.0
## Aim arrow time for a line with fewer than MULTI_KILL_HITS enemies (game seconds).
const QUICK_HOLD_SECONDS: float = 0.06
const MULTI_KILL_HITS: int = 3
## Game seconds between landing and the next decision, like a quick human rhythm.
const REACTION_MIN_SECONDS: float = 0.04
const REACTION_MAX_SECONDS: float = 0.14
## With no enemy on the field the bot waits this long before repositioning (game seconds).
const IDLE_REPOSITION_SECONDS: float = 1.2
## A redirect needs this much dash progress and this gap since the last redirect (game seconds).
const REDIRECT_MIN_DASH_AGE: float = 0.08
const REDIRECT_COOLDOWN_SECONDS: float = 1.0
## Movie seconds the upgrade cards stay on screen before the bot picks one.
const UPGRADE_LOOK_SECONDS: float = 1.1
## Game seconds before Soul Fragments refill after a non-critical hit (the tutorial uses 0.6 s).
const HEAL_DELAY_SECONDS: float = 0.6

var game: GameWorld
var player: WispPlayer
## When false, [method step] does nothing (the host pauses the bot).
var enabled: bool = true
## Movie seconds of the run end, or -1 while the run is live.
var run_ended_at: float = -1.0

var _options: Dictionary = {}
var _fps: float = 60.0
var _random := RandomNumberGenerator.new()
var _tray: UpgradeTray
var _started_at: float = -1.0
var _boss_called: bool = false
var _hold_seconds: float = 0.34
var _redirects: bool = true
var _decide_in: float = 0.0
var _aim_left: float = -1.0
var _aim_direction := Vector2.ZERO
var _idle_time: float = 0.0
var _upgrade_time: float = 0.0
var _heal_in: float = -1.0
var _dash_age: float = 0.0
var _last_redirect_game_time: float = -INF
var _game_time: float = 0.0
var _boss_seen: bool = false
var _movie_now: float = 0.0


## [param target] must be in the tree and ready. [param fps] is the movie frame rate.
func _init(target: GameWorld, options: Dictionary, fps: float, seed_value: int) -> void:
	game = target
	player = target._player
	_options = options
	_fps = maxf(fps, 1.0)
	_random.seed = seed_value * 13 + 5
	_tray = target.get_node("HUD/UpgradeTray") as UpgradeTray
	_hold_seconds = option_float(options, "hold", 0.34)
	_redirects = option_bool(options, "redirects", true)
	_boss_called = option_float(options, "boss_at", 0.0) <= 0.0
	if options.has("dash_speed"):
		player.tuning = player.tuning.duplicate() as PlayerTuning
		player.tuning.dash_speed = option_float(options, "dash_speed", player.tuning.dash_speed)
	game.dash_resolved.connect(_on_dash_resolved)
	game.player_damaged.connect(_on_player_damaged)
	game.rush_started.connect(func() -> void: event_logged.emit(&"rush_started", {}))
	game.boss_defeated.connect(func() -> void: event_logged.emit(&"boss_defeated", {}))
	game.upgrade_chosen.connect(
		func(mutation_id: StringName) -> void: event_logged.emit(&"upgrade", {"mutation": mutation_id})
	)
	game.run_ended.connect(_on_run_ended)
	player.dash_started.connect(func(_direction: Vector2, _dash_id: int) -> void: _dash_age = 0.0)


## One frame of play at movie time [param movie_seconds].
func step(movie_seconds: float) -> void:
	_movie_now = movie_seconds
	if not enabled or not is_instance_valid(game) or run_ended_at >= 0.0:
		return
	if not game.is_inside_tree() or not game.can_process():
		return
	if _started_at < 0.0:
		_started_at = movie_seconds
	if _tray.is_open():
		_upgrade_time += 1.0 / _fps
		_aim_left = -1.0
		if _upgrade_time >= UPGRADE_LOOK_SECONDS:
			_tray.choose_index(_random.randi_range(0, 2))
			_upgrade_time = 0.0
		return
	_upgrade_time = 0.0
	if game.get_tree().paused:
		return

	var step_seconds: float = Engine.time_scale / _fps
	_game_time += step_seconds
	_dash_age += step_seconds
	_track_boss()
	if not _boss_called and movie_seconds - _started_at >= option_float(_options, "boss_at", 0.0):
		_boss_called = true
		game.start_scripted_boss(option_int(_options, "boss_health", 0))
	if _heal_in >= 0.0:
		_heal_in -= step_seconds
		if _heal_in < 0.0:
			_refill_health()

	match player.state:
		WispPlayer.State.WAITING_AT_EDGE, WispPlayer.State.WALL_IMPACT, WispPlayer.State.AIMING:
			_act_at_rest(step_seconds)
		WispPlayer.State.DASHING:
			_aim_left = -1.0
			if _redirects:
				_try_redirect()
		_:
			_aim_left = -1.0


func _act_at_rest(step_seconds: float) -> void:
	if _aim_left < 0.0:
		_decide_in -= step_seconds
		if _decide_in > 0.0:
			return
		var choice: Dictionary = _choose_line()
		if int(choice[&"hits"]) == 0 and not _boss_core_open():
			_idle_time += step_seconds
			if _idle_time < IDLE_REPOSITION_SECONDS:
				return
		_idle_time = 0.0
		_aim_direction = choice[&"direction"] as Vector2
		var multi: bool = int(choice[&"hits"]) >= MULTI_KILL_HITS
		_aim_left = _hold_seconds if multi else QUICK_HOLD_SECONDS
		player.preview_aim(_aim_direction * DRAG_LENGTH)
		return
	_aim_left -= step_seconds
	var tracked: Dictionary = _choose_line()
	if int(tracked[&"hits"]) > 0:
		_aim_direction = tracked[&"direction"] as Vector2
	player.preview_aim(_aim_direction * DRAG_LENGTH)
	if _aim_left <= 0.0:
		player.perform_swipe(_aim_direction * DRAG_LENGTH)
		_aim_left = -1.0
		_decide_in = _random.randf_range(REACTION_MIN_SECONDS, REACTION_MAX_SECONDS)


## The resolved dash direction whose corridor crosses the most active enemies right now; with no
## such line, the exposed boss core, else a drift toward the arena centre.
func _choose_line() -> Dictionary:
	var origin: Vector2 = player.global_position
	var best: Dictionary = _best_line_from(origin)
	if int(best[&"hits"]) >= 2 or not _boss_core_open():
		if int(best[&"hits"]) == 0:
			var centre: Vector2 = game.get_arena_rect().get_center()
			var drift: Vector2 = (centre - origin).normalized().rotated(_random.randf_range(-0.6, 0.6))
			best[&"direction"] = player._resolve_dash(drift)[&"direction"] as Vector2
		return best
	var to_boss: Vector2 = game._boss.global_position - origin
	best[&"direction"] = player._resolve_dash(to_boss)[&"direction"] as Vector2
	return best


func _best_line_from(origin: Vector2) -> Dictionary:
	var enemies: Array[EnemyActor] = _active_enemies()
	var corridor: float = player.get_dash_corridor_radius()
	var best_hits: int = 0
	var best_direction := Vector2.ZERO
	if enemies.is_empty():
		return {&"direction": best_direction, &"hits": 0}
	for index: int in DIRECTION_SAMPLES:
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(DIRECTION_SAMPLES))
		var resolved: Dictionary = player._resolve_dash(direction)
		var target: Vector2 = resolved[&"target"] as Vector2
		if origin.distance_squared_to(target) <= 1.0:
			continue
		var hits: int = 0
		for enemy: EnemyActor in enemies:
			if enemy.would_dash_hit(origin, target, corridor):
				hits += 1
		if hits > best_hits:
			best_hits = hits
			best_direction = resolved[&"direction"] as Vector2
	return {&"direction": best_direction, &"hits": best_hits}


## Redirects a live dash when a line from here slices at least two more enemies than the rest of
## the current dash would, at most once per REDIRECT_COOLDOWN_SECONDS.
func _try_redirect() -> void:
	if _dash_age < REDIRECT_MIN_DASH_AGE:
		return
	if _game_time - _last_redirect_game_time < REDIRECT_COOLDOWN_SECONDS:
		return
	var origin: Vector2 = player.global_position
	var corridor: float = player.get_dash_corridor_radius()
	var remaining: int = 0
	for enemy: EnemyActor in _active_enemies():
		if enemy.would_dash_hit(origin, player._dash_target, corridor):
			remaining += 1
	var best: Dictionary = _best_line_from(origin)
	if int(best[&"hits"]) >= 2 and int(best[&"hits"]) >= remaining + 2:
		player.perform_swipe((best[&"direction"] as Vector2) * DRAG_LENGTH)
		_last_redirect_game_time = _game_time
		event_logged.emit(&"redirect", {"hits": int(best[&"hits"])})


func _active_enemies() -> Array[EnemyActor]:
	var enemies: Array[EnemyActor] = []
	for child: Node in game._enemy_layer.get_children():
		if child is EnemyActor and (child as EnemyActor).is_contact_active():
			enemies.append(child as EnemyActor)
	return enemies


func _boss_core_open() -> bool:
	return is_instance_valid(game._boss) and game.is_boss_core_exposed()


func _track_boss() -> void:
	var present: bool = is_instance_valid(game._boss)
	if present and not _boss_seen:
		event_logged.emit(&"boss_start", {})
	_boss_seen = present


func _refill_health() -> void:
	var missing: int = player.get_maximum_health() - player.get_current_health()
	if missing > 0 and player.get_current_health() > 0:
		player.heal(missing)


func _on_dash_resolved(kills: int, ended_by: StringName) -> void:
	if kills >= 2:
		event_logged.emit(&"multi_kill", {"kills": kills, "ended_by": ended_by})


func _on_player_damaged(current_health: int) -> void:
	event_logged.emit(&"hit", {"health": current_health})
	if not option_bool(_options, "survive", true):
		return
	if current_health <= 1:
		_refill_health()
	else:
		_heal_in = HEAL_DELAY_SECONDS


func _on_run_ended(summary: Dictionary) -> void:
	run_ended_at = _movie_now
	event_logged.emit(&"run_ended", {
		"score": int(summary.get(&"score", 0)), "wave": int(summary.get(&"wave", 0)),
	})


## `key=value` command-line arguments as a Dictionary of strings.
static func parse_options(args: PackedStringArray) -> Dictionary:
	var options: Dictionary = {}
	for argument: String in args:
		var separator: int = argument.find("=")
		if separator > 0:
			options[argument.substr(0, separator)] = argument.substr(separator + 1)
	return options


static func option_float(options: Dictionary, key: String, fallback: float) -> float:
	return float(str(options[key])) if options.has(key) else fallback


static func option_int(options: Dictionary, key: String, fallback: int) -> int:
	return int(str(options[key])) if options.has(key) else fallback


static func option_bool(options: Dictionary, key: String, fallback: bool) -> bool:
	if not options.has(key):
		return fallback
	return not (str(options[key]) in ["0", "false", "no"])
