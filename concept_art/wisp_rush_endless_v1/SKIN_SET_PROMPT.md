# Wisp Rush — Endless arena skin set (30 skins): generation prompt

> **Status:** ✅ 30 source images generated; runtime integration pending · **Written:** 2026-09-15 · One prompt for an image-generation agent.
> Attach `floor_template_layout.png` to every image. Skins 01–03 are already wired in the game
> (`res://data/endless/skins/`); 04–30 need data entries and rarity prices when they land.
> Floor rules: [ADR-0014](../../docs/decisions/0014-endless-arenas-share-one-floor-template.md).

```text
You are generating arena skins for Wisp Rush, a portrait mobile game where a small glowing spirit
(the Wisp) dashes in straight lines across an arena floor, slicing shadow enemies. In Endless mode
players unlock cosmetic arena backgrounds. Create 30 backgrounds: 10 Simple, 10 Rare, 5 Legendary
and 5 Mythic. Rarity changes how rich and impressive the scenery is — never the floor.

WHAT EVERY IMAGE IS
- A 941 x 1672 px portrait background (9:16), seen from a high top-down camera with only a slight
  three-quarter tilt.
- An empty arena: a flat walkable floor in the middle, a clear rim around it, themed scenery outside.
- Cosmetic only: all 30 skins share exactly the same playable floor, so they all play the same.

THE PLAYABLE FLOOR — IDENTICAL IN ALL 30 IMAGES
- Use the attached floor_template_layout.png as an exact layout guide for every image:
  mid-grey = floor, light-grey band = rim, dark = scenery.
- Floor: an upright rectangle at x 136-795, y 426-1287 px with all four corners cut at 45 degrees
  by 80 px (about 659 x 861 px). Straight edges and sharp cut corners — never oval, jagged, shrunk
  or moved.
- Floor paint covers that whole shape and continues 12 px past it.
- Rim: a clear, continuous border (curb, low wall, carved band, water line, roots…) 12-40 px outside
  the floor edge, following it exactly, including the four diagonal cuts.
- Inside the floor: one flat, continuous, dark to mid-dark surface with only subtle low-contrast
  texture. No props, holes, stairs, water, pillars, bright runes, symbols, glowing lines, reflections
  or light spots. Evenly lit, no glare in the centre.
- Scenery only outside the rim. Everything above y 426 sits under the game's HUD (decoration only).
  Tall phones crop the sides, so keep anything important between x 94 and x 847.

STYLE AND COLOUR (ALL SKINS)
- Original hand-painted 2D game art, crisp pixel-inspired silhouettes, selective hard edges, premium
  indie mobile finish; a dark-fantasy world of ancient arenas suspended in the void.
- Palette anchors: charcoal #111521, slate teal #263D42, soul white #EAFDFF, moss green #5E7D4C.
  Cyan #62E8F2, amber #F3A847 and magenta #B14CD9 are gameplay signal colours (the Wisp, danger
  warnings, enemies): use them only as tiny accents outside the floor, never as large areas. Keep warm
  themes desaturated.
- The floor is always darker and calmer than the scenery, so small bright sprites stay the brightest
  things on screen.
- Never include characters, living creatures, enemies, pickups, UI, frames, text, logos, watermarks
  or baked effects. Statues, carvings, fossils and remains are fine.
- Every skin must look clearly different from the others at thumbnail size (its own dominant
  material, colour and silhouette) and from the game's five existing Rifts: an overgrown obsidian
  garden, a purple crystal rift, a lava hollow, an ice cathedral and a gothic throne court.

WHAT RARITY CHANGES (OUTSIDE THE FLOOR ONLY)
- Simple: one main material, 2-4 kinds of props, calm and clean; flat soft light; plain rim.
- Rare: a clear theme with one landmark and richer textures; one soft light source outside the
  floor and light mist; a decorated rim.
- Legendary: a huge storytelling landmark with strong foreground, midground and far-background depth;
  dramatic but dim, atmospheric light; an ornate carved rim.
- Mythic: cinematic and epic in scale, recognisable at thumbnail size, with a rare sky or cosmic
  phenomenon; rich layered lighting that still leaves the floor dark; the most ornate rim with faint
  rune inlay. The floor may carry a barely visible inlay pattern but stays flat and low-contrast.

THE 30 SKINS (floor · rim · outside). 01-03 are already in the game, so they keep their numbers.

SIMPLE
01 Astral Observatory (default skin) — dark blue-grey slate slabs with a faint engraved star chart ·
   worn silver-grey stone with dim moonstone studs · broken stone astrolabe rings, cold telescopes,
   a deep indigo starfield.
04 Monastery Yard — worn grey flagstones · low weathered stone curb · bare trees, unlit stone
   lanterns, fallen muted-brown leaves, misty cloister walls.
05 Dusk Sandstone — dark desaturated sandstone tiles · carved sandstone step · shadowed dunes,
   a half-buried pillar, a cool dusk sky.
06 Slate Cliffs — dark slate on a cliff top · rough rock edge · a sheer drop, sea mist, distant grey
   mountains.
07 Cold Forge — dark riveted iron plates · heavy steel border · silent anvils, cold chimneys,
   hanging chains; no fire or glow.
08 Bamboo Deck — dark wooden boards · bamboo railing · a tall moonlit bamboo forest.
09 Basalt Shore — flat tops of dark hexagonal basalt columns · a border of taller columns · a black
   sea, pale foam, rocky sea stacks.
10 Windswept Hill — dark stone slabs · tufted grass edge · rolling dark hills, low clouds, a lone
   bent tree.
11 Rain Rooftops — dark matte roof tiles · stone parapet · chimneys, puddles and the rooftops of a
   sleeping town at night.
12 Rootwood Clearing — dark packed earth and flat stones · woven roots · towering dark trees, pale
   moonbeams in the distance.

RARE
02 Drowned Sanctum — wet-looking dark flagstones barely lighter than the water · low carved curb with
   a thin line of pale foam · black still water, submerged columns, drowned statues, a dim deep-green
   glow far below.
03 Moonpetal Shrine — smooth dark grey stone with no petals on it · pale carved border with unlit
   stone lanterns · gnarled trees with ivory-white blossoms (never pink or magenta), a mossy gate,
   a drop into cloud.
13 Clockwork Bastion — dark steel plates · desaturated bronze-grey gear-tooth border · giant still
   cogs and pistons, cold steel-blue light.
14 Sky Harbor — dark timber deck · iron railing · moored airship silhouettes, rope bridges, a
   moonlit sea of clouds.
15 Quartz Grotto — dark cave stone · pale white quartz crystals · a glittering cavern of white and
   pale-green crystal, never purple.
16 Fungal Hollow — dark earth and flat stones · giant pale mushrooms with a dim green glow · spore
   mist, a forest of towering fungi.
17 Library of Echoes — dark low-contrast wood parquet · low carved bookshelf wall · towering
   shelves, floating open books, tall moonlit windows.
18 Old Colosseum — dark packed earth · stone arena barrier · crumbling tiered seats, broken columns,
   an overcast sky.
19 Storm Lighthouse — dark rock platform · rough stone wall · crashing waves, a lighthouse with a
   cold white lamp, storm clouds.
20 Lantern Market — dark cobblestones · closed market stalls with muted cloth awnings · unlit paper
   lanterns strung over narrow moonlit streets.

LEGENDARY
21 Titan's Palm — the floor is the flat stone palm of a colossal ancient statue's open hand, carved to
   the exact floor shape · carved palm edge · giant stone fingers curling up beyond the rim, the
   statue's serene face far below in mist.
22 Clocktower Crown — dark stone roof platform atop an impossibly tall clocktower · carved border with
   small silver gears · a colossal bell, huge frozen clock gears, moonlit clouds far below.
23 Storm Anvil — the dark iron face of a gigantic anvil · hammered, battle-scarred edge · a colossal
   resting hammer, heavy chains, distant cold-white lightning in towering storm clouds.
24 World Tree Crown — dark polished living-wood platform · braided branches · a canopy of dimly
   glowing green leaves, floating islands, a vast night sky.
25 Galleon Wreck — dark weathered deck planks of a giant galleon wrecked on a cliff · broken
   gunwale · snapped masts, torn sails, old cannons, a stormy sea.

MYTHIC
26 Eclipse Sanctum — black marble with a barely visible silver inlay · ornate rim with faint silver
   runes · a total eclipse with a pale corona, a ring of colossal hooded statues facing outward,
   star dust.
27 Starforged Citadel — dark meteoric iron with the faintest star-metal veins · rim of carved
   silver-white runes · blue-white and silver galaxies (no magenta), shattered moons, floating
   citadel spires.
28 Abyssal Gate — dark ancient stone bridge platform · rim of carved guardian heads · a titanic sealed
   gate wrapped in chains, an endless abyss, deep blue mist; no magenta, no gothic cathedral.
29 Aurora Throne — dark stone summit plaza · a rim of ancient carved thrones set back from the edge ·
   a sky-wide green aurora (not bright cyan), jagged snowy peaks far away; no snow or ice on the floor.
30 Dragon Skull Throne — flat dark stone platform inside the open jaws of a colossal fossilised dragon
   skull · worn bone-and-stone rim · skull teeth and horns towering beyond the rim, a dim cold-blue
   light (not cyan) in the eye sockets, ash-grey dunes.

HOW TO WORK
1. Generate one skin per image, in number order, starting with 01, 02 and 03.
2. For each one, attach the layout image and apply every rule above plus that skin's tier and
   description.
3. Output exactly 941 x 1672 px. If the tool only offers another 9:16 size, scale the result to
   941 x 1672; reject anything that isn't 9:16.
4. Save it as concept_art/wisp_rush_endless_v1/assets/NN_endless_<skin_id>.png, where skin_id is the
   name in lowercase with underscores (01_endless_astral_observatory.png, 21_endless_titans_palm.png).
5. Check each result by laying floor_template_guide.png over it at 50% opacity. The painted rim must
   sit on the rim band all the way round, and nothing may sit inside the floor. If either fails,
   redraw: keep the style and scenery, but match the floor and rim to the layout exactly.
6. When all are done, write concept_art/wisp_rush_endless_v1/assets/skins_manifest.json listing each
   skin's number, skin_id, display name, tier, filename and a one-line description.
```
