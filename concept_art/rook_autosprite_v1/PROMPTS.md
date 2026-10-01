# Rook — AutoSprite v1: first frames and prompts

Status: **in the game (2026-09-27).** The owner's five AutoSprite sheets are in `raw/`, cleaned and
sliced by `slice_sheet.py`, and replace his bone rig (GDD §14 #56).
The recipe is [docs/guides/character_creation.md](../../docs/guides/character_creation.md) and its
**AutoSprite rules** (§3); Patchvile is the worked example. Decisions: GDD §14 #55 (he keeps his
outline, and gets his own ceiling animation).

**Owner direction, 2026-09-27** (the owner's words, lightly cleaned): the dash attack — "he pushes
himself and dives in to kill and then swings", the swing with his **tail blade**. The storefront —
"he breathes, moves a little ... swings the wings a little bit while they're tucked in ... not like a
big swing ... and he also breathes, don't forget that", then "a looping relaxed animation. It doesn't
do anything much, but just a good looping animation". The floor — "he breathes, his tail is moving,
his wings are moving a little bit ... ready to attack ... his head is also moving". The right wall —
"his wings are not moving because he's attached with his wing, but he has that breathing animation,
his tail is moving, his head is moving". The ceiling — "like a bat ... staying still, but he will
move his wings a little bit ... ready to attack ... he can move his tail, his head, and ... he's
breathing". Claude's suggested additions (the push-dive-swing-recovery beats, a pale slash trail,
a wing rustle, a tail flick, an eye glow, the pounce dip, fixed grips, the bat sway, keeping his
outline) were all approved ("all yes").

## 1. What to upload

| Sheet | First frame | Last frame | Clip |
|---|---|---|---|
| `storefront_idle` | `storefront_first_frame.png` | the same image | 4 s |
| `wall_bottom` | `wall_bottom_first_frame.png` | the same image | 2 s |
| `wall_right` | `wall_right_first_frame.png` | the same image | 2 s |
| `wall_top` (his own ceiling) | `wall_top_first_frame.png` | the same image | 2 s |
| dash attack | `dash_attack_first_frame.png` | **the end of the tail swing** (rule A2), still to be drawn: Codex prompt in §4 | Ultra, 1–2 s (rule A1) |

The left wall is the right wall mirrored by the packer. The first frames are the owner's Codex images,
unchanged (`build_first_frames.py` checks them).

## 2. AutoSprite settings

Identical across the roster: frame size **256**, **5 × 5** sheet, pixel-art filter **the same as
Patchvile's**, Prompt Helper **off**. From the AutoSprite rules: background removal **Ultra** (A5),
**humanoid off** (A6, he is a four-legged dragon), turbo for the loops but **Ultra** (1–2 s) for the
dash and for any loop that comes out wrong (A1).

## 3. The prompts

As given on 2026-09-27; each block is complete. The storefront, floor and ceiling are the rewritten
versions (a relaxed storefront; the loop wording of rules B1–B4).

### Sheet 1 — `storefront_idle` (4 s)

```text
CHARACTER: Rook, exactly as in the reference image, in the same pixel-art style, palette, proportions and size. A small bone dragon with a big head: a pale bone-white skull mask with a pointed snout and swept-back bone spikes, two glowing magenta eyes, and two dark purple curved horns. A dark purple-black shaggy body with bone-white rib, spine and shoulder plates. Bat-like wings: bone-white wing bones with a curved claw spike at each wrist, and violet membranes with dark round holes. Short dark legs with bone-white claws. A long tail striped in bone-white and dark segments, ending in a pale crescent blade. A thin dark outline runs around him, exactly as in the reference.

POSE: exactly the pose in the reference image, in every frame: front view, facing the viewer, sitting upright on the ground with his wings folded down around his body like a cloak, his front claws on the ground and his tail curled at his side with the crescent blade near the ground. His claws stay where they are. He does not stand up, fly, turn or move across the frame.

MOTION: a seamless, relaxed looping idle. He is relaxed and at ease, resting calmly; every movement is slow and gentle. Subtle, slow and calm: a breathing idle, not an action. He does not do much; the loop simply breathes and flows.
1. Breathing is the main motion and must be clearly visible: two slow, even breaths over the whole loop; his chest and shoulders rise and fall, and his head rises and settles a little with them.
2. Wings: they stay folded the whole time. Once in the loop they give one small, soft rustle: they lift a little and settle back into place. Never a big movement, and they never open.
3. Tail: it sways slowly and softly, and once in the loop the crescent blade at its tip gives a small, lazy flick.
4. Eyes: once in the loop his glowing eyes slowly brighten, then dim back to normal.

TIMING: every movement is smooth and even across all frames, with no sudden jumps and no fast moves. Every movement returns to the starting pose: the last frame matches the first exactly, so it loops seamlessly.

DO NOT: open or spread his wings; make the wings or the tail the main motion; make any move quick or sharp; freeze his body while only a wing or the tail moves; change his size or position; add a floor, shadow, particles, effects or text.

STYLE: pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Keep his thin dark outline exactly as in the reference. Static camera, no zoom. Plain background. He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him.
```

### Sheet 2 — `wall_bottom` (2 s)

```text
CHARACTER: Rook, exactly as in the reference image, in the same pixel-art style, palette, proportions and size. A small bone dragon with a big head: a pale bone-white skull mask with a pointed snout and swept-back bone spikes, two glowing magenta eyes, and two dark purple curved horns. A dark purple-black shaggy body with bone-white rib, spine and shoulder plates. Bat-like wings: bone-white wing bones with a curved claw spike at each wrist, and violet membranes with dark round holes. Short dark legs with bone-white claws. A long tail striped in bone-white and dark segments, ending in a pale crescent blade. A thin dark outline runs around him, exactly as in the reference.

POSE: exactly the pose in the reference image, in every frame: crouched low on the floor on all four legs, facing left, his head low and forward, his wings raised half-open above his back, and his tail curled up behind him with the crescent blade raised. His claws stay planted on the floor in every frame. He does not jump, lift off, slide or move across the frame.

MOTION: a seamless idle loop: a breathing idle, not an action. He is resting on the floor, alert and ready to pounce, but he is not attacking. Every movement is small and slow.
1. Breathing is the main motion and must be clearly visible: two slow, even breaths over the whole loop; his chest and shoulders rise and fall.
2. Head: small, slow turns and tilts, his eyes watching ahead.
3. Wings: the half-open wings shift a little, never flapping.
4. Tail: it sways slowly, the crescent blade moving with it.
5. Once in the loop his shoulders dip slightly, as if he is about to pounce, then rise back.

TIMING: every movement is smooth and even across all frames, with no sudden jumps. Every movement returns to the starting pose: the last frame matches the first exactly, so it loops seamlessly.

DO NOT: flap or fold his wings; make the wings or the tail the main motion; make any move quick or sharp; freeze his body while only a wing or the tail moves; lift a claw off the floor; change his size or position; add a floor, shadow, particles, effects or text.

STYLE: pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Keep his thin dark outline exactly as in the reference. Static camera, no zoom. Plain background. He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him.
```

### Sheet 3 — `wall_right` (2 s)

```text
CHARACTER: Rook, exactly as in the reference image, in the same pixel-art style, palette, proportions and size. A small bone dragon with a big head: a pale bone-white skull mask with a pointed snout and swept-back bone spikes, two glowing magenta eyes, and two dark purple curved horns. A dark purple-black shaggy body with bone-white rib, spine and shoulder plates. Bat-like wings: bone-white wing bones with a curved claw spike at each wrist, and violet membranes with dark round holes. Short dark legs with bone-white claws. A long tail striped in bone-white and dark segments, ending in a pale crescent blade. A thin dark outline runs around him, exactly as in the reference.

POSE: exactly the pose in the reference image, in every frame: clinging to a wall on the right side of the frame (the wall is not drawn), his feet gripping it and the claw of his raised wing hooked onto it, his body upright, his head turned toward the left, and his tail hanging down with the crescent blade at its end. His feet and the wing claw on the wall stay exactly where they are in every frame, and his wings do not move. He does not jump, push off, slide, drop or move across the frame.

MOTION: a seamless idle loop. He is holding on, alert and ready to attack, but he is not attacking.
1. Breathing is the main motion and must be clearly visible: slow breaths; his chest and shoulders rise and fall.
2. Head: it turns toward the arena on the left and back, with small tilts.
3. Tail: it hangs and sways slowly, the crescent blade swinging a little with it.

TIMING: smooth and even across all frames, no sudden jumps. The last frame returns exactly to the first pose, so the loop is seamless.

DO NOT: move his wings; let go of the wall or move his feet or the wing claw; make the tail the main motion; freeze his body while only the tail moves; change his size or position; draw the wall; add a shadow, particles, effects or text.

STYLE: pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Keep his thin dark outline exactly as in the reference. Static camera, no zoom. Plain background. He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him.
```

### Sheet 4 — `wall_top`, his own ceiling (2 s)

```text
CHARACTER: Rook, exactly as in the reference image, in the same pixel-art style, palette, proportions and size. A small bone dragon with a big head: a pale bone-white skull mask with a pointed snout and swept-back bone spikes, two glowing magenta eyes, and two dark purple curved horns. A dark purple-black shaggy body with bone-white rib, spine and shoulder plates. Bat-like wings: bone-white wing bones with a curved claw spike at each wrist, and violet membranes with dark round holes. Short dark legs with bone-white claws. A long tail striped in bone-white and dark segments, ending in a pale crescent blade. A thin dark outline runs around him, exactly as in the reference.

POSE: exactly the pose in the reference image, in every frame: hanging upside down from a ceiling at the top of the frame (the ceiling is not drawn), like a bat, his feet gripping it at the top, his wings wrapped around his body, his head at the bottom facing the viewer upside down, and his tail curled up at his side with the crescent blade. His feet on the ceiling stay exactly where they are in every frame. He does not let go, drop, fly or move across the frame.

MOTION: a seamless idle loop, like a bat hanging still: a breathing idle, not an action. He is alert and ready to attack, but he is not attacking. Every movement is small and slow.
1. Breathing is the main motion and must be clearly visible: two slow, even breaths over the whole loop; his chest rises and falls.
2. His whole hanging body sways very slightly from his feet, like a hanging bat, and comes back to where it started.
3. Head: it lifts and turns a little toward the arena, upside down, and settles back.
4. Wings: they stay wrapped around him and shift only a little, never opening.
5. Tail: it curls and uncurls a little, the crescent blade moving with it.

TIMING: every movement is smooth and even across all frames, with no sudden jumps. Every movement returns to the starting pose: the last frame matches the first exactly, so it loops seamlessly.

DO NOT: open his wings; move his feet on the ceiling; swing him far; make the wings or the tail the main motion; make any move quick or sharp; freeze his body while only a wing or the tail moves; change his size or position; draw the ceiling; add a shadow, particles, effects or text.

STYLE: pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Keep his thin dark outline exactly as in the reference. Static camera, no zoom. Plain background. He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him.
```

### Sheet 5 — the dash attack

**To be rewritten** once the end-of-swing last frame exists (rule A2): this version was written for
the same first and last image, so it ends with a recovery back to the flight pose, which the new last
frame makes unnecessary.

```text
CHARACTER: Rook, exactly as in the reference image, in the same pixel-art style, palette, proportions and size. A small bone dragon with a big head: a pale bone-white skull mask with a pointed snout and swept-back bone spikes, two glowing magenta eyes, and two dark purple curved horns. A dark purple-black shaggy body with bone-white rib, spine and shoulder plates. Bat-like wings: bone-white wing bones with a curved claw spike at each wrist, and violet membranes with dark round holes. Short dark legs with bone-white claws. A long tail striped in bone-white and dark segments, ending in a pale crescent blade. A thin dark outline runs around him, exactly as in the reference.

POSE: the first frame is exactly the reference image: flying toward the left, side view, his body stretched out, his head forward on the left, his wings raised up and back, and his tail curled behind him with the crescent blade. No wall, no floor.

MOTION: one single attack, played once, not a looping motion. Four clear beats, each a clearly different pose:
1. The push: from the flight pose he gives one strong wingbeat that drives him forward.
2. The dive: his wings tuck in tight against his body and he stretches out long, head first, diving at his target.
3. The swing (the hit): at the end of the dive he whips his tail around in front of him, and the crescent blade cuts through the air in one fast, wide arc, leaving a pale violet to bone-white slash trail along the arc. This is the strongest moment; hold it for a couple of frames.
4. The recovery: the slash trail fades, his wings open again and he eases back toward the flight pose; only in the last frames does he return to the first pose.
One swing only, no second hit.

TIMING: the push and the dive are quick, the swing is the peak, the recovery is calm. The last frame returns to the first pose.

DO NOT: travel across the frame or leave the frame; draw a wall, floor or landing; make the slash trail strong magenta; swing twice; change his size. Keep his whole body, his wings, the tail's full swing and the whole slash trail inside the frame.

STYLE: pixel art matching the reference: the same pixel size and palette in every frame, crisp pixels, no blur, no anti-aliasing. Keep his thin dark outline exactly as in the reference. Static camera, no zoom. Plain background. He stays exactly the same size and in the same place in the frame as in the reference image, in every frame. Do not mirror him.
```

## 4. Codex prompts

### The dash's last frame — the end of the tail swing (2026-09-27)

Attach `dash_attack_first_frame.png` (and `storefront_first_frame.png` for his look).

```text
Create one more image for Rook, a playable character in Wisp Rush, a 2D pixel-art mobile game: the LAST frame of his dash attack animation. I attach his dash first frame (dash_attack_first_frame.png) and his storefront (storefront_first_frame.png). Keep his design exactly: a small bone dragon with a big head, a pale bone-white skull mask with a pointed snout, two glowing magenta eyes, two dark purple curved horns, a dark purple-black shaggy body with bone-white plates, bat-like wings with bone-white wing bones and violet membranes with dark round holes, short dark legs with bone-white claws, and a long striped tail ending in a pale crescent blade. Same proportions, colours and details as the attached images.

THE POSE: the end of his attack. In the dash he flies toward the left, pushes himself forward with one wingbeat, dives with his wings tucked, then whips his tail around in front of him so the crescent blade cuts through the air in one wide arc. Draw the moment that swing ends: side view, still flying toward the left, his body stretched out in the same place as in the attached dash frame, his wings still tucked close from the dive, and his tail swept around in front of him with the crescent blade out ahead of his head at the end of its arc, as if it has just cut through a target.

Rules:
- Exactly the same canvas, scale and pixel size as the attached dash_attack_first_frame.png: 1024 x 1024 px with a transparent background (real transparency, not a checkerboard or white); the art is 256 x 256 pixels scaled up 4x with nearest neighbour, so every art pixel is an exact 4 x 4 block on one grid; the same head size. His body stays in the same place in the canvas as in the attached dash frame; only his pose changes.
- Pixel art: no anti-aliasing, no blur, no gradients, no glow haze, nothing painterly or 3D. Keep his thin dark outline exactly as in the attached images.
- At most 256 colours.
- Leave at least 60 px of empty space on every side; his whole body, wings, tail and blade stay inside the frame.
- Do not mirror him. No shadow, no floor, no wall, no background, no text, no border, and no effects (no slash trail, particles or speed lines).

Deliver one PNG file: rook_dash_attack_end.png.
```
