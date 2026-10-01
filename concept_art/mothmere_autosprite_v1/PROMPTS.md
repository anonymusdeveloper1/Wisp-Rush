# Mothmere — AutoSprite v1: first frames and prompts

Status: **in the game (2026-09-25).** The owner generated the four sheets from these first frames and
prompts; they are in `raw/`, cut by `slice_sheet.py` and packed by the extractor. Id `mothmere`,
display name MOTHMERE. The recipe is [docs/guides/character_creation.md](../../docs/guides/character_creation.md),
Patchvile is the worked example.

**Owner direction, 2026-09-25** (the owner's words, typos fixed): the four poses are the owner's Codex images (`sources/`). The
storefront: "He breathes, his cloth is moving, his head is feeling relaxed, his hands are moving in a
breathing way, he makes small movements with his legs and he holds the weapon and hits the floor with
the end part that is at the floor of the first frame and particles fly, then breathing again and
repeat." The walls: "normal breathing, cloth moving, a ready to attack animation". The dash: "not a
looping animation, it's like one hit animation that he swings the weapon and a red like reap
appears". **He keeps the outline** his Codex images carry (owner; GDD §14 #49), the one exception to
Patchvile's no-outline rule.

## 1. What to upload

| Sheet | Upload as first **and** last frame | From | Clip |
|---|---|---|---|
| `storefront_idle` | `storefront_first_frame.png` | `sources/storefront.png` | **4 s** |
| `wall_bottom` | `wall_bottom_first_frame.png` | `sources/wall_bottom.png` | 2 s |
| `wall_right` | `wall_right_first_frame.png` | `sources/wall_right.png` | 2 s |
| dash attack | `dash_attack_first_frame.png` | `sources/dash_attack.png` | 2 s |

Not generated: the ceiling is the floor flipped and the left wall is the right wall mirrored, by the
packer (the standard recipe).

Why these files and not the Codex images: those are 1254 px off any pixel grid, drawn at 81 % of
their height instead of the roster's 76 %, with a faint background-remover haze and a body at alpha
253. `build_first_frames.py` keeps the poses, clears the haze, makes the body solid, reduces all four
at the roster size (standing 194 px in the 256 px frame) to 256 colours with soft edges, and delivers
them 4× nearest at 1024. The outline is kept. `review_first_frames.png` shows all four;
`first_frames_metadata.json` has the scale, bounds, margins and colour counts.

The dash is one hit, played once per dash. The last frame is the same image only so AutoSprite keeps
him anchored; `slice_sheet.py` keeps just the single swing (flight, wind-up, the swing with the red
reap, the end of the swing), and the game holds its last frame until the wall.

## 2. AutoSprite settings — every sheet

Identical to Patchvile's: frame size **256**, **5 × 5** sheet, background remover **default**,
pixel-art filter **the same as Patchvile's**, Prompt Helper **off**, turbo, **2 s** (storefront
**4 s**). Upload the first frame as **both the first and the last frame**.

The exports the owner made are in `raw/`, unchanged: `storefront_idle_sheet.png` (22 cells),
`wall_bottom_sheet.png` (18 cells), `wall_right_sheet.png` (23 cells), `dash_attack_sheet.png`
(25 cells).

## 3. The prompts

As given on 2026-09-25, with "no outline" taken out of the last line of each because the owner kept
the outline. Each block is complete, ready to paste.

### Sheet 1 — `storefront_idle` (4 s)

```text
Mothmere, exactly as in the reference image, in the same pixel-art style and palette, with the same proportions (a big hood over a small body). A tall pointed cream-white hood with tan swirl patterns and a teal lining, with a small pin of two cyan wings on its right side as we look at him. Inside the hood only a dark shadow face with two glowing cyan oval eyes, no mouth. A dark indigo scarf around his neck. A ragged cream cloak with a teal underside and tan swirl patterns over his shoulders. A dark charcoal tunic with cyan X-shaped stitches on the chest, dark cuffs with cyan X stitches on both wrists, dark grey gloves, a brown belt, baggy dark trousers and brown buckled boots. In his right hand (on the left side of the picture when he faces us) a tall gnarled brown wooden staff whose twisted top holds a small red flame spirit with two white eyes. The staff stays in his right hand in every frame.
Motion: a seamless looping idle, front view, facing the viewer exactly as in the reference. He breathes slowly and calmly: his chest and shoulders rise and fall, and both hands move a little with each breath while he keeps holding the staff. His cloak, scarf and the tip of his hood move gently. His head is relaxed: it tilts a little and settles back. He makes small, gentle movements with his legs, his boots staying where they are. In the middle of the loop he lifts the staff a little and strikes the floor with its bottom end, at the same spot where it stands in the reference, and a burst of particles flies up from where it hits; then he goes back to calm breathing. Static camera, no zoom, he does not move across the frame. The last frame returns exactly to the first pose so it loops seamlessly.
He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Plain background.
```

### Sheet 2 — `wall_bottom` (2 s)

```text
Mothmere, exactly as in the reference image, in the same pixel-art style and palette, with the same proportions (a big hood over a small body). A tall pointed cream-white hood with tan swirl patterns and a teal lining, with a small pin of two cyan wings on its right side as we look at him. Inside the hood only a dark shadow face with two glowing cyan oval eyes, no mouth. A dark indigo scarf around his neck. A ragged cream cloak with a teal underside and tan swirl patterns over his shoulders. A dark charcoal tunic with cyan X-shaped stitches on the chest, dark cuffs with cyan X stitches on both wrists, dark grey gloves, a brown belt, baggy dark trousers and brown buckled boots. In his right hand (on the left side of the picture when he faces us) a tall gnarled brown wooden staff whose twisted top holds a small red flame spirit with two white eyes. The staff stays in his right hand in every frame.
Pose / motion: exactly the pose in the reference image - crouched low on the floor, knees bent, the staff raised in his right hand, his other hand open beside him. He keeps this pose in every frame: his boots stay on the floor and he does not jump, push off, slide or move across the frame. He is ready to attack: tense and alert, gripping the staff. Only these move, gently: normal breathing (his chest and shoulders rise and fall slightly), and his cloak, scarf and the tip of his hood moving. Static camera, no zoom. The last frame returns exactly to the first pose so it loops seamlessly.
He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Plain background.
```

### Sheet 3 — `wall_right` (2 s)

```text
Mothmere, exactly as in the reference image, in the same pixel-art style and palette, with the same proportions (a big hood over a small body). A tall pointed cream-white hood with tan swirl patterns and a teal lining, with a small pin of two cyan wings on its right side as we look at him. Inside the hood only a dark shadow face with two glowing cyan oval eyes, no mouth. A dark indigo scarf around his neck. A ragged cream cloak with a teal underside and tan swirl patterns over his shoulders. A dark charcoal tunic with cyan X-shaped stitches on the chest, dark cuffs with cyan X stitches on both wrists, dark grey gloves, a brown belt, baggy dark trousers and brown buckled boots. In his right hand (on the left side of the picture when he faces us) a tall gnarled brown wooden staff whose twisted top holds a small red flame spirit with two white eyes. The staff stays in his right hand in every frame.
Pose / motion: exactly the pose in the reference image - clinging to a wall on the right side of the frame (the wall is not drawn): his left hand pressed flat against it and both boots against it, the staff held in his right hand away from the wall. He keeps this pose in every frame: his hand and boots stay on the wall and he does not jump, push off, slide, drop or move across the frame. He is ready to attack: tense and alert, gripping the staff. Only these move, gently: normal breathing (his chest and shoulders rise and fall slightly), and his cloak, scarf and the tip of his hood moving. Static camera, no zoom. The last frame returns exactly to the first pose so it loops seamlessly.
He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Plain background.
```

### Sheet 4 — the dash attack (2 s)

```text
Mothmere, exactly as in the reference image, in the same pixel-art style and palette, with the same proportions (a big hood over a small body). A tall pointed cream-white hood with tan swirl patterns and a teal lining, with a small pin of two cyan wings on its right side as we look at him. Inside the hood only a dark shadow face with two glowing cyan oval eyes, no mouth. A dark indigo scarf around his neck. A ragged cream cloak with a teal underside and tan swirl patterns over his shoulders. A dark charcoal tunic with cyan X-shaped stitches on the chest, dark cuffs with cyan X stitches on both wrists, dark grey gloves, a brown belt, baggy dark trousers and brown buckled boots. In his right hand a tall gnarled brown wooden staff whose twisted top holds a small red flame spirit with two white eyes. The staff stays in his right hand in every frame.
Pose / motion: flying fast toward the left in exactly the reference pose: body stretched out, the staff held forward in his right hand, his other hand reaching ahead, the cloak and scarf streaming back behind him. One single hit, played once - not a looping motion: he holds the flight pose for a moment, draws the staff back, then swings it forward in one fast, wide swing, and a red reap appears along the swing: a curved red crescent slash like the cut of a reaper's scythe. The red slash fades and he holds the end of the swing; only in the last frames does he ease back into the flight pose. One swing only, no second hit. No wall, no floor, no landing, and he does not travel across the frame. Keep his whole body, the staff's full swing and the whole red slash inside the frame. Static camera, no zoom.
He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Plain background.
```

## 4. What the game uses

`slice_sheet.py`: the storefront's 22 cells, the floor's 18, the right wall's 23, and eight dash cells
(07 flight, 08-09 wind-up, 11 the swing starting, 12 the full red reap = the contact frame, 13 and 15
the reap sweeping round and thinning, 19 the end of the swing), turned a quarter clockwise so the
flight points up. The packer (`SHEET_PACKS["mothmere"]`, `roster_scale`) packs them at Patchvile's
scale; his look in the game (red attack glow, red trail particles, dust landing) is in
`docs/systems/playable_character_visuals.md`.
