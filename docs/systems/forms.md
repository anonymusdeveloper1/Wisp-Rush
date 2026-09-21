# System: Cosmetic forms (the character catalog)

> **Status:** ✅ done · **Last updated:** 2026-09-20 · **GDD section:** §6, §9, §11
>
> **Changed 2026-09-15 ([spec 04](../specs/story_and_endless/04_shop.md)):** the Forms screen is retired;
> forms are bought and equipped in the Shop ([shop.md](shop.md)). `FormData` and `FormCatalog` stay.
> **Changed 2026-09-20:** the catalog holds seven characters — two Wisp forms, four production
> rigs, and Ilyra, the whole-frame sprite character. The Shop tab is CHARACTERS.

## Purpose

Let players preview, purchase and equip every character using earned Rift Points while keeping
every gameplay value identical.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/form_data.gd` | Character identity, price, requirement, portrait, tint and optional `visual_scene` rig |
| `res://scripts/resources/form_catalog.gd` | Ordered thirteen-character registry (`REQUIRED_FORM_COUNT`) and validation |
| `res://data/forms/*.tres` | Void and Eclipse (Wisp forms), Veyra, Rook, Morrow and Noxen (rigs), and Ilyra (whole-frame sprite) — seven, since the 2026-09-20 cut |
| `res://scenes/screens/shop_screen.tscn` / `.gd` | CHARACTERS tab: the animated card carousel, buy/equip ([shop.md](shop.md)) |
| `res://scripts/components/focus_carousel.gd` / `page_dots.gd` | Shared card picker + page indicator ([ui_design_system.md](ui_design_system.md)) |

## Scene / node structure

No screen of its own since 2026-09-15: characters are cards in the Shop's CHARACTERS tab
([shop.md](shop.md)).

## Public API

| Member | Kind | Description |
|---|---|---|
| `FormCatalog.load_forms()` / `get_form(id)` / `validate()` | method | Ordered forms / lookup with Void fallback / authoring checks. |
| `SaveManagerService.purchase_cosmetic(&"form", id, price, requirement_met)` / `equip_cosmetic(&"form", id)` | method | Buy (and equip) / equip, through Main. |

## Data & tuning

Prices are in Rift Points and follow the GDD: Void free; Ash 250 RP; Venom 500 RP; Bloodmoon 800 RP;
Frost 1,200 RP; Eclipse 2,000 RP plus the first boss victory; every newer character is 0 RP while
the owner reviews it (GDD §14 #31–33). Each resource has a portrait texture and a presentation
tint; animated characters also name their visual scene.

## Dependencies

Main mediates SaveManager purchases/equips. Home and WispPlayer display the equipped portrait, rig
and tint; the Shop animates every card ([playable_character_visuals.md](playable_character_visuals.md)).

## Rules & behaviour

- **Picker (owner decision 2026-09-13, now the Shop's CHARACTERS tab):** a card carousel — one big lifted, magenta-framed card
  in the centre, neighbours dimmed at the sides, page dots, a description, then Back and one main
  button. Swipe or tap a side card to browse; tapping the focused card does what the main button does.
- Each card: name, the character alive over a halo in its tint (dimmed when not owned), and a state
  row — EQUIPPED / OWNED / BOSS / price (`250 RP`), always with an icon. Rigged characters play their
  own idle; single-image forms idle on the shared rig; Shade and Ilyra play a menu video (ADR-0016).
  Focus, equip and purchase play nothing — no bounce (owner, 2026-09-21).
- `%ActionButton`: the Shop's five states (`BUY  •  250 RP`, `NEED 50 RP`, `BEAT A BOSS FIRST`, EQUIP,
  EQUIPPED); buying equips.
- The carousel opens on the equipped form and follows it until the player picks one.
- Portraits come from the redesign form sheet, and each form's `tint` drives gameplay VFX colour.
- Every form can be previewed while locked.
- Purchase is rejected without enough balance or Eclipse's boss requirement.
- Equipping changes the look, trail particles and feedback tint only—never collision, health,
  speed, damage, XP/score.
- Void is always owned and a corrupt equipped ID falls back to Void.

## How to test

- Tap the hero on Home (or CHARACTERS on Results) to open the Shop's CHARACTERS tab. Verify all thirteen
  cards animate, locked cards preview, purchases are rejected/accepted and the equip persists.
- `tools/run_tests.sh form_catalog` and `playable_character_visual`.
- Headless screen tests still target the retired Forms screen and are stale (owner cleans them up).
- Phone layouts: `tools/qa_matrix.sh shop_wisps`.

## Known issues / TODO

- Trail and collection-particle tint polish belongs to Milestone 4; core sprite/impact tint ships now.

## Change history

| Date | Change |
|---|---|
| 2026-09-20 | Thirteen characters: Noxen, the Veilflame added as a free-for-review Legendary rig |
| 2026-09-18 | Eleven characters: Ilyra (Mythic) and Bram (Legendary) added with `FormData.tier`, shown as a badge on the focused card |
| 2026-09-17 | Nine characters (Veyra, Rook, Morrow added, `visual_scene`); tab renamed CHARACTERS; animated cards |
| 2026-09-15 | Forms screen retired; forms live in the Shop's WISPS tab (spec 04) |
| 2026-09-15 | Prices and balance in Rift Points (`RiftPoints.format`, spec 01) |
| 2026-09-13 | Forms screen rebuilt as a `FocusCarousel` card picker; `%ActionButton` replaces the grid + action |
| 2026-09-12 | Restyled to redesign v1; tints retuned to the new portraits (ADR-0005) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
