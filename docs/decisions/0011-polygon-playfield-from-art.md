# ADR-0011: The playfield is each Rift's painted floor, derived from its art

> **Status:** Accepted · **Date:** 2026-09-12 · **Deciders:** owner (chose option 4 of 6) + Claude Code ·
> **Supersedes the wall half of:** [ADR-0006](0006-inset-playfield-and-larger-sprites.md) (its scale guarantees stand)

## Context
Since ADR-0006 the playfield was one rectangle, `GameWorld.ARENA_FLOOR_UV`, shared by every Rift.
That was honest for rectangular floors and wrong for the rest. The owner saw it on device: in
Ember Hollow the rectangle's corners sat out over the lava, so the Wisp bounced off an invisible
wall visibly inside the painted edge. Measured afterwards, **0 of the rectangle's 4 corners lie on
the painted floor** in four of the five arenas, and 2 of 4 in Reaper's Court. ADR-0006 described
it as "the largest rectangle inscribed in its octagon"; it overhung.

## Options considered
Six were put to the owner: a per-Rift rectangle; drawing a visible wall; a per-Rift
rect/ellipse/octagon shape; **deriving the boundary from the art**; recompositing the art to fit
the rectangle; and shading everything outside the playfield. The owner chose deriving it from the art.

## Decision
- `tools/art/extract_floor_polygons.py` reads each Rift's **final runtime** background and bakes a
  24-vertex polygon, in texture UV space, into `RiftData.floor_polygon`. Floor-likeness is scored
  on two cues only — smooth and desaturated. **Luminance is deliberately excluded**: Frozen Choir's
  floor is pale ice while every other floor is dark stone, so any brightness rule fails one arena.
- The bake **clamps the top to V = 0.255**, the old rectangle's top edge. Four painted floors reach
  far above it (Frozen Choir to 0.124), which would put the resting Wisp back behind the HUD header
  — the exact bug ADR-0006 fixed.
- **The rectangle is kept, unchanged, as the design-pixel scale and distribution domain.** The
  polygon's bounding box is 11–28 % wider than the rectangle; a dozen sites divide by that width,
  including the Wisp's collision radius. The polygon is the wall and nothing else.
- GameWorld maps both through one `_backdrop_image_rect()`, insets the polygon once by
  `LANDING_INSET × radius` into a `_landing_polygon`, and pushes it to the player, enemies and boss.
  The bare `1.35` that three sites used to repeat now exists only as `LANDING_INSET`.
- **The resting edge is excluded from the dash cast by identity, not distance.** A distance-based
  skip also discards legitimate short dashes into a corner, which silently swallows the swipe.
- Edge normals come from the polygon's **winding**, not a comparison against the centroid.
- Placement (formations, hazards, portals, split children, boss teleports, the tutorial chain) stays
  authored in the rectangle and is made legal by `_place_on_floor()`.
- A Rift with no baked polygon falls back to the rectangle, so nothing breaks without art.

## Consequences
- Every arena's walls now match its painting. Total area is comparable (0.32–0.375 of the image
  against the rectangle's 0.360), redistributed from overhanging corners to the mid-edges.
- Formation data turned out almost entirely compatible: across 3,520 placements only 19 (2.7 %, all
  Shattered Rift) start off the floor, and correcting them never collapses two enemies together.
- Impact normals are no longer one of four axis vectors. The impact squash still picks one of two
  presets by the dominant axis, and the wall flash is still an axis-aligned rectangle — both are
  approximate on slanted edges.
- New art needs a re-run of the extractor and a look at `logs/rifts/floor_<rift>.png`; the bake
  is a heuristic, not ground truth.
