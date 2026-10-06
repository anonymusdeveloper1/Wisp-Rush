# System: Endless mode

> **Status:** ✅ one arena, SIMULATION, the sci-fi board with the HUD in its frame, the meters in its screen and its own spawn effects (2026-10-04, ADR-0025); every other arena removed 2026-10-05 (owner, ADR-0027) · device pass pending · **Last updated:** 2026-10-05 · **GDD section:** §6, §7, §11 ·
> **ADR:** [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [0024](../decisions/0024-board-arenas.md) (the board HUD path),
> [0025](../decisions/0025-sci-fi-board-and-arena-spawn-effects.md),
> [0027](../decisions/0027-one-arena-simulation.md) (one arena; history: 0014, 0017, 0020–0023) ·
> **Specs:** [03](../specs/story_and_endless/03_endless_mode.md)

## Purpose
The never-ending mode: runs on SIMULATION, the game's one arena, the Enemies v2 enemies on the run's
ramp ([wave_director.md](wave_director.md)), bosses from a pool, and the best score and wave to
chase. The daily run uses its rules. (The five enemy mixes came from the story Rifts, removed on
2026-09-25; since Enemies v2, 2026-09-28, they no longer change the enemies and only carry the old
bosses into the pool.)

## Files
| Path | Role |
|---|---|
| `res://scripts/resources/endless_catalog.gd` | `EndlessCatalog`: the arenas (one), the default arena, tuning, the rosters (`rosters`) that carry the boss pool, validation |
| `res://scripts/resources/endless_roster.gd` | `EndlessRoster`: one boss-pool entry — id, the old mix's name, `boss_id` (its `enemy_substitutions` went with Enemies v2) |
| `res://data/endless/rosters/<id>.tres` | The five rosters (old mixes), in pick order: `obsidian_garden`, `shattered_rift`, `ember_hollow`, `frozen_choir`, `reapers_court` |
| `res://scripts/resources/arena_skin_data.gd` | `ArenaSkinData`: one arena — id, name, description and its scene path |
| `res://scripts/resources/endless_tuning.gd` | `EndlessTuning`: boss cadence, per-cycle threat and speed, daily pool, the opening boss |
| `res://data/endless/default_endless_catalog.tres` · `default_endless_tuning.tres` | The catalog and tuning instances |
| `res://data/endless/skins/sci_fi_simulation_v1.tres` | SIMULATION's `ArenaSkinData` (hand-authored) |
| `res://scenes/arenas/arena_visual.gd` | `ArenaVisual`: the arena scene GameWorld hosts — `fit()` returns the drawn floor; the board HUD, the spawn-effect hooks and Reduced Motion |
| `res://scenes/arenas/sci_fi_board_visual.gd` · `sci_fi_simulation_v1.tscn` | `SciFiBoardVisual` (ADR-0025): the sci-fi board built from its kit as the kit's manifest lays it out, the HUD in its frame, the magenta boss and amber RUSH meters in its screen, and the enemy-arrival and boss-appearance effects clipped to its floor |
| `res://assets/art/environment/boards/sci_fi_simulation_v1/` | The kit's runtime pieces, copied by `tools/art/make_board.py` |
| `res://scenes/gameplay/run_item_hud.gd` | Active pickup timers and Ward hints |
| `tools/art/make_board.py` | Copies a board's pieces from `concept_art/boards_v1/<board>/` (checked against its manifest) to `assets/art/environment/boards/<board>/` |
| `res://scenes/gameplay/arena_rules.gd` | `ArenaRules`: the seam GameWorld reads (the arena scene, boss cadence/id, threat, speed); the base class is the neutral arena of fixtures, the Tutorial and F6 runs, on SIMULATION (`DEFAULT_ARENA_PATH`) |
| `res://scenes/gameplay/endless_arena_rules.gd` | `EndlessArenaRules`: the arena, seeded roster/boss picks with no immediate repeat, per-cycle tuning |
| `tools/godot/test_endless_enemies.gd` | Stale since 2026-09-28: it checks the removed Rift enemies and mixes |
| `tools/godot/test_endless_catalog.gd` | Catalog validation, the arena list vs the save's ids, SIMULATION fitted with the board HUD on five portrait views (1080 × 2340, 1080 × 2400, 1080 × 1920, 1200 × 1920, 1440 × 1920), the arena of the day, Endless and neutral rules giving its scene, and saves holding a removed arena falling back to it |
| `tools/godot/test_endless_mode.gd` | Behaviour checks (**not written yet**) |

## Public API
| Member | Kind | Description |
|---|---|---|
| `EndlessCatalog.get_rosters()` | method | Every roster, in pick order (they carry the boss pool). |
| `EndlessCatalog.get_rosters_by_id(ids)` | method | The rosters with these ids, in the given order (the daily pool). |
| `EndlessCatalog.get_boss_ids()` | method | Every roster's boss, in pick order, no repeats. |
| `EndlessCatalog.get_skin(skin_id)` | method | The arena, or the default when unknown. |
| `EndlessCatalog.get_arena_of_the_day(date_key)` | method | Deterministic daily arena (SIMULATION, the only one). |
| `EndlessCatalog.validate()` | method | Tuning, the arenas (unique ids, each arena's own checks), rosters, daily rosters and the default. |
| `ArenaSkinData.visual_scene_path` / `has_visual_scene()` / `load_visual_scene()` | export / methods | The arena's scene, loaded when a run starts; `ArenaRules.get_visual_scene()` hands it to GameWorld. |
| `ArenaVisual` | class | `fit(view_size, safe_top) -> Rect2` (the floor as drawn: GameWorld's arena rect, its corners the walls), `get_floor_rect()`, `set_reduced_motion()`; a board's HUD `has_board_hud()`, `set_board_hud(state)`, `get_hud_rect(element)` (where the board draws `rush` or `items`, for the Tutorial's callouts), signal `hud_pause_pressed` (ADR-0024); `set_safe_bottom(inset)` before `fit()`; spawn effects `show_enemy_arrival(enemy, progress) -> bool` (true: the arena draws it, and the enemy's amber ring is turned off), `show_boss_appearance(boss, progress)`, `clear_spawn_effects()`, each `progress` the actor's own reader (ADR-0025). |
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
| Arena | `sci_fi_simulation_v1` — SIMULATION, the default and only arena: the sci-fi board (floor 888 × 2028 in a 1080 × 2340 desktop window, desktop safe margins) | Codex's kit, 2026-10-04 |

## Dependencies
[core_run.md](core_run.md), [wave_director.md](wave_director.md), [reaper_boss.md](reaper_boss.md)
(`BossData` variants), [rifts.md](rifts.md) (history: where the mixes and bosses came from),
[save_manager.md](save_manager.md), [challenges.md](challenges.md) (daily run),
`DashGeometry` (polygon walls, ADR-0011).

## Rules & behaviour
- **Continuous spawning** (owner 2026-09-15): a new formation arrives whenever at most
  `refill_live_enemies` (2) enemies are alive, and a spent wave starts the next at once — no quiet waits.
- **Home's PLAY starts Endless** and it is open from the first launch (owner decision 2026-09-15); there is
  no ENDLESS button or unlock gate. Real runs never teach: the first launch opens the Tutorial screen
  instead ([tutorial.md](tutorial.md)). The pool is every mix and boss from the start (owner decision
  2026-09-15).
- **One arena** (owner 2026-10-05, ADR-0027): every run, the daily run and the Tutorial play on
  SIMULATION. There is no arena to pick: the Shop's ARENAS tab is gone, and a save that held a removed
  arena (`SaveManagerService.RETIRED_ARENA_SKIN_IDS`) loads with SIMULATION equipped.
- **The floor is the board's.** `SciFiBoardVisual.fit()` returns the floor as drawn; that rect is the
  arena rect and its corners are the walls, so walls, placement, bosses, dash collision and the sizes
  of the character and enemies all follow it. With no arena scene (none is left) the arena rect would
  be the whole view.
- **The sci-fi board** (ADR-0025, owner 2026-10-04: SIMULATION) lays out the kit's pieces as its
  manifest says, one art pixel = view width / 540, with the floor
  `[48, top + 64, 444, H − top − bottom − 128]` art pixels (`set_safe_bottom` gives the bottom); the
  safe insets above and below are filled with the kit's caps (owner, GDD §14 #74),
  the boss meter (only in a fight) and the RUSH meter inside the screen, and the other counters in
  the top hardware. GameWorld hides its own HUD and feeds the board (ADR-0024's board path): score,
  Rift Points, Ward stock and protection, RUSH, the boss meter, and whether the pause button shows
  (the Tutorial hides it). It draws each enemy's arrival (amber, its frame from
  `EnemyActor.get_arrival_progress()`) and the boss's appearance (magenta, with patches at the
  floor's edges and corners, its frame from `BossActor.get_intro_progress()`), clipped to the floor
  and cleared when the arrival or the intro ends, the actor is gone, or the run ends. Double tap
  activates Ward protection; [pickup items](pickup_items.md).
- No rule twist: no portals, shrinking floor, drift or boss rush (those were the story Rifts', removed).
- Enemies: the run's `EnemyRamp` picks every enemy (Enemies v2, 2026-09-28); the mixes no longer swap
  them, and their `<NAME> WAVE` callouts are gone (waves after the first show `WAVE nn`).
- Every `boss_wave_interval` waves, one boss from the pool arrives (seeded, no immediate repeat); in Endless
  the first is `opening_boss_id` (Grimgrin) instead. A victory
  raises the cycle and resumes waves; it never ends the run. Death ends it.
- Best score, best wave and run count belong to Endless. Depth milestones stay keyed on the lifetime
  best wave.
- Daily run: Endless rules, the date seed and the fixed daily pool, on SIMULATION; identical for
  every player on a date.

## How to test
- `tools/run_tests.sh endless_catalog`.
- Visual: `WISP_CHARACTER=<id> tools/screenshot.sh res://tools/godot/render_character_gameplay_showcase.tscn 40 540x960`
  (a run on SIMULATION; `540x1170` for 19.5:9).

## Known issues / TODO
- Generated-art licence to confirm before release (GDD §14 #1, #21).

## Change history
| Date | Change |
|---|---|
| 2026-10-05 | One arena (owner, GDD §14 #78, ADR-0027): every arena but SIMULATION removed with its scenes, scripts, shaders, art and tools; the painted background, the ambience and the zoom intro removed from GameWorld; `ArenaSkinData` keeps id, name, description and scene; `EndlessCatalog` loses the shared floor; the Tutorial and neutral rules play on SIMULATION; removed arena ids fall back to it; `ArenaVisual.get_hud_rect`; `test_endless_catalog` rewritten for the one arena |
| 2026-10-05 | Board HUD stock/protection replaces XP/upgrades; timed pickup icons remain visible |
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
