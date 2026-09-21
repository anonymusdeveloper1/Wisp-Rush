# Verdant Shade — whole-frame sprite pack v1

Status: **review source; not integrated into runtime art**.

This pack turns the approved green hooded creature from
`concept_art/verdant_shade_v1/concept_board_v2.png` into the complete whole-frame animation order.
`key_pose_atlas.png` establishes the identity and state silhouettes. Four generated phase atlases
then provide genuinely different drawings for every move: flame shapes, leaf overlap, eyes and
root-ribbon curves change between neighbours. `build_sprite_pack.py` keeps their cell registration,
adds crisp micro-timing inside each drawn phase and writes the exact state counts as numbered PNGs.

## Deliverables

- `frames/verdant_shade/` — 78 gameplay/wall frames at 512 × 512.
- `frames/verdant_shade/storefront/` — 30 menu frames at 724 × 724.
- `*_phase_atlas.png` — the separately drawn animation phases used to build the numbered frames.
- `wall_top_phase_strip.png` — corrected upright ceiling-cling phases with three visible hooks.
- `sheets/verdant_shade_sprite_sheet.png` — one-row-per-state transparent review sheet, 256 px cells.
- `sheets/verdant_shade_sprite_sheet_preview.png` — labelled dark-background review copy.
- `sheets/verdant_shade_sprite_sheet.json` — exact row/frame map.

`character_selected` uses `storefront_flourish`; `character_unlocked` uses `storefront_unlock`.
`wall_right` is a runtime mirror of `wall_left`. `aim_charge` is intentionally absent.
The complete review pack contains 108 frames.

Rebuild with:

```powershell
python concept_art/verdant_shade_sprite_v1/build_sprite_pack.py
```

Do not copy these files directly into `assets/art/`. They remain review sources until the owner
accepts the animation and the deterministic playable-character intake registers the pack.
