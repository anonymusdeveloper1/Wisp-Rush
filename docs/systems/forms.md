# System: Cosmetic forms

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §6, §9, §11

## Purpose

Let players preview, purchase and equip all six supplied Wisp forms using earned Soul Shards while
keeping every gameplay value identical.

## Files

| Path | Role |
|---|---|
| `res://scripts/resources/form_data.gd` | Form identity, price, requirement, art and tint |
| `res://scripts/resources/form_catalog.gd` | Ordered six-form registry and validation |
| `res://data/forms/*.tres` | Void, Ash, Venom, Bloodmoon, Frost and Eclipse data |
| `res://scenes/screens/forms_screen.tscn` | Preview, ownership, purchase/equip and Back UI |
| `res://scenes/screens/forms_screen.gd` | Form presentation and user intents |

## Scene / node structure

```text
Main
└── FormsScreen
    ├── Preview
    ├── six selectable form buttons
    └── Purchase/Equip + Back
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `purchase_requested(id)` | signal | Buy the selected locked form. |
| `equip_requested(id)` | signal | Equip the selected owned form. |
| `back_requested` | signal | Return Home. |
| `setup(balance, owned, equipped, bosses)` | method | Refresh all visible form states. |

## Data & tuning

Prices follow the GDD: Void free; Ash 250; Venom 500; Bloodmoon 800; Frost 1,200; Eclipse 2,000
plus the first boss victory. Each Resource uses one supplied form texture and presentation tint.

## Dependencies

Main mediates SaveManager purchases/equips. Home and WispPlayer display the equipped texture/tint.

## Rules & behaviour

- Redesign v1 layout: portrait-ring preview with a detail card, a 3×2 `SlotButton` grid (pressed = magenta selection) and one persistent bottom action. Portraits come from the redesign form sheet, and each form's `tint` drives gameplay VFX colour.
- Every form can be previewed while locked.
- Purchase is rejected without enough balance or Eclipse's boss requirement.
- Equipping changes sprite and feedback tint only—never collision, health, speed, damage, XP/score.
- Void is always owned and a corrupt equipped ID falls back to Void.

## How to test

- Verify all six Resources, preview locked forms, rejected/accepted purchase and persisted equip.

## Known issues / TODO

- Trail and collection-particle tint polish belongs to Milestone 4; core sprite/impact tint ships now.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Restyled to redesign v1; tints retuned to the new portraits (ADR-0005) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
