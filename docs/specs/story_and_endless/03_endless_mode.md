# Phase 3 — Endless mode, and the daily run on Endless rules

> Part of [story_and_endless](README.md) · **Rules:** GDD §6 (Endless, daily run), §7, §11, §14 #14–#15;
> [ADR-0013](../../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [ADR-0014](../../decisions/0014-endless-arenas-share-one-floor-template.md) ·
> **Touches:** [endless_mode.md](../../systems/endless_mode.md) (fill it), [core_run.md](../../systems/core_run.md),
> [wave_director.md](../../systems/wave_director.md), [reaper_boss.md](../../systems/reaper_boss.md),
> [challenges.md](../../systems/challenges.md), [save_manager.md](../../systems/save_manager.md),
> [game_flow.md](../../systems/game_flow.md), [settings.md](../../systems/settings.md) (statistics)

## Goal
Once Obsidian Garden level 1 is cleared, Home offers ENDLESS: one shared floor, the equipped arena skin,
waves and bosses from cleared Rifts, harder every boss cycle, running until death, with its own best
score and wave. The daily run uses the same rules with a fixed pool.

## Where things are today
| Concern | Location |
|---|---|
| Arena from a Rift | `GameWorld._apply_rift()` (background, rule twist, portals, drift, boss interval); `_compute_arena_polygon()` maps `RiftData.floor_polygon` through `_backdrop_image_rect()`; `_compute_arena_rect()` uses `ARENA_FLOOR_UV` and `ARENA_MIN_VIEWPORT_FRACTION` |
| Difficulty | `_apply_rift_difficulty()` → `WaveDirector.set_rift_threat_multiplier(RiftData.get_threat_multiplier(level))`; `RiftData.enemy_speed_scale` |
| Roster | `_spawn_enemy()` → `RiftData.substitute_enemy(kind)` |
| Boss | `_start_boss_encounter()` → `_get_boss_variant()` from `RiftData.boss_id` → `BOSS_VARIANTS` |
| Daily run | `Main._show_daily`, `_show_game`, `ChallengeTracker.get_daily_seed`; daily bests in `daily_state` |
| Depth milestones | `SaveManagerService.claim_depth_milestones()` on `highest_wave`; waves 5/10/15/20/25 |
| Floor template | `concept_art/wisp_rush_endless_v1/floor_template.json`; `tools/art/make_endless_floor_template.py` |

## Tasks
1. **Arena rules in one place.** GameWorld must never fake a `RiftData` for Endless. Recommended: an
   `ArenaRules` contract (`RefCounted`, `res://scenes/gameplay/arena_rules.gd`) that GameWorld reads
   for the background texture, UV floor polygon, rule key, boss wave interval, threat multiplier,
   enemy speed scale, the enemy substitution for a wave and the boss id for a boss index. Implement it
   twice: `RiftArenaRules` (a `RiftData` + level) and `EndlessArenaRules` (catalog + skin + pools +
   cycle). Any single equivalent seam is fine; scattered `if mode == endless` checks are not.
2. **Data.**
   - `ArenaSkinData` (`res://scripts/resources/arena_skin_data.gd`): `skin_id`, `display_name`,
     `description`, `background: Texture2D`, `price: int`, `accent: Color`, `placeholder: bool`.
     **No floor polygon field** — ADR-0014.
   - `EndlessTuning` (`res://scripts/resources/endless_tuning.gd`): starting values in
     [endless_mode.md](../../systems/endless_mode.md).
   - `EndlessCatalog` (`res://scripts/resources/endless_catalog.gd`,
     `res://data/endless/default_endless_catalog.tres`): `floor_polygon`, `skins`, `default_skin_id`,
     `tuning`; `get_skin(id)`, `get_arena_of_the_day(date_key)`, `validate()`.
   - `floor_polygon` holds the eight `polygon_uv` vertices of `floor_template.json`.
     `test_endless_catalog` reads the JSON (`FileAccess`, `res://concept_art/...`) and asserts equality
     within 1e-4.
3. **Development placeholder skin.** Run
   `python3 tools/art/make_endless_floor_template.py --placeholder assets/art/environment/endless/placeholder_void_slate.png`.
   Add `res://data/endless/skins/placeholder_void_slate.tres` (`placeholder = true`, price 0, the
   default), an ASSETS.md row marked "placeholder, never ships" and a ROADMAP M6 line. Phase 5 replaces it.
4. **Unlock and pools** (`ContentUnlocks`): `is_endless_unlocked(rift_levels)` (Obsidian Garden level ≥ 1);
   `get_endless_roster_rift_ids(rift_levels, catalog)` and `get_endless_boss_ids(rift_levels, catalog)`,
   both returning the Rifts with level 1 cleared, in ladder order.
5. **Endless run** (mode `&"endless"`).
   - Background: the equipped skin (fallback: default). Floor: the catalog polygon, mapped exactly like
     Rift polygons. `_compute_arena_rect()` is unchanged.
   - No rule twist: no portals, shrink, drift or boss rush.
   - Each non-boss wave picks one roster Rift with an RNG seeded from `run_seed` and the wave number;
     never the same roster twice in a row when two or more exist. Every enemy in that wave uses its
     substitutions.
   - Every `boss_wave_interval` waves, pick one boss id the same way, again with no immediate repeat.
     A victory raises the cycle, updates threat and speed from `EndlessTuning`, and resumes waves; it
     never ends the run.
   - Death ends the run. Summary: `mode`, `skin_id`, `wave`, `score`, `bosses`, `cycle` and the RP fields.
   - Optional polish: the wave callout names the roster, e.g. `EMBER HOLLOW WAVE`.
6. **Daily run** (mode `&"daily"`). Endless rules with the date seed,
   `EndlessTuning.daily_roster_rift_ids` and `daily_boss_ids` (player progress ignored), and
   `EndlessCatalog.get_arena_of_the_day(date_key)` regardless of ownership. The Daily screen names the
   arena. Available from first launch. The same date gives identical spawns on every save.
7. **Save** (bump the schema). Add `endless_best_score`, `endless_best_wave`, `endless_runs`,
   `endless_intro_seen: bool`, `owned_arena_skins` (default skin owned) and `equipped_arena_skin`.
   Unknown skin ids sanitize to the default. `record_run`: an Endless run updates its bests and count;
   a daily run keeps `daily_state` and leaves the Endless best score alone.
8. **Depth milestones** keep keying on `highest_wave`. Story runs never pass wave 4 and the first
   milestone is wave 5, so only Endless and daily runs pay them — no migration needed; update the docs.
9. **Home and Results.**
   - The ENDLESS button stays hidden until `is_endless_unlocked`. Place it in the PLAY row, opposite
     RIFTS, and confirm on the QA sheet. It shows a NEW badge until the first Endless run sets
     `endless_intro_seen`. One tap starts Endless with the equipped skin.
   - The top bar's BEST shows the selected Rift's best until Endless opens, then `endless_best_score`.
   - The clear that opens Endless adds an `ENDLESS UNLOCKED` banner to phase 2's unlock banners.
   - Endless and daily Results: `WAVE w`, score and best, RP lines, depth reward; primary PLAY AGAIN;
     secondary HOME.
10. **Statistics:** Endless best score, best wave and runs.
11. **Trials:** tier 4+ wave goals now complete in Endless and daily runs.

## Tests
- `tools/godot/test_endless_catalog.gd`: polygon equals the JSON; every background 941×1672; unique
  ids; default present; placeholder skins flagged.
- `tools/godot/test_endless_mode.gd`:
  - locked until Obsidian Garden level 1; pools grow with clears;
  - the same seed gives the same rosters and bosses, with no immediate repeats;
  - a boss victory raises the cycle and resumes;
  - two skins give identical screen-space floors at 1080×2340;
  - the daily run ignores progress and ownership.
- `test_dash_geometry`: add the template to the on-boundary property sweep and the 8-direction landing test.
- Update `test_save_manager` (migration, sanitizing), `test_menu_screens` (ENDLESS visibility and badge),
  `test_main_progression_flow` (Home → Endless → Results → PLAY AGAIN) and `test_challenge_tracker`
  (daily determinism).
- QA matrix: add `endless` (a run on the placeholder) and `results_endless`.

## Docs
endless_mode.md → 🔄 (✅ after phase 5); challenges.md, core_run.md, wave_director.md, reaper_boss.md,
meta_progression.md (depth), save_manager.md, game_flow.md, settings.md; PROJECT_CONTEXT §5.1, §5.2 if a
new key scene appears, §5.8 (`ArenaSkinData`, `EndlessTuning`, `EndlessCatalog`); ASSETS.md (placeholder);
ROADMAP M10 spec 03 ✅ and the M6 placeholder line; DEVLOG entry.

## Acceptance
- [ ] ENDLESS appears only after Obsidian Garden level 1, with a NEW badge until played.
- [ ] An Endless run uses only cleared Rifts' rosters and bosses, never ends on a boss, and gets harder
      every cycle.
- [ ] Changing the skin changes only the background; the wall is identical.
- [ ] The daily run is identical on two fresh saves for the same date.
- [ ] Endless bests persist, and depth milestones never pay twice.
- [ ] `tools/validate.sh` OK · `tools/run_tests.sh` 0 failed · MCP run clean · QA sheets: home, endless,
      results_endless, daily.
