# System: Playable characters

> **Status:** ✅ five rigs — Veyra, Rook and Morrow (2026-09-17), Ilyra and Bram (2026-09-18) ·
> owner approval, prices and device pass pending ·
> **Last updated:** 2026-09-18 · **GDD section:** §6, §9, §11, §14 #31 ·
> **ADR:** [0015](../decisions/0015-animated-playable-characters.md) ·
> **Adding a character?** [guides/character_rig_recipe.md](../guides/character_rig_recipe.md) — the
> step-by-step recipe (layer extraction, bones and skinning, springs, states, QA, known mistakes)

## Purpose

Animated, gameplay-neutral characters on the one Wisp controller. Veyra, the Last Wisp; Rook, the
Bonewing; Morrow, the Runebound; Ilyra, the Astral Dancer; and Bram, the Rift Knight join the six
single-image Wisp forms in the Shop's CHARACTERS tab. Collision, health, dash, scoring, controls and
camera never change with the character — the tier on a card is a label, not a stat.

## Files

| Path | Role |
|---|---|
| `res://scenes/player/visuals/playable_character_visual.gd` / `.tscn` | Base: state vocabulary, runtime AnimationPlayer library, AnimationTree state machine, heading spring, particle rules. The scene is the single-image rig (`%FormImage`) Shop cards use for the six forms |
| `res://scenes/player/visuals/chain_spring.gd` | `ChainSpring`: follow-through for tails, scarves, flaps and feet |
| `res://scenes/player/visuals/ribbon_chain.gd` | `RibbonChain` (`@tool`): skinned Polygon2D ribbon on its own Bone2D chain |
| `res://scenes/player/visuals/playable_character_preview.gd` | `PlayableCharacterPreview`: Control host for Home and the Shop |
| `res://scenes/player/visuals/veyra_visual.*` · `rook_visual.*` · `morrow_visual.*` · `ilyra_visual.*` · `bram_visual.*` | One rig per character |
| `res://assets/art/characters/playable/<id>/` | Runtime layers (generated, never hand-edit; [ASSETS.md](../ASSETS.md)) |
| `res://data/forms/veyra.tres` · `rook.tres` · `morrow.tres` · `ilyra.tres` · `bram.tres` | Identity, portrait, price 0, tint, `visual_scene`, `tier` |
| `tools/art/make_rig_source.py` | Transparent rig sources from an approved reference sheet (Bram is keyed off near-black) |
| `tools/art/extract_playable_characters.py` | Two intake paths: `CHARACTERS` cuts fixed cells out of a sheet (v1/v2), and `PART_PACKS` ingests a per-file pack verbatim — its PNGs are copied byte for byte because the manifest's pivots are in each file's own pixel space |
| `tools/art/build_character_rig.py` | Part-pack manifest → the rig scene: parent-relative transforms, pivot-to-offset inversion, `z_index` from draw order, mirrored sub-trees, and `design_size` / `preview_center` measured from the assembled silhouette |
| `tools/godot/render_character_{lineup,motion,select_showcase,home_showcase,gameplay_showcase}.*` · `tools/art/motion_contact_sheet.py` | Visual QA ([How to test](#how-to-test)) |
| `tools/godot/test_playable_character_visual.gd` | Rig contract, states, smoothness, menus, GameWorld |

## Scene / node structure

```text
<Name>Visual (PlayableCharacterVisual subclass)
├── %MotionRoot            ← body motion from the AnimationTree
│   ├── %TrailParticles / %DashParticles (optional GPUParticles2D, world space)
│   └── %Body              ← parts, drawn in tree order
│       ├── RibbonChain…   ← Skeleton (Bone2D chain) + Mesh (skinned Polygon2D)
│       └── pivots (Node2D) → Sprite2D layers
├── %AnimationPlayer
└── %AnimationTree
```

The rig is authored facing up: -Y forward, +Y behind (tails, trails), X sideways. It holds no
physics nodes; `WispPlayer/%CollisionShape` is the only footprint.

## Public API

| Member | Kind | Description |
|---|---|---|
| `sync_controller(visual_height, alpha, state, direction, speed)` | method | Called by `WispPlayer` every frame: uniform size, fade, gameplay state, dash/drift/aim direction, 0..1 speed. |
| `request_state(state)` | method | Loops play at once; one-shots fire once per request; `INTERRUPTS` (death, hit, spawn, dash end, dash start) cut in. |
| `play_attack()` / `play_character_selected()` / `play_character_unlocked()` | method | Dash-kill accent (repeat kills extend it) and menu flourishes. |
| `set_preview_mode(on)` / `set_reduced_motion(on)` | method | Menu mode (upright, no trails) / Reduced Motion (poses and heading only). |
| `get_animation_states()` · `get_current_visual_state()` · `get_state_length(state)` · `get_speed()` · `get_layer_bounds()` · `get_design_size()` | method | Tests, fixtures, rigs. |
| `visual_state_changed(state)` | signal | A state started. |
| `design_size` · `preview_center` · `squash_amount` · `bounce_amount` · heading / settle springs · `aim_lean` · `move_lean` · `trail_ratio_*` · `portrait_texture` | export | Per-rig tuning. |
| `_update_secondary_motion(delta)` · `_on_state_started(state)` · `_apply_reduced_pose()` | virtual | What each rig overrides. |
| `PlayableCharacterPreview.set_form(form, animate_portrait)` · `play_selected()` · `play_unlocked()` · `get_visual()` | method | Menu host; `animate_portrait` puts a single-image form on the base rig. |
| `ChainSpring.setup(joints, phase)` · `step(delta, time)` · `impulse(rad_per_s)` · `reset()` | method | Public fields tune stiffness, damping, lag, sway, `straighten`, `bias`, `max_offset`, `max_lag_rate`. |
| `RibbonChain.texture` · `spine` · `cell_size` · `phase_offset` · `spring` · `step()` · `get_bones()` · `get_mesh()` | export / method | Skinned ribbon. |
| `WispPlayer.set_cosmetic_form(texture, tint, visual_scene)` · `play_attack_visual()` · `get_character_visual()` | method | Controller side ([player_dash.md](player_dash.md)). |

## Animation vocabulary

| State | Gameplay source | Body motion (shared, local axes) |
|---|---|---|
| `idle_hover` | resting at an edge | 1.8 s bob and breathe loop |
| `move_fly` | Frozen Choir edge drift | 0.7 s loop, lean into the slide |
| `aim_charge` | finger held (the arrow is up) | 0.52 s pre-attack coil: the body winds back along its own axis, shivers and leans toward the aim |
| `dash_start` | windup | 0.12 s deep coil, then the blade profile; heading turns to the dash |
| `dash_loop` | dashing | 0.32 s dive: long and thin along the travel axis, leading edge first |
| `dash_end` | wall or crystal impact | 0.17 s compress over the feet, push back up to a stand |
| `attack` | each dash kill (`GameWorld`) | 0.24 s punch, wobble and flash |
| `hit_reaction` | hurt | 0.32 s shake, flinch and pink flash |
| `death` | dead | 0.5 s flare and fold, heading held (inside the 0.55 s death fade) |
| `revive_spawn` | spawning | 0.58 s pop-in from a squash |
| `victory` | boss-victory pulse | 0.9 s bounce loop |
| `character_selected` / `character_unlocked` | card focus or equip / purchase | 0.62 s hop / 0.9 s pop, twirl and flash |

Cross-fades are 0.075 s, 0.14 s into calm loops. Heading: dash spring 6.5 Hz (ζ 0.72); standing
spring 4.2 Hz (ζ 0.86).

**Standing on walls.** A resting character's up axis is the wall's inward normal
(`get_standing_heading()`), so it stands on the floor, sideways on a side wall and hangs from the
ceiling; aim and drift lean away from that, not from screen-up. A dash dives head-first and then
turns its feet toward the wall over the last `WispPlayer.LANDING_WINDOW` (0.16 s) of the flight
(`landing` 0→1), so it arrives feet-first; each rig also braces with it (fins and wings swing
forward, hands drop, tails gather).

| Character | Parts | Secondary motion | Particles |
|---|---|---|---|
| Veyra (`design_size` 580) | flame body, additive core, eyes, 2 fins, 2 halo halves, 3 skinned tails | core pulse, blinks, fins knife back in a dive and flare forward to land, flare wide while aiming, halo floats and spreads, tails trail, straighten and whip | 32 cyan-violet soul sparks |
| Rook (640, squash 1.0) | shadow body, skull, 2 wing frames on 2 membranes, 2 feet, 3 tail segments, crescent fin | strong beats at rest, wings cocked high while aiming, folded into a stoop in a dash, flared with the feet forward to land (he roosts under a ceiling), snap on a kill, flinch; body lifts on downstrokes; springy tail | 12 magenta wing dust + 6 bone-white dash streaks |
| Morrow (520, squash 0.55, bounce 0.7, softer heading) | cloak, hood, mask, front flap, 2 hands, 3 runes, 2 skinned scarves | cloak breathing, mask tilt, hands on independent orbits (raised with the runes spun up while aiming, back in flight, forward on a kill and to meet the wall, raised to cheer), runes on a tilted ring that never crosses the mask, flap and scarves trail | 10 turquoise rune fragments + 6 dark cloth wisps |
| **Ilyra** (979, squash 0.8) — Mythic, 51 parts from the v3 pack, seven of them skinned limbs | 5 registered head paintings, hair and 2 skinned braids, chest + hips, heart core and glow, 4 three-joint arms with 3 hand poses, 2 fans of 5 ribs and a membrane, 6 skirt panels, 4 skinned sashes, 3 crown pieces, 2 three-piece legs, 3 effect sprites | every arm is shoulder → elbow → wrist and the three ease at falling rates, so a gesture starts at the shoulder and arrives at the hand two frames later; hips counter-rotate against the chest; each fan opens and shuts by rotating five ribs about one rivet; knees and ankles fold on arrival and her free hands plant on the surface she lands against; a dash *is* an attack — the fans stay out as blades with an arc trailing each one, rather than folding shut; a kill is led by her free hands with the fans crossing a beat behind; she blinks on her own and swaps to focused, joyful or pained faces per state | 18 star motes + 10 dash streaks + an 8-petal kill burst |
| **Bram** (400, squash 0.7, bounce 0.8) — Legendary, ~14 groups | helmet, visor, torso, chest core, 2 two-part arms, shield, blade, blade arc, 2 legs, 2 cape panels | a slow weight shift and a breathing visor and reactor carry the idle; aiming raises the shield and winds the blade back; the dive turns the shield onto the travel axis with the sword arm folded in behind it; a kill is one cut with a single narrow arc; landing compresses and splays both boots; a hit braces behind the shield; selected is a sword salute and unlocked a shield plant with a short flare | 10 soul motes + 6 dash streaks |

## Rules & behaviour

- `FormData.visual_scene` is optional; the six Wisp forms keep the single-image path in a run. The
  HUD portrait is `FormData.texture` for every character.
- `FormData.tier` (`STANDARD` / `LEGENDARY` / `MYTHIC`) is presentation only: the Shop prints it on
  the focused card above the description (`%TierLabel`, `CaptionLabel` variation, amber for Legendary
  and `RIFT_MAGENTA` for Mythic) and nothing else reads it. Everything that shipped before 2026-09-18
  is `STANDARD` and shows no badge.
- Characters use the existing `owned_forms` / `equipped_form` save fields; no schema change.
- Only the uniform base size is mirrored from the controller; rigs play their own squash, breathing
  and death, so nothing is doubled.
- `GameWorld` calls `play_attack_visual()` only for dash-event kills (`damage_event_id > 0`).
- One live rig in a run; the Shop builds one preview per CHARACTERS card (nine) and only for that tab.
- Animation libraries and the state machine are built once per motion-strength pair and shared by
  every rig (they hold no playback state), and `FormCatalog` keeps loaded characters for the session
  (~18 MB of layers and portraits) so a tab switch never reloads art.
- A hidden rig stops completely (`set_process(false)`, tree inactive, particles off): the Shop keeps
  the character cards in the tree while another tab is shown. Reduced Motion reaches the equipped rig
  mid-run too, because `WispPlayer.set_reduced_motion()` forwards the pause menu's change.
- A dash kill on the fatal frame cannot cut the death animation short.
- Menus: a card that comes into focus or gets equipped plays `character_selected`; a purchase plays
  `character_unlocked` (the Shop compares the old and new save snapshot). Reduced Motion stills menu
  previews too.

## How to test

- `tools/run_tests.sh playable_character_visual` — all states, no collision, ≤ 40 particles, ribbon
  weights, silhouette vs `design_size`, the real controller through spawn/dash/kill/redirect/landing/
  hit/victory/death with a per-frame snap check, Reduced Motion, Home, Shop flourishes, GameWorld.
- `tools/run_tests.sh form_catalog` — eleven characters, prices, rigs, tiers, save ids.
- Rebuilding a part-pack rig: `python3 tools/art/extract_playable_characters.py <id>` then
  `python3 tools/art/build_character_rig.py <id>`. The scene is generated — hand edits to
  `<id>_visual.tscn` are lost on the next run; per-character motion lives in `<id>_visual.gd`.
- `tools/screenshot.sh res://tools/godot/render_character_lineup.tscn 90 540x960` — reference vs rig
  (`WISP_LINEUP_POSE=attack|hit|aim|victory`); prints `[Lineup]` bounds for sizing.
- Motion frames: the command in `render_character_motion.gd`, then
  `python3 tools/art/motion_contact_sheet.py <id>` → `logs/motion/<id>_*.png`.
- `WISP_CHARACTER=<id> tools/screenshot.sh res://tools/godot/render_character_{select,home,gameplay}_showcase.tscn`.
- Slow-motion dash clip (launch, kill accent, mid-dash turn, dive, landing) with a trailing camera and
  a live state caption: same command as the motion frames plus `WISP_MOTION_CLIP=1
  WISP_MOTION_SCALE=0.25 --quit-after 860`, then encode the frames with ffmpeg at 60 fps.
- Cost: `"$GODOT" --headless --path . --script res://tools/godot/bench_character_previews.gd` —
  nine previews build in ~133 ms cold and ~8 ms warm, and animating them costs under 0.1 ms/frame
  (measured 2026-09-17 on the owner's Mac).

## Known issues / TODO

- Owner approval of the look and motion, then prices (all five cost 0 RP for the review).
- Ilyra's torso, four arms and two legs are skinned meshes, not cutouts: cut segments opened a seam
  at every joint swung past the angle their painted caps were drawn for. Anything with an elbow,
  knee or waist should be skinned; see [the recipe](../guides/character_rig_recipe.md) §2.
- Her braids, sashes and skirt panels are still passive cloth on `ChainSpring`s, and a couple of the
  six panels carry a hair-thin sliver of the neighbour they were painted touching (invisible at
  gameplay scale).
- Bram's visor and reactor are drawn a second time over their own painted pixels and brightened,
  rather than as additive shapes, so they stay correct at rest.
- Not yet seen on a phone: readability at gameplay size and particle cost. Motion pacing is handled
  — `FramePacing.match_display()` steps the simulation at the screen's refresh rate (see
  [game_feel.md](game_feel.md)).
- Layers have no mipmaps (like the forms), so they can shimmer when drawn small; changing that is an
  import-setting decision.
- Generated art: licence to confirm before selling (GDD §14 #1, #21). Rook's layers came out at
  inconsistent scales; the rig scales them to the reference.

## Change history

| Date | Change |
|---|---|
| 2026-09-18 | Ilyra's limbs moved to **skinned meshes**: torso, four arms and two legs are each one painting over a three-bone chain, so elbows, knees and the waist bend the paint instead of rotating cutouts over each other and the joint seams are gone. Hands, boots, head, skirt and sashes re-parent onto the bone that carries them |
| 2026-09-18 | Ilyra rebuilt on the v3 part pack (separated parts + a pivot manifest): real shoulder/elbow/wrist chains on all four arms, a twisting waist, fans that fold rib by rib, bending knees, wall-grip landings, hands-first kills with a petal burst, and five registered faces with self-timed blinks. `build_character_rig.py` generates the scene from the manifest |
| 2026-09-18 | Ilyra (Mythic) and Bram (Legendary) rigs; `FormData.tier` and the Shop tier badge; `tools/art/make_rig_source.py`; versioned source packs and mask polygons in the extractor, whose component labelling now uses scipy (v1 output byte-identical); the lineup fixture scales to the roster |
| 2026-09-18 | Dive-and-slice dash profile, feet-first wall landings (`surface_normal`, `landing`, `get_standing_heading()`) and a pre-attack coil while the aim arrow is up; the clip fixture holds a real aim before its first dash |
| 2026-09-17 | Review fixes: Reduced Motion reaches the rig mid-run, a kill cannot interrupt death, hidden rigs stop processing, chain lag is a rate (same whip at 30/60/120 fps), no per-frame allocations |
| 2026-09-17 | Rook and Morrow rigs; Veyra rebuilt with skinned tails and split halo; base rewritten (heading spring, travel-axis squash, interrupts, per-character strengths, single-image rig); animated CHARACTERS cards with selected/unlock flourishes; QA fixtures, motion sheets and tests (Claude Code) |
| 2026-09-17 | Veyra prototype: layered rig, shared state machine, previews, save integration, particles, test (Codex) |
