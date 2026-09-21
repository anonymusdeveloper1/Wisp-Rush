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
  editor settings. Still open: iOS preset, launcher icons/adaptive icons, release signing and store config
- ⬜ Release README, privacy disclosures and asset-licence confirmation
- ⬜ No debug/legacy/placeholder content in the release export (the Endless placeholder skins are gone, 2026-09-15)
- ✅ Endless skins: all 30 real skins pass spec 05's checker and eye review and are extracted and wired with `placeholder = false`; `placeholder_void_slate` saves map to `astral_observatory` (2026-09-15). Device pass pending
- ⬜ Rift Points pacing calibrated on a device: `EconomyTuning.placeholder` (`res://data/economy/default_economy_tuning.tres`) is a headless bot estimate and must be `false` before release; the level-clear bonus (20 + 10/level, repeats 25 %) is a starting value in the same file (specs 01–02, [shop.md](systems/shop.md))
- ⬜ Home's SHOP and NO ADS wired to real billing, or hidden, before any store release (ADR-0012)
- ⬜ Tutorial screen placeholder replaced before release: the code-drawn ghost hand (`scenes/tutorial/tutorial_ghost_hand.gd`, glowing fingertip + stem, no hand art exists); its arena is the default Endless skin, now real art ([tutorial.md](systems/tutorial.md))

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
- ⬜ Device pass: how often RUSH fires per Rift level and Endless run, and how the finisher feels

## Milestone 12 — Tutorial screen

> Owner decision 2026-09-15: a separate Tutorial screen teaches every base mechanic, easiest first, as
> "show, then you try" lessons; real runs never teach. Rules: GDD §11, §14 #29. System: [tutorial.md](systems/tutorial.md).

- ✅ Nine lessons (aim & dash, slice, chain, redirect, blockers, danger, Rift Points & XP, RUSH, boss)
      in `data/tutorial/default_tutorial.tres`; ghost-hand demo drives the real Wisp (boss lesson: hand only)
- ✅ `RunProfile.tutorial` scripted arena + GameWorld run event signals and scripted-run hooks; in-run lesson,
      `TutorialOverlay`, `tutorial_enabled`/`tutorial_completed` and `test_tutorial_flow.gd` removed
- ✅ First launch opens the Tutorial after Loading; SKIP confirm; replay only from the Rift Map TUTORIAL button;
      Settings' REPLAY TUTORIAL removed (built 2026-09-15; validate.sh + one deleted smoke walk, no permanent tests by owner preference)
- ⬜ Device pass: lesson difficulty (the mid-dash redirect window is short), caption length on small phones,
      ghost-hand readability, Android back into the skip confirm
- ⬜ Tests when wanted: a tutorial flow test (director walk, first-launch and Rift Map routing); stale tests that
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
  to seven. New characters are whole-frame sprites — `docs/guides/character_sprite_frames.md`.
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
- ⬜ Re-cut Ilyra onto the sheet packer: she is the last character drawn from loose PNGs, so her
      `SpriteFrames` still holds every retired painting as a separate texture
- ✅ Owner-approved v2 designs and implementation handoff: Mythic Ilyra, then Legendary Bram
      (`concept_art/wisp_rush_playable_characters_v2/`, GDD §14 #32)
- ✅ Ilyra (Mythic) implemented and verified through her completion gate: 28 clean layers, all 13
      states, targeted tests, Reduced Motion, Shop/Home/GameWorld screenshots, real run
- ✅ Bram (Legendary) implemented after Ilyra's gate; combined regression (25 pass / 10 pre-existing
      stale), `qa_matrix shop_wisps` 5/5 and the preview benchmark (11 cold 234 ms, warm ~8 ms) run
- ✅ Noxen, the Veilflame (Legendary) basic rig implemented from the approved blue/cyan concept:
      twelve moving groups, two skinned root ribbons, flame-horn dash spear, contact slice,
      storefront flourish, catalog/save/dash-effect integration (2026-09-20; GDD §14 #33)
- ⬜ Owner: approve the look and motion of the six production rigs, then set their prices (all 0 RP now),
      including whether Legendary and Mythic should cost more than the rest
- ⬜ Device pass: readability at gameplay size, particle cost and feel on the phone
- ⬜ Optional: mipmaps for the character layers (import-setting decision)
- ✅ High-refresh phones: the simulation now steps at the screen's rate (`FramePacing`), so a dash is
      redrawn at a fresh position every frame at 60, 90 or 120 Hz

## Milestone 9 — Monetisation

> Owner decision 2026-09-12: **free with opt-in rewarded video plus one "Remove Ads + Shard Pack" IAP.**
> Never interstitials — a forced ad between three-minute runs breaks the "immediate momentum" pillar
> (GDD §2). Blocked on M7 shipping and showing healthy day-1/day-7 retention.
> **2026-09-14:** the pack carries no currency — Remove Ads only, and Rift Points can't be bought (ADR-0013).

- ✅ ADR-0009: monetisation model, SDK choice and the privacy consequences
- ⬜ GDD §12/§13 amendment — the "offline, no data collection, no fake purchases" promise no longer
      holds unqualified once an ad SDK ships
- ✅ Ad SDK integration behind a service wrapper, so gameplay code never calls the SDK directly
- ⬜ Rewarded placements: revive once per run · double Rift Points at Results · one upgrade reroll
- ⬜ IAP: Remove Ads (no currency inside — ADR-0013), including restore purchases
- ✅ Shop screen UI (Remove Ads bundle, Restore) reachable from Home's SHOP and NO ADS, purchases
      disabled until a store is connected ([ADR-0012](decisions/0012-store-surface-before-billing.md))
- ⬜ `AdProvider` price query, so BUY can show the localized price
- ⬜ Consent flow (GDPR / ATT) and a published privacy policy
- ✅ Verify no ad or IAP code path can block, delay or interrupt a run start

## Backlog
| Item | Notes |
|---|---|
| Fix the Void pack's canvas overrun at source | `concept_art/void_wisp_sprite_v1/` draws the character larger than its 512 canvas in 21 of 108 frames, so the crystal above its head is severed by the border. `extract_playable_characters.py` removes the severed fragments on intake (2026-09-20 DEVLOG), but the frames should be composed to fit so the crystal survives |
| Fix the Verdant Shade pack's frame cut at source | `concept_art/verdant_shade_sprite_v1/build_sprite_pack.py` cuts each frame with an offset that catches a sliver of the neighbouring phase-atlas cell — 39 of 108 frames carry a severed band above the character. `extract_playable_characters.py` strips it on the way in (2026-09-20 DEVLOG), but the pack should be corrected so the next whole-frame character does not inherit the same cut |
| Ornament / VFX textures for Verdant Shade | She has no loose pieces of her own, so her rig emits no particles and her wake is the painted flames plus the procedural dash signature. Borrowing another character's VFX was deliberately declined (2026-09-20 DEVLOG). A small set — a leaf, an ember, a dash streak — would let her carry a trail like the other characters |
| Evaluate a dedicated test framework | Raw headless SceneTree checks are sufficient today; add an ADR only if suite growth warrants a dependency |
| Desktop distribution export | mobile release is primary; desktop remains a debug target |
| Clean art re-export: baked checkerboard (logo, Void form, Reaper) and clipped Reaper cells | Title logo, Void form and all eight Reaper PNGs have a grey checkerboard painted into their semi-transparent halos, and several Reaper cells (e.g. scythe strike) clip the art at the 444 px cell edge; the master sheet has the same cuts, so this needs a clean re-export from the art source. |
| Tune synthesized audio mix and feel on a device | SFX trims in `audio_synth.gd`; shake/haptic constants in `game_world.gd` |
| Watch for "ObjectDB instances leaked at exit" | seen once on a windowed boot; not reproduced in a 700-frame `--verbose` run |
| Optional monetisation providers | only with real store services and a separate ADR |
