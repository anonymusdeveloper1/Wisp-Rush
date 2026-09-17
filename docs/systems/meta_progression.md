# System: Trials and depth milestones

> **Status:** ✅ done · **Last updated:** 2026-09-15 · **GDD section:** §6 ·
> **ADR:** [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md) (Rift Points, no
> permanent power)
>
> **Story audit (spec 02, 2026-09-15):** story runs last at most `waves_per_level` (4) waves. Tier 1–3
> trials are all completable in story runs; deeper wave goals (tier 4+) say "in Endless" and complete
> in Endless and daily runs (spec 03). Depth milestones stay keyed on `highest_wave`; story runs never
> pass wave 4, so **only Endless and daily runs reach them** (no migration).

## Purpose

Give a finished run something to carry forward besides cosmetics: a persistent ladder of goals and
one-time depth rewards, both paid in Rift Points. There is no permanent power — the Soul Sanctum was
removed on 2026-09-15 (ADR-0013) and its spend refunded by the save v6 migration
([save_manager.md](save_manager.md)).

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/trial_data.gd` / `trial_catalog.gd` | One goal, and the 12-tier ladder |
| `res://data/trials/*.tres` | 36 authored trials plus the catalog |
| `res://scripts/utils/trial_tracker.gd` | Applies a run to the ladder; pure and static |
| `res://scenes/screens/trials_screen.*` | The three active goals and the rank |
| `res://scripts/autoload/save_manager.gd` | Rank, progress, claimed depth (schema v6) |

## Public API

| Member | Kind | Description |
|---|---|---|
| `TrialTracker.apply_run(rank, progress, summary)` | static | New `rank`, `progress`, `reward_points`, `completed`, `ranked_up`. |
| `TrialTracker.get_active_trials(rank)` | static | The three goals currently shown. |
| `TrialData.reward_points` | export | Rift Points paid once when the trial completes. |
| `TrialCatalog.VALID_METRICS` | const | Run-summary keys a trial may read (`rp_collected`, not the old `soul_shards`). |
| `SaveManagerService.apply_trial_result(result)` | method | Banks a ladder result and pays its `reward_points`. |
| `SaveManagerService.claim_depth_milestones()` | method | Pays unclaimed depth rewards; returns `reward_points` and `waves`. |

## Data & tuning

**Trials** — 36 goals in 12 tiers of three. Each tier mixes a survival, a cumulative combat and a
mastery goal; rewards rise 15 → 125 RP per trial. Clearing all three ranks the player up.
Story goals read the cumulative `level_clears` summary key (1 per story victory): FIRST STEPS
(`t02_level_clears`, 2), PATHFINDER (`t03_level_clears`, 4), RIFT WALKER (`t06_level_clears_m`, 8)
and ASCENDANT (`t07_level_clears_m`, 12) replace GO DEEPER wave 6/8 and the multi-level
`rift_levels_cleared` / `run_level` goals (GDD §14 #23). GO DEEPER wave 10+ reads "Reach wave N in
Endless."
HOARDER (`t08_rp_collected_m`) reads `rp_collected`: Rift Points picked up or won from bosses in one
run, not the performance bonus, so its target of 40 keeps its old difficulty (GDD §14 #22).

**Depth milestones** — one-time Rift Points rewards at waves 5/10/15/20/25 (25/50/100/175/300),
keyed on the lifetime best wave.

## Dependencies

[core_run.md](core_run.md) (run summary), [rifts.md](rifts.md), [save_manager.md](save_manager.md),
[game_flow.md](game_flow.md) (Results shows the rewards), [shop.md](shop.md) (Rift Points),
[ui_design_system.md](ui_design_system.md).

## Rules & behaviour

- Trials never expire and never pay twice. Single-run trials keep the **best** run seen; cumulative
  trials add up. Both cap at their target.
- The ladder stops at the last authored tier instead of running off the end.
- Depth milestones are keyed on the lifetime best wave, so a shallow replay never re-pays.
- Trial and depth rewards reach the balance through their own SaveManager calls, after `record_run`;
  Results adds them up as REWARDS ([game_flow.md](game_flow.md)).
- The save v6 migration moves banked progress of the renamed HOARDER id to `t08_rp_collected_m`.

## How to test

- `tools/run_tests.sh trials` — ladder shape, escalation, progress rules, rank-up, depth milestones.
- Visual: `tools/qa_matrix.sh trials`.

## Known issues / TODO

- The Trials screen is read-only; there is no claim animation or completion celebration.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Story audit: level-clear trials replace deep-wave and multi-level goals in tiers 2, 3, 6, 7 (spec 02) |
| 2026-09-15 | Soul Sanctum removed (spec 01, ADR-0013); rewards renamed to Rift Points (`reward_points`); HOARDER reads `rp_collected`; system renamed "Trials and depth milestones" |
| 2026-09-12 | Created: Soul Sanctum, Trials ladder, depth milestones, save schema v3→v5 |
