# Devlog video brief — session 2026-09-15 → 2026-09-16

> **For the agent (or human) cutting TikTok / YouTube devlog videos.** What changed in this session,
> which parts are worth filming, how to capture them, and what must never be claimed. Facts live in
> [DEVLOG.md](../DEVLOG.md) (newest first) and the system docs; this file only adds the video angle.
>
> **How to cut the videos:** [devlog_video_recipe.md](devlog_video_recipe.md) (owner-approved
> 2026-09-16). §8's suggestions are superseded by the episode table in `tools/video/README.md`.
>
> **Status of the build:** pre-release Android debug APK on the owner's Galaxy S24. No store page, no
> release date, no monetisation live. Nothing in this session is committed to git yet.

## 1. The one-line story of the session

The game stopped being "one endless mode with a shop" and became **two modes with a real economy**:
finite story Rifts, a cosmetic Endless mode with 30 arenas, one currency (Rift Points), a RUSH power
burst, a real tutorial, and a navigation/loading pass that removed the freezes.

## 2. What shipped, in filming order (best first)

| # | Feature | Why it films well | Where to capture |
|---|---|---|---|
| 1 | **30 Endless arena skins** with animated scenery | The strongest visual: aurora ribbons, rotating eclipse corona, swirling galaxy, glowing abyss gate, dragon-skull embers | Shop → ARENAS (swipe the carousel), then PLAY on a Mythic skin |
| 2 | **RUSH mode** | 6 s of ×1.3 speed, ×2 score, no damage, peak music — a clean "power fantasy" beat | Any run: fill the meter under the XP bar, RUSH starts itself |
| 3 | **Slow-motion finisher** | A 5-kill dash, a cleared field or a boss killing blow drops time to 0.3× for ~0.4 s | Any run; easiest on a dense wave |
| 4 | **Interactive tutorial** (9 lessons) | A ghost hand demonstrates, then the player repeats — very readable in a 15 s clip | RIFTS → TUTORIAL |
| 5 | **Aim help** | Cyan rings light up every enemy the dash will slice, with a ×3 combo count, plus a gentle 6° aim assist | Any run: hold to aim beside a cluster |
| 6 | **Story Rifts** | One level per run, the boss ends it, clearing level 1 opens the next Rift | Rift Map → ENTER, beat the boss |
| 7 | **Upgrade cards** | Cards slide up in slow motion at a calm moment instead of pausing the game | Any run after a level-up, or tap the UPGRADE button |
| 8 | **New loading screen** | Random painted arena background, slow zoom, logo, arena name, LOADING… bar | Home → PLAY |
| 9 | **Before/after: navigation freeze** | Numbers land well in a "polish" video: tap-to-build went from 87–576 ms to 1.6–29 ms | Screen-record menus; read the numbers from this file |

## 3. Feature detail worth narrating

- **Rift Points (RP)** replaced Soul Shards. The Soul Sanctum was removed and its spend refunded, so
  power no longer carries between runs — cosmetics only.
- **Story mode:** a Rift run plays exactly one level of 4 waves and ends in victory on the level's
  boss. Clearing level 1 of a Rift opens the next one. 8 levels per Rift, 5 Rifts, 5 bosses.
- **Endless:** PLAY always starts Endless, open from the first launch, on one shared floor shape with
  a cosmetic skin over it. Every Rift's enemies and bosses can appear. Waves never pause: a new
  formation arrives while ≤ 2 enemies are alive.
- **Shop:** one screen, four tabs — WISPS (6 forms), DASHES (4 trail colours), ARENAS (30 skins),
  NO ADS. Prices: Simple 300 · Rare 800 · Legendary 2,000 · Mythic 3,500 RP (01–03 keep 0/800/1,200).
- **Arena scenery:** a shader grades the painting (Mythic scenery roughly doubles in saturation), its
  own light sources breathe and flare, water/fire/aurora/clouds move, and glow particles (embers,
  snow, stardust, fireflies) drift in the scenery. **The playable floor never changes** — same shape
  on all 30 skins, floor brightness unchanged so the Wisp stays the brightest object.
- **Tutorial lessons:** aim & dash → slice → chain → mid-dash redirect → blockers → hazards → RP & XP
  → RUSH → boss. The Wisp cannot die in it.
- **Performance/UX pass:** tap now covers the screen first and builds behind it; a run is built and
  its shaders warmed up behind the loading screen.

## 4. Numbers that are safe to show on screen

From the DEVLOG entries of 2026-09-15/16 (device = Galaxy S24, desktop = M2):

- Navigation build time at the tap: **271 ms → 0 ms** (Rift Map), **576 ms → 0 ms** (PLAY), desktop.
- First run of a session, worst frame after the loading bar: **74 ms → 10 ms** (desktop), phone
  before was 270 ms build + 196 ms worst frame.
- Endless arena art in the build: **45 MB → 3.7 MB** after lossy import; APK ≈ 78 MB.
- Dash speed lowered 10 % (4,400 → 3,960 px/s) at the owner's request.
- Art checker: **24 of 30 skins pass every metric**; 6 pass by eye review (a wide flat decorative
  border reads as floor to the heuristic).

Do **not** put unverified claims on screen (frame rate, "runs at 60 FPS on any phone", install size
of a release build, player counts).

## 5. How to capture

- **On device (best quality, real feel):**
  `~/Library/Android/sdk/platform-tools/adb shell screenrecord --time-limit 30 /sdcard/clip.mp4`
  then `adb pull /sdcard/clip.mp4`. Portrait 1080×2340 is already TikTok/Shorts ratio.
- **Deterministic in-engine renders** (no phone needed), from the repo root:
  - `tools/screenshot.sh res://scenes/screens/home_screen.tscn 24 1080x1920` → `logs/screenshot.png`
  - `tools/godot/render_endless_scenery_sheet.gd` — every Legendary/Mythic skin, 3 frames each
  - `tools/godot/render_*_showcase.gd` — pause menu, Reaper, upgrades, wall splash, aim arrow, Home motion
  - `tools/qa_matrix.sh <screen>` — the same screen at 5 phone sizes (good for "fits every phone" shots)
- **Existing stills to reuse:** `logs/endless/scenery_round0_before.png` (old effects) vs
  `scenery_round3.png` (new) is a ready-made before/after; `logs/endless/check_sheet.png` shows the
  floor-template overlay for a "how we keep arenas fair" clip.
- **Branding:** profile pictures at 1080×1080 in `~/Desktop/Wisp Rush Social/`
  (`wisp_rush_logo_mark_profile_1080.png`, `wisp_rush_emblem_profile_1080.png`,
  `wisp_rush_wordmark_profile_1080.png`). The in-game wordmark is
  `assets/art/branding/wisp_rush_logo.png`.

## 6. Hard rules for anything published

- **Never claim the art is hand-drawn, hand-painted or made by a human artist.** It is generated art.
  The production licence is still unconfirmed ([GDD](../GDD.md) §14 #1, #21) — settle it before any
  paid promotion or store page.
- **Never use** `concept_art/wisp_rush_redesign_v1/assets/01_visual_target_key_art.png`: it shows a
  joystick, skill buttons and a minimap the game does not have.
- **No release date, no store link, no pre-registration claim** until the owner sets them. "Coming
  soon to mobile" is the safe line.
- **No monetisation promises.** The Shop's NO ADS tab is visible but disabled; there is no billing.
- Placeholder content must not be filmed as final: the ghost hand in the tutorial is a code-drawn
  placeholder, and Rift level balance is untuned.

## 7. Known rough edges (avoid filming, or film honestly as "work in progress")

- One 681 ms stall when the run loading screen loads its random background (fix pending).
- HUD text can be hard to read over bright painted scenery on Quartz Grotto, Slate Cliffs and Dusk
  Sandstone; Mythic top set pieces sit partly behind the score plate.
- The Settings screen overflows in debug builds (developer card); no scrolling yet.
- Most headless tests are stale after the rework; only the new/updated ones pass.
- Six skins have wide flat decorative borders that could read as walkable.
- Balance (RP pacing, prices, Rift difficulty, RUSH frequency) is all starting values.

## 8. Suggested first three videos

1. **"I rebuilt my game's arenas"** — the 30 skins carousel, then a Mythic run: before/after scenery
   stills, then live gameplay. 30–45 s.
2. **"Making a dash feel good"** — aim rings + ×3 count, the 6° aim assist, the slow-motion finisher,
   then RUSH. Narrate the 10 % speed drop and why. 30 s.
3. **"Why my menus were freezing"** — the tap-to-build numbers, the cover-then-build fix, the new
   loading screen. A polish/dev-process video for YouTube. 60–90 s.

## 9. Where to read more

[DEVLOG.md](../DEVLOG.md) (session entries 2026-09-15/16) · [GDD.md](../GDD.md) §5–§6, §11 ·
[systems/endless_mode.md](../systems/endless_mode.md) · [systems/rush_mode.md](../systems/rush_mode.md) ·
[systems/tutorial.md](../systems/tutorial.md) · [systems/shop.md](../systems/shop.md) ·
[systems/rifts.md](../systems/rifts.md) · [specs/story_and_endless/](../specs/story_and_endless/README.md)
