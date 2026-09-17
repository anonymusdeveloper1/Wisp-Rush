extends SceneTree
## Devlog audio: writes the game's own synthesized sounds as WAV files for video editing.
##
## Usage (repo root; headless is fine, no audio device is used):
##   "$GODOT" --headless --path . --script res://tools/godot/export_game_audio.gd -- [out_dir] [bed_seconds]
## Defaults: out_dir `video/audio/game`, bed_seconds 64. Writes 16-bit mono WAVs at the game's
## AudioSynth.MIX_RATE: `sfx/<id>.wav` for every SFX id, `sfx/slice_step<N>.wav` for the eight
## multi-kill pitch steps, `music/<layer>.wav` as one 8 s loop, and `music/bed_<layer mix>.wav` beds of
## at least bed_seconds built from whole loops at AudioService's layer mix (pad; pad + pulse; boss).
## These are the game's own sounds (ADR-0004), so devlog exports can use them without licences.

const OUT_DIR_DEFAULT: String = "video/audio/game"
const BED_SECONDS_DEFAULT: float = 64.0
## AudioService.MULTI_KILL_SEMITONES: the slice pitch for each extra kill in one dash.
const MULTI_KILL_SEMITONES: Array[float] = [0.0, 3.0, 5.0, 7.0, 10.0, 12.0, 15.0, 17.0]
## AudioService.LAYER_BASE_DB for pad, pulse and boss.
const LAYER_DB: Dictionary[StringName, float] = {&"pad": -12.0, &"pulse": -14.0, &"boss": -11.0}
const BEDS: Dictionary[String, Array] = {
	"bed_calm": [&"pad"],
	"bed_run": [&"pad", &"pulse"],
	"bed_boss": [&"pad", &"boss"],
}


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else OUT_DIR_DEFAULT
	var bed_seconds: float = float(args[1]) if args.size() > 1 else BED_SECONDS_DEFAULT
	if out_dir.is_relative_path():
		out_dir = ProjectSettings.globalize_path("res://").path_join(out_dir)
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("sfx"))
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("music"))

	var written: int = 0
	for id: StringName in AudioSynth.SFX_IDS:
		written += _write(out_dir.path_join("sfx/%s.wav" % id), AudioSynth.render_sfx(id))
	var slice: PackedFloat32Array = AudioSynth.render_sfx(&"slice")
	for step: int in MULTI_KILL_SEMITONES.size():
		var rate: float = pow(2.0, MULTI_KILL_SEMITONES[step] / 12.0)
		written += _write(out_dir.path_join("sfx/slice_step%d.wav" % (step + 1)), _resample(slice, rate))

	var loops: Dictionary[StringName, PackedFloat32Array] = {}
	for layer: StringName in AudioSynth.MUSIC_LAYERS:
		loops[layer] = AudioSynth.render_music_layer(layer)
		written += _write(out_dir.path_join("music/%s.wav" % layer), loops[layer])
	var repeats: int = maxi(1, ceili(bed_seconds / AudioSynth.MUSIC_LOOP_SECONDS))
	for bed_name: String in BEDS:
		written += _write(out_dir.path_join("music/%s.wav" % bed_name), _bed(loops, BEDS[bed_name], repeats))

	print("export_game_audio: %d files in %s" % [written, out_dir])
	quit(0)


## Sums [param layers] at their game mix, repeats the loop, then normalises to about -1 dBFS.
func _bed(loops: Dictionary[StringName, PackedFloat32Array], layers: Array, repeats: int) -> PackedFloat32Array:
	var length: int = loops[layers[0]].size()
	var loop := PackedFloat32Array()
	loop.resize(length)
	for layer: StringName in layers:
		var gain: float = db_to_linear(LAYER_DB[layer])
		var samples: PackedFloat32Array = loops[layer]
		for i: int in mini(length, samples.size()):
			loop[i] += samples[i] * gain
	var peak: float = 0.0
	for value: float in loop:
		peak = maxf(peak, absf(value))
	var scale: float = 0.89 / peak if peak > 0.0 else 1.0
	var bed := PackedFloat32Array()
	bed.resize(length * repeats)
	for r: int in repeats:
		for i: int in length:
			bed[r * length + i] = loop[i] * scale
	return bed


## Plays [param samples] [param rate] times faster (linear interpolation), like a pitch-scaled voice.
func _resample(samples: PackedFloat32Array, rate: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var count: int = int(floor(float(samples.size() - 1) / rate))
	out.resize(maxi(count, 0))
	for i: int in out.size():
		var position: float = float(i) * rate
		var index: int = int(position)
		var fraction: float = position - float(index)
		out[i] = lerpf(samples[index], samples[mini(index + 1, samples.size() - 1)], fraction)
	return out


## Writes mono 16-bit PCM WAV; returns 1 when the file was written.
func _write(path: String, samples: PackedFloat32Array) -> int:
	if samples.is_empty():
		push_warning("export_game_audio: nothing rendered for %s" % path)
		return 0
	var pcm: PackedByteArray = AudioSynth.encode_pcm16(samples)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("export_game_audio: cannot write %s" % path)
		return 0
	var rate: int = AudioSynth.MIX_RATE
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + pcm.size())
	file.store_buffer("WAVEfmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(rate)
	file.store_32(rate * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(pcm.size())
	file.store_buffer(pcm)
	file.close()
	return 1
