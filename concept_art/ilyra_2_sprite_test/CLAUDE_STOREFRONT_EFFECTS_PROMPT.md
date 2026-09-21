# Claude follow-up — Ilyra 2 storefront/Home animation and gameplay VFX

Read `AGENTS.md` and the required project docs before changing anything. Preserve every existing
uncommitted change, including the current Ilyra 2 implementation. This is a focused polish pass:
the owner says the overall gameplay animation is good. Do **not** redesign or retime Ilyra 2's
gameplay poses, dash behavior, wall poses, controls, collisions, hitboxes, combat timing, or
camera. Add only the presentation animation and lightweight additive effects described below.

## Source assets

Use the approved source-art package:

`concept_art/ilyra_2_sprite_test/detached_parts/`

Important files:

- `storefront_frames/storefront_welcome.png`
- `storefront_frames/storefront_blink.png`
- `storefront_frames/storefront_flourish.png`
- `storefront_frames/storefront_settle.png`
- `sprites/secondary_motion/sparkle_00.png`
- `sprites/secondary_motion/sparkle_01.png`
- `sprites/secondary_motion/sparkle_pair.png`
- `sprites/secondary_motion/chest_gem_glow.png`
- `sprites/secondary_motion/dash_slash.png`
- `README.md` for the rig and playback notes

Do not load anything from `concept_art/` at runtime. Add the approved images to the existing
deterministic playable-character extraction/import path and generate runtime assets under
`assets/art/characters/playable/ilyra_2/`. Do not hand-edit generated runtime art.

## Storefront animation

Create one shared Ilyra 2 showcase animation used by both the Shop/storefront preview and the Home
screen selected-character preview. Both screens must call the same scene/component and animation
definition so their scale, offsets, timing and visual behavior cannot drift apart.

Keep every source frame on its original untrimmed `600 x 724` canvas and use the same centered
pivot. Suggested sequence:

1. `storefront_welcome` — hold about `0.65 s`
2. `storefront_blink` — hold about `0.16 s`
3. `storefront_flourish` — hold about `0.32 s`
4. `storefront_settle` — hold about `0.75 s`
5. Return softly through flourish/blink or cross back to welcome without a visible position jump.

The normal ambient shop/Home loop should be calm. Play the full flourish when Ilyra 2 becomes the
selected form, when her shop card is focused, or after a longer randomized idle interval. Use only
the subtle welcome/blink/settle behavior between flourishes. Do not make the preview constantly
thrash or flash.

The Home screen must show this exact same Ilyra 2 presentation animation whenever Ilyra 2 is the
currently selected form. Other forms must keep their existing behavior.

## Gameplay effects only

Keep the gameplay character animation exactly as it is now. Add a restrained Ilyra 2-only aura
using the detached sparkle and glow sprites:

- Two to four small cyan stars/motes should drift slowly around her on different elliptical paths.
- Their phases, radius and speed should differ slightly so they do not look mechanically locked.
- The stars should ease and lag during movement, briefly trail behind during dash, then settle.
- Pulse `chest_gem_glow` gently during idle and more strongly during aim/charge.
- Show `dash_slash` only as a short additive dash accent aligned with travel; it must not alter the
  dash animation, damage, collision, duration or movement.
- Keep the effects behind or beside the body so the face, four arms, fans and wall-contact pose stay
  readable. Never cover the hands or fan grips.
- Reuse/extend the existing character-aura/effect infrastructure if present instead of creating a
  second competing system.
- Effects are visual only: no physics, no collision shapes, no gameplay state and no save data.
- Limit the active effect count and avoid per-frame allocations; this must remain inexpensive on
  Android phones.
- Reduced-motion mode must freeze orbital movement, suppress the dash slash, and leave at most a
  faint static chest glow.

## Verification

- Verify Ilyra 2 in Shop and Home and confirm both use the same animation, pivot and apparent scale.
- Verify focus/selection starts the flourish cleanly and idle playback remains calm.
- Verify gameplay idle, aim, dash and all four wall contacts; the underlying animation must remain
  unchanged and the new effects must not obscure the silhouette.
- Verify another playable form is unaffected.
- Add/update focused automated tests for shared Home/Shop presentation selection, reduced motion
  and Ilyra 2-only gameplay VFX.
- Run the project validation and relevant tests, then perform the normal visual QA capture on the
  phone aspect ratios. If the connected phone is available, install and launch the verified build.
- Follow the project documentation triggers and add a DEVLOG entry. Do not commit or push.

Before implementation, visually inspect the supplied sprites and report any asset that cannot be
used cleanly. Do not silently replace them with procedural placeholder shapes.
