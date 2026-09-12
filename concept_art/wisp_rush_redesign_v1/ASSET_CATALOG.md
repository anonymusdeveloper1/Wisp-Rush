# Wisp Rush redesign v1 — asset catalog

All paths are relative to this folder. **Ready candidate** means suitable for an implementation
evaluation, not that it has been approved or imported. **Prep required** means the visual design is
complete but background extraction, atlas separation or manual cleanup is still required.

Inventory: **21 files** · **12 ready candidates** · **3 prep required** · **4 archive drafts** ·
**2 visual references**.

| File | Size | Alpha/background | Status | Intended use |
|---|---:|---|---|---|
| `assets/01_visual_target_key_art.png` | 941×1672 | Opaque | Reference | Master art-direction target; not a runtime plate because it includes concept HUD/combat. |
| `assets/02_gameplay_arena_floor.png` | 941×1672 | Opaque | Ready candidate | Empty 9:16 gameplay arena. Scale to 1080×1920; keep collision authored in Godot. |
| `assets/03_home_background.png` | 941×1672 | Opaque | Ready candidate | Home hero background with title-safe top and dark lower action zone. |
| `assets/04_shared_menu_background.png` | 941×1672 | Opaque | Ready candidate | Low-contrast background for Forms, Daily, upgrades, stats, settings, pause and Results. |
| `assets/05_wisp_animation_sheet.png` | 1448×1086 | Alpha | Archive draft | First 4×3 Wisp state sheet; 362×362 cells, but excess detached energy texture remains. |
| `assets/05_wisp_animation_sheet_v2.png` | 1448×1086 | Alpha | Prep required | Preferred 4×3 state direction; 362×362 cells. Mask detached blue/cyan noise per frame. |
| `assets/06_enemy_animation_sheet.png` | 1175×1338 | Baked checker | Archive draft | Original three-family/four-state presentation source. Do not import as transparent art. |
| `assets/06_enemy_animation_sheet_v2.png` | 1176×1338 | Alpha | Ready candidate | Three families × four states. Use manual silhouette bounds rather than a fixed grid. |
| `assets/07_reaper_animation_sheet.png` | 1448×1086 | Baked checker | Archive draft | Original Reaper 4×3 presentation sheet. |
| `assets/07_reaper_animation_sheet_v2.png` | 1448×1086 | Alpha | Ready candidate | Preferred Reaper 4×3 atlas; exact 362×362 cells and twelve encounter states. |
| `assets/08_hazards_pickups_sheet.png` | 1448×1086 | Baked checker | Prep required | Hazard, warning and reward design source; 4×3, 362×362 cells. Extract before use. |
| `assets/09_additive_vfx_sheet.png` | 1448×1086 | Pure black | Ready candidate | Twelve 362×362 VFX cells intended for additive/screen blending. |
| `assets/10_ui_frame_kit.png` | 1086×1448 | Alpha | Ready candidate | Twelve 362×362 source cells containing panels, buttons, slot, portrait, bar and divider. |
| `assets/11_ui_icon_sheet.png` | 1230×1278 | Alpha | Ready candidate | Sixteen navigation/status glyphs. Use manual icon bounds and normalize to a shared export box. |
| `assets/12_form_portraits_sheet.png` | 1536×1024 | Baked checker | Prep required | Six 512×512 form portraits in Void/Ash/Venom/Bloodmoon/Frost/Eclipse order. |
| `assets/13_upgrade_icon_sheet.png` | 1774×887 | Baked checker | Archive draft | Original eight-mutation presentation source. |
| `assets/13_upgrade_icon_sheet_v2.png` | 1774×887 | Alpha | Ready candidate | Preferred eight-mutation cutouts; use manual bounds, then normalize to square exports. |
| `assets/14_brand_mark.png` | 1254×1254 | Alpha | Ready candidate | Standalone Wisp/crescent rush emblem and app-icon source. |
| `assets/15_six_screen_ui_handoff_board.png` | 1225×1284 | Opaque | Reference | Home, gameplay, upgrade, Forms, Daily and Results UX/layout target. Never slice as production UI. |
| `assets/16_wordmark_logo.png` | 1536×1024 | Alpha | Ready candidate | Reviewed stacked `WISP RUSH` wordmark lockup; verify small-size legibility before replacement. |
| `assets/17_wisp_gameplay_master.png` | 1254×1254 | Alpha | Ready candidate | Clean neutral-idle Wisp master; preferred starting point for gameplay sprite production. |

## Atlas order

### Wisp sheet (`05_*`, 4×3)

Idle A · Idle B · Aim · Charge / Dash left · Dash right · Soul Reap · Wall impact / Hurt ·
Death · Reform · Victory.

### Enemy sheet (`06_*`, 3×4)

Columns: Soul Wisp · Shard Wraith · Bone Mote. Rows: Idle A · Idle B · Hit · Defeat.

### Reaper sheet (`07_*`, 4×3)

Idle A · Idle B · Gate arrival · Windup / Sweep · Vanish · Appear · Exposed core / Hit ·
Corridor cast · Stagger · Defeat.

### Hazards/pickups (`08_*`, 4×3)

The generation followed the requested families loosely rather than mechanically. Treat each cell
as an individually named concept during extraction. The visible groups are void-crystal states,
spike/crystal bloom states, blade-ring states and soul-flame/crystal/portal rewards.

### VFX (`09_*`, 4×3)

Short dash · Long dash · Wall impact · Soul slice / Death pulse · Enemy hit · Dissolve ·
Teleport vanish / Teleport appear · Boss warning · Pickup sparkle · Victory pulse.

### UI icons (`11_*`, 4×4)

Play · Forms · Daily · Upgrades / Statistics · Settings · Sound · Pause / Restart · Home · Life ·
Soul Shards / Combo · Score · Lock · Reaper.

### Mutations (`13_*`, 4×2)

Wide Reap · Soul Hunger · Death Pulse · Soul Link / Cold Wake · Void Velocity · Soul Vessel ·
Reaper's Gift.

## Integration checklist for the next agent

1. Do not overwrite `assets/art/`; create a versioned implementation branch/folder first.
2. Obtain owner approval on the key art and six-screen board.
3. Extract atlas cells non-destructively and keep these sources unchanged.
4. Remove baked checkerboards from files marked prep required before Godot import.
5. Normalize gameplay sprites to existing pivots/collision geometry; cosmetics must not change it.
6. Convert UI frames to nine-patch-safe pieces and render all text in Godot.
7. Use `09_additive_vfx_sheet.png` with additive/screen blend; black is intentional.
8. Test icons at device scale, color-blind shape recognition and all safe areas.
9. Replace references screen-by-screen, with visual snapshots and rollback-friendly commits.
