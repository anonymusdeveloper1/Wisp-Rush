# System: Reaper boss

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §5.5, §7–8

## Purpose

Interrupt endless waves near one minute with a readable three-phase skill check, then award a
victory beat and continue the same run at a harder threat tier.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/reaper_tuning.gd` | Health, phase timing, geometry and rewards |
| `res://data/bosses/default_reaper.tres` | Starting Reaper values |
| `res://scenes/bosses/reaper_boss.tscn` | Production-art boss prefab and warnings |
| `res://scenes/bosses/reaper_boss.gd` | Intro, three phases, exposed core and defeat |

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
| `summon_requested(points)` | signal | Teleport Hunt requests a small Soul Wisp line. |
| `health_changed(current, maximum)` | signal | Refresh boss-only health UI. |
| `defeated(position, score, shards)` | signal | Final dissolve completed and rewards are ready. |
| `configure(rect, target, encounter, seed)` | method | Start a scaled deterministic encounter. |
| `try_dash_hit(from, to, radius, damage, dash_id)` | method | Damage exposed core at most once per dash. |
| `get_dangerous_circles()` / `get_dangerous_lanes()` | method | Current telegraphed attack geometry. |

## Data & tuning

Base health and all intro/action/exposure timings, attack sizes, 1,500 score and Soul Shard reward
live in `default_reaper.tres`. Later encounters add health and accelerate only within authored caps.

## Dependencies

GameWorld suspends WaveDirector, routes player sweeps/damage and realizes requested minor enemies.

## Rules & behaviour

- Redesign v1 art: a 12-cell atlas (`09_gate_arrival`, `10_exposed_core`, `11_corridor_cast`, `12_stagger` are available for future wiring). Body and hittable core ×1.3; attack geometry unchanged because the inset playfield already makes it relatively larger.
- Phase 1 warns a scythe sweep, attacks, then exposes the core.
- Phase 2 marks two teleport points, brightens the true one, summons Soul Wisps, then exposes.
- Phase 3 warns two death lanes with a preserved diagonal route before they become dangerous.
- The core is immune outside exposed windows and one dash ID can damage it only once.
- Defeat clears unsafe minors, awards the victory, then resumes a harder endless-wave tier.

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
| 2026-09-12 | Redesign v1 art; body/core ×1.3 (ADR-0005, ADR-0006) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
