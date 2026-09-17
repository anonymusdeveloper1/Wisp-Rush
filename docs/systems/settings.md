# System: Settings, statistics and boot screens

> **Status:** ✅ done · **Last updated:** 2026-09-15 · **GDD section:** §11 (prompt §18, §26)

## Purpose

Player settings (music, SFX, screen shake, haptics, reduced motion, Privacy &
About, reset progress), lifetime statistics, and the boot Loading screen.

## Files

| Path | Role |
|---|---|
| `res://scenes/screens/settings_screen.tscn` / `.gd` | Settings, About panel, armed reset panel; Home screen or in-run overlay |
| `res://scenes/screens/statistics_screen.tscn` / `.gd` | Lifetime statistics grid built from the save snapshot |
| `res://scenes/screens/loading_screen.tscn` / `.gd` | Pulsing soul-core boot screen, threaded scene streaming |
| `res://scripts/autoload/save_manager.gd` | `get_settings`, `update_settings`, `settings_changed`, guarded `debug_*` unlocks |
| `res://scripts/utils/dev_unlock.gd` | `DevUnlock` — debug-only progression unlocks used by the developer card |

## Scene / node structure

```text
SettingsScreen (process mode Always)
├── Header (Back, title) · AudioCard (Music/SFX) · FeelCard (Shake slider; Haptics, Aim Arrow,
│   Aim Assist, Reduced Motion toggles)
├── Privacy & About · Reset Progress · FeedbackLabel
├── AboutPanel (hidden) · ResetPanel (hidden)
StatisticsScreen → Header, emblem, StatsGrid (rows from build_rows)
LoadingScreen → _draw() diamond core, StatusLabel, ProgressBar
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `SettingsScreen.back_requested` / `progress_reset` | signals | Leave; a confirmed reset happened. |
| `SettingsScreen.setup(settings)` / `handle_back()` | methods | Show values; close panels before leaving. |
| `SettingsScreen.allow_progress_reset` | export | False in-run (hides Reset). |
| `StatisticsScreen.setup(snapshot)` / `build_rows(snapshot)` | methods | Display rows: BEST SCORE, HIGHEST WAVE, LONGEST SOUL CHAIN tiles, then RUNS, ENDLESS BEST SCORE / BEST WAVE / RUNS (spec 03), souls, multi-reaps, bosses, time, Rift Points, forms. |
| `LoadingScreen.begin(paths, wait_for_audio)` / `finished(resources)` | method / signal | Boot streaming. |
| `SaveManagerService.update_settings(changes)` / `settings_changed(settings)` | method / signal | Validated persistence. |

## Data & tuning

Save `settings`: `music_volume` 0.8, `sfx_volume` 0.9, `screen_shake` 1.0 (all 0..1), `haptics`
true, `aim_arrow` true, `aim_assist` true, `reduced_motion` false. Bools sanitize to their default when
missing or not a bool, so `aim_assist` needed no schema bump. `SAVE_DELAY` 0.35 s, `RESET_ARM_SECONDS` 1.5 s, Loading
`MAX_WAIT_SECONDS` 6 s.

## Dependencies

SaveManager (authority, ADR-0003), Audio (live volume preview), GameWorld (listens to
`settings_changed` for feel).

## Rules & behaviour

- Redesign v1 layout: `PanelCard` groups, ON/OFF toggle buttons, amber `DangerButton` for the armed reset; Loading draws the soul core on void charcoal.
- Every change goes through SaveManager, which clamps, saves and emits `settings_changed`.
- Sliders preview volume live and save after 0.35 s at rest (and on exit); toggles save at once.
- Reset needs the panel plus a 1.5 s disarmed countdown; Cancel is focused; hidden in a run.
- **AIM ARROW** (caption "Show the dash path and lit targets"): the arrow, the path line and the lit
  enemies of the aim preview. **AIM ASSIST** (owner decision 2026-09-15, "Gently bends a dash into
  more enemies"): the release-time ±6° bend ([player_dash.md](player_dash.md)); independent of AIM ARROW.
- No tutorial replay here since 2026-09-15: the Tutorial is replayable only from the Rift Map ([tutorial.md](tutorial.md)).
- Privacy copy: offline, no accounts, ads, analytics or tracking; data stays on the device.
- Loading never stays longer than 6 s — anything unfinished then loads synchronously.

## How to test

- `tools/godot/test_m4_systems.gd`: clamping, persistence, debounce, reset arming, stats rows.
- Flow tests boot through Loading → Home.

## Known issues / TODO

- Revisit About credits once the art licence is confirmed (GDD §14 #1).
- In a debug build the DEVELOPER card makes the screen taller than most phone views (min height
  2,473 px measured 2026-09-15 with AIM ASSIST, ~2,366 before; ~1,780 px without the card) and there
  is no scroll container, so the bottom clips on 2,338–2,400 px-tall phones in the debug APK.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | AIM ASSIST toggle (`aim_assist`, default ON); AIM ARROW caption now covers the path and lit targets |
| 2026-09-15 | REPLAY TUTORIAL removed (Tutorial screen is replayed from the Rift Map) |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Created and verified in Milestone 4 |

## Developer card (debug builds only)

Settings appends a **DEVELOPER** card built in `_build_developer_card()` with five actions: unlock
everything, unlock all Rifts, unlock all forms, complete all Trials, and grant 5,000 Rift Points
(`DevUnlock.grant_rift_points`, `RP_GRANT`); the Sanctum action went with the Sanctum (2026-09-15). It exists so features gated behind progression can be reached without playing to them.

It is gated twice, because GDD §13 forbids debug panels in a release:

1. The card is only built when `SaveManagerService.debug_tools_allowed()` is true, which is
   `OS.is_debug_build()`.
2. Every `SaveManagerService.debug_*` method independently refuses to act in a release build, so
   even a caller that bypassed the UI would change nothing.

`tools/run_tests.sh dev_unlock` asserts what each action unlocks, that null saves and unknown rift
ids are refused, and that exactly one developer card is present in a debug build.
