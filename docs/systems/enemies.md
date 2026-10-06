# System: Enemies

> **Status:** 🔄 Enemies v2 in the game (2026-09-28) · owner phone test pending · **Last updated:**
> 2026-10-04 · **GDD section:** §5.4, §14 #58, #62 · **Design:** [specs/enemies_v2/](../specs/enemies_v2/README.md)

## Purpose

The regular enemies of a run: the owner's five Enemies v2 enemies, drawn from AutoSprite sheets, each
with its own move and attack. They go around the Wisp and attack; an attack that reaches the Wisp
kills it, even mid-dash. One dash hit kills any of them, and the kill is a slice. The first enemy set
(Soul Wisp, Shard Wraith, Bone Mote and the seven Rift enemies) was removed on 2026-09-28 (owner).

## Files

| Path | Role |
|---|---|
| `res://scripts/components/enemy_actor.gd` | `EnemyActor`: arrival telegraph, health, swept hits, Focus/slow, aim ring; hooks for the loop animation, death and sprite scale |
| `res://scripts/components/whole_frame_enemy.gd` | `WholeFrameEnemy`: movement around the Wisp, the three attacks, the warning glow, the slice kill |
| `res://scripts/components/enemy_projectile.gd` | `EnemyProjectile`: straight, homing and wall-mark shots, owned by the run |
| `res://scenes/enemies/{bone_witch,claw_ghost,hooded_scribe,root_mask,stone_golem}.tscn` | The five prefabs (the shared script, per-scene attack settings) |
| `res://data/enemies/<enemy>.tres` | `EnemyTuning` per enemy (Claude's values for the phone test) |
| `res://data/enemies/<enemy>_frames.tres` · `res://assets/art/characters/enemies_v2/` | Generated `SpriteFrames`, atlases and shot pictures — never hand-edit |
| `concept_art/enemies_v2_autosprite_v1/pack_enemies.py` | Cleans the owner's sheets (`raw/`) and packs them |
| `res://assets/shaders/enemy_slice.gdshader` | One half of a sliced enemy |
| `res://assets/shaders/character_attack.gdshader` | The melee warning glow (shared with the characters' attack look) |
| `res://scripts/utils/enemy_ramp.gd` | Which enemy a spawn slot gets ([wave_director.md](wave_director.md)) |

## Scene / node structure

```text
<Enemy> (Node2D, WholeFrameEnemy)  [group: enemies]
├── %ArrivalRing (Sprite2D)       arrival telegraph
├── %Sprite (AnimatedSprite2D)    <enemy>_frames.tres: move (loop), attack (once)
└── %HitFlash (Sprite2D)          white impact star
GameWorld/…/ProjectileLayer       the shots and wall marks, next to EnemyLayer
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `killed(enemy, position, score, experience, dash_id)` | signal | Once, after the lethal hit. |
| `projectile_fired(projectile)` | signal | A shot was loosed; `GameWorld` adds it to its projectile layer. |
| `get_attack_circles() -> Array[Vector3]` | method | The strike that kills right now (x, y, radius); empty otherwise. |
| `set_target_position` / `set_last_edge_position` / `set_world_speed` / `set_speed_scale` / `set_arena_rect` / `set_arena_polygon` / `apply_slow` | method | Run inputs, as before. |
| `get_arrival_progress() -> float` / `set_arrival_ring_enabled(enabled)` | method | How far the arrival telegraph has run, 0..1 (1 once active), the countdown that makes the enemy active; and the amber arrival ring on or off while it arrives (off when the arena draws the arrival itself, SIMULATION, ADR-0025; action warnings still use the ring). |
| `movement_enabled` | export | Off: the enemy stands still and never attacks (Tutorial targets, `debug_spawn_enemy`). |
| `try_dash_hit` / `would_dash_hit` / `try_direct_hit` / `set_targeted` / `is_contact_active` / `get_collision_radius` | method | Hits and aim preview, unchanged. |
| `WholeFrameEnemy.is_attacking()` | method | In its attack animation. |
| `EnemyProjectile.get_danger_circle()` / `on_hit_player()` / `is_mark()` | method | Danger check and hit report for `GameWorld`. |

## Data & tuning

`EnemyTuning` gains an "Enemies v2 attack" group (`attack_range`, `keep_distance`, `strike_radius`,
`strike_reach`, shot speed/radius/size, `homing_duration`, `homing_turn_rate`, `wall_mark_radius`,
`wall_mark_duration`); `action_interval` is the time between attacks. `sprite_diameter` is the body's
longer side on screen. Every value below is Claude's, for the owner's phone test; hits are the owner's.

| Enemy | Hits | Speed | Body on screen | Attack | Range · keep | Every | Shot |
|---|---|---|---|---|---|---|---|
| Claw Ghost | 1 | 170 | 230 | swipe, frames 12–15, reach 70 + radius 80 | 150 · — | 1.2 s | — |
| Root Mask | 1 | 120 | 180 | lunge, frames 11–16, up to 300 | 330 · — | 1.8 s | — |
| Hooded Scribe | 1 | 95 | 125 | shot on frame 7 | anywhere · 380 | 2.6 s | homing 2.5 s, 330 px/s |
| Bone Witch | 1 | 85 | 175 | shot on frame 16 | anywhere · 460 | 3.2 s | straight 520 px/s; wall mark r 70, 4 s |
| Stone Golem | 1 | 65 | 180 | shot on frame 16 | anywhere · 420 | 2.8 s | straight 650 px/s |

## Dependencies

`GameWorld` spawns them (`EnemyRamp` picks the kind), feeds targets, Focus and the arena, owns the
shots and checks every danger; `DashGeometry` for the floor.

## Rules & behaviour

Regular kills roll the independent seven-item drop chance in GameWorld. Stillglass slows regular
actors and their shots; Bomb calls `EnemyProjectile.banish()` to clear flying shots and wall marks.
Definitions and drop tuning: [pickup_items.md](pickup_items.md).

- **Movement (owner, 2026-09-27):** they go around the Wisp on the sides. A melee enemy closes in
  from the side, then straight; a shooter holds its distance and circles, turning back at a wall.
- **Attacks (owner, 2026-09-28):** the Claw Ghost swipes when close; the Root Mask lunges at where
  the Wisp is from a short distance; both glow amber on the wind-up (the attack outline shader) and
  flash on the strike. The Hooded Scribe's rune follows the Wisp for 2.5 s, then disappears; the Bone
  Witch's bolt flies straight and, where it hits the wall, leaves a purple mark the Wisp must not
  touch; the Stone Golem's shard flies straight and breaks on the wall.
- **What kills the Wisp:** a strike, a shot or a mark, even mid-dash (`take_hazard_damage`,
  `GameWorld._check_world_contacts` and the dash sweep). A dash that kills the striking enemy before
  its strike escapes it. Touching an enemy's body still hurts only a Wisp resting on a wall.
- **Hits:** one hit kills (owner). The kill splits the frame along the dash's cut; the halves drift
  apart and fade with the white flash.
- **Stationary:** with `movement_enabled` off an enemy neither moves nor attacks.
- **Facing:** the sprite mirrors so its attack faces the Wisp; the Root Mask's top-down crawl turns to
  where it goes, its side-view attack stays upright.

## How to test

- Manual: an Endless run (the owner tests on the phone).
- No automated test covers the new set yet; `test_enemy_families`, `test_endless_enemies`,
  `test_player_health_flow` and `bench_stress` still
  use the removed enemies.

## Known issues / TODO

- Every speed, size, range, cooldown and shot value is Claude's, for the phone test.
- The sixth enemy is not made yet (the eye beast reference).
- `tools/art/redesign_v1_slices.json` and `tools/art/extract_rifts.py` still list the removed enemy
  art; re-running them would recreate unused files.
- The split, shield and tether code (`EnemyTuning` "Rift behaviours", `GameWorld._spawn_split_children`)
  has no user since the Rift enemies went.

## Change history

| Date | Change |
|---|---|
| 2026-10-05 | Regular enemy drops and item slow/banish effects; projectile banish API handles wall marks |
| 2026-10-04 | `get_arrival_progress()` and `set_arrival_ring_enabled()`: an arena can draw the arrival (SIMULATION, ADR-0025) |
| 2026-09-28 | Enemies v2 (owner): Bone Witch, Claw Ghost, Hooded Scribe, Root Mask, Stone Golem from the owner's AutoSprite sheets (cleaned of white leftovers), `WholeFrameEnemy`, `EnemyProjectile`, slice kill; every old enemy removed (to the Recycle Bin) |
| 2026-09-15 | `would_dash_hit` pure query + `set_targeted` aim-preview ring (aim help) |
| 2026-09-12 | Redesign v1 art; sprites and hitboxes ×1.45 (ADR-0006) |
| 2026-09-11 | Added shared EnemyActor, Shard Wraith, Bone Mote, threat and shard rewards |
| 2026-09-11 | Implemented production-art Soul Wisp with telegraph, steering and swept hits |
