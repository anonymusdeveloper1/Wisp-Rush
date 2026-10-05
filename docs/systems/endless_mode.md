# System: Endless mode

> **Status:** ✅ three painted arenas, the Quarry Titan (2026-09-23; the thirty generated skins were removed), the Stitched Doll Jungle and the Chained Colossus (2026-09-30, each its own floor), one layered arena, Stitchwarden's Vigil (2026-09-30), one 3D arena, the Chained Colossus 3D (2026-09-30, ADR-0023), the 3D ZOOM ARENA test slot, which opens with a zoom (2026-10-01), two board slots, BOARD 01 and BOARD 01 LIGHT, the full-screen pixel-art board with the HUD in its frame (2026-10-02, ADR-0024), and SIMULATION, the sci-fi board with the meters in its screen and its own spawn effects (2026-10-04, ADR-0025) · the Quarry Titan's 1080×2400 re-delivery and a device pass pending · **Last updated:** 2026-10-04 · **GDD section:** §6, §7, §11 ·
> **ADR:** [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [0017](../decisions/0017-painted-arenas-with-bleed.md) (supersedes [0014](../decisions/0014-endless-arenas-share-one-floor-template.md)),
> [0020](../decisions/0020-an-arena-may-bring-its-own-floor.md), [0021](../decisions/0021-layered-arenas.md),
> [0023](../decisions/0023-3d-arenas.md), [0024](../decisions/0024-board-arenas.md),
> [0025](../decisions/0025-sci-fi-board-and-arena-spawn-effects.md) ·
> **Guide:** [arena_art.md](../guides/arena_art.md) — the arena image contract · **Specs:** [03](../specs/story_and_endless/03_endless_mode.md)

## Purpose
The never-ending mode: arenas picked in the Shop over one shared floor (or an arena's own, ADR-0020), the Enemies v2 enemies on the
run's ramp ([wave_director.md](wave_director.md)), bosses from a pool, and the best score and wave to
chase. The daily run uses its rules. (The five enemy mixes came from the story Rifts, removed on
2026-09-25; since Enemies v2, 2026-09-28, they no longer change the enemies and only carry the old
bosses into the pool.)

## Files
| Path | Role |
|---|---|
| `res://scripts/resources/endless_catalog.gd` | `EndlessCatalog`: the shared floor (`floor_rect`, `floor_polygon`), arenas, default arena, tuning, the rosters (`rosters`) that carry the boss pool, validation |
| `res://scripts/resources/endless_roster.gd` | `EndlessRoster`: one boss-pool entry — id, the old mix's name, `boss_id` (its `enemy_substitutions` went with Enemies v2) |
| `res://data/endless/rosters/<id>.tres` | The five rosters (old mixes), in pick order: `obsidian_garden`, `shattered_rift`, `ember_hollow`, `frozen_choir`, `reapers_court` |
| `res://scripts/resources/arena_skin_data.gd` | `ArenaSkinData`: one arena — background path, thumbnail, price, its own floor when it has one (ADR-0020), a layered or 3D arena's scene path (ADR-0021, ADR-0023) |
| `res://scripts/resources/endless_tuning.gd` | `EndlessTuning`: boss cadence, per-cycle threat and speed, daily pool, the opening boss |
| `res://data/endless/default_endless_catalog.tres` · `default_endless_tuning.tres` | The catalog and tuning instances |
| `res://data/endless/skins/<id>.tres` | One `ArenaSkinData` per arena (hand-authored): `quarry_titan`, `stitched_doll_jungle`, `stitchwarden_vigil`, `chained_colossus`, `chained_colossus_3d`, `zoom_arena_3d`, `board_01`, `board_01_light`, `sci_fi_simulation_v1` |
| `res://assets/art/environment/arenas/<id>.png` · `thumbnails/<id>.png` | Runtime background (loaded only when a run or a near Shop card needs it) and the 0.3× Shop thumbnail, from `tools/art/make_arena.py` |
| `concept_art/arenas_v2/<id>/` | Source image and `arena.json` (name, description, measured `floor_rect_px`); `_layout/arena_layout_guide.png` is the contract drawn out |
| `tools/art/make_arena.py` | Source → background + thumbnail, prints the floor in UV; `--guide` draws the layout guide |
| `res://scenes/arenas/arena_visual.gd` | `ArenaVisual`: the scene GameWorld shows for an arena that is not a painting (ADR-0023) — `fit()` returns the drawn floor; focus point and Reduced Motion |
| `res://scenes/arenas/layered_arena_visual.gd` | `LayeredArenaVisual`: a layered arena's scene root (ADR-0021) — `fit()` covers the screen with its backdrop, scales its centre group and returns the drawn floor |
| `res://scenes/arenas/model_arena_visual.gd` · `res://scripts/resources/model_arena_layout.gd` | `ModelArenaVisual`: a 3D arena's scene root (ADR-0023) — a SubViewport 3D world, the camera placed so the model's floor is the returned rectangle, the head bone's breathing; `ModelArenaLayout`: the model's measured floor, eye, flame and skull points |
| `res://scenes/arenas/board_arena_visual.gd` · `board_01.tscn` · `board_01_light.tscn` | `BoardArenaVisual` (ADR-0024): the full-screen board built from its pieces at run time, the HUD drawn in its frame (`set_board_hud`, `hud_pause_pressed`); the two slots differ only by `light_floor` |
| `res://scenes/arenas/sci_fi_board_visual.gd` · `sci_fi_simulation_v1.tscn` | `SciFiBoardVisual` (ADR-0025): the sci-fi board built from its kit as the kit's manifest lays it out, the HUD in its frame, the magenta boss and amber RUSH meters in its screen, and the enemy-arrival and boss-appearance effects clipped to its floor |
| `res://scenes/gameplay/upgrade_glow.gd` | `UpgradeGlow`: the light on the character while upgrades are ready on a board; tap him to open them |
| `tools/art/make_board.py` | Copies a board's pieces from `concept_art/boards_v1/<board>/` (checked against its manifest) to `assets/art/environment/boards/<board>/` |
| `res://scenes/arenas/zoom_arena_3d.tscn` | The 3D ZOOM ARENA (2026-10-01): the Chained Colossus 3D scene with `zoom_intro` on |
| `res://scenes/arenas/chained_colossus_3d.tscn` · `.gd` | The Chained Colossus 3D: the owner's model, and in Godot the night sky and moon, cloud banks, two arches, floating shards, blue ghost fire, glowing skulls and the eye's glow |
| `res://assets/shaders/arena_3d_common.gdshaderinc` · `arena_night_sky` · `arena_cloud_bank` · `ghost_flame` · `ghost_skull` · `ghost_glow` | A 3D arena's noise, billboard and floor mask; its sky, clouds, fire, skulls and glow |
| `concept_art/arenas_v2/chained_colossus_3d/build_colossus.py` | The owner's `.blend` → the rigged, lighter GLB and its `ModelArenaLayout` (Blender, headless) |
| `tools/godot/render_arena_still.gd` | Renders an arena scene to its Shop still and prints the floor drawn there |
| `res://scenes/arenas/stitchwarden_vigil.tscn` · `.gd` | Stitchwarden's Vigil: the generated scene and its motion (hood and face on one pivot, responding cloth, flame, lanterns, wisps, bats, fog) |
| `res://assets/shaders/cloth_wave.gdshader` · `lantern_flicker.gdshader` · `arena_fire_wave.gdshader` · `arena_hood_follow.gdshader` · `arena_frame_tilt.gdshader` | Cloth wave and turn response, lantern flicker, scythe fire motion, split hood/body rendering and decorative frame taper on the Vigil's pixel grid |
| `concept_art/arenas_v2/stitchwarden_vigil/pack_vigil.py` | Revised `source_v2/` art plus retained cloth and effects → the Vigil's pieces, scene, Shop still, thumbnail, `arena.json` and `review/`; the original `stitched_doll_pixel_kit/` is retained |
| `res://scenes/gameplay/arena_rules.gd` | `ArenaRules`: the seam GameWorld reads (backdrop, floor polygon, floor rect, boss cadence/id, threat, speed); the base class is the neutral arena of fixtures and F6 runs |
| `res://scenes/gameplay/endless_arena_rules.gd` | `EndlessArenaRules`: the catalog floor, the arena, seeded roster/boss picks with no immediate repeat, per-cycle tuning |
| `res://scripts/resources/arena_scenery_data.gd` · `arena_scenery_zone.gd` · `arena_particle_emitter.gd` · `res://scenes/gameplay/arena_ambience.gd` · `res://assets/shaders/arena_scenery*.gdshader` | Animated scenery over an arena's painting — **no arena uses it since 2026-09-23** (see Rules) |
| `tools/godot/test_endless_enemies.gd` | Stale since 2026-09-28: it checks the removed Rift enemies and mixes |
| `tools/godot/test_endless_catalog.gd` | Catalog validation, arena ids vs save ids, each arena's measured floor vs the floor the game uses for it (shared or its own), arena scenes (scene loads, floor on screen at four portrait sizes; the Vigil's smaller than the jungle's on 1080 × 2340; the Colossus 3D's a little bigger than the Vigil's on 1080-wide phones; the zoom arena has its opening shot, a skipped one ends on the play floor, and its zoomed-in floor is bigger than the Colossus 3D's; only the three boards draw the HUD), backgrounds and thumbnails, arena of the day, rules' floor, sanitizing saves that held retired arenas |
| `tools/godot/render_arena_tab.*` | The Shop ARENAS pager, for review |
| `tools/godot/test_endless_mode.gd` | Behaviour checks (**not written yet**) |

## Public API
| Member | Kind | Description |
|---|---|---|
| `EndlessCatalog.get_rosters()` | method | Every roster, in pick order (they carry the boss pool). |
| `EndlessCatalog.get_rosters_by_id(ids)` | method | The rosters with these ids, in the given order (the daily pool). |
| `EndlessCatalog.get_boss_ids()` | method | Every roster's boss, in pick order, no repeats. |
| `EndlessCatalog.get_skin(skin_id)` | method | The arena, or the default when unknown. |
| `EndlessCatalog.get_arena_of_the_day(date_key)` | method | Deterministic daily arena; ownership ignored. |
| `EndlessCatalog.validate(check_backgrounds = true)` | method | Floor polygon and rect inside UV, unique ids, default present and free, backgrounds at `BACKGROUND_SIZE` (loads them), no placeholder, scenery rules. |
| `EndlessCatalog.floor_rect` / `floor_polygon` / `BACKGROUND_SIZE` | export / const | The shared floor in UV of the arena canvas; the canvas size every arena must be. |
| `ArenaSkinData.floor_rect` / `has_own_floor()` | export / method | An arena's own floor in UV (ADR-0020); zero size = the shared floor. `EndlessArenaRules.get_floor_rect_uv()` / `get_floor_polygon()` return it while that arena is equipped. |
| `ArenaSkinData.visual_scene_path` / `has_visual_scene()` / `load_visual_scene()` | export / methods | A layered arena's scene (ADR-0021), loaded when a run starts; `ArenaRules.get_visual_scene()` hands it to GameWorld (null for a painted arena). |
| `LayeredArenaVisual.fit(view_size, safe_top)` → `Rect2` | method | Lays a layered arena out for the screen and returns its floor as drawn, which GameWorld uses as the arena rect and walls. Also `get_floor_rect()`, `get_group_scale()`, `set_focus_point()`, `set_reduced_motion()`. |
| `ArenaVisual` (base of layered, 3D and board arenas) | class | `fit()`, `get_floor_rect()`, `get_drawn_floor_rect()`, `set_focus_point()`, `set_reduced_motion()`; the opening shot `has_intro()`, `play_intro()`, `skip_intro()`, signal `intro_finished` (ADR-0023); a board's HUD `has_board_hud()`, `set_board_hud(state)`, signal `hud_pause_pressed` (ADR-0024); `set_safe_bottom(inset)` before `fit()`; spawn effects `show_enemy_arrival(enemy, progress) -> bool` (true: the arena draws it, and the enemy's amber ring is turned off), `show_boss_appearance(boss, progress)`, `clear_spawn_effects()`, each `progress` the actor's own reader (ADR-0025). |
| `GameWorld.play_arena_intro` | var | Off for a restart from the run's dialogs (Main), so the arena starts zoomed in. |
| `ArenaRules.get_floor_rect_uv()` | method | The rectangle formations, hazards and the playfield's scale use; empty = `GameWorld.ARENA_FLOOR_UV` (the neutral arena). `EndlessArenaRules` returns `floor_rect`. |
| `ArenaSkinData.load_background()` / `get_tier_name()` | method | Lazy full-size background; `SIMPLE`…`MYTHIC`. |
| `GameWorld.configure_run(profile)` | method | Modes `endless` / `daily` select arena, pool and tuning through `RunProfile.create_arena_rules()`. |
| `RunProfile.endless(catalog, skin, rosters, boss_ids, form)` / `daily(catalog, skin, rosters, boss_ids, date, seed, form)` | static | Profiles Main builds for ENDLESS and the daily run. |
| `EndlessArenaRules.get_roster(wave, seed)` / `get_boss_id(index, seed)` | method | Seeded picks; a boss wave keeps the previous wave's roster; boss 0 is `RunProfile.opening_boss_id` when set. |
| `GameWorld.get_cycle()` | method | Bosses beaten this run (the Endless cycle). |

## Data & tuning (starting values)
| Field | Value | Meaning |
|---|---|---|
| `EndlessTuning.boss_wave_interval` | 4 | A boss every 4 waves |
| `threat_start` / `threat_per_cycle` / `threat_cap` | 1.0 / 0.18 / 3.0 | WaveDirector threat multiplier per boss cycle |
| `speed_scale_start` / `speed_scale_per_cycle` / `speed_scale_cap` | 1.0 / 0.04 / 1.3 | Enemy speed per cycle |
| `daily_roster_ids` / `daily_boss_ids` | `[obsidian_garden]` / `[reaper]` | Fixed daily pool |
| `opening_boss_id` | `grimgrin` | The first boss of every Endless run (Claude's choice for the phone test, 2026-09-27); Main copies it into the Endless `RunProfile` only, so the daily run and the Tutorial ignore it |
| Arenas | `quarry_titan` — QUARRY TITAN, Simple, free, the default · `stitched_doll_jungle` — STITCHED DOLL JUNGLE, Simple, free for now (owner), its own floor x 265–679, y 450–1266 · `stitchwarden_vigil` — STITCHWARDEN'S VIGIL, Simple, free, a layered arena (ADR-0021, ADR-0022) whose floor is about 453 × 996 on a 1080 × 2340 phone · `chained_colossus` — CHAINED COLOSSUS, Simple, free for now (owner), its own floor x 282–667, y 470–1277 · `chained_colossus_3d` — CHAINED COLOSSUS 3D, Simple, free for now, a 3D arena (ADR-0023) whose floor is 498 × 1078 on a 1080 × 2340 phone · `zoom_arena_3d` — 3D ZOOM ARENA, Simple, free, the same scene zoomed in until its floor (about 1080 × 2338 there) fills the whole screen · `board_01` / `board_01_light` — BOARD 01 / BOARD 01 LIGHT, Simple, free, the full-screen board (floor 936 × 1990 on 1080 × 2340), mid-dark or light floor · `sci_fi_simulation_v1` — SIMULATION, Simple, free, cyan accent, the sci-fi board (floor 888 × 2028 in a 1080 × 2340 desktop window, desktop safe margins) | Owner's images, 2026-09-23 and 2026-09-30; the Vigil's kit made with Codex, 2026-09-30; the Colossus 3D's model the owner's (Meshy), 2026-09-30 |
| `EndlessCatalog.BACKGROUND_SIZE` | 941 × 1672 | The Quarry Titan as delivered; the contract canvas is 1080 × 2400 ([guide](../guides/arena_art.md) §4) |
| `floor_rect` = `floor_polygon` bounds | UV (0.1615, 0.2183)–(0.8374, 0.7853) | The painted floor inside the stone rim: x 152–788, y 365–1313 of 941 × 1672 |

## Dependencies
[core_run.md](core_run.md), [wave_director.md](wave_director.md), [reaper_boss.md](reaper_boss.md)
(`BossData` variants), [rifts.md](rifts.md) (history: where the mixes and bosses came from),
[save_manager.md](save_manager.md), [challenges.md](challenges.md) (daily run), [shop.md](shop.md)
(the ARENAS pager), `DashGeometry` (polygon walls, ADR-0011).

## Rules & behaviour
- **Continuous spawning** (owner 2026-09-15): a new formation arrives whenever at most
  `refill_live_enemies` (2) enemies are alive, and a spent wave starts the next at once — no quiet waits.
- **Home's PLAY starts Endless** and it is open from the first launch (owner decision 2026-09-15); there is
  no ENDLESS button or unlock gate, and arenas can be bought any time. Real runs never teach: the
  first launch opens the Tutorial screen instead ([tutorial.md](tutorial.md)). The pool is every mix
  and boss from the start (owner decision 2026-09-15).
- **The floor is shared.** The walls are `EndlessCatalog.floor_polygon` and the playfield's layout
  rectangle is `floor_rect`, for every arena, mapped over the cover-scaled background; an arena
  changes only the picture. Every arena paints its floor there
  ([guide](../guides/arena_art.md) §2) and the catalog test compares each arena's measured floor.
  **Except an arena with its own floor** (ADR-0020, owner 2026-09-30: the Stitched Doll Jungle and the
  Chained Colossus, kept as painted): while it is equipped its rectangle's corners are the walls. Its `floor_rect` is the layout
  rect, which GameWorld still widens to `ARENA_MIN_VIEWPORT_FRACTION` of the screen (756 × 1170 on
  1080 × 2340, against the painted 580 × 1142): sizes, formation placement and Grimgrin's walls follow
  that wider rect (ADR-0021 corrects ADR-0020 on this).
- **A layered arena** (ADR-0021, owner 2026-09-30: Stitchwarden's Vigil) is a scene, not a picture: a
  run shows it instead of the backdrop, and `LayeredArenaVisual.fit()` lays it out for the screen and
  returns its floor as drawn. That rect is the arena rect, not widened, and its corners are the walls,
  so everything — walls, placement, bosses, dash collision and the sizes of the character and enemies
  — follows the drawn floor. Its motion (hood and face as one rig, cloth that responds to its turn, flame,
  lanterns, wisps, bats, fog) pauses with the run and Reduced Motion stills it. The Shop shows its
  941 × 1672 still.
- **A 3D arena** (ADR-0023, owner 2026-09-30: the Chained Colossus 3D) works the same way through
  `ModelArenaVisual.fit()`: the camera looks straight at the model's floor, so the floor is an exact
  rectangle, sized at 0.461 of the screen's width (1.08× the Vigil's height on 1080 × 2340) unless the
  eye, 230 px under the HUD's safe top, leaves less room. The head breathes slowly (a 4.8 s breath,
  ±1.2°); the fire, skulls, shards and clouds move; all of it pauses with the run and Reduced Motion
  stills it. No effect is ever drawn over the floor. The Shop shows a still rendered from the scene.
- **The zoom intro** (owner 2026-10-01, GDD §14 #69, ADR-0023 Addendum): with `zoom_intro` on (the
  3D ZOOM ARENA), `fit()` returns the floor as big as the whole screen allows, the HUD over it
  (`play_fills_screen`, GDD §14 #70), and each run
  opens on the whole model and its scenery, holds 0.8 s, then zooms in for 2.5 s; GameWorld keeps
  the Wisp and the HUD hidden and the waves waiting until it lands, and a tap skips it; a restart
  from the run's dialogs skips it entirely. The
  character and enemies are sized from that bigger floor. The Shop still is the opening shot.
- **A board arena** (ADR-0024, owner 2026-10-02: BOARD 01) fills the screen: `BoardArenaVisual.fit()`
  builds the board on 540 art pixels across the screen and returns the floor inside its frame. The
  frame holds the HUD (pause, boss plate or crest, score, Rift Points, soul gauge, RUSH gauge,
  lanterns that glow for upgrades); GameWorld hides its own HUD and feeds the board, and tapping the
  glowing character opens the upgrades.
- **The sci-fi board** (ADR-0025, owner 2026-10-04: SIMULATION) is a board with its own layout:
  `SciFiBoardVisual` lays out the kit's pieces as its manifest says, with the floor
  `[48, top + 64, 444, H − top − bottom − 128]` art pixels (`set_safe_bottom` gives the bottom); the
  safe insets above and below are filled with the kit's caps (owner, GDD §14 #74),
  the boss meter (only in a fight) and the RUSH meter inside the screen, and the other counters in
  the top hardware. It draws each enemy's arrival (amber, its frame from
  `EnemyActor.get_arrival_progress()`) and the boss's appearance (magenta, with patches at the
  floor's edges and corners, its frame from `BossActor.get_intro_progress()`), clipped to the floor
  and cleared when the arrival or the intro ends, the actor is gone, or the run ends.
- **Fit on every phone** (ADR-0017): the background is cover-scaled; an arena painted to the
  1080 × 2400 contract is drawn 1:1 on every phone from 16:9 to 20:9, losing only bleed.
- No rule twist: no portals, shrinking floor, drift or boss rush (those were the story Rifts', removed).
- Enemies: the run's `EnemyRamp` picks every enemy (Enemies v2, 2026-09-28); the mixes no longer swap
  them, and their `<NAME> WAVE` callouts are gone (waves after the first show `WAVE nn`).
- Every `boss_wave_interval` waves, one boss from the pool arrives (seeded, no immediate repeat); in Endless
  the first is `opening_boss_id` (Grimgrin) instead. A victory
  raises the cycle and resumes waves; it never ends the run. Death ends it.
- Best score, best wave and run count belong to Endless. Depth milestones stay keyed on the lifetime
  best wave.
- Daily run: Endless rules, the date seed, the fixed daily pool and the arena of the day (by date
  seed); identical for every player on a date.
- **Animated scenery** (built 2026-09-15/16 for the Legendary and Mythic skins: per-arena masks, a
  one-pass scenery shader, mask-gated particles, Reduced Motion stills it) is still in the code but
  no arena uses it since the skins were removed. Its full description is in this file's history
  (2026-09-16 revision).

## How to test
- `tools/run_tests.sh endless_catalog`.
- Visual: `WISP_CHARACTER=<id> tools/screenshot.sh res://tools/godot/render_character_gameplay_showcase.tscn 40 540x960`
  (a run on the default arena; `540x1170` for 19.5:9) and `tools/screenshot.sh res://tools/godot/render_arena_tab.tscn 60 540x960` (the Shop pager).

## Known issues / TODO
- `wisp_bearer` has a 1080x2400 painted source and generated background/thumbnail but is art-only; it is not listed in the catalog or save IDs.
- The Quarry Titan is 941 × 1672 without bleed: on phones taller than 16:9 its sides are trimmed
  and the floor is drawn larger. Re-deliver at 1080 × 2400 (guide §4).
- The playfield's layout rectangle is widened to `GameWorld.ARENA_MIN_VIEWPORT_FRACTION` (70 % of the
  width) on 16:9, a little wider than the 67.6 % painted floor; the walls still follow the floor.
- The retired arena tools (`extract_endless.py`, `make_endless_skin_data.py`, `endless_scenery.py`,
  `make_endless_floor_template.py`, `check_endless_skin.py`, `set_endless_import_lossy.py`) and the
  scenery fixtures (`render_endless_*_sheet.gd`) still target the removed skins. `check_endless_skin.py`
  also imports `extract_floor_polygons.py`, removed with the story Rifts (2026-09-25), so it no longer runs.
- Generated-art licence to confirm before release (GDD §14 #1, #21).

## Change history
| Date | Change |
|---|---|
| 2026-10-05 | SIMULATION's top and bottom caps (GDD §14 #74): the kit's joins and bands fill the safe insets instead of the flat cap colour |
| 2026-10-04 | SIMULATION, the sci-fi board (owner, GDD §14 #73, ADR-0025): `SciFiBoardVisual`, `sci_fi_simulation_v1` slot, `ArenaVisual.set_safe_bottom` and the spawn-effect hooks; `test_endless_catalog` counts it as a board |
| 2026-10-02 | Board arenas (owner, GDD §14 #71–#72, ADR-0024): `BoardArenaVisual`, BOARD 01 and BOARD 01 LIGHT, `ArenaVisual.has_board_hud` / `set_board_hud` / `hud_pause_pressed`, `make_board.py`; `test_endless_catalog` checks which arenas draw the HUD |
| 2026-10-02 | The zoom arena's floor fills the whole screen (`play_fills_screen`); a restart from the run's dialogs skips the zoom (`GameWorld.play_arena_intro`, Main) (owner, GDD §14 #70) |
| 2026-10-01 | The zoom intro (owner, GDD §14 #69): `ArenaVisual`'s opening shot (`has_intro`, `play_intro`, `skip_intro`, `intro_finished`, `get_drawn_floor_rect`), `ModelArenaVisual.zoom_intro`, GameWorld plays it before the waves; the 3D ZOOM ARENA slot (`zoom_arena_3d`); `render_arena_still.gd` prints the drawn floor; the cloud banks fade at their bottom edge |
| 2026-09-30 | The Chained Colossus 3D (owner, GDD §14 #68, ADR-0023): arenas may be 3D; `ArenaVisual` is the arena scene GameWorld hosts, `LayeredArenaVisual` and the new `ModelArenaVisual` extend it; `ModelArenaLayout`; the owner's model built by `build_colossus.py`; the scene, its effects and shaders; `render_arena_still.gd`; catalog, save ids; `test_endless_catalog` checks every arena scene and the Colossus 3D's floor against the Vigil's |
| 2026-09-30 | The Chained Colossus (owner's image, kept as sent; name and free price the owner's, GDD §14 #67): a painted arena with its own floor, x 282–667, y 470–1277 of 941 × 1672; catalog, save ids |
| 2026-09-30 | Revised Vigil art and scale (ADR-0022, GDD §14 #66): target-like moonlit ruins, narrow board with a mild top taper on its frame and a 120 × 264-texel rectangular floor, the doll's hood and face turn as one rig, scarf and cloth respond, fire follows the scythe blade; the two painted arenas remain as they were |
| 2026-09-30 | Stitchwarden's Vigil, the first layered arena (ADR-0021): `ArenaSkinData.visual_scene_path`, `ArenaRules.get_visual_scene()`, `LayeredArenaVisual`, GameWorld shows the scene and takes the arena rect and walls from its drawn floor; its packer, scene, motion script and shaders; free; catalog, save ids and `test_endless_catalog` (layered checks). The own-floor rule text corrected (sizes follow the widened rect there) |
| 2026-09-30 | The Stitched Doll Jungle (owner's image, placed by Codex; name and free price the owner's): an arena may bring its own floor (`ArenaSkinData.floor_rect`, ADR-0020), and the rules lay the playfield on it while it is equipped |
| 2026-09-28 | Enemies v2: the rosters' `enemy_substitutions` and the mix callouts removed (`substitute_enemy`, `get_roster_name`); the rosters only carry the old bosses into the pool (owner: the old bosses stay for now) |
| 2026-09-27 | `EndlessTuning.opening_boss_id` (Grimgrin), `RunProfile.opening_boss_id`, `EndlessArenaRules` returns it for boss 0; Endless only |
| 2026-09-25 | Story Rifts removed (owner): the five enemy mixes and the boss pool move out of `RiftData` into `EndlessRoster`s on the catalog (`data/endless/rosters/`, same order and values), so Endless plays exactly as before; `ContentUnlocks` and `RiftArenaRules` removed; `get_roster_rift` → `get_roster`, `daily_roster_rift_ids` → `daily_roster_ids`; `test_rift_enemies` → `test_endless_enemies` |
| 2026-09-23 | The thirty generated skins removed (data, 69 MB of art); one painted arena, the Quarry Titan, as the free default; the floor moves into the catalog as `floor_rect` + `floor_polygon`, `ArenaRules.get_floor_rect_uv()` lets an arena lay the playfield out; the arena image contract (1080 × 2400 with bleed) in `docs/guides/arena_art.md`; `tools/art/make_arena.py`; the Shop ARENAS tab is a pager again (ADR-0017) |
| 2026-09-16 | Animated scenery rebuilt on the painting (owner feedback 2026-09-15): per-skin masks, one-pass scenery shader (grade, emissive, distortion, corona/swirl, sweep, shooting stars), mask-gated glow particles; `ArenaAmbienceEffect` and the drawn-shape kinds removed; `ArenaSceneryData`/`Zone`/`ParticleEmitter`; validation + test updated |
| 2026-09-15 | Spec 05 done for all 30 skins: checker + extraction, generated data (tiers, prices, accents), lazy backgrounds + thumbnails, lossy import, `ArenaAmbience` for Legendary/Mythic, save ids, test_endless_catalog (GDD §14 #19, #26) |
| 2026-09-15 | Spec 05 partial: `astral_observatory` (default), `drowned_sanctum`, `moonpetal_shrine` wired with placeholder art; `placeholder_void_slate` removed, saves mapped off it (GDD §14 #26) |
| 2026-09-15 | PLAY = Endless, always open; ENDLESS button, NEW badge and `endless_intro_seen` removed (owner) |
| 2026-09-15 | Built on the placeholder skin (spec 03): catalog, tuning, `ArenaRules` seam, Home ENDLESS, Endless/daily Results, save v7; enemy speed scale now applied (GDD §14 #24) |
| 2026-09-14 | Planned (ADR-0013, ADR-0014) |
