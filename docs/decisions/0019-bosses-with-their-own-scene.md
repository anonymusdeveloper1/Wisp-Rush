# ADR-0019: Bosses of the new set bring their own scene

> **Status:** Accepted · **Date:** 2026-09-27 · **Deciders:** Claude Code ·
> **Extends:** [ADR-0010](0010-data-driven-boss-variants.md)

## Context
ADR-0010 made every boss a data variant of one phase machine, `ReaperBoss`. The owner's new set
(Enemies v2, GDD §14 #58) wants every boss to be its own design with its own attacks, and the first,
Grimgrin (§14 #59), fights nothing like the Reaper: he lives on the walls, dashes between them, rots a
wall and marks the Wisp. His fight does not fit the Reaper's sweep / teleport / corridor grammar.

## Decision
- **`BossActor`** (`res://scenes/bosses/boss_actor.gd`) is the one interface `GameWorld` drives a boss
  through: the signals, configuration, the Wisp's position and landings, the danger geometry, dash
  hits, the phase name and the victory numbers. Every method has a safe default. `ReaperBoss` extends
  it unchanged in behaviour.
- **`BossData.scene`**: a boss with its own scene plays it; null keeps the shared `ReaperBoss` with the
  variant's frames and tuning, so the five old variants are untouched. `BossData.approach_callout`
  names the arriving boss.
- `GameWorld` gains one request, **`spawn_requested(count, max_live)`**, for bosses whose fight spawns
  regular enemies at random.

## Consequences
- A new boss is a scene and a script of its own; the old variants stay data files until the new set
  replaces them.
- Danger still reaches the Wisp only through circles and lanes, so the contact, dash-path and
  safe-reform code in `GameWorld` serves every boss.
