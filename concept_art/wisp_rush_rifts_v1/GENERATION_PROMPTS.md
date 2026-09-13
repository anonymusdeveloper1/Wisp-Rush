# Wisp Rush — Rifts v1 generation prompts (Milestone 8)

Paste the shared block plus one sheet prompt per generation. Continuation of
`concept_art/wisp_rush_redesign_v1/GENERATION_PROMPTS.md` — same art direction, same palette.

## Shared art-direction block (prepend to EVERY prompt)

```text
Original hand-painted 2D game art with crisp pixel-inspired silhouettes and selective hard edges.
Ancient overgrown obsidian sanctuary suspended over the void; premium indie mobile-game finish;
portrait readability. Palette: charcoal #111521, slate teal #263D42, cyan #62E8F2,
soul white #EAFDFF, warning amber #F3A847, rift magenta #B14CD9, moss green #5E7D4C.
Top-down camera with only a slight three-quarter tilt. Keep the image low-contrast in the centre so
small bright sprites stay the brightest objects on screen. Cyan, amber and magenta are information
colours, not decoration. No copied characters, logos or layouts.
```

## Hard requirements for all four backgrounds

```text
Portrait 9:16, output exactly 941 x 1672 pixels. The usable stone floor must fill the region from
14.5% to 84.5% horizontally and 25.5% to 77% vertically — that rectangle is the playable area and
must be flat, continuous and walkable, with no props, holes or high-contrast detail inside it.
At least 75% of the arena is uninterrupted navigable floor. Tall scenery, strong shadows and
high-frequency decoration only in the outer 12%. No characters, no creatures, no pickups, no UI,
no frames, no words, no logos, no watermarks, no baked combat effects, no central collision props.
```

## 01 — Shattered Rift → `01_rift_shattered.png`

```text
Create an empty top-down arena floor of fractured obsidian slabs hanging over a torn magenta rift.
The central floor is a continuous cracked slate platform; the outer edge breaks into drifting
angular shards with rift-magenta light bleeding up between them. Sparse cyan rune inlays. Cold,
unstable, weightless.
```

## 02 — Ember Hollow → `02_rift_ember_hollow.png`

```text
Create an empty top-down arena floor inside a volcanic obsidian hollow. The central floor is dark
cooled basalt with fine amber cracks glowing faintly through it. The perimeter is molten channels,
ash drifts and broken furnace ruins. Warm amber rim light against charcoal. The centre stays dark
and low contrast.
```

## 03 — Frozen Choir → `03_rift_frozen_choir.png`

```text
Create an empty top-down arena floor inside a frozen cathedral of ice and black obsidian. The
central floor is pale polished ice over dark stone, with faint cyan refraction. The perimeter is
broken ice pillars, frozen organ pipes and hanging frost. Still, pale, silent, slippery.
```

## 04 — Reaper's Court → `04_rift_reapers_court.png`

```text
Create an empty top-down arena floor of the Reaper's throne court: the darkest and most oppressive
arena. The central floor is near-black polished stone with a faint magenta sigil worn into it at
very low contrast. The perimeter is towering ribbed archways, hanging chains and an empty throne
silhouette, all in deep charcoal with narrow magenta rim light. Ominous and heavy, but the centre
stays readable and clear.
```

## 05 — Rift props sheet → `05_rift_props_sheet.png`

```text
Create a transparent-background 4 x 3 sprite sheet, output exactly 1448 x 1086 pixels, twelve equal
362 x 362 cells, one prop centred in each cell with consistent scale and anchors. Top-down view to
match the arena. Reading left to right, top to bottom:
1 void portal entrance, dormant, cyan ring, dark centre
2 void portal entrance, active, bright cyan swirl
3 void portal exit, dormant, magenta ring, dark centre
4 void portal exit, active, bright magenta swirl
5 obsidian pillar, intact, chipped slate faces with a cyan rune inlay
6 obsidian pillar, cracked after impact, same silhouette
7 floor-edge warning marker, safe state, dim amber chevron set into stone
8 floor-edge warning marker, warning state, bright amber chevron
9 crumbling floor edge piece, breaking away
10 small obsidian rubble cluster
11 cyan rune tile, dormant
12 cyan rune tile, lit
No background, no grid lines, no labels, no text, no drop shadows on the sheet itself.
```

## 06 — New enemies sheet → `06_new_enemies_sheet.png`

Three new enemy families, each designed to test a different dash-line skill. Sits between Shard
Wraith and Bone Mote in the style guide's hierarchy: compact charcoal masses, one magenta core,
silhouette over texture.

```text
Create a transparent-background 4 x 3 sprite sheet, output exactly 1448 x 1086 pixels, twelve equal
362 x 362 cells, one creature pose centred per cell, consistent scale and anchors, top-down view.
Three original non-human creatures, four poses each, read left to right, top to bottom.

Row 1 - CINDER SHADE, a small round ember-shadow that splits in two when cut. Compact charcoal mass
wrapped in low amber embers, single magenta core:
  1 idle A, 2 idle B, 3 splitting apart into two halves, 4 dissolving.

Row 2 - WARDEN, a squat armoured guardian with a heavy slate shield plate on ONE face only, so its
vulnerable side is instantly readable. Charcoal body, cyan rune on the shield, magenta core exposed
at the back:
  5 idle facing down with shield forward, 6 turning, 7 shield impact sparks, 8 dissolving.

Row 3 - RIFT SPAWN, a thin tethered twin: two small angular crystal bodies joined by a taut magenta
energy tether. Shard-like silhouette:
  9 pair at rest with slack tether, 10 pair pulled apart with taut tether, 11 tether snapping,
  12 dissolving.

Silhouette over texture. No background, no grid lines, no labels, no text, no drop shadows.
```

## 07 — Second boss: The Hollow Choir → `07_boss_hollow_choir_sheet.png`

Deliberate contrast to the Reaper (tall, dark, antler crown, magenta scythe). The Choir is wide,
pale and static — a frozen multi-core structure you dismantle rather than a hunter that chases you.

```text
Create a transparent-background 4 x 3 sprite sheet, output exactly 1448 x 1086 pixels, twelve equal
362 x 362 cells, consistent scale and anchors, top-down view. One original boss creature: THE HOLLOW
CHOIR, a wide frozen cathedral-organ entity of pale ice and black obsidian, with three glowing cyan
cores set in its face and a hollow singing mouth. Cold, pale, still and monumental — never humanoid,
never a skeleton. Read left to right, top to bottom:
  1 dormant, cores dark
  2 awakening, cores dim cyan
  3 idle, all three cores lit
  4 one core shattered
  5 two cores shattered
  6 all cores shattered, body cracked
  7 winding up a sound attack, mouth open, amber warning glow
  8 releasing a sound wave, mouth wide, bright cyan
  9 frost bloom cast pose
  10 staggered, leaning, cores flickering
  11 shattering apart
  12 final dissolve into pale motes
No background, no grid lines, no labels, no text, no drop shadows.
```

## Delivery — DO THIS AT THE END

```text
IMPORTANT DELIVERY INSTRUCTIONS — follow exactly:

1. Save the seven generated images with these EXACT filenames, no other names:
     01_rift_shattered.png
     02_rift_ember_hollow.png
     03_rift_frozen_choir.png
     04_rift_reapers_court.png
     05_rift_props_sheet.png
     06_new_enemies_sheet.png
     07_boss_hollow_choir_sheet.png
2. Put all seven files in ONE folder named: wisp_rush_rifts_v1
3. Compress that folder into a SINGLE zip archive on the macOS Desktop, at exactly this path:
     ~/Desktop/wisp_rush_rifts_v1.zip
4. Confirm to me that the zip exists at that path and list what is inside it.

Do not send the images individually. Deliver the one zip file on the Desktop.
```
