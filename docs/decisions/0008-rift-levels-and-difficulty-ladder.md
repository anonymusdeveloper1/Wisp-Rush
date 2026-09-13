# ADR-0008: Rift levels and the difficulty ladder

> **Status:** Accepted · **Date:** 2026-09-12 · **Deciders:** owner (requested per-arena difficulty
> and levels) + Claude Code · **Extends:** [ADR-0007](0007-rifts-as-rule-variant-arenas.md)

## Context
ADR-0007 gave every Rift a rule twist but one shared difficulty curve, so arena five played as
easily as arena one. The owner asked for each arena to be harder than the last, and for levels
inside an arena that start easy and escalate — more enemies, abilities unlocked and upgraded.

Two structures could deliver that. Levels could **replace** the endless run, turning Wisp Rush into
a stage-based campaign; or they could **sit inside** the endless engine as difficulty milestones.
GDD §7 states the main mode is endless, and GDD §2's third pillar is immediate momentum.

## Options considered
1. **Stage-based campaign** — finite levels with fixed enemy sets and a win screen. Clearest
   progression, but it contradicts GDD §7, discards the threat-budget director, and turns a
   two-minute arcade loop into a level-select game.
2. **Levels inside the endless run** — a level is a difficulty band. The wave director keeps
   running; each level multiplies its threat budget, and the Rift's boss closes the level.
3. **Difficulty slider per Rift** — cheapest, but the player picks their own challenge, so nothing
   is earned and the ladder carries no progression.

## Decision
Option 2.

- A Rift has `level_count` levels of `waves_per_level` waves. Its boss closes each level; defeating
  it banks the level, advances `_rift_level` **within the same run** and immediately raises the
  threat multiplier. A good run therefore climbs several levels.
- `RiftData.get_threat_multiplier(level) = level_one_threat + (level - 1) * threat_per_level`,
  clamped past the final level. `level_one_threat` is 1.0 in **every** Rift — the owner's rule that
  each arena starts easy — and `RiftCatalog` fails validation above `MAX_LEVEL_ONE_THREAT` (1.1).
  The ladder's bite comes from `threat_per_level`, which rises with the tier: level 8 runs 1.84×
  in Obsidian Garden and 2.75× in Reaper's Court, on top of the existing per-wave growth.
- Per-arena rosters reuse the twenty authored formations through
  `RiftData.enemy_substitutions`, which remaps an authored enemy kind onto that Rift's own roster.
  No formation is duplicated per arena.
- Progress persists as `rift_levels` (schema v2), banked from the run summary and never lowered.
- After the last level a Rift stays endless at its maximum multiplier, so GDD §7 still holds.

## Consequences
- Difficulty now has three multiplied sources — per-wave growth, Rift level, and post-boss tier.
  They compound; `tools/godot/test_rift_catalog.gd` pins the level curve, and the combined curve
  needs a real device pass before release.
- Every Rift needs its own boss to close a level. Only two exist (Reaper, Hollow Choir art);
  `the_fracture`, `cinder_maw` and `reaper_ascended` are named in data but unimplemented, so every
  Rift currently falls back to the Reaper.
- `enemy_substitutions` is empty everywhere until the new enemy behaviours exist, so all arenas
  still field the base roster.
- Abilities unlocked by clearing levels are specified but not built.
