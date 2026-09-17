# Phase 4 — One Shop for everything Rift Points buy

> Part of [story_and_endless](README.md) · **Rules:** GDD §6 (Shop), §9 (cosmetics keep the hitbox), §11,
> §14 #18–#19; [ADR-0013](../../decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [ADR-0012](../../decisions/0012-store-surface-before-billing.md) ·
> **Touches:** [shop.md](../../systems/shop.md) (fill it), [forms.md](../../systems/forms.md),
> [monetisation.md](../../systems/monetisation.md), [ui_design_system.md](../../systems/ui_design_system.md),
> [game_flow.md](../../systems/game_flow.md), [save_manager.md](../../systems/save_manager.md),
> [core_run.md](../../systems/core_run.md) (dash trail)

## Goal
The Shop is the only place to spend RP. It has four tabs — WISPS, DASHES, ARENAS, NO ADS — each a
card carousel with one main button. The Forms screen is retired. Dash styles recolour the dash trail
and change nothing else.

## Where things are today
| Concern | Location |
|---|---|
| Forms picker | `res://scenes/screens/forms_screen.*` on `FocusCarousel`; `Main._show_forms`, `_on_form_purchase_requested`, `_on_form_equip_requested`; `FormCatalog`, `FormData` (`price`, `requires_boss_victory`, `texture`, `tint`) |
| Shop | `res://scenes/screens/shop_screen.*`: Remove Ads + Restore, disabled without a store (ADR-0012); `Main._show_shop` |
| Home routes | Wisp tap → `forms_requested`; SHOP → `shop_requested`; NO ADS → `remove_ads_requested` |
| Results route | `ResultsScreen.forms_requested` |
| Dash trail | `GameWorld._play_dash_trail()` with `DASH_TRAIL_SHORT` / `DASH_TRAIL_LONG` through the VFX pool |
| Purchases | `SaveManagerService.purchase_form`, `equip_form`, `owned_forms`, `equipped_form` |

## Tasks
1. **Cosmetic kinds in SaveManager.** Add `purchase_cosmetic(kind, item_id, price, requirement_met) -> bool`,
   `equip_cosmetic(kind, item_id) -> bool` and `owns_cosmetic(kind, item_id) -> bool` for `&"form"`,
   `&"dash_style"` and `&"arena_skin"`. Forms keep `owned_forms` / `equipped_form`; add
   `owned_dash_styles` / `equipped_dash_style` (default `soul`); the arena keys exist from phase 3.
   Valid ids come from the catalogs rather than hard-coded arrays where possible. Replace every
   `purchase_form` / `equip_form` caller.
2. **Dash styles.**
   - `DashStyleData` (`res://scripts/resources/dash_style_data.gd`): `style_id`, `display_name`,
     `description`, `price`, `trail_tint: Color`, `burst_tint: Color`. Add `DashStyleCatalog` and
     `res://data/dash_styles/*.tres`.
   - Starting set: SOUL (today's look, free), MOONSILVER (300), VERDANT (600), ABYSSAL (900). Pick tints
     from `Palette` and the style guide. Catalog validation rejects any tint with saturation above 0.25
     whose hue is within 25° of warning amber or rift magenta.
   - GameWorld tints the trail and the launch burst from the equipped style. Timing, collision, sound
     and haptics never change. Render a dash on all five Rifts and the Endless skins to check contrast.
3. **Shop screen.**
   - Header: title and RP balance. A tab bar built from Theme type variations (add `ShopTab` variations
     only if none fit, and document them). Remember the last tab for the session.
   - Each RP tab is a `FocusCarousel` of cards that behaves like today's Forms picker (swipe, snap, tap
     a side card, locked items previewable), with a description and one main button:

     | State | Button |
     |---|---|
     | Not owned, affordable, allowed | `BUY  •  800 RP` |
     | Not owned, not enough RP | disabled `NEED 120 RP` |
     | Gated | disabled with the reason: `BEAT A BOSS FIRST` (Eclipse), `UNLOCK ENDLESS FIRST` (arenas) |
     | Owned | `EQUIP` |
     | Equipped | disabled `EQUIPPED` |

   - WISPS: forms (portrait and tint). DASHES: an animated trail preview, static under Reduced Motion.
     ARENAS: a background thumbnail labelled `PLAYS IN ENDLESS`.
   - NO ADS: today's ADR-0012 panel (Remove Ads, Restore) with unchanged behaviour and no RP anywhere.
   - API: `setup(snapshot, tab)`; signals `purchase_requested(kind, item_id)`,
     `equip_requested(kind, item_id)`, `store_purchase_requested(product_id)`, `restore_requested`,
     `back_requested`.
4. **Routing.**
   - Home: Wisp tap → Shop WISPS; SHOP → the last tab (default WISPS); NO ADS → the NO ADS tab.
   - Results' link → Shop WISPS.
   - Back returns to wherever the Shop was opened from.
   - Delete `forms_screen.*` and its routes.
5. **Feedback.** A purchase plays `ui_purchase` and shows the card as equipped (buying equips); a
   failure plays `ui_error` and shows a message.

## Tests
- New `tools/godot/test_shop.gd`:
  - buy and equip each kind;
  - insufficient RP, duplicate, unknown id and gated purchases fail without spending;
  - the balance never goes negative;
  - arena purchases are refused until Endless opens;
  - No Ads changes no balance;
  - the last-tab memory works.
- New `tools/godot/test_dash_styles.gd`: catalog validation (ids, free default, hue rule); equipping a
  style changes the trail tint only — dash duration and hits in a scripted dash match SOUL.
- Update `test_form_catalog`, `test_menu_screens`, `test_screen_setup_order`, `test_screen_transitions`,
  `test_main_progression_flow`, `test_progression_screens` and `test_focus_carousel` for the new routes and screen.
- QA matrix: replace `forms` with `shop_wisps`, `shop_dashes`, `shop_arenas`, `shop_no_ads`.

## Docs
shop.md → ✅; forms.md (screen retired, data kept); monetisation.md (NO ADS tab); ui_design_system.md
(tab variations); game_flow.md; save_manager.md; core_run.md (dash style); PROJECT_CONTEXT §5.1
(Cosmetic forms row → Shop), §5.2 (Shop purpose; Forms scene removed), §5.8 (`DashStyleData`,
`DashStyleCatalog`); ROADMAP M10 spec 04 ✅; DEVLOG entry.

## Acceptance
- [ ] Every RP purchase happens in the Shop, and the Forms screen is gone.
- [ ] Each tab shows the right button for all five states.
- [ ] Dash styles change colour only.
- [ ] No Ads grants no RP, and purchases stay disabled without a store (ADR-0012).
- [ ] `tools/validate.sh` OK · `tools/run_tests.sh` 0 failed · MCP run clean · QA sheets for the four tabs.
