# System: Player dash

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §4–5, §8

## Purpose

Turn one touch/mouse drag or a desktop QA aim vector into a precise edge-to-edge Wisp dash. Own the
state machine, aim preview, authoritative movement segment and wall-impact presentation.

## Files

| Path | Role |
|---|---|
| `res://scenes/player/wisp_player.tscn` | Reusable Wisp prefab and visuals |
| `res://scenes/player/wisp_player.gd` | State/input/movement controller |
| `res://scripts/utils/dash_geometry.gd` | Pure ray/rectangle and swept-distance math |
| `res://scripts/resources/player_tuning.gd` | Typed tuning schema |
| `res://data/player/default_player_tuning.tres` | Default starting values |

## Scene / node structure

```text
WispPlayer (CharacterBody2D)  wisp_player.gd
├── %HealthComponent (Node)
├── %Sprite (AnimatedSprite2D)
├── %CollisionShape (CollisionShape2D)
├── %AimLine (Line2D)
├── %ImpactPoint (Polygon2D)
└── %ImpactBurst (Sprite2D)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `dash_started(direction, dash_id)` | signal | A valid windup begins. |
| `dash_segment_swept(from, to, dash_id, corridor_radius)` | signal | Authoritative segment for hit tests. |
| `wall_impacted(position, normal, dash_id)` | signal | Dash lands at its calculated edge. |
| `obstacle_impacted(position, normal, dash_id)` | signal | A solid hazard truncated the active dash. |
| `focus_started(duration, world_speed)` | signal | Run-local enemies/hazards should slow. |
| `tuning` | export | Gesture, dash, health and feedback values. |
| `dash_damage` | export | Base integer damage dealt by swept dash segments. |
| `request_dash(direction)` | method | Resolve and start one normalized dash request. |
| `set_arena_rect(rect)` | method | Apply live viewport bounds and resnap safely. |
| `cancel_active_aim()` | method | Clear an unresolved gesture before pause/screen replacement. |
| `get_collision_radius()` | method | Live viewport-scaled gameplay radius. |
| `set_run_combat_modifiers(damage, width, speed)` | method | Apply current run mutation results. |
| `get_blade_width_multiplier()` | method | Current run-local damage-corridor multiplier. |
| `get_dash_speed_multiplier()` | method | Current run-local dash-speed multiplier. |
| `interrupt_dash_at(position, normal)` | method | Stop a live dash at an indestructible obstacle. |

## Data & tuning

`default_player_tuning.tres`: design width 1080 px; dash 4,400 px/s; windup 0.065 s; wall impact
0.14 s; focus 0.32 s at 0.32×; minimum swipe 28 px at design density; radius 3% viewport width;
blade bonus 14 px at design width. The landing inset is 1.35× collision radius so transparent-frame
art remains completely visible while still reading as contact with the physical edge.

## Dependencies

Input actions in PROJECT_CONTEXT §5.4; GameWorld supplies the dynamic arena and consumes signals.
Health state/presentation is detailed in [player_health.md](player_health.md).

## Rules & behaviour

- Redesign v1 art plus [ADR-0006](../decisions/0006-inset-playfield-and-larger-sprites.md): the Wisp's radius ratio went 0.03 → 0.05 (sprite and collision ×1.45) and the playfield is inset to the painted floor, so dashes cover less distance than before.
- Valid input only while waiting/aiming; first active touch wins.
- Direction is normalized and never scales power with gesture length.
- An outward edge component reflects inward before calculating the first edge intersection.
- Dash motion emits every swept physics segment; visual state never outruns authoritative state.
- A solid hazard can interrupt the dash during that signal; movement does not continue behind it.
- Run mutations scale damage, corridor width and speed within readability caps.
- Resize recalculates bounds and keeps a waiting Wisp attached to its nearest edge.

## How to test

- From every edge, swipe/cardinal-key dash inward, diagonally and outward.
- Resize during waiting; the Wisp remains visible and the next dash reaches the new edge exactly.
- Run the dash geometry checks documented in the DEVLOG verification entry.

## Known issues / TODO

- Touch minimum is design-scaled; physical-device density tuning needs device QA.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Redesign v1 art; radius ×1.45; inset playfield (ADR-0006) |
| 2026-09-11 | Added obstacle interruption and run-local damage, width and speed modifiers |
| 2026-09-11 | Composed HealthComponent and made HURT/DEAD states reachable |
| 2026-09-11 | Implemented exact dash, input, preview, impact/focus and pure geometry checks |
| 2026-09-11 | Planned from owner prompt v2 |
