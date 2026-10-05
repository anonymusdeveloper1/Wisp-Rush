# Wisp Rush — character and boss loading scenes

Created 2026-10-04 with the built-in Codex image generator for the owner's request for loading
scenes featuring all current playable characters except Morrow, Grimgrin and the supplied new boss.
The owner then requested implementation in the game.

## Images

| Final image | Scene |
|---|---|
| [loading_new_boss.png](loading_new_boss.png) | The supplied skeletal lantern boss floats above a broken threshold; emerald flames light his robes and the suspended ruins. |
| [loading_grimgrin.png](loading_grimgrin.png) | Grimgrin grips both katanas on a shattered bridge, with crimson cloth, an amber grin and ember-lit stone. |
| [loading_patchvile_grove.png](loading_patchvile_grove.png) | Patchvile crosses a root-covered floating bridge with his curved dagger, ivory scarf, a warm lantern and cyan wisps. |
| [loading_shade.png](loading_shade.png) | Shade hovers above a mossy stone well in a moonlit floating grove, with lime-green horns, tail and side wisps. |
| [loading_scarlet.png](loading_scarlet.png) | Scarlet and her blue folding fan stand on an inlaid moonlit terrace, between warm side lanterns. |
| [loading_rook.png](loading_rook.png) | Rook hovers above a fractured shrine, with violet fissures, floating shards and dark stone steps. |
| [loading_mothmere.png](loading_mothmere.png) | Mothmere walks through a ruined floating library; his red staff wisp, cyan eyes, loose pages and side wisps light the passage. |

[preview_all.png](preview_all.png) is a labelled review sheet; the seven final images have no
embedded lettering or interface. Each final is opaque RGB, **1080 × 2400**, normalized to
**270 × 600** and enlarged **4× nearest**, with at most 256 colors. Counts, hashes, crop boxes,
source files and runtime paths are recorded in [metadata.json](metadata.json).

## Runtime

The builder copies the final PNGs unchanged into `assets/art/environment/loading_screens/`.
`LoadingScreen.BACKGROUND_POOL` in `scenes/screens/loading_screen.gd` chooses one of these seven
at random for boot or a PLAY loading screen. The background node uses nearest filtering.
The existing loading logo, run heading, progress bar, threaded streaming and Reduced Motion
behavior are supplied by `scenes/screens/loading_screen.*`.

Rebuild from the repo root:

```text
python concept_art/loading_screens_v2/build_backgrounds.py
```

The script only crops, reduces, quantizes and enlarges generated art; it does not draw new scenery.
It rebuilds both the source finals and their runtime copies, plus the review sheet and measured
metadata. Runtime PNGs are generated files.

## References and exact prompts

- The current character storefront first frames are used for Shade, Scarlet, Rook and Mothmere.
- Patchvile uses `concept_art/patchvile_autosprite_v1/references/patchvile.png` and `dagger.png`.
- Grimgrin uses the first 256 × 256 cell from his approved floor-idle sheet, enlarged nearest;
  the saved reference is [references/grimgrin.png](references/grimgrin.png).
- The owner's attached new-boss reference is preserved in
  [references/new_boss.jpg](references/new_boss.jpg). “New boss” is a descriptive filename label.
- The corrected `concept_art/loading_and_shop_v1/loading_patchvile.png` supplies the shared
  pixel rendering and floating-ruin world reference.

[generation.json](generation.json) records the original input paths and generated outputs.
Every exact initial prompt is in [prompts/](prompts/). Four loading-layout refinements lower the
new boss, Shade, Scarlet and Rook to clear the existing logo and arena heading; their inputs and
prompts are recorded in [refinements.json](refinements.json). Initial and refined generations
remain unchanged in `raw/`; the builder selects a `_source_v2.png` where present.

The source folder remains under `concept_art/.gdignore`; the game uses the runtime copies.
