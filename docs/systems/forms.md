# System: Cosmetic forms

> **Status:** ✅ done · **Last updated:** 2026-09-15 · **GDD section:** §6, §9, §11
>
> **Changed 2026-09-15 ([spec 04](../specs/story_and_endless/04_shop.md)):** the Forms screen is retired;
> forms are bought and equipped in the Shop's WISPS tab ([shop.md](shop.md)). `FormData` and
> `FormCatalog` stay.

## Purpose

Let players preview, purchase and equip all six supplied Wisp forms using earned Rift Points while
keeping every gameplay value identical.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/form_data.gd` | Form identity, price, requirement, art and tint |
| `res://scripts/resources/form_catalog.gd` | Ordered six-form registry and validation |
| `res://data/forms/*.tres` | Void, Ash, Venom, Bloodmoon, Frost and Eclipse data |
| `res://scenes/screens/shop_screen.tscn` / `.gd` | WISPS tab: the form carousel, buy/equip ([shop.md](shop.md)) |
| `res://scripts/components/focus_carousel.gd` / `page_dots.gd` | Shared card picker + page indicator ([ui_design_system.md](ui_design_system.md)) |

## Scene / node structure

No screen of its own since 2026-09-15: forms are cards in the Shop's WISPS tab ([shop.md](shop.md)).

## Public API

| Member | Kind | Description |
|---|---|---|
| `FormCatalog.load_forms()` / `get_form(id)` / `validate()` | method | Ordered forms / lookup with Void fallback / authoring checks. |
| `SaveManagerService.purchase_cosmetic(&"form", id, price, requirement_met)` / `equip_cosmetic(&"form", id)` | method | Buy (and equip) / equip, through Main. |

## Data & tuning

Prices are in Rift Points and follow the GDD: Void free; Ash 250 RP; Venom 500 RP; Bloodmoon 800 RP;
Frost 1,200 RP; Eclipse 2,000 RP plus the first boss victory. Each Resource uses one supplied form texture and presentation tint.

## Dependencies

Main mediates SaveManager purchases/equips. Home and WispPlayer display the equipped texture/tint.

## Rules & behaviour

- **Picker (owner decision 2026-09-13, now the Shop's WISPS tab):** a portrait carousel — one big lifted, magenta-framed card
  in the centre, neighbours dimmed at the sides, page dots, a description, then Back and one main
  button. Swipe or tap a side card to browse; tapping the focused card does what the main button does.
- Each card: name, the portrait over a halo in the form's tint (dimmed when not owned), and a state
  row — EQUIPPED / OWNED / BOSS / price (`250 RP`), always with an icon.
- `%ActionButton`: the Shop's five states (`BUY  •  250 RP`, `NEED 50 RP`, `BEAT A BOSS FIRST`, EQUIP,
  EQUIPPED); buying equips.
- The carousel opens on the equipped form and follows it until the player picks one.
- Portraits come from the redesign form sheet, and each form's `tint` drives gameplay VFX colour.
- Every form can be previewed while locked.
- Purchase is rejected without enough balance or Eclipse's boss requirement.
- Equipping changes sprite and feedback tint only—never collision, health, speed, damage, XP/score.
- Void is always owned and a corrupt equipped ID falls back to Void.

## How to test

- Tap the hero Wisp on Home (or WISP FORMS on Results) to open the Shop's WISPS tab. Verify all six
  Resources, preview locked forms, rejected/accepted purchase and persisted equip.
- Headless screen tests still target the retired Forms screen and are stale (owner cleans them up).
- Phone layouts: `tools/qa_matrix.sh shop_wisps`.

## Known issues / TODO

- Trail and collection-particle tint polish belongs to Milestone 4; core sprite/impact tint ships now.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Forms screen retired; forms live in the Shop's WISPS tab (spec 04) |
| 2026-09-15 | Prices and balance in Rift Points (`RiftPoints.format`, spec 01) |
| 2026-09-13 | Forms screen rebuilt as a `FocusCarousel` card picker; `%ActionButton` replaces the grid + action |
| 2026-09-12 | Restyled to redesign v1; tints retuned to the new portraits (ADR-0005) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
