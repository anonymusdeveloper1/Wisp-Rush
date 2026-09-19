extends SceneTree
## Headless checks for synthesized audio: formats, levels, clicks, loops, buses and settings.

const Service := preload("res://scripts/autoload/audio_service.gd")
const Synth := preload("res://scripts/utils/audio_synth.gd")
const BUS_LAYOUT_PATH: String = "res://default_bus_layout.tres"
const EXPECTED_BUSES: Array[String] = ["Master", "Music", "SFX", "UI"]
const EDGE_SAMPLES: int = 4
const EDGE_LIMIT: float = 0.01
const LOOP_SEAM_LIMIT: float = 0.05

var _failures: int = 0
var _checks: int = 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var service: Service = Service.new()
	root.add_child(service)
	_check(not service.is_ready(), "headless run skips automatic synthesis")
	service.play_sfx(&"dash") # Before ready: silently ignored.
	_check(service.get_sfx_stream(&"dash") == null, "no streams before synthesis")

	var started: int = Time.get_ticks_usec()
	service.generate_now()
	var elapsed_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
	print("test_audio_service: synthesis took %.0f ms" % elapsed_ms)
	_check(service.is_ready(), "ready after generate_now")

	for id: StringName in Synth.SFX_IDS:
		var samples: PackedFloat32Array = _check_stream(service.get_sfx_stream(id), String(id))
		if samples.size() > EDGE_SAMPLES * 2:
			for i in EDGE_SAMPLES:
				_check(absf(samples[i]) <= EDGE_LIMIT, "%s starts near zero" % id)
				_check(absf(samples[-1 - i]) <= EDGE_LIMIT, "%s ends near zero" % id)
		var wav := service.get_sfx_stream(id) as AudioStreamWAV
		if wav != null:
			_check(wav.loop_mode == AudioStreamWAV.LOOP_DISABLED, "%s does not loop" % id)

	var loop_length: int = -1
	for layer: StringName in Synth.MUSIC_LAYERS:
		var samples: PackedFloat32Array = _check_stream(service.get_music_stream(layer),
				"music %s" % layer)
		var wav := service.get_music_stream(layer) as AudioStreamWAV
		if wav == null or samples.is_empty():
			continue
		if loop_length == -1:
			loop_length = samples.size()
		_check(samples.size() == loop_length, "music %s has the shared loop length" % layer)
		_check(samples.size() == roundi(Synth.MUSIC_LOOP_SECONDS * Synth.MIX_RATE) + Synth.GUARD_FRAMES,
				"music %s is %.1f s plus guard frames" % [layer, Synth.MUSIC_LOOP_SECONDS])
		_check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "music %s loops forward" % layer)
		_check(wav.loop_begin == 0 and wav.loop_end == samples.size() - Synth.GUARD_FRAMES,
				"music %s loops the whole buffer" % layer)
		_check(absf(samples[samples.size() - 1 - Synth.GUARD_FRAMES] - samples[0]) <= LOOP_SEAM_LIMIT,
				"music %s loop seam is continuous" % layer)

	_check_bus_layout()
	_check_settings(service)
	_check_played_ids_exist()

	# An unknown id must not crash (it only warns once). Known ids are not played here: the
	# headless Dummy driver never mixes, so started playbacks would be reported as leaked at exit.
	service.play_sfx(&"definitely_not_a_sound")
	service.play_sfx(&"definitely_not_a_sound")
	_check_music_fades(service)

	service.free()
	if _failures == 0:
		print("test_audio_service: %d checks passed (%d SFX, %d music layers, %.0f ms synthesis)"
				% [_checks, Synth.SFX_IDS.size(), Synth.MUSIC_LAYERS.size(), elapsed_ms])
	quit(_failures)


## Every id the project actually plays must be a real SFX id.
##
## `SoundFx.play()` is null-safe and `play_sfx()` only warns, so a typo or a music-layer id used as
## an effect is silent at runtime and easy to miss: `game_world.gd` asked for `pulse` — the name of a
## music layer — from M10 until 2026-09-18, and both sounds were dropped for every player.
func _check_played_ids_exist() -> void:
	var played: Dictionary[StringName, String] = {}
	for directory: String in ["res://scenes", "res://scripts"]:
		_collect_played_ids(directory, played)
	_check(not played.is_empty(), "found SoundFx.play() call sites to check")
	for id: StringName in played:
		_check(
			Synth.SFX_IDS.has(id),
			"%s plays SFX %s, which AudioSynth can render" % [played[id], id]
		)
		_check(
			not Synth.MUSIC_LAYERS.has(id),
			"%s plays %s, which is not a music layer id" % [played[id], id]
		)


## Recursively records every `SoundFx.play(&"id"` literal under [param directory] against its file.
func _collect_played_ids(directory: String, played: Dictionary[StringName, String]) -> void:
	for sub: String in DirAccess.get_directories_at(directory):
		_collect_played_ids("%s/%s" % [directory, sub], played)
	var pattern := RegEx.create_from_string(r'SoundFx\.play\(\s*&"([a-z0-9_]+)"')
	for file_name: String in DirAccess.get_files_at(directory):
		if not file_name.ends_with(".gd"):
			continue
		var path: String = "%s/%s" % [directory, file_name]
		var text: String = FileAccess.get_file_as_string(path)
		for found: RegExMatch in pattern.search_all(text):
			played[StringName(found.get_string(1))] = path


## Validates format and level of [param stream] and returns its decoded samples (empty on error).
func _check_stream(stream: AudioStream, label: String) -> PackedFloat32Array:
	var wav := stream as AudioStreamWAV
	_check(wav != null, "%s synthesizes to an AudioStreamWAV" % label)
	if wav == null:
		return PackedFloat32Array()
	_check(wav.format == AudioStreamWAV.FORMAT_16_BITS, "%s is 16-bit" % label)
	_check(wav.mix_rate == Synth.MIX_RATE, "%s mix rate is %d" % [label, Synth.MIX_RATE])
	_check(not wav.stereo, "%s is mono" % label)
	var data: PackedByteArray = wav.data
	_check(data.size() > 0 and data.size() % 2 == 0, "%s has 16-bit sample data" % label)
	var samples := PackedFloat32Array()
	samples.resize(data.size() / 2)
	var peak: float = 0.0
	for i in samples.size():
		var value: float = float(data.decode_s16(i * 2)) / 32767.0
		samples[i] = value
		peak = maxf(peak, absf(value))
	_check(peak <= 1.0 and peak >= 0.1, "%s peak %.3f within 0.1..1.0" % [label, peak])
	# The mixer reads one frame past the current sample, so every stream must keep silent guard
	# frames after its audio and (when looping) after loop_end — otherwise Android segfaults.
	_check(samples.size() > Synth.GUARD_FRAMES, "%s is longer than its guard frames" % label)
	for guard: int in Synth.GUARD_FRAMES:
		_check(is_zero_approx(samples[samples.size() - 1 - guard]), "%s guard frame is silent" % label)
	_check(wav.loop_end < samples.size(), "%s loop end stays inside the buffer" % label)
	return samples


func _check_bus_layout() -> void:
	var layout := load(BUS_LAYOUT_PATH) as AudioBusLayout
	_check(layout != null, "bus layout loads")
	if layout == null:
		return
	for i in EXPECTED_BUSES.size():
		var bus_name: String = str(layout.get("bus/%d/name" % i))
		_check(bus_name == EXPECTED_BUSES[i], "layout bus %d is %s (got %s)"
				% [i, EXPECTED_BUSES[i], bus_name])
		if i > 0:
			_check(str(layout.get("bus/%d/send" % i)) == "Master", "%s sends to Master"
					% EXPECTED_BUSES[i])
	for bus_name in EXPECTED_BUSES:
		_check(AudioServer.get_bus_index(bus_name) != -1, "AudioServer has bus %s" % bus_name)


func _check_settings(service: Service) -> void:
	var buses: Array[StringName] = [&"Music", &"SFX", &"UI"]
	var saved_db: Array[float] = []
	var saved_mute: Array[bool] = []
	for bus_name in buses:
		var index: int = AudioServer.get_bus_index(bus_name)
		saved_db.append(AudioServer.get_bus_volume_db(index))
		saved_mute.append(AudioServer.is_bus_mute(index))

	service.apply_settings({music_volume = 0.0, sfx_volume = 0.5})
	var music: int = AudioServer.get_bus_index(&"Music")
	var sfx: int = AudioServer.get_bus_index(&"SFX")
	var ui: int = AudioServer.get_bus_index(&"UI")
	_check(AudioServer.is_bus_mute(music), "music_volume 0 mutes Music")
	_check(not AudioServer.is_bus_mute(sfx), "sfx_volume 0.5 leaves SFX unmuted")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(sfx), linear_to_db(0.5)),
			"sfx_volume 0.5 sets SFX to linear_to_db(0.5)")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(ui), linear_to_db(0.5)),
			"sfx_volume 0.5 sets UI to linear_to_db(0.5)")
	service.apply_settings({})
	_check(AudioServer.is_bus_mute(music), "missing keys leave buses unchanged")

	for i in buses.size():
		var index: int = AudioServer.get_bus_index(buses[i])
		AudioServer.set_bus_volume_db(index, saved_db[i])
		AudioServer.set_bus_mute(index, saved_mute[i])


## Drives the fade loop directly (players stay stopped) and checks the settled layer volumes.
func _check_music_fades(service: Service) -> void:
	var pad := service.get_node("MusicPad") as AudioStreamPlayer
	var pulse := service.get_node("MusicPulse") as AudioStreamPlayer
	var boss := service.get_node("MusicBoss") as AudioStreamPlayer
	_check(pad != null and pulse != null and boss != null, "three music players exist")
	if pad == null or pulse == null or boss == null:
		return
	_check(pad.stream == service.get_music_stream(&"pad"), "pad player holds the pad loop")
	service.set_music_intensity(1.0)
	service.set_boss_music(true)
	service.set_interrupted(true)
	_settle(service)
	var duck: float = Service.INTERRUPT_DUCK_DB
	_check(is_equal_approx(pulse.volume_db, Service.LAYER_BASE_DB[1] + duck),
			"pulse fades to full (ducked), got %.2f dB" % pulse.volume_db)
	_check(is_equal_approx(boss.volume_db, Service.LAYER_BASE_DB[2] + duck),
			"boss fades in (ducked), got %.2f dB" % boss.volume_db)
	_check(is_equal_approx(pad.volume_db, Service.LAYER_BASE_DB[0] + Service.BOSS_PAD_DIM_DB
			+ duck), "pad dims under the boss (ducked), got %.2f dB" % pad.volume_db)
	service.set_interrupted(false)
	service.set_boss_music(false)
	service.set_music_intensity(0.0)
	_settle(service)
	_check(pulse.volume_db <= Service.SILENT_DB and boss.volume_db <= Service.SILENT_DB,
			"pulse and boss fade out to silence")
	_check(is_equal_approx(pad.volume_db, Service.LAYER_BASE_DB[0]), "pad restores after duck")
	_check(not service.is_processing(), "fade processing stops once settled")


func _settle(service: Service) -> void:
	for i in 400:
		service._process(0.05)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("test_audio_service: %s" % label)
