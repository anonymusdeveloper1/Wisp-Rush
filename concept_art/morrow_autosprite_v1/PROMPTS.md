# Morrow — AutoSprite v1: prompts

Status: **Codex variants requested (2026-09-27).** Morrow is still the bone rig in the game. The recipe
is [docs/guides/character_creation.md](../../docs/guides/character_creation.md); Patchvile is the
worked example, and Rook (`concept_art/rook_autosprite_v1/`) the last character done this way.

**Owner direction, 2026-09-27:** "lets just redesign the last character left morrow give me the images
from him and prompt for AI to generate variants for each pose". Every new or redesigned character
stands centred on Home's platform (GDD §14 #57).

## 1. References to attach

- `concept_art/wisp_rush_playable_characters_v1/references/morrow_concept.jpg` — the owner's
  original character sheet (front, side and back views, and a flight).
- `assets/art/characters/playable/morrow/preview.png` — his current front portrait.

## 2. Codex prompt — three variants of each pose (2026-09-27)

Given in chat with both references; the owner asked for it to be saved here.

```text
Morrow is a playable character in Wisp Rush, a 2D pixel-art mobile game. I attach two references: his character sheet (front, side and back views, and a flight) and his front portrait. Keep his design exactly: a hooded figure with no visible body, only a deep purple hooded cloak with pale gold angular trim along the hood and the cloak; a pale bone-white mask inside the hood, long and pointed toward the bottom, with a crack running down from the top and two glowing cyan eyes; a cyan diamond gem in a gold clasp at his collar; a gold diamond emblem on the front of the cloak; the bottom of the cloak ending in two long translucent violet tails that curl at their ends, with cyan diamond runes on them; two floating hands made of dark stone with glowing cyan cracks, not attached to the cloak, one on each side of him; and dark diamond-shaped rune stones with glowing cyan runes floating around him. Same proportions, colours and details as the references. Do not mirror him between images.

TASK: this is a review round, not the final frames. For each of the five states below, draw 3 different variants (a, b, c), so I can pick the best pose for each: 15 images in total.

1. storefront: front view, facing the viewer, a calm idle pose, whole figure visible, centred left to right on the canvas.
2. wall_bottom: resting on the floor at the bottom of the image (do not draw the floor): low and ready to spring into an attack.
3. wall_right: clinging to a wall on the right side of the image (do not draw the wall): his stone hands gripping it, his body upright.
4. wall_top: hanging from a ceiling at the top of the image (do not draw the ceiling): his stone hands gripping it, upside down.
5. dash_attack: side view, flying fast toward the left, attacking with his stone hands forward, the cloak and its tails streaming behind (use the flight in the character sheet as a starting point). No wall, no floor. Leave room in front of him for the attack.

Rules for every image:
- Canvas 1024 x 1024 px with a transparent background (real transparency, not a checkerboard or white).
- Pixel art: the art is 256 x 256 pixels scaled up 4x with nearest neighbour, so every art pixel is an exact 4 x 4 block on one grid. No anti-aliasing, no blur, no gradients, no glow haze, nothing painterly or 3D. His glowing parts (eyes, gem, runes, the cracks in his hands) are bright solid pixels with no haze around them.
- No outline: his own colours meet the transparent background.
- At most 256 colours.
- Size: in every storefront variant his whole figure is exactly 776 px tall, from his highest point to his lowest point, everything included (hood, floating hands, rune stones, cloak tails). All 15 images use exactly the same scale (same mask size, same pixel size), so a low or hanging pose is shorter and the flight is as long as his body.
- Leave at least 60 px of empty space on every side. His hands, rune stones and cloak tails must fit inside that too, so place them as each variant needs; do not make him smaller.
- No shadow, no floor, no background, no text, no border, and no separate effects around him (no glow, particles or speed lines).

Deliver:
- 15 separate PNG files named morrow_<state>_<a|b|c>.png, for example morrow_storefront_a.png and morrow_wall_top_c.png.
- One review sheet, morrow_variants_review.png: all 15 side by side, one row per state, each labelled with its file name.
```

**Next:** the owner picks a variant for each pose; they are checked against the character rules
(canvas, transparency, pixel grid, colours, outline, 776 px storefront, one scale, margins, centred
storefront), then the owner describes his animations for the AutoSprite prompts.
