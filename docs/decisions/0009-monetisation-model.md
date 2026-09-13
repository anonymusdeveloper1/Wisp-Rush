# ADR-0009: Monetisation is opt-in rewarded video plus one Remove Ads purchase

> **Status:** Accepted (plumbing shipped, no provider configured) · **Date:** 2026-09-12 ·
> **Deciders:** owner (chose the model) + Claude Code

## Context
Wisp Rush is a free, offline arcade game. GDD §12 promises "offline base game, no account/backend/
data collection" and §13 promises a release with "no fake purchases" and no dead buttons. The owner
chose a free game funded by opt-in rewarded video plus a single Remove Ads purchase.

Any real ad SDK breaks the §12 promise: it adds a network dependency, an advertising identifier and
a consent obligation. That is a design change, not an implementation detail.

## Options considered
1. **Premium paid app** — no SDK, no tracking, §12 survives intact. Rejected by the owner; premium
   mobile arcade sells poorly without marketing.
2. **Interstitials between runs** — highest fill and revenue per session, but a forced ad between
   two-minute runs directly contradicts GDD §2's "immediate momentum" pillar. Rejected outright.
3. **Opt-in rewarded video + one non-consumable IAP** — the player only ever sees an ad they chose
   to watch, in exchange for something they wanted. **Chosen.**

## Decision
- **Three rewarded placements only**: revive once per run, double Soul Shards at Results, one
  upgrade reroll. **No interstitials, ever.**
- **One product**: `remove_ads_shard_pack` — removes ads and grants 1,500 shards. Restoring it
  re-grants ad removal but never the shards again.
- **The game never touches an SDK.** `MonetisationService` (autoload `Monetisation`) talks to an
  injected `AdProvider`. The shipped default is `NullAdProvider`, which reports nothing available.
- **Every gate lives in one place**, `can_offer()`: provider up, consent decided, ads not removed,
  placement known, and not already used this run. A dismissed ad consumes its placement for the
  run, so a declined offer is never immediately repeated.
- **Consent before any request.** `needs_consent_prompt()` is true only when a provider exists and
  no decision is stored, so the shipped build never asks.

## Consequences
- **On the current build nothing changes.** With `NullAdProvider`, `is_available()` is false, so no
  ad or purchase surface renders and the game stays exactly the offline build it was. GDD §13's
  "no dead buttons, no fake purchases" therefore still holds today.
- **GDD §12 and §13 must be amended before a monetised build ships**, not before this code lands.
  The promise is only broken when a real provider is configured.
- Wiring a real SDK means implementing `AdProvider` and calling `set_provider()` at boot. It also
  needs the owner's AdMob and Play accounts, a privacy policy, a GDPR/ATT consent UI and signing —
  none of which can be done from this repository.
- Save schema v5 stores `ads_removed` and `consent_state`. Both are validated on load, so a
  hand-edited save cannot grant ad removal through an unknown consent value.
