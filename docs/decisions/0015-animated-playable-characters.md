# ADR-0015: Animated playable characters are presentation-only rigs on the Wisp controller

> **Status:** Accepted · **Date:** 2026-09-17 · **Deciders:** owner (three playable characters with
> smooth animation, "they are not just wisps but characters") + Codex (Veyra prototype) + Claude Code
> (completion) · **Relates to:** [ADR-0005](0005-visual-redesign-v1.md) (generated art pipeline),
> [ADR-0006](0006-inset-playfield-and-larger-sprites.md) (sprite and hitbox scale),
> [ADR-0013](0013-rift-story-levels-endless-mode-and-rift-points.md) (Rift Points cosmetics)

## Context
- The owner asked for three playable characters from concept sheets — Veyra, the Last Wisp; Rook, the
  Bonewing; Morrow, the Runebound — with layered parts, per-character motion, particle trails, a full
  state vocabulary (idle, move, dash start/loop/end, attack, hit, death, revive, selected, unlocked),
  no snapping between states and 60 fps playback. The brief warned that parts of it might not match
  the codebase.
- `WispPlayer` owns movement, the dash (which is the attack), damage, collision and presentation. Six
  existing cosmetic forms are single 512 px portraits that mirror the Wisp's AnimatedSprite2D.
- GDD §6 and §9: cosmetics never change scale, anchor, hitbox, timing or rules.
- The concept sheets are poses, not animation-ready art. Codex generated one transparent layer sheet
  per character from them (OpenAI image tool) before the session ran out of quota.

## Options considered
1. **Frame-by-frame sprite sheets per state** — would need dozens of generated frames per character
   that never match each other; heavy; stiff blends. Rejected.
2. **A new controller or physics body per character** — duplicates the tuned dash and invites
   per-character collision drift. Rejected.
3. **A third-party skeletal addon (Spine, DragonBones)** — new dependency and export plugin for three
   characters. Rejected.
4. **A presentation-only rig scene per character, driven by the existing controller** — Godot-native
   AnimationTree plus code-driven secondary motion, cutout sprites and skinned Polygon2D ribbons.
   **Chosen.**

## Decision
- `FormData.visual_scene` (optional) names a scene whose root extends `PlayableCharacterVisual`. Forms
  without one keep the single-image path in gameplay. The catalog, save ids (`owned_forms`,
  `equipped_form`) and Shop flow are shared; there is no character save, stat or controller.
- `WispPlayer` instances the rig under `%CharacterVisualMount` and calls
  `sync_controller(visual_height, alpha, state, direction, speed)` every frame. Only the uniform base
  size is mirrored; `%CollisionShape` stays the only footprint, and the rig holds no physics nodes.
- `PlayableCharacterVisual` builds one AnimationPlayer library for the 13 states at runtime (squash and
  stretch on the travel axis, recoils, flourishes; strengths per character) and blends it with an
  AnimationTree state machine (0.075 s cross-fades, 0.14 s into calm loops). One-shots never restart
  on a repeated request; impacts, hits, launches, spawns and death interrupt. Heading is a damped
  spring: full turn toward the dash, a lean while aiming or drifting, upright at rest (held through
  the landing squash and the death), so turns ease and overshoot instead of snapping.
- Secondary motion is code: `ChainSpring` (spring joints with a rate-capped lag and a travelling
  sway) drives tails, scarves, flaps and feet; `RibbonChain` builds a skinned Polygon2D on its own
  Bone2D chain along a spine printed by `tools/art/extract_playable_characters.py`, so ribbons bend
  without gaps. Each rig adds restrained GPUParticles2D trails (≤ 40 particles in total).
- Menus use `PlayableCharacterPreview`. The Shop animates every character card: rigged characters play
  their rig, single-image forms idle on the shared base scene; focus or equip plays
  `character_selected`, a purchase `character_unlocked`. Home shows a rigged character live.
- Runtime layers come only from `extract_playable_characters.py` (fixed cells, speckle cleanup); the
  complete sheets never ship.

## Consequences
- New characters need a layer sheet, a rig scene and a `FormData`; no gameplay code changes. The
  lineup, motion and showcase fixtures plus `test_playable_character_visual` check size, states and
  per-frame smoothness.
- Rig layers are drawn at about a fifth of their size in a run and have no mipmaps (like the forms).
  Crisper downscaling would need an import-setting change, which is an owner decision.
- A character stands on whatever wall it rests against (feet on the floor, sideways on a side wall,
  hanging from the ceiling) and turns feet-first into the wall over the last 0.16 s of a dash, so a
  dive always lands on its feet. Anything that reads the rig's rotation must expect that.
- Prices, and whether characters stay cosmetic-only, are owner decisions (GDD §14 #31); the art's
  licence must be confirmed before characters are sold (GDD §14 #1, #21).
- The physics loop used to run at a fixed 60 Hz, so on a 90 or 120 Hz phone each position was drawn
  more than once and a dash read as judder. Since 2026-09-18 `FramePacing.match_display()` steps the
  simulation at the screen's own rate (clamped 60-120 Hz) at boot, which costs nothing on a 60 Hz
  device. Godot's physics interpolation is the cheaper textbook fix, but every node animated per
  frame in `_process` must opt out of it — the rigs, both ambiences, the tutorial hand, the VFX pool
  and most screens — and with it enabled the rig smoothness contract failed intermittently. Revisit
  it only if that per-frame animation moves onto the physics tick.

## Addendum 2026-09-18 — collectible tiers and versioned source packs

Ilyra (Mythic) and Bram (Legendary) join the roster, taking the catalog to eleven characters. Two
small extensions follow from them, and neither changes the decision above:

- **Tiers are a label.** `FormData.tier` is `STANDARD` / `LEGENDARY` / `MYTHIC`, defaulting to
  `STANDARD` for everything that shipped before. The Shop prints it on the focused card above the
  description; no other system reads it. Characters remain purely cosmetic — a Mythic rig buys more
  coordinated motion, never a different collision footprint, dash, damage or score.
- **Source packs are versioned.** `SOURCE_SHEETS` in the extractor maps a character to its rig
  source, so the v1 pack keeps producing byte-identical layers while later packs live beside it.
  Approval sheets are opaque presentation art, so `tools/art/make_rig_source.py` derives the
  transparent sheet the extractor needs, and `MASKS` cuts a part out of a pose when the sheet never
  isolates it (Ilyra's torso). The component labelling is `scipy.ndimage.label`, which replaced a
  hand-rolled union-find that degenerated to minutes on a dense silhouette; v1 output is unchanged.
