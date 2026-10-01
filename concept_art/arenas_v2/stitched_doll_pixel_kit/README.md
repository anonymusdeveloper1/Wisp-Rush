# Stitchwarden's Vigil — layered pixel-art source kit

Stitchwarden's Vigil is the name chosen for this darker, living version of the stitched-doll arena. The current playable `stitched_doll_jungle` arena is unchanged. `reference/scene.png` is the composition reference with the smaller board; the PNGs here are separate generated pieces, not a registered or imported Godot scene.

## Pieces

| Folder | Files | Role |
|---|---|---|
| `background/` | `jungle_backplate.png`, `jungle_wide.png`, `sky_wide.png`, `far_canopy.png`, `foreground_tree_left.png`, `foreground_tree_right.png`, `ground_left.png`, `ground_right.png`, `path_ground.png` | Moonlit jungle, distant canopy, near trees and roots, side ground, and the approach to the arena. The portrait and wide plates give different screen compositions. |
| `arena/` | `floor.png`, `frame.png` | Warm beige rectangular tile floor and a separate mossy stone-and-wood frame. The frame's bevel gives a mild perspective impression while the playable walls remain rectangular. |
| `doll/` | `body.png`, `head.png`, `grip_hands.png`, `scythe.png`, `cloth_left.png`, `cloth_right.png` | Upper body behind the board, movable head, optional front grip layer, separate weapon, and two cloth panels for continuous waving. |
| `fx/` | `lantern.png`, `fog_bank.png`, `flame/`, `wisp/`, `flying_creature/` | Board lantern, low fog, four-frame scythe-fire loop, four-frame wisp loop, and four-frame flying-creature loop. Each animated folder retains its generated raw sheet and has transparent frames, a sheet, preview GIF, and processor QC metadata under `processed/`. |

## How the scene can move

| Element | Method | Motion |
|---|---|---|
| Doll head | Separate 2D node pivot | Turns a little to follow play; the amber eye can pulse independently. Keep the neck joint covered by the hood and collar. |
| Hanging cloth | Deformable 2D mesh with a short bone chain or weighted control points | A continuous wind wave travels from the fixed root to the loose end. Keep each panel's root fixed and let its tip lag. This is the flexible motion the owner asked for; a frame swap alone would look stiff. |
| Scythe fire | `fx/flame/processed/` frame loop, attached to the blade | Flame silhouette changes continuously while its root stays on the blade; light colour/intensity may vary on top. The weapon itself stays a separate layer. |
| Lanterns | One lantern image reused at the board corners | Amber light flickers without moving the lantern body. |
| Wisps | `fx/wisp/processed/` loop plus separate movement paths | Small wisps drift around the doll and scenery, behind the playable surface. |
| Flying creatures | `fx/flying_creature/processed/` loop plus separate movement paths | Occasional crossings through the distant canopy. |
| Fog | `fx/fog_bank.png` with slow translation and opacity change | Sits low behind the board; it does not obscure the floor. |
| Background | Separate near, middle, and far layers | Side trees and distant canopy can move at different rates as the view shifts; the scene still works when static. |

The flame, wisp, and flying-creature loops are the parts to refine in AutoSprite if smoother authored motion is wanted. The doll's head turn, cloth wave, lantern flicker, fog drift, and travel paths are better controlled by the scene so they can react during play.

## Composition and responsive layout

Keep the floor, frame, doll, scythe, cloth and their attachment points in one uniformly scaled centre group. Its floor remains a straight rectangle for collision and dashes. The art can suggest a mild tilt through the frame depth; do not rotate or taper the collision walls. The floor is narrower than the earlier full-height concept, as requested.

On a phone, use the portrait jungle plate and show the whole doll-and-board group. On a larger screen, scale the centre group with the available play space and reveal additional side jungle from the wide plate, canopy, trees and ground pieces. Keep all effects and scenery outside the active floor. The portrait and wide plates are alternate composition sources; their joins have not been matched pixel for pixel.

## Current QA status

- Source art only. These independently generated pieces do **not** share a common canvas or registered pivots. The floor-to-frame fit, doll grip, scythe/flame attachment and cloth roots still need visual assembly and adjustment.
- The static transparent PNGs have faint generated alpha halos and have not been snapped to the game's strict 4-pixel art grid or limited palette. Clean and inspect them before runtime import. Do not treat them as finished pixel-perfect art.
- The three four-frame effect sheets were split and checked by `generate2dsprite.py`; its `pipeline-meta.json` in each `processed/` folder records frame QC. Their visual timing and scale still need review in the assembled scene.
- No game code, arena data, collision measurements, or Shop wiring were changed for this kit.
