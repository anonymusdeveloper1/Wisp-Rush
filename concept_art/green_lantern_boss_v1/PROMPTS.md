# Green lantern boss — pose pack and AutoSprite prompts

> Owner request, 2026-10-05: document the boss; generate the attack starting poses, idle and death,
> including the healing pose; keep pixel art. The owner declines a separate recovery pose.
> Boss design: [boss_ranged.md](../../docs/specs/enemies_v2/boss_ranged.md).
> Source artwork only; no runtime implementation, game runs or tests.

## What is here

Six unchanged generated PNGs, each **1254 × 1254**. The image prompts requested 1024 × 1024;
the generator returned 1254 × 1254, and these copies retain that output. The idle master is the
reference for the other five poses. The magenta backing is for background removal in AutoSprite.
These are individual pose images, not animated sheets or packed runtime sprites.

The supplied reference is [references/boss.jpg](references/boss.jpg). All image-generation prompts
are retained verbatim; their pose, scale, palette and rendering instructions describe the requested
art, not a measurement of a finished AutoSprite sheet.

| Pose image | Prompt used to generate it |
|---|---|
| [01_idle.png](poses/01_idle.png) | [Exact generation prompt](first_frame_prompts/01_idle.txt) |
| [02_summon_start.png](poses/02_summon_start.png) | [Exact generation prompt](first_frame_prompts/02_summon_start.txt) |
| [03_flame_volley_start.png](poses/03_flame_volley_start.png) | [Exact generation prompt](first_frame_prompts/03_flame_volley_start.txt) |
| [04_lantern_sweep_start.png](poses/04_lantern_sweep_start.png) | [Exact generation prompt](first_frame_prompts/04_lantern_sweep_start.txt) |
| [05_soul_recall_heal_start.png](poses/05_soul_recall_heal_start.png) | [Exact generation prompt](first_frame_prompts/05_soul_recall_heal_start.txt) |
| [06_death_end.png](poses/06_death_end.png) | [Exact generation prompt](first_frame_prompts/06_death_end.txt) |

## First and last frames

Use the four cast images as their starting poses. Reuse idle as the shared ending;
a separate recovery image is unnecessary. The slumped death pose is the **last** frame of death,
with idle as its first frame, so AutoSprite animates the change into defeat.

| Animation | Custom name | First image | Last image | Loop |
|---|---|---|---|---|
| Idle loop | `glb_idle` | [01_idle.png](poses/01_idle.png) | [01_idle.png](poses/01_idle.png) | Yes |
| Summon green wisps | `glb_summon` | [02_summon_start.png](poses/02_summon_start.png) | [01_idle.png](poses/01_idle.png) | No |
| Green Flame Volley | `glb_flame_volley` | [03_flame_volley_start.png](poses/03_flame_volley_start.png) | [01_idle.png](poses/01_idle.png) | No |
| Lantern Sweep | `glb_lantern_sweep` | [04_lantern_sweep_start.png](poses/04_lantern_sweep_start.png) | [01_idle.png](poses/01_idle.png) | No |
| Soul Recall — heal | `glb_soul_recall_heal` | [05_soul_recall_heal_start.png](poses/05_soul_recall_heal_start.png) | [01_idle.png](poses/01_idle.png) | No |
| Death | `glb_death` | [01_idle.png](poses/01_idle.png) | [06_death_end.png](poses/06_death_end.png) | No |

No further boss body poses are needed for this stationary design and these six animations.
The summoned wisps, flying volley flames, broad sweep wave and returning-soul effects belong
in separate assets; their sheets are not part of this pose pack.

## AutoSprite setup

This is a suggested export setup, not a decision about the boss's gameplay size or attack timing.

1. Use the generated idle image as the character reference. Upload the six pose images to the
   same character's Poses library or custom-animation frame inputs.
2. Make six separate custom animations with the names and first/last images in the table.
   Use **Custom First & Last Frame**; only idle loops. Frame upload is supported by the
   [custom-animation wizard](https://www.autosprite.io/docs/guide-advanced-creation).
3. Start with **Turbo, 2 seconds**, using the supplied first and last poses. Max is an alternative
   when a longer clip is wanted. The current API documents first/last-frame and loop support for
   Turbo and Max; Ultra ignores a supplied last frame and cannot make a seamless loop.
   [Spritesheets API](https://www.autosprite.io/docs/api-spritesheets).
4. Suggested sheet settings: **512 px frames, 25 frames**, **Ultra background removal**,
   and the **same pixel-art filter setting for every animation**. Frame extraction, background
   removal and the pixel-art filter are configured at the spritesheet stage.
   [Advanced Mode](https://www.autosprite.io/docs/guide-advanced-mode).
5. Paste each complete motion prompt below. For API use, keep `rawPrompt: true` so AutoSprite's
   default directional template does not turn the front-facing boss sideways. Each prompt is
   below the documented 600-character custom-animation limit.
   [Spritesheets API](https://www.autosprite.io/docs/api-spritesheets).

The generated image is the identity reference; retain its front-facing skull, right-hand staff
(viewer's left), costume and equipment scale. Keep the body in place. The clip length above is
an art-generation setting, not a cooldown, a damage window or the duration of the future fight.

Short character description, if an input asks for one:

```text
Hooded skeleton in dark teal robes, emerald gems, green-fire cage-lantern staff.
```

## Copy-ready motion prompts

These animate the boss's body and attached lantern/hand fire. Detached wisps, projectiles,
large arcs and incoming souls are kept out of body sheets so their movement does not change
the boss's apparent scale.

### Idle loop

Custom animation name: `glb_idle`. First frame: `01_idle.png`. Last frame: `01_idle.png`. 543 characters.

```text
CHARACTER: Same hooded skeleton and green cage-lantern staff.
POSE: Front-facing, centered, full body, staff in right hand on viewer left.
MOTION: Small robe flutter, subtle shoulder motion and pixel fire flicker; remain in place.
TIMING: Calm seamless loop; last pose matches first.
DO NOT: Walk, turn, zoom, mirror, change size, swap hands, add wisps or scenery.
STYLE: 2D pixel art, same limited palette and square pixels, crisp edges, no added outline, no anti-aliasing, gradients, blur, painterly or 3D rendering. Flat magenta background.
```

### Summon green wisps

Custom animation name: `glb_summon`. First frame: `02_summon_start.png`. Last frame: `01_idle.png`. 568 characters.

```text
CHARACTER: Same hooded skeleton and cage-lantern staff.
POSE: Start from summon image, centered and front-facing.
MOTION: Lift the lantern, open the free left palm, pulse its green fire to call wisps, then lower arms to idle.
TIMING: Readable preparation, one clear summoning cast, settle into supplied idle last frame.
DO NOT: Move the body root, turn, zoom, mirror, change size, swap staff hand or embed detached wisps.
STYLE: 2D pixel art, same palette, crisp square pixels, no added outline, anti-aliasing, gradients, blur, painterly or 3D rendering. Flat magenta.
```

### Green Flame Volley

Custom animation name: `glb_flame_volley`. First frame: `03_flame_volley_start.png`. Last frame: `01_idle.png`. 576 characters.

```text
CHARACTER: Same hooded skeleton and cage-lantern staff.
POSE: Start from flame-volley image; centered and front-facing.
MOTION: Gather green fire in the free left palm, draw it close, thrust that hand outward once, then return to idle.
TIMING: Clear charge, sharp casting release, settle into supplied idle last frame.
DO NOT: Walk, turn, zoom, mirror, resize, swap the right-hand staff, embed flying projectiles or wide effects.
STYLE: 2D pixel art, same palette, crisp square pixels; no added outline, anti-aliasing, gradients, blur, painterly or 3D rendering. Flat magenta.
```

### Lantern Sweep

Custom animation name: `glb_lantern_sweep`. First frame: `04_lantern_sweep_start.png`. Last frame: `01_idle.png`. 581 characters.

```text
CHARACTER: Same hooded skeleton and cage-lantern staff.
POSE: Start from sweep wind-up image; centered, front-facing.
MOTION: Draw the staff back, swing its lantern across the body in one broad curve, let sleeves follow, return to idle.
TIMING: Readable wind-up, decisive sweep, settle into supplied idle last frame.
DO NOT: Move the body root, spin, zoom, mirror, resize, swap the staff hand, clip the staff or bake a wide flame arc.
STYLE: 2D pixel art, same palette, crisp square pixels; no added outline, anti-aliasing, gradients, blur, painterly or 3D rendering. Flat magenta.
```

### Soul Recall — heal

Custom animation name: `glb_soul_recall_heal`. First frame: `05_soul_recall_heal_start.png`. Last frame: `01_idle.png`. 589 characters.

```text
CHARACTER: Same hooded skeleton and cage-lantern staff.
POSE: Start from Soul Recall image; centered, front-facing.
MOTION: Raise the lantern and curl the free left fingers inward, pulling souls toward it; lantern and chest pulse green, then return to idle.
TIMING: Clear beckoning, held healing channel, settle into supplied idle last frame.
DO NOT: Walk, turn, zoom, mirror, resize, swap staff hand, add a new spell or embed detached wisps.
STYLE: 2D pixel art, same palette, crisp square pixels; no added outline, anti-aliasing, gradients, blur, painterly or 3D rendering. Flat magenta.
```

### Death

Custom animation name: `glb_death`. First frame: `01_idle.png`. Last frame: `06_death_end.png`. 563 characters.

```text
CHARACTER: Same hooded skeleton and cage-lantern staff.
POSE: Start from idle, end at supplied slumped death image.
MOTION: Shoulders sag, skull bows, free left hand falls limp; lantern fire, eyes, gems and robe fire extinguish. Keep holding the staff.
TIMING: One final collapse into the slumped pose; stay there, no loop.
DO NOT: Walk, zoom, mirror, resize, swap staff hand, explode, dissolve or revive.
STYLE: 2D pixel art, same palette, crisp square pixels; no added outline, anti-aliasing, gradients, blur, painterly or 3D rendering. Flat magenta background.
```

## Art handoff

- Preserve one character scale and body root across the six animations.
- Keep the complete lantern staff and robe tips inside each frame.
- Use the magenta removal and the same pixel filter on every sheet.
- Download each animation separately with its atlas metadata. No sheet has been generated in
  AutoSprite during this task.
- Boss name, health, damage, cooldowns, wisp count/behaviour, healing amount, vulnerability
  windows and on-screen size are not decided in this session.

The source reference, poses and prompts stay under `concept_art/`; no scene, gameplay script
or runtime resource is changed for this boss.

