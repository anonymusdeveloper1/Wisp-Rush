> **Superseded for new characters, 2026-09-20.** Playable characters are whole-frame sprites
> now — see [character_sprite_frames.md](character_sprite_frames.md). This recipe stays for the
> four rigs still in the game (Veyra, Rook, Morrow, Noxen). Ilyra and Bram, which much of it was
> written from, have been retired; their worked examples are still the clearest ones here.

# How to build an animated playable character

> **Recipe of record for adding a character to Wisp Rush.** What the system *is* lives in
> [systems/playable_character_visuals.md](../systems/playable_character_visuals.md); *why* it is
> built this way in [ADR-0015](../decisions/0015-animated-playable-characters.md). This file is the
> *how*: the steps, the bone and skinning mechanics, the numbers that worked, and the mistakes that
> cost time. Written 2026-09-18 after building Veyra, Rook and Morrow.
>
> Rule that outranks everything here: a character is **presentation only**. `WispPlayer` owns
> movement, collision, damage and scoring. If a change to a rig can alter gameplay, it is wrong.

## 0. What you need before you start

| Input | Where | Notes |
|---|---|---|
| Owner's concept art | `concept_art/wisp_rush_playable_characters_v1/references/<id>_concept.jpg` | Identity, palette, silhouette |
| A layer sheet | `concept_art/.../assets/<id>_rig_source.png` | A **transparent** sheet the extractor can cut cells from. v1 generated a purpose-built 4×3 grid; v2 derives one from the approved turnaround with `tools/art/make_rig_source.py` (below) |
| A name and tint | — | Display name, one-line description, a `Palette`-friendly tint |

The generated sheet is **source art**: it is never a runtime texture and never loaded by the game.
Ask for parts that a rig actually needs — a body without the head, each limb separately, one reusable
segment for a chain, one small particle — and for "left"/"right" to mean the character's own sides.

## 1. Extract the layers

**First, make the sheet transparent.** The extractor isolates parts by *alpha*, so an opaque approval
sheet has to be matted first. `tools/art/make_rig_source.py` does that without touching the reference:

```sh
python3 tools/art/make_rig_source.py <id>   # writes concept_art/<pack>/assets/<id>_rig_source.png
```

It has two modes. `matte` keeps a subject alpha the reference already carries (Ilyra's does — check
with Pillow before assuming it does not; a sheet that *looks* like it has a grey background may just
be a flattened preview of a matted PNG). `key` lifts the subject off near-black (Bram). Two numbers
matter for `key`: `key_floor` must stay **low** (12–16) or the charcoal inside the armour, which
reaches the border through the gaps between plates, is flood-filled away as background; and the alpha
ramp must start at `noise_floor` (the sheet's black level, ~8) rather than at zero, or the whole
background stays faintly opaque and the extractor reads it as one enormous painted component.

Then add the character to `CHARACTERS` in `tools/art/extract_playable_characters.py`: one entry per
part with a fixed crop box and a `min_area`. Point `SOURCE_SHEETS` at the pack (v1 characters keep
their original sheet, so their output stays byte-identical). Then:

```sh
python3 tools/art/extract_playable_characters.py <id>   # writes assets/art/characters/playable/<id>/
```

What the extractor does, and why: it crops fixed cells (the sheet is an approved artifact, not an
atlas), keeps only connected components ≥ `min_area` (drops the coloured speckles image generators
scatter between parts), grows the kept mask by a 31 px max filter so the **soft glow around a part
survives** while distant speckles do not, then trims to content with 8 px of padding.

**Parts the sheet never isolates.** A turnaround sheet's component row may be missing a group — Ilyra
has no separate torso anywhere. Add a polygon to `MASKS` (in sheet pixels) and the extractor cuts that
silhouette out of a pose before the usual cleanup; the painted pixels inside are untouched. Author the
polygon against a coordinate-grid render of the region, not by eye.

Check `logs/playable_characters/<id>_parts.png` before rigging: every part isolated, no fragments of
a neighbour, glow intact. Add a row to `docs/ASSETS.md`.

**Ribbon spines.** For any part that must *bend* (a tail, a scarf), list it in `RIBBONS` with a
rough root hint (fraction of the image where it attaches). The extractor walks geodesic distance
from that root through the alpha mask and takes the centroid of each distance band, which gives a
centre line that stays inside the paint even where the ribbon curls back on itself. It prints:

```
SPINE veyra/tail_b: PackedVector2Array(30, 29, 95, 63, 170, 92, 213, 157, 153, 240)
```

Paste that into the rig scene (step 3). The contact sheet draws the spine in yellow — look at it.

### 1b. Or skip all of that: a per-file part pack

A sheet only ever gives you what the generator happened to separate. Ilyra's v2 rig inherited straight
crop-box "elbows", a torso masked out of a turnaround and a fan that folded by cross-fading two
paintings — none of which can carry a Mythic character. Her v3 pack instead ships **one PNG per rig
group plus a `manifest.json`** giving each part a pivot, a tip, a rest transform and a draw order, and
that is the better shape for anything with real joints. Ask for it the way
`concept_art/wisp_rush_playable_characters_v3/ART_REQUEST.md` does.

With a pack there is nothing to cut:

```sh
python3 tools/art/extract_playable_characters.py <id>   # copies the parts, derives preview.png
python3 tools/art/build_character_rig.py <id>           # manifest -> <id>_visual.tscn
```

- The PNGs are copied **byte for byte**. The manifest's pivots are in each file's own pixel space, so
  trimming or re-padding them here silently moves every joint in the rig.
- `preview.png` (the HUD and card portrait) is derived from the pack's assembly reference, so the
  portrait can never drift from the rig.
- `build_character_rig.py` owns the arithmetic that is miserable by hand: absolute rest transforms
  into parent-relative ones, pivots into sprite offsets, draw order into `z_index` (tree order cannot
  express it — legs must sit behind a torso they hang from), a mirrored sub-tree flipped **once at its
  root**, and `design_size` / `preview_center` measured from the assembled silhouette.
- **The scene is generated.** Hand edits to `<id>_visual.tscn` are lost on the next run; everything
  per-character lives in `<id>_visual.gd`.
- Check the rig against `assembly/<id>_assembly_reference.png` before animating: the lineup fixture
  prints bounds, and they should match the reference's proportions exactly.

### 1c. Or not a rig at all: a whole-pose sprite pack

A character can also be one finished painting per state instead of parts on bones — that is what
Ilyra is (`scenes/player/visuals/ilyra_visual.*`). Add the pack to `POSE_PACKS` in
`extract_playable_characters.py` and run it: the approved PNGs are copied byte for byte and each
one's silhouette is measured into a `CharacterPoseSheet` the rig applies as a per-pose drawing
offset and scale. Then skip sections 2 to 8 — there are no bones, ribbons or springs — and go
straight to section 9.

What it buys and what it costs, after building both for the same character: a pose pack is a day's
work instead of a week's and the art is exactly what was approved, but the character can only ever
show the poses that were painted, has no follow-through of its own, and reads as a flip-book rather
than as motion at gameplay size. Two rules that are not obvious:

- **Anchor on the canvas, not on the silhouette.** A pose pack is painted from one camera, so the
  canvas centre already is the anchor. Centring each pose's opaque bounding box instead looks like
  the right normalisation and is not: that box moves with the pose — a crouch lowers the head while
  the feet stay put — so following it lifts a crouching character off the surface she crouches on.
  Correct only what is measured to be wrong (Ilyra: one pose painted at 0.84 inside extra padding).
- **Put the offset on the sprite, not on a node.** `AnimatedSprite2D.offset` is a drawing offset and
  is outside the node transform, so the smoothness contract keeps measuring real motion rather than
  the placement correction. A pose scale does have to go on the node, so ease it — a step of 0.19 in
  one frame is most of the contract's per-frame budget.

## 2. Plan the rig

Decide per part:

| Kind | Use | Node |
|---|---|---|
| Rigid cutout | Heads, hands, feet, single armour plates, anything that never bends | `Node2D` pivot → `Sprite2D` child |
| Bending ribbon | Tails, scarves, cloth | `RibbonChain` (skinned mesh, step 4), bones driven by a `ChainSpring` |
| **Skinned limb** | **Arms, legs, torso — anything with an elbow, knee or waist** | **`RibbonChain` whose spine is the limb's joint chain, bones posed directly by the rig script** |
| Chain of rigid pieces | Bony tails, segmented limbs | Nested `Node2D` pivots + one `ChainSpring` |

**Cut segments cannot bend cleanly.** Veyra, Rook and Morrow use rigid cutouts throughout, and that
is fine for them — nothing of theirs has an elbow. Ilyra's first rig split each arm into upper,
forearm and wrist pieces, and every pose that swung a joint past the angle the art's round joint caps
were drawn for opened a visible seam. The fix is one painting per limb over a bone chain: the paint
deforms instead of two pieces rotating over each other. Parts that hang off a limb (a hand, a boot,
the head) must be re-parented onto the **bone** that carries them, not the limb node — `reparent(bone,
true)` at `_ready` does it, because the bones are still at their rest pose there.

Conventions that everything else depends on:

- **The rig faces up.** `-Y` is forward, `+Y` is behind (tails and trails), `X` is sideways. The
  heading spring rotates the whole rig, so "forward" must be consistent or dashes point wrong.
- **The origin is the collision centre**, not the silhouette centre. Put the body there; tails may
  hang past it.
- **Draw order is tree order.** No `z_index` games inside a rig (the one exception is Morrow's runes,
  which flip between −1 and +1 to pass behind and in front of him).
- **A pivot sits on the joint.** Place the `Node2D` at the joint and offset its `Sprite2D` so the
  art hangs from it: rotating the pivot then rotates the part around the joint, not its centre.

## 3. Build the scene

Structure (see `veyra_visual.tscn` for a complete one):

```text
<Name>Visual (script extends PlayableCharacterVisual)
├── %MotionRoot              ← the AnimationTree moves this, nothing else
│   ├── %TrailParticles      ← optional GPUParticles2D (movement trail)
│   ├── %DashParticles       ← optional GPUParticles2D (dash-only accent)
│   └── %Body                ← every part, in draw order
│       ├── TailLeft (RibbonChain)   texture + spine + cell_size
│       ├── LeftFin (Node2D) → Sprite2D (offset so the pivot is the shoulder)
│       └── OuterBody / Core / Eyes (Sprite2D)
├── %AnimationPlayer         ← empty; the library is built in code
└── %AnimationTree           ← empty; the state machine is built in code
```

Getting proportions right is the fiddly part. Two tricks that saved time:

- **Compare against the reference.** `tools/screenshot.sh res://tools/godot/render_character_lineup.tscn 120 540x960`
  renders each character's `preview.png` beside its live rig (idle and mid-dash) and prints
  `[Lineup] <id> bounds=… size=… centre=…`. Set `design_size` to the larger bound and
  `preview_center` to the bounds centre; the test enforces both within 12 % / 8 %.
- **Align two parts automatically** when they must overlay (Rook's bone wing frame over its
  membrane): search offset and scale for the best overlap of the two alpha masks, then hard-code the
  winning numbers. His generated parts came at inconsistent scales, so the rig scales them per part.

## 4. Bones and skinning (how the bending actually works)

Rigid cutouts cannot bend: rotate a painted tail and it swings like a plank, and splitting it into
pieces leaves gaps at the joints. So bending parts are **skinned meshes**: `RibbonChain` builds, at
`_ready`, a `Skeleton2D` with a `Bone2D` chain along the spine plus a `Polygon2D` weighted to it.

**The bone chain.** One bone per spine segment, each parented to the previous one:

- `bone.position` — the first bone sits at the spine root (the node's origin); every later bone sits
  at `(previous segment length, 0)` in its parent's frame, because a `Bone2D`'s local +X runs along
  the bone.
- `bone.rotation` — the segment's angle *relative to its parent's* angle.
- `bone.rest = bone.transform` — **set this before adding the bone to the tree.** Skinning deforms
  vertices by `current pose × rest⁻¹`; without a rest pose the mesh collapses on the first frame.
- `set_autocalculate_length_and_angle(false)` then `set_length(segment length)` — a `Bone2D` whose
  children are sprites rather than bones would otherwise try to measure itself and warn.

**The mesh.** A plain grid over the texture, one quad per cell (`cell_size` 30 px for our ribbons):

- `polygon` — vertex positions in the node's local space (`pixel − root`), so the attachment point
  is the node origin.
- `uv` — the same pixels, untranslated (Polygon2D UVs are in texture pixels).
- `polygons` — an array of `PackedInt32Array` quads; Godot triangulates each one.
- `skeleton` — the path to the `Skeleton2D`. The mesh must be a **sibling** of the skeleton, not a
  child of a bone; a bone parent applies its transform *and* the skinning, doubling the motion.
- `add_bone(skeleton.get_path_to(bone), weights)` — one `PackedFloat32Array` per bone, one entry per
  vertex, **paths relative to the skeleton**.

**The weights** decide how it bends. For each vertex, find the nearest spine segment and the
parameter `t` along it; give that bone the weight, and blend linearly with the neighbouring bone
across a joint (`t < 0.5` shares with the previous bone, `t > 0.5` with the next). That 50/50 seam
is what removes creases. Weights must **sum to 1 per vertex** and cover every vertex —
`test_playable_character_visual` checks exactly that, because Godot silently ignores a bone whose
weight array is the wrong length.

Limits worth knowing: bends beyond roughly 0.45 rad per joint start folding the paint over itself
(`ChainSpring.max_offset` caps this), and a skinned `Polygon2D` is culled by its *undeformed* rect,
so a ribbon that bends far outside its rest bounds can disappear at screen edges.

## 5. Secondary motion: `ChainSpring`

Every appendage that trails — skinned ribbons, Rook's bony tail, Morrow's cloak flap, feet — uses one
helper, so they all behave consistently. Per joint it holds a rest angle, an offset and a velocity,
and each frame it:

1. **Lags.** Measures how far the joint's *parent* turned in the world since last frame and keeps a
   share of it (`lag_root` → `lag_tip`, tips are lazier). This is what makes a tail swing when the
   body turns, with no physics engine involved.
2. **Targets.** Rest + a sine sway whose phase steps down the chain (a wave travelling to the tip),
   plus `straighten` (removes painted curl at speed) and `bias` (a constant pull, e.g. feet tucking).
3. **Springs.** Semi-implicit integration toward the target, sub-stepped at 1/120 s so stiff springs
   stay stable, then clamps the offset.

Tuning that reads well: `stiffness` 55–120, `damping` 8–12, `softening` ~0.5 (tips softer),
`max_offset` 0.45–0.6, `sway_tip` 0.08–0.16 rad. Call `impulse(rad_per_s)` on events (Veyra's tails
get ±3 on landing, ±7 on a kill) and `reset()` for Reduced Motion.

**Frame-rate independence is not optional.** The lag cap is a *rate* (`max_lag_rate`, rad/s, scaled
by delta). It was a per-frame constant first, which meant the whip never clamped at 120 fps and was
halved at 30 fps — a review caught it. Anything you write per frame must be expressed per second.

## 6. The state machine

`PlayableCharacterVisual` builds the animation set in code at `_ready`, so a new character inherits
all thirteen states for free:

- One `Animation` per state, four value tracks on `MotionRoot` (position, scale, rotation, modulate),
  cubic interpolation, lengths from `STATE_LENGTHS`. Per-character strength comes from
  `squash_amount` / `bounce_amount` (Morrow is 0.55 / 0.7 — calm; Veyra is 1.0 — elastic).
- One `AnimationNodeStateMachine` with an edge between **every** pair of states so any reaction can
  cut in, 0.075 s cross-fades and 0.14 s into calm loops.
- Both resources are cached statically and shared by every rig — they hold no playback state, and the
  Shop builds nine at once.

Rules the controller relies on: loops (`idle_hover`, `move_fly`, `aim_charge`, `dash_loop`,
`victory`) play immediately; everything else is a one-shot that fires **once per controller event**
(the controller asks every frame, so repeat requests must not restart it); `INTERRUPTS` (death, hit,
spawn, dash start, dash end) cut in; a kill cannot interrupt a death.

**Squash acts on the travel axis.** The rig is rotated so local `-Y` is forward, so a dash stretches
`Y` and thins `X`. Getting this backwards (the first version did) makes every dash read as a pancake.

**Heading.** A damped spring, never a lerp: `6.5 Hz` (ζ 0.72) toward the dash, `4.2 Hz` (ζ 0.86) back
to standing. Standing is not "upright" — it is the wall's inward normal (`get_standing_heading()`),
so characters stand on side walls and hang from ceilings, and a dash turns feet-first over the last
`WispPlayer.LANDING_WINDOW` (0.16 s) using the `landing` value the controller supplies.

## 7. Per-character motion

Override three hooks; everything else is shared.

```gdscript
func _update_secondary_motion(delta: float) -> void:   # every frame
func _on_state_started(state_name: StringName) -> void: # impulses on state entry
func _apply_reduced_pose() -> void:                     # settle everything, Reduced Motion
```

The pattern that keeps this readable: read `get_speed()`, `get_landing()` and `_current_state`, pick
**target** values in a `match`, then ease the stored values toward them (`lerpf(v, target, 1 - exp(-rate * delta))`).
Never snap a value the player can see — a forced-open blink cost one frame of pop and the smoothness
test caught it. Hoist state lists to `const` arrays: array literals inside `_update_secondary_motion`
allocate every frame (CONVENTIONS §8), and nine Shop cards multiply that by nine.

Accumulators that feed `sin`/`cos` may wrap; accumulators that feed a **rotation** must not. Morrow's
runes counter-spin off the orbit angle, and wrapping it at `TAU` made every rune jump once per lap.

## 8. Particles

One optional movement trail and one dash-only accent per rig, `local_coords = false` so the trail
stays in the world. The process material's `direction` is in the rig's **local** frame, so backwards
is `(0, 1, 0)` — a trail set to `(-1, 0, 0)` fires sideways once the rig rotates into a dash. Keep
the total under 40 particles (the test enforces it) and scale sizes for a character that is ~130 px
tall in a run.

## 9. Wire the character in

1. `data/forms/<id>.tres` — `FormData`: id, display name, one-line description (short enough for one
   line on a card), price, `texture` (the extracted `preview.png`), `visual_scene`, tint.
2. Add the path to `data/forms/default_catalog.tres` and raise `FormCatalog.REQUIRED_FORM_COUNT`.
   Set `tier` if the character is a Legendary or Mythic collectible (presentation only — the Shop
   prints it above the description and nothing else reads it).
3. Add the id to `SaveManagerService.VALID_FORM_IDS` (no schema bump — characters reuse
   `owned_forms` / `equipped_form`).
4. Nothing else: the Shop card, its animation, Home's hero, the HUD portrait and every run mode
   already read the catalog.

## 10. Verify (in this order)

```sh
tools/validate.sh                                   # must print VALIDATE: OK
tools/run_tests.sh playable_character_visual        # rig contract, states, smoothness, menus, GameWorld
tools/screenshot.sh res://tools/godot/render_character_lineup.tscn 120 540x960   # sizing vs reference
WISP_CHARACTER=<id> WISP_MOTION_CLIP=1 WISP_MOTION_SCALE=0.25 WISP_ISOLATED_SAVE=1 \
  "$GODOT" --path . --resolution 540x960 --fixed-fps 60 \
  --write-movie logs/clips/<id>/frame.png --quit-after 1010 \
  res://tools/godot/render_character_motion.tscn    # 4× slow-motion clip to watch
python3 tools/art/motion_contact_sheet.py <id>      # real-speed frames, tiled for review
"$GODOT" --headless --path . --script res://tools/godot/bench_character_previews.gd
```

Watch the contact sheets frame by frame — that is where the real bugs show. The automated test
covers the vocabulary, no collision in the rig, particle budget, skin weights, sizing, every
controller state, per-frame snaps, Reduced Motion, both menus and a production GameWorld, but it
cannot tell you that a pose looks silly.

## 11. Mistakes already made (do not repeat)

| Symptom | Cause | Fix |
|---|---|---|
| Dash reads as a pancake | Squash applied across the travel axis | Stretch local `Y`, thin `X` |
| Impact squash lands on the wrong axis | Mirroring the controller's wall squash into the rig's rotated frame | Mirror only the uniform base size; the rig plays its own squash |
| Character faces the previous dash while drifting | Controller passed a stale `_dash_direction` | Pass the actual drift heading |
| A rune/part jumps once per revolution | Wrapping an angle that drives a rotation | Let the accumulator grow |
| A resting pose never appears in game | It was keyed off `get_landing()`, which is a *dash* value — `WispPlayer` returns 0 the instant the dash ends | Drive anything that persists at rest from `surface_normal` (`1 - surface_normal.dot(UP)` is 0 on the floor, 1 on a wall), not from the approach to it |
| A held prop floats beside the hand | The pack places the prop *near* the hand, draws the whole fist on one side of it, or lets the handle exit sideways | Align the shaft with the fist axis, solve it through the painted palm, leave the butt visible below, then draw the palm behind it and curled fingers in front |
| One-frame eye/limb pop | A value forced to a new state instantly | Feed it through the same smoothing |
| Tails whip differently at 30/60/120 fps | A per-frame cap instead of a rate | Express caps per second |
| Slow-motion render came out 16× slow | `Engine.time_scale` **and** a raised physics rate | Godot already scales physics delta by time scale |
| Hidden Shop cards still animate | Rigs process while their tab is invisible | Stop on `NOTIFICATION_VISIBILITY_CHANGED` |
| Tab switch reloads every texture | `FormCatalog` re-`load()`ed each call | Cache loaded characters for the session |
| Keyed sheet extracts as one huge blob | The alpha ramp started at luminance 0, so the whole black background stayed faintly opaque | Start the ramp at the sheet's black level (`noise_floor`) |
| Extraction hangs for minutes on a complex cell | The hand-rolled union-find labeller degenerates on a dense, tangled mask | It is `scipy.ndimage.label` now — 6 s for two characters, and v1 output is byte-identical |
| A mirrored limb swings 4 rad on the first frame | Angles stored unsigned and mirrored on application, but seeded from the authored (already mirrored) rotation | Un-mirror when seeding: `angles[i] = node.rotation * side` |
| Skirt/cape splays *outward* during a dive | The per-panel sign was taken from which side the panel is on, not from which way its rest angle opens | `outward` is the sign of the panel's rest rotation; folding then drives every panel toward zero |
| A one-joint `ChainSpring` feels half as strong | `bias` is scaled by `lerpf(0.5, 1.0, share)` and `share` is 0 for a single joint | Double the intended angle, or use a real chain |
| A part pops the first time it appears | Scale/alpha written only on the frame it becomes visible | Write them every frame and let `visible` gate drawing; settle them once in `_ready` |
| Motion reads as a still pose in a run | Amplitudes authored at preview scale | She is ~130 px tall in play: under ~0.2 rad moves a limb by a pixel |

## 12. Checklist for a new character

- [ ] Layer sheet generated, prompt recorded, contact sheet inspected, `ASSETS.md` row added
      (a whole-pose sprite pack instead? [§1c](#1c-or-not-a-rig-at-all-a-whole-pose-sprite-pack))
- [ ] Spines pasted into the rig scene; ribbon weights pass the test
- [ ] `design_size` and `preview_center` match `get_layer_bounds()`; lineup looks like the reference
- [ ] Secondary motion for idle, aim coil, dive tuck, landing brace, kill accent, hit, death
- [ ] Particles under budget, trail pointing backwards
- [ ] `FormData` (including `tier`), catalog count, save ids, the two tests' `RIGGED` lists and the
      preview benchmark's `IDS`
- [ ] `validate.sh`, the character test, a slow-motion clip reviewed
- [ ] System doc table row, DEVLOG entry; a price decision asked of the owner
