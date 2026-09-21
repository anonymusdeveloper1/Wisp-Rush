# Eclipse Wisp — whole-frame sprite pack v1

Status: **review source; not integrated into runtime art**.

This pack gives the Eclipse form a new silhouette while keeping it unmistakably a Wisp. The old
upright purple flame is now a compact celestial corona: an obsidian face-core surrounded by opposing
dark-violet and gold-white crescents, three lower flame ribbons and a close orbit of moon beads. It
has no arms, hands, legs, clothing or held weapon. Its own gold crescent becomes the dash contact
edge.

The phase atlases contain separately drawn neighbouring poses. Flame tips, corona light, eyes,
ribbons and moon beads advance through short continuous arcs so loops do not cut between unrelated
paintings.

## Deliverables

- `frames/eclipse_wisp/` — 78 gameplay/wall frames at 512 × 512.
- `frames/eclipse_wisp/storefront/` — 30 menu frames at 724 × 724.
- `key_pose_atlas.png` — the redesigned form and sixteen state silhouettes.
- `*_phase_atlas.png` — separately drawn animation phases used by the builder.
- `sheets/eclipse_wisp_sprite_sheet.png` — transparent one-row-per-state review sheet.
- `sheets/eclipse_wisp_sprite_sheet_preview.png` — labelled dark-background review copy.
- `sheets/eclipse_wisp_sprite_sheet.json` — exact row, frame, speed and smoothness map.
- `previews/*.gif` — playback checks for idle, movement, top-wall and storefront loops.

`character_selected` uses `storefront_flourish`; `character_unlocked` uses
`storefront_unlock`. `wall_right` is a runtime mirror of `wall_left`. `dash_loop_02` is the dash
contact/attack frame. `aim_charge` is intentionally absent. The complete pack has 108
pixel-distinct frames.

Rebuild with:

```powershell
python concept_art/eclipse_wisp_sprite_v1/build_sprite_pack.py
```

Do not copy these files directly into `assets/art/`. They remain source art under
`concept_art/.gdignore` until the owner approves the redesign and motion.
