# Codex prompt — the sci-fi board's top and bottom caps

Add four pixel-art pieces to the sci-fi simulation board kit in this folder
(`concept_art/boards_v1/sci_fi_simulation_v1/`). They fill the bands above and below the board on a
phone. Then rebuild the kit with its own pipeline. Repository: `D:/Wisp Rush`. This is art for the
kit only: do not change the game's code, scenes or data.

## 1. The problem (owner, 2026-10-04)

The game draws this board as **SIMULATION** (`scenes/arenas/sci_fi_board_visual.gd`, ADR-0025). The
board is laid out under the phone's safe area: above the top hardware there is a **top cap** (behind
the status bar and camera cutout), and under the bottom hardware a **bottom cap** (the gesture bar).
Both caps are filled today with `frame/outer_cap_segment.png`, a flat 16 × 8 tile of one grey
(#29323F), so on the phone the top shows a plain band of background colour. The owner: fill it "as
the arena is". Reference: `reference/approved_board.png` and `preview/hud_1080x2340.png` (the flat band
is at the top of that preview).

How tall the caps are, in art pixels (one art pixel = 2 game pixels on a 1080-wide screen;
`unit = screen width / 540`):

- **Top cap** = `ceil(safe_top / unit)`, where `safe_top` is the phone's top safe inset plus the
  game's base margin (2.5 % of the screen width, 18–36 game px). It is 14 art px in a desktop window;
  on a phone with a status bar it is several times that. The pieces must fill **any height from 0 to
  128 art px**.
- **Bottom cap** = `ceil(safe_bottom / unit)`, the same way with the bottom inset. It is 14 art px in a
  desktop window and more on a phone that shows a gesture bar. Again, **any height from 0 to 128 art px**.

## 2. The pieces

All four are exactly **540 art pixels wide** (the board's width), so each cap is one full-width band.

| File | Size (art px) | Repeats | Where the game puts it |
|---|---|---|---|
| `frame/cap_top_join.png` | 540 × 8 | no | Directly above the top hardware: its bottom row touches the top row of `frame/corner_top_left.png`, `frame/top_segment.png`, `deco/core_housing.png` and `frame/corner_top_right.png` |
| `frame/cap_top_band.png` | 540 × 48 | **y** (seamless top to bottom) | Above the join, repeated upwards; the last repeat is cropped at the top of the screen |
| `frame/cap_bottom_join.png` | 540 × 8 | no | Directly under the bottom hardware: its top row touches the bottom row of `frame/corner_bottom_left.png`, `frame/bottom_segment.png` and `frame/corner_bottom_right.png` |
| `frame/cap_bottom_band.png` | 540 × 48 | **y** (seamless) | Under the join, repeated downwards; the last repeat is cropped at the bottom of the screen |

The game anchors each cap at the board's edge and crops it at the screen's edge. A short cap shows
only the join and part of the first band repeat; a cap shorter than 8 art px crops the join itself.

## 3. How they look

- **More of the same device**: the graphite and silver hardware of the frame continues past the board,
  in the frame's style. Use the same 37-colour palette (`manifest.json` `palette`), the same pixel
  scale, flat colours and crisp edges. No blur, gradients, anti-aliasing or painterly shading.
- The joins make the edge look built: the top hardware and the cap read as one machine, with no
  seam where the corners and `top_segment` stop (the same at the bottom). Check the joins at both
  board corners and around the core housing at the top centre.
- The left 48 and right 48 art px of each band continue the side rails' look (the vertical rail
  columns of `frame/side_left_segment.png` and `frame/side_right_segment.png`), so the frame's sides
  run on past the corners.
- Quiet and dark: no HUD pieces, buttons, sockets, text, numbers or icons. Lights, if any, are sparse,
  small and steady, like the rails' amber and cyan lamps. The phone draws its white status-bar icons
  and the clock over the top cap, so they must stay readable over it. The bottom cap is under the
  gesture bar.
- Opaque: alpha 255 on every pixel (the caps cover the whole band).

## 4. Pipeline and checks

1. Add the four pieces through `build_kit.py`, as the other `frame/` pieces are (from new source art
   kept under `source/` with its exact prompt in `prompts/`). Give them manifest entries with `size`,
   `tiles` (`"y"` for the two bands, `null` for the joins), `sha256` and `source`, plus a
   `layout.caps` note giving where each goes (section 2).
2. The kit's `verify()` checks must pass for them: dimensions, binary alpha (here fully opaque),
   palette membership, and equal repeat-edge bands for the two `y`-tiling bands.
3. Previews: add `preview/caps_1080x2340.png`, the HUD preview at 1080 × 2340 with a **137 game px**
   top safe area (69 art px) and a **96 game px** bottom safe area (48 art px), both caps drawn, and
   the same at 1536 × 2048 portrait. Update `review/components.png` and `review/tiling_check.png`, and
   add a row to `README.md`.
4. Re-run `python concept_art/boards_v1/sci_fi_simulation_v1/build_kit.py`. The existing 54 pieces must
   stay byte-identical (their manifest hashes unchanged).
5. Do not copy anything into `assets/`; Claude runs `tools/art/make_board.py sci_fi_simulation_v1`
   and draws the caps in `SciFiBoardVisual`.

Finish with the four files, their sizes, the previews, and the `verify()` result.
