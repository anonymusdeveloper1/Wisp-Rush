# System: Game flow

> **Status:** ✅ done · **Last updated:** 2026-10-05 · **GDD section:** §11
>
> **Changed 2026-09-25:** the story Rifts are removed (owner): no Rift Map, no story runs, no level
> Results. Endless and the daily run are the only runs. Older Rift routes below are marked history.

## Purpose

Own the active top-level screen without global state: boot Loading → Tutorial (first launch) or Home
and every Home destination, the run, Results, and consistent back handling. Screens only emit intent.

## Files

| Path | Role |
|---|---|
| `res://scenes/main/main.tscn` / `main.gd` | Composition root: screen replacement, back routing, app-lifecycle music duck, debug overlay |
| `res://scenes/screens/loading_screen.*` | Boot/PLAY: threaded streaming, progress and a random character/boss loading illustration |
| `res://scenes/tutorial/tutorial_screen.*` | Tutorial screen ([tutorial.md](tutorial.md)): first launch and the Settings replay |
| `res://scenes/screens/home_screen.*` | Home: top bar, pixel-art logo, equipped character over an empty central dais between two button columns, caption + animated PLAY under it |
| `res://scenes/screens/home_ambience.gd` | `HomeAmbience`: living background (brazier flicker, rune pulse, mist, rising motes) |
| `res://scenes/screens/orbit_motes.gd` | `OrbitMotes`: soul sparks orbiting the hero; a back and a front instance give depth; `get_extent_ratio()` bounds them |
| `res://scenes/screens/results_screen.*` | Run summary and Rift Points breakdown: PLAY AGAIN (primary), RETURN HOME |
| `res://scripts/utils/rift_points.gd` | `RiftPoints`: `1,250 RP` / `+45 RP` formatting shared by every currency label |
| Forms / Daily / Trials / Shop / Statistics / Settings | See [forms.md](forms.md), [challenges.md](challenges.md), [meta_progression.md](meta_progression.md), [monetisation.md](monetisation.md), [settings.md](settings.md) |

## Scene / node structure

```text
Main (Node)
└── exactly one: LoadingScreen, TutorialScreen, HomeScreen, ShopScreen, DailyScreen,
    TrialsScreen, StatisticsScreen, SettingsScreen, GameWorld or ResultsScreen
    (+ internal CanvasLayers: NavigationVeil 100 and LoadingCover 99, which holds the run loading
    screen while a held GameWorld prewarms as get_child(0))
/root/DebugOverlay (debug builds only)

HomeScreen (Control)
├── Background (home_background) · Ambience (HomeAmbience) · BottomShade (fade from above the caption)
└── ContentMargin (base margins + device safe area) → Content (VBox)
    ├── TopBar: RiftPointsPlate (icon · %RiftPointsLabel · "RP") · BestPlate · spacer · StatsButton ·
    │   SettingsButton (IconButton)
    ├── Logo
    └── HeroArea (fills the rest; children placed in code by _layout_hero)
        ├── HeroPocket · HeroGlow · OrbitBack · WispPreview (tap → Forms) · OrbitFront
        ├── LeftColumn: TrialsButton · DailyButton   (IconButton + Icon + Caption)
        ├── RightColumn: ShopButton · RemoveAdsButton (AdGlyph + RemoveAdsStrike + Caption)
        └── ActionBlock: PlayCaption · ActionRow: PlayButton (PlayGlow, PlaySheenClip → PlaySheen)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `LoadingScreen.finished(resources)` | signal | Boot resources ready; Main shows the Tutorial (save `tutorial_completed` false) or Home. |
| `TutorialScreen.finished(skipped)` / `SettingsScreen.tutorial_requested` | signals | Main marks the tutorial completed and goes Home / opens a replay. |
| `HomeScreen.play/wisps/daily/trials/statistics/settings/shop/remove_ads_requested` | signals | Home destinations: `wisps_requested` (tap on the hero character) → Shop CHARACTERS, `shop_requested` → last Shop tab, `remove_ads_requested` → Shop NO ADS. |
| `HomeScreen.setup(snapshot, equipped_form)` | method | Best, Rift Points, equipped form, Reduced Motion, `ads_removed` and the Endless best wave for PLAY's caption. |
| `HomeScreen.get_orbits()` / `is_animating()` / `get_play_caption()` / `get_hero_motion_rect()` | methods | Test helpers: orbit halves, motion state, caption text, bounds of every hero animation. |
| `ShopScreen.setup(rift_points, ads_removed, store_available)` / `show_feedback()` / `can_buy()` | methods | See [monetisation.md](monetisation.md). |
| `GameWorld.home_requested` / `restart_requested` / `run_ended(summary)` | signals | Leave, restart or finish a run. |
| `ResultsScreen.restart/home/wisps_requested` | signals | Post-run navigation; `restart_requested` replays the same profile; `wisps_requested` opens Shop CHARACTERS, whose Back re-shows these Results (its button is hidden today). |
| `ResultsScreen.setup(summary)` / `get_displayed_rp_total()` / `get_primary_text()` | methods | Run values plus `rp_collected`, `rp_performance`, `rp_rewards`, `rp_earned`, `rift_points_total`, and Main's `mode`, `arena_name`, `best_score`, `depth_reward`; test helpers. |
| `handle_back() -> bool` | optional method | A screen consumes back first (GameWorld, SettingsScreen, TutorialScreen → skip confirm). |

## Data & tuning

`Main.SCREEN_PATHS` lists every streamed screen; Loading stops waiting after 6 s. Rift Points
payouts: [shop.md](shop.md).

## Dependencies

SaveManager (snapshot, runs, forms, challenges), Audio via `SoundFx` (music state, UI clicks),
ChallengeTracker, FormCatalog. The run: [core_run.md](core_run.md), [game_feel.md](game_feel.md).

## Rules & behaviour
- Every screen is styled through the project Theme's type variations ([ui_design_system.md](ui_design_system.md)). Home uses `home_background.png`; Shop, Daily Run, Trials and Results use their dedicated nearest-filtered pixel-art images in `assets/art/environment/menu_screens/` ([source pack](../../concept_art/menu_backgrounds_v1/README.md)). Other menus retain `menu_background.png`.
- **Home layout** (owner decision 2026-09-13, GDD §11; the bottom navigation bar is gone): top bar
  (Rift Points, best, Statistics, Settings) and logo; the equipped character above the central stone dais — **tap it for
  Shop CHARACTERS**; left column TRIALS · DAILY (the SANCTUM button went with the Sanctum, ADR-0013), right
  column SHOP · NO ADS; under the Wisp the
  caption `ENDLESS` / `ENDLESS  •  BEST WAVE n` and a large PLAY (560 px min, 66 px text), centred
  on its own. BEST shows `endless_best_score`. (Owner 2026-09-15: PLAY = Endless; no ENDLESS
  button. Owner 2026-09-24: the RIFTS button and its `ActionBalance` slot are gone and PLAY sits
  lower — see `ACTION_DROP` below. Owner 2026-09-25: the story Rifts are removed.)
- **Tutorial routes** (owner decision 2026-09-15): after Loading, a save with `tutorial_completed` false
  opens the Tutorial instead of Home; finishing or skipping calls `mark_tutorial_completed()` and goes
  Home. Afterwards the entry is Settings → REPLAY TUTORIAL (`SettingsScreen.tutorial_requested`,
  Home-level Settings only), which returns Home. Main builds `RunProfile.tutorial` on the
  `TutorialCatalog.arena_skin_id` skin with the equipped form. The Tutorial never glides in.
- **Run routes**: Main builds every `RunProfile`. PLAY → `endless` profile (always open; equipped
  arena, every enemy mix and boss from `EndlessCatalog`). Real runs never teach. DAILY → `daily`
  profile (daily pool, arena of the day). Restart (pause menu or Results) replays the same profile.
  (History: story runs — Rift Map ENTER, Results' NEXT LEVEL / ENTER <RIFT> / RETRY — were removed with
  the Rifts on 2026-09-25.)
- **Buttons → signal:** TRIALS → `trials_requested`, DAILY → `daily_requested`, SHOP →
  `shop_requested`, NO ADS → `remove_ads_requested` (Main opens the
  Shop for both; NO ADS hides once `ads_removed`). `rift_map_requested` was removed with RIFTS.
- **Every character stands centred on the dais** (owner, 2026-09-27, GDD §14 #57): feet on the dais' centre
  (540, 1166 in the 1080 × 1920 design), body centred over it; a whole-frame character's `menu_offset`
  fixes a storefront frame that does not (Rook).
- **Nothing animated passes over a button.** `_layout_hero()` keeps the preview in the empty stage pocket above the dais, shrinks the orbit (`OrbitMotes.get_extent_ratio()`) and glow to the room between the columns
  minus `HERO_SIDE_CLEARANCE` (28), and places the caption + PLAY row `HERO_BOTTOM_CLEARANCE` (64)
  under the lowest animated pixel, then up to `ACTION_DROP` (80) further down, taken only from the free
  space below it, so the hero never shrinks for it. `test_menu_screens.gd` asserts it at 1080×2337 and 1080×1920.
- **Home motion:** the equipped character stays anchored while its authored storefront sprite loop or
  menu video plays; its glow (form tint) pulses and soul sparks orbit behind and in front.
  `HomeAmbience` adds brazier flicker, rune pulse, drifting mist and rising motes aligned to the
  pixel-art stone background. PLAY breathes
  (it owns its press dip, so UiJuice skips it), pulses a cyan glow and sweeps a light band every
  3.4 s. No entrance animation. Reduced Motion stills all of it.
- The Wisp tap is mouse-only (touch arrives emulated), ignores drags past `HERO_TAP_SLOP` and
  cancelled touches, and dips the Wisp while pressed.
- **Card pickers:** the Shop tabs are portrait carousels (`FocusCarousel`, see
  [ui_design_system.md](ui_design_system.md)): swipe to browse, tap a side card to focus it, tap
  the focused card = the screen's main button. Details in [shop.md](shop.md).
- Main owns screen lifetime; replacing a screen binds UI click sounds and press feedback (`UiJuice`)
  and releases the old screen: freed, except **Home, which Main builds once and keeps** (rebuilding
  it cost ~190 ms plus ~190 ms to first draw on a Galaxy S24, on every Back).
- **Cover, then build** (owner report 2026-09-16, supersedes the 2026-09-14 fade-in): no screen is
  built at the tap. Every builder goes through `Main._defer_navigation`: a void-charcoal veil
  (CanvasLayer 100, internal) covers in 0.12 s, the queued builder then runs under it, the new screen
  becomes `get_child(0)`, draws `COVER_DRAW_FRAMES` (2) frames covered (first-draw/pipeline costs land
  behind the veil), and the veil lifts over 0.28 s (ease-out cubic) while the screen glides 90 design
  px — from the right going deeper, from the left returning Home. Rules:
  - One pending request, **latest wins** (a superseded screen is never built); `Main._input` swallows
    presses while a change runs, and back is ignored. `Main.is_navigating()` tells tools a change (or
    a loading screen) is still up.
  - GameWorld and the Tutorial never glide (screen-space arena maths). Every GameWorld Main builds is
    `hold_start()`ed and `PROCESS_MODE_DISABLED` until the reveal starts (`release_start()`): no waves,
    clock, timers, input or focus-loss pause while covered.
  - The step clock takes at most 1/30 s per frame. Reduced Motion: 0.14 s reveal, no glide.
  - `Main.transitions_enabled` is off in headless runs, so tests see instant swaps;
    `test_screen_transitions.gd` turns it on.
- **Run prewarm** (2026-09-16): Home PLAY shows the run loading screen; once its
  art has loaded Main builds and configures the run (bar step 1), moves the loading screen onto the
  internal `LoadingCover` CanvasLayer (99, over the run's HUD) and adds the run held and frozen as
  `get_child(0)` with `GameWorld.warm_up_render()` — one of every enemy kind plus a VFX sprite (step 2),
  lets it draw 3 frames covered (step 3), and only when the bar completes covers with the veil and
  reveals that same run. Nothing is instantiated after the bar. Restart / Results follow-ups / Daily
  build under the veil without a loading screen.
- **Loading screen** (boot and run share it, redesign 2026-09-16): a random portrait pixel-art illustration from
  `LoadingScreen.BACKGROUND_POOL` (five playable characters except Morrow, Grimgrin and the supplied new
  lantern boss; [source pack](../../concept_art/loading_screens_v2/README.md)). Runtime files are generated
  in `assets/art/environment/loading_screens/`, nearest-filtered, shown at once if cached, otherwise
  loaded threaded and faded in over void charcoal, then cover-scaled with the existing slow Ken Burns
  zoom/drift; a
  void-charcoal gradient scrim; the logo with a soft glow in the upper part and, for a run, the
  heading (`ENDLESS` + the arena's name); near the bottom `LOADING...` with animated dots
  over a full-width standard `ProgressBar`. Reduced Motion stills the drift, breath and dots. The bar
  counts threaded loads + audio (boot) or loads + `RUN_PREWARM_STEPS` host steps (run), at least 0.9 s
  for a run.
- Debug builds log each switch: `[Main] switch <Screen> | build … · tap to revealed … · worst frame …
  · worst of next 20 …`, and `[Main] run prewarm | build … · add+ready+warm …`.
  (logcat on device) — use it to find navigation hitches.
- Back (Android) / Escape: the screen's `handle_back()` first, otherwise Home; on Home, mobile quits.
- Returning Home clears the tree pause state and calms the music.
- Run end records the run and challenge rewards in SaveManager before Results appears.
- **Results outcome:** banner `WAVE w`, `ENDLESS  •  <ARENA>` / `DAILY RUN  •  <ARENA>`, best = Endless
  best / today's daily best, a `DEPTH REWARD` banner when one paid, primary **PLAY AGAIN**, secondary
  RETURN HOME. (History: a Rift level showed `LEVEL n CLEARED` / `FAILED`, unlock banners and
  ENTER <NEW RIFT> / NEXT LEVEL / RETRY.)
- **Results Rift Points** (spec 01): RP COLLECTED (`rp_collected`: pickups, multi-reaps, bosses),
  PERFORMANCE (`rp_performance` = score ÷ `EconomyTuning.score_per_rift_point`), REWARDS
  (challenges + Trials + depth milestones), then TOTAL and the new BALANCE. `record_run` adds collected
  + performance; each reward arrives through its own SaveManager call. Main measures the balance
  before and after all of them and shows that change as TOTAL, so the balance rises by exactly what
  Results displays (`test_main_progression_flow.gd`).
- Currency text follows one rule: `RP` after numbers (`1,250 RP`), "Rift Points" in sentences,
  shard icon kept (`RiftPoints`, `test_rift_points_text.gd`).
- Restart reuses cached scenes, so a new run starts without a loading delay.
- No visible button is inert.

## How to test

- `test_game_flow.gd`, `test_main_progression_flow.gd` (mark the tutorial completed, then boot through
  Loading → Home → flows). Tutorial routing: manual (fresh save → Tutorial → Home; Settings → REPLAY
  TUTORIAL → Home).
- `test_rift_points_text.gd`: no player-facing "shard" text outside the Shard Wraith; RP on Home,
  Shop, Results and the HUD.
- `test_menu_screens.gd` is currently stale: it still references the removed Forms screen and old
  Shop setup signature, so it cannot parse. `test_main_progression_flow.gd` covers Home → Shop
  (both entries) → back.
- Phone layouts: `tools/qa_matrix.sh home`; `qa_capture.gd` builds Home directly from the sample
  snapshot, with `WISP_CHARACTER=<id>` selecting the preview character. Check all five GDD §12
  phone sizes for the full logo, top bar, central dais and unobstructed buttons.
- Manual: every Home destination and back path with Escape (desktop) and back (Android).

## Known issues / TODO

- **`tools/validate.sh` fails intermittently on a headless Windows run** with
  `Initializing already initialized RID` / `Parameter "shader" is null` from
  `loading_screen.gd` `_update_motion`. It is the dummy renderer racing the Ken Burns pan's
  texture, not a project error — it clears on a re-run and never appears with a real window.
  Seen twice on 2026-09-19. Re-run before investigating.

- **The first boot after a cold `--import` logs `Parse Error` on a handful of resources** —
  `home_screen.tscn` and two or three `.tres` files (Rift data at the time), always on the line that
  resolves `script = ExtResource(...)`. The loading screen requests every screen and form path through
  `ResourceLoader.load_threaded_request` at once, and the worker threads fail to parse a few of them
  while the script cache is still being built. **Not a data error:** every one of those resources
  loads cleanly with a direct `load()`, and the same failures reproduce on a worktree built at HEAD,
  so it predates any recent change. It clears on the next boot, when the import cache is warm.
  Confirmed 2026-09-20 during the roster cut. Re-run `tools/validate.sh` before investigating; if it
  ever stops clearing, the fix is to stagger the threaded requests rather than fire all of them in
  one frame.

- None known.

## Change history

| Date | Change |
|---|---|
| 2026-10-05 | Owner-requested Shop, Daily Run, Trials and death/results pixel-art backgrounds connected to the existing scenes, with nearest filtering and aspect-preserving cover |
| 2026-10-04 | Owner-requested loading illustrations implemented: seven character/boss pixel-art scenes in the existing random boot/PLAY pool, nearest filtering; source generation and runtime copies through the loading pack builder |
| 2026-09-27 | Every character stands centred on the dais (owner, GDD §14 #57); Rook's `menu_offset` puts his feet on its centre |
| 2026-09-25 | Story Rifts removed (owner): Rift Map screen and route, story runs, level Results (`next_level_requested`, `enter_rift_requested`, clear bonus, unlock banners) and `selected_rift` on unlock gone; Home's `RiftCaption` → `PlayCaption`; Results' `RiftName` → `ArenaName`; the loading pool drops the four Rift backdrops; the tutorial replay is Settings only |
| 2026-09-23 | Pixel-art Home plate and logo, central empty dais for the equipped character, fixed preview transform while authored sprite or video motion continues; Home phone QA now builds directly, independent of the Tutorial save gate |
| 2026-09-17 | Shop WISPS tab and Results' WISP FORMS are labelled CHARACTERS (routes unchanged) |
| 2026-09-16 | Cover-then-build navigation (veil, latest wins), run prewarm behind the run loading screen, image-based loading screen |
| 2026-09-15 | Tutorial screen: first-launch route after Loading, Rift Map TUTORIAL replay back to the Rift Map, no glide; Settings replay removed |
| 2026-09-15 | Shop (spec 04): Forms screen and route removed; Wisp tap / Results → Shop WISPS, SHOP → last tab, NO ADS → NO ADS tab; Shop Back returns to its origin |
| 2026-09-15 | Rift Points (spec 01): Sanctum route and Home button removed; Results RP breakdown (collected, performance, rewards, total, balance); `RiftPoints` formatting |
| 2026-09-13 | Bottom nav removed: Wisp tap → Forms, button columns, animated PLAY + Rifts under the Wisp, Shop route |
| 2026-09-13 | Home rebuilt: top bar, animated hero + living background, PLAY with Rift caption, bottom nav |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Fade-in transitions, press feedback, versioned Home footer (Milestone 5 polish) |
| 2026-09-11 | Loading boot, Statistics/Settings destinations, back routing, Results Forms (Milestone 4) |
| 2026-09-11 | Expanded Results and added session best-score/Soul-Shard accumulation |
| 2026-09-11 | Added Results summary, fast restart and session-local tutorial gating |
| 2026-09-11 | Implemented and verified Home → Play → Pause/Resume/Home flow |
| 2026-09-11 | Planned from owner prompt v2 |
