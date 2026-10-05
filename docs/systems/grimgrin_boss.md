# System: Grimgrin, the Hollow Ronin (melee boss)

> **Status:** 🔄 in the game (2026-09-27) · the first boss of the new set (Enemies v2) · the owner's
> phone test pending · **Last updated:** 2026-10-04 · **GDD section:** §5.5, §14 #58–61 ·
> **Design:** [specs/enemies_v2/boss_melee.md](../specs/enemies_v2/boss_melee.md) (the owner's decisions)

## Purpose

A hooded ninja hunter with two katanas who fights from the walls: he dashes fast and unpredictably
from wall to wall, and his flight is the time to hit him (it does not hurt the Wisp); sometimes his dash
is a fast attack instead, in which he cannot be hit and touching him kills the Wisp; sometimes he plants
both katanas in the Wisp's wall so it rots and turns deadly, and in the second half marks the Wisp with
Death's Grin so the next wall it lands on rots at once. Regular enemies spawn at random during his
fight. He can be hit on his walls and in his slow flight; a hit while both katanas are planted counts
double.

## Files

| Path | Role |
|---|---|
| `res://scenes/bosses/boss_actor.gd` | `BossActor`: the base every boss extends, the one interface `GameWorld` uses |
| `res://scenes/bosses/grimgrin_boss.gd` / `.tscn` | `GrimgrinBoss`: his state machine, walls, rot, Death's Grin, hits, drawing |
| `res://scripts/resources/grimgrin_tuning.gd` · `res://data/bosses/grimgrin_tuning.tres` | His numbers |
| `res://scripts/resources/boss_sprite_layout.gd` · `res://data/bosses/grimgrin_layout.tres` | Where his feet and wall grip sit in the packed frames (generated) |
| `res://data/bosses/grimgrin_frames.tres` · `res://assets/art/characters/grimgrin/grimgrin_sheet.png` | His animations (generated, never hand-edit) |
| `res://data/bosses/grimgrin.tres` | `BossData`: id `grimgrin`, name, scene, callouts |
| `concept_art/grimgrin_autosprite_v1/pack_grimgrin.py` | Packs the owner's six AutoSprite sheets (`raw/`) into the above |
| `tools/godot/test_grimgrin_boss.gd` | Contract, walls, dash danger, rot, hits, Death's Grin, defeat |

## Scene / node structure

```text
GrimgrinBoss (Node2D, at his body centre)   grimgrin_boss.gd
├── %Glow (Sprite2D)            Death's Grin flare and hit flash, behind him
├── %Sprite (AnimatedSprite2D)  grimgrin_frames.tres, oriented to his wall or his flight
└── %Effects (Node2D, top_level) draws the rotting walls and the grin mark in world space
```

`%Effects` has an absolute z of 11 (under him at 12 and the Wisp at 20): a top-level node's relative z
counts from the canvas, not from the boss, and at −3 the rot drew under the floor.

## Public API

`BossActor` (shared with `ReaperBoss`): the signals `phase_changed`, `summon_requested`,
`spawn_requested(count, max_live)`, `health_changed`, `defeated`; `configure_variant`, `configure`,
`set_target_position`, `set_arena_rect`, `set_arena_polygon`, `set_last_edge_position`,
`set_player_radius`, `skip_intro`, `get_intro_progress` (0..1 through his intro, 1 after; an arena
draws his appearance from it, ADR-0025), `get_current_health`, `get_maximum_health`, `is_core_exposed`,
`get_phase`, `get_phase_name`, `get_dangerous_circles`, `get_dangerous_lanes`, `get_lane_radius`,
`try_dash_hit`, `get_victory_duration`, `get_experience_reward`, `get_defeat_name`.
His own queries: `is_planted`, `is_marking`, `is_fast_attack` (its warning or flight), `get_wall`.
`get_dangerous_circles` is one circle on him during the fast flight and empty otherwise.

## Data & tuning

`GrimgrinTuning` in `data/bosses/grimgrin_tuning.tres`. All starting values are Claude's proposal for
the owner's phone test (2026-09-27): size, health, rest times, dash speed, the chance and cooldown of
the ill wall, rot warning and deadly times, Death's Grin timing, and the random spawns. The fast attack
(2026-09-28): `fast_attack_chance` 0.3, `fast_attack_cooldown` 4 s, `first_fast_attack_delay` 3 s,
`fast_warning_duration` 0.8 s, `fast_danger_ratio` 0.25 (Claude's) and `fast_dash_speed` 1500 (the
owner: the first test's speed).

## Dependencies

`GameWorld` (starts him from `BossData.scene`, routes the Wisp's dashes, landings and contacts, spawns
the enemies he requests), `EndlessArenaRules` (the opening boss), `SoundFx` (the Reaper's sounds are
reused).

## Rules & behaviour

- **Walls:** the four sides of the arena rectangle. On the floor he plays the floor idle, on the
  ceiling the same flipped upside down; on the right wall the right-wall idle, on the left the same
  mirrored (owner). On the floor and ceiling he faces the Wisp.
- **Movement (owner):** after a short, random rest he dashes from wall to wall, swiping as he flies;
  his target wall and point are random. **His dash does not hurt the Wisp** (owner, 2026-09-27, after
  the first phone test: it killed at once and he could not be beaten); nothing on his body is a danger,
  except in the fast attack (below).
- **The indicator (owner, 2026-09-27):** before every dash he holds his wall for
  `dash_warning_duration` (0.5 s) while his eyes and glow flare, building up (the warning); **in flight
  he glows the whole time**: the time to hit him. Half the first test's speed (`dash_speed` 750).
- **The fast attack (owner, 2026-09-28):** sometimes, after a rest, his dash is the fast attack
  instead, to a random wall like the slow one. **Its own warning:** a crimson flare instead of the
  orange, held `fast_warning_duration` (0.8 s); he stays crimson through the flight. The flight is fast
  (`fast_dash_speed` 1500, the first test's speed), **he cannot be hit in it**, and touching him
  **kills the Wisp even mid-dash** (a danger circle, `fast_danger_ratio` of his height). A Wisp dash
  through him does nothing to him. He can be hit again once he lands. An ill-wall dash is never the fast
  attack (Claude's choice).
- **The ill wall (owner: not every time):** sometimes he dashes to the Wisp's wall instead, lands
  away from the Wisp and plants both katanas. The wall rots from his blades outward (the warning), then
  the whole wall is deadly for a moment: a Wisp still on it dies (a danger lane along the wall).
- **Death's Grin (owner: second half only, effects, no sheet):** at half health and below, he
  sometimes grins: he flares orange and a crimson mark appears on the Wisp; the next wall the Wisp lands
  on rots at once from its landing point.
- **Hits (owner):** on his walls and in his slow flight, never in the fast attack, one hit per Wisp
  dash; **while both katanas are planted a hit counts double**. Every hit shows the strike
  (`StrikeFx`, [game_feel.md](game_feel.md)). At zero health he plays his death, dissolves and the run
  continues harder, as after every boss.
- **Spawns (owner):** regular enemies spawn at random during his fight (no animation); he asks
  `GameWorld` for one at a time, two in the second half, up to a live cap.
- **Attacks are visible (owner):** the rot is drawn on the wall; no warning lines.
- **Where he appears (Claude's choice for the test):** the first boss of every Endless run
  (`EndlessTuning.opening_boss_id`); later bosses come from the old pool. The daily run and the
  Tutorial keep the Reaper.

## How to test

- `tools/run_tests.sh grimgrin_boss` and `tools/run_tests.sh boss_variants`.
- Manual: play Endless to wave 4.

## Known issues / TODO

- No sound of his own (the Reaper's are reused) and no new art for the rot or the mark (drawn in code).
- His random spawns are the Enemies v2 enemies, picked by the run's ramp (2026-09-28).
- The boss bar's title row still shows the Reaper's icon (`%BossHud/TitleRow/ReaperIcon` is fixed
  art), and `GameWorld` still logs his contacts as "Reaper attack" / "Reaper corridor".
- Phase names (WALL TO WALL, DEATH'S GRIN on the bar) and every tuning value are Claude's, for the
  phone test (GDD §14 #59).

## Change history

| Date | Change |
|---|---|
| 2026-10-04 | `get_intro_progress()` for an arena's appearance effect (SIMULATION, ADR-0025) |
| 2026-09-28 | His random spawns are the Enemies v2 enemies (the ramp's picks) |
| 2026-09-28 | The fast attack (owner, GDD §14 #61): a longer crimson warning, then a fast flight in which he cannot be hit and touching him kills the Wisp even mid-dash; the slow dash stays. `test_grimgrin_boss` keeps the fast attack off (its checks hit him at any moment); not run, and the fast attack is not in it (the owner tests on the phone). Verified: `validate.sh` OK; APK installed and launched on the owner's phone |
| 2026-09-27 | After the owner's phone test (owner): his dash no longer hurts the Wisp; he can be hit in flight as well as on his walls; a 0.5 s flaring warning before each dash and a glow through each flight; dash speed halved to 750. Verified: `test_grimgrin_boss`, `test_boss_variants`, `test_reaper_boss` pass |
| 2026-09-27 | Created: the owner's six AutoSprite sheets packed, `BossActor` base, `GrimgrinBoss`, opening Endless boss. Verified: `test_grimgrin_boss`, `test_boss_variants`, `test_reaper_boss` pass; a 14 s fight in the real arena (Wisp idle) showed his dashes, an ill floor, the random spawns and a dash kill; renders of every wall, both plantings and the flight checked by eye |
