# Character sprite frames — the generation contract

> What a playable character is made of when it is drawn as **whole frames** rather than rigged from
> parts. This is the order form: everything here is something an art pass has to produce, and
> nothing here is optional unless it says so.
>
> Read with [ASSETS.md](../ASSETS.md) → *"Commissioning an animation loop as whole frames"*, which
> holds the registration rules every set must meet, and
> [playable_character_visuals.md](../systems/playable_character_visuals.md), which holds how the rig
> consumes them. The parts-and-bones alternative is [character_rig_recipe.md](character_rig_recipe.md).

**Decision, owner, 2026-09-20 (GDD §14 #34):** playable characters are whole-frame sprites. No new
bone rigs. The roster was cut to seven the same day — Void and Eclipse, the four surviving rigs
(Veyra, Rook, Morrow, Noxen) and **Ilyra**. The four rigs keep their rigs until they are re-cut as
frames.

**Decision, owner, 2026-09-20:** a character is **five animations**. See §3 — the set was cut from
sixteen the same day, and the sections below are the reduced order form.

---

## 1. What the engine already animates — do not draw these

`PlayableCharacterVisual` applies all of the following on top of whatever frame is showing. Drawing
them into the frames too makes them happen twice.

| The engine does | Meaning for the art |
|---|---|
| Squash and stretch on every state change | Don't bake anticipation squash into a frame |
| A bounce/settle offset on `MotionRoot` | Don't draw the character rising and falling; it already does |
| Heading turn — the body rotates to face the dash direction, damped | Draw the dash facing **down the +Y axis of the canvas**; the rig turns it |
| Alpha fade on death and spawn | Don't draw fade-out frames |
| Wall counter-rotation | See §5 — wall frames are drawn in screen space and the rig un-rotates them |
| The drifting ornament ring (`CharacterAura`) | Loose sparkles orbit outside the body; see §7 |
| The dash trail and the dash signature | Fully procedural; see §8. **No dash VFX art is needed** |
| The hit blink and the edge reset | A hit is the controller blinking and moving the Wisp; no hit art |

What a frame carries is **the body**: pose, limbs, cloth, hair, face, held props.

---

## 2. Canvases and registration

Two canvases per character, each used consistently across its whole set.

| Set | Delivered at | Packed at | Drawn on screen |
|---|---|---|---|
| Dash + wall loops | **512 × 512** | 384 × 384 | **~230 px** in the 1080-wide design space |
| Menu / storefront | **724 × 724**, portrait crop allowed | 448 × 448 | ~520 px |

**Why deliver bigger than we ship.** Measured on the real gameplay render at 1080 × 1920: the
character is about **230 px tall in a run** — the playfield is inset, `_player_radius` clamps at 70
and the rig draws `radius × 3.35`. Delivering at 512 leaves headroom for higher-DPI phones and for
marketing renders, while the sheet packs at 384. Both numbers are ours to change later without
re-commissioning art; the art pass only needs the delivery size.

Hard rules, all of them:

- **Transparent straight-alpha RGBA PNG.** RGB under alpha 0 zeroed, or Godot's `fix_alpha_border`
  bleeds stale colour into the silhouette edge.
- **One anchor pixel per set.** Nominate the character's hips and put them at the same canvas
  coordinate in **every** frame of the set. This is the single property that decides whether a loop
  reads as motion or as jitter. The intake measures it: if `CharacterPoseSheet` comes back with a
  non-zero offset for any frame, the set is **not** registered — fix the art rather than leaning on
  the offset, because a runtime offset that varies per frame *is* the jitter.
- **Small deltas between neighbours.** Consecutive frames differ by a breath, not a new idea. Two
  separately excellent drawings of the same character still cut when swapped.
- **Loops must close** — the last frame leads back into the first. Every animation in the set loops.
- **Numbered sequences**, `<state>_00.png` upward, zero-padded to two digits.
- **One camera, one light, one scale** across the entire character. Gameplay and menu sets may differ
  in framing but not in who the character is.

---

## 3. The move list — five animations

A character has five animations and no more. The controller still speaks the full thirteen-state
vocabulary in `PlayableCharacterVisual` — the bone rigs animate all of it for free — but a drawn
character only has frames for what the player actually looks at, and
`WholeFrameCharacterVisual._target_animation()` resolves everything else onto one of these five.

| Animation | Frames | fps | Loops | On screen |
|---|---:|---:|:--:|---|
| `dash_loop` | **4** | 12.5 | ✔ | Every dash. **One frame must be the contact frame** — the dash *is* the attack |
| `wall_bottom` | **8** | 6.7 | ✔ | Resting on the floor |
| `wall_top` | **8** | 6.7 | ✔ | Hanging from the ceiling |
| `wall_left` | **8** | 6.7 | ✔ | Clinging to the left wall (`wall_right` is this mirrored — see §5) |
| `storefront_idle` | **12** | 6.0 | ✔ | Home and the Shop card |

**Total: 40 frames per character.**

### What the cut states do instead

The owner cut eleven animations on 2026-09-20. Each one still *happens* — it is simply carried by
the controller, not by a drawing:

| Cut | What the player sees now |
|---|---|
| `aim_charge` | Only the aim arrow appears. Holding it must not change the character at all (owner, 2026-09-19) |
| `dash_start` | Nothing: the windup is 0.065 s and the arrow is the tell. The dash frames start immediately |
| `dash_end` | The wall animation arriving *is* the landing, on whichever wall was hit |
| `attack` | The dash's own contact frame — the dash is the attack |
| `move_fly` | The wall loop, while the Frozen Choir drift slides the character along its edge |
| `hit_reaction` | The controller's invulnerability blink and the reform at a safe edge |
| `death` | The controller's 0.55 s alpha dissolve over whatever was showing |
| `revive_spawn` | The character is simply on its wall when the run starts |
| `victory` | The wall loop; the boss-victory beat is the HUD and the audio |
| `idle_hover` (gameplay) | Unreachable in a run — a live character is always against a wall |
| `storefront_flourish` / `_unlock` | A focused, equipped or bought card keeps breathing |

The frames for all of these are still in `concept_art/`. Restoring one is a row in
`tools/art/extract_playable_characters.py`'s `sheets` list and a re-pack — not a re-commission.

### Direction and framing

- The four `dash_loop` frames are drawn **facing down the canvas's +Y axis** (toward the bottom
  edge). The rig rotates the whole frame to point along the dash. A frame drawn "flying to the
  right" will fly sideways relative to its own travel.
- The wall loops and `storefront_idle` are **not** heading states — they are shown upright, so draw
  them upright.

---

## 4. The storefront loop — what the Shop and Home show

Drawn on the menu canvas (§2), where the character is large and still and there is nothing else to
look at. This is the single animation that decides whether a character feels alive in the Shop.

- **`storefront_idle` is a closing loop, not a set of poses.** This is the lesson that cost the most:
  Ilyra originally shipped four separate storefront *paintings* that the rig cycled, and four
  different drawings swapping four times a second read as a flip-book, not a breath. She is down to
  one held painting today because one still frame beats four unregistered ones. Twelve registered
  frames of a single slow breath is the target.
- It may show the character doing something impossible in a run. It is a performance.
- It is the **only** menu animation. A card that is focused, equipped or bought keeps breathing;
  there is no pick or purchase reaction any more.

**Or a video.** The menu performance can instead be a pre-rendered clip from an image-to-video
model ([ADR-0016](../decisions/0016-menu-videos-for-character-storefronts.md)). The brief to copy
is `concept_art/verdant_shade_storefront_video_v1/VIDEO_PROMPT.md` — flat magenta, start frame =
end frame, static camera — and `tools/art/extract_menu_video.py` turns the take into the game's
copy. The 12-frame `storefront_idle` is still delivered: it is the Reduced Motion fallback.

---

## 5. Wall loops — the most-seen frames in the game

The player spends most of a run resting against a wall waiting to aim, so these are on screen more
than everything else combined. They are the reason to spend frames.

Four surfaces, from the inward wall normal:

| Frame set | Surface | Frames |
|---|---|---:|
| `wall_bottom_NN` | Standing on the floor | **8** |
| `wall_top_NN` | Hanging from the ceiling | **8** |
| `wall_left_NN` | Clinging to the left wall | **8** |
| `wall_right` | Clinging to the right wall | **0** — mirror of `wall_left` |

- **Drawn in screen space, not character space.** The character is upright to the *player* on every
  wall — head up on the floor, head down is wrong. The rig cancels the rotation it would otherwise
  apply, so what is drawn is what is seen.
- **`wall_right` is `wall_left` mirrored** unless the character is asymmetric in a way that matters
  (a weapon in one hand, an eyepatch, an asymmetric costume). Mirroring is free and deterministic;
  state per character whether it is allowed. If not, it is another 8 frames.
- The arena floor is a polygon, so a resting normal is rarely exactly cardinal — the nearest wall by
  alignment wins. Draw for the four cardinals only.

---

## 6. Ornaments — the drifting ring

Six to eight loose pieces of the character's own costume, cut out separately. `CharacterAura` orbits
them outside the body, so they keep moving while the character is idle or hanging on a wall, and
they are what stops a held frame looking dead. With the set down to five animations they matter
more, not less.

- Small, 64–256 px each, transparent RGBA, no canvas rule — they are placed by the aura.
- They must be **of the costume**: Ilyra's ring is her crown shards and her sparkles, not a generic
  star. That is the whole point — a character's ring should be recognisably theirs.
- Anything else loose is welcome: a chest-gem glow, a slash arc, a feather, an ember.

---

## 7. What is **not** art — generated per character, no drawing needed

State these when commissioning so nobody draws them.

| Thing | Where it lives | Notes |
|---|---|---|
| **Dash signature** | `data/characters/dash_effects/<id>.tres` | One of six procedural shapes: `RIBBON`, `BLADE_ARC`, `TWIN_ARC`, `DUST_WAKE`, `RUNE_WAKE`, `SOUL_FLARE`, plus a tint, spark count and ribbon width. Drawn with `Line2D` and particles at runtime |
| **Dash trail and dash particles** | The rig | Reuses shared star/streak textures |
| **Portrait** (HUD and Shop card thumbnail) | `FormData.texture` | The packer writes `<id>_portrait.png` from the pack's `idle_hover_00.png`. No separate portrait art |
| **Tier** | `FormData.tier` | `STANDARD` / `LEGENDARY` / `MYTHIC` — drives the card frame, not the art |
| **Price, flavour text, display name** | `data/forms/<id>.tres` | |

---

## 8. Naming and delivery

```
<id>/
  dash_loop_00.png … dash_loop_03.png      # one of these is the contact frame
  wall_bottom_00.png … _07.png
  wall_top_00.png … _07.png
  wall_left_00.png … _07.png               # wall_right mirrored unless stated
  idle_hover_00.png                        # the portrait only — not an animation
  storefront/
    storefront_idle_00.png … _11.png
  ornaments/
    <six to eight loose pieces>.png
```

Deliver into `concept_art/<pack>/` — **never** directly into `assets/art/`. A deterministic pass in
`tools/art/extract_playable_characters.py` (`SHEET_PACKS`) packs them into the runtime sheets and
measures each one into `data/characters/<id>_frames.tres`. Never hand-edit `assets/art/` or a
`.import` file; re-run the extractor.

A pack may deliver more than the five — the three shipped characters' packs still carry all
sixteen original animations — but only what the `sheets` list names is packed, and only what is
packed costs anything.

---

## 8b. Sheets — one row per animation, two sheets per character

The frames ship as **sprite sheets** in the classic layout: a fixed grid, **one row per animation**,
each row as long as that animation needs, ragged right edge. The grid does the registration for
free — a cell's centre *is* the anchor, so a loop cannot drift.

Vulkan's guaranteed minimum texture size is **4096 × 4096** and plenty of Android devices report
exactly that, so no sheet may exceed it in either axis.

| Sheet | Cell | Rows | Frames | Size | Loaded |
|---|---|---|---:|---|---|
| `<id>_run.png` | 384 × 384 | `dash_loop`, `wall_bottom`, `wall_top`, `wall_left` | 28 | 3200 × 1600 | during a run |
| `<id>_menu.png` | 448 × 448 | `storefront_idle` (2 rows of 6) | 12 | 2784 × 928 | on Home and in the Shop |

The split is not arbitrary — it is exactly the split the memory budget needs (§8c). Each sheet is a
unit that gets loaded and dropped together. It was three sheets until the animation set was cut on
2026-09-20 and the reaction sheet had nothing left on it.

**Generate per frame; pack with the tool.** The art pass delivers individual numbered PNGs as §8
lays out, and `extract_playable_characters.py` packs them onto the grid. This is not extra work, it
is the only version that survives contact:

- No image model produces 40 mutually consistent frames inside one 3200 px canvas. Frames come out
  consistent one at a time, against a fixed reference.
- A frame that comes out wrong is re-rolled on its own, not by regenerating a whole sheet.
- Packing is where the anchor gets **measured** rather than trusted. The packer centres each frame's
  content on the cell and writes the residual into `data/characters/<id>_frames.tres`; a non-zero
  residual is the registration check failing, and it fails loudly instead of shipping as jitter.
- The cell size stops being an art decision. Raising 384 to 512 later is a re-pack, not a
  re-commission.

## 8c. The Shop is the memory constraint, not the download

`ShopScreen` keeps the focused card and its two neighbours live (`LIVE_CARD_RADIUS = 1`) and shows
the static portrait on the rest. A texture costs its full uncompressed size in VRAM whatever it cost
on disk, so what matters is which sheets are resident:

| | Per character | In practice |
|---|---:|---:|
| `<id>_run.png`, 3200 × 1600 RGBA | **~20 MB** | 20 MB — the equipped character, in a run |
| `<id>_menu.png`, 2784 × 928 RGBA | **~10 MB** | ~30 MB — three live Shop cards |
| Both | ~30 MB | never: nothing holds both |

The two engine changes this budget needed are both done: the frame sets are split into a menu
resource and a gameplay resource (`WholeFrameCharacterVisual` loads one on demand, and the tests
assert a run never holds the menu sheet), and the Shop builds cards lazily. Before the animation cut
the same layout came to 107 MB per character and 330 MB for a Shop full of cards.

## 9. Budget — measured

Per frame at the shipped 384 cell: ~195 KB as source PNG in the repo, ~155 KB as a lossless
imported texture, ~42 KB lossy. At 40 frames per character that is ~6 MB lossless or ~1.7 MB lossy
of shipped texture; seven characters, ~42 MB against ~12 MB.

- **The sheets currently import lossless** (`compress/mode=0`). Lossy import is an import setting on
  our side — the art is always delivered as lossless PNG and the repo keeps it that way. It cuts the
  APK, not the VRAM: a texture is full RGBA once it is on the GPU either way.
- **Cell size and frame count are the only VRAM levers**, and the animation cut was the big one.
- **Cropping is not a lever.** The frames already use 93–96% of their canvas.

If the budget has to shrink further, the order is: the wall loops from 8 frames to 6 → the dash from
4 to 3. **Never** cut a wall loop entirely or `storefront_idle` — those are what the player actually
looks at.

---

## 10. Order form

Copy per character:

```
Character:            <name>
Id:                   <id>
Tier:                 STANDARD | LEGENDARY | MYTHIC
Gameplay frames:      delivered 512 x 512   (packed at 384; see §2)
Menu frames:          delivered 724 x 724   (packed at 448)
Anchor:               hips at (<x>, <y>) in EVERY frame of the set
Delivery:             individual numbered PNGs - the packer builds the sheets (§8b)

Animations, and only these five:
  dash_loop          4 frames, loops, one of them the contact frame, facing canvas +Y
  wall_bottom        8 frames, loops, drawn upright in screen space
  wall_top           8 frames, loops, drawn upright in screen space
  wall_left          8 frames, loops, drawn upright in screen space
  storefront_idle   12 frames, loops, on the menu canvas
  idle_hover_00      1 frame, the portrait only

wall_right mirrored:  yes | no    (no = 8 more frames)
Dash signature:       RIBBON | BLADE_ARC | TWIN_ARC | DUST_WAKE | RUNE_WAKE | SOUL_FLARE
Dash tint:            <colour>    (kept clear of the reserved telegraph hues)
Ornaments:            <six to eight pieces of their costume>
Do not draw:          aim_charge, dash_start, dash_end, attack, move_fly, hit_reaction,
                      death, revive_spawn, victory, storefront_flourish, storefront_unlock
```
