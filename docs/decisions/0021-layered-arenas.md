# ADR-0021: Layered arenas

> **Status:** **Superseded by [ADR-0027](0027-one-arena-simulation.md)** (2026-10-05: the Vigil and the layered-arena code removed; `ArenaVisual` stays, for SIMULATION; kept as history); Accepted; the Vigil's floor and art were revised by [ADR-0022](0022-vigil-art-and-floor-revision.md); the arena scene contract is `ArenaVisual` since [ADR-0023](0023-3d-arenas.md) · **Date:** 2026-09-30 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Amends:** [ADR-0017](0017-painted-arenas-with-bleed.md) (an arena is one painted image) and
> [ADR-0020](0020-an-arena-may-bring-its-own-floor.md) (corrects its note on sizes)

## Context
The owner's third arena, **Stitchwarden's Vigil**, is not one image. Its kit
(`concept_art/arenas_v2/stitched_doll_pixel_kit/`, made with Codex, GDD §14 #64) is separate pieces:
jungle plates and trees, a floor and a frame, the doll's body, head, grip hands, scythe and two cloth
panels, a lantern, fog, and four-frame loops for the scythe's flame, wisps and flying creatures. Its
README sets out how they move: the head turns toward play, the cloth waves from a fixed root, the
flame loops on the blade, the lanterns flicker, wisps and bats travel behind the board, fog drifts.

The owner (2026-09-30): keep the two existing arenas as they are and add this one; it is animated;
its playable area is "a little bit bigger" than the Stitched Doll Jungle's; vertical play only, no
16:9 composition; and an example image of how it should look. The kit's pieces were generated
separately (no shared canvas, pixel sizes from about 3 to 12 source px) and its board was drawn
around a small floor.

## Options considered
1. **Flatten the kit into one painted image** (ADR-0017's pipeline) — fits the existing code; nothing
   moves.
2. **One painting plus `ArenaAmbience`** — its shader animates regions of a painting; it cannot turn a
   head, wave cloth from a root or loop sprite frames.
3. **A layered scene** — the arena is a Godot scene of sprites on one texel grid; a run shows it
   instead of the backdrop and takes the floor from it.

## Decision
Option 3. `ArenaSkinData.visual_scene_path` names a `LayeredArenaVisual` scene (`scenes/arenas/`), and
`ArenaRules.get_visual_scene()` hands it to GameWorld, which shows it in place of
`%FullBleedBackground`. `LayeredArenaVisual.fit(view, safe_top)` covers the screen with the backdrop,
scales the centre group uniformly (as big as the screen allows, at most 4 design px per texel, the
head `head_clear` px under the HUD's safe top) and returns the floor as drawn. GameWorld uses that
rectangle as the arena rect and its corners as the walls, without `ARENA_MIN_VIEWPORT_FRACTION`, so the
walls, formation placement, the bosses' walls and dash collision all follow the drawn floor. The
skin keeps a 941 × 1672 still (`background_path`) and a thumbnail for the Shop, and the still's floor
as its own floor (ADR-0020) for the catalog test.

The Vigil is packed by `concept_art/arenas_v2/stitchwarden_vigil/pack_vigil.py`, which also generates
its scene: every piece resampled onto one texel grid with hard alpha and a limited palette; the board
rebuilt around a floor of 152 × 304 texels (608 × 1216 design px on a 1080-wide phone, where the
jungle's painted floor is 580 × 1142) — the frame's rails repeat a plain section on each side of the
banner, its posts lose a band from the middle, the top banner loses the rows that hung into the floor,
and the floor is 4 × 8 of the kit's tiles; the body sits behind the board with the kit's grip hands on
the rail. The packer fails if anything drawn over the floor reaches into it.

## Consequences
- The character, enemies and effects are sized from the arena rect's width, as on every arena. On the
  Vigil that is the drawn floor (608 px on a 1080-wide phone), so they are about 20 % smaller there
  than on the Stitched Doll Jungle, whose rect is widened to 756 px.
- **Correction to ADR-0020:** its note that the character and enemies are drawn smaller on an arena
  with its own floor is wrong. `ARENA_MIN_VIEWPORT_FRACTION` still widens that arena's layout rect to
  70 % × 50 % of the screen (756 × 1170 px on 1080 × 2340 for the jungle, against its painted
  580 × 1142): the walls follow the painted floor, while sizes, formation placement and Grimgrin's
  walls follow the wider rect.
- Motion lives in the arena's own script (`scenes/arenas/stitchwarden_vigil.gd`) and two shaders
  (`cloth_wave`, `lantern_flicker`). It pauses with the run, and Reduced Motion holds it still.
- Screens wider than a phone show the portrait jungle plate, cover-scaled; the kit's wide pieces are
  not used (owner: vertical play only).
- The layout constants (the fit's margins, the doll's and the scythe's pose) were tuned on a
  1080 × 2340 screen with an assumed safe top of 125 px, so that the scythe clears the pause and
  UPGRADE buttons and the head clears the HUD's bars; the packer prints that check for each phone size
  it reviews.
