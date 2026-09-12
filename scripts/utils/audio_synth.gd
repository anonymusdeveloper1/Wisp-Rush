class_name AudioSynth
extends RefCounted
## Renders every Wisp Rush sound effect and music loop as 16-bit mono PCM at runtime.
##
## Pure static DSP with no nodes or engine state, so it is safe to run on a worker thread.
## Building blocks: enveloped sine/triangle voices with exponential pitch glides, detuned
## choruses, noise through cascaded one-pole low-pass + one-pole high-pass filters, inharmonic
## bell partials, gentle tanh saturation, 4 ms edge fades and peak normalisation to about
## -3 dBFS. Music layers are exact 8 s loops (4 bars at 120 BPM): every oscillator completes a
## whole number of cycles per loop and every note ends inside it, so the loop point is seamless.
## Sound identity: dark, soft, violet "soul energy", with no square waves. See
## docs/systems/audio.md and ADR-0004.

## Output sample rate in Hz (mono, 16-bit).
const MIX_RATE: int = 22050
## Linear peak level each sound is normalised to (about -3 dBFS).
const PEAK_LEVEL: float = 0.707
## Fade-in/out applied to both ends of every SFX and to the end of every note (anti-click).
const EDGE_FADE_SECONDS: float = 0.004
## Music tempo; one beat is 0.5 s.
const MUSIC_BPM: float = 120.0
## Music loop length in seconds: 4 bars of 4/4 at MUSIC_BPM.
const MUSIC_LOOP_SECONDS: float = 8.0
## Silent frames appended after every stream. Godot's mixer interpolates one frame past the sample
## it is on (and past `loop_end` when wrapping), so without this guard the last frame reads off the
## end of the buffer: harmless on desktop, but a SIGSEGV in Android's audio thread.
const GUARD_FRAMES: int = 2
## Every SFX id the synth can render.
const SFX_IDS: Array[StringName] = [
	&"aim_tension",
	&"dash",
	&"slice",
	&"wall_impact",
	&"shard_pickup",
	&"player_damage",
	&"player_dissolve",
	&"level_up",
	&"upgrade_choice",
	&"reaper_appear",
	&"reaper_windup",
	&"reaper_sweep",
	&"reaper_hit",
	&"reaper_defeat",
	&"ui_confirm",
	&"ui_back",
	&"ui_purchase",
	&"ui_error",
]
## Music loop layers, all MUSIC_LOOP_SECONDS long.
const MUSIC_LAYERS: Array[StringName] = [&"pad", &"pulse", &"boss"]
const SATURATION_DRIVE: float = 1.4
const DC_BLOCK_POLE: float = 0.995
const NYQUIST_GUARD: float = 0.45
const BELL_RATIOS: Array[float] = [1.0, 2.76, 5.4, 8.93]
const BELL_LEVELS: Array[float] = [1.0, 0.45, 0.22, 0.1]


## Renders SFX [param id] as normalised float samples; empty for an unknown id.
static func render_sfx(id: StringName) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	match id:
		&"aim_tension":
			buffer = _aim_tension()
		&"dash":
			buffer = _dash()
		&"slice":
			buffer = _slice()
		&"wall_impact":
			buffer = _wall_impact()
		&"shard_pickup":
			buffer = _shard_pickup()
		&"player_damage":
			buffer = _player_damage()
		&"player_dissolve":
			buffer = _player_dissolve()
		&"level_up":
			buffer = _level_up()
		&"upgrade_choice":
			buffer = _upgrade_choice()
		&"reaper_appear":
			buffer = _reaper_appear()
		&"reaper_windup":
			buffer = _reaper_windup()
		&"reaper_sweep":
			buffer = _reaper_sweep()
		&"reaper_hit":
			buffer = _reaper_hit()
		&"reaper_defeat":
			buffer = _reaper_defeat()
		&"ui_confirm":
			buffer = _ui_confirm()
		&"ui_back":
			buffer = _ui_back()
		&"ui_purchase":
			buffer = _ui_purchase()
		&"ui_error":
			buffer = _ui_error()
		_:
			return buffer
	return _finish_one_shot(buffer)


## Renders music layer [param id] (`pad`, `pulse`, `boss`) as a seamless loop; empty if unknown.
static func render_music_layer(id: StringName) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	match id:
		&"pad":
			buffer = _music_pad()
		&"pulse":
			buffer = _music_pulse()
		&"boss":
			buffer = _music_boss()
		_:
			return buffer
	return _finish_loop(buffer)


## Renders every SFX and music layer to 16-bit PCM, keyed by id. Thread-safe (no engine state).
static func render_all_pcm() -> Dictionary[StringName, PackedByteArray]:
	var result: Dictionary[StringName, PackedByteArray] = {}
	for id: StringName in SFX_IDS:
		result[id] = encode_pcm16(render_sfx(id))
	for id: StringName in MUSIC_LAYERS:
		result[id] = encode_pcm16(render_music_layer(id))
	return result


## Converts float samples in -1..1 to little-endian signed 16-bit PCM bytes.
static func encode_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(roundf(clampf(samples[i], -1.0, 1.0) * 32767.0)))
	return bytes


## Wraps 16-bit mono PCM in an AudioStreamWAV; [param looping] loops the whole buffer forward.
static func build_stream(pcm: PackedByteArray, looping: bool) -> AudioStreamWAV:
	var frames: int = pcm.size() / 2
	var guarded: PackedByteArray = pcm.duplicate()
	guarded.resize(pcm.size() + GUARD_FRAMES * 2)  # resize zero-fills: the guard frames are silent
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = guarded
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		# One past the last real frame: the wrap interpolates into a guard frame, never off the end.
		stream.loop_end = frames
	return stream


## Renders [param id] (SFX or music layer) straight into a stream; null for an unknown id.
static func create_stream(id: StringName) -> AudioStreamWAV:
	var looping: bool = MUSIC_LAYERS.has(id)
	var samples: PackedFloat32Array = render_music_layer(id) if looping else render_sfx(id)
	if samples.is_empty():
		return null
	return build_stream(encode_pcm16(samples), looping)


# --- SFX recipes (times in seconds, frequencies in Hz) -----------------------------------------

static func _aim_tension() -> PackedFloat32Array:
	var b := _buffer(0.4)
	_chorus(b, 0.0, 0.4, 587.33, 880.0, 0.33, 0.18, 0.1, 9.0, 0.0)
	_tone(b, 0.0, 0.4, 1174.66, 1760.0, 0.07, 0.2, 0.08)
	_noise(b, 0.0, 0.4, 0.5, 0.2, 0.09, 3000.0, 7500.0, 2500.0, 11)
	return b


static func _dash() -> PackedFloat32Array:
	var b := _buffer(0.45)
	_noise(b, 0.0, 0.45, 1.1, 0.012, 0.11, 7000.0, 700.0, 250.0, 21)
	_tone(b, 0.0, 0.45, 700.0, 170.0, 0.35, 0.004, 0.12, 0.2)
	_tone(b, 0.0, 0.45, 1400.0, 340.0, 0.08, 0.004, 0.1)
	return b


static func _slice() -> PackedFloat32Array:
	var b := _buffer(0.32)
	_tone(b, 0.0, 0.32, 2100.0, 1650.0, 0.35, 0.001, 0.07)
	_tone(b, 0.0, 0.32, 3150.0, 2800.0, 0.18, 0.001, 0.05)
	_tone(b, 0.0, 0.32, 5200.0, 4700.0, 0.07, 0.001, 0.03)
	_chorus(b, 0.0, 0.32, 1046.5, 1000.0, 0.2, 0.002, 0.08, 6.0, 0.0)
	_noise(b, 0.0, 0.1, 0.7, 0.001, 0.02, 10000.0, 6000.0, 2500.0, 31)
	return b


static func _wall_impact() -> PackedFloat32Array:
	var b := _buffer(0.5)
	_tone(b, 0.0, 0.5, 150.0, 52.0, 0.8, 0.003, 0.09, 0.15)
	_noise(b, 0.0, 0.3, 2.0, 0.002, 0.035, 900.0, 250.0, 60.0, 41)
	_bell(b, 0.005, 1318.5, 0.1, 0.12)
	return b


static func _shard_pickup() -> PackedFloat32Array:
	var b := _buffer(0.5)
	_bell(b, 0.0, 1174.66, 0.4, 0.12)
	_bell(b, 0.045, 1760.0, 0.28, 0.1)
	return b


static func _player_damage() -> PackedFloat32Array:
	var b := _buffer(0.55)
	_tone(b, 0.0, 0.55, 200.0, 70.0, 0.7, 0.002, 0.07, 0.3)
	_noise(b, 0.0, 0.3, 1.6, 0.001, 0.04, 1500.0, 300.0, 80.0, 51)
	_tone(b, 0.0, 0.55, 110.0, 104.0, 0.3, 0.01, 0.12, 0.5)
	_tone(b, 0.0, 0.55, 116.5, 110.0, 0.25, 0.01, 0.12, 0.5)
	_tone(b, 0.0, 0.55, 155.6, 147.0, 0.15, 0.01, 0.12, 0.3)
	return b


static func _player_dissolve() -> PackedFloat32Array:
	var b := _buffer(0.75)
	_noise(b, 0.0, 0.75, 1.0, 0.03, 0.2, 6000.0, 350.0, 300.0, 61)
	_chorus(b, 0.0, 0.75, 880.0, 196.0, 0.3, 0.01, 0.2, 12.0, 0.0)
	_chorus(b, 0.0, 0.75, 1318.5, 294.0, 0.12, 0.02, 0.16, 15.0, 0.0)
	_tone(b, 0.0, 0.75, 440.0, 98.0, 0.15, 0.005, 0.22, 0.3)
	return b


static func _level_up() -> PackedFloat32Array:
	var b := _buffer(0.9)
	var notes: Array[float] = [587.33, 880.0, 1174.66]
	for n in notes.size():
		var start: float = 0.085 * n
		_chorus(b, start, 0.9 - start, notes[n], notes[n], 0.28, 0.004, 0.16, 6.0, 0.0)
		_tone(b, start, 0.9 - start, notes[n] * 2.0, notes[n] * 2.0, 0.06, 0.004, 0.1)
	_chorus(b, 0.25, 0.65, 1760.0, 1760.0, 0.12, 0.08, 0.14, 10.0, 0.0)
	_bell(b, 0.26, 1760.0, 0.1, 0.12)
	_noise(b, 0.1, 0.8, 0.35, 0.15, 0.12, 9000.0, 9000.0, 4000.0, 71)
	return b


static func _upgrade_choice() -> PackedFloat32Array:
	var b := _buffer(0.65)
	_chorus(b, 0.0, 0.65, 293.66, 296.0, 0.3, 0.06, 0.22, 7.0, 0.25)
	_chorus(b, 0.0, 0.65, 440.0, 443.5, 0.22, 0.07, 0.22, 7.0, 0.2)
	_tone(b, 0.0, 0.65, 587.33, 592.0, 0.1, 0.08, 0.18)
	_bell(b, 0.05, 1174.66, 0.08, 0.12)
	return b


static func _reaper_appear() -> PackedFloat32Array:
	var b := _buffer(1.35)
	_chorus(b, 0.0, 1.35, 55.0, 58.0, 0.45, 0.55, 0.32, 20.0, 0.5)
	_tone(b, 0.0, 1.35, 82.4, 87.3, 0.25, 0.6, 0.3, 0.4)
	_tone(b, 0.0, 1.35, 116.5, 110.0, 0.15, 0.65, 0.28, 0.3)
	_noise(b, 0.0, 1.35, 2.5, 0.6, 0.3, 200.0, 900.0, 40.0, 81)
	_chorus(b, 0.1, 1.25, 622.25, 587.33, 0.05, 0.7, 0.25, 25.0, 0.0)
	return b


static func _reaper_windup() -> PackedFloat32Array:
	var b := _buffer(0.85)
	_noise(b, 0.0, 0.85, 0.9, 0.6, 0.12, 800.0, 5000.0, 500.0, 91)
	_tone(b, 0.0, 0.85, 180.0, 520.0, 0.25, 0.55, 0.14, 0.6)
	_tone(b, 0.0, 0.85, 191.0, 551.0, 0.2, 0.55, 0.14, 0.6)
	_tone(b, 0.0, 0.85, 90.0, 260.0, 0.25, 0.5, 0.14, 0.3)
	return b


static func _reaper_sweep() -> PackedFloat32Array:
	var b := _buffer(0.65)
	_noise(b, 0.0, 0.65, 2.0, 0.07, 0.14, 3000.0, 250.0, 60.0, 101)
	_tone(b, 0.0, 0.65, 170.0, 45.0, 0.55, 0.04, 0.15, 0.4)
	_tone(b, 0.0, 0.65, 340.0, 90.0, 0.12, 0.04, 0.13)
	return b


static func _reaper_hit() -> PackedFloat32Array:
	var b := _buffer(0.8)
	_tone(b, 0.0, 0.8, 120.0, 38.0, 0.9, 0.002, 0.16, 0.25)
	_noise(b, 0.0, 0.4, 2.0, 0.001, 0.05, 3500.0, 200.0, 50.0, 111)
	_noise(b, 0.0, 0.06, 0.5, 0.0005, 0.012, 11000.0, 9000.0, 2500.0, 112)
	_tone(b, 0.0, 0.8, 73.4, 69.0, 0.3, 0.005, 0.22, 0.5)
	_tone(b, 0.0, 0.8, 77.8, 73.0, 0.25, 0.005, 0.22, 0.5)
	return b


static func _reaper_defeat() -> PackedFloat32Array:
	var b := _buffer(1.6)
	_noise(b, 0.0, 1.6, 1.3, 0.02, 0.45, 7000.0, 250.0, 120.0, 121)
	_chorus(b, 0.0, 1.6, 587.33, 146.83, 0.3, 0.01, 0.42, 12.0, 0.2)
	_chorus(b, 0.0, 1.6, 880.0, 220.0, 0.18, 0.02, 0.38, 14.0, 0.0)
	_tone(b, 0.0, 1.6, 110.0, 36.7, 0.5, 0.01, 0.4, 0.3)
	var bells: Array[float] = [1760.0, 1396.91, 1174.66, 880.0]
	for n in bells.size():
		_bell(b, 0.15 + 0.2 * n, bells[n], 0.07, 0.16)
	return b


static func _ui_confirm() -> PackedFloat32Array:
	var b := _buffer(0.22)
	_tone(b, 0.0, 0.22, 880.0, 932.0, 0.4, 0.003, 0.05)
	_tone(b, 0.0, 0.22, 1318.5, 1397.0, 0.15, 0.003, 0.04)
	_tone(b, 0.0, 0.22, 1760.0, 1760.0, 0.05, 0.003, 0.03)
	return b


static func _ui_back() -> PackedFloat32Array:
	var b := _buffer(0.22)
	_tone(b, 0.0, 0.22, 698.46, 587.33, 0.4, 0.003, 0.05, 0.15)
	_tone(b, 0.0, 0.22, 1046.5, 880.0, 0.12, 0.003, 0.04)
	return b


static func _ui_purchase() -> PackedFloat32Array:
	var b := _buffer(0.6)
	var notes: Array[float] = [1174.66, 1396.91, 1760.0, 2349.32]
	for n in notes.size():
		_bell(b, 0.045 * n, notes[n], 0.22, 0.17 if n == notes.size() - 1 else 0.08)
	_noise(b, 0.0, 0.6, 0.4, 0.05, 0.12, 10000.0, 10000.0, 5000.0, 131)
	_chorus(b, 0.0, 0.6, 587.33, 587.33, 0.12, 0.02, 0.15, 8.0, 0.0)
	return b


static func _ui_error() -> PackedFloat32Array:
	var b := _buffer(0.32)
	for start: float in [0.0, 0.13]:
		_tone(b, start, 0.1, 220.0, 208.0, 0.4, 0.004, 0.035, 0.35)
		_tone(b, start, 0.1, 233.0, 220.0, 0.15, 0.004, 0.035, 0.35)
	return b


# --- Music loops --------------------------------------------------------------------------------
# Loop frequencies are multiples of 1/MUSIC_LOOP_SECONDS (0.125 Hz), so each oscillator completes
# whole cycles per loop; LFO cycle counts are integers for the same reason.

static func _music_pad() -> PackedFloat32Array:
	var b := _buffer(MUSIC_LOOP_SECONDS)
	# D minor drone: D2 (+ detuned twin), A2, D3, F3 and a faint A4 shimmer swelling once a loop.
	_loop_voice(b, 73.375, 0.34, 0.5, 1, 0.3, 0.0, 0, 0.0)
	_loop_voice(b, 73.625, 0.26, 0.5, 1, 0.3, 0.5, 0, 0.0)
	_loop_voice(b, 110.0, 0.2, 0.3, 2, 0.5, 0.25, 0, 0.0)
	_loop_voice(b, 146.875, 0.14, 0.4, 1, 0.6, 0.6, 0, 0.0)
	_loop_voice(b, 174.625, 0.1, 0.2, 1, 0.8, 0.1, 0, 0.0)
	_loop_voice(b, 440.0, 0.035, 0.0, 1, 1.0, 0.75, 0, 0.0)
	return b


static func _music_pulse() -> PackedFloat32Array:
	var b := _buffer(MUSIC_LOOP_SECONDS)
	var beat: float = 60.0 / MUSIC_BPM
	var beats: int = int(roundf(MUSIC_LOOP_SECONDS / beat))
	for n in beats:
		var start: float = beat * n
		# Soft sub kick on every beat, gentler on the off-bar beats.
		var accent: float = 1.0 if n % 4 == 0 else 0.75
		_tone(b, start, 0.38, 110.0, 42.0, 0.8 * accent, 0.003, 0.1, 0.1)
		# Quiet filtered-noise tick on the off-beat.
		var tick_level: float = 0.35 if n % 2 == 1 else 0.25
		_noise(b, start + beat * 0.5, 0.08, tick_level, 0.001, 0.014, 9000.0, 7000.0, 5000.0,
				200 + n)
	return b


static func _music_boss() -> PackedFloat32Array:
	var b := _buffer(MUSIC_LOOP_SECONDS)
	# Sub bass pulsing in eighth notes (32 pulses per loop): D1 + D2.
	_loop_voice(b, 36.75, 0.5, 0.2, 1, 0.0, 0.0, 32, 0.09)
	_loop_voice(b, 73.375, 0.3, 0.6, 1, 0.0, 0.0, 32, 0.07)
	# Dissonant tension: tritone G#3 against D3, plus a beating high pair that swells per loop.
	_loop_voice(b, 146.875, 0.1, 0.4, 2, 0.5, 0.0, 0, 0.0)
	_loop_voice(b, 207.625, 0.09, 0.3, 2, 0.6, 0.5, 0, 0.0)
	_loop_voice(b, 415.25, 0.035, 0.0, 1, 1.0, 0.5, 0, 0.0)
	_loop_voice(b, 416.0, 0.03, 0.0, 1, 1.0, 0.5, 0, 0.0)
	return b


# --- DSP building blocks ------------------------------------------------------------------------

static func _buffer(seconds: float) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(int(roundf(seconds * MIX_RATE)))
	buffer.fill(0.0)
	return buffer


## Adds an oscillator (sine blended toward a sine-aligned triangle by [param shape]) with a
## linear attack, exponential decay, exponential pitch glide and a short release at its end.
static func _tone(buffer: PackedFloat32Array, start: float, length: float, freq_from: float,
		freq_to: float, amp: float, attack: float, decay: float, shape: float = 0.0) -> void:
	var first: int = int(start * MIX_RATE)
	var count: int = mini(int(length * MIX_RATE), buffer.size() - first)
	if count <= 0:
		return
	var step: float = freq_from / MIX_RATE
	var glide: float = pow(freq_to / freq_from, 1.0 / float(count))
	var attack_samples: float = maxf(attack * MIX_RATE, 1.0)
	var decay_factor: float = exp(-1.0 / maxf(decay * MIX_RATE, 1.0))
	var release: int = mini(int(EDGE_FADE_SECONDS * MIX_RATE), count)
	var phase: float = 0.0
	var level: float = 1.0
	for i in count:
		var env: float = level
		if i < attack_samples:
			env = float(i) / attack_samples
		else:
			level *= decay_factor
		var remaining: int = count - i
		if remaining < release:
			env *= float(remaining) / float(release)
		var wave: float = sin(TAU * phase)
		if shape > 0.0:
			var p: float = phase + 0.75
			if p >= 1.0:
				p -= 1.0
			wave = lerpf(wave, 4.0 * absf(p - 0.5) - 1.0, shape)
		buffer[first + i] += amp * env * wave
		phase += step
		if phase >= 1.0:
			phase -= 1.0
		step *= glide


## Adds three tones detuned by -cents, 0 and +cents for a soft, shimmering unison.
static func _chorus(buffer: PackedFloat32Array, start: float, length: float, freq_from: float,
		freq_to: float, amp: float, attack: float, decay: float, cents: float,
		shape: float) -> void:
	var spread: float = pow(2.0, cents / 1200.0)
	_tone(buffer, start, length, freq_from, freq_to, amp * 0.45, attack, decay, shape)
	_tone(buffer, start, length, freq_from * spread, freq_to * spread, amp * 0.3, attack, decay,
			shape)
	_tone(buffer, start, length, freq_from / spread, freq_to / spread, amp * 0.3, attack, decay,
			shape)


## Adds an inharmonic bell/chime; higher partials decay faster and partials above Nyquist are
## skipped.
static func _bell(buffer: PackedFloat32Array, start: float, freq: float, amp: float,
		decay: float) -> void:
	var length: float = float(buffer.size()) / MIX_RATE - start
	for n in BELL_RATIOS.size():
		var partial: float = freq * BELL_RATIOS[n]
		if partial > MIX_RATE * NYQUIST_GUARD:
			break
		_tone(buffer, start, length, partial, partial, amp * BELL_LEVELS[n], 0.002,
				decay / (1.0 + 0.8 * n))


## Adds seeded white noise through two cascaded one-pole low-passes (cutoff gliding
## exponentially from [param lowpass_from] to [param lowpass_to]) and a one-pole high-pass.
static func _noise(buffer: PackedFloat32Array, start: float, length: float, amp: float,
		attack: float, decay: float, lowpass_from: float, lowpass_to: float, highpass: float,
		noise_seed: int) -> void:
	var first: int = int(start * MIX_RATE)
	var count: int = mini(int(length * MIX_RATE), buffer.size() - first)
	if count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed
	var omega: float = TAU * minf(lowpass_from, MIX_RATE * NYQUIST_GUARD) / MIX_RATE
	var omega_glide: float = pow(lowpass_to / lowpass_from, 1.0 / float(count))
	var hp_omega: float = TAU * highpass / MIX_RATE
	var hp_coeff: float = hp_omega / (1.0 + hp_omega)
	var attack_samples: float = maxf(attack * MIX_RATE, 1.0)
	var decay_factor: float = exp(-1.0 / maxf(decay * MIX_RATE, 1.0))
	var release: int = mini(int(EDGE_FADE_SECONDS * MIX_RATE), count)
	var low_a: float = 0.0
	var low_b: float = 0.0
	var high_state: float = 0.0
	var level: float = 1.0
	for i in count:
		var env: float = level
		if i < attack_samples:
			env = float(i) / attack_samples
		else:
			level *= decay_factor
		var remaining: int = count - i
		if remaining < release:
			env *= float(remaining) / float(release)
		var coeff: float = omega / (1.0 + omega)
		low_a += (rng.randf() * 2.0 - 1.0 - low_a) * coeff
		low_b += (low_a - low_b) * coeff
		high_state += (low_b - high_state) * hp_coeff
		buffer[first + i] += amp * env * (low_b - high_state)
		omega *= omega_glide


## Adds a whole-loop oscillator. Amplitude breathes with an LFO of [param lfo_cycles] cycles per
## loop ([param lfo_depth] 0..1, [param lfo_phase] 0..1); [param pulses] > 0 also gates it with
## that many decaying pulses per loop that start and end at zero.
static func _loop_voice(buffer: PackedFloat32Array, freq: float, amp: float, shape: float,
		lfo_cycles: int, lfo_depth: float, lfo_phase: float, pulses: int,
		pulse_decay: float) -> void:
	var count: int = buffer.size()
	var step: float = freq / MIX_RATE
	var lfo_step: float = float(lfo_cycles) / float(count)
	var pulse_period: float = MUSIC_LOOP_SECONDS / maxf(float(pulses), 1.0)
	var pulse_tail: float = exp(-pulse_period / maxf(pulse_decay, 0.001))
	var pulse_attack: float = 0.008
	for i in count:
		var phase: float = fmod(step * i, 1.0)
		var wave: float = sin(TAU * phase)
		if shape > 0.0:
			var p: float = phase + 0.75
			if p >= 1.0:
				p -= 1.0
			wave = lerpf(wave, 4.0 * absf(p - 0.5) - 1.0, shape)
		var gain: float = 1.0 - lfo_depth * (0.5 - 0.5 * cos(TAU * (lfo_step * i + lfo_phase)))
		if pulses > 0:
			var local: float = fmod(float(i) / MIX_RATE, pulse_period)
			gain *= minf(local / pulse_attack, 1.0) * (exp(-local / pulse_decay) - pulse_tail) \
					/ (1.0 - pulse_tail)
		buffer[i] += amp * gain * wave


## Saturates, removes DC, fades both edges and normalises a one-shot sound.
static func _finish_one_shot(buffer: PackedFloat32Array) -> PackedFloat32Array:
	_saturate(buffer)
	var previous_in: float = 0.0
	var previous_out: float = 0.0
	for i in buffer.size():
		var x: float = buffer[i]
		previous_out = x - previous_in + DC_BLOCK_POLE * previous_out
		previous_in = x
		buffer[i] = previous_out
	var fade: int = mini(int(EDGE_FADE_SECONDS * MIX_RATE), buffer.size() / 2)
	var last: int = buffer.size() - 1
	for i in fade:
		var gain: float = float(i) / float(fade)
		buffer[i] *= gain
		buffer[last - i] *= gain
	_normalise(buffer)
	return buffer


## Saturates and normalises a loop; memoryless, so the seamless loop point is preserved.
static func _finish_loop(buffer: PackedFloat32Array) -> PackedFloat32Array:
	_saturate(buffer)
	_normalise(buffer)
	return buffer


## Gentle tanh saturation applied after scaling the peak to 1.
static func _saturate(buffer: PackedFloat32Array) -> void:
	var peak: float = _peak(buffer)
	if peak <= 0.0:
		return
	var pre: float = SATURATION_DRIVE / peak
	var post: float = 1.0 / tanh(SATURATION_DRIVE)
	for i in buffer.size():
		buffer[i] = tanh(buffer[i] * pre) * post


static func _normalise(buffer: PackedFloat32Array) -> void:
	var peak: float = _peak(buffer)
	if peak <= 0.0:
		return
	var gain: float = PEAK_LEVEL / peak
	for i in buffer.size():
		buffer[i] *= gain


static func _peak(buffer: PackedFloat32Array) -> float:
	var peak: float = 0.0
	for i in buffer.size():
		peak = maxf(peak, absf(buffer[i]))
	return peak
