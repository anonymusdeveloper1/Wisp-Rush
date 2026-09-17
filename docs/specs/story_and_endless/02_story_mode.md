# Phase 2 — Rifts become story levels

> **Status:** ✅ built 2026-09-15 (DEVLOG) — implementation only; the Tests and QA items were skipped by
> owner request. The system docs now own these rules.
>
> Part of [story_and_endless](README.md) · **Rules:** GDD §3, §5.5, §6 (Rifts), §7, §11, §14 #12–#13;
> [ADR-0013](../../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md) ·
> **Touches:** [rifts.md](../../systems/rifts.md), [core_run.md](../../systems/core_run.md),
> [reaper_boss.md](../../systems/reaper_boss.md), [game_flow.md](../../systems/game_flow.md),
> [meta_progression.md](../../systems/meta_progression.md) (Trials), [challenges.md](../../systems/challenges.md),
> [tutorial.md](../../systems/tutorial.md)
>
> **Before starting:** the owner must confirm GDD §14 #12 (one level per Rift run).

## Goal
A Rift run plays exactly one level and ends in victory when that level's final boss falls. Clearing
level 1 of a Rift opens the next Rift. PLAY follows the story, the Rift Map handles replays, and Results
offers the next step.

## Where things are today
| Concern | Location |
|---|---|
| Boss cadence | `GameWorld._on_wave_started`: a boss when `wave % _boss_wave_interval == 0`; the interval is `RiftData.waves_per_level`, halved for `boss_rush` |
| Victory | `GameWorld._on_reaper_defeated`: banks `_rift_levels_cleared`, **increments `_rift_level` inside the run**, resumes waves after `victory_duration` |
| Start level | `Main._show_game`: `get_rift_level(selected_rift) + 1` |
| Unlock | `RiftData.unlock_wave` + `is_unlocked(highest_wave)`; Rift Map lock text `REACH WAVE N`; `DevUnlock.unlock_rifts` raises `highest_wave` |
| Persistence | `record_run` banks `rift_levels[rift] = max(old, rift_levels_cleared)` and `rift_bests` |
| Card copy | Rift Map: `LEVEL n / 8`, `ALL 8 CLEARED  ·  ENDLESS` |
| Results | `ResultsScreen` signals `restart_requested`, `home_requested`, `forms_requested` |
| Naming trap | `GameWorld._start_endless_run()` and `_endless_started` start the normal waves, not an Endless mode. Rename them (for example `_start_waves`) so phase 3 is unambiguous |

## Tasks
1. **Run profile.** Add a typed `RunProfile` (`res://scenes/gameplay/run_profile.gd`, `RefCounted`) and
   `GameWorld.configure_run(profile)` replacing `configure_run_profile(...)`. Fields: `mode`
   (`&"story"` or `&"daily"`; phase 3 adds `&"endless"`), `rift: RiftData`, `level: int`, `run_seed`,
   `daily_date_key`, `form: FormData`, and `first_clear_possible: bool` (level above the banked level).
   Main builds every profile.
2. **Unlock data.** Replace `RiftData.unlock_wave` with `unlock_after_rift_id: StringName` and
   `unlock_after_level: int = 1`, and `is_unlocked(highest_wave)` with `is_unlocked(rift_levels: Dictionary)`.
   Chain the five `.tres` files in ladder order. `RiftCatalog.validate()`: the first Rift has no
   requirement; every other requirement names an earlier Rift with a level inside its `level_count`.
3. **Pure helper `ContentUnlocks`** (`res://scripts/utils/content_unlocks.gd`, static, no nodes):
   `is_rift_unlocked(rift, rift_levels)`, `get_next_level(rift, rift_levels)` (cleared + 1, capped at
   `level_count`), `is_mastered(rift, rift_levels)`, and
   `get_newly_unlocked(levels_before, levels_after, catalog) -> Array[StringName]`. Phase 3 adds the
   Endless helpers here.
4. **One level per run** (GameWorld, mode `story`).
   - The level's final boss is the boss on wave `waves_per_level`. `boss_rush` keeps its mid-level
     boss on wave `waves_per_level / 2`, which resumes waves as today.
   - When the final boss dies: award as today, play `WispPlayer.play_victory(duration)`, then end the
     run as a victory through the same `run_ended(summary)` path as death — after the victory beat,
     with no input or pause menu in between.
   - `_rift_level` never changes inside a run. HUD: `LEVEL n  •  WAVE w / 4`, then `LEVEL n CLEARED`.
   - Summary adds `mode`, `level`, `victory`, `level_cleared`, `first_clear`, `rp_clear_bonus`;
     `rift_levels_cleared` becomes `level` on a victory, else 0.
   - The tutorial still runs inside Obsidian Garden level 1, and its victory counts.
5. **Clear bonus.** Add to `EconomyTuning`: `level_clear_base = 20`, `level_clear_per_level = 10`,
   `repeat_clear_fraction = 0.25` (starting values). The first clear of level n pays
   base + (n − 1) × per_level; a repeat pays `roundi(first-clear bonus × fraction)`. Added once through
   the summary.
6. **The daily run stays endless for now.** Mode `daily` ignores level ends: it plays Obsidian Garden
   with a boss every 4 waves and harder cycles, as today. Phase 3 moves it to the Endless floor.
7. **Persistence.** `record_run` banks `rift_levels` only when `level_cleared`. When a run opens a new
   Rift (`ContentUnlocks.get_newly_unlocked`), that Rift becomes `selected_rift`. `highest_wave` stays
   a lifetime statistic.
8. **Main, Home and the Rift Map.**
   - PLAY starts a story profile for `selected_rift` at `get_next_level`.
   - Caption under PLAY: `SHATTERED RIFT  •  LEVEL 3`, or `SHATTERED RIFT  •  MASTERED`.
   - Unlocked Rift card: `LEVEL n / 8` (the next level) or `MASTERED`. Locked card and status line:
     `CLEAR <PREVIOUS RIFT> LEVEL 1`. Remove the word ENDLESS from Rift cards.
   - `DevUnlock.unlock_rifts` banks level 1 of every Rift instead of raising `highest_wave`.
9. **Results.**
   - **Victory:** `LEVEL n CLEARED` with the Rift name; RP lines (collected, performance, clear bonus,
     rewards); unlock banners from `get_newly_unlocked` (for example `SHATTERED RIFT OPEN`).
     Primary button: **ENTER <NEW RIFT>** when this clear opened one, otherwise **NEXT LEVEL**, or
     **PLAY AGAIN** when mastered. Secondary HOME; keep the existing Forms link.
   - **Defeat:** `LEVEL n FAILED`; primary **RETRY**; secondary HOME.
   - New signals `next_level_requested` and `enter_rift_requested(rift_id)`; `restart_requested`
     replays the same profile.
10. **Trials and challenges audit** (`res://data/trials/*.tres`, `TrialTracker`, `ChallengeTracker`).
    - Story runs never pass wave `waves_per_level` (4). Every trial in tiers 1–3 must be completable in
      story mode: replace wave targets above 4 in those tiers with story goals such as level clears.
    - Wave targets above 4 in tier 4 and later stay, and their text says "in Endless"; they complete
      once phase 3 lands.
    - The `rift_levels_cleared` and `run_level` trials assume several levels per run: re-author them.
      A cumulative `level_clears` metric is fine; add it to the summary and `TrialTracker`.
    - Daily challenges keep their wave goals, since daily runs stay endless.
11. **Depth milestones** stay keyed on `highest_wave`. Note in meta_progression.md that only daily runs
    reach them until phase 3.

## Tests
- New `tools/godot/test_story_progression.gd`:
  - level 1 victory ends the run with `victory = true`;
  - `rift_levels` banks once, Shattered Rift opens and becomes selected;
  - a repeat clear pays the repeat bonus;
  - a mastered Rift replays level 8;
  - a defeat banks nothing.
- `test_rift_rules`: boss rush's mid-level boss resumes waves and its final boss ends the level.
- `test_rift_catalog`: chain validation; no `unlock_wave` left.
- Update `test_main_progression_flow`, `test_menu_screens` (caption, lock text, no ENDLESS on cards),
  `test_trials`, `test_save_manager` (story `record_run`), `test_dev_unlock` and `test_tutorial_flow`
  (tutorial victory).
- `test_dash_geometry` and the rule suites stay green across all five Rifts.

## Docs
rifts.md (rules, API, data table), core_run.md (run end on victory, `RunProfile`), reaper_boss.md
(victory per mode), game_flow.md (Results, routes), meta_progression.md (Trials audit), challenges.md,
tutorial.md; ROADMAP M10 spec 02 ✅; DEVLOG entry.

## Acceptance
- [ ] Fresh save: the tutorial run is Obsidian Garden level 1. Beating the Reaper ends the run with
      `LEVEL 1 CLEARED` and `SHATTERED RIFT OPEN`; ENTER SHATTERED RIFT starts its level 1; Home's caption
      now reads `SHATTERED RIFT  •  LEVEL 1`; the Rift Map still offers Obsidian Garden level 2.
- [ ] Levels never advance inside a run; boss rush still shows two bosses per level.
- [ ] A locked Rift can't be entered and says which clear opens it.
- [ ] Every tier 1–3 trial can be completed without Endless.
- [ ] `tools/validate.sh` OK · `tools/run_tests.sh` 0 failed · MCP run clean · QA sheets: home, rifts,
      rifts_locked, results (victory and defeat).
