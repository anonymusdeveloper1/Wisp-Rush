# Noxen continuation handoff

Noxen, the Veilflame (`form_id = noxen`) is the approved blue/cyan handless creature. The basic
production path is implemented; continue from it instead of rebuilding the character.

## What exists

- `extract_parts.py` deterministically cuts the transparent twelve-part generation sheet and writes
  `parts/noxen/manifest.json` with pivots, hierarchy and rest transforms.
- `tools/art/extract_playable_characters.py noxen` copies the pack into runtime art and derives the
  portrait from the transparent assembly reference.
- `tools/art/build_character_rig.py noxen` generates `noxen_visual.tscn`. Never hand-edit that scene;
  motion belongs in `noxen_visual.gd`.
- The rig has separate cloak fins, hood, mask, core, front flap, shadow tail and flame horns, plus
  two skinned `RibbonChain` root flames. It implements all 13 shared states and Reduced Motion.
- Dash pose: narrow body, flame horns first, root ribbons streaming behind. `attack` is the contact
  cut: both fins move forward and flare, the core flashes and eight shards burst.
- Home and Shop use the same live rig. The form is a temporary 0-RP Legendary entry and carries a
  cyan `BLADE_ARC` `DashEffectData`.

## Verified in this pass

- `tools/run_tests.sh form_catalog` — pass.
- `tools/run_tests.sh playable_character_visual` — pass, including states, smoothness, ribbons,
  particle budget, Reduced Motion, menus and production GameWorld.
- Full suite — 27 pass / 10 known stale M10 tests fail; no new regression.
- Visual review: Shop card, Home hero, gameplay dash, and filtered reference/idle/dash/attack lineup.

## Continue one reviewable step at a time

1. Capture the full scripted motion sequence and inspect the contact sheet at gameplay scale:
   `WISP_CHARACTER=noxen` with `render_character_motion.tscn`, then
   `python tools/art/motion_contact_sheet.py noxen`.
2. Tune only `noxen_visual.gd` for any weak state. Keep the leading twin flame silhouette in
   `dash_loop`, the visible fin snap in `attack`, and the root ribbons behind the travel axis.
3. Review landings on all four surfaces. The shared base supplies orientation; Noxen's fins provide
   the handless brace. Add a bespoke response only if a surface reads ambiguously.
4. Run the Shop/Home/gameplay screenshots and the two targeted tests after each motion change.
5. Finish with full `tools/validate.sh`, full `tools/run_tests.sh`, a phone pass, docs and DEVLOG.

Owner decisions still needed: approve the name/look/motion, confirm Legendary versus another tier,
set the price, and approve generated-art licensing for distribution.
