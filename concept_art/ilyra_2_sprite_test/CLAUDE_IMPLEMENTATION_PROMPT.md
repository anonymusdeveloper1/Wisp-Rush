# Prompt for Claude

Implement the approved **Ilyra 2 sprite experiment** in the Wisp Rush Godot project. This is a
separate test character. Do not replace, rename, refactor or otherwise modify the existing Ilyra
form, scene, script, assets or current uncommitted Ilyra work.

Read and follow `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, `docs/generated/PROJECT_MAP.md`, the relevant
GDD sections, `docs/CONVENTIONS.md`, `docs/systems/ui_design_system.md`, the redesign style guide,
ADR-0005, ADR-0006, `docs/guides/character_rig_recipe.md`,
`docs/systems/playable_character_visuals.md`, ADR-0015, and the current DEVLOG/ROADMAP entries before
editing.

The reviewed source pack is:

`concept_art/ilyra_2_sprite_test/final_sprites/`

Its state mapping and wall-orientation rules are documented in:

`concept_art/ilyra_2_sprite_test/README.md`

Requirements:

1. Preserve the existing Ilyra exactly. Add a new form id `ilyra_2`, temporary display name
   `ILYRA 2`, tier Mythic, test price 0, and a separate visual scene/script such as
   `scenes/player/visuals/ilyra_2_visual.tscn` and `.gd`.
2. Implement Ilyra 2 as a whole-pose sprite character, preferably an `AnimatedSprite2D` beneath
   the normal `PlayableCharacterVisual/%MotionRoot`, not as the current skinned procedural Ilyra
   rig. Keep gameplay collision and scoring untouched.
3. Do not reference concept art directly at runtime and do not hand-edit `assets/art/`. Extend the
   deterministic art extraction pipeline (or add a narrowly scoped extractor consistent with the
   existing tools) to copy the reviewed `final_sprites` into
   `assets/art/characters/playable/ilyra_2/`, then regenerate them. Never hand-edit `.import` files
   or invent `uid://` values.
4. Build sprite animations for all thirteen `PlayableCharacterVisual` states using the exact
   mapping in the README. Use the documented two-frame loops and dash sequence. The dash faces
   local `-Y`; let the existing heading spring rotate it toward travel. `attack` uses
   `dash_loop_01_attack`, so the dash visibly is the attack.
5. Implement all four distinct resting surface sprites using inward `surface_normal`:
   `UP -> wall_bottom`, `DOWN -> wall_top`, `RIGHT -> wall_left`, `LEFT -> wall_right`. The four wall
   PNGs are already screen-oriented, so cancel inherited root/MotionRoot rotation while one is
   shown; do not double-rotate them. Use wall poses only for the live gameplay character resting on
   a boundary. Home and Shop previews must use the ordinary idle sprite.
6. Every source PNG is 627×627, but opaque bounds vary. Author or calculate per-pose scale and
   offset around a stable collision-centre anchor. State changes must not change apparent character
   height or make the character jump. This is especially important for the deliberately padded
   `wall_top`. Preserve the existing visual-height contract and expected design size.
7. Keep the shared `AnimationPlayer`/`AnimationTree` whole-body squash, bounce, alpha and heading
   behavior unless it conflicts with wall sprite counter-rotation. Reduced Motion must freeze
   sprite cycling and particles on a readable state pose.
8. Register the new form through the normal catalog/save pipeline: new `FormData`, add the path to
   `default_catalog.tres`, raise `FormCatalog.REQUIRED_FORM_COUNT`, and add `ilyra_2` to
   `SaveManagerService.VALID_FORM_IDS`. Update catalog, save, statistics and playable-character
   tests affected by the count. Do not silently alter the owner's existing save; the free Shop
   purchase/equip flow may be used for this experiment.
9. Add or extend automated coverage for all thirteen states, sprite frame switching, four surface
   mappings, stable anchor position, no visual collision, particle budget, Reduced Motion, Home,
   Shop and GameWorld integration.
10. Verify in small steps: run `tools/validate.sh` after each meaningful change; run the relevant
    filtered tests and then `tools/run_tests.sh`; run the game through the Godot MCP and inspect
    debug output; render Ilyra 2 with the motion fixture and surface-pose fixture; inspect the
    screenshots/contact sheet; finally build/install the Android debug APK and visually verify on
    the connected phone if available.
11. Complete all documentation triggered by PROJECT_CONTEXT §7.2, refresh/check the generated
    project map, and add a DEVLOG entry. Mark this form clearly as an experimental sprite test; do
    not write a production GDD/ADR decision unless the owner approves replacing the experiment.
12. Do not commit or push unless the owner explicitly asks.

Before implementation, report any pose that is technically unusable (cropped anatomy, wrong arm
count, broken transparency or unstable registration). Otherwise proceed without redesigning the
art.
