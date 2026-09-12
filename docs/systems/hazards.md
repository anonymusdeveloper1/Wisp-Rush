# System: Arena hazards

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §5.4, §13

## Purpose

Add sparse, telegraphed route constraints without removing every viable dash or safe edge.

## Files

| Path | Role |
|---|---|
| `res://scripts/components/hazard_actor.gd` | Shared scaling, focus and collision query API |
| `res://scripts/resources/hazard_tuning.gd` | Collision, cycle and presentation tuning |
| `res://scenes/hazards/split_void_crystal.*` | Indestructible narrow dash blocker |
| `res://scenes/hazards/spike_bloom.*` | Safe/pulse/active cycle |
| `res://scenes/hazards/blade_ring.*` | Fixed rotating blade circles |
| `res://data/hazards/*.tres` | Per-hazard starting values |

## Scene / node structure

```text
GameWorld
└── %HazardLayer
    └── HazardActor scenes
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `tuning` | export | Per-prefab scale, collision, timing and threat values. |
| `set_viewport_width(width)` | method | Rescale art and collision from design width. |
| `set_world_speed(multiplier)` | method | Apply Wisp Focus to hazard simulation. |
| `blocks_dash()` | method | Whether an active body truncates a dash segment. |
| `get_blocking_radius()` | method | Viewport-scaled solid radius, or zero during arrival. |
| `get_dangerous_circles()` | method | Current world-space damaging circles. |
| `get_threat_cost()` | method | Authored wave threat value. |

## Data & tuning

Each scene has a `HazardTuning` Resource. Formation data permits at most one authored hazard.

## Dependencies

Wave formations choose hazard kind/position; GameWorld owns swept queries and damage routing.

## Rules & behaviour

- Redesign v1 art with ×1.3 sizes (sprite, blocking and danger radii together). Warnings are amber (where/when), execution is magenta — shape and timing differ too, never hue alone.
- Crystal blocks a narrow corridor after a visible arrival warning.
- Bloom is harmless while closed/pulsing and dangerous only while visibly open.
- Blade ring danger follows four rotating blade points, not its empty centre.
- Telegraphs and hazard state remain readable during Wisp Focus.
- Swept queries choose the earliest block/damage point; blockers truncate the same authoritative
  dash segment used for enemy hits, while dangerous hazards reform the Wisp at a safe edge.

## How to test

- Run `tools/godot/test_hazards.gd` for lifecycle/geometry and
  `tools/godot/test_hazard_gameplay.gd` for a live crystal-truncated dash.
- Inspect a mixed wave to confirm no more than one obstacle and an open arena remain.

## Known issues / TODO

- Void portals and separately taught obsidian pillars are later optional mechanics.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Redesign v1 art; sizes ×1.3; amber/magenta telegraphs (ADR-0005, ADR-0006) |
| 2026-09-11 | Implemented crystal, bloom and blade ring with swept GameWorld routing |
| 2026-09-11 | Planned for Milestone 2 |
