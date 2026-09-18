# Devlog episodes: the playable characters

> **For the agent making the video.** Two ready-to-shoot episodes about Veyra, Rook and Morrow
> (YouTube Shorts + TikTok, one export serves both). The **how** is unchanged and lives in
> [devlog_video_recipe.md](devlog_video_recipe.md); hooks in [devlog_hooks.md](devlog_hooks.md);
> commands in [tools/video/README.md](../../tools/video/README.md); what may be shown in
> [devlog_video_brief.md](devlog_video_brief.md). Make **one** episode per request.
>
> Source of the facts: DEVLOG 2026-09-17 and 2026-09-18, system doc
> [playable_character_visuals.md](../systems/playable_character_visuals.md), ADR-0015.
> **Status:** both planned, nothing shot yet (2026-09-18).

## What shipped (the story material)

Three playable characters join the six Wisp forms in the Shop's CHARACTERS tab: **Veyra, the Last
Wisp**, **Rook, the Bonewing** and **Morrow, the Runebound**. They are cosmetic only — same
collision circle, dash, health and scoring — and each is a layered rig animated in code: 13 states
from idle to death, springy tails, wings and scarves, and a small particle trail each. A second pass
made the dash read as a dive, gave every character a feet-first landing on whatever wall it hits
(Rook roosts under the ceiling) and turned the aim hold into a pre-attack coil.

## Numbers that are safe to show

Measured or authored; anything else needs a new measurement (brief §4 rules still apply).

- **3** characters, **37** runtime layers extracted from three generated sheets, **13** animation
  states each, **9** characters in the CHARACTERS tab.
- Same hitbox for every character: the collision radius does not change when you equip one (asserted
  by `test_playable_character_visual`).
- Particle budget **≤ 40** per character; nine live cards build in **133 ms** cold, **8 ms** warm and
  cost **under 0.1 ms/frame** to animate (M2 desktop, `bench_character_previews.gd`).
- Landing turn-in window **0.16 s**; heading springs **6.5 Hz** diving, **4.2 Hz** standing.
- Slow-motion clips are **4×** (`WISP_MOTION_SCALE=0.25`).
- Honest AI line (required): the character art is **AI-generated from the owner's own concept
  sheets**, and coding agents build the game. Never call the art hand-painted.

## Episode A — "Three characters, one hitbox"

**Angle:** a content drop that stays honest — three characters that change nothing about the fight.
**Hook:** H8 *unexpected number* + **Speed flex** treatment (neither repeats EP03's H2 / black word
card or EP04's H9 / payoff-first). Open on the three of them diving in under three seconds while one
claim word holds, then the number lands.

Suggested opening lines (`am_puck`; keep "Wisp Rush" out of a sentence's first word):

1. "Three new characters. Exactly zero of them make you stronger."
2. "They change how the game looks, never how it plays."

**Beats** (recipe §3.2 structure B, target 45–55 s):

| Beat | What happens | Pieces |
|---|---|---|
| Hook | Three dives cut together under `THREE` / `CHARACTERS` | `render_character_motion` clip mode per character |
| Meet them | One card each: name, one line of identity, live idle | `render_character_select_showcase` per id |
| The rule | "Same hitbox, same dash, same damage" over a run | gameplay footage + a marker circle on the Wisp |
| How they are built | Layer sheet → parts fly apart → rig moves | `sheet` crops of `<id>_parts.png`, arrows |
| Motion identity | One line each: Veyra's ribbons, Rook's wing beats, Morrow's runes | lineup + slow-motion cuts |
| Pick one | The CHARACTERS tab swiping, buy → unlock flourish | `render_devlog_tour tour=menus` (Shop) |
| Payoff + credit | Best dive of the three, AI credit pill | clip mode, AI pill (recipe §6) |
| Question + follow | "WHICH ONE / WOULD YOU PLAY?" then the follow card | recipe §6 |

## Episode B — "They land on their feet"

**Angle:** the craft pass — why a dash that *flies* into a wall feels wrong, and what fixed it.
**Hook:** H6 *pattern interrupt* + **Question / challenge** treatment. Open on Rook hanging upside
down under the ceiling, held two seconds: "My dragon sleeps on the ceiling. That one's on purpose."

**Beats** (structure C, target 45–55 s):

| Beat | What happens | Pieces |
|---|---|---|
| Hook | The ceiling roost, held, then the question card | clip mode, Rook, ceiling landing |
| The problem | Old behaviour: the body flies into the wall and rights itself late | slow-motion dive, marker arrow |
| The rule | "Up is whatever wall you stand on" — floor, side wall, ceiling in three cuts | three landings, step cards |
| The trick | The last 0.16 s: the dive turns feet-first before contact | slow-motion + a meter/bar graphic |
| The dive | Blade profile, appendages knifed back, trails behind | clip mode close-ups |
| Pre-attack | Hold to aim → the coil, then release | clip mode (its aim hold is scripted in) |
| Joke beat | The 16× render: "I slowed time twice and got a 16× slow-motion clip" | a code-card pair, hurt-Wisp gag |
| Payoff + credit | A full swipe at speed, AI pill | gameplay footage |
| Question + follow | "WHAT SHOULD I / ANIMATE NEXT?" then the follow card | recipe §6 |

## Capture commands (new since EP04)

`GODOT=/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot`, from the repo root.
`WISP_CHARACTER` is `veyra` | `rook` | `morrow`.

```sh
# 4× slow-motion dash clip: aim hold → dive → kill accent → mid-dash turn → ceiling and floor landings.
WISP_CHARACTER=rook WISP_MOTION_CLIP=1 WISP_MOTION_SCALE=0.25 WISP_ISOLATED_SAVE=1 \
  "$GODOT" --path . --resolution 540x960 --fixed-fps 60 \
  --write-movie video/footage/ep_characters/rook/frame.png --quit-after 1010 \
  res://tools/godot/render_character_motion.tscn
# Real-speed motion frames (contact sheets for picking moments)
python3 tools/art/motion_contact_sheet.py rook
# Stills / short shots
tools/screenshot.sh res://tools/godot/render_character_lineup.tscn 120 540x960   # reference | idle | dash
WISP_CHARACTER=morrow tools/screenshot.sh res://tools/godot/render_character_select_showcase.tscn 80 540x960
WISP_CHARACTER=veyra tools/screenshot.sh res://tools/godot/render_character_home_showcase.tscn 90 540x960
WISP_CHARACTER=rook tools/screenshot.sh res://tools/godot/render_character_gameplay_showcase.tscn 110 540x960
# Layer sheets to crop for the "how it is built" beat
logs/playable_characters/<id>_parts.png   (rerun: python3 tools/art/extract_playable_characters.py)
```

Transcode PNG sequences to mp4 exactly as the README step does (60 fps, H.264, yuv420p). Everything
else — voices, captions, game sounds, graphics, Palmier track stack, QA and export naming — follows
the recipe unchanged.

## Rules for these two

- One episode per request; a new Palmier project each (`Wisp Rush Devlog NN - <Title>`).
- Log the hook pair in [devlog_hooks.md](devlog_hooks.md) §6 and the episode row in
  [tools/video/README.md](../../tools/video/README.md) in the same session you export.
- Never show a character's price (they sit at 0 RP only while the owner reviews them) and never
  claim they are for sale.
- Say plainly that AI agents build the game and that the character art is AI-generated from the
  owner's concept sheets.
