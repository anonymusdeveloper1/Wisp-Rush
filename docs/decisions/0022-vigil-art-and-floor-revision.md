# ADR-0022: Revise Stitchwarden's Vigil art and floor

> **Status:** Accepted · **Date:** 2026-09-30 · **Deciders:** owner / Codex ·
> **Amends:** [ADR-0021](0021-layered-arenas.md) (the Vigil's first floor size and art assembly)

## Context
The first playable Stitchwarden's Vigil was assembled from the original separate kit. After seeing
it in the game, the owner supplied `ChatGPT Image Sep 30, 2026, 01_04_52 AM.png` as the target and
asked for a closer doll, board, scythe fire and background. The owner then requested the target's
smaller floor proportions, a little larger than the target image's floor, a mild tilted impression,
the whole head rather than only the face moving, and clothes that move with the doll.

## Decision
Keep ADR-0021's layered scene and rectangular gameplay walls. Rebuild the Vigil's sources and pack
them at a 120 × 264-texel floor. The board frame has a small top taper in its shader; the floor and
its collision rectangle stay aligned. The doll's hood and face share a `HeadRig` pivot and follow
the Wisp together. Its scarf, shoulder cloth, tunic and hanging cloth panels move with wind and
respond to the turn, while the gloves stay on the rail. Fire follows the curved scythe blade as
a separate animated layer. The two painted arenas remain unchanged.

## Consequences
- `source_v2/` and `pack_vigil.py` generate the scene, runtime pieces, Shop still and thumbnail.
  The original kit remains as source history.
- The new floor is about 453 × 996 design pixels at 1080 × 2340; the Stitched Doll Jungle's
  painted floor there is 580 × 1142. The Shop still's measured floor is x 274–667, y 451–1316
  on its 941 × 1672 canvas.
- The whole head motion pauses with play and resets under Reduced Motion, alongside the cloth,
  fire, lanterns, wisps, bats and fog.
