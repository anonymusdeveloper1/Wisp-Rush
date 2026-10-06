# System: Pickup items

> **Status:** ✅ implemented · balance/device feel pass pending · **Last updated:** 2026-10-05 · **GDD section:** §14 #76–77

## Purpose
Replace run XP and mutation choices with the seven accepted enemy drops. Store Soul Wards for
double-tap protection, and sell Soul Ward, Rift Magnet and Fortune Star packs with Rift Points.

## Files
| Path | Role |
|---|---|
| `res://scripts/resources/run_item_data.gd` / `run_item_catalog.gd` | Item definitions, shop prices, pack quantities and drop tuning |
| `res://data/items/` | Seven item resources and the catalog |
| `res://scripts/components/run_items.gd` | Temporary effect state |
| `res://scenes/pickups/run_item_pickup.*` | Physical enemy drop and collection |
| `res://scenes/gameplay/run_item_hud.gd` | Ward stock and active effect timers |
| `res://scenes/gameplay/game_world.*` / `res://scenes/player/wisp_player.gd` | Live effects, shield and gestures |
| `res://scenes/screens/shop_screen.*` / `run_item_shop_page.gd` / `res://scenes/main/main.gd` | Item packs and selected starting boost |
| `res://scripts/autoload/save_manager.gd` | Stored stock and purchases |
| `concept_art/pickup_items_v1/` | Preserved generations, packing and visual review |

## Public API
| API | Role |
|---|---|
| `RunItemCatalog.get_item`, `get_shop_items`, `get_pack_price`, `validate` | Definitions and allowed pack prices; invalid packs return -1 |
| `RunItems.activate`, `advance`, `clear`, `is_active`, `get_remaining` | Five temporary timers, immediate Bomb activation and effect expiry |
| `RunItemPickup.configure`, `try_dash_collect`, `collected(item_id)` | Physical floor drop and single collection |
| `GameWorld.activate_item`, `get_run_items`, `spawn_scripted_item` | Effects and deterministic tutorial/QA drops |
| `GameWorld.set_soul_ward_stock`, `get_soul_ward_stock`, `can_activate_soul_ward`, `activate_soul_ward` | Host-synchronized Ward stock and protection |
| `GameWorld.item_collected`, `shield_requested`, `shield_activated`, `run_started` | Main saves stock and spends copies at activation/start |
| `WispPlayer.activate_soul_ward`, `has_soul_ward`, `clear_soul_ward`, `shield_requested`, `shield_broken` | Completed tap gesture and hit protection |
| `SaveManagerService.get_item_count`, `purchase_item_pack`, `grant_item`, `consume_item` | Persistent stock and RP purchases; rollback on save failure |
| `SaveManagerService.select_starting_item`, `consume_starting_item` | One owned boost selected; spend and clear selection together at run start |
| `ShopScreen.item_pack_requested`, `starting_item_selected` | Purchase/selection intent routed by Main |
| `RunItemShopPage.setup`, `pack_requested`, `starting_item_selected` | Stock, affordability, pack buttons and boost selection |
| `RunItemHud.fit`, `refresh`, `get_stock_rect` | Ward counter, hints, icons and remaining seconds |

## Data & tuning
The owner approved choosing provisional values (2026-10-05). Starting unit prices: Soul Ward 40 RP,
Rift Magnet 20 RP, Fortune Star 30 RP. Pack quantities: 1, 5, 10, 25; price = unit price × quantity.
Temporary effects start at 10 s; regular enemy item chance 10%, equal chance among the seven;
Stillglass enemy/projectile speed 0.55; Reaper's Edge corridor multiplier 2; Banish Bomb radius
240 design px; Ward escape immunity 0.9 s. Floor lifetime 14 s; base RP attraction 150 design px.
Completed taps: hold at most 450 ms, second release within 350 ms and three minimum-swipe
distances of the first; movement below the swipe threshold. PlayerTuning stores these timings. Values remain editable and await the owner's feel pass.

## Dependencies
Core run, player, save manager, shop, tutorial and the board HUD (SIMULATION's; BOARD 01 was
removed 2026-10-05, ADR-0027). RUSH remains
the existing separate mechanic. The item effects are run-local; unspent stock is persistent.

## Rules & behaviour
Accepted behaviour: [GDD §14 #76](../GDD.md). Six drops activate on collection. Soul Ward is stored
and double tapping spends one copy to activate it. Shop sells the three discussed items; bought
Magnet/Star copies can be selected for the next run. The selection does not spend stock until waves
start, after prewarm. It clears after that single activation. All pack prices
and stock checks are revalidated in SaveManager, not trusted from buttons.

Repeated timed drops refresh duration without multiplying strength. Timers and floor lifetime use
game time and freeze on pause. Star multiplies earned score alongside RUSH. Stillglass applies to
regular enemies and their shots, including new spawns; bosses keep their existing behaviour. Bomb
clears nearby flying shots and wall marks. Echo spends one extra-hit budget per dash leg; it cannot
recurse into another echo. Ward blocks a hit without health loss, teleport or combo reset, then
grants its escape immunity; RUSH immunity takes priority and does not break it.

XP, level HUD and the upgrade tray are disconnected from GameWorld. The old progression resources
and tray remain as unused legacy files ([mutations.md](mutations.md)). Tutorial lesson 7 uses local
Ward stock and never changes the player's saved inventory. Board protection gauges and counters
replace their former XP/upgrade values; timed icons sit below the top hardware and the Ward hint
sits in the bottom frame.

## How to test
- `tools/run_tests.sh pickup`: four checks for inventory/migration/rollback, seven live effects,
  Main/Shop pack buttons and held-run consumption, emulated touch/mouse double taps, and the
  tutorial's demonstration/player try with save isolation.
- `tools/run_tests.sh gameplay_slice`: scripted target line, combo, wall landing and pause/resume.
- `tools/qa_matrix.sh shop_deals pickups`: both screens at five portrait phone aspects (`shop_deals`
  is the Shop's SHOP page, where ITEMS is a section since 2026-10-05).
- `tools/godot/render_pickup_showcase.gd -- <out.png> [arena_skin_id]`: seven floor icons, Ward and
  five timers; reviewed on BOARD 01 and SIMULATION at 390×844 (BOARD 01 since removed).
- `python concept_art/pickup_items_v1/build_icons.py`: final/runtime copies and raw hash checks.

## Known issues / TODO
Prices, durations and drop chance are provisional; owner device/feel review remains. Full suite:
33 passed, 10 pre-existing stale failures; details in [DEVLOG](../DEVLOG.md).

## Change history
| Date | Change |
|---|---|
| 2026-10-05 | ITEMS is a section of the Shop's SHOP page (owner, GDD §14 #78, ADR-0028); BOARD 01 removed with the other arenas (ADR-0027) |
| 2026-10-05 | Seven drops, saved consumable packs, double-tap Ward, starting boosts, HUD and tutorial implemented and verified |
| 2026-10-05 | Planned after the owner requested implementation and item packs |
