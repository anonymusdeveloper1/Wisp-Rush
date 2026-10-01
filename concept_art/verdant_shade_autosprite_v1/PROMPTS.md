# Shade — AutoSprite rework v1: first frames and prompts

Status: **in the game (2026-09-25).** The owner generated all five sheets, the ceiling included;
they are in `raw/`, cut by `slice_sheet.py` and packed by the extractor. The Codex-frame Shade and
its menu video are retired. Id stays `verdant_shade`,
display name SHADE. The recipe is [docs/guides/character_creation.md](../../docs/guides/character_creation.md),
Patchvile is the worked example.

**Owner direction, 2026-09-25:** the positions are the ones the game shows today; the storefront
idle is exactly the motion the menu video was described with
(`concept_art/verdant_shade_storefront_video_v1/VIDEO_PROMPT.md`).

## 1. What to upload

| Sheet | Upload as first **and** last frame | From today's frame | Clip | Keep |
|---|---|---|---|---|
| `storefront_idle` | `storefront_first_frame.png` | `idle_hover_00`, the pose the menu video started from | **4 s** | 25 |
| `wall_bottom` | `wall_bottom_first_frame.png` | `wall_bottom_00` | 2 s | 24 |
| `wall_right` | `wall_right_first_frame.png` | `wall_left_00`, mirrored | 2 s | 24 |
| dash attack | `dash_attack_first_frame.png` | `dash_loop_01`, the dive (drawn face down) | 2 s | 8 |
| *(optional)* `wall_top` | `optional_wall_top_first_frame.png` | `wall_top_00`, today's own ceiling pose | 2 s | 24 |

Not generated: the ceiling is the floor flipped and the left wall is the right wall mirrored, by the
packer (the standard recipe). **Today's ceiling pose is different** (three flames gripping the
ceiling); keeping it takes the optional fifth sheet, and then the packer uses it instead of the flip.

Why these files and not today's frames: today's frames are painted at 512 and 724 px (50–100k
colours), drawn at 96 % of their canvas instead of the roster's 76 %, and two are damaged —
`wall_bottom` carries slivers of a neighbouring atlas cell above the head, and every `wall_left`
frame has a sliver at the top and its tail cut flat by the canvas bottom. `build_first_frames.py`
keeps the poses and draws them **exactly like Patchvile** (owner, 2026-09-25; guide §3): 256 px
frame resolution delivered 4× nearest at 1024, **no outline**, up to 256 colours with soft edges
as AutoSprite exports a frame, the slivers and their glow removed, the tail finished to a point, and
**the roster size: 194 px standing** (flame-horn tips to tail tip), every pose at that one scale.
`review_first_frames.png` shows all five; `first_frames_metadata.json` has the scale, bounds,
margins and colour counts.

The dash is drawn **upright**, as it was in the game, with the face at the bottom and the horns at
the top. Shade is symmetric, so it needs no side view and `dash_head_up` stays off, but the face
must lead: the slicer turns each dash cell 180° (owner, 2026-09-25: "he has to attack with his
face in front").

## 2. AutoSprite settings — every sheet

Identical to Patchvile's: frame size **256**, **5 × 5** sheet (25 frames), background remover
**default**, pixel-art filter **the same as Patchvile's**, Prompt Helper **off**, turbo, **2 s**
(storefront **4 s**). Upload the first frame as **both the first and the last frame**.

Save each export unchanged in `raw/`: `storefront_idle_sheet.png`, `wall_bottom_sheet.png`,
`wall_right_sheet.png`, `dash_attack_sheet.png` (and `wall_top_sheet.png` if you make it).

## 3. The prompts

Every prompt is **[IDENTITY] + the sheet's motion + [ENDING]**. Each block below is complete,
ready to paste.

[IDENTITY]
```text
Shade, exactly as in the reference image, in the same pixel-art style and palette: a small hooded forest spirit. A pointed dark green hood made of overlapping leaves; a smooth pale bone-white mask for a face with two glowing green almond-shaped eyes and no mouth; a small glowing green gem on its chest; a coat of layered dark green leaves with bright green edges; two curling green flame horns rising from the top of the hood; a glowing green flame tail that curls below the body instead of legs. It has no arms, no hands, no legs and no feet, and it must not grow any.
```

[ENDING]
```text
It stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no glow haze. The flames are green and pale green, never gold, orange, pink or purple. Plain background.
```

### Sheet 1 — `storefront_idle` (4 s)

The menu video's motion, line for line.

```text
Shade, exactly as in the reference image, in the same pixel-art style and palette: a small hooded forest spirit. A pointed dark green hood made of overlapping leaves; a smooth pale bone-white mask for a face with two glowing green almond-shaped eyes and no mouth; a small glowing green gem on its chest; a coat of layered dark green leaves with bright green edges; two curling green flame horns rising from the top of the hood; a glowing green flame tail that curls below the body instead of legs. It has no arms, no hands, no legs and no feet, and it must not grow any.
Motion: a seamless looping breathing idle, front view, facing the viewer exactly as in the reference. Subtle, slow and calm: a breathing idle, not an action. The whole body floats gently up and down by a very small amount, in one slow cycle over the whole loop, and ends exactly where it started. The two flame horns flicker and sway softly like candle flames, their tips curling and uncurling. The leaf coat breathes: the leaves lift and settle slightly and the outer leaf tips ripple. The flame tail sways slowly from side to side and curls, like smoke in still air. The chest gem pulses softly brighter and dimmer. The eyes glow steadily, with one slow, calm blink in the middle of the loop. The hood and mask keep facing the viewer; the head may tilt a few degrees and back. Static camera, no zoom; apart from the gentle float it does not move across the frame. Every movement returns to the starting pose: the last frame matches the first exactly, so it loops seamlessly. Do not mirror it.
It stays exactly the same size as in the reference image, in every frame. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no glow haze. The flames are green and pale green, never gold, orange, pink or purple. Plain background.
```

### Sheet 2 — `wall_bottom` (2 s)

```text
Shade, exactly as in the reference image, in the same pixel-art style and palette: a small hooded forest spirit. A pointed dark green hood made of overlapping leaves; a smooth pale bone-white mask for a face with two glowing green almond-shaped eyes and no mouth; a small glowing green gem on its chest; a coat of layered dark green leaves with bright green edges; two curling green flame horns rising from the top of the hood; a glowing green flame tail that curls below the body instead of legs. It has no arms, no hands, no legs and no feet, and it must not grow any.
Pose / motion: exactly the pose in the reference image - crouched low on the floor, the hood tilted and the mask turned toward the right, its flame tail spread along the ground in curling flame tendrils on both sides, the two flame horns rising above the hood. It keeps this pose in every frame: the hood, the mask, the leaf coat and where the flames leave its body stay exactly where they are, and it does not jump, push off, slide, float up or move across the frame. Only these move, gently: slow breathing (the leaf coat lifts and settles slightly), the flame horns and the flame tendrils flickering and swaying softly like candle flames, the outer leaf tips rippling, and the chest gem pulsing softly. The eyes glow steadily. Static camera, no zoom. The last frame returns exactly to the first pose so it loops seamlessly. Do not mirror it.
It stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no glow haze. The flames are green and pale green, never gold, orange, pink or purple. Plain background.
```

### Sheet 3 — `wall_right` (2 s)

```text
Shade, exactly as in the reference image, in the same pixel-art style and palette: a small hooded forest spirit. A pointed dark green hood made of overlapping leaves; a smooth pale bone-white mask for a face with two glowing green almond-shaped eyes and no mouth; a small glowing green gem on its chest; a coat of layered dark green leaves with bright green edges; two curling green flame horns rising from the top of the hood; a glowing green flame tail that curls below the body instead of legs. It has no arms, no hands, no legs and no feet, and it must not grow any.
Pose / motion: exactly the pose in the reference image - clinging to a wall on the right side of the frame (the wall is not drawn), its back and its streaming flame horns toward the wall, the mask turned out toward the left, the flame tail hanging below it, a few small loose leaves floating beside it. It keeps this pose in every frame: the hood, the mask, the leaf coat and where the flames leave its body stay exactly where they are, and it does not jump, push off, slide, drop or move across the frame. Only these move, gently: slow breathing (the leaf coat lifts and settles slightly), the flame horns and the tail flickering and swaying softly like candle flames, the outer leaf tips rippling, the loose leaves drifting a little and staying close to it, and the chest gem pulsing softly. The eyes glow steadily. Static camera, no zoom. The last frame returns exactly to the first pose so it loops seamlessly. Do not mirror it.
It stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no glow haze. The flames are green and pale green, never gold, orange, pink or purple. Plain background.
```

### Sheet 4 — the dash attack (2 s)

One attack, played once per dash (owner, #40). The game adds the glow outline, the contact flash,
afterimages and a shader slash on top, so the drawn burst stays compact.

```text
Shade, exactly as in the reference image, in the same pixel-art style and palette: a small hooded forest spirit. A pointed dark green hood made of overlapping leaves; a smooth pale bone-white mask for a face with two glowing green almond-shaped eyes and no mouth; a small glowing green gem on its chest; a coat of layered dark green leaves with bright green edges; two curling green flame horns rising from the top of the hood; a glowing green flame tail that curls below the body instead of legs. It has no arms, no hands, no legs and no feet, and it must not grow any.
Pose / motion: flying fast straight up toward the top of the frame, head first, in exactly the reference pose: the hood leading, the two flame horns swept up along the hood, the leaf coat folded tight around the body and the flame tail streaming down behind it. One attack that starts and ends in this pose: it holds the flight pose, draws in (the leaf coat tucks tighter and the flame horns pull back), then strikes - the leaf coat bursts open wide to both sides and both flame horns lash forward over the hood in one bright green burst of flame close around its head - holds the follow-through while the flames settle, then folds back into the flight pose. No wall, no floor, no landing, and it does not travel across the frame. Keep the whole body, the opened leaves and the whole flame burst inside the frame; the burst stays close around the body. Static camera, no zoom. The last frame returns exactly to the first pose. Do not mirror it.
It stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no glow haze. The flames are green and pale green, never gold, orange, pink or purple. Plain background.
```

### Sheet 5 (optional) — `wall_top`, only to keep today's ceiling pose (2 s)

```text
Shade, exactly as in the reference image, in the same pixel-art style and palette: a small hooded forest spirit. A pointed dark green hood made of overlapping leaves; a smooth pale bone-white mask for a face with two glowing green almond-shaped eyes and no mouth; a small glowing green gem on its chest; a coat of layered dark green leaves with bright green edges; two curling green flame horns rising from the top of the hood; a glowing green flame tail that curls below the body instead of legs. It has no arms, no hands, no legs and no feet, and it must not grow any.
Pose / motion: exactly the pose in the reference image - hanging upright below a ceiling (the ceiling is not drawn), gripping it with the glowing curled tips of the flames that reach up from its hood, facing the viewer. It keeps this pose in every frame: the gripping flame tips stay exactly where they are, and the hood, the mask and the leaf coat stay in place; it does not drop, swing or move across the frame. Only these move, gently: slow breathing (the leaf coat lifts and settles slightly), the flames flickering softly below their gripping tips, the flame tail swaying like smoke, the outer leaf tips rippling, and the chest gem pulsing softly. The eyes glow steadily. Static camera, no zoom. The last frame returns exactly to the first pose so it loops seamlessly. Do not mirror it.
It stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing, no glow haze. The flames are green and pale green, never gold, orange, pink or purple. Plain background.
```

## 4. Reject a sheet if

- It grows arms, hands, legs, feet, a mouth or extra eyes, or loses a flame horn, the tail or the gem.
- The flames turn gold, orange, pink or purple, or a soft glow haze or blur spreads around it.
- **A wall sheet changes the pose**: it slides, jumps, drops, leaves the surface or turns its mask.
- The storefront turns away, floats more than a few pixels, skips the blink or blinks more than once,
  or does not return to the first pose.
- The dash shows a wall or floor, travels across the frame, clips the burst at a cell edge, or its
  last frame is not the first pose.
- It drifts, grows or shrinks across the loop, anything touches a cell edge, or the pixels go soft
  or change size.

## 5. After the exports (Claude)

Slicer (`slice_sheet.py`, walls 24, storefront 25, dash 8 cells turned 180°), a `SHEET_PACKS`
entry with `roster_scale` and Patchvile's `derive` (or the fifth sheet for the ceiling), Shade on
`WholeFrameCharacterVisual` like `patchvile_visual.tscn`, its own attack look (green glow, pale green
slash edge), dash and trail particles cut from its own leaves and flames, and the green `SOUL_FLARE`
dash signature kept. **Open question for the owner:** the Home and Shop card keep the painted menu
video, or play this pixel storefront instead (the recipe's default under ADR-0018).
