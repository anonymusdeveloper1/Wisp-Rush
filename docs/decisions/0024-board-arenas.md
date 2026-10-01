# ADR-0024: Board arenas — a full-screen board with the HUD in its frame

> **Status:** Accepted · **Date:** 2026-10-02 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Builds on:** [ADR-0021](0021-layered-arenas.md) and [ADR-0023](0023-3d-arenas.md) (an arena may be a
> scene, an `ArenaVisual`)

## Context
On 2026-10-02 the owner chose a new direction for the arena (GDD §14 #71): the game is played on a
**full-screen board** like their reference image (a wooden, iron-bound frame around a stone floor), in
pixel art with "not too big pixels"; **the HUD is in the board** — RUSH, soul level, the boss
indicator, the Rift Points counter, the score and the pause button; **the upgrades open when the
character is tapped**, the board shows that an upgrade is available and the character has a little
light on him. Codex made every piece from `concept_art/boards_v1/board_01/CODEX_PROMPT.md`; then the
owner: "implement" (GDD §14 #72).

## Options considered
1. **One painted image** with the HUD on top (ADR-0017): the board could not fit every phone shape
   without stretching, and the HUD would still float over it.
2. **A board built from its pieces at run time**, sized to the screen, with the HUD drawn into the
   frame by the board and fed by GameWorld.

## Decision
Option 2, as a new kind of arena scene.
- **`BoardArenaVisual`** (an `ArenaVisual`) builds the board from the pieces in its `art_dir`
  (`assets/art/environment/boards/<board>/`, copied unchanged from the Codex kit by
  `tools/art/make_board.py`): the floor tiled with a few variant slabs, posts, beams, corners, caps,
  the wall line, gauges, plates, lanterns and decorations, on one grid of 540 art pixels across the
  screen (2 design pixels per art pixel on a 1080-wide screen), nearest filtering. Its `fit()` returns
  the floor inside the frame: the walls are the frame's inner edge.
- **The HUD in the frame:** the pause button (top-left), the boss plate or a crest (top centre), score
  over Rift Points (top-right), the soul gauge with the level (left post), the RUSH gauge with its
  flare when full (right post), four lanterns that glow while upgrades are ready, and a count tag when
  more than one is.
- **GameWorld** keeps its own HUD logic. With a board equipped (`has_board_hud()`), its HUD bars and
  buttons move under a hidden holder, keep being updated, and are read each frame into
  `set_board_hud()`; the board's pause button emits `hud_pause_pressed`. The combo and focus callouts,
  the instruction line and the upgrade cards stay where they were.
- **Tap the character for the upgrades:** an `UpgradeGlow` (stepped amber rings, no blur) shows
  behind the character while upgrades are ready; a press that starts on him and lifts before the dash's
  minimum swipe distance and 450 ms opens the cards. The press still reaches the Wisp, so an aim can
  start on him; the tap's release does not, and the aim is dropped as the cards open.
- **Two test slots:** BOARD 01 (the mid-dark floor the arena guide asks for) and BOARD 01 LIGHT (the
  lighter tan of the owner's reference), so the owner can compare them on the phone. Every other arena
  keeps the floating HUD.

## Consequences
- The play area is the screen minus the frame: 936 × 1990 design pixels on a 1080 × 2340 phone with a
  125 px safe top.
- Every future board must keep the same slots and sizes (CODEX_PROMPT.md §4–§5) so the code fits it;
  only the art changes.
- Claude's values, for the phone test: the slot positions on the top beam, the gauges starting 76 art
  px under the floor's top and running about 42 % of its height, the lantern frame time (0.14 s),
  the decorations' spacing, the 20 art px bottom cap, the font sizes (32 / 28 / 18), the glow (2.2 ×
  the collision radius, 1.2 s breath) and the tap's reach (2.4 × the collision radius).
