# ADR-0014: Endless arenas share one canonical floor template

> **Status:** Accepted · **Date:** 2026-09-14 · **Deciders:** owner (purchasable Endless backgrounds
> that never help the player) + Claude Code · **Relates to:**
> [ADR-0011](0011-polygon-playfield-from-art.md) (Rifts keep art-derived walls),
> [ADR-0006](0006-inset-playfield-and-larger-sprites.md) (design scale),
> [ADR-0013](0013-rift-story-levels-endless-mode-and-rift-points.md) (Endless mode)

## Context
- ADR-0011 derives each Rift's wall from its painted floor. That is right for Rifts, whose shape is
  part of their identity, and wrong for Endless skins, which are cosmetics: a skin would change the
  room, dash lengths and difficulty.
- Measured on 2026-09-14 from `data/rifts/*.tres`: floor areas range from 85 % to 100 % of the largest
  floor; the shape all five share keeps 69–82 % of each (63–74 % if also mirror-symmetric).
- The Rifts v1 prompts described the floor only as text percentages. The generator ignored them —
  the floors came out oval and jagged — which is what led to ADR-0011.

## Options considered
1. **Per-skin walls derived from art (as ADR-0011)** — every skin would play differently. Rejected.
2. **The intersection of the five Rift floors** — small, irregular, and no existing background fits
   it. Rejected.
3. **One fixed chamfered rectangle, with the art painted to it** — every skin plays identically, and
   the shape matches the cut-stone UI language. **Chosen.**

## Decision
- **The template** is `GameWorld.ARENA_FLOOR_UV` (u 0.145–0.845, v 0.255–0.770 of the 941×1672
  background) with each corner cut at 45° by 80 texture px. Eight UV vertices, clockwise:
  `(0.23002, 0.255) (0.75998, 0.255) (0.845, 0.30285) (0.845, 0.72215) (0.75998, 0.77)
  (0.23002, 0.77) (0.145, 0.72215) (0.145, 0.30285)` — about 659 × 861 px, UV area 0.352 (the Rift
  floors span 0.319–0.376).
- **One source per consumer.** Art uses `concept_art/wisp_rush_endless_v1/floor_template.json`
  (rendered by `tools/art/make_endless_floor_template.py`). The game uses `EndlessCatalog.floor_polygon`,
  and a test keeps the two equal. **Skins never carry a polygon**, so no skin can change the shape.
- **Art contract** for every Endless skin:
  - exactly 941×1672 RGB;
  - the walkable floor covers the template and bleeds at least 12 px past it;
  - a visible rim sits 12–48 px outside the template edge and follows it, including the chamfers;
  - nothing but flat, dark, low-contrast surface inside the template, and scenery outside the rim;
  - nothing important outside u 0.10–0.90 (20:9 phones crop it); v < 0.255 sits under the HUD.
- **Every generation attaches `floor_template_layout.png`** as its layout reference. Each result is
  checked by a tool and by eye against the template before it enters the game
  ([spec 05](../specs/story_and_endless/05_endless_arena_art.md)).
- **No code-drawn edge line.** The painted rim marks the playable area; the owner removed wall
  highlights on 2026-09-12.
- Rifts are unchanged and keep their art-derived polygons.

## Consequences
- Every Endless skin plays identically, so daily and best scores stay comparable across skins.
- The template's bounding box is the formation distribution rect, so placements only need correcting in
  the four chamfer corners, and the Wisp's design scale is unchanged.
- Rift backgrounds cannot be reused as Endless skins; each skin is new art.
- The template is frozen: changing it means regenerating and re-validating every skin.
- The property tests over real polygons (`test_dash_geometry`) must include the template.

## Addendum — 2026-09-15: animated scenery
Owner decision: Legendary and Mythic skins get code-rendered scenery ambience (`ArenaAmbience`, driven by
`ArenaSkinData.ambience`). It keeps this ADR's contract: the painted art and the floor never change,
and every effect is confined to a UV region that `EndlessCatalog.validate()` keeps outside the template
grown by `rim_tolerance_px`, so nothing animates over the playfield. Reduced Motion stills it.

**Revised 2026-09-16** (owner feedback 2026-09-15, device test): the scenery now works on the painting
itself — a generated per-skin mask (`tools/art/endless_scenery.py`), a scenery shader on the backdrop and
mask-gated particles (`ArenaSkinData.scenery`, `ArenaSceneryData`). The runtime art files still never
change; at runtime the scenery is graded and animated, while the floor gets only a saturation lift with its
luminance kept, and all light, motion and particles stay outside the template grown by `rim_tolerance_px`
(mask-gated and validated). Collision and the template are untouched. Details: `docs/systems/endless_mode.md`.
