# Spec: Rift story levels, Endless mode and Rift Points

> **Status:** ⬜ ready for implementation · **Written:** 2026-09-14 by Claude Code (Opus 5) ·
> **Rules:** [GDD](../../GDD.md) §3, §5.5, §6, §7, §9, §11–§14 ·
> [ADR-0013](../../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md) ·
> [ADR-0014](../../decisions/0014-endless-arenas-share-one-floor-template.md)
>
> A work order for coding agents. The GDD and ADRs own the rules; these files own the build order,
> the file-level changes and the acceptance checks. If a spec and the GDD/ADR disagree, the GDD/ADR
> win — fix the spec.

## How to use this folder
- **Owner:** give a coding agent this README plus **one** phase file per session, in order. For
  example: "Implement `docs/specs/story_and_endless/01_rift_points.md`. Follow AGENTS.md."
- **Agent:** read [AGENTS.md](../../../AGENTS.md) → [PROJECT_CONTEXT](../../PROJECT_CONTEXT.md) → this
  README → your phase file → the system docs it lists. Finish the phase completely (code, tests,
  docs, DEVLOG) and stop; don't start the next phase.

## What changes
| Area | Today | After this work |
|---|---|---|
| Rift runs | Endless; each boss victory climbs a level inside the run | One level per run; the level's final boss ends it in victory |
| Rift unlocks | Lifetime best wave 5/10/15/20 | Clear level 1 of the previous Rift |
| Endless | — | New mode: one shared floor, cosmetic arena skins, bosses and enemies from cleared Rifts |
| Daily run | Selected Rift and level | Endless rules, fixed pool, arena of the day |
| Currency | Soul Shards | Rift Points (RP), earned only by playing |
| Permanent power | Soul Sanctum (~17 % max) | None — Sanctum removed, spend refunded |
| Spending | Forms screen, Sanctum | Shop tabs: Wisps, Dashes, Arenas, No Ads |
| Real money | Remove Ads + 1,500 shards | Remove Ads only |

## Phases
Do them in order. Each one leaves the game working, tested and documented.

| # | File | Result | Needs |
|---|---|---|---|
| 1 ✅ | [01_rift_points.md](01_rift_points.md) | Rift Points everywhere, Sanctum gone, save migration, performance bonus | — |
| 2 ✅ | [02_story_mode.md](02_story_mode.md) | One level per Rift run, level-clear unlocks, victory and defeat Results | 1 · owner confirms GDD §14 #12 |
| 3 ✅ | [03_endless_mode.md](03_endless_mode.md) | Endless mode and the daily run on Endless rules, with a dev placeholder skin | 2 |
| 4 ✅ | [04_shop.md](04_shop.md) | One RP Shop with four tabs, dash styles, Forms screen retired | 1; Arenas tab needs 3 |
| 5 ✅ | [05_endless_arena_art.md](05_endless_arena_art.md) | 30 real Endless skins validated and wired; placeholder out; Legendary/Mythic ambience | 3, 4 · owner art |

## Rules for every phase
- Godot 4.7.2, typed GDScript, [CONVENTIONS](../../CONVENTIONS.md); call down, signal up; tuning lives
  in `data/*.tres`, never in logic.
- UI only through Theme type variations and `Palette` ([ui_design_system.md](../../systems/ui_design_system.md));
  card pickers reuse `FocusCarousel`. Home keeps the owner's layout and motion rules (GDD §11).
- Save changes: bump `SCHEMA_VERSION`, migrate the previous version, sanitize every new field, and test
  with a hand-built fixture of the old version. Migrations are one-way and stable on reload.
- Keep the game working between phases. No dead buttons, fake purchases or placeholders in a release
  (GDD §13); anything temporary is flagged in data and listed in ROADMAP M6.
- Delete what you replace — files, tests, data, docs rows. No dead code behind flags.
- A design question the GDD doesn't answer: stop and ask the owner with a recommended default. Don't
  invent mechanics (AGENTS.md §2).
- Verify: `tools/validate.sh` → `VALIDATE: OK`; `tools/run_tests.sh` → 0 failed; a Godot MCP run with no
  errors; `tools/qa_matrix.sh <screens>` for every screen you changed; a device run when the owner's
  phone is connected.
- Document in the same phase (PROJECT_CONTEXT §7.2): system docs, registries, the GDD only if a rule
  changes (ask first), the ROADMAP M10 tick and a DEVLOG entry.

## Vocabulary
| Term | Meaning |
|---|---|
| Rift level | One of a Rift's 8 levels; a story run plays exactly one |
| Cleared | A level whose final boss was beaten; banked in `rift_levels` |
| Mastered | All 8 levels of a Rift cleared; the Rift replays level 8 |
| Endless | The never-ending mode on the floor template |
| Arena skin | A purchasable Endless background; it never changes the floor |
| Floor template | The one playable floor shape every Endless skin shares (ADR-0014) |
| RP | Rift Points, the only currency |
| Run profile | Everything a run needs before it starts: mode, Rift and level or skin, seed, cosmetics |

## Done when (after phase 5)
- [ ] A fresh save: tutorial → Obsidian Garden level 1 → victory → `ENDLESS UNLOCKED` and
      `SHATTERED RIFT OPEN` → ENTER SHATTERED RIFT.
- [ ] No Sanctum and no "Soul Shard" text remain (the Shard Wraith enemy and asset file names aside).
- [ ] Endless runs on three real skins with an identical floor; bosses and rosters come only from
      cleared Rifts.
- [ ] The daily run is identical for every player on a given date.
- [ ] The Shop buys and equips forms, dash styles and arena skins with RP; No Ads grants no RP.
- [ ] validate OK, tests 0 failed, QA sheets reviewed, device pass logged in the DEVLOG.

## Open questions for the owner
- GDD §14 #12 — one level per Rift run: confirm before phase 2.
- Prices and RP pacing are starting values; tune them after the device pass.
- Paid cosmetics (custom Wisps, characters) are out of scope and need their own ADR.
