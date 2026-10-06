# ADR-0027: One arena, SIMULATION — every other arena removed from the game

> **Status:** Accepted · **Date:** 2026-10-05 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Supersedes:** the arenas of [ADR-0017](0017-painted-arenas-with-bleed.md),
> [ADR-0020](0020-an-arena-may-bring-its-own-floor.md), [ADR-0021](0021-layered-arenas.md),
> [ADR-0022](0022-vigil-art-and-floor-revision.md), [ADR-0023](0023-3d-arenas.md) and
> [ADR-0024](0024-board-arenas.md) · **Keeps:** [ADR-0025](0025-sci-fi-board-and-arena-spawn-effects.md)
> (SIMULATION) and ADR-0024's board HUD path in GameWorld

## Context
On 2026-10-05 the game had ten arena slots in the Shop's ARENAS tab: the painted Quarry Titan (the
default), the Stitched Doll Jungle and the Chained Colossus; the layered Stitchwarden's Vigil; the 3D
Chained Colossus and the 3D ZOOM ARENA; BOARD 01 and BOARD 01 LIGHT; and SIMULATION. GameWorld drew a
painted full-screen background for arenas without a scene, an ambience layer, and the 3D zoom intro.
The owner (GDD §14 #78): "remove the arena toogle and remove all the arens from the game from the code
as well just leave the simulation arena which is the main arena or playuable board for the user". From
Claude's options the owner picked **all of it**: the tutorial moves to SIMULATION, the other arenas'
scenes, scripts, shaders and runtime art and the painted-background path are removed, saves holding a
removed arena fall back to SIMULATION, and the source art in `concept_art/` stays as history.

## Options considered
1. **Hide the ARENAS tab, keep the arenas in code** — the smallest change, but not what the owner asked.
2. **Remove the arenas and their code paths**, keeping only what SIMULATION uses (the owner's pick).

## Decision
Option 2.
- **The catalog and the save hold one arena.** `data/endless/default_endless_catalog.tres` lists only
  `sci_fi_simulation_v1`, its default. `SaveManagerService.VALID_ARENA_SKIN_IDS` is that id alone, and
  `RETIRED_ARENA_SKIN_IDS` maps every removed id (`placeholder_void_slate`, `quarry_titan`,
  `stitched_doll_jungle`, `stitchwarden_vigil`, `chained_colossus`, `chained_colossus_3d`,
  `zoom_arena_3d`, `board_01`, `board_01_light`) to it, so an old save loads on SIMULATION.
- **`ArenaSkinData`** keeps `skin_id`, `display_name`, `description` and `visual_scene_path`; the
  `tier`, `background_path`, `thumbnail`, `price`, `accent`, `scenery`, `placeholder` and
  `floor_rect` fields are gone. `EndlessCatalog` loses the
  shared floor rectangle, the mask floor and the scenery helpers; the arena of the day is drawn from
  the one skin.
- **`ArenaRules.DEFAULT_ARENA_PATH`** is SIMULATION's scene, so neutral rules (the tutorial, tests)
  play on it too. It is `load()`ed, not preloaded: SIMULATION's script reaches GameWorld, which reaches
  ArenaRules, and a preload would make a cycle.
- **GameWorld** has no painted background (the `FullBleedBackground` node is gone), no ambience and
  no intro. The arena rectangle is the arena's `fit()`, or the whole view when no arena scene is
  given. `get_hud_rect()` asks the board first (`ArenaVisual.get_hud_rect`: SIMULATION answers for
  `rush` and `items`), so the tutorial's callouts point at the board's own meters. The board hides its
  pause button when GameWorld's is hidden (the `pause` key of `set_board_hud`), as the tutorial does.
- **`ArenaVisual`** keeps `fit`, `get_floor_rect`, `has_board_hud`, `set_board_hud`,
  `hud_pause_pressed`, `set_safe_bottom`, the spawn effects and `set_reduced_motion`; the intro API and
  `set_focus_point` are removed.
- **The tutorial** (`data/tutorial/default_tutorial.tres`) plays on `sci_fi_simulation_v1`.
- **The Shop's ARENAS tab** is removed ([ADR-0028](0028-shop-bottom-navigation-and-rift-points-packs.md)),
  with Main's arena-skin purchase branch.
- **Removed from the game:** the eight other skin `.tres` files; `board_arena_visual.gd`,
  `layered_arena_visual.gd`, `model_arena_visual.gd`, the Chained Colossus 3D, Stitchwarden's Vigil,
  zoom and BOARD 01 scenes; `arena_ambience.gd`, `ArenaParticleEmitter`, `ArenaSceneryData`,
  `ArenaSceneryZone` and `ModelArenaLayout`; the arena, scenery, ghost-fire, cloth and lantern shaders
  and `arena_3d_common.gdshaderinc`; `assets/art/environment/arenas/`,
  `assets/art/environment/boards/board_01/` and `wisp_rush_arena_background.png`; and the arena-only
  tools (`tools/art/make_arena.py`, `check_endless_skin.py`, `extract_endless.py`, `endless_scenery.py`,
  `make_endless_floor_template.py`, `make_endless_skin_data.py`, `set_endless_import_lossy.py`;
  `tools/godot/render_arena_showcase.gd`, `render_arena_still.gd`, `render_arena_tab.*`,
  `render_endless_scenery_sheet.gd`, `render_endless_skins_sheet.gd`).
- **Kept as history:** every arena's source art and build scripts in `concept_art/`, and the ADRs above.

## Consequences
- A new arena is a new `ArenaVisual` scene, its skin `.tres`, a catalog entry and a valid save id.
  `docs/guides/arena_art.md` (the painted-image contract) describes removed arenas.
- `tools/godot/test_endless_catalog.gd` checks the one arena: the catalog, the save ids, SIMULATION
  fitted on five portrait views with the board HUD, the arena of the day, and every removed id
  falling back to SIMULATION. `test_dash_geometry.gd` measures on SIMULATION's floor.
- Tests that pressed GameWorld's pause button press the board's (`hud_pause_pressed`), as a run on a
  board does.
