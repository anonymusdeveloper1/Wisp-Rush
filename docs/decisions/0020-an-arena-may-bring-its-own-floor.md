# ADR-0020: An arena may bring its own floor

> **Status:** **Superseded by [ADR-0027](0027-one-arena-simulation.md)** (2026-10-05: these arenas removed; kept as history); Accepted; its note on sizes is corrected by [ADR-0021](0021-layered-arenas.md) ·
> **Date:** 2026-09-30 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Amends:** [ADR-0017](0017-painted-arenas-with-bleed.md) (one shared floor for every arena)

## Context
ADR-0017 gives every Endless arena one shared floor (`EndlessCatalog.floor_rect` / `floor_polygon`):
an arena is painted to the contract with its floor in the same place, so it only changes the look.
The owner's second arena, the **Stitched Doll Jungle** (a giant stitched doll holding the floor over
jungle ruins at night, 941 × 1672, placed in `concept_art/arenas_v2/stitched_doll_jungle/` by Codex),
paints its floor elsewhere: x 265–679, y 450–1266 (414 × 816 px) against the shared 636 × 948 at
x 152–788, y 365–1313. The owner keeps the image as it is ("it won't be changed. Keep this arena like
this for now").

## Options considered
1. **Its own floor** — the walls follow its painted frame while it is equipped. The picture stays
   untouched; the play area there is about two-thirds as wide and a little taller, and since the
   character and enemies are sized from the floor's width, they are drawn smaller there.
2. **Stretch to fit** — stretch the picture about 1.5× wider so its floor fills the shared one. Play is
   unchanged; the art is visibly distorted.
3. **Scale up and crop** — enlarge it evenly until its floor is as wide as the shared one. The top and
   bottom walls then land inside its tiles, and the doll and the edges are cut off.

## Decision
Option 1, the owner's pick (2026-09-30). `ArenaSkinData.floor_rect` (UV of the arena's background, as
`tools/art/make_arena.py` prints it) is an arena's own floor; zero size keeps the shared floor.
`EndlessArenaRules.get_floor_rect_uv()` and `get_floor_polygon()` return the equipped arena's own floor
when it has one (its rectangle's corners), else the shared floor. Everything that lays out a run
already reads those two, so formations, hazards, spawns, bosses and the character follow.

## Consequences
- An arena with its own floor changes how a run plays while it is equipped: the space is narrower and
  the character and enemies are smaller. Arenas painted to the contract still share one floor and stay
  cosmetic.
- `test_endless_catalog` compares each arena's measured floor (`arena.json` `floor_rect_px`) with the
  floor the game uses for it, the shared one or its own.
- The daily run can draw such an arena as the arena of the day; it plays on that arena's floor.
