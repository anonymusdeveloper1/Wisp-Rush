# System: Player health

> **Status:** ✅ done · one fragment, nothing adds one, one rewarded-ad revive per run (2026-10-05): the Soul Vessel and Reaper's Gift
> were removed and the HUD shows no count (2026-09-24) · **Last updated:** 2026-10-05 · **GDD section:** §5.3

## Purpose

Track the Wisp's Soul Fragments independently from movement, and turn valid enemy contact into a
readable hurt/invulnerability/death sequence. GameWorld selects a safe reform edge; WispPlayer owns
the state and visuals.

A run starts on **one** fragment and death is final. Soul Ward protects that fragment by blocking
the next fatal hit, then breaks and grants brief escape immunity. It never adds or heals health.
Activation, stock and provisional timing: [pickup_items.md](pickup_items.md). The only revive is
the rewarded ad (owner 2026-10-05, ADR-0029): once per run, `WispPlayer.revive(seconds)` brings a dead
Wisp back where it fell with full Soul Fragments, the spawn reform and that many seconds without
damage (GameWorld passes 2) ([monetisation.md](monetisation.md)).

## Files

| Path | Role |
|---|---|
| `res://scripts/components/health_component.gd` | Reusable integer health state and signals |
| `res://scenes/player/wisp_player.tscn` | Composes HealthComponent under the Wisp |
| `res://scenes/player/wisp_player.gd` | Vulnerability rules and hurt/death presentation |
| `res://data/player/default_player_tuning.tres` | Starting fragments (1), hurt, invulnerability and death timing |

## Scene / node structure

```text
WispPlayer (CharacterBody2D)
├── %HealthComponent (Node)  health_component.gd
├── %Sprite (AnimatedSprite2D)
└── existing dash presentation nodes
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `HealthComponent.health_changed(current, maximum)` | signal | Emitted after reset, damage or heal. |
| `HealthComponent.depleted` | signal | Emitted once when health first reaches zero. |
| `HealthComponent.configure(maximum, refill)` | method | Set a valid maximum and optionally refill. |
| `HealthComponent.reset()` | method | Refill to maximum and clear depletion state. |
| `HealthComponent.apply_damage(amount)` | method | Apply non-negative damage and report a change. |
| `HealthComponent.heal(amount)` | method | Restore health without exceeding maximum. |
| `HealthComponent.get_current_health()` | method | Current clamped integer health. |
| `HealthComponent.is_depleted()` | method | Whether health is zero. |
| `WispPlayer.health_changed(current, maximum)` | signal | Player-facing health update for HUD/results. |
| `WispPlayer.damaged(current, maximum)` | signal | One valid contact was accepted. |
| `WispPlayer.died` | signal | Death-dissolve finished; run may transition to Results. |
| `WispPlayer.take_contact_damage(safe_edge)` | method | Apply one valid contact and reform safely. |
| `WispPlayer.take_hazard_damage(safe_edge)` | method | Apply telegraphed hazard damage, including during dash. |
| `WispPlayer.increase_maximum_health(amount, heal)` | method | Raise the maximum; only the Tutorial and the tests use it since the Soul Vessel went. |
| `WispPlayer.heal(amount)` | method | Clamped recovery; only the Tutorial's refill uses it since Reaper's Gift went. |
| `WispPlayer.is_vulnerable()` | method | True only in waiting, aiming or windup without i-frames. |
| `WispPlayer.get_current_health()` | method | Current Soul Fragment count. |
| `WispPlayer.get_maximum_health()` | method | Current maximum Soul Fragment count. |

## Data & tuning

Existing `PlayerTuning`: 1 Soul Fragment (`maximum_health`); 0.22 s hurt reaction; 0.9 s post-hit
invulnerability; 0.55 s death dissolve.

## Dependencies

GameWorld performs circle-distance contact checks and passes a safe edge point. Dash states remain
authoritative for vulnerability; HUD observes player health signals.

## Rules & behaviour

- `activate_soul_ward`, `has_soul_ward`, `clear_soul_ward`, `shield_requested`, `shield_broken`: protection
  API. RUSH immunity takes priority; Ward blocks without teleport, health loss or combo reset.

- The HUD shows no lives readout (2026-09-24): a run has exactly one fragment.
- Normal enemies cannot hurt the Wisp during spawn, dash, wall impact, hurt, death or victory.
- Telegraphing hazards can hurt during a dash only while their visible geometry is dangerous.
- Valid contact removes exactly one Soul Fragment and resets combo.
- Non-lethal hits reform at a safe edge and visibly pulse during i-frames.
- Nothing in a run adds or restores a fragment; the Tutorial refills it so a lesson never ends in death.
- Zero health enters DEAD immediately, then emits `died` only after the dissolve duration.

## How to test

- `tools/run_tests.sh pickup_effects`: Ward break, retained health, escape immunity, next fatal hit
  and RUSH preserving the shield. `pickup_shop_flow` verifies one saved copy spent by double tap.

- Unit: `tools/godot/test_health_component.gd` checks clamp, heal and depletion behavior.
- Live: `tools/godot/test_player_health_flow.gd` checks contact, i-frames, 3→0, dissolve and summary.

## Known issues / TODO

- Dedicated healing VFX/audio remain part of the Milestone 4 feedback pass.

## Change history

| Date | Change |
|---|---|
| 2026-10-05 | `WispPlayer.revive(invulnerable_seconds)` for the rewarded-ad revive (ADR-0029) |
| 2026-10-05 | Soul Ward blocks one hit without losing the single fragment, then grants escape immunity |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Added hazard damage and mutation-driven maximum health/healing |
| 2026-09-11 | Implemented component, contact rules, safe reform, HUD, i-frames and death sequence |
| 2026-09-11 | Planned for the second Milestone 1 slice |
