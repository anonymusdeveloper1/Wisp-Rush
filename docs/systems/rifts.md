# System: Rifts

> **Status:** ✅ done (story levels, clear-based unlocks, difficulty, rosters, all four rule twists and
> five bosses) · **Last updated:** 2026-09-15 · **GDD section:** §5.4, §6 ·
> **ADR:** [0007](../decisions/0007-rifts-as-rule-variant-arenas.md),
> [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md) (story levels, spec 02)

## Purpose

Give the story a ladder of arenas that each change one rule, played one level per run, with a map
screen that shows the progression, the rule twist, the clear that opens each arena and its best.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/rift_data.gd` | One arena: identity, backdrop, unlock requirement, accent, rule key |
| `res://scripts/utils/content_unlocks.gd` | Pure story rules: unlocked, next level, mastered, newly opened |
| `res://scenes/gameplay/run_profile.gd` | `RunProfile`: mode, Rift, level, seed, form, first-clear eligibility |
| `res://scripts/resources/rift_catalog.gd` | Ordered five-Rift registry and validation |
| `res://data/rifts/*.tres` | The five authored Rifts and the catalog |
| `res://scenes/screens/rift_map_screen.tscn` / `.gd` | The arena ladder UI (carousel card picker) |
| `res://scripts/components/focus_carousel.gd` / `page_dots.gd` | Shared card picker + page indicator ([ui_design_system.md](ui_design_system.md)) |
| `res://scripts/autoload/save_manager.gd` | `selected_rift`, `rift_bests`, `select_rift()` (schema v2) |
| `res://scenes/gameplay/game_world.gd` | Applies the backdrop and latches `rule_key` at run start |
| `tools/art/extract_rifts.py` | Generates the Rift art from the concept pack |
| `tools/art/extract_floor_polygons.py` | Bakes each Rift's playable floor polygon from its runtime background |
| `tools/godot/test_rift_catalog.gd` | Ladder, backdrop geometry and persistence checks |
| `tools/godot/test_rift_enemies.gd` | Split config, Warden shield arc, Rift Spawn tether damage |
| `tools/godot/test_rift_rules.gd` | Live checks that each rule twist changes the run |
| `res://scenes/enemies/{cinder_shade,warden,rift_spawn}.*` | The three Rift enemy families |

## Scene / node structure

```text
RiftMapScreen (Control)  rift_map_screen.gd
├── %Background (TextureRect)      focused Rift's arena, cover-scaled
├── %BackgroundFade (TextureRect)  previous arena, fades out over it (0.3 s)
├── Shade (ColorRect)              void charcoal 66 %, keeps text readable over the art
└── SafeMargin → Content (VBoxContainer)
    ├── TitleBanner (PanelBanner + banner_top ornament + "RIFT MAP")
    ├── %Carousel (FocusCarousel) ← one CardButton card per catalog Rift, built in code
    ├── %Dots (PageDots, hollow = locked)
    ├── %RuleLabel (rule summary)
    ├── StatusRow → %BestIcon · %StatusLabel
    └── Footer → %BackButton (SecondaryButton) · %EnterButton (PrimaryButton)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `RiftMapScreen.back_requested` | signal | Player left the map without entering a Rift. |
| `RiftMapScreen.play_requested(rift_id)` | signal | Player chose a Rift and asked to start a run. |
| `RiftMapScreen.setup(snapshot)` | method | Rebuilds the ladder from a SaveManager snapshot (safe before `_ready`). |
| `RiftMapScreen.get_selected_rift_id()` | method | The focused Rift, locked or not; ENTER starts it only when unlocked. |
| `RiftMapScreen.is_rift_unlocked(rift_id)` | method | Whether a Rift is open to the current save. |
| `RiftData.is_unlocked(rift_levels)` | method | Whether banked clears reach `unlock_after_rift_id` level `unlock_after_level`. |
| `ContentUnlocks.is_rift_unlocked` / `get_next_level` / `is_mastered` / `get_cleared_level` | static | Story progress from `rift_levels` (next = cleared + 1, capped at `level_count`). |
| `ContentUnlocks.get_newly_unlocked(before, after, catalog)` | static | Rift ids a clear just opened, in ladder order. |
| `ContentUnlocks.resolve_story_rift(catalog, selected_id, rift_levels)` | static | The selection if open, else Obsidian Garden. |
| `RiftData.validate()` | method | Authoring failures for one Rift. |
| `RiftCatalog.load_rifts()` / `validate()` / `get_rift(id)` | method | Load, check, or resolve with a baseline fallback. |
| `SaveManagerService.select_rift(rift_id)` | method | Persists the arena the next run will use. |
| `GameWorld.configure_run(profile)` | method | Applies a `RunProfile` built by Main (Rift, level, mode). |

## Data & tuning

| Rift | Opens after | Tier | `rule_key` | Twist | L1 → L8 threat | Speed | Boss |
|---|---|---|---|---|---|---|---|
| Obsidian Garden | — (open) | 1 | `none` | Baseline arena | 1.00 → 1.84 | ×1.00 | `reaper` |
| Shattered Rift | Obsidian Garden L1 | 2 | `portals` | Void portals bend the dash to their pair | 1.00 → 2.05 | ×1.05 | `the_fracture` |
| Ember Hollow | Shattered Rift L1 | 3 | `shrinking_floor` | The floor burns away as the run goes on | 1.00 → 2.26 | ×1.10 | `cinder_maw` |
| Frozen Choir | Ember Hollow L1 | 4 | `drift` | Ice keeps the Wisp drifting after impact | 1.00 → 2.47 | ×1.15 | `hollow_choir` |
| Reaper's Court | Frozen Choir L1 | 5 | `boss_rush` | Reaper every two waves, double rewards | 1.00 → 2.75 | ×1.20 | `reaper_ascended` |

Every Rift has 8 levels of 4 waves. **Level 1 is threat ×1.00 in all five** — each arena opens easy
([ADR-0008](../decisions/0008-rift-levels-and-difficulty-ladder.md)); the ladder bites through the
per-level ramp, which steepens with the tier. **A story run plays exactly one level** (GDD §14 #12):
the boss on wave `waves_per_level` is the final boss and its defeat ends the run in victory;
`boss_rush` adds a mid-level boss on wave `waves_per_level / 2` that resumes waves. A victory banks
the level in `rift_levels`; a defeat banks nothing. PLAY and ENTER always start the next level; a
mastered Rift (all 8 cleared) replays level 8. `RiftCatalog.validate()` checks the chain: the first
Rift has no requirement, every other one names an earlier Rift and a level inside its `level_count`.

**Rosters** (`enemy_substitutions` remaps the authored formation kinds):

| Rift | soul_wisp → | shard_wraith → | bone_mote → |
|---|---|---|---|
| Obsidian Garden | — | — | — |
| Shattered Rift | Rift Spawn | Echo | — |
| Ember Hollow | Cinder Shade | — | Slag Hulk |
| Frozen Choir | Frost Wisp | Warden | — |
| Reaper's Court | Court Shade | Warden | Slag Hulk |

## Dependencies

[core_run.md](core_run.md) (backdrop and run start), [save_manager.md](save_manager.md) (schema v2),
[game_flow.md](game_flow.md) (Home → Rift map → run), [ui_design_system.md](ui_design_system.md).

## Rules & behaviour

- **Unlocking is derived from banked clears (`rift_levels`), never stored** (GDD §14 #13); a clear
  that opens a Rift makes it `selected_rift` (Main). `highest_wave` is only a lifetime statistic.
- **The wall is the Rift's painted floor** ([ADR-0011](../decisions/0011-polygon-playfield-from-art.md)):
  `RiftData.floor_polygon`, baked from the art by `tools/art/extract_floor_polygons.py`. The legacy
  `ARENA_FLOOR_UV` rectangle is kept only as the design-pixel scale and the distribution domain —
  never use the polygon's bounding box for scale, it would resize the Wisp's hitbox.
- Re-run the extractor after any background change and review `logs/rifts/floor_<rift>.png`.
- **Every backdrop must be exactly 941×1672**, because the scale rectangle is still a UV rect.
  `test_rift_catalog.gd` fails the build if this is broken.
- **Map UI (owner decision 2026-09-13):** a portrait carousel like Forms. Swipe or tap a side card
  to browse; tapping the focused card = ENTER. The screen background crossfades to the focused
  Rift's arena (instant under Reduced Motion).
  - Unlocked card: arena art, name, `TIER n`, `LEVEL n / 8` (the next level) or `MASTERED`, and a
    slim level bar. Locked card: dimmed art, a lock and `CLEAR <PREVIOUS RIFT> LEVEL 1`.
  - Under the carousel: dots (hollow = locked), the rule summary, a status line — amber `BEST n`,
    `NO RUN YET`, or `LOCKED  ·  CLEAR <PREVIOUS RIFT> LEVEL 1` — then BACK, TUTORIAL (SecondaryButton,
    `tutorial_requested`: the only Tutorial replay, owner decision 2026-09-15) and ENTER.
  - **Locked Rifts can be previewed but never entered:** ENTER is disabled and reads LOCKED.
- A locked Rift left selected in a save (for example after a progress reset) falls back to
  Obsidian Garden when the map is built.
- Cards are generated from the catalog, so a new Rift is a `.tres` plus a background.
- `record_run` stores a per-Rift best only for known ids, and never lowers an existing best.

## How to test

- `tools/run_tests.sh rift` — ladder, gates, backdrop geometry, persistence, best-score guard.
- `test_menu_screens.gd` (lock gating, selection, ENTER); `test_screen_setup_order.gd` (`%Carousel`, 5 cards).
- Visual: `WISP_ISOLATED_SAVE=1 tools/screenshot.sh res://scenes/screens/rift_map_screen.tscn 24 1080x1920`;
  phone layouts `tools/qa_matrix.sh rifts rifts_locked`.
- Manual: Home → RIFTS → swipe to an unlocked Rift → ENTER; the arena backdrop changes and Results
  records a best against that Rift.

## Known issues / TODO

- Bosses share one attack grammar ([ADR-0010](../decisions/0010-data-driven-boss-variants.md)):
  they differ in silhouette, colour, toughness and timing, not in what the attacks fundamentally
  are. `reaper_ascended` is a recolour of the Reaper atlas rather than new art.
- A portal transit fires at most once per dash, so the pair cannot trap a dash in a loop. The
  exit places the Wisp just outside the mouth for the same reason.
- There are no permanent upgrades: the Soul Sanctum was removed on 2026-09-15 (ADR-0013), so a Rift
  level plays the same for every save.
- Ember Hollow's contraction is partly limited by `ARENA_MIN_VIEWPORT_FRACTION`, which can pin one
  axis at its floor before `SHRINK_FLOOR_MINIMUM` is reached; `test_rift_rules.gd` therefore
  asserts area, not per-axis, contraction.
- Per-Rift mission chains (ROADMAP M8) are not built; unlocking is clear-based only.
- There is no level picker: ENTER plays the next level, so an earlier level can't be replayed on
  purpose (GDD §14 #23). Headless tests written for wave gates are stale (not updated in spec 02).
- Echo, Slag Hulk, Frost Wisp and Court Shade reuse the Cinder Shade / Bone Mote / Shard Wraith
  behaviour scripts with their own art, tuning and roster slot — distinct threats to plan around,
  but not new mechanics.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | TUTORIAL footer button (`tutorial_requested`) between BACK (now 240 px) and ENTER |
| 2026-09-15 | Spec 02: one level per run, clear-based unlock chain, `ContentUnlocks`, `RunProfile`, MASTERED cards |
| 2026-09-13 | Rift Map rebuilt as a `FocusCarousel` card picker with arena crossfade and locked preview |
| 2026-09-12 | Walls follow each arena's painted floor, derived from the art (ADR-0011) |
| 2026-09-12 | Void portals, and five data-driven bosses (ADR-0010) |
| 2026-09-12 | Wave-2 art extracted (3 bosses, 4 enemies); seven enemy families across five rosters |
| 2026-09-12 | Three enemy families, per-arena rosters, and the boss-rush / shrinking-floor / drift twists |
| 2026-09-12 | Levels, per-Rift difficulty tiers and roster substitution (ADR-0008) |
| 2026-09-12 | Created: five Rifts, derived unlock ladder, map screen, schema v2, art pipeline (ADR-0007) |
