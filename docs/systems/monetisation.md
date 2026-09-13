# System: Monetisation

> **Status:** 🔄 plumbing only — no provider configured, nothing is offered ·
> **Last updated:** 2026-09-12 · **GDD section:** §12, §13, §14 #11 ·
> **ADR:** [0009](../decisions/0009-monetisation-model.md)

## Purpose

Hold the complete opt-in monetisation flow behind one injectable provider, so the shipped build
stays a fully offline game with no ad or purchase surface, and wiring a real SDK later touches no
gameplay code.

## Files

| Path | Role |
|---|---|
| `res://scripts/autoload/monetisation_service.gd` | `MonetisationService` (autoload `Monetisation`), `AdProvider`, `NullAdProvider` |
| `res://scripts/autoload/save_manager.gd` | `ads_removed`, `consent_state` (schema v5) |
| `res://tools/godot/test_monetisation.gd` | Gating, rewarded locks, purchase and restore |

## Public API

| Member | Kind | Description |
|---|---|---|
| `rewarded_granted(placement)` / `rewarded_failed(placement)` | signal | Reward earned, or not owed. |
| `ads_removed_changed(removed)` / `consent_changed(state)` | signal | Purchase and consent updates. |
| `set_provider(provider)` | method | Injects a real SDK adapter at boot. |
| `is_available()` | method | Whether any monetisation surface may be shown at all. |
| `can_offer(placement)` | method | The single gate: provider, consent, ads-removed, run lock. |
| `show_rewarded(placement)` | method | Shows an ad; true only when the reward was earned. |
| `begin_run()` | method | Clears per-run placement locks. |
| `can_purchase_remove_ads()` / `purchase_remove_ads()` / `restore_purchases()` | method | Store flow. |
| `needs_consent_prompt()` | method | True only when a provider exists and no decision is stored. |

## Data & tuning

Three rewarded placements — `revive`, `double_shards`, `upgrade_reroll`. **No interstitials.**
One product, `remove_ads_shard_pack`: removes ads and grants 1,500 shards; restoring re-grants
removal but never the shards again.

## Dependencies

`SaveManager` for persistence, `GameWorld` calls `begin_run()` at run start. Nothing else in the
game references this service, which is the point.

## Rules & behaviour

- **The shipped default is `NullAdProvider`**, so `is_available()` is false, `can_offer()` is false
  for every placement, and no ad or purchase button renders. GDD §13's "no dead buttons, no fake
  purchases" therefore holds on the current build.
- **Every gate lives in `can_offer()`** — provider up, consent decided, ads not removed, placement
  known, not already used this run. Callers cannot accidentally show an offer they cannot honour.
- A **dismissed ad still consumes its placement for the run**, so a declined offer is never
  immediately repeated. `begin_run()` is the only thing that clears the locks.
- Consent is asked **before any ad request**, and only when a provider exists.
- An unknown consent value on disk falls back to `unknown`, so a hand-edited save cannot enable
  personalised ads.

## How to test

`tools/run_tests.sh monetisation` — drives the whole flow through a fake provider: the null default
offers nothing, consent gates offers, rewards grant once per run, dismissals lock the placement,
purchase hides every placement, and restore never re-grants the bundled shards.

## Known issues / TODO

- **No real SDK.** Implementing `AdProvider` against AdMob and Play Billing needs the owner's
  accounts, app ids, a privacy policy, a GDPR/ATT consent UI and release signing. None of that can
  be done from this repository.
- **No UI exists** for the revive, double-shards or reroll offers, or for the store. They are
  deliberately unbuilt while `is_available()` is false, so nothing inert ships.
- GDD §12 and §13 must be amended **before** a build with a real provider ships.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Created: service, provider contract, null default, consent, save schema v5 (ADR-0009) |
