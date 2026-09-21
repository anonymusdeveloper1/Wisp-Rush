# Devlog videos (TikTok and YouTube Shorts)

The tools and commands behind Wisp Rush devlog videos. **How to make an episode** (rules, story
structures, Palmier timeline blueprint, exact values, QA) is the recipe of record:
[docs/marketing/devlog_video_recipe.md](../../docs/marketing/devlog_video_recipe.md). Owner decisions:
edit in **Remotion** (2026-09-20; `remotion/`, one composition per episode), footage **recorded by
the game itself**, **Kokoro** voices, **game first, open about AI**. EP01-EP04 were cut in
**Palmier Pro** through its MCP server and are not being remade; that workflow is recipe 6.1-6.2.

## Layout

| Path | What |
|---|---|
| `tools/godot/render_gameplay_clip.gd` | Bot plays a real run while Godot's MovieWriter records 1080×1920 video + game audio; writes `<movie>.events.jsonl` |
| `tools/godot/render_devlog_tour.gd` | Drives the real `Main` through a scripted tour and records it: `tour=menus` (boot → Rift Map → Shop WISPS/DASHES/ARENAS → PLAY → run loading screen → Endless run on `skin`), `tour=story` (Rift Map → locked card → ENTER → level 1 → Results → next Rift). Own isolated save, real veil/glide/loading screens |
| `tools/godot/render_feel_showcase.gd` | Scripted feel shots in a quiet tutorial arena (aim rings sweep, AIM ASSIST off/on, 8-kill finisher, 5-kill finisher, RUSH with the bot); event log marks shots, releases and kills |
| `tools/godot/render_arena_showcase.gd` | Endless arena skins back to back with live scenery and no enemies (a real GameWorld whose run start is held); event log marks `segment_start` / `segment_end` per skin |
| `tools/godot/render_character_motion.gd` | One playable character through a scripted gameplay timeline on a plain arena; `WISP_MOTION_CLIP=1` runs the dash showcase (aim hold → dive → kill accent → mid-dash turn → ceiling and floor landings) with a trailing camera and a state caption, `WISP_MOTION_SCALE=0.25` makes it 4× slow motion |
| `tools/godot/render_character_{lineup,select_showcase,home_showcase,gameplay_showcase}.gd` | Reference art vs live rig; one character in the Shop's CHARACTERS tab, on Home, and mid-dash in a real run |
| `tools/godot/devlog_bot.gd` | The bot both recorders share: best-line aim with a held arrow before multi-kills, mid-dash redirects, upgrade picks, Soul Fragment refills, `dash_speed=` override (duplicated tuning) for before/after shots |
| `tools/godot/export_game_audio.gd` | The game's own synthesized SFX (18 ids + 8 multi-kill slice pitches) and music loops/beds as WAVs — licence-free sound design for edits |
| `tools/video/kokoro_tts.py` | Script → voiceover WAV + `lines.json` + exact-timing caption `.srt` |
| `tools/video/devlog_graphics.py` | Still graphic pieces for Palmier to animate (Palmier can't draw shapes): viewer-comment card, grid backdrop, frame strip, freeze bar, touch dot / tap ring, marker arrows / circle / underline / strike, frost edge, numbered step cards on the game's stone panel, tier cards, the Endless floor outline, scenery light maps, sheet crops, code-line cards, meter track/fill pairs |
| `tools/video/palmier_motion.py` | Numbers for Palmier: pop / tap-ring / custom keyframe rows (top-left position maths), image `transform` sizes, and `fit-text` font sizes |
| `tools/video/remotion/` | **The build surface.** `src/style` (palette, fonts, motion curves, safe zones), `src/components` (the recipe 6.3 cookbook as React: roster wall, parts scatter/grid, joint diagram, registration demo, spectrum bars, numbers board, step cards, captions, footage, game SFX), `src/episodes/epNN` (one composition each). `remotion.config.ts` points the public dir at `video/`, so `staticFile("footage/x.mp4")` resolves there and nothing is duplicated |
| `tools/video/srt_to_ts.py` | Kokoro `.srt` -> a typed cue array for the Remotion caption track (the browser cannot read the SRT at render time) |
| `tools/video/master_export.sh` | Two-pass EBU R128 on a finished render: about -14.5 LUFS, true peak <= -1 dBTP. Remotion mixes at the voice's own level (~-17.7 LUFS), so **every** export needs this |
| `tools/video/contact_sheet.sh` | Watch a render as a contact sheet so an agent can Read the PNG. On this Windows host ffmpeg's `drawtext` segfaults and it cannot read Git Bash `/tmp` paths, so timestamps are printed and scratch stays in `logs/video/` |
| `tools/video/.venv/`, `tools/video/models/` | Local Kokoro (kokoro-onnx 0.6.1, `kokoro-v1.0.onnx`, `voices-v1.0.bin`) — git-ignored, ~380 MB |
| `video/` | Git-ignored, `.gdignore`d workspace: `footage/` (captures, event logs), `voice/epNN/` (scripts, WAV, SRT), `graphics/epNN/`, `audio/game/`, `references/` (the owner's four style TikToks `ref1–4` and three hook TikToks `hook1–3`), `exports/` |
| Palmier projects | One per episode: `~/Documents/Palmier Pro/Wisp Rush Devlog NN - <Title>.palmier` (EP01 lives in the older shared "Wisp Rush Devlogs"). Palmier references files in place: don't move or delete `video/` files a project uses |

## Palmier Pro connection

The MCP server runs inside the app: `http://127.0.0.1:19789/mcp` (Streamable HTTP). It is registered
in the local Claude Code config as `palmier-pro` (`claude mcp add --transport http palmier-pro
http://127.0.0.1:19789/mcp`); the app must be open. Read the server's own instructions on connect.
`inspect_media` / `inspect_timeline` return frames on a 0–1 grid plus transcripts — that is how an agent
watches footage and checks an edit. AI generation needs a Palmier subscription and costs money: always
ask first.

## Commands

Run from the repo root; `GODOT=/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot`.

1. **Capture gameplay** (a small Godot window opens; ~2× real time):
   ```bash
   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 --write-movie "$PWD/video/footage/NAME.avi" \
     --script res://tools/godot/render_gameplay_clip.gd -- mode=endless skin=starforged_citadel seed=7 seconds=45
   ```
   - Story Rifts: `mode=story rift=ember_hollow level=1`. Endless uses the 30 real skins; keep gameplay
     off quartz_grotto, slate_cliffs and dusk_sandstone (HUD over bright scenery) and prefer skins whose
     rim the checker did not flag (brief §7): starforged_citadel and dragon_skull_throne among the Mythics.
   - Level 1 runs have ~20 s empty stretches between waves: cut to the event log's `multi_kill`
     (5+ kills = slow-motion finisher), `rush_started`, `boss_start`, `run_ended` moments.
   - The bot looks at upgrade cards for ~1.1 s before each `upgrade` event; cut around them.
   - `boss_at=5` calls a boss early; `survive=1` (default) keeps the run alive; `rush=60` pre-fills RUSH.
2. **Capture menus and flow** (real Main, own isolated save, the event log marks each `step`):
   ```bash
   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 --write-movie "$PWD/video/footage/tour_menus.avi" \
     --script res://tools/godot/render_devlog_tour.gd -- tour=menus skin=aurora_throne run_seconds=16
   ```
   `tour=story` walks the Rift Map → ENTER → level 1 → Results → next Rift (not run yet).
   Scripted feel shots (aim rings, AIM ASSIST off/on, finishers, RUSH):
   ```bash
   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 --write-movie "$PWD/video/footage/feel.avi" \
     --script res://tools/godot/render_feel_showcase.gd -- skin=world_tree_crown shots=rings,assist,finisher,five,rush \
     events="$PWD/video/footage/feel.events.jsonl"
   ```
   Arena scenery without enemies or HUD (cut on the event log's `segment_start` / `segment_end`):
   ```bash
   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 --write-movie "$PWD/video/footage/arena_showcase.avi" \
     --script res://tools/godot/render_arena_showcase.gd -- skins=eclipse_sanctum,dragon_skull_throne seconds=5 \
     events="$PWD/video/footage/arena_showcase.events.jsonl"
   ```
3. **Transcode** for import (Palmier takes mp4/mov, not AVI; `-ss RUN_START` trims to the run):
   ```bash
   ffmpeg -i NAME.avi -vf "scale=in_range=pc:out_range=tv:in_color_matrix=bt601:out_color_matrix=bt709,format=yuv420p" \
     -c:v libx264 -preset medium -crf 14 -g 60 -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
     -color_range tv -c:a aac -b:a 256k -ar 48000 -movflags +faststart NAME.mp4 && rm NAME.avi
   ```
   MJPEG at quality 0.9 is ~10 MB/s and the disk is small — delete the AVI after transcoding.
4. **Voice**: write the scripts (recipe §4), then
   ```bash
   tools/video/.venv/bin/python tools/video/kokoro_tts.py video/voice/epNN/epNN_comment.txt video/voice/epNN/epNN_comment.wav --voice af_heart --speed 1.12
   tools/video/.venv/bin/python tools/video/kokoro_tts.py video/voice/epNN/epNN_slug.txt video/voice/epNN/epNN_slug.wav --voice am_puck --speed 1.1
   tools/video/.venv/bin/python tools/video/kokoro_tts.py video/voice/epNN/epNN_slug.txt video/voice/epNN/epNN_slug.wav --captions-only --offset <voice start s>
   ```
   Kokoro WAVs peak near 0 dBFS at only −18 LUFS, so a mix with them clips (EP02 draft: +1.0 dBTP).
   Master each voice before importing (audio prep, like transcoding; the timing is unchanged):
   ```bash
   ffmpeg -i VOICE.wav -af "aresample=48000,acompressor=threshold=-24dB:ratio=3:attack=2:release=70:makeup=2dB,volume=8dB,alimiter=limit=0.6:attack=1:release=40:level=false" -c:a pcm_s16le VOICE_master.wav
   ```
   → about −17.8 LUFS with peaks ≤ −3.8 dBFS (`volume=8.5dB` for `af_heart`). Measure any file with
   `ffmpeg -i FILE -af ebur128=peak=true -f null -`. Import the mastered WAV and read its
   `inspect_media` transcript to catch mispronunciations.
5. **Game sounds**: `"$GODOT" --headless --path . --script res://tools/godot/export_game_audio.gd -- video/audio/game 64`
   → `sfx/<id>.wav`, `sfx/slice_step1..8.wav`, `music/{pad,pulse,boss}.wav`, `music/bed_{calm,run,boss}.wav` (64 s).
6. **Graphics**:
   ```bash
   python3 tools/video/devlog_graphics.py kit video/graphics/epNN
   python3 tools/video/devlog_graphics.py comment video/graphics/epNN/comment_card.png --name Playtester --subtitle "playtest note" --text "why does your game FREEZE every time i tap PLAY??" --accent "FREEZE,PLAY??"
   python3 tools/video/devlog_graphics.py step video/graphics/epNN/step1.png --number 1 --label COVER --icon cover
   python3 tools/video/devlog_graphics.py bar video/graphics/epNN/freeze_bar_blank.png --label "" --width 760
   python3 tools/video/devlog_graphics.py preview video/graphics/epNN SHEET.png
   python3 tools/video/devlog_graphics.py tier video/graphics/epNN/tier_mythic.png --image PAINTING.png --label MYTHIC --count "×5" --color magenta
   python3 tools/video/devlog_graphics.py outline video/graphics/epNN/floor_outline.png          # --fill for a tinted floor
   python3 tools/video/devlog_graphics.py lightmap video/graphics/epNN/lights.png --mask assets/art/environment/endless/masks/SKIN.png --channel R --color amber
   python3 tools/video/devlog_graphics.py crop logs/endless/SHEET.png video/graphics/epNN/strip.png --box x0,y0,x1,y1
   python3 tools/video/devlog_graphics.py code video/graphics/epNN/code_bug.png --number 1 --text "rush_time = 0" --accent red
   python3 tools/video/devlog_graphics.py meter video/graphics/epNN/timer --label "RUSH TIMER" --color cyan
   ```
7. **Motion numbers**:
   ```bash
   python3 tools/video/palmier_motion.py pop 0.2 0.205 0.27 383 483 280      # step card 1 of EP02
   python3 tools/video/palmier_motion.py ring 0.5 0.745                       # tap ring on PLAY
   python3 tools/video/palmier_motion.py size 0.14 200 200                     # transform for a 200 px image
   python3 tools/video/palmier_motion.py fit-text anton "576 MS" 760          # → fontSize 146
   ```
8. **Captions for Remotion**: the browser cannot read the SRT at render time, so compile it:
   ```bash
   python tools/video/srt_to_ts.py video/voice/epNN/epNN_slug.srt tools/video/remotion/src/episodes/epNN/captions.ts 60
   ```
9. **Build, QA, export** (from `tools/video/remotion`; `--public-dir` is needed because the config's
   relative path is not picked up by every entry point):
   ```bash
   npm run studio                                   # live preview while building
   npx tsc --noEmit                                 # the beat map is typed; keep it clean
   npx remotion still src/index.ts epNN-slug OUT.png --frame=N --public-dir="D:/Wisp Rush/video"
   npx remotion render src/index.ts epNN-slug RAW.mp4 --public-dir="D:/Wisp Rush/video" --codec=h264 --crf=16
   ```
   Render **outside** `video/`: it is the public dir, so anything written there is copied into the
   bundle on every later render. Then master and watch it back:
   ```bash
   tools/video/master_export.sh RAW.mp4 video/exports/wisp_rush_devlog_NN_<slug>.mp4
   tools/video/contact_sheet.sh video/exports/wisp_rush_devlog_NN_<slug>.mp4 logs/video/epNN_watch.png 5 4
   ```
   Then Read the PNG. Check the §7 list: no wrapped or clipped headline, nothing overlapping, no
   caption repeating a headline already on screen, nothing in the TikTok safe zones, every number
   traceable to the brief or a logged measurement, the AI line present.

## Episodes

| # | Title | Palmier project → timeline | Export | Notes |
|---|---|---|---|---|
| 01 | One swipe | "Wisp Rush Devlogs" → EP01 One Swipe | `video/exports/wisp_rush_devlog_01_one_swipe_draft1.mp4` | Draft 1, 25.6 s, older EP01 style (no comment hook); awaiting owner review — remake in the recipe style if the owner wants it |
| 02 | Why every button froze | "Wisp Rush Devlog 02 - Why Buttons Froze" → EP02 Why Buttons Froze v1 | `video/exports/wisp_rush_devlog_02_why_buttons_froze.mp4` | **Approved by the owner 2026-09-16 — the model episode** (recipe §9); 43.7 s, −14.5 LUFS, −2.7 dBTP; no stock footage |
| 03 | 30 new arenas | "Wisp Rush Devlog 03 - 30 New Arenas" → EP03 30 New Arenas v1 | `video/exports/wisp_rush_devlog_03_30_new_arenas.mp4` | Draft 1, 51.0 s, awaiting owner review. Hook: H2 "Never, ever draw effects on top of your game art. I learned that the hard way." (black word card → ringed, struck-through sticker effects → hurt Wisp); draft 1's glow-up opening was replaced at the owner's request. Structure B: tiers, v1 stickers, light maps, set pieces, fair floor, 45 → 3.7 MB, Mythic runs. No stock footage |
| 04 | Four tricks for one swipe | "Wisp Rush Devlog 04 - One Swipe Feel" → EP04 One Swipe Feel v1 | `video/exports/wisp_rush_devlog_04_four_tricks_one_swipe.mp4` | Draft 1, 49.0 s, awaiting owner review. Hook: H9 numbered promise + open loop ("Number four almost broke my game."), payoff-first visual. Structure C: aim rings ×3, AIM ASSIST off/on (≤ 6°), slow-mo finisher (time ×0.3), RUSH (6 s, ×1.3, ×2, no damage) and its never-ending bug explained with code cards and meters. Scripted shots on World Tree Crown. No stock footage |
| 05 | I deleted six characters | `remotion` → `ep05-deleted-six` | `video/exports/wisp_rush_devlog_05_deleted_six.mp4` | Draft 1, 47.1 s, −14.4 LUFS / −2.7 dBTP, awaiting owner review. **First Remotion episode.** Hook: H6 pattern interrupt + the new roster-wall strike-out treatment. Roster 13 → 7 → 8; Ilyra's 55-part rig (recovered from git HEAD) scattered; 108 frames / 16 animations; the Ilyra 2 → Ilyra promotion; the registration A/B built from Verdant Shade's 12 real `idle_hover` frames. No stock footage |
| 06 | I built it, it worked, and I deleted it | `remotion` → `ep06-built-then-deleted` | `video/exports/wisp_rush_devlog_06_built_then_deleted.mp4` | Draft 1, 49.2 s, −14.4 LUFS / −2.1 dBTP, awaiting owner review. Hook: H1 shortcut promise + speed flex. The reverted jointed menu puppet: 26 parts, the typed-angles vs solved-endpoint IK diagram, the chin-on-waist layout, the spare arm pair. Takes the puppet's own lesson because EP05 spent the registration one. No stock footage |
| 07 | Zero sound files | `remotion` → `ep07-zero-sound-files` | `video/exports/wisp_rush_devlog_07_zero_sound_files.mp4` | Draft 1, 43.7 s, −14.4 LUFS / −2.7 dBTP, awaiting owner review. Hook: H8 unexpected number + the new counter-slam treatment. 0 audio files; 19 synthesized effects + 8 pitched slice steps; three music layers; 1.33 s at boot. Bars are the real spectrum of the game's own WAVs and the counting beat plays `slice_step1..5`. No stock footage |
| 08 | 858 megabytes for a shop screen | `remotion` → `ep08-858-megabytes` | `video/exports/wisp_rush_devlog_08_858_megabytes.mp4` | Draft 1, ~52.7 s, awaiting owner review. Hook: H5 I-know-your-pain + question/challenge. Disk size vs VRAM, 13 live cards → 858 MB, the menu/gameplay split, lazy cards 8/8 → 2/8, the 4096 px floor, Home 695 → 261 ms on the S24, and the honest "still not free". No stock footage |

**Unshot topics.** Three were numbered 05-07 before this batch took those numbers; they keep their
briefs but not their numbers:

- **Deleted a whole system** — Sanctum removed and refunded, story Rifts, Endless, the Rift Points
  shop, no-pause upgrade cards (recipe 3 B/C).
- **Three characters, one hitbox** — [devlog_characters_episodes.md](../../docs/marketing/devlog_characters_episodes.md)
  episode A. **Its numbers are stale**: the CHARACTERS tab holds 8, not 9.
- ~~They land on their feet~~ — episode B of the same brief. **Superseded**: its pre-attack-coil
  beat was removed from the game on 2026-09-19 ("holding the aim arrow no longer changes the
  character at all"). Rewrite against the current build before shooting.

Other backlog ideas (all from docs/DEVLOG.md): the phone-only audio crash, walls traced from the
art, 400 ms of dead input, RUSH and its endless-RUSH bug, one boss per video, every Rift breaks a
rule, the fragment bug (same symptom, two diseases), the ARENAS gallery research, the `ext_resource`
id that threw a parse error on a file nobody touched, one life and the Soul Vessel drop.
