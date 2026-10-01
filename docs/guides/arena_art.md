# Arena art — the contract

> What an Endless arena image must be so it fits every phone without bars, blur, stretching or
> cropping anything that matters, and so every arena plays on the same floor. Owner decision
> 2026-09-23 ([ADR-0017](../decisions/0017-painted-arenas-with-bleed.md)): the thirty generated
> Endless skins were removed; arenas are single painted images, picked in the Shop's ARENAS pager.

**Pixel art** (owner, 2026-09-24, [ADR-0018](../decisions/0018-pixel-art-direction.md)): draw the
arena at **270 × 600** art pixels and scale it up **4× with nearest neighbour** to the 1080 × 2400
canvas below. That is the same 4 px grid as the UI and Home. Use a limited palette with crisp edges,
and no anti-aliasing, gradients or blur. Keep the floor edges on the grid: the ±6 px floor tolerance
in §2b covers snapping them to multiples of 4. The Quarry Titan and Wisp Bearer are painted, and stay
legacy until they are redrawn.

**Layout guide:** [`concept_art/arenas_v2/_layout/arena_layout_guide.png`](../../concept_art/arenas_v2/_layout/arena_layout_guide.png)
— every zone below drawn on the canvas over the Quarry Titan. Give it to the image generator as the
layout reference. Regenerate it with `python tools/art/make_arena.py --guide`.

---

## 1. Why a fixed image needs bleed

Phones run from 16:9 to 20:9 and taller. The game is 1080 design pixels wide on all of them and only
the height changes (1920 on 16:9, 2340 on 19.5:9, 2400 on 20:9). One image cannot fill all of those
unless it is **as tall as the tallest** and the extra height is **unimportant**: sky above, ground
below. On a shorter phone that extra — the **bleed** — falls off the top and bottom. Everything that
matters sits in the **safe zone**, which every phone shows.

The game draws the background cover-scaled, so a 1080 × 2400 image is drawn **1:1** on every phone
from 16:9 to 20:9: the floor is the same size, in the same place, on all of them.

## 2. The numbers

All in pixels of the arena canvas. `tools/art/make_arena.py` holds the same constants.

| Zone | Rectangle | Rule |
|---|---|---|
| **Canvas** | **1080 × 2400** (20:9, portrait) | Opaque PNG or WebP, sRGB, exactly this size |
| **Safe zone** | x 0–1080, **y 240–2160** (1080 × 1920) | Always visible. The frame (the mech), the floor and anything that matters live here |
| **Bleed, top** | y 0–240 | Sky only — cut on 16:9 phones, partly on 19.5:9 |
| **Bleed, bottom** | y 2160–2400 | Ground only — cut on 16:9 phones, partly on 19.5:9 |
| **Side margin** | 60 px each side | Phones taller than 20:9 (21:9, 22:9) trim up to ~55 px off each side: nothing important there |
| **Floor (the playfield)** | **x 174–904, y 659–1747** (730 × 1088) | Plain and calm: enemies, hazards and the character must read on it. No props, text or bright detail |
| **Rim** | a clear edge 30–40 px wide just outside the floor | The character rests against it; it is where the walls are |
| **HUD, top** | y 240–560 on a 16:9 phone | Score, readouts, pause. Paint scenery there, never the floor |
| **HUD, bottom** | y 2040–2160 on a 16:9 phone | The RUSH bar |

The floor is shared: every arena paints it in the same place (`EndlessCatalog.floor_rect` /
`floor_polygon`), so an arena is cosmetic and never changes how a run plays. The one exception is an
arena the owner keeps with its floor elsewhere: it brings its own floor (`ArenaSkinData.floor_rect`,
[ADR-0020](../decisions/0020-an-arena-may-bring-its-own-floor.md)), and while it is equipped the walls
follow its frame (§4).

**Machine-readable:** [`_layout/arena_spec.json`](../../concept_art/arenas_v2/_layout/arena_spec.json)
(every rectangle above) and [`_layout/arena_floor_mask.png`](../../concept_art/arenas_v2/_layout/arena_floor_mask.png)
(1080 × 2400: white = floor, grey = rim, black = the rest — usable as an inpainting mask). Both come
from `make_arena.py --guide`, so they never disagree with this page.

## 2b. The playable area — rules for an image generator

The floor is where the whole run happens: the character rests against its edges and dashes across
it, enemies, hazards and pickups appear anywhere on it. Anything painted there is something the
player has to read the game *through*.

| Rule | Why |
|---|---|
| **Exactly x 174–904, y 659–1747** (730 × 1088), each edge within **±6 px** | The walls are the floor's edges; a floor painted elsewhere puts the walls in the air or in the scenery |
| **A flat, axis-aligned rectangle seen straight on** — right-angle corners, no perspective, no tilt, no rounded or broken edges | The walls are straight lines on those four edges |
| **A clear rim 40 px wide just outside it** (x 134–944, y 619–1787), lighter or darker than the floor | The character rests against the rim; it must read as a wall |
| **Nothing overlaps the floor or the rim**: no hands, cables, claws, banners, shadows or particles from the frame | Anything over the floor looks like an obstacle and hides enemies |
| **Plain surface**: one even mid-dark value, ≈ 30–40 % brightness, varying by no more than ±7 % across it (the Quarry Titan's: 35 %, 33–38 %), a muted cool or neutral colour, subtle texture only (tiles, stone slabs, fine cracks) | Enemies, hazards, pickups and the character must be the brightest, most saturated things on it |
| **No props, holes, pits, lava, water, glowing runes, light pools, bright spots, text, symbols or characters** on the floor | Each reads as a hazard, a target or a gameplay element that is not there |
| **No strong lines inside** that could read as a wall; keep tile seams faint | The player judges dashes against the real walls |
| **The first 150 px inside every edge** are as plain as the centre | That is where the character stands and where most dashes land |
| **The frame (mech, walls, statues…) sits wholly between the rim and the safe zone's edges**, y 240–2160, 60 px from the sides | Outside that it is cut off on some phones |
| **Bleed bands hold only sky (top) and ground (bottom)** | They are cut off on 16:9 phones |
| **The layout guide must not appear in the output**: no coloured bands, outlines or labels | It is a reference, not art |
| Opaque, 1080 × 2400, PNG | The game loads it as is |

## 3. Delivering an arena

1. Generate at 1080 × 2400 with the layout guide as the reference, or make it at 1080 × 1920 (the
   safe zone) first and extend it: add 240 px of sky above and 240 px of ground below with an
   "expand" / outpaint tool, without moving anything in the original.
2. Put it in `concept_art/arenas_v2/<id>/` as `source.png` (or `.webp`) with an `arena.json`: `id`,
   `display_name`, `description`, `source`, and `floor_rect_px` — the painted floor's
   `[left, top, right, bottom]`, measured on the rim's inner edge.
3. `python tools/art/make_arena.py <id>` writes the background and the Shop thumbnail under
   `assets/art/environment/arenas/` and prints the floor in UV.
4. Add `data/endless/skins/<id>.tres`, list it in `default_endless_catalog.tres` and in
   `SaveManagerService.VALID_ARENA_SKIN_IDS`, then `tools/validate.sh` and
   `tools/run_tests.sh endless_catalog` — the test fails if the measured floor is not the catalog's.

## 4. Where things stand

The **Quarry Titan** (2026-09-23) was delivered at **941 × 1672** — the safe zone's shape with no
bleed. Until it is re-delivered at 1080 × 2400 the catalog uses its own canvas
(`EndlessCatalog.BACKGROUND_SIZE` = 941 × 1672, floor measured at x 152–788, y 365–1313), so on a
phone taller than 16:9 its sides are trimmed and the arena is drawn a little larger. To finish it:
scale it to 1080 wide (1080 × 1919), centre it on a 1080 × 2400 canvas and outpaint the 240 px
bands; then set `BACKGROUND_SIZE` to 1080 × 2400 and the floor to the numbers in §2.

The **Stitched Doll Jungle** (2026-09-30, the owner's image placed by Codex) is also **941 × 1672** with
no bleed, and its floor is not the shared one: x 265–679, y 450–1266 (414 × 816), measured on the
frame's inner outline; lanterns and cloth hang over its corners and top edge. The owner keeps it as it
is, so it brings its own floor (ADR-0020): its walls follow the frame; GameWorld's layout rect,
which sizes the character and enemies, is still widened past it (ADR-0021 corrects ADR-0020).

The **Chained Colossus** (2026-09-30, the owner's image, GDD §14 #67) is **941 × 1672** with no bleed
and brings its own floor the same way: x 282–667, y 470–1277 (385 × 807). Its painted floor widens
slightly downward (the frame's inner edge is at x 288 / 655 near the top, x 278 / 673 near the
bottom), so the sides are the best-fit straight lines. The owner keeps the image as sent, including
the floor's emblem, the hand's shadow, the rubble and the brackets and chain over its edges.

**Stitchwarden's Vigil** (2026-09-30) is not an image to this contract but a **layered arena**
(ADR-0021): a generated scene of separate pieces on one texel grid (4 design px per texel at full
size). Its revised source is `concept_art/arenas_v2/stitchwarden_vigil/source_v2/` (the original
`stitched_doll_pixel_kit/` is retained); `python concept_art/arenas_v2/stitchwarden_vigil/pack_vigil.py` makes everything:
the pieces under `assets/art/environment/arenas/stitchwarden_vigil/`, the scene
`scenes/arenas/stitchwarden_vigil.tscn` (never hand-edit it), the 941 × 1672 Shop still and thumbnail,
`arena.json` and `review/` (the arena at phone sizes with the HUD's boxes and the Wisp drawn in).
Change its numbers in the packer, re-run it, check `review/` and the printed HUD check, then
`tools/validate.sh` and `tools/run_tests.sh endless_catalog`. The revised board is split into a
frame and a 120 × 264-texel tile floor; `arena.json` records the measured floor in the Shop still.
Nothing drawn over the floor may reach into it (the packer refuses), and the cloth shader drops
any texel its wave would move onto it. The whole hood and face share a pivot and turn toward the
Wisp; the scarf, shoulders, tunic and long cloth panels respond while the gloves stay on the rail.
Fire on the scythe is a separate sprite animated by `arena_fire_wave.gdshader`. The floor remains a
rectangle for the walls; `arena_frame_tilt.gdshader` gives the decorative frame a mild top taper
(GDD §14 #66).

The **Chained Colossus 3D** (2026-09-30, GDD §14 #68) is the owner's model live in 3D, not an image:
§5. Its Shop still is rendered from the scene; its floor there is x 254–688, y 647–1586 of 941 × 1672.

## 5. 3D arenas

Arenas may be 3D, and a 3D arena need not be pixel-rendered (owner, 2026-09-30,
[ADR-0023](../decisions/0023-3d-arenas.md)). The worked example is the Chained Colossus 3D.

1. **The model** (the owner's; the CHAINED COLOSSUS's came from Meshy) goes unchanged into the arena's
   `concept_art/arenas_v2/<id>/source/`. Its playable floor must be a flat face looking straight at the
   camera: the game draws it as the exact rectangle the walls follow.
2. **A Blender script prepares it**, run headless:
   `"D:/Blender/blender.exe" --background --factory-startup --python concept_art/arenas_v2/chained_colossus_3d/build_colossus.py`.
   It measures the floor by casting rays at the model's front (the most common front-facing depth is
   the floor's plane; the typical ends of its runs are the frame's inner edges), finds the eye in the
   colour texture, keeps a quarter of the triangles with the floor's vertices protected (its big flat
   triangles otherwise collapse first and smear its texture), rigs the head (`root` and `head` bones,
   the head's vertices weighted by a soft ellipsoid, nothing below the shoulders), and writes the GLB and
   a `ModelArenaLayout` (`.tres`) next to it under `assets/art/environment/arenas/<id>/`, plus
   `model_report.json` with the measurements. Never hand-edit its outputs; change the script and re-run it.
3. **The scene** extends `ModelArenaVisual`: `%View` → `%World` (own 3D world) with the environment,
   lights, `%Camera` and `%Model` (the GLB at the origin, unmoved, so the layout is in world space).
   `fit()` places the camera for the screen. The arena's own script adds the scenery and effects
   around the model; every effect shader discards what would fall over the floor
   (`arena_3d_common.gdshaderinc`, `arena_over_floor`).
4. **The Shop still:** `"$GODOT" --path . --script res://tools/godot/render_arena_still.gd --
   scene=res://scenes/arenas/<id>.tscn out=concept_art/arenas_v2/<id>/source.png` (a window, not
   headless); put the printed `floor_rect_px` in `arena.json`, then `python tools/art/make_arena.py <id>`
   and copy its `floor_rect` into the skin, whose `visual_scene_path` names the scene.
5. `tools/validate.sh` and `tools/run_tests.sh endless_catalog`.

**The zoom intro** (owner 2026-10-01, GDD §14 #69, ADR-0023 Addendum): set `zoom_intro` on the scene
(the 3D ZOOM ARENA is `scenes/arenas/zoom_arena_3d.tscn`, the Colossus scene with it on). A run then
opens on the whole model and zooms in until the floor fills the whole screen (owner, #70), so the
floor should have about the screen's shape (the Colossus's 0.412 × 0.892 is close to 1080 × 2340). Its Shop
still is the opening shot, and `render_arena_still.gd` prints the floor drawn there.
