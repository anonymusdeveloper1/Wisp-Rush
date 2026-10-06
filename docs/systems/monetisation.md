# System: Monetisation

> **Status:** 🔄 Google AdMob on Android with Google's test ad units (interstitial, rewarded revive and
> double RP, consent form; 2026-10-05) · store not connected, nothing can be bought ·
> **Last updated:** 2026-10-05 · **GDD section:** §5.3, §11, §12, §13, §14 #11, #78, #82 ·
> **ADR:** [0009](../decisions/0009-monetisation-model.md), [0012](../decisions/0012-store-surface-before-billing.md),
> [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [0028](../decisions/0028-shop-bottom-navigation-and-rift-points-packs.md),
> [0029](../decisions/0029-admob-interstitial-and-rewarded-ads.md)
>
> **Changed 2026-10-05 (owner, ADR-0029):** Google AdMob through the Poing Studios plugin: an
> interstitial after every second finished run, before Results; rewarded ads for a revive once per run
> and for doubling the run's Rift Points; Remove Ads removes all ads; Google's consent form.
>
> **Changed 2026-10-05 (owner, ADR-0028):** the Shop's SHOP page holds Remove Ads and the Rift Points
> packs, sold for real money (Home's NO ADS button opens it); both stay disabled with no store
> ([shop.md](shop.md)).

## Purpose

Hold the monetisation flow behind one injectable provider, so gameplay code never touches an SDK.
On Android the `AdMobProvider` serves interstitial and rewarded ads; on desktop and in tests the
`NullAdProvider` offers nothing. The store is not connected, so the Shop's real-money buttons stay
disabled (ADR-0012).

## Files

| Path | Role |
|---|---|
| `res://scripts/autoload/monetisation_service.gd` | `MonetisationService` (autoload `Monetisation`), `AdProvider`, `NullAdProvider`; installs the AdMob provider on Android |
| `res://scripts/monetisation/admob_provider.gd` | The `AdProvider` over the Poing Studios AdMob plugin: consent form, initialise, one interstitial and one rewarded ad kept loaded on Google's test units |
| `res://addons/admob/` | Poing Studios AdMob plugin v5.1.0 (MIT) and its Android "ads" library in `android/bin/` (ADR-0029) |
| `res://scenes/gameplay/game_world.{gd,tscn}` | The revive offer (`ReviveOverlay`: CONTINUE? WATCH AD / NO THANKS) |
| `res://scenes/screens/results_screen.{gd,tscn}` | WATCH AD • DOUBLE RP (`DoubleRpButton`) |
| `res://scenes/player/wisp_player.gd` | `revive(invulnerable_seconds)` |
| `res://scripts/autoload/save_manager.gd` | `ads_removed`, `consent_state` (schema v6) |
| `res://scenes/screens/shop_screen.tscn` / `.gd` | `ShopScreen`: the SHOP page's Remove Ads offer, Restore Purchases and the Rift Points pack cards |
| `res://scripts/resources/rift_points_pack.gd` · `rift_points_pack_catalog.gd` · `res://data/shop/rift_points_packs.tres` | The four Rift Points packs: product id, RP, price label, icon |
| `res://scenes/main/main.gd` | Opens the Shop from Home's SHOP and NO ADS; runs purchase/restore through the service; the interstitial before Results; the double-RP reward |
| `res://tools/godot/test_monetisation.gd` | Gating, rewarded locks, interstitial cadence, store availability, purchase and restore |

## Public API

| Member | Kind | Description |
|---|---|---|
| `rewarded_granted(placement)` / `rewarded_failed(placement)` | signal | Reward earned, or not owed. |
| `ads_removed_changed(removed)` / `consent_changed(state)` | signal | Purchase and consent updates. |
| `set_provider(provider)` | method | Injects a real SDK adapter at boot. |
| `is_available()` | method | Whether any monetisation surface may be shown at all. |
| `can_offer(placement)` | method | The single gate: provider, consent, ads-removed, run lock. |
| `show_rewarded(placement)` | coroutine | Shows an ad; `await` it; true only when the reward was earned. |
| `begin_run()` | method | Clears per-run placement locks. |
| `record_finished_run()` / `can_show_interstitial()` / `show_interstitial()` | method / method / coroutine | Counts a run end; whether an interstitial is due (two runs since the last, provider up, consent decided, ads not removed, one loaded); shows it and returns once closed. |
| `is_showing_ad()` | method | True while a full-screen ad is up. |
| `AdProvider.start()` / `is_interstitial_ready()` / `show_interstitial()` | coroutine / method / coroutine | Consent and SDK start; the interstitial contract (ADR-0029). |
| `GameWorld` revive offer | scene | On death in a real run with a rewarded ad ready: CONTINUE? WATCH AD / NO THANKS (back = NO THANKS); an earned reward calls `WispPlayer.revive(2.0)`. |
| `ResultsScreen.set_double_rp_offer(amount)` / `finish_double_rp(added)` / `double_rp_requested` | method / method / signal | The WATCH AD • DOUBLE RP button; Main shows the ad and banks the run's Rift Points again. |
| `is_store_available()` · `get_store_price(product_id)` | method | The store is up and knows products (gates BUY and Restore) / Google's localized price, or empty. |
| `can_purchase_remove_ads()` / `purchase_remove_ads()` / `restore_purchases()` | method / coroutine / coroutine | Remove Ads: returns a `PURCHASE_*` status (`purchased`, `pending`, `cancelled`, `failed`); restore asks the store and returns whether ads are removed. |
| `set_store(store)` · `set_rift_points_packs(catalog)` · `store_changed` · `purchase_delivered(product_id, rift_points)` | coroutine · method · signal · signal | Store injection and start (delivers what the account owns); the packs it sells; availability or prices changed; a purchase landed outside a purchase call. |
| `StoreProvider` | class | `start(ids)`, `is_available`, `get_price`, `purchase(id)` → {status, token}, `finish(token, consumable)`, `query_purchases()`, signal `purchase_ready`; `PlayBillingStore` on Android (ADR-0030). |
| `purchase_rift_points(pack)` | coroutine | Buys a Rift Points pack and returns a `PURCHASE_*` status; a completed one adds `pack.rift_points` to the save, then the purchase is consumed (ADR-0028, ADR-0030). |
| `needs_consent_prompt()` | method | True only when a provider exists and no decision is stored. |
| `ShopScreen.purchase_requested(product_id)` / `restore_requested` / `back_requested` | signal | Shop intent; Main acts on it. |
| `ShopScreen.setup(rift_points, ads_removed, store_available)` / `show_feedback(msg, ok)` | method | Safe before `_ready`; the header shows the Rift Points balance. |
| `ShopScreen.can_buy()` | method | Whether BUY can start a purchase (test helper). |

## Data & tuning

Rewarded placements offered: `revive` (once per run) and `double_rift_points` (on Results: the run's
collected + performance RP again). `upgrade_reroll` stays in the list with nothing offering it.
Interstitial: after every `INTERSTITIAL_RUN_INTERVAL` (2) finished runs, counted per session, before
Results (owner 2026-10-05, ADR-0029). Ad units: Google's Android test units —
`ca-app-pub-3940256099942544/1033173712` (interstitial), `ca-app-pub-3940256099942544/5224354917`
(rewarded); App ID `ca-app-pub-3940256099942544~3347511713` (`admob/general/android/app_id`). A failed
load retries after 30 s. Revive protection: 2 s (`GameWorld.REVIVE_INVULNERABLE_SECONDS`).
Products: `remove_ads`, which removes ads and nothing else, so its purchase and restore leave the
Rift Points balance unchanged; and the four Rift Points packs (`rp_pack_500` / `1200` / `2500` /
`6500`: 500, 1,200, 2,500 and 6,500 RP for 0.99 / 1.99 / 4.99 / 9.99 USD, placeholder prices, owner
2026-10-05, ADR-0028), each adding its RP. Restore restores Remove Ads only.

## Dependencies

`SaveManager` for persistence; `GameWorld` calls `begin_run()` at run start and offers the revive;
Main shows the interstitial and the double. The Poing Studios AdMob plugin (`addons/admob/`) and the
Gradle Android build (Godot's build template, installed per machine with
`--install-android-build-template`).

## Rules & behaviour

- **Android with the plugin gets the `AdMobProvider`**; everything else keeps `NullAdProvider`, so on
  desktop and in tests `is_available()` is false and no ad is ever offered. The provider is loaded
  with `load()` on Android only: from the editor the plugin would serve mock ads.
- **Start-up:** Google's consent form shows when it is required (UMP); ads are allowed when consent is
  obtained or not required, and the answer is stored as the consent state. Then `MobileAds.initialize`
  and one interstitial and one rewarded ad are loaded, each replaced after it shows.
- **Interstitial:** Main banks the run, counts it, and when one is due shows it before Results.
- **Revive:** GameWorld freezes the run under the offer; WATCH AD awaits the ad; earned → the Wisp
  comes back where it fell (full Soul Fragments, the spawn reform, 2 s without damage); otherwise the
  run ends. Never in the Tutorial.
- **Double RP:** Results shows the button only when a rewarded ad is ready and the run earned Rift
  Points; earned → `add_rift_points` once more, the total and balance update, the button reads
  DOUBLED +N.
- **Remove Ads removes every ad** (owner 2026-10-05): interstitials and the rewarded offers.
- **The Shop is visible but cannot sell** (owner decision, ADR-0012). Home's SHOP and NO ADS both open
  `ShopScreen` (NO ADS on its SHOP page), whose offer reads REMOVE ADS with no currency line. The
  Rift Points packs follow the same rule: COMING SOON and disabled with no store, BUY with one. With no store, BUY reads COMING SOON and BUY and RESTORE are disabled; with a store,
  BUY emits `purchase_requested`; once owned, BUY reads OWNED, RESTORE stays enabled and Home hides
  NO ADS. **A release must wire real billing or hide both buttons** (GDD §13).
- **Google Play Billing** (owner 2026-10-05, ADR-0030): on Android `PlayBillingStore` connects at boot
  and asks Play for `remove_ads` and the four packs; the store is available once Play knows them (Play
  Console). A completed pack is saved, then consumed; Remove Ads is granted, then acknowledged. At
  start, everything the account owns is delivered (Remove Ads after a reinstall, a pack a crash left
  undelivered). A pending payment adds nothing until Google completes it, then arrives on its own.
  Store purchases do not depend on ad consent.
- **Every gate lives in `can_offer()`** — provider up, consent decided, ads not removed, placement
  known, not already used this run. Callers cannot accidentally show an offer they cannot honour.
- A **dismissed ad still consumes its placement for the run**, so a declined offer is never
  immediately repeated. `begin_run()` is the only thing that clears the locks.
- Consent is asked **before any ad request** (Google's form), and only by the AdMob provider.
- An unknown consent value on disk falls back to `unknown`, so a hand-edited save cannot enable
  personalised ads.

## How to test

`tools/run_tests.sh monetisation` — drives the whole flow through a fake provider: the null default
offers nothing and reports no store, consent gates offers, rewards grant once per run, dismissals
lock the placement, the interstitial is due after every second finished run and never after Remove
Ads, the product id is `remove_ads`, purchase hides every placement, and neither purchase nor
restore changes the Rift Points balance. The real ads are checked on the phone (test ads).
`tools/run_tests.sh menu_screens` covers the Shop's three states; `main_progression_flow` opens it
from both Home buttons and proves a purchase cannot complete with no store. Visual:
`tools/qa_matrix.sh shop`.

## Known issues / TODO

- **Test ad units only.** Before release: the owner's AdMob App ID and ad units, a privacy policy.
  Not built: a privacy-options entry in Settings, mediation, iOS.
- **The store waits for Play Console** ([play_console_setup.md](../guides/play_console_setup.md)): until
  Play knows the products, the Shop keeps COMING SOON. Not run against Google yet.

## Change history

| Date | Change |
|---|---|
| 2026-10-05 | Google Play Billing (owner, GDD §14 #84, ADR-0030): a separate `StoreProvider` seam and `PlayBillingStore`; async purchases with `PURCHASE_*` statuses; RP saved then consumed, Remove Ads acknowledged; owned purchases delivered at start (restore after reinstall, crash recovery); pending payments; `store_changed`, `purchase_delivered`, `get_store_price` |
| 2026-10-05 | Google AdMob (owner, GDD §14 #82, ADR-0029): Poing Studios plugin v5.1.0, `AdMobProvider` on Android with Google's test units and consent form, async provider contract, interstitial after every second run, rewarded revive and double RP, Remove Ads removes all ads; Gradle Android build |
| 2026-10-05 | Rift Points packs sold for real money (owner, GDD §14 #78, ADR-0028): `purchase_rift_points`, `RiftPointsPack` / `RiftPointsPackCatalog`; Remove Ads and the packs on the Shop's SHOP page |
| 2026-09-15 | Remove Ads moved into the Shop's NO ADS tab; `ShopScreen.store_purchase_requested(product_id)` (spec 04) |
| 2026-09-15 | Product `remove_ads` with no currency; `double_rift_points` placement; Shop copy without the shard line (spec 01, ADR-0013) |
| 2026-09-13 | Shop screen (Remove Ads bundle, Restore) reachable from Home, disabled with no store; `is_store_available()` (ADR-0012) |
| 2026-09-12 | Created: service, provider contract, null default, consent, save schema v5 (ADR-0009) |
