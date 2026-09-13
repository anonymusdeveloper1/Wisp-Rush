# Devlog

> Append-only session log, **newest first**. One entry per work session; format in
> [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) §7.6. Keep entries short — details belong in the docs
> they changed.

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
