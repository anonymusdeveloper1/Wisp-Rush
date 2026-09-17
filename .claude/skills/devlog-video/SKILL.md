---
name: devlog-video
description: Make a Wisp Rush devlog video (TikTok / YouTube Shorts) in Palmier Pro the owner-approved way — topic from the session brief, a rotating hook, motion-graphics explainer, Kokoro voice, game footage and sounds, QA and export. Use when asked to create, edit, plan or fix a devlog / TikTok / Shorts video about the game.
---

# Devlog video

Repo root: `/Users/dimitarslezenkovski/Desktop/Wisp Rush`. The recipe of record is
`docs/marketing/devlog_video_recipe.md` — read it fully first; commands are in `tools/video/README.md`;
what may be shown or claimed is `docs/marketing/devlog_video_brief.md` (§4, §6, §7).

1. **Topic.** Read the brief and the newest `docs/DEVLOG.md` entries. Unless the owner already named
   the topic, offer 3–4 (title + structure A/B/C from recipe §3) and let them pick. Make **one** video
   per request; never batch unless asked.
2. **Palmier.** Tools are `mcp__palmier-pro__*` (the app must be open; "Editor not available" → call
   `manage_project open` again). `manage_project create` a new project
   `Wisp Rush Devlog NN - <Title>` (9:16, 60 fps, 1080p) — never edit another episode's project,
   and only *read* the EP02 reference project.
3. **Style check.** Import `video/references/ref1-4.mp4` and watch them (`inspect_media` overview,
   then frame windows) if you haven't this session.
4. **Hook, script and voices** (recipe §3.1, §4, README step 4).
   - Pick ONE spoken hook idea from `docs/marketing/devlog_hooks.md` (H1–H9, from the owner's three
     hook TikToks) and use its template so it is recognizable. Take the ideas only, never their look.
   - Pick a recipe §3.1 visual treatment too. The previous episode (hooks §6 log) must not have used
     the same idea or treatment.
   - Run the context → lean → snapback test.
   - Write the dev script (`am_puck`, plus an `af_heart` line only for the comment treatment).
   - Master, import, read the transcripts, rephrase anything misheard, re-voice.
5. **Pieces** (recipe §5): capture footage (`render_devlog_tour.gd` / `render_gameplay_clip.gd`),
   transcode, `capture_frame` stills, `export_game_audio.gd`, `devlog_graphics.py`, void matte.
6. **Build** the timeline with the recipe §6 track stack and cookbook values; use
   `tools/video/palmier_motion.py` for every pop, ring, image size and headline font size.
7. **QA and export** (recipe §7): `inspect_timeline` + `capture_frame`, fix wraps/overlaps/safe
   zones, export to `video/exports/wisp_rush_devlog_NN_<slug>.mp4`, check `ebur128`
   (≈ −14.5 LUFS, ≤ −1 dBTP), then watch the export back with `inspect_media`.
8. **Record** (recipe §10): README episode row, hooks §6 log row, DEVLOG entry; send the file to the owner
   (`SendUserFile`) and ask for notes. If the owner changes a rule, update recipe §1 the same session.

Generation tools (`generate_*`, `upscale_media`) cost money — ask first. Stock footage only with an
open licence, noted in the episode row.
