# Wisp Rush pixel UI components — source handoff

This is the **asset-only** replacement kit requested on 2026-09-24. It covers menus and the gameplay HUD.

**Status: integrated 2026-09-24** (owner phone review pending). The folder stays source-only and read-only: `assets/ui/theme/tools/build_theme_textures.py` copies the pieces the game uses into `assets/ui/theme/textures/` and `assets/ui/theme/icons/` (with nearest-filtered wrappers), and `build_wisp_theme.gd` builds the project Theme from them. Where a manifest nine-slice band would stretch an ornament, the runtime copy stretches a plain wall row instead (listed in `textures/slices.json`). How it is used: `docs/systems/ui_design_system.md`. The `"status"` field in `components.json` is written by `build_ui_kit.py` and still says `source_only_not_integrated`.

## Look

- True pixel art: every image is built on a strict 4 px square grid, with hard edges and no antialiasing.
- Dark obsidian and charcoal stone (`#0B1116`, `#151E24`, `#263238`, `#35434A`) match the new Home stage.
- Warm repair stitching and ivory (`#A78768`, `#E8CAA0`), plus amber action/reward highlights (`#ECA255`), carry the broken-wisp character's material language.
- Cyan (`#63D7DF`) is restrained to focus/friendly highlights. Magenta (`#B963CB`) distinguishes selected or boss states. These semantic accents should remain distinguishable from arena telegraphs.
- All delivered components are transparent RGBA PNGs with **no baked text**. Godot should render labels and numbers.

## Contents

`components/` has 74 individual PNGs. `components.json` lists each file's role, native size, nine-slice margins, and content insets. Its margin order is **left, top, right, bottom**, in source pixels. A missing `nine_slice_px` means the piece should keep its native aspect ratio. The `previews/` sheets are review aids only; their labels are not part of the components.

| Component family | Files | Intended use |
|---|---|---|
| Buttons | `button_primary_*`, `button_secondary_*`, `button_danger_*`, `icon_tile_*` | Main, secondary, destructive, and compact icon actions; supplied states are explicit |
| Menu surfaces | `panel_*`, `plate_small`, `slot_*`, `tab_*`, `badge_plate_*` | Dialogs, cards, slots, tabs, and badges |
| Home/Shop | `caption_tile_*`, `portrait_ring*`, `nav_dock`, `page_diamond_*` | Captioned Home tiles, character focus, navigation, pagination |
| Menu meters | `progress_track`, `progress_fill_*` | XP, boss, and reward bars |
| Gameplay HUD | `hud_counter_plate`, `hud_alert_plate`, `hud_slim_track`, `hud_slim_fill_*`, `hud_health_*` | Score/currency, alert, XP/RUSH/boss, health |
| Accessories | `divider`, `slider_grabber_*`, `ornament_*` | Separators, setting controls, optional detail |
| Symbols | `icon_*.png` | 16 separate text-free 64×64 glyphs |

## Integration notes for Claude

- Use nearest texture filtering and integer-aligned placement. Keep the supplied alpha and avoid smoothing/mipmaps.
- Treat the manifest's nine-slice margins as the source of truth. Tiles, rings, glyphs, grabbers, health sockets, and diamonds are intended at native aspect; do not stretch them into long bars.
- Align text inside the manifest's content insets. No text is embedded in the art.
- Map existing UI roles to these assets through the project's Theme and `Palette`; this pack itself does not change either one. Preserve semantic button states, touch targets, and existing game flow.
- Preview sheets: `previews/menu_components.png`, `previews/navigation_components.png`, `previews/hud_components.png`, `previews/icon_components.png`.

## Rebuild and checks

Run `python concept_art/wisp_rush_pixel_ui_v1/build_ui_kit.py` and then `python concept_art/wisp_rush_pixel_ui_v1/build_previews.py` from the repo root. The first script recreates the individual PNGs and `components.json`; the second recreates the preview sheets. Both use Pillow. At delivery, all 74 files matched the manifest, every visible pixel occupied a uniform 4×4 block, transparent pixels had zero RGB, and each component used at most 32 RGBA colors.
