# System: Player dash

> **Status:** ✅ done · **Last updated:** 2026-09-15 · **GDD section:** §4–5.1, §5.6, §8

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
| `res://scenes/gameplay/aim_guide.gd` | `AimGuide`: GameWorld-owned ×N combo label past the arrow tip (the path line was removed 2026-09-15) |

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
| `aim_preview_changed(origin, direction, landing, active)` | signal | Every aim-arrow update (resolved, **assisted** direction and landing, global px) and once `active = false` when it hides. GameWorld draws the path and lights enemies from it. |
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
| `set_aim_arrow_enabled(enabled)` | method | Show or hide the direction arrow; off also hides the lit-target rings and ×N (AIM ARROW). |
| `set_aim_assist_enabled(enabled)` / `is_aim_assist_enabled()` | method | AIM ASSIST setting. |
| `set_aim_target_counter(counter)` | method | GameWorld hands down `func(origin, landing, corridor_radius) -> int` (enemies a dash would slice); invalid = no assist. |
| `get_assisted_direction(direction)` | method | The direction a released swipe will really dash (raw when assist is off). |
| `get_dash_corridor_radius()` | method | (radius + blade bonus) × blade-width mutation; used by swept hits and the preview. |
| `get_aim_line_start_distance()` / `is_aim_preview_active()` | method | Arrow-tip distance where the line starts; whether the preview is shown. |
| `get_momentum()` / `get_current_dash_speed()` | method | Chain momentum and live dash speed, for HUD and tests. |
| `get_momentum_steps()` / `get_momentum_visual_level()` | method | Whole momentum steps (dash pitch); 0..1 presentation level, 1 during RUSH. |
| `set_momentum_presentation(feel, glow_tint)` | method | `RunFeelTuning` + dash-style tint for the streak glow, speed lines and RUSH aura ([rush_mode.md](rush_mode.md)). |
| `set_rush_speed_multiplier(m)` / `get_rush_speed_multiplier()` | method | RUSH run modifier (1.0 = off). |
| `set_damage_immune(on)` / `is_damage_immune()` | method | RUSH immunity to contact, hazard and boss damage; separate from hurt invulnerability, no blink. |
| `set_rush_visuals(active, warning)` | method | Momentum visuals at full + steady Wisp aura; `warning` flickers the aura. |
| `has_buffered_swipe()` | method | Whether a released swipe is waiting to fire. |

## Data & tuning

`default_player_tuning.tres`: design width 1080 px; dash 3,960 px/s (−10 %, owner 2026-09-15); windup 0.065 s; wall impact
0.14 s; focus 0.32 s at 0.32×; minimum swipe 28 px at design density; radius 3% viewport width;
blade bonus 14 px at design width; aim assist ±`aim_assist_degrees` 6.0 sampled every
`aim_assist_step_degrees` 1.0 (group "Aim assist"). The landing inset is 1.35× collision radius so transparent-frame
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
- **Speed** = `dash_speed × mutation multiplier × RUSH multiplier × viewport scale × (1 + momentum) ×
  burst`. Burst decays from `launch_burst_multiplier` (1.4) over `launch_burst_decay` (0.11 s). RUSH's
  ×1.3 is a separate run modifier; `PlayerTuning` is never written.
- **Momentum** +`momentum_step` (0.08) per launch within `momentum_window` (0.35 s) of landing and per
  redirect, capped at `momentum_max` (0.25); reset by a slow launch or by damage. The window counts
  **game time** (`_game_time`, accumulated physics delta, so it slows with `Engine.time_scale` and
  stops while paused), not the wall clock: a slow-motion finisher between landing and relaunch never
  breaks a chain. Same behaviour at normal speed.
- **Momentum visuals** (GDD §5.6): a streak glow behind the dashing Wisp grows with
  `momentum / momentum_max`; at `speed_lines_at` (1.0) faint speed lines scroll behind it for that dash
  (off under Reduced Motion). Built in code at `_ready` as `StreakGlow`, `RushAura` and `SpeedLines`
  at absolute z 0, so hazard/boss telegraphs and the aim arrow stay above them. Damage clears them.
- **Damage immunity** (RUSH): `is_vulnerable()` and `take_hazard_damage()` refuse while
  `_damage_immune`; the invulnerability blink is untouched.
- A system-cancelled touch (notification shade, app switch) is dropped, never acted on.
- While a finger is held the arrow is recomputed every tick, so it stays truthful through flight,
  the landing lock and rest.
- Only a launch off a wall counts as a rapid ricochet; an empty redirect leg does not decay the combo.
- **Aim arrow** replaced the full aim line and landing marker (2026-09-12): a chevron beside the Wisp
  showing the resolved direction from the same `_resolve_dash` the dash uses, so it cannot mislead.

**Aim help** (owner decision 2026-09-15, GDD §4–5.1; players missed enemies through aim, not speed):
- **Aim preview.** While the arrow shows (touch/mouse hold, keyboard aim, a held finger in flight or
  windup, tutorial `preview_aim`) the Wisp emits `aim_preview_changed`. GameWorld
  (`_on_player_aim_preview_changed`) draws `AimGuide` — a faint cyan-glow / soul-white line from the
  arrow tip to where the dash stops, with a small diamond — and calls `EnemyActor.set_targeted` on
  every enemy that dash would hit (soft `SOUL_CYAN` ring; pulses, static under Reduced Motion). 2+ lit
  → a `×N` `ValueLabel` near the line end, kept inside the arena. The line is a child of WorldContent
  under the enemy layer.
- **Counted like combat.** Segment origin → landing, corridor = `get_dash_corridor_radius()`, test =
  `EnemyActor.would_dash_hit` (the same test `try_dash_hit` now calls: Warden shield arc and Rift Spawn
  tether included, no side effects). It stops at the first dash-blocking hazard (same entry radius as
  combat) or portal mouth. Lit = hit, not killed: a 2–3 health enemy lights up but survives one hit.
  Damaging hazards (spikes, blade rings, boss attacks) are not stops — they change during the dash's
  flight and have their own telegraphs; past a portal the exit leg is not previewed. Boss not lit.
- **Aim assist.** `_act_on_swipe` (launch, redirect, windup retarget, buffered swipes when they fire)
  and both keyboard paths pass the swipe through `get_assisted_direction`: sample ±1°…±6° from the raw
  swipe, bend to the direction that slices MORE enemies than the raw one (strictly more, walking
  outward so ties keep the closest), never toward 0 hits, never past the cone (checked on the
  resolved direction), only legal casts. The preview shows the assisted result. `request_dash` and
  `redirect_dash` themselves stay raw. Dash speed, collision, scoring and momentum are unchanged.
- **Clears** on release, cancel, damage, pause (`_set_paused` / tutorial skip confirm call
  `cancel_active_aim`), death and level victory (`_clear_aim_preview`), and when AIM ARROW is off.
- **Cost.** Up to 13 `_resolve_dash` casts plus enemy/hazard scans per aim update; the scans walk
  children by index, but `_resolve_dash` / `DashGeometry.cast_polygon` still return Dictionaries.

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
- Aim help: hold aim through three lined-up souls → line, three rings, `×3`; release kills 3. Aim just
  beside a far pair → the dash bends (≤ 6°) into them; AIM ASSIST off → it doesn't. Crystal on the
  line → line and lighting stop there. Pause / get hit / AIM ARROW off → everything clears.

## Known issues / TODO

- Touch minimum is design-scaled; physical-device density tuning needs device QA.
- Aim help needs the device pass: line/ring readability on every Rift floor, whether 6° feels
  gentle, whether lighting 2–3 health enemies that survive reads as a promise of a kill.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Aim help: `aim_preview_changed`, GameWorld path line + lit enemies + ×N, release-time aim assist (±6°, AIM ASSIST), `get_dash_corridor_radius` (owner decision) |
| 2026-09-15 | Momentum window in game time; streak glow, speed lines, RUSH aura; RUSH speed modifier and damage immunity (spec rush_and_feel) |
| 2026-09-12 | Movement flow: buffering, landing-lock cancel, mid-dash redirect, launch burst, momentum, aim arrow |
| 2026-09-12 | Redesign v1 art; radius ×1.45; inset playfield (ADR-0006) |
| 2026-09-11 | Added obstacle interruption and run-local damage, width and speed modifiers |
| 2026-09-11 | Composed HealthComponent and made HURT/DEAD states reachable |
| 2026-09-11 | Implemented exact dash, input, preview, impact/focus and pure geometry checks |
| 2026-09-11 | Planned from owner prompt v2 |
