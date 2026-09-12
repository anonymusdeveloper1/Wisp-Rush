# Wisp Rush — visual redesign concept pack v1

> **Status:** concept handoff only · **Created:** 2026-09-11 · **Not integrated into Godot**

This folder is a self-contained visual direction for a future Wisp Rush redesign. It synthesizes
the six owner-provided Pinterest references into an original system built around a luminous Wisp,
ancient floating sanctuaries, top-down mobile readability and engraved supernatural UI.

The handoff contains **21 visual files**: 12 ready candidates (including one additive VFX atlas),
3 sources that require cleanup, 4 preserved drafts and 2 visual-reference boards.

No scene, script, Resource or existing production asset points at these files. An implementation
agent can evaluate and prepare them without changing the finished game until the owner explicitly
approves the redesign.

## Start here

- [STYLE_GUIDE.md](STYLE_GUIDE.md) — art direction, palette, camera, UI and UX rules.
- [ASSET_CATALOG.md](ASSET_CATALOG.md) — every generated asset, dimensions and readiness.
- [GENERATION_PROMPTS.md](GENERATION_PROMPTS.md) — reproducible prompt set.
- [REFERENCES.md](REFERENCES.md) — what was learned from each supplied reference.
- [manifest.json](manifest.json) — machine-readable asset inventory.

## Recommended evaluation order

1. [`01_visual_target_key_art.png`](assets/01_visual_target_key_art.png) — overall target.
2. [`15_six_screen_ui_handoff_board.png`](assets/15_six_screen_ui_handoff_board.png) — screen hierarchy.
3. [`02_gameplay_arena_floor.png`](assets/02_gameplay_arena_floor.png),
   [`03_home_background.png`](assets/03_home_background.png) and
   [`04_shared_menu_background.png`](assets/04_shared_menu_background.png).
4. [`17_wisp_gameplay_master.png`](assets/17_wisp_gameplay_master.png), then the selected
   `*_v2.png` character/icon sheets.
5. [`10_ui_frame_kit.png`](assets/10_ui_frame_kit.png),
   [`11_ui_icon_sheet.png`](assets/11_ui_icon_sheet.png) and
   [`16_wordmark_logo.png`](assets/16_wordmark_logo.png).

## Important production note

The pack deliberately keeps source generations untouched. Files marked **ready candidate** have
usable alpha or an intentional black additive background; files marked **prep required** are visual
source sheets whose checkerboard must be removed and whose sprites must be separated before Godot
integration. See the catalog for the status of each file.
