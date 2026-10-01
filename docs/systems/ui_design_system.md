# System: UI design system (pixel UI kit theme)

> **Status:** ✅ done (pixel kit integrated 2026-09-24; owner phone review pending) ·
> **Last updated:** 2026-09-25 · **GDD section:** §9 UI, §11
>
> Source of the look: the pixel-art component kit `concept_art/wisp_rush_pixel_ui_v1/` (README,
> `components.json`, review boards in `previews/`), ADR-0018 (the game is pixel art). Palette meaning
> from redesign v1 (`concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md`). Never edit `concept_art/`.

## Purpose
One project-wide Godot `Theme` built from the pixel UI kit, so every screen gets the dark-stone,
warm-stitched look by picking a **type variation** instead of hand-made StyleBoxes and colours.
It is set as `gui/theme/custom` in `project.godot`, so every Control uses it with no extra setup.

## Pixel rules
- The kit is drawn on a **4 px grid: one art pixel = 4 design px**, at native size in the
  1080 × 1920 design space (a Primary button is 120 × 112, exactly as the PNG).
- **Nearest filtering without touching the project default:** every UI PNG has a `CanvasTexture`
  `.tres` beside it with `texture_filter = nearest`. The theme, scenes and scripts use the `.tres`,
  so the UI is crisp wherever it is drawn while characters and arenas keep their own filtering.
  Reference `res://assets/ui/theme/icons/<name>.tres`, never the `.png`, for any kit sprite.
- **Nine-patches only stretch identical rows/columns.** The texture step keeps the manifest's
  margins when their band is uniform, otherwise it moves the band to plain wall so stitches, studs
  and runes never smear. Consequence: side studs/diamonds keep their **native distance from the
  top**, so a piece drawn taller than native (PLAY at 134, the HUD upgrade tile, tall cards and
  crests) has them above centre. Keep native heights where you can; change width, not height.
- Glyph sizes that keep whole art pixels: 32, 48, 64, 80, 96, 112, 128 (0.5×–2× of 64).
- No soft glows in the theme: titles and reward numbers get a hard 4 px drop shadow.

## Files
| Path | Role |
|---|---|
| `res://assets/ui/theme/wisp_theme.tres` | The theme (generated; do not hand-edit) |
| `res://assets/ui/theme/textures/*.png` + `*.tres` + `slices.json` | Theme pieces copied from the kit (+ derived focus rings), their nearest wrappers, and nine-patch margins / content insets / edge bands |
| `res://assets/ui/theme/icons/*.png` + `*.tres` | Kit sprites used by scenes: glyphs, `hud_health_full`, page diamonds, edge ornaments |
| `res://assets/ui/theme/ornaments/*.tscn` | Optional edge ornaments (kit cyan rune / warm seal) |
| `res://assets/ui/theme/tools/build_theme_textures.py` | Step 1: kit → textures/icons + `slices.json` (deterministic; `--preview` → `logs/pixel_ui/`) |
| `res://assets/ui/theme/tools/build_wisp_theme.gd` | Step 3: wrappers, the `.tres` theme and the ornament scenes from `slices.json` + `Palette` |
| `res://scripts/utils/palette.gd` | `class_name Palette` — typed palette constants |
| `res://scripts/components/focus_carousel.gd` | `FocusCarousel` — shared portrait card picker (Shop tabs) |
| `res://scripts/components/page_dots.gd` | `PageDots` — the kit's page diamonds following a carousel |
| `res://scenes/debug/theme_gallery.tscn` (+ `.gd`) | Every variation on one screen (visual reference) |

Rebuild (repo root): `python assets/ui/theme/tools/build_theme_textures.py` →
`$GODOT --headless --path . --import` → `$GODOT --headless --path . --script res://assets/ui/theme/tools/build_wisp_theme.gd`
→ `tools/validate.sh`. Which kit pieces ship, the explicit stretch rows (`BAND_V`) and the icon list
live in the Python step; colours, fonts and content margins in the builder or `palette.gd`.

## Type variations (set `theme_type_variation`)
Sizes are in the 1080×1920 design space (≈ ×0.36 on a 390 pt phone).

| Variation | Base | Kit piece · use it for |
|---|---|---|
| *(default)* `Button` | Button | Same as `SecondaryButton` |
| `PrimaryButton` | Button | `button_primary_*` (112 tall, amber studs, ivory 44 px label). The single dominant, bottom-reachable action: Play, Restart, Daily Play, Buy/Equip. One per screen |
| `SecondaryButton` | Button | `button_secondary_*` (96 tall, 34 px). Home on Results, Back, Resume/Quit, settings actions |
| `DangerButton` | Button | `button_danger_*` (amber, light-amber label). Destructive/irreversible; always confirm |
| `IconButton` | Button | `icon_tile_*` (112 × 112). Square icon-only tile: Pause, Settings, Back, Stats, HUD upgrade. Set `icon` (64 px glyph), no text. Pressed = brightened tile (the kit has no pressed tile) |
| `CaptionTile` *(new)* | Button | `caption_tile_*`, native 140 × 164 only. Home's captioned tiles (Trials, Daily, Shop, No Ads; Rifts until 2026-09-24): children `Icon` (96 px box at y 18–114) and a 22 px uppercase `Caption` in the slot under the seam (y 127–151) |
| `SlotButton` | Button | `slot_*`; toggle mode, pressed = magenta slot. No game user today |
| `CardButton` | Button | `panel_card` / `panel_card_selected` (pressed: magenta bar + studs) / `panel_card_locked` (disabled). Upgrade tray cards and every `FocusCarousel` card |
| `NavButton` | Button | `tab_normal` / `tab_active` (pressed). One Shop tab: the 64 px tab is drawn centred in an 88 px touch row (negative expand margins), so only use it at 88 px inside a `NavBar` |
| *(default)* `PanelContainer` | PanelContainer | `panel_default`: info boxes, settings groups, confirm dialogs, tutorial guide |
| `PanelCard` | PanelContainer | `panel_card`: run-metric tiles, stat tiles, form details |
| `PanelCrest` | PanelContainer | `panel_crest` (cyan side lines): one hero panel per screen — pause, Daily portal, No Ads offer, tutorial skip |
| `PanelBanner` | PanelContainer | `panel_banner`: screen title banner; put a `TitleLabel` inside (native 96 tall with one 48 px line) |
| `PanelPlate` | PanelContainer | `plate_small`: value pill (Home's RP counter and best). Icon + `ValueLabel`/`AmberValueLabel` at 36–48 px. The run HUD uses none since 2026-09-24: its score is unframed |
| `RewardPlate` *(new)* | PanelContainer | `hud_alert_plate` (amber top line): Rift Points earned — Results reward plates, Daily reward |
| `NavBar` | PanelContainer | `nav_dock` (88 tall, no vertical padding): the Shop's tab dock holding an `HBoxContainer` of `NavButton`s |
| `PortraitRing` | PanelContainer | `portrait_ring`, square ≥ 280. No game user today |
| `TitleLabel` | Label | Titles, callouts. 48 px, letter-spaced, bold, light ivory, dark outline + hard drop. UPPERCASE |
| `CaptionLabel` | Label | Secondary text, units, "BEST". 26 px muted slate-cyan |
| `ValueLabel` | Label | Large numerals. 56 px soul white, tabular figures |
| `AmberValueLabel` | Label | Score and rewards. 64 px amber, tabular, hard drop shadow |
| `ProgressBar` | ProgressBar | `progress_track` + `progress_fill_xp` (40 tall; the fill covers the track where it reaches) |
| `BossProgressBar` | ProgressBar | Same track, `progress_fill_boss` (magenta): Reaper health |
| `SlimProgressBar` | ProgressBar | `hud_slim_track` + `hud_slim_fill_xp` (20 tall): HUD XP strip, goal rows, tray timeout |
| `RushProgressBar` | ProgressBar | Slim track + `hud_slim_fill_rush` (ivory), so RUSH never reads as a second XP strip. Only `%RushBar` |
| `HSlider` / `HSeparator` / `VScrollBar` | — | Slim track + cyan fill + `slider_grabber_*` / `divider` (centre gem removed, it cannot survive a stretch) / crisp flat stone grabber |
| plain `Label` | Label | Body text 30 px soul white |

Focus: every button, slider and card draws a cyan **focus ring** (the kit's focus art minus its
normal art) over its current state. Hover is a mild brighten (touch leaves hover on the last tap).

## Ornaments (optional, `assets/ui/theme/ornaments/`)
Instance one as a **child of a PanelContainer with the matching variation**; it centres the kit's
48 px edge ornament on the frame's top/bottom band. Pure decoration (`mouse_filter` ignore).

| Scene | Goes in | Look |
|---|---|---|
| `crest_top.tscn` / `crest_bottom.tscn` | `PanelCrest` | Cyan rune on the top / bottom edge |
| `card_top.tscn` | `PanelCard` | Cyan rune on top |
| `banner_top.tscn` | `PanelBanner` | Cyan rune on top (leave ~16 px free above the banner) |
| `amber_top.tscn` | default `PanelContainer` | Warm seal on top — reward/landmark panels only |

They assume the variation's content margins; if you override a panel's content margins, don't use them.

## Shared components (`scripts/components/`)
**Card-picker pattern** (owner decision 2026-09-13, Shop tabs; the Rift Map used it until 2026-09-25): a vertical screen with a
title, one big tall focused card in the centre (larger, lifted, magenta-framed), dimmed neighbours
peeking in at the sides, `PageDots` under it, one description/status block, then Back
(`SecondaryButton`) and the one main action (`PrimaryButton`). Swipe sideways to browse; tapping the
focused card does the same as the main action. Locked entries stay previewable and say why in text.

| Component | Behaviour and API |
|---|---|
| `FocusCarousel` (Control) | `set_cards(cards, selected)` adopts screen-built cards (sets them mouse-ignore; a `BaseButton` card becomes toggle-mode and is pressed while focused, so `CardButton` draws the selection frame). Swipe with exponential snap and rubber band at the ends; a flick advances one card (not if the finger stopped > 80 ms before lifting); tap a side card to focus it, tap the focused card → `activated(index)`. Taps are hit-tested against the resting layout; a cancelled touch, any drag past `tap_slop`, or focus loss / pause / hide mid-press never counts as a tap; `ui_left`/`ui_right`/`ui_accept` when focused. Mouse events only (touch arrives as emulated mouse). Signals `selection_changed(index)`, `activated(index)`. Methods `select(index, animate)`, `get_selected_index`, `get_card_count`, `get_card`, `get_scroll`, `is_settled`, `get_focus_card_size`. Exports: `focus_width_share`, `max_width_share` + `max_card_aspect`, `card_aspect`, `pitch_share`, `side_scale`, `side_brightness`, `lift_share`, `snap_speed`, `tap_slop`, `flick_speed` |
| `PageDots` (Control) | The kit's 24 px page diamonds at whole-pixel positions; set `count` and `dot_spacing` (multiple of 4), feed `position_value = carousel.get_scroll()` each frame — the lit (amber) diamond cross-fades between neighbours during a drag; indices in `hollow` use the locked diamond |

## Palette (`Palette.*`, see `scripts/utils/palette.gd`)
`VOID_CHARCOAL #111521` · `SLATE_TEAL #263D42` · `SOUL_CYAN #62E8F2` · `SOUL_WHITE #EAFDFF` ·
`WARNING_AMBER #F3A847` · `RIFT_MAGENTA #B14CD9` · `MOSS_GREEN #5E7D4C` · derived: `PANEL_BG`,
`TEXT_MUTED #8FB3BA`, `TEXT_DISABLED`, `STEEL_BORDER`, `CYAN_GLOW`, `AMBER_GLOW`, `SCRIM`,
`TEXT_OUTLINE` · kit (decoration only): `OBSIDIAN #0B1116`, `STONE_LIGHT #536064`, `STITCH #A78768`,
`IVORY_LIGHT #FAE5C1`, `AMBER_LIGHT #FFD391`.
Cyan = friendly/navigation/focus, amber = actions, warnings, rewards, landmarks, magenta =
enemy/boss/selection only. Never communicate meaning by hue alone — pair with an icon, shape or text.

## Art to use
- **Backgrounds:** `home_background.png` for Home only (animated over by `HomeAmbience`);
  `menu_background.png` for every other menu; the arena for
  gameplay (pause sits over the frozen arena with a `Palette.SCRIM` ColorRect). `TextureRect` with
  `expand_mode = 1`, `stretch_mode = 6`.
- **Icons:** kit glyphs in `res://assets/ui/theme/icons/` (`icon_play`, `icon_pause`, `icon_home`,
  `icon_lock`, `icon_settings`, `icon_shop`, `icon_trials`, `icon_daily`, `icon_stats`,
  `icon_currency`); `hud_health_full` is unused since the HUD lost its lives readout (2026-09-24). Glyphs the kit lacks still come
  from the painted `res://assets/art/ui/system/` set (`03_combo_chain`, `04_high_score`,
  `07_restart`, `10_forms`, `11_upgrades`, `18_reaper`) and `assets/art/ui/mutations/` — legacy
  until redrawn (ADR-0018). Put glyphs in an `IconButton`/`CaptionTile` or beside a value in a plate.

## Rules for screen agents
1. No per-node style overrides: no `theme_override_styles/*`, `theme_override_colors/*` or colour
   literals. Pick a variation; colours in code come from `Palette`.
2. Allowed overrides: `theme_override_font_sizes/font_size` and container `theme_override_constants`.
3. One `PrimaryButton` per screen; everything else Secondary/Icon. Home is always quieter than
   Restart/Play.
4. Keep native heights: Primary 112, Secondary 96, bars 40 / slim 20, plates ~64–80, caption tile
   140 × 164. Use `custom_minimum_size` for **width** on buttons. Inside an `HBoxContainer`/
   `GridContainer` row set `size_flags_vertical = 4` (shrink centre) on buttons and bars.
5. Touch targets ≥ 48 px in the design space, prefer ≥ 96. An `HSlider` accepts touches over its
   whole rect: give it `custom_minimum_size.y = 96`.
6. Tabular numerals are automatic in `ValueLabel`/`AmberValueLabel`. Currency reads `1,250 RP`
   (`RiftPoints.format`), with the `icon_currency` glyph beside it.
7. All text stays code-rendered; never bake words into textures.
8. Keep node names/paths that scripts and tests reference; restyle, don't re-parent.

## Dependencies
`project.godot`: `gui/theme/custom`, `rendering/environment/defaults/default_clear_color` = void
charcoal. The theme's default font is **Pixelify Sans** (OFL; `assets/fonts/pixelify_sans/`). The
builder makes `pixelify_sans.res` from the gdignored `source/PixelifySans.ttf` with no anti-aliasing,
no hinting and whole-pixel positioning, and the engine's default font (Open Sans) is its fallback
for the two glyphs it lacks, → and ✓. No autoloads. The texture step needs Python 3 with Pillow and
numpy.

**Font sizes are multiples of 11** (owner asked for a pixel font, 2026-09-24). Pixelify's pixel is
~1/11 em, so 22, 33, 44, 55 and 66 put one font pixel on exactly 2–6 design px. Any other size draws
uneven pixels. Each old size was scaled ×1.06 (Pixelify is ~6 % narrower than Open Sans) and
snapped to the grid. Use only the regular weight: bolder weights thicken strokes by fractions of a
pixel, and `variation_embolden` smears them. Titles get one font pixel of letter spacing instead.

## How to test
- Owner look-and-feel passes: `tools/validate.sh`, then the Android APK on the phone.
- Texture sanity without Godot: `python assets/ui/theme/tools/build_theme_textures.py --preview`
  → `logs/pixel_ui/theme_textures_preview.png` (native + nearest-stretched nine-patch per piece).
  The step fails if a piece leaves the 4 px grid or an explicit band is not uniform.
- Components: `tools/run_tests.sh focus_carousel`. Gallery: `res://scenes/debug/theme_gallery.tscn`.

## Known issues / TODO
- Side studs and runes sit at their native distance from the top on taller-than-native pieces
  (PLAY 134, HUD upgrade tile 132, carousel cards, crest panels). A one-band nine-patch cannot keep
  them centred; the alternative (edge-ornament scenes per piece) was not worth it yet.
- On a phone whose screen is not 1080 wide, the canvas scale is not a whole number, so font pixels
  land 1 px uneven (no blur, since anti-aliasing is off). The UI kit shares this.
- The kit's plates and caption slot are sized for ~16–24 px text; plates grow to fit 36–48 px values.
- Painted glyphs, mutation icons, the Home PLAY glow/sheen and the Results score rays are soft,
  non-pixel art still on screen (legacy until redrawn).

## Change history
| Date | Change |
|---|---|
| 2026-09-25 | Story Rifts removed (owner): the Rift Map no longer uses `FocusCarousel` or its arena background |
| 2026-09-24 | Pixel font: Pixelify Sans as the theme default (crisp FontFile built by the theme builder), every size on the 11 grid (theme and all per-node overrides), no embolden on titles |
| 2026-09-24 | Pixel UI kit integrated: theme rebuilt from `concept_art/wisp_rush_pixel_ui_v1/` with nearest `CanvasTexture` wrappers; new `CaptionTile` (Home tiles) and `RewardPlate` (Results/Daily rewards); kit glyphs replace painted ones where the kit has them; `PageDots` draws kit diamonds; hard shadows instead of glows |
| 2026-09-24 | Added source-only pixel-art replacement kit for menus and HUD; runtime Theme unchanged |
| 2026-09-15 | In-run upgrade tray: just a `SlimProgressBar` timeout and three `CardButton`s; no new variations |
| 2026-09-15 | `RushProgressBar` variation for the HUD RUSH meter (spec rush_and_feel); theme regenerated |
| 2026-09-15 | Shop tab bar reuses `NavBar` + toggle `NavButton`s; no new variations (spec 04) |
| 2026-09-13 | Captioned tile pattern (Home columns, RIFTS); `NavButton`/`NavBar` now unused |
| 2026-09-13 | `NavButton`/`NavBar` variations; shared `FocusCarousel` + `PageDots` and the card-picker pattern |
| 2026-09-11 | Created: redesign v1 theme, Palette, ornaments, gallery (replaces the violet per-node styling) |
