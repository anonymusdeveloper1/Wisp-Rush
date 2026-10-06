# System: Settings, statistics and boot screens

> **Status:** ✅ done · **Last updated:** 2026-09-25 · **GDD section:** §11 (prompt §18, §26)

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
├── Margin/Content
│   ├── Header (Back, title, badge) — fixed, does not scroll
│   └── %Scroll (ScrollContainer, vertical only, no scroll bar) → Body
│       ├── %Groups: AudioCard (Music/SFX) · FeelCard (Shake slider; Haptics, Aim Arrow, Aim Assist,
│       │   Reduced Motion toggles) · MoreCard (Privacy & About, Replay Tutorial, Reset Progress) ·
│       │   DEVELOPER card (debug builds, built in code)
│       └── %FeedbackLabel
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
- Everything under the header scrolls (`%Scroll`, vertical only, since 2026-09-25); the header stays
  put, and no scroll bar is drawn (`vertical_scroll_mode` SHOW_NEVER; owner, 2026-09-25). Cards and buttons use mouse filter Pass, so a touch swipe that starts on them scrolls and does
  not press the button. `_show_feedback` scrolls the feedback line (ALL PROGRESS ERASED, developer
  APPLIED / REFUSED) into view.
- Every change goes through SaveManager, which clamps, saves and emits `settings_changed`.
- Sliders preview volume live and save after 0.35 s at rest (and on exit); toggles save at once.
- Reset needs the panel plus a 1.5 s disarmed countdown; Cancel is focused; hidden in a run.
- **AIM ARROW** (caption "Show the dash path and lit targets"): the arrow, the path line and the lit
  enemies of the aim preview. **AIM ASSIST** (owner decision 2026-09-15, "Gently bends a dash into
  more enemies"): the release-time ±6° bend ([player_dash.md](player_dash.md)); independent of AIM ARROW.
- REPLAY TUTORIAL (MORE card, Home-level only like RESET PROGRESS) emits `tutorial_requested`; Main opens the Tutorial and returns Home. Back since 2026-09-24, when the Rift Map, which held the only replay, left the first release; the Rifts were removed on 2026-09-25 ([tutorial.md](tutorial.md)).
- Privacy copy (corrected 2026-10-05, ADR-0030): plays offline; ads from Google AdMob with Google's
  consent form; purchases through Google Play; progress on the device and, when signed in to Google
  Play Games, on the Google account; Reset Progress erases them.
- **CLOUD SAVE card** (Home-level, only on a build with a cloud; [cloud_save.md](cloud_save.md)):
  ON, or OFF with SIGN IN WITH GOOGLE PLAY GAMES; it follows `CloudSave.state_changed`.
- Loading never stays longer than 6 s — anything unfinished then loads synchronously.

## How to test

- `tools/godot/test_m4_systems.gd`: clamping, persistence, debounce, reset arming, stats rows.
- Flow tests boot through Loading → Home.

## Known issues / TODO

- Revisit About credits once the art licence is confirmed (GDD §14 #1).
- A vertical swipe that starts on a slider (Music, Sound FX, Screen Shake) moves the slider instead
  of scrolling (measured 2026-09-25 with simulated touch input); the owner keeps it that way
  (2026-09-25).

## Change history

| Date | Change |
|---|---|
| 2026-10-05 | The CLOUD SAVE card and the corrected privacy text (owner, GDD §14 #84, ADR-0030) |
| 2026-09-25 | The scroll bar is hidden (owner); swiping still scrolls. The touch pass-through stays and a swipe on a slider keeps moving the slider (owner) |
| 2026-09-25 | Developer-card section brought up to date: four actions (owner) |
| 2026-09-25 | Settings scrolls (owner): fixed header, `%Scroll` → Body (cards, feedback line); cards and buttons pass touches to the scroll; feedback scrolls into view. Developer UNLOCK EVERYTHING tooltip reads "Forms, Trials and Rift Points"; statistics row TIME IN THE RIFT → TIME PLAYED |
| 2026-09-25 | Story Rifts removed (owner): the developer UNLOCK ALL RIFTS action removed |
| 2026-09-15 | AIM ASSIST toggle (`aim_assist`, default ON); AIM ARROW caption now covers the path and lit targets |
| 2026-09-15 | REPLAY TUTORIAL removed (Tutorial screen is replayed from the Rift Map) |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Created and verified in Milestone 4 |

## Developer card (debug builds only)

Settings appends a **DEVELOPER** card built in `_build_developer_card()` with four actions: UNLOCK
EVERYTHING (characters, Trials and Rift Points in one go, `DevUnlock.unlock_everything`), UNLOCK ALL
CHARACTERS (`unlock_forms`), COMPLETE ALL TRIALS (`complete_trials`) and +5,000 RP
(`grant_rift_points`, `RP_GRANT`). The Sanctum action went with the Sanctum (2026-09-15) and UNLOCK
ALL RIFTS with the story Rifts (2026-09-25). It exists so features gated behind progression can be reached without playing to them.

It is gated twice, because GDD §13 forbids debug panels in a release:

1. The card is only built when `SaveManagerService.debug_tools_allowed()` is true, which is
   `OS.is_debug_build()`.
2. Every `SaveManagerService.debug_*` method independently refuses to act in a release build, so
   even a caller that bypassed the UI would change nothing.

`tools/run_tests.sh dev_unlock` asserts what each action unlocks, that null saves are refused, and that exactly one developer card is present in a debug build. It is stale today: it still calls the removed `DevUnlock.get_unlock_wave`, so it does not parse.
