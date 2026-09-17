# System: Save manager

> **Status:** ✅ done · **Last updated:** 2026-09-15 · **GDD section:** §6, §12, §24
>
> **Changed 2026-09-15 ([spec 04](../specs/story_and_endless/04_shop.md)):** schema v8 adds dash styles;
> every cosmetic is bought and equipped through `purchase_cosmetic` / `equip_cosmetic`.

## Purpose

Keep release progression local and reliable across launches. Validate and migrate stored data,
write atomically, retain the last valid backup and recover without blocking Home.

## Files

| Path | Role |
|---|---|
| `res://scripts/autoload/save_manager.gd` | Global validated progression state and atomic JSON I/O |
| `user://wisp_rush_save.json` | Current save outside the repository |
| `user://wisp_rush_save.backup.json` | Previous valid save |

## Scene / node structure

```text
/root/SaveManager (autoload Node)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `progression_changed(snapshot)` | signal | Persistent state changed after a successful mutation. |
| `get_snapshot()` | method | Deep copy of validated current data. |
| `record_run(summary)` | method | Update cumulative statistics and add the run's `rp_collected + rp_performance + rp_clear_bonus` once; bank `rift_levels[rift] = max(old, level)` only when `level_cleared` (spec 02). `highest_wave` stays a lifetime statistic. |
| `mark_tutorial_completed()` | method | Persist that the Tutorial screen was finished or skipped (first launch then opens Home). `reset_tutorial()` was removed 2026-09-15 with Settings' replay. |
| `purchase_cosmetic(kind, id, price, requirement_met)` / `equip_cosmetic(kind, id)` / `owns_cosmetic(kind, id)` | method | Kinds `KIND_FORM`, `KIND_DASH_STYLE`, `KIND_ARENA_SKIN`. Buying spends RP and equips; refused (nothing spent) for unknown/owned ids, a negative or unaffordable price, `requirement_met == false`, or an arena skin before Endless opens. |
| `add_rift_points(amount)` / `get_rift_points()` | method | Grant a non-negative reward / read the balance. |
| `apply_challenge_result(result)` / `apply_trial_result(result)` / `claim_depth_milestones()` | method | Persist tracker output and pay its `reward_points`. |
| `grant_remove_ads()` | method | Marks ads removed; grants no currency (ADR-0013). |
| `configure_storage_paths(save, temp, backup)` / `reset_save()` | method | Test hooks: explicit files and safe defaults. |
| `uses_isolated_storage()` | static method | True for automated runs, which use `user://test_runs/`. |
| `save_now()` / `reload()` | method | Explicit persistence and recovery boundary. |

## Data & tuning

**Schema v8.** Best/high wave, totals, play time, `rift_points`, forms, selected Rift, Rift bests and
levels, Endless (`endless_best_score`, `endless_best_wave`, `endless_runs`, `endless_intro_seen`,
`owned_arena_skins` with the default always owned, `equipped_arena_skin`; ids outside
`VALID_ARENA_SKIN_IDS` sanitize to `DEFAULT_ARENA_SKIN_ID` = `astral_observatory`; retired ids in
`RETIRED_ARENA_SKIN_IDS`, i.e. `placeholder_void_slate`, map to their replacement), dash styles (`owned_dash_styles` with
`soul` always owned, `equipped_dash_style`; valid ids come from `DASH_STYLE_CATALOG`, while form and
skin ids stay listed because their catalogs load art), Trials rank/progress, claimed depth,
`ads_removed`, consent, challenge/daily state, tutorial completion and settings, stored as validated
JSON-compatible values. `record_run` updates the Endless bests and count only for `mode == "endless"`
(a daily run touches only `daily_state`, via challenges); `mark_endless_intro_seen()` clears Home's NEW badge.

| Migration | What it does |
|---|---|
| v0 → v5 shape | `high_score`, `currency`, `tutorial_seen`, `unlocked_forms`, `selected_form` renamed |
| v6 → v7 (spec 03) | Adds the Endless fields at their defaults; nothing else changes |
| v7 → v8 (spec 04) | Adds `owned_dash_styles` / `equipped_dash_style` at their defaults (`soul`) |
| v1–v5 → v6 (ADR-0013) | `soul_shards` → `rift_points`, plus a refund of every Sanctum level bought, from the frozen `SANCTUM_REFUND_COSTS` table; `sanctum_levels` dropped; Trials id `t08_soul_shards_m` → `t08_rp_collected_m` and challenge id `shard_seeker` → `rp_seeker` keep their progress |

`SANCTUM_REFUND_COSTS` (RP per level, index 0 = level 1) was resolved from `data/sanctum/*.tres` with
`SanctumNode.get_cost` before that data was deleted: keen_edge 200/320/440, swift_soul 200/320/440,
shard_finder 150/240/330/420, rift_scholar 160/260/360, soul_magnet 140/230/320, long_chain
180/310/440, warded_soul 220/370/520, first_gift 900, soul_reserve 1,500 (8,970 for a maxed tree).

## Dependencies

Registered as the `SaveManager` autoload; architectural rationale is ADR-0003.

## Rules & behaviour

- Write a flushed temporary file, rotate the valid main file to backup, then rename temp to main.
- Reject invalid types, clamp numeric ranges and migrate older schemas before use.
- A save loaded from an older schema is written back at once, so a migration runs exactly once on
  disk and a reload never refunds twice. Saves from a newer schema are not migrated; recognised
  fields are kept.
- The Sanctum refund pays only known node ids, and at most up to each node's cap.
- Corrupt main falls back to backup, then safe defaults; launch never blocks.
- Save on important progression changes, application interruption and shutdown.
- Automated runs (`--script` tests, or `WISP_ISOLATED_SAVE=1` from validate/screenshot tools) use
  `user://test_runs/` and never modify real progress; explicit `configure_storage_paths()` wins.

## How to test

- `tools/run_tests.sh save_manager` — defaults, round trip, corruption recovery, v0 and v1 migration,
  and a hand-built v5 fixture (300 shards, keen_edge 2, soul_reserve 1, an unknown id, a level above
  cap) migrating to v6 exactly once, a v6 round trip and a future-schema save left alone.

## Known issues / TODO

- Cloud saves and store entitlement authority are explicitly out of local-save scope.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Schema v8: dash styles; `purchase_cosmetic` / `equip_cosmetic` / `owns_cosmetic` replace `purchase_form` / `equip_form` (spec 04) |
| 2026-09-15 | Schema v7: Endless bests, runs, intro flag, owned/equipped arena skin (spec 03) |
| 2026-09-15 | Schema v6: Rift Points, Sanctum refund migration, `sanctum_levels` dropped, write-back after migration, `grant_remove_ads()` without currency (spec 01) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
