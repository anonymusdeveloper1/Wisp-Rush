# System: Enemies

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §5.4

## Purpose

Provide three readable, data-tuned regular threats with shared arrival, durability, swept damage,
focus/slow and dissolve rules plus distinct movement or action behavior.

## Files

| Path | Role |
|---|---|
| `res://scripts/components/enemy_actor.gd` | Shared lifecycle, health, collision and rewards |
| `res://scenes/enemies/soul_wisp.*` | One-hit steering enemy |
| `res://scenes/enemies/shard_wraith.*` | Two-hit angular tracker with warned dart |
| `res://scenes/enemies/bone_mote.*` | Three-hit drifter with warned predictive charge |
| `res://scripts/resources/enemy_tuning.gd` | Shared enemy tuning schema |
| `res://data/enemies/*.tres` | Per-family movement, health, action, threat and reward values |

## Scene / node structure

```text
EnemyActor subclass (Node2D)  [group: enemies]
├── %Sprite (AnimatedSprite2D)
├── %ArrivalRing (Sprite2D)
└── %HitFlash (Sprite2D)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `killed(enemy, world_position, score, experience, dash_id)` | signal | Emits once after lethal damage. |
| `set_target_position(position)` | method | Updates the live Wisp steering target. |
| `set_last_edge_position(position)` | method | Updates the predictive-action target. |
| `set_world_speed(multiplier)` | method | Applies Wisp Focus to enemy simulation only. |
| `set_viewport_width(width)` | method | Rescales movement, art and collision from design width. |
| `set_arena_rect(rect)` | method | Supplies bounds and viewport scaling. |
| `apply_slow(duration, multiplier)` | method | Applies an enemy-local Cold Wake slow. |
| `is_slowed()` | method | Whether an enemy-local slow is currently active. |
| `movement_enabled` | export | Disable steering for deterministic tutorial targets. |
| `is_contact_active()` | method | True only after the arrival telegraph and before death. |
| `get_collision_radius()` | method | Live viewport-scaled contact radius. |
| `get_current_health()` | method | Remaining family durability. |
| `get_threat_cost()` / `get_shard_drop_chance()` | method | Wave and reward metadata. |
| `try_dash_hit(from, to, corridor_radius, damage, dash_id)` | method | Tests one swept segment and applies at most one hit per dash. |
| `try_direct_hit(damage, event_id)` | method | Applies mutation damage with per-event protection. |

## Data & tuning

Soul Wisp: 1 health, 72 px/s, threat 1. Shard Wraith: 2 health, 132 px/s, threat 2, angular
tracking and short dart. Bone Mote: 3 health, 48 px/s, threat 3, slow drift and charge toward the
Wisp's latest edge. All values scale from 1080 px design width and live in EnemyTuning Resources.

## Dependencies

Pure geometry from `DashGeometry`; GameWorld supplies targets/focus/slow and consumes kill signals.

## Rules & behaviour

- Redesign v1 art: charcoal silhouettes with magenta cores. Sprites **and** collision radii were scaled ×1.45 together, so aiming is unchanged ([ADR-0006](../decisions/0006-inset-playfield-and-larger-sprites.md)).
- Telegraph state is non-damaging and non-targetable.
- Soul Wisp steers gradually; Wraith and Mote actions always visibly wind up.
- Collision is a distance-to-swept-segment test against enemy radius plus blade corridor.
- The same damage event cannot damage an enemy twice; higher-health families show shield/hit state.
- Only ACTIVE enemies participate in GameWorld contact damage; telegraph/dying states are safe.
- Lethal hits show hit feedback, then dissolve and release the node.

## How to test

- Run `tools/godot/test_enemy_families.gd` for telegraphs and 1/2/3-hit durability.
- Run `tools/godot/test_gameplay_slice.gd` for live swept multi-kill behavior.

## Known issues / TODO

- The Reaper is a separate boss system in Milestone 3.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Redesign v1 art; sprites and hitboxes ×1.45 (ADR-0006) |
| 2026-09-11 | Added shared EnemyActor, Shard Wraith, Bone Mote, threat and shard rewards |
| 2026-09-11 | Exposed active contact radius and stationary-target control for health/tutorial |
| 2026-09-11 | Implemented production-art Soul Wisp with telegraph, steering and swept hits |
| 2026-09-11 | Planned from owner prompt v2 |
