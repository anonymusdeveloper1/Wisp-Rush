class_name LoadingScreen
extends Control
## Boot and run loading screen (redesign 2026-09-16): a random painted background already in the
## game, cover-scaled under a dark Palette scrim, the Wisp Rush logo in the upper part (and the
## arena heading under it for a run), and near the bottom "LOADING..." over a full ProgressBar.
##
## Boot: scenes load on worker threads while audio synthesizes. Run (PLAY, Rift Map ENTER): the
## arena's art loads on worker threads, then the host (Main) builds and warms the run beneath this
## screen in `extra_steps` steps it reports with [method complete_step]; the bar covers both and
## stays up at least RUN_MIN_SECONDS. The bar always visibly completes before `finished`.
##
## Never waits on resources forever: after MAX_WAIT_SECONDS anything unfinished loads synchronously
## (debug builds warn). Reduced Motion stills the background drift, logo breath and dots.

## Emitted once every requested path is loaded (before `finished`), mapped to its Resource.
signal resources_loaded(resources: Dictionary)
## Emitted once with every requested path mapped to its loaded Resource (null if it failed).
signal finished(resources: Dictionary)

const MAX_WAIT_SECONDS: float = 6.0
## A run loading screen stays up at least this long, so it reads as a screen, not a flash.
const RUN_MIN_SECONDS: float = 0.9
## Painted backgrounds already in the game (Main keeps them loaded after boot); one is picked at
## random. The five Rift arenas, Home and the menu background.
const BACKGROUND_POOL: PackedStringArray = [
	"res://assets/art/environment/wisp_rush_arena_background.png",
	"res://assets/art/environment/rifts/shattered_background.png",
	"res://assets/art/environment/rifts/ember_hollow_background.png",
	"res://assets/art/environment/rifts/frozen_choir_background.png",
	"res://assets/art/environment/rifts/reapers_court_background.png",
	"res://assets/art/environment/home_background.png",
	"res://assets/art/environment/menu_background.png",
]
## Seconds a background that had to load on a worker thread takes to fade in over void charcoal.
const BACKGROUND_FADE_SECONDS: float = 0.35
## Ken Burns: the image breathes between these zooms (always > 1, so it keeps covering) and drifts
## this many design pixels over one KEN_BURNS_SECONDS cycle.
const KEN_BURNS_MIN_ZOOM: float = 1.06
const KEN_BURNS_MAX_ZOOM: float = 1.12
const KEN_BURNS_DRIFT := Vector2(22.0, 34.0)
const KEN_BURNS_SECONDS: float = 16.0
## Scrim stops: opacity of void charcoal from the top of the screen to the bottom.
const SCRIM_OFFSETS: PackedFloat32Array = [0.0, 0.38, 0.62, 1.0]
const SCRIM_ALPHAS: PackedFloat32Array = [0.72, 0.30, 0.40, 0.94]
const STATUS_TEXT: String = "LOADING..."
## Seconds per step of the animated dots.
const DOTS_SECONDS: float = 0.38
## Fastest the bar moves, in bar lengths per second (it eases toward the real progress).
const BAR_SPEED: float = 2.2
## Opacity of the soft soul-cyan glow behind the logo at its centre.
const GLOW_ALPHA: float = 0.26
const GLOW_TEXTURE_SIZE: int = 256
## Breathing speed (radians/s) and amplitude of the logo.
const BREATH_SPEED: float = 2.2
const BREATH_SCALE: float = 0.015

var _paths := PackedStringArray()
var _wait_for_audio: bool = false
var _elapsed: float = 0.0
var _time: float = 0.0
var _started: bool = false
var _loaded: bool = false
var _done: bool = false
var _reduced_motion: bool = false
var _min_seconds: float = 0.0
var _extra_steps: int = 0
var _steps_done: int = 0
var _resources: Dictionary = {}
var _background_path: String = ""
## The chosen background is still loading on a worker thread.
var _background_pending: bool = false
var _background_fade: float = 1.0
var _ken_burns_phase: float = 0.0

@onready var _background: TextureRect = %Background
@onready var _scrim: TextureRect = %Scrim
@onready var _logo: TextureRect = %Logo
@onready var _logo_glow: TextureRect = %LogoGlow
@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _heading_label: Label = %HeadingLabel
@onready var _subheading_label: Label = %SubheadingLabel


func _ready() -> void:
	_progress_bar.value = 0.0
	_scrim.texture = _build_scrim()
	_logo_glow.texture = _build_glow()
	_status_label.text = STATUS_TEXT
	var save_manager := get_tree().root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager != null:
		_reduced_motion = bool(save_manager.get_settings().get(&"reduced_motion", false))
	_ken_burns_phase = randf()
	_update_motion()
	print("[Loading] ready")


func _process(delta: float) -> void:
	_time += delta
	_update_motion()
	_update_background(delta)
	if not _started or _done:
		return
	_elapsed += delta
	var loaded_fraction: float = _poll_loads()
	var audio_ready: bool = not _wait_for_audio or _is_audio_ready()
	var total: float = float(_paths.size() + _extra_steps) + (1.0 if _wait_for_audio else 0.0)
	var done_units: float = (
		loaded_fraction + float(_steps_done) + (1.0 if _wait_for_audio and audio_ready else 0.0)
	)
	# A run screen fills over its minimum time even when everything is already cached.
	var time_share: float = clampf(_elapsed / _min_seconds, 0.0, 1.0) if _min_seconds > 0.0 else 1.0
	var target: float = minf(done_units / maxf(1.0, total), time_share)
	_progress_bar.value = move_toward(_progress_bar.value, target, BAR_SPEED * delta)
	var steps_finished: bool = _steps_done >= _extra_steps
	if _loaded and steps_finished and audio_ready and _progress_bar.value >= 1.0:
		_finish()
	elif _elapsed >= MAX_WAIT_SECONDS and _loaded and steps_finished:
		_finish()


## Starts threaded loading of `paths`; also waits for synthesized audio when `wait_for_audio`.
func begin(paths: PackedStringArray, wait_for_audio: bool) -> void:
	_paths = paths
	_wait_for_audio = wait_for_audio
	for path: String in _paths:
		if ResourceLoader.load_threaded_request(path) != OK:
			push_warning("LoadingScreen could not queue %s; it will load synchronously" % path)
	_started = true
	if is_node_ready():
		_pick_background()
	else:
		ready.connect(_pick_background, CONNECT_ONE_SHOT)


## Run loading: shows [param heading] and [param subheading] under the logo, loads [param paths] on
## worker threads, then waits for [param extra_steps] host steps ([method complete_step]) and
## finishes no sooner than RUN_MIN_SECONDS.
func begin_run(
		paths: PackedStringArray,
		heading: String,
		subheading: String,
		extra_steps: int = 0,
	) -> void:
	_min_seconds = RUN_MIN_SECONDS
	_extra_steps = maxi(0, extra_steps)
	if is_node_ready():
		_apply_heading(heading, subheading)
	else:
		ready.connect(_apply_heading.bind(heading, subheading), CONNECT_ONE_SHOT)
	begin(paths, false)


## Marks one host step (from `begin_run`'s `extra_steps`) done; the bar advances by its share.
func complete_step() -> void:
	_steps_done = mini(_steps_done + 1, _extra_steps)


## The painted background on screen (res:// path), or empty before one is chosen.
func get_background_path() -> String:
	return _background_path


## Whether every requested resource has loaded (`resources_loaded` has fired).
func is_loaded() -> bool:
	return _loaded


func _apply_heading(heading: String, subheading: String) -> void:
	_heading_label.text = heading
	_heading_label.visible = not heading.is_empty()
	_subheading_label.text = subheading
	_subheading_label.visible = not subheading.is_empty()


## Returns the loaded share of `_paths` (0..size) and fires `resources_loaded` once all are in.
func _poll_loads() -> float:
	if _loaded:
		return float(_paths.size())
	var loaded_fraction: float = 0.0
	var all_loaded: bool = true
	var progress: Array = []
	for path: String in _paths:
		match ResourceLoader.load_threaded_get_status(path, progress):
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				all_loaded = false
				loaded_fraction += float(progress[0]) if not progress.is_empty() else 0.0
			_:
				loaded_fraction += 1.0
	if all_loaded or _elapsed >= MAX_WAIT_SECONDS:
		_collect_resources()
	return loaded_fraction


func _collect_resources() -> void:
	_loaded = true
	for path: String in _paths:
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_resources[path] = ResourceLoader.load_threaded_get(path)
		else:
			if OS.is_debug_build():
				push_warning("LoadingScreen fell back to a synchronous load for %s" % path)
			_resources[path] = load(path)
	resources_loaded.emit(_resources)


func _finish() -> void:
	_done = true
	_progress_bar.value = 1.0
	print("[Loading] done | %.2fs resources=%d" % [_elapsed, _resources.size()])
	finished.emit(_resources)


func _is_audio_ready() -> bool:
	var audio: AudioService = SoundFx.audio()
	return audio == null or audio.is_ready()


## Picks one pool image: shown at once when already cached, otherwise loaded on a worker thread
## and faded in over void charcoal.
func _pick_background() -> void:
	if not _background_path.is_empty():
		return
	_background_path = BACKGROUND_POOL[randi() % BACKGROUND_POOL.size()]
	if ResourceLoader.has_cached(_background_path):
		_background.texture = load(_background_path) as Texture2D
		return
	# A path the screen already loads for its host arrives with `_resources`; never request it twice.
	if not _background_path in _paths and ResourceLoader.load_threaded_request(_background_path) != OK:
		return
	_background_pending = true
	_background_fade = 0.0
	_background.modulate.a = 0.0


func _update_background(delta: float) -> void:
	if _background_pending and _background_path in _paths:
		if not _loaded:
			return
		_background.texture = _resources.get(_background_path) as Texture2D
		_background_pending = false
	elif _background_pending:
		match ResourceLoader.load_threaded_get_status(_background_path):
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				return
			ResourceLoader.THREAD_LOAD_LOADED:
				_background.texture = ResourceLoader.load_threaded_get(_background_path) as Texture2D
		_background_pending = false
	if _background_fade < 1.0:
		_background_fade = minf(1.0, _background_fade + delta / BACKGROUND_FADE_SECONDS)
		_background.modulate.a = _background_fade


## Ken Burns drift of the background, the logo's breath and the loading dots.
func _update_motion() -> void:
	if _reduced_motion:
		_background.scale = Vector2.ONE
		_background.position = Vector2.ZERO
		_status_label.visible_characters = -1
		return
	var cycle: float = TAU * (_ken_burns_phase + _time / KEN_BURNS_SECONDS)
	_background.pivot_offset = _background.size * 0.5
	var zoom: float = lerpf(KEN_BURNS_MIN_ZOOM, KEN_BURNS_MAX_ZOOM, 0.5 + 0.5 * sin(cycle))
	_background.scale = Vector2(zoom, zoom)
	_background.position = Vector2(
		KEN_BURNS_DRIFT.x * sin(cycle * 0.5), KEN_BURNS_DRIFT.y * cos(cycle * 0.5)
	)
	_logo.pivot_offset = _logo.size * 0.5
	_logo.scale = Vector2.ONE * (1.0 + sin(_time * BREATH_SPEED) * BREATH_SCALE)
	var dots: int = int(_time / DOTS_SECONDS) % 4
	_status_label.visible_characters = STATUS_TEXT.length() - 3 + dots


## Vertical void-charcoal scrim: darker behind the logo and the footer so text reads over any image.
static func _build_scrim() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = SCRIM_OFFSETS
	var colors := PackedColorArray()
	for alpha: float in SCRIM_ALPHAS:
		colors.append(Color(Palette.VOID_CHARCOAL, alpha))
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 4
	texture.height = 256
	return texture


## Radial soul-cyan glow (smooth, unlike stacked circles, which band on dark backgrounds).
static func _build_glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(Palette.SOUL_CYAN, GLOW_ALPHA))
	gradient.set_color(1, Color(Palette.SOUL_CYAN, 0.0))
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = GLOW_TEXTURE_SIZE
	texture.height = GLOW_TEXTURE_SIZE
	return texture
