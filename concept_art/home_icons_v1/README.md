# Wisp Rush - Home button icon sources

Created 2026-10-05 for the owner's requested SHOP, DAILY and TRIALS icons.
Each source is a separate built-in image generator output with a transparent background.
The generated PNGs are copied unchanged into `raw/`; `prompts/` preserves the exact prompts.
`generation.json` records the original paths, reference roles, dimensions and SHA-256 hashes.
All three preserved sources measure 1254 x 1254 RGBA; their corner alpha samples are zero.
They contain partial-alpha pixels, which the build thresholds to binary alpha.

## Build status and command

Packing is deferred to Claude, as the owner requested. This task does not run the builder,
Godot, `tools/validate.sh` or tests. Runtime icons and the review sheet are build outputs.

From `D:/Wisp Rush`, outside this sandbox:

```powershell
python concept_art/home_icons_v1/build_icons.py
```

The builder requires Pillow, the existing pickup/RP pack builder dependency. It uses no NumPy.
It writes only the three runtime PNGs and `concept_art/home_icons_v1/preview_all.png`.

| Button | Preserved source | Exact prompt | Runtime output after build |
|---|---|---|---|
| SHOP - merchant's bag | [shop.png](raw/shop.png) | [shop.md](prompts/shop.md) | `assets/art/ui/home_icons/shop.png` |
| DAILY - sun | [daily.png](raw/daily.png) | [daily.md](prompts/daily.md) | `assets/art/ui/home_icons/daily.png` |
| TRIALS - star | [trials.png](raw/trials.png) | [trials.md](prompts/trials.md) | `assets/art/ui/home_icons/trials.png` |

## References and packing

Each old glyph in `assets/ui/theme/icons/` supplies meaning: `icon_shop.png`, `icon_daily.png`
and `icon_trials.png`, respectively. They are read-only references.
The packed pickup [Soul Ward](../pickup_items_v1/icons/soul_ward.png) and
[Fortune Star](../pickup_items_v1/icons/fortune_star.png), together with the packed
[RP chest](../../assets/art/ui/rp_packs/rp_pack_6500.png), supply style, scale, outline and lighting.

The builder uses the exact 12-colour palette from `concept_art/pickup_items_v1/build_icons.py`:
`#0B1116`, `#111521`, `#263D42`, `#4C6670`, `#536064`, `#8FB3BA`, `#62E8F2`, `#EAFDFF`,
`#A78768`, `#FAE5C1`, `#F3A847`, `#FFD391`.
The dark, slate, ivory, brown and amber colours also appear in the RP chest builder's palette.

Packing follows the pickup/RP recipe: check raw and prompt hashes, threshold alpha at 128,
crop to visible bounds, fit with nearest filtering, map opaque colours to the palette, centre
on the logical canvas and enlarge with nearest filtering. Sources stay unchanged.
The pickup/RP builders use a 48-pixel body extent on a 64-pixel logical canvas. This builder
keeps that three-quarter scale as a maximum 36-pixel body extent on a **48 x 48 logical canvas**.
Runtime files are **192 x 192 RGBA**, with each logical pixel exactly **4 x 4 output pixels**.
At the Home button's **96 x 96** display size, each logical pixel is **2 x 2 screen pixels**.

The builder checks output size and mode, allowed palette colours, binary alpha, zero RGBA in
transparent pixels, transparent margins, the exact 4-pixel output grid and the 2-pixel display
grid. It reopens the saved PNGs and checks the raw and prompt hashes again.
Successful completion prints `HOME ICONS: OK`.

`preview_all.png` is an 880 x 850 review sheet. It shows all three at 192 pixels, at 96 pixels on
the existing 140 x 164 Home CaptionTile texture, at 96 pixels on ivory for alpha review, and
at 48 pixels. Captions and size labels belong to the review sheet, separate from the icon PNGs.

## Claude's checks after building

- Confirm `HOME ICONS: OK` and all three 192 x 192 RGBA runtime PNGs.
- Read `preview_all.png`: bag, four-ray sun and five-pointed star must be clear at 96 pixels on
  the dark stone button, with balanced scale and transparent margins. Check the bag's handle opening.
- Compare with the packed pickup and RP pack icons for outline weight, flat shading and lighting.
- Check the ivory samples for fringes or stray pixels and check that the icons contain no text,
  numbers or letters.
- Wire the icons into Home with nearest filtering, inspect the portrait Home screen, and record
  the integration and its validation. Game integration and project documentation belong to Claude.

This task and builder do not change game code, scenes, data, `assets/ui/theme/`, import files
or `docs/`.
