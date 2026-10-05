# Wisp Rush — loading and shop backgrounds

Created 2026-10-04 in response to the owner's request for a loading screen featuring an existing
character and a matching shop background.

## Images

| File | Artwork |
|---|---|
| [loading_patchvile.png](loading_patchvile.png) | Patchvile crouches on a floating broken causeway, holding his approved curved dagger. Ivory scarf, amber eye, warm lantern and cyan wisps. Quiet upper sky and lower shadows leave space for the loading interface. |
| [shop_gallery.png](shop_gallery.png) | Empty suspended stone gallery with side lanterns, stitched ivory banners, display niches and two cyan wisps. A dark central view and a low stone dais sit behind the existing card carousel. |

Both final images are opaque RGB PNGs, **1080 × 2400**, made from **270 × 600** art enlarged
**4× nearest**. They share a palette of at most 256 colors. Actual color counts, source dimensions,
center crop measurements, checks and hashes are in [metadata.json](metadata.json).

## References and generation

Built-in Codex image generation, followed by deterministic pixel-grid processing.

- Patchvile identity: `concept_art/patchvile_autosprite_v1/references/patchvile.png`.
- His dagger: `concept_art/patchvile_autosprite_v1/references/dagger.png`.
- World and dark stone stage: `assets/art/environment/home_background.png`.
- The shop generation also uses the new loading image as its palette/world reference.

Exact prompts:
[loading](prompts/loading_patchvile.md) ·
[loading composition refinement](prompts/loading_patchvile_refinement.md) ·
[knife grip correction](prompts/loading_patchvile_grip.md) ·
[shop](prompts/shop_gallery.md).

The loading refinement lowers Patchvile and his ledge to clear the existing logo in a 9:16 preview.
The final loading image is built from `raw/loading_patchvile_source_v3.png`, which corrects the
gloved hand to grasp the knife's handle. The first generation and layout refinement remain in
`raw/loading_patchvile_source.png` and `raw/loading_patchvile_source_v2.png`. The palette is still
derived from the layout refinement and original shop source, so the shop output stays identical.

The unchanged generated images are preserved under `raw/`. Run
`python concept_art/loading_and_shop_v1/build_backgrounds.py` from the project root to rebuild the
finals from these originals. This only processes the images; it does not draw new scenery.

## Current state

Source artwork only, under `concept_art/.gdignore`. No existing background or scene is replaced.

The current loading scene already supplies the logo, heading, status and progress bar
(`scenes/screens/loading_screen.tscn`); the shop supplies its header, tabs, carousel and controls
(`scenes/screens/shop_screen.tscn`). Neither final background has embedded text, cards or buttons.

Both were visually checked with those existing interfaces over the new images at 1080 × 1920,
using temporary fixtures. The loading logo clears the refined hood; the shop card occupies the
quiet center between the side lanterns. Review captures are `logs/loading_art_review.png` and
`logs/shop_art_review.png` (ignored working files, not runtime integration).

