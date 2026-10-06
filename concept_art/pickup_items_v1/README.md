# Wisp Rush — pickup item icon designs

Created 2026-10-05 for the owner's request to make icons for the seven accepted pickup concepts.
The built-in image generator produced each icon separately. Soul Ward established the sibling
style; the other six use it and the current pixel UI glyph sheet as references.

## Final icons and preserved designs

| Item | Final / source PNG | Silhouette | Exact prompt |
|---|---|---|---|
| SOUL WARD | [Packed](icons/soul_ward.png) · [Original](raw/soul_ward.png) | Shield charm | [Prompt](prompts/soul_ward.md) |
| RIFT MAGNET | [Packed](icons/rift_magnet.png) · [Original](raw/rift_magnet.png) | Horseshoe rune and RP gem | [Prompt](prompts/rift_magnet.md) |
| FORTUNE STAR | [Packed](icons/fortune_star.png) · [Original](raw/fortune_star.png) | Reward star | [Prompt](prompts/fortune_star.md) |
| STILLGLASS | [Packed](icons/stillglass.png) · [Original](raw/stillglass.png) | Hourglass | [Prompt](prompts/stillglass.md) |
| BANISH BOMB | [Packed](icons/banish_bomb.png) · [Original](raw/banish_bomb.png) | Soul bomb | [Prompt](prompts/banish_bomb.md) |
| REAPER'S EDGE | [Packed](icons/reapers_edge.png) · [Original](raw/reapers_edge.png) | Crescent blade | [Prompt](prompts/reapers_edge.md) |
| ECHO WISP | [Packed](icons/echo_wisp.png) · [Original](raw/echo_wisp.png) | Paired friendly wisps | [Prompt](prompts/echo_wisp.md) |

[review.html](review.html) displays the packed icons at 256, 64, 48 and 32 px, with a light
surface sample for transparency review. Its labels are separate from the icon images.

## Source files

- `raw/`: seven unchanged **1254×1254 RGBA PNGs**, one image per item, with transparent backgrounds.
- `prompts/`: the exact generation prompts, including reference roles and the project palette.
- `generation.json`: original generated-file paths and the references used for each icon.
- `raw_metadata.json`: measured dimensions, alpha bounds, colour counts and SHA-256 hashes;
  every copied file matches its original byte-for-byte.

The originals contain extra colour shades and partial-alpha edge pixels and stay unchanged.
`build_icons.py` thresholds alpha, crops and fits each original to a 64 px logical canvas, maps
colours to the existing project palette, then enlarges 4× with nearest filtering. `icons/` holds
seven 256×256 RGBA finals with binary alpha on an exact 4 px grid. `metadata.json` records source
and final hashes, crops, palette counts and byte-identical runtime copies in
`assets/art/ui/items/`. `preview_all.png` shows all seven at full and small sizes.

Rebuild: `python concept_art/pickup_items_v1/build_icons.py`. It checks the raw hashes, final grid,
palette, alpha and runtime copies. This source pack stays under `concept_art/.gdignore`.

Accepted item behaviour and shield activation are recorded in
[GDD §14 #76](../../docs/GDD.md). Implementation and provisional tuning: [pickup_items.md](../../docs/systems/pickup_items.md).

