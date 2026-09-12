# System: Save manager

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §6, §12, §24

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
| `record_run(summary)` | method | Update cumulative statistics/currency and save. |
| `mark_tutorial_completed()` | method | Persist first-run lesson completion. |
| `purchase_form(id, price, requires_boss)` / `equip_form(id)` | method | Atomic cosmetic ownership/equip changes. |
| `apply_challenge_result(result)` / `add_soul_shards(amount)` | method | Persist ChallengeTracker output / grant currency. |
| `configure_storage_paths(save, temp, backup)` / `reset_save()` | method | Test hooks: explicit files and safe defaults. |
| `uses_isolated_storage()` | static method | True for automated runs, which use `user://test_runs/`. |
| `save_now()` / `reload()` | method | Explicit persistence and recovery boundary. |

## Data & tuning

Schema version, best/high wave, totals, play time, Soul Shards, forms, challenge/daily state,
tutorial completion and settings are stored as validated JSON-compatible values.

## Dependencies

Registered as the `SaveManager` autoload; architectural rationale is ADR-0003.

## Rules & behaviour

- Write a flushed temporary file, rotate the valid main file to backup, then rename temp to main.
- Reject invalid types, clamp numeric ranges and migrate older schemas before use.
- Corrupt main falls back to backup, then safe defaults; launch never blocks.
- Save on important progression changes, application interruption and shutdown.
- Automated runs (`--script` tests, or `WISP_ISOLATED_SAVE=1` from validate/screenshot tools) use
  `user://test_runs/` and never modify real progress; explicit `configure_storage_paths()` wins.

## How to test

- Use isolated test paths for default load, round trip, corruption recovery and v0 migration.

## Known issues / TODO

- Cloud saves and store entitlement authority are explicitly out of local-save scope.

## Change history

| Date | Change |
|---|---|
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
