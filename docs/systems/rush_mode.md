# System: RUSH mode and fast feel

> **Status:** ✅ done (device pass pending) ·
> **Last updated:** 2026-09-15 · **GDD section:** §5.1, §5.6, §8, §14 #27–#28
>
> Built from [specs/rush_and_feel/](../specs/rush_and_feel/README.md). The GDD owns the rules; this
> file owns how they are built.

## Purpose
Makes a run feel faster with no new buttons: visible chain momentum, Rift Point shards that collect
themselves, a short slow-motion finisher on big moments, and a RUSH meter that fires a 6-second power
burst. Run-local; no mode-specific code, so it works the same in Rift levels, Endless and the daily run.

## Files
| Path | Role |
|---|---|
| `res://scripts/resources/run_feel_tuning.gd` | `RunFeelTuning` — every value below |
| `res://data/feel/default_run_feel_tuning.tres` | Starting values (GDD §14 #27), set on `GameWorld.feel_tuning` |
| `res://scenes/gameplay/game_world.gd` | Meter, RUSH mode, finishers, time-scale owner, shard sweeps, trails, HUD |
| `res://scenes/gameplay/game_world.tscn` | `%RushRow` (`%RushLabel` + `%RushBar`) under the soul level |
| `res://scenes/player/wisp_player.gd` | Game-time momentum window, RUSH speed modifier and damage immunity, streak glow, speed lines, RUSH aura |
| `res://scenes/pickups/soul_shard_pickup.gd` | `sweep_to` / `collect_now` |
| `res://scripts/components/vfx_pool.gd` | `play_flight` (soul orbs) |
| `res://assets/ui/theme/tools/build_wisp_theme.gd` | `RushProgressBar` type variation |

## Scene / node structure
```
GameWorld
├── WispPlayer  + StreakGlow, RushAura (Sprite2D), SpeedLines (Node2D)   built in _ready, absolute z 0
├── VfxPool      soul orbs (play_flight)
└── HUD (CanvasLayer)
    ├── RushEdgeGlow (TextureRect, radial Palette.SOUL_CYAN gradient)   built in _ready, first child
    └── SafeHud/%RushRow (HBoxContainer) → %RushLabel (ValueLabel) + %RushBar (RushProgressBar)
```

## Public API
| Member | Kind | Description |
|---|---|---|
| `GameWorld.feel_tuning` | export | `RunFeelTuning`; a default instance when unset. |
| `GameWorld.is_rush_active()` / `get_rush_meter()` / `get_rush_remaining()` / `get_rush_count()` | methods | RUSH state for HUD, fixtures and future tests. |
| summary `rush_count` | `run_ended` key | RUSH activations this run; no save field. |
| `WispPlayer.set_rush_speed_multiplier(m)` / `get_rush_speed_multiplier()` | methods | RUSH run modifier in `get_current_dash_speed()`. |
| `WispPlayer.set_damage_immune(on)` / `is_damage_immune()` | methods | Blocks contact, hazard and boss damage; no blink. |
| `WispPlayer.set_rush_visuals(active, warning)` | method | Momentum visuals at full + Wisp aura; `warning` flickers it. |
| `WispPlayer.set_momentum_presentation(feel, glow_tint)` | method | Enables the streak glow / speed lines with the dash style's trail tint. |
| `WispPlayer.get_momentum_visual_level()` / `get_momentum_steps()` | methods | 0..1 (1 during RUSH) / whole momentum steps. |
| `SoulShardPickup.sweep_to(target, seconds) -> bool` | method | Starts a sweep; false if collected or already flying. |
| `SoulShardPickup.collect_now() -> bool` / `is_sweeping()` / `is_auto_collected()` | methods | Instant collect; sweep state. |
| `VfxPool.play_flight(texture, from, to, start_scale, end_scale, duration, tint)` | method | Pooled sprite that flies between canvas points. |
| `GameWorld._request_time_scale(scale, real_seconds)` | private method | Timed request (hit-stop, finisher). |
| `GameWorld._hold_time_scale(key, scale)` / `_release_time_scale(key)` | private methods | Keyed hold with no timer, e.g. `&"upgrade_tray"` for as long as the upgrade tray is up ([mutations.md](mutations.md)); holding a key again replaces its scale. |

## Data & tuning
`RunFeelTuning` (`default_run_feel_tuning.tres`):
- **Momentum:** `trail_length_at_max` 1.8, `trail_alpha_at_max` 1.0, `speed_lines_at` 1.0 (share of
  `momentum_max`), `dash_pitch_per_step` 0.04; streak glow 3.0 → 5.5 radii, alpha 0.18 → 0.55;
  4 speed lines, 6 radii, alpha 0.32.
- **Auto-collect:** `sweep_seconds` 0.35 (0.15 under Reduced Motion), `sweep_sound_cap` 6,
  `sweep_pitch_step` 0.05, `sweep_chime_interval` 0.05 s.
- **Finisher:** `finisher_kills` 5, `finisher_time_scale` 0.3, `finisher_seconds` 0.4 (real),
  `field_clear_cooldown` 6.0, flash alpha 0.3, trauma 0.25, `pulse` pitch 0.6.
- **RUSH:** `meter_max` 100, `per_kill` 4, `per_extra_dash_kill` 4, `per_boss_hit` 10, `damage_drain` 0,
  `duration` 6.0, `warning_seconds` 1.0, `speed_multiplier` 1.3, `score_multiplier` 2.0,
  `blocks_damage` true, `start_trauma` 0.5, `orb_flight_seconds` 0.3, `edge_glow_alpha` 0.28,
  `pulse_rate` 3.0, `warning_flicker_rate` 14, end sound −6 dB.

Presentation-only constants (orb size, callout scale, glow texture size, HUD offsets) stay in
`game_world.gd` / `wisp_player.gd`.

## Dependencies
[player_dash.md](player_dash.md) (momentum), [game_feel.md](game_feel.md) (shake, hit-stop, VfxPool),
[core_run.md](core_run.md) (kills, score, waves, bosses, summary), [audio.md](audio.md) (`pulse`,
`level_up`, `shard_pickup`, music intensity), [ui_design_system.md](ui_design_system.md). No autoload.

## Rules & behaviour
- **Time scale has one owner.** `_request_time_scale(scale, real_seconds)` adds a request with a
  timer that ignores time scale; `_hold_time_scale(key, scale)` adds a keyed hold that lasts until
  `_release_time_scale(key)`. The lowest active request or hold wins and none left means 1.0.
  `_hit_stop()` and the finisher request; the upgrade tray holds `&"upgrade_tray"` (×0.3) while it is up
  and releases it on pick-with-nothing-left, dismiss, timeout and boss start. Pause, interruption (it
  pauses), death, level victory, scene exit and `_reset_view_effects()` clear every request and hold
  (Resume re-holds for a tray that is still up).
- **Momentum window in game time.** `WispPlayer._game_time` accumulates physics delta (already scaled
  by `Engine.time_scale`, frozen while paused); landings store it. Unchanged at normal speed.
- **Visible momentum.** `level = momentum / momentum_max`. The launch burst and the long impact trail
  (`_play_dash_trail`) lengthen to ×1.8 and reach alpha 1.0 at `level` 1; tints stay the dash
  style's. A streak glow trails a dashing Wisp; at `level >= speed_lines_at` speed lines scroll behind
  it (never under Reduced Motion). Everything the player draws sits at absolute z 0, under hazard and
  boss telegraphs and the aim arrow. Damage zeroes momentum and ends the dash, clearing it all. Dash
  pitch = 1 + steps × 0.04.
- **Auto-collect.** `_sweep_floor_shards()` on wave start, boss encounter start, boss defeat and the
  fatal hit (during the death dissolve); `_emit_run_end()` then `collect_now()`s anything left right
  before the summary. Shards collect through `collected` → `_award_rift_points`, once. One rising
  chime run of at most 6 `shard_pickup`s per sweep; swept shards play no per-shard sound.
- **Finisher** (`_play_finisher`): the kill that brings one dash id to 5 kills (Soul Link kills of that
  dash count, Death Pulse kills do not); a kill that leaves `_remaining_live_enemies == 0` in free-play
  waves with no boss pending or alive, at most once per 6 s of game time; any boss's killing blow
  (before the victory beat). Refused while paused, while the upgrade tray is up or after run end. Reduced
  Motion: only the low `pulse` (no time scale, flash or trauma).
- **Meter.** Hidden (`%RushRow`) and frozen while `GameWorld.set_rush_enabled(false)` (Tutorial lessons
  other than RUSH, [tutorial.md](tutorial.md)); reset per run (GameWorld is
  rebuilt). Kills add `per_kill` + `per_extra_dash_kill` for each kill after the dash's first; each boss
  health loss adds `per_boss_hit`; damage subtracts `damage_drain`. No decay; no fill while RUSH runs.
  Each kill flies a soul orb (`12_collectible_sparkle`, form tint) to the bar in 0.3 s and the bar
  catches up when it lands; under Reduced Motion the bar simply fills. Full or running: the row pulses
  (static brighter under Reduced Motion).
- **RUSH mode.** Starts in `_process` once the meter is full and play is free (never while RUSH is disabled,
  paused or the upgrade tray is up — it waits for them; the tray in turn never opens during RUSH).
  For 6 game seconds: Wisp speed ×1.3 (`set_rush_speed_multiplier`), score ×2 inside
  `_apply_velocity_score_bonus` (after Void Velocity), combo timer and empty-dash decay frozen, damage
  immunity, music intensity 1.0, momentum visuals at full, Wisp aura, edge glow (off under Reduced
  Motion); the bar drains with the time left. Start: 1.5× `RUSH` callout, heavy haptic, trauma 0.5,
  `level_up`. Last second: the aura flickers. End: meter 0, soft `pulse`, everything restored.
- Pause freezes RUSH; death, level victory and scene exit end it (`_end_rush`) with no sound.

## How to test
- Manual (device, owner preference): chain three quick dashes (trail grows, speed lines at max, then
  take a hit); leave shards and start a wave/boss; reap 5 in one dash; clear the field twice within
  6 s; kill a boss; fill RUSH (~25 kills) and check ×1.3 speed, ×2 score, frozen combo, no damage,
  peak music, meter empty after; pause and bank an upgrade with a full meter; repeat with Reduced
  Motion; play a Rift level, Endless and the daily run. Logs: `[GameWorld] RUSH start|end`,
  `finisher | reason=`, `shard sweep | shards=`.
- Automated: none (owner preference 2026-09-15). Planned: `test_rush_mode.gd`, `test_run_feel.gd` (spec
  Verify section); `test_movement` should stay green.
- Layout: `tools/qa_matrix.sh game` → `logs/qa/game_sheet.png` (RUSH row, five phone sizes).

## Known issues / TODO
- Every value is a starting value: RUSH frequency per Rift level / Endless run and finisher feel need
  the device pass (ROADMAP M11).
- The boss panel and callouts moved down 34 px for the RUSH row; the boss panel was not in the QA
  capture (no boss screen in `qa_matrix.sh`).
- A boss killing-blow finisher slows the boss's defeat dissolve for its 0.4 s, so a Rift level's
  victory beat starts slightly later (intended).

## Change history
| Date | Change |
|---|---|
| 2026-09-15 | Keyed time-scale holds (`_hold_time_scale` / `_release_time_scale`) for the upgrade tray; the paused upgrade choice is gone |
| 2026-09-15 | Meter gating reads `set_rush_enabled` (Tutorial screen) instead of the removed in-run lesson |
| 2026-09-15 | Built (spec rush_and_feel): time-scale owner, game-time momentum, visible momentum, auto-collect, finisher, RUSH meter and mode, `RushProgressBar`, `rush_count` |
| 2026-09-15 | Created (planned) |
