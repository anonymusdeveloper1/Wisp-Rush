# Void Wisp sprite generation record

Generated with the built-in OpenAI image tool using the current runtime form
`assets/art/characters/forms/01_void.png` as the identity reference.

## Identity lock

Keep the original Wisp form: a handless, legless floating soul-flame creature with a glossy black
round face core, two luminous oval eyes, a four-point forehead star, layered cyan/cobalt/white fire,
a large crescent side plume with a hanging diamond ornament and a few detached comet wisps. Do not
turn it into a humanoid, animal or robed person. No scenery, text, borders, shadows, weapons, motion
trails or baked particles. Transparent background. Keep the core anchor at the exact centre of each
cell and keep scale consistent.

## Generated atlases

- `key_pose_atlas.png`: strict 4 × 4 identity board — idle, move, dash launch, dash contact, dash
  landing, attack, hit, death, revive, victory, wall bottom, wall top, wall left, storefront idle,
  storefront flourish and storefront unlock.
- `loop_phase_atlas.png`: four phases each for idle, move, victory and storefront idle.
- `action_phase_atlas.png`: dash launch/end, four dash-flight frames, attack and hit.
- `death_spawn_floor_atlas.png`: six death frames, six reform frames and four floor-cling phases.
- `wall_menu_phase_atlas.png`: four phases each for top wall, left wall, flourish and unlock.

For every row, each next drawing changes only slightly: shift individual flame tips by a few pixels,
alter the core glow by one small step, use a single blink phase where appropriate, and move the
crescent plume, diamond and comet wisps along short continuous arcs. Preserve the same silhouette
mass, ornament placement, line weight, palette, materials, lighting direction and centre anchor.
Loops must close gently from their last phase back to the first. Actions may change more strongly
overall, but their neighbouring frames still need readable in-betweens.

`build_sprite_pack.py` expands these separately drawn phases to the exact 108-frame character
contract with extremely small centred timing deformations. It never cross-fades two bodies.
`aim_charge` is not generated.
