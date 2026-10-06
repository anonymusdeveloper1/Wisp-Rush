# ADR-0025: The sci-fi board — a board with its own layout, and spawn effects drawn by the arena

> **Status:** The other arenas removed by [ADR-0027](0027-one-arena-simulation.md) (2026-10-05): SIMULATION is the one arena; Accepted · **Date:** 2026-10-04 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Builds on:** [ADR-0024](0024-board-arenas.md) (board arenas, the HUD in the board) and
> [ADR-0021](0021-layered-arenas.md) (an arena may be a scene, an `ArenaVisual`)

## Context
Codex built a component kit for a sci-fi simulation screen (`concept_art/boards_v1/sci_fi_simulation_v1/`:
54 pixel-art pieces, `manifest.json`, previews, and `CLAUDE_IMPLEMENTATION_PROMPT.md`). The owner
(2026-10-04, GDD §14 #73): implement the kit, connect the embedded meters and spawn animations, keep
the existing arenas, and verify it in playable runs. The kit is not BOARD 01 with new art. It has its
own frame sizes (48 art px rails, 64 / 64 hardware, a 6 px cyan rim), and the magenta boss meter and
amber RUSH meter sit *inside* the playing screen. It also brings an amber enemy-arrival sheet and a
magenta boss-appearance sheet with screen patches, and their frames must follow the game's own
arrival and intro timing. `BoardArenaVisual` hardcodes BOARD 01's posts, beams, gauges and pieces,
and no arena could draw spawn effects.

## Options considered
1. **Configure `BoardArenaVisual` by layout data**: one renderer for both boards. BOARD 01's slots
   (vertical post gauges, lanterns, the boss plate) and this kit's (meters in the screen, badges in
   the hardware) share almost nothing, so the "layout" would be two code paths behind one name, with
   BOARD 01 at risk.
2. **A separate `ArenaVisual` for this kit**, `SciFiBoardVisual`, with BOARD 01 left untouched; spawn
   effects as a small, generic `ArenaVisual` hook that GameWorld calls on every spawn.

## Decision
Option 2.
- **`SciFiBoardVisual`** (`scenes/arenas/sci_fi_board_visual.gd`, scene
  `scenes/arenas/sci_fi_simulation_v1.tscn`) builds the kit's pieces as the manifest and the kit's
  `build_kit.py` assemble them: one art pixel = view width / 540, the safe top and bottom kept as
  whole art pixels, the floor `[48, top + 64, 444, H − top − bottom − 128]`, the rails and floor tiled
  with the last repeat cropped, the rim just outside the floor, the meters from the floor's top centre
  (`[−178, 56]` boss, `[−178, 98]` RUSH), the HUD pieces at the manifest's spots. `fit()` returns the
  floor. Every fill is its whole texture inside a clipping box sized to the value, so the RUSH
  segments never stretch. It `has_board_hud()`, so GameWorld's board path (ADR-0024: hidden HUD,
  `set_board_hud` feed, `hud_pause_pressed`, the glow and the character tap) works unchanged.
- **`ArenaVisual.set_safe_bottom()`**: GameWorld gives the arena its bottom safe margin before
  `fit()`, as the kit asks for a bottom cap. Other arenas ignore it.
- **Spawn effects drawn by the arena:** `ArenaVisual.show_enemy_arrival(enemy, progress)` (true
  when the arena draws it, and GameWorld then turns off that enemy's amber ring with
  `EnemyActor.set_arrival_ring_enabled(false)`), `show_boss_appearance(boss, progress)` after the boss
  is configured, and `clear_spawn_effects()` at death. The progress readers are the actors' own:
  `EnemyActor.get_arrival_progress()` (the telegraph countdown that makes it active) and
  `BossActor.get_intro_progress()` (Grimgrin's and the Reaper's intro hold; −1 for a boss that does
  not say). The arena only samples them, so an effect cannot drift from the game, pauses with it, and
  follows Wisp Focus. It never changes when anything arrives. Every other arena returns false and
  keeps the amber ring.
- **The arena never names the actor classes:** it gets a `Node2D` and a `Callable`. Naming
  `EnemyActor` / `BossActor` in the arena scripts left a resource in use at exit in
  `check_scripts.gd` (measured 2026-10-04, by reverting each file in turn).
- **Layers inside the board:** the screen (floor and data marks), then the spawn effects clipped to
  the floor, then the frame and the HUD art, then the counters. Actors and their warnings draw
  above the whole arena.

## Consequences
- A new board kit with a different layout gets its own `ArenaVisual`. A kit with SIMULATION's
  layout can reuse `SciFiBoardVisual` by setting `art_dir`.
- Any arena can now draw arrivals and boss appearances without touching the actors.
- Claude's values, for the phone test (owner to change):
  - **Reduced Motion:** an arrival holds frame 4 and the boss pattern frame 6 (the kit's own stills),
    and the boss patches stay hidden.
  - **Boss patches:** as the kit's boss preview (streaks every 120 art px from 154 under the floor's
    top, alternating walls, sliding 8 px with the opacity; edge marks at 4 and 22 px). The four corner
    marks sit 7 px from each corner along the top and bottom walls, mirrored (the reference's top-left
    one).
  - **Counters:** the largest font size on the 11 grid whose digits (0.65 em, measured) fit the
    socket. The upgrade count is amber.
  - **Pause:** the touch target is the floating HUD's 112 design px around the 36 art px icon.
  - **Bottom safe inset:** GameWorld's bottom safe margin, which includes its base margin, as the top
    one does.
  - **Fallback clock** for a boss with no intro progress: the kit preview's 75 ms per frame.
  - **The skin:** tier Simple, free, last in the catalog.
- Owner decisions in it (GDD §14 #73): the name SIMULATION, the Shop line, the upgrade badge always
  shown and numbered from 1, the kit's cyan accent.
