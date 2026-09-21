# Ilyra 2 detached animation kit

This folder is a source-art experiment for a layered Ilyra 2 puppet and a dedicated storefront
loop. It does **not** replace the existing Ilyra or the first flattened Ilyra 2 pose pack.

## Deliverables

- `01_secondary_motion_parts_raw.png` — fans, braids, crown jewels, cloth panels, streamers,
  chest glow, dash slash and sparkles on transparent alpha.
- `03_upper_body_puppet_sheet.png` — head, armored torso, four upper arms, four forearms and six
  hand choices on transparent alpha.
- `04_lower_body_puppet_sheet.png` — waist armor, hip flaps, two upper legs, two booted lower legs
  and an underskirt on transparent alpha.
- `sprites/` — the 46 individually cropped puppet components produced by `extract_parts.py`.
- `02_storefront_loop_sheet.png` — a four-frame shop/select showcase loop.
- `storefront_frames/` — four equal-size `600 x 724` RGBA frames with a stable pivot canvas.

## Storefront order

1. `storefront_welcome.png`
2. `storefront_blink.png`
3. `storefront_flourish.png`
4. `storefront_settle.png`

Suggested timing: welcome `0.65 s`, blink `0.16 s`, flourish `0.32 s`, settle `0.75 s`, then
reverse through flourish and blink for a soft loop. For a less busy shop, play the flourish only
when the player selects Ilyra 2 and otherwise alternate welcome/blink/settle.

## Rigging notes

- Keep the torso centered and parent the head, four upper arms, waist and chest-glow overlay to it.
- Parent each forearm to its upper arm, and each chosen hand to its forearm.
- Parent fans to the grip hands. Put the fan pivot at the gold handle point inside the palm, with
  the short gold handle butt visible below the fist.
- Parent each leg at the hip and each lower-leg/boot layer at the knee.
- Parent braids near the rear sides of the head. Use two or three soft rotation keys or a spring;
  do not rigidly copy the head angle.
- Parent cloth panels and waist streamers to the waist, each with its own small delayed sway.
- Crown jewels should float independently above the head with a subtle vertical sine offset.
- Keep the storefront frame canvases untrimmed so their pivot remains stable.

Regenerate the crops from the source sheets with:

```text
python concept_art/ilyra_2_sprite_test/detached_parts/extract_parts.py
```

The source images live under `concept_art/` (which has `.gdignore`). Move only approved final
sprites through the project's deterministic art extraction pipeline before runtime use.
