# Wisp Rush — Endless arena skins v1: generation prompts

> **Status:** ✅ generated (30 skins, `assets/skins_manifest.json`) and wired in-game through spec 05, 2026-09-15 · **Written:** 2026-09-14 ·
> **Rules:** [ADR-0014](../../docs/decisions/0014-endless-arenas-share-one-floor-template.md) ·
> **Integration:** [spec 05](../../docs/specs/story_and_endless/05_endless_arena_art.md)
>
> Three purchasable backgrounds for **Endless** mode. They are cosmetic, so all three must share
> exactly the same playable floor. That is why the layout image is attached to every generation.

## Why the layout image is mandatory
The Rifts v1 prompts described the floor only in words ("14.5% to 84.5% horizontally…"). The
generator ignored them: the floors came out oval, jagged and different sizes, and each Rift needed
its own wall (ADR-0011). That is fine for Rifts and wrong for skins people buy. So **attach
`floor_template_layout.png` every time**, and check every result against the template.

## Files
| File | Use |
|---|---|
| `floor_template_layout.png` | **Attach to every generation.** Grey box: mid-grey = floor, light-grey band = rim, dark = scenery |
| `floor_template_guide.png` | Annotated version for people: zones, pixel sizes, HUD band, phone crop |
| `floor_template_mask.png` | White = playable floor; for masked or inpainting tools and the checker |
| `floor_template.json` | Source of truth for the shape (frozen by ADR-0014) |
| `assets/` | Save the three results here under the exact filenames below |

Regenerate the PNGs with `python3 tools/art/make_endless_floor_template.py` — never edit them by hand.

## The playable area, in numbers
- **Canvas:** 941 × 1672 px, portrait (9:16).
- **Playable floor (the template):** an upright rectangle at x 136–795, y 426–1287 px, with all four
  corners cut at 45° by 80 px — about 659 × 861 px. Straight edges, sharp cut corners, no curves.
- **Floor paint** covers the whole template and continues 12 px past its edge.
- **Rim** — the visible edge of the floor (curb, low wall, rune band, water line) — runs 12–40 px
  outside the template edge and follows it exactly, including the four diagonal cuts. Never more than
  48 px out.
- **Scenery** goes beyond the rim. Everything above y 426 sits under the game's HUD: decoration only.
- **Phone crop:** tall phones cut the sides, so keep anything important between x 94 and x 847.

## How to run one generation
1. Attach `floor_template_layout.png`.
2. Paste the shared block, then the hard requirements, then **one** arena prompt.
3. Ask for exactly 941 × 1672 px. If the tool only offers other 9:16 sizes, scale the result to
   941 × 1672 afterwards. Reject any result that isn't 9:16.
4. Save it to `assets/` under the arena's filename.
5. Lay `floor_template_guide.png` over the result at 50 % opacity. The painted rim must sit on the rim
   band all the way round. If it doesn't, run the fix-up prompt with the result and the layout image
   both attached. Integration adds an automatic check (spec 05).

## Shared art-direction block (prepend to every prompt)

```text
Original hand-painted 2D game art with crisp pixel-inspired silhouettes and selective hard edges.
An empty ancient arena suspended over the void; premium indie mobile-game finish; portrait
readability. Palette anchors: charcoal #111521, slate teal #263D42, soul white #EAFDFF,
moss green #5E7D4C. Cyan #62E8F2, warning amber #F3A847 and rift magenta #B14CD9 are gameplay
information colours: use them only as tiny, sparse accents outside the floor, never as large areas.
High top-down camera with only a slight three-quarter tilt. The floor stays dark and low-contrast so
small bright sprites remain the brightest things on screen. No copied characters, logos or layouts.
```

## Hard requirements (paste after the shared block)

```text
Use the attached layout image as an exact composition guide. Its mid-grey shape is the walkable
floor, its light-grey band is the rim of the floor, and the dark area is scenery.
- Output exactly 941 x 1672 pixels, portrait.
- The walkable floor fills the entire mid-grey shape: an upright rectangle whose four corners are cut
  at 45 degrees. Keep that exact outline, size and position. Do not round it into an oval, do not make
  its edge jagged or broken, do not shrink or move it.
- Paint a clear, continuous rim exactly on the light-grey band so the edge of the floor is obvious at
  a glance, including along the four diagonal corner cuts.
- Inside the floor: one flat, continuous, walkable surface with only subtle, low-contrast texture.
  No props, pillars, holes, stairs, water, cracks that look like gaps, bright runes, symbols, text or
  light spots inside it.
- The floor is dark to mid-dark and evenly lit; no glare or spotlight in the centre.
- All tall scenery, props, light sources and fine detail stay outside the rim.
- The top of the image above the floor holds decorative scenery only; it sits under the game's HUD.
- No characters, creatures, enemies, pickups, UI, frames, borders, words, logos, watermarks or
  baked effects.
```

## The three arenas

| # | Arena | Identity | In game |
|---|---|---|---|
| 01 | Astral Observatory | Indigo night, silver stone, stars | Free default skin |
| 02 | Drowned Sanctum | Black water, wet stone, drowned statues | Bought with Rift Points |
| 03 | Moonpetal Shrine | Moonlit terrace, ivory blossoms, mist | Bought with Rift Points |

### 01 — Astral Observatory → `assets/01_endless_astral_observatory.png`

```text
Create an empty top-down arena: the open-air summit of an ancient star observatory floating in a calm
night void. Floor: dark blue-grey slate slabs with a very faint engraved star-chart pattern at very
low contrast. Rim: a band of worn silver-grey stone set with small, dim moonstone studs, following the
floor's cut corners. Outside the rim: broken stone astrolabe rings, cold stone telescopes, floating
stepping stones, and a deep indigo starfield with a faint distant nebula. Quiet, vast, cold and
elegant.
```

### 02 — Drowned Sanctum → `assets/02_endless_drowned_sanctum.png`

```text
Create an empty top-down arena: a sunken temple courtyard rising just above black, still water.
Floor: wet dark flagstones with faint soft reflections, only slightly lighter than the water. Rim: a
low carved stone curb where the water meets the floor, with a thin line of pale foam, following the
floor's cut corners. Outside the rim: submerged columns, drowned statues, drifting mist and dark kelp,
with a very dim deep-green glow far under the water. Silent, damp and mysterious. Keep every glow
muted and greenish, never bright cyan.
```

### 03 — Moonpetal Shrine → `assets/03_endless_moonpetal_shrine.png`

```text
Create an empty top-down arena: a moonlit mountain shrine terrace among ancient blossom trees. Floor:
smooth dark grey stone tiles, clean and swept, with no petals on it. Rim: a raised border of pale
carved stone with small unlit stone lanterns, following the floor's cut corners. Outside the rim:
gnarled dark trees with pale ivory-white blossoms (only the faintest warm blush, never pink or
magenta), a mossy stone gate at the top, drifting mist, and a steep drop into cloud at the bottom.
Serene, cool and beautiful.
```

## Fix-up prompt (attach the result and the layout image)

```text
Keep this image's style, palette, lighting and scenery. Using the attached layout image, redraw the
floor so the walkable floor matches the mid-grey shape exactly and the rim sits on the light-grey
band all the way round, including the four 45-degree corner cuts. Remove anything inside the floor
that is not flat floor. Output exactly 941 x 1672 pixels.
```

## Acceptance checklist (each image)
- [ ] 941 × 1672, portrait, RGB with no transparency.
- [ ] With the guide laid over at 50 %, the rim sits on the band all the way round: straight edges,
      four diagonal cuts, nothing rounded.
- [ ] Nothing inside the floor but flat, low-contrast surface.
- [ ] The floor is darker than the rim and the scenery highlights; no bright centre.
- [ ] No large amber, magenta or bright cyan areas; no text, UI, characters, creatures or effects.
- [ ] Clearly different from the other two arenas and from the five Rifts.
