# System: Run progression and mutations

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §5.5, §6–7, §15–16

## Purpose

Convert enemy XP into safe three-choice run upgrades and track separate score, combo, kills,
multi-reaps, wave and earned Soul Shards through Results.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/mutation_data.gd` | Mutation identity, cap, icon and UI value schema |
| `res://scripts/resources/run_progression_tuning.gd` | XP curve, streak and reward tuning |
| `res://data/mutations/*.tres` | Eight supplied mutations |
| `res://data/progression/default_run_progression.tres` | Starting XP/reward values |
| `res://scripts/components/run_progression.gd` | XP, levels, choices and upgrade application state |
| `res://scenes/screens/upgrade_select.*` | Three-card paused overlay |
| `res://scenes/pickups/soul_shard_pickup.*` | Dropped currency, dash collection and attraction |

## Scene / node structure

```text
GameWorld
├── %RunProgression (Node)
└── HUD
    ├── XP bar
    └── UpgradeSelect overlay
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `experience_changed(xp, threshold, level)` | signal | Refresh the slim HUD progress display. |
| `level_ready` | signal | XP threshold reached; open after dash resolution. |
| `mutation_applied(id, level)` | signal | Run-local mutation level changed. |
| `tuning` | export | XP curve, catalog and cross-system effect values. |
| `start(seed)` | method | Reset XP, levels and deterministic choice order. |
| `add_experience(amount)` | method | Add XP and latch a pending level. |
| `offer_choices(count)` | method | Distinct deterministic non-capped MutationData choices. |
| `apply_choice(id)` | method | Spend one pending level and emit the new mutation level. |
| `get_mutation_level(id)` | method | Current run-only level for one mutation. |
| `get_mutation(id)` / `get_levels()` | method | Mutation data or a copy of the run-level registry. |
| `has_pending_level()` | method | Whether XP is banked for a safe choice. |
| `get_current_xp()` / `get_xp_threshold()` | method | Current XP progress. |
| `get_run_level()` / `get_total_mutation_levels()` | method | Run level and aggregate power context. |
| `MutationData.get_next_description(level)` | method | Concise next-level card copy from authored values. |
| `UpgradeSelect.choice_selected(id)` | signal | One card was accepted exactly once. |
| `UpgradeSelect.present(choices, levels)` / `dismiss()` | method | Open or close the always-processing overlay. |
| `UpgradeSelect.choose_index(index)` | method | Accept one visible choice exactly once. |
| `UpgradeSelect.get_presented_choice_ids()` | method | Current card identifiers for verification. |
| `SoulShardPickup.collected(amount)` | signal | Report one collected run-currency reward. |
| `SoulShardPickup.configure(target, radius, width)` | method | Supply attraction target/radius and viewport scale. |
| `SoulShardPickup.set_attraction_radius(radius)` | method | Refresh Soul Hunger's live pull distance. |
| `SoulShardPickup.try_dash_collect(from, to, radius)` | method | Resolve swept pickup collection. |

## Data & tuning

All eight GDD mutations have supplied icons, concise next-value copy and sensible caps. XP threshold
uses a rising Resource-defined curve; selection pauses only after the Wisp returns to waiting.

## Dependencies

GameWorld translates mutation levels into Wisp/enemy/hazard effects and owns run statistics.

## Rules & behaviour

- Redesign v1: new upgrade icons; the three choices are `CardButton` cards with a magenta selected state over the dimmed, frozen arena.
- Offers contain three distinct, non-capped choices whenever at least three remain.
- Upgrade input cannot double-select and gameplay remains paused behind the overlay.
- Wide Reap, Soul Hunger, Death Pulse, Soul Link, Cold Wake, Void Velocity, Soul Vessel and
  Reaper's Gift all change live run behavior; nothing persists between runs yet.
- Soul Shards remain separate from score and are reported by Results.

## How to test

- Run `tools/godot/test_run_progression.gd` for threshold/choice rules and
  `tools/godot/test_mutation_effects.gd` for all eight live effects.
- Confirm XP gained mid-dash opens selection only after wall recovery, then resumes cleanly.

## Known issues / TODO

- Cross-run currency/best persistence arrives with SaveManager in Milestone 3.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Implemented XP, safe three-card choices, eight effects, drops and run statistics |
| 2026-09-11 | Planned for Milestone 2 |
