# System: Run progression and mutations

> **Status:** ✅ done · **Last updated:** 2026-09-15 · **GDD section:** §5.5, §6–7, §15–16

## Purpose

Convert enemy XP into banked level-ups offered as three cards at calm moments, without ever pausing
or cutting the player off, and track separate score, combo, kills, multi-reaps, wave and earned Rift
Points through Results.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/mutation_data.gd` | Mutation identity, cap, icon and UI value schema |
| `res://scripts/resources/run_progression_tuning.gd` | XP curve, streak and reward tuning |
| `res://data/mutations/*.tres` | Eight supplied mutations |
| `res://data/progression/default_run_progression.tres` | Starting XP/reward values |
| `res://scripts/components/run_progression.gd` | XP, banked levels, choices and upgrade application state |
| `res://scenes/gameplay/upgrade_tray.*` | `UpgradeTray`: compact bottom card tray (replaced the paused `UpgradeSelect` overlay, 2026-09-15) |
| `res://scenes/gameplay/game_world.*` | Banking, calm moments, tray open/close, slow-motion hold, timeout, `%UpgradeReady` HUD pill |
| `res://scenes/pickups/soul_shard_pickup.*` | Dropped Rift Points shard, dash collection and attraction |

## Scene / node structure

```text
GameWorld
├── %RunProgression (Node)
└── HUD (CanvasLayer 10)
    ├── SafeHud → %XPBar
    └── %UpgradeTray (Control, mouse ignore) → %TrayPanel (MarginContainer, no frame, mouse stop)
        └── Content: %TimeoutBar (SlimProgressBar), Cards → %Choice0..2 (CardButton + Highlight/Icon/Name/Description/Level)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `experience_changed(xp, threshold, level)` | signal | Refresh the slim HUD progress display. |
| `level_ready` | signal | XP first banks a level-up (again after a pick that leaves one banked). |
| `mutation_applied(id, level)` | signal | Run-local mutation level changed. |
| `tuning` | export | XP curve, catalog and cross-system effect values. |
| `start(seed)` | method | Reset XP, levels and deterministic choice order. |
| `add_experience(amount)` | method | Add XP and latch a pending level. |
| `offer_choices(count)` | method | Distinct deterministic non-capped MutationData choices. |
| `apply_choice(id)` | method | Spend one pending level and emit the new mutation level. |
| `get_mutation_level(id)` | method | Current run-only level for one mutation. |
| `get_mutation(id)` / `get_levels()` | method | Mutation data or a copy of the run-level registry. |
| `has_pending_level()` | method | Whether at least one threshold is covered. |
| `get_banked_levels()` | method | Level-ups banked and still spendable (thresholds covered along the curve, capped by mutation levels left). |
| `get_current_xp()` / `get_xp_threshold()` | method | Current XP progress. |
| `get_run_level()` / `get_total_mutation_levels()` | method | Run level and aggregate power context. |
| `MutationData.get_next_description(level)` | method | Concise next-level card copy from authored values. |
| `UpgradeTray.choice_selected(id)` | signal | One card accepted, exactly once per presentation. |
| `UpgradeTray.present(choices, levels, slide_seconds)` / `dismiss(slide_seconds)` | method | Slide up (or swap in the next set) / slide away; 0 s = instant. |
| `UpgradeTray.set_suspended(on)` | method | Hide under the pause menu and show again fully up. |
| `UpgradeTray.choose_index(index)` | method | Accept one card; refused while sliding in, locked, suspended or closed. |
| `UpgradeTray.is_open()` / `is_settled()` / `get_presented_choice_ids()` / `get_card_rect(i)` | method | State, ids and card rects (tutorial hand, checks). |
| `UpgradeTray.set_bottom_inset(px)` / `set_timeout_share(share)` | method | Layout above the safe margin (+ host lift) / drain the timeout bar. |
| `GameWorld` scripted hooks | methods | `request_upgrade_calm_moment`, `has_upgrade_calm_request`, `get_banked_upgrades`, `is_upgrade_tray_open/settled`, `get_upgrade_card_rect`, `choose_upgrade_card`, `set_upgrade_tray_lift` ([tutorial.md](tutorial.md)). |
| `SoulShardPickup.collected(amount)` | signal | Report one collected Rift Points reward. |
| `SoulShardPickup.configure(target, radius, width)` | method | Supply attraction target/radius and viewport scale. |
| `SoulShardPickup.set_attraction_radius(radius)` | method | Refresh Soul Hunger's live pull distance. |
| `SoulShardPickup.try_dash_collect(from, to, radius)` | method | Resolve swept pickup collection. |
| `SoulShardPickup.sweep_to(target, seconds)` / `collect_now()` | method | Auto-collect sweep and instant collect ([rush_mode.md](rush_mode.md)); both collect through `collected` once. |

## Data & tuning

All seven tray mutations have supplied icons, concise next-value copy and sensible caps. (SOUL
VESSEL was the eighth; since 2026-09-19 its effect is the Soul Vessel *pickup* instead — see
[player_health.md](player_health.md) — because a card capped at three levels cannot express an
uncapped fragment count.) XP threshold
uses a rising Resource-defined curve (`base_xp_threshold` 30, `xp_growth` 1.32).
`RunProgressionTuning` group **Upgrade offer** (starting values, tune on device): `tray_time_scale`
0.3, `tray_timeout` 6.0 real s, `tray_slide_seconds` 0.22 real s, `calm_window_seconds` 4.0 game s,
`indicator_pulse_rate` 1.2 Hz, `indicator_pulse_amount` 0.3. Layout constants (`HUD_UPGRADE_READY_TOP`,
tray side margin) stay in code.

## Dependencies

GameWorld translates mutation levels into Wisp/enemy/hazard effects and owns run statistics.

## Rules & behaviour

- **Owner decision 2026-09-15 (GDD §5.5): level-ups never interrupt.** XP past a threshold banks the
  level (several can bank); nothing pauses. A tappable `%UpgradeButton` (IconButton, 11_upgrades icon, "UPGRADE"
  caption, amber ×N, gentle pulse) sits under the pause button while a level is banked; tapping it opens
  the tray immediately (`_on_upgrade_button_pressed`). The tray is just the cards and a timeout bar.
- **Calm moments** (`GameWorld._mark_calm_moment`): a wave starting (not a boss wave), a boss beaten
  (when its victory beat ends, `_update_post_boss`), and a kill that leaves the field clear of regular
  enemies (`_is_field_clear`). Each gets a new id and a `calm_window_seconds` window. Inside it the tray
  opens once everything holds (`_is_upgrade_calm`): a level banked; free play (a tutorial lesson only
  through `request_upgrade_calm_moment`); no boss pending, alive or in its victory beat; RUSH off; not
  paused; run not over; the Wisp `WAITING_AT_EDGE`; `_combo == 0`. A moment whose cards were shown
  is spent: after a dismiss the cards return only at the next calm moment.
- **Card tray, no pause.** `UpgradeTray` slides up above the bottom safe margin (`tray_slide_seconds`,
  real time; instant under Reduced Motion) with three distinct non-capped `CardButton` cards and a
  draining timeout bar, and plays `level_up`. While it is up GameWorld holds
  `_hold_time_scale(&"upgrade_tray", tray_time_scale)` ([rush_mode.md](rush_mode.md)); Reduced Motion
  keeps normal speed. Enemies and hazards still move and hurt; a hit does not dismiss the tray.
- **Tap a card** → `RunProgression.apply_choice` once (`upgrade_choice` sound, `upgrade_chosen`); if
  more are banked the next three slide in at once with a fresh timeout, otherwise the tray slides away
  and the hold is released. Picks are refused while cards slide in, so a double tap cannot take a card
  from the next set.
- **Keep playing** → any dash (`dash_started`, a swipe outside the tray) closes the tray and releases
  the hold; the level stays banked. The tray root ignores the mouse and its panel stops touches, so a
  card tap never reaches the Wisp and an arena swipe never presses a card (Buttons need press and
  release on the card). Cards never take keyboard focus, so Space (dash) cannot pick one.
- **Timeout** → after `tray_timeout` real seconds (counted in `_process` as `delta / time_scale`) the
  tray slides away, level banked. **Pause / interruption** hide the tray (`set_suspended`), stop its
  timeout and drop the hold; Resume shows it again and re-holds. **Boss start**, a tutorial arena reset
  and **run end** close it (instant at run end); scene exit and `_reset_view_effects` drop the hold.
  A pending boss waits for an open tray to close (≤ timeout).
- Banked but unpicked levels are lost at run end; the summary's `run_level` counts only picked levels,
  so Results and Trials stay correct. Same rules in story Rift levels, Endless and the daily run.
- RUSH never starts and finishers never play while the tray is up.
- Wide Reap, Soul Hunger, Death Pulse, Soul Link, Cold Wake, Void Velocity and
  Reaper's Gift all change live run behavior; nothing persists between runs — mutations are the only
  run power, and there is no permanent power (ADR-0013).
- Rift Points remain separate from score and are reported by Results. Soul Hunger's copy reads
  "stronger pickup pull".
- **Soul Hunger still matters mid-wave** (2026-09-15): the auto-collect sweep only runs at wave start,
  boss start, boss defeat and run end, so during a wave shards still wait on the floor (14 s lifetime)
  and Soul Hunger's wider pull is what gathers them before they fade or while the Wisp keeps dashing.

## How to test

- Run `tools/godot/test_run_progression.gd` for threshold/choice rules and
  `tools/godot/test_mutation_effects.gd` for all seven live effects and the Soul Vessel drop.
- Manual (device, owner preference): bank two levels mid-combo (pill ×2, no interruption); stop at a
  wave start (cards slide up, world slow); tap one (next set slides in), swipe the arena on the second
  (tray away, pill ×1); wait out 6 s once; pause with the tray up; repeat with Reduced Motion.
  Logs: `[GameWorld] level banked`, `calm moment | reason=`, `upgrade tray open|closed | reason=`.
- Visual: `tools/godot/render_upgrade_showcase.gd` (command in its header).
- Automated: none (owner preference 2026-09-15). A temporary headless smoke (52 checks, deleted)
  covered banking, calm-moment opening, slow motion, pick/next set, swipe, timeout, pause, boss, RUSH,
  Reduced Motion, scene exit and the tutorial lesson. The stale `test_run_progression.gd` /
  `test_gameplay_slice.gd` were only pointed at `UpgradeTray`.

## Known issues / TODO

- Cross-run currency/best persistence arrives with SaveManager in Milestone 3.
- Starting values need the device pass: whether 0.3 slow motion reads as "not a safe pause", whether
  6 s is long enough, and whether a constantly dashing player in Endless (continuous refill, rare field
  clears) sees the cards often enough.
- The tray covers the bottom ~27 % of the screen; a Wisp resting on the bottom wall sits behind it
  (swipes from elsewhere still dash). Desktop hover shows the magenta highlight; touch never does.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Tray simplified: no header text or frame, UPGRADE READY pill removed (owner) |
| 2026-09-15 | Banked level-ups, calm moments, bottom `UpgradeTray` with slow motion, swipe/timeout dismiss, UPGRADE READY pill; paused `UpgradeSelect` removed (owner decision, GDD §5.5) |
| 2026-09-15 | Pickup auto-collect sweep (`sweep_to`, `collect_now`); Soul Hunger's mid-wave role noted (spec rush_and_feel) |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-19 | SOUL VESSEL left the tray: it is a rare world pickup now, so the fragment count has no cap. Seven cards remain |
| 2026-09-11 | Implemented XP, safe three-card choices, eight effects, drops and run statistics |
| 2026-09-11 | Planned for Milestone 2 |
