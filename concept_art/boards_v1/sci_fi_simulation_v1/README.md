# Sci-fi simulation board — component kit

Ready for Claude's integration. Start with [CLAUDE_IMPLEMENTATION_PROMPT.md](CLAUDE_IMPLEMENTATION_PROMPT.md), [manifest.json](manifest.json) and the [assembled board](preview/hud_1080x2340.png).

The approved concept is a close-up portrait simulation screen: graphite hardware, cyan boundary, quiet navy playing surface, and textless meters embedded inside the display. **Boss health is magenta; RUSH is amber.** Enemy arrivals use a small amber scan effect; boss arrivals use a larger magenta scan effect and screen fragments.

## Contents

**58 exported RGBA PNG components.** The original 54 remain byte-identical; four opaque cap pieces are added. Exact sizes, hashes, source locations, fill sockets and animation origins are in the manifest.

| Folder | PNGs | Contents |
|---|---:|---|
| `frame/` | 17 | Four corners, repeatable side rails and top/bottom hardware, four cyan boundary strips, original flat cap, four new cap joins/bands |
| `floor/` | 1 | Opaque, seamless 96 × 96 navy scanline texture |
| `deco/` | 4 | Separate core wisp and empty housing; low-contrast left/right screen data patches |
| `hud/` | 11 | Boss/RUSH tracks and separate fills; pause button; blank score, RP, level and upgrade sockets; soul/XP track and fill |
| `anim/` | 25 | Eight enemy frames plus sheet; twelve boss frames plus sheet; three boss screen-disturbance patches |

Also included: three unchanged concepts in `reference/`; raw imagegen artwork, cleaned sheets and processor QC in `source/`; the original four generation prompts and four cap prompts in `prompts/`; four portrait preview sizes with and without supporting HUD, two cap previews, spawn stills and GIFs in `preview/`; component/tiling contact sheets and `qa_report.json` in `review/`.

## Responsive pixel contract

Native board width: **540 art pixels**. At 1080 design width, **one art pixel = two design pixels**. Use nearest filtering and no mipmaps. Component alpha is 0 or 255; every visible pixel belongs to the shared **37-colour palette**. GIF previews demonstrate composited fades; PNGs are the runtime textures.

Scale uniformly by `view_width / 540`. Tile the floor and rails, crop the last repeat, and move the bottom hardware with the available height. Do not stretch a finished phone image. Side rails are 48 art pixels wide; top/bottom hardware are each 64 high. The playable rectangle is 444 art pixels wide, at x = 48; the manifest specifies its height and safe-area caps.

This layout is specific to this kit. `BoardArenaVisual` currently hardcodes a different wooden-board layout. Claude must implement the new screen layout rather than merely changing that script's `art_dir`.

Boss and RUSH tracks are 356 art pixels wide. Both fill sockets are `[55,12,248,11]`, relative to the track. Clip the supplied fills horizontally to current game values. RUSH's six visual segments do not change its charge rules. Boss health appears only during an encounter. Neither meter has text, icons or baked percentages. Other counters are code-rendered in their blank sockets; RP has a socket for the existing game icon.

| Preview size | Native art canvas | Safe top, art px | Floor rectangle, art px |
|---|---|---:|---|
| 1080 × 1920 | 540 × 960 | 32 | `[48,96,444,800]` |
| 1080 × 2340 | 540 × 1170 | 62 | `[48,126,444,980]` |
| 1080 × 2560 | 540 × 1280 | 64 | `[48,128,444,1088]` |
| 1536 × 2048 portrait | 540 × 720 | 24 | `[48,88,444,568]` |

These safe-top values are preview inputs, not device measurements. Runtime uses the actual safe area, including a bottom inset where present. On a larger portrait screen the physical board becomes larger; its rails gain or lose repeats to fit the aspect ratio.

## Top and bottom cap extension

The four new pieces continue the casing beyond the board hardware into the phone's safe bands.
They contain no HUD, lettering or sockets and are fully opaque. Their middle stays dark; the outer
48 art pixels on each side reuse the existing rails' pixels. The join's hardware-facing row matches
the actual corner/beam edge, including the core housing at the top centre.

| Piece | Size, art px | Tiles | Placement |
|---|---|---|---|
| [cap_top_join.png](frame/cap_top_join.png) | 540 × 8 | no | Directly above top hardware; bottom edge touches it |
| [cap_top_band.png](frame/cap_top_band.png) | 540 × 48 | y | Above the top join, repeated upward and cropped at the screen top |
| [cap_bottom_join.png](frame/cap_bottom_join.png) | 540 × 8 | no | Directly below bottom hardware; top edge touches it |
| [cap_bottom_band.png](frame/cap_bottom_band.png) | 540 × 48 | y | Below the bottom join, repeated downward and cropped at the screen bottom |

Cap height is `ceil(safe_inset / unit)`, with `unit = view_width / 540`. Each cap supports every height
from 0 to 128 art pixels. If shorter than 8 pixels, crop the join from the screen-facing end and
preserve the hardware-facing end. The bands retain equal two-row repeat-edge strips. Placement is
recorded in `manifest.json` → `layout.caps`.

HUD previews with both caps:

- [caps_1080x2340.png](preview/caps_1080x2340.png): 137 game px top / 96 bottom, using 69 / 48 art px.
- [caps_1536x2048.png](preview/caps_1536x2048.png): the same 137 / 96 game px safe bands in portrait,
  using 49 / 34 art px at this width.

These are requested preview inputs, not device measurements. After nearest enlargement, the outer
excess from ceil rounding is cropped and a quiet floor row extended to retain the exact preview
size and safe-area anchors; the preview metadata records the 1 / 3 game rows involved. Components
are unchanged by that presentation step. [components.png](review/components.png) and
[tiling_check.png](review/tiling_check.png) include the four additions.

The four unchanged imagegen outputs and their source crop metadata are in `source/`; exact prompts
are [cap_top_join.md](prompts/cap_top_join.md), [cap_top_band.md](prompts/cap_top_band.md),
[cap_bottom_join.md](prompts/cap_bottom_join.md) and [cap_bottom_band.md](prompts/cap_bottom_band.md).
`source/cap_generation.json` records the built-in generator and reference paths.
`source/cap_baseline_54.json` preserves the original hashes and palette: the builder checks them
before and after rebuilding. `verify()` also checks every cap height, full opacity, palette, exact
hardware attachment rows, copied rail columns and the join/band edges.

## Spawn animations

| Effect | Grid | Frames | Origin in each PNG | Timing |
|---|---|---:|---|---|
| Enemy arrival | 4 columns × 2 rows | 8 | `[64,77]` | Existing enemy telegraph progress |
| Boss arrival | 4 columns × 3 rows | 12 | `[128,128]` | Existing boss appearance/intro timing |

Read row by row, left to right. All frames share one source-cell scale and origin, with no per-frame bbox normalization or recentering. Effects expand within their cells. Hide/recycle the sprite after the one shot; the last frame still has residual pixels.

GIFs use 75 ms per frame: 0.6 s enemy and 0.9 s boss. Those are **preview durations**, not new game delays. `EnemyActor` already applies `telegraph_duration` and `_world_speed`; Grimgrin's current tuning supplies a 1.1 s intro. The demo boss pattern is centered to show its shape; the real effect must use the actual boss spawn position.

The three separate boss screen patches attach to floor edges and share the boss sequence's phase and cleanup. Its demonstrated opacity curve is in the manifest. Clip effects to the floor, below actors and dangerous combat telegraphs. All are cosmetic; they have no collision shapes.

**AutoSprite is not required.** The sheets already contain the animation; Claude needs Godot `SpriteFrames`/`AtlasTexture`s and the existing spawn connections.

## Provenance and rebuilding

Frame, rim, meter outlines, core and scan decorations are cropped from the approved imagegen concepts. Supporting HUD hardware, clean screen texture and the two spawn sequences were generated with the built-in image generator. No sprite artwork was procedurally drawn.

Postprocessing removes magenta backgrounds, reduces the palette without dithering, reserves HUD sockets, copies joining pixels for repeatable edges, and packs fixed cells using nearest sampling. The boss raw sheet is temporarily cyan to avoid losing magenta effect pixels during chroma cleanup; its exported frames are magenta.

Rebuild from saved inputs with Python, Pillow and NumPy:

```text
python concept_art/boards_v1/sci_fi_simulation_v1/build_kit.py
```

This rebuilds this kit's exports, manifest and previews; it does not generate new artwork or modify the game. `review/qa_report.json` records dimensions, binary alpha, palette membership, equal repeat-edge bands, opaque floor and nonempty, unclipped animation frames. Both original animation grids passed the sprite processor's strict containment checks; their metadata is retained.

The kit remains under `concept_art/.gdignore`. Claude has integrated the original 54 pieces as
SIMULATION. The four cap additions are source-only: this delivery changes no game code, scenes,
data or runtime assets. Claude can copy them with `tools/art/make_board.py sci_fi_simulation_v1`
and draw them in `SciFiBoardVisual` as `layout.caps` specifies.
