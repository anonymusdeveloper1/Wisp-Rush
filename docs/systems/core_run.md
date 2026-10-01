# System: Core run

> **Status:** ✅ done · **Last updated:** 2026-09-28 · **GDD section:** §3, §5–7, §11

## Purpose

Coordinate the live full-bleed arena, Wisp, wave requests, enemies, hazards, pickups, combat,
mutations, run-local statistics and HUD without making child systems depend on each other. It also
hosts the Tutorial screen's scripted arena ([tutorial.md](tutorial.md)); real runs never teach.

## Files

| Path | Role |
|---|---|
| `res://scenes/gameplay/game_world.tscn` | Arena, layers, HUD and pause overlay |
| `res://scenes/gameplay/game_world.gd` | Spawn/combat routing, statistics, upgrade effects and feedback |

## Scene / node structure

```text
GameWorld (Control)  game_world.gd
├── %FullBleedBackground (TextureRect)
├── %EnemyLayer (Node2D)
├── %HazardLayer (Node2D)
├── %PickupLayer (Node2D)
├── %PlayerLayer (Node2D)
│   └── WispPlayer
├── %EffectsLayer (Node2D)
├── %WaveDirector (Node)
├── %RunProgression (Node)
└── HUD (CanvasLayer)
    ├── SafeHud: %PauseButton + %UpgradeButton top-left · %StatsColumn (Rift Points line, icon on the
    │   right, then the unframed %ScoreLabel) top-right · %XPBar, %RunLevelLabel, %RushRow, %BossHud
    │   centred at the top; no wave line (owner, 2026-09-24; `_layout_safe_hud()`)
    ├── UpgradeTray (bottom card tray, [mutations.md](mutations.md))
    └── PauseOverlay
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `home_requested` | signal | The paused run requests Home navigation. |
| `run_ended(summary)` | signal | The death dissolve finished: score, kills, best combo, wave, multi-reaps, rapid ricochets, bosses, `rp_collected`, `rp_performance`, `run_level`, `daily_date`, `is_daily`, `mode`, `skin_id`, `cycle` and `rush_count` (RUSH activations; no save field). |
| `dash_launched(from_redirect)` / `dash_resolved(kills, ended_by)` / `enemy_defeated(world_position, dash_kill_index)` / `player_damaged(current_health)` / `upgrade_chosen(mutation_id)` / `rush_started` / `boss_defeated` | signals | Run events for observers (the tutorial director). `ended_by`: `&"wall"`, `&"redirect"`, `&"obstacle"`. `upgrade_chosen` fires on a tray card pick. |
| `run_seed` | export | Deterministic wave and upgrade seed; zero derives a clock seed. |
| `cancel_player_aim()` | method | Drops the Wisp's gesture and aim preview (host modals). GameWorld also owns the aim preview: `AimGuide`, enemy highlights and the aim-assist counter ([player_dash.md](player_dash.md)). |
| `get_score()` | method | Current run score for results/tests. |
| `get_combo()` | method | Current combo before timeout. |
| `get_highest_combo()` | method | Best run-local combo. |
| `get_total_kills()` | method | Defeated enemy count. |
| `get_current_wave()` | method | Current one-based wave. |
| `get_rp_collected()` | method | Rift Points collected this run (pickups, multi-reaps, bosses), separate from score. |
| `get_rp_performance()` | method | Performance bonus the current score pays: score ÷ `score_per_rift_point`. |
| `economy_tuning` | export | `EconomyTuning` (`res://data/economy/default_economy_tuning.tres`), see [shop.md](shop.md). |
| `feel_tuning` | export | `RunFeelTuning` (`res://data/feel/default_run_feel_tuning.tres`), see [rush_mode.md](rush_mode.md). |
| `is_rush_active()` / `get_rush_meter()` / `get_rush_remaining()` / `get_rush_count()` | methods | RUSH state; the summary adds `rush_count`. |
| `configure_run(profile)` | method | Applies a `RunProfile` (`scenes/gameplay/run_profile.gd`, built only by Main): `mode` (`endless`/`daily`/`tutorial`), `endless_catalog` + `skin` + `rosters` + `boss_ids`, `run_seed`, `daily_date_key`, `form`, `dash_style`; `tutorial` = Endless floor + skin, scripted. GameWorld reads everything arena-specific through `profile.create_arena_rules()` (`EndlessArenaRules`; the base `ArenaRules` is the neutral arena of fixtures and F6 runs) — backdrop, UV floor, boss interval and id, threat, enemy speed, roster per wave. No permanent bonuses. |
| `hold_start()` / `is_start_held()` / `warm_up_render()` / `release_start()` | methods | Main's cover and run prewarm (2026-09-16): a held run builds and draws but its start (`_begin_run`: waves, instructions, scripted hand-off) and focus-loss pause wait for `release_start()`; `warm_up_render()` draws one of every enemy kind + a VFX sprite while held (freed on release). Main keeps a held run `PROCESS_MODE_DISABLED`. |
| `get_run_mode()` | method | Profile mode. |
| `get_multi_kill_dashes()` | method | Dashes that defeated at least two enemies. |
| `add_experience(amount)` | method | Test/debug route into normal run progression. |
| `get_mutation_level(id)` | method | Current level of one run-only mutation. |
| Scripted-run hooks | methods | For `MODE_TUTORIAL` only: `is_scripted`, `arena_to_world(uv, margin)`, `spawn_scripted_enemy/hazard(kind, uv)`, `clear_scripted_arena`, `start_scripted_boss(health)`, `is_boss_core_exposed`, `find_nearest_target`, `set_experience_enabled`, `set_experience_share(share)`, `set_rush_enabled`, `set_rush_meter`, `refill_health`, `hit_player_at(uv)`, `place_player(uv)`, `set_player_input_enabled`, `is_player_ready/dashing`, `get_player_position`, `demo_aim/demo_swipe(drag)`, `spawn_scripted_shard`, `sweep_shards`, `get_hud_rect(&"xp"/&"rush")`, `get_safe_margins`, `show_callout`; upgrade tray: `request_upgrade_calm_moment`, `has_upgrade_calm_request`, `get_banked_upgrades`, `is_upgrade_tray_open/settled`, `get_upgrade_card_rect`, `choose_upgrade_card`, `set_upgrade_tray_lift` ([mutations.md](mutations.md)). Reuses `debug_spawn_enemy`, `debug_quiet_arena`, `debug_live_enemy_count`. |

## Data & tuning

All balance comes from the typed Resources linked in dependent system docs; Rift Points payouts
that are not pickups come from `EconomyTuning` ([shop.md](shop.md)). GameWorld keeps only event
windows and presentation constants that coordinate multiple systems.

## Dependencies

[player_dash.md](player_dash.md), [player_health.md](player_health.md), [enemies.md](enemies.md),
[wave_director.md](wave_director.md), [hazards.md](hazards.md), [mutations.md](mutations.md),
[rush_mode.md](rush_mode.md) and production world/UI art; [tutorial.md](tutorial.md) drives the scripted mode. It has no autoload.

## Rules & behaviour

- **Dash style (spec 04):** `RunProfile.dash_style` (set by Main from `equipped_dash_style`) tints the
  launch burst (`DASH_TRAIL_SHORT`, `burst_tint`) and the long impact trail (`DASH_TRAIL_LONG`,
  `trail_tint`). SOUL (`uses_form_tint`) keeps the form tint. Timing, collision, sound and haptics
  never read it.
- The playfield is not the whole screen: `GameWorld._compute_arena_rect()` maps `ARENA_FLOOR_UV`
  (the painted stone floor) through the backdrop's cover-scale into screen space, so the Wisp always
  rests on stone, below the HUD ([ADR-0006](../decisions/0006-inset-playfield-and-larger-sprites.md)).
  Everything else — formations, spawn distances, hazard placement, the safest-edge search — is
  arena-relative and follows automatically.
- World art covers the viewport; only HUD uses safe-area padding.
- Wave requests are realized only from known enemy/hazard scene maps; at most one authored hazard
  exists per formation and spawn points are kept clear of the Wisp.
- Each swept segment resolves its earliest hazard event, then applies the reachable portion to
  enemies and pickups so nothing behind a blocker is hit.
- Active enemy/hazard circles damage an exposed Wisp; GameWorld chooses the edge point with the
  greatest clearance from every active threat.
- Combo increases on kills, times out after 2.2 s and survives wall impact; empty dashes shorten it.
  RUSH freezes both the timeout and the empty-dash decay.
- **RUSH meter** ([rush_mode.md](rush_mode.md), GDD §5.6): `_on_enemy_killed` adds `per_kill` (+
  `per_extra_dash_kill` after a dash's first kill) and sends a soul orb to `%RushBar` (under SOUL
  LEVEL; hidden and frozen while `set_rush_enabled(false)` — tutorial lessons other than RUSH); boss
  health loss adds `per_boss_hit`. A full meter starts RUSH in free play: ×1.3 dash speed, ×2 score inside `_apply_velocity_score_bonus` (the score choke
  point, after Void Velocity), no damage, peak music, 6 game seconds.
- **Auto-collect sweep:** `_sweep_floor_shards()` flies every floor shard to the Wisp
  (`SoulShardPickup.sweep_to`) on wave start, boss encounter start, boss defeat and the fatal hit;
  `_emit_run_end()` collects anything left before building the summary. Awards still pass only
  through `_award_rift_points`; one capped chime run replaces per-shard sounds.
- Multi-reaps use a quadratic base bonus, rapid redirects add score and Rift Points stay separate.
- **Rift Points in a run:** every in-run award passes through `_award_rift_points` — shard pickups,
  one RP per three kills in a multi-reap, and the boss `rp_reward` (doubled in Reaper's Court). The
  HUD shows it as `12 RP`. At run end the summary carries `rp_collected` and `rp_performance`
  (`score / score_per_rift_point`, integer division); SaveManager adds both once.
- **No permanent power** (ADR-0013): a run starts at the no-bonus baseline — 1 Soul Fragment, base
  invulnerability, no starting mutation, every blade, speed, XP, pickup and attraction multiplier 1.0,
  combo grace `COMBO_TIMEOUT`. Run-only power is the six mutations (the Soul Vessel and Reaper's Gift
  were removed 2026-09-24).
- **Upgrades never pause** (owner decision 2026-09-15, [mutations.md](mutations.md)): level-ups bank
  silently; the bottom `UpgradeTray` slides up only at a calm moment —
  a wave start, a boss beaten (after the victory beat) or a field clear — when the Wisp rests with no
  combo, boss or RUSH, and the world runs at ×0.3 while it is up. A tap picks (next banked set slides
  in), a dash dismisses, 6 real seconds time out; dismissed levels stay banked for the next calm moment
  and are lost at run end. A pending boss waits for an open tray; boss start closes it. Selected
  mutation effects remain run-local.
- Contact resets combo; the death-dissolve signal freezes the run and emits its summary once.
- **Only death ends a run.** (History: a story Rift level ended in victory on its final boss, with a
  level-clear bonus; removed with the Rifts on 2026-09-25.)
- **Endless rules** (`endless` and `daily`, spec 03, [endless_mode.md](endless_mode.md)): the template
  floor under a skin, no twist; a boss every `EndlessTuning.boss_wave_interval` waves; each victory
  raises the cycle (`get_cycle()` = bosses beaten), which sets threat and enemy speed, and resumes
  waves; only death ends the run. HUD `ENDLESS`/`DAILY  •  WAVE w  •  THREAT t`; the wave callout is
  `WAVE nn` (the mix names went with Enemies v2, 2026-09-28). Summary adds `skin_id` and `cycle`.
- **Tutorial mode** (`RunProfile.MODE_TUTORIAL`, owner decision 2026-09-15): `_begin_run` starts no
  waves, hides the pause button and instruction; no boss cadence, run end or recording (nobody
  listens to `run_ended`); focus loss never pauses and back/Escape go to the host screen; a boss
  defeat reads `TUTORIAL • BOSS DEFEATED`. XP and RUSH are switched per lesson through the hooks.
  The old in-run lesson (`TutorialStep`, `TutorialOverlay`, `tutorial_enabled`) is gone.
- **Arena opening shot** (owner 2026-10-01, GDD §14 #69, ADR-0023): when the arena scene
  `has_intro()` (the 3D ZOOM ARENA), `_begin_run` hides the Wisp and the HUD, turns steering off and
  plays it; a tap skips it; on `intro_finished` the Wisp and the HUD fade in (0.35 s) and the waves
  start. The arena rect is the zoomed-in floor from the start, so nothing is laid out twice. A run
  Main builds from its restart (Results' PLAY AGAIN, the pause menu's restart) has
  `play_arena_intro` off: the arena starts zoomed in and the waves start at once (owner, #70).
- **Board HUD** (owner 2026-10-02, GDD §14 #71–#72, ADR-0024): when the arena scene `has_board_hud()`
  (BOARD 01), `_apply_board_hud` moves the pause and UPGRADE buttons, the stats column, the XP bar,
  the level label, the RUSH row and the boss HUD under a hidden holder (they keep being updated) and
  `_update_board_hud` feeds their values to the board every frame; the board's pause emits
  `hud_pause_pressed`. While upgrades are ready an `UpgradeGlow` lights the character, and `_input`
  opens the cards on a tap that starts on him (within 2.4 × his radius, under the minimum swipe
  distance and 450 ms).
- Focus changes enemy and hazard simulation only, never input or UI speed.
- Pause consumes input, freezes gameplay and always restores normal tree state on navigation; it
  hides an open upgrade tray and drops its slow motion, and Resume brings both back. Back/Escape
  toggle pause even while the tray is up.
- Mobile focus loss opens Pause; desktop focus loss stays live so automated visual capture works.

## How to test

- Run main (tutorial completed), continue through escalating waves; bank a level mid-combo and pick
  it from the tray at the next wave start.
- Run the wave, enemy, hazard, progression, mutation and gameplay scripts listed in README.
- Confirm background reaches all edges at every GDD §12 QA size.
- Pause/resume, then Pause/Home; no swipe leaks through UI.

## Known issues / TODO

- Reaper handoff, on-disk currency/best persistence and physical-device safe-area QA are later
  milestones.

## Change history

| Date | Change |
|---|---|
| 2026-09-25 | Story Rifts removed (owner): no `story` mode, level victory or clear bonus; the summary loses `level`, `victory`, `level_cleared`, `first_clear`, `rp_clear_bonus`, `level_clears`, `rift_levels_cleared` and `rift`; `get_rift_level()` / `is_level_cleared()` and `RiftArenaRules` removed; `RunProfile.rosters` (`EndlessRoster`) replaces `roster_rifts` |
| 2026-09-15 | Upgrades bank and offer a slow-motion bottom `UpgradeTray` at calm moments; no pause; tray hooks for the tutorial |
| 2026-09-15 | Aim help: `AimGuide`, enemy highlights, aim-assist counter, `cancel_player_aim` |
| 2026-09-15 | In-run lesson removed; `MODE_TUTORIAL` scripted arena, run event signals and scripted-run hooks for the Tutorial screen |
| 2026-09-15 | RUSH meter/mode, auto-collect sweep, finishers, `rush_count`, HUD RUSH row (boss panel and callouts 34 px lower) (spec rush_and_feel) |
| 2026-09-15 | Dash styles tint the launch burst and long trail (`RunProfile.dash_style`, spec 04) |
| 2026-09-15 | Story levels: `RunProfile`/`configure_run`, one level per run ending in victory, clear bonus (spec 02) |
| 2026-09-15 | Rift Points: `_award_rift_points`, `rp_collected` / `rp_performance` summary, `EconomyTuning`; Sanctum effects removed (spec 01) |
| 2026-09-12 | Playfield inset to the painted floor; sprites and hitboxes scaled up (ADR-0006) |
| 2026-09-11 | Integrated waves, full regular roster, hazards, XP/mutations, drops and run statistics |
| 2026-09-11 | Added health contacts, safe reform, run statistics/death summary and tutorial routing |
| 2026-09-11 | Implemented responsive arena, training loop, score/combo, focus and pause HUD |
| 2026-09-11 | Planned from owner prompt v2 |
