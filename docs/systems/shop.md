# System: Shop & Rift Points

> **Status:** ✅ a bottom navigation between two pages, CHARACTERS and SHOP (NO ADS, ITEMS, RIFT POINTS) (2026-10-05) ·
> **Last updated:** 2026-10-05 · **GDD section:** §6, §11, §14 #16, #31, #78 ·
> **ADR:** [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [0012](../decisions/0012-store-surface-before-billing.md),
> [0028](../decisions/0028-shop-bottom-navigation-and-rift-points-packs.md) ·
> **Specs:** [01](../specs/story_and_endless/01_rift_points.md), [04](../specs/story_and_endless/04_shop.md) (both built)

## Purpose
Rift Points (RP) are the only currency, earned by playing and sold in packs for real money (owner
2026-10-05, ADR-0028). The Shop spends them on characters and consumable items, and hosts the
real-money deals: Remove Ads and the Rift Points packs.

## Files
| Path | Role | State |
|---|---|---|
| `res://scripts/resources/economy_tuning.gd` · `res://data/economy/default_economy_tuning.tres` | RP payouts that are not pickups | ✅ |
| `res://scripts/utils/rift_points.gd` | `RiftPoints`: `1,250 RP` / `+45 RP` text | ✅ |
| `res://scripts/autoload/save_manager.gd` | `rift_points` balance, rewards, cosmetic purchases/equips and item stock/packs (schema v10) | ✅ |
| `res://scenes/gameplay/game_world.gd` | In-run RP (`_award_rift_points`), `rp_collected` / `rp_performance` summary | ✅ |
| `res://scenes/screens/results_screen.*` | RP breakdown and balance | ✅ |
| `res://tools/godot/calibrate_rp.gd` | Scripted bot runs that log score and RP (not a test) | ✅ |
| `res://scenes/screens/shop_screen.tscn` / `.gd` | BACK, title and RP balance; the CHARACTERS `FocusCarousel`; the SHOP page's scrolling list (NO ADS offer, ITEMS section, RIFT POINTS pack cards); the bottom navigation | ✅ |
| `res://scenes/screens/run_item_shop_page.gd` | The ITEMS section: three consumable cards, stock, four pack buttons each and next-run boost selection ([pickup items](pickup_items.md)) | ✅ |
| `res://scripts/resources/rift_points_pack.gd` · `rift_points_pack_catalog.gd` · `res://data/shop/rift_points_packs.tres` | The Rift Points packs sold for real money: product id, RP, price label, icon (ADR-0028) | ✅ |
| `res://assets/art/ui/rp_packs/rp_pack_*.png` | The four pack icons (Codex, `concept_art/rp_packs_v1/`) | ✅ |
| `res://scripts/resources/dash_style_data.gd` · `dash_style_catalog.gd` · `res://data/dash_styles/*.tres` | Dash styles (trail + launch burst tints). Not sold since 2026-09-19 — kept because a run still reads the equipped one, pending per-character dashes | 🔄 |
| `res://scripts/resources/form_catalog.gd` | Character items | ✅ |
| `res://scenes/player/visuals/playable_character_preview.gd` | Live character on each CHARACTERS card ([playable_character_visuals.md](playable_character_visuals.md)) | ✅ |

## Public API
| Member | Kind | Description |
|---|---|---|
| `SaveManagerService.add_rift_points(amount)` / `get_rift_points()` | method | Adds a non-negative reward / reads the balance. |
| `SaveManagerService.record_run(summary)` | method | Adds `rp_collected + rp_performance` once. |
| `EconomyTuning.get_performance_points(score)` | method | `score / score_per_rift_point`, never negative. |
| `GameWorld.get_rp_collected()` / `get_rp_performance()` | method | Run RP so far / the bonus the current score pays. |
| `RiftPoints.format(amount)` / `format_gain(amount)` / `group_digits(value)` | static | `1,250 RP`, `+45 RP`, `12,480`. |
| `SaveManagerService.purchase_cosmetic(kind, item_id, price, requirement_met)` | method | Spends RP and equips; false (nothing spent) when unaffordable, owned, unknown or gated. |
| `SaveManagerService.equip_cosmetic(kind, item_id)` / `owns_cosmetic(kind, item_id)` | method | Equip an owned item / ownership check. |
| `ShopScreen.setup(snapshot, tab)` · `get_tab()` · `get_selected_id()` · `show_feedback(message, success)` | method | Save snapshot plus `store_available` (added by Main); safe before `_ready`. |
| `ShopScreen.purchase_requested(kind, item_id)` · `equip_requested(kind, item_id)` · `store_purchase_requested(product_id)` · `restore_requested` · `tab_changed(tab)` · `back_requested` | signal | Intent only; Main runs SaveManager / Monetisation. `store_purchase_requested` carries `remove_ads` or a Rift Points pack's product id. |
| `RiftPointsPackCatalog.get_pack(product_id)` · `MonetisationService.purchase_rift_points(pack)` | method | The pack for a product id, or null / runs the store purchase and adds the pack's RP; returns the RP added, 0 when nothing was bought. |
| `ShopScreen.item_pack_requested(id, quantity)` / `starting_item_selected(id)` | signals | Main persists purchases/selections; empty id clears the starting boost. |
| `DashStyleCatalog.get_style(id)` / `get_style_ids()` / `validate()` | method | Lookup with SOUL fallback / save validation ids / id, free-default and hue checks. |

Kinds: `SaveManagerService.KIND_FORM` `&"form"`; `KIND_ARENA_SKIN` `&"arena_skin"` stays in the save
layer for the equipped arena (SIMULATION, ADR-0027), and nothing in the Shop reaches it any more. Pages:
`ShopScreen.TAB_WISPS` `&"wisps"` (labelled CHARACTERS since 2026-09-17; the id keeps the old name)
and `TAB_SHOP` `&"shop"`; an unknown id opens SHOP. `KIND_DASH_STYLE` still exists in the save layer
and still colours a run's dash, but nothing in the Shop reaches it any more.

## Data & tuning (starting values; calibrate on a device)
| Field | Value | Meaning |
|---|---|---|
| `EconomyTuning.score_per_rift_point` | 200 | Performance bonus = score ÷ this, rounded down (spec start 400; halved by the bot calibration below) |
| `EconomyTuning.placeholder` | `true` | Bot estimate, **pending device calibration**; must be `false` before release (ROADMAP M6) |
| `level_clear_base` / `level_clear_per_level` | 20 / 10 | ⬜ spec 02: first clear of level n pays base + (n − 1) × per_level |
| `repeat_clear_fraction` | 0.25 | ⬜ spec 02: share of the first-clear bonus paid on repeats |
| Pacing target | 35–45 RP per median early run | GDD §14 #16 |
| Other sources (unchanged) | pickups (`EnemyTuning.shard_drop_chance`, 1 RP each), 1 RP per 3 kills in a multi-reap, boss `rp_reward` 25 (×2 in Reaper's Court), daily 10, challenges 15–25, Trials 15–125, depth 25–300 | |
| Characters | patchvile 0 (default) · verdant_shade 0 · scarlet 0 · rook 0 · mothmere 0 (owner review; GDD §14 #31, #47, #52) | RP |
| ~~Dash styles~~ | soul 0 · moonsilver 300 · verdant 600 · abyssal 900 — **no longer sold** (2026-09-19). Each character carries a `DashEffectData` instead, which is read first; the old catalog and save fields remain as the fallback for a character without one | — |
| Rift Points packs | `rp_pack_500` 500 RP · 0.99 USD · `rp_pack_1200` 1,200 RP · 1.99 USD · `rp_pack_2500` 2,500 RP · 4.99 USD · `rp_pack_6500` 6,500 RP · 9.99 USD — placeholder prices (owner, GDD §14 #78) | Real money, disabled until billing exists |

### Calibration — pending device calibration
Measured 2026-09-15 with `tools/godot/calibrate_rp.gd` (Obsidian Garden level 1, no dodging, 390×844
window; a headless 1344-wide arena batch gave the same picture). Score and `rp_collected` do not
depend on `score_per_rift_point`, so the 200 column is the same runs re-divided. **Pending device
calibration** (`EconomyTuning.placeholder = true`).

| Run | Wave reached | Score | `rp_collected` | `rp_performance` @400 | Total @400 | `rp_performance` @200 | Total @200 |
|---|---|---|---|---|---|---|---|
| Tutorial (novice bot) | 4 (Reaper) | 6,775 | 12 | 16 | 28 | 33 | **45** |
| Early run 1 (novice, seed 211) | 4 (Reaper) | 5,104 | 8 | 12 | 20 | 25 | **33** |
| Early run 2 (steady, seed 313) | 4 (Reaper) | 5,580 | 11 | 13 | 24 | 27 | **38** |
| Steady, seed 311 | 4 (Reaper) | 4,765 | 8 | 11 | 19 | 23 | 31 |
| Steady, seed 307 | 6 | 15,133 | 47 | 37 | 84 | 75 | 122 |
| Novice, seed 227 | 8 | 18,500 | 52 | 46 | 98 | 92 | 144 |
| Novice, seed 223 (capped at 300 s) | 9 | 22,144 | 81 | 55 | 136 | 110 | 191 |

- At the spec's 400 the tutorial and two early runs paid 28 / 20 / 24 RP (median 24), under the
  35–45 target; pickups are ~40 % of it, so the score rate moved, not pickup rates.
- At 200 they pay 45 / 33 / 38 (median 38). Runs that die to the first boss pay 31–45.
- Runs that beat the first boss pay three to four times more, mostly from pickups and the boss
  reward; that is intended (more RP for a better run) but unmeasured with real players.

## Dependencies
[save_manager.md](save_manager.md), [forms.md](forms.md), [endless_mode.md](endless_mode.md),
[monetisation.md](monetisation.md) (Remove Ads and the RP packs), [ui_design_system.md](ui_design_system.md)
(`FocusCarousel`, Theme variations), [core_run.md](core_run.md) (payouts, dash trail),
[meta_progression.md](meta_progression.md) (Trials and depth rewards).

## Rules & behaviour
- Real money buys RP only through the Rift Points packs (owner 2026-10-05, ADR-0028): a completed
  store purchase adds the pack's RP once through `SaveManager.add_rift_points`. Remove Ads grants ad
  removal only, and restoring restores Remove Ads only.
- Every RP source reaches the balance exactly once: the run's collected + performance RP through
  `record_run`, challenges, Trials and depth milestones through their own calls. Results shows RP
  COLLECTED, PERFORMANCE, REWARDS, the TOTAL (the measured balance change) and the new BALANCE.
- Text: `RP` after numbers (`1,250 RP`), "Rift Points" in sentences; the shard icon stays. The pickup
  keeps its `soul_shard_pickup` file and class names; nothing player-facing says "shard" except the
  Shard Wraith.
- Defaults are owned from the start: the default character, the SOUL dash style and the arena
  (SIMULATION). Every character purchase equips immediately.
- **Shop screen** (owner 2026-10-05, GDD §14 #78): a header with BACK, the SHOP title and the RP
  balance; the page; and a bottom navigation (`NavBar` of toggle `NavButton`s) with CHARACTERS and
  SHOP, each tab 160 px tall with size-48 text (owner 2026-10-05: "make the bottom navigation
  bigger"; it was 104 px and 33; the values are Claude's). A character's button: `BUY  •  800 RP` · disabled `NEED 120 RP` · disabled gate reason
  (`BEAT A BOSS FIRST` for a boss-gated character) · `EQUIP` · disabled `EQUIPPED`.
- **CHARACTERS is a card carousel.** A card is the right shape for a thing you *collect*. Cards show
  the character alive (its own scene, or its portrait on the shared rig). Focusing, buying or
  equipping a card plays no flourish — the owner removed the bounce on 2026-09-21, so the card just
  keeps its idle, or its menu video (ADR-0016). Only the focused card and its `LIVE_CARD_RADIUS` neighbours are
  built live; the rest show a still portrait.
- **SHOP is one scrolling list of the deals** (`%ShopPage`), in Claude's order NO ADS → ITEMS → RIFT
  POINTS: the ADR-0012 Remove Ads offer and Restore Purchases; the ITEMS section; and a two-column
  grid of Rift Points pack cards (icon, amount, price, button). Without a store, Remove Ads and
  every pack read `COMING SOON` and are disabled, and the offer says THE STORE IS NOT OPEN YET; with
  one they read `BUY`. (The ARENAS tab was removed with the arenas, 2026-10-05, ADR-0027.)
- **SHOP scrolls by swiping** (owner 2026-10-05: it did not scroll on phones; "remove the side
  scroll"): vertical only, no scroll bar drawn (`vertical_scroll_mode` SHOW_NEVER), as in Settings.
  Every card and button under `%ShopPage` passes touches on (`_pass_touches_to_scroll`, mouse filter
  Pass), so a swipe that starts on them scrolls and does not press; a tap still presses. Measured
  2026-10-05 with simulated touch input on 1080 × 2340: with the old filters a swipe on a card
  scrolled 0 px; now it scrolls, from a card or a pack button, without buying.
- **Routing:** Home's hero tap → CHARACTERS; SHOP → the last page viewed this session (default
  CHARACTERS); NO ADS → SHOP; Results' CHARACTERS → CHARACTERS. Back returns where the Shop was opened from (Results
  is re-shown from its stored summary, nothing is banked twice).
- **Feedback:** a purchase plays `ui_purchase`, an equip `ui_confirm`, a failure `ui_error`, each with
  a message line; a Rift Points pack shows the RP added (`+1,200 RP`) or THE PURCHASE DID NOT
  COMPLETE.
- **ITEMS:** Ward, Magnet and Fortune Star; 1/5/10/25 packs, stock and RP cost shown together.
  Insufficient balance disables that pack; SaveManager revalidates every request. Select an owned
  Magnet/Star with USE NEXT RUN; selection spends nothing until the run starts. Ward is activated
  by double tap in play. Prices and behaviour: [pickup_items.md](pickup_items.md).
- Every cosmetic keeps the Wisp's scale, anchor, hitbox, timing and rules.

## How to test
- `tools/run_tests.sh pickup_inventory` / `pickup_shop_flow`: purchases, failed writes, migration,
  reload, stock, real pack buttons, next-run start and one Ward per emulated double tap.
- `tools/run_tests.sh save_manager` (v6 migration and refund), `monetisation` (no RP from Remove Ads),
  `main_progression_flow` (Results total = balance change = 3 + 1 RP plus rewards computed
  independently from the pre-run save, so a double payment fails), `player_health_flow` (the live
  GameWorld summary carries `rp_collected` / `rp_performance` from the wired `EconomyTuning`, every
  Trial and challenge metric is a summary key, `get_performance_points` edge cases), `rift_points_text`
  (wording; every currency value is a grouped number with RP).
- Calibration: `WISP_ISOLATED_SAVE=1 $GODOT --path . --resolution 390x844 --script res://tools/godot/calibrate_rp.gd`.
- Visual: `tools/qa_matrix.sh home results shop_wisps shop_deals daily trials` (`shop_deals` is the
  SHOP page).
- `test_shop.gd` / `test_dash_styles.gd` were not written (owner instruction 2026-09-15); screen tests
  that used the Forms screen or the old Shop `setup` are stale.

## Known issues / TODO
- RP pacing is a bot estimate: the bots never dodge, so most die to the first boss. A device pass
  must confirm or retune `score_per_rift_point`, then set `placeholder = false`.
- Spec 02's first-clear bonus lands on top of today's numbers for runs that beat the level boss.
- The Remove Ads card's emblem is Home's NO ADS glyph ("AD" with an amber strike) rather than currency
  art, so it can't read as a Rift Points pack.
- Not yet verified on a device: the bottom navigation and the SHOP page on small phones, dash tint
  contrast on SIMULATION.
- The pack prices are placeholders shown as text (`price_label`); billing is not wired (ADR-0012).
- `Main._show_results` logs a warning when the measured RP total differs from collected +
  performance + rewards; only the balance cap should ever cause it.
- Paid characters and bundles are future work (owner: "buy bundles later im gonna sell like a
  character", GDD §14 #78).

## Change history
| Date | Change |
|---|---|
| 2026-10-05 | Google Play Billing (ADR-0030): Google's localized prices on the pack cards and the Remove Ads offer once the store answers; purchase feedback for pending ("PAYMENT PENDING • IT ARRIVES WHEN GOOGLE CONFIRMS IT") and cancelled purchases; a payment that completes later shows its RP |
| 2026-10-05 | SHOP scrolls by swiping on phones and draws no scroll bar (owner): `vertical_scroll_mode` SHOW_NEVER, `_pass_touches_to_scroll` |
| 2026-10-05 | The bottom navigation bigger (owner): each tab 160 px tall (was 104), text 48 (was 33) |
| 2026-10-05 | Bottom navigation, CHARACTERS and SHOP; ITEMS becomes a SHOP section beside NO ADS and the new RIFT POINTS packs (real money, disabled until billing); the ARENAS tab removed with the arenas (owner, GDD §14 #78, ADR-0027, ADR-0028) |
| 2026-10-05 | ITEMS tab with four pack quantities, persistent stock and one-use starting boost selection (ADR-0026) |
| 2026-10-05 | All three Shop tabs share the dedicated pixel-art gallery background ([game_flow.md](game_flow.md)); nearest filtering on the background |
| 2026-09-26 | Scarlet replaces Ilyra in the CHARACTERS tab, free like the rest; the tier badge (`%TierLabel`) is removed with the character tiers (GDD §14 #53) |
| 2026-09-25 | Mothmere joins the CHARACTERS tab, free like the rest of the roster |
| 2026-09-25 | Story Rifts removed (owner): the dash tint check covers the Endless arenas only |
| 2026-09-23 | ARENAS back to a card pager like CHARACTERS (gallery, peek and `handle_back` removed); the thirty skins replaced by one painted arena (ADR-0017) |
| 2026-09-21 | Focus, purchase and equip no longer play a flourish (owner: no bounce); `_play_selected_character_preview`, `_celebrate_character_changes` and `_wake_for_celebration` removed |
| 2026-09-17 | WISPS tab renamed CHARACTERS; every character card animates; unlock and selected flourishes; a snapshot that arrives after the cards were built re-focuses the equipped card |
| 2026-09-16 | Lazy ARENAS card visuals (focused ± 2, shared scenery materials), active tab only |
| 2026-09-15 | Spec 04 built: four-tab Shop, dash styles, `purchase_cosmetic` / `equip_cosmetic`, Forms screen retired |
| 2026-09-15 | Spec 01 built: Rift Points everywhere, `EconomyTuning` performance bonus, calibration tool and bot numbers, Remove Ads without currency |
| 2026-09-15 | Review: exactly-once RP checks end to end, live summary checks, NO ADS emblem on the offer card |
| 2026-09-14 | Planned (ADR-0013) |
