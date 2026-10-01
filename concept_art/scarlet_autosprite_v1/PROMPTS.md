# Scarlet — AutoSprite v1: first frames and prompts

Status: **in the game (2026-09-26).** The owner generated the four sheets from these first frames and
prompts; they are in `raw/`, cut and cleaned by `slice_sheet.py` and packed by the extractor. Id
`scarlet`, display name SCARLET. She replaced Ilyra, who was removed completely (GDD §14 #52). The
recipe is [docs/guides/character_creation.md](../../docs/guides/character_creation.md); Patchvile is
the worked example.

**Owner direction, 2026-09-26** (the owner's words, typos fixed): the storefront — "she breathes,
her clothes move, her hair moves ... she moves the fan behind her a little bit ... not a big
movement as she breathes, and that loops", and "in storefront she waves her fan". The floor — "same,
her breathing, clothes moving, hair moving, and then she moves her fan a little bit ... in an attacky
way ... it has to be a seamless loop". The dash — "not a loop animation, just one attack animation
... she's moving her fan and ... an airy kind of blue ... reap ... as we did for [Mothmere], much
more same but bigger because her fan is bigger". The side (right wall) — "she also breathes, her
clothes move ... she moves her fan a little bit, small movements ... little attacky movements that
loop". Every sheet: the diamonds above her head "are not attached to her ... also move, not big
movements". She switches her fan from hand to hand (no fixed weapon hand). Claude's suggested
additions (the same hand within one animation, the diamonds each moving a little differently, one
fan wave mid-loop, a blink, a glint on the middle diamond, the floor feint, the wall flicks, the dash
swing and its colour) were all approved ("all yes").

## 1. What to upload

| Sheet | Upload as first **and** last frame | From | Clip |
|---|---|---|---|
| `storefront_idle` | `storefront_first_frame.png` | `sources/storefront.png` | **4 s** |
| `wall_bottom` | `wall_bottom_first_frame.png` | `sources/wall_bottom.png` | 2 s |
| `wall_right` | `wall_right_first_frame.png` | `sources/wall_right.png` | 2 s |
| dash attack | `dash_attack_first_frame.png` | `sources/dash_attack.png` | 2 s |

Not generated: the ceiling is the floor flipped and the left wall is the right wall mirrored, by the
packer (the standard recipe).

Why these files and not the Codex images: those are 1254 px off any pixel grid, with a faint
background-remover haze and a body at alpha 253, and Codex drew the four poses at different sizes.
`build_first_frames.py` keeps the poses, clears the haze, makes the body solid, reduces them to her
own height (166 px standing, fan top to feet; owner, GDD §14 #52) with each pose scaled so her head
matches the storefront's, quantizes to 256 colours with soft edges and no outline, and delivers them
4× nearest at 1024. `review_first_frames.png` shows all four; `first_frames_metadata.json` has the
scale, bounds, margins and colour counts.

The dash is one attack, played once per dash. The last frame is the same image only so AutoSprite
keeps her anchored; `slice_sheet.py` keeps eight cells of the swing, and the game holds the last one
until the wall.

## 2. AutoSprite settings — every sheet

Identical to Patchvile's: frame size **256**, **5 × 5** sheet, background remover **default**,
pixel-art filter **the same as Patchvile's**, Prompt Helper **off**, turbo, **2 s** (storefront
**4 s**). Upload the first frame as **both the first and the last frame**.

The exports the owner made are in `raw/`, unchanged: `storefront_idle_sheet.png` (25 cells),
`wall_bottom_sheet.png` (24 cells), `wall_right_sheet.png` (25 cells), `dash_attack_sheet.png`
(25 cells).

## 3. The prompts

As given on 2026-09-26. Each block is complete, ready to paste.

### Sheet 1 — `storefront_idle` (4 s)

```text
Scarlet, exactly as in the reference image, in the same pixel-art style and palette, with the same proportions (a slim young woman about seven heads tall, not chibi). Pale blonde hair swept to one side, with one long, thick braid over her right shoulder (on the left side of the picture when she faces us) that ends in a pale tuft tied with a gold and blue band. Pointed elf ears, blue eyes and blue crystal earrings. Above her head float three blue crystal diamonds framed in gold, not attached to her; the middle one is the largest. A dark navy high-collared bodysuit with bare shoulders, gold shoulder guards set with blue gems, and a large blue diamond gem framed in gold on her chest. Dark navy armbands and gloves with gold cuffs and blue gems. A gold belt with a blue diamond gem. A long skirt of pointed blue and turquoise panels with gold trim and gold diamond patterns, open at the front over dark navy leggings. Gold-plated high-heeled boots with blue gems. A very large open folding fan: blue paper in light and dark blue bands with two gold diamond patterns, on brown wooden ribs. The fan is open behind her, held low by its outer stick in her left hand (on the right side of the picture); her right hand rests on her hip. The fan stays in her left hand for the whole animation.
Motion: a seamless looping idle, front view, facing the viewer exactly as in the reference. She breathes slowly and calmly: her chest and shoulders rise and fall. Her hair, her braid and her skirt panels move gently. With her breathing she moves the big fan behind her a little with her hand, a small soft sway, never a big movement. In the middle of the loop she waves the fan once: it sweeps gently to one side and back, like fanning a breeze, and the tip of her braid and her skirt panels sway a little with that breeze; then she goes back to the calm breathing sway. She blinks once. The three floating diamonds above her head move a little, each slightly differently (a small bob and tilt), never drifting away and never changing size or shape, and the middle diamond glints once with a small sparkle. Her feet stay where they are. Static camera, no zoom, she does not move across the frame. The last frame returns exactly to the first pose so it loops seamlessly.
She stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror her. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no outline. Plain background.
```

### Sheet 2 — `wall_bottom` (2 s)

The in-depth prompt the owner asked for last (AutoSprite takes about 4,000 characters; this is 3,398),
given after the first floor sheet came out wrong: its fan rocked from 0° to −32° and back while
under 2 % of her body's pixels changed, so she did not look like she was breathing. The first
version asked for a small fan feint; two 500-character versions followed before the owner asked for
this one. It makes breathing the main motion and keeps the fan almost still. The sheet in `raw/` was
delivered after it.

```text
CHARACTER: Scarlet, exactly as in the reference image, in the same pixel-art style, palette, proportions and size. A slim young woman, about seven heads tall, not chibi. Pale blonde hair swept to one side, with one long, thick braid over her right shoulder that ends in a pale tuft tied with a gold and blue band. Pointed elf ears, blue eyes, blue crystal earrings. Above her head float three blue crystal diamonds framed in gold, not attached to her; the middle one is the largest. A dark navy high-collared bodysuit with bare shoulders, gold shoulder guards with blue gems, a large blue diamond gem framed in gold on her chest, dark navy armbands and gloves with gold cuffs, a gold belt with a blue gem, a long skirt of pointed blue and turquoise panels with gold trim over dark navy leggings, and gold high-heeled boots with blue gems. Behind her back is a very large open folding fan: blue paper in light and dark blue bands with two gold diamond patterns, on brown wooden ribs.

POSE: exactly the pose in the reference image, in every frame. She is crouched low on the floor with her knees bent, her right hand resting flat on the floor, and the big open fan behind her, held in her hidden left hand. Her boots, her knee and the hand on the floor stay exactly where they are in every frame. She does not stand up, jump, push off, slide, turn or move across the frame. She stays the same size and in the same place in the frame as in the reference.

MOTION: a calm, seamless idle loop. She is resting on the floor, alert and ready to spring into an attack, but she is not attacking.
1. Breathing is the main motion and must be clearly visible: two slow, deep breaths over the loop. On each breath in, her chest swells, her shoulders lift a little and her head rises slightly with them; on each breath out, they sink back down. Her upper body gently rises and settles; her arms follow the movement softly.
2. Hair: the loose strands around her face and her side-swept bangs sway softly. The long braid swings gently with her breathing, and the pale tuft at its end flutters a little.
3. Clothes: the pointed skirt panels move gently, their tips fluttering slightly as if in a light breeze. The cloth ripples softly as she breathes.
4. Fan: it moves only a little. It rises and settles very slightly together with her body as she breathes, as if carried by her. It does not tilt, rock, swing, spin, flip, close or open further; its shape and angle stay almost the same in every frame, like in the reference.
5. Floating diamonds: each of the three diamonds bobs up and down a little with a small tilt, each slightly out of step with the others. They stay above her head, never drift away and never change size or shape.
6. Face: calm and alert, eyes open, looking ahead. No head turns and no big expression changes.

TIMING: the movement is smooth and even across all frames, with no sudden jumps. The last frame returns exactly to the first pose, so the loop is seamless.

DO NOT: make the fan the main motion; swing or rotate the fan; freeze her body while only the fan moves; move her hand or feet off the floor; change her size or position; add a wall, floor, shadow, particles, effects or text; mirror her.

STYLE: pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no outline. Static camera, no zoom. Plain background.
```

### Sheet 3 — `wall_right` (2 s)

```text
Scarlet, exactly as in the reference image, in the same pixel-art style and palette, with the same proportions (a slim young woman about seven heads tall, not chibi). Pale blonde hair swept to one side, with one long, thick braid over her right shoulder (on the left side of the picture when she faces us) that ends in a pale tuft tied with a gold and blue band. Pointed elf ears, blue eyes and blue crystal earrings. Above her head float three blue crystal diamonds framed in gold, not attached to her; the middle one is the largest. A dark navy high-collared bodysuit with bare shoulders, gold shoulder guards set with blue gems, and a large blue diamond gem framed in gold on her chest. Dark navy armbands and gloves with gold cuffs and blue gems. A gold belt with a blue diamond gem. A long skirt of pointed blue and turquoise panels with gold trim and gold diamond patterns, open at the front over dark navy leggings. Gold-plated high-heeled boots with blue gems. A very large open folding fan: blue paper in light and dark blue bands with two gold diamond patterns, on brown wooden ribs. The fan is held out by its handle in her right hand, on the left side of the picture, away from the wall. The fan stays in her right hand for the whole animation.
Pose / motion: exactly the pose in the reference image - clinging to a wall on the right side of the frame (the wall is not drawn): her left hand pressed flat against it and both boots against it, the big open fan held out in her right hand away from the wall. She keeps this pose in every frame: her hand and boots stay on the wall and she does not jump, push off, slide, drop or move across the frame. She is ready to attack: alert. Normal breathing (her chest and shoulders rise and fall slightly), her hair and skirt panels moving gently, and her braid hanging and swaying a little. The three floating diamonds above her head move a little, each slightly differently (a small bob and tilt), never drifting away and never changing size or shape. Once or twice in the loop she flicks the fan a little outward, away from the wall, and back. Small movements only, not a real attack. Static camera, no zoom. The last frame returns exactly to the first pose so it loops seamlessly.
She stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror her. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no outline. Plain background.
```

### Sheet 4 — the dash attack (2 s)

The dash prompt names no hand for the fan: which hand holds it in the dash image could not be told.

```text
Scarlet, exactly as in the reference image, in the same pixel-art style and palette, with the same proportions (a slim young woman about seven heads tall, not chibi). Pale blonde hair swept to one side, with one long, thick braid that ends in a pale tuft tied with a gold and blue band. Pointed elf ears, blue eyes and blue crystal earrings. Above her head float three blue crystal diamonds framed in gold, not attached to her; the middle one is the largest. A dark navy high-collared bodysuit with bare shoulders, gold shoulder guards set with blue gems, and a large blue diamond gem framed in gold on her chest. Dark navy armbands and gloves with gold cuffs and blue gems. A gold belt with a blue diamond gem. A long skirt of pointed blue and turquoise panels with gold trim and gold diamond patterns over dark navy leggings. Gold-plated high-heeled boots with blue gems. A very large open folding fan: blue paper in light and dark blue bands with two gold diamond patterns, on brown wooden ribs. The fan stays in the hand that holds it in the reference image for the whole animation.
Pose / motion: flying fast toward the left in exactly the reference pose: body stretched out, her free hand reaching ahead, the big open fan raised above and behind her, her braid and skirt streaming back behind her. One single attack, played once - not a looping motion: she holds the flight pose for a moment, then sweeps the fan forward in one big arc in front of her, and an airy blue reap follows the fan's edge: a wide crescent of wind in pale sky blue to white, with a few thin wind streaks, staying close to the fan. The reap fades and she holds the end of the swing; only in the last frames does she ease back into the flight pose. One swing only, no second hit. Her braid, her skirt and the three floating diamonds stream behind her during the swing. No wall, no floor, no landing, and she does not travel across the frame. Keep her whole body, the fan's full swing and the whole blue reap inside the frame. Static camera, no zoom.
She stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror her. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no outline. Plain background.
```

## 4. What the game uses

`slice_sheet.py`: the storefront's 25 cells, the floor's 24, the right wall's 25, and eight dash
cells (07 flight, 09 wind-up, 10-11 the swing, 12 the full blue reap = the contact frame, 15 the reap
sweeping on, 19 the reap fading, 22 the end of the swing), turned a quarter clockwise so the flight
points up. Every frame is cleaned first (the fan's rib gaps AutoSprite filled with grey or white, the
reap's black tips; `review_cleanup.png`), and her particle pieces are cut from her frames
(`particles/`). The packer (`SHEET_PACKS["scarlet"]`, `roster_scale`, `standing` 166) packs them at
Patchvile's scale; her look in the game is in `docs/systems/playable_character_visuals.md`.
