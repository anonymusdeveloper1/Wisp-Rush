# Wisp Rush playable characters v3.1 — skinned rig-source art

> **Status:** ✅ Ilyra skinned-source replacement complete · ⛔ Bram intentionally not generated
>
> **Identity authority:** [`references/ilyra_concept.png`](references/ilyra_concept.png)
> **Rig contract:** [`ART_REQUEST_SKINNED.md`](ART_REQUEST_SKINNED.md), which supersedes
> §§3.2–3.5 of [`ART_REQUEST.md`](ART_REQUEST.md)

This pack replaces Ilyra's rigid segmented torso, arms and legs with seven continuous paintings for
skinned meshes: one torso, four whole arms and two whole legs. Her approved identity and the other
48 source PNGs are unchanged. It does not change gameplay and nothing in this folder is loaded by
the game directly; `concept_art/` remains `.gdignore`d.

Only Ilyra is complete. Per `ART_REQUEST.md` §8, Claude rebuilds her rig and the owner tests it on a
phone before any Bram part is created. Bram's approved reference is copied unchanged because the
contract's storage layout requires both locked references, but there is no `parts/bram/` folder.

## Handoff contents

| Path | Contents |
|---|---|
| `parts/ilyra/` | Exactly 55 transparent, lower-snake-case RGBA PNGs plus `manifest.json` |
| `assembly/ilyra_assembly_reference.png` | 1024×1024 neutral front assembly rendered only from manifest transforms |
| `references/` | Byte-preserving copies of the approved v2 Ilyra and Bram sheets |
| `GENERATION_PROMPTS.md` | Verbatim generation prompts and deterministic finishing provenance |

The 55 parts are: five registered heads, back hair, one continuous torso, two shoulder ornaments,
four continuous arms, six bare hands, a handle/five ribs/two membrane states, two continuous legs,
two boots, two braids, six skirt panels, four sashes, three crown pieces, heart core + glow and seven
VFX textures.

## Scale, orientation and alpha

- The assembly reference is a 1024 px coordinate frame. `rest_position` is relative to its collision
  centre with +X right and +Y down.
- Character-left/right suffixes are Ilyra's own sides. In the front assembly, her left appears on
  the viewer's right.
- Limbs, braids, sashes and skirt panels are stored vertically with the attachment at the top.
  Their manifest pivot/tip X coordinates are identical.
- Each replacement limb is one unbroken painting: no elbow/knee cut, no joint cap and no duplicated
  cuff. Gold bands sit between the bend points. The torso is one flattened, connected painting with
  the waist bend deliberately placed away from the gold belt.
- The four arms, two legs and torso each carry a four-point `chain`; every internal joint was bent
  to −70° and +70° over magenta with no tear, opening or detached paint.
- Every PNG is straight-alpha RGBA, has RGB zeroed wherever alpha is zero, and has at least eight
  transparent pixels on every edge. No sheet background, neighbour shadow or detached generation
  fragment is retained.
- The five heads have an identical 272×246 canvas and pivot. The five fan ribs have an identical
  176 px canvas height. `fan_membrane.png` and `fan_membrane_lit.png` share byte-identical alpha.
- Particle textures are near-white and single-ramp-friendly so the runtime can tint them.

## Manifest notes

Every entry supplies the fields required by `ART_REQUEST.md` §2.1: `file`, `pivot`, optional `tip`,
`rest_position`, `rest_rotation_deg`, `draw_order` and `parent`. The seven deformable replacements
also supply the v3.1 `chain`; `pivot == chain[0]` and `tip == chain[-1]`.

Two additive handoff fields remove ambiguity without changing the required contract:

- `assembly_visible` selects the neutral variant when several files occupy the same rig slot.
- `assembly.mirrored_instances` places the second copy of the shared fan mechanism. The approved
  design uses two identical fans, while §3.4 requests one reusable fan part set.

Claude should treat `assembly/ilyra_assembly_reference.png` as the registration target, not as a
runtime sprite. Alternate heads, cupped hands, the lit membrane and all VFX are deliberately hidden
in that neutral reference.

## Provenance and identity preservation

The four continuous arms and two continuous legs were generated with the built-in OpenAI image tool
using the approved sheet, the earlier approved parts and the neutral assembly as locked references.
The continuous torso is a lossless flattening of the approved `torso_chest` over `torso_hips` at
their manifest transforms; no new torso design was substituted. Exact requests and deterministic
finishing are in `GENERATION_PROMPTS.md`.

All 48 retained PNGs are byte-identical to the previous handoff: the five faces, back hair, shoulder
ornaments, hands, fan mechanism, boots, braids, skirt panels, sashes, crown, core and VFX. Their
existing provenance still applies. `heart_glow.png` remains a separate cyan radial bloom with no gem
pixels.

## Acceptance results

- **55/55** expected PNG filenames; **55/55** manifest entries.
- All files open as RGBA; padding, zero-alpha RGB, naming and required manifest fields pass.
- Magenta contact review: no matte, dark fringe, clipped glow, neighbour pixels or detached specks.
- Seven deformable parts pass both internal-joint bends at −70° / +70° without a tear or seam.
- `arm_ul` stays connected beneath `torso` + `shoulder_ornament_l` through −70° / 0° / +70°.
- Manifest assembly content fits `(54, 5)–(970, 968)` inside the 1024² canvas.
- The assembly remains identifiable at **61×64 px**.
- Side-by-side review preserves Ilyra's face, four connected arms, two legs, twin fans, costume and
  locked teal/indigo/violet/gold/cyan palette.

## Remaining art limitations

- This is rig source, not the finished animation. Godot mesh construction/weights, fan-collapse
  deformation, state timing, particle counts and Reduced Motion behaviour remain Claude's work.
- The neutral assembly intentionally uses a symmetric, implementation-friendly rest pose; it is not
  a pixel copy of any posed figure on the concept sheet.
- Generated missing geometry matches the approved identity and rendering language but is newly
  painted source art. The original approved sheet remains the final visual authority during rig QA.
