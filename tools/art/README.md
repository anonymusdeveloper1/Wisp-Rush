# tools/art — redesign v1 art extraction

`extract_redesign.py` slices the owner-approved concept sheets in
`concept_art/wisp_rush_redesign_v1/assets/` into the runtime PNGs under `assets/art/`. Everything it
does is declared in `redesign_v1_slices.json`. The concept sources are only read, never written.

## Re-running

```sh
python3 tools/art/extract_redesign.py                    # every group + contact sheets
python3 tools/art/extract_redesign.py --only wisp props  # only these groups
python3 tools/art/extract_redesign.py --no-contact       # skip the contact sheets
```

Requirements: Python 3.7+, Pillow 9.5 and numpy 1.21. Nothing else is needed.
A full run takes about 30 s. The run writes these files to `logs/redesign/assets/`:

- `contact_<group>.png`: each output shown three times, as legacy art, new art on `#111521`, and new art on light grey.
- `extract_report.json`: per output, the source rect, crop, canvas, scale, centre and any clamping. It also records the checker estimates for each sheet.
- `scale_summary.txt`: the scale factors per group.

After a run, Godot must re-import the art (open the editor, or run `tools/validate.sh`) before the
game shows it.

## Playable-character layers

`extract_playable_characters.py` isolates the approved transparent cutout sheets under
`concept_art/wisp_rush_playable_characters_v1/assets/` into independent runtime PNG layers for
Veyra, Rook and Morrow:

```sh
python3 tools/art/extract_playable_characters.py              # all three
python3 tools/art/extract_playable_characters.py rook morrow  # only these
```

It uses fixed cells (the cell order of each `GENERATION_PROMPT.md`), removes detached generation
speckles by connected area, preserves nearby soft glow, and writes a QA contact sheet per character
to `logs/playable_characters/<id>_parts.png`. The complete source sheets are never runtime textures.

For every ribbon layer (Veyra's tails, Morrow's scarves) it also prints a `SPINE` line — the centre
line the rig bends the ribbon along, as `PackedVector2Array(...)` in texture pixels. After replacing
a source sheet, paste the printed spines into the `RibbonChain` nodes of
`scenes/player/visuals/<id>_visual.tscn` (the yellow overlay on the contact sheet shows them), then
run `tools/validate.sh` and `tools/run_tests.sh playable_character_visual`. Motion review:
`tools/art/motion_contact_sheet.py` tiles the frames of `render_character_motion.tscn`
([playable_character_visuals.md](../../docs/systems/playable_character_visuals.md)).

### `.import` files and uids

A replaced file keeps its existing `.import` file, so it keeps its `uid`, and scenes that reference
it by uid keep working. When a replaced file's `.import` is missing (for example after a fresh move
of the legacy tree), the script copies it from `assets/legacy_v1/art/`. Brand-new outputs get their
`.import` file on the next Godot import.

## Cleanup modes (the `cleanup` field of each sheet)

| Mode | Used for | What it does |
|---|---|---|
| `alpha` | 05, 06, 07, 10, 11, 13 v2 | The sheet already has alpha. It is split into connected components (seed = alpha > `seed`, optionally `grow`n first so nearby fragments merge). |
| `black` | 09 VFX | For additive art on black. Pixels below `floor` are treated as black. Then alpha = max(r,g,b) and rgb = rgb / alpha (unpremultiplied and clamped), so the art renders correctly with normal blending. |
| `checker` | 08 props, 12 forms | For a baked checkerboard; see the next section. |
| `opaque` | 02/03/04 plates | The image is copied as RGB and resized only when a legacy canvas size differs. |

### Checker removal

1. The two checker tones are estimated from a 24 px border strip.
2. Square boundaries are found from the tone transitions, which run straight across the sheet but are irregularly spaced.
3. The boundaries are regularised against the median period: spurious ones are dropped and missing ones filled in.
4. Each column and row of squares gets its parity by majority vote against the visible checker. Local tone maps absorb drift across the sheet.
5. The expected background is rebuilt per pixel, anti-aliased at square edges.
6. Two alpha estimates are computed:
   - Difference matting: `alpha = clamp(max_c|p - bg| / max_c(max(bg, 255 - bg)), 0, 1)`.
   - Local contrast: the pixel colour is regressed on the checker pattern, and the visible checker amplitude is `(1 - alpha) * (T0 - T1)`. This makes opaque dark interiors fully opaque while glows stay soft.
7. Alpha is forced to 0 where a pixel matches the checker within `match_tol` and connects to the sheet border through such pixels. It is also forced to 0 for enclosed pixels that match the checker and whose local contrast shows the checker.
8. Colour is recovered as `rgb = bg + (p - bg) / alpha`.

## Component selection (per item)

Items can be picked in three ways:

- `cell`: a grid index (row-major).
- `rect`: `[x0, y0, x1, y1]`. A component belongs to the item when its centroid lies inside the rect, so art that overflows the cell is kept whole and neighbours never bleed in.
- `near`: `[x, y]`, which picks the component nearest that point. Used for the frame kit.

These options control which components are kept:

- `keep: "all"` keeps every component of at least `min_area` px and `min_frac` of the largest.
- `keep: "main"` keeps the largest component, plus any other component within `attach` px of it, over up to 3 passes. This removes detached noise, for example on the Wisp sheet.
- `halo` re-adds soft low-alpha edge pixels near kept components, but never pixels that belong to other components.
- `clip: [x0, y0, x1, y1]` re-segments inside a hard window, which splits art that touches a neighbour (Reaper gate arrival and appear).
- On a sheet, `cut_rows: true` cuts the labelling mask on the emptiest row near each grid row boundary (props).

## Normalisation (per group)

- `canvas`:
  - `"legacy"` uses the legacy file's size.
  - `[w, h]` sets the size explicitly. `force_canvas` overrides it, for example to keep the Reaper at 444×444.
  - `"trim"` uses the native size plus `pad`.
- `scale`:
  - `item`: the content's robust bbox height (alpha > 0.125, specks dropped) matches the legacy bbox height.
  - `group`: the median of those ratios over `scale_ref`. Animation frames share one scale so the body never pops.
  - `fit`: fits into `box`.
  - `native`: uses `factor`.
- `center`:
  - `"legacy"`: the legacy bbox centre of that file.
  - `"median"`: the median legacy centre of the group.
  - `[x, y]`: an explicit point.
  - `like` + `register: true`: state variants reuse another item's scale and keep the sheet's cell-relative registration.
- Content never leaves the canvas. If it would, it is shifted inward first and scaled down only as a last resort; both cases are listed in the report.
- `background: "#rrggbb"` flattens the output to an opaque RGB file.

## Floor polygons (`extract_floor_polygons.py`)

Bakes each Rift's playable floor into `RiftData.floor_polygon` from its **runtime** background
(ADR-0011). Run it after `extract_rifts.py` or any background change:

```sh
python3 tools/art/extract_floor_polygons.py
```

Then **look at** `logs/rifts/floor_<rift>.png` — the bake is a heuristic. Pipeline: score pixels as
smooth and desaturated (never by brightness), keep the top share, close, keep the largest region,
fill enclosed holes (runes, cracks), erode, then cast 24 rays from the centroid, clamp single-ray
spikes against their neighbours and pull in any edge whose midpoint leaves the floor. The top is
clamped to V 0.255 so the resting Wisp never sits behind the HUD.
