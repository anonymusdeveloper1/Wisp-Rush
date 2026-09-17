# System: Tutorial

> **Status:** ✅ done (device pass pending) · **Last updated:** 2026-09-15 · **GDD section:** §11, §14 #29
>
> **Changed 2026-09-15 (owner decision):** a separate Tutorial screen replaced the in-run first-run
> lesson (`TutorialOverlay`, `GameWorld.tutorial_enabled` / `tutorial_completed`). Real runs never teach.

## Purpose

Teach every base mechanic, easiest first, as "show, then you try" lessons: a ghost hand demonstrates
the gesture while the real Wisp performs it, then the player repeats it and the lesson passes only on
success. First launch opens it after Loading; afterwards it is replayable only from the Rift Map.

## Files

| Path | Role |
|---|---|
| `res://scenes/tutorial/tutorial_screen.tscn` / `.gd` | `TutorialScreen`: hosts a scripted GameWorld, step counter, dots, caption, SKIP + confirm, back |
| `res://scenes/tutorial/tutorial_director.gd` | `TutorialDirector`: lesson state machine (demo → try → success → next → complete) |
| `res://scenes/tutorial/tutorial_ghost_hand.gd` | `TutorialGhostHand`: code-drawn placeholder hand (fingertip, drag trail, release ring, real-time tap, HUD focus ring) |
| `res://scripts/resources/tutorial_lesson_data.gd` / `tutorial_catalog.gd` | Lesson and catalog schemas + `validate()` |
| `res://data/tutorial/default_tutorial.tres` | The nine lessons, arena skin id, boss health, every timing |
| `res://scenes/gameplay/run_profile.gd` | `RunProfile.tutorial()` / `MODE_TUTORIAL` / `is_scripted()` |
| `res://scenes/gameplay/game_world.gd` | Run event signals and scripted-run hooks ([core_run.md](core_run.md)) |
| `res://scenes/main/main.gd` | First-launch routing, Rift Map replay, `mark_tutorial_completed` |

## Scene / node structure

```text
TutorialScreen (Control, mouse ignore)          GameWorld is added in _ready as child 0 (MODE_TUTORIAL)
├── %Director (TutorialDirector)
├── GuideLayer (CanvasLayer 9: above the world, under the HUD's layer 10)
│   └── Guide → %SkipButton (SecondaryButton, top-right where the hidden pause button sits)
│             %GuideMargin → Center → %GuidePanel → Copy: StepRow (%StepLabel, %Dots PageDots), %CaptionLabel
├── HandLayer (CanvasLayer 11: above the HUD, so the hand can tap the upgrade tray's cards)
│   └── %GhostHand (TutorialGhostHand)
└── ConfirmLayer (CanvasLayer 12, always processes) → %SkipConfirm: %ConfirmDim (Palette.SCRIM),
    PanelCrest: "SKIP THE TUTORIAL?", %SkipConfirmButton (DangerButton), %SkipCancelButton (SecondaryButton)
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `TutorialScreen.finished(skipped)` | signal | All lessons passed, or SKIP confirmed. Main marks completion and routes. |
| `TutorialScreen.setup(profile)` | method | Profile from Main (`RunProfile.tutorial`); without it (F6) a fallback profile is built. |
| `TutorialScreen.handle_back()` | method | Back / Escape: opens the skip confirm, or closes it. Always consumes. |
| `open_skip_confirm()` / `close_skip_confirm()` / `is_skip_confirm_open()` | methods | Confirm pauses the tree while open (restores only what it paused). |
| `get_game()` / `get_director()` | methods | For tools and fixtures. |
| `TutorialDirector.start(game, hand, catalog, reduced_motion)` / `stop()` | methods | Begin lesson 1 / halt (skip). |
| `TutorialDirector.lesson_started(index, count, lesson)`, `caption_changed(text)`, `lesson_passed(index)`, `completion_started`, `completed` | signals | UI observes these. |
| `get_lesson_index()` / `get_lesson_count()` / `get_phase()` | methods | `Phase { IDLE, DEMO, TRY, SUCCESS, COMPLETE }`. |
| `TutorialGhostHand.play_swipe(from, drag, press, drag_s, hold, release, alpha)` / `stop()` / `is_gesturing()` / `set_focus_rect(rect)` | methods | Emits `aim_changed(drag)` while dragging and `released(drag)` at lift. |
| `TutorialGhostHand.play_tap(point, press, hold, release, alpha)` | method | Real-time tap (reads the same in slow motion); emits `tapped(point)` at lift, never `aim_changed`/`released`. |

## Data & tuning

`TutorialCatalog` (`default_tutorial.tres`): `lessons`, `arena_skin_id` (`astral_observatory`, the
default skin), `boss_health` 3, captions for retry/hit/complete; demo timings (start delay 1.0 s, press
0.3, drag 0.55, hold 0.4 (was 0.2; long enough to read the aim path and ×count), release 0.45, redirect drag 0.1, drag length 260 px, start offset 90 px, gap
0.45, demo hit distance 150 px, settle 0.9; upgrade demo: card look 0.7 real s, tapped card index 1,
tray wait limit 8 real s); try timings (hint every 2.6 s at 60 % alpha, retry 0.8 s,
refill 0.6 s, success 1.3 s, complete 2.0 s, callout ×1.25).
`TutorialLessonData`: id, title, demo/try captions, success callout, `goal` (`wall_dash`, `kill`,
`chain`, `redirect_kill`, `safe_kill`, `upgrade`, `rush_kill`, `boss`), `goal_count`, `player_start`,
`enemy_kind` + `enemy_positions`, `rush_positions`, `hazard_kind` + `hazard_position`, `spawns_boss`,
`demo_swipes` (`Vector2.ZERO` = aim at nearest target), `redirect_swipe_index`, `demo_drives_wisp`,
`demo_shows_hit` + `demo_hit_reform`, `reset_after_demo`, `retry_on_miss`, `hud_focus`,
`experience_enabled`, `demo_experience_share`, `demo_upgrade_tap`, `drops_shards`, `rush_enabled`,
`rush_start_share`.
Positions are arena UV (0..1 of the playfield rect, clamped onto the floor).

## Dependencies

GameWorld (scripted-run hooks, run event signals), WispPlayer (`set_input_enabled`, `preview_aim`,
`perform_swipe`, `place_at_edge`), ReaperBoss (`configure(..., health_override)`), EndlessCatalog,
SaveManager (`mark_tutorial_completed`, Reduced Motion), `PageDots`, `SoundFx`, the Theme.

## Rules & behaviour

- **Lessons (easy → skilful):** 1 aim & dash (goal: a wall landing) · 2 slice one Soul Wisp (caption:
  aim until it lights up) · 3 chain ≥ 2 of 3 in one dash (caption: line up lit souls, read the ×count) · 4 redirect: a kill on a leg started mid-dash · 5 blockers: reach the soul behind
  a split void crystal · 6 danger: kill past a spike bloom without a hit (focus ring on Soul Fragments)
  · 7 Rift Points & XP: kills drop shards (swept on landing), XP fills and banks a level (UPGRADE
  READY), the cards slide up at the lesson's calm moment, tap one · 8 RUSH: meter
  starts at 90 %, fill it, kill during RUSH (targets respawn when RUSH starts) · 9 boss: Reaper with 3
  health, strike the open core.
- **Demo:** player input off; the hand plays each swipe beside the Wisp and the director mirrors it into
  the real Wisp (aim arrow while dragging, `perform_swipe` on release; aim-at-target swipes re-aim at
  release). `demo_aim` → `WispPlayer.preview_aim` fires the real aim preview, so demos show the path
  line, the lit enemies and ×N, and releases take the aim assist, exactly as the player's own swipes. A redirect swipe plays right after the previous release. The danger demo forces its hit as
  the dash nears the spikes, reforming at `demo_hit_reform`. The boss demo shows the hand only (the
  Wisp does not strike). **Upgrade demo** (`demo_upgrade_tap`, 2026-09-15): after its swipe the
  director fills the XP bar (the level banks), calls `GameWorld.request_upgrade_calm_moment()`; once the
  Wisp rests with its combo run out the tray slides up (world ×0.3), the hand waits 0.7 real s, taps
  card 1 (`play_tap`) and the director picks it through `choose_upgrade_card` — the hand really drives
  the tap, not caption-only. If the tray never opens within 8 real s the demo moves on caption-only.
  Then the arena is rebuilt (unless `reset_after_demo` is false).
- **Try:** input on; the hand repeats a dimmed hint after 2.6 s idle (boss: only while the core is
  open); a dash hides it. Misses rebuild the lesson after 0.8 s when `retry_on_miss` (or the field is
  empty); a hit in the danger lesson retries with "Hit! …". XP is on only in lesson 7; RUSH only in 8.
  Lesson 7's try: reaping every soul tops the bar up and requests the calm moment; the first time the
  tray rests a dimmed hand taps a card as a hint (never picks); a swipe or the 6 s timeout sends the
  cards away and the director requests another calm moment once the Wisp rests on an empty field. The
  lesson passes on `upgrade_chosen`.
- **Upgrade tray placement:** `TutorialScreen._layout` calls `set_upgrade_tray_lift(GUIDE_BAND_HEIGHT)`,
  so the tray rests above the caption band and the caption stays readable.
- **Never dies:** every hit refills Soul Fragments after 0.6 s (at once if one more would kill).
- **Success beat:** callout + `upgrade_choice` sound, 1.3 s, next lesson. **Complete:** arena cleared,
  "TUTORIAL COMPLETE" + `level_up`, 2.0 s, then `finished(false)`.
- **SKIP** always visible; confirm pauses the arena and drops the Wisp's aim (`GameWorld.cancel_player_aim`, clears lit enemies); back/Escape toggles the confirm. Leaving disables the
  hosted GameWorld and unpauses the tree (the confirm may have paused it).
- **Scripted arena** (`MODE_TUTORIAL`): no wave director, boss cadence, run end, Results, RP banking,
  challenge/Trial/statistics recording (Main never connects `run_ended`); pause button hidden, no
  focus-loss pause, GameWorld leaves back/Escape to the host. RP and XP shown in the HUD are never banked.
  No natural calm moments: the upgrade tray opens only on a lesson's `request_upgrade_calm_moment`.
- **Routing (Main):** after Loading, `tutorial_completed == false` → Tutorial, else Home. Finishing or
  skipping calls `mark_tutorial_completed()`; first launch → Home, Rift Map replay → Rift Map. The
  Tutorial never glides in transitions (it hosts a screen-space arena).
- **Reduced Motion:** no trail, glow pulse, ring growth, focus pulse or caption pop; the gesture plays.

## How to test

- Fresh save (Settings → Reset Progress): launch → Tutorial; play all nine lessons; Home follows.
- Rift Map → TUTORIAL → SKIP → confirm → back on the Rift Map; Android back inside opens the confirm.
- Automated: none (owner preference 2026-09-15). A temporary headless smoke walked every lesson,
  skip, first-launch and Rift Map routing (0 failures) and was deleted. Logs: `[Tutorial] lesson n/9 id | demo|try|retry|passed`.

## Known issues / TODO

- Placeholder art: the ghost hand is code-drawn (ROADMAP M6). The arena is the default Endless skin, now
  real art (2026-09-15).
- The mid-dash redirect window is short (a dash crosses the arena in ~0.25 s); needs the device pass.
- The aim preview follows the player's AIM ARROW setting; with it OFF (possible on a Rift Map replay)
  the slice/chain captions mention lighting the player cannot see.
- Demo dashes are real physics: an unlucky natural hazard hit can change a demo's second swipe path
  (the demo still moves on to the try).

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Lesson 7 uses the banked upgrade flow: UPGRADE READY, calm-moment tray, hand taps a card (`demo_upgrade_tap`, `play_tap`, HandLayer 11), new captions |
| 2026-09-15 | Aim help: slice/chain captions teach lit enemies and ×count, demos show the aim path, demo hold 0.4 s, skip confirm clears the aim |
| 2026-09-15 | Rebuilt as a separate Tutorial screen: nine show-then-try lessons, ghost hand, SKIP confirm, first-launch and Rift Map routing; in-run lesson removed |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Implemented non-blocking three-step lesson, retry line and session gating |
| 2026-09-11 | Planned for the second Milestone 1 slice |
