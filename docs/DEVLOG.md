# Devlog

> Append-only session log, **newest first**. One entry per work session; format in
> [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) §7.6. Keep entries short — details belong in the docs
> they changed.

## 2026-10-02 — The full-screen board in the game: BOARD 01
- **Who:** Claude Code (Opus 5.5), working on while the owner was away
- **Owner:** Codex built the board's pieces; "implement", then commit and push everything to GitHub
  and update the docs; "work in a loop while I'm gone" (GDD §14 #72).
- **Did:** ADR-0024. `BoardArenaVisual` builds the board at run time from the pieces
  (`tools/art/make_board.py` copies Codex's 59 pieces, checked against its manifest, to
  `assets/art/environment/boards/board_01/`): tiled floor with a few variant slabs, posts, beams,
  corners, caps and the wall line, decorations, and the HUD in the frame (pause, boss plate or crest,
  score, Rift Points, soul gauge with the level, RUSH gauge with its flare, four lanterns that glow for
  upgrades, a count tag). `ArenaVisual` gained `has_board_hud()`, `set_board_hud()` and
  `hud_pause_pressed`. GameWorld, on a board, moves its HUD bars and buttons under a hidden holder,
  feeds the board each frame, shows `UpgradeGlow` on the character while upgrades are ready and opens
  the cards on a tap that starts on him; the resume button only takes focus when the pause button is
  visible. Slots BOARD 01 (mid-dark floor) and BOARD 01 LIGHT (the reference's lighter floor): scenes,
  Shop stills, skins, catalog, save ids; `test_endless_catalog` checks which arenas draw the HUD.
- **Claude's choices:** the two slots and their names, the other arenas keeping the floating HUD, every
  value in ADR-0024's Consequences, and committing on the branch `feat/board-and-arenas-catch-up`
  (CONVENTIONS §12) — first a catch-up commit of all the uncommitted work since df1956d, then this one;
  Codex's local `.codex-remote-attachments/` was left out of git.
- **Files/systems:** `scenes/arenas/{arena_visual,board_arena_visual}.gd`, `scenes/arenas/board_01*.tscn`,
  `scenes/gameplay/{game_world.gd,upgrade_glow.gd}`, `tools/art/make_board.py`,
  `assets/art/environment/{boards/board_01/,arenas/board_01*}`, `concept_art/arenas_v2/board_01*/`,
  `data/endless/`, `scripts/autoload/save_manager.gd`, `tools/godot/test_endless_catalog.gd`; docs:
  ADR-0024, GDD §4, §6, §14 #71–#72, core_run, endless_mode, arena_art §6, ASSETS, PROJECT_CONTEXT.
- **Verified:** `validate.sh` OK (one earlier run printed FAILED with an empty error log and every step
  clean, as before); `test_endless_catalog` (8 arenas) and `test_game_flow` pass. A render at
  1080 × 2340 with sample values showed every HUD piece in its slot and the floor 936 × 1990. A scratch
  run on BOARD 01: the board took over the HUD (the pause button under the hidden holder), the arena rect
  was the board's floor, the light showed with upgrades banked and the cards closed, a tap on the
  character opened them, and the board's pause paused the run. A bot run (`render_gameplay_clip.gd
  skin=board_01`) showed the board with live score, gauges and the light; it also showed the light
  staying after the run ended, fixed (no light once the run is over or the cards are open). APK built;
  the phone was not connected, so it is not installed.
- **Follow-ups:** install, and the owner's phone test: the board's look and sizes, which floor, the HUD
  readability (the pixel font's 5 reads like an S at this size), tapping the character, the light. The
  branch is pushed, not merged into `main`.

## 2026-10-02 — Portrait only; the full-screen board's Codex prompt
- **Who:** Claude Code (Opus 5.5)
- **Owner:** the game is played vertically only, never horizontally or in landscape (record it or make
  the game not rotate); the board is full screen like the owner's reference image, in pixel art with
  "not too big pixels", with the HUD built into it (RUSH, soul level, boss indicator, Rift Points,
  score, pause), and the upgrades opened by tapping the character, whose light and the board show an
  upgrade is ready; a prompt for Codex for every piece, stored where Claude can find it (GDD §14 #71).
- **Did:** checked the lock: `project.godot` has `display/window/handheld/orientation=1`, and the built
  APK's manifest (`aapt dump xmltree`) has `android:screenOrientation` 0x1, portrait, so nothing in the
  build changed. Wrote the rule into AGENTS.md §2, PROJECT_CONTEXT §1 and GDD §12. Saved the owner's
  image to `concept_art/boards_v1/board_01/reference/` and wrote `CODEX_PROMPT.md` there: pixel scale,
  layout, every piece with its size and folder, previews, `manifest.json` with the empty text and fill
  rectangles, and a checklist.
- **Claude's choices in the prompt:** listed in GDD §14 #71 (1 art pixel = 2 game pixels, frame sizes,
  the slots, the floor kept mid-dark with a light variant to compare, gauge colours).
- **Files/systems:** `AGENTS.md`, `docs/{PROJECT_CONTEXT,GDD,ASSETS}.md`, `concept_art/boards_v1/board_01/`.
- **Verified:** docs and source files only; the orientation read from the built APK.
- **Follow-ups:** Codex makes the pieces; then Claude builds the board, the HUD in it and the
  tap-to-upgrade in the game. The reference's floor is a light tan; the arena guide asks for a mid-dark
  floor, so the prompt asks for both to compare.

## 2026-10-02 — The zoom arena fills the screen; play again skips the zoom
- **Who:** Claude Code (Opus 5.5)
- **Owner:** on the 3D ZOOM ARENA: "overall, I like it"; the textures "should be much more polished";
  keep the HUD where it is; the arena should "fill up the whole screen ... for now"; playing again
  from the dialog after dying should not replay the zoom, "just make the user come back and play"
  (GDD §14 #70).
- **Did:** `ModelArenaVisual.play_fills_screen` (on): zoomed in, the floor is as big as the whole
  screen allows, centred, with the HUD over it (about 1080 × 2338 on 1080 × 2340; on 16:9 the floor
  fills the height and the frame shows at the sides). `GameWorld.play_arena_intro`: off, the arena
  starts zoomed in (`skip_intro()` before it starts) and the waves start at once; Main's
  `_restart_run` (Results' PLAY AGAIN and the pause menu's restart, which share it) builds the next
  run with it off; Home resets it. `ModelArenaVisual.skip_intro()` now also ends an opening shot
  that has not started.
- **Files/systems:** `scenes/arenas/{arena_visual,model_arena_visual}.gd`, `scenes/gameplay/game_world.gd`,
  `scenes/main/main.gd`; docs: GDD §6, §14 #70, ADR-0023 Addendum, core_run, endless_mode, arena_art §5,
  PROJECT_CONTEXT.
- **Verified:** `validate.sh` OK (one run printed FAILED with an empty error log and every step's
  scripts clean; the next run was OK); `test_endless_catalog` and `test_game_flow` pass. A scratch
  check built the zoom arena's run twice: fresh, the zoom plays with the waves waiting and the Wisp
  hidden; as a replay, no zoom, waves started, the floor already the full-height play floor. A bot run
  (`render_gameplay_clip.gd`) reported `arena=(887.0, 1920.0)` on 1080 × 1920 and showed the floor
  filling the height with the HUD over it. APK built; the phone was not connected, so it is not
  installed.
- **Follow-ups:** install it; the texture polish (how: owner to decide). With the floor at the screen's edge, the
  top wall sits under the HUD's buttons and the status bar.

## 2026-10-01 — The zoom intro: 3D ZOOM ARENA
- **Who:** Claude Code (Opus 5.5)
- **Owner:** in a design talk, the lore direction "you play the game in a simulation", the owner to
  design the first arena, one arena and fewer bosses for release with more added before it, and what
  is not redesigned removed later — "for now, keep it like this" (nothing removed). Then: a run shows
  the whole arena, then slowly zooms in until the playable area is as big as the screen, tested on a
  new slot from the 3D arena. From Claude's options: the slot 3D ZOOM ARENA, the character and enemies
  grow with the floor, the floor fills the space under the HUD, the zoom every run with a tap to skip
  (GDD §14 #69).
- **Did:** ADR-0023 Addendum. `ArenaVisual`: `intro_finished`, `has_intro`, `play_intro`,
  `skip_intro`, `get_drawn_floor_rect`. `ModelArenaVisual.zoom_intro`: `fit()` returns the floor as big
  as the screen allows under the HUD; the camera starts on the whole model and moves, never turning, to
  the camera that draws that floor (eased on the floor's drawn size), Reduced Motion cuts to the end;
  `_camera_moved` hook (the Colossus's fog follows the camera). GameWorld `_begin_run` plays it with the
  Wisp and HUD hidden and steering off, a tap skips it, and on `intro_finished` they fade in (0.35 s)
  and the waves start; `SafeHud` got a unique name. `scenes/arenas/zoom_arena_3d.tscn` (the Colossus
  scene with `zoom_intro`), its still, skin, catalog, save id; `render_arena_still.gd` prints the drawn
  and the play floor; the cloud banks fade at their bottom edge (a hard line showed in the opening
  shot), both 3D stills re-rendered; `test_endless_catalog` checks the zoom arena.
- **Claude's choices:** every value in the Addendum (0.8 s hold, 2.5 s zoom, the model at 0.86 of the
  screen's height first, the floor 280 px under the safe top, 24/40 px margins, 0.35 s fade), the Shop
  line, Reduced Motion skipping the zoom.
- **Files/systems:** `scenes/arenas/{arena_visual,model_arena_visual,chained_colossus_3d}.gd`,
  `scenes/arenas/zoom_arena_3d.tscn`, `scenes/gameplay/game_world.{gd,tscn}`,
  `assets/shaders/arena_cloud_bank.gdshader`, `data/endless/{default_endless_catalog.tres,skins/zoom_arena_3d.tres}`,
  `scripts/autoload/save_manager.gd`, `tools/godot/{render_arena_still,test_endless_catalog}.gd`,
  `concept_art/arenas_v2/{zoom_arena_3d,chained_colossus_3d}/`, `assets/art/environment/arenas/`; docs:
  ADR-0023, GDD §6, §14 #69, core_run, endless_mode, arena_art §5, ASSETS, PROJECT_CONTEXT.
- **Verified:** `validate.sh` OK; `test_endless_catalog` (6 arenas) and `test_game_flow` pass. A bot run
  on the zoom arena (`render_gameplay_clip.gd skin=zoom_arena_3d`) logged `arena intro`, `arena intro
  done`, then waves and kills; its frames show the whole colossus, the zoom, the board filling the
  screen and play with bigger characters. That tool reports leaked objects at exit on the Quarry Titan
  too (14), so not from this change. APK built, installed and launched on the owner's phone (`RFCX2035YHT`).
- **Follow-ups:** the owner's phone test of the zoom (its pace, the hold, the tap to skip)
  and of play on the big floor. The bottom instruction line ("DRAG TO AIM") now sits over the floor's
  lower edge on this arena.

## 2026-09-30 — The Chained Colossus 3D: the first 3D arena
- **Who:** Claude Code (Opus 5.5)
- **Owner:** the Meshy model (`Meshy_AI_Chained_Titan_s_Gameb_0930163022_texture.blend`) and an image
  of how the arena shall look: implement the model in the arena, create the background scenery, add
  the blue flames with Godot, rig the head for slow, steady breathing, and make the arena a little
  bigger than "the Patchvile-looking arena"; then "it doesnt have to be pixel rendered". From Claude's
  options: bigger than Stitchwarden's Vigil, keep the image arena beside it, add the glowing skulls
  (GDD §14 #68). This replaces the earlier Vigil 3D approach questions, which were not answered.
- **Did:** ADR-0023. `ArenaVisual` base (GameWorld hosts it; `LayeredArenaVisual` now extends it);
  `ModelArenaVisual` (SubViewport 3D world, camera placed so the model's floor is the returned rect,
  head-bone breathing) and `ModelArenaLayout`. `build_colossus.py` (Blender 5.2 headless): floor
  measured by front ray casts (plane y −0.259, rect x −0.268…0.144, z −0.594…0.298), eye found in the
  colour texture, 337,015 → 84,253 triangles with the floor's 1,846 vertices protected, a `root`/`head`
  rig, GLB + layout. `chained_colossus_3d.tscn/.gd`: night sky and moon, four cloud banks, two arches,
  26 floating shards, GPU-particle blue ghost fire along the outline, six skulls, the eye's glow; six
  shaders, each effect discarded over the floor. `render_arena_still.gd` for the Shop still; skin,
  catalog, save ids; `test_endless_catalog` takes any `ArenaVisual` and checks the Colossus 3D's floor
  against the Vigil's on 1080-wide phones.
- **Claude's choices:** every value in ADR-0023's Consequences (floor 0.461 of the width, eye 230 px
  under the safe top, 25° field of view, breath 4.8 s / ±1.2° / 0.004 rise, decimation, lights, fog,
  glow, MSAA 2×, effect counts, sizes, colours and placements, skulls where the owner's image has
  them); the name CHAINED COLOSSUS 3D, the Shop line, tier Simple, the amber accent, free like #67.
- **Files/systems:** `scenes/arenas/{arena_visual,layered_arena_visual,model_arena_visual,chained_colossus_3d}.*`,
  `scripts/resources/{model_arena_layout,arena_skin_data}.gd`, `scenes/gameplay/{game_world,arena_rules}.gd`,
  `assets/shaders/{arena_3d_common.gdshaderinc,arena_night_sky,arena_cloud_bank,ghost_flame,ghost_skull,ghost_glow}.gdshader`,
  `assets/art/environment/arenas/chained_colossus_3d/` (+ still, thumbnail), `concept_art/arenas_v2/chained_colossus_3d/`
  (source `.blend` 38 MB, `build_colossus.py`, `arena.json`, `source.png`, `model_report.json`),
  `data/endless/`, `scripts/autoload/save_manager.gd`, `tools/godot/{render_arena_still,test_endless_catalog}.gd`;
  docs: ADR-0023 (+ ADR-0018, ADR-0021 status lines), GDD §6, §9, §14 #68, arena_art §4–§5,
  endless_mode, ASSETS, PROJECT_CONTEXT, AGENTS.md 5b, CLAUDE.md.
- **Verified:** `validate.sh` OK; `test_endless_catalog` and `test_game_flow` pass; `test_endless_enemies`
  fails on the removed `WardenEnemy` (stale before this change). Renders at 1080 × 2340 (floor 498 × 1078,
  eye clear of the HUD boxes), 1080 × 1920 and 1200 × 1920; a real GameWorld (`render_arena_showcase.gd`)
  reports `arena=(498.0, 1078.0)` with no errors, the character on the floor's edge and the effects
  moving. A 10° test pose in Blender turned the hood and face without moving the board. APK built
  (141 MB); no phone was connected, so it is not installed.
- **Follow-ups:** install and the owner's phone test: the look against the image, the breathing, and
  the frame rate (unmeasured: the first 3D in the game). The Blender MCP add-on is installed in Blender
  but not registered with Claude Code (not needed: the script runs headless).

## 2026-09-30 — The Chained Colossus arena, as an image
- **Who:** Claude Code (Opus 5.5)
- **Owner:** asked to make the layered arena 3D instead of 2D pixel art. From Claude's options they
  picked pixelated 3D, keeping the 2D Vigil, "arenas may be 3D", the jungle modelled in 3D, a blockout
  first and the parts split (the owner makes the doll, Claude the rest in Blender). Then: "don't start
  … creating anything … first think how we are gonna approach this problem". Claude answered with an
  approach, which the owner is reading. Meanwhile they sent a new image: implement it as an arena
  ("every arena has a different playable area for now because we're testing … then we can start
  implementing real 3D models"). They picked the name CHAINED COLOSSUS, free for now, and the image
  kept as sent (GDD §14 #67).
- **Did:** `concept_art/arenas_v2/chained_colossus/` (`source.png`, the WebP saved as PNG with
  identical pixels; `arena.json`), `make_arena.py` wrote the background and thumbnail;
  `data/endless/skins/chained_colossus.tres` with its own floor (ADR-0020), the catalog and
  `SaveManagerService.VALID_ARENA_SKIN_IDS`.
- **Claude's choices:** the floor x 282–667, y 470–1277 of 941 × 1672 — the painted floor widens
  slightly downward (frame edge x 288 / 655 near the top, x 278 / 673 near the bottom, measured on
  luminance profiles), so the sides are the best-fit lines, off the painted edge by at most about 14
  design px; tier Simple, the amber accent, the Shop line.
- **Files/systems:** `concept_art/arenas_v2/chained_colossus/`, `assets/art/environment/arenas/`
  (+ thumbnail), `data/endless/{default_endless_catalog.tres,skins/chained_colossus.tres}`,
  `scripts/autoload/save_manager.gd`; docs: GDD §6, §14 #67, endless_mode, arena_art §4, ASSETS,
  PROJECT_CONTEXT.
- **Verified:** `validate.sh` OK; `test_endless_catalog` passes (4 arenas). APK built; no phone was
  connected, so it is not installed.
- **Follow-ups:** install on the owner's phone (`RFCX2035YHT`) and their check of the walls against the
  frame; equip it in the Shop's ARENAS tab (BUY • 0 RP, then EQUIP). The 3D decisions above are not
  recorded in the GDD or an ADR yet; they wait for the owner's answers to the approach (live or
  pre-rendered 3D, layout, look settings, Blender MCP, the doll's head as a separate model).

## 2026-09-30 — Stitchwarden's Vigil art, floor and whole-head rig revision
- **Who:** Codex
- **Owner:** supplied the dark pixel-art target image, asked to rebuild the arena to match its doll,
  board, jungle and scythe; keep the playable floor a little bigger than the target image's smaller
  floor; tilt the board mildly, keep rectangular walls, move the whole head and clothes together.
- **Did:** regenerated the backdrop, board, doll body and face, floor, scythe and flame in
  `source_v2/`; revised `pack_vigil.py` to build a 120 × 264-texel floor and a narrower frame. A
  shader tapers the decorative frame toward its top. `HeadRig` turns the hood and face on one pivot;
  the scarf, shoulder cloth, tunic and long cloth panels respond to motion while the gloves stay on
  the rail. Flame motion follows the curved blade. Updated the Shop still, thumbnail, catalog UV and
  the arena comparison check; the Quarry Titan and Stitched Doll Jungle were not changed.
- **Files/systems:** `concept_art/arenas_v2/stitchwarden_vigil/`,
  `res://assets/art/environment/arenas/stitchwarden_vigil/`,
  `res://scenes/arenas/stitchwarden_vigil.*`, `res://assets/shaders/{cloth_wave,arena_hood_follow,arena_fire_wave,arena_frame_tilt}.gdshader`,
  `res://data/endless/skins/stitchwarden_vigil.tres`, `tools/godot/test_endless_catalog.gd`;
  ADR-0022, GDD §14 #66, arena art guide, Endless system doc and ASSETS registry.
- **Verified:** `tools/validate.sh` printed `VALIDATE: OK` after one Windows Godot script-check
  process exited 139 despite logging 107 scripts checked and 0 failed. Targeted
  `test_endless_catalog` and `test_game_flow`: 1 passed, 0 failed each. Full suite: 29 passed,
  11 failed in tests that reference removed screens, enemies and APIs (same count as before this
  revision). A GameWorld movie capture at 1080 × 1920 shows the revised arena and reports a
  452.6 × 995.7 arena rect; `logs/stitchwarden_vigil_revised.png` is its captured frame. A runtime
  focus check turned the whole `HeadRig` about ±0.07 radians and Reduced Motion reset it.
- **Follow-ups:** review the revised look and motion on the owner's phone. The packer's 1080 × 2340
  safe top of 125 px is a review assumption; the game reads the device's actual value.

## 2026-09-30 — Stitchwarden's Vigil in the game: the first layered arena
- **Who:** Claude Code (Opus 5.5)
- **Owner:** gave the kit: "Fit this as a new arena", the two existing arenas stay; it is animated;
  "make it a little bit bigger than the arena you have just done"; prompt Codex for anything needed.
  Then "there would not be 16:9 just vertical play", an example image of how it should look, and
  "review at the end the goal what you have to achive vs what you have achvied" (GDD §14 #65).
- **Did:** `concept_art/arenas_v2/stitchwarden_vigil/pack_vigil.py` packs the kit
  (`stitched_doll_pixel_kit/`) onto one texel grid (4 design px per texel at full size, hard alpha,
  palette per piece), rebuilds the board around a 152 × 304-texel floor (rails widened by a repeated
  plain section, posts shortened, top banner shortened; 4 × 8 of the kit's tiles), sinks the body
  behind the board with the kit's grip hands on the rail, and generates `scenes/arenas/stitchwarden_vigil.tscn`,
  the 941 × 1672 Shop still, the thumbnail, `arena.json` and `review/`; it refuses anything drawn over
  the floor. `LayeredArenaVisual` (fit, drawn floor, focus, Reduced Motion) and `stitchwarden_vigil.gd`
  (head turn, cloth wave, flame loop and light, lantern flicker, wisps, bats, fog); shaders
  `cloth_wave` and `lantern_flicker`. `ArenaSkinData.visual_scene_path`, `ArenaRules.get_visual_scene()`;
  GameWorld shows the scene instead of the backdrop and takes the arena rect and walls from its drawn
  floor, not widened; Main preloads the scene for a run. Skin data (free, from the kit's handoff),
  catalog, save ids, `test_endless_catalog` layered checks. ADR-0021, which also corrects ADR-0020's note
  on sizes. My copy of the kit (identical to the in-repo `stitched_doll_pixel_kit/`) went to the
  Recycle Bin; the packer reads the in-repo kit.
- **Claude's choices:** the floor 608 × 1216 on a 1080-wide phone (the jungle's painted floor there is
  580 × 1142); the board rebuild; the grip hands; the scythe the largest that fits the width and clears
  the pause and UPGRADE buttons (scale 0.14 texel/px, tilted 6°); the head 150 px under the HUD's top;
  the cloth hanging over the posts; lanterns on the posts; the motion values (head ±5°, a 3-texel cloth
  wave, flicker, 12-texel fog drift, a bat pair every 9–16 s); tier Simple, the amber accent, the Shop
  line from the kit README's words. The cloth waves by whole-texel shifts in a shader, not a mesh, to
  keep the pixel grid. The kit's wide pieces are not used (vertical play only).
- **Files/systems:** `concept_art/arenas_v2/stitchwarden_vigil/`, `assets/art/environment/arenas/stitchwarden_vigil/`
  (+ `stitchwarden_vigil.png`, thumbnail), `scenes/arenas/`, `assets/shaders/{cloth_wave,lantern_flicker}.gdshader`,
  `scripts/resources/arena_skin_data.gd`, `scenes/gameplay/{arena_rules,endless_arena_rules,game_world}.gd`,
  `scenes/main/main.gd`, `scripts/autoload/save_manager.gd`, `data/endless/{default_endless_catalog.tres,skins/stitchwarden_vigil.tres}`,
  `tools/godot/test_endless_catalog.gd`; docs: ADR-0021, ADR-0017 and ADR-0020 status lines,
  arena_art, endless_mode, GDD §6, §14 #63–#65, PROJECT_CONTEXT §5.8, ASSETS.
- **Verified:** `validate.sh` OK, except one of five runs that printed FAILED; its step's logs were
  overwritten before they were read, and the runs before and after it were clean. `test_endless_catalog` passes (3 arenas; the Vigil's floor is on
  screen at 1080 × 2340, 1080 × 2400, 1080 × 1920 and 1200 × 1920 and bigger than the jungle's on
  1080 × 2340); full suite 29 passed, 11 failed, the same stale tests as before (removed Forms screen,
  old enemies and APIs). In a real GameWorld at 1080 × 2340 (SubViewport capture, desktop safe top):
  the arena rect is the drawn floor, 608 × 1216 at (236, 673); between two frames only the flame,
  lanterns, cloth, fog and wisps change, and inside the floor only the Wisp; under Reduced Motion only
  the Wisp; the head turns 4–5° toward the Wisp's side; a paused tree holds the motion. The Shop card
  shows the still with BUY • 0 RP. APK built; the phone was not connected, so it is not installed.
- **Follow-ups:** the owner's call on character size here — they are sized from this floor, about
  20 % smaller than on the jungle, whose layout rect is widened to 756 px; on the jungle that wider rect
  also drives formation placement and Grimgrin's walls past its painted floor (not changed: the owner
  keeps that arena as it is). The packer's review assumes a 125 px safe top on 1080 × 2340; the phone
  may differ. Against the owner's example: the board sits lower and the scythe is smaller (the HUD's
  buttons and the screen's width), and the kit's backplate has no ruins or waterfall.

## 2026-09-30 — Stitchwarden's Vigil layered arena source kit
- **Who:** Codex
- **Owner:** requested the whole dark stitched-doll arena as separate 2D pixel-art pieces, including board, doll, scenery, fire, cloth, wisps, fog and flying creatures; chose mild visual perspective with rectangular walls, a narrower/smaller board, and larger arena plus more side scenery on larger screens; then requested a named Desktop folder and a detailed Claude implementation prompt.
- **Did:** generated the source kit in `concept_art/arenas_v2/stitched_doll_pixel_kit/`: portrait/wide jungle and separate scenery, floor/frame, doll layers, lantern/fog, and four-frame flame/wisp/flying-creature loops; wrote `README.md` and `CLAUDE_IMPLEMENTATION_PROMPT.md`. Named it Stitchwarden's Vigil and copied all 52 files to the Desktop folder of that name. Existing runtime arenas and code are unchanged.
- **Files/systems:** `concept_art/arenas_v2/stitched_doll_pixel_kit/`, `docs/ASSETS.md`, `docs/GDD.md` §14 #64 and change history; Desktop handoff copy.
- **Verified:** visually inspected generated pieces; the three animated sheets' processor QC found four present, unclipped frames each. Desktop copy hashes match all 52 source files. `tools/validate.sh` printed `VALIDATE: OK` on the final run (one intervening Godot script-check process exited 139 after logging 105 checked, 0 failed). Full `tools/run_tests.sh`: 29 passed, 11 failed in tests referring to removed enemy/forms APIs or old save/dev-unlock calls. No in-game visual check was possible for this source-only kit.
- **Follow-ups:** static PNG alpha halos, strict grid/palette and common pivots need cleanup and assembled visual QA; the new arena scene, runtime floor transform, responsive layout, Shop entry and motion are for Claude's implementation handoff. Do not treat the source pieces as runtime-ready.

## 2026-09-30 — The Stitched Doll Jungle arena, with its own floor
- **Who:** Claude Code (Opus 5.5)
- **Owner:** "Codex actually started already implementing this arena ... continue implementing ... it
  won't be changed. Keep this arena like this for now", then, of the day and night images, "Actually is
  this one you have to add" (the night one). Codex had placed only
  `concept_art/arenas_v2/stitched_doll_jungle/source.png` (the night image, 941 × 1672). Its floor is not
  the shared one; from Claude's options the owner picked its own floor, the name STITCHED DOLL JUNGLE and
  free for now (GDD §14 #63).
- **Did:** `arena.json` (floor measured on the frame's inner outline: x 265–679, y 450–1266, 414 × 816);
  `make_arena.py` wrote the background and thumbnail. `ArenaSkinData.floor_rect` (+ `has_own_floor()`,
  validated inside UV); `EndlessArenaRules.get_floor_rect_uv()` / `get_floor_polygon()` return it while
  that arena is equipped. `data/endless/skins/stitched_doll_jungle.tres`, the catalog and
  `SaveManagerService.VALID_ARENA_SKIN_IDS`. `test_endless_catalog` checks each arena's measured floor
  against the floor the game uses for it. ADR-0020; ADR-0017's status line.
- **Claude's choices:** tier Simple, the amber accent (`Palette.WARNING_AMBER`), the description.
- **Files/systems:** `scripts/resources/arena_skin_data.gd`, `scenes/gameplay/endless_arena_rules.gd`,
  `scripts/autoload/save_manager.gd`, `data/endless/{default_endless_catalog.tres,skins/stitched_doll_jungle.tres}`,
  `concept_art/arenas_v2/stitched_doll_jungle/arena.json`, `assets/art/environment/arenas/` (+ thumbnail),
  `tools/godot/test_endless_catalog.gd`, `tools/art/make_arena.py` (docstring); docs: ADR-0020, ADR-0017,
  arena_art, endless_mode, GDD §6, §14 #63, PROJECT_CONTEXT, ASSETS.
- **Verified:** `validate.sh` OK; `test_endless_catalog` passes (two arenas). APK built, installed and
  launched on the owner's phone (`RFCX2035YHT`). Not yet seen in a run: equip it in the Shop's ARENAS tab
  (BUY • 0 RP, then EQUIP).
- **Follow-ups:** the owner's phone check of the walls against the frame. Like the Quarry Titan it is
  painted art at 941 × 1672 with no bleed, and lanterns and cloth hang over its floor's corners and top
  edge, kept as painted (owner).

## 2026-09-28 — Agent files: pointers for enemy work
- **Who:** Claude Code (Opus 5.5)
- **Owner:** "update the devlog and the agent releted files"; of Claude's three proposals the owner picked
  the enemy pointers only (not the Mac-only path fix, not dropping the subagent advice).
- **Did:** AGENTS.md read order 5e, "Adding or changing an enemy?": `enemies.md`, the ramp in
  `wave_director.md`, the Enemies v2 spec (one enemy at a time, nothing before the owner approves it
  there) and the art path (the owner's sheets copied unchanged into the pack's `raw/`, cleaned and packed
  by `pack_enemies.py`, its `review/` checked, then `validate.sh`). CLAUDE.md: runtime art also comes from
  a pack's own packer (Grimgrin's, the enemies').
- **Files/systems:** `AGENTS.md`, `CLAUDE.md`.
- **Verified:** docs only; `node tools/project_map.mjs --check` up to date.
- **Follow-ups:** the playtester agent and the run-game and devlog-video skills keep their Mac-only
  paths, and CLAUDE.md and the skills keep their subagent advice (owner's pick).

## 2026-09-28 — Enemies v2: five new enemies in, every old enemy removed
- **Who:** Claude Code (Opus 5.5)
- **Owner:** the five enemies in `Desktop/Whisbrush Enemies/` (a move and an attack sheet each, three
  shot pictures): "implement this new enemies, remove all of the old enemies"; the range ones shoot, done
  in code; the Hooded Scribe's shot "follows you ... for 2 or 3 seconds ... and then it disappears"; the
  Bone Witch's, where it hits a wall, "creates a small area that you cannot touch ... with a purple thing";
  then "some of the sheets have white parts in them ... clean first". Answers to Claude's four questions:
  the old bosses stay for now (they and Grimgrin spawn the new enemies; the Tutorial uses the new ones
  standing still); the Stone Golem shoots straight; the Claw Ghost swipes and the Root Mask lunges, both
  glowing before the strike; every enemy dies in one hit.
- **Did:** `concept_art/enemies_v2_autosprite_v1/` (the owner's files copied unchanged; `pack_enemies.py`
  removes the white patches trapped in the Stone Golem and Claw Ghost and a light edge fringe on every
  sheet, keeps real white art, and packs one atlas per enemy with body-centred frames). New
  `WholeFrameEnemy` (moves around the Wisp; swipe, lunge or shot; amber glow on melee wind-ups; the kill
  splits the frame along the cut), `EnemyProjectile` (straight, homing, wall mark), `EnemyRamp`; hooks in
  `EnemyActor`; `GameWorld` owns the shots and checks strikes, shots and marks every frame and in the dash
  sweep (they kill even mid-dash; a dash that kills the striker first escapes). Removed: ten old enemy
  scenes, six scripts, ten tunings and 30 art frames (104 files, to the Recycle Bin); formation slots are
  plain `enemy`; the rosters lost their enemy swaps and `<NAME> WAVE` callouts (they carry only the old
  bosses); the Tutorial's targets are the Hooded Scribe.
- **Claude's choices, for the phone test:** every speed, size, range, cooldown and shot value; the rune's
  2.5 s; the mark's radius and 4 s; the ramp (two kinds at the start, one more every two waves); the amber
  glow; the Tutorial's Hooded Scribe; the slice's look (GDD §14 #62).
- **Files/systems:** `scripts/components/{enemy_actor,whole_frame_enemy,enemy_projectile}.gd`,
  `scripts/utils/enemy_ramp.gd`, `scripts/resources/{enemy_tuning,wave_tuning,formation_data,endless_roster,tutorial_lesson_data}.gd`,
  `scenes/enemies/*.tscn`, `data/enemies/*`, `data/formations/*`, `data/endless/rosters/*`,
  `data/waves/default_wave_tuning.tres`, `scenes/gameplay/{game_world,arena_rules,endless_arena_rules}.gd`,
  `assets/shaders/enemy_slice.gdshader`, `assets/art/characters/enemies_v2/`; docs: enemies,
  wave_director, endless_mode, core_run, tutorial, reaper_boss, grimgrin_boss, GDD §5.4, §5.5, §14 #62,
  enemies_v2 README, PROJECT_CONTEXT, ASSETS, ROADMAP.
- **Verified:** `validate.sh` OK (one script check crashed on exit with no error right after the new art
  was imported; two reruns and the next full validate were clean). Two headless smoke runs from scratch
  scripts (not in the repo): a busy run with all five, no script errors or warnings, 36 slice kills, shots
  and wall marks fired, four of five seen attacking; then the Claw Ghost and Root Mask alone, each closed
  in, struck and hurt a still Wisp. No test suite, no renders. APK built, installed and launched on the
  owner's phone (`RFCX2035YHT`).
- **Follow-ups:** the owner's phone test (sizes, speeds, attacks, the ramp). Now stale, still using the
  removed enemies: `test_enemy_families`, `test_endless_enemies`, `test_gameplay_slice`,
  `test_mutation_effects`, `test_player_health_flow`, `bench_stress` and the `render_*` fixtures that
  spawn them. `tools/art/redesign_v1_slices.json` and `tools/art/extract_rifts.py` still list the removed
  art. The sixth enemy; the old bosses and the rosters go when the new bosses exist; the split, shield and
  tether code has no user.

## 2026-09-28 — Enemies v2: Grimgrin's fast attack; a strike on every hit
- **Who:** Claude Code (Opus 5.5)
- **Owner:** "he has one attack that he goes fast from wall to wall and at that attack you cant hit him,
  he also can attack you while you dash and add a hit animation when the chracter hits something".
  Asked four questions; the owner picked every recommended option: an extra attack (the slow dash
  stays), touching him in it kills even mid-dash, its own crimson warning held longer, and a pixel-art
  strike drawn in code. Then: "dont test i will test just implement", "launch it on my phone".
- **Did:** `GrimgrinBoss` fast attack: after a rest, sometimes (`fast_attack_chance`, cooldowns) a
  crimson warning (`fast_warning_duration` 0.8 s), then a flight at `fast_dash_speed` 1500 in which
  `is_core_exposed` is false and `get_dangerous_circles` holds one circle on him (the Wisp takes it
  mid-dash too); crimson glow through it. New `StrikeFx` (`scenes/gameplay/strike_fx.gd`): a four-frame
  pixel strike where a dash hit lands on an enemy or a boss, in the form tint; `GameWorld` plays it when
  `try_dash_hit` returns true. Every value and the strike's look are Claude's (GDD §14 #61).
- **Files/systems:** `scenes/bosses/grimgrin_boss.gd`, `scripts/resources/grimgrin_tuning.gd`,
  `data/bosses/grimgrin_tuning.tres`, `scenes/gameplay/strike_fx.gd`, `scenes/gameplay/game_world.gd`,
  `tools/godot/test_grimgrin_boss.gd` (one line: keeps the fast attack off, since its checks hit him at
  any moment); docs: GDD §5.5, §8, §14 #61; grimgrin_boss, game_feel, enemies_v2 README and
  boss_melee §2, PROJECT_CONTEXT §5.8.
- **Verified:** `validate.sh` OK. No tests run and no renders (owner). APK built, installed and
  launched on the owner's phone (`RFCX2035YHT`).
- **Follow-ups:** the owner's phone test (the fast attack's chance, warning and danger size; the
  strike's look); the fast attack is not in `test_grimgrin_boss` yet.

## 2026-09-27 — Enemies v2: Grimgrin's dash becomes the time to hit him
- **Who:** Claude Code (Opus 5.5)
- **Owner (after the phone test):** "i cant beat him he killes me instantly when he dashes"; his dash
  should be when you attack him, with an indicator. Answers: he can still be hit on walls; a warning
  flare before each dash and a glow through it; about half speed.
- **Did:** the dash is no longer a danger (`get_dangerous_circles` override and `dash_radius_ratio`
  removed); `is_core_exposed` is true until his death; new state `WARN` holds his wall for
  `dash_warning_duration` (0.5 s, Claude's value) with a building flare before every dash; a steady glow
  in flight; `dash_speed` 1500 → 750. GDD §5.5, §14 #60; grimgrin_boss.md; boss_melee.md; README.
- **Files/systems:** `scenes/bosses/grimgrin_boss.gd`, `scripts/resources/grimgrin_tuning.gd`,
  `data/bosses/grimgrin_tuning.tres`, `tools/godot/test_grimgrin_boss.gd`
- **Verified:** `validate.sh` OK; `test_grimgrin_boss` (now checks the warning, the harmless flight and
  a hit in flight), `test_boss_variants`, `test_reaper_boss` pass. APK built.
- **Installed** and launched on the owner's phone (`RFCX2035YHT`) once it was connected.
- **Follow-ups:** the owner's next phone test.

## 2026-09-27 — Enemies v2: Grimgrin in the game
- **Who:** Claude Code (Opus 5.5), working alone while the owner was out
- **Owner:** "Here are all of the sprite sheets wire them" (the six AutoSprite sheets), in auto mode.
- **Did:** the six sheets copied unchanged to `concept_art/grimgrin_autosprite_v1/raw/` (checked: no
  background leftovers) and packed by `pack_grimgrin.py` into one atlas, `grimgrin_frames.tres` and a
  generated `BossSpriteLayout` (one scale for every sheet; feet and grip lines).
  `BossActor` is now the base of every boss (ADR-0019): `ReaperBoss` extends it, `BossData` gains
  `scene` and `approach_callout`, and `GameWorld` drives any boss through it, with a new
  `spawn_requested` for random enemies. `GrimgrinBoss` plays the owner's fight (GDD §5.5, §14 #59):
  wall-to-wall dashes that kill on touch, the ill wall (rot, then a deadly lane along the wall), double
  hits while planted, Death's Grin in the second half, random spawns, death and rewards.
- **Claude's choices, for the phone test:** every value in `grimgrin_tuning.tres`; he is the **first
  boss of every Endless run** (`EndlessTuning.opening_boss_id`, wave 4; daily and Tutorial keep the
  Reaper); phase names WALL TO WALL / DEATH'S GRIN; the Reaper's sounds; the old enemies spawn in his fight.
- **Files/systems:** `scenes/bosses/{boss_actor,grimgrin_boss}.*`, `reaper_boss.gd`,
  `scripts/resources/{boss_data,boss_sprite_layout,grimgrin_tuning,endless_tuning}.gd`,
  `data/bosses/grimgrin*.tres`, `game_world.gd`, `run_profile.gd`, `endless_arena_rules.gd`, `main.gd`,
  `tools/godot/test_grimgrin_boss.gd`, `test_boss_variants.gd`; docs: grimgrin_boss, reaper_boss,
  endless_mode, PROJECT_CONTEXT, GDD, ROADMAP, ASSETS, enemies_v2, ADR-0019.
- **Verified:** `validate.sh` OK; `test_grimgrin_boss`, `test_boss_variants`, `test_reaper_boss` pass;
  full suite 33 passed, 7 failed (the 7 known stale tests). A 14 s fight in the real arena with the
  Wisp idle: dashes, an ill floor, spawns, and his dash killed the Wisp. Renders of every wall, both
  plantings and the flight checked; the rot first drew under the floor (top-level z), fixed. APK built;
  the first phone showed `unauthorized` to adb, so it was installed and launched later, on the owner's
  request, on the phone then connected (`RFCX2035YHT`).
- **Follow-ups:** the owner's phone test (feel, size, speed, rot timing); the boss bar
  still shows the Reaper's icon; his own sounds; the new enemies for his spawns.

## 2026-09-27 — Enemies v2: Grimgrin's right-wall pose fixed
- **Who:** Claude Code (Opus 5.5)
- **Owner:** the right-wall pose came out wrong; "fix the pose prompt"; also asked what reference image
  to use (answer: always Grimgrin's own base image) and to get each animation with its poses underneath.
- **Did:** the generated pose had three legs, stood on the floor, drew a brick wall and a grey background,
  lost a katana and a grey blade. The pose now hangs him from the hilt of one katana stabbed into the wall
  (one boot braced, one leg hanging, the other katana free) with "draw only him, no wall or floor,
  exactly two arms and two legs, both blades dark teal"; `right_wall_idle`, `plant_wall` (now the second
  katana goes in beside the first) and `Grimgrin_PlantWall` rewritten to match, in `boss_melee.md`.
- **Second try (owner: legs not positioned well, still a wall):** the prompts no longer say "wall"
  ("the right edge of the picture"), the legs are placed explicitly; the four prompts updated again.
- **Wall-planting end pose (owner: "make him put his feet on the wall"):** he perches like a climber,
  side-on with his head to the viewer, both boots flat on the edge; `Grimgrin_PlantWall` and `plant_wall` updated.

## 2026-09-27 — Enemies v2: Grimgrin's pose and animation prompts
- **Who:** Claude Code (Opus 5.5)
- **Owner:** the throw is gone; Death's Grin only in the second half; "now write the prompts".
- **Did:** six pose prompts (297–390 characters: right wall, both plantings, dash and dash end, death end)
  and six animation prompts (1,582–1,849 characters: floor idle, right-wall idle, floor and wall
  planting, dash, death) in the owner's format, with a table of first and last frames, tiers and what
  each sheet covers (flipped and mirrored walls), the settings (512 px frames proposed) and a cost of
  about 110 credits, all in `docs/specs/enemies_v2/boss_melee.md` §3; the fight in §2 updated.
- **Follow-ups (owner):** generate the poses, then the six sheets, and send the exports.

## 2026-09-27 — Enemies v2: Grimgrin's animation list
- **Who:** Claude Code (Opus 5.5)
- **Owner:** floor idle, right-wall idle (mirrored, and the floor flipped for the top), a two-katana
  planting animation for the floor and top and one for the sides, the dash attack, Death's Grin done
  with effects in the game (no sheet), death; no throw animation.
- **Did:** recorded in `boss_melee.md` §2–3 and the README. The hit window was "while the thrown katana
  is away"; with no throw it is open again, asked.
- **Then (owner):** he can be hit any time (several hits to kill), and a hit deals more damage while both
  his katanas are planted in the wall; recorded. Whether the throw stays as an effect-only attack is open.

## 2026-09-27 — Enemies v2: Grimgrin, the Hollow Ronin
- **Who:** Claude Code (Opus 5.5)
- **Owner:** generated the melee boss's base in AutoSprite from the text description alone; picked the
  name **Grimgrin, the Hollow Ronin** from Claude's options; "he throws one katana at a time".
- **Did:** the base described from the owner's image (black gloves instead of the crimson asked for,
  white background, about as wide as tall with the blades) and the decisions recorded in
  `docs/specs/enemies_v2/boss_melee.md` and the README.
- **Follow-ups:** his poses and animation prompts.

## 2026-09-27 — Enemies v2: the melee boss is a ninja hunter; everything saved before compaction
- **Who:** Claude Code (Opus 5.5)
- **Owner:** test without a reference image first; "write everything we have discussed so far, I will
  compact the session"; "the character is not a reaper ... more like a ninja feel or a hunter with two
  katanas", write a more detailed prompt (the field supports more characters).
- **Did:** looked at the reference again: a hooded ninja-hunter with curved katanas, not a reaper with a
  scythe (Claude's misreading). `boss_melee.md` rewritten to the current state: the look, the owner's
  fight, the base settings (HD Pixel Art, no reference, base colour undocumented), a detailed description
  (1,540 characters), the planned animation list; the scythe poses and prompts deleted. New
  `prompt_drafts.md` (the six enemy descriptions with suggested roles, the first three boss drafts, none
  approved). README: "Where we are", the melee row, open questions. `autosprite_workflow.md`: the vibe,
  base colour and longer description the owner saw in AutoSprite.
- **Follow-ups (owner):** generate the melee boss's base; one katana thrown or both, and the hit window;
  his name.

## 2026-09-27 — Enemies v2: the melee boss's fight settled; his base
- **Who:** Claude Code (Opus 5.5)
- **Owner:** both extra attacks (Scythe Throw, Death's Grin); hit him only while his scythe is away; he
  can hit the Wisp while he moves wall to wall, and that movement is unpredictable; "don't write
  anything yet", then "write his prompts, but first the prompt for the character", which image to give
  AutoSprite as the reference, and which vibe (16-bit or HD pixel art) and base colour to pick.
- **Did:** the fight recorded in `boss_melee.md` §2; Step 1 rewritten: the base description (589
  characters), vibe HD Pixel Art (it matches Patchvile's first frames: many colours, no dithering),
  Patchvile's storefront first frame as the style reference (not the Pinterest image, another artist's
  work), and the base colour flagged as undocumented by AutoSprite. The poses and animations in §3 are
  still the first proposal's, to be rewritten.
- **Follow-ups:** the owner generates the base; then the poses and animations for the settled fight.

## 2026-09-27 — Enemies v2: attacks must be visible
- **Who:** Claude Code (Opus 5.5)
- **Owner:** the melee boss dashes wall to wall as his normal movement, then goes to the wall and makes
  it ill, but not every time; no attacks like the game's current ones — attacks are visible, "not like
  lines that for example reaper has".
- **Did:** recorded in `boss_melee.md` §2 and, as a rule for the whole set, in the README §2 (a warning
  still comes through the visible thing: a wind-up, a wall starting to rot). The line-based ideas (Echo
  Reap, Cross Cut) dropped.

## 2026-09-27 — Enemies v2: the melee boss's attacks
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** a dash at the Wisp "would have a feeling of following"; instead his first attack
  makes the Wisp's wall "ill" (leave fast or die), his second is fast wall-to-wall dashes, swiping as he
  dashes; regular enemies just spawn at random during his fight (no spawn animation); asked for ideas
  for other attacks; every boss has different attacks.
- **Did:** recorded in `docs/specs/enemies_v2/boss_melee.md` §2 (the first proposal's animations and
  prompts marked as not final) and the README's boss table; ideas for a third attack and the hit window
  given in chat.
- **Follow-ups (owner):** pick the third attack and the hit window; then the animations and prompts are
  rewritten.

## 2026-09-27 — Enemies v2: the melee boss's full package
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** make the bosses and enemies one at a time, each with its own time; focus on this
  boss: "give me a name and everything".
- **Did:** new `docs/specs/enemies_v2/boss_melee.md`, all a proposal for the owner: the name
  Grimgrin, the Crimson Reaper (two alternatives), the fight (idle, a warned dash edge to edge, stunned
  against the wall as the only hit window, a scythe sweep up close, two dashes in a row after half
  health, no regular enemies), the AutoSprite order (base, five poses as first and last frames, six
  animations with tiers and clips), every prompt (poses 218–274 characters, animations 727–1,026), the
  export settings and a cost of about 100 credits. Linked from the README.
- **Follow-ups (owner):** approve or change the name, the fight and the prompts; then generate.

## 2026-09-27 — Enemies v2: the melee boss is the reaper
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** the boss descriptions tested in AutoSprite were "not exactly what I want"; the
  melee boss is the second reference (the hooded reaper with the scythe, resent): "basically just copy
  that guy", keep his legs; he dashes toward the Wisp and across the arena as the characters do; every
  boss has different animations; write his AutoSprite prompt.
- **Did:** a detailed Discover description of the reaper (593 characters), given in chat; the melee row
  in `docs/specs/enemies_v2/README.md` §6 corrected (the two-swords demon was the wrong image).
- **Follow-ups (owner):** generate him in AutoSprite; then his attacks and animations.

## 2026-09-27 — Enemies v2: six enemy references; no legs
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** six references for the small enemies; "avoid enemies with legs because in the
  arena how would they walk? ... redesign them without legs"; asked whether the bosses' legs are a
  problem or can be designed around.
- **Did:** six AutoSprite Discover descriptions without legs (383–486 characters), given in chat with a
  suggested role for each; the references and the decision recorded in
  `docs/specs/enemies_v2/README.md` §5; the bosses' legs answered in chat (options, not decided).
- **Follow-ups (owner):** the roles per reference and the sixth role; legs or floating for the bosses;
  the melee reference and the colours (earlier questions); whether to save the prompts in the folder.

## 2026-09-27 — Enemies v2: the three bosses picked; their descriptions drafted
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** six concept references; three bosses — a melee one from "the one with the two
  swords", a ranged one from "the green guy" (fifth), and one that spawns enemies from "the cat" (fourth),
  redesigned so it feels like a spawner; write their prompts.
- **Did:** the three AutoSprite Discover descriptions (523, 486 and 533 characters, under AutoSprite's
  600), given in chat; the bosses' roles and references recorded in `docs/specs/enemies_v2/README.md` §6.
  The two-swords image was the third received, not the second: flagged to the owner.
- **Follow-ups (owner):** confirm the melee reference; the colours (the references' red, green and orange
  or the game's magenta for bosses); generate the three in AutoSprite.

## 2026-09-27 — Enemies v2: the owner's answers; AutoSprite-only workflow researched
- **Who:** Claude Code (Opus 5.5)
- **Owner answers:** corrupted spirits and beasts (like Patchvile in spirit but not a copy; a broken
  wisp or spirit inside a body; bones and ghosts; bats, moths and crows; a mix; not cursed objects like
  lanterns); roles hunter (fast, along the walls), shooter, trickster, trapper, swarm, no tank; all fast
  and easy to kill, one hit mostly, some two, at most three, with a slicing feel; enemies circle the
  Wisp and can kill it mid-dash, instant death; items that save you come later; three bosses, one that
  summons any enemy, two that fight alone with no enemies spawning; looks from the owner's references;
  no Codex quota, AutoSprite only. Asked: write it in a folder for other agents, generate nothing, and
  research the best AutoSprite prompts and poses for the enemies.
- **Did:** the spec moved into `docs/specs/enemies_v2/` (`README.md` with the answers, the rules — the
  mid-dash kill marked as the owner's change to GDD §5.3 — and what is still open); new
  `autosprite_workflow.md` from AutoSprite's docs, API reference, pricing and guides (Discover with 12
  art styles, pose correction, the humanoid toggle, generated poses as first and last frames, tiers,
  export settings, costs) with a proposed enemy and boss pipeline, description and animation templates,
  consistency rules, a rough cost (~550 credits for the set) and Morrow as an AutoSprite-only option.
  GDD §14 #58, ROADMAP M14. Nothing generated or built.
- **Follow-ups (owner):** the references for the enemies and bosses; the sixth enemy's role.

## 2026-09-27 — Enemies v2: decisions and the design document
- **Who:** Claude Code (Opus 5.5)
- **Owner decisions (discussion):** remove every current enemy, boss and enemy mix and redesign the
  enemies; start with 6 enemies and 3 bosses and add more later; every enemy its own design (no upgrade
  ranks) mixed at random so a play-till-you-die run stays fresh; sprite-sheet animated (Codex first
  frame, AutoSprite sheets), not rigs; pixel art in the Wisp theme, which some may leave out or carry
  subtly; "write it, but prompt me back" for how the enemies should be and their attacks.
- **Did:** new `docs/specs/enemies_v2.md` (now `docs/specs/enemies_v2/README.md`) with the decisions, the game's rules every enemy keeps, the
  animation states (enemy: move, attack, death; boss: idle, attacks, summon, stunned, death; appearing,
  hits, the boss entrance and phase change in code) and the run plan; the six enemies and three bosses
  left empty for the owner's answers. GDD §14 #58, ROADMAP Milestone 14. Nothing removed or built.
- **Follow-ups (owner):** answer the questions on the enemies and bosses.

## 2026-09-27 — Morrow's redesign started: references and the Codex variants prompt
- **Who:** Claude Code (Opus 5.5)
- **Owner requests:** the other characters stay as they are on Home; "redesign the last character left
  morrow give me the images from him and prompt for AI to generate variants for each pose"; then "yes
  save it".
- **Did:** sent his character sheet (`concept_art/wisp_rush_playable_characters_v1/references/morrow_concept.jpg`)
  and portrait (`assets/art/characters/playable/morrow/preview.png`), and a Codex prompt for three
  variants of each of the five poses (Rook's prompt, with his design, the storefront centred, the
  776 px height counting his floating hands and rune stones, and his glow as solid pixels). Saved in
  the new `concept_art/morrow_autosprite_v1/PROMPTS.md`. ASSETS, ROADMAP.
- **Follow-ups (owner):** pick a variant for each pose.

## 2026-09-27 — Characters stand centred on Home's platform; Rook centred
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "center it in the platform, make that a rule in the game: every character new or
  redesigned has to be centered in the home platform".
- **Did:** measured every character on the real Home (first storefront frame, 1080 × 1920 design;
  the platform's centre is at (540, 1166), texel (470, 1015) of `home_background.png`): Patchvile,
  Shade, Mothmere and Scarlet stand with their lowest pixel at y 1153–1187 and their head's centre at
  x 527–547; Rook's feet were at about y 1086, because his tail blade hangs 34 source px below them.
  New `WholeFrameCharacterVisual.menu_offset` (design units, Home and the Shop card only); Rook's is
  (2.7, 62.5). The rule written in the character guide §6 (and its §7 check, the §6 table now also
  records Rook's 336 px cells), AGENTS.md §1, GDD §14 #57, playable_character_visuals, game_flow.
- **Verified:** on Home Rook's feet land at y 1166 and his head's centre line at x 540.4; the Home and
  Shop renders show him on the platform and inside his card.
- **Follow-ups (owner):** the other characters were not moved (the rule is for new or redesigned
  ones): Mothmere's and Scarlet's heads sit 11–13 px left of the centre, Patchvile's feet 21 px low.

## 2026-09-27 — Rook in the game on AutoSprite; his bone rig removed
- **Who:** Claude Code (Opus 5.5)
- **Owner requests and answers:** implement Rook's five AutoSprite sheets, but first clean the white
  AutoSprite's background remover left (between wing and leg, and elsewhere), frame by frame; the
  cleaned result reviewed and accepted ("it's okay"); then "implement the character and remove the old
  rigged character". Answers: dash cells 3, 5, 7, 8, 9, 11, 14, 17 (hit on 9); keep his current dash
  look; retire the rig; use the storefront as delivered.
- **Did:** the five exports copied unchanged into `concept_art/rook_autosprite_v1/raw/`. New
  `slice_sheet.py`: cuts every filled cell and cleans it (the white in his gaps and inside the tail
  curl and blade notch, its blend into the body, the faint white halo on his outline, cream specks left
  in a cleaned pocket), with the pieces and single pixels the rule got wrong decided by eye in zoomed
  before/after views and listed in the slicer (`BY_EYE`, `ERASE`); eye cores and bone, claw and blade
  highlights kept; `review/cleanup_<sheet>.png` for every cell. Packer `SHEET_PACKS["rook"]` (his own
  ceiling, the right wall mirrored for the left, `roster_scale`, his rig's streak and dust pieces as
  particle strips); his walls do not fit 256 px cells at Patchvile's scale (floor 299, right wall 321
  cell px), so the run sheet has 336 px cells, `design_size` 336 and `art_scale` 1.55859375 (1.1875 ×
  336/256). `rook_visual.gd/.tscn` rewritten on `WholeFrameCharacterVisual` with the rig's particles and
  mote ring, their sizes carried over (× 336/640); form uses `rook_portrait.png` and
  `menu_frames_path`. Rig removed: the old scene and script and his 13 body-part images (with their
  `.import` files) sent to the Recycle Bin, `CHARACTERS["rook"]` dropped from the extractor. New
  `test_rook_visual.gd`. Docs: GDD (characters row, art direction, §14 #55–56, change history), playable_character_visuals,
  forms, PROJECT_CONTEXT, ROADMAP, ASSETS, rig recipe, ADR-0015, tools/art/README, the characters devlog
  plan, Rook's PROMPTS.md.
- **Verified:** ROSTER CHECK 202 px (+4 %) ok; `VALIDATE: OK`; `test_rook_visual` passes (his side wall
  drifts 35.5 px with the tail swing, budget 40); `test_playable_character_visual` passes (one run hit
  the known intermittent MotionRoot scale flake, on Scarlet), `test_dash_effects` and
  `test_form_catalog` pass; full suite 32 passed, 7 failed, the same seven stale tests as before
  (they still load the removed Forms screen, `purchase_form` and `get_unlock_wave`). APK exported;
  not installed, no phone was connected.
- **Follow-ups (owner):** install and test on the phone.

## 2026-09-27 — AutoSprite rules written down; Rook's prompts
- **Who:** Claude Code (Opus 5.5)
- **Owner requests:** Rook's animations (dash: push, dive, swing with the tail blade; relaxed
  breathing storefront with a small wing rustle; floor, right wall and ceiling alert, breathing, head
  and tail moving); all suggested additions approved; the storefront reworded as a relaxed seamless
  loop; then "search on the web ... the best prompts to give to AutoSprite", and "write this as rules
  for creating animation for AutoSprite in this project so other agents know".
- **Did:** Rook's five AutoSprite prompts, given in chat. Read AutoSprite's documentation (animation
  types, custom animations, advanced mode, FAQ). New "AutoSprite rules" in the character guide §3:
  A1–A9 from AutoSprite's docs (ultra or max for the dash, a distinct last frame for a one-shot attack,
  motion not end state, one action per animation or keyframes/storyboard/Motion Library, Ultra
  background removal, humanoid off for non-humans, clip length, preview, Prompt Helper) and B1–B6 from
  this project; the §3 table's dash last frame and the settings line now point to them. AGENTS.md §1
  points to the rules.
- **Then:** the floor and ceiling prompts rewritten to the new rules; all of Rook's prompts saved in
  `concept_art/rook_autosprite_v1/PROMPTS.md` (owner: "yes save them"), with a Codex prompt for the
  dash's last frame, the end of the tail swing (rule A2).
- **Follow-ups (owner):** the end-of-swing image from Codex; then the dash prompt rewritten for it
  (it still ends with a recovery to the flight pose).

## 2026-09-27 — Rook's AutoSprite first frames
- **Who:** Claude Code (Opus 5.5)
- **Owner requests and answers:** a Codex prompt for Rook (the dragon) asking for about three variants
  of every state (storefront, floor, right wall, ceiling, dash), with his reference images; then five
  images for Rook. Answers after the check: keep his outline; his own ceiling animation.
- **Did:** checked the five images (1024², transparent, exact 4 × 4 blocks, 90–109 colours, margins
  ≥ 60 px, storefront exactly 776 px). Scale: by the tail blade every pose is within about ±10 % of the
  storefront (ceiling −14 %), by the head the ceiling is about 5–16 % larger; left as drawn. A dark
  rim runs round the bone (49–91 % of that edge dark). New pack `concept_art/rook_autosprite_v1/`:
  `sources/` (the owner's images from `Desktop\Rook\Codex Generated`, unchanged),
  `build_first_frames.py` (checks and copies them unchanged), five first frames, review sheet,
  metadata. GDD §14 #55, ROADMAP M13, PROJECT_CONTEXT §2, ASSETS.
- **Verified:** the build script's checks pass for all five; the first frames are byte-identical to
  the sources.
- **Follow-ups (owner):** describe Rook's animations (storefront, floor, right wall, ceiling, dash
  attack) for his AutoSprite prompts.

## 2026-09-26 — Every character the same size again; Scarlet drawn 1.16× larger
- **Who:** Claude Code (Opus 5.5)
- **Owner requests:** on Home Scarlet did not stand on the platform's centre ("she's too small"),
  tell how to fix it; of three options (draw her 1.16× bigger, only move her down, new sheets at full
  size): "option 1, make her bigger and launch it on my phone and also do that same in the game";
  then "each character has to be the same size in game, in store, everywhere ... revert that change
  to as it was before".
- **Measured:** the menu cell centres each storefront loop, so a shorter figure's feet sit higher:
  feet line (448 px menu cell) Patchvile 430, Shade 417, Mothmere 408, Scarlet 378; her figure 0.86×
  Patchvile's height (her body about 0.74×, the fan and crown count in the 167 px).
- **Did:** `scarlet_visual.tscn` `art_scale` 1.1875 → 1.38 and `menu_art_scale` 1.25 → 1.45 (×194/167).
  Reverted the own-height rule (GDD §14 #51): the packer's `ROSTER_STANDING` 194 and its original
  check are back, Shade's and Mothmere's `standing` entries removed; Scarlet's pack keeps `standing`
  166 as the one exception, with the reason. Docs: GDD §14 #54 (new), #51/#52/#43 status; ADR-0018
  addendum; AGENTS.md §1; character guide §3/§4/§6/§7; PROJECT_CONTEXT §5.1/§5.2;
  playable_character_visuals; ROADMAP.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; ROSTER CHECK on Shade and Mothmere against 194
  and Scarlet against 166: ok; `scarlet_visual` passes; `playable_character_visual` failed once on
  Patchvile ("MotionRoot scale jumped 0.30") and passed twice on re-run (the intermittent timing
  failure `frame_pacing.gd` notes). APK built, installed on the phone and launched.
- **Follow-ups (owner):** check Scarlet on Home, in the Shop and in a run on the phone.

## 2026-09-26 — Scarlet is in the game; Ilyra removed; no character tiers
- **Who:** Claude Code (Opus 5.5)
- **Owner requests and answers:** the animations for Scarlet (breathing, clothes, hair, the floating
  diamonds, a small fan wave on the storefront, small attack-like moves on the floor and wall, a
  one-shot fan swing with an airy blue reap; "all yes" to the suggested additions); the floor sheet
  came out wrong ("her fan is just moving … she doesn't feel like she is breathing"), so the floor
  prompt was rewritten, finally as an in-depth ~3,400-character prompt; then the four AutoSprite
  sheets: "implement them … clean in each image what's wrong" (white between the fan's ribs), tell
  first. Answers: remove Ilyra completely and make Scarlet a new character with her own everything;
  remove the tiers ("every character is same"); the Shop text: Claude's line ("create"); the landing
  as Ilyra's; "work in a loop till everything is finished".
- **Did:**
  - Measured the first floor sheet: the fan rocked from 0° to −32° and back while under 2 % of her
    body's pixels changed; the prompt then made breathing the main motion and locked the fan.
  - `concept_art/scarlet_autosprite_v1/`: `raw/` (the owner's four PNG exports, unchanged),
    `slice_sheet.py` (cells: storefront 25, floor 24, right wall 25, dash 07, 09-12, 15, 19, 22
    turned to fly up; cleaning: the grey/white AutoSprite filled between the fan's ribs, found inside
    the fan's own wood and never touching a solid area, the reap's black tips and rib specks; her
    particle pieces; `review_cleanup.png`), `scarlet_sprite_sheet.json`. Cleaned 2,693 / 4,699 / 854
    / 1,075 px (storefront / floor / wall / dash).
  - Packer: `SHEET_PACKS["scarlet"]` (`roster_scale`, `standing` 166; ROSTER CHECK 167 px, +1 %, ok)
    and `particles` may be a list; `assets/art/characters/playable/scarlet/`. `ScarletVisual`
    (`scarlet_visual.{gd,tscn}`: pale blue attack glow, `dash_head_up`, contact frame 4, her reap
    crescents on `%DashParticles`, her crown diamond on `%TrailParticles`), `data/forms/scarlet.tres`,
    `data/characters/dash_effects/scarlet.tres` (Ilyra's `TWIN_ARC` look, larger), catalog slot,
    `VALID_FORM_IDS`, tests and fixtures; new `test_scarlet_visual.gd` (her storefront gets a 30 px
    drift budget: the fan wave moves the silhouette 26.1 px; walls 4.7-5.5 px).
  - Ilyra removed: scene, data, menu video, runtime art, test and fixture, her concept packs, the
    v3 pack and her two v2 images — 28 items to the Windows Recycle Bin, nothing permanently deleted;
    the extractor's pose/ornament/puppet/frame tables and the menu-video table are empty seams; the
    `ilyra_2` save mapping is gone (unknown ids fall back to Patchvile).
  - Tiers removed: `FormData.Tier`/`tier`/`get_tier_name`, the Shop's `%TierLabel` and its code, the
    `tier` lines in the character `.tres`, the tier check in `test_form_catalog`.
  - Docs: GDD §6/§9/§13, §14 #52 (implemented) and new #53 (no tiers), ADR-0015 and ADR-0016 status
    and addendum, PROJECT_CONTEXT §2/§5/§6/§8, playable_character_visuals, forms, shop, player_dash,
    character guide §4-§5, ROADMAP M13, ASSETS (14 Ilyra rows out, Scarlet's rows in).
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (103 scripts); `tools/run_tests.sh` → 31 passed,
  7 failed — the same 7 stale ones (removed `FormsScreen`/`forms_screen.tscn`, `purchase_form`,
  `DevUnlock.get_unlock_wave`); `scarlet_visual`, `form_catalog`, `playable_character_visual`,
  `dash_effects` pass. Cleanup checked on before/after zooms over magenta; no near-black run of 5 px
  or more left in the dash. Debug APK built and installed on the owner's phone and launched.
- **Then:** her prompts saved in `concept_art/scarlet_autosprite_v1/PROMPTS.md` (owner: "yes save the
  prompts in her folder"), the app relaunched on the phone.
- **Follow-ups (owner):** test Scarlet on the phone. `concept_art/wisp_rush_playable_characters_v2/`
  still holds Bram's source and notes that mention Ilyra (not asked to remove).

## 2026-09-26 — Characters keep Patchvile's pixel size at their own height; Scarlet's first frames
- **Who:** Claude Code (Opus 5.5)
- **Owner requests and answers:** Scarlet, a new character that replaces Ilyra (four Codex images:
  storefront, floor crouch, right wall, dash): check the recipe and say whether to go on to the
  sprite animations. Answers: she switches her fan from hand to hand; in the crouch the fan is held
  by her other hand, which is fine; characters can be smaller than others and act the same in
  gameplay, and Patchvile is the example for the pixel block size and how a character is made
  (Option B, "you can change the rules but first lets discuss"); scale each pose; "166 is good, fan
  size is fine"; "go ahead with both" (the rule change and her first frames).
- **Did:**
  - **Rule** (GDD §14 #51): every character keeps Patchvile's pixel size (256 px frame, packed at his
    scale with `roster_scale`); its height is its own, set by the owner. The packer's roster packs now
    record their approved `standing` (Shade and Mothmere 194) and `_check_roster_standing` compares
    with it (±5 % warns, ±10 % or a missing `standing` refuses); `ROSTER_STANDING` is gone. Guide
    §3/§4/§6/§7, AGENTS.md §1, ADR-0018 addendum, GDD §14 #51 (and a note on #43), PROJECT_CONTEXT
    §5.1, playable_character_visuals, ROADMAP backlog row.
  - **Scarlet** (GDD §14 #52): measured her images (1254², transparent, alpha 1–2 haze across the
    canvas, body at alpha 253–254, no pixel grid, 69k–93k colours, no outline). Her head against the
    storefront's, on the crown's middle diamond (106 / 106 / 86 / 77 px), eyes and earrings: floor
    1.00, right wall 0.82, dash 0.72. Comparison sheets for the owner (her at 194/180/166/152 beside
    Patchvile; the poses at one scale; head-matched at 194 and 166, where the dash fits the 256 frame
    only up to ~174 px standing). New pack `concept_art/scarlet_autosprite_v1/`: `sources/` (the
    four PNGs from the owner's `Desktop\Scarlet\Sprite Concepts`, unchanged; the pasted WebP copies
    differed by ~2.4 per channel), `build_first_frames.py` (Mothmere's conversion, `STANDING` 166,
    `POSE_SCALE` right wall ×1.22 and dash ×1.38), four first frames, review sheet, metadata.
    PROJECT_CONTEXT §2/§5.2, ROADMAP M13, system page, guide and ASSETS name her.
- **Files/systems:** `tools/art/extract_playable_characters.py`, `concept_art/scarlet_autosprite_v1/`,
  `AGENTS.md`, `docs/{GDD,PROJECT_CONTEXT,ROADMAP,ASSETS}.md`, `docs/guides/character_creation.md`,
  `docs/decisions/0018-pixel-art-direction.md`, `docs/systems/playable_character_visuals.md`.
- **Verified:** first frames 1024², exact 4 × 4 blocks, 255 colours, transparent; storefront 146 ×
  166, floor 161 × 126, right wall 181 × 179, dash 214 × 178 (margins ≥ 21 px of 256). The new check
  on Shade's and Mothmere's first storefront frames: 196 px against 194, +1 %, ok (the check alone;
  nothing was re-packed). `tools/validate.sh` → `VALIDATE: OK`.
- **Follow-ups (owner):** describe Scarlet's animations, the dash included, for her AutoSprite
  prompts. When she is added: does she take Ilyra's save id and menu video. Ilyra's 2026-09-24
  AutoSprite brief (`concept_art/ilyra_autosprite_v1/`) is left as it is.

## 2026-09-26 — Patchvile's Codex reference frames kept in his pack
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "yes save them in his folder" - the four Patchvile reference frames made for the
  Codex first-frame prompt on 2026-09-25.
- **Did:** `concept_art/patchvile_autosprite_v1/codex_reference/`: `patchvile_storefront.png`,
  `patchvile_wall_bottom.png`, `patchvile_wall_right.png`, `patchvile_dash_attack.png` (1024 × 1024,
  4 × 4 blocks, 776 px standing, transparent). Kept apart from `references/`, which holds the owner's
  original images. Character guide §3 and ASSETS point to them.
- **Verified:** each file equals its source frame scaled 4× nearest (the dash turned back a quarter);
  `tools/validate.sh` → `VALIDATE: OK`.

## 2026-09-25 — Codex prompt, Patchvile references, the fan character's fixes; session docs
- **Who:** Claude Code (Opus 5.5)
- **Owner requests:** a Codex prompt for a new character "in rules the game needs"; Patchvile's pixel
  block size; "the codex frames" (owner answer: Patchvile's poses as Codex references); prompts for
  Codex to fix the fan character's images; then "document everything … what we did in this session".
- **Did:**
  - The general Codex prompt for four first frames (1024 canvas, 4 × 4 blocks, 776 px standing, no
    outline, ≤ 256 colours, ≥ 60 px margin, same scale and weapon hand in all four) — now in the
    character guide §3.
  - Measured Patchvile: 1 art pixel = 1 px of his 256 px frames (87 % of same-colour runs), 2 × 2 in
    his 640 px dash upload, about 1.3 screen px per art pixel in a run (headless, 1920 × 1920) —
    guide §3.
  - Patchvile's four poses as 1024 Codex references (his first AutoSprite frame per state, the dash
    turned back to fly left, 4× nearest): sent to the owner, not kept in the repo; how to rebuild them
    is in guide §3.
  - The fan character (the owner's new Codex images; not named this session): checked all four
    (1024², transparent) and wrote three Codex edit prompts. `wall_bottom`: the fan hand is a pale
    blob, the fan has no handle, and the ribs are missing left of her body. `dash_attack`: the braid
    covers the fan's lower end, so the braid goes behind the fan. `wall_right`: the owner's earlier
    version is kept and only the fan is raised a little (owner answer: "A bit higher").
  - Docs: guide §3–§4 (the Codex prompt, the reference frames, the measured pixel size, PNG exports
    over pasted WebP, shorter sheets, Mothmere's pack as an example); GDD §14 #49 (Mothmere's look)
    and #50 (Settings scrolling).
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`.
- **Follow-ups (owner):** the fan character's fixed images, then first frames and AutoSprite prompts;
  install the last build (Settings with no scroll bar) when the phone is connected.

## 2026-09-25 — Settings scroll bar hidden; Mothmere's prompts saved
- **Who:** Claude Code (Opus 5.5)
- **Owner answers:** keep the Settings touch pass-through; a swipe on a slider keeps moving the slider,
  and "remove the slider for scrolling the page" = hide the scroll bar (confirmed when asked); fix the
  outdated developer-card section of the Settings doc; save Mothmere's prompts in his pack.
- **Did:** `settings_screen.tscn` `%Scroll` `vertical_scroll_mode` = SHOW_NEVER (swiping still
  scrolls); script comment and `settings.md` (scene tree, rule, the slider note, the developer card's
  four actions, `test_dev_unlock` marked stale); `concept_art/mothmere_autosprite_v1/PROMPTS.md`
  (first frames, settings, the four prompts without "no outline", the cells the game uses); ASSETS row.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; `test_m4_systems` passes; Settings rendered at
  540×960 with no scroll bar and the cards still continuing below the fold.

## 2026-09-25 — Mothmere is in the game
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "Here are the sprite sheets for the character now implement them" — the four
  AutoSprite exports (`C:\Users\marti\Desktop\Mothmere\sheet`). Owner answers: description "A
  moth-pale cloak, a quiet step, and a flame that reaps red."; dash effects red; his dash throws "like
  red trail"; dust landing.
- **Did:** `concept_art/mothmere_autosprite_v1/`: the four exports in `raw/` unchanged, `slice_sheet.py`
  (storefront 22, floor 18, right wall 23, dash 8 of 25: flight 07, wind-up 08-09, swing 11, full red
  reap 12 = contact frame 4, 13, 15, end of the swing 19; turned a quarter so it flies up),
  `mothmere_sprite_sheet.json`; `SHEET_PACKS["mothmere"]` (Patchvile's layout and `derive`,
  `roster_scale`) → `assets/art/characters/playable/mothmere/` and `data/characters/mothmere_*.tres`.
  `MothmereVisual` (`dash_head_up`, red `attack_glow`, no shader slash since his frames draw the reap,
  red dot `%DashParticles` and red additive `%TrailParticles`), `data/forms/mothmere.tres` (free,
  Standard, like the whole roster; last in the catalog), `data/characters/dash_effects/mothmere.tres`
  (`RIBBON` in red a little deeper than the drawn reap, which sits 24.6° from the danger amber, just
  inside the reserved 25°; shared cyan trails off; dust in Patchvile's tint). Registered:
  `default_catalog.tres`, `REQUIRED_FORM_COUNT` 6, `VALID_FORM_IDS`, the roster lists in
  `test_form_catalog`, `test_playable_character_visual`, `bench_character_previews`. New
  `test_mothmere_visual.gd`. The pasted WebP copies of the dash and wall sheets were lossy, so the
  owner's PNG exports are used (the WebP copies went to the Recycle Bin).
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (103 scripts). ROSTER CHECK 196 px (+1 %) ok.
  Tests pass: `mothmere_visual`, `form_catalog`, `dash_effects`, `playable_character_visual`,
  `patchvile_visual`, `verdant_shade_visual`, `ilyra_visual`, `m4_systems`, `game_flow`,
  `player_health_flow`, `screen_transitions`, `wall_splash`. The state board reaches every
  animation; a headless check confirmed the dash's forward (the staff and flame) points along the
  flight for up, left, right and down dashes once the heading has turned.
- **Follow-ups (owner):** look at him on the phone, and check the dash direction in a slowed run.
  `render_whole_frame_states` still holds dash frame 2 for its "contact" cell rather than each
  character's own contact frame.

## 2026-09-25 — Mothmere: AutoSprite first frames
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** check the four Codex images of the new character Mothmere
  (`C:\Users\marti\Desktop\Mothmere`) and write the AutoSprite prompts: a storefront where he
  breathes, his cloth, head, hands and legs move a little, and he strikes the floor with the bottom of
  his staff so particles fly; walls with normal breathing, moving cloth, ready to attack; the dash one
  hit, a staff swing with a red reap. Owner answer: keep the outline the images carry (GDD §14 #49).
- **Checked:** the four poses are the recipe's four first frames (front, floor crouch, right-wall
  cling, side-on dash), the staff in his right hand in all, one scale (the staff's flame spirit
  96–102 px wide in each), transparent. Not upload-ready: 1254 px off any pixel grid, standing 81 %
  of the height instead of 76 %, a faint background-remover haze and a body at alpha 253, and a thin
  dark outline (95–97 % of the cloak's edge pixels on three poses, 70 % standing).
- **Did:** new source pack `concept_art/mothmere_autosprite_v1/`: the owner's images unchanged in
  `sources/`; `build_first_frames.py` clears the haze, makes the body solid, reduces all four at the
  roster scale (0.1897; standing exactly 194 px), quantizes to 256 colours with soft edges and the
  outline kept, and delivers 4× nearest at 1024 → four `*_first_frame.png`, `review_first_frames.png`,
  `first_frames_metadata.json`. The prompts were given in chat.
- **Verified:** every frame is uniform 4 × 4 blocks, ~90 % of visible pixels solid (Patchvile's
  AutoSprite frames: 86 %), margins ≥ 27 px (the dash's sides).
- **Follow-ups (owner):** generate the four sheets in AutoSprite; then the slicer (the dash keeps only
  the single swing), packer entry, scene, data and effects per the character guide.

## 2026-09-25 — Rift wording replaced; Settings scrolls
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "do the renaming to that and make settings scrollable for mobile devices" — the
  18 player-facing "Rift" texts, with the wordings the owner approved.
- **Did:** texts: pause `PAUSED`; Daily `DAILY RUN`, `PLAY TODAY'S RUN`, `DAILY SEED  ·  …`,
  "… FOR FINISHING TODAY'S RUN"; Home Daily tooltip `Daily Run`; Results `RUN SCORE`; statistics
  `TIME PLAYED`; Trials `REAP THE HORDE` (t01–t12), `BOSS BREAKER`, `ARENA SOVEREIGN`; daily challenge
  `DEEP DIVER` (id `rift_diver` kept); Endless mix `SHATTERED WASTES` (roster id kept); fallback wave
  callout `WAVE %02d`; tutorial "The arena is yours." and "You can replay it any time from Settings.";
  Abyssal dash description; developer UNLOCK EVERYTHING tooltip. Internal names unchanged.
- **Did (Settings):** the header stays fixed and a vertical `%Scroll` holds the cards and the feedback
  line; `_show_feedback` scrolls the feedback into view. Cards and buttons (scene and the code-built
  developer card) use mouse filter Pass: with the default Stop, a touch swipe scrolled only when it
  started in the gaps between cards.
- **Files/systems:** `scenes/screens/{settings,daily,home,results}_screen.*`,
  `scenes/screens/statistics_screen.gd`, `scenes/gameplay/game_world.{tscn,gd}`,
  `scenes/tutorial/tutorial_screen.tscn`, `scripts/resources/tutorial_catalog.gd`,
  `scripts/utils/challenge_tracker.gd`, `data/trials/`, `data/endless/rosters/shattered_rift.tres`,
  `data/dash_styles/abyssal.tres`, `tools/godot/test_m4_systems.gd`; docs GDD §14 #48, ROADMAP M10,
  systems challenges / meta_progression / settings, marketing devlog_video_brief §7.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. Tests pass: `m4_systems`, `trials`,
  `challenge_tracker`, `endless_catalog`, `endless_enemies`, `game_flow`, `player_health_flow`,
  `boss_variants`, `dash_effects`, `gameplay_slice`, `screen_transitions`, `wave_director`,
  `wall_splash`; the 7 stale ones fail as before. `tools/qa_matrix.sh settings`: header whole at all
  five phone sizes, cards scroll under it. Simulated touch swipes (scratch script): scroll from
  captions, labels, toggles and buttons; a tap still flips a toggle; a short swipe on PRIVACY & ABOUT
  scrolls without opening it.
- **Follow-ups:** a vertical swipe that starts on a slider moves the slider instead of scrolling.
  `tools/screenshot.sh` at a size other than 9:16 (e.g. 540x1170) records a 1080×1920 movie that
  cuts the top and bottom off every screen (Trials too) — a capture artifact, not the layout.
  settings.md's developer-card section still lists "unlock all Rifts" and five actions.

## 2026-09-25 — Story Rifts removed; Endless keeps their enemy mixes and bosses
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "remove the rift concept entirely just keep it in the docs as history". Owner
  answers: the currency keeps the name Rift Points; Endless "plays exactly as it does now" with its
  enemies and bosses (new enemy sheets come later, after the characters); player-facing texts that
  say "Rift" get a proposed new wording first and change only once the owner approves it.
- **Did:** removed story mode, the Rift Map, the five Rifts with their twists (portals, shrinking
  floor, drift, boss rush), level victory and clear bonuses, the four Rift backdrops, props `10`–`16`,
  their source sheets `01`–`05` and the floor-polygon baker — 46 items to the Windows **Recycle Bin**,
  nothing permanently deleted. **Endless unchanged:** its five enemy mixes and boss pool moved from
  `RiftData` into new `EndlessRoster`s (`data/endless/rosters/`) on `EndlessCatalog.rosters`, in the
  same order with the same values, so the seeded picks are identical. Save v9 drops `selected_rift`,
  `rift_bests`, `rift_levels`. Results show only the Endless/daily outcome; Home's caption node is
  `PlayCaption`; the tutorial replay is Settings only; DevUnlock and Settings lose UNLOCK ALL RIFTS;
  the Trial metric `level_clears` is gone. Simplified along the way: the loading pool keeps three
  backgrounds, `test_dash_geometry` checks the Endless floor only, `calibrate_rp` uses the daily pool.
  `test_rift_enemies` → `test_endless_enemies`; `test_wall_splash` now watches both landing styles
  (Patchvile, the default, lands in dust).
- **Kept (not asked to change):** every player-facing "Rift" text (list sent to the owner for
  wording), internal names (`rift_spawn`, roster ids such as `shattered_rift`, `extract_rifts.py`,
  `concept_art/wisp_rush_rifts_v1/`, challenge id `rift_diver`, `RIFT_MAGENTA`), and the Rift docs as
  history (rifts.md, ADRs, specs, GDD §14 #48).
- **Files/systems:** `scripts/resources/{endless_roster,endless_catalog,endless_tuning,economy_tuning,trial_catalog}.gd`,
  `data/endless/`, `scenes/gameplay/{run_profile,arena_rules,endless_arena_rules,game_world,wave_director}.gd`,
  `scenes/player/wisp_player.gd`, `scripts/autoload/save_manager.gd`, `scenes/main/main.gd`,
  `scenes/screens/{results,home,loading,settings}_screen.*`, `scripts/utils/dev_unlock.gd`,
  `tools/godot/*`, `tools/art/extract_rifts.py`, `tools/qa_matrix.sh`; docs PROJECT_CONTEXT, GDD, ADR
  0007/0008/0011/0013 status, 15 system docs plus rifts.md as history, ROADMAP, ASSETS, tool READMEs, marketing notes.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (102 scripts). Tests: 30 pass, including
  `endless_catalog`, `endless_enemies`, `boss_variants`, `game_flow`, `player_health_flow`, `trials`,
  `dash_geometry`, `wall_splash`; the 7 that fail are the stale ones from before (removed
  `forms_screen` / `FormsScreen`, `purchase_form`, `DevUnlock.get_unlock_wave`).
- **Follow-ups (owner):** approve the wording for the "Rift" texts; `tools/art/check_endless_skin.py`
  (already retired) imported the removed floor baker and no longer runs.

## 2026-09-25 — Strict rules for agents: ask when unsure, never bluff
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** make it a strict rule that an agent who is not sure what it is doing, or did not
  understand what the owner wants, does not generate anything but asks for clear instructions; that it
  never writes anything the owner did not tell it or mention; and that it asks before adding anything
  to the docs it is not certain about.
- **Did:** new `AGENTS.md` §0 **STRICT RULES** above everything else (not sure → ask, no bluffing, docs
  only with certainty, only what was asked, questions get answers); §2 and §7 point to it.
  PROJECT_CONTEXT §7 carries the docs half, and §7.7 no longer lets an agent write guesses as
  `ASSUMPTION:` without the owner's approval.
- **Files/systems:** `AGENTS.md`, `docs/PROJECT_CONTEXT.md`.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`.

## 2026-09-25 — Roster cut to five; Patchvile is the default; old sources removed
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "delete everything old about patchvile and shade keep the current and delete the
  following characters from the game noxen, veyra, eclipse and void". Owner answers: Patchvile takes
  Void's place as the default; delete the four characters' source art too; keep the original
  reference images; delete the old per-frame guide.
- **Did:** everything removed went to the Windows **Recycle Bin** (52 files and folders), nothing was
  permanently deleted. **Kept first:** the owner's originals (`patchvile.png`, `dagger.png`,
  `reference_original.jpg`) → `concept_art/patchvile_autosprite_v1/references/`; Patchvile's four
  particle scraps → `…/particles/`; Shade's five first-frame source poses →
  `concept_art/verdant_shade_autosprite_v1/sources/` (both re-packs and the first frames verified
  byte-identical). **Removed:** old Patchvile (`patchvile_sprite_v1`, `patchvile_full_frames_v1`,
  `patchvile_idle_v1`, `premium_character_*`, the v1 dash sheet), old Shade (`verdant_shade_v1`,
  `verdant_shade_sprite_v1`, the menu video, its source and `MenuVideoData`), Void, Eclipse, Veyra and
  Noxen (scenes, forms, dash effects, frame sets, runtime art, the old form icons, tests, source
  packs), and `docs/guides/character_sprite_frames.md`. **Code:** `FormCatalog.DEFAULT_FORM_ID` /
  `SaveManagerService.DEFAULT_FORM_ID` = `patchvile`, five forms, the catalog opens on Patchvile;
  saves naming a removed character fall back to him (unknown ids are dropped; no migration). Packer:
  their entries and the two cleanup passes only they used are gone; Noxen's rig-builder entry and
  Shade's menu-video pack too. Home's placeholder is Patchvile's portrait. Tests and tools moved to
  the remaining roster.
- **Files/systems:** `data/forms/`, `scripts/{resources/form_catalog,autoload/save_manager}.gd`,
  `scenes/screens/{shop,statistics}_screen.gd`, `home_screen.tscn`, `game_world.tscn`,
  `scenes/debug/theme_gallery.gd`, `tools/art/{extract_playable_characters,build_character_rig,extract_menu_video,motion_contact_sheet}.py`,
  `tools/godot/*`; docs AGENTS, PROJECT_CONTEXT, GDD (§6, §9, §13, #34, #47), ADR-0015/0016 status,
  playable_character_visuals, forms, shop, character guides, ROADMAP, ASSETS, marketing notes.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (106 scripts). Tests: 28 pass, including
  `form_catalog`, `playable_character_visual`, `patchvile_visual`, `verdant_shade_visual`,
  `ilyra_visual`, `dash_effects`; the 10 that fail are the stale ones listed before (removed
  `forms_screen`, `purchase_form`, `configure_run_profile`, DevUnlock APIs). Patchvile's and Shade's
  runtime art unchanged byte for byte. A packer run over every character rewrote Rook's and Morrow's
  layers on this machine; they were restored from git (docs now say to name the characters).
- **Follow-ups (owner):** the Recycle Bin holds everything removed until it is emptied.

## 2026-09-25 — Shade's dash leads with the face
- **Who:** Claude Code (Opus 5.5)
- **Owner report:** slowed down in Godot, the dash "is backwards, he has to attack with his face in
  front not in back". (The dash stays a one-shot, as it already was.)
- **Did:** the sheet draws the flight face down, horns up, and the rig flies a dash frame toward its
  top, so the horns led. `slice_sheet.py` now turns each of the eight dash cells 180°; re-sliced and
  re-packed. The old Codex dash had the same orientation (the +Y wording the guide §8 lists as a
  known gap), and the first frame was taken from it without checking the direction. Guide §6 now
  says a symmetric upright dash is turned so the face leads, and to check it in a slowed run.
- **Files/systems:** `concept_art/verdant_shade_autosprite_v1/{slice_sheet.py,frames,PROMPTS.md,build_first_frames.py}`,
  `assets/art/characters/playable/verdant_shade/verdant_shade_dash.png`, `data/characters/verdant_shade_gameplay.tres`,
  `docs/guides/character_creation.md`, `docs/systems/playable_character_visuals.md`, `docs/ASSETS.md`.
- **Verified:** the packed dash sheet shows the mask at the top of every frame; `tools/validate.sh`
  → `VALIDATE: OK`; `verdant_shade_visual` passes; APK rebuilt and installed.
- **Follow-ups (owner):** Void's and Eclipse's Codex dashes were drawn to the same +Y wording and
  may lead with their backs too (not checked, not changed).

## 2026-09-25 — Shade rebuilt on the AutoSprite recipe
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "Here is everything you need for shade implement it now" — five AutoSprite
  sheets (storefront, floor, right wall, ceiling, dash attack) from the first frames of
  `concept_art/verdant_shade_autosprite_v1/`.
- **Did:** exports copied unchanged to `raw/`. The sheets fill 21–24 of their 25 cells. New
  `slice_sheet.py`: storefront 24, floor 23 (its last cell repeats the first), right wall 21, the
  owner's own ceiling 23, and the dash as a one-shot of eight cells (03–05 flight, 11 burst opening,
  12 full burst = contact frame 4, 13–14–16 follow-through). Dash cells 06–09 swing the body upright
  and 06/10/21 carry white glare blobs, so none are used. The four loose leaves of the right-wall
  frame become the dash particles. Packer entry replaced: `roster_scale`, Patchvile's cells (run
  256, dash 336, menu 448), `derive` only for the left wall. Scene rebuilt on Patchvile's layout
  (`design_size` 256, `art_scale` 1.1875, `menu_art_scale` 1.25, contact frame 4, pale green attack
  glow, no shader slash, leaf `DashParticles`, green `TrailParticles`); the menu video is off and
  `menu_frames_path` warms the storefront. Dash effect: `shared_trails` off, `DUST` landing in muted
  green. `test_verdant_shade_visual.gd` rewritten for the new contract (99 frames, one-shot dash,
  storefront menu, a 36 px float allowance for the storefront); Void and Eclipse stay the looping
  dashes in `test_patchvile_visual.gd`.
- **Files/systems:** `concept_art/verdant_shade_autosprite_v1/{raw,frames,particles,slice_sheet.py,verdant_shade_sprite_sheet.json,PROMPTS.md}`,
  `tools/art/extract_playable_characters.py`, `assets/art/characters/playable/verdant_shade/`,
  `data/characters/verdant_shade_{gameplay,menu,frames}.tres`, `data/forms/verdant_shade.tres`,
  `data/characters/dash_effects/verdant_shade.tres`, `scenes/player/visuals/verdant_shade_visual.{gd,tscn}`,
  `tools/godot/test_{verdant_shade,patchvile}_visual.gd`; docs PROJECT_CONTEXT, GDD (§9, #35, #37),
  ADR-0016 status, playable_character_visuals, forms, ROADMAP, ASSETS.
- **Verified:** ROSTER CHECK 196 px (+1 %) ok; `tools/validate.sh` → `VALIDATE: OK`; tests
  `verdant_shade_visual`, `patchvile_visual`, `form_catalog`, `playable_character_visual` pass. Debug
  APK exported; no phone was connected, so it is not installed. No render pass (owner tests on the phone).
- **Follow-ups (owner):** phone test. Storefront speed: 24 frames at 12 fps play the 4 s clip in 2 s
  (6 fps would be real time). Effect colours, the leaves and the dust landing are first choices.

## 2026-09-25 — Characters drawn exactly like Patchvile; agents ask before acting
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "remove the outline, keep it like patchvile", "the rules shall match exactly like
  patchvile", and "write in agent docs that before the agent does something that wasn't said it to do
  shall first ask me".
- **Did:** Measured Patchvile: no outline (edge pixels as bright as the inside), AutoSprite's
  256-entry paletted export (~255 entries, ~63 transparency levels, soft edges), dash uploads = his
  256 px frames enlarged 2× nearest. The one-pixel outline, 48-colour palette and binary alpha in the
  character recipe were never owner rules (added when ADR-0018 was written). **Rules:** character
  guide §3 rewritten to Patchvile's look; ADR-0018 addendum; GDD §9 and §14 #46; AGENTS.md §1 5b,
  CLAUDE.md and PROJECT_CONTEXT §1 except characters from the outline/palette rule; Ilyra's and
  Shade's briefs. **Shade:** `build_first_frames.py` rebuilt: no outline, up to 256 colours with soft
  edges, glow kept, the slivers' glow and cut-strand fragments removed; all five first frames
  regenerated. **Agents:** AGENTS.md §2 opens with "do only what the owner asked; ask before anything
  else", §2's GDD and scope bullets and §7 no longer let an agent decide and keep moving.
- **Files/systems:** `AGENTS.md`, `CLAUDE.md`, `docs/{GDD,PROJECT_CONTEXT,ASSETS}.md`,
  `docs/decisions/0018-pixel-art-direction.md`, `docs/guides/character_creation.md`,
  `concept_art/{verdant_shade,ilyra}_autosprite_v1/`.
- **Verified:** Shade's five frames: 4 × 4 blocks at 1024, 255 colours, ~90 transparency levels, no
  outline, storefront 194 px standing, margins ≥ 34 px; side by side with Patchvile's storefront
  frame. `tools/validate.sh` → `VALIDATE: OK`.
- **Follow-ups (owner):** Ilyra's first frames in her folder still have the old dark outline and
  48-colour palette; rebuild them without it? (not done: not asked).

## 2026-09-25 — Patchvile marked approved; Shade's AutoSprite first frames and prompts
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "Patchvile is approved how it is created … fix the docs", then "begin with creating
  sprite sheets for the Shade character": AutoSprite prompts for every state, upload-ready images from
  the current ones ("the positions are good"), and a storefront idle exactly as the video described it.
- **Did:** **Patchvile docs:** the "not approved / for review / Codex's dash" wording is gone from
  PROJECT_CONTEXT §2/§5.1/§5.2, playable_character_visuals (Files, status, attack and `art_scale`
  rows: contact frame 4, `art_scale` 1.1875), GDD #40's status, ASSETS (runtime sheets: three sheets,
  8-frame dash, 256² portrait, AutoSprite source) and the `patchvile_visual.gd` class doc.
  **Shade:** today's frames are not uploadable as they are (painted, drawn at 96 % of the canvas
  against the roster's 76 %, atlas slivers in the floor frame, every left-wall frame clipped with its
  tail cut flat). `concept_art/verdant_shade_autosprite_v1/build_first_frames.py` keeps the poses
  (`idle_hover_00`, the menu video's start; `wall_bottom_00`; `wall_left_00` mirrored to the right
  wall; the upright `dash_loop_01`; optionally `wall_top_00`) and makes pixel-art first frames at the
  roster size. `PROMPTS.md` holds the upload table, settings, a complete prompt per sheet (the
  storefront is VIDEO_PROMPT.md's motion line for line) and the reject list. Guide §6: a symmetric
  character may upload its dash upright (slicer 0°, `dash_head_up` off).
- **Files/systems:** `docs/{PROJECT_CONTEXT,GDD,ASSETS,ROADMAP}.md`, `docs/systems/playable_character_visuals.md`,
  `docs/guides/character_creation.md`, `scenes/player/visuals/patchvile_visual.gd` (doc only),
  `concept_art/verdant_shade_autosprite_v1/`.
- **Verified:** the five first frames are exact 4 × 4 blocks at 1024, binary alpha, one shared
  47-colour palette, margins ≥ 26 px; the storefront stands 194 px (the roster check's number).
  Frames reviewed on `review_first_frames.png`. `tools/validate.sh` → `VALIDATE: OK`.
- **Follow-ups (owner):** generate the four sheets into `raw/`; decide the ceiling (floor flipped, or
  the optional fifth sheet for today's pose) and whether Home/Shop keep the painted menu video or play
  the new storefront. Ilyra's docs still say she has no first frames, but six exist in her folder.

## 2026-09-25 — Smaller startup splash logo
- **Who:** Codex (GPT-6)
- **Owner request:** make the Wisp Rush logo smaller on the splash screen.
- **Did:** generated a separate Godot boot-splash image with a centered 1080 px wide logo on its 1440×960 transparent canvas, and reduced the Android system splash logo from 220 to 168 px wide. Both use the existing opaque brown-face wordmark on a hard 4 px grid. `project.godot` now selects the dedicated splash image; Home/loading continue using their larger logo.
- **Files/systems:** `tools/art/make_app_icon.py`, `project.godot`, `assets/art/branding/wisp_rush_splash_logo.png`, `assets/art/branding/app_icon/android_splash_icon_432.png`; source-pack, asset, and project-context docs.
- **Verified:** portrait splash preview visually checked and Windows validation printed `VALIDATE: OK`. Android debug APK export succeeded; its packaged system splash exactly matches the new 168 px logo image.
- **Follow-ups:** check both startup stages on an Android device before release.

## 2026-09-25 — Brown cloth face in Wisp Rush branding
- **Who:** Codex (GPT-6)
- **Owner request:** correct the black head in the icon, splash, and Home logo to match the original character's brown stitched-cloth face.
- **Did:** used the original character reference to make brown face edits, then transferred only the face into the existing pixel Home wordmark and v4 icon. Kept the approved hood, lettering, background, and composition. Rebuilt the runtime Home/loading/Godot splash logo, Android system splash icon, and project/Android launcher assets from their source scripts.
- **Files/systems:** `concept_art/wisp_rush_home_pixel_v1/`, `concept_art/wisp_rush_app_icon_pixel_v1/`, `assets/art/branding/`, `tools/art/make_app_icon.py` outputs; source-pack, asset, and project-context docs.
- **Verified:** visually inspected the 128 px icon, actual Home render, and portrait splash preview; logo face is opaque, both masters remain on a 4 px grid, and the icon retains 64 colors. Both source rebuilds are deterministic. Windows validation printed `VALIDATE: OK`; Android debug APK export succeeded and its packaged system splash and launcher foreground exactly match the new PNGs.
- **Follow-ups:** check Android launcher and both splash stages on a connected device before release.

## 2026-09-25 — Backgroundless splash and opaque Home-logo face
- **Who:** Codex (GPT-6)
- **Owner request:** remove the splash-screen background and fix the transparent face in the Home-screen logo.
- **Did:** restored the original dark face and left hood stitch in the transparent logo source with `repair_logo_face.py`, then regenerated `wisp_rush_logo.png` for Home/loading. The Godot boot splash now draws that repaired transparent logo over a plain charcoal color. Added a separate transparent Android system splash icon; the v4 game/launcher icon keeps its approved dark-stone background.
- **Files/systems:** `concept_art/wisp_rush_home_pixel_v1/`, `assets/art/branding/wisp_rush_logo.png`, `tools/art/make_app_icon.py`, `assets/art/branding/app_icon/`, `project.godot`, `export_presets.cfg`; asset and project-context docs.
- **Verified:** `VALIDATE: OK`; visually inspected the repaired logo over a bright test color, the portrait splash preview, and a rendered Home-screen frame. Android debug APK export succeeded; its packaged system splash and launcher foreground exactly match their separate source PNGs. The prior full suite still has unrelated stale Forms/unlock tests (31 passed, 10 failed); no gameplay code changed.
- **Follow-ups:** check both splash stages and the Home logo on an Android device when one is connected.

## 2026-09-25 — Approved pixel icon installed for launcher and splash
- **Who:** Codex (GPT-6)
- **Owner request:** use the v4 Wisp Rush icon as the game icon and on the splash screen.
- **Did:** changed `tools/art/make_app_icon.py` to rebuild the project icon, Android legacy and adaptive icon layers, and a 1024 px boot-splash image from the approved pixel master. The boot splash now uses that image, a matching charcoal background, and nearest filtering. The Android export preset keeps its existing icon paths, whose generated files now contain v4. Updated source-pack and asset documentation.
- **Files/systems:** `tools/art/make_app_icon.py`, `assets/art/branding/app_icon/`, `project.godot`; `concept_art/wisp_rush_app_icon_pixel_v1/README.md`, `docs/ASSETS.md`, `docs/PROJECT_CONTEXT.md`.
- **Verified:** visually checked the 192 px launcher icon, circular adaptive mask, and portrait splash composition. Windows project validation printed `VALIDATE: OK`; the Android debug APK exported and contains the updated launcher and native splash icon resources. The full headless suite had 31 passes and 10 failures in existing Forms/unlock API tests, two missing-method hangs, and a Rift rules leak report; none of the errors reference branding files. No Android device was connected for an installed-app check.
- **Follow-ups:** check the installed Android launcher and startup on a device before release; resolve the separate stale test suite failures.

## 2026-09-25 — Dark-stone background for the named Wisp Rush icon
- **Who:** Codex (GPT-6)
- **Owner request:** add a background to the Wisp Rush game icon while retaining the game name.
- **Did:** added a subdued pixel-stone courtyard behind the broken wisp and exact two-line WISP RUSH title. Saved v4 as a source-only 1024 px master, 128 px preview, raw draft, and reproducible Pillow build script. Updated the icon pack README and asset registry.
- **Files/systems:** `concept_art/wisp_rush_app_icon_pixel_v1/`; `docs/ASSETS.md`.
- **Verified:** visually reviewed master and launcher-size preview; 1024×1024 opaque RGB, 64 colors, uniform 4×4 pixel blocks. Runtime branding and export configuration remain unchanged.
- **Follow-ups:** owner review of v4 before any integration task.

## 2026-09-24 — Ilyra's AutoSprite brief finished; she is not added yet
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** her animations ("walls as they are now, only cloth, breathing and hair moving";
  "the dash like Patchvile, one fan attack"; "storefront: breathes, legs close, looks ahead then at
  both fans, repeats"), "make sure every detail is visible like her four hands", pixel art, one image
  prompt and one AutoSprite prompt per state, and the standard four sheets ("for top and bottom I
  create bottom and mirror top; left and right I create right and mirror"). Then "document
  everything, the Ilyra character is not added".
- **Did:** `concept_art/ilyra_autosprite_v1/PROMPTS.md` is her complete brief. It covers the five
  animations; four sheets (storefront, floor, right wall, dash), with the ceiling flipped and the
  left wall mirrored by the packer; the pixel rules; Patchvile's pixel count (194 px standing, 776 on
  the 1024 image, head ~41); and one image prompt and one AutoSprite prompt per state. The fans stay
  in "the same two hands as the reference", every detail is visible, and "she stays exactly the size
  and in the same place". Docs: ROADMAP M13 (her rework in progress, the rest of the roster
  queued), PROJECT_CONTEXT §2, ASSETS, playable_character_visuals known issues, and the ui_design_system
  HUD notes (no framed score, no health icon).
- **Not done:** no first frames, sheets, slicer, packer entry, scene or effects. The game still runs
  the old `IlyraVisual` with her menu video.
- **Follow-ups (owner):** generate her four AutoSprite sheets into `raw/`; keep her menu video or use
  the new storefront; pick her name (ideas given, id stays `ilyra`).

## 2026-09-24 — Every character gets Patchvile's pixel count
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** base the character size on Patchvile: say in the Codex prompt and the character
  guide how many pixels each character contains, since AutoSprite outputs 256 × 256 ("yes update the
  guide, ilyra prompt and packer"). Earlier the same session a pixel-budget packer and 2× drawing were
  built, then reverted at the owner's request ("revert everything as it was").
- **Did:** measured that AutoSprite keeps the upload's proportions exactly (Patchvile's dash upload
  77.2 % wide, the frame 77.3 %) and that he stands **194 px in his 256 px frames** (76 %; 186
  crouched, 187 on the wall). **Guide** §3/§4/§6/§7: the roster size (194 of 256, 776 px on Codex's
  1024 first frame, every pose at one scale) and `"roster_scale": True` for every character after
  Patchvile. **Packer:** `roster_scale` packs at his exact scale (`ROSTER_RUN_FACTOR` 1.253 cell px
  per source px, `ROSTER_MENU_FACTOR` 1.848), with each animation centred on its own bounds. A
  `ROSTER CHECK` on the first storefront frame warns past ±5 % of 194 px and refuses past ±10 %.
  **Ilyra's brief:** 194 px standing crown to boots, head ~41, the dash at the same scale (it said
  head 33 / ~130 px). GDD §14 #43, ADR-0018 and the ROADMAP drop the 2 px rule.
- **Verified:** Patchvile packed through `roster_scale` into the scratchpad matches his real run,
  dash, menu and portrait sheets pixel for pixel (max difference 0), and his check reads 194 px,
  +0 %. His own pack is unchanged.

## 2026-09-24 — Ilyra wisp-fan attack scene
- **Who:** Codex (GPT-6)
- **Did:** generated one pixel-art action scene from Ilyra's wisp-fan A-pose, showing her attacking with both fans, four visible arms, two legs and a dark arena backdrop. Saved it as a source-only concept for owner review.
- **Files/systems:** `concept_art/ilyra_wisp_attack_scene.png`; `docs/ASSETS.md`.
- **Verified:** visually reviewed the attack pose and fan motifs; confirmed the PNG is 1254×1254 opaque RGB. No runtime files changed.
- **Follow-ups:** owner review; this illustration is not a strict-grid AutoSprite frame.

## 2026-09-24 — Pixel UI kit integrated into every menu and the HUD
- **Who:** Claude Code (Opus 5.5), background session for the owner ("implement that redesign in the game")
- **Did:** replaced the texture step with one that copies the pixel kit (`concept_art/wisp_rush_pixel_ui_v1/`) into `assets/ui/theme/textures/` + `icons/`. It checks the 4 px grid, derives four focus rings (focus art minus normal art), and moves nine-slice bands off ornaments, so stitches, studs and runes never smear. The theme builder wraps every UI PNG in a nearest-filtered `CanvasTexture` `.tres`, so the UI is crisp and the project filter is untouched, then rebuilds every variation from kit pieces. Titles and reward numbers get a hard 4 px drop shadow instead of glows.
- **Did:** added the `CaptionTile` variation (Home's Trials, Daily, Shop, No Ads, and Rifts, now 140 × 164) and `RewardPlate` (Results reward plates, Daily reward). Kit glyphs replace the painted ones where the kit has one (play, pause, home, lock, settings, shop, trials, daily, stats, currency, HUD Soul Fragment), with icon boxes snapped to whole-art-pixel sizes. `PageDots` draws the kit diamonds, the Shop tabs draw the kit tab inside the 88 px touch row, and the upgrade-tray highlight uses the new selected card. The HUD XP strip is 20 px. Palette gains five kit colours (decoration only). Layout and flow are unchanged.
- **Files/systems:** `assets/ui/theme/{tools/*,textures/,icons/,ornaments/,wisp_theme.tres}`, `scripts/utils/palette.gd`, `scripts/components/page_dots.gd`, `scenes/screens/{home,results,daily,settings,statistics,shop,trials}_screen.tscn`, `home_screen.gd`, `{daily,rift_map,shop}_screen.gd`, `scenes/gameplay/{game_world.tscn,game_world.gd,upgrade_tray.tscn}`, `scenes/tutorial/tutorial_screen.tscn`, `scenes/debug/theme_gallery.gd`; docs: `ui_design_system.md`, GDD §9 UI bullet and §14 #42, ASSETS, PROJECT_CONTEXT §5.1, kit README.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. `test_focus_carousel` passes. `test_menu_screens` still fails to parse on the removed `forms_screen.tscn`; that failure predates this change. The `--preview` texture sheet was checked. There were no render passes (owner rule), and the debug APK was exported.
- **Follow-ups:** owner phone review. Open questions: a pixel font; side studs sit high on taller-than-native pieces (PLAY, HUD upgrade tile, cards, crests); no kit glyph for restart, combo, high score, upgrades, Reaper or the mutations, which are still painted. Kit pieces with no user: `slot_small`, `hud_counter_plate` (same art as `plate_small`), both badge plates, `progress_fill_reward`, `hud_slim_fill_boss`, `portrait_ring_selected`, `ornament_stitches`, `hud_health_socket`, and the back, rift, health, audio, mute and close glyphs. `assets/art/ui/frames/` now has no runtime user. `test_menu_screens` needs updating for the Shop.

## 2026-09-24 — Named Wisp Rush icon source
- **Who:** Codex (GPT-6)
- **Owner request:** add the game name Wisp Rush to the pixel-art icon.
- **Did:** composed the broken-wisp mascot above the exact two-line WISP RUSH title from the Home logo's lettering style. Saved v3 beside v1/v2, with raw draft, 128 px preview, exact edit prompt and reproducible postprocess. The source icon remains separate from game configuration and exports.
- **Files/systems:** `concept_art/wisp_rush_app_icon_pixel_v1/`; `docs/ASSETS.md` registry.
- **Verified:** final icon and 128 px preview visually reviewed; master is 1024×1024 opaque RGB with 59 colors, zero 4×4 pixel-grid mismatches, and a matching nearest-resized preview. Diff and project-map checks pass. The Windows validator remains failed on missing legacy Theme texture paths during a separate UI-kit integration; this source-only icon did not touch them.
- **Follow-ups:** owner review of v3 before any integration task; the separate UI-kit migration must clear its Theme texture errors.

## 2026-09-24 — No wave line in the run HUD
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "remove the text saying Endless WAVE X and threat X".
- **Did:** removed `%WaveLabel` and every line that wrote to it (wave/threat, REAPER APPROACHING,
  BOSS DEFEATED, CYCLE n CLEARED, LEVEL n CLEARED); each of those beats already has a centre callout.
  `_hud_run_prefix()` went with it. The boss line moved up to `HUD_BOSS_TOP` 150, clear of the Rift
  Points / score column. `render_milestone2_showcase.gd` no longer sets the label.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; `game_flow`, `gameplay_slice` and
  `wave_director` pass; header probe at 1080×1920: no overlaps (boss line at y 177, under the score
  column's bottom at 164).

## 2026-09-24 — No Soul Vessel, and the run HUD rearranged
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "remove the shards that give you a revive completely from the game, leave the RP
  counter and under that counter place the score without any frame … on the right with the RP icon on
  the right, pause button on the left and the upgrades button, move the rush bar at the top as well as
  the soul level bar".
- **Did:** the Soul Vessel drop is gone: pickup scene and script, drop chance, callout.
  **Reaper's Gift left the upgrade pool** (ASSUMPTION, GDD §14 #45), because it heals a missing
  fragment and a one-fragment run never has one; its tuning, the kill streak and the data file went
  with it, and `RunProgression` asserts six mutations. **HUD** (`_layout_safe_hud()`): pause and
  UPGRADE top-left; `%StatsColumn` top-right, with Rift Points (count, RP, icon on the right) and the
  unframed `%ScoreLabel` under it; the SOUL LEVEL bar, RUSH row, wave line and boss line stacked at
  the top centre. The lives readout, `ScorePlate` and `get_hud_rect(&"health")` are gone. **Tutorial:**
  the DANGER lesson reads "One touch of the spikes ends a run. Stay clear." with no focus ring, and
  SKIP moved top-left, where the hidden pause sits, because RP and the score now own the top-right.
- **Files/systems:** `scenes/gameplay/game_world.{gd,tscn}`, `scenes/pickups/` (vessel removed),
  `scripts/{components/run_progression,resources/run_progression_tuning,resources/player_tuning,resources/tutorial_lesson_data}.gd`,
  `data/{progression/default_run_progression,tutorial/default_tutorial}.tres`, `data/mutations/reapers_gift.tres`
  (removed), `scenes/tutorial/tutorial_screen.{gd,tscn}`, tests `mutation_effects` and
  `player_health_flow`, docs (GDD §5.3/§5.5/§6/§11/§13/§14 #45, PROJECT_CONTEXT, core_run, mutations,
  player_health, tutorial).
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; `mutation_effects`, `player_health_flow`,
  `run_progression`, `gameplay_slice`, `game_flow`, `m4_systems` and `challenge_tracker` pass. A
  headless layout probe at 1080×1920 (with UPGRADE and the boss line showing) found one overlap: the
  wave line under the score. The wave and boss lines moved down 16 and 20 px, and nothing overlaps.
  No render pass (owner tests on the phone).
- **Follow-ups:** `07_soul_vessel.png` is still generated in the mutation icon set, unused.
  `test_rift_points_text` (already stale) still names the old HUD path.

## 2026-09-24 — Pixel font, no Rifts in the first release, PLAY lower
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "add a pixel font to the game and remove the rifts button that will not be in
  the first release", then "move the play button a little bit lower".
- **Did:** **Font:** Pixelify Sans (OFL, from Google Fonts' official repository) is the theme's
  default. The theme builder makes a crisp `FontFile` (no anti-aliasing, no hinting, whole-pixel
  positions, Open Sans fallback for → and ✓) from the gdignored TTF. Every size, in the theme and in
  the 73 scene and 16 code overrides, is snapped to a multiple of 11 (the font's pixel is ~1/11 em)
  after ×1.06, so its width matches the old font. Titles lose `embolden` and gain one font pixel of
  spacing. Credit added to Privacy & About. **Rifts:** the RIFTS tile and its balance slot are gone
  from Home, with `rift_map_requested`; the story mode stays in the build, unreachable. Its knock-ons:
  REPLAY TUTORIAL is back in Settings (Home-level only) because the Rift Map held the only replay, and
  the four level-clear Trials, which would have locked the ladder at tier 2, are Endless goals again
  (wave 6 and 8, 6 and 9 bosses). **PLAY:** `HomeScreen.ACTION_DROP` (80) lowers the caption and
  PLAY into the free space below, 64 px lower than before, and the hero keeps its size.
  `render_devlog_tour.gd` opens the Rift Map directly.
- **Files/systems:** `assets/fonts/pixelify_sans/`, `assets/ui/theme/{tools/build_wisp_theme.gd,wisp_theme.tres}`,
  scene font overrides, `scenes/screens/{home_screen,settings_screen}.{gd,tscn}`, `scenes/main/main.gd`,
  `data/trials/`, docs (GDD §6/§11/§13/§14 #44, game_flow, tutorial, settings, meta_progression, rifts,
  ui_design_system, PROJECT_CONTEXT, ASSETS).
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. Home probe at 1080×1920: PLAY top 1408 → 1480,
  hero unchanged. Tests `trials`, `game_flow`, `screen_transitions` and `focus_carousel` pass;
  `main_progression_flow`, `screen_setup_order`, `progression_screens`, `dev_unlock` and
  `rift_points_text` fail to parse on stale references (`forms_screen.tscn`, old DevUnlock API), as
  they did before this change. No render pass (owner tests on the phone).
- **Follow-ups:** owner look at the font sizes on the phone, especially captions (26 → 33) and
  anything that might now wrap. Whether the level-clear Trials return with the Rifts.

## 2026-09-24 — More breathing room in the game icon
- **Who:** Codex (GPT-6)
- **Owner request:** move the broken-wisp character back a little in the source-only game icon.
- **Did:** edited the icon composition so the character and cyan flames sit smaller and centered with more dark space around them. Saved v2 beside v1, retained its 40-color palette and included a 128 px preview, raw edit, exact prompt and reproducible postprocess. No game icon setting or runtime art was changed.
- **Files/systems:** `concept_art/wisp_rush_app_icon_pixel_v1/`; `docs/ASSETS.md` registry.
- **Verified:** v2 visually reviewed at full size and 128 px; 1024×1024 RGB, 40 colors, zero 4×4 grid mismatches, and the preview matches nearest reduction. Project map and diff checks pass. The Windows validator currently fails on missing legacy Theme texture paths during a separate UI-kit integration; this source-only icon did not touch those paths.
- **Follow-ups:** owner review of v2 before any integration task; the separate UI-kit migration must clear its Theme texture errors.

## 2026-09-24 — Pixel-art game icon source from the Home logo
- **Who:** Codex (GPT-6)
- **Owner request:** generate a game icon matching the supplied Home-screen logo, without implementing it.
- **Did:** created a square broken-wisp head icon with the stitched ivory hood, X-button eye, amber eye and small cyan flames. Reduced the generated draft to 40 colors on a strict 4 px grid and saved an opaque 1024 px master, a 128 px readability preview, source draft, owner reference and rebuild script. No project icon setting, platform export or runtime branding file was changed.
- **Files/systems:** `concept_art/wisp_rush_app_icon_pixel_v1/`; `docs/ASSETS.md` registry.
- **Verified:** master is 1024×1024 RGB with exactly 40 colors and zero 4×4 grid mismatches; 128 px preview matches nearest reduction and was visually reviewed. Windows Godot 4.7.2 validator reports `VALIDATE: OK`.
- **Follow-ups:** owner review of the icon before a separate integration task.

## 2026-09-24 — New game icon, and a build on the phone mid-UI-rework
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "change the game icon to this" (a pixel-art stitched hood with one ember eye),
  then "install the game on the connected phone".
- **Did:** source kept unchanged at `concept_art/wisp_rush_app_icon_v2/app_icon_source.webp`;
  new `tools/art/make_app_icon.py` writes `assets/art/branding/app_icon/` (512 project icon, 192 legacy
  launcher on white, 432 adaptive foreground and white background, since its transparent gaps read as
  white in the owner's view). `config/icon` and the three `launcher_icons` in `export_presets.cfg`
  point there. Docs: ASSETS, PROJECT_CONTEXT §6.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; debug APK exported, installed and launched on
  the phone: boot → Home. The build caught the background UI-kit integration mid-change: 16 missing
  theme textures at export and ornament load errors on the device, which that session's own final
  build replaces.
- **Follow-ups:** owner look at the launcher icon; a monochrome (themed-icon) layer if wanted.

## 2026-09-24 — The game is pixel art: art direction docs, and Ilyra's AutoSprite brief
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "update project docs that the game is in pixel art not normal art", after asking
  for Ilyra's states and her Codex and AutoSprite prompts ("did you specify … it to be a pixel art?").
- **Did:** ADR-0018 (pixel art everywhere, which supersedes ADR-0005's painterly rendering; the
  palette stays). GDD §9 rewritten around it (characters and arenas bullets brought up to date),
  §14 #43, change history. CLAUDE.md "Current look", AGENTS.md 5b, PROJECT_CONTEXT §1 "Art style",
  the pixel rules in `character_creation.md` §3 and §8 and in `arena_art.md` (270 × 600 ×4 nearest),
  two ROADMAP backlog rows. New brief `concept_art/ilyra_autosprite_v1/PROMPTS.md`: her five
  animations, the four Codex first frames as true pixel art (256 grid ×4, one shared palette, binary
  alpha, one head size) and the four AutoSprite prompts. The UI-kit integration runs in a separate
  background session with its own entry.
- **Verified:** documentation only; project map regenerated.
- **Owner decision, same session:** characters use **2 design px per art pixel** (GDD §14 #43,
  ADR-0018): ~130–140 art pixels tall, head ~33. Ilyra's brief was resized to match.
- **Follow-ups:** the engine's pixel-grid packing, nearest filtering and exact 2× drawing land with
  Ilyra, and Patchvile is re-packed to the same rule.

## 2026-09-24 — Godot MCP on the Windows checkout; Blender removed
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "connect with the godot mcp server and remove the blender mcp server data in the
  project they arent needed the game is 2d pixel art only".
- **Did:** installed the pinned server (`tools/mcp`, `npm ci`) and registered a local-scope `godot`
  server for `D:/Wisp Rush` with Windows node and Godot paths. It overrides `.mcp.json`, which keeps the
  Mac paths, so neither machine breaks the other. Removed the local `blender` server entry and moved to
  the Recycle Bin the untracked Blender material: `concept_art/{ilyra,noxen}_blender_rig_v1/`,
  `concept_art/premium_character_3d_v1/` (the 3D doll model), `tools/art/{build,animate}_blender_rig.py`
  and `logs/blender_rig/`. The 2D turnaround references in `concept_art/premium_character_turnaround_v1/`
  stay. Docs: CLAUDE.md, AGENTS.md §4 (the Windows MCP setup), PROJECT_CONTEXT §3/§6, ASSETS,
  `tools/art/README.md`, `character_sprite_frames.md` (§7b removed).
- **Verified:** drove the server over stdio outside the session: `get_godot_version` 4.7.2,
  `get_project_info`, and `run_project` → `get_debug_output` (boot, Loading, Home) → `stop_project`.
  `tools/validate.sh` → `VALIDATE: OK`.
- **Follow-ups:** the server appears in the next session, not this one. The run printed existing
  `bool()` constructor warnings from `save_manager.gd:146` and nearby lines.

## 2026-09-24 — Wisp Bearer Endless arena source
- **Who:** Codex (GPT-6)
- **Owner request:** make an Endless arena image to the 1080x2400 contract, with the floor and rim at the specified coordinates, and leave it unwired.
- **Did:** generated a sparse dark-fantasy Wisp Bearer backplate, fitted it with the project mask to a 730x1088 plain floor and 40 px clear rim, kept sky/ground bleed, wrote `arena.json`, and ran `make_arena.py` for the background and thumbnail. The catalog and game scenes are unchanged.
- **Files/systems:** `concept_art/arenas_v2/wisp_bearer/`, `assets/art/environment/arenas/wisp_bearer.png`, its thumbnail, `docs/ASSETS.md`, `docs/systems/endless_mode.md`.
- **Verified:** source and runtime image are identical opaque 1080x2400 RGB; floor [174, 659, 904, 1747] has 30.4-37.4% brightness and its 150 px edge band matches the centre. `make_arena.py` built a 324x720 thumbnail; `tools/validate.sh` printed `VALIDATE: OK`; `test_endless_catalog` passed. Full suite: 31 passed, 10 failed in existing tests for removed APIs/screens (including two timeouts).
- **Follow-ups:** owner visual review before any catalog wiring; existing test suite failures remain outside this art task.

## 2026-09-24 — Pixel-art menu and HUD component handoff
- **Who:** Codex (GPT-6)
- **Owner request:** generate only pixel-art UI components for menus and gameplay HUD, recolored to the dark-stone and warm-detail Home redesign; Claude will integrate them.
- **Did:** drew 74 separate transparent, text-free PNG components on a strict 4 px grid, including buttons, panels, Home tiles, character rings, tabs, meters, HUD health/counters and icon glyphs. Added a manifest with native sizes, nine-slice margins and content insets, plus four labeled review sheets and a reproducible Pillow builder. The runtime Theme and scenes were not changed.
- **Files/systems:** `concept_art/wisp_rush_pixel_ui_v1/`, GDD §9/§14, `docs/ASSETS.md`, `docs/systems/ui_design_system.md`. Corrected the prior Home decision number to #41 to avoid the existing Patchvile #40 collision.
- **Verified:** all 74 files match the manifest, use uniform 4×4 pixel blocks, have zero RGB under full transparency, and use no more than 32 RGBA colors each; review sheets inspected. Windows Godot 4.7.2 validator reports `VALIDATE: OK`; generated project map check passes.
- **Follow-ups:** Claude to map the source kit into the runtime Theme and screens, then check phone readability and touch targets.

## 2026-09-23 — Pixel-art Home stage, broken-wisp logo and anchored character idle
- **Who:** Codex (GPT-6)
- **Owner request:** redesign the logo and Home art around the broken wisp, keep the game in pixel art, reserve a central resting place for every character, and remove the added code-driven character wobble while keeping authored sprite motion.
- **Did:** generated and reduced to a 4 px grid and 64-color palette a dark-stone Home plate with warm stitched details, amber braziers and an empty central dais, plus a two-line Wisp Rush wordmark with a small broken-wisp icon. Wired both through the generated-art slice spec, aligned the Home preview and ambience, enlarged the logo, removed Home's added float/breath/sway and shared `idle_hover`/`aim_charge` whole-body wobble. Authored storefront sprites, menu videos and non-idle gameplay reactions remain.
- **Files/systems:** `concept_art/wisp_rush_home_pixel_v1/`, `tools/art/redesign_v1_slices.json`, `assets/art/{branding,environment}/`, `scenes/screens/{home_screen.gd,home_screen.tscn,home_ambience.gd}`, `scenes/player/visuals/playable_character_visual.gd`, GDD §11/§14, `docs/systems/{game_flow,playable_character_visuals}.md`, `docs/ASSETS.md`.
- **Verified:** Windows Godot 4.7.2 equivalent of `tools/validate.sh` reports `VALIDATE: OK`; `test_playable_character_visual`, `test_verdant_shade_visual` and `test_ilyra_visual` pass. Captured Home with Patchvile and Void, and Shop with Patchvile, at portrait size. Fixed `qa_capture.gd` Home mode to build Home directly, then checked the real viewport at all five supported phone sizes; the full logo, top bar and unobstructed buttons remain visible and both heroes stay over the dais. `test_menu_screens` is a pre-existing stale test that fails to parse because it references removed `forms_screen.tscn` and an old `setup()` signature.
- **Follow-ups:** review the Home art and logo on a phone and tune the final scale/placement if desired. The legacy menu-screen test needs a separate update to the current Shop routing.

## 2026-09-23 — Patchvile master redo from owner art
- **Who:** Codex (GPT-6)
- **Owner request:** redo Patchvile under the whole-frame contract, one generated image per frame, with owner approval gates after the master and six key poses.
- **Did:** rejected the earlier grid-generated draft; copied the owner character and dagger images unchanged; hard-keyed the character and dagger, placed the dagger once, fixed one hip landmark and source scale per canvas, and exported 512 and 724 px pixel-grid masters. No pose or in-between generation, sprite sheet, or Godot integration.
- **Files:** concept_art/patchvile_sprite_v1/, concept_art/patchvile_full_frames_v1/README.md, docs/ASSETS.md, docs/DEVLOG.md.
- **Verified:** both masters have 32 source-derived colors, a fixed nearest-neighbor 2x grid, binary alpha, zero RGB under alpha 0, and visible heights of 88.3%/87.8%; recorded hips are (256,290)/(362,410). Visual review complete.
- **Follow-ups:** owner approval or corrections of both masters before any key-pose generation.
## 2026-09-24 — How every character is made: the character creation guide
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "now document how every character is created" (the states, shaders and effects).
- **Did:** `docs/guides/character_creation.md` — the AutoSprite recipe with Patchvile as the worked
  example: the five animations and which states each carries, the four sheets to generate (settings,
  first/last-frame rules, prompt rules and skeleton), the source pack and slicer, the packer entry
  (derive, cells, fit/fit_match, particles), the scene, data and registration steps, every effect and
  where it is set, sizes/speeds/orientation, the checks. AGENTS.md read order points new-character
  work there first; `character_sprite_frames.md` is marked as the older Codex contract and its dash
  direction corrected (the rig's up is forward, it said +Y).
- **Follow-ups:** check Void, Eclipse and Verdant Shade's dash frames, drawn to the old +Y wording,
  in a run; pack menu sheets at 256 px for AutoSprite characters.

## 2026-09-24 — Patchvile 5% smaller in runs
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "make the character in game 5% smaller".
- **Did:** `WholeFrameCharacterVisual.menu_art_scale` (0 = same as `art_scale`) so a run and the menus
  can differ; Patchvile runs at `art_scale` 1.1875 (was 1.25) and keeps 1.25 on Home and the Shop.
- **Verified:** `tools/validate.sh` OK; installed on the owner's phone. No test pass (owner tests).

## 2026-09-24 — Landing effects per character: Patchvile lands in dust
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "when the character lands on the walls there is a blue splash change it to dust
  like splash and each character will have its own effects".
- **Did:** `DashEffectData.landing` (`SPLASH`, the default, or `DUST`) and `dust_tint` (checked against
  the reserved hues). `WallSplashFx` plays the same splash in dust (owner: "like the blue one … but
  dust particles"): grains fanned off the wall with the droplets' count, speed, spread and damping, a
  dust splat flattening along the wall and a lighter puff at the contact — normal blend, soft
  procedural dots, none of the cyan splat and flash art; `WispPlayer.set_impact_burst_enabled()` hides its cyan impact burst for
  such a character. Patchvile: `DUST`, dusty beige.
- **Verified:** `tools/validate.sh` OK; installed on the owner's phone (boot with no errors). No test
  or render pass — the owner tests on the device (his request).
- **Follow-ups:** owner feedback on the dust; other characters' own landings when he asks.

## 2026-09-24 — Patchvile's wall-free attack, his own slash and particles, no blue
- **Who:** Claude Code (Opus 5.5)
- **Owner requests:** the new AutoSprite attack sheet (from the flight pose, no wall); then "the blue
  dash effect remove it and create a shader and effect just for this character … like Ilyra … when
  she attacks"; then "launch it on my phone".
- **Did:** the attack: eight cells — flight pose, windup (06–08), the slash with its painted flash
  (09, contact frame 4), arc, streaks, first held follow-through — at 28 fps (~0.29 s), one row of 336 px
  cells; the first sheet kept as `raw/dash_attack_sheet_v1.png`. **No blue:** the cyan came from the
  shared dash art itself (the launch streak, the long streak and the momentum glow are painted cyan, so
  a tint cannot fix them); `DashEffectData.shared_trails` turns all three off, Patchvile false.
  **His own effects:** `character_slash.gdshader` draws a bone-white crescent sweeping across the front
  of the flight on the contact frame; `%DashParticles` throws costume scraps (a strip packed from
  Codex's ornaments) and `%TrailParticles` leaves cream motes, like Ilyra's fan arcs and sparkles.
- **Verified:** `tools/validate.sh` OK; `test_patchvile_visual`, `test_playable_character_visual`
  (after moving the slash to a fixed transform — the smoothness probe samples every body node),
  `test_dash_effects` pass; rendered a slowed dash: slash, scraps, motes, afterimages, no blue;
  debug APK installed on the owner's phone, boot and Home with no errors.
- **Follow-ups:** the painted slash flash in cell 09 is golden, near the reserved amber — watch it on
  the device; the arc in cell 10 is cut by its 256 px source cell for one frame.

## 2026-09-24 — Patchvile's AutoSprite dash attack packed; a wall-free attack requested
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "here is the sprite sheet implement it now" (AutoSprite, 25 cells), then, seeing
  it: the launch from the floor does not read — generate just the attack instead.
- **Did:** the AutoSprite pack's slicer picks cells and turns them: seven dash cells (wall pose, dagger
  rising, the slash at cell 06, the lunge, a held lunge), a quarter clockwise so the lunge flies up
  the frame (the rig turns a dash frame by the flight angle + 90 degrees). The packer gains
  `fit_match` — a sheet takes another sheet's pixel scale — so the dash gets its own 336 px sheet
  (its lunge is 256 px wide, ~321 at the walls' 1.253×) and he stays one size. `dash_head_up`
  mirrors a side-drawn dash on rightward flights so he is never upside down; a mirror change no
  longer restarts the animation. The gameplay fixture takes `WISP_DASH="x,y"`. Contact frame 4, 28 fps.
- **Found:** the sheet spends cells 0–5 in the right-wall pose with only the arm rising, swings in one
  jump (5→6) and holds the lunge for 18 cells, so from the floor the launch shows a sideways wall
  pose. Owner decision: generate a wall-free attack from a flight pose —
  `concept_art/patchvile_autosprite_v1/dash_attack_first_frame.png` (cell 16, padded to 80 %).
- **Verified:** `tools/validate.sh` OK; `test_patchvile_visual`, `test_playable_character_visual`
  pass; the other whole-frame characters re-pack byte-identical; renders up-left / up-right / left /
  right: upright in all four.
- **Follow-ups:** repick the slicer's dash cells and contact frame when the new attack arrives.

## 2026-09-23 — Patchvile's dash as one attack, with an attack look
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "for the dash anim i want it to not have a loop like one single dash attack
  then the wall state appears and that attack shall be visible shall also have shaders".
- **Did:** a whole-frame dash can now be a one-shot (`"loop": false` in the pack manifest): it
  starts on the launch (`DASH_START`), holds its last frame until the landing hands over to the wall
  animation, and restarts on a mid-dash redirect through the new `PlayableCharacterVisual.restart_dash()`
  (`WispPlayer.redirect_dash` calls it; the controller's dash state never changes on a redirect).
  The attack look, opt-in per character through `attack_glow`: `character_attack.gdshader` draws a
  glowing outline while dashing and a flash toward the glow on the contact frame and on a kill
  (capped at 0.75 so the character stays readable), plus additive afterimages from an 8-sprite pool
  behind the body, pinned in world space. Menus and Reduced Motion get no flash or afterimages.
  Patchvile: cream glow (amber is reserved for telegraphs), contact frame 2, his placeholder
  4-frame dash as a one-shot at 16 fps (~0.25 s — a short dash is ~0.2 s).
- **Files:** `scenes/player/visuals/{whole_frame_character_visual.gd,playable_character_visual.gd,patchvile_visual.tscn}`,
  `scenes/player/wisp_player.gd`, `assets/shaders/character_attack.gdshader`,
  `concept_art/patchvile_autosprite_v1/patchvile_sprite_sheet.json`, `data/characters/patchvile_gameplay.tres`,
  `tools/godot/test_patchvile_visual.gd` (new), docs (playable_character_visuals, character_sprite_frames §3,
  GDD §14 #40, ASSETS, PROJECT_CONTEXT).
- **Verified:** `tools/validate.sh` OK; `test_patchvile_visual` (new), `test_playable_character_visual`,
  `test_{verdant_shade,void,eclipse}_visual` pass — their dashes still loop; rendered a slowed dash:
  outline, afterimage trail and the contact flash show, and the held last frame trails into the landing.
- **Follow-ups:** his AutoSprite dash attack (8 frames, one-shot, launch → slash → follow-through;
  prompts given to the owner) replaces the placeholder; set its fps so it lasts ~0.25 s and its
  `attack_contact_frame` to the slash frame. Device check of the look on the phone.

## 2026-09-23 — Playable-area rules for generated arenas
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "give me specs for the playable area so codex doesnt generate something that
  can [not] fit in the playable area".
- **Did:** `docs/guides/arena_art.md` §2b — the floor's exact rectangle (±6 px), a straight-on
  axis-aligned rectangle, a 40 px rim, nothing over floor or rim, an even 30–40 % brightness (measured
  on the Quarry Titan: 35 %), no props or bright details, the 150 px edge band as plain as the centre,
  the frame inside the safe zone. `make_arena.py --guide` now also writes
  `concept_art/arenas_v2/_layout/arena_spec.json` and `arena_floor_mask.png`; AGENTS.md read order 5d
  points agents at the guide.
- **Verified:** the Quarry Titan's measured floor maps onto the spec floor to the pixel
  (174, 659, 904, 1747).
- **Follow-ups:** a checker that measures a generated arena against the spec (floor edges, evenness,
  rim contrast) before it is imported.

## 2026-09-23 — Endless arenas: thirty skins out, one painted arena, a pager and a size contract
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "remove all of the existing arenas and create a pager like the character one for
  picking arenas … add just this arena … define the size of everything … it must be fixed in every
  phone size and shall look good, it shall not be cropped"; asked, Shop arenas only (Rifts keep
  theirs), and neither blur nor colour around the image.
- **Did:** removed the thirty Endless skins (data and 69 MB of art); added the owner's mining-mech
  arena as `quarry_titan`, the free default (`concept_art/arenas_v2/quarry_titan/`, new
  `tools/art/make_arena.py`). The floor moved into the catalog as `floor_rect` + `floor_polygon`,
  measured on the painted stone (x 152–788, y 365–1313 of 941×1672); `ArenaRules.get_floor_rect_uv()`
  lets an arena lay the playfield out while the Rifts keep `ARENA_FLOOR_UV`. The Shop's ARENAS tab is
  the CHARACTERS card pager again (gallery, peek and `handle_back` removed), each arena whole. Save
  ids, tutorial arena and fixtures moved to it. **The size contract** (ADR-0017,
  `docs/guides/arena_art.md`, a layout guide image): 1080×2400 canvas, 1080×1920 safe zone, 240 px of
  sky/ground bleed, 60 px side margin, shared floor x 174–904 y 659–1747 — cover-scaled, it lands 1:1
  on every phone from 16:9 to 20:9 with no bars, blur, stretch or lost content.
- **Files:** `data/endless/`, `assets/art/environment/arenas/`, `concept_art/arenas_v2/`,
  `scripts/resources/{endless_catalog,arena_skin_data,tutorial_catalog}.gd`,
  `scenes/gameplay/{arena_rules,endless_arena_rules,game_world}.gd`,
  `scenes/screens/shop_screen.{gd,tscn}`, `scripts/autoload/save_manager.gd`,
  `tools/art/make_arena.py`, `tools/godot/{test_endless_catalog,render_arena_tab,qa_capture,…}.gd`,
  docs (ADR-0017, arena_art guide, endless_mode, shop, GDD §6/§14 #39, PROJECT_CONTEXT, ASSETS).
- **Verified:** `tools/validate.sh` OK (after another agent's in-progress Home edit settled);
  `test_endless_catalog` (rewritten), `test_form_catalog`, `test_dash_effects`,
  `test_playable_character_visual` pass; full suite 30 passed, 10 failed — the same ten
  tests that have been out of date since M10, none of them about arenas. Rendered the ARENAS pager and a run on
  16:9 and 19.5:9: the walls sit on the painted floor.
- **Follow-ups:** the Quarry Titan came as 941×1672 without bleed, so on phones taller than 16:9 its
  sides are trimmed until it is re-delivered at 1080×2400 (guide §4). Retired tools and scenery
  fixtures still target the removed skins; the animated-scenery code has no user. Another agent was
  editing Home, the logo and the menu backgrounds at the same time — not part of this change.

## 2026-09-23 — Patchvile drawn 25% bigger
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "make the character bigger".
- **Did:** `WholeFrameCharacterVisual.art_scale` (default 1): draws a whole-frame character's frames
  larger than their cell, in a run and on Home and the Shop alike. Patchvile's scene sets 1.25, so he
  is now larger than the other characters. Cosmetic only — his hitbox is unchanged, so his drawing
  reaches further past it than anyone else's (ADR-0006 sets the drawing-to-hitbox ratio for the
  roster). `test_playable_character_visual` now checks the silhouette against `design_size × art_scale`.
- **Files:** `scenes/player/visuals/{whole_frame_character_visual.gd,patchvile_visual.tscn}`,
  `tools/godot/test_playable_character_visual.gd`, `docs/systems/playable_character_visuals.md`.
- **Verified:** `tools/validate.sh` OK; `test_playable_character_visual` 2/2 and
  `test_verdant_shade_visual` pass; Home, Shop card and a run rendered — he fits between the Home
  side columns and inside the Shop card.
- **Follow-ups:** tune `art_scale` on the phone; if every new character should be this size, the
  answer is the drawing-to-hitbox ratio for everyone, not per-character scales.

## 2026-09-23 — Patchvile's walls from AutoSprite: floor and right wall, the rest flipped
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** wall prompts, the ceiling "flipped, head down, same as the bottom", then "create
  one side like top and right and you invert to other two sides?" — delivered the floor and the
  right wall.
- **Did:** the AutoSprite pack gains the two exports; `slice_sheet.py` keeps 24 cells per wall (the
  25th repeats the first) and writes the portrait from the storefront. The packer gains
  `state_folders` (the dash still comes from Codex's pack) and `derive` (`wall_top` = the floor
  flipped vertically; `wall_left` = the right wall mirrored, so the right wall shows AutoSprite's
  art as generated). Walls play all 24 frames at 12 fps, ≈2 s. `fit` now scales each delivered frame
  size separately. **Owner decision:** on the ceiling Patchvile hangs head down, against the guide's
  upright-on-every-wall rule (§5) — the art is drawn that way and the game shows it as drawn.
- **Found:** packed at the usual 384 px cell the 76 frames made a 3200×4000 sheet that loaded in
  85 ms (others ~42 ms); the stall let the spawn squash advance two physics steps in one rendered
  frame and `test_playable_character_visual` failed 1 in 2 ("MotionRoot scale jumped 0.31").
  AutoSprite's frames are 256 px, so the run cell is now 256 (2176×2720) and his `design_size` 256;
  `WholeFrameCharacterVisual.MENU_SCALE` (384/448) became `design_size / MENU_CELL`, the same value
  for every existing character.
- **Files:** `concept_art/patchvile_autosprite_v1/`, `tools/art/extract_playable_characters.py`,
  `scenes/player/visuals/{whole_frame_character_visual.gd,patchvile_visual.tscn}`,
  `assets/art/characters/playable/patchvile/`, `data/characters/patchvile_*.tres`, docs.
- **Verified:** `tools/validate.sh` OK; `test_playable_character_visual` 3/3 passes, and
  `test_{form_catalog,verdant_shade_visual,void_visual,eclipse_visual}` pass; the other whole-frame
  characters re-pack byte-identical; the six-cell board shows every animation, his run size matches
  Verdant Shade's and the Shop card is unchanged in size.
- **Follow-ups:** the floor has the dagger in his left hand, the storefront in his right; the dash
  is still the Codex chibi; frames are 256 px, so the Shop card is soft — re-export larger (free).
  The guide should record the head-down ceiling if it becomes the rule for new characters.

## 2026-09-23 — Patchvile's storefront from AutoSprite
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** try AutoSprite for sprite sheets (prompts written for every state), then
  "here is the sprite sheet for the store front implement it in godot", then "install it on the
  connected phone".
- **Did:** new source pack `concept_art/patchvile_autosprite_v1/` — the export unchanged, a slicer
  and a manifest listing the rows of both Patchvile packs. Home and the Shop card now play
  AutoSprite's 25-frame loop (front view, breathing, a dagger flip and catch) at 12 fps, ≈2.1 s
  (owner; 6 fps was the contract's storefront rate); the
  run frames are still Codex's. His menu sheet is a 5 × 5 square (2320², ~21.5 MB when live against
  ~10 MB for the others). The packer's `menu_source` may now be an absolute path to another pack.
- **Files:** `concept_art/patchvile_autosprite_v1/`, `tools/art/extract_playable_characters.py`,
  `assets/art/characters/playable/patchvile/patchvile_menu.png`, `data/characters/patchvile_{menu,frames}.tres`,
  docs (ASSETS, playable_character_visuals, DEVLOG).
- **Verified:** the export is registered — feet on the same row in all 25 cells, body within 0.5 px;
  `tools/validate.sh` OK; `test_form_catalog` and `test_playable_character_visual` pass; Shop card
  and Home rendered mid-toss; debug APK installed on the owner's Galaxy S24 and launched — boot,
  Home and Shop with no errors in the device log.
- **Follow-ups:** the export is 256 px per frame, so the card upscales it ~1.85× and it is soft —
  re-export from AutoSprite at a larger frame size (free) and re-run `slice_sheet.py` (update its
  `CELL`) and the packer. Frame 09 clips the dagger tip. The portrait and the run are still the Codex
  chibi, so the Shop shows two looks until the wall and dash states are made in AutoSprite. AutoSprite
  as a pipeline wants an ADR once the owner commits to it.

## 2026-09-23 — Patchvile plugged into the game for review, scaled up
- **Who:** Claude Code (Opus 5.5)
- **Owner request:** "plug in the latest artwork from gpt so i can see how it look like in the
  game", then "yes plug him in and scale him up".
- **Did:** Patchvile (Codex's `concept_art/patchvile_full_frames_v1/`, 48 frames) is the ninth
  character: `patchvile_visual.tscn` on `WholeFrameCharacterVisual`, `data/forms/patchvile.tres`
  (price 0, STANDARD), a pale BLADE_ARC dash effect (his colours sit on the reserved amber, so the
  tints are desaturated), catalog, save id and `REQUIRED_FORM_COUNT` 9. The packer gains a `fit`
  option: one scale per sheet from the largest animation's combined bounds, each animation centred,
  resampled once and premultiplied; it refuses a fit that reaches the cell edge. Patchvile uses 0.92
  (run ×1.249, menu ×1.382) — the frames filled ~65% of their canvas, the shipped characters 85–94%.
- **Not done on purpose:** the pack's own `wall_right` row is not packed (the visual mirrors
  `wall_left` for everyone, so his ember eye swaps sides on the right wall); his eight ornaments are
  not used; no menu video.
- **Files:** `tools/art/extract_playable_characters.py`, `assets/art/characters/playable/patchvile/`,
  `data/characters/patchvile_{gameplay,menu,frames}.tres`, `data/characters/dash_effects/patchvile.tres`,
  `data/forms/{patchvile,default_catalog}.tres`, `scenes/player/visuals/patchvile_visual.*`,
  `scripts/{autoload/save_manager,resources/form_catalog}.gd`, `tools/godot/test_{form_catalog,playable_character_visual}.gd`,
  docs (ASSETS, PROJECT_CONTEXT, forms, playable_character_visuals).
- **Verified:** `tools/validate.sh` OK (Windows, Godot 4.7.2); `test_form_catalog`,
  `test_dash_effects` and `test_playable_character_visual` (now covering him) pass; full suite:
  30 passed, 10 failed — the ten stale since M10 (removed `forms_screen`, renamed run/unlock
  APIs), none touching characters. Debug APK built on Windows and installed on the owner's
  Galaxy S24; the device log shows boot, Home, Shop and a run with no errors. Rendered Home, the Shop card, the six-cell whole-frame board and a run next to
  Verdant Shade: every animation reached, and his run size now matches hers. Godot MCP is not
  connected on this checkout, so there was no live MCP run.
- **Follow-ups:** the art is not approved — the design drifted from the reference (chibi, leaf
  mantle) and the side-wall poses leap rather than cling. Codex has started the redo in
  `concept_art/patchvile_sprite_v1/` (master only, awaiting the owner); the master's pasted dagger
  merges into the coat. If he stays, a proper `wall_right` needs runtime support and GDD §14 needs
  the roster change.

## 2026-09-23 — Patchvile four-frame idle study with agent-sprite-forge
- **Who:** Codex (GPT-6)
- **Owner request:** install the linked sprite skill, learn its sheet workflow and animate an idle for the supplied Patchvile character and curved dagger.
- **Did:** installed generate2dsprite from 0x0funky/agent-sprite-forge; generated a 2x2 idle sheet preserving the hood, stitched face, glowing eye, scarf, patchwork outfit and low-held knife; used the skill processor for transparent 512 px frames, sheet, GIF and QC metadata. Preserved the exact prompt and unchanged references; zeroed invisible RGB after export. Source art only, with no Godot integration.
- **Files:** concept_art/patchvile_idle_v1/, docs/ASSETS.md, docs/DEVLOG.md.
- **Verified:** visually reviewed raw and processed sheets; four distinct frames, no empty or clipped frames or paste clamps; body-scale variation 0.018 and vertical-anchor variation 0.011 pass the skill strict thresholds. Frame 4 to 1 mean difference 0.020. `tools/validate.sh` returned `VALIDATE: OK`; the full suite returned 30 passed, 10 failed, matching the existing stale-test baseline. All character visual tests passed.
- **Follow-ups:** owner reviews the loop. A production storefront animation needs 12 registered frames and the remaining character animations in the project contract before Patchvile could join the game.

## 2026-09-22 — Empty-hand A-pose turnaround and separate dagger reference
- **Who:** Codex (GPT-5)
- **Owner request:** prepare the patchwork character in A-pose with empty hands and put the weapon
  alone in another image for Claude Code and Blender.
- **Did:** generated a second four-view modeling sheet with aligned front, left, right and back
  A-poses, open unobstructed gloved hands and no dagger. Generated the curved dagger separately as
  consistent Side A, edge and Side B technical views. Saved the exact ImageGen prompts beside the
  references. No runtime or Blender model files changed.
- **Files:** `concept_art/premium_character_turnaround_v1/hooded_doll_apose_turnaround_v1.png`,
  `hooded_doll_dagger_reference_v1.png`, `APOSE_WEAPON_PROMPTS.md`, `README.md`.
- **Verified:** visually inspected both original-resolution outputs: all four character views are
  complete and weapon-free with visible empty hands; the weapon sheet contains only three aligned
  dagger views with no character parts or cropping.
- **Follow-ups:** split the four character views into separate label-free PNG files before loading
  them as Blender camera references; the combined sheet remains the review master.

## 2026-09-22 — Premium hooded character four-view modeling turnaround
- **Who:** Codex (GPT-5)
- **Owner request:** create front, left, right and back views of the supplied character so Claude
  Code can use them to build a 3D model.
- **Did:** generated one aligned, orthographic-style four-view sheet from the owner-supplied front
  illustration. The sheet keeps the hood, stitched mask and eyes, feather mantle, scarf, belts,
  lantern, dagger, patchwork coat, trousers, wraps and boots visible at a common scale, and infers a
  conservative rear construction. Added handoff notes that keep the original front image as the
  identity authority and flag the generated back as unapproved concept detail. No runtime art or
  Godot files changed.
- **Files:** `concept_art/premium_character_turnaround_v1/` (`hooded_doll_turnaround_v1.png`,
  `reference_original.jpg`, `README.md`).
- **Verified:** visually inspected the generated sheet at original resolution: four complete
  figures, shared head height and foot baseline, correct labels, readable profiles, no cropping or
  extra limbs. The original source remains beside the generated sheet for discrepancy resolution.
- **Follow-ups:** approve or correct the inferred rear seam, harness, scarf-tail and pouch layout
  before treating it as canonical; use the original reference for fine surface detail while
  modeling.

## 2026-09-22 — Premium hooded character 3D authoring model v1
- **Who:** Codex (GPT-5)
- **Owner request:** use the installed Blender MCP to create a 3D model from the supplied character
  illustration, without implementing it in the game.
- **Did:** started Blender MCP 0.1.6 in Blender 5.2.2 and built a reproducible, poseable 3D
  authoring maquette from the front reference: separate patchwork hood and mask details, button and
  amber flame eyes, layered feather mantle, scarf, wrapped limbs, curved dagger, belts, pouches,
  lantern, coat panels, ribbons, trousers and boots. Added 14 materials, presentation lighting and
  cameras, and an 18-bone humanoid armature; character pieces are separated and bone-parented so a
  later animation pass can add secondary-motion controls. Saved native Blender, GLB and FBX files
  plus front and three-quarter review renders. No Godot scenes, resources or runtime code changed.
- **Files:** `concept_art/premium_character_3d_v1/` (`build_model.py`, Blender/GLB/FBX model,
  renders, source reference and `README.md`).
- **Verified:** the `.blend` reopens in Blender 5.2.2 with 148 scene objects, 119 meshes, 14
  materials and an 18-bone armature. Clean Blender sessions imported the GLB and FBX successfully;
  both retained all 18 bones. Front and three-quarter EEVEE renders were visually inspected.
- **Follow-ups:** this is a geometric authoring maquette, not the final high-frequency sculpt or a
  game-ready sprite replacement. The unseen back is inferred from one front illustration and needs
  owner approval; a production pass still needs sculpted seams/wrinkles, texture painting, feather
  and cloth controls, and authored wall-cling poses before rendering whole-frame sprite sheets.

## 2026-09-22 — Noxen's storefront idle, animated in Blender, and its sprite sheet
- **Who:** Claude Code (Opus 5)
- **Owner request:** "okay pick one state and animate it in blender and create a sprite sheet of
  that animation".
- **Picked:** Noxen's `storefront_idle` — the one menu animation (guide §3/§4), 12 frames at 6 fps,
  upright on the 724 px canvas. It suits a cut-out rig best: all its motion is secondary (flames,
  root flames, cloak), and Noxen has no menu performance yet. The dash and wall loops would need new
  poses designed first.
- **Did:** `tools/art/animate_blender_rig.py` (new). It starts Blender headless on the rig, keys the
  animation from a table of periodic channels (so the loop closes exactly), names the Actions and
  makes every curve cycle, adds a square menu camera, renders every 4th frame of the 48-frame
  24 fps loop as a sprite frame, and saves the .blend; then, in plain Python, it zeroes RGB under
  alpha, measures the frames and packs them with the packer's own gutter into the menu-sheet
  layout. The motion: one breath — hood rise and lagging tilt, mask counter-tilt, core swell and
  glow, fin flare, flap and tail follow-through — with the flame horns flickering twice a loop and
  the root flames swaying, waves running along each chain. No root motion: the engine adds the
  bounce and squash.
- **Files:** `tools/art/animate_blender_rig.py`, `tools/art/README.md`,
  `concept_art/noxen_blender_rig_v1/{noxen_rig.blend,README.md}`, `.../frames/noxen/storefront/storefront_idle_00..11.png`,
  `.../sheets/noxen_storefront_idle_sheet.{png,json}`, `docs/{ASSETS,PROJECT_CONTEXT}.md`,
  `docs/guides/character_sprite_frames.md` (§7b).
- **Verified:** sheet 2784 × 928 (two rows of six 448 px cells, 8 px gutter — the game's menu
  sheet); neighbour difference mean 0.085, max 0.096 (Eclipse's shipped idle 0.107); the step from
  the last frame back to the first 0.089, like any other; 12/12 frames distinct; at least 17 px of
  canvas margin; body and anchor still in every frame (onion skin). The saved file holds the Action
  (26 curves, all cycling) and the glow Action, frames 1–48 at 24 fps.
- **Follow-ups:** the game does not use these frames — Noxen is still a bone rig, and a whole-frame
  Noxen needs the dash and three wall loops before the packer can take him. A tall character fills
  only a third of a square cell; worth deciding whether his menu frames should crop.

## 2026-09-22 — Noxen as a 2D cut-out rig in Blender
- **Who:** Claude Code (Opus 5)
- **Owner request:** "okay now try and do this with another character from the game that has parts
  like this in the game files, dont delete this character".
- **Which character:** Noxen is the only other shipped character with a complete part pack — parts
  **and** a pivot manifest (`concept_art/noxen_v1/parts/noxen/`, identical to the runtime copy).
  Veyra, Rook and Morrow have loose parts laid out by hand in their scenes, with no manifest.
- **Found:** the manifest's rest positions are round-number guesses from `extract_parts.py`, never
  set against his approved assembly. Built as they stand — which is how the game draws him — the
  flame horns float above the hood, the cloak fins jut out like wings, the two root flames cross
  into an X and the hood is smaller than approved (silhouette IoU 0.51 against the assembly). The
  manifest's 900 × 1180 canvas also cuts off his flame horns and root flames.
- **Did:** `tools/art/build_blender_rig.py` gains a `noxen` pack, and the builder generalises for it:
  per-pack bone groups (first match wins), ribbons for any prefixed part with a measured `tips`
  line (flame horns, root flames, front flap, shadow tail), a per-pack camera `frame` (and an ortho
  scale spanning the longer side of a non-square frame), and `layout` corrections as named keys —
  `at`, `deg`, `scale` (one number or [across, down]) and `flip`. Ilyra's entries moved to the
  named form. Noxen's layout was fitted to the approved assembly, drawn at 1.08 px per assembly px
  (measured on the mask) and registered on the chest core: each part's position, angle and scale
  minimise the per-pixel difference, with the fins and flame horns mirror images and the centre
  column centred; an unconstrained fit had slid the rear cloak off centre and squashed a root flame.
  The flame horns stay at full size, and each root flame is flipped because each painting curls the
  other way from its side. Built headless into its own file; Ilyra's file and her open Blender
  window were not touched.
- **Files:** `tools/art/build_blender_rig.py`, `concept_art/noxen_blender_rig_v1/{noxen_rig.blend,README.md}`,
  `docs/{ASSETS,PROJECT_CONTEXT}.md`, `docs/guides/character_sprite_frames.md` (§7b), `CLAUDE.md`.
- **Verified:** rest render against the approved assembly — IoU 0.78, mean colour difference 36/255
  (from 0.51 and 55/255); a pose test bent both flame horns, both root flames, the flap and the tail
  and turned the fins and hood without a seam; the saved file holds 26 bones in four collections,
  six skinned parts, three hidden effects, every image packed. Ilyra rebuilt from the changed
  builder renders identically to before (max pixel difference 0).
- **Follow-ups:** the in-game Noxen (`noxen_visual.tscn`, from the same manifest) still has the
  floating flame horns, wing-like fins and crossed root flames — carrying this layout into the
  manifest would fix the game too, but moves every part his rig script animates, so it needs its own
  pass and the owner's go-ahead. The approved assembly has a third, central root flame the pack lacks.

## 2026-09-21 — Ilyra's Blender rig posed like her concept
- **Who:** Claude Code (Opus 5)
- **Owner request:** "the parts are not placed correctly see an image from her and move the parts
  like that review your work".
- **Found:** the rig reproduced the pack's assembly sheet exactly, and that sheet is a rigging layout,
  not her: arms straight out with the fans upright, braids hanging behind the body, the skirt hung
  across 363 px for 120 px hips, panels 1–3 under the torso and 4–6 over it (a thigh showing on one
  side only), the sashes buried under everything.
- **Did:** `tools/art/build_blender_rig.py` gains per-pack corrections — `draw_order` (skirt over the
  torso, centre panels in front, sashes between panels, fists over the fan handles) and `layout`
  (skirt panels and sashes hung from the hip line and fanned out, braids from the nape) — and a
  default `pose` the file opens in: her concept's front view, with the joint angles measured on
  `references/ilyra_concept.png` and set over five render passes side by side with it. Clearing the
  pose returns to the manifest's rigging layout. Rebuilt live and saved.
- **Files:** `tools/art/build_blender_rig.py`, `concept_art/ilyra_blender_rig_v1/{ilyra_rig.blend,README.md}`.
- **Verified:** the live build and a headless build render the default pose identically (max pixel
  difference 0); the cleared pose renders the rigging layout with the corrected skirt.
- **Follow-ups:** the pack's legs are shorter than the concept's, so the skirt still covers them to
  the boots; lengthening them would mean stretching the art.

## 2026-09-21 — Ilyra as a 2D cut-out rig in Blender
- **Who:** Claude Code (Opus 5)
- **Owner request:** connect to Blender (`claude mcp add --transport http blender http://127.0.0.1:9876`),
  then "create the ilyra 2d character rig in blender"; on the art, "if you don't have full pack parts
  go with the one you have full pack parts".
- **Blender connection:** nothing listened on 9876 because Blender was closed and the Blender MCP
  add-on (0.1.6, an HTTP MCP server) does not auto-start. Launched `D:\Blender\blender.exe` with a
  startup script that starts the server, confirmed the handshake (88 tools) and a live scene read,
  then registered it with the CLI bundled in the Claude app (local scope, `✔ Connected`).
- **Which art:** the in-game violet costume exists only as 26–46 loose puppet parts with no pivots
  or assembly; the v3 pack is complete (55 parts, pivots, parents, rest transforms, joint chains,
  draw order, mirrored fan). Built from v3, which is the older teal look.
- **Did:** `tools/art/build_blender_rig.py` turns a part-pack manifest into a Blender scene: an
  image plane per part at its rest transform, an 84-bone stick armature in the picture plane
  (rotation about the view axis only, depth locked, `.L`/`.R` names), skinned torso / arms / legs /
  braids / skirt panels / sashes weighted along their chains, bone-parented rigid parts, the
  mirrored right fan, 15 hidden alternates (faces, cupped hands, lit membranes, effects), an
  orthographic camera on the 1024 px canvas, transparent film, Standard view transform; images
  packed. It uses the current scene, because an MCP- or background-run script has no window to
  switch scenes with. Built headless first, then live in the owner's Blender.
- **Files:** `tools/art/build_blender_rig.py`, `concept_art/ilyra_blender_rig_v1/{ilyra_rig.blend,README.md}`,
  `docs/{ASSETS,PROJECT_CONTEXT}.md`, `docs/guides/character_sprite_frames.md` (§7b), `CLAUDE.md`.
- **Verified:** rest-pose render against `assembly/ilyra_assembly_reference.png`: silhouette IoU
  0.999, mean colour difference 4/255. Pose test — raised arm with a bent elbow, bent knee, curled
  braids, tilted head, half-folded fan — bent every skinned part without a seam; a raised lower arm
  that vanished was traced to the fan correctly drawing in front of it. Viewport captured live.
- **Follow-ups:** the fan membrane is one painting, so folding a fan needs it keyed as well; no IK
  controls yet (FK chains only). The rig is v3's look — a rig of the violet costume needs a pivot
  manifest for its parts first. Blender needs its MCP server started each session unless the owner
  turns on *Auto-Start Server*.

## 2026-09-21 — Ilyra's menu video, and no bounce when a character is picked
- **Who:** Claude Code (Opus 5)
- **Owner requests:** a Lumina prompt for Ilyra that the generator accepts (two versions were refused
  with *"The input text may contain sensitive information"*, code 23003); her idle as an attacking
  pose; the upper hands of take 1 fixed; then "implement it now" for take 2; and mid-task, "remove
  that bounce animation each character has when it's picked".
- **The prompt:** Seedance reports text and image refusals separately, so code 23003 was the words.
  "arms" (weapons) and "crystals" (drug slang) sat in both refused prompts and in none that passed;
  the working prompt never describes her body and says "upper hands / lower hands" and "three small
  gems" instead. The reference is her in-game `aim_charge.png`, the only uncut combat-ready
  painting. Take 1's "flick them" made the upper hands snap the fans every ~0.6 s with speed-trail
  arcs; "hold the open fans high and steady" fixed it in take 2.
- **Did:** `extract_menu_video.py` takes a per-pack key colour — `keyness` / `despill` helpers,
  green for Ilyra (0.0 % of her solid pixels greenish, 6.5 % magenta-ish), magenta for Shade, whose
  output was checked unchanged against the shipped video (0.42 either way) — and a per-pack rig
  scale for placement. Ilyra's loop is frames 0–71 cut at the frame closest to frame 0, seam 3.36
  against a 3.28 median step. The playback moved into a shared `CharacterMenuVideo`
  (packed-alpha shader, pause while hidden, restart after re-attach) used by both
  `WholeFrameCharacterVisual` and `IlyraVisual`; her pose sprite and ornament ring hide while it
  plays. The pick, buy and equip flourishes are gone: the Shop no longer hops the focused card or
  pops a bought one, Home no longer hops a newly equipped hero, and `PlayableCharacterPreview` lost
  `play_selected` / `play_unlocked`. The states stay in the vocabulary for the QA boards.
- **Files/systems:** `tools/art/extract_menu_video.py`, `scenes/player/visuals/character_menu_video.gd`
  (new), `scenes/player/visuals/{whole_frame_character_visual,ilyra_visual,playable_character_visual,playable_character_preview}.gd`,
  `scenes/player/visuals/ilyra_visual.tscn`, `scenes/screens/{shop,home}_screen.gd`,
  `data/characters/ilyra_menu_video.tres`, `assets/art/characters/playable/ilyra/ilyra_menu.ogv`,
  `concept_art/ilyra_storefront_video_v1/`, `tools/godot/test_{ilyra,verdant_shade,playable_character}_visual.gd`,
  ADR-0016 addendum, GDD §14 #37 and #38 (no bounce; #31's flourishes superseded),
  `docs/{PROJECT_CONTEXT,ASSETS,ROADMAP}.md`, `docs/systems/{playable_character_visuals,shop,forms}.md`
  (API table, vocabulary, rules and test notes), `docs/marketing/devlog_characters_episodes.md`
  (the "buy → unlock flourish" shot no longer exists).
- **Verified:** Ilyra's stream decodes to 72 frames at 24 fps, matte floor 0.071, ceiling 0.937;
  her Shop card rendered and read back clean. `tools/validate.sh` → `VALIDATE: OK`.
  `tools/run_tests.sh _visual` → 5 passed, 0 failed — Ilyra now checks her video's placement, pause,
  re-attach and Reduced Motion fallback, and both Shop tests assert that buying or equipping no
  longer bounces. Full suite → `TESTS: 30 passed, 10 failed`, the same ten by name as the baseline.
  APK built with both videos, then installed and launched on the Galaxy S24 at the owner's request
  (21:26): boot OK at 120 Hz, Home ready, no errors in `adb logcat -s godot`.
- **Follow-ups:** owner looks at Ilyra's Home (with her equipped) and Shop card on the phone, and
  confirms picking and equipping no longer bounce. Her `SpriteFrames` still
  holds every painting even while the video plays — the re-cut onto the sheet packer would fix it.
  With two videos in the game, two Shop cards can decode at once if they are neighbours; limit
  playback to the focused card before a third lands.

## 2026-09-21 — Ilyra's video brief and a clean front-facing image
- **Who:** Claude Code (Opus 5)
- **Owner request:** "write the prompt for ilyra and give me from game files a clean front facing image".
- **Did:** chose her front-facing `idle_hover` pose and found its right boot cut flat by the game
  file's canvas edge — the painting is a 627 px quarter of `pose_sheets/01_core_states.png` and the
  boot runs 14 px past the quarter line. Rebuilt it from the game file's own cleaned pixels plus the
  boot's own tip from the sheet (the neighbouring pose starts 10 px lower). Measured the key colour
  instead of reusing Shade's: magenta would start eating 5.3 % of her (lavender skin, violet fan
  tips), blue 27.8 % (fans), green 0.0 % — so her reference is on `#00FF00`. Wrote the brief, which
  leans hardest on what video models break: exactly four arms, hands, and fans that stay open.
- **Files:** `concept_art/ilyra_storefront_video_v1/` (`VIDEO_PROMPT.md`, two 1024² references,
  `ilyra_front_clean.png`), `docs/ASSETS.md`.
- **Verified:** boot tip inspected at 3x; no piece of the neighbouring pose in the result (one piece
  on the bottom row, the boot's own). Prompt lengths: full 2,370 (under Kling's 2,500), short 845,
  negative 797.
- **Follow-ups:** before her take can play, `extract_menu_video.py` needs a green-key mode, and
  Ilyra — still on `IlyraVisual` — needs menu-video playback or the re-cut onto
  `WholeFrameCharacterVisual`. The game's `idle_hover.png` still has the cut boot; worth repacking
  from the sheet when she is re-cut.

## 2026-09-21 — Shade's menu video, and the Home bug it caused
- **Who:** Claude Code (Opus 5)
- **Owner request:** add the generated Shade video (`2026-09-21_14-58-50_Lumina.mp4`) to the game
  and remove any watermark; then, mid-task, "there is a bug in the home screen sometimes the
  animation doesn't go off".
- **Did:** built the menu-video path of ADR-0016. `tools/art/extract_menu_video.py` cuts the loop at
  frame 80 (the one closest to frame 0) and cross-fades 8 frames across the seam, keys the magenta
  (unmix, despill, colour decontamination, 0.2 matte choke), forces the generator's "AI" label
  corner transparent, packs premultiplied colour | matte, encodes Ogg Theora, then decodes its own
  output and writes `MenuVideoData` with the measured matte floor/ceiling. `WholeFrameCharacterVisual`
  plays it on Home and the Shop card through `packed_alpha_video.gdshader`; Reduced Motion falls back
  to the sprite loop; a hidden card pauses; Shade's form no longer warms a menu sheet.
- **Three things went wrong on the way, each now guarded:** (1) Windows ffmpeg wrote broken Theora —
  its own decoder rejected 91 % of the packets and Godot drew macroblocks; Godot's docs name exactly
  this, so the encode moved to Godot's own Movie Maker in a throwaway project. (2) Movie Maker stamped
  the stream at 60 fps (1.33 s instead of 3.33 s) until `--fixed-fps` was passed; the tool now fails
  on a frame-rate or frame-count mismatch. (3) It recorded one extra frame at the end, a hold at the
  loop point; the encoder now quits on the frame that shows the last image. Also a float32 mean that
  read the background as (140, 0, 140) instead of (243, 0, 245).
- **The Home bug:** Main keeps one Home and *detaches* it on leaving; a `VideoStreamPlayer` stops
  itself on leaving the tree and never restarts, and Home only rebuilds the hero when the equipped
  character changes — so Shade's video stood still after every trip to another screen. Reproduced by
  a probe that detached and re-attached every character: only Shade stuck, the seven others kept
  moving. Fixed by restarting the clip when it re-enters the tree; the regression check was confirmed
  to fail with the fix disabled.
- **Files/systems:** `tools/art/extract_menu_video.py`, `scripts/resources/menu_video_data.gd`,
  `assets/shaders/packed_alpha_video.gdshader`, `scenes/player/visuals/whole_frame_character_visual.gd`,
  `scenes/player/visuals/verdant_shade_visual.tscn`, `data/forms/verdant_shade.tres`,
  `scripts/resources/form_data.gd`, `data/characters/verdant_shade_menu_video.tres`,
  `assets/art/characters/playable/verdant_shade/verdant_shade_menu.ogv`,
  `concept_art/verdant_shade_storefront_video_v1/source/`, `tools/godot/test_verdant_shade_visual.gd`,
  ADR-0016, GDD §14 #37, `docs/{PROJECT_CONTEXT,ASSETS}.md`, the system doc and the frames guide.
- **Verified:** decoded stream is 80 frames at 24 fps (3.33 s), round-trip error 0.42/255, decoded
  seam 1.22 against a 1.66 median step, background matte mean 0.03/255. Shop card rendered and read
  back: clean edges, no box, no label. `tools/validate.sh` → `VALIDATE: OK` (109 scripts).
  `tools/run_tests.sh _visual` → 5 passed, 0 failed. Full suite: `TESTS: 30 passed, 10 failed`. The fixed APK was
  installed and launched on the Galaxy S24 at the owner's request (15:46): boot OK at 120 Hz, Home
  ready, no errors in `adb logcat -s godot`. An earlier attempt was held back while the phone was on
  an Instagram call; nothing on it was touched and the two phone screenshots taken were deleted.
- **Follow-ups:** owner looks at Shade's Home and Shop card on the phone, including a trip to another
  screen and back (the case the bug hid in). Before a second character gets a video,
  play only the focused Shop card's clip. Check the generator's terms on commercial use and label
  removal, and the store's AI-content disclosure, before release.

## 2026-09-21 — On the phone, and a video brief for Shade's storefront idle
- **Who:** Claude Code (Opus 5)
- **Did:** exported the debug APK with the five-animation set and installed it on the owner's
  Galaxy S24 (`SM-S921B`) over USB; it boots clean (`physics=120 Hz`, Loading 0.77 s, Home ready,
  no errors in `adb logcat -s godot`). The owner then proposed replacing the storefront idle with
  a pre-made video. Recommended it for **Home and the Shop only**, on Godot's documented limits:
  Ogg Theora is the only core codec, decoding is on the CPU (≤ 720p / 30 fps on mobile), there is
  no alpha, and a loop stays seamless only with *Video Delay Compensation* at 0. Wrote the
  image-to-video brief for Shade and built its reference image.
- **Transparency without alpha:** no image-to-video model exports it, so the model paints Shade on
  flat magenta and the pipeline removes it. Green is out (Shade is green), black and white collide
  with the hood and the mask. The reference goes in *already on magenta*, because most models keep
  the input's background — a stronger lever than prompt text.
- **Files:** `concept_art/verdant_shade_storefront_video_v1/` (`VIDEO_PROMPT.md`, two 1024²
  references from `idle_hover_00.png`, the 512 original of the owner's 384 portrait), `docs/ASSETS.md`.
- **Verified:** device boot log read back; references inspected. Prompt lengths measured: full
  2,465 characters (under Kling's 2,500), short 801, negative 667.
- **Follow-ups:** owner generates 3–4 takes and drops the MP4s in `source/`. Then: magenta key with
  despill cross-checked against an AI matte, colour|alpha packed side by side, Theora encode, a
  recombining shader, video on the focused Shop card and the Home hero only, portrait for Reduced
  Motion. An ADR is due when that playback lands — it is a new media type and pipeline.

## 2026-09-20 — A drawn character is five animations

- **Who:** Claude Code (Opus 5)
- **Owner decision:** "the game shall have idle animation which is going to be displayed in the shop
  and as well in the home screen, the dash state, all wall animations — and the dash and the attack
  are the same … the others shall be removed", then, on the detail: holding the phone to aim shows
  only the arrow; releasing plays the dash, which is the same animation as the attack; landing shows
  the wall animation whichever wall it is; and there is **no death or spawn animation** — a killed
  character "just blinks like it was before and his position gets reset". GDD §14 #36.
- **Did:** cut the drawn set from sixteen animations to **five** — `dash_loop` (one frame of which is
  the contact), `wall_bottom` / `wall_top` / `wall_left` (`wall_right` mirrored) and one
  `storefront_idle`. `WholeFrameCharacterVisual._target_animation()` now resolves the whole
  thirteen-state controller vocabulary onto those five: dash states show the dash, everything else
  shows the wall, a menu always shows the storefront rest, and `aim_charge` still holds whatever is
  playing. Nothing in the vocabulary is refused — a `death` request still travels the state machine,
  locks out later states and fades out; it just has no picture of its own. Ilyra follows the same
  rule from her loose PNGs. **The four bone rigs are untouched** and still animate all thirteen,
  because generating them costs nothing.
- **What the cut states look like now:** the arrow is the windup; the wall loop arriving is the
  landing; the dash's own contact frame is the attack; the controller's invulnerability blink and
  reform-at-a-safe-edge are the hit; the 0.55 s alpha dissolve is the death; a run simply starts with
  the character on its wall. The gameplay `idle_hover` was provably dead already — `_has_surface` was
  true from the first `sync_controller`, so a live character is always on a wall — and the menu sheet
  carried a second copy of it that only one of the two idles ever used.
- **Cost:** 120 frames on three sheets → **40 on two**. `<id>_run.png` 3200×1600 (28 frames) and
  `<id>_menu.png` 2784×928 (12); the reaction sheet is gone. About **30 MB of texture per character
  instead of 107 MB**, and ~30 MB for a Shop carousel instead of 330 MB. The packer's `sheets` list
  is the whole cut — every removed frame is still in `concept_art/`, so restoring one is a name in
  that list and a re-pack, not a re-commission.
- **Files/systems:** `scenes/player/visuals/{whole_frame_character_visual,ilyra_visual}.gd`,
  `scenes/player/visuals/{void,eclipse,verdant_shade}_visual.tscn` (`menu_idle_animation`),
  `tools/art/extract_playable_characters.py` (two-sheet layout), regenerated
  `assets/art/characters/playable/{void,eclipse,verdant_shade}/` and
  `data/characters/*_{gameplay,menu,frames}.tres`,
  `tools/godot/test_{verdant_shade,void,eclipse,ilyra}_visual.gd`,
  `tools/godot/render_{whole_frame_states,ilyra_poses}.gd`,
  `docs/guides/character_sprite_frames.md` (the order form, rewritten to five),
  `docs/systems/playable_character_visuals.md`, `docs/{GDD,PROJECT_CONTEXT,ROADMAP,ASSETS}.md`,
  `docs/systems/shop.md`.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (108 scripts, clean import and boot).
  `tools/run_tests.sh _visual` → **5 passed, 0 failed**, including the reduced contract (the five
  animations at their counts/rates/loops, and a new `CUT_ANIMATIONS` check that none of the eleven
  crept back onto a sheet), state and wall mapping, the mirrored right wall, the menu rest, Reduced
  Motion and the frame-set split. Both review boards rendered and read back: the six-cell whole-frame
  board (Shade) and the seven-cell Ilyra board — every cell reaches its animation, every wall upright,
  `wall_right` correctly mirrored. Full suite: `tools/run_tests.sh` → **30 passed, 10 failed**, the same ten by name that failed before this
  change (all stale since M10 — `forms_screen.tscn`, `configure_run_profile`, `purchase_form`);
  none of them touch characters or animations.
  One test fix worth noting: the three whole-frame tests drove `request_state` directly, so a finished
  `dash_start` one-shot fell back to the idle instead of the dash and Eclipse lost the race; they now
  drive `sync_controller`, which is how the controller actually talks to a rig.
- **Follow-ups for the owner:**
  - **Watch a run.** The cut is reversible per animation, but it is the run's *feel* that decides it —
    particularly the missing landing beat on every dash and the missing death.
  - **The bone rigs now differ from the drawn characters.** Veyra, Rook, Morrow and Noxen still play
    death, victory, hit, spawn and the aim lean; Void, Eclipse, Shade and Ilyra do not. Either re-cut
    the rigs to match or accept that a run reads differently per character.
  - **Menus moved to `storefront_idle`.** With one idle surviving, the menus now show the authored
    storefront loop rather than the gameplay idle you were comparing it against on 2026-09-20. One
    export flip and a re-pack if you preferred the other.
  - **The wall loops are now 60% of a character's art.** That is the right place to spend it — they
    are what a player looks at — but a weak wall loop is now a weak character.
  - Re-cut Ilyra onto the sheet packer: she is the last character drawn from loose PNGs, so her
    `SpriteFrames` still holds every retired painting as its own texture.
  - Prices are still 0 RP for every character except Eclipse.

## 2026-09-20 — Devlogs #5–#8, and the move from Palmier to Remotion
- **Who:** Claude Code (Opus 5)
- **Owner request:** "you are a professional video editor using remotion, create the next devlogs" —
  analyse the project, the agent docs, the hook library and the DEVLOG, propose topics, then build
  the four chosen ones (#5, #6, #7, #8) one at a time.
- **Why the tool changed, and what did not.** Palmier Pro is macOS-only and its MCP server, the
  `video/` workspace and the Kokoro models all live on the owner's Mac; this checkout is Windows.
  Remotion runs here on what is already installed (Node 24, ffmpeg 8). **Only the assembly tool
  moved.** Every editorial rule in [devlog_video_recipe.md](marketing/devlog_video_recipe.md)
  survives unchanged — hooks, story structures, safe numbers, the visual-event→game-sound map,
  TikTok safe zones, caption style, QA and loudness. §6's element cookbook is now React components
  rather than hand-typed keyframe rows, which is why episodes #6–#8 cost a fraction of #5.
- **The pipeline** (`tools/video/remotion`): `src/style` holds the palette (from
  `devlog_graphics.py`, so it matches the earlier episodes and the game's own UI), the three fonts
  via `@remotion/google-fonts`, and the house pop/slam/draw-on curves. `src/components` is the
  cookbook: roster wall, parts scatter and grid, a two-bone IK diagram, the registration A/B,
  spectrum bars, numbers board, step cards, captions, footage and game SFX. Each episode is a beat
  map of frame numbers taken straight from Kokoro's `lines.json`/`srt`, so a visual lands on its
  spoken word. New helpers: `srt_to_ts.py` (the browser cannot read an SRT at render time),
  `master_export.sh` (Remotion mixes at the voice's own ~−17.7 LUFS; every export needs the R128
  pass) and `contact_sheet.sh` (how an agent watches a render back on this machine).
- **Episodes, all drafts awaiting review.** #5 "I deleted six characters" (47.1 s) · #6 "I built
  it, it worked, and I deleted it" (49.2 s) · #7 "Zero sound files" (43.7 s) · #8 "858 megabytes
  for a shop screen" (52.7 s). Hooks rotate H6/H1/H8/H5 across four different §3.1 treatments, two
  of which are new and are now registered in the recipe: **roster wall strike-out** and **counter
  slam**.
- **Facts were re-derived from the repo, not copied from the briefs.** Ilyra's rig is **55** parts
  (the 56th file is `preview.png`), matching the DEVLOG's "55-part pack" — the first voice take
  said 56 and was re-recorded. The roster is **8**, not the 9 in the 2026-09-20 brief. The audio
  ids are **19** effects plus 8 pitched slice steps, from `audio_synth.gd`'s 22 minus the three
  music layers. `find assets` for wav/ogg/mp3 returns **0**, so #7's hook is true. The 695→261 ms
  measurement is **Home**, not the Shop; the newer brief conflates them and the script says home
  screen.
- **Nothing on screen is a mock-up.** Footage is the real `render_devlog_tour` capture; the retired
  portraits and the 55 rig parts came out of `git show HEAD:`; the registration demo plays Verdant
  Shade's twelve real `idle_hover` frames sliced from the packed atlas by its own `.tres` regions;
  #7's bars are the true spectrum of the game's exported WAVs and its counting beat plays
  `slice_step1..5`. The one synthetic element — the drift on the right of the registration panel —
  is labelled on screen as added.
- **Files:** `tools/video/remotion/` (34 source files), `tools/video/{srt_to_ts.py,
  master_export.sh,contact_sheet.sh}`, `tools/video/README.md`,
  `docs/marketing/devlog_video_recipe.md` (§1 rule, §6 pointer, two new treatments),
  `docs/marketing/devlog_hooks.md` (§6 log rows 05–08). Exports and the voice/graphics workspace
  are under the git-ignored `video/`.
- **Verified:** all four export 1080×1920 / 60 fps / H.264 + AAC 48 kHz, under 60 s, at **−14.4
  LUFS** with true peak −2.1 to −2.9 dBTP. `npx tsc --noEmit` clean. Every episode was watched back
  as a contact sheet and fixed on what that showed — the buried "55", a dead 4 s hold in the parts
  cloud, two captions sitting on artwork, a chin gag that did not read, and `visualizeAudio`
  needing a power-of-two sample count plus a dB scale before the bars stopped being a cliff.
- **Follow-ups for the owner:** watch the four and say which hooks land; the EP01–EP04 exports are
  not on this machine, so the port matches the written spec but the *feel* of the approved EP02 has
  not been checked against the real cut. The three previously-planned episodes lost their numbers to
  this batch and are now listed as unshot topics; "They land on their feet" is superseded outright,
  because the pre-attack coil it is about was removed on 2026-09-19.

## 2026-09-20 — Eclipse Wisp celestial-corona redesign and sprite sheet
- **Who:** Codex
- **Owner request:** change Eclipse's form while keeping it a Wisp, then create a detailed sprite
  sheet with smooth neighboring frames like the new Void pack.
- **Did:** redesigned Eclipse from an upright purple flame into a compact handless celestial Wisp:
  glossy obsidian face-core, opposing violet/gold broken-eclipse crescents, three lower flame ribbons
  and a close moon-bead orbit. Generated an identity atlas and four animation-phase atlases, then
  built the complete 108-frame contract without cross-fades. The dash points down canvas +Y and uses
  its gold crescent as the contact edge; storefront flourish briefly aligns both crescents into a
  full eclipse ring. Added labelled/transparent sheets, JSON timing/QA data and four loop GIFs.
- **Files/systems:** `concept_art/eclipse_wisp_sprite_v1/`, `docs/ASSETS.md`; source art only. The
  current runtime Eclipse form, catalog, save and gameplay files remain unchanged pending review.
- **Verified:** builder QA reports 108/108 unique frames, exact counts, 512² gameplay/wall canvases,
  724² storefront canvases, clean transparent RGB and alpha-box registration within 0.5 px. Removed
  two clipped top-edge atlas fragments with a narrow deterministic rule and re-inspected the death
  frames plus the complete 3072 × 4096 review sheet. `tools/validate.sh` → `VALIDATE: OK` (105
  scripts checked, clean import and boot).
- **Follow-ups:** owner reviews the redesign and motion; revise source poses if needed, then integrate
  only approved art through the deterministic whole-frame intake.

## 2026-09-20 — Void Wisp smooth whole-frame sprite sheet
- **Who:** Codex
- **Owner request:** redesign the Void and Eclipse Wisps as animated whole-frame sheets, starting
  with Void and making every neighbouring frame differ only slightly so playback stays smooth.
- **Did:** kept Void's handless soul-flame silhouette, black face core, cyan/white/cobalt palette,
  forehead star, crescent plume, diamond and comet wisps; generated an identity atlas plus four
  animation-phase atlases. `concept_art/void_wisp_sprite_v1/build_sprite_pack.py` turns the distinct
  drawings into the exact 108-frame contract without cross-fades, using only sub-pixel timing
  changes inside each phase. Added the transparent sheet, labelled review sheet, exact JSON row map
  and GIF previews for idle, movement, top-wall and storefront loops.
- **Files/systems:** `concept_art/void_wisp_sprite_v1/`, `docs/ASSETS.md`; source art only. Eclipse
  and runtime character/catalog/save/gameplay files were deliberately left untouched for owner
  review of Void first.
- **Verified:** builder QA reports 108/108 unique frames, exact per-state counts, 512² gameplay/wall
  canvases, 724² storefront canvases, clean transparent RGB and alpha-box registration within
  0.5 px. Labelled 3072 × 4096 review sheet inspected state by state. `tools/validate.sh` →
  `VALIDATE: OK` (105 scripts checked, clean import and boot).
- **Follow-ups:** owner reviews Void's look and motion; revise this pack if needed, then build the
  Eclipse pack to the same contract and only integrate approved art through the deterministic
  playable-character intake.

## 2026-09-20 — Verdant Shade whole-frame sprite sheet
- **Who:** Codex
- **Owner request:** turn the approved green hooded creature into a classic one-row-per-state sprite
  sheet with the exact requested animation counts, including menu reactions and no `aim_charge`.
- **Did:** generated a transparent identity atlas plus four 4 × 4 phase atlases so every move has
  separately drawn changes to flame shapes, cloak-leaf overlap, eyes and root-ribbon curves—not
  repeated stills with transforms. `concept_art/verdant_shade_sprite_v1/build_sprite_pack.py`
  preserves the fixed cell registration, adds crisp in-phase timing without cross-fades and builds 108 unique
  frames: 54 requested gameplay frames, 24 wall frames and 30 storefront frames. `wall_right` is
  mirrored from `wall_left` at runtime.
- **Files/systems:** `concept_art/verdant_shade_sprite_v1/` only; source art and review sheet, no
  runtime character, catalog, save or gameplay integration.
- **Verified:** sprite QA checks 108 files, exact state counts, 512² gameplay/wall canvases, 724²
  storefront canvases, clean transparent RGB, unique frames, visible-content registration within
  one pixel, and a 3072 × 4096 row sheet. `tools/validate.sh` → `VALIDATE: OK`. Full tests remain
  24 pass / 13 unrelated failures from the pre-existing in-progress catalog/screen/rig edits.
- **Follow-ups:** owner reviews the art/motion first; after approval, add the sheet packer/runtime
  resource split and lazy Shop cards required by `docs/guides/character_sprite_frames.md` §9c.

## 2026-09-20 — Noxen, the Veilflame: basic production rig
- **Who:** Codex
- **Owner request:** implement the last blue concept as a new handless creature, name it, and give it
  a Morrow/Rook-style rig in reviewable steps so Claude can continue the polish.
- **Named:** **Noxen, the Veilflame** (`noxen`). ASSUMPTION pending owner review: Legendary tier,
  0 RP. Like every character, he is presentation-only and keeps the shared collision, controls,
  dash, damage and scoring.
- **Art/pipeline:** generated a transparent twelve-part source sheet and neutral assembly, then added
  `concept_art/noxen_v1/extract_parts.py`. It deterministically produces the per-part pivot manifest;
  the shared extractor copies it into `assets/art/characters/playable/noxen/`, derives the portrait,
  and the rig builder generates `noxen_visual.tscn`. Edge-connected leaks from neighbouring sheet
  cells are removed without deleting detached flame sparks.
- **Rig/motion:** 12 painted groups: cloak, hood, mask, core, two fins, front flap, shadow tail, two
  independently sprung flame horns and two skinned root-flame `RibbonChain`s. All 13 shared states,
  Reduced Motion and menu flourishes work. The dash narrows into a flame-first spear with the root
  ribbons trailing; contact flares the fins into the cut and throws an eight-shard burst; landing
  spreads the fins into a handless wall brace.
- **Integration:** thirteenth catalog/save character; cyan Blade Arc `DashEffectData`; live Home and
  Shop previews; form/tier/count tests and benchmark lists updated. The lineup fixture can now filter
  to one row with `WISP_CHARACTER=<id>` for close review.
- **Looked at:** transparent part contact sheet, Shop, Home, production gameplay, and filtered
  reference/idle/dash/attack boards. The final idle is cohesive and the dash clearly leads with both
  flame horns; it does not read as a humanoid with missing hands.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; targeted `form_catalog` and
  `playable_character_visual` tests pass; full suite 27 pass / the same 10 documented stale M10
  failures; all 13 preview benchmark 422 ms cold / ~7 ms warm with no measurable headless per-frame
  cost above the 6.9 ms baseline.
- **Handoff:** `concept_art/noxen_v1/CLAUDE_HANDOFF.md` records the exact regeneration chain and the
  remaining one-step-at-a-time motion/contact-sheet, four-wall and phone review. Owner still decides
  final name approval, tier, price, motion sign-off and generated-art licence.

## 2026-09-20 — Session wrap: the roster was halved, then hand-animated
- **Who:** Claude Code (Opus 5)
- **The spine of the session**, for anyone reading back: bone rigs were abandoned in favour of
  hand-drawn frame animation, the roster was cut from thirteen to seven, and the last two still
  images in the game — Void and Eclipse — were rebuilt as 108-frame characters. Nothing in the
  CHARACTERS tab is a static picture any more.
- **In order, with its own entry below each:** Ilyra 2's jointed menu puppet built and reverted ·
  the whole-frame generation contract written · the roster cut and Ilyra 2 promoted to Ilyra ·
  Shade added as the first whole-frame character · her atlas bleed, loop rate and Shop hitch fixed ·
  the stray fragments traced to her source art · the run HUD decluttered · the dash slowed 20% ·
  the equipped character's menu sheet warmed behind the boot screen · the arena Shop turned into a
  gallery · Void and Eclipse rebuilt · the menus pointed at the gameplay idle as an owner test.
- **Three findings worth carrying forward**, because each cost real time to learn:
  1. **Registration beats drawing quality.** Twelve frames drawn on the same anchor pixel read as
     motion; four beautiful frames that are not registered read as a flip-book. This is now the
     first rule in the commissioning brief.
  2. **The same visible symptom had two different causes.** A sliver of another frame stuck to the
     character was atlas bleed in one pack (fixed with an 8 px gutter) and clipped source art in
     another (the character drawn larger than its own canvas). Both cleanups are opt-in per pack,
     because each would have damaged the other's art — the clipped-fragment rule would have eaten
     Eclipse's moon beads, and the stray rule would have amputated Void's flame plumes.
  3. **A Shop card is a live character, and VRAM does not care what a texture cost on disk.**
     Thirteen live cards at the recommended frame budget came to 858 MB. Lazy cards and the
     menu/gameplay frame split are what make a whole-frame roster affordable at all.
- **Marketing:** [devlog_video_brief_2026_09_20.md](marketing/devlog_video_brief_2026_09_20.md) —
  what films well, the stills that already exist, the numbers that are safe to put on screen and
  the claims that are not.
- **State at the end:** `tools/validate.sh` → OK; the whole-frame character tests, the catalog test
  and the shared rig test all pass; the full suite sits at 30 passed / 10 failed, the ten being the
  documented M10-stale ones. Built and installed on the owner's Galaxy S24, clean boot, no errors.
  Nothing committed.

## 2026-09-20 — Owner test: menus rest on the gameplay idle, not the storefront performance
- **Who:** Claude Code (Opus 5)
- **Owner, explicitly a test:** "in store front in all character replace the animations as idle
  animations that are in the game". Home and the Shop card now rest on each character's **gameplay**
  `idle_hover` instead of its authored `storefront_idle`.
- **How, without breaking the memory split.** The obvious route — a menu loading the gameplay frame
  set — would have put the run sheets in every menu, which is the one thing the split exists to
  prevent. Instead the packer copies `idle_hover` onto the **menu** sheet as well, so a card resting
  on the gameplay idle costs exactly what it did before and a run still never loads the menu sheet.
  It is the single deliberate overlap between the two sets, and the tests now allow that one name
  and keep asserting the rest are exclusive.
- **The menu cell shrank 512 → 448.** 42 frames at 512 would have been 3168 × 4224, over the 4096
  texture floor — the intake's own size guard caught it rather than shipping a sheet half the
  devices cannot sample. `MENU_SCALE` follows at 384/448 so the character is still drawn at its
  in-run height. Sheets are 2784 × 3712, comfortably inside.
- **Reversible in one line per character:** `menu_idle_animation` is an export on
  `WholeFrameCharacterVisual`, set per scene. Point it back at `storefront_idle` and the authored
  performance returns; the frames are all still there.
- **Verified:** `tools/validate.sh` → OK; `test_void_visual`, `test_eclipse_visual` and
  `test_verdant_shade_visual` all pass; all three Shop cards captured and compared side by side.
- **What it looks like:** Void and Eclipse read almost identically either way — they are wisps, so
  the idle and the storefront pose are the same silhouette. Shade is the real comparison: her
  gameplay idle is a tighter, more compact figure than her storefront spread. That is the judgement
  call to make on a device.

## 2026-09-20 — Eclipse rebuilt as a whole-frame character; no still images left
- **Who:** Claude Code (Opus 5)
- **Did:** Eclipse is an animated whole-frame character now, on the same shared
  `WholeFrameCharacterVisual` as Void and Shade. `form_id`, name, description, **price 2000**, the
  **boss-victory gate**, tint, dash effect and catalog position are all unchanged — no migration,
  no second entry. With Void done earlier today, **nothing in the CHARACTERS tab is a still image
  any more**: the two single-image Wisp forms were the last ones.
- **Its pack is the cleanest of the three.** Registered to 0.5 px, RGB zeroed under alpha 0, and
  **not one of the 108 frames reaches a border** — so neither intake cleanup is enabled for it.
  That matters: `strip_clipped`, which Void needs, would have eaten Eclipse's orbiting moon beads,
  which are detached by design. Both cleanups being per pack rather than global is what makes three
  packs with three different defect profiles share one intake.
- **Checked every Eclipse-specific item from the brief**, on the 17-cell board and a live run: the
  circular celestial-corona silhouette survives, it still reads as a handless Wisp, violet and gold
  crescents stay distinct, the gold crescent leads on the dash contact frame, `death` collapses into
  the cracked core, `revive_spawn` reforms in order, the storefront flourish forms the full eclipse
  ring, and the moon beads show no jitter and no clipped fragments.
- **Files:** `tools/art/extract_playable_characters.py` (`eclipse` pack),
  `scenes/player/visuals/eclipse_visual.{gd,tscn}`, `data/forms/eclipse.tres`,
  `data/characters/eclipse_{gameplay,menu,frames}.tres`,
  `assets/art/characters/playable/eclipse/`, `tools/godot/test_eclipse_visual.gd`, and the two
  roster test lists.
- **Verified:** `tools/validate.sh` → OK; `test_eclipse_visual` and `test_form_catalog` pass; the
  board reached 17/17 animations with none missing; Home, Shop card and a live run inspected.

## 2026-09-20 — Void rebuilt as a whole-frame character
- **Who:** Claude Code (Opus 5)
- **Did:** the default Wisp is an animated whole-frame character now instead of a single image on the
  shared base rig. Same `form_id`, name, description, price 0, tint, dash effect and catalog
  position — no save migration, no second entry.
- **Extracted `WholeFrameCharacterVisual` first.** Void would have been a second copy of Shade's
  ~250 lines, and Eclipse a third. The behaviour moved to a shared base; `VoidVisual` and
  `VerdantShadeVisual` are now four-line subclasses that exist only to carry a `class_name`, and
  each scene sets its own two frame-set paths. Shade's test still passes unchanged.
- **The stray-stripper was unconditional, and that was a bug waiting to happen.** It was written for
  a defect in Shade's pack; run against Void it would have amputated the flame plumes
  (−2,476 px on `move_fly_00`). It is opt-in per pack now, and Void does not use it.
- **Void's pack has its own, different defect.** 21 of its 108 frames draw the character larger than
  the 512 canvas, so the crystal above its head is severed by the border — a flat-cut sliver that
  floated over the wisp in a run. Confirmed by measurement (`dash_loop_02`: 194 px on the top row)
  and by looking at the gameplay render. The pixels are gone and cannot be recovered on intake, so
  `strip_clipped` removes the severed fragments: ~90k px across 14 states, and a missing crystal
  reads better than a guillotined one. **The pack should be fixed at source** — logged in the
  ROADMAP backlog.
- **The rule took three passes to get right,** which is worth recording. "Touches the frame edge"
  missed it, because the pack re-centres each silhouette after cutting and a severed piece lands a
  few pixels short of the border. "Wholly above the body" was Shade's rule and would have taken
  legitimate floating orbs. What works is "detached **and** hugging the border", with the margin a
  share of the frame; `move_fly_00` keeps its 105 px orb and loses its 2,336 px severed piece.
- **Loops play at the authored rate.** `loop_fps_scale` is 1.0 for Void — Shade's 1.4 is a phone
  compromise for her own pack and is not inherited by default.
- **Files:** `tools/art/extract_playable_characters.py` (`void` pack, opt-in cleanups,
  `strip_clipped_fragments`), `scenes/player/visuals/whole_frame_character_visual.gd`,
  `void_visual.{gd,tscn}`, `verdant_shade_visual.{gd,tscn}`, `data/forms/void.tres`,
  `tools/godot/test_void_visual.gd`, `render_whole_frame_states.*` (the Shade-specific board is now
  generic, driven by `WISP_CHARACTER`), and the two roster test lists.
- **Verified by looking, not only by logs:** the 17-cell state board (every animation reached, none
  missing, right wall mirrored, no severed fragments left), a live run, Home and the Shop card.
- **Eclipse was not touched.**

## 2026-09-20 — ARENAS becomes a gallery, not a card carousel
- **Who:** Claude Code (Opus 5)
- **Owner:** the arena layout should not be "like these cards"; asked for research and options, then
  picked the grid-plus-full-bleed-peek option.
- **What was wrong**, from rendering the tab rather than assuming: thirty arenas one at a time
  behind **thirty dots**, each shown as a 282×502 thumbnail inside an ornate card frame on a purple
  background — a picture of a picture. The part you are actually buying, the floor you dash around,
  was a grey rectangle in the middle. A card is a *collectible* signifier; it fits a character,
  which is a thing you own, and miscasts an arena, which is a place you enter.
- **Research:** the [Game UI Database](https://gameuidatabase.com/) files these as different screen
  families — *Change Skin or Accessory* is the card/carousel pattern, while environments sit under
  *Stage/Level Select*, *Level Select: World Map* and *Area Map*. The tab was using the first for
  content belonging to the others.
- **Built:** a scrolling gallery of three portrait tiles across, grouped under tier headings that
  carry an owned/total count, each tile the arena's own thumbnail with its name and
  `EQUIPPED` / `OWNED` / price, unowned art dimmed. Tapping a tile opens the **peek**: the full
  background edge to edge over a scrim with the name, tier, description and the same buy/equip
  button. `handle_back` closes the peek first, so Android back steps out one level at a time.
- **Two things the renders caught that reasoning did not.** Landscape tiles cropped every arena to
  its empty floor — the one part they all share — so the tiles are portrait at the thumbnails' own
  282×502 shape. And the `CardButton` frame's bottom trim sat exactly where the price goes, which is
  what made the tiles flat, which is the better design anyway.
- **Dead code removed, because this change orphaned it:** `_add_arena_visual`, `_fill_arena_visuals`,
  `_arena_filled`, `_arena_centre`, the per-frame fill in `_process` and the `ArenaSkinData` branch
  of `_build_card`. Arenas no longer pass through the carousel at all.
- **Files:** `scenes/screens/shop_screen.{tscn,gd}`, `tools/godot/render_arena_tab.*` (new fixture,
  `WISP_ARENA_PEEK=<skin_id>` captures the second level).
- **Verified:** `tools/validate.sh` → OK; both Shop tabs re-rendered and inspected — CHARACTERS keeps
  its carousel, ARENAS is the gallery; the peek captured on `dragon_skull_throne`.
- **Not changed:** the purchase and equip flow. The peek drives the same `_on_action_pressed`, so
  gating, pricing and the snapshot diff are untouched.

## 2026-09-20 — Warm the equipped character's menu sheet behind the boot screen
- **Who:** Claude Code (Opus 5)
- **Owner report:** opening Home stalls now that Verdant Shade is equipped.
- **Cause:** a whole-frame character's menu `SpriteFrames` is a 3,168 px square, and whichever screen
  drew her first paid for it. Shrinking the cell earlier only moved the stall from the Shop to Home.
- **Did:** `FormData.menu_frames_path` — deliberately a **path**, not a resource reference, because a
  reference would pull the sheet in with the form itself including during a run, which is exactly
  what the menu/gameplay split exists to avoid. `Main._kept_paths()` appends it for the **equipped**
  character only, so the boot screen's threaded loader fetches it behind the bar. Warming the whole
  roster would hold every character's sheet at once, which is the bill the Shop's lazy cards were
  built to avoid.
- **Measured on the phone, same device and save:**
  `switch HomeScreen | build 695.1 ms · worst frame 752.4 ms` → **`build 260.8 ms · worst frame
  293.7 ms`**, and the loading screen's resource count went 23 → 24, which is the sheet arriving
  where it should.
- **Not claiming it is gone.** Home still builds in ~261 ms against ~37 ms before this character
  existed. The remainder is Home building the live preview itself plus the first GPU upload of the
  sheet, which a CPU-side `load()` does not force. The next lever, if it is worth one, is drawing it
  once off-screen during the boot screen.
- **The path is written in two places** — the form warms it, the rig loads it — so
  `test_verdant_shade_visual` now asserts they match.
- **Files:** `scripts/resources/form_data.gd`, `data/forms/verdant_shade.tres`,
  `scenes/main/main.gd`, `tools/godot/test_verdant_shade_visual.gd`.
- **Verified:** `tools/validate.sh` → OK; `test_verdant_shade_visual` and `test_form_catalog` pass;
  built, installed and measured on the device.

## 2026-09-20 — Dash slowed another 20%
- **Who:** Claude Code (Opus 5)
- **Did (owner):** "in the gameplay screen when the character dashes slow the dash down for 20%".
  `PlayerTuning.dash_speed` 3,960 → **3,168 px/s** in `data/player/default_player_tuning.tres` and
  the schema default, the same pair the −10 % pass on 2026-09-15 changed.
- **Why one number was enough.** Everything that modifies the dash is a *fraction of* it — the
  launch burst, `momentum_step` / `momentum_max`, the mutation multiplier and RUSH all multiply on
  top — so they scale with the base and keep their relative feel. Nothing in the data or the tests
  hard-codes an absolute dash speed; the tests assert the multiplier, not the px/s.
- **What it costs in feel:** a 1080 px cruise crossing goes from ~273 ms to ~341 ms. Fixed times
  around it are unchanged (windup 0.065 s, wall impact 0.14 s, focus 0.32 s), so the pause at each
  wall now reads as a slightly smaller share of the loop.
- **Verified:** `tools/validate.sh` → OK, `test_movement` and `test_mutation_effects` pass.
- **Docs:** [player_dash.md](systems/player_dash.md) tuning line.

## 2026-09-20 — The stray fragments were in the source art; run HUD decluttered
- **Who:** Claude Code (Opus 5)
- **Owner report, with a phone screenshot:** a fragment of another animation still floats above the
  character's head in a run and in the Shop, the boss banner eats the top of the arena, and the run
  header is crowded.
- **The fragments are in the source pack, not the packing.** The gutter fix earlier today was right
  but it was fixing the wrong thing. Measured `wall_bottom_00.png` directly: content in rows 22–95,
  then a gap, then the character from row 125. The pack's frames are cut out of phase atlases and
  the cut takes a sliver of the neighbouring cell with it — a band of flame tips, severed flat.
  **39 of 108 frames** carry one.
- **Fixed in the intake, narrowly.** `strip_floating_strays` drops any connected piece lying wholly
  above the top of the largest piece. Tried and rejected first: "remove anything touching a frame
  edge" — it misses the real cases (the strays sit just *below* the edge) and 17 frames legitimately
  run off the canvas. The rule as shipped keeps the leaves this character scatters in `death` and
  `revive_spawn`, which is why it is phrased around the body rather than around the edge.
  152,810 source pixels removed across 8 states; `wall_bottom` alone was 62,298.
- **Verified by measurement, not eye:** at most 16 pixels of alpha ≤ 10 (4% opacity) survive above
  the body in any `wall_bottom` cell, and the re-rendered state board shows a clean silhouette.
- **The drift assertion was the wrong proxy** once the strays were gone: removing them changed the
  silhouette boxes and the blanket budget failed on a dissolving `death`. It now measures spread
  *within each looping animation* — where drift would actually read as jitter — instead of across
  the whole pack.
- **Run HUD, on owner request:** the character portrait ring is gone from the header (the character
  is already on screen a few hundred pixels below it), the boss readout is a line rather than a
  framed plate — **76 px tall, was 170** — and RUSH moved from the header stack to the bottom edge
  where the thumb already is. The header stack tightened by ~14 px on top of that. Net: the header
  now ends well clear of the playfield.
- **Files:** `tools/art/extract_playable_characters.py` (`strip_floating_strays`),
  `scenes/gameplay/game_world.{tscn,gd}` (HUD), `tools/godot/test_verdant_shade_visual.gd`.
- **Verified:** `tools/validate.sh` → OK; `test_verdant_shade_visual` passes; boss line and RUSH
  positions measured live in a real `GameWorld`.
- **Follow-up for the art pack:** `concept_art/verdant_shade_sprite_v1/build_sprite_pack.py` is
  cutting its frames with an offset that catches the neighbouring atlas cell. The intake now cleans
  up after it, but the pack should be fixed at source so the next character does not inherit it.
- **Not done, and it is an owner call:** "more room for the arena". The playfield size comes from
  `ARENA_FLOOR_UV` on the backdrop, and widening it scales `_player_radius` with it, which changes
  dash distances and enemy spacing — a gameplay change, not a layout one. The HUD decluttering
  above reveals more of the arena without touching the balance.

## 2026-09-20 — Verdant Shade, after the phone: atlas bleed, loop rate, Shop hitch
- **Who:** Claude Code (Opus 5)
- **Owner report from the phone:** "the cutouts are not perfect, sometimes the current playing
  animation frames has cutout from another", the first Shop open hitches, and the frames "are not
  that smooth, maybe make them loop faster".
- **The cutouts were a real packing bug, and mine.** The first sheets put cells edge to edge, and
  measurement confirmed the worst case: **0 px of transparent margin** — the art reached the cell
  boundary on some frames. The canvas texture filter samples half a texel outside an `AtlasTexture`
  region, so it was pulling pixels from the neighbouring frame and sticking them on the current one.
  Fixed by giving every cell an **8 px transparent gutter** (`CELL_PADDING`), verified by asserting
  the gutters contain zero art pixels. The character's silhouette renders clean now.
- **Loops play 1.4× faster** (`loop_fps_scale` in the pack spec): idle and the walls go 6.7 → 9.4
  fps, the storefront idle 6 → 8.4. One-shots are deliberately **not** scaled, because their rates
  are matched to `STATE_LENGTHS` and speeding them up would end them before their state does.
  This is a compromise, not a fix: a 12-frame loop is simply few frames, and the honest answer is
  more frames per loop. Recorded for the next art pass.
- **The Shop hitch was the menu sheet.** The first wake of a card uploaded a 3552 px square, and the
  device log showed `switch ShopScreen | build 524.4 ms`. The menu cell is 512 now rather than 576 —
  she draws at ~520 px on a card, so it is still about 1:1 — which takes the sheet to 3168² and
  about a fifth off the upload. Gutters cost a little back, hence 3168 rather than 3072.
- **Files:** `tools/art/extract_playable_characters.py` (`CELL_PADDING`, `loop_fps_scale`, padded
  packing), `scenes/player/visuals/verdant_shade_visual.gd` (`MENU_SCALE` 384/512),
  `tools/godot/test_verdant_shade_visual.gd` (asserts the scaled loop rates), `docs/ASSETS.md`.
- **Verified:** `tools/validate.sh` → OK, `test_verdant_shade_visual` passes, full suite
  **28 passed / 10 failed** (the ten documented M10-stale ones), Shop card re-rendered at full
  resolution and inspected for edge slivers — none. Rebuilt, installed and launched on the phone:
  clean boot, no errors.
- **Still open:** whether 1.4× reads better to the owner than the authored rate, and the sharpness
  trade at a 512 menu cell on a 1440p screen. Both are looks-at-it decisions.

## 2026-09-20 — Verdant Shade: the first character built whole-frame end to end
- **Who:** Claude Code (Opus 5)
- **Did:** added **Verdant Shade** (`verdant_shade`) as a playable whole-frame sprite character, to
  the contract written earlier today. No bone rig, no puppet: 16 real multi-frame animations on one
  `AnimatedSprite2D`. Roster is eight.
- **The art pack arrived exactly to spec**, which is worth recording because it is the first time:
  108 frames, 78 gameplay/wall at 512² and 30 storefront at 724², straight alpha with RGB zeroed
  under alpha 0, and a **content-box centre spread of 0.5 px across the whole pack**. Registration
  was the thing the contract said would decide it, and it needed no correction at all.
- **New intake, `SHEET_PACKS`.** Individual frames in, packed atlas sheets plus ready-made
  `SpriteFrames` out. Three sheets, chosen by the 4096 px texture floor and by what has to be
  resident together: `run` 2304×3456 (34 frames), `react` 3072×2304 (44), `menu` 3456×3456 (30),
  plus a standalone 384² portrait so a HUD icon never drags a whole sheet into memory. Cells are
  384 (gameplay) and 576 (menu) — smaller than delivered, because the character draws at ~230 px in
  a run and ~520 px on a card.
- **Two frame sets, never both.** `verdant_shade_gameplay.tres` and `verdant_shade_menu.tres` are
  loaded on demand, so a run never holds the storefront sheet and a menu never holds the run and
  react sheets. Verified by probe: a gameplay instance reports the gameplay set, a Shop card the
  menu set, and switching swaps rather than accumulates.
- **Lazy Shop cards, which §9c said had to land before this character.** Only the focused card and
  its neighbours are live; every other card shows its still portrait. Measured: **2 live previews
  across 8 cards** where it used to be 8 of 8. Two things fell out of it and were fixed — a
  single-image Wisp form must still count as live (it idles on the shared base rig), and a card
  that has just been bought or equipped has to be woken so it can play its flourish.
- **Decisions made, all recorded as placeholders in GDD §14 #35:** `STANDARD` tier and 0 RP, and
  the display name, all pending owner sign-off. Green `SOUL_FLARE` dash signature; its three tints
  were checked and sit 92–94° from the nearest reserved telegraph hue, against a 25° minimum.
- **`idle_hover` is only the pre-landing read.** A resting character is always against a wall, and
  the rig picks the nearest wall by alignment (the arena is a rounded polygon, so normals are rarely
  cardinal). The 12 idle frames therefore show during the spawn and as the portrait source.
- **Files:** `tools/art/extract_playable_characters.py` (`SHEET_PACKS`, `ingest_sheet_pack`,
  `_write_sprite_frames`), `scenes/player/visuals/verdant_shade_visual.{gd,tscn}`,
  `scenes/screens/shop_screen.gd` (lazy cards), `data/forms/{verdant_shade,default_catalog}.tres`,
  `data/characters/dash_effects/verdant_shade.tres`, `scripts/autoload/save_manager.gd`,
  `scripts/resources/form_catalog.gd`, `tools/godot/test_verdant_shade_visual.gd`,
  `render_verdant_shade_states.*`, and the two roster tests.
- **Verified by looking, not just by logs:** the 17-cell state board (every animation reached, none
  missing, right wall confirmed mirrored, `wall_top` hooks visible), the Shop card, Home, and a live
  run. A probe proved the wall counter-rotation exact — `body.global_rotation` is 0° on all four
  surfaces, so the screen-space frames stay upright to the player.
- **Follow-up, not invented:** she has **no separate ornament or VFX textures**, so her rig emits no
  particles; her wake is the painted flames plus the procedural dash signature. Borrowing another
  character's VFX was explicitly declined. Worth commissioning a small ornament set for her.

## 2026-09-20 — Roster cut to seven; Ilyra 2 promoted to Ilyra
- **Who:** Claude Code (Opus 5)
- **Owner decision:** sprite sheets beat rigs — *"they are more complex and require more thinking
  while sheet you just need to place them"*. Remove the bone-rigged Ilyra and Bram, keep the sprite
  Ilyra 2 under the name Ilyra, keep only the first and last Wisp forms. Recorded as GDD §14 #34.
- **Roster, thirteen → seven:** Void, Eclipse, Veyra, Rook, Morrow, Ilyra, Noxen. Retired: Ash,
  Venom, Bloodmoon, Frost (Wisp forms), Bram and the bone-rigged Ilyra. The four surviving rigs stay
  until they are re-cut as frames; the owner named only Ilyra and Bram, so nothing else was touched.
- **The promotion is a real rename, not an alias.** `ilyra_2` → `ilyra` across the form, the dash
  effect, the pose sheet, the visual scene and script (`Ilyra2Visual` → `IlyraVisual`), the art
  folder, the QA board and the test. The two dash effects were byte-identical, so the rig's
  `ilyra.tres` was simply kept.
- **Saves migrate without losing anything.** `RETIRED_FORM_IDS` maps `ilyra_2` → `ilyra`, mirroring
  the arena-skin mechanism that already existed, so anyone who owned the experiment owns Ilyra.
  Retired ids need no entry: `_sanitize_cosmetic` already drops an unknown id and falls the equipped
  slot back to Void.
- **Her particle textures changed.** They pointed at the rig's `vfx_star.png` / `vfx_streak.png`,
  which the deletion took with it. She uses her own previously-unused ornaments now —
  `sparkle_small.png` for the trail, `slash_arc.png` for the dash — which is better anyway: the
  pieces are hers rather than borrowed.
- **Also removed as a consequence:** `tools/art/make_rig_source.py` (both its characters were
  retired and Noxen ships as a per-file pack, so its table was empty), the Ilyra entries in
  `build_character_rig.py`, the Bram cell table in the extractor, `render_ilyra_grip_review.*`, and
  the four retired Wisp portraits. `REQUIRED_FORM_COUNT` 13 → 7.
- **A pre-existing bug found and cleared, not caused by this.** After the mass deletions the first
  boot logged `Parse Error` on `home_screen.tscn` and three Rift resources, always on a
  `script = ExtResource(...)` line. Every one of them loads fine with a direct `load()`, so it is
  the loading screen's threaded loader, not the data. Confirmed by building a worktree at HEAD and
  running it: **identical errors with none of these changes**. It only appears on the first boot
  after a cold `--import` and clears on the next run. Recorded in
  [game_flow.md](systems/game_flow.md) beside the other intermittent headless failure.
- **Files:** `data/forms/*`, `data/characters/*`, `scripts/autoload/save_manager.gd`,
  `scripts/resources/form_catalog.gd`, `scenes/player/visuals/ilyra_visual.*`,
  `scenes/debug/theme_gallery.gd`, the art tools, nine test scripts, and the docs below.
- **Docs:** GDD §14 #34 and the character row, PROJECT_CONTEXT status/registries,
  [forms.md](systems/forms.md), [playable_character_visuals.md](systems/playable_character_visuals.md)
  (the experiment section now records that it won), [ASSETS.md](ASSETS.md), and
  [character_rig_recipe.md](guides/character_rig_recipe.md), which is now marked maintenance-only.
- **Verified:** `tools/validate.sh` → OK; `test_form_catalog`, `test_ilyra_visual` pass; Shop card
  renders as ILYRA/MYTHIC with seven carousel dots.
- **Next:** the two engine changes in [character_sprite_frames.md](guides/character_sprite_frames.md)
  §9c before more frame art lands, then Ilyra's registered frame set.

## 2026-09-20 — The whole-frame character contract, and two numbers that change the plan
- **Who:** Claude Code (Opus 5)
- **Owner decision:** playable characters are whole-frame sprites, not bone rigs. Owner generates
  the frames; this session wrote what has to be generated.
- **Did:** [docs/guides/character_sprite_frames.md](guides/character_sprite_frames.md) — the
  generation contract. Every state with its frame count and fps derived from `STATE_LENGTHS`, the
  storefront set, wall poses, ornaments, what the engine already animates (so it is not drawn
  twice), what is procedural and needs no art at all, naming, sheet layout, and the budget. Linked
  from AGENTS.md §1 read order, the system doc header and the PROJECT_CONTEXT repo map.
- **Two measurements that changed the recommendation, both of which were assumptions until checked:**
  - **The character draws at ~230 px, not 627.** The playfield is inset, so `_player_radius` clamps
    at its 70 maximum and the rig draws `radius × 3.35` ≈ 235 design px. Confirmed on a real 1080 ×
    1920 gameplay render. Ilyra 2's 627 px pack is a 2.7× downscale of pixels nobody sees, so the
    contract delivers 512 and packs 384 — 38% of the pixels, no visible loss.
  - **The Shop, not the download, is the constraint.** `ShopScreen._build_cards()` instantiates
    *every* character card at once and each holds its whole `SpriteFrames`. A texture costs its full
    uncompressed size in VRAM whatever it cost on disk, so thirteen live cards at the recommended
    frame budget is 858 MB. Two engine changes are needed **before** seven characters of art exist:
    split each character's frames into a menu resource and a gameplay resource, and build cards
    lazily. Written up as §9c; not implemented yet.
- **Sheet layout:** owner asked for one sheet per character. It does not fit — 98 cells at 627 px is
  7524 × 8151 and Vulkan only guarantees 4096². Three sheets per character at 384 px cells
  (`_run`, `_react`, `_menu`), one row per animation with a ragged right edge, and the split is
  exactly the load split §9c needs anyway. Frames are still generated individually and packed by
  `extract_playable_characters.py`: no image model makes 78 consistent frames in one canvas, a bad
  frame should be re-rollable alone, and packing is where the anchor gets measured instead of trusted.
- **Verified:** project map regenerated and clean; no code changed.
- **Next:** the two engine changes in §9c, then the packer, then the first character's frames.

## 2026-09-20 — Ilyra 2's jointed menu puppet: built, then reverted by the owner
- **Who:** Claude Code (Opus 5)
- **Context:** the open question from the entry below — she holds still where Morrow moves. Built
  the jointed menu body the parts were extracted for, then the owner stopped it mid-review:
  *"codex will generate the frame posses you will implement"*. Everything below is reverted; the
  menus are back to the held `storefront_welcome` painting. Written down so nobody builds it twice.
- **What was built and worked.** `Ilyra2MenuPuppet`, a 12-joint Node2D chain generated from the
  extracted parts by `tools/art/build_ilyra_2_puppet.py`, swapped in for the painting whenever the
  rig is in preview mode, every joint on its own sine so no two frames matched. It rendered
  correctly on both the Shop card and Home.
- **Four things it cost, all worth knowing:**
  - **Hand-authored joint angles do not converge.** Three rounds of eyeballed shoulder/elbow/wrist
    angles put her fists behind her head. What fixed it in one pass was authoring the *wrist
    position* — the one thing readable off the painting — and solving the two angles from the
    limbs' own measured lengths. Author endpoints, solve joints.
  - **Measure before laying out.** The first table was eyeballed and put her chin on her waist. The
    fix was to measure every part's pixel size and hang each from a landmark taken as a fraction of
    figure height from `storefront_welcome.png`.
  - **She has two arms, not four.** `upper_arm_02/03` + `hand_relaxed_*` are a *relaxed alternate*
    for the same pair, not a second pair. Building all four made her a four-armed idol.
  - **The kit ships one closed fist.** `hand_grip_b` is an open hand despite the name; her left fist
    had to be `hand_grip_a` mirrored. Now recorded in [ASSETS.md](ASSETS.md).
- **Also fixed, and it was a real bug:** a Shop card is configured *before* it is added to the tree,
  so `set_preview_mode` landed ahead of `_ready` and anything that touched a child node was silently
  dropped. Harmless for the painted rig (`_ready` re-settles the pose anyway), which is why it had
  never shown; it is a trap for any future rig that owns child state.
- **Files:** reverted `scenes/player/visuals/ilyra_2_visual.{gd,tscn}`; deleted
  `ilyra_2_menu_puppet.{gd,tscn}`, `tools/art/build_ilyra_2_puppet.py`,
  `tools/godot/render_ilyra_2_puppet.*`. **Kept** the extracted parts under
  `assets/art/characters/playable/ilyra_2/puppet/` and their `PUPPET_PACKS` intake — nothing loads
  them, and they are the material if part-level motion is ever revisited. Say the word to delete.
- **Docs:** [ASSETS.md](ASSETS.md) gains the puppet pack row, the fist gap, and
  **"Commissioning an animation loop as whole frames"** — the registration rules any new frame set
  must meet (one canvas, one anchor pixel, small deltas, ≥12 frames, closed loop). That section is
  the brief for the frames Codex is generating next.
- **Verified:** `tools/validate.sh` → OK, `test_ilyra_2_visual` passes, and the re-rendered Shop card
  shows the painted frame again.
- **Next:** implement Codex's frame set against the rules in that ASSETS.md section.

## 2026-09-19 — Ilyra 2's menu idle stops flip-booking
- **Who:** Claude Code (Opus 5)
- **Owner report from the phone:** the game runs fine, but her Home and Shop animation "is not
  smooth" next to the other characters.
- **Diagnosed by looking, as asked.** Captured 130 frames of the Shop card for Morrow and for Ilyra 2
  and tiled every eighth frame side by side (`logs/menu/<id>/`). Morrow is *one* drawing whose parts
  move — hood tilts, hands orbit, runes drift, cloak hem breathes — so his silhouette is stable and
  the motion is continuous. Ilyra 2 was cutting between four *different* whole paintings, so her
  arms, fans and silhouette all jumped at each swap and nothing moved in between. That is a
  flip-book, and no amount of timing fixes it.
- **Did:** her menu rest is one painting held steady now (`MENU_REST`), not a four-frame loop. The
  motion comes from the shared body breath and her drifting ornament ring, which is the same read
  Morrow has. The flourish stays as a reaction to a pick or a purchase, where a cut is intended.
- **Files/systems:** `scenes/player/visuals/ilyra_2_visual.gd`, `tools/godot/test_ilyra_2_visual.gd`
  (now asserts the rest pose is *held*, not cycled), `tools/godot/render_ilyra_2_poses.gd`.
- **Verified:** `tools/validate.sh` → OK, `test_ilyra_2_visual` passes, and the re-captured strip
  shows no silhouette jump.
- **Still open, and it needs a decision.** The cut is gone but she is now a still illustration with
  sparkles, where Morrow is a moving character. Matching him means giving her a real rig. The art
  for it exists and is good: `concept_art/ilyra_2_sprite_test/detached_parts/` holds a 30-part
  puppet — head, armoured torso, four upper arms, four forearms, six hands, waist, hip flaps, two
  thighs, two boots, underskirt — drawn to one scale with **gold joint caps at every shoulder, elbow
  and wrist**, which is exactly the design that stops cutouts gapping (the seam problem that forced
  Ilyra v1 onto skinned meshes). Two caveats found while checking: the parts correspond to **no**
  existing pose — template-matching them against `storefront_settle.png` scores 0.18–0.27 against
  0.6–0.7 for a real match — so every joint has to be placed by hand, and `waist_armor` already has
  the skirt panels painted in, so the seven separate `skirt_panel` pieces would double up unless the
  waist is used bare. That is the "add an animated character" job in
  [the recipe](guides/character_rig_recipe.md), not a tweak.

## 2026-09-19 — Ilyra 2 performs in the menus and carries her own ornaments
- **Who:** Claude Code (Opus 5)
- **Did (owner request, from the reference sheet):** Codex had already cut the sheet into a 46-part
  puppet kit plus a four-frame storefront loop under
  `concept_art/ilyra_2_sprite_test/detached_parts/`, so this brought the useful half of it into the
  game through the deterministic pipeline rather than re-cutting anything.
  - **Her ornaments drift around her.** `CharacterAura` takes several pictures now instead of one,
    so her ring is six of her own loose pieces — two sparkle sizes, a sparkle pair and three crown
    shards — rather than a repeated generic star. Fourteen of them, on a wider orbit, sized to read
    at gameplay scale. The ring sits outside `%MotionRoot`, so it keeps turning while she is idle,
    drifting along an edge and hanging off a wall, exactly as asked.
  - **She performs in the menus.** Home and the Shop card play her own welcome → blink → settle
    loop, and **picking or buying her card throws the fan flourish** — the attack in the storefront.
    Those frames are a 600×724 canvas of their own, drawn at 627/724 so she stands the same height
    as she does in a run.
  - Two pipeline intakes for it: `ORNAMENT_PACKS` (which also zeroes the RGB under alpha 0 the QC
    found on all 46 parts, so `fix_alpha_border` has nothing stale to bleed) and `FRAME_PACKS`.
- **Two things the kit got wrong, corrected on the way in:** `dash_slash.png` is a pair of small
  sparkles and `sparkle_pair.png` is the big slash arc — the names are swapped, so the intake renames
  them rather than carrying the mistake into the game.
- **A consequence worth stating:** with the storefront loop owning menus and the wall poses owning a
  live character's rest, `idle_hover.png` is no longer reachable as a *pose* — it is her portrait
  and nothing else — and `idle_blink.png` is superseded by `storefront_blink`. The blink machinery
  she had is gone rather than left dead.
- **Files/systems:** `scenes/player/visuals/character_aura.gd` (+`mote_textures`),
  `ilyra_2_visual.{gd,tscn}`, `tools/art/extract_playable_characters.py`,
  `assets/art/characters/playable/ilyra_2/{ornaments,storefront}/`,
  `tools/godot/{test_ilyra_2_visual,render_ilyra_2_poses}.gd`, ASSETS.md, the playable-character
  system doc.
- **Verified:** `tools/validate.sh` → OK; `test_ilyra_2_visual` passes with new coverage for the menu
  loop, the flourish on both menu events, the menu scale, and Reduced Motion holding one menu frame.
  Re-rendered the pose board: **23 of 23 cells** reach their painting, storefront frames included.
- **Caught by a probe, not by eye:** the ring silently rendered *nothing* for a while because I put a
  `#` comment inside the `.tscn` node block. A `.tscn` has no comments — the parser stops reading
  properties at that line and the node loads with defaults, so `mote_textures`, `mote_count` and
  everything below it were dropped. A one-line probe printing each mote's texture found it; the Home
  screenshot had not, because the background has its own floating lights. Recorded in AGENTS.md §5
  beside the `ext_resource` id rule.
- **Follow-ups:** at gameplay size the ring reads as a faint shimmer rather than as ornaments —
  proportionally correct, but it wants a look on the phone before the sizes are signed off. The
  36 puppet parts (head, torso, four arms, hands, legs, fans, braids, skirt panels) are extracted
  and unused: they are the material for a fully rigged Ilyra 2, which is a much bigger job than this
  and should be its own decision.

## 2026-09-19 — Per-character dash signatures, and the build on the phone
- **Who:** Claude Code (Opus 5)
- **On the phone first, as asked:** exported the Android debug APK from Windows (`JAVA_HOME` =
  Android Studio's JBR 21, Godot 4.7.2 at `D:/Godot_v4.7.2-stable_win64.exe/`), installed and
  launched it on the connected Galaxy S24. Clean boot, no errors: Vulkan **Forward Mobile** on a
  Samsung Xclipse 940, `physics=120 Hz` (FramePacing matched the panel), audio synthesised in
  1.33 s, Home up in 1.30 s. Morrow's new aura motes are visible drifting around him on Home. The
  Windows recipe is worth recording — AGENTS.md §4 only has the macOS one.
- **Did:** each of the twelve characters now has its own dash *effect*, not a purchasable recolour.
  `DashEffectData` carries a `Signature` (RIBBON, BLADE_ARC, TWIN_ARC, DUST_WAKE, RUNE_WAKE,
  SOUL_FLARE), three tints, a spark count and ribbon numbers; `DashEffectFx` draws it from six
  `Line2D` ribbons and three `CPUParticles2D` emitters, all on `VfxPool`'s one shared additive
  material. No new art, no shader. Bram cuts once, long and thin; Ilyra and Ilyra 2 lay two bowed
  ribbons, one per fan, and turn the shared launch flash down to 0.45 so it does not stack; Rook
  sheds a broad dust fan; Morrow's sparks lag and tumble; Veyra and the Wisp forms flare radially.
- **Designed against a survey, not a guess.** Six parallel readers mapped the dash path end to end
  and a completeness critic then audited the result *and* the code I had already landed. It caught
  five real defects, which is why they are not in this commit: a `Line2D` ignores `default_color`
  once it has a gradient, so **every ribbon was rendering white** and the whole per-character point
  was being dropped; nine separate `CanvasItemMaterial`s were breaking 2D batching; `z_index = 3`
  drew the signature over every pooled trail instead of at the VFX pool's absolute 0; the effect
  only played on wall impact, so a four-redirect chain left one streak covering the final leg; and
  `setup(_vfx)` injected a pool that was never read.
- **Files/systems:** `scripts/resources/dash_effect_data.gd`, `scenes/gameplay/dash_effect_fx.gd`,
  `data/characters/dash_effects/*.tres` (12), `scripts/resources/form_data.gd` (+`dash_effect`,
  validated), `data/forms/*.tres` (12 linked), `scenes/gameplay/game_world.gd`,
  `tools/godot/test_dash_effects.gd` (new), player_dash / shop / forms system docs,
  PROJECT_CONTEXT §5.2 and §5.8.
- **Verified:** `tools/validate.sh` → OK. `test_dash_effects` covers the gap the critic named — that
  the feature could ship inert — by asserting every character *has* an effect whose id matches, that
  its tints clear the reserved hues, that the pool is a sibling of `EffectsLayer` at absolute z 0 on
  one shared material, that a dash driven through the real controller leaves a ribbon **in that
  character's colour**, that a twin-arc character draws two and others one, that a redirected leg
  gets its own ribbon, and that Reduced Motion throws no sparks but still draws. Rendered Ilyra 2's
  twin arc and Bram's blade arc in a live arena; they read as two different weapons.
- **Decisions taken while the owner was away** (all reversible, all recorded here): `DashStyleData`
  stays as the fallback rather than being retired (no save change); a redirect gets the same
  signature as a launch rather than a cheaper variant; one recipe with twelve tunings rather than
  twelve bespoke systems; Ilyra and Veyra get non-particle signatures because their rigs have 4 and
  8 particles of headroom; the reserved-hue rule is enforced on the new field only. That rule
  immediately caught Ash and Eclipse — both amber characters — so Ash's dash is pale ash rather than
  flame, which suits the name better anyway.
- **Follow-ups:** the ribbon is authored and reviewed on Forward Plus (desktop) but the phone runs
  Forward Mobile, and nothing in `project.godot` pins either — worth a look on device before the
  look is signed off. The existing streak glow, RUSH aura and pooled trails still play at full under
  Reduced Motion (only the new signature and the speed lines are gated); changing that is a call on
  shipped feel, not a quiet correction.

## 2026-09-19 — Holding the aim arrow no longer changes the character at all
- **Who:** Claude Code (Opus 5)
- **Did:** The first attempt at this only flattened the shared body coil inside `aim_charge`, which
  missed the point — the controller still *asked* for a different state the moment the arrow went
  up, so the character still swapped pose, ran its rig's aim gesture and leaned toward the aim.
  `WispPlayer._get_character_visual_state()` now answers `idle_hover` (or `move_fly` on a drifting
  edge) while `State.AIMING`, so holding a finger down changes nothing: the character keeps resting
  against its wall and the arrow is the only thing that appears. `AIM_CHARGE` stays in the
  vocabulary — the rigs, the menus and the QA boards still reach it — but nothing in a run does.
- **Files/systems:** `scenes/player/wisp_player.gd`, playable-character and player-dash system docs.
- **Verified:** Re-ran the motion fixture, which performs a real press-and-hold: every frame of the
  aim now logs `state=AIMING visual=idle_hover` with `heading=-0.000` unchanged across the
  WAITING_AT_EDGE → AIMING transition, and `aim_charge` never appears in the run at all.
  `tools/validate.sh` → OK; `test_ilyra_2_visual`, `test_playable_character_visual`, `test_movement`,
  `test_gameplay_slice` and `test_game_flow` pass.
- **Also fixed:** every file edited through Python this session had been rewritten with CRLF, which
  `.gitattributes` forbids (`* text=auto eol=lf`). All 46 are back to LF, and the pose-sheet writer
  in `extract_playable_characters.py` now passes `newline="
"` so a Windows run cannot reintroduce
  it.

## 2026-09-19 — No more aim coil, and every character carries a ring of lights
- **Who:** Claude Code (Opus 5)
- **Did (owner request):**
  - **The pre-attack coil is gone.** Holding the aim arrow used to wind the whole body back along
    its own axis, shiver and squash it to 1.16/0.85; the owner found it unnatural. `aim_charge` is
    the resting breath now, so a character standing on a wall keeps standing on it and only leans
    toward the aim. Wall and landing animations are untouched. Each rig's own limb gestures while
    aiming (Rook's wings, Morrow's runes, Ilyra's fans) still play — say the word and those go too.
  - **`CharacterAura`**: a reusable ring of lights built in code, no new art. Each mote runs its own
    ellipse at its own speed and phase, dips behind the body on the far half of the orbit and passes
    in front on the near half, and stretches along the travel axis during a dash. It hangs beside
    `%MotionRoot` rather than inside it, so the body's squash and dash heading never drag it around,
    and `PlayableCharacterVisual` steps it, stills it for Reduced Motion and leaves it out of
    `get_layer_bounds()` so no rig's `design_size` contract moves.
  - Wired to **Ilyra 2** (12 star motes — she is a painted pose with no limbs of her own, so the
    ring is what keeps her alive between swaps), **Veyra** (7 soul sparks), **Rook** (7 wing dust),
    **Morrow** (6 rune fragments) and **Bram** (6 pale streaks), each in its own colour.
- **Files/systems:** `scenes/player/visuals/character_aura.gd` (new),
  `playable_character_visual.gd`, `{veyra,rook,morrow,bram,ilyra_2}_visual.tscn`,
  `tools/godot/test_ilyra_2_visual.gd`, AGENTS.md §5, the playable-character system doc.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`; `test_playable_character_visual` and
  `test_ilyra_2_visual` pass, the latter now also checking that the aura has motes, sits outside
  `%MotionRoot`, drifts, and stops dead for Reduced Motion. Rendered Home, the arena and the
  six-character lineup.
- **Cost a while, worth writing down:** adding the aura broke the boot with `Parse Error` on
  *unrelated* lines of *other* scenes, and the victim changed between runs. The cause was the
  `ext_resource` ids I generated (`aura_rook`): Godot always writes `<number>_<name>` and its text
  loader depends on that prefix. Renumbering them fixed it. Now in AGENTS.md §5.
- **Follow-ups:** The rigged **Ilyra** has no aura — her scene is generated by
  `build_character_rig.py` (a hand edit would be lost) and has uncommitted work on it, so adding
  hers means teaching the generator. The Shop's CHARACTERS tab now builds up to 38 extra mote
  sprites across its cards; `bench_character_previews.gd` has not been re-run since.

## 2026-09-19 — One life, Soul Vessel drops, and the DASHES tab removed
- **Who:** Claude Code (Opus 5)
- **Did (owner request):**
  - **Shop is three tabs.** DASHES is gone — a dash is going to belong to its character, not be a
    separate purchase. The tab, its cards, the animated trail/burst preview and the Shop's whole
    dash-style path are removed; the `DashStyleData` system, the save fields and the run-time trail
    tint stay untouched underneath, so nothing about how a dash looks in play changed yet.
  - **A run starts on one Soul Fragment and death is final.** `maximum_health` 3 → 1. There was
    never a revive to remove: `MonetisationService.PLACEMENT_REVIVE` is plumbing with no UI and
    stays that way until the rewarded-ad flow is built.
  - **SOUL VESSEL left the upgrade tray and became a rare floor drop.** A killed enemy has a
    `soul_vessel_drop_chance` (0.012) of dropping a `SoulVesselPickup`: +1 maximum fragment, filled,
    **with no cap** — three collected is four fragments. It is a `SoulShardPickup` subclass, so it
    attracts, sweeps and expires exactly like a Rift Points shard and a wave change never strands
    one. The tray is seven cards now; a card capped at three levels could not express an uncapped
    count, which is why the effect moved rather than being duplicated.
- **Files/systems:** `scenes/screens/shop_screen.{gd,tscn}`, `scenes/pickups/soul_vessel_pickup.{gd,tscn}`,
  `scenes/pickups/soul_shard_pickup.gd` (its canvas size is an export now, so a pickup drawn on a
  444 px icon is the same size on screen), `scenes/gameplay/game_world.gd`,
  `scripts/resources/{player_tuning,run_progression_tuning}.gd`, `scripts/components/run_progression.gd`,
  `data/player/default_player_tuning.tres`, `data/progression/default_run_progression.tres`,
  **deleted** `data/mutations/soul_vessel.tres`, `tools/godot/{render_devlog_tour,qa_capture}.gd`,
  GDD §5.3, shop / mutations / player_health system docs, PROJECT_CONTEXT §5.2/§5.8/glossary.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. Rendered the Shop: three tabs (CHARACTERS,
  ARENAS, NO ADS) laid out correctly. Four tests assumed the old three-fragment start and were
  fixed rather than weakened — `test_movement`, `test_playable_character_visual` and
  `test_ilyra_2_visual` now stock fragments before the beats that need a *survivable* hit (they test
  input buffering and hurt poses, not the health economy), and `test_player_health_flow` asserts the
  new one-fragment start before climbing to three for its i-frame/death/summary ladder.
  `test_mutation_effects` now drops three real Soul Vessels and checks the maximum passes three.
- **Follow-ups:** **Per-character dash effects are not built yet** — this change only removed the
  tab. Proposed next: a `DashEffect` resource per character driving GPUParticles2D shape/gradient,
  an optional Line2D slash ribbon, character afterimages and an optional `.gdshader` pass, authored
  in Godot with no new art. `soul_vessel_drop_chance = 0.012` (~1 per 83 kills) is a first guess and
  needs a device pass together with the one-life difficulty; the vessel reuses the old upgrade icon
  and the shard chime pitched down, so it could use art and a sound of its own.

## 2026-09-19 — Ilyra 2 integrated as an experimental sprite character
- **Who:** Claude Code (Opus 5)
- **Did:** Wired Codex's reviewed `ilyra_2` pack into the game **beside** the rigged Ilyra, which is
  untouched. One painting per state on a single `AnimatedSprite2D` under `%MotionRoot`; the shared
  base still owns the state machine, heading, alpha, squash, bounce and the no-collision contract.
  Extended the art pipeline with a `POSE_PACKS` intake that copies the 20 approved PNGs **byte for
  byte** and measures each silhouette into a generated `CharacterPoseSheet`. The dash is the attack
  (the contact accent holds `dash_loop_01_attack`); the four wall paintings are picked from the
  inward `surface_normal` and the base's wall rotation is cancelled again for them, eased so a
  ceiling landing does not spin the picture in one frame; Reduced Motion freezes cycling, blinking
  and particles but keeps the pose and the wall. Registered as form `ilyra_2` / `ILYRA 2`, Mythic,
  0 RP, catalog 11 → 12, obtainable only through the normal free Shop flow (no save was mutated).
- **Inspected the pack first (all 20 usable):** correct four-arm anatomy, clean straight alpha, one
  identity, all 627×627. Defects found and accepted: eight paintings clip a boot toe or crown tip at
  the canvas edge (`victory` worst, 143 px of the crown), and `wall_top` is drawn at 0.84 inside
  extra padding — corrected with a per-pose ×1.19.
- **Anchoring, measured not assumed:** head template matching across the pack put every pose within
  ±5 % of one scale except `wall_top`. Centring each pose's opaque bounding box was tried, rendered
  as pair overlays, and **rejected** — that box moves with the pose, so it lifted the crouches off
  their footing. The pack is framed from one camera, so all offsets are zero; each pose's measured
  drift is recorded in the sheet for review.
- **Files/systems:** `scenes/player/visuals/ilyra_2_visual.{gd,tscn}`,
  `scripts/resources/character_pose_sheet.gd`, `data/characters/ilyra_2_poses.tres`,
  `data/forms/ilyra_2.tres` + catalog, `FormCatalog.REQUIRED_FORM_COUNT`,
  `SaveManagerService.VALID_FORM_IDS`, `tools/art/extract_playable_characters.py`,
  `tools/godot/test_ilyra_2_visual.gd`, `tools/godot/render_ilyra_2_poses.{gd,tscn}`,
  `assets/art/characters/playable/ilyra_2/`, playable-character system doc, rig recipe §1c,
  ASSETS.md, PROJECT_CONTEXT §2/§5.1/§5.2/§5.8/§6.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK`. `tools/run_tests.sh` → **26 passed, 10 failed**;
  all ten failures are the pre-existing M10-stale tests (missing `forms_screen.tscn`,
  `purchase_form`, `configure_run_profile`, an `is_unlocked()` signature) and none touch this change
  — `test_ilyra_2_visual`, `test_playable_character_visual` (she is in its `RIGGED` list now) and
  `test_form_catalog` all pass. Rendered and read the 21-cell pose board
  (`render_ilyra_2_poses.tscn`), the gameplay showcase and the six `motion_contact_sheet` windows:
  the dash-as-attack sequence, both wall landings and the flourishes all read correctly.
- **Follow-ups:** Owner verdict — keep, promote to production art (then GDD/ADR, a price and the
  clipped crowns and boot toes re-generated) or delete. **Not verified on a phone: no device was
  attached to this machine** (`adb devices` empty), so readability at gameplay size is still open —
  the desktop capture already suggests a painted figure loses detail at ~150 px. The Godot MCP
  server could not be used either: `.mcp.json` holds macOS paths, so the game was driven through the
  Windows Godot binary directly instead.

## 2026-09-19 — Ilyra 2 whole-pose sprite experiment
- **Who:** Codex (GPT-5)
- **Did:** Left the existing procedural/skinned Ilyra untouched and generated a separate source-only
  Ilyra 2 experiment: five transparent 2×2 pose sheets covering all thirteen visual states, a
  four-frame dash-as-attack sequence, four distinct screen-oriented arena-surface holds, reactions
  and menu flourishes. Split them into twenty equal-canvas sprites, removed neighboring-cell edge
  debris, regenerated the bottom hold with its missing fourth arm and the ceiling hold with complete
  padded fists, and wrote the state manifest, final prompt set and ready-to-paste Claude integration
  brief. No catalog, save, scene, script or runtime asset was added.
- **Files/systems:** `concept_art/ilyra_2_sprite_test/`; `docs/ASSETS.md`; generated project map.
- **Verified:** 20/20 proposed final PNGs are 627×627 RGBA with alpha extrema 0–255; reviewed the
  complete final contact sheet and individual dash/top/left/bottom poses; 99 scripts parsed with
  0 failures; generated project map current; `git diff --check` clean. `tools/validate.sh` cannot
  run on this Windows host because WSL has no `/bin/bash`; its script-parse/map checks were run
  directly instead.
- **Follow-ups:** Owner reviews the pose board. If approved, give Claude
  `concept_art/ilyra_2_sprite_test/CLAUDE_IMPLEMENTATION_PROMPT.md`; integration must preserve the
  current Ilyra and normalise each pose's opaque bounds around one stable collision-centre anchor.

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
