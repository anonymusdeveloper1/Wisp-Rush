# Key-pose atlas generation prompt

Generated with the built-in OpenAI image tool. The reference image was
`concept_art/verdant_shade_v1/concept_board_v2.png` and was used only to preserve Verdant Shade's
identity, materials, palette and painterly Wisp Rush rendering.

The first generation requested a transparent 4 × 4 atlas with, in order: neutral idle, move, dash
launch, dash contact, dash landing, attack, hit, death, revive, victory, wall bottom, wall top, wall
left, storefront idle, storefront flourish and storefront unlock.

Four follow-up 4 × 4 atlases replace transformed copies with distinct animation drawings:

- `loop_phase_atlas.png`: four phases each for idle, move, victory and storefront idle.
- `action_phase_atlas.png`: dash launch/end, four dash-flight phases, attack and hit phases.
- `death_spawn_floor_atlas.png`: six death frames, six reform frames and four floor-cling phases.
- `wall_menu_phase_atlas.png`: four phases each for top/left walls, flourish and unlock.
- `wall_top_phase_strip.png`: correction strip that keeps the body upright and sends three distinct
  hooked root-ribbons above the hood to the ceiling contact.

Every prompt explicitly prohibited arms, hands, legs, weapons, scenery, labels, borders, trails and
watermarks, required the core/hip anchor at the exact centre of every cell, and asked for visible
changes to flame silhouettes, cloak-leaf overlap, eye expression and root-ribbon curvature.

The exact frame counts are deterministic output from `build_sprite_pack.py`; it never cross-fades
two bodies, and only adds tiny centred timing steps within a drawn phase. `aim_charge` is not
generated.
