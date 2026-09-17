extends SceneTree
## Devlog footage: a bot plays a real Wisp Rush run while MovieWriter records the video and game audio.
##
## Usage (from the repo root; every option after `--` is optional):
##   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 \
##     --write-movie "$PWD/video/footage/endless_s7.avi" \
##     --script res://tools/godot/render_gameplay_clip.gd -- mode=endless seconds=45 seed=7
## A 540×960 window records 1080×1920 on a Retina Mac. MovieWriter runs at a fixed 60 FPS (for true
## slow-motion material add `--fixed-fps 120` and `fps=120`). The .avi holds MJPEG video plus PCM
## game audio; Palmier Pro only imports mp4/mov, so transcode it first (tools/video/README.md).
##
## Options:
##   mode=endless|story  rift=<rift id> level=<1-8> (story)  skin=<arena skin id> (endless)
##   seed=<int>  form=<form id>  dash_style=<style id>  seconds=<clip length after the run starts>
##   fps=<movie fps, must match --fixed-fps>  quality=<MJPEG quality 0-1, default 0.9>
##   rush=<starting RUSH meter>  events=<event log path, default: the movie path with .events.jsonl>
##   plus the bot's options (tools/godot/devlog_bot.gd): hold, redirects, survive, boss_at,
##   boss_health, dash_speed
## The run starts once synthesized audio is ready, so the movie opens with loading frames. The
## event log (JSON lines, `t` = movie seconds) marks run_start, multi-kills, redirects, RUSH, boss
## starts and defeats, hits and upgrades: trim to run_start and cut to the marked moments.
## Captures use the isolated save (WISP_ISOLATED_SAVE=1), never the owner's real one.

const DevlogBot = preload("res://tools/godot/devlog_bot.gd")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const RIFT_CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const DASH_STYLE_CATALOG: DashStyleCatalog = preload(
	"res://data/dash_styles/default_dash_style_catalog.tres"
)
## Real milliseconds to wait at most for audio synthesis before starting anyway.
const AUDIO_WAIT_MSEC: int = 8000
## Movie seconds kept after the run ends (death dissolve or victory beat).
const END_TAIL_SECONDS: float = 1.6

var _options: Dictionary = {}
var _fps: float = 60.0
var _game: GameWorld
var _bot: DevlogBot
var _events: FileAccess
var _run_start: float = 0.0


func _init() -> void:
	_options = DevlogBot.parse_options(OS.get_cmdline_user_args())
	# MovieWriter reads its JPEG quality when recording begins, which is after the main loop exists.
	ProjectSettings.set_setting(
		"editor/movie_writer/mjpeg_quality",
		clampf(DevlogBot.option_float(_options, "quality", 0.9), 0.1, 1.0),
	)
	call_deferred(&"_run")


func _run() -> void:
	_fps = maxf(DevlogBot.option_float(_options, "fps", 60.0), 1.0)
	_events = open_event_log(str(_options.get("events", "")))

	var audio: AudioService = SoundFx.audio()
	var wait_started: int = Time.get_ticks_msec()
	while audio != null and not audio.is_ready():
		if Time.get_ticks_msec() - wait_started > AUDIO_WAIT_MSEC:
			push_warning("render_gameplay_clip: audio not ready after 8 s; recording without it")
			break
		await process_frame
	if audio != null:
		audio.start_music()

	var seed_value: int = DevlogBot.option_int(_options, "seed", 7)
	_game = GAME_WORLD_SCENE.instantiate() as GameWorld
	_game.run_seed = seed_value
	_game.auto_pause_on_focus_loss = false
	_game.configure_run(_build_profile())
	root.add_child(_game)
	await process_frame
	_bot = DevlogBot.new(_game, _options, _fps, seed_value)
	_bot.event_logged.connect(_log_event)
	if _options.has("rush"):
		_game.set_rush_meter(DevlogBot.option_float(_options, "rush", 0.0))

	_run_start = movie_seconds(_fps)
	_log_event(&"run_start", {"mode": str(_options.get("mode", "endless")), "seed": seed_value})
	print("[capture] run_start=%.3f" % _run_start)
	var clip_seconds: float = DevlogBot.option_float(_options, "seconds", 40.0)
	while true:
		await process_frame
		var now: float = movie_seconds(_fps)
		if now - _run_start >= clip_seconds:
			break
		if _bot.run_ended_at >= 0.0 and now - _bot.run_ended_at >= END_TAIL_SECONDS:
			break
		_bot.step(now)

	_log_event(&"capture_end", {"score": _game.get_score(), "wave": _game.get_current_wave()})
	print("[capture] done | movie_seconds=%.2f score=%d wave=%d kills=%d" % [
		movie_seconds(_fps), _game.get_score(), _game.get_current_wave(), _game.get_total_kills()
	])
	if _events != null:
		_events.close()
	Engine.time_scale = 1.0
	quit(0)


## The profile a Home PLAY (Endless) or a Rift Map ENTER (story level) would build.
func _build_profile() -> RunProfile:
	var form: FormData = FORM_CATALOG.get_form(StringName(str(_options.get("form", "void"))))
	var profile: RunProfile
	if str(_options.get("mode", "endless")) == "story":
		var rift: RiftData = RIFT_CATALOG.get_rift(
			StringName(str(_options.get("rift", "obsidian_garden")))
		)
		profile = RunProfile.story(
			rift, clampi(DevlogBot.option_int(_options, "level", 1), 1, 8), {}, form
		)
	else:
		var rifts: Array[RiftData] = []
		for rift_id: StringName in ContentUnlocks.get_endless_roster_rift_ids(RIFT_CATALOG):
			rifts.append(RIFT_CATALOG.get_rift(rift_id))
		profile = RunProfile.endless(
			ENDLESS_CATALOG,
			ENDLESS_CATALOG.get_skin(StringName(str(_options.get("skin", "")))),
			rifts,
			ContentUnlocks.get_endless_boss_ids(RIFT_CATALOG),
			form,
		)
	profile.dash_style = DASH_STYLE_CATALOG.get_style(
		StringName(str(_options.get("dash_style", "")))
	)
	return profile


func _log_event(event: StringName, fields: Dictionary = {}) -> void:
	write_event(_events, event, fields, movie_seconds(_fps), _run_start)


## Movie seconds since recording began: one process frame is one movie frame.
static func movie_seconds(fps: float) -> float:
	return float(Engine.get_process_frames()) / fps


## The JSON-lines event log at [param path], or next to the movie when empty; null without either.
static func open_event_log(path: String) -> FileAccess:
	if path.is_empty() and not Engine.get_write_movie_path().is_empty():
		path = Engine.get_write_movie_path().get_basename() + ".events.jsonl"
	if path.is_empty():
		return null
	if path.is_relative_path():
		path = ProjectSettings.globalize_path("res://").path_join(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("render_gameplay_clip: cannot write the event log %s" % path)
	return file


static func write_event(
	file: FileAccess, event: StringName, fields: Dictionary, now: float, origin: float
) -> void:
	if file == null:
		return
	var line: Dictionary = {
		"t": snappedf(now, 0.001), "run_t": snappedf(now - origin, 0.001), "event": event,
	}
	line.merge(fields)
	file.store_line(JSON.stringify(line))
	file.flush()
