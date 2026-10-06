# ADR-0030: Purchases through Google Play Billing, and the save on the player's Google account

> **Status:** Accepted · **Date:** 2026-10-05 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Builds on:** [ADR-0012](0012-store-surface-before-billing.md) (buttons disabled until a store
> sells), [ADR-0028](0028-shop-bottom-navigation-and-rift-points-packs.md) (the RP packs),
> [ADR-0029](0029-admob-interstitial-and-rewarded-ads.md) (AdMob, the Gradle build)

## Context
The owner (2026-10-05, GDD §14 #84): a player who buys Rift Points would lose them with a local save,
so the data should be kept with the player's Google or Apple account, and the No Ads purchase
should go through Google Play or the App Store. Claude explained the two problems (purchases go
through the store; a consumable like RP must live in a cloud save, while Remove Ads is kept by the
store itself) and three cloud options. The owner picked **the platform cloud save, Android first**,
and then: **both plugins** may be downloaded; there is **no Play Console app yet**; when the phone and
the cloud differ, **the newest save wins**; sign-in is **automatic at launch, plus Settings**.

## Decision
- **Plugins** (MIT, github.com/godot-sdk-integrations): `godot-google-play-billing.zip` 3.3.0
  (Billing Library 9.1.0) in `addons/GodotGooglePlayBilling/`, enabled; Play Games Services
  `addons.zip` v3.4.0 in `addons/GodotPlayGameServices/`, **disabled** until the owner has the Games
  project ID: its export writes that ID into a resource only when it is set, while the manifest always
  points at it. Both call Google's libraries through the Gradle build.
- **A separate store seam:** `MonetisationService.StoreProvider` (start, availability, prices,
  purchase, finish, owned purchases), independent of the ad provider and its consent. On Android,
  `PlayBillingStore` (`scripts/monetisation/play_billing_store.gd`) over the plugin's `BillingClient`.
  Product IDs: `remove_ads` and the four `rp_pack_*`.
- **Delivery:** a completed RP pack is added to the save **first**, then consumed; Remove Ads is
  granted, then acknowledged. When the store starts, everything the account owns is delivered:
  Remove Ads comes back after a reinstall, and a pack paid but never delivered (a crash) is
  delivered then. A pending payment adds nothing until Google completes it, then arrives on its
  own. Purchases are coroutines returning `purchased`, `pending`, `cancelled` or `failed`.
- **Prices:** once Google answers, the Shop shows Google's localized price instead of the placeholder.
- **The cloud save:** a `CloudSave` autoload (`CloudSaveService`) with a provider seam; on Android,
  when the Play Games singleton exists, `PlayGamesCloudProvider` (`scripts/cloud/`), which calls the
  plugin's Android singleton directly. The whole save is one snapshot (`wisp_rush_save`).
  - At launch: silent sign-in, then a sync. The newer save wins, by the time of the last **real**
    change: consent (stored at every launch) and play time do not count. A phone that has never
    synced takes the cloud save when there is one, so a fresh install cannot overwrite it. An
    unreachable cloud changes nothing; bytes that are not a save are refused.
  - After a real change the save uploads 5 s later, and at once when the app is paused.
  - `SaveManager.export_cloud_save()` / `import_cloud_save(bytes)`: imported bytes go through the same
    validation and migration as a save file.
- **Settings** shows a CLOUD SAVE card (Home-level, only on a build with a cloud): ON, or OFF with
  SIGN IN WITH GOOGLE PLAY GAMES. Home is rebuilt when a cloud save replaces the save under it.
- **About's privacy text** now says what is true: ads from Google AdMob with Google's consent form,
  purchases through Google Play, progress on the device and, when signed in, on the Google account.

## Consequences
- Nothing sells and nothing syncs until the owner sets up Play Console
  ([play_console_setup.md](../guides/play_console_setup.md)); until then the store reports no
  products, the Shop keeps COMING SOON, and Settings has no cloud card (the plugin is disabled).
- Progress does not cross between Android and iPhone; iOS (StoreKit, iCloud) is later.
- Local saves can still be edited on a rooted phone; only a server could stop that (not chosen).
- Claude's choices, for the owner to change: a phone that never synced takes the cloud save; 5 s
  upload delay; 20 s request time-out; the snapshot name; the Settings wording; pending feedback
  "PAYMENT PENDING • IT ARRIVES WHEN GOOGLE CONFIRMS IT".
- Checked headlessly (2026-10-05): `test_monetisation` (store purchases, pending, a late payment,
  crash recovery, restore at start) and the new `test_cloud_save` (the sync rules) pass; a scratch
  run through Main showed the store's prices, a purchase, a pending one completing, and the Settings
  card signing in. The real Google flows need Play Console.
