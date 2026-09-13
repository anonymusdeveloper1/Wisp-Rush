# System: Game flow

> **Status:** ✅ done · **Last updated:** 2026-09-13 · **GDD section:** §11

## Purpose

Own the active top-level screen without global state: boot Loading → Home and every Home
destination, the run, Results, and consistent back handling. Screens only emit intent.

## Files

| Path | Role |
|---|---|
| `res://scenes/main/main.tscn` / `main.gd` | Composition root: screen replacement, back routing, app-lifecycle music duck, debug overlay |
| `res://scenes/screens/loading_screen.*` | Boot: threaded scene streaming and audio readiness |
| `res://scenes/screens/home_screen.*` | Home: top bar, logo, animated hero Wisp, PLAY + Rift caption, bottom navigation bar |
| `res://scenes/screens/home_ambience.gd` | `HomeAmbience`: living background (brazier flicker, rune pulse, mist, rising motes) |
| `res://scenes/screens/orbit_motes.gd` | `OrbitMotes`: soul sparks orbiting the hero; a back and a front instance give depth |
| `res://scenes/screens/results_screen.*` | Run summary: Rush Again (primary), Return Home, Wisp Forms |
| Forms / Rift Map / Daily / Sanctum / Trials / Statistics / Settings | See [forms.md](forms.md), [rifts.md](rifts.md), [challenges.md](challenges.md), [meta_progression.md](meta_progression.md), [settings.md](settings.md) |

## Scene / node structure

```text
Main (Node)
└── exactly one: LoadingScreen, HomeScreen, FormsScreen, RiftMapScreen, DailyScreen, SanctumScreen,
    TrialsScreen, StatisticsScreen, SettingsScreen, GameWorld or ResultsScreen
/root/DebugOverlay (debug builds only)

HomeScreen (Control)
├── Background (home_background) · Ambience (HomeAmbience) · BottomShade (gradient behind PLAY/nav)
└── ContentMargin (base margins + device safe area) → Content (VBox)
    ├── TopBar: ShardsPlate · BestPlate · spacer · StatsButton · SettingsButton (IconButton)
    ├── Logo
    ├── HeroArea: HeroPocket · HeroGlow · OrbitBack · WispPreview · OrbitFront
    ├── RiftCaption (CaptionLabel) · PlayButton (PrimaryButton)
    └── NavBar (NavBar) → NavRow: RiftsNav · FormsNav · SanctumNav · TrialsNav · DailyNav (NavButton)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `LoadingScreen.finished(resources)` | signal | Boot resources ready; Main shows Home. |
| `HomeScreen.play/forms/daily/rift_map/sanctum/trials/statistics/settings_requested` | signals | Home destinations. |
| `HomeScreen.setup(snapshot, equipped_form)` | method | Best, shards, equipped form, Reduced Motion and the Rift PLAY enters. |
| `HomeScreen.get_orbits()` / `is_animating()` / `get_rift_caption()` | methods | Test helpers: orbit halves, motion state, caption text. |
| `GameWorld.home_requested` / `restart_requested` / `run_ended(summary)` | signals | Leave, restart or finish a run. |
| `ResultsScreen.restart/home/forms_requested` | signals | Post-run navigation. |
| `handle_back() -> bool` | optional method | A screen consumes back first (GameWorld, SettingsScreen). |

## Data & tuning

`Main.SCREEN_PATHS` lists every streamed screen; Loading stops waiting after 6 s.

## Dependencies

SaveManager (snapshot, runs, forms, challenges), Audio via `SoundFx` (music state, UI clicks),
ChallengeTracker, FormCatalog. The run: [core_run.md](core_run.md), [game_feel.md](game_feel.md).

## Rules & behaviour

- Every screen is styled only through the project Theme's type variations ([ui_design_system.md](ui_design_system.md)); Home uses `home_background.png`, the Rift Map the focused arena, every other menu `menu_background.png`.
- **Home layout** (owner decision 2026-09-13; minimal, Material-like, stone-and-cyan): slim top bar
  (shards, best, Statistics, Settings), logo, the equipped Wisp in the middle, one PLAY with a
  caption naming the Rift it enters (`<RIFT>  •  LEVEL n`, or `•  ENDLESS` once all levels are
  cleared), and a bottom navigation bar. PLAY starts a run in the saved `selected_rift`.
- **Bottom nav → signal:** RIFTS → `rift_map_requested`, FORMS → `forms_requested`, SANCTUM →
  `sanctum_requested`, TRIALS → `trials_requested`, DAILY → `daily_requested`.
- **Home motion:** the Wisp floats, breathes and sways and its glow (form tint) pulses; soul sparks
  orbit it, passing behind and in front of the body; `HomeAmbience` adds brazier flicker, rune
  pulse, drifting mist and rising motes anchored to the painted art (art unchanged). No entrance
  animation and no PLAY pulse. Reduced Motion stills all of it (resting pose, orbit and motes hidden).
- **Card pickers:** Forms and Rift Map are portrait carousels (`FocusCarousel`, see
  [ui_design_system.md](ui_design_system.md)): swipe to browse, tap a side card to focus it, tap
  the focused card = the screen's main button. Details in [forms.md](forms.md) and [rifts.md](rifts.md).
- Main owns screen lifetime; replacing a screen frees the old one, binds UI click sounds and press
  feedback (`UiJuice`) and fades the new screen in from a dark veil (0.22 s, internal child).
- Back (Android) / Escape: the screen's `handle_back()` first, otherwise Home; on Home, mobile quits.
- Returning Home clears the tree pause state and calms the music.
- Run end records the run and challenge rewards in SaveManager before Results appears.
- Restart reuses cached scenes, so a new run starts without a loading delay.
- No visible button is inert.

## How to test

- `test_game_flow.gd`, `test_main_progression_flow.gd` (boot through Loading → Home → flows).
- `test_menu_screens.gd`: Home nav signals, Rift caption, hero motion and Reduced Motion; Rift Map
  gating and ENTER; Forms carousel selection and tap-to-act.
- Phone layouts: `tools/qa_matrix.sh home forms rifts rifts_locked`.
- Manual: every Home destination and back path with Escape (desktop) and back (Android).

## Known issues / TODO

- None known.

## Change history

| Date | Change |
|---|---|
| 2026-09-13 | Home rebuilt: top bar, animated hero + living background, PLAY with Rift caption, bottom nav |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Fade-in transitions, press feedback, versioned Home footer (Milestone 5 polish) |
| 2026-09-11 | Loading boot, Statistics/Settings destinations, back routing, Results Forms (Milestone 4) |
| 2026-09-11 | Expanded Results and added session best-score/Soul-Shard accumulation |
| 2026-09-11 | Added Results summary, fast restart and session-local tutorial gating |
| 2026-09-11 | Implemented and verified Home → Play → Pause/Resume/Home flow |
| 2026-09-11 | Planned from owner prompt v2 |
