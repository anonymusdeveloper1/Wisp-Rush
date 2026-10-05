# System: Reaper boss

> **Status:** ✅ done · **Last updated:** 2026-10-04 · **GDD section:** §5.5, §7–8

## Purpose

Interrupt the waves near one minute with a readable three-phase skill check, then award a victory
beat: a story level's final boss ends the run in victory; otherwise the run continues harder.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/reaper_tuning.gd` | Health, phase timing, geometry and rewards |
| `res://data/bosses/default_reaper.tres` | Starting Reaper values |
| `res://scenes/bosses/reaper_boss.tscn` | Production-art boss prefab and warnings |
| `res://scenes/bosses/reaper_boss.gd` | Intro, three phases, exposed core and defeat |
| `res://scenes/bosses/boss_actor.gd` | `BossActor`, the base it shares with Grimgrin: the one interface `GameWorld` drives a boss through ([ADR-0019](../decisions/0019-bosses-with-their-own-scene.md)) |

## Scene / node structure

```text
GameWorld
├── %BossLayer
│   └── ReaperBoss
└── HUD
    └── Boss health/warning
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `phase_changed(phase)` | signal | Boss phase changed for HUD/callout feedback. |
| `summon_requested(points)` | signal | Teleport Hunt requests a small line of enemies (GameWorld picks each from the Enemies v2 ramp since 2026-09-28). |
| `health_changed(current, maximum)` | signal | Refresh boss-only health UI. |
| `defeated(position, score, rp_reward)` | signal | Final dissolve completed and rewards are ready. |
| `configure(rect, target, encounter, seed)` | method | Start a scaled deterministic encounter. |
| `get_intro_progress()` | method | 0..1 through the intro hold, 1 after (`BossActor`: −1 when a boss does not say); an arena draws the appearance from it (SIMULATION, ADR-0025). |
| `try_dash_hit(from, to, radius, damage, dash_id)` | method | Damage exposed core at most once per dash. |
| `get_dangerous_circles()` / `get_dangerous_lanes()` | method | Current telegraphed attack geometry. |
| `get_phase_name(phase)` · `get_victory_duration()` · `get_experience_reward()` · `get_defeat_name()` | method | What `GameWorld` shows and grants: TELEPORT HUNT / DEATH CORRIDORS / SCYTHE SWEEP, the tuning's victory time and experience, "REAPER" |

## Data & tuning

Base health and all intro/action/exposure timings, attack sizes, 1,500 score and Rift Points reward (`rp_reward`)
live in `default_reaper.tres`. Later encounters add health and accelerate only within authored caps.

## Dependencies

GameWorld suspends WaveDirector, routes player sweeps/damage and realizes requested minor enemies.

## Rules & behaviour

- Redesign v1 art: a 12-cell atlas (`09_gate_arrival`, `10_exposed_core`, `11_corridor_cast`, `12_stagger` are available for future wiring). Body and hittable core ×1.3; attack geometry unchanged because the inset playfield already makes it relatively larger.
- Phase 1 warns a scythe sweep, attacks, then exposes the core.
- Phase 2 marks two teleport points, brightens the true one, summons enemies (the Enemies v2 ramp's picks since 2026-09-28; Soul Wisps before), then exposes.
- Phase 3 warns two death lanes with a preserved diagonal route before they become dangerous.
- The core is immune outside exposed windows and one dash ID can damage it only once.
- Defeat clears unsafe minors and awards the victory. Every boss resumes a harder cycle (`endless`,
  `daily`; the story levels that ended on a boss were removed on 2026-09-25), and the variant is
  `ArenaRules.get_boss_id(bosses beaten, seed)`: a seeded pick from the pool (every Endless mix's boss,
  or the daily `reaper`), no immediate repeat.

## How to test

- Automated: force each phase, inspect warning/danger geometry, damage gates and final rewards.
- Manual: reach wave 4, survive all three phase patterns and continue into the next wave.

## Known issues / TODO

- Final boss audio and reduced-motion camera feedback belong to Milestone 4.
- Supplied Reaper art has a baked checkerboard halo and clips at 444 px cell edges (individual PNGs
  and master sheet alike) — awaiting a clean re-export from the owner; see ROADMAP backlog.

## Change history

| Date | Change |
|---|---|
| 2026-10-04 | `get_intro_progress()` for an arena's appearance effect (ADR-0025) |
| 2026-09-28 | Teleport Hunt summons the Enemies v2 ramp's picks (the Soul Wisp is gone) |
| 2026-09-27 | `ReaperBoss` extends `BossActor` (shared with Grimgrin); `GameWorld` reads its phase name, victory time, experience and callout name through it. Behaviour unchanged |
| 2026-09-25 | Story Rifts removed (owner): no level-ending boss; the pool is every Endless mix's boss |
| 2026-09-12 | Redesign v1 art; body/core ×1.3 (ADR-0005, ADR-0006) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
