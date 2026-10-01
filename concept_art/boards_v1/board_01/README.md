# Wisp Rush — board_01 pixel-art kit

Created from `CODEX_PROMPT.md` on 2026-10-02. The kit contains **59 separate art PNGs**, **two assembled phone previews**, and **one tiling review PNG**. Claude can use `manifest.json` to locate all PNGs, their exact dimensions and the HUD rectangles.

## Pixel grid and materials

All art files are native 1× art pixels: **1 art pixel = 2 game pixels**. The previews alone are enlarged exactly 2× with nearest-neighbour sampling. The board is 540 art pixels wide, with 36-pixel posts and a 468-pixel floor. Wood, iron, brass, aged cream cloth, rust-red stitches, moss and amber lanterns follow the owner’s reference. Lighting comes from the top-left.

PNG files are RGBA. Floor tiles are fully opaque. Piece backgrounds are transparent; alpha values are only 0 or 255. Colours are flat palette steps; no blur or antialiasing was added.

## How the art was made

Five source sheets were created with the built-in image generator: stone tiles, frame pieces, HUD pieces, lantern states and cloth/moss overlays. The owner’s board and existing pixel UI kit supplied material and style references. Abstract slot guides supplied geometry. Raw sheets used a solid magenta key background; they remain outside the repository.

Deterministic postprocessing removed the magenta, cropped and packed each named piece, resized with nearest-neighbour sampling, reduced all colours to the shared 45-colour palette, reserved the empty HUD rectangles and matched repeat edges. Lantern frames use one scale, one anchor and one unchanged generated metal housing; only their glass/flame area changes. The preview-only digits and plain silhouette are the only code-drawn elements.

## Files and empty HUD areas

Every image is listed in `manifest.json`. `size` is in art pixels for art pieces; the two preview sizes are in game pixels. `tiles` is `x`, `y`, `xy` or `null`. `text_rect`, `icon_socket` and `fill_rect` use **[x, y, width, height] relative to the piece’s top-left**. Reserved HUD rectangles contain no baked digits, icons or labels. The soul top’s same socket can hold the game’s level number; its manifest records both the socket and text rectangle.

Use the fill segments inside the housing’s fill rectangle. Repeat and clip the fill to the desired height/width, then place the matching fill tip at its upper end. `crest_center.png` and `boss_plate.png` occupy the same centre slot; use one at a time. The pause buttons contain only the permitted two-bar pause symbol.

Lantern frame order is 0 → 1 → 2 → 3 → 0 for both `lit` and `glow`. `lantern_off.png` is the dim state. Animation speed is left to the game integration; the brief did not specify a frame rate. All frames are 28×44 with anchor [14,43]. Keep the lantern and any pulse inside the post; no light is baked onto the floor.

## Floor tiling

The three gameplay variants are plain, muted warm-grey stone. Their measured mean luminance is listed below. Fine seams and cracks are compressed in contrast so they do not look like collision walls. The lighter tan `floor_tile_a_light.png` uses the same base slab pattern for comparison.

All four floor tiles share identical joining pixels on every edge, including the light comparison tile. A short hard-pixel dither transition near the border connects the different stone values. The lighter tile still appears visibly lighter in its interior; this is intentional.

- `floor/floor_tile_a.png`: 34.15% mean luminance (Rec. 709 weights on RGB bytes).
- `floor/floor_tile_b.png`: 34.03% mean luminance (Rec. 709 weights on RGB bytes).
- `floor/floor_tile_c.png`: 34.19% mean luminance (Rec. 709 weights on RGB bytes).
- `floor/floor_tile_a_light.png`: 53.87% mean luminance (Rec. 709 weights on RGB bytes).

## Assembled previews

| Preview | Native art canvas | Top cap | Bottom cap | Floor rectangle in art pixels | Centre slot |
|---|---|---|---|---|---|
| `preview/mock_1080x2340.png` | 540×1170 | 62 art px / 124 game px | 20 art px / 40 game px | [36, 126, 468, 996] | boss_plate |
| `preview/mock_1080x1920.png` | 540×960 | 32 art px / 64 game px | 20 art px / 40 game px | [36, 96, 468, 816] | crest_center |

Rims occupy the adjacent four pixels **inside the frame**, preserving the full 468-pixel floor width. The previews include the requested 004250 score, 125 Rift Points, soul level 7, upgrade tag 2 and a plain left-wall silhouette. Only that explicitly requested silhouette appears on the floor; frame pieces, moss, cloth and lanterns remain outside it.

## Shared palette — 45 colours

| Material / role | Hex colours |
|---|---|
| iron | `#0B1116`, `#151E24`, `#263238`, `#35434A`, `#62716C` |
| wood | `#241A16`, `#36241B`, `#493021`, `#5D3C29`, `#754E32`, `#8B603C`, `#A67749` |
| stone | `#3E3C38`, `#48453F`, `#514D45`, `#5C564D`, `#655D52`, `#71685B` |
| stone light | `#91806C`, `#A28F76`, `#B4A084`, `#C3AF93` |
| cloth | `#8E795F`, `#B19A78`, `#D3BB96`, `#FAE5C1` |
| stitches | `#7C3B28`, `#AD5435` |
| brass amber | `#674222`, `#95662E`, `#C88E39`, `#F3A847`, `#FFD275` |
| flame core | `#FFF1C3`, `#EAFDFF` |
| moss | `#2F3C27`, `#465836`, `#5E7D4C`, `#82985C` |
| soul | `#276E80`, `#3FB7C4`, `#62E8F2` |
| boss | `#512860`, `#883BA7`, `#B14CD9` |

## Tiling review

`review/tiling_check.png` has one 3×3 repetition panel for every repeatable piece. The contact sheet has three columns, read left-to-right then top-to-bottom. Small panels use an integer nearest-neighbour display scale. There are no text labels inside the image; the panel order is:

| Row | Column | Piece |
|---|---|---|
| 1 | 1 | `floor/floor_tile_a.png` |
| 1 | 2 | `floor/floor_tile_b.png` |
| 1 | 3 | `floor/floor_tile_c.png` |
| 2 | 1 | `floor/floor_tile_a_light.png` |
| 2 | 2 | `frame/post_left_segment.png` |
| 2 | 3 | `frame/post_right_segment.png` |
| 3 | 1 | `frame/beam_top_segment.png` |
| 3 | 2 | `frame/beam_bottom_segment.png` |
| 3 | 3 | `frame/cap_top_segment.png` |
| 4 | 1 | `frame/cap_bottom_segment.png` |
| 4 | 2 | `frame/rim_h.png` |
| 4 | 3 | `frame/rim_v.png` |
| 5 | 1 | `deco/chain_segment.png` |
| 5 | 2 | `hud/boss_fill_segment.png` |
| 5 | 3 | `hud/soul_gauge_segment.png` |
| 6 | 1 | `hud/soul_fill_segment.png` |
| 6 | 2 | `hud/rush_gauge_segment.png` |
| 6 | 3 | `hud/rush_fill_segment.png` |

## Checks and limits

- Exact image dimensions and all HUD rectangle bounds checked.
- Shared palette contains 45 colours; all visible PNG colours belong to it.
- Alpha checked as binary; opaque floors checked.
- Repeat edges checked pixel-for-pixel on each specified axis, including all floor pairings.
- Four distinct frames checked in each lantern loop; the casing and chain stay fixed.
- Phone previews checked as exact nearest-neighbour 2× images.
- Floor checked before the preview silhouette: no frame or decoration intrudes.

This delivery is artwork and integration metadata. It does not include game scenes or runtime behaviour. No game files or project documents were changed. The existing prompt and owner reference were left intact.
