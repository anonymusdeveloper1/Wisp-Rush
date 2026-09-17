# ADR-0013: Rift story levels, a cosmetic Endless mode and earned-only Rift Points

> **Status:** Accepted (design; implementation planned in
> [docs/specs/story_and_endless/](../specs/story_and_endless/README.md)) · **Date:** 2026-09-14 ·
> **Deciders:** owner (direction) + Claude Code (details, marked ASSUMPTION in GDD §14 #12–#21) ·
> **Partially supersedes:** [ADR-0007](0007-rifts-as-rule-variant-arenas.md) (wave-gated unlocks),
> [ADR-0008](0008-rift-levels-and-difficulty-ladder.md) (level climb inside a run),
> [ADR-0009](0009-monetisation-model.md) (shard pack), [ADR-0012](0012-store-surface-before-billing.md)
> (Shop contents) and the ROADMAP M7 decision to keep one endless mode.

## Context
- On 2026-09-14 the owner set the game's direction in conversation:
  - Remove Ads is the only thing sold for real money for now. Custom Wisps or characters may be sold
    later through Google Play / the App Store. No game account.
  - The currency becomes **Rift Points (RP)**: earned only by playing, more for a better run, never bought.
  - The **Soul Sanctum is removed**. RP buys Wisp forms, characters, arena looks and dash effects — never power.
  - The **Rifts stay as the "story mode"**, with their bosses and enemies.
  - A separate **Endless mode** plays on arenas whose backgrounds are bought with RP and never help
    the player; it mixes enemies and bosses from the Rifts.
- Measured the same day: the five Rift floors differ in size (85–100 % of the largest) and shape, and
  the shape all five share keeps only 63–82 % of each floor. Purchasable backgrounds therefore cannot
  reuse the per-art walls of ADR-0011 without changing difficulty — see
  [ADR-0014](0014-endless-arenas-share-one-floor-template.md).
- Before this change: a Rift run is endless and climbs a level on each boss (ADR-0008); Rifts unlock
  on lifetime best wave 5/10/15/20 (ADR-0007); the Sanctum grants up to ~17 % combat power; the IAP is
  "Remove Ads + 1,500 Soul Shards" (ADR-0009).

## Options considered
1. **One mode; Rifts become skins on one shape** — removes each Rift's identity (twist, roster, boss,
   shape) and the shared shape loses up to about a third of the bigger floors. Rejected.
2. **One mode; runs travel through the Rifts automatically** — keeps the content but leaves nothing to
   sell as arena looks, and every run replays the first arena. Rejected by the owner's split.
3. **Two modes: finite Rift levels (story) + a cosmetic Endless mode** — clear goals and progress in
   the Rifts, score chasing and arena looks in Endless, and a clean line between them. **Chosen.**

## Decision
**Modes**
- **Rifts (story).** Five Rifts × 8 levels. A Rift run plays one level: `waves_per_level` waves, then
  the Rift's boss. Beating the level's final boss **clears the level and ends the run in victory**;
  death ends it in defeat. Levels never advance inside a run (reverses ADR-0008's climb; its threat
  ladder stands). After level 8 the Rift is *mastered* and replays level 8.
- **Unlocks come from clears, not wave depth.** Rift N+1 opens when Rift N level 1 is cleared
  (data-driven per Rift). PLAY starts the selected Rift's next level; a newly opened Rift becomes the
  selection. The Rift Map stays for replays.
- **Endless** opens when Obsidian Garden level 1 is cleared. It plays on the shared floor template
  (ADR-0014) with the equipped arena skin and no rule twists (v1). Each wave's roster comes from a Rift
  whose level 1 is cleared, and each boss is one of their bosses. A boss victory starts a harder cycle
  and never ends the run. Endless owns the best score and best wave.
- **Daily run:** Endless rules, the date seed, a fixed base roster + the Reaper, and a rotating arena
  of the day (unowned skins included), so every player gets the same run.
- **Depth milestones** stay keyed on the lifetime best wave; story runs never pass wave 4, so only
  Endless and daily runs pay them.

**Economy**
- Soul Shards are renamed **Rift Points (RP)**. Sources: pickups, a score-based performance bonus,
  level-clear bonuses (full on the first clear, reduced on repeats), boss rewards, Trials, challenges,
  the daily reward, depth milestones and the opt-in "double RP" rewarded placement.
  **No real-money path grants RP.**
- The **Soul Sanctum is removed**; a save that bought Sanctum levels is refunded that spend in RP.
  No permanent power remains: permanent progress is content access and cosmetics only.
- **Shop (RP):** Wisps (forms; characters later), Dashes (trail styles), Arenas (Endless skins,
  buyable once Endless is open) and No Ads (ADR-0012). Every cosmetic keeps the Wisp's scale, anchor,
  hitbox and rules.
- **Real money:** Remove Ads only, with no currency inside; product id `remove_ads`. ADR-0009's
  rewarded placements stand, with "double Soul Shards" becoming "double RP". Paid cosmetics are future
  work and need their own ADR (ADR-0009 allows one product).

## Consequences
- Sanctum code, data, screen and tests are deleted; the save schema bumps with a refund migration.
- GameWorld gains a run mode and must read arena rules (background, floor, twist, boss, roster,
  difficulty) from one seam, so Endless never needs a fake `RiftData`.
- Trials and challenges need an audit: story runs last at most `waves_per_level` waves, so deep-wave
  goals only complete in Endless or the daily run.
- Two modes to balance instead of one; RP pacing must be measured on a device.
- New art dependency: template-conformant Endless skins before Endless can ship.
- Marketing gets a simple promise: everything is earned by playing, and nothing sold changes the game.
- Pre-release, so wave-gated Rift unlocks in existing saves are not grandfathered.
