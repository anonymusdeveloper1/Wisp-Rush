# ADR-0029: Google AdMob — interstitials between runs and two rewarded ads, on test ad units

> **Status:** Accepted · **Date:** 2026-10-05 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Supersedes:** "No interstitials, ever" in [ADR-0009](0009-monetisation-model.md) · **Keeps:** ADR-0009's provider seam and
> [ADR-0012](0012-store-surface-before-billing.md) (the store stays disconnected)

## Context
ADR-0009 chose opt-in rewarded video only ("No interstitials, ever", for the momentum pillar) behind a
`MonetisationService` with a null provider; no ad SDK was in the game and no rewarded offer had a
screen. The owner (2026-10-05, GDD §14 #82): "implement google ads in the game with test ads keys the
game shall have intersteial ads, rewarded ads". From Claude's options the owner picked: an
interstitial **after every second run, before Results**; rewarded ads for a **revive once per run**
and to **double the run's Rift Points** on Results; **Remove Ads removes all ads**; and the **Poing
Studios AdMob plugin with Google's consent form**, downloads approved.

## Options considered
1. **Poing Studios AdMob plugin v5.1.0** (MIT, Godot 4.2+ including 4.7, updated 2026-09-14, Google's
   Mobile Ads SDK plus the UMP consent SDK). Needs Godot's Android build template and a Gradle build.
2. **godot-sdk-integrations/godot-admob v7.0** (MIT, Godot 4.7+, marked unstable on 2026-06-19).

## Decision
Option 1.
- **Installed:** `addons/admob/` from `poing-godot-admob-v5.1.0.zip`, and its Android "ads" library
  (`android-template-v4.7.2.zip`: `addons/admob/android/bin/package.gd` and `bin/ads/`, no mediation
  networks). The plugin's line that git-ignores `android/bin/` is removed so the libraries are
  committed. `addons/admob/csharp/.gdignore` hides the plugin's C# side, as the plugin does itself
  on a non-C# Godot. The plugin is enabled in `project.godot`; `admob/general/android/app_id` is
  Google's test App ID `ca-app-pub-3940256099942544~3347511713`.
- **Android build:** the export preset uses the Gradle build (`gradle_build/use_gradle_build`) with
  compressed native libraries; Godot's build template is installed once per machine with
  `--install-android-build-template` (`/android/` stays git-ignored). The first build downloads Gradle
  and Google's SDK. A headless export also makes the plugin fetch its iOS libraries from the same
  release (git-ignored).
- **`AdMobProvider`** (`scripts/monetisation/admob_provider.gd`), an `AdProvider`: Google's consent form
  when it is required, then `MobileAds.initialize`, then one interstitial and one rewarded ad kept
  loaded on Google's test units (`…/1033173712` interstitial, `…/5224354917` rewarded) and reloaded
  after each show; a failed load retries after 30 s. Ads are allowed when consent is obtained or not
  required. `MonetisationService._ready` creates it only on Android when the plugin's singleton
  exists, so desktop runs and tests never load the plugin (from the editor it would serve mock ads).
- **The provider contract is asynchronous:** `start()`, `show_rewarded()` and `show_interstitial()`
  may wait, and callers `await` them.
- **Interstitial:** Main counts each finished run (`record_finished_run`); when two runs have finished
  since the last interstitial and one is loaded, it shows after the run is banked and before Results.
  The count is per session.
- **Revive:** when the Wisp dies in a real run (not the Tutorial) and a rewarded ad is ready, the run
  freezes under CONTINUE? — "Watch an ad to come back and keep this run going.", WATCH AD / NO
  THANKS (Android back = NO THANKS). An earned reward brings the Wisp back where it fell with full
  Soul Fragments, the spawn reform and 2 s without damage (`WispPlayer.revive`); anything else ends
  the run. Once per run (Monetisation's per-run lock).
- **Double RP:** Results shows WATCH AD • DOUBLE RP +N when a rewarded ad is ready and the run earned
  Rift Points; N is the run's own Rift Points (collected + performance, not challenge, Trial or depth
  rewards). An earned reward banks N again; the button then reads DOUBLED +N.
- **Remove Ads** removes every ad: interstitials and the rewarded offers.
- The rewarded ads are the revive and the double. ADR-0009's third placement, the upgrade reroll,
  stays in `MonetisationService.PLACEMENTS` with nothing offering it (run upgrades were removed by
  [ADR-0026](0026-pickup-items-and-consumable-packs.md)).

## Consequences
- GDD §12's "no data collection" no longer holds on Android: the Google SDK collects ad data, with
  consent through Google's form where required. Before release: the owner's AdMob account, App ID
  and ad units replace the test ones, and a privacy policy is needed.
- The APK grows by Google's SDK. The first Gradle build was 187 MB because Gradle stores the engine
  library uncompressed; `gradle_build/compress_native_libraries` is now on.
- Claude's choices, for the owner to change: the offer's wording, 2 s of revive protection, doubling
  collected + performance only, the per-session run count, retrying a failed load after 30 s.
- Not built: a privacy-options entry in Settings (Google's form can be reopened there), mediation,
  iOS.
- Checked headlessly through Main with a stand-in provider (2026-10-05, 0 failures): the offer on
  death, watching revives and the run goes on, a second death ends it, NO THANKS ends it, the
  interstitial shows on the second run end only, and doubling adds the run's Rift Points.
