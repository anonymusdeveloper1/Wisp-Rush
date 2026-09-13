# System: Meta progression (Soul Sanctum, Trials, depth milestones)

> **Status:** ✅ done · **Last updated:** 2026-09-12 · **GDD section:** §6 ·
> **ADR:** [0009](../decisions/0009-monetisation-model.md) (currency context)

## Purpose

Give a finished run something to carry forward. Before this, nothing persisted but cosmetics, and
Soul Shards became inert once the six forms were owned (4,750 shards total).

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/sanctum_node.gd` / `sanctum_catalog.gd` | Permanent upgrade tree and its power budget |
| `res://data/sanctum/*.tres` | Nine nodes and the catalog |
| `res://scripts/utils/sanctum_effects.gd` | Resolves purchased levels into flat effect values |
| `res://scenes/screens/sanctum_screen.*` | Browse, select and buy nodes |
| `res://scripts/resources/trial_data.gd` / `trial_catalog.gd` | One goal, and the 12-tier ladder |
| `res://data/trials/*.tres` | 36 authored trials plus the catalog |
| `res://scripts/utils/trial_tracker.gd` | Applies a run to the ladder; pure and static |
| `res://scenes/screens/trials_screen.*` | The three active goals and the rank |
| `res://scripts/autoload/save_manager.gd` | Schema v5: sanctum, trials, depth, monetisation |

## Public API

| Member | Kind | Description |
|---|---|---|
| `SanctumNode.get_value(level)` / `get_cost(level)` | method | Effect total and next-level price (−1 when maxed). |
| `SanctumCatalog.is_unlocked(node, levels)` | method | Whether the prerequisite chain is satisfied. |
| `SanctumCatalog.get_maxed_combat_power()` | method | Fractional power a maxed tree grants. |
| `SanctumEffects.get_multiplier(key)` / `get_count(key)` | method | Resolved bonus for one effect key. |
| `TrialTracker.apply_run(rank, progress, summary)` | static | New rank, progress, rewards, completions. |
| `TrialTracker.get_active_trials(rank)` | static | The three goals currently shown. |
| `SaveManagerService.purchase_sanctum_level(id, price, max)` | method | Spends shards on one level. |
| `SaveManagerService.apply_trial_result(result)` | method | Banks a ladder result and pays it. |
| `SaveManagerService.claim_depth_milestones()` | method | Pays unclaimed depth rewards. |

## Data & tuning

**Soul Sanctum** — nine nodes, 8,970 shards to max, **0.167 combat power** against a hard 0.20
budget. `SanctumCatalog.validate()` fails the build above it, so GDD §6's "must not trivialise a
fresh start" is enforced rather than remembered.

| Node | Max | Per level | Combat? | Prerequisite |
|---|---|---|---|---|
| Keen Edge | 3 | +2 % blade width | yes | — |
| Swift Soul | 3 | +1.5 % dash speed | yes | — |
| Shard Finder | 4 | +8 % shard find | no | — |
| Rift Scholar | 3 | +5 % XP | no | — |
| Soul Magnet | 3 | +12 % attraction | no | — |
| Long Chain | 3 | +0.15 s combo grace | no | Rift Scholar |
| Warded Soul | 3 | +0.08 s invulnerability | yes | Keen Edge |
| First Gift | 1 | Start with 1 mutation | no | Swift Soul |
| Soul Reserve | 1 | +1 Soul Fragment | yes | Warded Soul |

**Trials** — 36 goals in 12 tiers of three. Each tier mixes a survival, a cumulative combat and a
mastery goal; rewards rise 15 → 125 shards per trial. Clearing all three ranks the player up.

**Depth milestones** — one-time shard rewards at waves 5/10/15/20/25 (25/50/100/175/300), keyed on
the lifetime best wave.

## Dependencies

[core_run.md](core_run.md) (run-start hook and reward choke points), [rifts.md](rifts.md),
[save_manager.md](save_manager.md), [game_flow.md](game_flow.md), [forms.md](forms.md) (shares the
shard economy), [ui_design_system.md](ui_design_system.md).

## Rules & behaviour

- **Sanctum effects are applied once, at run start**, and never mutate a shared tuning Resource.
  Invulnerability is a runtime field on `WispPlayer` for exactly this reason: writing it into
  `PlayerTuning` would leak the bonus into later runs and into the `.tres` on disk.
- Sanctum bonuses **compose** with run mutations rather than overwriting them — blade width and
  dash speed multiply the mutation result.
- Shard and XP bonuses are applied at the single choke point each award passes through
  (`_award_soul_shards`, `_grant_experience`), so no reward path can miss them.
- A saved level above a node's cap, or an unknown node id, is clamped or ignored on load.
- Trials never expire and never pay twice. Single-run trials keep the **best** run seen; cumulative
  trials add up. Both cap at their target.
- The ladder stops at the last authored tier instead of running off the end.
- Depth milestones are keyed on the lifetime best wave, so a shallow replay never re-pays.

## How to test

- `tools/run_tests.sh sanctum` — tree shape, power budget, cost curve, gating, purchase, clamping.
- `tools/run_tests.sh trials` — ladder shape, escalation, progress rules, rank-up, depth milestones.
- Visual: `WISP_ISOLATED_SAVE=1 tools/screenshot.sh res://scenes/screens/sanctum_screen.tscn 24 1080x1920`.

## Known issues / TODO

- Sanctum nodes are gated by prerequisites and shards only. They are **not** gated on Rift level
  progress, so "abilities unlock as you clear levels" is currently a shard economy, not a level one.
- `get_maxed_combat_power()` weights flat effects (fragments, seconds) with a single
  `FRAGMENT_POWER` constant. It is a guardrail, not a simulation; real balance needs device play.
- The Trials screen is read-only; there is no claim animation or completion celebration.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Created: Soul Sanctum, Trials ladder, depth milestones, save schema v3→v5 |
