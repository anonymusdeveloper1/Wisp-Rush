# ADR-0028: The Shop's bottom navigation, and Rift Points packs sold for real money

> **Status:** Accepted · **Date:** 2026-10-05 · **Deciders:** owner / Claude Code (Opus 5.5) ·
> **Supersedes:** "Rift Points are never bought" in [ADR-0013](0013-rift-story-levels-endless-mode-and-rift-points.md) ·
> **Keeps:** [ADR-0012](0012-store-surface-before-billing.md) (real-money buttons disabled until billing)

## Context
The Shop had four tabs along its top: Characters, Arenas, Items and No Ads. ADR-0013 made Rift Points
(RP) earned by playing only, never bought. The owner (2026-10-05, GDD §14 #78): in the Shop, "a bottom
navigation insted of top navigation and at the top there is the back button"; one page for the
characters and the other, the shop, "which will have all the shop deals, like remove ads, buy game
stuff, buy bundles later im gonna sell like a character and monmey etc", and "a place where the users
can buy RP". The ARENAS tab goes with the arenas ([ADR-0027](0027-one-arena-simulation.md)). From
Claude's options the owner picked: the characters page named **CHARACTERS**; **ITEMS a section of
SHOP**; Claude's suggested packs, **500 / 1,200 / 2,500 / 6,500 RP for 0.99 / 1.99 / 4.99 / 9.99 USD**,
as placeholders, their buttons disabled until billing exists.

## Decision
- **Layout** (`scenes/screens/shop_screen.tscn`): a header with BACK, the SHOP title and the RP
  balance; the page; and a bottom `NavBar` with two toggle `NavButton`s, **CHARACTERS** and **SHOP**.
  The page ids are `ShopScreen.TAB_WISPS` (the older id is kept, sessions and fixtures use it) and
  `TAB_SHOP`; an unknown id opens SHOP. Home's SHOP opens the last page of the session (CHARACTERS at
  first), tapping the character opens CHARACTERS, and Home's NO ADS opens SHOP.
- **CHARACTERS** is the character card pager as it was.
- **SHOP** is one scrolling list (`%ShopPage`): NO ADS (the Remove Ads offer and Restore Purchases),
  ITEMS (`RunItemShopPage`, now a section: the pickup packs and the next-run boost) and RIFT POINTS (a
  two-column grid of pack cards: icon, amount, price and a button).
  It scrolls by swiping, vertically only, with no scroll bar drawn; its cards and buttons pass
  touches on, so a swipe that starts on them scrolls (owner 2026-10-05, as in Settings).
- **Rift Points packs** are data: `RiftPointsPack` (`product_id`, `rift_points`, `price_label`, `icon`)
  in a `RiftPointsPackCatalog`, `data/shop/rift_points_packs.tres`, with the product ids
  `rp_pack_500`, `rp_pack_1200`, `rp_pack_2500` and `rp_pack_6500`. The price labels are the
  owner-approved placeholders.
- **Buying:** a pack's button emits `store_purchase_requested(product_id)`; Main finds the pack and
  calls `MonetisationService.purchase_rift_points(pack)`, which asks the store provider to `purchase`
  the product and, on a completed purchase, adds the pack's RP with `SaveManager.add_rift_points`. The
  Shop shows `+1,200 RP` (the amount added) or THE PURCHASE DID NOT COMPLETE.
- **No store, no purchase** (ADR-0012, GDD §13): with the shipped `NullAdProvider` the pack buttons
  and Remove Ads read COMING SOON and are disabled. Restore Purchases still restores Remove Ads only.
- **Icons:** Codex generated the four sources (`concept_art/rp_packs_v1/`, its README and prompts);
  its `build_icons.py` makes `assets/art/ui/rp_packs/rp_pack_*.png` (256 × 256).

## Consequences
- RP now comes from play and from real money. Remove Ads still carries no currency.
- Wiring billing means the store provider answers `purchase()` for the four pack ids as well as
  `remove_ads`.
- New deals (the owner's "bundles later") are new sections or cards on the SHOP page.
- Claude's choices, for the owner to change: SHOP's order NO ADS → ITEMS → RIFT POINTS; COMING SOON on
  a disabled pack; the pack icon size (176 px); the bottom navigation's tabs 160 px tall with size-48
  text (the owner asked for it bigger; it was 104 px and 33); the Remove Ads card's line "No ads,
  ever." (it said everything else in the game is earned by playing, no longer true).
- Checked with a scratch script through Main (2026-10-05, 0 failures): Home's SHOP opens CHARACTERS
  and NO ADS opens SHOP; with no store every real-money button is disabled; with a stand-in store each
  pack reads BUY, and buying `rp_pack_1200` adds 1,200 RP, updates the balance and shows `+1,200 RP`.
