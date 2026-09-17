# Phase 1 — Rift Points replace Soul Shards; the Soul Sanctum is removed

> **Status:** ✅ built 2026-09-15 (DEVLOG). The system docs now own these rules: [shop.md](../../systems/shop.md),
> [save_manager.md](../../systems/save_manager.md), [meta_progression.md](../../systems/meta_progression.md).

> Part of [story_and_endless](README.md) · **Rules:** GDD §6 (Rift Points, no permanent power), §14 #16–#17;
> [ADR-0013](../../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md) ·
> **Touches:** [shop.md](../../systems/shop.md), [meta_progression.md](../../systems/meta_progression.md),
> [save_manager.md](../../systems/save_manager.md), [monetisation.md](../../systems/monetisation.md),
> [challenges.md](../../systems/challenges.md), [forms.md](../../systems/forms.md),
> [game_flow.md](../../systems/game_flow.md), [core_run.md](../../systems/core_run.md)

## Goal
The currency is called Rift Points (RP) everywhere, every run pays a performance bonus from its score,
the Soul Sanctum no longer exists, and Remove Ads carries no currency. Everything else plays as it does
today — Rift runs stay endless until phase 2.

## Out of scope
Story levels (phase 2), Endless (phase 3), Shop tabs and dash styles (phase 4).

## Where things are today
| Concern | Location |
|---|---|
| Balance | `SaveManagerService` key `soul_shards`, schema 5 (`res://scripts/autoload/save_manager.gd`) |
| Balance writers | `record_run` (summary `soul_shards`), `add_soul_shards`, `apply_challenge_result` (`reward_shards`), `apply_trial_result`, `claim_depth_milestones` (`reward_shards`), `purchase_form`, `grant_remove_ads(bonus_shards)`, `purchase_sanctum_level`, `refund_sanctum` |
| Run payout | `GameWorld._award_soul_shards()`, `SOUL_SHARD_SCENE` pickups, boss `shard_reward` (`res://scenes/gameplay/game_world.gd`) |
| Display | HUD currency label, Home top bar, Results (`soul_shards`, `total_soul_shards`, `challenge_reward`), Shop, Daily, Trials, Settings developer card, `res://scenes/debug/theme_gallery.gd` |
| Sanctum | `res://scenes/screens/sanctum_screen.*`, `res://scripts/resources/sanctum_node.gd`, `sanctum_catalog.gd`, `res://scripts/utils/sanctum_effects.gd`, `res://data/sanctum/`, Home button, `Main._show_sanctum`, SaveManager sanctum methods, `DevUnlock.max_sanctum`, `tools/godot/test_sanctum.gd` |
| Sanctum in play | `GameWorld`: `SANCTUM_CATALOG`, `configure_run_profile(..., sanctum_levels)`, combo grace, bonus health, invulnerability, starting mutations, XP / shard find / attraction / blade width / dash speed multipliers; `WispPlayer` runtime invulnerability; `RunProgression` |
| IAP | `MonetisationService.PRODUCT_REMOVE_ADS = &"remove_ads_shard_pack"` |
| Trials | one trial uses `metric = &"soul_shards"` (`res://data/trials/`) |

Find the rest with `grep -rni "shard" scenes scripts data tools/godot` and
`grep -rni sanctum scenes scripts data tools/godot`. The **Shard Wraith** enemy is unrelated: keep its
name, scene and data.

## Tasks
1. **Save schema v6.**
   - Rename `soul_shards` → `rift_points`, carrying the value.
   - Refund Sanctum spend: for every node id and level in `sanctum_levels`, add the costs of levels
     1..n. Resolve those costs from `res://data/sanctum/*.tres` (`SanctumNode.get_cost`) **before**
     deleting the data, and freeze them as a `const` table in the migration with the comment
     "frozen at removal, ADR-0013". Unknown ids refund nothing.
   - Drop `sanctum_levels`; keep every other key. `SCHEMA_VERSION = 6`. Saves newer than 6 keep
     today's behaviour.
2. **Rename the currency in code.**
   | Old | New |
   |---|---|
   | save / snapshot `soul_shards` | `rift_points` |
   | run summary `soul_shards` | `rp_collected` |
   | display summary `total_soul_shards` | `rift_points_total` |
   | `add_soul_shards()` | `add_rift_points()` |
   | result key `reward_shards` (challenges, trials, depth) | `reward_points` |
   | `GameWorld._award_soul_shards()` | `_award_rift_points()` |
   | trial metric `soul_shards` | `rp_collected` (trial metrics are run-summary keys; GDD §14 #22) |
   | `grant_remove_ads(bonus_shards)` | `grant_remove_ads()` |
   | `DevUnlock.SHARD_GRANT`, `grant_shards` | `RP_GRANT`, `grant_rift_points` |

   Scene and texture files named `soul_shard_*` keep their names — they are the RP shard pickup.
   Record that in the PROJECT_CONTEXT glossary.
3. **Player-facing text.** Short form `RP` after numbers (`1,250 RP`), long form "Rift Points" in
   sentences: HUD, Home top bar, Results, Daily, Trials, Shop, Statistics, Settings developer card,
   theme gallery. Keep the shard icon and tabular numerals.
4. **Performance bonus.**
   - New Resource `EconomyTuning` (`res://scripts/resources/economy_tuning.gd`, instance
     `res://data/economy/default_economy_tuning.tres`) with `score_per_rift_point: int = 400`
     (starting value). Phase 2 adds the clear bonuses to it.
   - At run end GameWorld writes `rp_performance = score / score_per_rift_point` (integer division)
     into the summary. `record_run` adds `rp_collected + rp_performance` to the balance once.
   - Calibrate: log score, `rp_collected` and `rp_performance` for the tutorial run and two early runs
     (MCP run or device) and record the numbers in [shop.md](../../systems/shop.md). The target is
     35–45 RP in total for a median early run; change `score_per_rift_point` first, pickup rates only if
     both are far off.
5. **Remove the Soul Sanctum.**
   - Delete the screen, resources, effects helper, data and test. Remove the Home button, the Main
     route, the SaveManager methods, the developer card action and `DevUnlock.max_sanctum`.
   - Replace every effect with its no-bonus baseline: combo grace 0, bonus health 0, invulnerability
     bonus 0, starting mutations 0, every multiplier 1.0. `configure_run_profile` loses its
     `sanctum_levels` parameter.
   - Home's left column becomes Trials + Daily. Keep Home's layout rules and re-run its QA sheet.
6. **Remove Ads without currency.** Product id `remove_ads`; purchase and restore grant ad removal only.
   Shop copy shows "REMOVE ADS" with no shard line.
7. **Trials and challenges.** Rename the metric and reward wording; no other change this phase.
8. **Results.** Show `RP COLLECTED`, `PERFORMANCE`, `REWARDS` (challenges + trials + depth) and the new
   total. Each value reaches the balance exactly once.

## Tests
- `test_save_manager`: a v5 fixture with `soul_shards = 300` and Sanctum levels (for example
  keen_edge 2, soul_reserve 1) migrates to v6 with `rift_points = 300 + frozen costs` and no
  `sanctum_levels`; reloading changes nothing; a v6 save round-trips.
- `test_monetisation`: new product id; purchase and restore leave the balance unchanged.
- Update for the rename and removal: `test_trials`, `test_challenge_tracker`, `test_dev_unlock`,
  `test_menu_screens`, `test_screen_setup_order`, `test_screen_transitions`,
  `test_main_progression_flow`, `test_mutation_effects`. Delete `test_sanctum`.
- New checks: the summary carries `rp_collected` and `rp_performance`; the Results total equals the
  balance change.
- No player-facing string contains "SHARD" except the Shard Wraith (a test or a grep recorded in the DEVLOG).

## Docs
- [meta_progression.md](../../systems/meta_progression.md): remove the Sanctum sections; the system
  becomes "Trials and depth milestones".
- [shop.md](../../systems/shop.md): `EconomyTuning`, calibration numbers; status 🔄.
- save_manager.md (schema v6), monetisation.md, challenges.md, forms.md (prices in RP), game_flow.md,
  core_run.md.
- PROJECT_CONTEXT: §5.1 Soul Sanctum row removed, §5.2 scenes, §5.8 `EconomyTuning`, §8 glossary.
- ROADMAP M10 spec 01 ✅; DEVLOG entry.

## Acceptance
> Verified 2026-09-15; evidence in the DEVLOG entry of that date (spec 01), including its Review bullet.

- [x] The v5 → v6 migration refunds Sanctum spend exactly once and is stable on reload.
- [x] No Sanctum code, data, screen, test or Home button remains.
- [x] Every player-facing currency label reads RP or Rift Points.
- [x] Results shows collected and performance RP, and the balance rises by exactly the displayed total.
- [x] Remove Ads purchase and restore change no balance.
- [x] `tools/validate.sh` OK · `tools/run_tests.sh` 0 failed · MCP run clean · QA sheets: home, results,
      shop, daily, trials.
