class_name AudioService
extends Node
## Plays synthesized SFX through a voice pool and mixes three synced adaptive music layers.
##
## Registered as the `Audio` autoload. At startup it renders every sound with AudioSynth on a
## worker thread and installs the streams on the main thread (skipped under the headless display
## server; tests call generate_now()). SFX ids starting with `ui_` play on the UI bus, the rest
## on SFX; the node always processes, so UI sounds and music fades keep working while the tree is
## paused. Music = pad + pulse + boss loops of identical length started together; intensity, boss
## and interruption state only move their volumes. Bus volumes come from apply_settings().
## See docs/systems/audio.md and ADR-0004.

## Emitted once, when every sound has been synthesized and play_sfx() produces sound.
signal sounds_ready

# Preloaded (not referenced by class_name) so this works before the global class cache refreshes.
const Synth := preload("res://scripts/utils/audio_synth.gd")
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"
const VOICE_COUNT: int = 12
const UI_PREFIX: String = "ui_"
## Semitone offsets of the minor pentatonic ladder used by play_multi_kill() (capped at the top).
const MULTI_KILL_SEMITONES: Array[float] = [0.0, 3.0, 5.0, 7.0, 10.0, 12.0, 15.0, 17.0]
const LAYER_PAD: int = 0
const LAYER_PULSE: int = 1
const LAYER_BOSS: int = 2
## Player volume of each music layer at full gain (index = LAYER_*); keeps music under the SFX.
const LAYER_BASE_DB: Array[float] = [-12.0, -14.0, -11.0]
const SILENT_DB: float = -80.0
const BOSS_PAD_DIM_DB: float = -4.0
const INTERRUPT_DUCK_DB: float = -18.0
## Time constants of the exponential music fades, in seconds.
const LAYER_FADE_SECONDS: float = 0.8
const DUCK_FADE_SECONDS: float = 0.15
const GAIN_EPSILON: float = 0.001
## Per-id mix trims in dB so frequent or piercing sounds sit under the important ones.
const SFX_TRIM_DB: Dictionary[StringName, float] = {
	&"aim_tension": -8.0,
	&"dash": -3.0,
	&"slice": -2.0,
	&"shard_pickup": -6.0,
	&"wall_impact": -4.0,
	&"ui_confirm": -6.0,
	&"ui_back": -6.0,
	&"ui_purchase": -4.0,
	&"ui_error": -5.0,
}

var _is_ready: bool = false
var _sfx_streams: Dictionary[StringName, AudioStream] = {}
var _sfx_buses: Dictionary[StringName, StringName] = {}
var _music_streams: Dictionary[StringName, AudioStream] = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_players: Array[AudioStreamPlayer] = []
var _layer_gains := PackedFloat32Array([0.0, 0.0, 0.0])
var _layer_targets := PackedFloat32Array([0.0, 0.0, 0.0])
var _duck_gain: float = 1.0
var _duck_target: float = 1.0
var _intensity: float = 0.0
var _boss_active: bool = false
var _interrupted: bool = false
var _music_requested: bool = false
var _warned_ids: Dictionary[StringName, bool] = {}
var _task_id: int = -1
var _pending_pcm: Dictionary[StringName, PackedByteArray] = {}
var _synthesis_started_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for i in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		voice.bus = BUS_SFX
		add_child(voice)
		_voices.append(voice)
	for layer: StringName in Synth.MUSIC_LAYERS:
		var player := AudioStreamPlayer.new()
		player.name = "Music%s" % String(layer).capitalize()
		player.bus = BUS_MUSIC
		player.volume_db = SILENT_DB
		add_child(player)
		_music_players.append(player)
	_assign_music_streams()
	set_process(false)
	if _is_ready or DisplayServer.get_name() == "headless":
		return
	_synthesis_started_usec = Time.get_ticks_usec()
	_task_id = WorkerThreadPool.add_task(_synthesize_on_worker, false, "Audio synthesis")


func _process(delta: float) -> void:
	var layer_blend: float = 1.0 - exp(-delta / LAYER_FADE_SECONDS)
	var duck_blend: float = 1.0 - exp(-delta / DUCK_FADE_SECONDS)
	var settled: bool = true
	_duck_gain = lerpf(_duck_gain, _duck_target, duck_blend)
	if absf(_duck_gain - _duck_target) < GAIN_EPSILON:
		_duck_gain = _duck_target
	else:
		settled = false
	for i in _music_players.size():
		var gain: float = lerpf(_layer_gains[i], _layer_targets[i], layer_blend)
		if absf(gain - _layer_targets[i]) < GAIN_EPSILON:
			gain = _layer_targets[i]
		else:
			settled = false
		_layer_gains[i] = gain
		_music_players[i].volume_db = _gain_to_db(gain * _duck_gain) + LAYER_BASE_DB[i]
	if settled:
		set_process(false)


func _exit_tree() -> void:
	if _task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1


## Returns true once every sound is synthesized (after sounds_ready).
func is_ready() -> bool:
	return _is_ready


## Plays SFX [param id] on a pooled voice (round-robin; the oldest voice is stolen when all are
## busy). `ui_*` ids use the UI bus, others SFX. Ignored until ready; an unknown id warns once.
func play_sfx(id: StringName, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not _is_ready:
		return
	var stream: AudioStream = _sfx_streams.get(id)
	if stream == null:
		if not _warned_ids.has(id):
			_warned_ids[id] = true
			push_warning("[Audio] unknown SFX id: %s" % id)
		return
	if _voices.is_empty():
		return
	var voice: AudioStreamPlayer = _take_voice()
	var trim: float = SFX_TRIM_DB.get(id, 0.0)
	voice.stream = stream
	voice.bus = _sfx_buses[id]
	voice.pitch_scale = maxf(pitch_scale, 0.05)
	voice.volume_db = volume_db + trim
	voice.play()


## Plays `slice` pitched up the minor pentatonic ladder: [param step] 1 = base pitch, each extra
## kill one step higher, capped at the top of MULTI_KILL_SEMITONES.
func play_multi_kill(step: int) -> void:
	var index: int = clampi(step - 1, 0, MULTI_KILL_SEMITONES.size() - 1)
	play_sfx(&"slice", pow(2.0, MULTI_KILL_SEMITONES[index] / 12.0))


## Starts all three music layers together from the loop start: the pad fades in, pulse and boss
## start silent (intensity resets to 0, boss off). If called before ready, starts once ready.
func start_music() -> void:
	_music_requested = true
	_intensity = 0.0
	_boss_active = false
	_layer_gains.fill(0.0)
	_update_targets()
	if _is_ready:
		_start_music_players()


## Stops every music layer immediately.
func stop_music() -> void:
	_music_requested = false
	for player in _music_players:
		player.stop()


## Sets combo/threat intensity 0..1; the pulse layer fades toward that linear gain.
func set_music_intensity(value: float) -> void:
	_intensity = clampf(value, 0.0, 1.0)
	_update_targets()


## Fades the boss layer in (and dims the pad by BOSS_PAD_DIM_DB) or back out.
func set_boss_music(active: bool) -> void:
	_boss_active = active
	_update_targets()


## Ducks all music by INTERRUPT_DUCK_DB while paused/backgrounded; false restores it.
func set_interrupted(interrupted: bool) -> void:
	_interrupted = interrupted
	_update_targets()


## Applies `music_volume` (Music bus) and `sfx_volume` (SFX + UI buses), linear 0..1, via
## linear_to_db; 0 mutes the bus. Missing or non-numeric keys leave that bus unchanged.
func apply_settings(settings: Dictionary) -> void:
	_ensure_buses()
	var music: Variant = settings.get("music_volume")
	if music is float or music is int:
		_set_bus_linear(BUS_MUSIC, float(music))
	var sfx: Variant = settings.get("sfx_volume")
	if sfx is float or sfx is int:
		_set_bus_linear(BUS_SFX, float(sfx))
		_set_bus_linear(BUS_UI, float(sfx))


## Synthesizes every sound synchronously on the calling thread (tests, or to force readiness).
## Waits for an in-flight background synthesis instead of repeating it; no-op once ready.
func generate_now() -> void:
	if _is_ready:
		return
	if _task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
	if _pending_pcm.is_empty():
		_pending_pcm = Synth.render_all_pcm()
	_install_pending()


## Returns the stream for SFX [param id], or null if unknown or not ready yet.
func get_sfx_stream(id: StringName) -> AudioStream:
	return _sfx_streams.get(id)


## Returns the loop stream for music layer [param layer] (`pad`, `pulse`, `boss`), or null.
func get_music_stream(layer: StringName) -> AudioStream:
	return _music_streams.get(layer)


func _synthesize_on_worker() -> void:
	_pending_pcm = Synth.render_all_pcm()
	_finish_background_synthesis.call_deferred()


func _finish_background_synthesis() -> void:
	if _task_id == -1:
		return # generate_now() already consumed the result.
	WorkerThreadPool.wait_for_task_completion(_task_id)
	_task_id = -1
	_install_pending()
	var elapsed_ms: float = float(Time.get_ticks_usec() - _synthesis_started_usec) / 1000.0
	print("[Audio] synthesized %d sounds in %.0f ms" % [_sfx_streams.size() +
			_music_streams.size(), elapsed_ms])


func _install_pending() -> void:
	for id: StringName in _pending_pcm:
		var looping: bool = Synth.MUSIC_LAYERS.has(id)
		var stream: AudioStreamWAV = Synth.build_stream(_pending_pcm[id], looping)
		if looping:
			_music_streams[id] = stream
		else:
			_sfx_streams[id] = stream
			_sfx_buses[id] = BUS_UI if String(id).begins_with(UI_PREFIX) else BUS_SFX
	_pending_pcm = {}
	_assign_music_streams()
	_is_ready = true
	if _music_requested:
		_start_music_players()
	sounds_ready.emit()


func _assign_music_streams() -> void:
	for i in _music_players.size():
		_music_players[i].stream = _music_streams.get(Synth.MUSIC_LAYERS[i])


func _start_music_players() -> void:
	for player in _music_players:
		player.volume_db = SILENT_DB
		if player.stream != null:
			player.play(0.0)
	set_process(true)


func _update_targets() -> void:
	_layer_targets[LAYER_PAD] = db_to_linear(BOSS_PAD_DIM_DB) if _boss_active else 1.0
	_layer_targets[LAYER_PULSE] = _intensity
	_layer_targets[LAYER_BOSS] = 1.0 if _boss_active else 0.0
	_duck_target = db_to_linear(INTERRUPT_DUCK_DB) if _interrupted else 1.0
	set_process(true)


func _take_voice() -> AudioStreamPlayer:
	var count: int = _voices.size()
	for offset in count:
		var index: int = (_next_voice + offset) % count
		if not _voices[index].playing:
			_next_voice = (index + 1) % count
			return _voices[index]
	# All busy: steal the voice that was started longest ago (round-robin order).
	var stolen: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % count
	return stolen


func _set_bus_linear(bus_name: StringName, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var linear: float = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.0)
	if linear > 0.0:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))


## Creates any of Music/SFX/UI missing from the active layout (normally default_bus_layout.tres
## provides them), each sending to Master.
func _ensure_buses() -> void:
	for bus_name: StringName in [BUS_MUSIC, BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, BUS_MASTER)


func _gain_to_db(gain: float) -> float:
	return SILENT_DB if gain <= 0.0001 else maxf(linear_to_db(gain), SILENT_DB)
