# System: Audio

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §10
>
> Why sounds are synthesized instead of loaded from files: [ADR-0004](../decisions/0004-runtime-synthesized-audio.md).

## Purpose

Give every gameplay and UI moment a soft, dark, violet "soul energy" sound, plus a quiet adaptive
music bed (pad → pulse with combo/threat → boss layer). All audio is synthesized once at startup,
so the game needs no audio files.

## Files

| Path | Role |
|---|---|
| `res://scripts/autoload/audio_service.gd` | `AudioService`: voice pool, music layers, fades, bus settings (autoload `Audio`) |
| `res://scripts/utils/audio_synth.gd` | `AudioSynth`: static, thread-safe DSP that renders every sound to 16-bit PCM |
| `res://default_bus_layout.tres` | Buses `Master`, `Music`, `SFX`, `UI` (the last three send to Master) |
| `res://tools/godot/test_audio_service.gd` | Headless test (`tools/run_tests.sh audio`) |

## Scene / node structure

```text
/root/Audio (Node, process_mode ALWAYS)   audio_service.gd
├── Voice0 … Voice11 (AudioStreamPlayer)  SFX voice pool, bus SFX or UI per call
└── MusicPad / MusicPulse / MusicBoss (AudioStreamPlayer, bus Music)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `sounds_ready` | signal | Emitted once when synthesis finished and sounds play. |
| `is_ready() -> bool` | method | True after `sounds_ready`. |
| `play_sfx(id, pitch_scale = 1.0, volume_db = 0.0)` | method | Plays an SFX id; `ui_*` → UI bus, else SFX. Ignored before ready; unknown id warns once. |
| `play_multi_kill(step)` | method | `slice` pitched up a minor-pentatonic step per extra kill (1 = base, capped). |
| `start_music()` / `stop_music()` | method | Start all three layers in sync (pad fades in, pulse/boss silent, intensity 0, boss off) / stop them. Before ready, start is deferred until ready. |
| `set_music_intensity(value)` | method | 0..1 combo/threat → pulse layer fades to that gain. |
| `set_boss_music(active)` | method | Fade the boss layer in/out; pad dims 4 dB while active. |
| `set_interrupted(interrupted)` | method | Duck all music by 18 dB (pause/background); false restores. |
| `apply_settings(settings)` | method | `music_volume` → Music bus, `sfx_volume` → SFX + UI buses (linear 0..1, `linear_to_db`, 0 = mute). Missing keys are ignored. |
| `generate_now()` | method | Synchronous synthesis (tests); waits for a running background job; no-op when ready. |
| `get_sfx_stream(id)` / `get_music_stream(layer)` | method | The installed stream, or null (tests, inspection). |

`AudioSynth` (static): `render_sfx(id)`, `render_music_layer(id)`, `render_all_pcm()`,
`encode_pcm16(samples)`, `build_stream(pcm, looping)`, `create_stream(id)`, plus `SFX_IDS`,
`MUSIC_LAYERS`, `MIX_RATE`, `MUSIC_LOOP_SECONDS`.

### SFX ids

| Id | Sound |
|---|---|
| `aim_tension` | Soft rising shimmer (0.4 s) |
| `dash` | Airy whoosh with pitch-down tail |
| `slice` | Bright glassy cut + short noise (also the multi-kill ladder) |
| `wall_impact` | Low soft thud with a faint crystal ring |
| `shard_pickup` | Small two-note bell chime |
| `player_damage` | Dull hit + dissonant low cluster |
| `player_dissolve` | Descending airy dissolve (0.75 s) |
| `level_up` | Rising D–A–D arpeggio shimmer with a bell |
| `upgrade_choice` | Warm open-fifth confirm swell |
| `reaper_appear` | Deep dark beating swell (1.35 s) |
| `reaper_windup` | Rising dissonant tension scrape |
| `reaper_sweep` | Heavy low whoosh |
| `reaper_hit` | Deep impact + crack |
| `reaper_defeat` | Big descending release with falling bells (1.6 s) |
| `ui_confirm` / `ui_back` | Short soft rising / falling tick |
| `ui_purchase` | Quick rising bell cluster with airy shimmer |
| `ui_error` | Soft low dissonant double blip |

## Data & tuning

All values are constants (sound design, not balance): recipes in `audio_synth.gd`; mix in
`audio_service.gd` — `SFX_TRIM_DB` (per-id trims), `LAYER_BASE_DB` (pad −12, pulse −14, boss −11),
`BOSS_PAD_DIM_DB` (−4), `INTERRUPT_DUCK_DB` (−18), `LAYER_FADE_SECONDS` (0.8), `DUCK_FADE_SECONDS`
(0.15), `VOICE_COUNT` (12). Format: 22050 Hz, mono, 16-bit, every sound peak-normalised to −3 dBFS.

## Dependencies

AudioServer buses from `default_bus_layout.tres` (picked up automatically by the default
`audio/buses/default_bus_layout` setting; `_ensure_buses()` creates missing buses as a fallback).
Settings dictionary keys come from `SaveManager` (`music_volume`, `sfx_volume`).

## Rules & behaviour

- **Every stream ends with `AudioSynth.GUARD_FRAMES` silent frames, and a loop's `loop_end` points at
  the first guard frame.** Godot's mixer interpolates one frame past the sample it is on (and past
  the loop point when wrapping); without the guard that read runs off the buffer — harmless on
  desktop, but an instant SIGSEGV in Android's audio thread (seen on a Galaxy S24, 2026-09-12).
  `test_audio_service.gd` asserts the guard frames and `loop_end < frame count`.
- Synthesis runs on a `WorkerThreadPool` task that only produces PCM bytes; streams are built and
  installed on the main thread via `call_deferred`. Skipped when the display server is
  `headless` (keeps headless tests/tools fast); call `generate_now()` there.
- SFX: 12 pooled players, round-robin; when all are busy the oldest-started voice is stolen.
  No nodes are created per call.
- Music: three loops of exactly 8.0 s (4 bars at 120 BPM) started in the same frame so they stay
  sample-aligned; state changes only move target gains. Fades are exponential in `_process`
  (no allocations) and processing switches itself off once settled.
- Loop seams are seamless: loop oscillators complete whole cycles in 8 s, LFOs have integer cycle
  counts and pulse-layer notes end inside the loop.
- The node uses `PROCESS_MODE_ALWAYS`, so UI sounds and music ducking work while the tree is paused.
- Replacing a sound with a real file later: install it under the same id (streams are stored as
  `AudioStream`), callers don't change.

## How to test

- Automated: `tools/run_tests.sh audio` — formats, peaks (0.1..1.0), click-free edges, loop
  length/mode/seam, bus layout, `apply_settings`, unknown-id/before-ready handling and settled
  fade volumes (intensity, boss dim, duck); prints synthesis time. It never starts real
  playback: the headless Dummy driver doesn't mix, so started playbacks leak at exit.
- Manual: run the game, press UI buttons (UI bus), dash/slice (SFX), watch music layers follow
  combo and the Reaper; pause → music ducks.

## Known issues / TODO

- Sounds were designed numerically (no listening pass yet); tune recipes/trims by ear on device.
- Loudest sustained bass (< 80 Hz) is inaudible on phone speakers by nature; harmonics carry it.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Guard frames + loop_end fix after an Android audio-thread crash |
| 2026-09-11 | Created: runtime-synthesized SFX + 3-layer adaptive music, bus layout, test |
