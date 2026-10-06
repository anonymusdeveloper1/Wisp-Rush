# ADR-0017: Painted arenas with bleed, picked in a pager

> **Status:** **Superseded by [ADR-0027](0027-one-arena-simulation.md)** (2026-10-05: the painted arenas and the painted-background path removed; kept as history); Accepted; amended by [ADR-0020](0020-an-arena-may-bring-its-own-floor.md) (an arena may
> bring its own floor) and [ADR-0021](0021-layered-arenas.md) (an arena may be a layered scene) · **Date:** 2026-09-23 · **Deciders:** owner / Claude Code (Opus 5.5)
>
> Supersedes [ADR-0014](0014-endless-arenas-share-one-floor-template.md) (the frozen 941×1672
> floor template and the thirty generated Endless skins). Rifts are unchanged
> ([ADR-0011](0011-polygon-playfield-from-art.md)).

## Context
The owner removed all thirty Endless arena skins and supplied one painted arena (a mining mech
holding the stone floor), asking for a Shop pager like the CHARACTERS one and an image that is
"fixed in every phone size", looks good and is never cropped — and, asked, neither blurred nor
barred. The old skins were 941×1672 (9:16) images drawn cover-scaled: on a 19.5:9 phone that cuts
~9 % off each side and draws the floor ~25 % larger than on 16:9.

## Options considered
1. **Fit the 9:16 image, fill the rest** (blurred copy or a colour) — never crops, but the owner
   rejected both fills.
2. **Stretch** — fills without bars, distorts the art.
3. **Paint with bleed** — one image as tall as the tallest supported phone (1080×2400, 20:9); the
   parts a shorter phone loses are sky and ground only, and everything that matters sits in a
   1080×1920 safe zone. No bars, no stretching, nothing important cropped; the floor lands 1:1 in
   design pixels on every phone from 16:9 to 20:9.

## Decision
Option 3. An arena is one painted image to the contract in
[docs/guides/arena_art.md](../guides/arena_art.md): 1080×2400 canvas, safe zone y 240–2160, 60 px
side margin, and a shared floor at x 174–904, y 659–1747 (the Quarry Titan's). The floor lives once in
`EndlessCatalog` (`floor_rect` for layout, `floor_polygon` for the walls), so an arena stays
cosmetic. `ArenaRules.get_floor_rect_uv()` lets an arena bring its own layout rectangle; the Rifts
keep `GameWorld.ARENA_FLOOR_UV`. The Shop's ARENAS tab is the same FocusCarousel pager as CHARACTERS,
showing each arena whole. `tools/art/make_arena.py` turns a source image into the background and
thumbnail and draws the layout guide.

## Consequences
- **Until the Quarry Titan is re-delivered at 1080×2400** the catalog runs on its delivered
  941×1672 canvas: correct floor, but on phones taller than 16:9 its sides are trimmed. Switching is
  `BACKGROUND_SIZE` and the floor numbers (guide §4).
- The thirty skins' data and 69 MB of art are gone; old saves keep only the default arena (the
  sanitizer drops unknown ids). The generators that made them (`extract_endless.py`,
  `make_endless_skin_data.py`, `endless_scenery.py`, `make_endless_floor_template.py`,
  `check_endless_skin.py`, `set_endless_import_lossy.py`) are retired.
- The animated-scenery system (`ArenaAmbience`, `ArenaSceneryData`, the scenery shaders) has no
  arena using it; it stays as code for a painted arena that wants it, untested by
  `test_endless_catalog` since the Mythic skins left.
- A generated image rarely lands the floor exactly; each new arena is measured (`arena.json`) and
  the catalog test fails when it disagrees with the shared floor, so it gets fitted before it ships.
