# Making a playable character — the AutoSprite recipe

> How every new playable character is made, end to end: what to generate, how it is packed, which
> states it shows, and which shaders and effects give it its own look. **Patchvile** (2026-09-23/24)
> is the worked example; every number here is his unless it says otherwise.
>
> It replaced the Codex per-frame contract (deleted 2026-09-25 with the characters made to it). What
> the rig does with the frames is [playable_character_visuals.md](../systems/playable_character_visuals.md).
> Owner decisions behind it: GDD §14 #34 (whole-frame sprites, no new rigs), #36 (a small animation
> set), #40 (the one-shot dash attack), and the 2026-09-24 DEVLOG entries.

---

## 1. What a character is

A playable character is **cosmetic**: its art, its dash look and its landing. Speed, hitbox,
timing, damage and scoring are the same for everyone (GDD §9). It is a
[`WholeFrameCharacterVisual`](../../scenes/player/visuals/whole_frame_character_visual.gd) — one
`AnimatedSprite2D` playing packed sprite sheets — plus data (`FormData`, `DashEffectData`) and a few
per-character effects.

## 2. The states and what the player sees

The controller speaks thirteen states; a drawn character has **five animations** and resolves every
state onto one of them (`WholeFrameCharacterVisual._target_animation()`).

| Animation | Plays for | Looks like | Loop |
|---|---|---|---|
| `storefront_idle` | Home and the Shop card (every menu state) | Front view: breathing, cloth moving, one flourish (Patchvile flips his dagger), back to the start pose | loops |
| `dash_loop` | `dash_start`, `dash_loop`, `attack` — the launch, the flight and a kill | **One attack**: flight pose → windup → slash → follow-through, held until the wall (owner, #40). Restarts on every dash and every mid-dash redirect | **one-shot** |
| `wall_bottom` | resting on the floor | Crouched, ready to strike, breathing | loops |
| `wall_top` | resting on the ceiling | **The floor animation flipped upside down**, head down (owner, 2026-09-23) | loops |
| `wall_left` / right | resting on a side wall | One hand and both feet on the wall, weapon hand free. The left wall is the generated right wall mirrored; the game mirrors it back on the right wall, so the right wall shows the art as generated | loops |

Everything else is carried by the controller, not by art: the aim shows only the arrow (the character
keeps doing what it was doing), a hit is the blink and the reset, a death is the alpha dissolve, the
landing *is* the wall animation arriving. The engine also adds squash on state changes, the heading
turn and the fade — never paint those into frames.

**Reduced Motion** holds frame 0 of each animation (the dash holds its contact frame) and drops the
flash, the slash and the afterimages.

## 3. What to generate in AutoSprite — four sheets

| # | Animation | First frame | Last frame | Frames |
|---|---|---|---|---|
| 1 | `storefront_idle` | **Upload** a front-view image of the character (AutoSprite's default is side view; Prompt Helper **off**) | — | 25 |
| 2 | `wall_bottom` | generate or upload the floor crouch | — | 25 |
| 3 | `wall_right` | generate or upload the right-wall cling | — | 25 |
| 4 | the dash attack | **Upload a flight pose with no wall in it** (Patchvile: a clean held lunge from an earlier sheet, padded so a wide slash fits) | **the end of the attack**, a pose of its own (rule A2 below, from 2026-09-27); Patchvile, Shade, Mothmere and Scarlet used the same image as the first | 25 (8 are kept) |

`wall_top` and `wall_left` are **not generated**: the packer flips the floor and mirrors the right
wall. Four generations instead of six. A character may have its own ceiling sheet instead of the
flipped floor when the owner decides so (Shade; Rook, GDD §14 #55).

**Drawn exactly like Patchvile** (owner, 2026-09-25; ADR-0018 addendum). The four first frames are
the character at AutoSprite's frame resolution, looking the way Patchvile's own frames look:
- **256 × 256** art (one AutoSprite frame), delivered as **1024 × 1024** scaled up 4× with nearest
  neighbour, so every art pixel is a 4 × 4 block (Patchvile's dash uploads were his 256 px frames
  enlarged 2× nearest);
- **no outline**: the character's own colours meet the background, as on Patchvile;
- **up to 256 colours, soft edges allowed**, as AutoSprite exports a frame (a 256-entry paletted
  PNG: Patchvile's frames use ~255 entries and ~63 transparency levels); no blur;
- a transparent background;
- **the roster size: every character has Patchvile's pixel count** (owner, 2026-09-24). Standing,
  the whole figure is **194 px tall in the 256 px frame (76 %)**, measured from its highest point
  (hood, hair, crown) to its feet. On the 1024 px first frame Codex delivers, that is **776 px**.
  Every other pose is drawn at the same scale (the same head size), so a crouch or a cling is shorter
  and a flight pose is as long as the body. Patchvile's frames measure 194 standing, 186 crouched on
  the floor and 187 on the wall. **Every character is the same size in the game, the Shop and
  everywhere** (owner, 2026-09-26: a same-day change that let heights differ was reverted, GDD §14
  #54). Scarlet's sheets were made with her standing 166 px, so her scene draws her 1.16× larger (`art_scale` 1.38, `menu_art_scale` 1.45) and she is the same size as everyone on screen; her pixels are 16 % larger than Patchvile's.

**Why this is enough.** AutoSprite keeps the uploaded first frame's proportions exactly: Patchvile's
dash upload filled 77.2 % of its width and AutoSprite's frame 77.3 %. So whatever share of the canvas
the first frame gives the character is the share it keeps in every AutoSprite frame, and the packer
then packs every character at Patchvile's scale (§4). Same pixel count, same size and same level of
detail on screen.

An image model's pixels come out uneven and its size only roughly right, so a generated or painted
image is converted before it is uploaded: reduced to 256 at the roster scale (area
resampling), quantized to 256 colours with its soft edges kept, no outline added, scaled up 4×
nearest. Shade's converter is the worked example: `concept_art/verdant_shade_autosprite_v1/build_first_frames.py`.
When Codex draws the poses at different scales, each pose is scaled so the head matches the
storefront's and keeps its own height (a crouch stays shorter). Scarlet's were (owner, 2026-09-26):
right wall ×1.22 and dash ×1.38, measured on her crown, eyes and earrings; her fan then differs in
size between poses, which the owner accepted. Her converter:
`concept_art/scarlet_autosprite_v1/build_first_frames.py`.
Every AutoSprite prompt ends with "Pixel art matching the reference: the same pixel size and
palette in every frame, crisp pixels, no blur, no anti-aliasing." Shade's brief is the template for
the AutoSprite prompts: `concept_art/verdant_shade_autosprite_v1/PROMPTS.md`.

**The Codex prompt for the four first frames** (given to the owner on 2026-09-25). Paste it with the
character's reference image or description; nothing in it needs filling in. Whatever Codex returns
is still converted (above) before it goes to AutoSprite. The "no outline" line is Patchvile's rule;
Mothmere is the one character who keeps an outline (owner, GDD §14 #49).

```text
Create the four AutoSprite first frames for a new playable character in Wisp Rush, a 2D pixel-art mobile game. Use the character I give you (reference image or description) and keep its design exactly.

Deliver four separate PNG files:
1. storefront.png - front view, standing, facing the viewer in a calm idle pose, whole body visible.
2. wall_bottom.png - crouched low on the floor, knees bent, ready to strike.
3. wall_right.png - clinging to a wall on the right side of the image (do not draw the wall): the free hand pressed flat against it and both feet against it, the weapon hand away from the wall, the body upright.
4. dash_attack.png - side view, flying fast toward the left, body stretched out, the weapon held forward. No wall, no floor.

Rules for every image:
- Canvas 1024 x 1024 px with a transparent background (real transparency, not a checkerboard or white).
- Pixel art: the art is 256 x 256 pixels scaled up 4x with nearest neighbour, so every art pixel is an exact 4 x 4 block on one grid. No anti-aliasing, no blur, no gradients, no glow haze, nothing painterly or 3D.
- No outline: the character's own colours meet the transparent background.
- At most 256 colours.
- Size: in storefront.png the character is exactly 776 px tall, from its highest point (hood, hair, horns or hat) to the bottom of its feet. The other three images use exactly the same scale (same head size, same pixel size), so the crouch and the wall cling are shorter and the flight is as long as the body.
- Leave at least 60 px of empty space on every side; in the dash, leave room in front of the character for a weapon swing.
- The same character in all four: same proportions, colours, costume and details. The weapon stays in the same hand in every image, and asymmetric details stay on the same side. Do not mirror the character between images.
- No shadow, no floor, no background, no text, no border, and no separate effects around the character.
```

**Patchvile as the reference to attach.** His first AutoSprite frame of each state (`frames/storefront/storefront_idle_00.png`,
`wall_bottom_00.png`, `wall_right_00.png`, and the dash's flight frame `dash_loop_00.png` turned back a
quarter so it flies left), each scaled 4× nearest to 1024: exact 4 × 4 blocks, 776 px standing, at
least 104 px of margin, no outline. Add a line such as "Match these reference images exactly for
canvas, pixel size, character size and pose layout; draw my character, not this one." They are kept
in `concept_art/patchvile_autosprite_v1/codex_reference/` (`patchvile_storefront.png`,
`patchvile_wall_bottom.png`, `patchvile_wall_right.png`, `patchvile_dash_attack.png`; owner, 2026-09-26).

**Patchvile's pixel size, measured 2026-09-25.** In his AutoSprite frames one art pixel is **1 px of
the 256 px frame** (87 % of same-colour runs are 1 px; the edges are soft; there is no coarser
grid). His dash upload (`dash_attack_first_frame.png`, 640 px) is 2 × 2 blocks; a 1024 Codex first
frame is 4 × 4. In a run he is drawn at about **1.3 screen px per art pixel** (194 px standing → about
253 design px, measured headless on a 1920 × 1920 layout), a non-integer scale (§8).

**Settings for every sheet, identical across the whole roster** (so every character has the same
pixel size on screen): frame size **256**, a **5 × 5** sheet, the **same pixel-art filter** setting.
Background removal and the model tier follow the AutoSprite rules below (A1, A5). Loop closure is
automatic when the first and last frame match.

**Rules the prompts must carry** (they are what went wrong before):
- Repeat the full identity in every prompt: proportions ("about four heads tall, not chibi"), the
  asymmetric details (which eye glows, which hand holds the weapon) and "do not mirror him".
- **The weapon stays in the same hand in every sheet.** Scarlet is the exception: she switches her
  fan from hand to hand (owner, 2026-09-26).
- Wall poses **cling**: hand and feet on the wall, upright on screen, no jump.
- The dash attack is **in the air**: no wall, no landing, no travel across the frame, and "keep the
  whole body and the weapon's full arc inside the frame" (AutoSprite otherwise clips a wide slash at
  the 256 px cell).
- Static camera, plain background.

Prompt skeleton (Patchvile's prompts are in the 2026-09-23/24 conversation record and in
`concept_art/patchvile_autosprite_v1/`):

```text
<Name>, exactly as in the reference image: <identity: proportions, face, eyes and which one glows,
costume pieces, weapon and which hand>.
Pose / motion: <one state from §2, in plain words>. <What moves: breathing, cloth, eyes>. <What must
not move: feet and hands on the wall>. Static camera, no zoom, <he> does not move across the frame.
The last frame returns exactly to the first pose so it loops seamlessly. Do not mirror <him>.
Plain background.
```

### AutoSprite rules — prompts and settings (owner, 2026-09-27)

Written down at the owner's request so every agent makes AutoSprite animations the same way. Rules
A1–A9 come from AutoSprite's own documentation (checked 2026-09-27: [Animation Types](https://www.autosprite.io/docs/reference-animation-types),
[Custom Animations](https://www.autosprite.io/docs/guide-advanced-creation),
[Advanced Mode](https://www.autosprite.io/docs/guide-advanced-mode), [FAQ](https://www.autosprite.io/docs/faq));
B1–B6 are what this project measured and learned.

**From AutoSprite's documentation**
- **A1. Model tier.** AutoSprite: "Custom animations underperform on `turbo` and `pro`. If a complex
  action comes out wrong, switch to `ultra` (1–2s) or `max`." Use **ultra** (or max) for the dash
  attack and whenever a turbo sheet comes out wrong. Tiers at the time of writing: turbo 2 s, 5
  credits · pro 4/6 s, 10–15 · ultra 1–6 s, 10 per second · max 4/6 s, 35–53. Every loop of
  Patchvile, Shade, Mothmere and Scarlet was made on turbo.
- **A2. Last frame.** A loop uploads its first frame as the last frame too. A one-shot attack gets a
  **different last frame: the end of the attack** (AutoSprite: "For non-looping animations (attacks,
  jumps, one-shot actions), generate a distinct ending pose"). The game keeps only the attack and
  holds its last frame until the landing, so no recovery back to the flight pose is needed.
- **A3. Describe the motion, not the end state:** the direction, the body parts that move and how
  fast or hard ("Character swings sword from right shoulder to left hip", not "character attacks").
  The prompt says what happens between the first and the last frame; the uploaded first frame
  carries the character's look.
- **A4. One action per animation, no complex choreography.** For a sequence of beats, give AutoSprite
  the key poses instead: keyframes (opening pose, action beat, impact frame, ending pose) or storyboard
  mode (a list of beats, up to 9 reference images, a 4–10 s clip). The **Motion Library** (about 100
  built-in motions, or motion reused from our own characters) is, in AutoSprite's words, "the most
  reliable way to get complex motion right".
- **A5. Background removal: Ultra.** AutoSprite's fix for bad cutouts. A default cutout left grey and
  white in the enclosed gaps between Scarlet's fan ribs (2026-09-26).
- **A6. The humanoid toggle is off** for a four-legged or non-human character (Rook).
- **A7. Clip length.** Clips render at 24 fps. Loops: 4 s, or turbo's 2 s. A one-shot may use 6 s only
  with more frames (64 or MAX): "A longer clip at the same frame count looks choppier."
- **A8. Preview before exporting** and look for sliding feet, drifting props and unclear silhouettes.
- **A9. Prompt Helper.** AutoSprite recommends it for first frames AutoSprite *generates*; ours are
  uploaded, and it stays **off** (§3 table).

**Learned in this project**
- **B1. Breathing is the main motion of every loop**, stated first and clearly visible. Scarlet's first
  floor sheet (2026-09-26) rocked her fan from 0° to −32° and back while under 2 % of her body's
  pixels changed; stating breathing as the main motion and locking the fan fixed it.
- **B2. Everything else is small, and whatever must not move is named:** grips on a wall or ceiling,
  planted feet or claws, a prop held behind the body. AutoSprite otherwise animates a big loose prop
  instead of the body.
- **B3. The owner's prompt format:** CHARACTER / POSE / MOTION (numbered) / TIMING / DO NOT / STYLE, in
  depth, up to about 4,000 characters (AutoSprite's limit, owner). Worked examples:
  `concept_art/scarlet_autosprite_v1/PROMPTS.md` and Rook's prompts (2026-09-27).
- **B4. Loop wording that worked** (Shade's storefront): "a breathing idle, not an action"; "every
  movement returns to the starting pose: the last frame matches the first exactly". A whole number of
  breaths over the loop (Rook: two) ends where it started.
- **B5. Tone per animation:** the storefront is relaxed ("relaxed and at ease ... every movement slow
  and gentle", owner, 2026-09-27); the walls and the ceiling are alert and ready to attack, but not
  attacking.
- **B6. A character that keeps an outline** says "keep his thin dark outline exactly as in the
  reference" instead of "no outline" (Mothmere, Rook).

Untested idea, not a rule: a short prompt (one or two lines of identity plus the motion), since the
image already shows the character. Try it on one sheet before using it more widely.

## 4. From exports to the game

1. **Source pack** `concept_art/<id>_autosprite_v1/` (source-only, `.gdignore`d):
   - `raw/<state>_sheet.png` — the AutoSprite exports, **never edited**.
   - `slice_sheet.py` — cuts each sheet's 256 px cells into `frames/<state>_NN.png`
     (`frames/storefront/` for the menu), zeroes colour under alpha 0, and per sheet lists **which
     cells to keep** and **how far to turn them**. Walls keep 24 (the 25th repeats the first);
     the storefront keeps 25 (its tail is a deliberate still hold); the dash keeps 8 and turns them
     a quarter so the flight points **up** the frame (§6). The storefront's first cell is written
     as `frames/idle_hover_00.png`, the portrait.
   - `<id>_sprite_sheet.json` — one row per packed animation: `state`, `frames`, `fps`, `loop`.
2. **Packer entry** — `SHEET_PACKS["<id>"]` in `tools/art/extract_playable_characters.py`:

   | Key | Patchvile | Why |
   |---|---|---|
   | `derive` | `wall_top` ← `wall_bottom` flip_v · `wall_left` ← `wall_right` flip_h | the two sheets not generated |
   | `cells` | run **256**, dash **336**, menu 448 | frames are 256 px, so a 384 run cell only enlarged them — and 76 frames at 384 loaded in 85 ms, twice the others, and broke the smoothness test |
   | `sheets` | run: the three walls · dash: `dash_loop` · menu: `storefront_idle` | the dash's extended lunge is as wide as its frame; its own sheet gives it room |
   | `fit` / `fit_match` | 0.92 each · dash takes the run's pixel scale | one size across walls and dash; each animation centred on its own bounds |
   | `columns` | run 8, dash 8, menu 5 | every sheet ≤ 4096 px |
   | `particles` | four costume pieces → `<id>_scraps.png` | §5 |

   **Every character after Patchvile** uses the same `cells`, `columns` and `sheets` layout with
   `"roster_scale": True` instead of `fit` / `fit_match`. It is then packed at Patchvile's exact
   scale (`ROSTER_RUN_FACTOR` 1.253 cell px per source px for the run and dash sheets,
   `ROSTER_MENU_FACTOR` 1.848 for the menu), with each animation still centred on its own bounds.
   Packing Patchvile this way reproduces his sheets pixel for pixel. **The roster check** measures
   the first storefront frame: `ROSTER CHECK: <id> stands N px … ok`, a **warning** past ±5 % of
   194 px, and the pack is **refused** past ±10 %. Redraw the first frames at the roster size rather
   than scaling around it. Scarlet's pack is the one exception, `"standing": 166` (her sheets' size;
   her scene draws her 1.16× larger, §3).

   **Use the AutoSprite PNG exports.** Images pasted into a chat arrive as lossy WebP (Mothmere's
   pasted storefront differed from its PNG by 2.7 per channel on average), and a re-export can hold
   a different number of cells (Mothmere's right wall: 25 cells pasted, 23 in the PNG). A sheet can
   also be shorter than 5 × 5 (Mothmere's floor is 1280 × 1024, 18 cells); Mothmere's slicer takes
   whole 256 px rows. Mothmere's pack (`concept_art/mothmere_autosprite_v1/`) is the third worked
   example: its `PROMPTS.md` records the owner's motion descriptions and the prompts.
3. `python concept_art/<id>_autosprite_v1/slice_sheet.py` then
   `python tools/art/extract_playable_characters.py <id>` → `assets/art/characters/playable/<id>/`
   (`_run`, `_dash`, `_menu`, `_portrait`, `_scraps`) and `data/characters/<id>_{gameplay,menu,frames}.tres`.
   Never hand-edit those; re-run.
4. **Scene** `scenes/player/visuals/<id>_visual.gd` (`class_name`, `extends WholeFrameCharacterVisual`,
   nothing else) and `<id>_visual.tscn` — copy `patchvile_visual.tscn`: `MotionRoot` →
   `DashParticles`, `TrailParticles`, `Body` → `PoseSprite`, plus `AnimationPlayer` and
   `AnimationTree`, all unique names.
5. **Data**: `data/forms/<id>.tres` (`FormData`: id, name, description, price, portrait, the scene,
   the dash effect, `menu_frames_path`, tint; no tier, owner 2026-09-26) and `data/characters/dash_effects/<id>.tres`.
6. **Registration**: the form path in `data/forms/default_catalog.tres`,
   `FormCatalog.REQUIRED_FORM_COUNT`, `SaveManagerService.VALID_FORM_IDS`, and the character lists in
   `tools/godot/test_form_catalog.gd` (plus its price list) and `test_playable_character_visual.gd`.

## 5. The effects — each character its own

| Effect | What it is | Where it is set | Patchvile |
|---|---|---|---|
| **Attack outline** | A glow around the silhouette while dashing — `character_attack.gdshader` | `attack_glow` (alpha 0 = off) | cream |
| **Contact flash** | The frame pushed toward the glow on the contact frame and on a kill, peak 0.75 | `attack_contact_frame` | frame 4 (the slash) |
| **Afterimages** | Additive copies of the frame left along the flight, 8 pooled, pinned in world space | `afterimage_interval` / `_life` / `_alpha` | 0.03 s / 0.18 s / 0.45 |
| **Shader slash** | A crescent swept across the front of the flight on the contact frame (0.08 s sweep, gone by 0.26 s) — `character_slash.gdshader`, no art | `slash_edge` (alpha 0 = off), `slash_size`, `slash_forward` | bone white edged in muted cream |
| **Dash particles** | Pieces of the costume thrown back while dashing (normal blend, a random cell of the strip, tumbling) | `%DashParticles` in the scene + the packer's `particles` strip | button, patch, bandage, tassel |
| **Trail particles** | Soft motes behind the flight (additive radial dot) | `%TrailParticles` | cream motes |
| **Dash signature** | The ribbon and sparks along the path (`DashEffectFx`) | `DashEffectData.signature`, tints, `spark_count`, ribbon | `BLADE_ARC`, cream |
| **Shared cyan dash art** | The Wisp's launch streak, long streak and momentum glow — painted cyan, a tint cannot fix it | `DashEffectData.shared_trails` | **off** |
| **Landing** | `SPLASH` (the Wisp's, over cyan art) or `DUST`: the same splash in dust — grains, a splat along the wall, a puff | `DashEffectData.landing`, `dust_tint` | `DUST`, dusty beige |

Scarlet's are the same idea as Patchvile's scraps: her `%DashParticles` throw her reap crescent and
her `%TrailParticles` trail her crown diamond, pieces her slicer cuts from her own frames (the
packer's `particles` takes a list when each emitter has its own strip). A new character picks its
own pieces and colours; nothing is borrowed.

**Colour rule.** Amber (`Palette.WARNING_AMBER`) and magenta (`Palette.RIFT_MAGENTA`) mean danger.
Any dash or landing tint within 25° of those hues must stay at saturation ≤ 0.25
(`DashEffectData.validate()` checks it). Patchvile's golden painted slash flash is close — watch
that on the device.

**Particle budget:** at most 40 particles per character (the rig contract test).

## 6. Sizes, speeds and orientation

| What | Value | Note |
|---|---|---|
| Delivered frame | 256 px (5 × 5 sheet) | the same for every character |
| Standing height in that frame | **194 px** (76 %); 776 px on the 1024 first frame | the roster size (§3); checked by the packer (§4). Scarlet's sheets: 166 px, drawn 1.16× larger |
| Packing scale | 1.253 cell px per source px (run, dash) · 1.848 (menu) | Patchvile's, for everyone (`roster_scale`) |
| Run cell / `design_size` | 256 / 256 | the run cell and `design_size` must match; 336 / 336 when the walls do not fit a 256 px cell at the roster scale (Rook), with `art_scale` × 336/256 so the character stays everyone's size |
| Dash cell | 336 px at the walls' pixel scale | room for the lunge |
| Menu cell | 448 px | drawn at `design_size` / 448, so any run cell keeps the card size |
| On screen in a run | ~230 px × `art_scale` | Patchvile `art_scale` 1.1875 in a run, `menu_art_scale` 1.25 on Home/Shop |
| Walls / storefront | 12 fps (24 frames ≈ 2 s; 25 ≈ 2.1 s) | |
| Dash attack | 8 frames at 28 fps ≈ 0.29 s, slash at ~0.14 s | a dash lasts 0.2–0.35 s; the last frame holds to the wall |

**On Home's platform (owner, 2026-09-27).** Every character, new or redesigned, **stands centred on
Home's platform**: its feet on the centre of the platform's top and its body (head and torso, not a
tail or a prop) centred over it. Home puts the middle of the storefront animation's combined bounds at
a fixed point above the platform, so a character whose feet are not at the bottom of its frame (Rook's
tail blade hangs below his feet) floats above the platform, and one whose body is off the middle of its
frame leans off it. Fix it in the scene with `menu_offset` (design units; it moves the storefront on
Home and the Shop card, never the character in a run). In the 1080 × 1920 Home the platform's centre is
at (540, 1166), texel (470, 1015) of `home_background.png`. Rook: his feet were about 80 px above it,
so his `menu_offset` is (2.7, 62.5); his feet now land at y 1166 and his body's centre line at x 540.

**Dash orientation.** The rig turns a dash frame by the flight angle **+ 90°**, so the frame's **up**
is the flight direction (the base rig is "authored facing up"). Generate the attack flying left or
right; the slicer turns it so it flies up the frame. A side-drawn dash would fly upside down on half
the flights, so `dash_head_up` mirrors it on flights with a rightward component (the weapon hand and
the asymmetric eye swap on those — acceptable at dash speed, like the mirrored right wall).
A **symmetric** character may upload its dash upright instead (Shade), with no mirroring
(`dash_head_up` off). The slicer then turns it so the **face leads**: the frame's top is where it
flies. Shade's pose was drawn face down (the old Codex contract drew dashes facing +Y, §8), so its
dash is turned 180° (owner, 2026-09-25: "he has to attack with his face in front"). Check the
direction in a slowed run before calling a dash done.

**Canvas fill.** `fit` scales each sheet so the largest animation fills 92 % of its cell and centres
each animation on its own combined bounds; the loop keeps its registration because the transform is
constant across it.

## 7. Checking it

- The packer's `ROSTER CHECK` line says `ok` (the character stands 194 px ± 5 % in its frames).
- `tools/validate.sh` → `VALIDATE: OK`; `tools/run_tests.sh form_catalog`,
  `playable_character_visual`, and a character test like `test_patchvile_visual.gd` (one-shot dash,
  restart, hold, attack look, Reduced Motion).
- Home: `WISP_CHARACTER=<id> tools/screenshot.sh res://tools/godot/render_character_home_showcase.tscn 90 540x1170`
  — the character stands centred on the platform (§6): feet on its centre, body centred over it.
- Boards: `WISP_CHARACTER=<id> tools/screenshot.sh res://tools/godot/render_whole_frame_states.tscn 260 540x960`
  (every animation), and the gameplay fixture with `WISP_DASH="x,y"` for a dash in any direction.
- On the phone: the Windows APK commands in AGENTS.md §4. During look-and-feel iteration the owner
  tests there himself.

## 8. Known gaps

- The packer resamples bicubic, and the game draws a character at a non-integer scale with linear
  filtering, so AutoSprite's pixels are slightly softened on screen. It is the same for every
  character, so it does not change the equal level of detail.

- The menu sheet uses a 448 px cell for 256 px frames (upscaled, ~21 MB live); packing it at 256
  would cut that to ~7 MB with no visible difference.
- AutoSprite clips a wide slash at its 256 px frame; ask for the arc inside the frame.
- The old Codex contract drew a dash facing +Y (down); the rig's up is forward. Shade's dash pose came
  from it and had to be turned 180° (§6).
