# System: Game feel & lifecycle

> **Status:** ✅ done (device tuning pending) · **Last updated:** 2026-09-11 · **GDD section:** §8, §12
> (prompt §21, §26, §27)

## Purpose

Make every dash, reap, hit and boss beat read physically — screen shake, hit-stop, haptics and
pooled one-shot effects — while honouring Screen Shake, Reduced Motion and Haptics, and keep a run
safe across app interruptions and back presses.

## Files

| Path | Role |
|---|---|
| `res://scenes/gameplay/game_world.gd` | Trauma shake, hit-stop, feedback hooks, auto-pause, back handling, pause/confirm/settings overlays |
| `res://scenes/gameplay/game_world.tscn` | PauseOverlay (Resume, Restart, Settings, Home) and ConfirmOverlay |
| `res://scripts/components/vfx_pool.gd` | `VfxPool`: 24 pooled Sprite2D one-shots, no per-effect allocation |
| `res://scripts/utils/haptics.gd` | `Haptics.pulse()` — mobile-only, settings-gated vibration |
| `res://scripts/utils/sound_fx.gd` | `SoundFx` — null-safe Audio shortcuts and UI click binding |
| `res://scenes/debug/debug_overlay.gd` | `DebugOverlay` — F3 performance overlay, debug builds only |
| `res://scenes/main/main.gd` | Android back / Escape routing, app pause → music duck |

## Scene / node structure

```text
GameWorld
├── WorldContent
│   ├── … EffectsLayer   one-off effects (e.g. Death Pulse)
│   └── VfxPool          pooled effects, created in _ready
└── HUD (CanvasLayer — never shakes)
    ├── PauseOverlay → ConfirmOverlay → SettingsScreen overlay (instanced on demand)
/root/DebugOverlay       debug builds only
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `GameWorld.add_trauma(amount)` | method | Adds 0..1 shake trauma (offset ∝ trauma²). |
| `GameWorld.handle_back() -> bool` | method | Confirm → settings → pause toggle; always consumes back. |
| `GameWorld.is_run_meaningful()` | method | Score, kills or wave > 1 → Restart/Home ask first. |
| `GameWorld.restart_requested` | signal | Confirmed restart from the pause menu. |
| `VfxPool.play(texture, position, rotation, start_scale, end_scale, duration, tint) -> int` | method | One pooled effect. |
| `Haptics.pulse(duration_ms, amplitude)` | static | Vibrate when enabled on mobile. |
| `SoundFx.play / multi_kill / music_state / set_interrupted / bind_buttons` | static | Audio access. |

## Data & tuning

Constants in `game_world.gd`. Offset = `SHAKE_MAX_OFFSET` (12) × arena width/1080 × strength × trauma²;
trauma decays 1.8/s. Strength = Screen Shake × (`REDUCED_MOTION_SHAKE` 0.3 when Reduced Motion).

| Event | Trauma → px | Extra |
|---|---|---|
| Wall impact | 0.45 → 2.4 | `wall_impact` |
| Double reap | 0.52 → 3.2 | medium haptic |
| Triple+ reap | 0.62 → 4.6 | 60 ms hit-stop (time scale 0.08), large impact VFX, medium haptic |
| Player damage | 0.75 → 6.8 | heavy haptic |
| Reaper hit / final hit | 0.35 / 1.0 → 1.5 / 12 | medium / double-heavy haptic |

## Dependencies

`SaveManager.settings_changed` (live), Audio autoload through `SoundFx`, supplied VFX art 01, 02,
04, 05, 08, equipped `FormData.tint`.

## Rules & behaviour

- Redesign v1: telegraphs are amber (warning) and magenta (execution); VFX PNGs are straight alpha, so they use normal blending (additive would double-brighten them).
- Shake moves the viewport canvas transform, so the HUD stays still; the backdrop is overscanned
  16 px; the offset and `Engine.time_scale` are always reset when GameWorld exits.
- Reduced Motion scales shake to 30 %, disables hit-stop and halves the wall flash.
- Pooled effects are tinted with the equipped form; when full, the most-finished effect is recycled.
- Focus loss or app pause opens the pause overlay (never resumes into danger); music ducks.
- Restart/Home from pause confirm only when progress would be lost; in-run Settings hides Reset.
- The debug overlay is never created in release builds.

## How to test

- `tools/godot/test_m4_systems.gd` (shake settings, auto-pause, back, confirmation, cleanup).
- `tools/godot/render_pause_showcase.gd [-- confirm|settings]` for visuals.
- Manual: triple reap → hit-stop; toggle Reduced Motion; alt-tab → paused; F3 overlay.

## Known issues / TODO

- Shake/haptic strengths and effect sizes need an on-device pass.
- Enemies and pickups are not pooled (counts are low); revisit if device profiling shows spikes.
- `09_teleport_vanish.png` is unused (Reaper teleports use their own sprites).
- Supplied VFX carry the baked checkerboard halo (ROADMAP backlog).

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Redesign v1 colours; VFX converted to straight alpha (ADR-0005) |
| 2026-09-11 | Created and verified in Milestone 4 |
