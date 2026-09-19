# Ilyra v3 / v3.1 rig-source generation prompts

Generated on 2026-09-18 with the built-in OpenAI image-generation tool. The approved
`references/ilyra_concept.png` was the identity reference unless a prompt explicitly names an
intermediate board. Boards were staging artifacts only; the checked-in deliverable is one PNG per
part under `parts/ilyra/`.

The prompts below are verbatim. Each heading records whether that result contributes to the final
pack. Deterministic isolation and finishing are documented after the prompts.

## v3.1 continuous arms — used

Output board: `exec-e312e99c-ba7f-4a15-8125-68a9504f47b8.png`

```text
Use case: identity-preserve
Asset type: modest, nonsexual fantasy game rig-source component board for an adult heroine
Input images: Image 1 is the approved adult fantasy heroine Ilyra concept and strict identity lock. Image 2 is her approved arm-component board. Image 3 is her neutral game-rig assembly for scale. Preserve the costume, palette, materials, proportions and painterly rendering. The character is an adult. Keep all costume coverage exactly as approved; no nudity, cleavage emphasis, fetish styling or sexualization.

Generate exactly FOUR isolated WHOLE continuous costumed arms on one genuinely transparent RGBA landscape canvas, arranged in four evenly spaced vertical columns with broad empty gutters. Left to right: her upper-left arm, upper-right arm, lower-left arm, lower-right arm. Each is one unbroken painting from a generous rounded shoulder socket at TOP through elbow and forearm to wrist at BOTTOM. No hand or fingers. All four fully extended, perfectly straight and vertical, orthographic front view, relaxed neutral anatomy, centered, same exact scale.

Appearance: luminous dusky-lavender fantasy skin where uncovered, deep teal/indigo forearm guards, antique-gold trim, small cyan diamond accents, exact premium hand-painted Wisp Rush look. Preserve true left/right asymmetry. Upper pair slightly more armored; lower pair lighter, matching the approved concept.

Deformation rules: no painted cut, seam, ball cap, cuff edge, ring, hard gold band or abrupt width change at either elbow. Place gold ornament bands between joints—mid-upper-arm and mid-forearm—never on the elbow or wrist bend. Smooth gradual taper through elbow. Add enough rounded shoulder/socket mass at the top to hide under torso and shoulder ornament through ±70° rotation. Wrist ends with a small rounded hand-attachment stub. Bold low-frequency detail only.

Technical: truly transparent straight-alpha background; exactly four disconnected arm assets and nothing else; at least 80 transparent pixels between assets and edges; fully visible, uncropped. No background, checkerboard, matte, guide, label, text, shadow, glow, particles, detached fragments or neighbor pixels.
Avoid: bent or posed arms, foreshortening, hands, torso, repeated elbow cuffs, beads, seams, extra limbs, changed costume, 3D render, watermark.
```

## v3.1 continuous legs — used

Output board: `exec-4a0e171c-9385-49bb-8470-ae1e3975f476.png`

```text
Use case: identity-preserve
Asset type: modest, nonsexual fantasy game rig-source component board for an adult heroine
Input images: Image 1 is the approved adult fantasy heroine Ilyra concept and strict identity lock. Image 2 is her approved thigh-and-shin component board. Image 3 is her neutral game-rig assembly for scale. Preserve costume coverage, palette, materials, proportions and painterly rendering. The character is an adult. No nudity, anatomy emphasis, fetish styling or sexualization.

Generate exactly TWO isolated WHOLE continuous costumed legs on one genuinely transparent RGBA canvas, arranged side by side with a broad empty gutter. Left object is Ilyra's own left leg; right object is her own right leg. Each is one unbroken painting from a generous rounded hip socket at TOP through thigh, knee and shin to ankle at BOTTOM. No boot or foot. Both fully extended, perfectly straight and vertical, orthographic front view, relaxed neutral anatomy, same scale and length.

Appearance: exact approved fitted deep-indigo leggings, lavender skin only where the approved costume exposes it, antique-gold angular trim, restrained cyan diamond accents, premium hand-painted Wisp Rush look. True character-left/right paintings.

Deformation rules: no painted cut, seam, ball cap, ring, hard armor edge or gold band exactly across knee or ankle bends. Gradual silhouette taper through knee. Place ornament bands between joints. Include generous rounded hip/socket mass hidden by torso and skirt through ±70°. End in a clean rounded ankle/boot attachment stub. Bold low-frequency detail only.

Technical: truly transparent straight-alpha background; exactly two disconnected leg assets and nothing else; at least 100 transparent pixels around and between them; fully visible, uncropped. No background, checkerboard, matte, labels, guides, shadows, glow, particles, detached fragments or neighbor pixels.
Avoid: bent knees, posed legs, foreshortening, boots, feet, skirt, torso, visible old cut lines, beads, seams, extra legs, changed costume, 3D, watermark.
```

## v3.1 continuous torso generation probe — not used

Output board: `exec-43ad9b37-12a3-4126-895c-5881a1442abc.png`

The probe was clean and deformable, but it broadened the approved torso and added hip plates that
belong to the separate cloth layers. Identity fidelity won: the final `torso.png` is the approved v3
chest and hips flattened at their existing manifest transforms instead.

```text
Use case: identity-preserve
Asset type: modest, nonsexual fantasy game rig-source torso armor for an adult heroine
Input images: Image 1 is the approved adult fantasy heroine Ilyra concept and strict identity lock. Image 2 is a transparent board of her approved upper-body armor and hip armor pieces. Image 3 is her neutral game-rig assembly for scale. Preserve costume coverage, palette, materials, proportions and painterly rendering. The character is an adult. Keep the design fully covered and practical; no nudity, cleavage emphasis, fetish styling or sexualization.

Generate exactly ONE isolated continuous front-facing COSTUMED TORSO AND HIP ARMOR ASSET on a genuinely transparent RGBA portrait canvas. It runs unbroken from the high protective collar at TOP through upper-body armor, waist and hip armor to the two upper-leg sockets at BOTTOM. Include full left/right shoulder socket masses beneath her separate shoulder ornaments. No head, hair, crown, arms, hands, bright heart gem or glow, skirt panels, sashes, legs or boots.

Identity lock: exact fitted deep-teal/indigo ceremonial armor, antique-gold trim geometry, dark unlit diamond heart socket, modest fully covered surface, small lavender shoulder socket areas, compact dancer proportions, exact premium hand-painted Wisp Rush look. Heart setting stays but its center is dark and empty because the separate heart_core asset overlays it.

Deformation rules: one continuous painting with no horizontal waist cut, no gap and no floating layer. Keep width transition smooth through waist. Integrate the approved belt-like gold trim into the painted surface without a hard straight cut exactly at the waist bend. Four arm roots need complete generous rounded shoulder socket mass under the two ornaments so no gap opens through ±70° movement. Two clean rounded upper-leg sockets at bottom. Bold low-frequency detail only.

Composition: symmetric neutral front view, perfectly upright and centered, same source scale as current pack, large transparent padding, fully visible and uncropped.
Technical: truly transparent straight alpha; exactly one isolated armor/torso asset and nothing else. No background, checkerboard, matte, label, guide, text, cast shadow, particles, detached fragments or glow.
Avoid: split upper and lower objects, face, arms, shoulder ornaments, bright gem, skirt, sashes, legs, exposed anatomy, changed costume/proportions, 3D, watermark.
```

## v3.1 torso cleanup probe — not used

Output board: `exec-3d13595e-4210-406a-9791-7c7ae597edd6.png`

```text
Use case: precise-object-edit, identity-preserve
Input images: Image 1 is the edit target: the newly generated continuous torso armor asset. Image 2 is the exact approved old upper-body and hip-armor component board. Image 3 is the approved adult heroine concept identity lock.

Change ONLY these issues in Image 1:
1. Replace the oversized lower hip flaps, long center tab and purple side panels with the compact hip silhouette shown in Image 2: fitted short hip armor ending at two rounded upper-leg sockets. No skirt panel, sash, loincloth or hanging tab belongs in this torso asset because those remain separate rig parts.
2. Make the small diamond at the waist/belt dark and unlit, matching Image 2. There must be no cyan gem pixels anywhere; heart_core.png remains a separate overlay.
3. Keep the upper armor, collar, dark chest socket, continuous waist, shoulder socket mass, scale, front view, lighting, transparent canvas and every other pixel/feature as close to Image 1 as possible.

The result must remain exactly one modest, fully covered, nonsexual continuous torso-and-hip armor source for an adult fantasy heroine. Preserve genuine transparent straight alpha. No head, arms, hands, separate shoulder ornaments, bright gems, skirt panels, sashes, legs, boots, background, text, shadow, glow or extra object.
```

## v3.1 deterministic isolation and finishing

- The arm and leg boards were separated by their alpha-connected components at alpha ≥ 8. The kept
  component mask was expanded four source pixels to retain antialiasing, while detached low-alpha
  generation noise was discarded.
- Every generated layer was resized in premultiplied-alpha space with Lanczos filtering: one common
  `0.34` factor for all four arms and one common `0.24` factor for both legs. No individual part was
  scaled to fill its canvas.
- `torso.png` is `torso_hips.png` at character top-left `(-81, -100)`, then
  `torso_chest.png` at `(-80, -286)`, flattened in their prior draw order. The original pixels and
  scale are unchanged; the waist chain point sits away from the gold belt.
- Every result was tightly cropped, padded by eight transparent pixels, saved as RGBA, and had RGB
  set to zero wherever alpha is zero.
- The v3.1 manifest was then used to render the neutral 1024² assembly. A mesh QA warp bent both
  internal joints of all seven skinned parts to −70° and +70°, and a separate socket sheet rotated
  `arm_ul` beneath `torso` + `shoulder_ornament_l` through the same range.

## Heads and back hair — used

Output board: `exec-6d7df959-9053-46b4-8392-76db849d50af.png`

```text
Use case: identity-preserve
Asset type: transparent rig-source component board for a 2D skeletal game character
Input image: the approved Ilyra, the Astral Dancer concept sheet. It is the strict identity lock and edit source. Preserve her exact face, luminous dusky-lavender skin, pearl-white hair, pointed ears, cyan-white eyes, earrings, antique-gold trim, hand-painted Wisp Rush rendering, proportions, palette, and line quality. Do not redesign, restyle, recolour, age, or change facial proportions.

Primary request: Produce exactly SIX isolated source components on one genuinely transparent RGBA canvas, arranged as a clean 3-column by 2-row board with large empty transparent gutters and no grid lines. Reading left-to-right:
top row: (1) head_neutral, (2) head_blink, (3) head_focused.
bottom row: (4) head_joy, (5) head_pain, (6) hair_back.

Head construction for components 1–5: the same full front-facing Ilyra head at identical scale, canvas registration, silhouette, neck length and lighting. Each contains only head, ears, earrings, front hair, side hair framing the face, and a short rounded neck stub. No crown pieces, no braids, no back-hair mass, no collar, no shoulders, no torso, no glow or cast shadow.
Expressions:
1 neutral — eyes open, faint warm smile, matches approved face.
2 blink — eyes naturally closed, identical mouth to neutral.
3 focused — eyes narrowed, brows set, mouth firm, heroic not angry.
4 joy — eyes happily closed, open joyful smile.
5 pain — eyes squeezed shut, restrained wince, not grotesque.
All five must be true expression variants of exactly the same face and head geometry, with identical outer silhouette and pivot registration so they can cross-fade without popping.

Component 6 hair_back: only Ilyra's pearl-white rear hair mass behind her head, no face, skull, ears, earrings, front fringe, crown, braids, collar, shoulders, neck or body. Symmetric neutral back-hair piece, attachment/root at the top, hanging straight down, no curl or pose, full rounded upper attachment area.

Style/medium: exact approved premium hand-painted 2D fantasy game art, crisp pixel-inspired outer contour and selective hard edges, flat even front lighting with only self-form shading.
Composition: each head approximately the same size, centered in its own equal cell; hair_back centered in cell 6 at the same character scale. At least 80 transparent pixels between every component and the canvas edges.
Technical constraints: genuinely transparent background with straight alpha; no matte, checkerboard, backing rectangle, guide marks, labels, text, numbers, shadows, particles, detached specks or neighboring pixels. Tight clean silhouettes, soft glow only where intrinsic to earrings and faded fully before any edge. Exactly six components and nothing else.
Avoid: full body, torso, shoulders, braids, crown, fans, arms, extra faces, alternate hairstyle, changed skin tone, anime restyle, oversized eyes, glossy 3D, black background, grey background, white background, checkerboard, contact shadows, captions, watermark.
```

The five heads were registered to one 272×246 canvas after isolation. A later edit probe is archived
below but was rejected because it introduced a collar and duplicate earring details.

## Original v3 torso and shoulder ornaments — shoulders retained; torso pieces flattened into v3.1

Output board: `exec-4c6e4bfc-be82-4751-9521-8dc35df4c8da.png`

```text
Use case: identity-preserve
Asset type: transparent rig-source component board for Ilyra, the Astral Dancer
Input image: approved Ilyra concept sheet; absolute identity lock. Preserve exactly her fitted deep-teal/indigo torso armor, high collar, antique-gold trim, cyan diamond heart setting, dusky-lavender skin, compact proportions, palette and hand-painted Wisp Rush rendering. Do not redesign.
Primary request: Exactly FOUR isolated components on a genuinely transparent RGBA canvas, arranged 2 columns by 2 rows with wide empty gutters and no grid: top-left torso_chest, top-right torso_hips, bottom-left shoulder_ornament_l (Ilyra's own left), bottom-right shoulder_ornament_r.
torso_chest: collar and chest down to the waist seam only; no head, neck above collar, arms, shoulder ornaments, hips, skirt or legs. Keep the approved gold heart-core setting but make its central gem socket dark/unlit and empty. Symmetric neutral front view. Bottom edge is a full smoothly painted rounded overlap cap extending below the visible waist seam.
torso_hips: waist seam to tops of both thighs only; fitted belt and approved costume geometry; no chest, skirt panels, sashes, legs or arms. Full rounded top overlap cap hidden under chest; two clean rounded thigh sockets at bottom.
shoulder ornaments: each approved antique-gold/dark-teal armored shoulder cap alone, true left/right versions, not a flipped reuse, attachment socket clean and rounded so it covers an arm joint.
Style: exact approved premium hand-painted 2D fantasy game art, crisp contour, even front lighting, self-form shading only.
Composition: all parts at one common 1024-px-character reference scale, not enlarged to fill cells. Torso chest about one quarter of reference body height; hips smaller; shoulder ornaments compact.
Technical: straight alpha, actual transparency, no matte/background/checkerboard, exactly four disconnected objects, 80px gutters, no labels/text, no neighboring pixels, no cast shadows, no glow, no specks. Full rounded caps and 20% overlap allowance.
Avoid: face, hair, braids, crown, arms, hands, fans, skirt panels, sashes, thighs, boots, lit heart gem, changed costume, alternate palette, pose, perspective, black or grey background.
```

## Original v3 segmented arms — superseded by the v3.1 continuous arms

Output board: `exec-fc96e929-3a7b-4d31-8915-d91f4b6e5b1d.png`

```text
Use case: identity-preserve
Asset type: transparent rig-source component board for Ilyra's four-arm skeletal rig
Input image: approved Ilyra concept sheet; absolute identity lock. Preserve exact dusky-lavender skin, deep-teal forearm cloth, asymmetric antique-gold banding, proportions, palette and painted contour. Do not redesign.
Primary request: Exactly TWELVE isolated components on a genuinely transparent RGBA canvas, arranged as a clean 4-column × 3-row board with wide gutters and no grid.
Columns left-to-right are Ilyra's arms: upper-left (ul), upper-right (ur), lower-left (ll), lower-right (lr). Rows top-to-bottom:
row 1: arm_upper_ul, arm_upper_ur, arm_upper_ll, arm_upper_lr — shoulder-to-elbow segments.
row 2: arm_fore_ul, arm_fore_ur, arm_fore_ll, arm_fore_lr — elbow-to-wrist segments.
row 3: arm_wrist_ul, arm_wrist_ur, arm_wrist_ll, arm_wrist_lr — gold cuff/bangle only.
Every upper and forearm segment is drawn perfectly straight and vertical, centered horizontally, attachment end at TOP, distal end at bottom, orthographic front presentation, no bend, no foreshortening, no hand. Both ends must be complete smoothly painted rounded joint caps with at least 20% extra overlap beyond the visible joint so ±60-degree rotation never opens a gap. Wrist cuffs are closed rings/cuffs alone, straight-on, sized to cover the wrist seam.
True character-left/right art: preserve Ilyra's asymmetric gold banding; do not mirror one painted piece. Upper and lower arm tiers retain their approved subtle ornament differences.
Style: exact approved hand-painted Wisp Rush art, crisp pixel-inspired contour, even front lighting, only intrinsic self-shading.
Scale: one common reference scale for every piece, corresponding to a 1024px-tall assembled character; upper arm and forearm lengths consistent with approved anatomy. Do not enlarge individual pieces to fill cells.
Technical: actual transparent straight alpha; exactly 12 disconnected objects; 50px+ transparent gutters; no labels, text, arrows, guide lines, background, checkerboard, shadows, glows, stray specks or neighbor pixels.
Avoid: complete arms, bent limbs, posed or diagonal parts, hands, shoulder ornaments, torso, duplicate/missing pieces, flat cut ends, more or fewer arms, changed skin/costume/palette, 3D render.
```

## Six hand poses — two-stage, used

Base output board: `exec-aadebaaf-57e6-4d99-a7e6-c41acfece45f.png`

```text
Use case: identity-preserve
Asset type: transparent hand-pose source board for Ilyra's skeletal rig
Input image: approved Ilyra concept sheet; strict identity lock. Preserve her exact dusky-lavender skin, elegant four-finger-plus-thumb anatomy, antique-gold nail/bracelet language where visible, compact proportions and painted Wisp Rush line quality.
Primary request: Exactly SIX isolated hands on a genuinely transparent RGBA canvas in a 3-column × 2-row board with wide gutters and no grid.
Top row: hand_open_l, hand_open_r, hand_grip_l.
Bottom row: hand_grip_r, hand_cup_l, hand_cup_r.
Left/right mean Ilyra's own sides, true anatomical mirrors with approved asymmetric fine detail.
Open: fingers naturally spread, palm facing viewer, readable friendly dance gesture.
Grip: fingers closed around an EMPTY cylindrical fan-handle space, but include no handle and no fan pixels; thumb placement clear.
Cup: fingers together and curved inward, palm forming a shallow cup for gathering energy; no energy orb.
Each hand includes a short rounded wrist stub at the top/attachment side with enough overlap under the cuff; no forearm, cuff or jewelry from neighboring parts. Neutral orthographic presentation, consistent size at the same 1024px assembled-character reference scale.
Style: exact approved premium hand-painted 2D fantasy game art, even frontal lighting, crisp contours, self-shading only.
Technical: genuine straight-alpha transparency; exactly six disconnected components, no background, matte, checkerboard, text, labels, cast shadows, glows, fans, energy, extra fingers, detached specks or neighboring pixels.
Avoid: oversized hands, human skin tone, claws, nail polish changes, weapons, full arms, cuffs, pose perspective, inconsistent scales, duplicate hand orientation.
```

The base board incorrectly painted cuffs. This exact edit request removed them; only the corrected
output contributes to the pack.

Corrected output board: `exec-a7c8c876-1f07-4810-a839-af1de8f7189a.png`

```text
Edit the attached six-hand component board for Ilyra. Preserve the exact six hand poses, lavender skin, anatomy, scale, painterly rendering, and layout, but REMOVE every cuff, bracelet, bangle, gold ornament, blue sleeve, gem, and forearm segment.

OUTPUT remains exactly six isolated bare hands in the same 3 columns by 2 rows order:
top: open left, open right, grip left
bottom: grip right, cupped left, cupped right.

Each hand must end in only a short smooth lavender-skin wrist stub at its attachment side. The wrist stub must have a clean rounded cap and enough overlap to tuck under a separate cuff layer. No jewelry pixels of any kind may remain. Do not change the fingers, gesture, nail treatment, handedness, palette, or proportions.

Genuine transparent RGBA only: no grey/black/white background, vignette, halo, contact shadow, labels, grid, text, glow, detached specks, fan handle, energy orb, or neighboring pixels. One component per cell with wide transparent gutters and clean straight-alpha edges. This is a surgical production edit, not a redesign.
```

## Folding fan mechanism — used

Output board: `exec-6772f2fa-c7c6-4899-95a5-f6cf6585d499.png`

```text
Use case: identity-preserve
Asset type: transparent folding-fan mechanism source board for Ilyra's rig
Input image: approved Ilyra concept sheet; strict identity lock. Preserve her exact crescent fan design: restrained antique-gold construction, five slim ribs, translucent soul-cyan to aurora-violet membrane, small cyan diamond tip ornaments and premium hand-painted Wisp Rush rendering.
Primary request: Exactly EIGHT isolated components on a genuinely transparent RGBA canvas, arranged 4 columns × 2 rows with wide gutters and no grid.
Top row: fan_handle, fan_rib_a, fan_rib_b, fan_rib_c.
Bottom row: fan_rib_d, fan_rib_e, fan_membrane, fan_membrane_lit.
fan_handle: only the short antique-gold handle and round rivet; no hand, ribs or membrane; rivet clearly centered.
Each of five ribs: one separate identical-length thin antique-gold spine alone, drawn perfectly vertical pointing UP, rivet attachment end at the BOTTOM, centered in its cell. Preserve small approved tip-ornament variations a–e. No membrane and no neighboring rib. Complete rounded rivet end for overlap.
fan_membrane: the approved fully open translucent crescent cloth alone, no gold ribs, handle, rivet or hand; lower convergence point exactly at the imaginary rivet; smooth full open arc, frontal orthographic view.
fan_membrane_lit: same exact silhouette and registration as fan_membrane, brighter white-hot cyan center with controlled violet edge for attack cross-fade; no shape change.
Scale: all components belong to one fan at the same 1024px assembled-character reference scale; ribs and membrane must register mechanically. Do not enlarge pieces to fill cells.
Style: exact approved hand-painted 2D fantasy game art, crisp contour, translucent color with straight alpha and short intrinsic glow.
Technical: genuine transparent RGBA, exactly eight disconnected components, generous transparent gutters, no background/matte/checkerboard, labels/text, grid, shadows, hand, arm, duplicate ribs, stray pixels or clipped glow.
Avoid: complete assembled fan, more/fewer than five ribs, folding fan at an angle, opaque membrane, redesign, extra ornaments, black background, grey background.
```

All ribs were normalized to one 176 px canvas height around the bottom rivet. The clean membrane
alpha was reused for the lit state and only its colour was brightened, guaranteeing identical
silhouette and registration.

## Original v3 segmented legs — boots retained; thigh/shin pieces superseded by v3.1

Output board: `exec-c8f472a8-663b-44b5-a392-e8ae2f34331a.png`

```text
Create a transparent rig-source component sheet for Ilyra, the Astral Dancer, using the attached approved concept as a strict identity reference. Do not redesign, recolor, restyle, or change proportions.

OUTPUT: exactly six isolated leg components in a clean 3 columns by 2 rows grid, no dividers and no text:
top row: left thigh, right thigh, left shin.
bottom row: right shin, left boot, right boot.

TECHNICAL:
- genuine transparent RGBA canvas, absolutely no background, floor, vignette, shadow, glow cloud, labels, border, or contact shadow
- one component per cell with wide clear separation
- all six parts at one consistent character scale
- every component perfectly straight and vertical, centered in its cell, attachment end at the TOP
- thighs and shins have clean rounded joint caps at both ends with at least 20 percent hidden overlap allowance for gap-free rotation through plus/minus 60 degrees
- boots have a rounded ankle socket/overlap area at top and point downward in a neutral front-facing stance
- no neighboring body pixels, no skirts, no hips, no second part attached
- match Ilyra's exact pale lavender skin, midnight blue fabric, gold trim, cyan-violet gem accents, painterly finish, silhouette, and ornament language from the approved concept
- true left/right counterparts, not six copies
- crisp readable silhouette at mobile scale, clean anti-aliased edges, no baked cast shadows
This is production rig source art, not a concept sheet and not a posed character.
```

## Particle and effect shapes — used after contract finishing

Output board: `exec-a4f48243-c7f7-4fbb-8b46-009f45683802.png`

```text
Create a transparent production VFX texture sheet for Ilyra, the Astral Dancer, derived from the attached approved character palette and motif language. Do not alter the character design.

OUTPUT: exactly seven isolated effects in a clean 4 columns by 2 rows grid, with the bottom-right cell empty. No text or dividers.
top row: four-point astral star, small round astral mote, slim diamond/petal, sweeping fan arc.
bottom row: thin complete magic ring, soft radial bloom, long tapered motion streak, EMPTY.

TECHNICAL:
- genuine transparent RGBA, no background, floor, vignette, rectangular haze, border, labels, or shadows
- one effect per occupied cell, wide separation
- turquoise/cyan core, violet-blue falloff, tiny restrained warm-gold highlight only where appropriate
- soft additive-ready alpha with no black matte; color remains saturated through translucent edges
- star, mote, and petal compact and readable at 16 to 32 px
- fan arc is one clean crescent sweep, not a fan or weapon
- ring is a complete thin ellipse/circle with a transparent center
- bloom is a centered circular glow texture
- streak is horizontal, straight, tapered, and isolated
- elegant mythic player-character energy, not hostile, no character body parts
Production particle textures, not a presentation board.
```

`ART_REQUEST.md` §3.8 is stricter than this colour request: runtime-tintable textures must be
near-white. Therefore RGB was normalized to a cool near-white while retaining authored alpha and
shape. The arc was rotated to the required horizontal 256×96 sweep; ring and bloom were normalized
to square 256 px content, and detached presentation sparkles were removed.

## Approved-sheet components — no generation prompt

The following final files are pixel-preserving derivatives of the approved v2 art, not regenerated:

- `braid_l`, `braid_r`
- `skirt_panel_1` … `skirt_panel_6`
- `sash_1` … `sash_4`
- `crown_star`, `crown_shard_l`, `crown_shard_r`
- `heart_core`

They were isolated from the approved transparent rig source at a uniform 2× scale, de-matted and
padded. The braid and sash centre lines were straightened by horizontal scanline translation only.
`heart_glow` is a deterministic soft cyan radial bloom with no gem pixels.

## Rejected generation probes — not used in any final PNG

### Expression edit probe

Output board: `exec-1e7f3685-f656-40e9-a485-3b32e79c37d3.png`

```text
Edit the attached approved isolated Ilyra head into a production expression sheet. This is an identity-preserving edit, not a redesign.

OUTPUT: exactly four isolated full-head variants in a clean 2 by 2 grid:
top-left blink, top-right focused, bottom-left joy, bottom-right pain.

IDENTITY LOCK:
- preserve the attached head's exact chibi proportions, face width and height, jaw, nose, ear shape, skin colour, eye spacing and size, pearl-white front-hair silhouette, short neck stub, earrings, painterly rendering, and costume pixels
- preserve the exact outer silhouette and registration across all four variants
- do not make her older, taller-faced, more realistic, more glamorous, or differently proportioned
- change ONLY eyelids/irises, eyebrows, and mouth expression
- blink: eyes closed, same faint smile
- focused: eyes narrowed, brow set, mouth firm
- joy: eyes happily closed, open smile
- pain: eyes shut tight, brow pinched, small wince
- no crown pieces, no braids, no back-hair mass, no collar, no shoulders

TECHNICAL:
- genuine transparent RGBA canvas; absolutely no background, grey wash, vignette, halo, label, border, cast shadow, or checkerboard
- one head per cell with wide empty separation
- identical scale and registration in every cell
- clean anti-aliased straight-alpha edges with no matte
This will cross-fade over the approved neutral head in a 2D game rig.
```

Rejected because the result added a collar and duplicate earring details. The original six-part
head board above remained closer to the locked sheet after registration.

### Sash generation probe

Output board: `exec-b2e05195-2446-4aaf-8241-d7d1f67148ee.png`

```text
Create a transparent rig-source component sheet for Ilyra, the Astral Dancer, using the attached approved concept as a strict identity reference. Do not redesign, recolor, restyle, or change proportions.

OUTPUT: exactly four separate sash ribbons in a clean 2 by 2 grid, no text or dividers:
top row: sash 1, sash 2
bottom row: sash 3, sash 4.

TECHNICAL:
- genuine transparent RGBA, absolutely no background, floor, vignette, shadow, glow cloud, labels, border, or contact shadow
- one sash per cell with wide clear separation
- all four at the same scale and length family
- each sash drawn STRAIGHT AND VERTICAL, attachment end at the TOP; no curled, bent, posed, S-shaped, diagonal, or windblown ribbon
- rounded reinforced attachment cap at top with overlap allowance
- long tapered celestial silk shapes matching Ilyra's exact midnight-blue, violet, turquoise and gold costume palette
- retain her approved faceted astral texture and restrained luminous edge language
- four subtly distinct silhouettes/details while remaining one coordinated set
- no body, hands, skirt, braids, clasps, or neighboring pixels
- no baked shadows from other objects, clean anti-aliased edges, readable at mobile scale
These are production rig pieces intended to be procedurally bent later.
```

Rejected because the approved sheet already contained the exact four signed-off sashes. The final
pack preserves those pixels and only removes their baked curve.

## Deterministic finishing

After generation, connected components were selected at alpha ≥24, low-alpha presentation wash was
removed, RGB under alpha zero was cleared, and every source was tightly cropped with eight pixels of
transparent padding. Resampling was performed in premultiplied space and converted back to straight
alpha to prevent dark fringes. No complete board or concept sheet is stored as a runtime part.

The manifest then supplied every pivot, optional tip, collision-centre-relative rest position,
rest rotation, draw order and parent. `assembly/ilyra_assembly_reference.png` was rendered solely
from those values; no pixels were painted onto the assembly afterward.
