# Spec: RUSH mode and fast feel

> **Status:** ✅ built 2026-09-15 (device pass pending; see [rush_mode.md](../../systems/rush_mode.md)) · **Written:** 2026-09-15 by Claude Code (Opus 5) ·
> **Rules:** [GDD](../../GDD.md) §5.1 (chain momentum), §5.6 (RUSH, momentum, auto-collect, finisher),
> §8 (game feel), §14 #27 ·
> **Touches:** [player_dash.md](../../systems/player_dash.md), [game_feel.md](../../systems/game_feel.md),
> [core_run.md](../../systems/core_run.md), [audio.md](../../systems/audio.md),
> [mutations.md](../../systems/mutations.md), new `docs/systems/rush_mode.md`
>
> One phase. Owner decision 2026-09-15: build these four base mechanics; the "Essences" power-up idea
> is **not** planned. The GDD owns the rules; this file owns the build steps and checks.

## Goal
Runs feel faster with no new buttons: momentum shows on the Wisp, Rift Point shards collect
themselves, big moments get a short slow-motion finisher, and kills fill a RUSH meter that fires a
6-second power burst. Everything works the same in Rift levels, Endless and the daily run.

## Out of scope
Essences or any other collectible power-ups; new enemies; save or Shop changes; Trials using RUSH.

## Where things are today
| Concern | Location |
|---|---|
| Chain momentum | `WispPlayer._momentum`, `get_momentum()`, `_update_momentum_for_launch()` — the chain window uses **wall-clock** `Time.get_ticks_msec()`; `PlayerTuning.momentum_window / momentum_step / momentum_max` (0.35 s / 0.08 / 0.25) |
| Dash speed | `WispPlayer` speed = base × run modifiers × (1 + momentum) × launch burst |
| Trail | `GameWorld._play_dash_trail()`, `_get_dash_trail_tint()`, `_get_dash_burst_tint()` (dash styles) |
| Hit-stop | `GameWorld._hit_stop()` writes `Engine.time_scale = HIT_STOP_TIME_SCALE` directly and refuses while scale < 1; `_reset_view_effects()` restores 1.0; skipped under Reduced Motion |
| Kills and combo | `GameWorld._on_enemy_killed()` (`_combo`, `_kills_by_dash[damage_event_id]`, score via `_apply_velocity_score_bonus`), `_update_combo(delta)`, `COMBO_TIMEOUT` 2.2 s, `%ComboLabel` "×n SOUL CHAIN" |
| Dash resolution | `GameWorld._resolve_completed_dash(dash_id)` — multi-kill callouts and bonuses at wall impact or redirect |
| Pickups | `SoulShardPickup` (`configure`, `try_dash_collect`, `collected(amount)`), `_spawn_rp_pickup`, `_on_rp_pickup_collected` → `_award_rift_points` (the single RP award path) |
| Waves / boss / end | `_on_wave_started`, `_start_boss_encounter`, `_on_reaper_defeated`, `_on_player_damaged`, `_on_player_died` → `run_ended.emit(summary)` (also the story victory path) |
| Music | `_update_music_state()` → `SoundFx.music_state(intensity, boss)` |
| Feedback | `add_trauma()`, `Haptics.pulse()`, `_show_callout()`, `_world_shade`, `VfxPool`; `_reduced_motion` from settings |
| HUD | `%XPBar`, `%ComboLabel`, `%WaveLabel`, `%RiftPointsCount` in `game_world.tscn` |
| Tutorial gate | `_tutorial_step` (`DISABLED` / `COMPLETE` = free play) |

## Tasks
1. **System doc first.** Create `docs/systems/rush_mode.md` from `_TEMPLATE.md` (⬜ → ✅ at the end) and add it to PROJECT_CONTEXT §5.1.
2. **Tuning.** New Resource `RunFeelTuning` (`res://scripts/resources/run_feel_tuning.gd`,
   `res://data/feel/default_run_feel_tuning.tres`), grouped exports, starting values from GDD §14 #27:
   - Momentum: `trail_length_at_max` 1.8, `trail_alpha_at_max` 1.0, `speed_lines_at` 1.0 (share of `momentum_max`), `dash_pitch_per_step` 0.04.
   - Auto-collect: `sweep_seconds` 0.35, `sweep_sound_cap` 6, `sweep_pitch_step` 0.05.
   - Finisher: `finisher_kills` 5, `finisher_time_scale` 0.3, `finisher_seconds` 0.4 (real time), `field_clear_cooldown` 6.0.
   - RUSH: `meter_max` 100, `per_kill` 4, `per_extra_dash_kill` 4, `per_boss_hit` 10, `damage_drain` 0, `duration` 6.0, `warning_seconds` 1.0, `speed_multiplier` 1.3, `score_multiplier` 2.0, `blocks_damage` true.
3. **One owner for time scale.** Replace direct `Engine.time_scale` writes with a small request list in
   GameWorld: `_request_time_scale(scale, real_seconds)`. The lowest active scale wins; each request
   expires on a timer that ignores time scale; with none left the scale is 1.0. `_hit_stop()` and the
   finisher both use it; pause, interruption, run end and `_reset_view_effects()` clear every request.
   Why: two writers race — a hit-stop timer ending would snap a slow-motion finisher back to 1.0.
4. **Chain momentum in game time.** Count `momentum_window` in accumulated physics time instead of
   `Time.get_ticks_msec()`, so slow motion between a landing and the next launch never breaks a chain.
   Behaviour at normal speed must not change (`test_movement` stays green).
5. **Momentum you can see.** With `level = get_momentum() / momentum_max` (0..1):
   - `_play_dash_trail()` scales the long trail's length and alpha by `level`; tints stay the dash style's.
   - A soft streak glow behind the Wisp while dashing grows with `level`.
   - At `level >= speed_lines_at`: faint speed lines along the dash direction for that dash (off under Reduced Motion).
   - Dash sound pitch rises `dash_pitch_per_step` per momentum step.
   - No new HUD text. Telegraphs and aim previews still draw above all of it (GDD §8).
6. **Auto-collect.** Add a sweep to `SoulShardPickup` (e.g. `sweep_to(target, seconds)`): it stops normal
   attraction, eases to the Wisp and collects through the existing `collected` signal, so
   `_award_rift_points` stays the only award path and nothing counts twice.
   - Sweep all floor shards when a new wave starts, when a boss encounter starts, when a boss is defeated,
     and right before the run summary is built on death or victory.
   - Play one rising chime run capped at `sweep_sound_cap`, never one sound per shard.
   - Under Reduced Motion the shards still fly (it is information), just faster.
7. **Slow-motion finisher.** Trigger `_request_time_scale(finisher_time_scale, finisher_seconds)` with a light
   `Palette.SOUL_WHITE` flash on `_world_shade`, a small trauma kick and a low-pitched `pulse` sound when:
   - a single dash reaches `finisher_kills` kills — at that kill, while the dash is still slicing;
   - a kill leaves no regular enemies alive during waves (not tutorial, not boss), at most once per `field_clear_cooldown`;
   - a boss takes its killing blow (no cooldown; in a Rift level it plays before the victory beat).

   Never during the pause menu or the upgrade choice. Under Reduced Motion: no time scale or flash, just the sound and the existing callout.
8. **RUSH meter.** A run-local meter in GameWorld, hidden and frozen during the tutorial lessons, reset each run.
   - Fill in `_on_enemy_killed`: `per_kill`, plus `per_extra_dash_kill` for every kill after the first in the same dash; `per_boss_hit` on each boss core hit. `damage_drain` (0) on damage. No decay.
   - Each kill sends one small soul orb (VFX pool sprite, form tint) from the enemy to the meter in about 0.3 s; under Reduced Motion the meter simply fills.
   - HUD: a slim RUSH bar under `%XPBar`, styled only through a Theme type variation; a `RUSH` label and a pulse when full (static under Reduced Motion). QA it at the five phone sizes.
9. **RUSH mode.** Starts automatically the moment the meter is full and play is free; if full during the
   tutorial, pause or upgrade choice, it starts when they close. For `duration` seconds of game time:
   - dash speed × `speed_multiplier` through a new `WispPlayer` run modifier that composes with momentum and mutations (never write `PlayerTuning`);
   - score × `score_multiplier` at the score choke point, composing with Void Velocity;
   - the combo timer is frozen;
   - no damage when `blocks_damage` — a new `WispPlayer` damage immunity separate from hurt invulnerability (no blink), covering enemies, hazards and boss attacks;
   - music intensity forced to 1.0 in `_update_music_state()`; momentum visuals at full; a subtle screen-edge glow (off under Reduced Motion);
   - start: big `RUSH` callout, heavy haptic, trauma 0.5, `level_up` sound; last `warning_seconds`: the Wisp glow flickers; end: meter to 0, soft `pulse` sound, everything restored.

   Run end, pause and scene exit stop RUSH cleanly. Add `rush_count` to the run summary for future goals; no save changes.

## Verify
- `tools/validate.sh` → `VALIDATE: OK`, then a device run. Owner preference (2026-09-15): device
  testing over headless tests, so add or update tests only when asked.
- When tests are wanted:
  - `test_rush_mode.gd` — fill maths, auto-start and deferral, duration, score ×2, immunity, frozen combo, per-run reset.
  - `test_run_feel.gd` — time-scale requests (lowest wins, overlapping expiry, reset), momentum window in game time, finisher triggers and cooldown, sweep awards each shard exactly once.
  - `test_movement` stays green.

## Docs
rush_mode.md ✅; player_dash.md (momentum visuals, game-time window, speed modifier, damage immunity);
game_feel.md (time-scale owner, finisher); core_run.md (RUSH meter, auto-collect sweep, `rush_count`);
audio.md (RUSH intensity); mutations.md (Soul Hunger still matters mid-wave); PROJECT_CONTEXT §5.1 and §5.8
(`RunFeelTuning`); ROADMAP M11 ticks; DEVLOG entry.

## Acceptance
- [ ] Three quick chained dashes visibly lengthen and brighten the trail; max momentum shows speed lines; damage clears them.
- [ ] At every wave start, boss start, boss defeat and run end, all floor shards fly to the Wisp and count once, with one capped chime run.
- [ ] A 5-kill dash slows time for about 0.4 s mid-dash; a field clear does so at most every 6 s; a boss killing blow always does; Reduced Motion shows no slow motion; time scale always returns to 1.0.
- [ ] A chain survives a slow-motion moment between landing and relaunch.
- [ ] RUSH fills from kills (faster from multi-kills), starts on its own, and gives 6 s of ×1.3 speed, ×2 score, frozen combo, no damage and peak music; the meter then empties. It never starts during the tutorial, pause or upgrade choice.
- [ ] Works the same in a Rift level, Endless and the daily run.
