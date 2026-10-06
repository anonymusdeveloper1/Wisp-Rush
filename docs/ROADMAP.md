# Roadmap

> Milestones and the task backlog. Status legend: ⬜ todo · 🔄 in progress · ✅ done · ⛔ blocked · ✖ superseded.
> Keep items small and verifiable ("player can dash through enemies with 0.15 s i-frames", not
> "improve movement"). Move finished items to ✅, don't delete them within the active milestone.

## Milestone 0 — Project setup
- ✅ Godot 4.7 project scaffold (folders, project.godot, bootstrap scene)
- ✅ Validation tooling (`tools/validate.sh`, `tools/project_map.mjs`)
- ✅ Agent docs, documentation rules, Claude Code config (subagents, skills)
- ✅ Godot MCP server connected (see ADR-0002)
- ✅ Receive and reconcile the game prompt → fill `docs/GDD.md`
- ✅ Receive the asset pack → inspect and intake production art per `docs/ASSETS.md`
- ✅ Define release milestones from the GDD

## Milestone 1 — Playable vertical slice (complete)

- ✅ Full-bleed responsive arena at phone, tablet and desktop aspect ratios
- ✅ Home → Play → Pause/Resume/Home flow with production art
- ✅ Wisp states, touch/mouse/keyboard aim, exact ray-to-edge dash and wall focus
- ✅ Soul Wisp formation, swept dash collision, score and combo feedback
- ✅ Player health, contact damage, invulnerability, death/results and fast restart
- ✅ Integrated first-run tutorial: wall dash → single slice → triple reap (✖ superseded 2026-09-15 by the Tutorial screen, Milestone 12)

## Milestone 2 — Endless run (complete)

- ✅ Resource-driven threat budget and 20 validated formation templates
- ✅ Shard Wraith and Bone Mote behaviours
- ✅ Split crystal, spike bloom and blade-ring hazards
- ✅ XP curve, upgrade selection and the functional mutations (eight; SOUL VESSEL became a world
  drop on 2026-09-19, leaving seven cards)
- ✅ Complete scoring, Soul Shard drops and run statistics

## Milestone 3 — Reaper and progression (complete)

- ✅ Three-phase Reaper encounter and post-boss difficulty cycle
- ✅ Versioned, atomic local save with corrupt-save recovery/migration
- ✅ Six cosmetic forms with purchase, preview and equip flow
- ✅ Local challenges and deterministic Rift of the Day

## Milestone 4 — Product surface and feel (complete except device pass)

- ✅ Loading, Forms, Statistics, Settings and About/Privacy screens; final Results polish
- ✅ Final VFX, generated or supplied audio, buses, haptics and reduced motion
- ✅ Mobile lifecycle, Android back, cutout-safe HUD and interruption handling
- 🔄 Debug overlay (F3) and VFX pooling done; representative-device performance pass needs a physical Android phone / iPhone

## Milestone 5 — Polish pass (pre-release)

> Owner decision 2026-09-11: no store release yet; mobile phones are the only target (no tablet or
> desktop QA). Planned identifier `com.cognitix.wisprush` — not configured until release.

- ✅ Reproducible phone QA matrix: `tools/qa_matrix.sh` (10 screens × 5 phone aspect ratios → contact sheets)
- ✅ Layout fixes from the QA matrix: phone readability pass — 40 small labels raised from 16–20 to 22–26 design px (HUD, Daily, Forms, Home, Results, upgrade cards, tutorial) with HUD offsets retuned; no clipping or overflow at any phone size
- ✅ Placeholder sweep: Home footer shows the real version; no stale HUD label
- ✅ Screen fade transitions and button press feedback
- ✅ Performance benchmark `tools/godot/bench_stress.gd` (windowed on the M2 at 390×844 with vsync off: avg 2.4 ms, p95 3.6–3.9 ms at both 10 and 45 enemies, but 3–4 isolated 37–44 ms spikes per 840 frames regardless of load — check for first-use hitches on a real phone)
- ⬜ Owner: clean art re-export (checkerboard, clipped Reaper), audio listening pass, on-device feel pass
- ⬜ Direction, monetisation and design changes — discussion with the owner next

## Redesign v1 — visual overhaul (integrated 2026-09-11)

> Owner request: archive the current art and adopt the Codex redesign pack
> (`concept_art/wisp_rush_redesign_v1/`). Decision: [ADR-0005](decisions/0005-visual-redesign-v1.md).

- ✅ Legacy art archived to `assets/legacy_v1/` (ignored); redesign art generated into the same runtime paths
- ✅ Reproducible art pipeline `tools/art/extract_redesign.py` (slicing, checkerboard matting, black→alpha VFX, legacy-occupancy normalisation)
- ✅ Project Theme from the frame kit + `Palette`; every screen restyled to the six-screen board
- ✅ Gameplay telegraphs recoloured (amber = where/when, magenta = execution); new splash configured
- ✅ Gameplay composition ([ADR-0006](decisions/0006-inset-playfield-and-larger-sprites.md)): playfield inset to the painted floor; sprites and hitboxes ×1.3–1.45
- ⬜ Brighten dark icons (`18_reaper`, `17_lock`, `13_daily`) in the pipeline; add a back-chevron icon
- ⬜ One shared number formatter (thousands separators) across screens and tests

## Milestone 6 — Release readiness (later)

- 🔄 Android debug device build works: `export_presets.cfg` preset "Android" (arm64, portrait,
  `com.cognitix.wisprush`, gradle build off), ETC2/ASTC VRAM compression enabled in project settings,
  Godot 4.7.2 Android export templates + a local debug keystore installed, JDK path set in Godot's
  editor settings. Launcher and adaptive icons done 2026-09-24 (`tools/art/make_app_icon.py`). Still open: iOS preset,
  release signing and store config
- ⬜ Release README, privacy disclosures and asset-licence confirmation
- ⬜ No debug/legacy/placeholder content in the release export (the Endless placeholder skins are gone, 2026-09-15)
- ✅ Endless skins: all 30 real skins pass spec 05's checker and eye review and are extracted and wired with `placeholder = false`; `placeholder_void_slate` saves map to `astral_observatory` (2026-09-15). Device pass pending
- ⬜ Rift Points pacing calibrated on a device: `EconomyTuning.placeholder` (`res://data/economy/default_economy_tuning.tres`) is a headless bot estimate and must be `false` before release; the level-clear bonus (20 + 10/level, repeats 25 %) is a starting value in the same file (specs 01–02, [shop.md](systems/shop.md))
- ⬜ Home's SHOP and NO ADS wired to real billing, or hidden, before any store release (ADR-0012)
- ⬜ Tutorial screen placeholder replaced before release: the code-drawn ghost hand (`scenes/tutorial/tutorial_ghost_hand.gd`, glowing fingertip + stem, no hand art exists); its arena is SIMULATION, the one arena ([tutorial.md](systems/tutorial.md))

## Milestone 7 — Engagement core (complete)

> Owner decision 2026-09-12: Wisp Rush keeps **one** endless mode. Engagement comes from layers
> around it, not a second mode. Sequencing is M7 → M8 → M9; Milestone 6 (release readiness) lands
> after M9.
>
> Why this first: nothing carries over between runs today. The only Soul Shard sink is the six
> cosmetic forms — exactly 4,750 shards — after which the currency is inert and every run looks
> identical. Permanent progression is the missing return reason.
>
> **Superseded 2026-09-14 ([ADR-0013](decisions/0013-rift-story-levels-endless-mode-and-rift-points.md)):**
> two modes (Rift story levels + a cosmetic Endless mode); the Soul Sanctum is removed in M10, and the
> return reasons become Rift levels, Endless, Rift Points cosmetics and the Trials.

- ✅ Soul Sanctum: permanent node tree bought with Soul Shards, applied at run start, power-capped
      so a maxed account gains no more than ~20 % (GDD §6: permanent progress must not trivialise starts)
- ✅ `SanctumNode` / `SanctumCatalog` Resources plus authored `data/sanctum/*.tres`
- ✅ Save schema: node levels, `SCHEMA_VERSION` bump and migration of existing saves
- ✅ Sanctum screen reachable from Home, styled only through the Theme's type variations
- ✅ Trials ladder: three active persistent goals → complete all three → rank up, harder triplet, shards
- ✅ `TrialData` / `TrialCatalog` plus 36 authored trials across 12 tiers
- ✅ Depth milestones: one-time shard rewards at waves 5/10/15/20/25, surfaced on Results
- ✅ In-engine motion polish: squash/stretch, easing, idle bob, telegraph pulses — no new art
- ✅ Headless tests: sanctum economy and power cap, trial ladder progression, save migration

## Milestone 8 — Rifts and bosses

> **History since 2026-09-25:** the owner removed the story Rifts from the game (GDD §14 #48). The Rift
> backdrops, props and rule twists are gone; the enemy families and bosses built here stay in Endless.

> Arenas only earn their cost if they change the **rules**; a repainted rectangle is a reskin the
> player notices once. Each Rift = background + one rule twist + its own mission chain and best score.
> Art is generated by the owner from `concept_art/wisp_rush_rifts_v1/GENERATION_PROMPTS.md` and
> integrated through the existing `tools/art/extract_redesign.py` pipeline.

- ✅ Void portal hazard — specified in GDD §5.4, never built; preserves or predictably rotates dash direction
- ✅ Obsidian pillar hazard — specified in GDD §5.4 and the tutorial doc, never built; dash stop/bounce
- ✅ Rift framework: per-Rift rule modifier, unlock condition, own best score and mission chain
- ✅ Shattered Rift (portals) · Ember Hollow (shrinking floor) · Frozen Choir (drift after impact) ·
      Reaper's Court (boss every two waves, double rewards)
- ✖ Three to five missions per Rift gating the next unlock — superseded by level-1 clears (ADR-0013)
- ✅ Second boss, or a Reaper variant with a swapped phase — one boss forever is the fastest source of staleness
- ✅ Owner: generate the four Rift backgrounds, props, enemies and Hollow Choir boss sheets; hand
      back `wisp_rush_rifts_v1.zip`
- ✅ Owner: generate Wave 2 Fracture/Cinder Maw bosses and four per-arena enemy families; hand back
      `wisp_rush_rifts_v2.zip`
- ✅ Wire the new art through a v2 slice spec and re-run the art pipeline
- ✅ New arena backgrounds must keep their usable floor inside `ARENA_FLOOR_UV` (ADR-0006) or re-measure it

## Milestone 10 — Rift story levels, Endless mode and Rift Points

> **2026-09-25:** the story half of this milestone is history — the owner removed the story Rifts
> (GDD §14 #48). Endless, Rift Points and the Shop stay.

> Owner direction 2026-09-14 ([ADR-0013](decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [ADR-0014](decisions/0014-endless-arenas-share-one-floor-template.md)). Build order and acceptance
> checks: [docs/specs/story_and_endless/](specs/story_and_endless/README.md). Sequencing: M10 → the rest
> of M9 → M6.

- ✅ Direction recorded: GDD rewrite, ADR-0013/0014, specs 01–05, planned system docs
- ✅ Endless floor template (`concept_art/wisp_rush_endless_v1/floor_template.json`), its image tool and the three skin prompts
- ✅ Owner approved the whole plan on 2026-09-15 ("follow this to change the fundamentals"), GDD §14 #12–#19 included
- ✅ Spec 01 — Soul Shards → Rift Points; Sanctum removed with refund; save v6; performance bonus; Remove Ads without currency (2026-09-15; bot-estimated `score_per_rift_point`, GDD §14 #22)
- ✅ Spec 02 — One level per Rift run; level-1 clears open the next Rift; victory/defeat Results; Trials audit (2026-09-15; implementation only, headless tests not updated or run by owner request — device pass pending)
- ✅ Spec 03 — Endless mode on the floor template with cleared-Rift rosters and bosses; Endless bests; daily run on Endless rules (2026-09-15; implementation only on the placeholder skin, headless tests not written/updated/run by owner request — device pass pending)
- ✅ Spec 04 — Rift Points Shop tabs (Wisps, Dashes, Arenas, No Ads); dash styles; Forms screen retired (2026-09-15; implementation only, headless tests not written/updated/run by owner request — device pass pending)
- ✅ Endless skin art generated on the floor layout: all 30 skins instead of three (Codex ImageGen from the owner's prompt, 2026-09-15)
- ✅ Spec 05 — Validate, extract and wire the Endless skins; placeholder removed (2026-09-15: all 30 skins from the manifest, tier prices, lossy import, Shop thumbnails, animated Legendary/Mythic scenery (`ArenaAmbience`; rebuilt 2026-09-16 on masks + scenery shader + particles), `test_endless_catalog`. Pending: device pass)
- ⬜ Device pass: Rift Points pacing (35–45 RP per median early run) and Endless difficulty per cycle
- ✅ Story Rifts removed (owner, 2026-09-25): Rift Map, story runs, the five Rifts' twists, backdrops and
      floors, level clears; save v9. Endless keeps the five enemy mixes and the boss pool as `EndlessRoster`s
      and plays exactly as before
- ✅ Owner: approve new wording for the player-facing texts that still say "Rift" (daily run, Trials,
      statistics, wave callouts, pause, Results, tutorial); the currency keeps the name Rift Points
      (approved and applied 2026-09-25, GDD §14 #48)

## Milestone 11 — RUSH mode and fast feel

> Owner decision 2026-09-15: four base mechanics make runs feel faster; the "Essences" power-up idea
> is not planned. Rules: GDD §5.6 and §14 #27. Build steps: [docs/specs/rush_and_feel/](specs/rush_and_feel/README.md).

- ✅ Spec written, GDD §5.6 added
- ✅ One owner for `Engine.time_scale` (hit-stop + finisher); chain momentum counted in game time
- ✅ Momentum you can see: trail length and brightness, dash pitch, speed lines at max
- ✅ Auto-collect: floor shards fly to the Wisp at wave and boss changes and before the run ends
- ✅ Slow-motion finisher: 5-kill dash, field clear (6 s cooldown), boss killing blow
- ✅ RUSH meter and RUSH mode: 6 s of ×1.3 speed, ×2 score, frozen combo, no damage, peak music
      ([rush_mode.md](systems/rush_mode.md); built 2026-09-15, validate.sh only — no tests by owner preference)
- ⬜ Tests when wanted: `test_rush_mode.gd`, `test_run_feel.gd` (spec Verify section)
- ⬜ Device pass: how often RUSH fires per Endless run, and how the finisher feels

## Milestone 12 — Tutorial screen

> Owner decision 2026-09-15: a separate Tutorial screen teaches every base mechanic, easiest first, as
> "show, then you try" lessons; real runs never teach. Rules: GDD §11, §14 #29. System: [tutorial.md](systems/tutorial.md).

- ✅ Nine lessons (aim & dash, slice, chain, redirect, blockers, danger, Rift Points & XP, RUSH, boss)
      in `data/tutorial/default_tutorial.tres`; ghost-hand demo drives the real Wisp (boss lesson: hand only)
- ✅ `RunProfile.tutorial` scripted arena + GameWorld run event signals and scripted-run hooks; in-run lesson,
      `TutorialOverlay`, `tutorial_enabled`/`tutorial_completed` and `test_tutorial_flow.gd` removed
- ✅ First launch opens the Tutorial after Loading; SKIP confirm; replay only from the Rift Map TUTORIAL button;
      Settings' REPLAY TUTORIAL removed (built 2026-09-15; validate.sh + one deleted smoke walk, no permanent tests by owner preference).
      Settings' replay came back on 2026-09-24; the Rift Map was removed on 2026-09-25
- ⬜ Device pass: lesson difficulty (the mid-dash redirect window is short), caption length on small phones,
      ghost-hand readability, Android back into the skip confirm
- ⬜ Tests when wanted: a tutorial flow test (director walk, first-launch and Settings replay routing); stale tests that
      boot Main now mark the tutorial completed first

## Milestone 13 — Playable characters

> Owner request 2026-09-17 (three concept sheets, via a ChatGPT-written brief): "implement the three
> attached character designs as selectable PLAYABLE CHARACTERS", then "implement just one for now so
> i can see how it looks like", then (after Codex ran out of quota) "finish what he started, make
> sure the animations work and are smooth in the gameplay and also add animation in the character or
> wisp selecter and they are not just wisps but characters". Rules: GDD §6, §9, §14 #31,
> [ADR-0015](decisions/0015-animated-playable-characters.md). System:
> [playable_character_visuals.md](systems/playable_character_visuals.md).

- ✅ Layer art for all six production characters extracted from the generated sheets (`make_rig_source.py` →
      `extract_playable_characters.py`; versioned source packs keep v1 output byte-identical)
- ✅ Shared presentation-only rig: 13 states in a runtime AnimationTree, heading spring, travel-axis
      squash, interrupts, particle rules, `ChainSpring` follow-through, skinned `RibbonChain` ribbons
- ✅ Veyra (Codex prototype, rebuilt), Rook and Morrow rigs with their own secondary motion and trails
- ✅ Characters in the catalog, save ids and Shop; CHARACTERS tab with every card animated, plus
      selected and unlock flourishes; live hero on Home
- ✅ Verified: `playable_character_visual` (states, smoothness, menus, GameWorld), `form_catalog`,
      lineup/motion/showcase fixtures reviewed frame by frame
- ⛔ **Retired 2026-09-20** (GDD §14 #34): the Ilyra and Bram rigs are gone and the roster is cut
  to seven. New characters are whole-frame sprites — `docs/guides/character_creation.md`.
- ✅ **Animation set cut to five 2026-09-20** (GDD §14 #36): a drawn character is the dash (which is
      also the attack), three wall loops and one storefront idle. The windup, landing, drift, hit,
      death, spawn, victory and both menu reactions are carried by the controller instead. 120 frames
      on three sheets → 40 on two; ~107 MB → ~30 MB of texture per character
- ✅ **Menu videos 2026-09-21** ([ADR-0016](decisions/0016-menu-videos-for-character-storefronts.md), GDD §14 #37):
      Shade (magenta key) and Ilyra (green key, her ready stance) play AI-generated clips on Home and
      the Shop card through `CharacterMenuVideo`; `tools/art/extract_menu_video.py` keys, loops, packs
      and encodes them with Godot's Movie Maker
- ✅ **No bounce when a character is picked, bought or equipped** (owner, 2026-09-21; GDD §14 #38)
- ⬜ Before a third menu video: play only the focused Shop card's clip (two neighbouring cards can
      decode at once today)
- ✅ **Scarlet replaces Ilyra** (owner, 2026-09-26, GDD §14 #52): in the game from the owner's four
      AutoSprite sheets (`concept_art/scarlet_autosprite_v1/`), sliced and cleaned (made at 166 px,
      drawn 1.16× larger so she is the same size as everyone, #54); her own id, scene, data and effects (her reap crescents and crown diamond as
      particles, Ilyra's twin-arc dash look in her blue, splash landing). Ilyra removed completely
      (scene, art, menu video, data, tests, source art). Owner phone test pending
- ✅ **No character tiers** (owner, 2026-09-26, GDD §14 #53): `FormData.tier` and the Shop badge removed
- ✖ **Characters at their own height** (owner, 2026-09-26, GDD §14 #51) — reverted the same day:
      every character the same size again, Scarlet drawn 1.16× larger (#54)
- ✅ **Shade's rework onto the AutoSprite recipe** (owner, 2026-09-25): in the game from the owner's
      five sheets (`concept_art/verdant_shade_autosprite_v1/`): storefront, floor, right wall, its own
      ceiling and a one-shot dash attack at Patchvile's scale; its menus play the storefront instead of
      the video; leaf dash particles, green attack glow, dust landing. Owner phone test pending
- ✅ **Roster cut to five 2026-09-25** (owner, GDD §14 #47): Void, Eclipse, Veyra and Noxen removed;
      Patchvile is the default character
- ✅ **Mothmere** (owner, 2026-09-25): a new character from the owner's Codex poses and four AutoSprite
      sheets (`concept_art/mothmere_autosprite_v1/`): storefront (a staff strike), floor, right wall and a
      one-shot dash (a staff swing with a red reap); keeps his outline (GDD §14 #49); red attack look
      and trail, dust landing. Owner phone test pending
- ✅ **Rook** on the AutoSprite recipe (owner, 2026-09-27, GDD §14 #55–56): the owner's five sheets
      (`concept_art/rook_autosprite_v1/`), cleaned frame by frame, packed at Patchvile's scale; outline
      kept, his own ceiling, a one-shot dash (push, dive, tail-blade swing), his rig's dash look kept;
      his bone rig removed. Owner phone test pending
- ~~Morrow, the last rig, on the AutoSprite recipe~~ — Morrow removed from the game 2026-10-05 (owner,
      GDD §14 #83); his AutoSprite prompt pack went with him. The whole roster is on the recipe
- ✅ Owner-approved v2 designs and implementation handoff: Mythic Ilyra, then Legendary Bram
      (`concept_art/wisp_rush_playable_characters_v2/`, GDD §14 #32)
- ✅ Ilyra (Mythic) implemented and verified through her completion gate: 28 clean layers, all 13
      states, targeted tests, Reduced Motion, Shop/Home/GameWorld screenshots, real run
- ✅ Bram (Legendary) implemented after Ilyra's gate; combined regression (25 pass / 10 pre-existing
      stale), `qa_matrix shop_wisps` 5/5 and the preview benchmark (11 cold 234 ms, warm ~8 ms) run
- ✅ Noxen, the Veilflame (Legendary) basic rig implemented from the approved blue/cyan concept:
      twelve moving groups, two skinned root ribbons, flame-horn dash spear, contact slice,
      storefront flourish, catalog/save/dash-effect integration (2026-09-20; GDD §14 #33)
- ⬜ Owner: approve the look and motion of the six production rigs, then set their prices (all 0 RP now)
- ⬜ Device pass: readability at gameplay size, particle cost and feel on the phone
- ⬜ Optional: mipmaps for the character layers (import-setting decision)
- ✅ High-refresh phones: the simulation now steps at the screen's rate (`FramePacing`), so a dash is
      redrawn at a fresh position every frame at 60, 90 or 120 Hz

## Milestone 14 — Enemies v2
> Owner decisions 2026-09-27 (GDD §14 #58): every current enemy, boss and enemy mix goes; a new set,
> starting with 6 enemies and 3 bosses, each its own design, animated from sprite sheets and mixed at
> random in Endless. Design: [specs/enemies_v2/](specs/enemies_v2/README.md), with how to make them
> in AutoSprite only ([autosprite_workflow.md](specs/enemies_v2/autosprite_workflow.md)).

- 🔄 Define the 6 enemies and 3 bosses with the owner (look, theme, movement, attacks, hits, sheets):
      roles and rules recorded 2026-09-27; the sixth role and every look still open (the owner is
      collecting references)
- ⬜ Owner: Codex first frame and AutoSprite sheets for each enemy and boss (Grimgrin's six sheets
      delivered 2026-09-27)
- 🔄 Grimgrin, the melee boss: in the game 2026-09-27 as the first boss of every Endless run
      ([grimgrin_boss.md](systems/grimgrin_boss.md)); owner phone test pending
- ✅ Green ranged boss: central ranged fight, own green wisps and healing recall documented;
      six source poses and AutoSprite prompts prepared 2026-10-05
      ([boss_ranged.md](specs/enemies_v2/boss_ranged.md)); animation sheets and runtime still pending
- 🔄 Build the new enemies, bosses and the random ramp; remove the current enemies, bosses and mixes in
      the same step: **five enemies, the ramp and the removal of every old enemy done 2026-09-28**
      ([enemies.md](systems/enemies.md), GDD §14 #62; the mixes no longer change the enemies); owner phone
      test pending; the sixth enemy, two bosses and the removal of the old bosses and rosters to come

## Milestone 15 — Enemy pickups and consumable item packs

> Owner request 2026-10-05: replace run upgrades with the accepted seven drops; Items Shop packs
> of 1, 5, 10 and 25. [Pickup items](systems/pickup_items.md), GDD §14 #76–77, ADR-0026.

- ✅ Seven packed pixel icons and physical enemy drops; temporary effects replace live XP/cards
- ✅ Persistent Ward stock, double-tap protection and brief escape immunity
- ✅ RP packs for Ward, Magnet and Fortune Star; one-use selected next-run Magnet/Star
- ✅ Ordinary/board HUD indicators and replacement tutorial lesson; isolated integration checks
- ✅ Portrait phone QA: Items and gameplay at five aspects; BOARD 01 and SIMULATION HUD review
- ⬜ Owner device/feel pass for provisional prices, durations and drop rate

## Milestone 16 — One arena and the Shop's bottom navigation

> Owner request 2026-10-05: remove the arena toggle and every arena but SIMULATION, from the code too;
> a bottom navigation in the Shop (CHARACTERS, SHOP) with the back button at the top; a place to buy
> Rift Points. GDD §14 #78, [ADR-0027](decisions/0027-one-arena-simulation.md),
> [ADR-0028](decisions/0028-shop-bottom-navigation-and-rift-points-packs.md).

- ✅ Every arena but SIMULATION removed (scenes, scripts, shaders, runtime art, the painted-background
      path, arena-only tools); the Tutorial on SIMULATION; old saves fall back to it
- ✅ Shop: BACK at the top, a bottom navigation with CHARACTERS and SHOP; SHOP lists NO ADS, ITEMS and
      RIFT POINTS; the bottom navigation made bigger (owner)
- ✅ Rift Points packs (500 / 1,200 / 2,500 / 6,500 RP, placeholder prices), disabled until billing
- ⬜ Owner phone test

## Milestone 9 — Monetisation

> Owner decision 2026-09-12: **free with opt-in rewarded video plus one "Remove Ads + Shard Pack" IAP.**
> Never interstitials — a forced ad between three-minute runs breaks the "immediate momentum" pillar
> (GDD §2). Blocked on M7 shipping and showing healthy day-1/day-7 retention.
> **2026-09-14:** the pack carries no currency — Remove Ads only, and Rift Points can't be bought (ADR-0013).
> **2026-10-05 (owner):** Rift Points are sold in packs for real money (ADR-0028). Interstitials after
> every second run join the rewarded ads, on Google AdMob with test ad units (ADR-0029).

- ✅ ADR-0009: monetisation model, SDK choice and the privacy consequences
- ⬜ GDD §12/§13 amendment — the "offline, no data collection, no fake purchases" promise no longer
      holds unqualified once an ad SDK ships
- ✅ Ad SDK integration behind a service wrapper, so gameplay code never calls the SDK directly
- 🔄 Google AdMob on test ad units (2026-10-05, ADR-0029): interstitial after every second run, rewarded
      revive once per run and double Rift Points at Results, Google's consent form; owner phone test
      pending; the owner's App ID and ad units, a privacy policy and a Settings privacy-options entry
      before release (the upgrade reroll has nothing to reroll since ADR-0026)
- 🔄 IAP through Google Play Billing (2026-10-05, ADR-0030): Remove Ads (acknowledged, restored at start)
      and the four Rift Points packs (saved, then consumed; pending payments; crash recovery); waits for
      Play Console ([checklist](guides/play_console_setup.md))
- 🔄 Cloud save on the player's Google account (Play Games Saved Games, newest save wins; ADR-0030):
      built and tested with stand-ins; the Play Games plugin is enabled once Play Console gives its project ID
- ✅ Shop screen UI (Remove Ads bundle, Restore) reachable from Home's SHOP and NO ADS, purchases
      disabled until a store is connected ([ADR-0012](decisions/0012-store-surface-before-billing.md))
- ✅ Rift Points packs on the Shop's SHOP page, sold through the same store contract and disabled until a
      store is connected (2026-10-05, [ADR-0028](decisions/0028-shop-bottom-navigation-and-rift-points-packs.md))
- ⬜ `AdProvider` price query, so BUY can show the localized price
- ⬜ Consent flow (GDPR / ATT) and a published privacy policy
- ✅ Verify no ad or IAP code path can block, delay or interrupt a run start

## Backlog
| Item | Notes |
|---|---|
| Redraw painted art as pixel art (ADR-0018) | The game is 2D pixel art (owner, 2026-09-24). Legacy painted art: enemies, bosses, VFX sprites (the Quarry Titan and Wisp Bearer arenas were removed 2026-10-05, ADR-0027), and the characters that are not yet reworked. Characters first (Patchvile done, Ilyra next), then the UI (integration in progress), then the arenas and the world |
| Pixel-exact drawing of characters (nearest filtering, whole-number scale) | Not decided. A version was built and reverted on 2026-09-24 (owner). Equal detail across the roster is handled instead by the roster size: Patchvile's pixel count and scale for everyone ([character_creation.md](guides/character_creation.md) §3–§4) |
| ~~Fix the Void pack's canvas overrun at source~~ | Obsolete 2026-09-25: Void was removed from the game |
| ~~Fix the Verdant Shade pack's frame cut at source~~ | Obsolete 2026-09-25: Shade is rebuilt from AutoSprite sheets, and the Codex pack is only the source of its first frames (whose slivers `build_first_frames.py` removes) |
| ~~Ornament / VFX textures for Verdant Shade~~ | Done 2026-09-25: its dash throws its own loose leaves, cut from the AutoSprite right-wall frame (`verdant_shade_leaves.png`), with green trail motes |
| Evaluate a dedicated test framework | Raw headless SceneTree checks are sufficient today; add an ADR only if suite growth warrants a dependency |
| Desktop distribution export | mobile release is primary; desktop remains a debug target |
| Clean art re-export: baked checkerboard (logo, Reaper) and clipped Reaper cells | Title logo and all eight Reaper PNGs have a grey checkerboard painted into their semi-transparent halos, and several Reaper cells (e.g. scythe strike) clip the art at the 444 px cell edge; the master sheet has the same cuts, so this needs a clean re-export from the art source. |
| Tune synthesized audio mix and feel on a device | SFX trims in `audio_synth.gd`; shake/haptic constants in `game_world.gd` |
| Watch for "ObjectDB instances leaked at exit" | seen once on a windowed boot; not reproduced in a 700-frame `--verbose` run |
| Optional monetisation providers | only with real store services and a separate ADR |
