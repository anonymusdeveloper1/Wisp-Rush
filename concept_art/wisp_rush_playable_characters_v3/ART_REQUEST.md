# Art request v3 — fully separated rig parts for Ilyra, then Bram

> **From:** Claude Code (implementing the rigs) · **To:** Codex (generating the art)
> **Order:** Ilyra's parts first. I implement and the owner tests her. Only then Bram's parts.
> **Identity is locked.** `concept_art/wisp_rush_playable_characters_v2/references/ilyra_concept.png`
> and `bram_concept.png` are the approved designs. Do not redesign, restyle, recolour or
> re-proportion anything. This request is only about *cutting them into riggable pieces*.

## 1. Why this request exists

Ilyra shipped as a rig on 2026-09-18 from the v2 approval sheet's separated-components row. That row
was drawn to show a reviewer the parts, not to drive a skeleton, so the rig inherited three hard
limits. On the owner's phone she read as a still pose, and no amount of tuning fixes the cause:

| Limit today | What it costs |
|---|---|
| Arms exist only as one painted piece per arm, split with a crop box at the elbow cuff | The cut edge is a straight line, so a bent elbow shows a seam. Shoulders and wrists cannot rotate at all, and there are no hands to pose — her four arms can only swing as rigid planks. |
| No isolated torso anywhere on the sheet | The torso is cut out of the front turnaround with a mask polygon. The chest and waist are one piece, so she cannot twist, and the silhouette is frozen at the pose she was painted in. |
| The fan is one flat painting plus a separate "closed" painting | Folding is a cross-fade between two images, not a fan closing. Ribs cannot counter-rotate and the membrane cannot collapse. |

With properly separated parts I can build a real `Bone2D` skeleton: shoulder → elbow → wrist chains
on all four arms, a waist that twists against the chest, fans whose ribs rotate about the handle, and
knees and ankles that bend on a landing. That is what makes a Mythic character feel alive at the
~130 px she occupies during a run.

**Nothing here changes gameplay.** Every part stays presentation-only: collision, health, dash,
damage, scoring, controls and camera are identical for every character.

## 2. Global technical rules (both characters — read before generating anything)

These matter more than the art itself. A beautiful part that breaks a rule is unusable.

1. **One PNG per part.** No grid sheets, no atlases. The filename *is* the contract (§4, §6).
2. **Transparent RGBA, straight alpha.** No background, no matte colour, no checkerboard, no dark
   fringe. Pixels that are not the part must be alpha 0.
3. **One consistent scale.** Every part of a character is drawn from the same character at the same
   size, so compositing them reproduces the approved front view exactly. Do not scale parts to fill
   their canvas.
4. **Neutral orientation.** Limbs, braids, sashes and skirt panels are drawn **vertical, attachment
   end at the top, centred horizontally**. Not posed, not foreshortened, not curled. A rotated or
   curled part cannot be aimed by a bone.
5. **Round joint caps and overlap.** Where a part meets another, its end must be a **full rounded
   cap**, and it must extend far enough past the joint that the parent still covers it at ±60°. A
   straight-cut end shows a gap the moment the joint bends. This is the single most common failure.
6. **No borrowed pixels.** A part must never contain any of a neighbouring part, and must carry no
   shadow cast *by* another part — those shadows break as soon as the joint moves. Flat, even front
   lighting; keep the painted form shading that is inside the part itself.
7. **Tight crop plus 8 px transparent padding** on every side.
8. **Glow stays with its own part.** The soft cyan bloom around a gem or blade belongs in that part's
   PNG, faded to alpha 0 — never clipped at the canvas edge.
9. **Readable at 64 px.** She is ~130 px tall in a run. Fine filigree that vanishes at that size is
   wasted; keep shapes bold and the silhouette clear.

### 2.1 The manifest — the highest-value thing you can give me

Alongside the parts, write **`parts/<id>/manifest.json`**. It removes all guesswork from rigging and
is worth more to me than extra polish on the art:

```json
{
  "character": "ilyra",
  "canvas": { "reference_height_px": 1024 },
  "parts": {
    "arm_upper_ul": {
      "file": "arm_upper_ul.png",
      "pivot": [34, 12],
      "tip": [36, 118],
      "rest_position": [-42, -112],
      "rest_rotation_deg": 123.0,
      "draw_order": 40,
      "parent": "torso_chest"
    }
  }
}
```

- `pivot` — the joint this part rotates about, in **that PNG's own pixels**.
- `tip` — where the *next* part down the chain attaches, same pixel space. Omit for leaf parts.
- `rest_position` — where `pivot` sits in the assembled neutral pose, in pixels **relative to the
  character's collision centre**, with **+X right and +Y down**. This is the frame the game rig uses.
- `rest_rotation_deg` — the part's rotation in that neutral pose, 0° meaning "as drawn" (pointing
  down/+Y), positive clockwise.
- `draw_order` — back to front, any increasing integers.
- `parent` — the part it hangs from, or `null` for a root.

### 2.2 Assembly reference

Also render **`assembly/<id>_assembly_reference.png`**: every part composited at its manifest
position into the neutral front pose, on transparent. I diff my assembled rig against it to prove
registration is right before animating anything.

---

## 3. ILYRA — the Astral Dancer (Mythic) · generate these first

Approved design: `../wisp_rush_playable_characters_v2/references/ilyra_concept.png`.
Four connected arms, exactly two legs, twin folding crescent fans, twin articulated braids, six skirt
panels, four waist sashes, three floating crown pieces, a cyan heart core. Luminous dusky-lavender
skin, pearl-white hair, deep-teal/indigo/aurora-violet cloth, restrained antique gold.

Her Mythic value is **coordinated motion**, so the part list below is organised by the animation each
part unlocks. The game drives thirteen states; the ones that need new geometry are called out.

### 3.1 Head and face — makes her feel awake

Four full-head variants at **identical registration** (same canvas, same pivot), so I can cross-fade
between them. Each is head + ears + earrings + front hair + a short neck stub. **No crown, no braids,
no collar, no shoulders.**

| File | Expression | Drives |
|---|---|---|
| `head_neutral.png` | eyes open, faint smile | `idle_hover`, `move_fly` |
| `head_blink.png` | eyes closed, same mouth | random blinks during idle — this alone reads as "alive" |
| `head_focused.png` | eyes narrowed, brow set, mouth firm | `aim_charge`, `dash_start`, `dash_loop` |
| `head_joy.png` | eyes happily closed, open smile | `victory`, `character_selected`, `character_unlocked` |
| `head_pain.png` | eyes shut tight, wince | `hit_reaction`, `death` |

Plus `hair_back.png` — the mass of hair behind her head, **without** the braids, vertical, root at top.

### 3.2 Torso — lets a dancer actually dance

| File | Notes |
|---|---|
| `torso_chest.png` | Collar and chest down to the waist seam. **No arms, no shoulders, no head, no skirt.** The heart-core setting is present but **unlit / dark** — the glow is its own layer. Bottom edge is a rounded cap that the hips stay under. |
| `torso_hips.png` | Waist seam to the top of the thighs, with a rounded top cap. Separate so the waist can counter-rotate against the chest — that twist is most of what makes her read as a dancer rather than a doll. |
| `shoulder_ornament_l.png`, `shoulder_ornament_r.png` | The armoured shoulder caps, alone. They ride on the chest and hide the shoulder joints through the full arm range. |

### 3.3 The four arms — the headline fix

She has four arms: **upper-left, upper-right, lower-left, lower-right** (`ul`, `ur`, `ll`, `lr`).
The upper pair carries the fans; the lower pair dances free.

For **each of the four**, three pieces, each vertical with the attachment at the top:

| File pattern | Span | Both ends |
|---|---|---|
| `arm_upper_<pos>.png` | shoulder → elbow | rounded caps both ends |
| `arm_fore_<pos>.png` | elbow → wrist | rounded caps both ends |
| `arm_wrist_<pos>.png` | the gold cuff/bangle alone | covers the wrist seam |

→ 12 files: `arm_upper_ul`, `arm_fore_ul`, `arm_wrist_ul`, … `arm_wrist_lr`.

Draw the left-side and right-side pieces as **true mirrors of each other**, not one piece reused —
the gold banding on her arms is asymmetric and a flipped copy reads wrong on the Shop card.

**Hands** — separate, so gestures change per state. Six files:

| File | Pose | Drives |
|---|---|---|
| `hand_open_l.png`, `hand_open_r.png` | fingers spread, palm forward | `idle_hover`, `victory`, `character_unlocked` |
| `hand_grip_l.png`, `hand_grip_r.png` | closed around a fan handle | the upper pair, always |
| `hand_cup_l.png`, `hand_cup_r.png` | cupped, fingers together | `aim_charge` — the lower hands gather round the heart while the arrow is up |

### 3.4 The fans — a fan that actually folds

Today a fold is a cross-fade between two paintings. Give me the fan in pieces and it becomes a real
mechanism: the ribs rotate about the handle and the membrane collapses with them.

| File | Notes |
|---|---|
| `fan_handle.png` | The gold handle and rivet. The rivet centre is the pivot every rib shares. |
| `fan_rib_a.png` … `fan_rib_e.png` | **Five separate ribs**, each a single thin gold spine drawn **vertical, pointing up, rivet end at the bottom**. Identical length; they differ only by the ornament at the tip if the design has one. |
| `fan_membrane.png` | The translucent cyan-violet cloth **alone**, no ribs, spread to its full open arc. Its lower point sits on the rivet. |
| `fan_membrane_lit.png` | Same shape, brighter — cross-faded in for `attack` and `character_unlocked` so a slash flares. |

One set is enough; her two fans are the same object mirrored.

### 3.5 Legs — so a landing has weight

`dash_end` is a feet-first wall brace. Knees and ankles have to bend or she lands like a statue.

| File pattern | Span |
|---|---|
| `leg_thigh_l.png`, `leg_thigh_r.png` | hip → knee, rounded caps |
| `leg_shin_l.png`, `leg_shin_r.png` | knee → ankle, rounded caps |
| `boot_l.png`, `boot_r.png` | the armoured ankle boot, alone |

### 3.6 Trailing cloth and hair — already works, just needs clean geometry

These become skinned `Polygon2D` ribbons on their own bone chains, so they must be drawn **straight
and vertical, root at the top, untapered by perspective**. A curled painting bends wrongly.

| Files | Count | Notes |
|---|---|---|
| `braid_l.png`, `braid_r.png` | 2 | Full length, from the tie at the top to the tuft at the tip. **Without** the back-hair mass — that is `hair_back.png` now. |
| `skirt_panel_1.png` … `skirt_panel_6.png` | 6 | Each panel alone, hanging straight down, attachment edge across the top. Keep the six genuinely different, as the concept has them. |
| `sash_1.png` … `sash_4.png` | 4 | The waist ribbons, straight down, clasp at the top. |

### 3.7 Crown and core

| File | Notes |
|---|---|
| `crown_star.png` | The large four-point star, alone. |
| `crown_shard_l.png`, `crown_shard_r.png` | The two smaller diamonds, alone, as a mirrored pair. |
| `heart_core.png` | The cyan gem alone, with its gold setting, on transparent. |
| `heart_glow.png` | A soft radial cyan bloom, no gem, fading to alpha 0 at the edge. Additive; I scale and brighten it for the charge and the Mythic unlock. |

### 3.8 Particles and effects — "alive" is mostly this

The owner explicitly asked for particles around her. Small, clean, **single-colour-ramp-friendly**
shapes on transparent — I tint and animate them, so paint them near-white with soft edges.

| File | Shape | Used for |
|---|---|---|
| `vfx_star.png` | four-point star, ~64 px | ambient soul motes trailing her |
| `vfx_mote.png` | soft round dot, ~32 px | fine dust around the fans at rest |
| `vfx_petal.png` | small tapered shard, ~48 px | dash spray |
| `vfx_fan_arc.png` | crescent slash, thick in the middle, tapering to nothing at both tips, ~256×96 | the `attack` cross-slash |
| `vfx_ring.png` | thin circle, soft inner edge, ~256 | `aim_charge` — a ring that contracts into the heart while the arrow is up |
| `vfx_bloom.png` | soft radial flare, ~256 | `revive_spawn` and `character_unlocked` |
| `vfx_streak.png` | motion streak, sharp head, soft tail, ~192×48 | `dash_loop` |

**Budget:** her rig may show at most **28 live particles**, and the automated test fails the build
above 40 for the whole rig. Paint these to read at 2–6 px on screen.

### 3.9 Ilyra file count

5 heads + 1 hair_back + 2 torso + 2 shoulders + 12 arm segments + 6 hands + 8 fan + 6 leg + 2 braid
+ 6 skirt + 4 sash + 3 crown + 2 core + 7 vfx = **66 PNGs** plus `manifest.json` and the assembly
reference.

---

## 4. BRAM — the Rift Knight (Legendary) · only after Ilyra is tested

Approved design: `../wisp_rush_playable_characters_v2/references/bram_concept.png`.

**Bram must stay visibly simpler than Ilyra.** His quality comes from weight, anticipation and clean
timing, not from part count. Do not add orbiters, extra limbs or constant effects. Same global rules
(§2), same manifest (§2.1), same assembly reference (§2.2).

| Group | Files | Notes |
|---|---|---|
| Head | `helmet.png` (no visor light), `visor_glow.png` (the cyan slits alone, additive, soft falloff), `helmet_crest.png` | Two helmet variants are not needed; the visor carries all the expression. |
| Torso | `torso_chest.png`, `torso_hips.png`, `chest_core.png` (gem alone), `core_glow.png` (soft bloom) | Chest socket unlit, like Ilyra's. |
| Shoulders | `pauldron_l.png`, `pauldron_r.png` | Cover the shoulder joints through the full range. |
| Arms ×2 | `arm_upper_l/r.png`, `arm_fore_l/r.png` | Rounded caps; true mirrors. |
| Hands | `hand_fist_l/r.png`, `hand_grip_l/r.png` | Grip holds the sword hilt; fist is the shield side. |
| Shield | `shield_face.png`, `shield_rim.png`, `shield_gem.png` | Splitting rim and face lets the plate catch light as it turns. |
| Blade | `blade.png` (steel alone), `blade_glow.png` (the cyan bloom alone, additive), `hilt.png` | |
| Legs ×2 | `leg_thigh_l/r.png`, `leg_shin_l/r.png`, `boot_l/r.png` | Knees and ankles bend on the two-boot landing. |
| Cape | `cape_l.png`, `cape_r.png` | Straight down, attachment across the top — spring-driven panels, not skinned ribbons. |
| VFX | `vfx_blade_arc.png` (one narrow crescent), `vfx_shield_spark.png` (small burst), `vfx_dash_streak.png`, `vfx_mote.png`, `vfx_impact_ring.png` | **Cap 16 live particles.** Keep him restrained. |

**≈ 32 PNGs** — deliberately about half of Ilyra's, and that gap should be visible in the Shop.

---

## 5. Where to put everything

Create this under the repo root. `concept_art/` is `.gdignore`'d, so nothing here ships — the game
only ever loads the layers my extractor writes from it.

```text
concept_art/wisp_rush_playable_characters_v3/
├── README.md                     ← status, what changed from v2, and why v3 exists
├── GENERATION_PROMPTS.md         ← the exact prompts you used, per part group (provenance)
├── ART_REQUEST.md                ← this file; leave it in place
├── references/
│   ├── ilyra_concept.png         ← copy of the approved v2 sheet, unchanged (identity lock)
│   └── bram_concept.png          ← copy of the approved v2 sheet, unchanged
├── parts/
│   ├── ilyra/
│   │   ├── manifest.json
│   │   ├── head_neutral.png … vfx_streak.png      (66 files, §3)
│   │   └── …
│   └── bram/
│       ├── manifest.json
│       └── …                                      (32 files, §4)
└── assembly/
    ├── ilyra_assembly_reference.png
    └── bram_assembly_reference.png
```

Also add one row per new folder to `docs/ASSETS.md` (source, how generated, licence status, notes),
following the rows the v1 and v2 packs already have.

## 6. Naming rules

- Lower snake_case, exactly the names in §3 and §4 — I key the extractor off them.
- Side suffixes `_l` / `_r` are **the character's own left and right**, not the viewer's.
- Arm position suffixes are `_ul` `_ur` `_ll` `_lr` (upper/lower × left/right), her own sides again.
- No spaces, no capitals, no version suffixes, no `_final`, `_v2`, `_new`.

## 7. Acceptance checks before you hand it over

Please run these yourself — each one has bitten this pipeline before:

1. **Alpha is clean.** Composite every part over magenta. No grey halo, no dark fringe, no clipped
   glow, no stray speck. (Scattered specks between parts is exactly what the v1 sheets suffered from.)
2. **Registration is right.** `assembly_reference.png`, built purely from the manifest, reproduces the
   approved front view — same proportions, nothing floating, no gaps at the joints.
3. **Joints survive rotation.** Rotate each `arm_fore_*` about its `pivot` by ±60° over its parent and
   confirm no gap or corner appears. Same for the knees.
4. **Nothing is borrowed.** No part contains another part's pixels, and no cast shadows from
   neighbours are baked in.
5. **One scale.** No part was resized to fill its canvas.
6. **Identity is intact.** Side by side with `ilyra_concept.png` / `bram_concept.png`: same face,
   same limb count, same costume, same palette. Four arms and two legs for Ilyra, in every piece.
7. **64 px test.** The assembly reference downscaled to 64 px tall is still unmistakably her.

## 8. Order of work

1. **Ilyra's parts only.** Hand over `parts/ilyra/` + manifest + assembly reference.
2. I rebuild her as a `Bone2D` rig — shoulder/elbow/wrist chains on all four arms, a twisting waist,
   folding fans, bending knees, blinks and expression changes, and the particle work — then verify
   against the existing gate (13 states, no snaps, Reduced Motion, Shop/Home/GameWorld, phone build).
3. **The owner tests her on the phone and signs off.**
4. **Only then** generate `parts/bram/`.

If anything in §3 is impossible or would force a redesign, stop and say which part and why, rather
than substituting something close — a part that silently changes her identity costs more than a
missing one.
