# Void Wisp — whole-frame sprite pack v1

Status: **review source; not integrated into runtime art**.

This pack redesigns the existing Void form as a complete animated Wisp while preserving its
recognizable identity: cyan-white soul flame, glossy black face core, bright eyes, forehead star,
crescent plume, hanging diamond and small comet wisps. It remains a floating handless Wisp in every
state. The source phase atlases contain separately drawn neighbouring poses so the fire contour,
core glow, eyes and trailing wisps advance by small steps instead of cutting between unrelated
paintings.

## Deliverables

- `frames/void_wisp/` — 78 gameplay/wall frames at 512 × 512.
- `frames/void_wisp/storefront/` — 30 menu frames at 724 × 724.
- `key_pose_atlas.png` — the 16-state identity and silhouette board.
- `*_phase_atlas.png` — separately drawn animation phases used by the builder.
- `sheets/void_wisp_sprite_sheet.png` — transparent one-row-per-state review sheet.
- `sheets/void_wisp_sprite_sheet_preview.png` — labelled dark-background review copy.
- `sheets/void_wisp_sprite_sheet.json` — exact row, frame, speed and smoothness map.
- `previews/*.gif` — quick playback checks for the four most important loops.

`character_selected` uses `storefront_flourish`; `character_unlocked` uses
`storefront_unlock`. `wall_right` is a runtime mirror of `wall_left`. `dash_loop_02` is the dash
contact/attack frame. `aim_charge` is intentionally absent. The complete review pack has 108
pixel-distinct frames.

Rebuild with:

```powershell
python concept_art/void_wisp_sprite_v1/build_sprite_pack.py
```

Do not copy these files directly into `assets/art/`. They remain source art under
`concept_art/.gdignore` until the owner approves the look and motion. The Eclipse Wisp is not part
of this pack and has not been changed.
