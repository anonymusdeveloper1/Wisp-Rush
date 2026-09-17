# System: Monetisation

> **Status:** 🔄 plumbing + disabled Shop — no provider configured, nothing can be bought ·
> **Last updated:** 2026-09-15 · **GDD section:** §11, §12, §13, §14 #11 ·
> **ADR:** [0009](../decisions/0009-monetisation-model.md), [0012](../decisions/0012-store-surface-before-billing.md),
> [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md)
>
> **Changed 2026-09-15 ([spec 04](../specs/story_and_endless/04_shop.md)):** Remove Ads lives in the Shop's
> NO ADS tab (Home's NO ADS button opens it); behaviour unchanged, no RP shown ([shop.md](shop.md)).

## Purpose

Hold the complete opt-in monetisation flow behind one injectable provider, so the shipped build
stays a fully offline game where nothing can be bought or watched, and wiring a real SDK later
touches no gameplay code. The Shop screen is reachable now, with its purchases disabled (ADR-0012).

## Files

| Path | Role |
|---|---|
| `res://scripts/autoload/monetisation_service.gd` | `MonetisationService` (autoload `Monetisation`), `AdProvider`, `NullAdProvider` |
| `res://scripts/autoload/save_manager.gd` | `ads_removed`, `consent_state` (schema v6) |
| `res://scenes/screens/shop_screen.tscn` / `.gd` | `ShopScreen`: the Remove Ads bundle, Buy and Restore Purchases |
| `res://scenes/main/main.gd` | Opens the Shop from Home's SHOP and NO ADS; runs purchase/restore through the service |
| `res://tools/godot/test_monetisation.gd` | Gating, rewarded locks, store availability, purchase and restore |

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
| `is_store_available()` | method | Provider up and store reachable; gates Restore Purchases. |
| `can_purchase_remove_ads()` / `purchase_remove_ads()` / `restore_purchases()` | method | Store flow. |
| `needs_consent_prompt()` | method | True only when a provider exists and no decision is stored. |
| `ShopScreen.purchase_requested(product_id)` / `restore_requested` / `back_requested` | signal | Shop intent; Main acts on it. |
| `ShopScreen.setup(rift_points, ads_removed, store_available)` / `show_feedback(msg, ok)` | method | Safe before `_ready`; the header shows the Rift Points balance. |
| `ShopScreen.can_buy()` | method | Whether BUY can start a purchase (test helper). |

## Data & tuning

Three rewarded placements — `revive`, `double_rift_points`, `upgrade_reroll`. **No interstitials.**
One product, `remove_ads`: removes ads and nothing else. **No real-money path grants Rift Points**
(ADR-0013), so purchase and restore both leave the balance unchanged.

## Dependencies

`SaveManager` for persistence, `GameWorld` calls `begin_run()` at run start. Nothing else in the
game references this service, which is the point.

## Rules & behaviour

- **The shipped default is `NullAdProvider`**, so `is_available()` is false, `can_offer()` is false
  for every placement and no ad is ever offered.
- **The Shop is visible but cannot sell** (owner decision, ADR-0012). Home's SHOP and NO ADS both open
  `ShopScreen`, whose offer reads REMOVE ADS with no currency line. With no store, BUY reads COMING SOON and BUY and RESTORE are disabled; with a store,
  BUY emits `purchase_requested`; once owned, BUY reads OWNED, RESTORE stays enabled and Home hides
  NO ADS. **A release must wire real billing or hide both buttons** (GDD §13).
- **Every gate lives in `can_offer()`** — provider up, consent decided, ads not removed, placement
  known, not already used this run. Callers cannot accidentally show an offer they cannot honour.
- A **dismissed ad still consumes its placement for the run**, so a declined offer is never
  immediately repeated. `begin_run()` is the only thing that clears the locks.
- Consent is asked **before any ad request**, and only when a provider exists.
- An unknown consent value on disk falls back to `unknown`, so a hand-edited save cannot enable
  personalised ads.

## How to test

`tools/run_tests.sh monetisation` — drives the whole flow through a fake provider: the null default
offers nothing and reports no store, consent gates offers, rewards grant once per run, dismissals
lock the placement, the product id is `remove_ads`, purchase hides every placement, and neither
purchase nor restore changes the Rift Points balance.
`tools/run_tests.sh menu_screens` covers the Shop's three states; `main_progression_flow` opens it
from both Home buttons and proves a purchase cannot complete with no store. Visual:
`tools/qa_matrix.sh shop`.

## Known issues / TODO

- **No real SDK.** Implementing `AdProvider` against AdMob and Play Billing needs the owner's
  accounts, app ids, a privacy policy, a GDPR/ATT consent UI and release signing. None of that can
  be done from this repository.
- **No UI exists** for the revive, double Rift Points or reroll offers. They stay unbuilt while
  `is_available()` is false.
- `AdProvider` has no price query, so BUY cannot show a localized price yet.
- GDD §12 and §13 must be amended **before** a build with a real provider ships.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Remove Ads moved into the Shop's NO ADS tab; `ShopScreen.store_purchase_requested(product_id)` (spec 04) |
| 2026-09-15 | Product `remove_ads` with no currency; `double_rift_points` placement; Shop copy without the shard line (spec 01, ADR-0013) |
| 2026-09-13 | Shop screen (Remove Ads bundle, Restore) reachable from Home, disabled with no store; `is_store_available()` (ADR-0012) |
| 2026-09-12 | Created: service, provider contract, null default, consent, save schema v5 (ADR-0009) |
