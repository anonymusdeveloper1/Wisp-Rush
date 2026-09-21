# Ilyra 2 — sprite experiment

Status: **concept review only; not integrated into the game**.

This pack tests a state-swapped `AnimatedSprite2D` version of Ilyra while preserving the existing
skinned/procedural Ilyra unchanged. The images were generated with the built-in image-generation
tool from the approved Ilyra v3 concept and runtime preview, then reviewed and separated into
equal 627×627 transparent canvases.

## Review files

- `review_contact_sheet_final.png` — the complete 20-pose review board.
- `final_sprites/` — the proposed implementation inputs.
- `pose_sheets/` — the five original 2×2 generations.
- `sprites/` — first-pass quadrant crops; not the implementation inputs.
- `revisions/` — full-resolution corrections for the bottom and top wall poses.
- `clean_sprite_crops.py` — reproducibly removes small neighboring-cell fragments from crops.
- `GENERATION_PROMPTS.md` — prompt set and reference roles.
- `CLAUDE_IMPLEMENTATION_PROMPT.md` — ready-to-paste implementation request.

## State-to-sprite proposal

| Runtime state | Sprite(s) | Playback proposal |
|---|---|---|
| `idle_hover` | `idle_hover`, `idle_blink` | Hold idle; show blink briefly every 2.6–6.4 s |
| `move_fly` | `move_fly_00`, `move_fly_01` | 4 fps ping-pong |
| `aim_charge` | `aim_charge` | Static pose; retain base pulse/glow |
| `dash_start` | `dash_start_00`, `dash_start_01` | 16 fps one-shot |
| `dash_loop` | `dash_loop_00`, `dash_loop_01_attack` | 12 fps loop; forward is image `-Y` |
| `dash_end` | `dash_end` | Static recovery pose |
| `attack` | `dash_loop_01_attack` | Hold for the 0.24 s contact accent |
| `hit_reaction` | `hit_reaction` | Static one-shot |
| `death` | `death` | Static one-shot |
| `revive_spawn` | `revive_spawn` | Static one-shot plus base spawn animation |
| `victory` | `victory` | Static loop plus base hover |
| `character_selected` | `character_selected` | Static one-shot |
| `character_unlocked` | `character_unlocked` | Static one-shot |

## Surface-contact override

The wall sprites are already oriented in screen space, not local character space:

| Inward `surface_normal` | Sprite |
|---|---|
| `Vector2.UP` — bottom/floor | `wall_bottom` |
| `Vector2.DOWN` — top/ceiling | `wall_top` |
| `Vector2.RIGHT` — left wall | `wall_left` |
| `Vector2.LEFT` — right wall | `wall_right` |

Use these only for a live gameplay character resting on a surface. Home and Shop previews should
continue to use `idle_hover`. Because `PlayableCharacterVisual` rotates the visual root to the
surface normal, the implementation must cancel that inherited rotation for these four already
screen-oriented wall sprites.

## Review notes

- `wall_bottom` is the corrected four-arm revision. The first-pass `sprites/wall_bottom.png` is
  retained only for provenance.
- `wall_top` is the corrected padded revision; its first-pass crop clipped the raised fists.
- The dash faces upward so the existing heading system can rotate it toward travel.
- Each final asset has alpha and an equal canvas, but the opaque bounds differ by pose. The runtime
  must calculate or author a per-pose scale and offset so apparent height stays consistent and the
  collision-centre anchor does not jump. This is especially important for the padded `wall_top`.
- This is intentionally an AI-assisted test pack. Minor costume rendering differences remain and
  require owner approval before any production promotion.
