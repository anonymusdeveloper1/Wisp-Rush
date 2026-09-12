# Devlog

> Append-only session log, **newest first**. One entry per work session; format in
> [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) §7.6. Keep entries short — details belong in the docs
> they changed.

## 2026-09-12 — Playfield inset and larger sprites
- **Who:** Claude Code (Opus 5), at the owner's decision (both options)
- **Did:**
  - Playfield is now the painted stone floor: `ARENA_FLOOR_UV` (measured from the arena art) mapped
    through the backdrop cover-scale, clamped to the screen and a minimum fraction; HUD margins moved
    back to screen space; the wall-impact flash now draws on the playfield edge (ADR-0006).
  - Sprites and hitboxes scaled together: player and enemies ×1.45 (player radius ratio 0.03 → 0.05,
    min/max 30/70), hazards, Reaper body/core and Soul Shard pickups ×1.3. Reaper attack geometry
    left as tuned — the smaller arena already makes it relatively larger.
- **Files/systems:** `scenes/gameplay/game_world.gd`, `data/player/*`, `data/enemies/*`,
  `data/hazards/*`, `data/bosses/default_reaper.tres`, `scenes/pickups/soul_shard_pickup.gd`.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed; gameplay,
  tutorial and upgrade captured at all 5 phone sizes — the Wisp now rests on stone inside the floor,
  enemies read clearly, and nothing sits under the HUD. Android APK rebuilt.
- **Follow-ups:** feel check on the device (dash distances are shorter now); dark icons, number
  formatting and the missing back-chevron icon are still open.

## 2026-09-12 — Android device build; fixed an audio crash on device
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Set up the Android debug build: installed Godot 4.7.2 Android export templates, created a local
    debug keystore, added the "Android" preset (arm64, portrait, `com.cognitix.wisprush`), enabled
    ETC2/ASTC VRAM compression, set the JDK path in Godot's editor settings, and added a
    `concept_art/.gdignore` so sources never enter imports or the APK. APK: 53 MB.
  - Installed and launched it on the owner's Galaxy S24 (Android 16, 1080×2340) over USB.
  - **Crash fix:** the game died with SIGSEGV in the Android AudioTrack thread inside Godot's WAV
    mixer. `AudioSynth.build_stream()` set `loop_end` to the total frame count — one past the last
    frame — and the mixer interpolates one frame ahead, so it read off the end of the buffer. Now
    every stream gets two silent guard frames and `loop_end` points at the first guard frame;
    `test_audio_service.gd` asserts both (415 checks).
- **Files/systems:** `scripts/utils/audio_synth.gd`, `tools/godot/test_audio_service.gd`,
  `export_presets.cfg`, `project.godot`, `concept_art/.gdignore`, docs.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed; on the device
  the rebuilt APK ran 90 s with the 8 s music loop wrapping ~11 times — no crash, no SIGSEGV in
  logcat, process alive.
- **Follow-ups:** owner still to decide the gameplay composition (small Wisp/enemies, playfield under
  the HUD); iOS preset, launcher icons and release signing remain open.

## 2026-09-11 — Redesign v1 integrated
- **Who:** Claude Code (Opus 5) orchestrating a 10-agent workflow (assets, design system, 7 restyle agents, verify)
- **Did:**
  - Archived the owner asset pack v2 to `assets/legacy_v1/` (`.gdignore`) and regenerated every
    runtime art path from `concept_art/wisp_rush_redesign_v1/` with `tools/art/extract_redesign.py`
    (112 outputs; checkerboards matted out of the form and prop sheets; VFX converted to alpha;
    content normalised to legacy canvases so gameplay scale and collision fit are unchanged).
  - Built the project Theme (`assets/ui/theme/wisp_theme.tres`) from the stone frame kit with named
    type variations and `Palette` constants; restyled Home, Forms, Daily Rift, Results, HUD, pause,
    confirm, upgrade cards, tutorial, Settings, Statistics and Loading to the six-screen board.
  - Recoloured gameplay telegraphs (amber warnings, magenta execution), Death Pulse tint from the
    form; set the redesign boot splash; ADR-0005; GDD §9 rewritten; registry and docs updated.
- **Files/systems:** `assets/**`, `tools/art/**`, `assets/ui/theme/**`, `scripts/utils/palette.gd`,
  all `scenes/screens/*`, `scenes/gameplay/game_world.*`, gameplay prefabs, `data/forms/*.tres`, `project.godot`.
- **Verified:** `tools/validate.sh` → OK (49 scripts); `tools/run_tests.sh` → 20 passed, 0 failed;
  `tools/qa_matrix.sh` → 50/50 phone captures reviewed against the board (no overlap, clipping or
  checker remnants); Reaper render checked; no references to `assets/legacy_v1`.
- **Follow-ups:** owner decision on gameplay composition (Wisp/enemies too small, playfield edges on
  scenery and behind the HUD); dark icons; number formatting; back chevron; Statistics empty space on
  tall phones.

## 2026-09-11 — Milestone 5: polish pass (pre-release)
- **Who:** Claude Code (Opus 5)
- **Did:**
  - Owner decisions recorded: no store release yet, phones only, planned id `com.cognitix.wisprush`.
    Real save moved to `user://save_backup_2026-09-11/` (reversible reset; fresh first-run experience).
  - Added a reproducible phone QA matrix (`tools/qa_matrix.sh`, `qa_capture.gd`, `qa_contact_sheet.gd`)
    and reviewed 10 screens at 5 phone aspect ratios. Layout fixes: phone readability pass — 40 small labels raised from 16–20 to 22–26 design px (HUD, Daily, Forms, Home, Results, upgrade cards, tutorial) with HUD offsets retuned; no clipping or overflow at any phone size.
  - Polish: 0.22 s fade-in on every screen change, press dip/spring on all buttons (`UiJuice`), Home
    footer shows the project version, removed the stale "TRAINING" HUD label.
  - Added `tools/godot/bench_stress.gd`: windowed on the M2 at 390×844 with vsync off: avg 2.4 ms, p95 3.6–3.9 ms at both 10 and 45 enemies, but 3–4 isolated 37–44 ms spikes per 840 frames regardless of load — check for first-use hitches on a real phone.
- **Files/systems:** `scenes/main/main.gd`; `scripts/utils/ui_juice.gd`; `scenes/screens/home_screen.*`;
  `scenes/gameplay/game_world.{gd,tscn}`; `tools/qa_matrix.sh`; `tools/godot/{qa_capture,qa_contact_sheet,bench_stress}.gd`.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 20 passed, 0 failed; `tools/qa_matrix.sh` → 50/50 phone captures clean after the fixes (all 10 contact sheets reviewed); benchmark numbers above; tooling runs use the isolated `user://test_runs/` save.
- **Follow-ups:** owner discussion on direction/monetisation; art re-export; audio listening and
  device feel pass.

## 2026-09-11 — Milestone 4: product surface, audio and feel
- **Who:** Claude Code (Opus 5) with one Claude sub-agent (audio)
- **Did:**
  - Audio: 18 runtime-synthesized SFX and 3-layer adaptive music (pad / combo-driven pulse / boss)
    on Master/Music/SFX/UI buses via the `Audio` autoload; ducking on pause and interruption (ADR-0004).
  - Screens: boot Loading (threaded streaming, ≤ 6 s), Settings (volumes, shake, haptics, reduced
    motion, tutorial replay, Privacy & About, armed 2-step reset), Statistics, Home Stats/Settings,
    Results Wisp Forms button and NEW BEST.
  - Feel: trauma shake (2–12 px per the prompt), 60 ms hit-stop on triple reaps, haptics, pooled
    form-tinted VFX (dash trails, soul slice, dissolve, large impact), Reaper and gameplay sound cues —
    all honouring Reduced Motion and Screen Shake.
  - Lifecycle: auto-pause on focus loss/backgrounding, Android back + Escape routing
    (`quit_on_go_back=false`), pause menu Restart/Settings with confirmation for meaningful runs,
    debug-build-only F3 performance overlay.
- **Files/systems:** `scenes/main/main.gd`; `scenes/gameplay/game_world.{gd,tscn}`;
  `scenes/screens/{loading,settings,statistics,home,results}_screen.*`; `scenes/bosses/reaper_boss.gd`;
  `scripts/autoload/{audio_service,save_manager}.gd`; `scripts/utils/{audio_synth,haptics,sound_fx}.gd`;
  `scripts/components/vfx_pool.gd`; `scenes/debug/debug_overlay.gd`; `default_bus_layout.tres`; `project.godot`.
- **Verified:** `tools/validate.sh` → OK (45 scripts); `tools/run_tests.sh` → 20 passed, 0 failed
  (new `test_m4_systems`, `test_audio_service`); real-driver audio smoke on CoreAudio (every SFX,
  voice stealing, music layers, ducking) without errors; windowed boot Loading 1.16 s → Home;
  visually inspected Loading, Home, Settings, Statistics, pause menu, abandon-run confirmation and
  in-run Settings (reset hidden); real save byte-identical after validate + tests.
- **Follow-ups:** device pass for performance, shake/haptic strength and audio mix (sounds were
  designed numerically, not by ear); windowed boot warns "6 ObjectDB instances leaked at exit";
  art re-export and licence still open.

## 2026-09-11 — Milestone 3 close-out: Reaper, saves, forms, daily
- **Who:** Claude Code (Opus 5), resuming after Codex ran out of quota mid-milestone
- **Did:**
  - Audited Codex's unlogged Milestone 3 work: recurring three-phase Reaper (every 4 waves) with a
    harder post-boss tier, SaveManager autoload (ADR-0003), six forms with purchase/equip, Rift of
    the Day with three date-seeded challenges, Home Forms/Daily entry points.
  - Fixed `test_main_progression_flow`, which hung forever: it created a second SaveManager that
    Main never used, and read a non-existent `World/WispPlayer/FormSprite` path. Fixed the same
    duplicate-autoload bug in `test_game_flow`.
  - Stopped automated runs from overwriting the owner's real save:
    `SaveManagerService.uses_isolated_storage()` routes `--script` tests and `WISP_ISOLATED_SAVE=1`
    tool runs (validate/screenshot) to `user://test_runs/`.
  - Added `tools/run_tests.sh` (all headless tests, per-test timeout — a hung test now fails instead
    of blocking) and `tools/godot/render_reaper_showcase.gd`; registered SaveManager, the M3 scenes,
    `bosses` group and the three new resource types; closed the four M3 system docs.
  - Fixed the boss HUD overlapping the run-level label when a top safe-area inset applies:
    `BossHud` now follows the inset in `GameWorld._layout_safe_hud()`.
- **Files/systems:** `scripts/autoload/save_manager.gd`; `tools/godot/test_{game_flow,main_progression_flow}.gd`;
  `tools/{run_tests,validate,screenshot}.sh`; `scenes/gameplay/game_world.gd`; Reaper boss, Save manager, Cosmetic forms, Daily/challenges.
- **Verified:** `tools/validate.sh` → OK; `tools/run_tests.sh` → 18 passed, 0 failed; the real save
  was byte-identical before/after a full validate + test run. Visually inspected Home (Forms/Daily
  Rift buttons), Forms, Rift of the Day and the Reaper encounter at 540×960 (re-rendered after the HUD fix).
- **Follow-ups:** the real `user://wisp_rush_save.json` already holds test-run data from before the
  fix (4 runs, best 345, today's daily done) — owner decides whether to reset it. Title logo, Void form and all eight Reaper PNGs have a grey checkerboard painted into their semi-transparent halos, and several Reaper cells (e.g. scythe strike) clip the art at the 444 px cell edge; the master sheet has the same cuts, so this needs a clean re-export from the art source.
  Milestone 4 is next.

## 2026-09-11 — Complete resource-driven endless run
- **Who:** Codex (GPT-5)
- **Did:**
  - Added a deterministic threat-budget WaveDirector and 20 validated normalized formations with
    mirrored/rotated variants, health context and staged enemy/hazard introductions.
  - Added shared regular-enemy behavior plus the two-hit Shard Wraith and three-hit Bone Mote;
    added warned split-crystal, spike-bloom and blade-ring hazards with swept dash resolution.
  - Added run XP, a safe paused three-card choice, all eight production-icon mutations, Soul Shard
    drops/collection and mutation effects across dash, enemies, health, score and pickups.
  - Expanded score/reward tracking, HUD and Results with session best/currency, wave, multi-reap
    and boss fields; synchronized the roadmap, GDD assumption, registries and system docs.
- **Files/systems:** `scenes/{gameplay,enemies,hazards,pickups,player,screens,main}/`;
  `scripts/{components,resources}/`; `data/{enemies,formations,hazards,mutations,progression,waves}/`;
  Wave director, Enemies, Arena hazards, Run progression, Core run, Player dash/health, Game flow.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (28 game scripts, 0 failures); all 12 headless
  test scripts passed, covering geometry, health/death, tutorial/navigation, live scoring, 20
  formations, 1/2/3-hit enemies, hazard states/live dash blocking, XP choices and all eight mutation
  effects. Direct Godot runs had no errors. Visually inspected the HUD/tutorial, full M2 roster,
  three-card upgrade overlay and expanded Results at the 1080×1920 design output.
- **Follow-ups:** build the three-phase Reaper and post-boss cycle; add versioned local persistence
  for best/tutorial/Soul Shards; complete physical-device QA, audio and asset-license confirmation.

## 2026-09-11 — Health, tutorial and complete vertical-slice loop
- **Who:** Codex (GPT-5)
- **Did:**
  - Added reusable clamped health, three Soul Fragments, exposed-state enemy contact, combo reset,
    safest-edge reform, hurt/i-frame feedback and the timed Wisp death dissolve.
  - Added the non-blocking first-run lesson: wall dash, telegraphed single slice, then a retryable
    aligned triple reap; completion is remembered for the current app session.
  - Added run statistics and a production-art Results screen with score, kills, best chain,
    Restart and Home, completing the Milestone 1 play loop.
  - Added unit/live checks for health, contact/death, tutorial progression and Results/restart flow.
- **Files/systems:** `scripts/components/health_component.gd`; `scenes/{player,enemies,gameplay,tutorial,screens,main}/`;
  `data/player/`; `tools/godot/`; Player health, Tutorial, Core run, Game flow, Enemies, Player dash.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (11 game scripts, 0 failures); health component
  6/6; live contact → i-frames → death → one summary; tutorial wall dash → single slice → triple
  reap; Home/Pause/Home → Results → tutorial-gated Restart; original four-kill dash still scored
  310 with combo 4. Visually inspected tutorial/HUD and Results at the 1080×1920 design output.
- **Follow-ups:** begin Milestone 2 WaveDirector/data formations, extra enemies/hazards, XP and
  mutation choices; persist tutorial completion with SaveManager in Milestone 3; physical-device
  cutout/touch QA; confirm art license and final audio path before release.

## 2026-09-11 — Prompt intake and playable dash slice
- **Who:** Codex (GPT-5)
- **Did:**
  - Reconciled the standalone and archived v2 prompts (identical SHA-256), replaced the GDD
    template with the release-MVP specification and sequenced Milestones 1–5.
  - Imported 86 production PNGs into the project naming/layout; excluded master/reference/legacy
    files and recorded the missing license/audio as release follow-ups.
  - Built full-bleed Home and GameWorld scenes, responsive HUD/pause flow, typed tuning Resources,
    touch/mouse/keyboard Wisp aiming, exact edge dashes, wall focus, Soul Wisp steering, swept
    collision, score/combo and multi-reap feedback.
  - Added pure dash-geometry, live gameplay-slice and top-level navigation checks; updated the
    screenshot helper to exercise explicit window aspects.
- **Files/systems:** `project.godot`; `assets/art/`; `data/`; `scenes/{main,screens,gameplay,player,enemies}/`;
  `scripts/{resources,utils}/`; Game flow, Player dash, Core run, Enemies; GDD/ASSETS/ROADMAP/README.
- **Verified:** `tools/validate.sh` → `VALIDATE: OK` (8 game scripts, 0 failures); dash geometry 4/4;
  live first dash killed four enemies and settled at an edge (`score=310`, `combo=4`); Pause/Resume
  and Home → Play → Pause → Home passed. Visually inspected Home and arena at 540×960. Direct Godot
  runs produced expanding arenas without errors at 320×568, 360×800, 375×812, 390×844, 412×915,
  768×1024 and 1280×720.
- **Follow-ups:** add health/contact/death/results and first-run tutorial; replace the training
  formation loop with WaveDirector data; confirm art license; choose final audio path; use physical
  phone/tablet QA for density, cutouts, touch latency, haptics and performance.

## 2026-09-11 — Project setup
- **Who:** Claude Code (Opus 5), setup session
- **Did:**
  - Created the Godot 4.7 project at the repo root: feature-based folders, `project.godot`
    (typed-code warnings on), bootstrap scene `scenes/main/main.tscn`, icon.
  - Added tooling: `tools/validate.sh` (import → parse all scripts → boot → map),
    `tools/project_map.mjs` (generated inventory), `tools/screenshot.sh` (frame capture),
    `tools/godot/check_scripts.gd`.
  - Connected the Godot MCP server (Coding-Solo/godot-mcp 0.1.1, pinned in `tools/mcp/`) — ADR-0002.
  - Wrote the agent docs: AGENTS.md, CLAUDE.md, PROJECT_CONTEXT (map + documentation rules),
    CONVENTIONS, GDD/ASSETS/ROADMAP templates, ADR-0001; Claude Code subagents
    (playtester, gdscript-reviewer, docs-keeper) and skills (run-game, new-system, update-docs).
- **Files/systems:** whole repo (initial).
- **Verified:** `tools/validate.sh` → OK. A deliberately broken script made it FAIL (exit 1) as
  expected. MCP `get_godot_version` returns 4.7.2; `run_project` + `get_debug_output` show
  `[Main] boot ok` (only after enabling `flush_stdout_on_print` — see ADR-0002). `claude mcp get
  godot` → ✔ Connected. `tools/screenshot.sh` captured the label correctly.
- **Follow-ups:** waiting for the owner's game prompt (→ GDD) and asset folder (→ ASSETS intake).
  Choose a test framework when the first testable system exists.
