# System: Playable characters

> **Status:** ✅ one rig — Morrow (2026-09-17) · ✅ **Rook** rebuilt on AutoSprite and his rig removed (2026-09-27) · **Void, Eclipse, Veyra and Noxen removed**
> (owner, 2026-09-25; Patchvile is the default) ·
> ✅ **Shade** is a whole-frame character on `WholeFrameCharacterVisual` · ✅ **Shade rebuilt on AutoSprite** (2026-09-25), the second after
> Patchvile ·
> ✅ **the drawn set is five animations** (owner, 2026-09-20) — the dash, three wall loops and one
> storefront idle; see [Animation vocabulary](#animation-vocabulary) ·
> ✅ **Mothmere** (2026-09-25) and ✅ **Scarlet** (2026-09-26) on AutoSprite · **Ilyra removed**
> (owner, 2026-09-26; Scarlet replaced her, GDD §14 #52) · **no tiers** (GDD §14 #53) ·
> **new characters are whole-frame sprites, not rigs** (GDD §14 #34) ·
> the bone-rigged Ilyra and Bram were retired 2026-09-20 ·
> ✅ **Patchvile**, all AutoSprite, is **owner-approved** — the worked example for every new character ·
> owner approval (the others), prices and device pass pending ·
> **Last updated:** 2026-09-27 · **GDD section:** §6, §9, §11, §14 #31–34, #51–56 ·
> **ADR:** [0015](../decisions/0015-animated-playable-characters.md) ·
> **Adding a character?** [guides/character_creation.md](../guides/character_creation.md)
> — the AutoSprite recipe (Patchvile is the worked example): the states, the first frames, the
> **roster size** (every character has his pixel count, 194 px standing in the 256 px frame, packed
> with `roster_scale`; the same size everywhere, GDD §14 #54), packing, effects and checks. New characters take this path.
> **Maintaining a rigged one?** [guides/character_rig_recipe.md](../guides/character_rig_recipe.md)
> — layer extraction, bones and skinning, springs, states, QA, known mistakes

## Purpose

Animated, gameplay-neutral characters on the one Wisp controller. Morrow, the Runebound, is a bone
rig. **Patchvile** (the default character), **Shade**, **Mothmere**, **Scarlet** and **Rook**, the
Bonewing (a rig until 2026-09-27), are whole-frame characters on `WholeFrameCharacterVisual` — the
pattern every new one follows. Void, Eclipse, Veyra and Noxen were removed on 2026-09-25 and Ilyra on 2026-09-26 (owner).
Collision, health, dash, scoring, controls and camera never change with the character, and no
character has a tier (owner, 2026-09-26).

## Files

| Path | Role |
|---|---|
| `res://scenes/player/visuals/playable_character_visual.gd` / `.tscn` | Base: state vocabulary, runtime AnimationPlayer library, AnimationTree state machine, heading spring, particle rules. The scene is the single-image rig (`%FormImage`) Shop cards use for the Wisp forms |
| `res://scenes/player/visuals/chain_spring.gd` | `ChainSpring`: follow-through for tails, scarves, flaps and feet |
| `res://scenes/player/visuals/character_aura.gd` | `CharacterAura`: lights that orbit and drift around a character. Optional `%Aura` node beside `%MotionRoot`; the base steps it and stills it for Reduced Motion |
| `res://scenes/player/visuals/ribbon_chain.gd` | `RibbonChain` (`@tool`): skinned Polygon2D ribbon on its own Bone2D chain |
| `res://scenes/player/visuals/playable_character_preview.gd` | `PlayableCharacterPreview`: Control host for Home and the Shop |
| `res://scenes/player/visuals/morrow_visual.*` | Morrow's bone rig |
| `res://scenes/player/visuals/rook_visual.*` | Rook (2026-09-27), rebuilt on the AutoSprite recipe; his bone rig was removed (owner, GDD §14 #56). All AutoSprite (`concept_art/rook_autosprite_v1/`) — a 23-frame storefront, a 17-frame floor, his own 19-frame ceiling, a 20-frame right wall (mirrored for the left) and an 8-frame one-shot dash (cells 03, 05, 07, 08, 09, 11, 14, 17: flight, push, dive, tail raised, the tail swing, the swing held to the wall), drawn flying left and turned a quarter so it flies up, with `dash_head_up`. Contact frame 4 (the tail swing). He keeps his outline (GDD §14 #55). His slicer cleans every frame (the white AutoSprite's background remover left in his gaps). Packed at Patchvile's scale (ROSTER CHECK 202 px, +4 %); his walls do not fit a 256 px cell at that scale (the floor spans 299 cell px, the right wall's tail swing 321), so his run sheet has 336 px cells like the dash, `design_size` is 336 and `art_scale` 1.55859375 (1.1875 × 336/256), which draws him at everyone's size; `menu_art_scale` 1.25. His rig's dash look is kept (owner): `DashEffectData` `DUST_WAKE` in violet, bone-white streaks on `%DashParticles`, magenta dust on `%TrailParticles`, a ring of 7 dust motes on `%Aura`, their sizes carried over from the rig's 640 design (× 0.525); no attack glow. `menu_offset` (2.7, 62.5): his tail blade hangs below his feet, so without it he floated about 80 px above Home's platform; now his feet are on its centre (GDD §14 #57) |
| `res://scenes/player/visuals/whole_frame_character_visual.gd` | `WholeFrameCharacterVisual`: everything a whole-frame character does — the two on-demand frame sets, the screen-space wall animations and the mirrored right wall, the menu rest, Reduced Motion, and `_target_animation()`, which resolves the whole thirteen-state vocabulary onto the five animations a drawn character has. A character subclasses it only to carry a `class_name`; the frame-set paths and `menu_idle_animation` are set per scene. `menu_offset` (design units) moves the storefront on Home and the Shop card, never in a run, so the character stands centred on Home's platform (owner, 2026-09-27, GDD §14 #57) |
| `res://scenes/player/visuals/verdant_shade_visual.*` | Shade, rebuilt on the AutoSprite recipe (2026-09-25), the second character after Patchvile: all AutoSprite (`concept_art/verdant_shade_autosprite_v1/`) — a 24-frame storefront (the menu video's breathing float), the 23-frame floor, the 21-frame right wall (the left wall is it mirrored), AutoSprite's own 23-frame ceiling (the owner generated it, so it is not the floor flipped) and a one-shot 8-frame dash attack (a flame burst, contact frame 4) drawn face down and turned 180° by the slicer so the face leads the flight (owner, 2026-09-25; no `dash_head_up`). Packed at Patchvile's scale (`roster_scale`) with his sizes (`design_size` 256, `art_scale` 1.1875, `menu_art_scale` 1.25). Its menus play the storefront, not the old video. Effects: a pale green attack glow (no shader slash: the drawn burst is the attack), its own loose leaves as dash particles (`verdant_shade_leaves.png`), green trail motes, a green dust landing, no shared cyan trails. It was the first character built to the [whole-frame contract](../guides/character_sprite_frames.md) (2026-09-20, Codex frames) |
| `res://scenes/player/visuals/mothmere_visual.*` | Mothmere (2026-09-25), on the AutoSprite recipe after Patchvile and Shade: all AutoSprite (`concept_art/mothmere_autosprite_v1/`) — a 22-frame storefront (breathing, and a strike of the staff on the floor that throws dust), an 18-frame floor (flipped for the ceiling), a 23-frame right wall (mirrored for the left) and an 8-frame one-shot dash (cells 07-09, 11-13, 15, 19: wind-up, the swing drawing a red reap, the end of the swing held to the wall), drawn flying left and turned a quarter so it flies up, with `dash_head_up`. Contact frame 4 (the full reap). He keeps the outline his source images carry (GDD §14 #49). Red attack glow, no shader slash (his frames draw the reap), red dot trail on `%DashParticles` and red additive motes on `%TrailParticles`; `DashEffectData` `RIBBON` in red, shared cyan trails off, dust landing |
| `res://scenes/player/visuals/scarlet_visual.*` | Scarlet (2026-09-26), on the AutoSprite recipe, replacing Ilyra: all AutoSprite (`concept_art/scarlet_autosprite_v1/`) — a 25-frame storefront (breathing, and one wave of her fan), a 24-frame floor (flipped for the ceiling), a 25-frame right wall (mirrored for the left) and an 8-frame one-shot dash (cells 07, 09-12, 15, 19, 22: flight, wind-up, the swing drawing an airy blue reap, the reap fading, the end of the swing held to the wall), drawn flying left and turned a quarter so it flies up, with `dash_head_up`. Contact frame 4 (the full reap). Her slicer cleans every frame (the fan's rib gaps AutoSprite filled with grey or white, the reap's black tips). Packed at Patchvile's scale; her sheets stand 166 px (`standing` 166 in her pack), so her scene draws her 1.16× larger (`art_scale` 1.38, `menu_art_scale` 1.45) and she is the same size as everyone (GDD §14 #54). Pale blue attack glow, no shader slash (her frames draw the reap); `%DashParticles` throw her own reap crescents (`scarlet_reap_arcs.png`, additive, 12) and `%TrailParticles` trail her crown diamond (`scarlet_diamond.png`, additive, 20); `DashEffectData` `TWIN_ARC` in pale blue, shared cyan trails on, splash landing — Ilyra's dash look, larger (owner) |
| `res://scenes/player/visuals/patchvile_visual.*` | Patchvile, **owner-approved**: the worked example of [character_creation.md](../guides/character_creation.md). All AutoSprite (`concept_art/patchvile_autosprite_v1/`): a 25-frame storefront (a dagger toss), the 24-frame floor and right wall, and the one-shot dash attack (8 frames at 28 fps). The packer's `derive` flips the floor for the ceiling (head down, owner) and mirrors the right wall for the left, which the visual mirrors back on the right wall, so the right wall shows the art as generated. His run sheet packs at 256 px cells with `design_size` 256 and the dash at 336 px cells at the same pixel scale (`fit_match`) — `WholeFrameCharacterVisual` draws menu frames at `design_size` / 448, so any run cell keeps the Shop card the same size. Packed with the extractor's `fit` option; every character after him packs at his scale instead (`roster_scale`). The earlier Codex frames (`concept_art/patchvile_full_frames_v1/`) were rejected and are not used |
| `res://scenes/player/visuals/character_menu_video.gd` | `CharacterMenuVideo`: the one menu-video player every visual uses — packed-alpha shader, placement from `MenuVideoData`, pause while hidden, restart after its screen is re-attached |
| `res://scripts/resources/menu_video_data.gd` · `res://data/characters/verdant_shade_menu_video.tres` · `res://assets/shaders/packed_alpha_video.gdshader` | `MenuVideoData`: a menu performance as a packed-alpha Theora video (generated by `tools/art/extract_menu_video.py`), and the shader that puts colour and matte back together ([ADR-0016](../decisions/0016-menu-videos-for-character-storefronts.md)). No character plays one since 2026-09-26: Ilyra's went with her, and Shade's clip is kept but unused since 2026-09-25 |
| `res://scripts/resources/character_pose_sheet.gd` · `res://data/characters/<id>_frames.tres` | `CharacterPoseSheet`: generated with each whole-frame character's sheets; the tests read its per-frame silhouette drift. Its per-pose offset and scale were Ilyra's |
| `res://assets/art/characters/playable/<id>/` | Runtime layers (generated, never hand-edit; [ASSETS.md](../ASSETS.md)) |
| `res://data/forms/patchvile.tres` · `verdant_shade.tres` · `scarlet.tres` · `rook.tres` · `morrow.tres` · `mothmere.tres` | Identity, portrait, price 0, tint, `visual_scene`; Patchvile is the default (`FormCatalog.DEFAULT_FORM_ID`) |
| `tools/art/extract_playable_characters.py` | Two intake paths: `CHARACTERS` cuts fixed cells out of a sheet (v1/v2), and `PART_PACKS` ingests a per-file pack verbatim — its PNGs are copied byte for byte because the manifest's pivots are in each file's own pixel space |
| `tools/art/build_character_rig.py` | Part-pack manifest → the rig scene: parent-relative transforms, pivot-to-offset inversion, `z_index` from draw order, mirrored sub-trees, and `design_size` / `preview_center` measured from the assembled silhouette |
| `tools/godot/render_character_{lineup,motion,select_showcase,home_showcase,gameplay_showcase}.*` · `tools/art/motion_contact_sheet.py` | Visual QA ([How to test](#how-to-test)) |
| `tools/godot/test_playable_character_visual.gd` | Rig contract, states, smoothness, menus, GameWorld (every character) |
| `tools/godot/test_patchvile_visual.gd` | The one-shot dash: plays once, holds its last frame, restarts on a redirect; the attack look rises, trails and fades; none of it moves under Reduced Motion; every other whole-frame dash still loops |
| `res://assets/shaders/character_attack.gdshader` | Outline + flash of a whole-frame character's dash attack |
| `res://assets/shaders/character_slash.gdshader` | The procedural dagger slash crescent (no texture read) |
| `res://scenes/player/visuals/patchvile_visual.tscn` `%DashParticles` / `%TrailParticles` | His own dash particles: costume scraps (`patchvile_scraps.png`, four cells picked at random, normal blend, tumbling) thrown back while dashing, and soft cream motes (a radial `GradientTexture2D`, additive). 8 + 12 particles |
| `tools/godot/test_verdant_shade_visual.gd` · `render_whole_frame_states.*` (`WISP_CHARACTER=<id>`) | Shade's test also checks its one-shot dash and attack look, the storefront menu (no video) and a float allowance for the storefront. The whole-frame contract: the five animations at their promised counts/rates/loops, that none of the cut ones came back, state and wall mapping, the mirrored right wall, the menu rest, Reduced Motion and the frame-set split — plus a six-cell review board |
| `tools/godot/test_mothmere_visual.gd` | Mothmere's pack contract (dash 8, floor 18, ceiling 18, left wall 23, storefront 22), the one-shot dash and its attack look, `dash_head_up`, state and wall mapping, the storefront menu (no video), the frame-set split and Reduced Motion |
| `tools/godot/test_rook_visual.gd` | Rook's pack contract (dash 8, floor 17, ceiling 19, left wall 20, storefront 23), the one-shot dash, his rig's dash look kept (particles, aura, no attack glow), `dash_head_up`, state and wall mapping, the storefront menu (no video), the frame-set split and Reduced Motion; his side wall has its own drift budget (40 px) because his tail swing moves the silhouette 35.5 px |
| `tools/godot/test_scarlet_visual.gd` | Scarlet's pack contract (dash 8, floor 24, ceiling 24, left wall 25, storefront 25), the one-shot dash and its attack look, `dash_head_up`, state and wall mapping, the storefront menu (no video), the frame-set split and Reduced Motion; her storefront has its own drift budget (30 px) because her fan wave moves the silhouette 26.1 px |

## Scene / node structure

```text
<Name>Visual (PlayableCharacterVisual subclass)
├── %Aura (optional)       ← CharacterAura: drifting lights, outside the body motion
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
| `play_attack()` / `play_character_selected()` / `play_character_unlocked()` | method | Dash-kill accent (repeat kills extend it), and the pick and buy flourishes — which no menu plays since 2026-09-21 (owner: no bounce when a character is picked); they stay for the QA boards and the rig contract test. |
| `set_preview_mode(on)` / `set_reduced_motion(on)` | method | Menu mode (upright, no trails) / Reduced Motion (poses and heading only). |
| `get_animation_states()` · `get_current_visual_state()` · `get_state_length(state)` · `get_speed()` · `get_layer_bounds()` · `get_design_size()` | method | Tests, fixtures, rigs. |
| `visual_state_changed(state)` | signal | A state started. |
| `design_size` · `preview_center` · `squash_amount` · `bounce_amount` · heading / settle springs · `aim_lean` · `move_lean` · `trail_ratio_*` · `portrait_texture` | export | Per-rig tuning. |
| `_update_secondary_motion(delta)` · `_on_state_started(state)` · `_apply_reduced_pose()` | virtual | What each rig overrides. |
| `CharacterAura.step(delta, speed, direction)` · `set_still(on)` · `get_mote_count()` | method | The optional ring of lights; exports tune count, orbit, drift, scale, tint and how far a dash stretches it. |
| `PlayableCharacterPreview.set_form(form, animate_portrait)` · `set_reduced_motion(on)` · `get_visual()` | method | Menu host; `animate_portrait` puts a single-image form on the base rig. `play_selected()` / `play_unlocked()` were removed 2026-09-21 with the bounce. |
| `PlayableCharacterVisual.restart_dash()` | method | Called by `WispPlayer.redirect_dash()`: a redirect is a new dash but keeps the controller's dash state, so no state change tells the rig. The base does nothing; a whole-frame character with a one-shot dash restarts it. |
| `WholeFrameCharacterVisual.attack_glow` · `attack_contact_frame` · `afterimage_interval` / `_life` / `_alpha` · `get_attack_look()` · `get_visible_afterimages()` | export / method | The dash attack look (`character_attack.gdshader`): a glowing outline while dashing, a flash toward the glow on the contact frame and on a kill (capped at `FLASH_PEAK` 0.75), and additive afterimages from an 8-sprite pool drawn behind the body, pinned in world space. `attack_glow.a` 0 (the default) turns it all off; menus and Reduced Motion get no flash or afterimages. Reduced Motion holds `attack_contact_frame` of the dash. Patchvile: cream glow, contact frame 4, the slash (owner, 2026-09-23) |
| `WholeFrameCharacterVisual.slash_edge` · `slash_size` · `slash_forward` · `is_slash_showing()` | export / method | A dagger slash drawn by `character_slash.gdshader` on the contact frame: an additive crescent sweeping across the front of the flight in `attack_glow`, edged in `slash_edge` (alpha 0 = none), 0.08 s sweep, gone by 0.26 s. A fixed-transform square on the body (the rig smoothness contract samples every body node); the shader sweeps and mirrors. Menus and Reduced Motion show none. Patchvile: bone white edged in a muted cream (kept under the reserved-hue saturation) |
| `DashEffectData.shared_trails` | export | False turns off the Wisp's shared dash art for a character — the launch streak, the long streak on a long landing and the momentum streak glow — because that art is painted cyan and a tint cannot make it the character's colour; `GameWorld` and `WispPlayer.set_momentum_presentation(feel, tint, streak_glow)` honour it. Patchvile: false |
| `WholeFrameCharacterVisual.dash_head_up` | export | For a dash drawn from the side (flying up the frame, head to its right): mirrors it on a dash with a rightward component, so the turned drawing never flies upside down. Mirroring no longer restarts an animation. Patchvile: on |
| `WholeFrameCharacterVisual.art_scale` | export | Draws a whole-frame character's frames larger than its cell, in a run and on the menus alike (default 1). Cosmetic: the collision radius never changes. Patchvile uses 1.1875 in a run and `menu_art_scale` 1.25 on Home and the Shop (owner); the rig contract test measures his silhouette against `design_size × art_scale`. |
| `WholeFrameCharacterVisual.menu_video` · `is_menu_video_playing()` · `get_menu_video_player()` | export / method | The character's `MenuVideoData`, played on Home and the Shop card through `CharacterMenuVideo`; tests and fixtures read the player ([ADR-0016](../decisions/0016-menu-videos-for-character-storefronts.md)). |
| `CharacterMenuVideo.create(data)` · `dispose()` | static / method | Builds the shared menu-video player — packed-alpha shader, placement, loop, no taps; it pauses itself while hidden and restarts itself after its screen is re-attached. |
| `ChainSpring.setup(joints, phase)` · `step(delta, time)` · `impulse(rad_per_s)` · `reset()` | method | Public fields tune stiffness, damping, lag, sway, `straighten`, `bias`, `max_offset`, `max_lag_rate`. |
| `RibbonChain.texture` · `spine` · `cell_size` · `phase_offset` · `spring` · `step()` · `get_bones()` · `get_mesh()` | export / method | Skinned ribbon. |
| `WispPlayer.set_cosmetic_form(texture, tint, visual_scene)` · `play_attack_visual()` · `get_character_visual()` | method | Controller side ([player_dash.md](player_dash.md)). |

## Animation vocabulary

| State | Gameplay source | Body motion (shared, local axes) |
|---|---|---|
| `idle_hover` | resting at an edge | Anchored body; authored wall or idle sprite frames and rig secondary parts may move |
| `move_fly` | Frozen Choir edge drift | 0.7 s loop, lean into the slide |
| `aim_charge` | **nothing in a run requests it since 2026-09-19** — holding the arrow must not change the character at all, so `WispPlayer` keeps asking for `idle_hover` (or `move_fly` on a drifting edge). The state stays in the vocabulary for the rigs, the menus and the QA boards; its shared body pose is anchored |
| `dash_start` | windup | 0.12 s deep coil, then the blade profile; heading turns to the dash |
| `dash_loop` | dashing | 0.32 s dive: long and thin along the travel axis, leading edge first |
| `dash_end` | wall or crystal impact | 0.17 s compress over the feet, push back up to a stand |
| `attack` | each dash kill (`GameWorld`) | 0.24 s punch, wobble and flash |
| `hit_reaction` | hurt | 0.32 s shake, flinch and pink flash |
| `death` | dead | 0.5 s flare and fold, heading held (inside the 0.55 s death fade) |
| `revive_spawn` | spawning | 0.58 s pop-in from a squash |
| `victory` | boss-victory pulse | 0.9 s bounce loop |
| `character_selected` / `character_unlocked` | **nothing since 2026-09-21** — the owner removed the bounce on pick, buy and equip; QA boards only | 0.62 s hop / 0.9 s pop, twirl and flash |

Cross-fades are 0.075 s, 0.14 s into calm loops. Heading: dash spring 6.5 Hz (ζ 0.72); standing
spring 4.2 Hz (ζ 0.86).

### What a drawn character has — five animations

The table above is what the **controller** speaks, and what a **bone rig** animates: the rigs build
all thirteen procedurally, so a state costs them nothing. A **whole-frame character** is different —
every state is drawn art and VRAM — and on **2026-09-20 the owner cut the drawn set to five**:

| Animation | Frames | Plays for |
|---|---:|---|
| `dash_loop` | 4 | `dash_start`, `dash_loop` and `attack` — the dash *is* the attack, and one frame is the contact frame |
| `wall_bottom` / `wall_top` / `wall_left` | 8 each | Everything else in a run. `wall_right` is `wall_left` mirrored |
| `storefront_idle` | 12 | Every menu state, on Home and on a Shop card |

`WholeFrameCharacterVisual._target_animation()` is the whole mapping. Nothing in the vocabulary is
refused — a `death` request still travels the state machine, still locks out later states and still
fades out; it just has no picture of its own ([character_creation.md](../guides/character_creation.md) §2).

**A menu may play a video instead** ([ADR-0016](../decisions/0016-menu-videos-for-character-storefronts.md)).
With `menu_video` set, Home and the Shop card play a pre-rendered clip in place of `storefront_idle`
and hold no frame set at all. Reduced Motion falls back to the sprite loop's held first frame, a
hidden card pauses the clip, and the clip restarts when its screen re-enters the tree, because a
`VideoStreamPlayer` stops itself on leaving it and Main detaches the kept Home rather than freeing
it. Shade was the first (2026-09-21 to 2026-09-25; it now plays its AutoSprite storefront) and
Ilyra the second (2026-09-21 until she was removed on 2026-09-26). No character plays one now.

Per character this is **40 frames on two sheets** (`<id>_run.png` 3200 × 1600, `<id>_menu.png`
2784 × 928) instead of 120 on three — about 30 MB of texture instead of 107 MB, and roughly 30 MB
for a Shop carousel instead of 330 MB. The bone rigs are unaffected.

**Standing on walls.** A resting character's up axis is the wall's inward normal
(`get_standing_heading()`), so it stands on the floor, sideways on a side wall and hangs from the
ceiling; aim and drift lean away from that, not from screen-up. A dash dives head-first and then
turns its feet toward the wall over the last `WispPlayer.LANDING_WINDOW` (0.16 s) of the flight
(`landing` 0→1), so it arrives feet-first; each rig also braces with it (fins and wings swing
forward, hands drop, tails gather).

| Character | Parts | Secondary motion | Particles |
|---|---|---|---|
| Rook (640, squash 1.0) — rig removed 2026-09-27, now a whole-frame character | shadow body, skull, 2 wing frames on 2 membranes, 2 feet, 3 tail segments, crescent fin | strong beats at rest, wings cocked high while aiming, folded into a stoop in a dash, flared with the feet forward to land (he roosts under a ceiling), snap on a kill, flinch; body lifts on downstrokes; springy tail | 12 magenta wing dust + 6 bone-white dash streaks (kept on the whole-frame Rook) |
| Morrow (520, squash 0.55, bounce 0.7, softer heading) | cloak, hood, mask, front flap, 2 hands, 3 runes, 2 skinned scarves | cloak breathing, mask tilt, hands on independent orbits (raised with the runes spun up while aiming, back in flight, forward on a kill and to meet the wall, raised to cheer), runes on a tilted ring that never crosses the mask, flap and scarves trail | 10 turquoise rune fragments + 6 dark cloth wisps |
| **Ilyra** (979, squash 0.8) — Mythic, 51 parts from the v3 pack, seven of them skinned limbs | 5 registered head paintings, hair and 2 skinned braids, chest + hips, heart core and glow, 4 three-joint arms with 3 hand poses, 2 fans of 5 ribs and a membrane, 6 skirt panels, 4 skinned sashes, 3 crown pieces, 2 three-piece legs, 3 effect sprites | every arm is shoulder → elbow → wrist and the three ease at falling rates, so a gesture starts at the shoulder and arrives at the hand two frames later; hips counter-rotate against the chest; each fan opens and shuts by rotating five ribs about one rivet, with its shaft running straight through the closed fist between a rear palm and foreground curled fingers and the short gold handle visible below; knees and ankles fold on arrival and her free hands plant on the surface she lands against; a dash *is* an attack — the fans stay out as blades with an arc trailing each one, rather than folding shut; a kill is led by her free hands with the fans crossing a beat behind; she blinks on her own and swaps to focused, joyful or pained faces per state | 18 star motes + 10 dash streaks + an 8-petal kill burst |
| **Bram** (400, squash 0.7, bounce 0.8) — Legendary, ~14 groups | helmet, visor, torso, chest core, 2 two-part arms, shield, blade, blade arc, 2 legs, 2 cape panels | a slow weight shift and a breathing visor and reactor carry the idle; aiming raises the shield and winds the blade back; the dive turns the shield onto the travel axis with the sword arm folded in behind it; a kill is one cut with a single narrow arc; landing compresses and splays both boots; a hit braces behind the shield; selected is a sword salute and unlocked a shield plant with a short flare | 10 soul motes + 6 dash streaks |

## Ilyra (removed 2026-09-26)

The whole-pose sprite character the whole-frame direction came out of: shipped as `ilyra_2` on
2026-09-19, promoted to `ilyra` on 2026-09-20 (GDD §14 #34), drawn from loose PNGs on one
`AnimatedSprite2D` with a `CharacterPoseSheet` placement per pose, her ornaments on a
`CharacterAura` and a menu video (ADR-0016). Removed completely on 2026-09-26 (owner): Scarlet
replaced her as a new character with her own id, and her scene, art, menu video, data, tests and
source art went to the Recycle Bin (GDD §14 #52). This page described her in full until then.

## Rules & behaviour

- `FormData.visual_scene` is optional (a form without one uses the single-image path; none does
  since 2026-09-25). The HUD portrait is `FormData.texture` for every character.
- No character has a tier (owner, 2026-09-26, GDD §14 #53): every character is the same.
  `FormData.tier` and the Shop's tier badge (`%TierLabel`) were removed.
- Characters use the existing `owned_forms` / `equipped_form` save fields; no schema change.
- Only the uniform base size is mirrored from the controller; rigs play their own squash, breathing
  and death, so nothing is doubled.
- `GameWorld` calls `play_attack_visual()` only for dash-event kills (`damage_event_id > 0`).
- One live rig in a run; the Shop builds one preview per CHARACTERS card and only for that tab.
- Animation libraries and the state machine are built once per motion-strength pair and shared by
  every rig (they hold no playback state), and `FormCatalog` keeps loaded characters for the session
  (~18 MB of layers and portraits) so a tab switch never reloads art.
- A hidden rig stops completely (`set_process(false)`, tree inactive, particles off): the Shop keeps
  the character cards in the tree while another tab is shown. Reduced Motion reaches the equipped rig
  mid-run too, because `WispPlayer.set_reduced_motion()` forwards the pause menu's change.
- A dash kill on the fatal frame cannot cut the death animation short.
- Menus: picking, buying or equipping a card plays nothing — no hop, no pop (owner, 2026-09-21). The
  card keeps its idle, or its video. Reduced Motion stills menu
  previews too.

## How to test

- `tools/run_tests.sh playable_character_visual` — all states, no collision, ≤ 40 particles, ribbon
  weights, silhouette vs `design_size`, the real controller through spawn/dash/kill/redirect/landing/
  hit/victory/death with a per-frame snap check, Reduced Motion, Home, that buying and equipping in the Shop no longer bounce, GameWorld.
- `tools/run_tests.sh rook_visual` (and `scarlet_visual`, `mothmere_visual`, `verdant_shade_visual`,
  `patchvile_visual`) — each whole-frame character's pack contract and behaviour.
- `tools/run_tests.sh form_catalog` — six characters, prices, rigs, save ids.
- Rebuilding a part-pack rig: `python3 tools/art/extract_playable_characters.py <id>` then
  `python3 tools/art/build_character_rig.py <id>`. The scene is generated — hand edits to
  `<id>_visual.tscn` are lost on the next run; per-character motion lives in `<id>_visual.gd`.
- Rebuilding Rook: `python concept_art/rook_autosprite_v1/slice_sheet.py` (cuts and cleans the frames,
  writes `review/cleanup_<sheet>.png`, every frame before and after), then
  `python3 tools/art/extract_playable_characters.py rook`.
- Rebuilding Scarlet: `python concept_art/scarlet_autosprite_v1/slice_sheet.py` (cuts and cleans the
  frames, cuts her particle pieces, writes `review_cleanup.png`), then
  `python3 tools/art/extract_playable_characters.py scarlet`.
- `tools/screenshot.sh res://tools/godot/render_character_lineup.tscn 90 540x960` — reference vs rig
  (`WISP_LINEUP_POSE=attack|hit|aim|victory`; optional `WISP_CHARACTER=<id>` filters to one row);
  prints `[Lineup]` bounds for sizing.
- Motion frames: the command in `render_character_motion.gd`, then
  `python3 tools/art/motion_contact_sheet.py <id>` → `logs/motion/<id>_*.png`.
- `WISP_CHARACTER=<id> tools/screenshot.sh res://tools/godot/render_character_{select,home,gameplay}_showcase.tscn`.
- Slow-motion dash clip (launch, kill accent, mid-dash turn, dive, landing) with a trailing camera and
  a live state caption: same command as the motion frames plus `WISP_MOTION_CLIP=1
  WISP_MOTION_SCALE=0.25 --quit-after 860`, then encode the frames with ffmpeg at 60 fps.
- Cost: `"$GODOT" --headless --path . --script res://tools/godot/bench_character_previews.gd` —
  all 13 previews build in 422 ms cold and ~7 ms warm; headless animation stayed at the 6.9 ms/frame
  empty-loop baseline (measured 2026-09-20 on the owner's Windows PC).

## Known issues / TODO

- **Rook** (2026-09-27) and **Scarlet** (2026-09-26) await the owner's phone test.
- Owner approval of the look and motion, then prices (all six production rigs cost 0 RP for review).
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
- Generated art: licence to confirm before selling (GDD §14 #1, #21).

## Change history

| Date | Change |
|---|---|
| 2026-09-27 | **Every character, new or redesigned, stands centred on Home's platform** (owner, GDD §14 #57): `WholeFrameCharacterVisual.menu_offset`; Rook's (2.7, 62.5) puts his feet on the platform's centre and his body over it |
| 2026-09-27 | **Rook rebuilt on the AutoSprite recipe; his bone rig removed** (owner, GDD §14 #56): the owner's five sheets, cleaned frame by frame by his slicer, packed at Patchvile's scale on 336 px run cells (`design_size` 336, `art_scale` 1.55859375); his own ceiling; dash cells 03, 05, 07, 08, 09, 11, 14, 17; his rig's dash look kept (streaks, dust trail, mote ring, `DUST_WAKE`); rig scene, script and 13 body-part images removed (to the Recycle Bin); `test_rook_visual.gd` |
| 2026-09-26 | **Every character the same size again** (owner, GDD §14 #54): the own-height change reverted (ROSTER CHECK back to 194 for everyone); Scarlet drawn 1.16× larger (`art_scale` 1.38, `menu_art_scale` 1.45) so she stands on Home's platform like the others |
| 2026-09-26 | **Scarlet** added (owner) in place of **Ilyra, removed completely** (scene, art, menu video, data, tests, source art; a save naming `ilyra` or `ilyra_2` falls back to Patchvile): the owner's four AutoSprite sheets, sliced and cleaned by her slicer, packed at `standing` 166; her own reap-crescent and crown-diamond particles, Ilyra's twin-arc dash look in her blue, splash landing; `test_scarlet_visual.gd`. **Tiers removed** (GDD §14 #53): `FormData.tier`, the Shop badge |
| 2026-09-26 | Characters keep Patchvile's pixel size but each has its own height (owner, GDD §14 #51): a `roster_scale` pack records its approved `standing` (Shade and Mothmere 194) and the ROSTER CHECK compares with it. Scarlet, who replaces Ilyra, has approved first frames at 166 px (GDD §14 #52) |
| 2026-09-25 | **Mothmere** added (owner): AutoSprite storefront, floor, right wall and one-shot dash with a red reap, packed at Patchvile's scale (ROSTER CHECK 196 px, +1 %); keeps his outline (GDD §14 #49); red attack look and trail particles, dust landing; `test_mothmere_visual.gd` |
| 2026-09-25 | **Roster cut to five** (owner): Void, Eclipse, Veyra and Noxen removed with their scenes, data, art, sources and tests; Patchvile is the default. Old Patchvile and Shade sources removed (the originals, particle pieces and first-frame sources kept in the current packs) |
| 2026-09-25 | **Shade rebuilt on the AutoSprite recipe** from the owner's five sheets: new slicer and pack, `roster_scale`, one-shot dash attack, own ceiling sheet, storefront instead of the menu video, leaf dash particles, green attack glow and dust landing; its test rewritten for the new contract |
| 2026-09-25 | Docs: **Patchvile is owner-approved** as built (all AutoSprite); stale "not approved" / "Codex's dash" wording corrected, contact frame 4 and `art_scale` 1.1875 recorded |
| 2026-09-23 | **No procedural idle body wobble** (owner): `PlayableCharacterVisual` holds position, scale and rotation in `idle_hover` and `aim_charge`; Home adds no float, scale breath or sway to either preview. Authored sprite loops and menu videos continue, as do rig secondary parts and non-idle gameplay reactions |
| 2026-09-21 | **No bounce when a character is picked** (owner): the Shop no longer hops the focused card, pops a bought one or hops an equipped one, and Home no longer hops a newly equipped hero. `PlayableCharacterPreview.play_selected` / `play_unlocked` removed; `character_selected` / `character_unlocked` stay in the vocabulary for the QA boards. The Shop tests assert neither plays |
| 2026-09-21 | **Ilyra's menu video**: the owner's ready-stance take on green, through the new shared `CharacterMenuVideo` (Shade's playback moved onto it). Her aura is hidden while it plays; Reduced Motion holds her welcome painting |
| 2026-09-21 | **Menu videos** (ADR-0016): `MenuVideoData`, `packed_alpha_video.gdshader` and `tools/art/extract_menu_video.py`; Shade's Home and Shop card play her generated clip. Fixed the same day: the clip stood still after every return to Home (the kept Home is detached, and a `VideoStreamPlayer` stops on leaving the tree) — it now restarts on re-entry, with a regression check |
| 2026-09-20 | **The drawn set cut to five animations** (owner): `dash_loop`, three wall loops and `storefront_idle`. The windup, landing, attack, drift, hit, death, spawn, victory, gameplay idle and both storefront reactions are gone as art and are carried by the controller instead — the arrow is the windup, the wall loop is the landing, the blink and edge reset are the hit, the alpha dissolve is the death. `WholeFrameCharacterVisual._target_animation()` maps the full vocabulary onto the five; Ilyra follows the same rule from her loose PNGs. 120 frames on three sheets → 40 on two, ~107 MB → ~30 MB of texture per character |
| 2026-09-20 | **Noxen, the Veilflame**: handless Legendary cut-out rig from a twelve-part blue/cyan source pack; two skinned root ribbons, independently sprung flame horns, fins that fold into a dash spear and flare into the contact cut, free-for-review catalog entry and Blade Arc dash signature |
| 2026-09-19 | 🧪 **Ilyra**: the same character as one painted pose per state on an `AnimatedSprite2D`, added beside the rigged Ilyra to compare the two approaches. New `POSE_PACKS` intake in the extractor, `CharacterPoseSheet` placement data, screen-space wall poses, a dedicated test and a 21-cell review board. Experimental — 0 RP, no GDD or ADR entry |
| 2026-09-19 | Ilyra fan-grip pass: each shaft runs on the fist's vertical axis, disappears between a rear palm and foreground curled fingers, and visibly protrudes below the fist; the character test enforces placement, axis, protrusion and depth order |
| 2026-09-18 | Ilyra's limbs moved to **skinned meshes**: torso, four arms and two legs are each one painting over a three-bone chain, so elbows, knees and the waist bend the paint instead of rotating cutouts over each other and the joint seams are gone. Hands, boots, head, skirt and sashes re-parent onto the bone that carries them |
| 2026-09-18 | Ilyra rebuilt on the v3 part pack (separated parts + a pivot manifest): real shoulder/elbow/wrist chains on all four arms, a twisting waist, fans that fold rib by rib, bending knees, wall-grip landings, hands-first kills with a petal burst, and five registered faces with self-timed blinks. `build_character_rig.py` generates the scene from the manifest |
| 2026-09-18 | Ilyra (Mythic) and Bram (Legendary) rigs; `FormData.tier` and the Shop tier badge; `tools/art/make_rig_source.py`; versioned source packs and mask polygons in the extractor, whose component labelling now uses scipy (v1 output byte-identical); the lineup fixture scales to the roster |
| 2026-09-18 | Dive-and-slice dash profile, feet-first wall landings (`surface_normal`, `landing`, `get_standing_heading()`) and a pre-attack coil while the aim arrow is up; the clip fixture holds a real aim before its first dash |
| 2026-09-17 | Review fixes: Reduced Motion reaches the rig mid-run, a kill cannot interrupt death, hidden rigs stop processing, chain lag is a rate (same whip at 30/60/120 fps), no per-frame allocations |
| 2026-09-17 | Rook and Morrow rigs; Veyra rebuilt with skinned tails and split halo; base rewritten (heading spring, travel-axis squash, interrupts, per-character strengths, single-image rig); animated CHARACTERS cards with selected/unlock flourishes; QA fixtures, motion sheets and tests (Claude Code) |
| 2026-09-17 | Veyra prototype: layered rig, shared state machine, previews, save integration, particles, test (Codex) |
