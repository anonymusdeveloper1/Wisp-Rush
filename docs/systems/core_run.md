# System: Core run

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §3, §5–7, §11

## Purpose

Coordinate the live full-bleed arena, Wisp, wave requests, enemies, hazards, pickups, combat,
mutations, run-local statistics, tutorial and HUD without making child systems depend on each other.

## Files

| Path | Role |
|---|---|
| `res://scenes/gameplay/game_world.tscn` | Arena, layers, HUD and pause overlay |
| `res://scenes/gameplay/game_world.gd` | Spawn/combat routing, statistics, upgrade effects and feedback |

## Scene / node structure

```text
GameWorld (Control)  game_world.gd
├── %FullBleedBackground (TextureRect)
├── %EnemyLayer (Node2D)
├── %HazardLayer (Node2D)
├── %PickupLayer (Node2D)
├── %PlayerLayer (Node2D)
│   └── WispPlayer
├── %EffectsLayer (Node2D)
├── %WaveDirector (Node)
├── %RunProgression (Node)
└── HUD (CanvasLayer)
    ├── SafeHud
    ├── TutorialOverlay
    ├── UpgradeSelect
    └── PauseOverlay
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `home_requested` | signal | The paused run requests Home navigation. |
| `run_ended(summary)` | signal | Death dissolve finished with score, kills, best combo and wave. |
| `tutorial_completed` | signal | Integrated first-run lesson completed. |
| `tutorial_enabled` | export | Enable the lesson before adding GameWorld to the tree. |
| `run_seed` | export | Deterministic wave and upgrade seed; zero derives a clock seed. |
| `get_score()` | method | Current run score for results/tests. |
| `get_combo()` | method | Current combo before timeout. |
| `get_highest_combo()` | method | Best run-local combo. |
| `get_total_kills()` | method | Defeated enemy count. |
| `get_current_wave()` | method | Current one-based endless wave. |
| `get_soul_shards()` | method | Separate run currency earned. |
| `get_multi_kill_dashes()` | method | Dashes that defeated at least two enemies. |
| `add_experience(amount)` | method | Test/debug route into normal run progression. |
| `get_mutation_level(id)` | method | Current level of one run-only mutation. |
| `is_tutorial_complete()` | method | Lesson is disabled or complete. |

## Data & tuning

All balance comes from the typed Resources linked in dependent system docs. GameWorld keeps only
event windows and presentation constants that coordinate multiple systems.

## Dependencies

[player_dash.md](player_dash.md), [player_health.md](player_health.md), [enemies.md](enemies.md),
[wave_director.md](wave_director.md), [hazards.md](hazards.md), [mutations.md](mutations.md),
[tutorial.md](tutorial.md) and production world/UI art. It has no autoload.

## Rules & behaviour

- The playfield is not the whole screen: `GameWorld._compute_arena_rect()` maps `ARENA_FLOOR_UV`
  (the painted stone floor) through the backdrop's cover-scale into screen space, so the Wisp always
  rests on stone, below the HUD ([ADR-0006](../decisions/0006-inset-playfield-and-larger-sprites.md)).
  Everything else — formations, spawn distances, hazard placement, the safest-edge search — is
  arena-relative and follows automatically.
- World art covers the viewport; only HUD uses safe-area padding.
- Wave requests are realized only from known enemy/hazard scene maps; at most one authored hazard
  exists per formation and spawn points are kept clear of the Wisp.
- Each swept segment resolves its earliest hazard event, then applies the reachable portion to
  enemies and pickups so nothing behind a blocker is hit.
- Active enemy/hazard circles damage an exposed Wisp; GameWorld chooses the edge point with the
  greatest clearance from every active threat.
- Combo increases on kills, times out after 2.2 s and survives wall impact; empty dashes shorten it.
- Multi-reaps use a quadratic base bonus, rapid redirects add score and Soul Shards stay separate.
- XP choices pause only at a safe waiting edge; selected mutation effects remain run-local.
- Contact resets combo; the death-dissolve signal freezes the run and emits its summary once.
- Focus changes enemy and hazard simulation only, never input or UI speed.
- Pause consumes input, freezes gameplay and always restores normal tree state on navigation.
- Mobile focus loss opens Pause; desktop focus loss stays live so automated visual capture works.

## How to test

- Run main, finish the lesson, continue through escalating waves and accept an XP choice.
- Run the wave, enemy, hazard, progression, mutation and gameplay scripts listed in README.
- Confirm background reaches all edges at every GDD §12 QA size.
- Pause/resume, then Pause/Home; no swipe leaks through UI.

## Known issues / TODO

- Reaper handoff, on-disk currency/best persistence and physical-device safe-area QA are later
  milestones.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Playfield inset to the painted floor; sprites and hitboxes scaled up (ADR-0006) |
| 2026-09-11 | Integrated waves, full regular roster, hazards, XP/mutations, drops and run statistics |
| 2026-09-11 | Added health contacts, safe reform, run statistics/death summary and tutorial routing |
| 2026-09-11 | Implemented responsive arena, training loop, score/combo, focus and pause HUD |
| 2026-09-11 | Planned from owner prompt v2 |
