# Implementation brief — Ilyra first, then Bram

> **Owner decision:** both designs are approved. Implement Ilyra completely and verify her before
> touching Bram's runtime files. If Ilyra is blocked, report the blocker instead of skipping ahead.

## 1. Existing architecture is authoritative

Read `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, `docs/generated/PROJECT_MAP.md`, GDD §§6/9/11/14,
`docs/CONVENTIONS.md`, `docs/systems/playable_character_visuals.md`,
`docs/decisions/0015-animated-playable-characters.md`, and the forms, Shop, player-dash and save docs.

- Reuse `PlayableCharacterVisual`, `PlayableCharacterPreview`, `ChainSpring`, `RibbonChain`, the
  existing 13-state AnimationTree vocabulary and `WispPlayer/%CharacterVisualMount`.
- The rigs are presentation only. They contain no collision, hitbox, hurtbox or gameplay logic.
- The existing `WispPlayer/%CollisionShape` remains the only logical footprint.
- Preserve camera, controls, dash timing, damage, health, scoring, wall landing and full-screen UI.
- Preserve Reduced Motion: stable pose, particles off and no hidden background processing.

## 2. Source-art pipeline

Approved references:

- `references/ilyra_concept.png`
- `references/bram_concept.png`

They are opaque concept sheets, never runtime sprites. For each character:

1. Create a clean transparent rig-source sheet under `assets/<id>_rig_source.png` without altering
   the approved reference. Preserve identity, proportions, palette and costume.
2. Extend `tools/art/extract_playable_characters.py` rather than duplicating its cleanup/contact-sheet
   machinery. Allow versioned per-character source paths so v1 output stays byte-stable.
3. Extract isolated lossless RGBA layers to `res://assets/art/characters/playable/<id>/`, plus a
   `preview.png`. No baked black/grey background, fringe, checkerboard, remote specks or clipped glow.
4. Produce `logs/playable_characters/<id>_parts.png` and inspect every part at native size.
5. Never hand-edit `.import` files or use the complete concept/rig sheet in a scene.

If clean production layers cannot be derived with the available art tooling, stop and report that
specific art blocker. Do not ship rough geometric substitutes or degrade the approved design.

## 3. Ilyra — Mythic, phase 1

Stable id: `ilyra`. Display: `ILYRA`. Title/description: `The Astral Dancer`.

Minimum layer families:

- torso/base, head/face, hair front/back, cyan heart core;
- exactly four connected arm chains with shoulder, elbow and hand pivots;
- two fans, preferably separate frame/membrane layers so opening remains clean;
- two leg chains and boots;
- left/right multi-joint braids;
- six independently pivoted skirt panels;
- four skinned waist ribbons;
- three independent crown pieces;
- restrained fan-arc and star-fragment VFX textures.

Motion identity by existing state:

| State | Ilyra direction |
|---|---|
| `idle_hover` | 1.8 s seamless calm four-arm choreography; gentle fan opening; alternating braid/ribbon delay; crown drift |
| `move_fly` | arms and panels lean into travel; ribbons lag by speed; face remains readable |
| `aim_charge` | lower hands gather around the heart; fan arms cock outward; skirt/ribbons pull inward |
| `dash_start` | 0.12 s anticipation; fans fold and all four arms narrow around the travel axis |
| `dash_loop` | compact spearhead silhouette; braids/ribbons stream separately; no limb jitter |
| `dash_end` | feet-first wall brace; fans and lower hands open with overshoot, then settle |
| `attack` | 0.24 s opposing fan cross-slash and two short visual arcs; never changes collision |
| `hit_reaction` | asymmetric arm guard, braid/panel snap and quick recovery |
| `death` | fans close, crown descends and choreography folds inward before the controller fade |
| `revive_spawn` | crown assembles, heart lights, limbs and panels unfold from the center |
| `victory` | joyful four-arm fan pattern with restrained follow-through |
| `character_selected` | readable fan salute |
| `character_unlocked` | radial four-arm dance pose; detail comes from the rig, not a particle burst |

Use `RibbonChain`/`ChainSpring` for braids and ribbons where appropriate. Cap live particles at 28 and
the whole rig below the existing 40-particle test ceiling. Reduced Motion must retain a clear neutral
pose with exactly four attached arms and two legs.

### Ilyra completion gate

Before creating Bram runtime files, all of these must pass:

- extractor/contact sheet review;
- `tools/validate.sh`;
- updated `form_catalog` and `playable_character_visual` targeted tests;
- all 13 states exercised without snaps, detached limbs, texture gaps or face occlusion;
- lineup plus motion contact sheets inspected;
- production Shop selection/unlock, Home and actual GameWorld screenshots inspected;
- real Godot run/debug output checked; no new errors;
- Reduced Motion and hidden-preview processing verified.

## 4. Bram — Legendary, phase 2

Stable id: `bram`. Display: `BRAM`. Title/description: `The Rift Knight`.

Minimum layer families:

- torso/hips, helmet, visor light and chest core;
- connected left/right upper arms, forearms and hands;
- compact shield and short soul-blade;
- connected left/right legs and boots;
- two spring-driven cape panels;
- restrained blade arc, shield spark and dash streak VFX.

Bram must remain visibly simpler than Ilyra: no orbiters, no extra limbs and no constant large effect.
Idle uses weight shift, visor/core pulse and small cape drag. Aim raises the shield and draws the
blade back. Dash is shield-first with tucked limbs; attack is one clean sword cut; landing compresses
through both boots; hit braces behind the shield; death kneels/folds; selected is a sword salute;
unlocked is a shield plant plus short cyan flare. Cap live particles at 16.

Run the same completion gate and then compare both characters at identical preview and gameplay
scale. Bram's lower complexity must read as intentional polish, not missing animation.

## 5. Catalog, rarity and persistence

- Add `res://data/forms/ilyra.tres` first, then `bram.tres`; append them to the catalog in that order.
- Update the required catalog count from 9 to 11 and extend the existing save-id allowlist. The same
  `owned_forms` / `equipped_form` fields are used, so do not create a second character save system.
- Both remain 0 RP review items unless the owner supplies prices. Do not invent balance values.
- Add typed cosmetic tier metadata to `FormData`: existing entries default to `STANDARD`; Ilyra is
  `MYTHIC`; Bram is `LEGENDARY`. Tier is presentation-only and never modifies stats or collision.
- Show the tier in the focused Shop character presentation without replacing price/ownership state
  or harming phone layouts. Reuse the current theme and palette; no per-node ad-hoc styling.
- Keep Home, HUD portrait, Shop preview, selected/unlocked flourish and every gameplay scene working.

## 6. Final verification and documentation

- Extend existing tests and fixtures; do not create a parallel testing architecture.
- Run both targeted tests, `tools/validate.sh`, `tools/run_tests.sh`, the preview benchmark and
  `tools/qa_matrix.sh shop_wisps`. Separate any documented pre-existing stale-test failures from new
  regressions; do not hide either.
- Run the project through the Godot MCP, play each character in a real GameWorld and inspect debug
  output. Capture selection, Home, motion and gameplay evidence for each.
- Keep mobile readability, overdraw and preview construction cost within the current character
  system's targets.
- Update the project map, ASSETS registry, GDD/ROADMAP decisions, playable-character/forms/Shop/save
  docs and DEVLOG. Report every created/modified file and remaining art/performance limitations.
- Preserve unrelated worktree changes. Do not commit or push unless the owner explicitly asks.

