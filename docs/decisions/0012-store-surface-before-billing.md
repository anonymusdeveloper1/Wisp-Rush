# ADR-0012: The Shop is visible before billing exists, with purchases disabled

> **Status:** Accepted; "the Shop sells exactly one product" is superseded by
> [ADR-0013](0013-rift-story-levels-endless-mode-and-rift-points.md) (Rift Points cosmetic tabs join the
> No Ads tab; the disabled-purchase rule stands) · **Date:** 2026-09-13 · **Deciders:** owner (chose the option) + Claude Code ·
> **Supersedes the "no surface renders" consequence of:** [ADR-0009](0009-monetisation-model.md) (its model stands)

## Context
The owner replaced Home's bottom navigation with side columns that include a **Shop** and a **Remove
Ads** button. ADR-0009 said that with `NullAdProvider` no ad or purchase surface renders, so GDD §13's
"no dead buttons, no fake purchases" held. Billing is still not connected (no Play Billing plugin,
accounts or signing), so any Shop today cannot sell anything.

## Options considered
1. **Show both buttons; the Shop shows its product with buying disabled** (chosen): the layout and
   entry points can be seen and tested on the phone now; nothing fake can be bought.
2. **Hide both until billing works:** keeps ADR-0009 literally, but the requested layout would be
   invisible on every build until release work.
3. **Debug builds only:** visible while developing, absent from release — hides the problem instead
   of forcing the release decision.

## Decision
- Home shows **Shop** and **Remove Ads**; both open `ShopScreen`. The Shop sells exactly ADR-0009's
  one product, Remove Ads + 1,500 Soul Shards, plus **Restore Purchases**.
- With no store (`MonetisationService.is_store_available()` false) Buy reads **COMING SOON** and
  Buy and Restore are **disabled** — a disabled control, never a purchase that pretends to succeed.
- Once ads are removed, Home hides Remove Ads; the Shop stays reachable and reads **OWNED**.
- Every purchase still goes through `MonetisationService`; the screen only emits intent.

## Consequences
- **Release blocker:** before a store release, either connect real billing (`AdProvider` + Play
  Billing, price display, consent) or hide Shop and Remove Ads. GDD §13 forbids shipping a Shop that
  can never sell. Tracked in ROADMAP M6/M9.
- `AdProvider` has no price query yet; a real provider needs one before BUY can show a price.
- ADR-0009's model (opt-in rewarded video, one IAP, no interstitials) is unchanged.
