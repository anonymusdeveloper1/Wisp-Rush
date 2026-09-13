# Wisp Rush — Rifts wave 2: per-arena bosses and enemies

Same rules as `GENERATION_PROMPTS.md`. Prepend the **Shared art-direction block** from that file to
every prompt. Three sheets. Existing coverage: Reaper (Obsidian Garden + Reaper's Court variant),
The Hollow Choir (Frozen Choir), and six enemies. These fill the gaps.

## 08 — Boss: The Fracture (Shattered Rift) → `08_boss_the_fracture.png`

```text
Create a transparent-background 4 x 3 sprite sheet, output exactly 1448 x 1086 pixels, twelve equal
362 x 362 cells, consistent scale and anchors, top-down view. One original boss: THE FRACTURE, a
levitating cluster of broken obsidian slabs orbiting a single tear of rift-magenta light. No face,
no limbs, no humanoid form - a shattered orbiting mass. Read left to right, top to bottom:
  1 dormant, slabs closed into a sphere, tear dark
  2 awakening, slabs parting, tear dim magenta
  3 idle, slabs orbiting slowly, tear bright
  4 core tear exposed and vulnerable, wide open
  5 winding up, slabs pulled inward, amber warning glow
  6 slab volley, shards flung outward
  7 opening a portal rift, cyan ring forming
  8 blinking out, slabs dissolving into streaks
  9 reforming after a blink
  10 staggered, slabs hanging loose and dim
  11 breaking apart, tear collapsing
  12 final dissolve into magenta motes
No background, no grid lines, no labels, no text, no drop shadows.
```

## 09 — Boss: The Cinder Maw (Ember Hollow) → `09_boss_cinder_maw.png`

```text
Create a transparent-background 4 x 3 sprite sheet, output exactly 1448 x 1086 pixels, twelve equal
362 x 362 cells, consistent scale and anchors, top-down view. One original boss: THE CINDER MAW, a
wide sunken ring of blackened basalt jaws set into the floor, with a molten amber throat and three
ember vents around its rim. Seen from above; monumental, static, never humanoid, never a creature
with eyes. Read left to right, top to bottom:
  1 dormant, jaws shut, throat dark
  2 awakening, jaws parting, faint amber
  3 idle, jaws open, throat glowing
  4 one vent extinguished
  5 two vents extinguished
  6 all vents extinguished, throat dimmed
  7 inhaling, amber warning glow pulling inward
  8 erupting, bright amber column from the throat
  9 magma spray cast pose
  10 staggered, jaws slack, cracks spreading
  11 collapsing inward
  12 final dissolve into ash and embers
No background, no grid lines, no labels, no text, no drop shadows.
```

## 10 — Per-arena enemies → `10_arena_enemies_sheet.png`

```text
Create a transparent-background 4 x 3 sprite sheet, output exactly 1448 x 1086 pixels, twelve equal
362 x 362 cells, one creature pose centred per cell, consistent scale and anchors, top-down view.
Four original non-human creatures, three poses each (idle, acting, dissolving), read left to right,
top to bottom. Compact charcoal silhouettes with a single coloured core, matching the existing
enemy hierarchy - silhouette over texture.

Row 1 - ECHO (Shattered Rift): a translucent duplicate wisp with a hollow outline and a magenta
core, trailing a faint after-image:
  1 idle, 2 splitting into a mirrored after-image, 3 dissolving.

Row 2 - SLAG HULK (Ember Hollow): a heavy hunched mass of cooled magma crusted black, glowing amber
in its seams, largest of the four:
  4 idle, 5 cracking open with amber seams flaring, 6 dissolving.

Row 3 - FROST WISP (Frozen Choir): a slender shard of pale blue ice with a white-cold core and thin
trailing frost:
  7 idle, 8 shattering into ice needles, 9 dissolving.

Row 4 - COURT SHADE (Reaper's Court): a small hooded silhouette in deepest charcoal with a thin
magenta crescent where a face would be, clearly a lesser echo of the Reaper:
  10 idle, 11 lunging forward with crescent flaring, 12 dissolving.

No background, no grid lines, no labels, no text, no drop shadows.
```

## Delivery — DO THIS AT THE END

```text
IMPORTANT DELIVERY INSTRUCTIONS — follow exactly:

1. Save the three generated images with these EXACT filenames, no other names:
     08_boss_the_fracture.png
     09_boss_cinder_maw.png
     10_arena_enemies_sheet.png
2. Put all three files in ONE folder named: wisp_rush_rifts_v2
3. Compress that folder into a SINGLE zip archive on the macOS Desktop, at exactly this path:
     ~/Desktop/wisp_rush_rifts_v2.zip
4. Confirm to me that the zip exists at that path and list what is inside it.

Do not send the images individually. Deliver the one zip file on the Desktop.
```
