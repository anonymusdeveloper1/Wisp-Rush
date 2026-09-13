# ADR-0010: Rift bosses are data-driven variants of one phase machine

> **Status:** Accepted · **Date:** 2026-09-12 · **Deciders:** Claude Code ·
> **Extends:** [ADR-0007](0007-rifts-as-rule-variant-arenas.md), [ADR-0008](0008-rift-levels-and-difficulty-ladder.md)

## Context
ADR-0008 gave every Rift its own boss to close a level, but only the Reaper existed, so all five
Rifts spawned it. Art then arrived for three more bosses (The Hollow Choir, The Fracture, The
Cinder Maw) plus a planned Reaper recolour.

`ReaperBoss` is 588 lines of tuned three-phase state machine — telegraphed sweep, teleport hunt and
corridor casts with exposed-core windows. It is the most carefully balanced code in the project.

## Options considered
1. **A phase machine per boss** — maximum expressiveness, but four hand-written state machines to
   write, tune and regression-test, and four chances to get the exposed-core window wrong.
2. **One machine, data-driven variants** — each boss is an atlas, a tuning resource, a tint and an
   accent. Bosses differ in look, toughness and pacing but share the proven attack grammar.
3. **Reuse the Reaper unchanged and only recolour it** — cheapest, but five identical fights.

## Decision
Option 2. `BossData` carries `boss_id`, `display_name`, `frames`, `tuning`, `tint` and `accent`.
`ReaperBoss.configure_variant()` applies it before `configure()`, and GameWorld resolves the
variant from `RiftData.boss_id`, warning and falling back to the Reaper for an unknown id.

- A variant with **no `frames` keeps the scene's own atlas**. That is how the base Reaper and its
  Ascended recolour both work, and `test_boss_variants.gd` asserts an atlas-less variant never
  clears the animation set.
- Base health escalates with the Rift ladder (6 → 8 → 10 → 12 → 15) and the test fails if a later
  Rift's boss is weaker than an earlier one.
- The test also asserts every supplied atlas covers all eleven animations the phase machine plays,
  because a missing one would freeze the encounter mid-phase rather than fail loudly.

## Consequences
- Four bosses cost four data files instead of four state machines, and every one inherits the
  Reaper's readability guarantees.
- **The fights share an attack grammar.** They differ in silhouette, colour, toughness and timing,
  not in what the attacks fundamentally are. If a Rift needs a genuinely new attack, that is a new
  phase in the shared machine, gated per variant — not a fork.
- `configure_variant()` must be called before `configure()`, and relies on `add_child()` running
  `_ready()` synchronously so the `@onready` sprite is resolved. That assumption is commented at
  the call site.
