# ADR-0007: Rifts are rule-variant arenas, not reskins

> **Status:** Accepted · **Date:** 2026-09-12 · **Deciders:** owner (requested arenas + a map UI) + Claude Code

## Context
Wisp Rush had one endless mode in one arena. Nothing carried between runs, and the only Soul Shard
sink was the six cosmetic forms — exactly 4,750 shards — after which the currency was inert and
every run looked the same. The owner asked for multiple arenas, each with its own area and
escalating missions, plus a map UI.

The playfield is a rectangle the Wisp bounces inside (`ARENA_FLOOR_UV`, [ADR-0006](0006-inset-playfield-and-larger-sprites.md)).
A new painting behind that rectangle changes nothing about how the game plays: the player notices it
once. Meanwhile each new arena costs a generated background, pipeline wiring and QA at five phone
sizes.

## Options considered
1. **Backgrounds only** — cheapest, but five arenas that play identically. The variety is cosmetic
   and the unlock ladder rewards the player with nothing mechanical.
2. **Arena + one rule twist each** — every Rift owns a `rule_key` that changes one rule of the run.
   Costs a small mechanic per Rift on top of the art, and every twist has to stay readable on a
   phone alongside the existing formations.
3. **Separate game modes per arena** — maximum differentiation, but it splits a one-mechanic game's
   player base and multiplies balance and QA work across modes.

## Decision
Option 2. A Rift is `RiftData`: identity, backdrop, unlock gate, accent, and exactly one
`rule_key` naming its twist. `RiftCatalog` is the ordered ladder.

- **Unlock is derived, never stored.** `RiftData.is_unlocked(highest_wave)` reads the lifetime best
  wave the save already tracks, so an unlock flag can never desync from progression. Gates are
  0 / 5 / 10 / 15 / 20, deliberately aligned with the Milestone 7 depth milestones.
- **Every backdrop is exactly 941×1672**, the original arena's size, so `ARENA_FLOOR_UV` maps the
  playfield identically in every Rift and no per-Rift geometry tuning exists.
  `test_rift_catalog.gd` asserts this — it is the constraint most likely to be broken by new art.
- **Save schema v2** adds `selected_rift` and `rift_bests`. A v1 save migrates by gaining the
  defaults; unknown rift ids are dropped by the sanitizer.
- **Presentation is data.** The Rift map builds its rows from the catalog, so adding a Rift is a
  `.tres` plus a background, not a scene change.

## Consequences
- Adding a Rift means authoring one twist, not just generating art. That is the point: it is the
  gate that stops the ladder becoming five recolours.
- `rule_key` is stored and latched at run start but **no twist is implemented yet** — every Rift
  currently plays as the baseline. Until they land, the map advertises rules the game does not
  honour, so the Rifts must not ship to players in this state.
- GDD §12's phone QA matrix now has five arenas to cover instead of one.
- The three new enemies and the second boss generated alongside the Rift art are **art only** — no
  tuning, behaviour or scene exists. They are recorded as assumptions in GDD §14 because the GDD
  never specified them.
