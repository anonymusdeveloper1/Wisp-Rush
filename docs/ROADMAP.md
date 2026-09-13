# Roadmap

> Milestones and the task backlog. Status legend: ⬜ todo · 🔄 in progress · ✅ done · ⛔ blocked.
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
- ✅ Integrated first-run tutorial: wall dash → single slice → triple reap

## Milestone 2 — Endless run (complete)

- ✅ Resource-driven threat budget and 20 validated formation templates
- ✅ Shard Wraith and Bone Mote behaviours
- ✅ Split crystal, spike bloom and blade-ring hazards
- ✅ XP curve, upgrade selection and all eight functional mutations
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
- ⬜ No debug/legacy/placeholder content in the release export

## Milestone 7 — Engagement core (complete)

> Owner decision 2026-09-12: Wisp Rush keeps **one** endless mode. Engagement comes from layers
> around it, not a second mode. Sequencing is M7 → M8 → M9; Milestone 6 (release readiness) lands
> after M9.
>
> Why this first: nothing carries over between runs today. The only Soul Shard sink is the six
> cosmetic forms — exactly 4,750 shards — after which the currency is inert and every run looks
> identical. Permanent progression is the missing return reason.

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
- ⬜ Three to five missions per Rift gating the next unlock
- ✅ Second boss, or a Reaper variant with a swapped phase — one boss forever is the fastest source of staleness
- ✅ Owner: generate the four Rift backgrounds, props, enemies and Hollow Choir boss sheets; hand
      back `wisp_rush_rifts_v1.zip`
- ✅ Owner: generate Wave 2 Fracture/Cinder Maw bosses and four per-arena enemy families; hand back
      `wisp_rush_rifts_v2.zip`
- ✅ Wire the new art through a v2 slice spec and re-run the art pipeline
- ✅ New arena backgrounds must keep their usable floor inside `ARENA_FLOOR_UV` (ADR-0006) or re-measure it

## Milestone 9 — Monetisation

> Owner decision 2026-09-12: **free with opt-in rewarded video plus one "Remove Ads + Shard Pack" IAP.**
> Never interstitials — a forced ad between three-minute runs breaks the "immediate momentum" pillar
> (GDD §2). Blocked on M7 shipping and showing healthy day-1/day-7 retention.

- ✅ ADR-0009: monetisation model, SDK choice and the privacy consequences
- ⬜ GDD §12/§13 amendment — the "offline, no data collection, no fake purchases" promise no longer
      holds unqualified once an ad SDK ships
- ✅ Ad SDK integration behind a service wrapper, so gameplay code never calls the SDK directly
- ⬜ Rewarded placements: revive once per run · double Soul Shards at Results · one upgrade reroll
- ⬜ IAP: Remove Ads + Shard Pack, including restore purchases
- ⬜ Consent flow (GDPR / ATT) and a published privacy policy
- ✅ Verify no ad or IAP code path can block, delay or interrupt a run start

## Backlog
| Item | Notes |
|---|---|
| Evaluate a dedicated test framework | Raw headless SceneTree checks are sufficient today; add an ADR only if suite growth warrants a dependency |
| Desktop distribution export | mobile release is primary; desktop remains a debug target |
| Clean art re-export: baked checkerboard (logo, Void form, Reaper) and clipped Reaper cells | Title logo, Void form and all eight Reaper PNGs have a grey checkerboard painted into their semi-transparent halos, and several Reaper cells (e.g. scythe strike) clip the art at the 444 px cell edge; the master sheet has the same cuts, so this needs a clean re-export from the art source. |
| Tune synthesized audio mix and feel on a device | SFX trims in `audio_synth.gd`; shake/haptic constants in `game_world.gd` |
| Watch for "ObjectDB instances leaked at exit" | seen once on a windowed boot; not reproduced in a 700-frame `--verbose` run |
| Optional monetisation providers | only with real store services and a separate ADR |
