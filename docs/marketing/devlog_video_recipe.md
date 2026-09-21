# Devlog video recipe (TikTok + YouTube Shorts)

> **How any agent makes a Wisp Rush devlog video.** The owner approved Devlog #2 "Why every button
> froze" (2026-09-16) as the model: every episode follows this file. Tool commands live in
> [tools/video/README.md](../../tools/video/README.md); what may be shown or claimed lives in
> [devlog_video_brief.md](devlog_video_brief.md) (§4 numbers, §6 hard rules, §7 rough edges). The
> reference cut is the Palmier project "Wisp Rush Devlog 02 - Why Buttons Froze". **Read it, never
> edit it.**
>
> **Build surface, from 2026-09-20 (owner):** episodes are assembled in **Remotion**
> (`tools/video/remotion`), not Palmier. Everything editorial in this file is unchanged — hooks,
> structures, safe numbers, the sound map, safe zones, caption style, QA and loudness. Only §6
> changes: its element cookbook is now implemented as React components in `src/components`, with
> the values in `src/style`. §6 stays as the specification those components answer to, and as the
> record of how EP01–EP04 were cut.

## 0. Checklist

1. Read the brief and the newest DEVLOG entries. Propose 3–4 topics (one line each + structure type).
   **The owner picks one. Make one video per request.** Never batch unless asked.
2. Create a **new Palmier project** for the episode (§6.1). Never edit another episode's project.
3. Pick the hook from [devlog_hooks.md](devlog_hooks.md) (a spoken idea + a §3.1 visual treatment,
   neither used by the previous episode). Write the script (§4). Voice it with Kokoro, master it,
   then check the transcript for mishearings.
4. Capture footage and stills. Export the game's sounds. Draw the graphic pieces (§5).
5. Build the timeline in the §3 structure with the §6 cookbook values.
6. QA with `inspect_timeline` / `capture_frame`. Export, measure loudness, then watch the export back (§7).
7. Record it: the README episode row, a DEVLOG entry. Send the file to the owner and ask for notes.

## 1. Owner rules (2026-09-16)

- **Edit in Remotion** (owner, 2026-09-20), one composition per episode in `tools/video/remotion`.
  The cookbook below is the style specification those components implement; EP01–EP04 were cut in
  Palmier and are not being remade.
- **Under 60 s** (aim 35–50 s), 1080×1920, 60 fps, H.264. One export serves TikTok and YouTube Shorts.
- **One topic per video**, taken from one coding session.
- **Vary the hook** (owner, 2026-09-16: "not every video shall have that comment hook"). Take the
  spoken hook from the **hook library [devlog_hooks.md](devlog_hooks.md)**, which is built from the
  owner's three hook TikToks. Use **one** of its ideas (H1–H9) so it is recognizable — owner: "use one
  idea from the hook ideas I have given you" — never their look. Pair it with a §3.1 visual treatment.
  Don't reuse the previous episode's idea or treatment. Every hook passes the context → lean →
  snapback test (hooks §2), and the payoff or question lands in the first 2–3 s.
- **Explainers** (how something works, a bug fix): show the problem in the game → explain it
  with motion graphics → show the fix (motion graphics over the real UI) → measured before/after → payoff.
- **Design or visual changes:** show the old look, say why it changed in one or two lines, then show the new look.
- **Every video** shows how the game was before, why it changed, and what's new, all in brief.
- **Charisma** (REF4): a strong hook, a joke or reaction beat, a question at the end, then the
  follow card.
- **AI:** say plainly, once, that AI coding agents build the game (spoken line + a label pill).
  Never call the art hand-made.
- **Numbers** come only from brief §4 or a logged measurement, with their context on screen
  ("measured on a Mac"). No release date, store link, pre-registration or monetisation claims.
- **Stock footage** is allowed when needed, but only openly licensed clips (Pexels, Pixabay). Bring it
  in with `import_media` url and note the source and licence in the README episode row. No TV,
  film or meme clips (REF4 uses them; we don't). Use game art for reactions instead (the hurt Wisp).
- **Voice:** Kokoro `am_puck` at 1.1–1.15 for the dev; `af_heart` at 1.12–1.16 for a commenter when
  the comment hook is used. Captions always on.

## 2. Style references

Kept in `video/references/` (git-ignored). If they're missing, re-download them:
`yt-dlp -S "vcodec:h264,res,br" --merge-output-format mp4 -o "video/references/refN.%(ext)s" <url>`.
Before a new episode, import them into the episode project's `References` folder and watch them with
`inspect_media`: `overview` first, then 12-frame windows over the whole length.

| Ref | Video | Take from it |
|---|---|---|
| REF1 | [Throne of Valoria devlog](https://www.tiktok.com/@throneofvaloria/video/7422055741734866209) (45 s) | The aesthetic: one calm voice says what changed and how it affects the game, over real footage; ends by asking for thoughts |
| REF2 | [Locomochi Devlog #1 – Camera](https://www.tiktok.com/@littlelanterngames/video/7638257027126447382) (56 s) | Problem → why → fix → result told simply; humble self-deprecating humour; one reaction insert at the end |
| REF3 | [Wynge "Day 1"](https://www.tiktok.com/@wynge_/video/7660943224415997206) (26 s) | The look: huge glowing words on black ("But", "That", "Not"), coloured words over footage, pop-in icon cards with labels, a yellow marker arrow, a cut or new element every ~0.7 s |
| REF4 | [vionical "How to make a game"](https://www.tiktok.com/@vionical/video/7616725298456841494) (35 s) | The charisma: opens on a fake comment card that slaps in, fast jokes, reaction beats, energetic payoff |

The owner's three **hook** references (HOOK-A–C, `video/references/hook1–3.mp4`) are catalogued in
[devlog_hooks.md](devlog_hooks.md). Take only their hook ideas from them, not their look.

## 3. Story structures

### 3.1 Hooks (first 2–3 s) — rotate them

A hook has two parts:
- **the spoken idea**, what the first lines say, from [devlog_hooks.md](devlog_hooks.md) §3 (H1–H9);
- **the visual treatment**, how the first seconds look, from the table below.

Pick one of each, and log the pair in hooks §6.

| Visual treatment | How | Good for | Used in |
|---|---|---|---|
| Viewer comment | Comment card slaps in over blurred footage, read by `af_heart`; the dev voice answers ("Fair enough.") and the card flies at the camera. Base it on real feedback; generic "Playtester" with a silhouette avatar, never a real creator, handle, badge or like count | fixes, complaints, "why" topics | EP02 |
| Glow-up wipe | Old look labelled BEFORE; on the payoff word a bright wipe line reveals the new look (AFTER), flash, then straight into the montage | design / visual changes | EP03 draft 1 (replaced) |
| Speed flex | A burst of the new content (e.g. 30 arenas in 3 s) under one big claim word | content drops | — |
| Payoff first | The best 1–2 s of the result (8-kill slow motion), then "here's how". EP04: the lit 8-enemy line at half speed under the series tag, the hook number (Anton 230 amber) and the promise words, then the slice with a white flash | feel / gameplay changes | EP04 |
| Black word card | REF3-style: one glowing word or number on black ("576 MS"), then the story. EP03: "NEVER," (white) and "EVER." (red `#FF3B5C`) slam in on the spoken words, then the old look with rings, a red strike and a hurt-Wisp joke beat | numbers, warnings, surprises | EP03 |
| Question / challenge | "Can you spot what changed?" or "Which one would you pick?" over a split screen | before/after, choices | EP08 |
| Roster wall strike-out | Every item the game has ever had fills the screen as a grid; the ones being removed take a red strike and drain of colour on the spoken word | removals, roster or content cuts | EP05 |
| Counter slam | One number alone on black at the house slam curve, then its unit under it, then the evidence behind it | a single surprising figure | EP07 |

Timings below are for a ~44 s cut. Scale them, but keep the order. EP02's frame map is in §9.

**A. Explainer / fix (EP02)**
| Beat | Time | What happens |
|---|---|---|
| Hook | 0–2.7 s | EP02: the comment hook (§3.1); any other hook fits here |
| Show the problem | 2.7–5 s | Real footage of the moment, then a still with an effect (frost + stamp word) |
| "WHY?" beat | 5–6 s | Black card, one giant glowing word |
| Explain the problem | 6–17 s | Motion graphics on the grid backdrop: a simple unit, then the failure growing, then the big number slam |
| Joke beat | 17–19.4 s | Reaction gag with game art (logo frosts and shakes, hurt Wisp, "oops.") |
| The fix, in words | 19.4–21.9 s | Black card: "SO HERE'S THE FIX" + two-line rule (white / cyan) + underline |
| The fix, shown | 21.9–30.8 s | Real UI with numbered step cards popping in on the spoken step, tap dots, dim, marker notes |
| Before → after | 30.8–35.5 s | Numbers board: header pill, labels, red "before" struck through, arrows, cyan "after", context line |
| Payoff + credit | 35.5–41.3 s | The best gameplay moment, AI label pill, "WHAT SHOULD I / FIX NEXT?" + arrow to the comment button |
| Follow card | 41.3–43.7 s | Dimmed gameplay, "FOLLOW FOR / DEVLOG #n+1" |

**B. Design / visual change** — Hook (EP03: "Never, ever…" on a black word card) → old look (footage or still,
labelled BEFORE) → why, in one or two lines (a kinetic word card) → the new look revealed (wipe or
slide; close-ups) → how it stays fair or readable (one motion graphic) → gameplay payoff →
question → follow card.

**C. Game change / feel** — Hook → the pain shown in gameplay (the miss, the lost combo) → why (one
line + a marker note) → the change shown with the same shot (split screen `apply_layout
top_bottom` for before/after, or back-to-back) → the result in play (slow motion for the best
moment) → question → follow card.

## 4. The script

- `video/voice/epNN/epNN_<slug>.txt` (one line
  per beat; a blank line is a 0.55 s act pause; `#` lines are notes; `{shown|spoken}` voices the
  spoken text and captions the shown text).
- ~115–130 words for ~40 s of voice at speed 1.1 (EP02: 125 words in 38.6 s).
- The hook lines follow [devlog_hooks.md](devlog_hooks.md) §4: context in the first words, then a lean,
  then a snapback or an open loop. A loop gets a payoff line later, with an on-screen callback.
- The first dev line is the hook line, spoken over the hook visual. With a comment hook it answers the
  comment with personality ("Fair enough."), then "Here's why."; with a comment hook add
  `epNN_comment.txt` (one line) for the second voice.
- Explain with a unit the viewer already feels ("a game draws a new frame about every 16 ms").
- Spell numbers out for Kokoro and show digits in captions: `{576 ms|five hundred seventy six milliseconds}`.
- Write `{Wisp Rush|Wisp, Rush}` (without the comma Kokoro says "Wisp Brush"), and put the name in the
  middle or at the end of a sentence ("a game called Wisp Rush", "now in Wisp Rush"). Never open a
  sentence with it, and never follow it with "has" (it gets heard as "rushes").
- One joke ("Not great for a game called Wisp Rush."), one AI line, and end with a question.
- Palmier's transcription is the pronunciation check. If it mishears a line, rephrase that line.
  EP02: "Fair." → heard "There", fixed as "Fair enough."; "The fix: cover first" → heard "The fake
  cover", fixed as "So here's the fix. Cover first, build later."
  EP03: "But one thing didn't change at all." → heard "The one thing…" (with or without a lead-in
  pause), fixed as "But one thing never changed." Every take that opened with or led into the name
  ("Wisp Rush now has…", "Now Wisp Rush has…", "My game, Wisp Rush, now has…") was heard as "Wisp
  Brush" or "Wisp rushes"; "Thirty new arenas are now in {Wisp Rush|Wisp, Rush}." passed.
- The transcription also drops a rare word at the very start of a clip or right after a sentence break,
  even when it is spoken clearly. Test a line as its own padded file (0.35 s of silence first, e.g.
  `adelay=350|350` before mastering). If only the first word is lost, check the RMS envelope before
  re-voicing.

EP02 (final):
```
Why does your game freeze every time I tap Play?            ← commenter, af_heart 1.12
Fair enough. It froze for over half a second.               ← am_puck 1.1, starts at 2.65 s
Here's why.
A game draws a new frame about every {16 ms|sixteen milliseconds}.
But when you tapped, my game built the whole next screen inside one frame.
That one frame took {576 ms|five hundred seventy six milliseconds}.
Not great for a game called {Wisp Rush|Wisp, Rush}.

So here's the fix. Cover first, build later.
Now a tap first fades the screen to dark.
The next screen builds behind it, then slides in.
And Play builds the whole run behind a new loading screen.

The freeze at the tap? From {576 ms|five hundred seventy six milliseconds}, to zero.
Measured on my Mac. The phone test is next.
My AI coding agent found it and fixed it.
What should I fix next?
```

## 5. Make the pieces

All commands are in the README; this is what each episode needs.

| Piece | How | EP02 |
|---|---|---|
| Menu / flow footage | `render_devlog_tour.gd` `tour=menus` or `tour=story` (real Main, isolated save) | `tour_menus.mp4`: boot, Rift Map, Shop tabs, PLAY, loading screen, Aurora Throne run |
| Gameplay footage | `render_gameplay_clip.gd` (bot, event log for the best moments) | the tour's run: 8-kill dash, RUSH, ×30 chain |
| Feel shots (scripted, repeatable) | `render_feel_showcase.gd` in a quiet tutorial arena: `rings` (arrow sweeps onto a line, ×N), `assist` (same drag with AIM ASSIST off, then on), `finisher` (8 in one dash), `five` (slow motion on the last kill), `rush` (full meter, the bot keeps slicing); the log marks every shot, release and kill | EP04: `ep04_feel_v2.mp4`, `ep04_assist.mp4` |
| Arena / scenery footage | `render_arena_showcase.gd` (Endless skins back to back, start held so no enemies spawn; `hud=0`, `wisp=1`; cut on the log's `segment_start`/`segment_end`) | EP03: `ep03_arena_showcase.mp4`, 9 Legendary/Mythic skins × 4.5 s |
| Stills of a moment | `capture_frame` with `mediaRef` + `sourceSeconds` | Home at the tap (8.1 s), Shop settled (9.3 s) |
| Voice + captions | `kokoro_tts.py` → master (README step 3) → `--captions-only --offset <voice start s>` | voice at 2.65 s → SRT offset 2.65 |
| Game sounds | `export_game_audio.gd` → `video/audio/game/` (import the folder) | 32 WAVs |
| Graphic pieces | `devlog_graphics.py kit OUT` + `comment` + `step` ×3 + `bar`; EP03 added `tier` (stone card with a painting, count and tier label), `outline` (the shared Endless floor polygon), `lightmap` (a scenery mask channel as a glow) and `crop` (cut a strip from a contact sheet); EP04 added `code` (a line of code on a dark card, red = bug, cyan = fix), `meter` (a track + fill pair to crop-animate a timer or meter), bar colours and the step icons `target` / `bend` / `slowmo` | `video/graphics/ep02/` – `ep04/` |
| Solid cards / dims | `import_media` `source.matte` `#07090F` | "Matte - void black" |
| Brand / reactions | `assets/art/branding/wisp_rush_logo.png`, `assets/art/characters/wisp/09_hurt.png` | logo gag, hurt Wisp |

Graphic pieces drawn from real UI must match it: step cards use the game's stone `panel_card`, and
colours come from the GDD §9 palette.

## 6. Build the timeline

> **Implemented in Remotion** since EP05: §6.3's cookbook is `src/components`, §6.4's motion rules
> are `src/style/motion.ts`, §6.5's type is `src/style/fonts.ts` with `Headline`/`Label`/
> `MarkerNote`, §6.6's captions are `<Captions>` fed by the Kokoro SRT through
> `tools/video/srt_to_ts.py`, and §6.7's sound map is `<Sfx>` / `<MusicBed>`. The values below are
> still the spec — change them here and in the component together. §6.1 and §6.2 are Palmier-only
> and apply to EP01–EP04.

### 6.0 Palmier project and library (EP01–EP04)

### 6.1 Project and library
- `manage_project create`, name `Wisp Rush Devlog NN - <Title>`, `aspectRatio 9:16`, `fps 60`,
  `quality 1080p`. Rename the timeline `EPNN <Title> v1` (`organize_media renames`).
- Import: footage → `Footage`, voices + SRT → `Voice`, the graphics folder → `Graphics`, the game
  audio folder → `Audio`, logo/reaction art → `Brand`, references → `References`.
- Check both voices with `inspect_media` (transcript, `wordTimestamps: true`) before placing
  anything. Word times set every beat's frame.

### 6.2 Track stack (top → bottom)
Clips on one track never overlap: a new clip trims or splits whatever is there. So every layer
that must coexist gets its own track. `add_texts` / `add_clips` without `trackIndex` create a new
**top** track and shift every index, so re-read `get_timeline` (or use trackIds) after each call.
Name tracks with `manage_tracks set`.

| Track | Holds |
|---|---|
| Captions | the SRT caption group (always on top) |
| Note, Result, Before, Label, Zero, Numbers, Kinetic, Headline | text layers; as many as appear at once (EP02 needed 8 on the numbers board) |
| Arrow, Rings | draw-on arrows / underlines, tap rings, extra step cards |
| FX | touch dots, arrows, reaction stickers, step card 2 |
| Cards | the comment card, the freeze bar, logo, step card 1 |
| Mid | frame strip, frost overlays, stills that slide in |
| Dim | void matte with opacity keyframes (dims, black-outs) |
| Base | footage, stills, grid backdrop, black beat cards |
| Audio: Game · Voice · SFX · Accents · Music | linked footage audio · both voices · one-shot sounds · overlapping one-shots · music bed |

### 6.3 Element cookbook (EP02 values)
Positions are centres in 0–1 canvas units. `pop` / `ring` / `size` are `tools/video/palmier_motion.py`
commands; paste their rows into `set_keyframes`.

| Element | Recipe |
|---|---|
| Hook background | footage at `speed` ~0.5; `blur` keyframes 28 → 0 over its last 24 frames; `apply_color saturation 0.9`; void matte on Dim at opacity 0.55 → 0 over the same frames |
| Comment card | image (1060×556) on Cards from frame 4 until just after the answer starts (EP02 4–168): `custom 0.5 0.44 0.92 1060 556 "0:0.55:0:0:0,5:1.1:1:0:0,9:0.97:1:0:0,12:1:1:0:0,130:1.12:1:0:0,150:1.35:1:0:0.01,163:2.1:0:0:0.03"`; rotation `[[0,-4],[12,-2],[130,-2],[163,-9]]`; opacity `[[0,0],[5,1],[150,1],[163,0]]` (it flies at the camera as the answer starts) |
| Series tag | Anton 66, two lines `WISP RUSH` / `DEVLOG #n`, `#EAFDFF`, outline `#111521` 8, cyan glow (shadow `#62E8F2` 0.75, blur 26, no offset), lineSpacing −6, `popIn`, y 0.175, over the hook |
| Tap | touch dot (w 0.14, h 0.079) on the button, fade in 3 / out 6–8, 20–33 frames; tap ring `ring X Y` (a 20-frame clip) starting 2–6 frames after the dot |
| Freeze stamp | still of the moment + frost overlay (opacity 0 → 1 in 8 frames, out in 6) + Anton 170 `FROZEN` `#BEEEFF`, outline `#0B3A52` 10, glow `#9FE7FF` 0.9 blur 34, rotation −7, y 0.36 |
| Black beat card | void matte on Base, one word in Anton ≈205, white glow (0.85, blur 40), y 0.47, ~1 s |
| Grid explainer | `bg_grid` on Base for the whole explanation |
| Frame strip | `frame_strip` w 2.639 h 0.109 at y 0.46; position `[[0,0.35,0.405],[12,0,0.405,"linear"],[253,-0.9,0.405,"hold"],[last,-0.9,0.405]]` (slides in, scrolls, stops when the failure appears); opacity in 8 / out 14 |
| Growing failure bar | `freeze_bar_blank` at (0.783, 0.46) w 0.767 h 0.124; crop `[[0,0,1,0,0],[45,0,0.21,0,0]]` (grows rightwards in 0.75 s) |
| Number slam | Anton, freeze red `#FF3B5C`, outline `#2A0610` 8, red glow 0.9 blur 40, `popIn`, below a white Anton "ONE FRAME TOOK"; a marker note under it ("= 35 frames frozen") |
| Logo gag | logo `pop 0.5 0.40 0.78 1318 956 75 --out 0`; split the clip at the joke word; second half: `apply_color temperature 4200, saturation 0.45, exposure 0.25, highsHue 195, highsAmount 0.35`, rotation shake `[[0,0],[2,-2.5],[4,2],[6,-1.5],[8,1],[10,0]]`, frost overlay; hurt Wisp `pop 0.76 0.62 0.36 362 362 64 --out 5` with rotation wobble `[[0,14],[8,-6],[16,8],[26,-4],[40,6],[63,6]]`; marker "oops." amber 80, rotation −10 at (0.3, 0.64) |
| Fix headline card | void matte; Poppins 45 `SO HERE'S THE FIX` `wordReveal` y 0.345; Anton 99 white `COVER FIRST` y 0.455 on the spoken word; amber underline (w 0.7, y 0.515) crop `[[0,0,1,0,0],[10,0,0,0,0]]`; Anton 99 cyan `BUILD LATER` y 0.585 |
| Step cards | `step` PNGs (383×483); `pop X 0.205 0.27 383 483 <dur>` at X = 0.2 / 0.5 / 0.8, each on the first word of its spoken step; they stay until the section ends |
| Dim for steps | void matte on Dim: `[[0,0],[20,0.93],[204,0.93],[222,0]]` so the step cards read, then the UI returns |
| Screen slides in | the new screen's still on Mid, 0.08 to the right, blur 14, opacity 0.3 under the dim; then position → 0, blur → 0, opacity → 1 over 14–18 frames as the dim lifts |
| Marker arrow | `arrow_*` w 0.11 (h 0.111) beside its note; crop draw-on `[[0,0,0,1,0],[12,0,0,0,0]]` (down arrow: bottom inset 1 → 0); fade out 6–8 |
| Slowed UI | footage `speed` 0.35–0.4 (+ `durationFrames`) for UI changes too fast to read; its audio −14 to −16 dB |
| Numbers board | grid; pill (Poppins 40, tracking 3, background `#1B2A30` 0.95, radius 22, padding 34/16, outline cyan 3) at y 0.235; per row: label Poppins 44 `#9FB3C8` tracking 6, before Anton red at x 0.25, `arrow_right` (w 0.17) at x 0.535, after Anton cyan at x 0.78; rows at y 0.43 / 0.585, labels 0.07–0.085 above (sizes: 576 MS 77, 0 MS 108, 271 MS 64, 0 MS 84); red strike (w 0.44) on the first before, crop right 1 → 0 in 8; context line Poppins 23 `#8FA3B8` at y 0.665. Reveal order: label → before → strike → arrow → after |
| AI credit pill | Poppins 40, two lines, tracking 2, background `#0B0E16` 0.96, radius 18, outline cyan 2, y 0.215, over gameplay while the AI line is spoken |
| Question | Anton 72 white `WHAT SHOULD I` y 0.41, then Anton 118 cyan `FIX NEXT?` y 0.5; a down arrow rotated −28° at (0.84, 0.585) pointing to TikTok's comment button |
| Follow card | Dim matte 0 → 0.62 in 12 frames over gameplay; Anton 80 cyan `FOLLOW FOR` y 0.43; Anton 108 white `DEVLOG #n+1` y 0.52 (8 frames later) |

### 6.4 Motion rules
- `position` = top-left corner, `scale` = normalized width/height (not a factor), `rotation` around
  the centre, `crop` = `[frame, top, right, bottom, left]`. Keyframe frames are clip-relative; the
  last usable frame is length − 1.
- Images are placed full-canvas-width: always set `transform {centerX, centerY, width, height}` with
  `palmier_motion.py size`, or use keyframes.
- Pops: 0.55 → 1.10 → 0.97 → 1.00 in 12 frames, opacity in 5. Shrink out: 1.0 → 0.75 with opacity 0
  over the last 6.
- Land every visual on its spoken word's frame (0–2 frames early is fine) and put its sound on the same frame.
- Something new every 0.7–2.5 s: a cut, a pop, a draw-on or a caption change. No still screen longer than ~3 s.
- At most two big text elements at once (the numbers board is the exception: it builds up piece by piece).
- Punch-ins on footage: `transform` width and height 1.15–1.3, with `centerY` kept within
  [1 − h/2, h/2] so the frame stays covered.

### 6.5 Text
- Fonts bundled with Palmier: Anton (headlines), Poppins-Bold (labels, captions), PermanentMarker-Regular
  (notes), BebasNeue, Inter, DMSans, SpaceGrotesk, Geist.
- Palmier renders `fontSize` ≈ 1.78× the PIL pixel size, and a line wraps past ~850 px. Size every
  headline with `palmier_motion.py fit-text <font> "<TEXT>" <px>` and keep centred text ≤ 800 px.
  EP02 sizes: `576 MS` 146 (760 px), `ONE FRAME TOOK` 63, `COVER FIRST` 99, `FIX NEXT?` 118,
  `DEVLOG #3` 108, `WHY?` 205, `FROZEN` 170, `1 FRAME = 16 MS` 74, marker notes 41–80.
- A newline in `content` must be a real line break. `\n` typed inside an escaped string stays
  literal (check the tool's echo).
- Safe zones: keep text out of y < 0.09 (TikTok tabs), x > 0.86 for y 0.45–0.87 (the right rail),
  and y > 0.87 (the description). Captions sit at y 0.73, headlines at 0.2–0.7.

### 6.6 Captions
- `add_captions subtitleMediaRef <SRT>` (never transcription on Kokoro audio: its cues land
  0.4–0.8 s early), then `update_text captionGroupId`: `highlightPop`, highlight `#62E8F2`, style
  Poppins-Bold 66, `#FFFFFF`, uppercase, `widthScale 0.86`, outline `#0B0E16` 9, shadow `#000000`
  0.55 blur 14 y 5, transform y 0.73.
- Cues are ≤ 3 words / ≤ 15 characters (`kokoro_tts.py` splits them that way). A wide cue full of
  W/M letters may need `widthScale` 0.76 on that clip.
- `get_timeline captionDetail:true`, then `remove_clips` any cue a big headline already shows (EP02
  removed 13: WHY, the 576 line, the fix rule, the numbers lines, the question).
- If a cue covers a button being tapped, move just those cues (`update_text clipIds`, transform
  y 0.6).

### 6.7 Sound
| Layer | Level |
|---|---|
| Voices (mastered) | 0 dB |
| One-shot SFX (SFX track) | −9 dB; slams and reveals −11 dB; SFX that land on a spoken word −15 dB |
| Accent SFX (overlaps) | −11 dB |
| Game audio from footage | −12 to −14 dB; slowed shots −16 dB; under the voice during busy gameplay −18 dB (volume keyframes), back to −11 dB once the voice ends |
| Music bed `bed_calm` (game's own) | −22 dB, fade in 20 frames, out 60, under the explainer only |

| Visual event | Game sound |
|---|---|
| card / pill / tap pop | `ui_confirm` |
| whoosh (card flies out, strip slides in, screen slides) | `dash` |
| stamp / impact / freeze hit | `wall_impact`, then `player_dissolve` (accent) |
| big word or number slam | `reaper_hit` (−11) |
| growing failure / tension | `reaper_windup`, `aim_tension` |
| reveal steps / headlines | `slice_step1` → `slice_step3` → `slice_step5` (rising) |
| a win / "after" number | `level_up` |
| strike-through | `slice` |
| dim / back | `ui_back` |
| reaction gag | `player_damage` (accent), logo shine `ui_purchase` |
| question | `upgrade_choice` |
| follow card | `shard_pickup`, then `slice_step8` |

## 7. QA, export, watch back

1. `inspect_timeline` with 12 frames across each section, then again across the whole cut. For a
   full-resolution look: `capture_frame timelineFrame N`, then `inspect_media` on that asset.
   Delete QA assets afterwards.
2. Check for: no wrapped or clipped headline, nothing overlapping by accident, captions readable and
   never over a tapped button, nothing in the TikTok safe zones, numbers matching the brief, the AI
   line present, no forbidden claims (brief §6), no rough edges from brief §7 on screen.
3. `export_project` mode video, H.264, Match Timeline, `outputPath`
   `video/exports/wisp_rush_devlog_NN_<slug>.mp4`; poll `manage_exports list`.
4. `ffprobe` (1080×1920, 60 fps, AAC 48 kHz, < 60 s) and
   `ffmpeg -i OUT -af ebur128=peak=true -f null -` → integrated about −14.5 LUFS, true peak ≤ −1 dBTP
   (EP02: −14.5 LUFS, −2.7 dBTP). If it clips, find the loud 0.1 s windows with `astats` and lower
   what overlaps there.
5. Import the export and watch it with `inspect_media` `overview` + transcript. Every line should
   read correctly (EP02: "agent" was misheard as "engine" until the game audio under it was ducked).
   Then remove the QA asset.

## 8. Gotchas

- "Editor not available" means the session's project closed. Run `manage_project open` again.
- `capture_frame` PNGs live inside the sandboxed `.palmier` package, so the shell can't read them.
  View them with `inspect_media`.
- `organize_media deletes` removes library items only, never the files on disk.
- `import_media` of a folder mirrors its sub-folders (`Graphics/ep02`, `Audio/game/sfx`).
- A caption cue whose transform you change shows up separately in `get_timeline`. That's harmless.
- Speed changes: `set_clip_properties speed` + `durationFrames`. Linked audio follows, so set its
  volume on the nested `audio.id`.
- `apply_color reset:true` clears a grade. A negative exposure on a blurred intro made it muddy;
  saturation alone was enough.
- Kokoro WAVs peak near 0 dBFS: master them before import, or the export clips (EP02 draft: +1.0 dBTP).
- The tour capture never sees the run loading screen settle; its wait handles that already.
- The disk is small (a few GB free): transcode captures right away and delete the AVIs.

## 9. EP02 frame map (60 fps)

| Frames | Base / Mid / Dim | Cards / FX | Text | Sound |
|---|---|---|---|---|
| 0–165 | tour 1.05–2.45 s at 0.509×, blur 28 → 0; Dim 0.55 → 0 | comment card 4–168; touch dot 168; ring 170 | tag 6–150 | commenter 0; `ui_confirm` 4; `dash` 148; `ui_confirm` 170; `bed_calm` 0–2140 |
| 165–303 | tour 7.75–8.1 s; Home still 186; frost 186–303 | — | `FROZEN` 196–300; captions at y 0.6 | dev voice 159; `wall_impact` 186; `player_dissolve` 192 |
| 303–360 | void matte | — | `WHY?` 305 | `reaper_hit` 305 |
| 360–1015 | grid; frame strip 360–1015 | arrow ↓ 420; dot 600 + ring 604; freeze bar 618–1015 | `1 FRAME = 16 MS` 404; `you tap` 606; `ONE FRAME TOOK` 813; `576 MS` 873; `= 35 frames frozen` 930 | `dash` 360; `slice_step1` 404; `ui_confirm` 600; `reaper_windup` 618; `slice_step3` 813; `reaper_hit` 873 |
| 1015–1164 | grid; frost 1090–1164 | logo 1015 (frozen from 1090); hurt Wisp 1100 | `oops.` 1104 | `ui_purchase` 1015; `wall_impact` 1090; `player_damage` 1100 |
| 1164–1316 | void matte | underline 1225 | fix card 1166 / 1217 / 1250 | `slice_step3` 1217; `slice_step5` 1250 |
| 1316–1632 | Home still; Dim 1352–1600; Shop still slides 1470 | dot on SHOP 1330 + ring 1336; step 1 1352, 2 1470, 3 1556 | `building...` 1480 | `ui_confirm` 1336; `ui_back` 1352; `level_up` 1470; `dash` 1556 |
| 1632–1850 | tour 30.75–31.1; 31.1–31.84 at 0.347×; 31.84–33.0 | dot on PLAY 1636 + ring 1640; arrow ↓ to the loading bar 1668 | `run builds here` 1672 | `ui_confirm` 1638; `aim_tension` 1668 |
| 1850–2130 | grid | strike 2000; arrows 2020 / 2045 | numbers board 1855 → 2045 | `slice_step1` 1855; `reaper_hit` 1916; `slice` 2000; `aim_tension` 2020; `level_up` 2035; `slice_step5` 2045 |
| 2130–2476 | tour 36.95–37.6 at 0.398×; 37.6–40.9; 40.9–44.17 | arrow to the comment button 2402 | AI pill 2248; question 2402 / 2425 | `slice_step1` 2248; `slice_step3` 2402; `upgrade_choice` 2425 |
| 2476–2622 | Dim 0 → 0.62 | — | `FOLLOW FOR` 2478; `DEVLOG #3` 2486 | `shard_pickup` 2478; `slice_step8` 2486 |

## 10. After an episode

- README episode table: the project, timeline, export path and status. Add the source and licence of
  any stock clip.
- A `docs/DEVLOG.md` entry (what the video covers, QA numbers, follow-ups).
- The hook log row in [devlog_hooks.md](devlog_hooks.md) §6 (spoken idea, visual treatment, lines).
- If the owner changes a rule, update §1 here in the same session. This file is the recipe of record.
