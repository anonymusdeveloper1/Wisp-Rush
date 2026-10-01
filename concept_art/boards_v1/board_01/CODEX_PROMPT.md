# Codex prompt — Wisp Rush full-screen board, pixel-art pieces (board_01)

You are making the art for the first **board** of Wisp Rush: the arena the game is played on. Make
every piece listed below as separate PNG files, store them **exactly** where this prompt says, and do
**not** touch anything else in the repository (no `assets/`, `scenes/`, `data/`, `scripts/`, `docs/`).
Claude integrates the pieces into the game afterwards; the file names and the manifest are how it
finds them.

## 1. The game, in one paragraph
Wisp Rush is a portrait-only (vertical, never landscape) one-finger mobile game. The player's
character is a 2D pixel-art figure that dashes in straight lines from wall to wall of the board,
slicing enemies. The board fills the **whole phone screen**: a wooden, iron-bound frame around a
stone floor. The frame is also the HUD: the pause button, score, Rift Points, soul level, RUSH meter
and boss bar are built into the frame instead of floating over the game. The upgrade menu opens when
the player taps the character; the board's lanterns glow when an upgrade is ready.

## 2. Reference
`concept_art/boards_v1/board_01/reference/owner_board_reference.png` — the owner's image of the
board. Match its materials and mood: dark brown wooden posts and beams, iron corner brackets and
bands, brass rivets and rings, aged cream cloth wrapped around the posts with rust-red cross
stitches, small moss and vine tufts, warm amber lanterns, stone floor tiles. **Do not copy its
proportions**: the game's board is the whole screen and is built from the pieces below.

Also look at the game's existing pixel UI kit, `concept_art/wisp_rush_pixel_ui_v1/` (README,
`components/`, `previews/`), so the HUD pieces feel like the same family.

## 3. Style rules (all pieces)
- **Pixel art with small pixels: 1 art pixel = 2 game pixels.** The phone screen is 1080 game pixels
  wide, so the board is **540 art pixels wide**. Draw every piece at 1× in art pixels; never upscale,
  never mix pixel sizes inside a piece.
- Hard pixel edges only: no anti-aliasing, no blur, no soft gradients, no painterly or 3D rendering.
  Shading by flat colour steps and dithering. Glows are drawn as hard-edged pixel rings or dithering,
  never as soft blur.
- One limited palette shared by every piece (aim for about 32–48 colours). Light comes from the
  top-left on every piece.
- **No text, letters, numbers or logos in any image.** The game draws every number and word with its
  own pixel font. (The pause symbol's two bars are allowed.)
- Colour meanings in the game: cyan = friendly / the player's soul, amber = rewards and warnings,
  magenta = bosses and enemies. Keep the frame itself wood, iron, brass and cream so those colours
  stay readable when the HUD uses them.
- Transparent background (PNG with alpha) for every piece except the floor tiles, which are opaque.

## 4. Layout of the board (art pixels; the game repeats and places the pieces)
- Screen: **540 wide**, between **960 and 1200 tall** depending on the phone (16:9 to 20:9).
- **Left and right posts: 36 wide.** Top beam: **64 tall.** Bottom beam: **28 tall.**
- Above the top beam the frame continues under the phone's status bar / camera notch (the **top cap**,
  0–80 tall depending on the phone). Below the bottom beam it continues under the gesture bar (the
  **bottom cap**, 0–40 tall).
- **The floor is everything inside: 468 wide.** It is where the whole game happens. Nothing may be
  drawn on the floor: no moss, cloth, shadows, lantern light or decorations reaching into it.
- Between the floor and the frame there is a crisp **wall line** (the rim pieces): it shows the
  player exactly where the character stops.
- Top beam contents, left to right: pause button (left), centre slot (the boss plate during a boss
  fight; a decorative crest otherwise), score plate above Rift Points plate (right, stacked).
- Left post: the soul-level gauge runs vertically along it. Right post: the RUSH gauge.
- Four lanterns, one at each floor corner, hang on the posts.

## 5. Pieces to make (exact sizes, width × height, in art pixels)

### Floor — `floor/` (opaque, seamless on all four sides)
| File | Size | What |
|---|---|---|
| `floor_tile_a.png` | 96 × 96 | Base stone slab tile: one or two slabs with faint seams. Plain, low contrast, **mid-dark** (about 30–40 % brightness, muted warm-grey stone) so enemies and the character are the brightest things on it |
| `floor_tile_b.png` | 96 × 96 | Same stone, a few fine cracks |
| `floor_tile_c.png` | 96 × 96 | Same stone, a little more worn |
| `floor_tile_a_light.png` | 96 × 96 | The base tile at the reference image's lighter tan value, for the owner to compare on the phone |

All four must tile seamlessly with each other in any mix. No strong lines that could read as a wall.

### Frame — `frame/`
| File | Size | What |
|---|---|---|
| `post_left_segment.png` | 36 × 64 | Left wooden post with an iron band; tiles vertically |
| `post_right_segment.png` | 36 × 64 | Right post (may be the mirror of the left, lit from the top-left); tiles vertically |
| `beam_top_segment.png` | 64 × 64 | Top beam; tiles horizontally |
| `beam_bottom_segment.png` | 64 × 28 | Bottom beam; tiles horizontally |
| `corner_top_left.png` / `corner_top_right.png` | 36 × 64 | Where a post meets the top beam: iron corner bracket, rivets |
| `corner_bottom_left.png` / `corner_bottom_right.png` | 36 × 28 | Where a post meets the bottom beam |
| `cap_top_segment.png` | 64 × 64 | The frame above the top beam (behind the status bar): darker, simpler wood; tiles horizontally and vertically |
| `cap_bottom_segment.png` | 64 × 32 | The frame below the bottom beam; tiles horizontally |
| `rim_h.png` / `rim_v.png` / `rim_corner.png` | 64 × 4 / 4 × 64 / 4 × 4 | The wall line between frame and floor: a dark shadow line and a 1-pixel light lip; tiles along its length |

### HUD — `hud/` (no numbers or text; leave the marked areas empty for the game's font)
| File | Size | What |
|---|---|---|
| `pause_button_normal.png` / `pause_button_pressed.png` | 52 × 52 | Iron ring/knob button on the top beam with a pause symbol (two bars); pressed = pushed in, darker |
| `crest_center.png` | 200 × 44 | Decorative crest for the top beam's centre when there is no boss |
| `boss_plate.png` | 200 × 44 | Iron-and-cloth plate for the boss bar: a round socket at the left (the game puts the boss's icon there, about 32 × 32 inside) and an empty track to its right |
| `boss_fill_segment.png` | 8 × 12 | The boss health fill, magenta (#B14CD9 family); tiles horizontally |
| `score_plate.png` | 120 × 26 | Brass plate; empty centre area at least 104 × 18 for the score digits |
| `rp_plate.png` | 120 × 26 | Small plate; a round socket at the left (the game puts its Rift Points icon there, about 20 × 20) and an empty area for digits |
| `soul_gauge_top.png` | 36 × 44 | Top of the soul gauge on the left post: a round socket (about 24 × 24 empty inside) for the level number |
| `soul_gauge_segment.png` | 36 × 32 | The empty gauge housing along the post (a glass tube or groove in the wood); tiles vertically |
| `soul_gauge_bottom.png` | 36 × 20 | Bottom end of the soul gauge |
| `soul_fill_segment.png` / `soul_fill_top.png` | 12 × 32 / 12 × 8 | The soul gauge's fill, cyan soul light (#62E8F2 family); the segment tiles vertically, the top is its bright tip |
| `rush_gauge_top.png` / `rush_gauge_segment.png` / `rush_gauge_bottom.png` | 36 × 44 / 36 × 32 / 36 × 20 | The RUSH gauge on the right post, same structure (its top socket may be a small emblem instead of a number socket) |
| `rush_fill_segment.png` / `rush_fill_top.png` | 12 × 32 / 12 × 8 | The RUSH fill, warm ivory (#FAE5C1 family), like a burning fuse |
| `rush_full_flare.png` | 36 × 64 | Overlay shown when RUSH is full: hard-pixel flare around the gauge top |
| `upgrade_count_tag.png` | 24 × 18 | Small hanging tag under a lantern; empty for one or two digits |

### Lanterns — `anim/` (transparent; frames of a loop)
| Files | Size | What |
|---|---|---|
| `lantern_off.png` | 28 × 44 | Lantern hanging from a short chain, dim |
| `lantern_lit_0.png` … `lantern_lit_3.png` | 28 × 44 | Normal light, a 4-frame flame flicker loop |
| `lantern_glow_0.png` … `lantern_glow_3.png` | 28 × 44 | Brighter amber glow for "an upgrade is ready", 4-frame pulse loop; the glow stays inside the 28 × 44 cell |

### Decorations — `deco/` (transparent; placed on the frame only, never on the floor)
| Files | Size | What |
|---|---|---|
| `cloth_wrap_post_a.png` … `_c.png` | 36 × 48 | Cream cloth wrapped around a post, rust-red cross stitches, torn ends staying within the post |
| `cloth_tail_beam_a.png` … `_c.png` | 48 × 24 | Short torn cloth tails lying on a beam, within the beam's height |
| `moss_a.png` … `moss_f.png` | 12–24 square | Moss and tiny vine tufts for the frame's surfaces |
| `rivet.png` | 6 × 6 | Brass rivet |
| `chain_segment.png` | 8 × 16 | Chain link pair; tiles vertically (hangs along a post) |

## 6. Previews — `preview/`
Assemble the pieces into two full-board previews **at game resolution** (art pixels ×2, nearest
neighbour): `mock_1080x2340.png` (1080 × 2340, with a 124-game-pixel top cap) and
`mock_1080x1920.png` (1080 × 1920, with a 64-game-pixel top cap). Fill the floor with the tiles, place the frame,
corners, rims, HUD pieces, lanterns and some decorations. For the preview only, write placeholder
numbers in a simple pixel font (score `004250`, Rift Points `125`, soul level `7`, upgrade tag `2`)
and draw a plain silhouette where the character rests on the left wall, so the owner can judge
sizes. Also make `review/tiling_check.png` showing each tiling piece repeated 3 × 3.

## 7. Where to store everything
```
concept_art/boards_v1/board_01/
  reference/        (already there — the owner's image; do not change)
  CODEX_PROMPT.md   (this file; do not change)
  floor/  frame/  hud/  anim/  deco/  preview/  review/
  manifest.json
  README.md
```
`manifest.json` lists every file: `path`, `size` [w, h], `kind` (`tile`, `piece`, `overlay`,
`anim_frame`), `tiles` (`x`, `y`, `xy` or none), and for the HUD pieces the **empty rectangles** the
game writes into (`text_rect`, `icon_socket`, `fill_rect`: x, y, w, h in art pixels inside the
piece). `README.md` says how the pieces were made, the palette used, and anything you could not do
exactly as asked.

## 8. Checklist before you finish
- Every size is exact; every piece is on the same pixel grid (1 art pixel = 2 game pixels).
- Tiles and segments repeat with no visible seams (`review/tiling_check.png`).
- No text or numbers anywhere except the preview's placeholders.
- Nothing is drawn into the floor area.
- The previews look like one board, consistent with the owner's reference in materials and mood.
