class_name LoadingScreen
extends Control
## Boot screen: the Wisp Rush mark over a soft soul-cyan glow while scenes load on worker threads
## and audio synthesizes.
##
## Never stays up forever: after MAX_WAIT_SECONDS anything unfinished is loaded synchronously
## (debug builds warn about it) and `finished` fires anyway. The logo breathes slowly (2-3 %)
## unless the player turned on reduced motion.

## Emitted once with every requested path mapped to its loaded Resource (null if it failed).
signal finished(resources: Dictionary)

const MAX_WAIT_SECONDS: float = 6.0
## Radius of the glow behind the logo, as a fraction of the screen width.
const GLOW_RADIUS: float = 0.46
## Opacity of the glow at its centre (it fades radially to nothing).
const GLOW_ALPHA: float = 0.22
const GLOW_TEXTURE_SIZE: int = 256
## Breathing speed (radians/s) and amplitude of the logo and glow.
const BREATH_SPEED: float = 2.2
const BREATH_SCALE: float = 0.015

var _paths := PackedStringArray()
var _wait_for_audio: bool = false
var _elapsed: float = 0.0
var _time: float = 0.0
var _started: bool = false
var _done: bool = false
var _reduced_motion: bool = false
var _glow: GradientTexture2D

@onready var _logo: TextureRect = %Logo
@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	_progress_bar.value = 0.0
	_glow = _build_glow()
	var save_manager := get_tree().root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager != null:
		_reduced_motion = bool(save_manager.get_settings().get(&"reduced_motion", false))
	print("[Loading] ready")


func _process(delta: float) -> void:
	_time += delta
	if not _reduced_motion:
		_logo.scale = Vector2.ONE * _breath()
		queue_redraw()
	if not _started or _done:
		return
	_elapsed += delta
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
	var audio_ready: bool = not _wait_for_audio or _is_audio_ready()
	var total: float = float(_paths.size()) + (1.0 if _wait_for_audio else 0.0)
	var done_units: float = loaded_fraction + (1.0 if _wait_for_audio and audio_ready else 0.0)
	_progress_bar.value = done_units / maxf(1.0, total)
	_status_label.text = "GATHERING SOULS" if not all_loaded else "TUNING THE RIFT"
	if (all_loaded and audio_ready) or _elapsed >= MAX_WAIT_SECONDS:
		_finish()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.VOID_CHARCOAL)
	var centre: Vector2 = _logo.position + _logo.size * 0.5
	var radius: float = size.x * GLOW_RADIUS * _breath()
	if _glow != null:
		var glow_rect := Rect2(centre - Vector2(radius, radius), Vector2.ONE * radius * 2.0)
		draw_texture_rect(_glow, glow_rect, false)


## Starts threaded loading of `paths`; also waits for synthesized audio when `wait_for_audio`.
func begin(paths: PackedStringArray, wait_for_audio: bool) -> void:
	_paths = paths
	_wait_for_audio = wait_for_audio
	for path: String in _paths:
		if ResourceLoader.load_threaded_request(path) != OK:
			push_warning("LoadingScreen could not queue %s; it will load synchronously" % path)
	_started = true


func _finish() -> void:
	_done = true
	var resources: Dictionary = {}
	for path: String in _paths:
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			resources[path] = ResourceLoader.load_threaded_get(path)
		else:
			if OS.is_debug_build():
				push_warning("LoadingScreen fell back to a synchronous load for %s" % path)
			resources[path] = load(path)
	print("[Loading] done | %.2fs resources=%d" % [_elapsed, resources.size()])
	finished.emit(resources)


func _is_audio_ready() -> bool:
	var audio: AudioService = SoundFx.audio()
	return audio == null or audio.is_ready()


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


func _breath() -> float:
	return 1.0 if _reduced_motion else 1.0 + sin(_time * BREATH_SPEED) * BREATH_SCALE
