# System: Game flow

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §11

## Purpose

Own the active top-level screen without global state: boot Loading → Home and every Home
destination, the run, Results, and consistent back handling. Screens only emit intent.

## Files

| Path | Role |
|---|---|
| `res://scenes/main/main.tscn` / `main.gd` | Composition root: screen replacement, back routing, app-lifecycle music duck, debug overlay |
| `res://scenes/screens/loading_screen.*` | Boot: threaded scene streaming and audio readiness |
| `res://scenes/screens/home_screen.*` | Home: Play, Forms, Daily Rift, Stats, Settings |
| `res://scenes/screens/results_screen.*` | Run summary: Rush Again (primary), Return Home, Wisp Forms |
| Forms / Daily / Statistics / Settings | See [forms.md](forms.md), [challenges.md](challenges.md), [settings.md](settings.md) |

## Scene / node structure

```text
Main (Node)
└── exactly one: LoadingScreen, HomeScreen, FormsScreen, DailyScreen, StatisticsScreen,
    SettingsScreen, GameWorld or ResultsScreen
/root/DebugOverlay (debug builds only)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `LoadingScreen.finished(resources)` | signal | Boot resources ready; Main shows Home. |
| `HomeScreen.play/forms/daily/statistics/settings_requested` | signals | Home destinations. |
| `GameWorld.home_requested` / `restart_requested` / `run_ended(summary)` | signals | Leave, restart or finish a run. |
| `ResultsScreen.restart/home/forms_requested` | signals | Post-run navigation. |
| `handle_back() -> bool` | optional method | A screen consumes back first (GameWorld, SettingsScreen). |

## Data & tuning

`Main.SCREEN_PATHS` lists every streamed screen; Loading stops waiting after 6 s.

## Dependencies

SaveManager (snapshot, runs, forms, challenges), Audio via `SoundFx` (music state, UI clicks),
ChallengeTracker, FormCatalog. The run: [core_run.md](core_run.md), [game_feel.md](game_feel.md).

## Rules & behaviour

- Every screen is styled only through the project Theme's type variations ([ui_design_system.md](ui_design_system.md)); Home uses `home_background.png`, every other menu `menu_background.png`.
- Main owns screen lifetime; replacing a screen frees the old one, binds UI click sounds and press
  feedback (`UiJuice`) and fades the new screen in from a dark veil (0.22 s, internal child).
- Back (Android) / Escape: the screen's `handle_back()` first, otherwise Home; on Home, mobile quits.
- Returning Home clears the tree pause state and calms the music.
- Run end records the run and challenge rewards in SaveManager before Results appears.
- Restart reuses cached scenes, so a new run starts without a loading delay.
- No visible button is inert.

## How to test

- `test_game_flow.gd`, `test_main_progression_flow.gd` (boot through Loading → Home → flows).
- Manual: every Home destination and back path with Escape (desktop) and back (Android).

## Known issues / TODO

- None known.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Fade-in transitions, press feedback, versioned Home footer (Milestone 5 polish) |
| 2026-09-11 | Loading boot, Statistics/Settings destinations, back routing, Results Forms (Milestone 4) |
| 2026-09-11 | Expanded Results and added session best-score/Soul-Shard accumulation |
| 2026-09-11 | Added Results summary, fast restart and session-local tutorial gating |
| 2026-09-11 | Implemented and verified Home → Play → Pause/Resume/Home flow |
| 2026-09-11 | Planned from owner prompt v2 |
