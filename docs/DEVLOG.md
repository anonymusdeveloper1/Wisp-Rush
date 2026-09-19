# Devlog

> Append-only session log, **newest first**. One entry per work session; format in
> [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) §7.6. Keep entries short — details belong in the docs
> they changed.

## 2026-09-18 — Ilyra v3.1 continuous skinned-source replacement
- **Who:** Codex (GPT-5)
- **Did:** Followed Claude's superseding `ART_REQUEST_SKINNED.md` contract for Ilyra only. Replaced
  the 12 rigid arm segments, four thigh/shin pieces and two-piece torso (18 PNGs) with four whole
  arms, two whole legs and one connected torso (seven PNGs), leaving a 55-part pack. The arms and
  legs were generated against the approved identity lock; the torso losslessly flattens the
  approved chest/hips at their prior registration. Added four-point deformation chains to the
  manifest, re-rendered the neutral assembly, and updated the pack README, exact prompt/finishing
  provenance and asset ledger. All 48 retained PNGs remain byte-identical. Created no Bram art and
  changed no runtime code, scenes, catalog or `data/forms`.
- **Files/systems:** `concept_art/wisp_rush_playable_characters_v3/{README,GENERATION_PROMPTS}.md`,
  `parts/ilyra/`, `assembly/ilyra_assembly_reference.png`, `docs/ASSETS.md`, generated project map.
- **Verified:** 55 PNGs / 55 manifest entries; 18/18 superseded files absent; all seven new parts are
  single connected straight-alpha components with four in-bounds vertical chain points, ≥8 px
  transparent padding and zero RGB below alpha 0; 48/48 retained hashes unchanged; every internal
  joint survives −70°/+70° mesh bends and `arm_ul` passes the torso/shoulder socket sweep; assembly
  fits the 1024² frame and reads at 61×64 px; `tools/validate.sh` → `VALIDATE: OK`;
  `tools/run_tests.sh` → 25 passed / 10 failed, matching the pre-existing stale form/unlock/save
  baseline, while `test_playable_character_visual` passes.
- **Follow-ups:** Claude updates the extractor and rebuilds Ilyra's runtime rig from the v3.1
  manifest, then the owner completes the phone gate. Bram remains blocked until that sign-off.

## 2026-09-18 — Ilyra v3 production rig-source handoff
- **Who:** Codex (GPT-5)
- **Did:** Followed Claude's `concept_art/wisp_rush_playable_characters_v3/ART_REQUEST.md` contract
  and produced Ilyra only: 66 isolated straight-alpha RGBA parts, a 66-entry pivot/tip/rest/draw-order
  manifest, and a neutral 1024² assembly rendered purely from that manifest. Missing rig geometry was
  generated against the owner-approved v2 identity lock; already-approved braids, skirt panels,
  sashes, crown and heart pixels were preserved, de-matted and put at one uniform source scale. A
  visual QA pass rejected cuffs baked into the first hand board, detached fan/braid fragments and a
  vertical slash texture; the final hands are bare, cloth centre lines are vertical, fan membrane
  states have identical alpha and VFX are near-white/tintable. Copied both locked references
  byte-for-byte as §5 requires, but created no Bram parts. Added the pack README, verbatim prompt and
  finishing provenance, and ASSETS rows. No runtime code, scenes, forms, catalog or runtime art was
  changed.
- **Files/systems:** `concept_art/wisp_rush_playable_characters_v3/{README,GENERATION_PROMPTS}.md`,
  `references/`, `parts/ilyra/`, `assembly/ilyra_assembly_reference.png`, `docs/ASSETS.md`.
- **Verified:** 66 PNGs / 66 manifest entries; every PNG is RGBA with ≥8 px transparent padding and
  zero RGB under alpha 0; magenta contact sheet clean; all five heads share 272×246 registration;
  five fan ribs share 176 px height; elbow and knee composites show no gap at −60°/0°/+60°; assembly
  fits `(55, 5)–(970, 968)` and remains recognisable at 61×64 px; approved reference copies have
  matching SHA-256; `tools/validate.sh` → `VALIDATE: OK`; full suite 25 passed / 10 failed, the same
  pre-existing stale tests documented in the preceding character session.
- **Follow-ups:** Claude rebuilds Ilyra's runtime rig from this source and manifest, then the owner
  completes the phone gate. Generate no Bram v3 parts until that explicit sign-off. Generated-art
  licence still requires confirmation before release.

## 2026-09-19 — The wall hold never actually ran; fixed at the source
- **Who:** Claude Code (Opus 5)
- **Did:** The owner reported that none of the previous round was visible in game. It was not, and the
  cause was a real defect rather than tuning: **the hold was keyed off `get_landing()`**, and
  `WispPlayer._get_landing_progress()` returns `0.0` the moment `state != State.DASHING`. So the pose
  appeared during the last 0.16 s of *flight* and was gone by the time she was standing on the wall —
  the one moment it was written for.
  - The hold is now driven by the surface she is resting against: the floor's inward normal points up,
    a side wall's is sideways, a ceiling's points down, so `1 - surface_normal.dot(UP)` is 0 on the
    floor and 1 on anything she has to hold. It holds for as long as she is there.
  - Same bug in the legs: the knee fold also keyed off `_brace`, so she stood straight-legged against
    the wall. It now folds into the hold too.
  - **Verified by measurement, not by eye.** A throwaway probe printed the real joint angles per
    situation, which is what caught the legs:

    | | ArmLl (shoulder, elbow, wrist) | LegL | arc scale |
    |---|---|---|---|
    | rest on floor | 1.78, 0.26, 0.20 | 1.57, 0.00 | 1.00 |
    | rest on side wall | 3.37, -1.55, -0.85 | 2.05, -0.73 | 1.00 |
    | mid dash | 1.31, -0.15, -0.11 | 1.64, -0.11 | 2.50 |

    The hold swings her left arm 1.6 rad further and folds that elbow hard, only on a wall; the knees
    fold asymmetrically (-0.73 against +0.34); the dash sweep grows 2.5x. All four arms trail at
    different angles through a dash.
- **Files/systems:** `scenes/player/visuals/ilyra_visual.gd`.
- **Verified:** `validate.sh` OK; `playable_character_visual` passes; joint angles measured as above;
  motion sheet shows the hold persisting across every wall-rest frame rather than one; installed and
  launched on the owner's SM-S921B with Ilyra equipped.
- **Lesson:** a controller value named for a *transition* (`landing`) is not a state. Anything that
  should persist while resting must read the resting condition, not the approach to it. Worth
  checking Bram's `_plant` for the same mistake when he moves to skinned limbs.

## 2026-09-19 — Ilyra's hold and dash rebuilt from the owner's references
- **Who:** Claude Code (Opus 5)
- **Did:** The owner sent three pose references (a climber holding a wall edge, a sheet of aerial
  falling poses, and a pixel-art sheet whose dash attack is one wide fire sweep). Pinterest links are
  not fetchable — login-walled and JavaScript-rendered — so they were pasted as images instead; worth
  remembering for next time.
  - **The hold is asymmetric now.** The climbing reference takes the surface with one side and
    counterbalances with the other; the rig was doing a symmetric two-arm brace that read as standing
    to attention. `GRIP_POSE` gives all four arms their own (shoulder, elbow, wrist) offsets — her
    left pair bites, her right pair swings free — only her left hand closes, `GRIP_KNEE` folds one
    leg under her while the other stays long, and the waist twists into the hold.
  - **The dive trails.** The falling sheet has limbs streaming at different angles, never collapsed
    onto one axis, so `DASH_TRAIL` gives each arm its own angle through a fold instead of pulling
    them all to zero.
  - **The dash is one wide sweep.** In the pixel reference the character travels *inside* a single
    broad slash rather than flicking small arcs. A `_sweep` accent (eased slower than `_cut`, so the
    arcs grow instead of popping) stretches both blade arcs along the travel axis until they read as
    one edge carried across the arena.
  - Also seated the fans properly: her fist now closes part-way up the shaft with the butt emerging
    below, rather than the fan balancing on top of her hand.
  - Removed two per-frame array allocations found while editing (`CONVENTIONS` §8).
- **Files/systems:** `scenes/player/visuals/ilyra_visual.gd`.
- **Verified:** `validate.sh` OK; `playable_character_visual` passes (no per-frame snaps despite the
  larger swings — the sweep is eased at 7/s precisely to stay inside the contract); grip inspected at
  Shop scale; slow-motion clip re-filmed to `logs/clips/ilyra_slowmo.mp4`.
- **Follow-ups:** the clip's timeline lands on the floor, so the one-sided wall hold is still easier
  to see in a side-wall landing than in this film. APK not yet reinstalled — the phone was
  disconnected. Bram is still on cut segments.

## 2026-09-19 — Ilyra holds her fans, holds the wall, and cuts with the dash
- **Who:** Claude Code (Opus 5)
- **Did:** Three fixes the owner called out on the skinned rig, then filmed it.
  - **She was not actually holding the fans.** Measured rather than eyeballed: the pack seats each
    `fan_handle` so its butt ends **57 px past her fist**, and gives it `draw_order` 66 against the
    hand's 46 — so the handle drew *over* the fist and the grip read as floating. `_seat_fan()` now
    solves the handle's local position from its own length and angle so the butt lands in the palm,
    keeping whatever angle the pack authored, and lifts the gripping hand's `z_index` above it.
  - **Wall landings read as standing.** The hold is much stronger now: the free pair reaches past her
    hips, the elbows fold hard so the forearms lie along the surface and the wrists cock back, on top
    of the knees and ankles that already folded.
  - **The dash is her attack.** It used to fold the fans shut into a spearhead, which read as a dive
    rather than a strike. A new `_cut` accent holds both fans ~85 % open through `dash_start` and
    `dash_loop`, lights the membranes, and trails an arc off each blade that sweeps ahead of her.
  - **Filmed it**: `logs/clips/ilyra_slowmo.mp4`, 4× slow motion through launch, kill accent,
    mid-dash turn, dive and landing, with the live state captioned.
- **Files/systems:** `scenes/player/visuals/ilyra_visual.gd`,
  `docs/systems/playable_character_visuals.md`, `docs/guides/character_rig_recipe.md`.
- **Verified:** `validate.sh` OK; `playable_character_visual` passes; full suite 25 passed / 10 failed
  (the documented stale set); grip inspected at Shop scale on both hands; slow-motion clip reviewed.
- **Follow-ups:** APK rebuilt but **not installed — the phone disconnected during the deploy**. The
  wall hold is hard to judge from this clip because its timeline lands on the *floor*; a side-wall
  landing would show it better. Bram is still on cut segments.

## 2026-09-18 — Ilyra's limbs are skinned meshes; the joint seams are gone
- **Who:** Claude Code (Opus 5)
- **Did:** Codex delivered the skinned part pack — the eighteen cut arm/leg/torso segments replaced by
  **seven whole paintings carrying a `chain` of joint points** (torso, four arms, two legs), 55 parts
  in total. Rebuilt her on it.
  - **`build_character_rig.py`** now emits any part with a `chain` as a `RibbonChain` whose spine is
    that chain, so a limb is one painting stretched over three bones. Cloth still uses a straight
    pivot→tip spine driven by a `ChainSpring`; limbs have their bones **posed** by the rig script.
  - **Riders re-parent onto bones.** The generated scene parents a hand to the arm's *root*, which is
    right for a cutout and wrong for a skinned limb — the hand would sit still while the elbow bent
    under it. `_mount_riders()` moves each part onto the bone that carries it with `reparent(bone,
    true)`; the bones are still at rest at `_ready`, so everything lands with the offset it was
    authored with. Hands ride the wrist bone, boots the ankle, head and arms the upper torso, skirt
    and sashes the hips, the heart the chest.
  - **The seams are gone.** At Shop scale the arms are continuous through shoulder, elbow and wrist —
    the paint deforms instead of two pieces rotating over each other.
  - **The owner's two asks, both in:** her free hands now plant on the surface she lands against
    (`_grip` follows `get_landing()`, the lower pair reaches out and the hands close), and a kill is
    led by those hands punching out along the travel axis with the fans crossing a beat behind, over
    an eight-petal `AttackParticles` burst.
- **Files/systems:** `scenes/player/visuals/ilyra_visual.{gd,tscn}`, `tools/art/build_character_rig.py`,
  `tools/art/extract_playable_characters.py`, `assets/art/characters/playable/ilyra/`,
  `scripts/utils/frame_pacing.gd`, `scenes/main/main.gd`, `data/forms/{ilyra,bram}.tres`,
  `docs/guides/character_rig_recipe.md`, `docs/systems/playable_character_visuals.md`.
- **Verified:** `validate.sh` OK; `playable_character_visual` passed first run (all 13 states, no
  collision, particle budget, skin weights, sizing, the real controller through every state with no
  per-frame snaps, Reduced Motion, both menus, a production GameWorld); `form_catalog` passes; full
  suite 25 passed / 10 failed — the documented stale set, no new regressions; motion contact sheet
  reviewed through idle, aim, dash, kill and landing; installed on the owner's SM-S921B, which boots
  `physics=120 Hz` with no script errors and no UID warnings.
  - **Adaptive displays.** Deploying caught the S24 reporting **60 Hz** at one launch and **120 Hz**
    at the next: Samsung's panel moves between its modes while the game runs, so reading the rate
    once at boot leaves the simulation mismatched for the rest of the session. `FramePacing.poll()`
    now re-reads the screen every two seconds and re-rates the simulation only when it changed;
    `Main` logs the change. This also explains the earlier confusion — the panel really was at 60 Hz
    when the "120 Hz simulation" build was tested, so that result never came from a refresh match.
  - **Stale UID.** The device logged `invalid UID … using text path instead` for Ilyra's
    `preview.png`: it is regenerated by the ingest and gets a fresh UID each time, while the export
    resolved one from an older run. Pinned the real UID (read from the `.import`, not invented) into
    `ilyra.tres` and `bram.tres`. The warning is gone.
- **Follow-ups:** Bram is still on cut segments and should move to skinned limbs when his v3 parts
  are made. The owner's verdict on Ilyra's motion is the gate for starting them.

## 2026-09-18 — Simulation follows the screen, not one phone
- **Who:** Claude Code (Opus 5)
- **Did:** The owner confirmed the 120 Hz simulation felt smooth on their S24, then asked the right
  question: *would it be smooth on other devices?* It would not. Pinning
  `physics_ticks_per_second=120` tunes the game to one screen — it wastes half the physics budget on
  a 60 Hz phone, gives an uneven 4:3 step on the many 90 Hz mid-range Androids, and judders again
  above 120 Hz.
  - **Re-opened physics interpolation properly this time** rather than leaving it at "rejected".
    Godot's docs say nodes animated per frame in `_process` should not rely on it, which matched the
    symptom exactly, so the rigs were opted out with `PHYSICS_INTERPOLATION_MODE_OFF`. That fixed
    Ilyra's effect sprites but the contract still failed 2 of 5 runs on Veyra's `MotionRoot`.
    Measured the baseline to be sure the flakiness was not pre-existing: 5/5 clean without
    interpolation, so it is genuinely the trigger. The cause is pacing, not a measurement bug — the
    sampler does refresh its baseline on skipped frames — and the cubic squash curve can outrun a
    linear per-frame budget once frame times vary. Making it work would mean opting out the rigs,
    both ambiences, the tutorial hand, the VFX pool and most screens, and adding
    `reset_physics_interpolation()` at every teleport: a lot of regression surface across the whole
    game for something the simpler fix also delivers.
  - **`FramePacing.match_display()`** instead, called once from `Main._ready()`: read the screen's
    refresh rate and step the simulation at it, clamped to 60-120 Hz. A 60 Hz phone pays nothing, 90
    and 120 Hz match exactly, and anything above is capped so the physics cost stays bounded. Where a
    display cannot report a rate — headless runs and every automated test — it falls back to 60 Hz,
    so the tuned simulation stays reproducible. The boot line now prints the rate it chose.
- **Files/systems:** `scripts/utils/frame_pacing.gd` (new), `scenes/main/main.gd`, `project.godot`
  (the `[physics]` override removed), `docs/systems/{game_feel,playable_character_visuals}.md`,
  `docs/ROADMAP.md`, ADR-0015.
- **Verified:** `validate.sh` OK and the boot line reads `physics=60 Hz` headless (the fallback);
  `playable_character_visual` 3/3 clean; a real run through the Godot MCP picks the rate from the
  Mac's display. Android APK rebuilt but **not yet installed — the phone was disconnected**.
- **Follow-ups:** confirm on the S24 that the boot line reads `physics=120 Hz` and that it still
  feels smooth; if a 90 Hz device ever shows uneven pacing, that is the case for revisiting
  interpolation with the per-frame nodes opted out.

## 2026-09-18 — 120 Hz simulation; skinned meshes chosen over 3D for the seams
- **Who:** Claude Code (Opus 5)
- **Did:** Owner tested the rebuilt Ilyra on the phone: still not smooth, and parts visibly out of
  line. Diagnosed both rather than tuning blind.
  - **The seams are the technique, not the tuning.** The rig reproduces the v3 assembly reference to
    0.01 px, so the gaps are in the source geometry and in what rigid cutouts can do: the joint caps
    were authored to ±60°, but `aim`, the dash fold, the kill and the flourishes all swing past that,
    and beyond a cap two cutouts rotating over each other must show a seam. The arms also float off
    the shoulders in the reference itself.
  - **Owner asked whether to switch to 3D.** Recommended against it and said why: the whole game is
    2D painted art, the other four characters are 2D rigs, there is no modelling or rigging pipeline
    (an image generator cannot produce a rigged skinned model), and it would not fix the judder. The
    real answer is skinned 2D meshes — one painting per limb with bones inside it, which is exactly
    what `RibbonChain` already does for her braids. Owner chose that.
  - **Judder.** Tried Godot's physics interpolation first; it shifted frame pacing enough that the
    rig smoothness contract failed *intermittently* on Veyra and Rook (0.32-0.33 scale steps inside a
    normal-length frame, passing on one run and failing the next). Rejected it and set
    `physics/common/physics_ticks_per_second=120` instead, which halves the step without touching how
    anything is drawn. Three consecutive clean runs of `playable_character_visual`, full suite back to
    25 passed / 10 pre-existing failures.
  - Wrote `concept_art/wisp_rush_playable_characters_v3/ART_REQUEST_SKINNED.md`: whole uncut arms,
    legs and torso replacing the eighteen cut segments (18 files become 7), each with a `chain` of
    joint points for mesh weighting, plus the rules that make a painting deformable — draw it
    straight, never put a gold band on a joint, keep the width even through a bend, and include the
    shoulder socket so the limb cannot float.
- **Files/systems:** `project.godot` (`[physics]`), `concept_art/wisp_rush_playable_characters_v3/ART_REQUEST_SKINNED.md`.
- **Verified:** `validate.sh` OK; `playable_character_visual` 3/3 clean runs at 120 Hz; full suite 25
  passed / 10 failed (the documented stale set); Android debug build installed and launched on the
  owner's SM-S921B, no script errors.
- **Follow-ups:** owner's verdict on whether 120 Hz fixed the judder. Then Ilyra's limbs and torso
  move to skinned `Polygon2D` meshes once the new art lands, and Bram only after she is signed off.
  Still open: the cosmetic stale-UID warning on `ilyra.tres`'s portrait.

## 2026-09-18 — Ilyra rebuilt on separated parts: real joints, folding fans, blinks
- **Who:** Claude Code (Opus 5)
- **Did:** The owner tested the first Ilyra on a phone and she read as a still pose. The cause was
  the source art, not the tuning: her v2 rig came from the approval sheet's component row, so each
  arm was one painting split at the elbow with a straight crop box (a bent elbow showed a seam, and
  shoulders and wrists could not rotate at all), the torso was masked out of a turnaround and could
  not twist, and the fan "folded" by cross-fading two paintings. Wrote an art request
  (`concept_art/wisp_rush_playable_characters_v3/ART_REQUEST.md`) for one PNG per rig group plus a
  pivot manifest; Codex delivered 66 parts, a manifest and an assembly reference.
  - **Intake.** `extract_playable_characters.py` gained `PART_PACKS`: a pack is copied **byte for
    byte**, because the manifest's pivots are in each file's own pixel space and any re-crop would
    move every joint. `preview.png` is derived from the pack's assembly reference, so the HUD and
    card portrait can never drift from the rig.
  - **`tools/art/build_character_rig.py`.** Generates the rig scene from the manifest: absolute rest
    transforms into parent-relative ones, pivots into sprite offsets, draw order into `z_index`
    (tree order cannot express it — her legs must draw behind the torso they hang from), the fan
    mechanism mirrored once at its chain root, and `design_size` / `preview_center` measured from the
    assembled silhouette. The rig matched the assembly reference to the pixel on the first run once
    the mirror was applied at the root rather than at every node.
  - **Motion.** Each of the four arms is shoulder → elbow → wrist easing at falling rates, so a
    gesture starts at the shoulder and lands in the hand two frames later; hips counter-rotate
    against the chest; each fan opens and shuts by rotating five ribs about one rivet; knees and
    ankles fold on arrival; five registered head paintings carry self-timed blinks and focused,
    joyful and pained faces.
  - **Owner feedback mid-pass:** her free hands now plant on the surface she lands against, and a
    kill is *led* by those hands with the fans crossing a beat behind (`_slash` on a fast ramp,
    `_slash_follow` on a slower one) over an eight-petal burst.
- **Files/systems:** `tools/art/build_character_rig.py` (new), `tools/art/extract_playable_characters.py`,
  `scenes/player/visuals/ilyra_visual.{gd,tscn}` (the scene is generated — hand edits are lost),
  `assets/art/characters/playable/ilyra/`, `concept_art/wisp_rush_playable_characters_v3/`,
  `docs/systems/playable_character_visuals.md`, `docs/ASSETS.md`, `docs/guides/character_rig_recipe.md`.
- **Verified:** `validate.sh` OK; `playable_character_visual` and `form_catalog` pass; full suite 25
  passed / 10 failed — the same documented stale-since-M10 scripts. Lineup bounds match the pack's
  assembly reference exactly (978.98 vs `design_size` 979, centre (0, −138.5)); motion contact sheets
  reviewed frame by frame for idle, aim, dash, the hands-first kill and the wall landing;
  Shop/Home/GameWorld screenshots inspected; Android debug build installed and launched on the
  owner's SM-S921B with no errors.
- **Follow-ups:** owner's device verdict on the motion is the gate before Bram's parts are generated.
  The exported build logs one cosmetic warning — `ilyra.tres` carries a stale UID for `preview.png`
  from before the portrait was regenerated, so Godot falls back to the text path and loads it
  correctly; the MCP `update_project_uids` tool resaved nothing (its path handling is wrong), and
  clearing `.godot/`'s UID cache is denied to agents, so this needs an editor open or a source-side
  UID. Unrelated and still open: on a 120 Hz phone positions step at the 60 Hz physics rate.

## 2026-09-18 — The finisher and RUSH-end sounds were never audible
- **Who:** Claude Code (Opus 5)
- **Did:** Fixed `WARNING: [Audio] unknown SFX id: pulse`, seen on the Android debug build.
  `game_world.gd` asked for `&"pulse"` for both the slow-motion finisher and the end of RUSH, but
  `pulse` is one of the three **music layers**, not an effect — so `play_sfx()` found no stream and
  warned, and neither sound had played since M10 introduced them. The id could not simply be
  registered either: `AudioSynth.render_all_pcm()` keys effects and music in one dictionary and
  `AudioService._install_pending()` files a stream as music or SFX **by name**, so an effect called
  `pulse` would be overwritten by the 8-second music loop and filed as music.
  - Added `soul_pulse` to `SFX_IDS` — a low octave-falling chorus with filtered air under it and no
    bell, so it lands as weight rather than a chime, matching what both call sites and both tuning
    fields (`finisher_pulse_pitch` 0.6, `end_sound_volume_db` −6) were written for. Trimmed −4 dB
    like `wall_impact`.
  - Pointed both call sites at it and corrected the doc comments that described "a low `pulse`".
  - **Regression guard:** `test_audio_service` now scans every `.gd` under `scenes/` and `scripts/`
    for `SoundFx.play(&"id")` and fails if the id is not renderable, or if it is a music-layer id.
    Verified by reintroducing the bug — the test failed naming the file and the id.
- **Files/systems:** `scripts/utils/audio_synth.gd`, `scripts/autoload/audio_service.gd`,
  `scenes/gameplay/game_world.gd`, `scripts/resources/run_feel_tuning.gd`,
  `tools/godot/test_audio_service.gd`, `docs/systems/{audio,game_feel,rush_mode}.md`.
- **Verified:** `validate.sh` OK; `test_audio_service` passes (every SFX renders, levels and edges
  clean, the new call-site scan covers 15 played ids); full suite 25 passed / 10 failed — the same
  documented stale-since-M10 scripts, no new regressions; a real run through the Godot MCP reports
  `[Audio] synthesized 22 sounds` (was 21) with no warnings and no errors.
- **Follow-ups:** the sound has only been verified headlessly and at boot — hearing it needs a
  multi-kill finisher or a RUSH ending on device, so it is worth a listen on the owner's next phone
  session. Unrelated and still open: on a 120 Hz phone positions step at the 60 Hz physics rate.

## 2026-09-18 — Ilyra and Bram: two more animated characters, and collectible tiers
- **Who:** Claude Code (Opus 5)
- **Did:** Implemented the two owner-approved characters from
  `concept_art/wisp_rush_playable_characters_v2/`, Ilyra first and fully verified before Bram existed,
  per that pack's `IMPLEMENTATION_BRIEF.md`.
  - **Art pipeline.** Approval sheets are opaque, so `tools/art/make_rig_source.py` now derives the
    transparent rig source the extractor needs: Ilyra's reference already carried a clean subject
    matte, Bram's is keyed off near-black. `extract_playable_characters.py` gained versioned
    `SOURCE_SHEETS` (v1 output stays byte-identical) and `MASKS`, a polygon cut for a part the sheet
    never isolates — Ilyra has no separate torso anywhere but inside her front turnaround. Its
    component labelling is `scipy.ndimage.label` now; the hand-rolled union-find degenerated to
    minutes on Bram's silhouette. 28 Ilyra layers, 17 Bram layers, both contact sheets reviewed.
  - **Ilyra (Mythic, ~30 groups).** Four two-part arms that counter-pose with the pairs a beat apart
    and the forearms easing slower than the upper arms; folding fans (the open painting cross-fades
    to the closed one); six skirt panels on their own springs; two skinned braids and four skinned
    sashes; three crown pieces orbiting clear of her face.
  - **Bram (Legendary, ~14 groups).** Deliberately quieter: weight shift, breathing visor and
    reactor, two spring-driven cape panels, a shield-first dive with the sword arm folded behind it,
    one clean cut with a single narrow arc, and a landing that compresses through both boots.
  - **Tiers.** `FormData.tier` (`STANDARD`/`LEGENDARY`/`MYTHIC`) with a `%TierLabel` badge above the
    Shop description — presentation only, and it never replaces price or ownership state.
  - **Owner feedback on device:** Ilyra read as a still pose in a run. Her idle sway was 0.09 rad,
    about one pixel on a 130 px character, so her arms and fans were moving invisibly. Raised the
    idle choreography to 0.30 + 0.14 rad with per-arm phase, forearms 0.07 → 0.34, fan
    counter-rotation 0.16 → 0.42 plus a breathing fold, and turned `attack` into a real opposed
    cross-slash (upper arms 2.0/1.45 rad, the lower pair answering). No new art was needed.
- **Files/systems:** `scenes/player/visuals/{ilyra,bram}_visual.{gd,tscn}`,
  `scripts/resources/form_data.gd` + `form_catalog.gd`, `data/forms/{ilyra,bram}.tres` + catalog,
  `scripts/autoload/save_manager.gd`, `scenes/screens/shop_screen.{gd,tscn}`,
  `tools/art/{make_rig_source,extract_playable_characters}.py`,
  `tools/godot/{test_form_catalog,test_playable_character_visual,render_character_lineup,bench_character_previews}.gd`,
  `assets/art/characters/playable/{ilyra,bram}/`, plus the character, forms, Shop, ASSETS, GDD,
  ROADMAP and rig-recipe docs and ADR-0015's addendum.
- **Verified:** `validate.sh` OK; `form_catalog` and `playable_character_visual` pass (all 13 states,
  no collision in a rig, particle budget, skin weights, sizing, the real controller through every
  state with no per-frame snaps, Reduced Motion, both menus, a production GameWorld); full suite 25
  passed / 10 failed — the same ten documented stale-since-M10 scripts, which reference scenes and
  methods absent from committed HEAD, so no new regressions. Lineup, motion contact sheets and
  Shop/Home/GameWorld screenshots reviewed; `qa_matrix.sh shop_wisps` 5/5; preview benchmark 11 cold
  234 ms, warm ~8 ms, per-frame cost indistinguishable from baseline; real run through the Godot MCP
  and an Android debug build on the owner's SM-S921B, both with no errors.
- **Next:** the owner asked for properly separated Mythic parts so the rig can be a real `Bone2D`
  skeleton (shoulder/elbow/wrist on four arms, a twisting waist, fans that fold rib by rib,
  bending knees, blinks) with particle work. Wrote the art request for Codex at
  `concept_art/wisp_rush_playable_characters_v3/ART_REQUEST.md`: 66 Ilyra PNGs and 32 Bram PNGs,
  one part per file with a pivot manifest, Ilyra first and tested before Bram.
- **Follow-ups:** owner approval of the motion and prices (all 0 RP, and whether Legendary/Mythic
  should cost more); on a 120 Hz phone positions still step at the 60 Hz physics rate, which reads as
  judder for every character — enabling physics interpolation is a project-wide owner decision;
  pre-existing and unrelated, `game_world.gd` plays `&"pulse"` as an SFX but that id belongs to a
  music layer, so the finisher and run-end sounds are silently dropped (task chip raised); a couple
  of Ilyra's six skirt panels carry a hair-thin sliver of the neighbour they were painted touching;
  generated-art licence still required before sale.

## 2026-09-18 — Bram and Ilyra approved; sequential implementation handoff staged
- **Who:** Codex (GPT-5)
- **Did:** Designed two non-Wisp playable-character candidates without changing runtime code:
  Legendary **Bram, the Rift Knight** is a complete armored warrior with a restrained 13-group rig;
  after the owner liked Bram but rejected the fox direction, Mythic **Ilyra, the Astral Dancer**
  replaced it with a complete four-armed humanoid and about 34 independently moving groups. Discarded
  the rejected art. The owner then approved both active directions and requested Ilyra first, Bram
  second. Moved them into the versioned playable-character source pack and wrote the codebase-aware
  art, layer, animation, catalog/rarity, verification and documentation handoff plus a ready-to-paste
  Claude prompt.
- **Files/systems:** `concept_art/wisp_rush_playable_characters_v2/`, `docs/{ASSETS,GDD,ROADMAP}.md`.
- **Verified:** reviewed both native-resolution RGB/RGBA sheets for character consistency, mobile-scale
  silhouette and a clear complexity gap; `tools/validate.sh` → `VALIDATE: OK`; no gameplay files or
  catalog data changed.
- **Follow-ups:** Claude implements and verifies Ilyra completely before starting Bram; owner sets
  final prices after the 0 RP review/device pass; generated-art licence remains required before sale.

## 2026-09-18 — Characters dive, land on their feet and coil before a strike
- **Who:** Claude Code (Opus 5)
- **Did:** Owner, after the slow-motion clip: "create a dive animation that looks like the character
  is diving and slicing through enemies not just flying, make sure they land on their feet on the
  walls, and when the user presses the screen to attack when the arrow appears animation as
  pre-attack animation".
  - **Dive:** `dash_start` coils deeper and snaps into a blade profile; `dash_loop` is long and thin
    along the travel axis. Each rig knifes its side parts back (Veyra's fins, Rook's wings folded
    into a stoop, Morrow's hands) and streams its ribbons straighter.
  - **Feet on walls:** `WispPlayer` passes the inward normal of the wall it rests against and how
    near a dash is to its wall (`LANDING_WINDOW` 0.16 s). A resting character's up axis is that
    normal — it stands on the floor, sideways on a side wall and hangs from the ceiling — and a dash
    turns feet-first over the last moments of the flight, with each rig bracing (fins and wings
    forward, feet and hands dropping). Aim and drift lean relative to the wall, not screen-up.
  - **Pre-attack:** `aim_charge` is now a wind-up — the body coils back along its own axis and
    shivers while the arrow is up; Veyra's fins flare forward and her core charges, Rook cocks his
    wings high for a stoop, Morrow raises both hands and spins the runes in.
- **Files/systems:** `scenes/player/wisp_player.gd`, `scenes/player/visuals/*` (base + three rigs),
  `tools/godot/{render_character_motion,test_playable_character_visual}.gd`, system doc, ADR-0015,
  GDD §14 #31.
- **Verified:** `tools/validate.sh` OK; `test_playable_character_visual` passes with new assertions
  that the standing heading follows each wall normal and that a character is within 0.3 rad of
  standing after landing on the ceiling and on the floor. Re-rendered the 4× slow-motion clip
  (`WISP_MOTION_CLIP=1`, now with a real touch-and-hold aim before the first dash) and reviewed the
  aim coil, dive, kill accent, mid-dash turn and both landings frame by frame.
  - Wrote [guides/character_rig_recipe.md](guides/character_rig_recipe.md) so another agent can build
    a character from scratch: layer extraction and ribbon spines, the rig conventions, how the Bone2D
    chain and skinned Polygon2D actually work (rest poses, sibling meshes, weights summing to 1),
    `ChainSpring` tuning, the runtime state machine and heading springs, particles, wiring, the QA
    order, and a table of the mistakes this build already made.
  - Wrote [devlog_characters_episodes.md](marketing/devlog_characters_episodes.md): two shoot-ready
    devlog episodes (A "Three characters, one hitbox", B "They land on their feet") with hooks that
    repeat neither EP03's nor EP04's, beat tables, the new capture commands and the numbers that are
    safe to show; registered as EP06/EP07 in the episode table and linked from the brief.
- **Follow-ups:** device pass on the new dive and landings; the owner may want the landing window or
  the dive profile retuned per character. The two devlog episodes are shot one per request when the
  owner asks.

## 2026-09-17 — Playable characters: Veyra, Rook and Morrow (M13)
- **Who:** Claude Code (Opus 5), finishing Codex's prototype
- **Did:**
  - Owner: "codex has started working on adding new characters … find what he did, analyze, finish
    what he started, make sure the animations work and are smooth in the gameplay and also add
    animation in the character or wisp selecter and they are not just wisps but characters".
  - Found Codex's uncommitted Veyra prototype (rig, shared state machine, Shop/Home previews, save
    wiring, one test) plus the layer sheets it had already generated for **Rook and Morrow** — the
    owner had narrowed that session to one character, and it hit its quota mid-QA. No DEVLOG,
    registry, GDD or ADR entry existed for it.
  - Extractor now serves all three characters (`extract_playable_characters.py`: per-character cells,
    Veyra's halo split in two, printed ribbon spines, per-character contact sheets).
  - Rewrote the shared base ([playable_character_visuals.md](systems/playable_character_visuals.md),
    [ADR-0015](decisions/0015-animated-playable-characters.md)): squash and stretch on the travel axis
    (they were inverted, so dashes read as pancakes), a damped heading spring instead of a lerp, the
    uniform base size only (the controller's wall-impact squash no longer lands on the rig's rotated
    axes), one-shot interrupts, per-character squash/bounce strengths, `%FormImage` so single-image
    forms animate on the same rig, and `get_layer_bounds()` for sizing.
  - New `ChainSpring` (spring joints with lag, per-frame lag cap, travelling sway) and `RibbonChain`
    (skinned Polygon2D on its own Bone2D chain along the printed spine) — Veyra's tails and Morrow's
    scarves now bend instead of swinging as rigid cutouts.
  - Built **Rook** (wing beats → glide → fold, springy segmented tail, dangling feet, bone-white dash
    streaks and wing dust) and **Morrow** (breathing cloak, tilting mask, hands on independent orbits,
    three runes on a tilted ring that never crosses his face, trailing scarves, rune fragments and
    cloth wisps); rebuilt **Veyra** (skinned tails, split halo, blinks, core flare).
  - Selector: the Shop's WISPS tab is now **CHARACTERS** (also on Results, Home's tap target, the
    Statistics row and the debug unlock), every card animates, a focused or equipped card plays the
    selected flourish and a purchase the unlock flourish (the Shop diffs the save snapshot itself).
  - `WispPlayer` passes the real dash/drift/aim direction (the drift heading was stale, so a Frozen
    Choir slide faced the previous dash).
  - Fixed while checking phone layouts: a Shop whose snapshot arrives *after* it entered the tree
    (fixtures do that; Main sets up first) refreshed its text but left the carousel on the first card,
    so QA sheets showed one character with another's description. Its carousel now follows the
    equipped item until the player browses that tab.
  - Cost work after benchmarking nine live cards: animation libraries and the state machine are built
    once and shared by every rig, and `FormCatalog` caches loaded characters for the session. Building
    the CHARACTERS tab went from ~480 ms to 133 ms cold and ~8 ms warm; animating nine previews costs
    under 0.1 ms/frame (`tools/godot/bench_character_previews.gd`).
- **Files/systems:** `scenes/player/visuals/*` (7 scripts, 4 scenes), `scenes/player/wisp_player.*`,
  `scenes/gameplay/game_world.gd`, `scenes/screens/{shop,home,results,settings,statistics}_screen.*`,
  `scripts/resources/form_{data,catalog}.gd`, `scripts/autoload/save_manager.gd`,
  `data/forms/{veyra,rook,morrow}.tres` + catalog, `assets/art/characters/playable/*`,
  `concept_art/wisp_rush_playable_characters_v1/*`, `tools/art/{extract_playable_characters.py,motion_contact_sheet.py}`,
  `tools/godot/{render_character_*,test_playable_character_visual,test_form_catalog,test_m4_systems}`,
  docs (ADR-0015, system doc, forms/shop/game_flow/player_dash, GDD §3/§6/§9/§11/§13/§14 #31,
  PROJECT_CONTEXT, ASSETS, ROADMAP M13).
- **Verified:**
  - Live run through the Godot MCP server (Shop CHARACTERS tab): `[Shop] ready`, audio synthesized,
    no errors; the only warnings are the project's existing Variant-narrowing ones.
  - `tools/validate.sh` → `VALIDATE: OK`. `tools/run_tests.sh` → 25 passed, 10 failed; every failure
    is a pre-existing stale test (removed `FormsScreen`, `configure_run_profile`, `purchase_form`,
    `DevUnlock` signatures). `test_m4_systems` now reads Statistics rows by label instead of index,
    so it passes again.
  - New `test_playable_character_visual`: 13 states per character, no collision in a rig, ≤ 40
    particles, ribbon weights summing to 1, silhouette vs `design_size`, the real controller through
    spawn → dash → kill → redirect → landing → hit → victory → death with a per-frame snap check,
    Reduced Motion stillness, Home's live hero, the Shop's nine animated cards with both flourishes,
    and a production GameWorld per character.
  - Frame-by-frame review of `render_character_motion` sheets at 60 fps for all three. Fixed from it:
    a 0.3 s tumble when righting after a downward dash, tails splaying from that righting, a one-frame
    eye snap when a dash interrupted a blink, oversized soul sparks, Rook's second pair of eyes below
    the skull, Morrow's runes crossing his mask, and his hands covering it on a kill.
  - The smoothness check also caught a real bug: Morrow's rune counter-spin jumped once per orbit
    because the orbit angle was wrapped at 2π.
  - Looked at: lineup vs reference art, Shop CHARACTERS tab, Home with each character, and each
    character mid-dash in a real GameWorld. `tools/qa_matrix.sh shop_wisps`: the longer CHARACTERS
    label fits all five phone aspect ratios.
  - Fixed from the `gdscript-reviewer` pass: Reduced Motion changed mid-run now reaches the equipped
    rig (`WispPlayer.set_reduced_motion`), a dash kill on the fatal frame can no longer cut the death
    animation, a hidden rig stops processing entirely (the Shop keeps cards in the tree while another
    tab shows), `ChainSpring`'s lag cap became a rate so the whip matches at 30/60/120 fps, a cleared
    ribbon no longer leaves its spring on freed bones, and Veyra's hot path lost its per-frame array
    literals.
- **Follow-ups:** unrelated: a headless boot reports one leaked `RefCounted` (refcount 0) at exit
  even with no character rig loaded — engine-side, worth a look sometime. Owner review of the look and
  motion, then prices (all three are 0 RP); device pass
  (readability at gameplay size, particle cost, 120 Hz feel); optional mipmaps for character layers
  (import-setting decision) and physics interpolation for 120 Hz phones; art licence before selling
  characters (GDD §14 #1, #21); the ten stale tests still need the owner's cleanup call.

## 2026-09-17 — M10–M12 and devlog work committed; agent docs refreshed
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner: "analyze the project and read agent related files, then commit, push and merge to main". Committed the uncommitted M10 (story Rifts, Endless, Rift Points Shop), M11 (RUSH), M12 (Tutorial) and devlog video work on `feat/m10-m12-story-endless-rush-tutorial`, then merged it into `main`.
  - Stopped tracking Python bytecode: `__pycache__/` and `*.pyc` are ignored; three old cpython-37 caches were untracked.
  - Refreshed stale agent-facing facts:
    - PROJECT_CONTEXT §2 said "Next: spec 02", save v6 and 33 tests; now specs 01–05 done, save v8, 34 tests;
    - §3 tools tree; §4 autoload sentence; §5.1 Rifts and Endless rows; §5.8 `BossData` row (missing), `ReaperTuning` instances and `EconomyTuning` clear bonuses; §8 Endless;
    - AGENTS.md: git rules are CONVENTIONS §12, not §11;
    - `new-system` skill: resources are named `*_tuning.gd` / `*_data.gd` / `*_catalog.gd` (no `*_config.gd` exists);
    - ROADMAP M10: the Endless skin art item is done (30 skins).
- **Files/systems:** `.gitignore`, `AGENTS.md`, `.claude/skills/new-system/SKILL.md`, `docs/{PROJECT_CONTEXT.md,ROADMAP.md,DEVLOG.md}`.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (89 scripts checked, main booted) before the first commit; no secrets, key files or files near GitHub's size limit in the commit (largest ≈ 2.8 MB); the repo on GitHub is public. Tests not run (owner's standing call).
- **Follow-ups:** the stale headless tests (11 failed on 2026-09-15) and the M10–M12 device pass are still open.

## 2026-09-17 — Devlog #4 "Four tricks for one swipe"
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner: "create the next devlog". Built EP04 (49.0 s, structure C, game feel) in the new Palmier project "Wisp Rush Devlog 04 - One Swipe Feel".
  - Hook: H9 numbered promise ("Four little tricks make one swipe feel this good.") plus an open loop ("Number four almost broke my game."), with the payoff-first treatment: an 8-kill line lit at half speed under a giant "4", then the slice. Neither the idea nor the treatment repeats EP03 (hooks §6 log).
  - The four tricks, each on a stone step card that parks top-left:
    1. aim rings with the ×3 count (arrow sweep);
    2. AIM ASSIST off (×2) then on (×3), "≤ 6°", "only if it hits more";
    3. the slow-motion finisher on a five-kill diagonal, "TIME ×0.3";
    4. RUSH in a free-play run with 6 s / ×1.3 / ×2 / no-damage pills.
  - The RUSH bug (DEVLOG 2026-09-15) explained on the grid: the timer drains to 0.0 s, `rush_time = 0` runs before `end_rush()`, which "thinks RUSH is over… skips!", the meter stays full, "RUSH ×2 ×3 ×4 ×∞". The fix swaps the two code cards, then the meter empties first and the timer after. Then the AI credit, the four step cards with "bug included", the question and the follow card.
  - New fixture `tools/godot/render_feel_showcase.gd` (scripted, repeatable feel shots in a quiet tutorial arena; the event log marks shots, releases and kills). New `devlog_graphics.py` commands `code` and `meter`, bar colours, step icons `target` / `bend` / `slowmo`, and step labels that shrink to fit. Documented in the README, recipe §3.1 / §5 and PROJECT_CONTEXT §6.
- **Files/systems:**
  - Tools: `tools/godot/render_feel_showcase.gd`, `tools/video/{devlog_graphics.py,README.md}`.
  - Docs: `docs/marketing/{devlog_hooks.md,devlog_video_recipe.md}`, `docs/PROJECT_CONTEXT.md`.
  - Workspace (git-ignored): `video/{footage/ep04_*,voice/ep04,graphics/ep04}`.
- **Verified:**
  - Script claims match the code: `aim_assist_degrees` 6, `finisher_kills` 5, `finisher_time_scale` 0.3, RUSH 6 s / ×1.3 / ×2 / immunity, and the fix order in `GameWorld._update_rush` / `_end_rush`.
  - Captures: the first assist take showed no difference (a 5° offset still hit all three), so the fixture now searches 3°–14° for a drag the assist improves; the retake lights 2 without the assist and 3 with it.
  - Voice lines checked with Palmier transcription: "Four tricks" was heard as "For treks", "Hold to aim" as "One hole", "hit zero first" as "01st", "Full meter? RUSH again." as "We'll meet a rush"; all four lines were reworded and the take re-voiced clean.
  - Composited frames checked across the cut. Fixes: a Wisp cut off in the hook push-in, big "×3 / ×2" echoes of the tiny in-game count, "TIME ×0.3" and "FIXED" moved off the captions and header, duplicate captions under kinetic text removed, and a wrapped last caption split in two.
  - First export peaked at −1.4 dBTP where a step SFX and RUSH footage audio stacked (f2172); after lowering both: −14.5 LUFS, −2.3 dBTP. Export `video/exports/wisp_rush_devlog_04_four_tricks_one_swipe.mp4`: H.264 1080×1920 60 fps, AAC 48 kHz, 49.0 s; watched back in Palmier, and the transcript matches the script.
- **Follow-ups:** owner review of EP04. EP05 only when asked, with a hook idea and treatment EP04 didn't use. Disk space is low (~4 GB free): delete captures after transcoding.

## 2026-09-16 — Devlog #3 "30 new arenas" and the hook library
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner asked for the next devlog, about the 30 new arenas. Built EP03 (51.0 s, structure B) in the new Palmier project "Wisp Rush Devlog 03 - 30 New Arenas":
    - the hook (below), then a montage under "30 NEW ARENAS";
    - "4 TIERS" cards (10 Simple, 10 Rare, 5 Legendary, 5 Mythic), and the first effects as a sticker strip ("shapes on top?");
    - "DIDN'T MATCH THE ART", and MYTHIC struck through;
    - the version-2 light-map explainer from a real scenery mask, then Legendary punch-ins with tier pills;
    - shop carousel, the three Mythic set pieces (a ring on the dragon's glowing throat), and the fair-floor outline over three arenas ("SAME FLOOR ×30", "LOOKS ONLY.");
    - the build-size board (45 MB → 3.7 MB, 12× smaller), a Starforged run with the AI pill, "WHICH ARENA WOULD YOU PICK?" over a Dragon Skull run, and the follow card.
  - Owner: "not every video shall have that comment hook". Recipe §1 now rotates hooks; EP03 opens on a before/after glow-up wipe.
  - Owner then sent three hook-teaching TikToks. They were downloaded to `video/references/hook1–3.mp4` and watched to the end in Palmier. The result is the new hook library [docs/marketing/devlog_hooks.md](marketing/devlog_hooks.md):
    - the context → lean → snapback test;
    - ten spoken hook ideas (templates paraphrased) with true Wisp Rush lines and topic picks;
    - what not to copy (their look, their CTA);
    - a hook log.
  - Recipe §0/§1/§2/§3.1/§4/§5/§10, the `devlog-video` skill, AGENTS.md 5c and PROJECT_CONTEXT point to it.
  - EP03's opening went through three versions:
    1. A glow-up wipe.
    2. A library re-hook: "My arenas just got a huge glow-up. But one thing never changed."
    3. The owner asked again: "the hook, the opening… use one idea from the hook ideas I have given you". It now uses H2, the never-again warning from HOOK-A: "Never, ever draw effects on top of your game art. I learned that the hard way."
  - How the final opening plays: "NEVER," / "EVER." slam in on black. Then the old sticker effects appear with rings and a red strike, and a hurt-Wisp joke beat follows. The warning pays off at "my first effects were just shapes, drawn on top of the painting", now marked "never do this!".
  - The library now requires one recognizable idea per episode (H1–H9). The triple hook stays as the §2 check only.
  - New fixture `tools/godot/render_arena_showcase.gd` (Endless skins back to back with a held start, so no enemies spawn; `segment_start` / `segment_end` events). New `devlog_graphics.py` commands: `tier`, `outline`, `lightmap`, `crop`. Documented in the README, recipe §5 and PROJECT_CONTEXT §6.
- **Files/systems:**
  - Docs: `docs/marketing/{devlog_hooks.md (new),devlog_video_recipe.md}`, `.claude/skills/devlog-video/SKILL.md`, `AGENTS.md`, `docs/PROJECT_CONTEXT.md`.
  - Tools: `tools/godot/render_arena_showcase.gd`, `tools/video/{devlog_graphics.py,README.md}`.
  - Workspace (git-ignored): `video/{references/hook1–3,footage/ep03_*,voice/ep03,graphics/ep03}`.
- **Verified:**
  - Every beat of the composited timeline was checked with `inspect_timeline` and full-res `capture_frame`. Fixes:
    - the empty top of the tier grid (headline added);
    - the strike line hidden behind MYTHIC;
    - captions over the shop card and over the floor-outline edges.
  - Voice lines were checked with Palmier transcription:
    - "But one thing didn't change at all." was heard as "The one thing…", so it was reworded to "But one thing never changed.";
    - line 2 was voiced several ways: every take that opened with or led into "Wisp Rush" was heard as "Wisp Brush" or "Wisp rushes", and even the older good take lost "Wisp" once it followed a sentence break. The line is now "Thirty new arenas are now in Wisp Rush.", timed so the "30" pops on "Thirty".
  - In the first export, the montage whoosh and an accent sat about 8 dB over the soft start of the next word. The whoosh now leads into the cut, and the accent is at −20 dB.
  - Export `video/exports/wisp_rush_devlog_03_30_new_arenas.mp4`: H.264 1080×1920 60 fps, AAC 48 kHz, 51.0 s, −14.6 LUFS, −2.7 dBTP. Watched back in Palmier: the storyboard and transcript match `video/voice/ep03/ep03_final_script.txt`.
- **Follow-ups:** owner review of EP03. EP04/EP05 only when asked; they must pick a hook idea and a visual treatment EP03 didn't use (hooks §6). `tour=story` capture is still untested.

## 2026-09-16 — Devlog video recipe for every agent (EP02 approved)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - The owner approved Devlog #2 and asked for it to be written up so other agents can make videos the same way. Reverse-engineered the final EP02 timeline into [docs/marketing/devlog_video_recipe.md](marketing/devlog_video_recipe.md): owner rules, the four references and what to take from each, three story structures with beat timings, script rules and the EP02 script, piece-making, the Palmier track stack, an element cookbook with EP02's exact values, motion/text/caption/sound rules with an SFX map, QA/export/watch-back steps, gotchas and a frame map.
  - `tools/video/palmier_motion.py` (pop, tap ring, custom keyframe rows, image sizes, `fit-text` font sizes; it reproduces EP02's keyframes exactly). New Claude Code skill `devlog-video`. `tools/video/README.md` is now commands only (style moved to the recipe; one export serves TikTok and Shorts). Pointers in AGENTS.md (§1 5c, §4), CLAUDE.md, PROJECT_CONTEXT §6/§7.1 and the brief.
  - Export renamed to `video/exports/wisp_rush_devlog_02_why_buttons_froze.mp4` (approved).
- **Files/systems:** `docs/marketing/{devlog_video_recipe.md,devlog_video_brief.md}`, `tools/video/{palmier_motion.py,README.md}`, `.claude/skills/devlog-video/SKILL.md`, `AGENTS.md`, `CLAUDE.md`, `docs/PROJECT_CONTEXT.md`.
- **Verified:** `palmier_motion.py` output matches the EP02 timeline keyframes (step card, tap ring, comment card, logo, sticker) and `fit-text` gives the sizes EP02 uses; `tools/validate.sh` → OK. Docs only otherwise.
- **Follow-ups:** EP03–EP05 when the owner asks (one per request); `tour=story` capture still untested; EP01 predates the recipe (owner to decide whether to remake it).

## 2026-09-16 — Devlog #2 "Why every button froze" and the devlog style guide
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner set a new style for all devlogs from four reference TikToks (downloaded to `video/references/`, watched to the end in Palmier): open on a viewer comment, explain problems with motion graphics, show before / why / after briefly, charisma, under 60 s, stock footage allowed. Recorded as the style guide in [tools/video/README.md](../tools/video/README.md); the owner asked for one test video first, one Palmier project per episode.
  - Owner picked the topic "why buttons froze". Built EP02 (43.7 s) in the new project "Wisp Rush Devlog 02 - Why Buttons Froze": comment card (second Kokoro voice `af_heart`) → frozen Home with frost → "WHY?" beat → frame-strip explainer with a growing red freeze bar → "576 MS" → logo frost gag → "cover first, build later" with stone step cards over the real Home/Shop and the run loading screen → numbers board (576 → 0 ms, 271 → 0 ms, "measured on a Mac") → Aurora Throne RUSH footage → AI credit → question → follow card.
  - New tools: `tools/godot/export_game_audio.gd` (the game's synthesized SFX and music as WAVs for sound design) and `tools/video/devlog_graphics.py` (comment card, grid, frame strip, freeze bar, taps, marker arrows, frost, step cards).
- **Files/systems:** `tools/godot/export_game_audio.gd`, `tools/video/{devlog_graphics.py,README.md}`; workspace `video/{references,audio,graphics,voice/ep02,exports}/` (git-ignored).
- **Verified:** export `video/exports/wisp_rush_devlog_02_why_buttons_froze_draft1.mp4`: H.264 1080×1920 60 fps, AAC 48 kHz, 43.7 s; the first render peaked at +1.0 dBTP (Kokoro voices peak near 0 dBFS), fixed by mastering both voices (README step 3) → −14.6 LUFS, −2.6 dBTP. Watched back in Palmier: storyboard and transcript match the script. Composited frames checked across the cut; oversized headlines (Palmier sizes text ~1.78× PIL) resized, captions moved off the tapped PLAY button.
- **Follow-ups:** owner review of EP02 (and EP01 draft 1); if approved, EP03–EP05 follow the guide; `tour=story` capture still untested.

## 2026-09-16 — Devlog capture tours and the EP02–EP05 plan
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner asked for 3–4 TikTok/YouTube devlogs from `docs/marketing/devlog_video_brief.md`, then paused production for a plan review. Four episodes planned in [tools/video/README.md](../tools/video/README.md): EP02 arenas, EP03 dash feel, EP04 two modes, EP05 menu freezes. Nothing edited yet.
  - The capture bot moved out of `render_gameplay_clip.gd` into `tools/godot/devlog_bot.gd`, shared with the new `tools/godot/render_devlog_tour.gd`, which drives the real `Main` through a scripted tour (`menus`, `story`) on its own isolated save (`user://test_runs/devlog_tour*.json`). New bot option `dash_speed` (on a duplicated `PlayerTuning`) for before/after shots; `quality` sets the MJPEG quality.
- **Files/systems:** `tools/godot/{devlog_bot,render_gameplay_clip,render_devlog_tour}.gd`, `tools/video/README.md` (also replaced its stale "Endless skin is placeholder art" capture note).
- **Verified:** all three scripts pass `--check-only`. `tour=menus skin=aurora_throne` recorded 50.9 s (`video/footage/tour_menus.mp4`, contact sheet reviewed): boot, Rift Map, Shop WISPS/DASHES/ARENAS to the Mythic cards, run loading screen, an Aurora Throne run with an 8-kill dash, a ×30 chain, RUSH and the Hollow Choir arriving. The run loading screen never reports "not navigating", so the tour's wait timed out (footage unaffected); it now waits for that screen unsettled. That fix and `tour=story` have not run yet.
- **Follow-ups:** owner approval of the plan and feedback on Devlog #1 draft 1; then captures (Mythic runs on starforged_citadel and dragon_skull_throne, a same-seed 4,400 vs 3,960 px/s pair, the story tour), voiceovers and edits.

## 2026-09-16 — Devlog video brief for the marketing agent
- **Who:** Claude Code (Opus 5)
- **Did:** Owner asked for one file another agent can track this session from and cut TikTok/YouTube devlogs against. Wrote `docs/marketing/devlog_video_brief.md`: the session story, the nine filmable features in priority order, safe on-screen numbers (navigation 271/576 ms → 0 ms at the tap, arena art 45 MB → 3.7 MB, 24/30 skins pass the checker), capture commands (adb screenrecord, screenshot.sh, render_*_showcase, qa_matrix, the before/after scenery sheets), branding asset paths, hard publishing rules (never call the art hand-made, never use the fake-controls key art, no release date or store claims, monetisation is disabled), known rough edges to avoid filming, and three suggested videos.
- **Files/systems:** `docs/marketing/devlog_video_brief.md` (new), PROJECT_CONTEXT §7.1 row.
- **Verified:** links checked against existing docs; no code touched.

## 2026-09-16 — No navigation freezes: cover-then-build, run prewarm, image loading screen
- **Who:** Claude Code (Opus 5)
- **Did:** Owner (Galaxy S24): PLAY and other buttons froze. Main now covers first and builds later: every navigation starts a 0.12 s void-charcoal veil at the tap, builds the next screen under it (latest request wins, presses swallowed), lets it draw 2 frames covered, then lifts with the glide. PLAY / Rift Map ENTER prewarm the run beneath the run loading screen (`GameWorld.hold_start/warm_up_render/release_start`, `PROCESS_MODE_DISABLED` while hidden; loading screen on the internal `LoadingCover` CanvasLayer 99 so it draws over the run) and reveal that run when the bar completes — no instantiate after the bar. Fixed the switch timing stamp (the boot LoadingScreen measured from the previous switch); the log now reports build · tap to revealed · worst frame. Rift and form data stay loaded after boot. Shop ARENAS builds thumbnails + scenery materials lazily (focused ± 2, shared per scenery), active tab only. Loading screen redesigned: random painted background (5 Rifts, Home, menu) with Ken Burns drift, gradient scrim, logo + arena heading, `LOADING...` with animated dots over a full-width ProgressBar (Reduced Motion: still).
- **Timings (desktop, 540x1170 window, blocking at tap → after):** Rift Map 271.5 → 0 ms (build under veil 7.5 ms); Shop ARENAS 27.0 → 0 (build 16.1); Trials 36.2 → 0 (38.4); Home 11–44 → 0 (1–6); PLAY 575.8 ms blocking, GameWorld 71 ms + 73.5 ms worst frame after the bar → 0 ms at tap, run build 1.7 ms + add/ready/warm 48–58 ms behind the loading screen, reveal worst frame 9.6 ms. Every change now settles tap → revealed in ~425–460 ms. Device before: GameWorld ready 270.9 ms + 196.5 ms worst frame (first run) after the bar — remeasure on device.
- **Files/systems:** `scenes/main/main.gd`, `scenes/gameplay/game_world.gd`, `scenes/screens/loading_screen.{gd,tscn}`, `scenes/screens/shop_screen.gd`, `tools/godot/test_screen_transitions.gd`; docs `game_flow.md`, `core_run.md`, `shop.md`.
- **Verified:** `tools/validate.sh` → OK; `test_screen_transitions` and `test_game_flow` pass; run loading screenshot at 540x1170 checked (the first capture showed the prewarming arena drawing over the loading screen — fixed with the cover layer).
- **Follow-ups:** device check of first-run GameWorld pipeline compilation behind the loading screen; Results after a run end still banks synchronously (~30 ms) before its veil.

---

## 2026-09-16 — Run loading screen for PLAY and Rift Map ENTER
- **Who:** Claude Code (Opus 5)
- **Did:** Owner asked for a loading screen when pressing PLAY or entering a Rift. `LoadingScreen.begin_run(paths, heading, subheading)` reuses the boot screen (logo, glow, progress bar) with the arena's name — `ENDLESS` + the equipped skin, or `<RIFT>` + `LEVEL n` — loads the Endless background on a worker thread and stays up at least `RUN_MIN_SECONDS` (0.9 s). Only Home PLAY and Rift Map ENTER use it; restart, PLAY AGAIN / NEXT LEVEL / RETRY on Results and the daily run keep the instant path (GDD §2 immediate momentum).
- **Files/systems:** `scenes/screens/loading_screen.{gd,tscn}`, `scenes/main/main.gd`.
- **Verified:** `tools/validate.sh` → OK.

## 2026-09-16 — Stale export cache after the scenery rebuild
- **Who:** Claude Code (Opus 5)
- **Did:** The first APK after the arena scenery rebuild logged 40 load errors on the phone: 20 Simple/Rare skin resources still referenced the deleted `arena_ambience_effect.gd`. The repo files were correct; Godot's export cache (`.godot/exported/`) had reused binary conversions from the previous build. Cleared that cache, rebuilt, confirmed no exported resource references the old script, reinstalled: Home boots with 0 errors. **After deleting or renaming a Resource script, clear `.godot/exported/` before exporting.**
- **Verified:** device boot log clean (Galaxy S24).

## 2026-09-16 — Endless scenery rebuilt on the painting (Legendary/Mythic)
- **Who:** Claude Code (Opus 5)
- **Did:** Owner device feedback 2026-09-15 ("effects do not look good — more vibrant; Mythic shall be felt"). Replaced the code-drawn circles/bands with layers that use the painting: `tools/art/endless_scenery.py` (per-skin `SCENERY` table) writes 471×836 RGBA masks (R light sources by brightness/top-hat/hue rules in tunable rects, G distortion regions, B floor weight across the rim tolerance, A zone ids) and floor-clear particle emission points; `arena_scenery.gdshader` grades scenery (saturation, contrast, split-tone lift; floor only a luminance-kept saturation lift), animates emissive zones (breathing, flicker, flares, colour cycling, twinkle, travelling pulses), distorts G (ripple/shimmer/wave/roil) and draws CORONA/SWIRL set pieces, light sweeps and shooting stars in one pass; `ArenaAmbience` drives time values (pausable) and mask-gated CPUParticles2D.
- Mythic set pieces: eclipse corona rays + flares + god-ray sweep + ash; starforged turning galaxy + shooting stars + light falls; abyssal portal swirl + seam/rune pulses + chain glints + motes; aurora waving colour-shifting aurora + torch flicker/haze + snow; dragon flaring eye sockets + throat fire + heat shimmer + embers/smoke. Legendary: 2–3 calm touches each (storm_anvil soft bolt flashes ≥ 6 s apart).
- Removed `ArenaAmbienceEffect` and every drawn-shape kind; `ArenaSkinData.ambience` → `scenery`, `ArenaRules.get_ambience()` → `get_scenery()`; Shop ARENAS thumbnails use the static grade + glow material; `EndlessCatalog.validate_scenery()` (centres, streak regions, emission points + drift paths, mask floor ≈ 0).
- **Files/systems:** `assets/shaders/arena_scenery{,_particles}.gdshader`, `scripts/resources/{arena_scenery_data,arena_scenery_zone,arena_particle_emitter,arena_skin_data,endless_catalog}.gd`, `scenes/gameplay/{arena_ambience,arena_rules,endless_arena_rules,game_world}.gd`, `scenes/screens/shop_screen.gd`, `assets/art/environment/endless/masks/`, `data/endless/skins/*.tres`, `tools/art/{endless_scenery,make_endless_skin_data,set_endless_import_lossy}.py`, `tools/godot/{render_endless_scenery_sheet,test_endless_catalog,qa_capture}.gd`; docs endless_mode, ASSETS, PROJECT_CONTEXT §5.8, GDD history.
- **Verified:** `tools/validate.sh` → OK; `run_tests.sh endless_catalog` → PASS. Real-run sheets (3 frames ~0.7 s apart × 10 skins, 540×1170): `logs/endless/scenery_round0_before.png`, `scenery_round1.png`, `scenery_round2.png`, `scenery_round3.png`; close-ups `scenery_detail_mythic_top.png`, `scenery_detail_mythic_bottom.png`; mask preview `scenery_masks_preview.png`; `logs/qa/endless_aurora_throne_sheet.png` (5 phones). Floor luminance identical before/after on all 10 skins (sheet stats), floor saturation +2–5 %, scenery saturation ≈ ×1.5–2; nothing over the floor; Wisp brightest small object. Round 1 caught a double texture multiply (canvas `COLOR` already holds the texture) that darkened everything.
- **Follow-ups:** device pass for look and cost (full-screen shader + ≤ ~100 CPU particles on Mythic); top set pieces sit partly behind the HUD score box; the rim band takes part of the grade (warmer dragon rim) — owner to judge.

## 2026-09-15 — Thirty Endless arena skins wired, animated Legendary/Mythic scenery
- **Who:** Claude Code (Opus 5)
- **Did:** Spec 05 finished for all 30 skins (owner decisions 2026-09-15). `make_endless_skin_data.py` generates the 30 `ArenaSkinData` (manifest names/descriptions, tier, prices 0/800/1,200 then 300/800/2,000/3,500 by tier, Palette accents, no placeholders) and the catalog. Backgrounds now load lazily (`background_path`) and the Shop uses 282×502 thumbnails, so boot and the ARENAS carousel never hold 30 full textures. New `ArenaAmbienceEffect` + `ArenaAmbience`: code-drawn glows, corona ring, flicker, mist, motes, twinkling stars, aurora and soft lightning (≥6 s apart) anchored to painted features on the 5 Legendary (light) and 5 Mythic (rich) skins, validated to stay outside the floor + 48 px; Reduced Motion keeps still glows; also shown on Shop cards. Save ids for 30 skins; tier shown on cards.
- **Checker:** 24/30 pass all metrics (coverage 0.884–1.000, luminance ×0.28–×0.91, props 0); 6 flagged only by the rim heuristic (fungal_hollow 0.718, library_of_echoes 0.927, galleon_wreck 0.400, eclipse_sanctum 0.922, abyssal_gate 0.517, aurora_throne 0.737), all eye-approved.
- **Import size:** 30 backgrounds lossless 47,051,268 B (44.9 MiB) → lossy q0.8 3,911,522 B (3.7 MiB); thumbnails 577,684 B lossy (≈4.8 MB lossless); uids unchanged (`set_endless_import_lossy.py`, owner-approved exception).
- **Files/systems:** `scripts/resources/{arena_skin_data,arena_ambience_effect,endless_catalog}.gd`, `scenes/gameplay/{arena_ambience,arena_rules,endless_arena_rules,game_world}.gd`, `scenes/screens/shop_screen.gd`, `scripts/autoload/save_manager.gd`, `data/endless/**`, `assets/art/environment/endless/**`, `tools/art/{extract_endless,make_endless_skin_data,set_endless_import_lossy}.py`, `tools/godot/{test_endless_catalog,render_endless_skins_sheet,qa_capture}.gd`; docs endless_mode, shop, tutorial, ASSETS, GDD §6/§14 #19 #26, ADR-0014 addendum, PROJECT_CONTEXT §5.8, ROADMAP M6/M10, spec 05.
- **Verified:** `tools/validate.sh` → OK; `run_tests.sh endless_catalog` → 1 passed; also passed challenge_tracker, screen_transitions, monetisation, game_flow. Already stale, unrelated (removed FormsScreen / `purchase_form`): save_manager, main_progression_flow, menu_screens, progression_screens, rift_points_text, screen_setup_order. Real renders: `logs/endless/run_sheet_{1,2}.png` (all 30 at 540×1170) and `logs/qa/endless_{astral_observatory,storm_anvil,aurora_throne}_sheet.png`: rim at the wall, Wisp on the edge and brightest small object, nothing over the floor.
- **Follow-ups:** device pass (rim, lossy quality, ambience cost); HUD text over bright top scenery on quartz_grotto/slate_cliffs/dusk_sandstone; confirm generated-art licence; update the stale tests.

## 2026-09-15 — Thirty Endless arena source skins
- **Who:** Codex (built-in ImageGen)
- **Did:** Generated all 30 cosmetic Endless arena backgrounds from the owner's skin prompt and exact playable-floor layout. Rebuilt late Mythic floors and cleaned the fungal, market and anvil drafts against the 50% playfield guide; exported one distinct 941×1672 opaque RGB PNG per skin and `skins_manifest.json` (Simple/Rare/Legendary/Mythic: 10/10/5/5). Source art only; no generated runtime PNGs, skin data or gameplay were changed.
- **Files/systems:** `concept_art/wisp_rush_endless_v1/{SKIN_SET_PROMPT.md,assets/}`, `docs/ASSETS.md`; Endless visual source pack.
- **Verified:** 30 unique PNGs, exact filenames/dimensions/RGB and tier counts; all art compared to `floor_template_guide.png`; `tools/validate.sh` → `VALIDATE: OK` (85 scripts checked, main booted). `tools/run_tests.sh` → 22 passed, 11 failed in existing stale tests that reference removed Forms/progression APIs or old screen expectations; none consume these source files. Godot MCP unavailable; no runtime art integration or in-game visual pass yet.
- **Follow-ups:** Run spec 05's art checker/extraction and wire all 30 skins (01–03 still have placeholders; 04–30 need data/prices) before shipping; confirm generated-art release licence; update the 11 stale tests separately.

## 2026-09-15 — Tappable UPGRADE button
- **Who:** Claude Code (Opus 5)
- **Did:** Owner missed an indicator after the tray simplification (the UPGRADE READY pill had been removed) and chose a tappable button. `%UpgradeButton` (IconButton, 11_upgrades icon, "UPGRADE" caption, amber ×N when several are banked, pulse from `RunProgressionTuning.button_pulse_*`) sits under the pause button while a level-up is banked and the cards are not up; tapping opens the cards immediately. Calm-moment auto-open is unchanged.
- **Verified:** `tools/validate.sh` → OK; temporary smoke (hidden when nothing banked, visible when banked, tap opens the tray, hidden while it is up) 4/4, deleted.

## 2026-09-15 — Upgrade cards raised
- **Who:** Claude Code (Opus 5)
- **Did:** Owner: the cards sat too low. New `RunProgressionTuning.tray_raise_share` (0.1 — first tried 0.2, owner: "not that high"): the tray's bottom edge rests 10 % of the screen height above the bottom safe margin (plus the tutorial lift), still sliding up from below.
- **Verified:** `tools/validate.sh` → OK.

## 2026-09-15 — Upgrade tray simplified to cards and a timer
- **Who:** Claude Code (Opus 5)
- **Did:** Owner: "don't make the UI that complex, just cards and timer". Removed the tray's frame (TrayPanel is a plain MarginContainer) and its "CHOOSE AN UPGRADE" / "SWIPE TO KEEP PLAYING" header, and the HUD UPGRADE READY pill (scene nodes, layout, pulse, `indicator_pulse_*` tuning). The three cards, the draining timeout bar, banking, calm moments, slow motion and swipe/timeout dismiss are unchanged.
- **Files/systems:** `scenes/gameplay/{upgrade_tray.tscn,upgrade_tray.gd,game_world.gd,game_world.tscn}`, `scripts/resources/run_progression_tuning.gd`, `data/progression/default_run_progression.tres`; docs GDD §5.5, mutations, core_run, tutorial, ui_design_system.
- **Verified:** `tools/validate.sh` → OK.

## 2026-09-15 — TikTok devlog pipeline and Devlog #1 draft
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner wants TikTok devlogs edited in **Palmier Pro** through its MCP server (registered locally as `palmier-pro`, `http://127.0.0.1:19789/mcp`), footage recorded by the game itself, a young male **Kokoro** voice, and "game first, open about AI". Workflow and house style: [tools/video/README.md](../tools/video/README.md).
  - `tools/godot/render_gameplay_clip.gd`: a bot plays a real Endless or Rift run (aim arrow held before multi-kills, redirects, Soul Fragment refills) while MovieWriter records 1080×1920 @ 60 fps with game audio, plus a JSON-lines event log (multi-kills, RUSH, boss, hits, upgrades) to cut to. (The parallel upgrade-tray session repointed it at `UpgradeTray`.)
  - `tools/video/kokoro_tts.py`: offline Kokoro voiceover (kokoro-onnx 0.6.1 in a git-ignored venv, models ~380 MB, owner-approved download) with per-line timings and an exact-timing SRT; Palmier's own transcription put captions 0.4–0.8 s early on Kokoro audio.
  - Devlog #1 "One swipe" (25.6 s) edited in Palmier project "Wisp Rush Devlogs": 12 shots from Ember Hollow, Obsidian Garden (Reaper), Frozen Choir and the Home screen, punch-ins, synced captions, series tag and follow card. Footage predates the upgrade tray (it shows the old paused card picker only outside the chosen shots).
- **Files/systems:** `tools/godot/render_gameplay_clip.gd`, `tools/video/{kokoro_tts.py,README.md}`, `.gitignore` (`/video/`, `/tools/video/.venv/`, `/tools/video/models/`), `docs/PROJECT_CONTEXT.md` §3/§6.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; captures ran without script errors (Obsidian Garden L1 cleared by the bot in 87 s); voiceover pronunciation checked through Palmier transcripts; composited timeline checked with `inspect_timeline`; export `video/exports/wisp_rush_devlog_01_one_swipe_draft1.mp4` probed: H.264 High 1080×1920 60 fps, AAC 48 kHz, −16.7 LUFS, −0.9 dBTP. No tests run (tooling only).
- **Follow-ups:**
  - Game bug found in capture logs: the slow-motion finisher and one more RUSH path call `SoundFx.play(&"pulse")`, which is a music layer, not one of the 18 SFX ids (`[Audio] unknown SFX id: pulse`; `game_world.gd:3009` finisher and `:3125`), so they play no sound.
  - Story Rift level 1 leaves the arena empty for ~20 s between waves when enemies die fast (Obsidian Garden 3–24 s, Ember Hollow 12–27 s) — Endless got continuous spawns, story levels did not.
  - The default Endless skin shows a baked "PLACEHOLDER - NOT FOR RELEASE" label; devlog footage uses story Rifts until real skins land.
  - Owner review of Devlog #1 (voice, pacing, captions) before posting.

## 2026-09-15 — Banked upgrades and the slow-motion card tray
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner: upgrades came too fast and cut the player off (the paused picker opened mid-combo). Owner decisions, not assumptions: GDD §5.5 upgrade offer rules; build choices are ASSUMPTION #30.
  - **Banking.** Level-ups never interrupt; `RunProgression.get_banked_levels()` counts thresholds covered (capped by mutation levels left). HUD `%UpgradeReady` `PanelPlate` pill ("UPGRADE READY", amber ×N) right of the XP strip; pulse off under Reduced Motion.
  - **Calm moments.** Wave start (not boss waves), boss beaten after the victory beat, field clear; each opens a 4 s window; the tray opens when banked, free play, no boss pending/alive/beat, no RUSH, not paused, run live, Wisp waiting, combo 0. A shown moment is spent, so dismissed cards return only at the next one.
  - **No pause.** New `UpgradeTray` (`scenes/gameplay/upgrade_tray.*`, replaces and deletes `scenes/screens/upgrade_select.*`): bottom default panel, header, `SlimProgressBar` timeout, three `CardButton`s; slides in real time. GameWorld holds the new keyed `_hold_time_scale(&"upgrade_tray", 0.3)` (released by `_release_time_scale`; pause, run end, scene exit and `_reset_view_effects` clear holds). Tap → one `apply_choice`, next banked set slides in or tray leaves; any dash dismisses (level banked); 6 real s timeout; pause suspends and Resume restores; boss start and run end close it. No `get_tree().paused` for upgrades anymore; finishers and RUSH wait for the tray. Tuning in `RunProgressionTuning` (Upgrade offer).
  - **Tutorial lesson 7.** Captions "Kills fill XP. Level-ups wait for a calm moment, then cards slide up." / "Reap the souls. When the cards slide up, tap one."; new `demo_upgrade_tap` fills the bar, requests the lesson calm moment and the ghost hand really taps a card (`TutorialGhostHand.play_tap`, real time; hand moved to a new HandLayer 11 above the HUD); the try requests calm moments again after a swipe/timeout and shows one dimmed hint tap; tray lifted above the caption band (`set_upgrade_tray_lift`). Catalog: `demo_card_look_seconds`, `demo_card_index`, `demo_tray_wait_limit`.
  - Stale tools pointed at `UpgradeTray` only (`test_run_progression`, `test_gameplay_slice`, `calibrate_rp`, `render_gameplay_clip`, `render_upgrade_showcase` — now banks ×2, spawns enemies, has a usage header).
- **Files/systems:** `scenes/gameplay/{game_world.gd,game_world.tscn,upgrade_tray.gd,upgrade_tray.tscn}`, `scripts/components/run_progression.gd`, `scripts/resources/{run_progression_tuning,tutorial_catalog,tutorial_lesson_data}.gd`, `data/progression/default_run_progression.tres`, `data/tutorial/default_tutorial.tres`, `scenes/tutorial/{tutorial_director,tutorial_ghost_hand,tutorial_screen}.gd`, `tutorial_screen.tscn`; docs mutations, core_run, rush_mode, game_feel, player_dash, tutorial, ui_design_system, GDD §5.5/§5.6/§14, PROJECT_CONTEXT.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. One temporary headless smoke (deleted): 52 checks, 0 failures — three quick level-ups bank mid-combo with no tray and time 1.0; no tray without a calm moment; opens at a calm wave start at ×0.30, tree unpaused; a pick applies exactly one mutation, a tap during slide-in is refused, the next set appears (×2), last pick closes and time 1.0; arena dash dismisses (banked, time 1.0), no reopen in the same moment, reopens at a field clear; timeout keeps the level; pause → 1.0 and hidden, resume → shown and ×0.3; boss start closes; never calm with a boss pending/alive or during RUSH; Reduced Motion instant at 1.0; scene exit → 1.0; tutorial lesson 7 demo opens the tray and the hand picks once, reaches the try, the try's calm moment opens the tray and a pick passes the lesson. One capture (540×960, render_upgrade_showcase): tray and ×2 pill read clearly; frame PNGs deleted. **No permanent tests and `tools/run_tests.sh` not run, by owner preference.** No MCP or device run.
- **Follow-ups:** device pass — 0.3 slow motion vs "not a safe pause", 6 s timeout, 4 s calm window, whether constant dashers in Endless (continuous refill) see cards often enough, tray covering a Wisp resting on the bottom wall, pill fit next to the XP bar on narrow safe areas; stale tests still stale.

## 2026-09-15 — App icon reverted to the previous brand mark
- **Who:** Claude Code (Opus 5)
- **Did:** Owner asked to put the previous logo back. `brand_icon` / `brand_icon_store` in `tools/art/redesign_v1_slices.json` point at `14_brand_mark.png` again and the two icon PNGs were regenerated. The emblem stays available, unused, at `concept_art/wisp_rush_redesign_v1/assets/17_game_emblem_icon.png`. The Home/loading wordmark was never changed.

## 2026-09-15 — Aim line removed, arrow kept
- **Who:** Claude Code (Opus 5)
- **Did:** Owner liked the aim help but asked to remove the dash-path line and keep the arrow. `AimGuide` no longer draws the line or end diamond; the lit-enemy rings, the ×N count (now just past the arrow tip) and the aim assist are unchanged.
- **Verified:** `tools/validate.sh` → OK.

## 2026-09-15 — Aim help: target highlight and gentle aim assist
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner: players miss enemies and lose combos through aim precision (hits are already swept). Owner decisions, not assumptions: GDD §4 / §5.1.
  - **Target highlight.** `WispPlayer.aim_preview_changed(origin, direction, landing, active)` fires on every aim-arrow update (resolved, assisted) and once on hide. GameWorld draws the new `AimGuide` (faint line from the arrow tip to where the dash stops, end diamond, `×N` `ValueLabel` at 2+) under the enemy layer and lights enemies with `EnemyActor.set_targeted` (code-drawn `SOUL_CYAN` ring, pulse off under Reduced Motion). Counting uses the new side-effect-free `EnemyActor.would_dash_hit` (Warden shield arc and Rift Spawn tether overrides), which `try_dash_hit` now calls too, with `WispPlayer.get_dash_corridor_radius()` (also used by `_advance_dash`); it stops at dash-blocking hazards and portal mouths, not at cycling damage hazards. Clears on release/cancel/damage/pause/upgrade/death/level victory/tutorial skip confirm (`GameWorld.cancel_player_aim`); AIM ARROW off hides it.
  - **Aim assist.** `WispPlayer.get_assisted_direction` samples ±1°…±6° and bends only to strictly more hits (ties → closest, never to 0, cone checked on the resolved direction, legal casts only), applied in `_act_on_swipe` (launch, redirect, windup retarget, buffered) and both keyboard paths; the preview shows the assisted result. GameWorld hands the enemy query down once via `set_aim_target_counter`. `PlayerTuning.aim_assist_degrees` 6.0 / `aim_assist_step_degrees` 1.0. Settings **AIM ASSIST** toggle (`aim_assist`, default ON, sanitized like `aim_arrow`, no schema bump); AIM ARROW caption now "Show the dash path and lit targets".
  - **Tutorial.** Slice and chain captions teach lit enemies and the ×count; demos already drive `preview_aim`, so they show the line, rings and ×3; catalog `hold_seconds` 0.2 → 0.4 so the demo holds long enough to read it. Lesson count and flow unchanged.
- **Files/systems:** `scenes/player/wisp_player.gd`, `scenes/gameplay/{game_world.gd,aim_guide.gd}` (new), `scripts/components/enemy_actor.gd`, `scenes/enemies/{warden,rift_spawn}.gd`, `scripts/resources/player_tuning.gd`, `data/player/default_player_tuning.tres`, `scripts/autoload/save_manager.gd`, `scenes/screens/settings_screen.{gd,tscn}`, `scenes/tutorial/tutorial_screen.gd`, `data/tutorial/default_tutorial.tres`; docs player_dash, enemies, core_run, settings, tutorial, GDD §4/§5.1.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. One temporary headless smoke (deleted): 36 checks, 0 failures — straight dash through 3 lined-up Soul Wisps: guide count 3, label `×3`, all three lit, no bend, release clears, kills 3; assist algorithm with a scripted counter (picks +4° best, tie keeps −2° closest, never past 6°, no bend at max or at zero hits, reaches the 6° edge); real enemies: raw 2 → assisted 3 hits at a 1° bend, preview and arrow show the assisted line, assist off returns raw, 90-direction sweep worst bend 6.00°, never worse, released dash killed 3; crystal truncates line and count; cancel/pause/damage/AIM ARROW off clear; Warden front blocked/back hits; save sanitizer defaults `aim_assist` ON. One capture (540×960, 3 souls + 1 off-line, finger held): line, two cyan rings and `×2` read clearly on Obsidian Garden (third soul lay beyond the landing); frame PNGs deleted. **No permanent tests and `tools/run_tests.sh` not run, by owner preference.** No MCP or device run.
- **Follow-ups:** device pass (ring/line readability on pale Frozen Choir ice and Ember Hollow, whether 6° feels gentle, whether lighting 2–3 health enemies that survive one hit misleads); tutorial slice/chain captions assume AIM ARROW is ON; in a debug build Settings (with the DEVELOPER card) has no scroll and now needs 2,473 px (was ~2,366; the AIM ASSIST row adds 107 px incl. spacing), so its bottom is clipped on 2,338–2,400 px-tall phones in the debug APK — release builds need ~1,780 px; a ScrollContainer (or a tighter FEEL card) is the fix, not done here; stale tests (`test_movement` arrow checks, `test_save_manager` settings keys) untouched.

## 2026-09-15 — Endless spawns continuously
- **Who:** Claude Code (Opus 5)
- **Did:** Owner: Endless had stretches with no enemies — "there shall be constantly enemies and things happening". Cause: each wave is a 22 s timer plus a threat budget, formations only spawn on an empty field, so clearing a wave's budget early left the arena empty until the timer ran out. New `WaveDirector.set_continuous(refill_live_enemies)`: under Endless rules (Endless and the daily run) the next formation arrives while at most `EndlessTuning.refill_live_enemies` (2) enemies are alive, and a spent (or timed-out) wave starts the next one at once. Story Rift levels keep timed waves. Waves, and so bosses every 4 waves, now come sooner in real time.
- **Files/systems:** `scenes/gameplay/{wave_director,game_world,endless_arena_rules}.gd`, `scripts/resources/endless_tuning.gd`, `data/endless/default_endless_tuning.tres`.
- **Verified:** `tools/validate.sh` → OK; device feel pending.

## 2026-09-15 — Dash slowed 10 %
- **Who:** Claude Code (Opus 5)
- **Did:** Owner: "slow the character dash a little bit, not a lot". `PlayerTuning.dash_speed` 4,400 → 3,960 px/s (−10 %) in `data/player/default_player_tuning.tres` and the schema default. Launch burst, momentum, mutations and RUSH still multiply on top; a cruise crossing of 1080 px now takes ~273 ms (burst start makes the real crossing shorter).
- **Verified:** `tools/validate.sh` → OK.

## 2026-09-15 — Tutorial screen replaces the in-run lesson
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner decision: a separate Tutorial screen teaches every base mechanic easiest-first as "show, then you try" lessons (aim & dash, slice, chain, redirect, blockers, danger, Rift Points & XP + upgrade, RUSH, boss with 3 health). `TutorialScreen` hosts a GameWorld built with the new `RunProfile.tutorial` (`MODE_TUTORIAL`: Endless floor template under the placeholder `astral_observatory` skin, no waves, boss cadence, run end, Results, banking or recording); `TutorialDirector` runs the lessons from `data/tutorial/default_tutorial.tres` (`TutorialCatalog` / `TutorialLessonData`).
  - Ghost hand (`TutorialGhostHand`) is code-drawn placeholder art; **the demo drives the real Wisp** (aim arrow while the hand drags, `WispPlayer.perform_swipe` on release, mid-dash redirects re-aimed at release), except the boss lesson, whose demo is hand-only. The danger demo forces its hit near the spikes; hits refill Soul Fragments so the tutorial never ends in death.
  - GameWorld: removed `TutorialStep`, `TutorialOverlay`, `tutorial_enabled`, `tutorial_completed`, `is_tutorial_complete`; added run event signals (`dash_launched`, `dash_resolved`, `enemy_defeated`, `player_damaged`, `upgrade_chosen`, `rush_started`, `boss_defeated`) and scripted-run hooks; RUSH/XP gating now `set_rush_enabled` / `set_experience_enabled`. WispPlayer: `set_input_enabled`, `preview_aim`, `perform_swipe`, `place_at_edge`. ReaperBoss `configure(..., health_override)`.
  - Main: first launch (save `tutorial_completed` false) opens the Tutorial after Loading; finish/skip marks it completed → Home; Rift Map footer TUTORIAL (SecondaryButton; BACK 240 px) replays it and returns to the Rift Map; back/Escape open the SKIP confirm; the Tutorial never glides. Settings' REPLAY TUTORIAL and `SaveManager.reset_tutorial()` removed. Deleted `scenes/tutorial/tutorial_overlay.*` (the deletion is staged in the index by a `git rm --cached`) and `tools/godot/test_tutorial_flow.gd`; tool scripts that set `tutorial_enabled` were trimmed (the ones that relied on it to hold waves now call `debug_quiet_arena()`), and `test_game_flow` / `test_main_progression_flow` mark the tutorial completed before booting Main; `qa_capture.gd`'s `tutorial` shot renders the new screen.
- **Files/systems:** `scenes/tutorial/*`, `scripts/resources/tutorial_{lesson_data,catalog}.gd`, `data/tutorial/`, `scenes/gameplay/{game_world.gd,game_world.tscn,run_profile.gd}`, `scenes/player/wisp_player.gd`, `scenes/bosses/reaper_boss.gd`, `scenes/main/main.gd`, `scenes/screens/{rift_map_screen,settings_screen}.*`, `scripts/autoload/save_manager.gd`, tool scripts; docs tutorial (rewritten), core_run, game_flow, rush_mode, rifts, settings, endless_mode, save_manager, enemies, GDD §5.6/§11/§14 #23/#29, PROJECT_CONTEXT §2/§4/§5.1/§5.2/§5.8, ROADMAP M12 + M6, README.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. One temporary headless smoke (deleted) walked all nine lessons with their real demos (demo dashes landed: slice 1 kill, chain 3, redirect leg 1, crystal route 1, danger 1 after the forced hit, XP 3, RUSH 3 and RUSH fired), emitted each goal (chain retry, danger hit → retry + refill, real upgrade pick, real RUSH, real boss core hits), then skip/back toggling, first-launch → Tutorial → skip → Home, Rift Map TUTORIAL → finish/skip → Rift Map: 0 failures; Rift Map footer min width 825 px of 1000. One `tools/screenshot.sh` capture mid-demo: hand, aim arrow, SKIP and caption panel read clearly. **No permanent tests written and `tools/run_tests.sh` not run, by owner preference.** No MCP/device run.
- **Follow-ups:** device pass (redirect lesson timing, caption length on small phones, back into the confirm); the placeholder skin's baked name plate shows faintly behind the step row; stale tests remain stale (untouched beyond API removals).

## 2026-09-15 — Light test pass after RUSH; fixed RUSH restarting forever
- **Who:** Claude Code (Opus 5)
- **Did:** Owner asked for a quick test-and-fix pass. Full headless suite: 22 passed, 12 failed — every failure is a stale test calling pre-rework APIs (`configure_run_profile`, `purchase_form`, the retired Forms screen); no error came from game code. Updated `test_movement` to `configure_run(RunProfile.story(...))`: it passes, so the game-time momentum window kept dash flow intact. A throwaway headless smoke of RUSH and the time-scale owner found a **real bug**: `_update_rush` zeroed `_rush_remaining` before calling `_end_rush`, which then saw RUSH inactive and skipped emptying the meter — RUSH restarted every time it ended (permanent ×1.3 speed and damage immunity). Fixed by ending while the remaining time is still positive. After the fix: lowest time-scale request wins, overlapping requests expire back to 1.0, RUSH starts on a full meter, grants immunity and speed, ends after its duration, restores both, empties the meter, and scene exit restores time scale.
- **Files/systems:** `scenes/gameplay/game_world.gd`, `tools/godot/test_movement.gd`.
- **Verified:** smoke 13/13 (script deleted after the run); `test_movement` PASS; `tools/validate.sh` → OK.
- **Follow-ups:** the other 11 stale tests still need updating to the story/Endless/Shop APIs; finisher triggers, shard sweep and RUSH fill from real kills only checked on device.

## 2026-09-15 — App icon from the owner's game emblem
- **Who:** Claude Code (Opus 5)
- **Did:** Owner supplied the cyan soul-flame emblem (Codex `wisp_rush_game_emblem_alpha.png`, genuine alpha) as the app icon. Added it as `concept_art/wisp_rush_redesign_v1/assets/17_game_emblem_icon.png` and pointed the `brand_icon` / `brand_icon_store` groups of `tools/art/redesign_v1_slices.json` at it; rebuilt with `extract_redesign.py --only brand_logo brand_icon brand_icon_store`. The Home/loading wordmark logo is unchanged (briefly swapped, reverted at the owner's request; the regenerated PNG is byte-identical to the committed one). Splash still uses `14_brand_mark`.
- **Files/systems:** `assets/art/branding/wisp_rush_app_icon_{master,store}.png`, `tools/art/redesign_v1_slices.json`, `docs/ASSETS.md`.
- **Verified:** `tools/validate.sh` → OK; icon previewed on `#111521`.

## 2026-09-15 — RUSH mode and fast feel built (spec rush_and_feel, implementation only)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - `RunFeelTuning` (`scripts/resources/run_feel_tuning.gd`, `data/feel/default_run_feel_tuning.tres`, GDD §14 #27 values) on `GameWorld.feel_tuning`.
  - One owner for `Engine.time_scale`: `_request_time_scale(scale, real_seconds)` (lowest wins, real-time expiry); hit-stop and the finisher use it; pause, upgrade choice, run end and `_reset_view_effects` clear it. Chain momentum's window now counts game time (`WispPlayer._game_time`) instead of `Time.get_ticks_msec()`.
  - Visible momentum: trails lengthen/brighten with momentum, streak glow, speed lines at max (not under Reduced Motion), dash pitch per step. Auto-collect: `SoulShardPickup.sweep_to` / `collect_now` at wave start, boss start, boss defeat, fatal hit and before the summary, one capped chime run. Slow-motion finisher on a 5-kill dash, field clear (6 s cooldown) and boss killing blow.
  - RUSH meter (orbs via `VfxPool.play_flight`, `%RushRow` with new `RushProgressBar` theme variation, theme regenerated) and RUSH mode (×1.3 speed modifier, ×2 score at the choke point, frozen combo, `WispPlayer` damage immunity, music 1.0, aura + flicker, edge glow); summary `rush_count`. Simplest choices recorded as GDD §14 #28.
- **Files/systems:** `scenes/gameplay/{game_world.gd,game_world.tscn}`, `scenes/player/wisp_player.gd`, `scenes/pickups/soul_shard_pickup.gd`, `scripts/components/vfx_pool.gd`, `scripts/resources/run_feel_tuning.gd`, `data/feel/`, `assets/ui/theme/{tools/build_wisp_theme.gd,wisp_theme.tres}`; docs new `systems/rush_mode.md`, player_dash, game_feel, core_run, audio, mutations, ui_design_system, PROJECT_CONTEXT §2/§5.1/§5.8, GDD §14 #27–#28, ROADMAP M11, spec status.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. `tools/qa_matrix.sh game` once: no overlap at the five phone sizes; the RUSH caption read faint, so it now uses `ValueLabel` and the row was widened left to line the bar up with the XP strip (not re-captured). **No tests were written, updated or run, by owner preference (device testing over headless tests)**; no MCP run. RUSH, finishers and sweeps have not been exercised at runtime — only parsed and booted.
- **Follow-ups:** device pass for every spec Acceptance item (RUSH frequency per Rift level / Endless run, finisher feel, time scale always back to 1.0, boss panel 34 px lower with the RUSH row); `test_rush_mode.gd` / `test_run_feel.gd` when wanted; `test_movement` should still pass (momentum window unchanged at normal speed).

## 2026-09-15 — RUSH mode and fast-feel spec (docs only)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner chose four base mechanics to make runs feel faster — RUSH mode, visible chain momentum, auto-collected Rift Points, a slow-motion finisher — and dropped the "Essences" power-up idea.
  - Recorded the rules in GDD §5.6 (+ starting values as §14 #27), wrote the one-phase work order [specs/rush_and_feel/](specs/rush_and_feel/README.md) and ROADMAP Milestone 11. Also added an Endless skin-set prompt earlier today (`concept_art/wisp_rush_endless_v1/SKIN_SET_PROMPT.md`, 30 skins in four rarities).
  - Code facts the spec guards against: `_hit_stop()` writes `Engine.time_scale` directly (a finisher would race it → one time-scale owner), and chain momentum's window uses wall-clock `Time.get_ticks_msec()` (slow motion would break chains → count game time).
- **Files/systems:** `docs/GDD.md`, `docs/ROADMAP.md`, `docs/specs/rush_and_feel/README.md`. No code changed.
- **Verified:** docs only; not run.
- **Follow-ups:** a coding agent implements the spec; RUSH frequency and finisher feel need a device pass.

## 2026-09-15 — PLAY starts Endless; story Rifts only through RIFTS
- **Who:** Claude Code (Opus 5)
- **Did:** Owner, after the first device look at the rework: "PLAY puts the user only in Endless mode; they enter a Rift with the RIFTS button; remove the ENDLESS button". PLAY now builds the `endless` profile and Endless is open from the first launch; the pool always holds Obsidian Garden (roster + Reaper) and grows with each Rift's level-1 clear (`ContentUnlocks.is_in_endless_pool`). Removed the ENDLESS button, NEW badge, `endless_intro_seen` (save key, `mark_endless_intro_seen`), `is_endless_unlocked`, the `ENDLESS UNLOCKED` Results banner and the arena-skin Endless gate (Shop + SaveManager). Home's caption reads `ENDLESS` / `ENDLESS  •  BEST WAVE n`; BEST is always the Endless best. The first-run lesson now plays inside the first Endless run (the tutorial was already mode-agnostic).
- **Files/systems:** `scenes/main/main.gd`, `scenes/screens/{home_screen.gd,home_screen.tscn,results_screen.gd,shop_screen.gd}`, `scripts/utils/content_unlocks.gd`, `scripts/autoload/save_manager.gd`; docs `GDD.md` §6/§11/§14 #13, `systems/{endless_mode,game_flow}.md`.
- **Verified:** `tools/validate.sh` only (owner: no tests). Stale tests now also include ENDLESS visibility/badge and `get_rift_caption` (renamed `get_play_caption`) checks.
- **Follow-ups:** device check of the first-launch tutorial inside Endless.
- **Then (owner):** Endless is not limited by Rifts — every Rift's roster and boss can appear even with nothing cleared. `ContentUnlocks.get_endless_roster_rift_ids(catalog)` / `get_endless_boss_ids(catalog)` now return every Rift; `is_in_endless_pool` removed.

## 2026-09-15 — Spec 05 (partial): final Endless skins wired with placeholder art (implementation only)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - [Spec 05](specs/story_and_endless/05_endless_arena_art.md) without the owner's art: `data/endless/skins/{astral_observatory,drowned_sanctum,moonpetal_shrine}.tres` (final ids/names, descriptions, accents, 0 / 800 / 1,200 RP, all `placeholder = true`); catalog default `astral_observatory`; `placeholder_void_slate` data and art deleted.
  - `make_endless_floor_template.py`: `--style <skin_id>` and `--placeholder-skins` render a distinct stand-in per skin on the identical template (`assets/art/environment/endless/<skin_id>.png`, 941×1672); template PNGs regenerated byte-identical.
  - Save: `VALID_ARENA_SKIN_IDS` = the three skins; `RETIRED_ARENA_SKIN_IDS` maps owned/equipped `placeholder_void_slate` → `astral_observatory` while sanitizing (no schema bump). GDD §14 #26.
- **Files/systems:** `data/endless/`, `assets/art/environment/endless/`, `tools/art/make_endless_floor_template.py`, `scripts/autoload/save_manager.gd`, `scripts/resources/arena_skin_data.gd`; docs endless_mode, save_manager, ASSETS, GENERATION_PROMPTS status, GDD §14 #26, ROADMAP M6/M10, spec README.
- **Verified:** `tools/validate.sh` → OK only. **No tests were written, updated or run, and no MCP/QA/screenshot runs, by owner request**; existing headless tests may now be stale (`test_save_manager`, `test_menu_screens`, anything expecting `placeholder_void_slate`). No checker numbers: `check_endless_skin.py` was not built.
- **Follow-ups:** owner generates the three images; build the checker and extraction, flip `placeholder` to `false`; QA sheets and device pass (rim at the wall, Wisp brightest, 20:9 crop); write `test_endless_catalog`.

## 2026-09-15 — Spec 04: One Shop for everything Rift Points buy (implementation only)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - [Spec 04](specs/story_and_endless/04_shop.md): `ShopScreen` rebuilt with tabs WISPS / DASHES / ARENAS (FocusCarousel cards, one main button: BUY • price, NEED n RP, BEAT A BOSS FIRST / UNLOCK ENDLESS FIRST, EQUIP, EQUIPPED) and NO ADS (ADR-0012 panel, unchanged behaviour, no RP). Tab bar = `NavBar` + toggle `NavButton`s (no theme change).
  - `DashStyleData` / `DashStyleCatalog`, `data/dash_styles/` (SOUL 0, MOONSILVER 300, VERDANT 600, ABYSSAL 900; reserved-hue validation). GameWorld tints the launch burst and long trail from `RunProfile.dash_style`; SOUL keeps the form tint.
  - Save v8: `owned_dash_styles` / `equipped_dash_style`; `purchase_cosmetic` / `equip_cosmetic` / `owns_cosmetic` replace `purchase_form` / `equip_form` (buying equips; arena skins refused until Endless opens).
  - Routing: Forms screen deleted; Wisp tap and Results' WISP FORMS → Shop WISPS, SHOP → last tab this session, NO ADS → NO ADS tab, Back returns to Home or the same Results (`Main._present_results`). Home/Results signal `forms_requested` → `wisps_requested`. `qa_capture.gd` / `qa_matrix.sh` screens `forms`/`shop` → `shop_wisps`/`shop_dashes`/`shop_arenas`/`shop_no_ads`.
- **Files/systems:** `scenes/screens/shop_screen.*` (forms_screen.* deleted), `scripts/resources/dash_style_{data,catalog}.gd`, `data/dash_styles/`, `scripts/autoload/save_manager.gd`, `scenes/main/main.gd`, `scenes/gameplay/{run_profile,game_world}.gd`, `scenes/screens/{home_screen,results_screen}.gd`, `tools/godot/qa_capture.gd`, `tools/qa_matrix.sh`; docs shop, forms, monetisation, ui_design_system, game_flow, save_manager, core_run, PROJECT_CONTEXT §5.1/§5.2/§5.8, GDD §14 #18/#25, ROADMAP M10.
- **Verified:** `tools/validate.sh` → OK only. **No tests were written, updated or run, and no MCP/QA/screenshot/render runs, by owner request.** `test_shop` / `test_dash_styles` do not exist; existing headless tests are likely stale (`test_save_manager` schema 8 and `purchase_form`, `test_form_catalog`, `test_menu_screens`, `test_screen_setup_order`, `test_screen_transitions`, `test_main_progression_flow`, `test_progression_screens`, `test_focus_carousel`, `test_monetisation`/Shop `setup` callers, anything using `FormsScreen` or `forms_requested`).
- **Follow-ups:** device pass (tab bar and long button text on small phones, dash preview, dash tint contrast on all Rifts and the Endless skin, Back from Shop to Results); write the Shop and dash style tests; tune prices after the device pass.

## 2026-09-15 — Spec 03: Endless mode and the daily run on Endless rules (implementation only)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - [Spec 03](specs/story_and_endless/03_endless_mode.md): `ArenaSkinData`, `EndlessTuning`, `EndlessCatalog` (`data/endless/`, template polygon from `floor_template.json`); `ArenaRules` seam with `RiftArenaRules` / `EndlessArenaRules` built by `RunProfile.create_arena_rules()` — GameWorld no longer holds a `RiftData`. Endless: template floor under the skin, no twist, seeded roster per wave and boss per cycle without immediate repeats, threat/speed per cycle, never ends on a boss; roster wave callout.
  - Daily run = Endless rules with the daily pool and arena of the day; Daily screen names the arena. `EnemyActor.set_speed_scale` (Rift `enemy_speed_scale` was never applied before; now it is — GDD §14 #24).
  - `ContentUnlocks.is_endless_unlocked` / `get_endless_roster_rift_ids` / `get_endless_boss_ids`; save v7 (Endless bests, runs, intro flag, owned/equipped arena skin); Home ENDLESS in the PLAY row's left slot (NEW badge, slow counter-turning portal, stilled by Reduced Motion), BEST = Rift best until Endless opens; Results `WAVE w` / PLAY AGAIN / HOME for Endless and daily, `ENDLESS UNLOCKED` banner; Statistics Endless rows.
  - Development placeholder skin `placeholder_void_slate` generated with `make_endless_floor_template.py --placeholder` (ASSETS.md, ROADMAP M6).
- **Files/systems:** `scenes/gameplay/{arena_rules,rift_arena_rules,endless_arena_rules,run_profile,game_world}.gd`, `scripts/resources/{arena_skin_data,endless_tuning,endless_catalog}.gd`, `data/endless/`, `assets/art/environment/endless/`, `scripts/utils/content_unlocks.gd`, `scripts/components/enemy_actor.gd`, `scripts/autoload/save_manager.gd`, `scenes/main/main.gd`, `scenes/screens/{home_screen.*,results_screen.gd,daily_screen.gd,statistics_screen.gd}`; docs endless_mode, core_run, wave_director, reaper_boss, challenges, save_manager, game_flow, settings, meta_progression, PROJECT_CONTEXT §5.1/§5.2/§5.8, ASSETS, GDD §14 #13–#15/#24, ROADMAP M6/M10.
- **Verified:** `tools/validate.sh` → OK only. **No tests were written, updated or run, and no MCP/QA/screenshot runs, by owner request.** `test_endless_catalog` / `test_endless_mode` do not exist; existing headless tests may now be stale (`test_save_manager` schema 7, `test_menu_screens`, `test_main_progression_flow`, `test_challenge_tracker`, `test_rift_rules`/`test_rift_enemies` — `_rift` is gone and Rift enemy speed now applies — plus everything already stale after spec 02).
- **Follow-ups:** device pass (ENDLESS visibility/badge, Endless run on the placeholder, Results `WAVE w`, Statistics fitting three more rows on small phones); tune per-cycle difficulty; write the Endless tests; spec 05 replaces the placeholder.

## 2026-09-15 — Spec 02: Rifts become story levels (implementation only)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Finished the interrupted phase ([spec 02](specs/story_and_endless/02_story_mode.md)): `RunProfile` + `GameWorld.configure_run` (Main builds every profile; `configure_run_profile` gone), `ContentUnlocks`, `RiftData.unlock_after_rift_id/level` chain with `RiftCatalog.validate()`, one level per story run ending in victory through `run_ended`, clear bonus via `EconomyTuning`, daily run unchanged in Obsidian Garden.
  - Main routes: PLAY → selected Rift's next level (lesson = Obsidian Garden L1), Rift Map ENTER → that Rift's next level, restart replays the profile, Results NEXT LEVEL / ENTER <RIFT>; a clear that opens a Rift selects it.
  - Results: `LEVEL n CLEARED` / `LEVEL n FAILED` banner, Rift name, `<RIFT> OPEN` banner, CLEAR BONUS plate, primary ENTER <RIFT> / NEXT LEVEL / PLAY AGAIN / RETRY. Home caption `<RIFT>  •  LEVEL n` or `MASTERED`; Rift Map cards `LEVEL n / 8` or `MASTERED`, lock text `CLEAR <RIFT> LEVEL 1`.
  - Trials audit: `level_clears` metric; tiers 2/3/6/7 re-authored as level-clear goals, GO DEEPER wave 10+ says "in Endless" (GDD §14 #23). GDD §14 #12/#13 owner approved.
  - Render fixtures and `calibrate_rp.gd` switched to `configure_run`.
- **Files/systems:** `scenes/main/main.gd`, `scenes/gameplay/{game_world.gd,run_profile.gd}`, `scenes/screens/{results_screen.*,home_screen.gd,rift_map_screen.gd}`, `scripts/utils/{content_unlocks,dev_unlock}.gd`, `scripts/resources/{rift_data,rift_catalog,trial_catalog,economy_tuning}.gd`, `data/rifts/`, `data/trials/`, `data/economy/`, `tools/godot/{render_aim_arrow_showcase,render_wall_splash_showcase,calibrate_rp}.gd`; docs rifts, core_run, reaper_boss, game_flow, meta_progression, challenges, tutorial, save_manager, GDD §14, ROADMAP M6/M10, spec README.
- **Verified:** `tools/validate.sh` → OK only. **No tests were written, updated or run, and no MCP/QA/screenshot runs, by owner request** (he tests on his phone). Existing headless tests that use `configure_run_profile`, `unlock_wave`, wave gates, `REACH WAVE`/`ENDLESS` card text, the old trial ids or multi-level runs (`test_rift_rules`, `test_rift_catalog`, `test_menu_screens`, `test_main_progression_flow`, `test_dev_unlock`, `test_movement`, `test_wall_splash`, likely `test_trials`/`test_tutorial_flow`) are now stale.
- **Follow-ups:** device pass of the acceptance list (tutorial → L1 CLEARED → SHATTERED RIFT OPEN → ENTER; Results layout with the fourth RP plate and unlock banner on small phones); clean up/replace the stale tests; tune the clear bonus (`EconomyTuning.placeholder`).

## 2026-09-15 — Spec 01: Rift Points replace Soul Shards; Soul Sanctum removed with a refund
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Currency renamed everywhere ([spec 01](specs/story_and_endless/01_rift_points.md)): save `rift_points`, run summary `rp_collected`, `add_rift_points()`, `reward_points`, `_award_rift_points()`, `grant_remove_ads()`, `DevUnlock.RP_GRANT` / `grant_rift_points`, boss `rp_reward`, placement `double_rift_points`. Player text reads `1,250 RP` / "Rift Points" through the new `RiftPoints` helper; HUD, Home, Results, Shop, Forms, Daily, Trials, Statistics, the Settings developer card and the theme gallery. Pickup files keep the `soul_shard` names (glossary).
  - Save schema v6: `soul_shards` carries over, plus a refund of every Sanctum level bought from a frozen `SANCTUM_REFUND_COSTS` table (resolved with `SanctumNode.get_cost` from `data/sanctum/*.tres` before deletion: 8,970 RP for a maxed tree); `sanctum_levels` dropped; renamed Trials/challenge ids keep progress; a migrated save is written back at once so it never refunds twice.
  - Soul Sanctum deleted: screen, `SanctumNode`/`SanctumCatalog`/`SanctumEffects`, data, test, Home button, Main route, SaveManager methods, dev action, `WispPlayer` bonus invulnerability, `RunProgression.grant_random_mutation`. Runs start at the no-bonus baseline; `configure_run_profile` lost `sanctum_levels`. Home's left column is Trials + Daily.
  - Performance bonus: new `EconomyTuning` (`res://data/economy/default_economy_tuning.tres`); `rp_performance = score / score_per_rift_point`; `record_run` adds collected + performance once. Results shows RP COLLECTED, PERFORMANCE, REWARDS, TOTAL (the measured balance change) and BALANCE. Remove Ads is product `remove_ads` with no currency; the Shop's shard line is gone.
  - Calibration: new `tools/godot/calibrate_rp.gd` bot runs. At the spec's 400 the tutorial and two early runs paid 28/20/24 RP (target 35–45), so `score_per_rift_point` is now **200** (45/33/38). Numbers in [shop.md](systems/shop.md); flagged `EconomyTuning.placeholder = true`, pending device calibration (ROADMAP M6).
- **Files/systems:** `scripts/autoload/{save_manager,monetisation_service}.gd`, `scenes/gameplay/game_world.{gd,tscn}`, `scenes/main/main.gd`, `scenes/screens/{home,results,shop,forms,daily,trials,statistics,settings}_screen.*`, `scenes/player/wisp_player.gd`, `scenes/bosses/reaper_boss.gd`, `scripts/resources/{economy_tuning,trial_data,trial_catalog,reaper_tuning}.gd`, `scripts/utils/{rift_points,dev_unlock,challenge_tracker,trial_tracker}.gd`, `data/{economy,trials,bosses}/`, `data/sanctum/` (deleted), tests, `tools/godot/qa_capture.gd` + `tools/qa_matrix.sh` (new `trials` screen); docs: shop, save_manager, meta_progression (now "Trials and depth milestones"), monetisation, challenges, forms, game_flow, core_run, mutations, rifts, settings, reaper_boss, ui_design_system, PROJECT_CONTEXT §2/§4/§5.1/§5.2/§5.8/§8, GDD §14 #12/#16/#17/#22, ROADMAP M6/M10, spec 01 status.
- **Verified:**
  - `tools/validate.sh` → OK; `tools/run_tests.sh` → **34 passed, 0 failed** (`test_sanctum` deleted; new `test_rift_points_text`).
  - New checks: v5 fixture (300 shards, keen_edge 2, soul_reserve 1, unknown id, over-cap level) → v6 `rift_points` 3,220 exactly once, persisted and stable on reload, v6 round trip, future schema untouched; Remove Ads purchase/restore leave the balance unchanged; Results total = balance change through a live Main; no-bonus run baseline.
  - "No SHARD text" check is a test, not a grep: `test_rift_points_text.gd` scans every `text =`/title/description in `scenes/` and `data/`, prose string literals in all scripts, the challenge pool and the live text of nine screens (only the Shard Wraith is allowed).
  - `tools/qa_matrix.sh home results shop daily trials forms stats game settings` — sheets reviewed at all five sizes, no clipping; Statistics then switched to grouped `1,320 RP`.
  - Godot MCP run: boot → Loading → Home, no SCRIPT ERROR (only the existing typed-conversion warnings).
- **Follow-ups:**
  - Device pass: confirm or retune `score_per_rift_point`, then set `EconomyTuning.placeholder = false`. Bots never dodge, so runs that beat the first boss (84–191 RP) are unmeasured with people.
  - ASSUMPTION GDD §14 #22: HOARDER and POINT SEEKER count `rp_collected`, not `rift_points` as the spec table said, to keep their difficulty.
  - The trial rename `t08_soul_shards_m` → `t08_rp_collected_m` was made with `git mv`, so that rename is staged in the index; nothing was committed.
  - The MCP run used the real desktop save, so an existing v5 save there is now v6 (what any first launch of this build does).
  - ~~The Shop's Remove Ads card still uses the shard-cluster art as its emblem~~ — fixed in the review below.
- **Review:** exactly-once RP was only checked against Main's own balance change (true by construction), and no test read the summary GameWorld really emits. `test_main_progression_flow` now computes the rewards independently from the pre-run save (`ChallengeTracker`/`TrialTracker.apply_run`, depth rule) and requires balance change = displayed total = 3 + 1 + rewards, plus `%RewardsValue`; a deliberate double challenge payment in Main now fails it (24 vs 14). `Main._show_results` warns when the total ≠ collected + performance + rewards. `test_player_health_flow` plants score/pickups before the killing hit and checks the live summary's `rp_collected`/`rp_performance` against the wired `EconomyTuning` (fails if the `.tscn` export or a key is lost — both tried), that every Trial/challenge metric is a summary key, and `get_performance_points` edge cases (0, negative, 199/200/399/400/401, divisor 0). `test_rift_points_text` now requires grouped-number + `RP` unit on Home/Shop/HUD and an RP value on Results, Daily rewards, Trials footers, Forms balance and the Statistics row (a bare Trials footer fails it); Daily and Trials format through `RiftPoints`, the HUD count groups digits. Shop offer emblem is Home's NO ADS glyph instead of currency art (`qa_matrix.sh shop` reviewed, 5 sizes). Dead `sanctum_levels` assertion removed from `test_dev_unlock`; migration tables are typed dictionaries; spec 01 acceptance boxes ticked.

## 2026-09-15 — Direction recorded: Rift story levels, Endless mode, Rift Points (docs, specs, art template)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Recorded the owner's 2026-09-14 direction: Rifts as story mode, a cosmetic Endless mode, earned-only Rift Points, Soul Sanctum removed, Remove Ads the only real-money item ([ADR-0013](decisions/0013-rift-story-levels-endless-mode-and-rift-points.md)).
  - Measured why arena looks can't reuse Rift walls: the five floors span 85–100 % of the largest, and their shared shape keeps 63–82 % of each. Chose one chamfered-rectangle floor for every Endless skin ([ADR-0014](decisions/0014-endless-arenas-share-one-floor-template.md)).
  - Filled design gaps as ASSUMPTIONs in GDD §14 #12–#21: one level per Rift run, level-1 clears unlock, Endless pools, the daily run on Endless rules, RP pacing, Sanctum refund.
  - Wrote the five-phase work order [specs/story_and_endless/](specs/story_and_endless/README.md), the planned system docs `endless_mode.md` and `shop.md`, planned-change notes in seven system docs, and status lines on ADR-0007/0008/0009/0012.
  - New art pack `concept_art/wisp_rush_endless_v1/`: `floor_template.json`, the rendered mask, layout and guide PNGs from `tools/art/make_endless_floor_template.py` (which also makes a dev-only placeholder arena), and three skin prompts that require the layout image.
- **Files/systems:** `docs/GDD.md`, `docs/decisions/0013-*`, `0014-*`, `docs/specs/story_and_endless/*`, `docs/systems/{endless_mode,shop,rifts,meta_progression,forms,monetisation,challenges,save_manager,game_flow}.md`, `docs/PROJECT_CONTEXT.md`, `docs/ROADMAP.md` (M10), `concept_art/wisp_rush_endless_v1/*`, `tools/art/make_endless_floor_template.py`. No game code changed.
- **Verified:**
  - Template tool run: vertices match `ARENA_FLOOR_UV` + 80 px chamfers, UV area 0.3524; mask spot checks pass (centre in, chamfer corner out); guide, layout and a scratchpad placeholder reviewed.
  - `tools/validate.sh` → OK (72 scripts); project map up to date. Tests not run: no game code changed.
- **Follow-ups:**
  - Owner: confirm GDD §14 #12 (one level per Rift run) before spec 02.
  - Owner: generate the three Endless skins from `concept_art/wisp_rush_endless_v1/GENERATION_PROMPTS.md`; settle the art licence (§14 #1, #21) before selling cosmetics.
  - The working tree still holds the uncommitted Home, Shop and transition work from 2026-09-13/14; commit it before spec 01 starts.

## 2026-09-14 — Game-style simplified logo refinement
- **Who:** Codex (GPT-5)
- **Did:** Restyled the simplified Wisp Rush identity to match the approved game language: painterly
  cyan-white soul flame, crisp dark contour, chipped obsidian crescent and restrained magenta rift
  fracture; kept the exact title deterministic and omitted the old full plaque.
- **Files/systems:** External brand-art handoff at `~/Desktop/wisp_rush_logo_game_style.png`; no
  runtime art or code changed.
- **Verified:** Final transparent PNG inspected at 2048×768 and composited over the approved Home
  background to confirm contrast, hierarchy and style fit; `tools/validate.sh` → OK;
  `tools/run_tests.sh` → 34 passed, 0 failed.
- **Follow-ups:** Owner/Claude can compare this hybrid against the flatter simple version before
  replacing the runtime logo through the generated-art pipeline.

## 2026-09-14 — Animated screen transitions; Home kept alive to remove the navigation delay
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner: "no animations between screens" and "a delay when I press to a new screen". Measured on
    the Galaxy S24 with a new debug-only `[Main] switch` log. Tap → first frame:
    - Home, on every Back: 370–420 ms, because Home was rebuilt each time.
    - Trials ~130 ms, Sanctum 76–122 ms, Daily ~50 ms.
    The old 0.22 s veil fade was invisible: it had finished before the slow first frame was drawn.
  - Main now builds Home once and keeps it (detached, not freed, while other screens show).
  - Every screen change is a crossfade: the new screen fades and glides in over the dimming old one,
    starting only after its first draw. A run never glides, hides its HUD until it lands, and is
    frozen while it leaves. Rules in [game_flow.md](systems/game_flow.md).
  - The Android export had started failing ("A valid Java SDK path is required"): Godot's editor
    settings had `export/android/java_sdk_path` empty. It is set back to the only JDK installed
    (OpenJDK 25), which earlier builds used.
- **Files/systems:** `scenes/main/main.gd`, `scenes/screens/home_screen.gd` (re-show focus),
  `tools/godot/test_screen_transitions.gd`, `docs/systems/game_flow.md`.
- **Verified:**
  - `tools/validate.sh` → OK; `tools/run_tests.sh` → **34 passed, 0 failed**.
  - The new test drives a live Main with transitions on. Undoing the transition fails 3 checks;
    rebuilding Home every visit fails it too.
  - APK built.
- **Follow-ups:**
  - The owner's device test of the feel is pending.
  - Trials and Sanctum still build in ~60–120 ms per open; keep them alive like Home if that still
    feels slow.
  - Remove the `[Main] switch` log once navigation feels right.

## 2026-09-13 — Home without a nav bar: tap-the-Wisp Forms, button columns, animated PLAY, Shop
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner asked to remove the bottom nav. Top bar and logo stay; tapping the Wisp opens Forms;
    Trials and Daily sit left, Shop and Remove Ads right; a bigger animated PLAY with an animated
    Rifts button sits ~50 px+ under the Wisp; no animation may be in the way of the UI.
  - Owner decisions (asked, not ASSUMPTIONs): Sanctum joins the left column; Shop and Remove Ads
    are visible now and open a Shop with purchases disabled until billing exists
    ([ADR-0012](decisions/0012-store-surface-before-billing.md)); the Shop sells only ADR-0009's
    Remove Ads bundle plus Restore Purchases.
  - `_layout_hero()` keeps the preview over the painted Wisp, shrinks orbit and glow to the room
    between the columns (`OrbitMotes.get_extent_ratio()`), and places the caption + PLAY row 64 px
    under the lowest animated pixel. PLAY breathes, pulses a glow and sweeps a light band; the
    Rifts portal turns; Reduced Motion stills it all.
  - First render showed captions under the tiles unreadable (DAILY vanished over a brazier) and PLAY
    parked at the screen bottom; captions moved inside the stone tiles and PLAY under the Wisp.
  - `ShopScreen` + Main routing; `MonetisationService.is_store_available()`.
- **Files/systems:** `scenes/screens/{home_screen.gd,home_screen.tscn,orbit_motes.gd,shop_screen.gd,shop_screen.tscn}`,
  `scenes/main/main.gd`, `scripts/autoload/monetisation_service.gd`,
  `tools/godot/{test_menu_screens,test_screen_setup_order,test_main_progression_flow,test_monetisation,qa_capture}.gd`,
  `tools/qa_matrix.sh`; docs `GDD.md` §11/§13/§14, ADR-0012 (+ ADR-0009 status),
  `systems/{game_flow,monetisation,ui_design_system,forms}.md`, `PROJECT_CONTEXT.md` §5.2, `ROADMAP.md`.
- **Verified:**
  - `tools/validate.sh` → OK; `tools/run_tests.sh` → **33 passed, 0 failed**.
  - `test_menu_screens` mounts Home in 1080×2337 and 1080×1920 frames (the headless root is square,
    which never squeezed the orbit). Mutation-checked: removing the orbit clamp, the glow clamp,
    or the bottom clearance each fails it.
  - QA sheets for home and shop at 5 phone sizes reviewed.
  - The Codex logo-handoff entry below records `test_menu_screens` failing on `%RiftsNav`: it ran
    mid-change, after Home lost the nav but before the test was updated. It passes now.
  - A `gdscript-reviewer` pass confirmed two visual bugs by running them, both now fixed and covered:
    - Press tweens were never killed: a focus loss mid-dip left the Wisp shrunk, and a quick
      re-press sprang back while still held.
    - On 23:9-class screens (1080×2800) the preview's animated width overlapped the right column,
      because the edge was capped by `free_width`, not by the breathing, swaying width.
    New tests cover a tall 1080×2800 frame and press recovery; undoing either fix fails them.
    Also fixed: Shop BUY/RESTORE no longer double-click (`SoundFx.BOUND_META`), the success font
    size no longer sticks, refreshes no longer steal focus, the pending feedback is typed, and a
    test no longer risks a null cast.
  - Debug APK built and installed on the Galaxy S24 (SM-S921B). It boots in 1.4 s; the owner opened
    Forms from the Wisp and played a run with no Godot errors, warnings or crashes in logcat.
- **Follow-ups:**
  - On tall phones the lower third under PLAY is empty painted stairs (the owner asked for PLAY
    under the Wisp); `HERO_BOTTOM_CLEARANCE` moves it.
  - Forms has no visible hint that the Wisp is tappable; consider one after a device pass.
  - Shop icon reuses the unused `02_soul_shard_cluster` prop and NO ADS is a code-rendered struck
    "AD"; dedicated icons would need the art pipeline.
  - The phone still has the pre-review build; reinstall to get the review fixes.
  - The Mac had about 0.5 GB of free disk during the build; exports may start failing.

## 2026-09-13 — Simplified Wisp Rush logo handoff
- **Who:** Codex (GPT-5)
- **Did:** Reworked the ornate existing identity into a compact soul-flame emblem and exact
  one-line `WISP RUSH` wordmark; exported the transparent final at
  `~/Desktop/wisp_rush_logo_simple.png` for owner review and Claude handoff.
- **Files/systems:** External brand-art handoff only; no runtime art or code changed.
- **Verified:** Final PNG inspected at 2048×768 RGBA with genuine alpha and deterministic lettering;
  `tools/validate.sh` → OK. Full tests: 32 passed, 1 unrelated current failure
  (`test_menu_screens` still looks for the removed `%RiftsNav` node); the focused rerun reproduces it.
- **Follow-ups:** If approved, Claude can intake the logo through the generated-art pipeline and
  assess a square app-icon crop separately.

## 2026-09-13 — Living Home, bottom nav, card-carousel Forms and Rift Map
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner asked for a Home that looks different and feels alive, with a minimal Material-like UI in
    the stone-and-cyan style, and Forms / Rift Map pickers modelled on two card-picker references.
    Owner decisions (not ASSUMPTIONs): portrait carousel pickers; bottom navigation (Rifts, Forms,
    Sanctum, Trials, Daily) under a slim top bar, logo, animated Wisp and one PLAY with a Rift
    caption; Wisp float/breathe/sway/glow + orbiting motes + living background; no entrance
    animation or PLAY pulse; Reduced Motion stills everything.
  - New shared `FocusCarousel` (swipe + snap, rubber band, flick, tap side/focused card, keys) and
    `PageDots` (hollow = locked).
  - Home rewritten with `HomeAmbience` (brazier flicker, rune pulse, mist, rising motes over the
    unchanged art) and `OrbitMotes` (back/front halves so sparks pass behind and in front of the
    Wisp). Signals and `setup` unchanged.
  - Forms and Rift Map rebuilt on the carousel; public APIs and signals unchanged. Forms main action
    is `%ActionButton`; Rift Map crossfades to the focused arena, previews locked Rifts but never
    enters them, and adds `is_rift_unlocked()`.
  - Theme builder: `NavButton` and `NavBar` variations (`FONT_NAV` 26, `NAV_ICON` 96).
- **Files/systems:** `scripts/components/{focus_carousel,page_dots}.gd`,
  `scenes/screens/{home_screen.gd,home_screen.tscn,home_ambience.gd,orbit_motes.gd}`,
  `scenes/screens/{forms_screen,rift_map_screen}.{gd,tscn}`, `assets/ui/theme/tools/build_wisp_theme.gd`,
  `tools/godot/{test_focus_carousel,test_menu_screens,test_screen_setup_order,test_progression_screens,qa_capture}.gd`,
  `tools/qa_matrix.sh`; docs `systems/{ui_design_system,game_flow,forms,rifts}.md`, `GDD.md` §11,
  `PROJECT_CONTEXT.md`.
  - Independent review (4 reviewers + adversarial verify, 9 confirmed) fixed:
    - Carousel taps: a rapid double tap on a peek card could buy a form or start a run. Taps are now hit-tested against the resting layout.
    - Carousel presses: a cancelled touch, app focus loss mid-press, or a drag past the tap slop in any direction no longer counts as a tap.
    - Flicks: a stale flick after the finger stopped no longer advances a card.
    - Home motes now respawn when the screen resizes.
    - The brazier glow colour now comes from `Palette.WARNING_AMBER`.
    - The missing `##` docs are added.
    - `test_screen_setup_order` never awaited its checks, so it passed without asserting anything.
    - The carousel rubber-band and short-drag tests are now meaningful and no longer flaky.
- **Verified:**
  - `tools/validate.sh` → OK.
  - `tools/run_tests.sh` → **33 passed, 0 failed** (new `test_focus_carousel`, `test_menu_screens`).
  - Each carousel fix was checked by mutation: reverting it makes the test fail.
  - QA sheets for home, forms, rifts and rifts_locked reviewed at 5 phone sizes; no clipping.
- **Follow-ups:**
  - Deployed the debug APK to a Samsung SM-S921B. It booted, and Home, Forms, Daily and a short run all ran with no engine errors or warnings in logcat.
  - Status mismatch: `rifts.md` says ✅ while PROJECT_CONTEXT §5.1 says 🔄.

## 2026-09-12 — Generated Rift Wave 2 boss and enemy handoff
- **Who:** Codex (GPT-5)
- **Did:** Generated The Fracture, The Cinder Maw and four per-arena enemy families from the
  owner's Wave 2 prompts; packaged the three exact sheets at `~/Desktop/wisp_rush_rifts_v2.zip`.
- **Files/systems:** External Milestone 8 art handoff and roadmap status; no runtime assets or code.
- **Verified:** Three sheets inspected at 1448×1086 RGBA with genuine alpha; ZIP contains only the
  requested folder and three PNGs; `tools/validate.sh` → OK; `tools/run_tests.sh` → 23 passed,
  0 failed.
- **Follow-ups:** Claude to intake, register and slice the sheets, then implement the two bosses and
  four arena-specific enemy families.

## 2026-09-12 — Extended Rift handoff with enemies and Hollow Choir
- **Who:** Codex (GPT-5)
- **Did:** Generated the 12-pose Cinder Shade/Warden/Rift Spawn sheet and the 12-state Hollow Choir
  boss sheet from `GENERATION_PROMPTS-enemies.md`; added both to the existing Rift pack and rebuilt
  `~/Desktop/wisp_rush_rifts_v1.zip` with all seven requested images.
- **Files/systems:** External art handoff and Milestone 8 roadmap status; no runtime assets or code.
- **Verified:** Both new sheets inspected at 1448×1086 RGBA with genuine alpha; ZIP inventory has
  the requested seven PNGs only; `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed.
- **Follow-ups:** Claude to intake the pack, register asset provenance, slice the sheets, and
  implement the three enemy families plus Hollow Choir encounter.

## 2026-09-12 — Generated Milestone 8 Rift art handoff
- **Who:** Codex (GPT-5)
- **Did:** Generated four visually distinct Rift arena backgrounds and one 12-prop transparent
  sprite sheet from `concept_art/wisp_rush_rifts_v1/GENERATION_PROMPTS.md`; packaged the five exact
  filenames for the owner/Claude handoff at `~/Desktop/wisp_rush_rifts_v1.zip`.
- **Files/systems:** External art handoff only; no runtime or `concept_art/` assets changed.
- **Verified:** Five PNGs inspected; backgrounds are 941×1672 RGB, props are 1448×1086 RGBA with
  genuine alpha; ZIP inventory contains only the requested folder and five images;
  `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed.
- **Follow-ups:** Claude to intake the ZIP, add sources to `concept_art/`, register provenance in
  `docs/ASSETS.md`, wire the v2 slice spec, and re-run the art pipeline.

## 2026-09-12 — Faster movement: no lost swipes, redirect, burst, momentum, aim arrow

- **Who:** Claude Code (Opus 5), plus a background `gdscript-reviewer` pass
- **Did:**
  - Measured the delay first. Touches were **refused** outside rest, so a swipe begun mid-dash was
    silently discarded — its release then ignored too — about 400 ms of dead time per dash cycle.
  - Owner chose: input buffering, landing-lock cancel, launch burst, chain momentum, a crisper launch
    haptic (one already existed, 12 ms at 0.35 — strengthened, not duplicated), **mid-dash redirect**
    (changes GDD §5.1), and a direction **arrow that replaces the full aim line** (on by default).
  - The reviewer found 4 bugs and 3 risks, all verified against the code and fixed: redirect legs
    farmed the rapid-ricochet score and Trials metric; a buffered dash threw away a second touch in
    progress; a windup swipe became a zero-length redirect that scored an empty leg and gave free
    momentum; the arrow went stale through landings; cancelled touches acted; faster dashes widened
    a boss-lane blind spot; damage left chain state behind. Also fixed doc/order convention issues.
  - The buffer now counts physics time, not the wall clock, and its window is 0.3 s against the
    0.22 s hurt reaction it bridges — the reviewer had observed the test flaking 1 run in 3.
- **Files/systems:** `scenes/player/wisp_player.{gd,tscn}`, `scripts/resources/player_tuning.gd`,
  `data/player/default_player_tuning.tres`, `scenes/gameplay/game_world.gd`,
  `scripts/autoload/save_manager.gd`, `scenes/screens/settings_screen.{gd,tscn}`,
  `tools/godot/{test_movement,render_aim_arrow_showcase}.gd`, `docs/{GDD.md,systems/player_dash.md}`.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → **31 passed, 0 failed**;
  `test_movement` **5/5 consecutive passes**. The test routes events through `Input.parse_input_event`
  (real viewport, GUI and touch-to-mouse emulation) rather than calling `_unhandled_input`.
  - Doing that exposed a real device-path bug: **Godot's emulated mouse press arrives before the touch
    press**, so on a phone the mouse branch owns touch input — and cancelled touches arrive there as a
    cancelled mouse release. The earlier direct-call test only exercised the path a phone does not use.
  - Mutation-proven: restoring the original input gate fails five named lost-swipe checks; reverting
    fixes #1 and #2 each fails its own named check.
  - The arrow was rendered in three arenas; it was near-invisible on Frozen Choir's pale ice until a
    dark outline was added.
- **Follow-ups:** device feel of burst strength and momentum cap; momentum has no visual cue yet.

## 2026-09-12 — Wall splash on impact; wall highlight removed

- **Who:** Claude Code (Opus 5)
- **Did:**
  - First built a glow that ran along the painted floor edge from the contact point. Rendering it
    showed two real problems — it floated on the stone, because the baked polygon sits a margin
    inside the painted edge, and it read as another slash — and a retune pushed it onto the edge.
  - The owner then asked for no wall highlight at all, just a splash where the Wisp hits. Replaced
    it with `WallSplashFx` and removed the old axis-aligned `WallFlash` rectangle entirely.
  - Tuned from captured frames: the first pass sat on top of the Wisp and read as a sparkle, so the
    fan was widened to 124°, droplets given more speed and less damping, and the splash pushed back
    onto the wall surface.
- **Files/systems:** `scenes/gameplay/wall_splash_fx.gd`, `scenes/gameplay/game_world.{gd,tscn}`,
  `tools/godot/test_wall_splash.gd`, `tools/godot/render_wall_splash_showcase.gd`, docs.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → **30 passed, 0 failed**. The new test
  asserts the splash fires on impact, sits closer to the wall than the Wisp, sprays into the floor,
  shrinks under Reduced Motion, and that **no `WallFlash` node or wall line exists**. Installed on
  the Galaxy S24: running in Obsidian Garden with zero script errors, Wisp resting on the painted wall.
  - The full suite caught a regression the targeted test did not: I had parented the pooled splash
    inside `EffectsLayer`, and `test_mutation_effects` counts that layer's children for Death Pulse.
    Fixed by following the existing `VfxPool` convention (sibling, not child).
- **Follow-ups:** device feel of the splash size; the impact squash still picks one of two presets by
  the dominant axis of the normal, so it is approximate on slanted walls.

## 2026-09-12 — Walls now follow each arena's painted floor

- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner saw the Ember Hollow rectangle's corners sitting over the lava and chose, from six
    options, to derive the wall from the art ([ADR-0011](decisions/0011-polygon-playfield-from-art.md)).
  - `tools/art/extract_floor_polygons.py` bakes a 24-vertex polygon per Rift. Four iterations, each
    from a real failure: ANDed thresholds gave an empty mask and the luminance cut excluded Frozen
    Choir's pale ice; a centre seed landed on Obsidian Garden's central rune; rays stopped on
    cracks; single rays spiked into the scenery.
  - Runtime: winding-based normals, resting edge excluded by **identity** (a distance skip swallowed
    short corner dashes), one `_resolve_dash()` shared by the dash and the aim preview, polygon rest
    snap and edge drift, polygon enemy containment, reform candidates sampled on the polygon, and
    every placement routed through `_place_on_floor()`. The rectangle stays as the design scale.
  - A parallel read-only mapping pass (5 agents) found two things I had missed: the polygon is not
    a superset of the rectangle (0/4 corners inside on four arenas — the rectangle overhung), and
    the painted floors reach above the HUD band. The bake now clamps the top to V 0.255.
- **Files/systems:** `tools/art/extract_floor_polygons.py`, `data/rifts/*.tres`,
  `scripts/utils/dash_geometry.gd`, `scripts/resources/rift_data.gd`, `scenes/player/wisp_player.gd`,
  `scenes/gameplay/game_world.gd`, `scripts/components/enemy_actor.gd`, `scenes/bosses/reaper_boss.gd`,
  `tools/godot/{test_dash_geometry,test_rift_rules}.gd`, docs.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → **29 passed, 0 failed**.
  - An on-boundary property test sweeps every edge of every real Rift against 16 directions
    (1,920 cases): the resolved aim points inward, the landing is forward on a different edge, and
    the inset polygon never empties.
  - A live test dashes in 8 directions in each of the five Rifts and asserts every landing is on
    the floor. **Proven to detect a regression**: with the polygon disabled it fails 77 ways.
  - Formation audit: 3,520 placements, 19 (2.7 %) corrected, zero formations collapsed.
  - Bugs caught along the way: `bounce(normal.orthogonal())` flipped the tangent and would have sent
    every reflected dash off the floor; and the rules suite had been running **frozen** — an earlier
    check's XP opened the upgrade picker, which pauses the tree, and freeing that GameWorld never
    unpaused it. That is also why the old drift check "passed": it silently skipped.
- **Follow-ups:**
  - **Not yet felt on device** — the phone dropped off adb before the new APK could be installed.
  - Impact squash and the wall flash still assume axis-aligned walls; approximate on slanted edges.
  - No live test drives the boss into Teleport Hunt, so boss teleport clamping is covered only by
    the shared `DashGeometry` tests.

## 2026-09-12 — Device run found three screen crashes; developer unlock card added

- **Who:** Claude Code (Opus 5)
- **Did:**
  - Built and installed the debug APK (72.6 MB, up from 53 MB with the new art) on the owner's
    Galaxy S24 and drove it with `adb input`. **Three real crashes the headless suite could not
    see:** `Main` configures a screen immediately after instancing it, *before* `_replace_screen()`
    puts it in the tree, so every `@onready` reference in `RiftMapScreen.setup()`,
    `SanctumScreen.setup()` and `TrialsScreen.setup()` was null. Screenshot fixtures missed it
    because loading a scene standalone runs `_ready()` first.
  - Fixed by making all three `setup()` calls order-independent: they store their arguments and
    defer the rebuild to `_ready()` when the node is not in the tree yet. `show_feedback()` on the
    Sanctum defers the same way.
  - Added `tools/godot/test_screen_setup_order.gd`, which reproduces Main's call order across six
    screens and asserts the **generated rows** exist — a whole-tree node count would have passed
    even with every row missing. Verified it actually catches the bug by reintroducing it
    (`trials built 0 rows, expected at least 3`) and then restoring the fix.
  - **Developer card in Settings** (owner request): unlock everything / all Rifts / all forms / max
    Sanctum / complete Trials / +5,000 shards, via `DevUnlock` and guarded
    `SaveManagerService.debug_*` methods. Gated twice on `OS.is_debug_build()` — the card is not
    built, and every method refuses independently — so GDD §13's "no debug panels in release" holds.
  - Corrected the Android launch command in AGENTS.md §4 and PROJECT_CONTEXT §6: the launcher
    activity is `GodotAppLauncher` and is **not exported**, so the documented
    `am start -n …/GodotApp` is denied by Android. Use `adb shell monkey … LAUNCHER 1`.
- **Files/systems:** `scenes/screens/{rift_map,sanctum,trials,settings}_screen.{gd,tscn}`,
  `scripts/autoload/save_manager.gd`, `scripts/utils/dev_unlock.gd`,
  `tools/godot/{test_screen_setup_order,test_dev_unlock}.gd`, `AGENTS.md`, docs.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → **29 passed, 0 failed**. On device:
  Home and the Rift Map render correctly at 1080×2340 and the log is clean of the three errors on
  the screens reached before the USB connection dropped.
- **Follow-ups:**
  - **The fixed build has not been re-run on device** — the phone disconnected from USB mid-session.
    Re-verify Sanctum, Trials and a full run before shipping.
  - Android back from the Rift Map appeared to exit the app rather than return Home. Not yet
    diagnosed; it may be an artefact of driving `KEYCODE_BACK` through `adb input`, or a real gap in
    `Main._handle_back()` for the new screens. **Worth checking first on the next device run.**

## 2026-09-12 — M7 and M9 built, M8 finished: Sanctum, Trials, portals, five bosses

- **Who:** Claude Code (Opus 5)
- **Did:**
  - **M7 complete.** *Soul Sanctum*: nine permanent nodes in a prerequisite tree, 8,970 shards to
    max, **0.167 combat power against a hard 0.20 budget that `validate()` enforces** — GDD §6's
    "must not trivialise a fresh start" is now a build failure, not a memo. *Trials*: 36 goals in
    12 tiers, three active at a time, rank up by clearing all three. *Depth milestones*: one-time
    rewards at waves 5/10/15/20/25. Plus an enemy arrival pop.
  - **M8 finished.** *Void portals* teleport a live dash to their pair, once per dash so the pair
    cannot loop it. *Five bosses* ([ADR-0010](decisions/0010-data-driven-boss-variants.md)):
    `BossData` carries atlas, tuning, tint and accent, and all four variants run the Reaper's
    proven three-phase machine rather than four hand-written ones. Base health escalates 6→15
    along the Rift ladder.
  - **M9 plumbing.** `MonetisationService` behind an injectable `AdProvider`; the shipped default
    is `NullAdProvider`, so `is_available()` is false and **no ad or purchase surface renders** —
    GDD §13's "no dead buttons, no fake purchases" still holds today ([ADR-0009](decisions/0009-monetisation-model.md)).
    Three rewarded placements, one Remove Ads product, consent gating, restore-safe shard grant.
  - Save schema **v2 → v5** across the three milestones, each step migrating older saves.
- **Files/systems:** `scripts/resources/{sanctum_node,sanctum_catalog,trial_data,trial_catalog,boss_data}.gd`,
  `scripts/utils/{sanctum_effects,trial_tracker}.gd`, `scripts/autoload/{save_manager,monetisation_service}.gd`,
  `scenes/screens/{sanctum,trials}_screen.*`, `scenes/gameplay/game_world.gd`,
  `scenes/player/wisp_player.gd`, `scenes/bosses/reaper_boss.gd`, `data/{sanctum,trials,bosses}/*`, docs.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → **27 passed, 0 failed**, with four
  new suites (`sanctum`, `trials`, `monetisation`, `boss_variants`). The rules suite now boots a
  live GameWorld per Rift and dashes through a portal to prove the transit.
  Bugs the tests caught: a depth-milestone test that silently depended on the shared isolated save
  persisting between suite runs (now uses its own save, and a repeat run confirms the fix); a
  `_refresh_combat_modifiers()` I invented that never existed; and a `_spawn_effect()` likewise.
- **Follow-ups:**
  - **No real ad SDK.** `AdProvider` needs the owner's AdMob/Play accounts, app ids, a privacy
    policy, a consent UI and signing — not doable from this repo. No monetisation UI exists yet,
    deliberately, so nothing inert ships.
  - Sanctum nodes are gated by shards and prerequisites, **not** by Rift level progress.
  - Per-Rift mission chains are still unbuilt; Rift unlocking remains wave-gated.
  - Nothing has been played on a device since these landed; the combined difficulty curve
    (per-wave × Rift level × post-boss tier) needs a real phone pass.

## 2026-09-12 — Wave-2 art integrated; seven enemies across five rosters

- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner delivered `wisp_rush_rifts_v2.zip` (The Fracture, the Cinder Maw, four arena enemies).
    Inspected the grid before wiring: the enemy sheet is four creatures of three poses laid out
    **row-major**, so a creature owns cells 3N..3N+2 and crosses the grid's row boundaries — the
    extractor groups by index triple, not by row. My wave-2 prompt had described it as "4 rows of 3"
    while specifying a 4×3 grid, which disagreed; the art follows the grid.
  - `extract_rifts.py` extended to 76 outputs: three 12-frame boss atlases at the Reaper's 444×444
    canvas, and Echo / Slag Hulk / Frost Wisp / Court Shade at 362×362.
  - The four new enemies reuse the Cinder Shade, Bone Mote and Shard Wraith behaviours with their
    own art, tuning and roster slot. All five Rifts now field visibly different rosters, and
    `test_rift_enemies.gd` fails if any Rift silently falls back to the baseline roster.
- **Files/systems:** `tools/art/extract_rifts.py`, `assets/art/characters/{the_fracture,cinder_maw,
  enemies}/`, `scenes/enemies/{echo,slag_hulk,frost_wisp,court_shade}.tscn`, `data/enemies/*`,
  `data/rifts/*`, `scenes/gameplay/game_world.gd`, docs.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → **23 passed, 0 failed**; extracted
  sprites reviewed on the dark ground they render against — consistent scale, clean alpha.
- **Follow-ups:** boss art is extracted but **no boss scene or phase machine exists for any of the
  three**, so every Rift still spawns the Reaper; `portals`, abilities, per-Rift missions, all of
  M7 and M9 remain.

## 2026-09-12 — Rift difficulty ladder, three enemies, three rule twists

- **Who:** Claude Code (Opus 5)
- **Did:**
  - Difficulty ladder ([ADR-0008](decisions/0008-rift-levels-and-difficulty-ladder.md)): 8 levels ×
    4 waves per Rift, threat ×1.00 at level 1 in **every** arena (validated, build fails above
    ×1.1) rising to ×1.84 in Obsidian Garden and ×2.75 in Reaper's Court, plus enemy speed
    ×1.00→×1.20. Levels advance mid-run on each boss defeat and persist as `rift_levels`.
  - Three enemy families from the delivered art: **Cinder Shade** (splits into two on death),
    **Warden** (140° shield arc blocks dashes into its plate, so it must be cut from behind),
    **Rift Spawn** (only the tether between its two bodies is damageable).
  - Per-arena rosters via `RiftData.enemy_substitutions`, so the 20 authored formations are reused
    rather than duplicated.
  - Rule twists: **boss_rush** (Reaper's Court — half the boss cadence, double rewards),
    **shrinking_floor** (Ember Hollow — the playfield contracts to 74 % across a level),
    **drift** (Frozen Choir — the resting Wisp slides along its edge and reverses at corners).
- **Files/systems:** `scripts/resources/{rift_data,rift_catalog,enemy_tuning}.gd`, `data/rifts/*`,
  `data/enemies/{cinder_shade,warden,rift_spawn}.tres`, `scenes/enemies/*`,
  `scenes/gameplay/{game_world,wave_director}.gd`, `scenes/player/wisp_player.gd`,
  `scenes/screens/rift_map_screen.gd`, `scripts/autoload/save_manager.gd`, docs.
- **Verified:** `tools/validate.sh` → OK (57 scripts); `tools/run_tests.sh` → **23 passed, 0 failed**,
  including two new suites. `test_rift_rules.gd` boots a live GameWorld per Rift and asserts the
  boss cadence halves, the floor actually contracts (and leaves the Wisp inside it), and the
  resting Wisp slides — the twists are verified in a running game, not just parsed.
  Two real bugs caught by the tests: the Warden scene was missing the `hit` animation EnemyActor
  plays, and a mis-anchored patch left `game_world.gd` calling a `set_edge_drift()` that did not
  exist — a crash that only fires inside a run, so validation alone would not have caught it.
- **Follow-ups:**
  - **`portals` (Shattered Rift) is still unimplemented** — the one remaining rule twist; art ready.
  - Per-Rift bosses still fall back to the Reaper; `the_fracture` and `cinder_maw` await art
    (`GENERATION_PROMPTS_WAVE2.md`), Hollow Choir has art but no scene or phase machine.
  - Abilities, per-Rift missions, all of M7, and M9 remain.
  - Substitution raises real difficulty without changing authored `threat_cost`; intentional for
    higher tiers but unmodelled — worth a device pass.

## 2026-09-12 — Rifts: five arenas, the map UI, and the M8 art pack

- **Who:** Claude Code (Opus 5)
- **Did:**
  - Direction agreed with the owner: keep one endless mode and layer engagement around it.
    ROADMAP gained M7 (engagement core), M8 (Rifts and bosses) and M9 (monetisation: opt-in
    rewarded video plus one remove-ads IAP, never interstitials).
  - Wrote `concept_art/wisp_rush_rifts_v1/GENERATION_PROMPTS.md` (7 sheets) for the owner to run
    through Codex image generation; owner delivered `wisp_rush_rifts_v1.zip`.
  - New reproducible pipeline `tools/art/extract_rifts.py` → 40 runtime files: 4 Rift backdrops,
    12 props, 12 new-enemy frames, 12 Hollow Choir frames. Frozen Choir's ice floor was brighter
    than the Wisp (breaks the STYLE_GUIDE's first rule) so it is dimmed 0.52 inside the playfield;
    Shattered Rift's magenta is desaturated to 0.72 so it stops competing with enemy cores.
  - Rifts system ([ADR-0007](decisions/0007-rifts-as-rule-variant-arenas.md)): `RiftData` /
    `RiftCatalog` + five `.tres`, save schema **v2** (`selected_rift`, `rift_bests`, v1 migration),
    a Rift map screen built from the catalog, a Home entry, and a GameWorld backdrop swap.
    Unlock is derived from lifetime `highest_wave`, so it cannot desync.
- **Files/systems:** `scripts/resources/rift_{data,catalog}.gd`, `data/rifts/*`,
  `scenes/screens/rift_map_screen.*`, `scenes/main/main.gd`, `scenes/screens/home_screen.*`,
  `scenes/gameplay/game_world.gd`, `scripts/autoload/save_manager.gd`, `tools/art/extract_rifts.py`,
  `tools/godot/test_rift_catalog.gd`, docs.
- **Verified:** `tools/validate.sh` → OK (52 scripts); `tools/run_tests.sh` → **21 passed, 0 failed**
  (new `test_rift_catalog`, and `test_save_manager` extended with v1→v2 migration coverage);
  Rift map and Home captured at 1080×1920 and reviewed. `test_rift_catalog` asserts every backdrop
  is exactly 941×1672, the constraint `ARENA_FLOOR_UV` depends on.
- **Follow-ups:**
  - **No rule twist is implemented** — `rule_key` is latched and read by nothing, so all five Rifts
    play identically. The map advertises rules the game does not honour; not shippable to players
    in this state.
  - New enemies and the Hollow Choir are **art only** — no tuning, behaviour or scene. Recorded as
    GDD §14 assumptions #9–10 because the GDD never specified them; owner may reject or redesign.
  - M7 (Soul Sanctum, Trials ladder, depth milestones) and per-Rift mission chains not started.
  - README "Current build" still claims Milestone 2; PROJECT_CONTEXT §4 still says no autoload is
    needed; `tests/` is still an empty folder. Pre-existing drift, not fixed here.

## 2026-09-12 — Playfield inset and larger sprites
- **Who:** Claude Code (Opus 5), at the owner's decision (both options)
- **Did:**
  - Playfield is now the painted stone floor: `ARENA_FLOOR_UV` (measured from the arena art) mapped
    through the backdrop cover-scale, clamped to the screen and a minimum fraction; HUD margins moved
    back to screen space; the wall-impact flash now draws on the playfield edge (ADR-0006).
  - Sprites and hitboxes scaled together: player and enemies ×1.45 (player radius ratio 0.03 → 0.05,
    min/max 30/70), hazards, Reaper body/core and Soul Shard pickups ×1.3. Reaper attack geometry
    left as tuned — the smaller arena already makes it relatively larger.
- **Files/systems:** `scenes/gameplay/game_world.gd`, `data/player/*`, `data/enemies/*`,
  `data/hazards/*`, `data/bosses/default_reaper.tres`, `scenes/pickups/soul_shard_pickup.gd`.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed; gameplay,
  tutorial and upgrade captured at all 5 phone sizes — the Wisp now rests on stone inside the floor,
  enemies read clearly, and nothing sits under the HUD. Android APK rebuilt.
- **Follow-ups:** feel check on the device (dash distances are shorter now); dark icons, number
  formatting and the missing back-chevron icon are still open.

## 2026-09-12 — Android device build; fixed an audio crash on device
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Set up the Android debug build: installed Godot 4.7.2 Android export templates, created a local
    debug keystore, added the "Android" preset (arm64, portrait, `com.cognitix.wisprush`), enabled
    ETC2/ASTC VRAM compression, set the JDK path in Godot's editor settings, and added a
    `concept_art/.gdignore` so sources never enter imports or the APK. APK: 53 MB.
  - Installed and launched it on the owner's Galaxy S24 (Android 16, 1080×2340) over USB.
  - **Crash fix:** the game died with SIGSEGV in the Android AudioTrack thread inside Godot's WAV
    mixer. `AudioSynth.build_stream()` set `loop_end` to the total frame count — one past the last
    frame — and the mixer interpolates one frame ahead, so it read off the end of the buffer. Now
    every stream gets two silent guard frames and `loop_end` points at the first guard frame;
    `test_audio_service.gd` asserts both (415 checks).
- **Files/systems:** `scripts/utils/audio_synth.gd`, `tools/godot/test_audio_service.gd`,
  `export_presets.cfg`, `project.godot`, `concept_art/.gdignore`, docs.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed; on the device
  the rebuilt APK ran 90 s with the 8 s music loop wrapping ~11 times — no crash, no SIGSEGV in
  logcat, process alive.
- **Follow-ups:** owner still to decide the gameplay composition (small Wisp/enemies, playfield under
  the HUD); iOS preset, launcher icons and release signing remain open.

## 2026-09-11 — Redesign v1 integrated
- **Who:** Claude Code (Opus 5) orchestrating a 10-agent workflow (assets, design system, 7 restyle agents, verify)
- **Did:**
  - Archived the owner asset pack v2 to `assets/legacy_v1/` (`.gdignore`) and regenerated every
    runtime art path from `concept_art/wisp_rush_redesign_v1/` with `tools/art/extract_redesign.py`
    (112 outputs; checkerboards matted out of the form and prop sheets; VFX converted to alpha;
    content normalised to legacy canvases so gameplay scale and collision fit are unchanged).
  - Built the project Theme (`assets/ui/theme/wisp_theme.tres`) from the stone frame kit with named
    type variations and `Palette` constants; restyled Home, Forms, Daily Rift, Results, HUD, pause,
    confirm, upgrade cards, tutorial, Settings, Statistics and Loading to the six-screen board.
  - Recoloured gameplay telegraphs (amber warnings, magenta execution), Death Pulse tint from the
    form; set the redesign boot splash; ADR-0005; GDD §9 rewritten; registry and docs updated.
- **Files/systems:** `assets/**`, `tools/art/**`, `assets/ui/theme/**`, `scripts/utils/palette.gd`,
  all `scenes/screens/*`, `scenes/gameplay/game_world.*`, gameplay prefabs, `data/forms/*.tres`, `project.godot`.
- **Verified:** `tools/validate.sh` → OK (49 scripts); `tools/run_tests.sh` → 20 passed, 0 failed;
  `tools/qa_matrix.sh` → 50/50 phone captures reviewed against the board (no overlap, clipping or
  checker remnants); Reaper render checked; no references to `assets/legacy_v1`.
- **Follow-ups:** owner decision on gameplay composition (Wisp/enemies too small, playfield edges on
  scenery and behind the HUD); dark icons; number formatting; back chevron; Statistics empty space on
  tall phones.

## 2026-09-11 — Milestone 5: polish pass (pre-release)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner decisions recorded: no store release yet, phones only, planned id `com.cognitix.wisprush`.
    Real save moved to `user://save_backup_2026-09-11/` (reversible reset; fresh first-run experience).
  - Added a reproducible phone QA matrix (`tools/qa_matrix.sh`, `qa_capture.gd`, `qa_contact_sheet.gd`)
    and reviewed 10 screens at 5 phone aspect ratios. Layout fixes: phone readability pass — 40 small labels raised from 16–20 to 22–26 design px (HUD, Daily, Forms, Home, Results, upgrade cards, tutorial) with HUD offsets retuned; no clipping or overflow at any phone size.
  - Polish: 0.22 s fade-in on every screen change, press dip/spring on all buttons (`UiJuice`), Home
    footer shows the project version, removed the stale "TRAINING" HUD label.
  - Added `tools/godot/bench_stress.gd`: windowed on the M2 at 390×844 with vsync off: avg 2.4 ms, p95 3.6–3.9 ms at both 10 and 45 enemies, but 3–4 isolated 37–44 ms spikes per 840 frames regardless of load — check for first-use hitches on a real phone.
- **Files/systems:** `scenes/main/main.gd`; `scripts/utils/ui_juice.gd`; `scenes/screens/home_screen.*`;
  `scenes/gameplay/game_world.{gd,tscn}`; `tools/qa_matrix.sh`; `tools/godot/{qa_capture,qa_contact_sheet,bench_stress}.gd`.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed; `tools/qa_matrix.sh` → 50/50 phone captures clean after the fixes (all 10 contact sheets reviewed); benchmark numbers above; tooling runs use the isolated `user://test_runs/` save.
- **Follow-ups:** owner discussion on direction/monetisation; art re-export; audio listening and
  device feel pass.

## 2026-09-11 — Milestone 4: product surface, audio and feel
- **Who:** Claude Code (Opus 5) with one Claude sub-agent (audio)
- **Did:**
  - Audio: 18 runtime-synthesized SFX and 3-layer adaptive music (pad / combo-driven pulse / boss)
    on Master/Music/SFX/UI buses via the `Audio` autoload; ducking on pause and interruption (ADR-0004).
  - Screens: boot Loading (threaded streaming, ≤ 6 s), Settings (volumes, shake, haptics, reduced
    motion, tutorial replay, Privacy & About, armed 2-step reset), Statistics, Home Stats/Settings,
    Results Wisp Forms button and NEW BEST.
  - Feel: trauma shake (2–12 px per the prompt), 60 ms hit-stop on triple reaps, haptics, pooled
    form-tinted VFX (dash trails, soul slice, dissolve, large impact), Reaper and gameplay sound cues —
    all honouring Reduced Motion and Screen Shake.
  - Lifecycle: auto-pause on focus loss/backgrounding, Android back + Escape routing
    (`quit_on_go_back=false`), pause menu Restart/Settings with confirmation for meaningful runs,
    debug-build-only F3 performance overlay.
- **Files/systems:** `scenes/main/main.gd`; `scenes/gameplay/game_world.{gd,tscn}`;
  `scenes/screens/{loading,settings,statistics,home,results}_screen.*`; `scenes/bosses/reaper_boss.gd`;
  `scripts/autoload/{audio_service,save_manager}.gd`; `scripts/utils/{audio_synth,haptics,sound_fx}.gd`;
  `scripts/components/vfx_pool.gd`; `scenes/debug/debug_overlay.gd`; `default_bus_layout.tres`; `project.godot`.
- **Verified:** `tools/validate.sh` → OK (45 scripts); `tools/run_tests.sh` → 20 passed, 0 failed
  (new `test_m4_systems`, `test_audio_service`); real-driver audio smoke on CoreAudio (every SFX,
  voice stealing, music layers, ducking) without errors; windowed boot Loading 1.16 s → Home;
  visually inspected Loading, Home, Settings, Statistics, pause menu, abandon-run confirmation and
  in-run Settings (reset hidden); real save byte-identical after validate + tests.
- **Follow-ups:** device pass for performance, shake/haptic strength and audio mix (sounds were
  designed numerically, not by ear); windowed boot warns "6 ObjectDB instances leaked at exit";
  art re-export and licence still open.

## 2026-09-11 — Milestone 3 close-out: Reaper, saves, forms, daily
- **Who:** Claude Code (Opus 5), resuming after Codex ran out of quota mid-milestone
- **Did:**
  - Audited Codex's unlogged Milestone 3 work: recurring three-phase Reaper (every 4 waves) with a
    harder post-boss tier, SaveManager autoload (ADR-0003), six forms with purchase/equip, Rift of
    the Day with three date-seeded challenges, Home Forms/Daily entry points.
  - Fixed `test_main_progression_flow`, which hung forever: it created a second SaveManager that
    Main never used, and read a non-existent `World/WispPlayer/FormSprite` path. Fixed the same
    duplicate-autoload bug in `test_game_flow`.
  - Stopped automated runs from overwriting the owner's real save:
    `SaveManagerService.uses_isolated_storage()` routes `--script` tests and `WISP_ISOLATED_SAVE=1`
    tool runs (validate/screenshot) to `user://test_runs/`.
  - Added `tools/run_tests.sh` (all headless tests, per-test timeout — a hung test now fails instead
    of blocking) and `tools/godot/render_reaper_showcase.gd`; registered SaveManager, the M3 scenes,
    `bosses` group and the three new resource types; closed the four M3 system docs.
  - Fixed the boss HUD overlapping the run-level label when a top safe-area inset applies:
    `BossHud` now follows the inset in `GameWorld._layout_safe_hud()`.
- **Files/systems:** `scripts/autoload/save_manager.gd`; `tools/godot/test_{game_flow,main_progression_flow}.gd`;
  `tools/{run_tests,validate,screenshot}.sh`; `scenes/gameplay/game_world.gd`; Reaper boss, Save manager, Cosmetic forms, Daily/challenges.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 18 passed, 0 failed; the real save
  was byte-identical before/after a full validate + test run. Visually inspected Home (Forms/Daily
  Rift buttons), Forms, Rift of the Day and the Reaper encounter at 540×960 (re-rendered after the HUD fix).
- **Follow-ups:** the real `user://wisp_rush_save.json` already holds test-run data from before the
  fix (4 runs, best 345, today's daily done) — owner decides whether to reset it. Title logo, Void form and all eight Reaper PNGs have a grey checkerboard painted into their semi-transparent halos, and several Reaper cells (e.g. scythe strike) clip the art at the 444 px cell edge; the master sheet has the same cuts, so this needs a clean re-export from the art source.
  Milestone 4 is next.

## 2026-09-11 — Complete resource-driven endless run
- **Who:** Codex (GPT-5)
- **Did:**
  - Added a deterministic threat-budget WaveDirector and 20 validated normalized formations with
    mirrored/rotated variants, health context and staged enemy/hazard introductions.
  - Added shared regular-enemy behavior plus the two-hit Shard Wraith and three-hit Bone Mote;
    added warned split-crystal, spike-bloom and blade-ring hazards with swept dash resolution.
  - Added run XP, a safe paused three-card choice, all eight production-icon mutations, Soul Shard
    drops/collection and mutation effects across dash, enemies, health, score and pickups.
  - Expanded score/reward tracking, HUD and Results with session best/currency, wave, multi-reap
    and boss fields; synchronized the roadmap, GDD assumption, registries and system docs.
- **Files/systems:** `scenes/{gameplay,enemies,hazards,pickups,player,screens,main}/`;
  `scripts/{components,resources}/`; `data/{enemies,formations,hazards,mutations,progression,waves}/`;
  Wave director, Enemies, Arena hazards, Run progression, Core run, Player dash/health, Game flow.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (28 game scripts, 0 failures); all 12 headless
  test scripts passed, covering geometry, health/death, tutorial/navigation, live scoring, 20
  formations, 1/2/3-hit enemies, hazard states/live dash blocking, XP choices and all eight mutation
  effects. Direct Godot runs had no errors. Visually inspected the HUD/tutorial, full M2 roster,
  three-card upgrade overlay and expanded Results at the 1080×1920 design output.
- **Follow-ups:** build the three-phase Reaper and post-boss cycle; add versioned local persistence
  for best/tutorial/Soul Shards; complete physical-device QA, audio and asset-license confirmation.

## 2026-09-11 — Health, tutorial and complete vertical-slice loop
- **Who:** Codex (GPT-5)
- **Did:**
  - Added reusable clamped health, three Soul Fragments, exposed-state enemy contact, combo reset,
    safest-edge reform, hurt/i-frame feedback and the timed Wisp death dissolve.
  - Added the non-blocking first-run lesson: wall dash, telegraphed single slice, then a retryable
    aligned triple reap; completion is remembered for the current app session.
  - Added run statistics and a production-art Results screen with score, kills, best chain,
    Restart and Home, completing the Milestone 1 play loop.
  - Added unit/live checks for health, contact/death, tutorial progression and Results/restart flow.
- **Files/systems:** `scripts/components/health_component.gd`; `scenes/{player,enemies,gameplay,tutorial,screens,main}/`;
  `data/player/`; `tools/godot/`; Player health, Tutorial, Core run, Game flow, Enemies, Player dash.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (11 game scripts, 0 failures); health component
  6/6; live contact → i-frames → death → one summary; tutorial wall dash → single slice → triple
  reap; Home/Pause/Home → Results → tutorial-gated Restart; original four-kill dash still scored
  310 with combo 4. Visually inspected tutorial/HUD and Results at the 1080×1920 design output.
- **Follow-ups:** begin Milestone 2 WaveDirector/data formations, extra enemies/hazards, XP and
  mutation choices; persist tutorial completion with SaveManager in Milestone 3; physical-device
  cutout/touch QA; confirm art license and final audio path before release.

## 2026-09-11 — Prompt intake and playable dash slice
- **Who:** Codex (GPT-5)
- **Did:**
  - Reconciled the standalone and archived v2 prompts (identical SHA-256), replaced the GDD
    template with the release-MVP specification and sequenced Milestones 1–5.
  - Imported 86 production PNGs into the project naming/layout; excluded master/reference/legacy
    files and recorded the missing license/audio as release follow-ups.
  - Built full-bleed Home and GameWorld scenes, responsive HUD/pause flow, typed tuning Resources,
    touch/mouse/keyboard Wisp aiming, exact edge dashes, wall focus, Soul Wisp steering, swept
    collision, score/combo and multi-reap feedback.
  - Added pure dash-geometry, live gameplay-slice and top-level navigation checks; updated the
    screenshot helper to exercise explicit window aspects.
- **Files/systems:** `project.godot`; `assets/art/`; `data/`; `scenes/{main,screens,gameplay,player,enemies}/`;
  `scripts/{resources,utils}/`; Game flow, Player dash, Core run, Enemies; GDD/ASSETS/ROADMAP/README.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (8 game scripts, 0 failures); dash geometry 4/4;
  live first dash killed four enemies and settled at an edge (`score=310`, `combo=4`); Pause/Resume
  and Home → Play → Pause → Home passed. Visually inspected Home and arena at 540×960. Direct Godot
  runs produced expanding arenas without errors at 320×568, 360×800, 375×812, 390×844, 412×915,
  768×1024 and 1280×720.
- **Follow-ups:** add health/contact/death/results and first-run tutorial; replace the training
  formation loop with WaveDirector data; confirm art license; choose final audio path; use physical
  phone/tablet QA for density, cutouts, touch latency, haptics and performance.

## 2026-09-11 — Project setup
- **Who:** Claude Code (Opus 5), setup session
- **Did:**
  - Created the Godot 4.7 project at the repo root: feature-based folders, `project.godot`
    (typed-code warnings on), bootstrap scene `scenes/main/main.tscn`, icon.
  - Added tooling: `tools/validate.sh` (import → parse all scripts → boot → map),
    `tools/project_map.mjs` (generated inventory), `tools/screenshot.sh` (frame capture),
    `tools/godot/check_scripts.gd`.
  - Connected the Godot MCP server (Coding-Solo/godot-mcp 0.1.1, pinned in `tools/mcp/`) — ADR-0002.
  - Wrote the agent docs: AGENTS.md, CLAUDE.md, PROJECT_CONTEXT (map + documentation rules),
    CONVENTIONS, GDD/ASSETS/ROADMAP templates, ADR-0001; Claude Code subagents
    (playtester, gdscript-reviewer, docs-keeper) and skills (run-game, new-system, update-docs).
- **Files/systems:** whole repo (initial).
- **Verified:** `tools/validate.sh` → OK. A deliberately broken script made it FAIL (exit 1) as
  expected. MCP `get_godot_version` returns 4.7.2; `run_project` + `get_debug_output` show
  `[Main] boot ok` (only after enabling `flush_stdout_on_print` — see ADR-0002). `claude mcp get
  godot` → ✔ Connected. `tools/screenshot.sh` captured the label correctly.
- **Follow-ups:** waiting for the owner's game prompt (→ GDD) and asset folder (→ ASSETS intake).
  Choose a test framework when the first testable system exists.
