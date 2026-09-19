# System: Shop & Rift Points

> **Status:** ✅ Rift Points (spec 01) and the four-tab Shop with dash styles (spec 04) built 2026-09-15 ·
> **Last updated:** 2026-09-17 · **GDD section:** §6, §11, §14 #16, #31 ·
> **ADR:** [0013](../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [0012](../decisions/0012-store-surface-before-billing.md) ·
> **Specs:** [01](../specs/story_and_endless/01_rift_points.md), [04](../specs/story_and_endless/04_shop.md) (both built)

## Purpose
Rift Points (RP) are the only currency, earned only by playing. The Shop spends them on cosmetics —
characters (Wisp forms and animated characters), dash styles and Endless arena skins — and hosts the
real-money Remove Ads tab.

## Files
| Path | Role | State |
|---|---|---|
| `res://scripts/resources/economy_tuning.gd` · `res://data/economy/default_economy_tuning.tres` | RP payouts that are not pickups | ✅ |
| `res://scripts/utils/rift_points.gd` | `RiftPoints`: `1,250 RP` / `+45 RP` text | ✅ |
| `res://scripts/autoload/save_manager.gd` | `rift_points` balance, rewards, cosmetic purchases and equips (schema v8) | ✅ |
| `res://scenes/gameplay/game_world.gd` | In-run RP (`_award_rift_points`), `rp_collected` / `rp_performance` summary | ✅ |
| `res://scenes/screens/results_screen.*` | RP breakdown and balance | ✅ |
| `res://tools/godot/calibrate_rp.gd` | Scripted bot runs that log score and RP (not a test) | ✅ |
| `res://scenes/screens/shop_screen.tscn` / `.gd` | RP balance, tab bar, one `FocusCarousel` per RP tab, NO ADS panel | ✅ |
| `res://scripts/resources/dash_style_data.gd` · `dash_style_catalog.gd` · `res://data/dash_styles/*.tres` | Dash styles (trail + launch burst tints) | ✅ |
| `res://scripts/resources/form_catalog.gd`, `endless_catalog.gd` | Character and arena items | ✅ (9 characters, 30 arena skins) |
| `res://scenes/player/visuals/playable_character_preview.gd` | Live character on each CHARACTERS card ([playable_character_visuals.md](playable_character_visuals.md)) | ✅ |
| `%TierLabel` in `shop_screen.tscn` | Collectible tier of the focused character (`FormData.tier`), above the description | ✅ |

## Public API
| Member | Kind | Description |
|---|---|---|
| `SaveManagerService.add_rift_points(amount)` / `get_rift_points()` | method | Adds a non-negative reward / reads the balance. |
| `SaveManagerService.record_run(summary)` | method | Adds `rp_collected + rp_performance` once. |
| `EconomyTuning.get_performance_points(score)` | method | `score / score_per_rift_point`, never negative. |
| `GameWorld.get_rp_collected()` / `get_rp_performance()` | method | Run RP so far / the bonus the current score pays. |
| `RiftPoints.format(amount)` / `format_gain(amount)` / `group_digits(value)` | static | `1,250 RP`, `+45 RP`, `12,480`. |
| `SaveManagerService.purchase_cosmetic(kind, item_id, price, requirement_met)` | method | Spends RP and equips; false (nothing spent) when unaffordable, owned, unknown, gated, or an arena skin before Endless opens. |
| `SaveManagerService.equip_cosmetic(kind, item_id)` / `owns_cosmetic(kind, item_id)` | method | Equip an owned item / ownership check. |
| `ShopScreen.setup(snapshot, tab)` · `get_tab()` · `get_selected_id()` · `show_feedback(message, success)` | method | Save snapshot plus `store_available` (added by Main); safe before `_ready`. |
| `ShopScreen.purchase_requested(kind, item_id)` · `equip_requested(kind, item_id)` · `store_purchase_requested(product_id)` · `restore_requested` · `tab_changed(tab)` · `back_requested` | signal | Intent only; Main runs SaveManager / Monetisation. |
| `DashStyleCatalog.get_style(id)` / `get_style_ids()` / `validate()` | method | Lookup with SOUL fallback / save validation ids / id, free-default and hue checks. |

Kinds: `SaveManagerService.KIND_FORM` `&"form"`, `KIND_DASH_STYLE` `&"dash_style"`, `KIND_ARENA_SKIN`
`&"arena_skin"`. Tabs: `ShopScreen.TAB_WISPS` `&"wisps"` (labelled CHARACTERS since 2026-09-17; the id
keeps the old name), `TAB_DASHES`, `TAB_ARENAS`, `TAB_NO_ADS`.

## Data & tuning (starting values; calibrate on a device)
| Field | Value | Meaning |
|---|---|---|
| `EconomyTuning.score_per_rift_point` | 200 | Performance bonus = score ÷ this, rounded down (spec start 400; halved by the bot calibration below) |
| `EconomyTuning.placeholder` | `true` | Bot estimate, **pending device calibration**; must be `false` before release (ROADMAP M6) |
| `level_clear_base` / `level_clear_per_level` | 20 / 10 | ⬜ spec 02: first clear of level n pays base + (n − 1) × per_level |
| `repeat_clear_fraction` | 0.25 | ⬜ spec 02: share of the first-clear bonus paid on repeats |
| Pacing target | 35–45 RP per median early run | GDD §14 #16 |
| Other sources (unchanged) | pickups (`EnemyTuning.shard_drop_chance`, 1 RP each), 1 RP per 3 kills in a multi-reap, boss `rp_reward` 25 (×2 in Reaper's Court), daily 10, challenges 15–25, Trials 15–125, depth 25–300 | |
| Characters | void 0 · ash 250 · venom 500 · bloodmoon 800 · frost 1,200 · eclipse 2,000 + first boss victory · veyra 0 · rook 0 · morrow 0 (owner review; GDD §14 #31) | RP |
| Dash styles | soul 0 (plays the form's tint, `uses_form_tint`) · moonsilver 300 · verdant 600 · abyssal 900 | RP; tints from Palette (Verdant lightened from moss green, Abyssal a deep blue) |
| Arena skins (30) | astral_observatory 0 (default) · drowned_sanctum 800 · moonpetal_shrine 1,200 · others by tier: Simple 300 · Rare 800 · Legendary 2,000 · Mythic 3,500 — full table in [endless_mode.md](endless_mode.md) | RP; owner decision 2026-09-15. ARENAS cards show a 282×502 thumbnail (never the full background), `<TIER>  ·  PLAYS IN ENDLESS`, and, for Legendary/Mythic, the static scenery grade + glow (`ArenaAmbience.create_material`; the animation plays only in a run) |

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
[monetisation.md](monetisation.md) (No Ads tab), [ui_design_system.md](ui_design_system.md)
(`FocusCarousel`, Theme variations), [core_run.md](core_run.md) (payouts, dash trail),
[meta_progression.md](meta_progression.md) (Trials and depth rewards).

## Rules & behaviour
- No real-money path grants RP. Remove Ads grants ad removal only, and restoring grants nothing else.
- Every RP source reaches the balance exactly once: the run's collected + performance RP through
  `record_run`, challenges, Trials and depth milestones through their own calls. Results shows RP
  COLLECTED, PERFORMANCE, REWARDS, the TOTAL (the measured balance change) and the new BALANCE.
- Text: `RP` after numbers (`1,250 RP`), "Rift Points" in sentences; the shard icon stays. The pickup
  keeps its `soul_shard_pickup` file and class names; nothing player-facing says "shard" except the
  Shard Wraith.
- Defaults are owned from the start: the void form, the SOUL dash style and the default arena.
- Arena skins cannot be bought until Endless is open. Every purchase equips immediately.
- **Shop screen:** header (SHOP, RP balance), a tab bar (`NavBar` of toggle `NavButton`s), then per RP
  tab a card carousel like the old Forms picker with a description and one main button:
  `BUY  •  800 RP` · disabled `NEED 120 RP` · disabled gate reason (`BEAT A BOSS FIRST` for Eclipse,
  `UNLOCK ENDLESS FIRST` for arenas) · `EQUIP` · disabled `EQUIPPED`. CHARACTERS cards show the character
  alive (its rig, or its portrait on the shared rig): the focused card plays a selected flourish, a
  purchase the unlock flourish and an equip the selected one (the Shop diffs the old and new
  snapshot in `setup`),
  DASHES an animated trail + burst preview (static under Reduced Motion), ARENAS the background
  thumbnail labelled `PLAYS IN ENDLESS`. Only the active tab's cards are built; ARENAS cards start as
  empty frames and get their thumbnail + scenery material only within `ARENA_VISUAL_RADIUS` (2) of the
  focused card as the carousel scrolls, one shared `ShaderMaterial` per `ArenaSceneryData`. NO ADS is the ADR-0012 panel (Remove Ads + Restore, disabled
  without a store) and shows no RP.
- **Routing:** Home's hero tap → CHARACTERS; SHOP → the last tab viewed this session (default
  CHARACTERS); NO ADS → NO ADS; Results' CHARACTERS → CHARACTERS. Back returns where the Shop was opened from (Results
  is re-shown from its stored summary, nothing is banked twice).
- **Feedback:** a purchase plays `ui_purchase`, an equip `ui_confirm`, a failure `ui_error`, each with
  a message line.
- Every cosmetic keeps the Wisp's scale, anchor, hitbox, timing and rules.
- Dash styles never lead with warning amber or rift magenta (catalog validation checks the hue).

## How to test
- `tools/run_tests.sh save_manager` (v6 migration and refund), `monetisation` (no RP from Remove Ads),
  `main_progression_flow` (Results total = balance change = 3 + 1 RP plus rewards computed
  independently from the pre-run save, so a double payment fails), `player_health_flow` (the live
  GameWorld summary carries `rp_collected` / `rp_performance` from the wired `EconomyTuning`, every
  Trial and challenge metric is a summary key, `get_performance_points` edge cases), `rift_points_text`
  (wording; every currency value is a grouped number with RP).
- Calibration: `WISP_ISOLATED_SAVE=1 $GODOT --path . --resolution 390x844 --script res://tools/godot/calibrate_rp.gd`.
- Visual: `tools/qa_matrix.sh home results shop_wisps shop_dashes shop_arenas shop_no_ads daily trials`.
- `test_shop.gd` / `test_dash_styles.gd` were not written (owner instruction 2026-09-15); screen tests
  that used the Forms screen or the old Shop `setup` are stale.

## Known issues / TODO
- RP pacing is a bot estimate: the bots never dodge, so most die to the first boss. A device pass
  must confirm or retune `score_per_rift_point`, then set `placeholder = false`.
- Spec 02's first-clear bonus lands on top of today's numbers for runs that beat the level boss.
- The Remove Ads card's emblem is Home's NO ADS glyph ("AD" with an amber strike) rather than currency
  art, so it can't read as a Rift Points pack.
- Not yet verified on a device: tab bar and long button text (`UNLOCK ENDLESS FIRST`) on small phones,
  dash tint contrast on every Rift and Endless skin.
- `Main._show_results` logs a warning when the measured RP total differs from collected +
  performance + rewards; only the balance cap should ever cause it.
- Paid cosmetics (custom Wisps, characters) are future work and need an ADR superseding ADR-0009's
  one-product rule (GDD §14 #20).

## Change history
| Date | Change |
|---|---|
| 2026-09-17 | WISPS tab renamed CHARACTERS; every character card animates; unlock and selected flourishes; a snapshot that arrives after the cards were built re-focuses the equipped card |
| 2026-09-16 | Lazy ARENAS card visuals (focused ± 2, shared scenery materials), active tab only |
| 2026-09-15 | Spec 04 built: four-tab Shop, dash styles, `purchase_cosmetic` / `equip_cosmetic`, Forms screen retired |
| 2026-09-15 | Spec 01 built: Rift Points everywhere, `EconomyTuning` performance bonus, calibration tool and bot numbers, Remove Ads without currency |
| 2026-09-15 | Review: exactly-once RP checks end to end, live summary checks, NO ADS emblem on the offer card |
| 2026-09-14 | Planned (ADR-0013) |
