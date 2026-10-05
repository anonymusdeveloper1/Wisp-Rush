# Wisp Rush — menu backgrounds

Created and implemented 2026-10-05 for the owner's Shop, Daily Run, Trials and death/results
background request. Artwork uses the built-in Codex image generator and the existing loading-art
world as its reference. Each screen has its own scenery, with a dark centre behind the interface.

| Final | Scene | Colors | Runtime screen |
|---|---|---:|---|
| [shop_background.png](shop_background.png) | Warm lantern-lit floating stone gallery with side stalls and stitched cloth | 205 | Shop, all three tabs |
| [daily_background.png](daily_background.png) | Moonlit gate, floating ruins, stone steps and cyan side wisps | 188 | Daily Run |
| [trials_background.png](trials_background.png) | Ascending terraces and pillars against muted violet dusk | 208 | Trials |
| [results_background.png](results_background.png) | Quiet broken shrine with a side lantern and a remaining cyan wisp | 171 | End-of-run Results |

All finals are opaque RGB, **1080 × 2400**, reduced to **270 × 600** and enlarged **4× nearest**.
The palette has at most 256 colors, with source accents and the seven GDD palette anchors retained.
There is no embedded interface, text or character artwork. [preview_all.png](preview_all.png)
labels the four images for review only.

[preview_in_game.png](preview_in_game.png) shows the four production interfaces at 390 × 844.
The existing QA capture tool also rendered all three Shop tabs, Daily Run, Trials and Results at
five portrait phone sizes (30 captures), without rendering/script errors; the full review sheets
are in ignored `logs/qa/`.

## Runtime and rebuilding

The builder installs byte-identical copies in `assets/art/environment/menu_screens/`. Each matching
`scenes/screens/<screen>_screen.tscn` references its image in the existing full-screen Background
TextureRect with nearest filtering and aspect-preserving cover. Screen layouts and behavior are
supplied by the existing scenes and scripts.

```text
python concept_art/menu_backgrounds_v1/build_backgrounds.py
```

This crops, reduces and quantizes the saved generations, enlarges them nearest, checks dimensions
and the pixel grid, builds the review sheet and copies the results into the runtime folder.
`metadata.json` contains measured sizes, color counts, source/runtime hashes and crop boxes.
`generation.json` records the original outputs and the two references. Raw generations are retained
unchanged in `raw/`.

## Exact prompts

- [Shop](prompts/shop_background.md)
- [Daily Run](prompts/daily_background.md)
- [Trials](prompts/trials_background.md)
- [Results](prompts/results_background.md)

The source pack is under `concept_art/.gdignore`; the game imports the runtime copies.
