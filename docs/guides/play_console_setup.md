# Google Play Console setup — what the owner does so purchases and the cloud save work

> Written 2026-10-05 (ADR-0030). The game side is built: Google Play Billing (Remove Ads and the four
> Rift Points packs) and the Play Games cloud save. Neither can work until Google knows the app.
> Play Console's menus change over time; the names below may differ slightly from what you see.

## 1. Account and app

1. Create a Google Play developer account (Play Console). It has a one-time registration fee and
   identity checks.
2. Create the app: **Wisp Rush**, a game, free.
3. Set up a payments profile (merchants account), needed to sell anything.

## 2. A first build in Play

1. **Upload key.** Google Play wants an Android App Bundle signed with your own upload key. Create
   the key yourself (Android Studio, or `keytool`) and keep the file and its password safe; Claude
   never handles the password. Then Claude switches the export to a signed App Bundle and you type
   the password into Godot's export settings.
2. Upload that build to the **Internal testing** track. The package name becomes
   `com.cognitix.wisprush` for good.
3. Add your own Google account as an internal tester and open the testing link on the phone.

## 3. The products

Create these one-time in-app products with exactly these IDs (the game already uses them), set their
prices and activate them:

| Product ID | What it is | Placeholder price in the game |
|---|---|---|
| `remove_ads` | Remove Ads (non-consumable: Google keeps it on the account) | — |
| `rp_pack_500` | 500 Rift Points (consumable) | 0.99 USD |
| `rp_pack_1200` | 1,200 Rift Points | 1.99 USD |
| `rp_pack_2500` | 2,500 Rift Points | 4.99 USD |
| `rp_pack_6500` | 6,500 Rift Points | 9.99 USD |

Once Google answers, the Shop shows Google's own localized prices instead of the placeholders.
Add your Google account as a **license tester**, so test purchases are not charged.

## 4. Play Games Services (the cloud save)

1. In Play Console, set up **Play Games Services** for the app (a Games project).
2. Add **credentials**: an Android OAuth client with the package name `com.cognitix.wisprush` and
   the SHA-1 fingerprint of each key that signs a build you will test:
   - Debug builds from the Windows PC (this checkout): `F2:09:CC:2F:F8:24:C5:AD:EC:CE:75:76:3B:39:1F:1E:1F:A6:5B:12`
     (`C:/Users/marti/AppData/Roaming/Godot/keystores/debug.keystore`, read 2026-10-05). The Mac has
     its own debug key with a different fingerprint.
   - Store builds: your upload key's SHA-1 and the app-signing key's SHA-1 that Play Console shows
     on its app-integrity page.
3. Turn on **Saved Games** for the Games project.
4. Add yourself as a Play Games tester.
5. Copy the Games **project ID** (a long number) and give it to Claude.

## 5. What Claude does then

- Sets the export option `godot_play_game_services/game_id` to that ID and enables the Play Games
  plugin (`addons/GodotPlayGameServices`; it stays disabled until the ID exists, because its export
  writes the ID resource only when an ID is set).
- Builds, installs, and checks on the phone: sign-in at launch, Settings' CLOUD SAVE card, a test
  purchase of each product, Restore Purchases, and a reinstall that brings the progress back.

## 6. Before release (separate)

- AdMob: your own AdMob account, App ID and ad units replace Google's test ones (ADR-0029).
- A privacy policy (ads, purchases and the cloud save use Google services).
