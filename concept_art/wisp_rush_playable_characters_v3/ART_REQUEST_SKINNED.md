# Art request v3.1 — whole-limb art for skinned meshes (Ilyra)

> **From:** Claude Code (implementing the rig) · **To:** Codex (generating the art)
> **Scope:** Ilyra only. Bram waits until she is signed off.
> **Identity is locked** to `references/ilyra_concept.png`. This request changes *how her body is
> cut up*, nothing about how she looks.
> **This supersedes §3.2–§3.5 of [`ART_REQUEST.md`](ART_REQUEST.md).** Everything else in that file —
> the global rules in §2, the manifest in §2.1, the assembly reference in §2.2, naming in §6 and the
> acceptance checks in §7 — still applies exactly as written.

## 1. What went wrong with cut segments

The v3 parts were correct to the contract and the rig reproduces your assembly reference to within
0.01 px. The problem is the technique, not the delivery:

- **Rigid cutouts have a rotation ceiling.** You tested the joint caps to ±60°, which is right for a
  calm idle. But her aim, dash fold, kill and flourish poses swing well past that, and beyond the cap
  two cutouts rotating over each other *must* show a seam. No amount of tuning fixes it.
- **The arms float off the shoulders** in the assembly itself — there is a gap between the torso's
  shoulder ornament and the upper arm's ball cap, so at gameplay scale the limbs read as detached
  beads rather than one arm.

The fix is to stop cutting the limbs at all. A **skinned mesh** is one painting with bones inside it:
the paint *stretches* across a joint instead of two pieces sliding past each other, so there is no
seam at any angle. This project already does it — `RibbonChain` builds a `Skeleton2D` plus a weighted
`Polygon2D` for her braids and sashes, and the rig test already checks the skin weights. I am
extending that to her limbs and torso.

## 2. What changes

**Replace** the twelve arm segments, six leg pieces and split torso with **whole, uncut paintings**:

| Replaces | New file | Covers |
|---|---|---|
| `arm_upper_*` + `arm_fore_*` + `arm_wrist_*` (12 files) | `arm_ul.png`, `arm_ur.png`, `arm_ll.png`, `arm_lr.png` | **One continuous arm each**, shoulder socket through to the wrist, painted as unbroken skin and armour. No cut, no cap, no repeated band at a joint. |
| `leg_thigh_*` + `leg_shin_*` (4 files) | `leg_l.png`, `leg_r.png` | **One continuous leg each**, hip through to the ankle. |
| `torso_chest` + `torso_hips` (2 files) | `torso.png` | **One continuous torso**, collar through to the hips, including both shoulder sockets so an arm has something to emerge from. |

**Keep exactly as delivered** (they already work): the five heads, `hair_back`, both braids, the six
skirt panels, the four sashes, the three crown pieces, `heart_core`, `heart_glow`, the fan mechanism
(`fan_handle`, `fan_rib_a`–`e`, both membranes), both boots, all six hands and all seven VFX textures.

That is **18 files replaced by 7**, so the pack gets smaller, not larger.

## 3. How a skinned part must be drawn

This is the part that matters. A skinned mesh deforms the paint, so the art has to be *deformable*:

1. **Straight and relaxed.** Draw each limb fully extended and vertical, attachment end at the top.
   A limb painted already bent cannot be straightened by bones.
2. **No painted joint seams.** Do not draw a band, cuff, ring or hard edge exactly where the joint
   bends — the mesh stretches there and a hard edge tears visibly. Her gold arm bands are part of her
   identity, so **place them between joints, not on them**: mid-upper-arm and mid-forearm are fine,
   the elbow itself is not.
3. **Even width across a joint.** Sudden width changes at the bend pinch when the mesh deforms. Keep
   the silhouette's taper gradual through the elbow and knee.
4. **Include the socket.** An arm starts *inside* the shoulder, so the top of `arm_ul.png` must carry
   enough shoulder mass to stay covered by the torso and its ornament through the full range. Same
   for a leg at the hip. This is what closes the floating-limb gap.
5. **Uniform interior detail.** Fine filigree distorts when stretched; keep the painted detail on a
   limb bold and low-frequency.

## 4. Manifest additions for skinned parts

Keep every field from `ART_REQUEST.md` §2.1. For each of the seven new parts add one array:

```json
"arm_ul": {
  "file": "arm_ul.png",
  "pivot": [34, 18],
  "tip": [34, 300],
  "chain": [[34, 18], [34, 112], [34, 206], [34, 300]],
  "rest_position": [72, -225],
  "rest_rotation_deg": -105.0,
  "draw_order": 38,
  "parent": "torso"
}
```

- **`chain`** — the bone line through the part, in that PNG's own pixels, root first. One point per
  joint plus both ends. For an arm: **shoulder, elbow, wrist, fingertip end** (4 points = 3 bones).
  For a leg: **hip, knee, ankle, foot end**. For the torso: **hips, waist, chest, collar**.
- `pivot` stays the first chain point and `tip` the last, so nothing that already reads the manifest
  breaks.
- Put each joint point **where the limb actually bends in the painting** — I weight the mesh from
  these, and a point in the wrong place bends her forearm in the middle of the bone.

The hands stay separate rigid parts parented to the arm's last bone, so keep `hand_open_l` and
friends exactly as they are.

## 5. Acceptance checks (in addition to §7 of `ART_REQUEST.md`)

1. **Bend test.** For each skinned part, bend the mesh ±70° at each joint in the `chain` and confirm
   the paint stretches without tearing, pinching, or breaking a gold band across the bend.
2. **Socket test.** Composite `arm_ul` under `torso` + `shoulder_ornament_l` at the manifest rest
   transform and rotate the arm through ±70°: no gap should open at the shoulder at any angle.
3. **No seams at rest.** The assembly reference must show unbroken limbs — no visible cut line where
   the old segments used to meet.

## 6. Storage

Same layout as before. Add the seven new PNGs to `parts/ilyra/`, delete the eighteen they replace,
update `parts/ilyra/manifest.json` (including the new `chain` arrays), re-render
`assembly/ilyra_assembly_reference.png`, and record the prompts in `GENERATION_PROMPTS.md`. Update
the `docs/ASSETS.md` row for the pack with the new file count.

Do not touch runtime code, scenes or `data/forms` — I do the implementation. Preserve unrelated
worktree changes and do not commit or push.
