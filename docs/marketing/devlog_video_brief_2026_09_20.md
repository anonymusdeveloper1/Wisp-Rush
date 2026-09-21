# Devlog video brief — session 2026-09-19 → 2026-09-20

> **For the agent (or human) cutting TikTok / YouTube devlog videos.** What changed in this session,
> which parts are worth filming, how to capture them, and what must never be claimed. Facts live in
> [DEVLOG.md](../DEVLOG.md) (newest first) and the system docs; this file only adds the video angle.
>
> **How to cut the videos:** [devlog_video_recipe.md](devlog_video_recipe.md) (owner-approved
> 2026-09-16), hooks from [devlog_hooks.md](devlog_hooks.md), commands in
> [tools/video/README.md](../../tools/video/README.md).
>
> **Status of the build:** pre-release Android debug APK on the owner's Galaxy S24. No store page, no
> release date, no monetisation live. Nothing in this session is committed to git.

## 1. The one-line story of the session

The roster was **cut in half and then rebuilt in a completely different way**: bone rigs were
abandoned for hand-drawn frame animation, every remaining character was redrawn as 108 frames, and
the last two still images in the game finally started moving.

That is the spine of the episode. Everything else is a supporting beat.

## 2. What shipped, in filming order (best first)

| # | Feature | Why it films well | Where to capture |
|---|---|---|---|
| 1 | **Three fully hand-animated characters** — Shade, Void, Eclipse | 108 frames each, 16 animations. Side-by-side of the old still image vs the new animation is the money shot | Shop → CHARACTERS, swipe between them; then PLAY |
| 2 | **Void and Eclipse stopped being still images** | The *default* character you start with was a static PNG for the whole project until now | Home screen, then a run |
| 3 | **The arena Shop became a gallery** | 30 arenas went from 30 swipes to a scrollable grid; tapping one opens it full-screen the way a run shows it | Shop → ARENAS, scroll, tap a Mythic arena |
| 4 | **The bug you can actually see** | Fragments of one animation frame leaking into another — a real artefact, found and fixed twice for two different reasons | Use the before/after stills in §4 |
| 5 | **Decluttered run HUD** | Boss bar went from a 170 px framed plate to a 76 px line; RUSH moved to the bottom; the portrait ring is gone. More arena visible | Any run, ideally one with a boss |
| 6 | **Dash slowed 20%** | A feel change with a number attached: 3,960 → 3,168 px/s | Same-seed before/after run |
| 7 | **Shop opens instantly again** | 695 ms → 261 ms → ~25 ms on the device, across three fixes | Screen-record Home → Shop |

## 3. The three stories worth a whole episode each

### A. "We deleted half the characters"

The roster went from **13 to 7**, then back to 9 as new ones landed. Ash, Venom, Bloodmoon and
Frost were retired. Bram was retired. The bone-rigged Ilyra was retired and her name given to the
sprite version that had been built as a test beside her — the experiment won and replaced the thing
it was testing against.

**The honest angle:** this is a *subtraction* story, which is rarer and more interesting than a
feature list. The reason is real — rigs cost too much authoring time per character.

### B. "Rigs vs frames, and why we switched"

A bone rig is a character cut into ~50 pieces on a skeleton. Frame animation is 108 drawings played
back. The project spent weeks on rigs, then switched.

Good visual: the abandoned jointed puppet. It was **built, working, and thrown away** — arms solved
with inverse kinematics, fans in its fists — because it could not match the finish of painted
frames. There are renders of it in the session history.

**The line that lands:** a 12-frame loop is few frames, but 12 *registered* frames beat 4
beautiful unregistered ones. Registration — every frame drawn on the same anchor pixel — turned out
to matter more than drawing quality.

### C. "The fragment bug"

Twice in one session, players saw a sliver of a different animation frame stuck to the character.
Same symptom, two completely different causes:

1. **Atlas bleed.** Frames packed edge-to-edge in one texture; the GPU's filter sampled half a pixel
   outside the frame and picked up the neighbour. Fixed with an 8-pixel transparent gutter.
2. **Clipped source art.** A character drawn bigger than its own canvas, so the crystal above its
   head was severed by the border. The missing pixels cannot be recovered — the severed remains are
   removed instead.

**Why it films well:** it is a proper detective story with a measurable before and after, and the
"same symptom, different disease" twist is genuinely satisfying.

## 4. Footage and stills that already exist

All under `logs/` in the repo (git-ignored, so capture fresh if they have been cleared):

| File | What it shows |
|---|---|
| `void_states.png`, `eclipse_states.png` | All 17 animations of a character on one board |
| `void_menus.png`, `eclipse_menus.png` | Home and the Shop card |
| `void_gameplay.png`, `eclipse_gameplay.png` | The character in a live run |
| `storefront_idle_test.png` | All three cards side by side |
| `arena_grid_final.png` | The new arena gallery |
| `void_stray_check.png`, `strip2.png` | The fragment bug with the offending pixels marked in red |

Re-capture any of them with:

```bash
WISP_CHARACTER=void tools/screenshot.sh res://tools/godot/render_whole_frame_states.tscn 260 540x960
```

Swap `void` for `eclipse` or `verdant_shade`. The same `WISP_CHARACTER` variable drives
`render_character_home_showcase`, `render_character_select_showcase` and
`render_character_gameplay_showcase`.

## 5. Numbers that are safe to put on screen

Every one of these was measured in this session, on the owner's Galaxy S24 or in the repo:

- **108 frames** per character; 16 animations; **0.5 px** registration across the whole pack.
- Roster **13 → 7 → 9**.
- Boss readout **170 px → 76 px** tall.
- Dash **3,960 → 3,168 px/s** (−20%).
- Shop first-open **695 ms → 261 ms → ~25 ms**.
- Arena browsing **30 swipes → one scrollable grid**.
- Live Shop cards **8 of 8 → 2 of 8** (the rest use a still portrait).
- Texture budget: every packed sheet stays under **4096 px**, the size every phone is guaranteed to
  accept.

## 6. What must never be claimed

- **No release date, no store page, no price.** Character prices are placeholders (0 RP) pending the
  owner's decision; Shade's tier and even its *name* are still provisional.
- **Do not call the art final.** Every pack is "licence to confirm before release".
- Do not show the four retired Wisp forms or Bram as if they are in the game — they were removed.
- Do not imply the remaining bone-rigged characters (Veyra, Rook, Morrow, Noxen) are being deleted.
  They are staying until they are re-cut as frames, and no date is set.
- The ten failing tests in the suite are **pre-existing and unrelated** (they reference a screen
  retired in an earlier milestone). Do not present them as new breakage, and do not present the
  suite as fully green either.
- Two art packs have **known defects** recorded in the ROADMAP backlog. If the videos show the
  characters, that is fine — the defects are cleaned up on intake — but do not claim the source art
  is flawless.

## 7. Suggested hook angles

Pull the actual wording from [devlog_hooks.md](devlog_hooks.md); these are the session-specific
angles that fit it:

- "I deleted half the characters in my game." (subtraction hook, story A)
- "I spent weeks building a skeleton system, then threw it away." (story B)
- "There was a piece of a different animation stuck to my character." (story C)
- "My shop took 30 swipes to browse." (arena gallery)
- "Half a second of lag, and it took three attempts to kill." (the Shop hitch)
