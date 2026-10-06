# Wisp Rush — Rift Points pack icon sources

Created 2026-10-05 for the owner's four Shop RP pack icons.
The built-in image generator made each source in a separate call, using the current RP currency
diamond and packed pickup icons as references. The four copied PNGs match their generated originals
byte-for-byte.

## Build status

**Packing is deferred to Claude, as the owner requested.** This task did not run `build_icons.py`,
Godot, validation or tests. Runtime icons and `preview_all.png` have not been produced by this task.

**Built 2026-10-05 by Claude:** `build_icons.py` made the four runtime icons
(`assets/art/ui/rp_packs/rp_pack_*.png`, 256 × 256) and `preview_all.png`; the Shop's RIFT POINTS
section shows them (ADR-0028).

From the repository root, outside this sandbox:

```powershell
python concept_art/rp_packs_v1/build_icons.py
```

The script requires Pillow, the same dependency as the pickup icon builder. It uses no NumPy.
After building, Claude checks the review sheet, the pile progression and the icons beside the
pickup item icons, then wires them into the Shop and records the game change.

## Four packs

| Pack | Preserved source | Exact prompt | Runtime output after build |
|---|---|---|---|
| 500 RP — a few crystals | [Source](raw/rp_pack_500.png) | [Prompt](prompts/rp_pack_500.md) | `assets/art/ui/rp_packs/rp_pack_500.png` |
| 1,200 RP — a small pile | [Source](raw/rp_pack_1200.png) | [Prompt](prompts/rp_pack_1200.md) | `assets/art/ui/rp_packs/rp_pack_1200.png` |
| 2,500 RP — a large pile | [Source](raw/rp_pack_2500.png) | [Prompt](prompts/rp_pack_2500.md) | `assets/art/ui/rp_packs/rp_pack_2500.png` |
| 6,500 RP — a spilling chest | [Source](raw/rp_pack_6500.png) | [Prompt](prompts/rp_pack_6500.md) | `assets/art/ui/rp_packs/rp_pack_6500.png` |

All four runtime outputs are configured as **256 × 256 RGBA PNGs**.
The build also creates `concept_art/rp_packs_v1/preview_all.png`, an **800 × 940** review sheet
showing all four icons at 256, 64, 48 and 32 px. The 64 px samples sit on ivory for transparency
review. Pack labels belong to the review sheet; the icons contain no text, numbers or letters.

## Sources and recipe

- `raw/`: four unchanged **1254 × 1254 RGBA PNGs**; all four corner alpha samples are zero.
- `prompts/`: the exact prompts sent to the built-in image generator.
- `generation.json`: generation paths, reference roles, raw dimensions, byte counts, source and
  prompt SHA-256 hashes, transparency samples and planned runtime paths.
- `build_icons.py`: the packer, adapted from `concept_art/pickup_items_v1/build_icons.py`.

The reference `assets/ui/theme/icons/icon_currency.png` is 64 × 64. Its three fully opaque RGB
colours were measured as **#604D40** (brown), **#ECA255** (amber) and **#FAE5C1** (ivory).
The crystal-only packs map to those three colours. The chest also uses the existing pickup
palette's dark, slate, brown and warm highlight colours.

The builder checks the recorded raw and prompt hashes, thresholds alpha at 128, crops to visible
bounds, fits to a maximum 48 px body extent on the pickup icons' 64 px logical canvas, maps to the
limited palette and enlarges 4× with nearest filtering. It checks every packed PNG's size, RGBA
mode, allowed colours, binary alpha, transparent margins and exact 4 px grid. Raw files stay
unchanged. It writes only the four runtime PNGs and this pack's review sheet.

No game code, scenes, data, import files or `docs/` files are edited by this task or builder.
