# ADR-0016: A character's menu performance may be a pre-rendered video

> **Status:** Accepted · **Date:** 2026-09-21 · **Deciders:** owner ("instead of having an idle
> animation for the store front and the home screen … an animation video already made"; "use ai
> for video creation") + Claude Code · **Relates to:** [ADR-0015](0015-animated-playable-characters.md)
> (presentation-only characters), GDD §14 #36 (the five-animation set), GDD §14 #37
>
> **Addendum 2026-09-21:** Ilyra is the second character with a menu video, keyed on **green**
> because she is violet (the key is chosen per character from its own pixels; Shade stays on
> magenta). The playback moved into one shared `CharacterMenuVideo` (a `VideoStreamPlayer`
> subclass) used by both `WholeFrameCharacterVisual` and `IlyraVisual`, so the packed-alpha shader,
> the pause while hidden and the restart after the kept Home is re-attached live in one place.

## Context

Since GDD §14 #36 a drawn character has one menu animation, `storefront_idle`: 12 frames on a 448 px
cell, drawn on Home and the Shop card where the character is large and still. The owner's standing
complaint about those loops is that they read as steps (DEVLOG 2026-09-20, the 1.4× loop-rate
workaround), and more frames cost VRAM linearly. The owner proposed generating the menu performance
as a video with an image-to-video model instead.

Hard constraints, from Godot's documentation and from measurement on this project:

- **Ogg Theora is the only core video codec.** No H.264 / WebM without an addon.
- **Theora has no alpha**, and no image-to-video model exports alpha either.
- **Decoding is on the CPU**; the docs advise ≤ 720p / 30 fps on mobile.
- **A loop is seamless only with *Video Delay Compensation* at 0** (the project default).
- **Windows 64-bit ffmpeg writes broken Theora** (Godot's docs warn of it). Measured here: ffmpeg's
  own decoder rejected 91 % of the packets its encoder wrote, and Godot drew them as macroblocks.

## Options considered

1. **More sprite frames** — no new media type, but VRAM grows with every frame and every live card,
   and a generated sequence of 40+ registered frames is exactly what image models are worst at.
2. **Chroma-keyed video at runtime** (a shader keys green or magenta live) — one file, but every
   device keys every frame, the key colour must avoid every character's palette (Shade is green),
   and soft glow edges fringe.
3. **Packed-alpha video, keyed offline** — the take is generated on flat magenta, keyed once by a
   tool, and each frame written as premultiplied colour beside its matte; a trivial shader
   recombines them. Costs a 2:1 frame and an intake tool, but the runtime does no keying and the
   edge quality is decided once, where it can be inspected.
4. **A video addon (FFmpeg/GDExtension)** — real alpha codecs, but a native dependency on every
   platform, and a new dependency is the owner's call (AGENTS.md §7).

## Decision

**Option 3.** A whole-frame character may carry `WholeFrameCharacterVisual.menu_video`, a
`MenuVideoData` resource generated with the stream by `tools/art/extract_menu_video.py`:

- **Generation** follows the pack's `VIDEO_PROMPT.md` (flat `#FF00FF`, start frame = end frame,
  static camera). The untouched take is kept in the pack's `source/` as the provenance record.
- **Intake** cuts the loop at the frame closest to frame 0 and cross-fades the seam, keys the
  magenta (unmix, despill, colour decontamination, a 0.2 matte choke), forces the generator's corner
  label transparent, packs colour | matte, and places the square so the character stands exactly as
  tall as the sprite loop it replaces.
- **Encoding is Godot's own Movie Maker** (OGV writer, editor builds only), in a throwaway project,
  with `--fixed-fps`. It encodes with the libtheora the game decodes with. The tool then decodes its
  own output and fails unless the frame count and frame rate match, and it measures the decoded
  matte's floor and ceiling into the resource so compression noise never shows as a box or a hole.
- **Playback** is menus only. Gameplay stays on sprite frames, which must follow the dash heading
  and the walls. A menu playing a video holds **no** frame set; Reduced Motion falls back to the
  sprite loop's held first frame; a hidden card pauses; and because a `VideoStreamPlayer` stops
  itself on leaving the tree while Main detaches the kept Home, the visual restarts it on re-entry.
- `FormData.menu_frames_path` is left empty for such a character, so the boot screen does not warm
  a sheet the menus never draw.

## Consequences

- Shade's menu costs one ~1.2 MB stream and one 1280 × 640 decoded texture (~3 MB) instead of a
  2784 × 928 sheet (~10 MB), and moves continuously instead of in 12 steps.
- Each character with a video decodes on the CPU while its card is live. With one video in the game
  this is one decoder; before a second lands, limit playback to the focused card (neighbours show the
  still portrait) and measure on a low-end phone.
- The intake needs ffmpeg (decode only), scipy and the Godot editor binary, and opens a window for a
  few seconds — the same requirement as `tools/screenshot.sh`.
- Movie Maker always records a silent Vorbis track. It is harmless; an encoder that can omit it
  would save a little CPU.
- Generated video carries the same open licence question as all generated art (GDD §14 #1, #21), and
  the generator stamps an "AI" content label that the intake removes from the game's copy; whether
  the tool's terms allow that, and the store's AI-content disclosure, are release checks.
