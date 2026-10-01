# ADR-0018: The game is 2D pixel art

> **Status:** Accepted, amended 2026-09-25 and 2026-09-26 for characters (see the Addenda; the first 2026-09-26 addendum was reverted the same day); amended 2026-09-30 by [ADR-0023](0023-3d-arenas.md): arenas may be 3D · **Date:** 2026-09-24 · **Deciders:** owner / Claude Code (Opus 5.5)
>
> Supersedes the **rendering style** of [ADR-0005](0005-visual-redesign-v1.md) (painterly art from
> `concept_art/wisp_rush_redesign_v1/`). ADR-0005's palette and information colours stay.

## Context
The look drifted toward pixel art one piece at a time. Home and the wordmark were redrawn on a 4 px
grid (GDD §14 #41), Codex drew a pixel-art UI and HUD kit (#42), and the characters are being
reworked through AutoSprite with its pixel-art filter (`docs/guides/character_creation.md`). On
2026-09-24 the owner made it the rule: "the game is 2d pixel art only", "the game is in pixel art not
normal art". The same day they removed the Blender tooling and the 3D model, which have no place in a
2D pixel game.

## Options considered
1. **Mixed:** painted world and characters with a pixel UI. This is how the current assets are.
   Rejected by the owner.
2. **Pixel art everywhere**, redrawn over time, with the painted assets kept as legacy until each is
   replaced.

## Decision
Everything the player sees is **2D pixel art**: characters, arenas and Rift backdrops, enemies,
bosses, VFX sprites, icons, the logo, the UI and the HUD. Source art sits on a fixed pixel grid of
whole-pixel blocks, uses limited palettes, has crisp outlines, and has no anti-aliasing, gradients
or blur. It is shown with nearest filtering at whole-number scales wherever the engine allows. There
is no painterly or 3D art. Text stays code-rendered. Palette meaning is unchanged: cyan is
friendly/navigation, amber is telegraphs/rewards, magenta is enemy cores/boss/selection.

## Consequences
- **Legacy until redrawn:** the Rift backdrops, enemies, bosses, VFX, the two painted arenas (Quarry
  Titan, Wisp Bearer) and the painted or rigged characters. Characters are being redone first
  (Patchvile done, Ilyra next).
- **The UI and HUD** move to the pixel kit (`concept_art/wisp_rush_pixel_ui_v1/`, integration in
  progress, 2026-09-24). Its grid is 4 design px per art pixel.
- **Arenas** are drawn at 270 × 600 and scaled up 4× nearest to the 1080 × 2400 contract
  ([arena_art.md](../guides/arena_art.md)), which is the UI's 4 px grid.
- **Characters** are drawn on a 256 × 256 grid, the AutoSprite frame. The game draws them at a
  non-integer scale with linear filtering (the packer resamples bicubic). Pixel-exact drawing, with
  nearest filtering at a whole-number scale, was built and reverted on 2026-09-24 and is not decided
  ([character_creation.md](../guides/character_creation.md) §8).
- **Character pixel count (owner, same day):** every character has **Patchvile's**. Standing, the
  figure is 194 px tall in its 256 px AutoSprite frame; Codex draws the first frames at that share
  and the packer packs everyone at his scale (`roster_scale`). This replaced a rule of 2 design px
  per art pixel set earlier that day, whose ~130-art-pixel figure was based on a wrong on-screen
  size. The UI, Home and arenas keep their 4 px grid. GDD §14 #43.

## Addendum — 2026-09-25: characters are drawn exactly like Patchvile
Owner: "remove the outline, keep it like patchvile", "the rules shall match exactly like patchvile".
The Decision's crisp outlines, limited palettes and no anti-aliasing do **not** apply to playable
characters. A character looks the way Patchvile's approved AutoSprite frames look: **no outline**, up
to 256 colours with soft edges (AutoSprite exports a 256-entry paletted PNG), no blur, at the roster
size. The outline was never an owner rule; it was added when this ADR was written, and Patchvile never
had one. The UI, HUD, arenas and the rest of the world keep the Decision as written. Recipe:
[character_creation.md](../guides/character_creation.md) §3; GDD §14 #46.

## Addendum — 2026-09-26: Patchvile's pixel size, each character's own height
Owner: characters can be different heights and still play the same (a character is cosmetic: the
hitbox and the attack are the same for everyone); Patchvile is the example for the pixel block size
and how a character is made, not for its height. So the Consequences' **character pixel count**
now means the pixel size: every character is drawn at AutoSprite's 256 px frame and packed at
Patchvile's scale (`roster_scale`), so its pixels are his size on screen. The **height is each
character's own**, set by the owner and recorded in its pack (`standing`), and the packer's check
holds the frames to it: Patchvile, Shade and Mothmere stand 194 px, Scarlet 166 (she is smaller than
Patchvile). Recipe: [character_creation.md](../guides/character_creation.md) §3–§4; GDD §14 #51.

## Addendum — 2026-09-26, later: the same size for everyone again
Owner: every character has to be the same size, in the game, in the Shop, everywhere; the change
above that let heights differ is reverted. The Consequences' **character pixel count** holds as
first written: 194 px standing in the 256 px frame, packed at Patchvile's scale, for everyone.
Scarlet's sheets were made with her standing 166 px, so her scene draws her 1.16× larger (`art_scale` 1.38, `menu_art_scale` 1.45) and she is the same size as everyone on screen; her pixels are 16 % larger than Patchvile's (GDD §14 #54).
