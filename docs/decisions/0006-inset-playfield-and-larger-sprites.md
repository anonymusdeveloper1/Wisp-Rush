# ADR-0006: Inset playfield to the painted floor, and larger sprites

> **Status:** Accepted · **Date:** 2026-09-12 · **Deciders:** owner (asked for both) + Claude Code

## Context
Redesign v1 ([ADR-0005](0005-visual-redesign-v1.md)) replaced the flat violet arena with a painted
obsidian sanctuary: a stone floor with scenery, waterfalls and void around its rim. The playfield
still ran to the physical screen edges, so the Wisp — which rests on an edge between dashes — sat on
painted waterfalls or behind the HUD, and at ~10 px wide on a 390 pt phone it was nearly invisible.
Enemies read as dots. That broke the style guide's first rule (the Wisp is always the brightest
small object) and the prompt's readability targets.

The original prompt calls the edge-to-edge phone layout non-negotiable, so the owner decided.

## Options considered
1. **Inset the playfield only** — the Wisp always lands on stone, but sprites stay small.
2. **Enlarge sprites only** — keeps edge-to-edge dashing, but the Wisp still rests on scenery and
   under the HUD, and bigger art over the same hitboxes reads unfair.
3. **Both** (owner's choice) — inset the playfield to the painted floor and scale sprites up.

## Decision
- The playfield is the painted stone floor: `GameWorld.ARENA_FLOOR_UV` (measured from
  `wisp_rush_arena_background.png`) is mapped through the backdrop's cover-scale into screen space,
  clamped to the screen and to `ARENA_MIN_VIEWPORT_FRACTION`. The *display* stays edge-to-edge
  (full-bleed art, no letterbox); only the dashable area is inset.
- Sprites and their hitboxes grow together, so aiming stays as fair as before: player and enemies
  ×1.45 (player radius ratio 0.03 → 0.05), hazards, the Reaper's body/core and pickups ×1.3.
  Reaper attack geometry (sweep, lanes) is unchanged: the smaller arena already makes it relatively
  larger.
- HUD margins are computed from the viewport, not the playfield, and the wall-impact flash is drawn
  on the playfield edge.

## Consequences
- GDD §12's edge-to-edge rule now means full-bleed presentation, not a full-screen playfield.
- Dash distances shrink with the arena, so runs play slightly tighter; wave tuning is unchanged
  because formations and spawn distances are all arena-relative.
- If the arena background is repainted or recropped, re-measure `ARENA_FLOOR_UV`.
