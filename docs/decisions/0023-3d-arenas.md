# ADR-0023: 3D arenas

> **Status:** Accepted; amended 2026-10-01 and 2026-10-02 (the zoom intro, see the Addendum) · **Date:** 2026-09-30 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Amends:** [ADR-0018](0018-pixel-art-direction.md) (no 3D art: arenas may now be 3D) and
> [ADR-0021](0021-layered-arenas.md) (the scene a run shows for an arena is now any `ArenaVisual`)

## Context
On 2026-09-30 the owner asked to make an arena 3D instead of 2D pixel art. From Claude's options the
owner answered that **arenas may be 3D** (characters, enemies and the UI stay 2D pixel art), and later
that the 3D "doesn't have to be pixel rendered". They then gave a model made in Meshy
(`Meshy_AI_Chained_Titan_s_Gameb_0930163022_texture.blend`: the hooded stone colossus holding the
arena board, one mesh of 337,015 triangles, three 2048 px textures) and an image of how the arena
should look, with: "implement the 3D model in the arena create the background scinery and add the blue
flames with godot, then rig the head and make the head move not big movements just slow and stedy
breathing like movements, dont make the arena with the 3D model too small make it little bigger then
the patchvile looking arena". From Claude's options the owner picked: bigger than **Stitchwarden's
Vigil**; keep the CHAINED COLOSSUS image arena and add the 3D one beside it; the glowing skulls of the
image too (GDD §14 #68).

## Options considered
1. **Pre-render the model in Blender** into images and show them with the layered pipeline
   (ADR-0021). No 3D at run time, but the head's motion and the fire become image sequences.
2. **Show the model live in 3D** in the arena's scene: the model, its rig and the effects run in
   Godot.

The owner's instructions (the model in the arena, the flames made with Godot, the head rigged and
breathing) describe option 2.

## Decision
Option 2.
- **`ArenaVisual`** (`scenes/arenas/arena_visual.gd`) is the scene a run shows for an arena that is not
  a painting: `fit(view, safe_top)` returns the floor as drawn, plus focus and Reduced Motion.
  `LayeredArenaVisual` (ADR-0021) and `ModelArenaVisual` extend it; GameWorld hosts either.
- **`ModelArenaVisual`** draws a 3D world in a stretched SubViewport at the design resolution (not
  pixelated; MSAA 2×, glow). Its camera looks straight at the model's floor, which faces it, so the
  floor is an exact rectangle; `fit()` sizes the floor from the screen's width, keeps the eye under
  the HUD, places the camera and returns that rectangle, which GameWorld uses for the walls. It
  breathes the head bone. A `ModelArenaLayout` resource holds the measured floor, eye, flame and skull
  points.
- **The model is prepared by a Blender script run headless** (`build_colossus.py` for this arena),
  from the owner's file kept unchanged in the arena's `source/`: it measures the floor by ray casts,
  finds the eye in the colour texture, keeps a quarter of the triangles (the floor kept whole), adds
  a two-bone rig (`root`, `head`), and exports the GLB and the layout. Blender's MCP is not used.
- **Everything around the model is made in Godot**: sky and moon, cloud banks, arches in the clouds,
  floating shards, the blue ghost fire (GPU particles), glowing skulls and the eye's glow. Every
  effect is discarded over the floor, so nothing is ever drawn over play.
- **The Shop still** is rendered from the scene by `tools/godot/render_arena_still.gd` and imported
  with `make_arena.py`, like a painted arena.

## Consequences
- The first 3D in the game. Its cost on the phone (84,253 triangles, a 12 MB model with three 2048 px
  textures, 170 flame particles, glow and MSAA in a full-screen SubViewport) is unmeasured until the
  owner's phone test.
- Blender is used again, headless, for arena models (`D:\Blender\blender.exe` on the Windows
  checkout); ADR-0018 had removed the Blender tooling on 2026-09-24.
- Characters, enemies, bosses, the UI and the HUD stay 2D pixel art (ADR-0018).
- With the HUD's safe top at 125 px the floor is 498 × 1078 on 1080 × 2340 (1.08× the Vigil's
  height there) and about 486 × 1051 on 1080 × 1920 (1.06×), where the colossus's tall head limits it;
  on the tablet shape (1200 × 1920) it is a little smaller than the Vigil's. `test_endless_catalog`
  checks the 1080-wide phones.
- Claude's values, for the phone test: the floor at 0.461 of the screen's width, the eye 230 px under
  the HUD's safe top, a 25° field of view, a breath of 4.8 s nodding ±1.2° and rising 0.004 units, the
  decimation ratio, the lights, fog and glow, and every effect's size, count, colour and placement.

## Addendum — 2026-10-01: the zoom intro
Owner: each run opens on the whole arena (the model and its scenery), then slowly zooms in until the
playable area is "basically big as the screen", tested on a new arena slot so the CHAINED COLOSSUS
3D stays as it is (GDD §14 #69). From Claude's options the owner picked: the slot **3D ZOOM ARENA**;
the character and enemies **grow with the floor** (their sizes follow the arena rect, as before); the
floor **fills the space under the HUD**; the zoom plays **every run, and a tap skips it**.
- `ArenaVisual` gains an opening shot: `has_intro()`, `play_intro()`, `skip_intro()`,
  `intro_finished`, and `get_drawn_floor_rect()` (the floor as drawn right now). GameWorld's
  `_begin_run` plays it with the Wisp and the HUD hidden and steering off, and starts the waves on
  `intro_finished`, fading the Wisp and the HUD in.
- `ModelArenaVisual.zoom_intro`: `fit()` returns the zoomed-in floor (as big as the screen allows
  under the HUD, centred there), and the camera starts on the whole model and moves, never turning,
  to the camera that draws that floor, so the floor stays an exact rectangle throughout. The zoom
  eases the floor's drawn size, slow at both ends. Reduced Motion cuts straight to the end.
- `scenes/arenas/zoom_arena_3d.tscn` is the Chained Colossus 3D scene with `zoom_intro` on.
- Claude's values, for the phone test: a 0.8 s hold on the opening shot, a 2.5 s zoom, the whole
  model at 0.86 of the screen's height in the opening shot, the floor 280 px under the HUD's safe top
  (its buttons reach 262), 24 px side and 40 px bottom margins, a 0.35 s fade-in. On a 1080 × 2340
  phone with a 125 px safe top the floor is about 875 × 1895 once zoomed in (498 × 1078 on the
  CHAINED COLOSSUS 3D).
- **2026-10-02 (owner, GDD §14 #70):** the zoom ends with the floor as big as the **whole
  screen** allows, centred, the HUD drawn over it (`play_fills_screen`, on; off restores the floor
  under the HUD above); and a run started again from its own dialogs (Results' PLAY AGAIN, the pause
  menu's restart) skips the zoom (`GameWorld.play_arena_intro`, set by Main's `_restart_run`).
