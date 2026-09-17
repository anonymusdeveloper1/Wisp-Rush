# System: UI design system (redesign v1 theme)

> **Status:** ✅ done (all screens migrated 2026-09-11) ·
> **Last updated:** 2026-09-15 · **GDD section:** §UI / presentation
>
> Source of truth for the look: `concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md` (palette, UI and
> UX rules) and `assets/15_six_screen_ui_handoff_board.png` (layouts). Never edit `concept_art/`.

## Purpose
One project-wide Godot `Theme` built from the redesign frame kit, so every screen gets the
stone-and-cyan look by picking a **type variation** instead of hand-made StyleBoxes and colours.
It is set as `gui/theme/custom` in `project.godot`, so every Control uses it with no extra setup.

## Files
| Path | Role |
|---|---|
| `res://assets/ui/theme/wisp_theme.tres` | The theme (generated; do not hand-edit) |
| `res://assets/ui/theme/textures/*.png` + `slices.json` | Nine-patch-safe textures derived from `assets/art/ui/frames/` + their margins |
| `res://assets/ui/theme/ornaments/*.tscn` | Optional centre ornaments (crest medallion, diamonds, amber gem) |
| `res://assets/ui/theme/tools/build_theme_textures.py` | Step 1: splice/recolour frame pieces → textures + `slices.json` |
| `res://assets/ui/theme/tools/build_wisp_theme.gd` | Step 3: builds the `.tres` + ornament scenes from `slices.json` + `Palette` |
| `res://scripts/utils/palette.gd` | `class_name Palette` — typed palette constants |
| `res://scripts/components/focus_carousel.gd` | `FocusCarousel` — shared portrait card picker (Shop tabs, Rift Map) |
| `res://scripts/components/page_dots.gd` | `PageDots` — diamond page indicator that follows a carousel |
| `res://scenes/debug/theme_gallery.tscn` (+ `.gd`) | Every variation on one screen (visual reference) |

Rebuild (repo root): `python3 assets/ui/theme/tools/build_theme_textures.py --preview` →
`$GODOT --headless --path . --import` → `$GODOT --headless --path . --script res://assets/ui/theme/tools/build_wisp_theme.gd`.
To retune colours/fonts/margins edit `palette.gd` or the builder constants, never the `.tres`.

## Type variations (set `theme_type_variation`)
Sizes are in the 1080×1920 design space (≈ ×0.36 on a 390 pt phone).

| Variation | Base | Use it for |
|---|---|---|
| *(default)* `Button` | Button | Same as `SecondaryButton`. Any button that is not the screen's one main action |
| `PrimaryButton` | Button | The single dominant, bottom-reachable action: Play, Restart, Daily Play, Buy/Equip form. ~110 px tall, 44 px text, glowing cyan when pressed or focused. One per screen |
| `SecondaryButton` | Button | Quieter tier: Home on Results, Back, Resume/Quit in Pause, settings actions. ~94 px, 34 px text |
| `DangerButton` | Button | Destructive/irreversible (reset progress, abandon run). Amber inlay + text; always confirm |
| `IconButton` | Button | Square icon-only slot: Pause, Settings, Back, Stats. Set `icon`, no text. 112×112 min, icon ≤ 64 px |
| `SlotButton` | Button | Grid slots (reward tiles). Use `toggle_mode`; **pressed/toggled = magenta selection**. Set `expand_icon = true` for portraits |
| `CardButton` *(extra)* | Button | Tappable tall cards: the three cards of the in-run upgrade tray (`focus_mode` none, magenta `panel_card_selected` highlight on hover) and every `FocusCarousel` card (Shop tabs, Rift Map). Pressed/toggled = magenta card. `vertical_icon_alignment = TOP` puts the icon above the text |
| `NavButton` *(extra)* | Button | One tab of a bottom navigation bar: flat, icon (box `NAV_ICON` 96) above a 26 px caption (`FONT_NAV`), muted text that turns soul white; pressed/focused = chamfered cyan lozenge. Only inside a `NavBar`. Since 2026-09-15 the Shop's tab bar: toggle-mode `NavButton`s in one `ButtonGroup`, text only (pressed = selected tab), so no `ShopTab` variation was added |
| *(default)* `PanelContainer` | PanelContainer | Plain framed panel: info boxes, goal rows, settings groups, pause panel |
| `PanelCard` | PanelContainer | Non-interactive tall card/tile: run-metric tiles, stat tiles, form details |
| `PanelCrest` | PanelContainer | One hero panel per screen: Daily Rift portal card, Results score block. Needs ≥ ~380×310 |
| `PanelBanner` | PanelContainer | Screen title banner ("FORMS", "DAILY RIFT", "RUN COMPLETE"); put a `TitleLabel` inside |
| `PanelPlate` | PanelContainer | Small value pill: Rift Points counter, best score, rewards. Icon + `ValueLabel` / `AmberValueLabel` (font size override 36–44 is fine) |
| `NavBar` *(extra)* | PanelContainer | A bottom navigation dock: default stone panel with tight vertical padding; holds an `HBoxContainer` of `NavButton`s (expand-fill, separation 0). Used by the Shop tab bar |
| `PortraitRing` | PanelContainer | Circular ring (magenta gems = selected) for a single portrait. Keep it square (≥ 280 px); child `TextureRect` with keep-aspect-centred |
| `TitleLabel` | Label | Screen/banner titles. 48 px, letter-spaced, bold, cyan halo. UPPERCASE text |
| `CaptionLabel` | Label | Secondary text, units, "BEST", row descriptions. 26 px muted slate-cyan |
| `ValueLabel` | Label | Large numerals (wave, kills, counts). 56 px, tabular figures |
| `AmberValueLabel` | Label | Score and rewards (results score, best, Rift Points earned). 64 px amber, tabular, amber glow; raise the size for the Results hero score |
| `ProgressBar` | ProgressBar | Stone track + cyan fill: XP, goal progress. Native height 41 px — don't make it taller |
| `BossProgressBar` *(extra)* | ProgressBar | Reaper health: same track, magenta fill |
| `SlimProgressBar` *(extra)* | ProgressBar | Thin flat bar (18 px) for dense rows (Daily goal rows, HUD XP strip) |
| `RushProgressBar` *(extra)* | ProgressBar | The HUD RUSH meter: the slim track with a Soul White fill and cyan rim, so it never reads as a second XP strip. Only `%RushBar` ([rush_mode.md](rush_mode.md)) |
| `HSlider` / `HSeparator` / `VScrollBar` | — | Default styles: cyan fill + diamond grabber / divider line / thin cyan grabber |
| plain `Label` | Label | Body text 30 px soul white |

Every Button/slider has a cyan focus state (glow ring or chamfered outline) for keyboard/controller.
Hover is deliberately subtle (touch leaves hover stuck on the last tapped button).

## Ornaments (optional, `assets/ui/theme/ornaments/`)
Centre ornaments cannot live in a nine-patch (they would stretch), so they are separate scenes.
Instance one as a **child of a PanelContainer with the matching variation** (any position among
its children); it centres itself on the frame edge. They are pure decoration (`mouse_filter` ignore).

| Scene | Goes in | Look |
|---|---|---|
| `crest_top.tscn` / `crest_bottom.tscn` | `PanelCrest` | Crescent medallion on top / diamond at the bottom |
| `card_top.tscn` | `PanelCard` | Cyan diamond on top |
| `banner_top.tscn` | `PanelBanner` | Small crescent medallion on top (leave ~24 px free above the banner) |
| `amber_top.tscn` | default `PanelContainer` | Amber gem on top — reward/landmark panels only |

They assume the variation's content margins; if you override a panel's content margins, don't use them.
In non-container parents (e.g. inside a `CardButton`) place `textures/ornament_*.png` yourself.

## Shared components (`scripts/components/`)
**Card-picker pattern** (owner decision 2026-09-13, Forms and Rift Map): a vertical screen with a
title, one big tall focused card in the centre (larger, lifted, magenta-framed), dimmed neighbours
peeking in at the sides, `PageDots` under it, one description/status block, then Back
(`SecondaryButton`) and the one main action (`PrimaryButton`). Swipe sideways to browse; tapping the
focused card does the same as the main action. Locked entries stay previewable and say why in text.

**Captioned tile pattern** (Home side columns and RIFTS, 2026-09-13): an `IconButton` sized as a tile
(140×164, or 156×156 for RIFTS) with two mouse-ignoring children — an `Icon` TextureRect (96 px
box at the top) and a 22–24 px `Caption` Label anchored to the bottom. The caption sits on the dark
slot interior, so it stays legible over painted backdrops where a label under the button did not
(it vanished over a brazier). Needs no theme change.

| Component | Behaviour and API |
|---|---|
| `FocusCarousel` (Control) | `set_cards(cards, selected)` adopts screen-built cards (sets them mouse-ignore; a `BaseButton` card becomes toggle-mode and is pressed while focused, so `CardButton` draws the selection frame). Swipe with exponential snap and rubber band at the ends; a flick advances one card (not if the finger stopped > 80 ms before lifting); tap a side card to focus it, tap the focused card → `activated(index)`. Taps are hit-tested against the resting layout, so a quick double tap on a peek strip browses two cards instead of activating the card still sliding in; a cancelled touch, any drag past `tap_slop`, or app focus loss / pause / hide mid-press never counts as a tap (the press snaps instead); `ui_left`/`ui_right`/`ui_accept` when focused. Mouse events only (touch arrives as emulated mouse; handling both would act twice). Signals `selection_changed(index)`, `activated(index)`. Methods `select(index, animate)`, `get_selected_index`, `get_card_count`, `get_card`, `get_scroll`, `is_settled`, `get_focus_card_size`. Exports: `focus_width_share`, `max_width_share` + `max_card_aspect` (spare height grows the card instead of leaving a gap), `card_aspect`, `pitch_share`, `side_scale`, `side_brightness`, `lift_share`, `snap_speed`, `tap_slop`, `flick_speed` |
| `PageDots` (Control) | Drawn diamonds; set `count`, feed `position_value = carousel.get_scroll()` each frame so it slides with a drag; indices in `hollow` draw as outlines (locked entries) |

## Palette (`Palette.*`, see `scripts/utils/palette.gd`)
`VOID_CHARCOAL #111521` · `SLATE_TEAL #263D42` · `SOUL_CYAN #62E8F2` · `SOUL_WHITE #EAFDFF` ·
`WARNING_AMBER #F3A847` · `RIFT_MAGENTA #B14CD9` · `MOSS_GREEN #5E7D4C` · derived: `PANEL_BG`
(near-black blue, 92 %), `TEXT_MUTED #8FB3BA`, `TEXT_DISABLED`, `STEEL_BORDER`, `CYAN_GLOW`,
`AMBER_GLOW`, `SCRIM` (void 72 % — modal dim), `TEXT_OUTLINE`.
Cyan = friendly/navigation/focus, amber = warnings/rewards/landmarks, magenta = enemy/boss/selection
only. Never communicate meaning by hue alone — pair with an icon, shape or text.

## Art to use
- **Backgrounds:** `res://assets/art/environment/home_background.png` for Home only (animated over,
  never altered, by `HomeAmbience`); the Rift Map shows the focused Rift's arena (crossfade);
  `menu_background.png` for every other menu (Forms, Daily, Stats, Settings, Results, loading);
  `wisp_rush_arena_background.png` for gameplay (the pause overlay sits over the frozen arena with a
  `Palette.SCRIM` ColorRect; the upgrade tray is a bottom default `PanelContainer` over the live,
  slowed arena, no scrim). `TextureRect` with `expand_mode = 1` (ignore size),
  `stretch_mode = 6` (keep aspect covered).
- **Icons:** `res://assets/art/ui/system/` — `01_soul_life`, `02_soul_shards`, `03_combo_chain`,
  `04_high_score`, `05_play`, `06_pause`, `07_restart`, `08_sound`, `10_forms`, `11_upgrades`,
  `13_daily`, `14_statistics`, `15_settings`, `16_home`, `17_lock`, `18_reaper` (`09_mute` and
  `12_store` no longer exist). They are bare glyphs — put them in an `IconButton`/`SlotButton`
  or next to a value in a `PanelPlate`. Mutation icons: `assets/art/ui/mutations/`.
- **Frame pieces** in `assets/art/ui/frames/` are the sources; screens use the theme, not the PNGs.

## Rules for screen agents
1. **Delete per-node style overrides** from the old violet design: every
   `theme_override_styles/*` StyleBoxFlat, `theme_override_colors/*`, and old violet/plum colour
   literals in scripts. Replace them with `theme_type_variation = &"…"` from the table above.
   Colours in code come from `Palette`, never literals.
2. Allowed overrides: `theme_override_font_sizes/font_size` (sizing to the layout) and container
   `theme_override_constants` (separation/margins). Nothing else without updating the theme.
3. One `PrimaryButton` per screen; everything else Secondary/Icon. Home is always quieter than
   Restart/Play.
4. Keep native heights: Primary ~110, Secondary ~94, ProgressBar 41. Use `custom_minimum_size`
   only for **width** on buttons (and square size on slots/rings/cards). Inside an
   `HBoxContainer`/`GridContainer` row set `size_flags_vertical = 4` (shrink centre) on buttons and
   bars, otherwise the row stretches them to its tallest child. (Buttons survive moderate extra
   height, which lengthens their sides; bars do not.)
5. Touch targets ≥ 48 px in the design space, and prefer ≥ 96 px (≈ 35 pt). An `HSlider` accepts
   touches over its whole rect: give it `custom_minimum_size.y = 96`.
6. Tabular numerals are automatic in `ValueLabel`/`AmberValueLabel`; use them for score, wave,
   Rift Points and goal progress (`12 / 20`). Currency reads `1,250 RP` (`RiftPoints.format`), with
   the `02_soul_shards` icon beside it.
7. All text stays code-rendered; never bake words into textures.
8. Keep node names/paths that scripts and tests reference; restyle, don't re-parent.

## Dependencies
`project.godot`: `gui/theme/custom`, `rendering/environment/defaults/default_clear_color` = void
charcoal. Uses Godot's default font (Open Sans SemiBold, supports `tnum`). No autoloads.

## How to test
- Visual: `WISP_ISOLATED_SAVE=1 tools/screenshot.sh res://scenes/debug/theme_gallery.tscn 20`,
  then Read `logs/screenshot.png`. Texture preview without Godot: the `--preview` flag writes
  `logs/redesign/design/theme_textures_preview.png` (native + stretched nine-patch).
- Parse: `tools/godot/check_scripts.gd` covers the builder and gallery scripts.
- Components: `tools/run_tests.sh focus_carousel` (layout, swipe-snap, flick, hold-then-release, tap, rapid double tap, cancelled / focus-lost presses, damped rubber band, keys, clamping, card replacement — real GUI input).
- Phone layouts: `tools/qa_matrix.sh home forms rifts rifts_locked` → `logs/qa/<screen>_sheet.png`.

## Known issues / TODO
- Buttons, ProgressBars and plates have side tips/diamonds on their vertical stretch row: making
  them much taller than native elongates the tips. Change width, not height.
- Magenta corner ticks of the source frames are recoloured to steel cyan on default pieces.
- Hover uses `modulate_color` > 1 (brighten); on touch hover is nearly invisible by design.

## Change history
| Date | Change |
|---|---|
| 2026-09-15 | In-run upgrade tray: just a `SlimProgressBar` timeout and three `CardButton`s (no frame or header, no HUD pill — owner simplified it); no new variations |
| 2026-09-15 | `RushProgressBar` variation for the HUD RUSH meter (spec rush_and_feel); theme regenerated |
| 2026-09-15 | Shop tab bar reuses `NavBar` + toggle `NavButton`s; no new variations (spec 04) |
| 2026-09-13 | Captioned tile pattern (Home columns, RIFTS); `NavButton`/`NavBar` now unused |
| 2026-09-13 | `NavButton`/`NavBar` variations; shared `FocusCarousel` + `PageDots` and the card-picker pattern |
| 2026-09-11 | Created: redesign v1 theme, Palette, ornaments, gallery (replaces the violet per-node styling) |
