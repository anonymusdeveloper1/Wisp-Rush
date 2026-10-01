# System: Wave director

> **Status:** ✅ done · **Last updated:** 2026-09-28 · **GDD section:** §3, §5.5, §14

## Purpose

Turn elapsed time and current wave into bounded, readable formation requests. Twenty handcrafted
normalized templates supply where enemies arrive; mirroring and quarter-turn rotation supply safe
variation. Which enemy fills each slot is the run's Enemies v2 ramp (`EnemyRamp`, 2026-09-28).

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/formation_data.gd` | One validated normalized formation schema |
| `res://scripts/resources/formation_catalog.gd` | Ordered set of formation Resources |
| `res://scripts/resources/wave_tuning.gd` | Duration, budget and pacing values |
| `res://data/formations/*.tres` | Twenty handcrafted templates |
| `res://data/waves/default_catalog.tres` | Formation catalog |
| `res://data/waves/default_wave_tuning.tres` | Endless-wave tuning |
| `res://scenes/gameplay/wave_director.gd` | Deterministic budget/state coordinator |
| `res://scripts/utils/enemy_ramp.gd` | `EnemyRamp`: which enemy kind each slot gets (GameWorld owns one per run) |

## Scene / node structure

```text
GameWorld
└── %WaveDirector (Node)  wave_director.gd
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `formation_requested(data, mirrored, rotation)` | signal | Request one affordable formation variant. |
| `wave_started(wave, budget)` | signal | New 18–25 second wave began. |
| `tuning` / `catalog` | export | Pacing values and ordered validated formation source. |
| `start(seed)` | method | Reset and begin wave one deterministically. |
| `advance(delta, live_threat)` | method | Advance the timer and spend budget only when no live enemy remains. |
| `set_run_context(health, maximum, upgrades)` | method | Supply health and power context for bounded difficulty adaptation. |
| `set_threat_multiplier(multiplier)` | method | Scales every wave budget (0.25–4). GameWorld passes `ArenaRules.get_threat_multiplier(cycle)`: `EndlessTuning` per boss cycle (spec 03). |
| `get_current_wave()` | method | Current one-based wave. |
| `get_wave_progress()` | method | Normalized elapsed progress through the current wave. |
| `get_remaining_budget()` | method | Threat budget not yet assigned this wave. |
| `FormationData.validate()` | method | Return authored spawn-safety failures. |
| `FormationData.get_transformed_positions(mirror, turns)` | method | Apply allowed variants in normalized space. |
| `FormationCatalog.load_formations()` / `validate()` | method | Load the catalog and report schema/duplicate/count failures. |
| `EnemyRamp.configure(kinds, seed, at_start, per_waves)` / `pick(wave)` / `get_unlocked(wave)` | method | Shuffle the kinds for a run; one slot's kind; the kinds a wave may draw. |

## Data & tuning

Default waves last 22 seconds. Budget starts generous and grows gradually; formation cost, minimum
wave, enemy slots, normalized positions and optional hazard are authored per template. Exactly 20
validated Resources ship in the default catalog. Every slot is `&"enemy"` (`FormationData.ENEMY_SLOT`)
since 2026-09-28. The ramp (`WaveTuning` "Enemies v2 ramp"): `enemy_kinds_at_start` 2 and
`waves_per_new_enemy_kind` 2 (Claude's values), so all five enemies are in by wave 7.

## Dependencies

GameWorld supplies live threat and realizes spawn requests. The director never touches scene nodes.

## Rules & behaviour

- Formations, spawn distances and hazard placement are all arena-relative, so the inset playfield ([ADR-0006](../decisions/0006-inset-playfield-and-larger-sprites.md)) needed no tuning change.
- Formation cost must fit the remaining wave budget.
- **The Enemies v2 ramp (owner, 2026-09-27, agreed in principle):** each run shuffles the enemies from
  its seed, starts with a few and adds another every few waves; every slot of every formation, every
  boss spawn and every Reaper summon draws at random from those unlocked. The same seed plays the same
  run. (Until 2026-09-28 formations named their enemies and the Endless mixes swapped them.)
- One hazard can come from wave 4.
- No unrestricted random flooding; deterministic variants preserve authored relationships.
- One-third health excludes hazard formations; every three selected upgrade levels may admit a
  formation up to one wave early, capped at two waves.
- Validation rejects unsafe margins, mismatched arrays, overlap and invalid obstacle placement.

## How to test

- Run `tools/godot/test_wave_director.gd` to validate all 20 Resources, transforms, deterministic
  selection and budget transition.
- Run through wave transitions and confirm wave/budget logs contain no spawn errors.

## Known issues / TODO

- Reaper handoff at 55–75 seconds belongs to Milestone 3.

## Change history

| Date | Change |
|---|---|
| 2026-09-28 | Enemies v2: formation slots are plain `enemy`; `EnemyRamp` picks the kind; `WaveTuning` ramp values |
| 2026-09-25 | Story Rifts removed (owner): `set_rift_threat_multiplier` → `set_threat_multiplier` |
| 2026-09-12 | Verified against the inset playfield (ADR-0006) |
| 2026-09-11 | Implemented 20 formations, deterministic variants, 22-second budgets and run context |
| 2026-09-11 | Planned for Milestone 2 |
