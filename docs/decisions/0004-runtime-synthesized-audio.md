# ADR-0004: Runtime-synthesized audio

> **Status:** Accepted
> **Date:** 2026-09-11 · **Deciders:** owner prompt / Claude Code

## Context

The game needs a full set of SFX (dash, slice, impacts, pickups, Reaper cues, UI) and adaptive
music, but no final audio files were supplied. The design (GDD §10, prompt §22) asks for
"carefully tuned runtime synthesis, not crude placeholder beeps" with a dark, soft, violet "soul
energy" identity. Target is mobile: small download, low CPU, no audio glitches.

## Options considered

1. **Pre-rendered files (OGG/WAV) from an external tool** — best control, but nothing exists yet
   and every tweak needs an offline round trip and imported binary assets.
2. **Per-sample `AudioStreamGenerator` streaming** — fully live, but GDScript must fill buffers on
   time every frame; costly and underrun-prone on mobile, and hard to keep several voices in sync.
3. **Synthesize once at startup into `AudioStreamWAV` buffers** — pure GDScript DSP, runs once off
   the main thread, afterwards playback is ordinary sample playback with zero per-frame DSP cost.

## Decision

Option 3. `AudioSynth` renders every SFX and three 8 s music loop layers (pad, pulse, boss) into
22050 Hz mono 16-bit PCM on a `WorkerThreadPool` task at startup; `AudioService` (autoload
`Audio`) wraps them in `AudioStreamWAV` on the main thread and plays them through a fixed voice
pool and three synchronized music players on `Music`/`SFX`/`UI` buses. Callers use string ids only,
so any id can later be replaced by a real audio file without API changes.

## Consequences

- No audio assets in the repo; download size stays tiny; sound design lives in code and is
  diffable and testable headlessly.
- Startup does a short one-off synthesis job (off the main thread); sounds requested before it
  finishes are silently skipped, and `start_music()` is deferred until ready.
- Quality is bounded by simple DSP and by designing without a listening pass; recipes need tuning
  by ear on device. Headless runs skip synthesis unless a test calls `generate_now()`.
- About 1.5 MB of PCM in memory (≈1.06 MB for the 3 × 8 s music loops) — fine on mobile.
