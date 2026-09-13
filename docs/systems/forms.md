# System: Cosmetic forms

> **Status:** ✅ done · **Last updated:** 2026-09-13 · **GDD section:** §6, §9, §11

## Purpose

Let players preview, purchase and equip all six supplied Wisp forms using earned Soul Shards while
keeping every gameplay value identical.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/form_data.gd` | Form identity, price, requirement, art and tint |
| `res://scripts/resources/form_catalog.gd` | Ordered six-form registry and validation |
| `res://data/forms/*.tres` | Void, Ash, Venom, Bloodmoon, Frost and Eclipse data |
| `res://scenes/screens/forms_screen.tscn` | Carousel picker, ownership, claim/equip and Back UI |
| `res://scenes/screens/forms_screen.gd` | Builds the form cards, presentation and user intents |
| `res://scripts/components/focus_carousel.gd` / `page_dots.gd` | Shared card picker + page indicator ([ui_design_system.md](ui_design_system.md)) |

## Scene / node structure

```text
FormsScreen (Control)
├── Background (menu_background) · Shade
└── SafeMargin → Content (VBox)
    ├── Header: TitleBanner "FORMS" · BalancePlate (%BalanceLabel)
    ├── %Carousel (FocusCarousel) ← six CardButton cards built in code
    ├── %Dots (PageDots, hollow = not owned)
    ├── %DescriptionLabel · %RequirementLabel · %FeedbackLabel
    └── Footer: %BackButton (SecondaryButton) · %ActionButton (PrimaryButton)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `purchase_requested(id)` | signal | Buy the selected locked form. |
| `equip_requested(id)` | signal | Equip the selected owned form. |
| `back_requested` | signal | Return Home. |
| `setup(balance, owned, equipped, bosses)` | method | Refresh all visible form states (safe before `_ready`). |
| `select_form(id)` / `get_selected_form_id()` | method | Focus any form, locked included / the focused form. |
| `show_feedback(message, success)` | method | Short purchase/equip result line. |

## Data & tuning

Prices follow the GDD: Void free; Ash 250; Venom 500; Bloodmoon 800; Frost 1,200; Eclipse 2,000
plus the first boss victory. Each Resource uses one supplied form texture and presentation tint.

## Dependencies

Main mediates SaveManager purchases/equips. Home and WispPlayer display the equipped texture/tint.

## Rules & behaviour

- **Picker (owner decision 2026-09-13):** a portrait carousel — one big lifted, magenta-framed card
  in the centre, neighbours dimmed at the sides, page dots, a description, then Back and one main
  button. Swipe or tap a side card to browse; tapping the focused card does what the main button does.
- Each card: name, the portrait over a halo in the form's tint (dimmed when not owned), and a state
  row — EQUIPPED / OWNED / REAPER / shard price, always with an icon.
- `%ActionButton`: EQUIPPED (disabled) / EQUIP / REAPER REQUIRED (disabled, lock) / CLAIM price
  (shard icon; disabled until affordable). `%RequirementLabel` says why in text.
- The carousel opens on the equipped form and follows it until the player picks one.
- Portraits come from the redesign form sheet, and each form's `tint` drives gameplay VFX colour.
- Every form can be previewed while locked.
- Purchase is rejected without enough balance or Eclipse's boss requirement.
- Equipping changes sprite and feedback tint only—never collision, health, speed, damage, XP/score.
- Void is always owned and a corrupt equipped ID falls back to Void.

## How to test

- Verify all six Resources, preview locked forms, rejected/accepted purchase and persisted equip.
- `test_menu_screens.gd` (carousel selection, tap-to-act), `test_progression_screens.gd` (`%ActionButton`).
- Phone layouts: `tools/qa_matrix.sh forms`.

## Known issues / TODO

- Trail and collection-particle tint polish belongs to Milestone 4; core sprite/impact tint ships now.

## Change history

| Date | Change |
|---|---|
| 2026-09-13 | Forms screen rebuilt as a `FocusCarousel` card picker; `%ActionButton` replaces the grid + action |
| 2026-09-12 | Restyled to redesign v1; tints retuned to the new portraits (ADR-0005) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
