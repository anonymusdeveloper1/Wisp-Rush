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
├── %AimArrow (Node2D) — Outline, %Glow, %Head chevrons
└── %ImpactBurst (Sprite2D)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `dash_started(direction, dash_id)` | signal | A valid windup begins, or a redirect launches a new leg. |
| `dash_redirected(position, previous_dash_id)` | signal | A mid-dash swipe turned the dash; the previous leg ended without a wall. |
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
| `redirect_dash(direction)` | method | Turn a live dash from the current position; false unless dashing. |
| `set_arena_polygon(polygon)` | method | Apply the Rift floor polygon (ADR-0011); empty keeps the rectangle. |
| `set_aim_arrow_enabled(enabled)` | method | Show or hide the direction arrow. |
| `get_momentum()` / `get_current_dash_speed()` | method | Chain momentum and live dash speed, for HUD and tests. |
| `has_buffered_swipe()` | method | Whether a released swipe is waiting to fire. |

## Data & tuning

`default_player_tuning.tres`: design width 1080 px; dash 4,400 px/s; windup 0.065 s; wall impact
0.14 s; focus 0.32 s at 0.32×; minimum swipe 28 px at design density; radius 3% viewport width;
blade bonus 14 px at design width. The landing inset is 1.35× collision radius so transparent-frame
art remains completely visible while still reading as contact with the physical edge.

## Dependencies

Input actions in PROJECT_CONTEXT §5.4; GameWorld supplies the dynamic arena and consumes signals.
Health state/presentation is detailed in [player_health.md](player_health.md).

## Rules & behaviour

**Flow** (owner decision 2026-09-12, GDD §5.1):
- **No swipe is ever lost.** Touches are tracked in every state except DEAD/VICTORY. Previously a
  touch that began mid-dash was refused and its release then ignored, silently eating fast play.
  Released during SPAWNING/HURT → buffered for `input_buffer_window` (0.30 s, physics time); released
  during WALL_IMPACT → launches at once; released while DASHING → `redirect_dash`; released in
  WINDUP → `_retarget_windup` re-aims the pending dash (no redirect signal, no momentum).
- A finger held down through a landing is kept: `_enter_waiting` no longer clears the pointer.
- **Redirect** emits `dash_redirected` then `dash_started` with a new dash id, so GameWorld resolves
  the finished leg's kills and enemies can be hit again on the new leg.
- **Speed** = `dash_speed × mutation multiplier × viewport scale × (1 + momentum) × burst`. Burst
  decays from `launch_burst_multiplier` (1.4) over `launch_burst_decay` (0.11 s).
- **Momentum** +`momentum_step` (0.08) per launch within `momentum_window` (0.35 s) of landing and per
  redirect, capped at `momentum_max` (0.25); reset by a slow launch or by damage.
- A system-cancelled touch (notification shade, app switch) is dropped, never acted on.
- While a finger is held the arrow is recomputed every tick, so it stays truthful through flight,
  the landing lock and rest.
- Only a launch off a wall counts as a rapid ricochet; an empty redirect leg does not decay the combo.
- **Aim arrow** replaced the full aim line and landing marker: a chevron beside the Wisp showing
  the resolved direction from the same `_resolve_dash` the dash uses, so it cannot mislead.

- Redesign v1 art plus [ADR-0006](../decisions/0006-inset-playfield-and-larger-sprites.md): the Wisp's radius ratio went 0.03 → 0.05 (sprite and collision ×1.45) and the playfield is inset to the painted floor, so dashes cover less distance than before.
- First active pointer wins. On a phone that is the EMULATED mouse: the emulated press arrives
  before the touch press, so touch input is owned by the mouse branch — handle cancels there too.
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
| 2026-09-12 | Movement flow: buffering, landing-lock cancel, mid-dash redirect, launch burst, momentum, aim arrow |
| 2026-09-12 | Redesign v1 art; radius ×1.45; inset playfield (ADR-0006) |
| 2026-09-11 | Added obstacle interruption and run-local damage, width and speed modifiers |
| 2026-09-11 | Composed HealthComponent and made HURT/DEAD states reachable |
| 2026-09-11 | Implemented exact dash, input, preview, impact/focus and pure geometry checks |
| 2026-09-11 | Planned from owner prompt v2 |
