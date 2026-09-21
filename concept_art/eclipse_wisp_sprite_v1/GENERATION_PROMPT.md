# Eclipse Wisp sprite generation record

Generated with the built-in OpenAI image tool using the current runtime form
`assets/art/characters/forms/06_eclipse.png` as the material and identity reference.

## Redesign lock

Keep the character a handless, legless floating Wisp, but replace the ordinary upright flame form
with a compact celestial corona. Its glossy obsidian teardrop-round face-core carries two warm oval
eyes and a four-point gold brow star. A broken eclipse halo is part of its flame anatomy: a dark
violet crescent on the upper-left and a gold-white crescent on the upper-right. Three soft flame
ribbons taper below it and two or three moon beads orbit close to the body. The crescents are not
held weapons. No humanoid torso, robe or animal anatomy.

## Generated atlases

- `key_pose_atlas.png`: strict 4 × 4 redesigned identity board — idle, move, dash launch, dash
  contact, dash landing, attack, hit, death, revive, victory, wall bottom, wall top, wall left,
  storefront idle, flourish and unlock.
- `loop_phase_atlas.png`: four phases each for idle, move, victory and storefront idle.
- `action_phase_atlas.png`: dash launch/end, four +Y-facing dash-flight frames, attack and hit.
- `death_spawn_floor_atlas.png`: six collapse frames, six reform frames and four floor-cling phases.
- `wall_menu_phase_atlas.png`: four phases each for top wall, left wall, flourish and unlock.

All atlases require a transparent background, one equal-scale Wisp per cell and the face-core at the
same cell-center anchor. Each neighboring drawing changes only a few flame curves, a small light
pulse, an eye expression step or a short bead/ribbon arc. Loops close gently. Action sequences may
change the silhouette more strongly overall, but still use readable in-betweens. Wall poses stay
upright in screen space. Dash and attack point down the canvas along +Y because the runtime rotates
the entire frame toward travel.

`build_sprite_pack.py` expands the separately drawn phases to the exact 108-frame character
contract with sub-pixel timing changes. It never cross-fades two bodies. `aim_charge` is not
generated.
