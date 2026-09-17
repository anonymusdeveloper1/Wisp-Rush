# System: Daily run and local challenges

> **Status:** ✅ done · **Last updated:** 2026-09-15 · **GDD section:** §6, §20
>
> **Endless rules (spec 03, 2026-09-15):** the daily run plays on Endless rules — the shared floor
> template, `EndlessTuning.daily_roster_rift_ids` / `daily_boss_ids` (Obsidian Garden roster, the Reaper)
> and `EndlessCatalog.get_arena_of_the_day(date)` — ignoring progress and ownership, so every player gets
> the same run. The Daily screen's seed line names the arena (`DailyScreen.setup(..., arena_name)`).

## Purpose

Provide deterministic offline return goals without penalties or network dependence: one
calendar-seeded Rift of the Day and three rotating local challenges.

## Files

| Path | Role |
|---|---|
| `res://scripts/utils/challenge_tracker.gd` | Date seed, daily rotation and run-summary progress |
| `res://scenes/screens/daily_screen.tscn` | Today's seed, best, reward and three challenge rows |
| `res://scenes/screens/daily_screen.gd` | Daily Play and Back intents |

## Scene / node structure

```text
Main
└── DailyScreen
    ├── Rift of the Day summary
    ├── three challenge rows
    └── Play Daily + Back
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `ChallengeTracker.get_date_key()` | static method | Local `YYYY-MM-DD` key. |
| `ChallengeTracker.get_daily_seed(key)` | static method | Stable positive run seed. |
| `ChallengeTracker.get_challenges(key)` | static method | Three deterministic daily definitions. |
| `ChallengeTracker.apply_run(summary, challenge_state, daily_state, key, is_daily)` | static method | Update progress and return `reward_points` and state. |
| `DailyScreen.play_daily_requested(date, seed)` | signal | Start today's deterministic run. |

## Data & tuning

Challenge definitions and modest 10–25 Rift Points rewards are constants in ChallengeTracker;
`DAILY_COMPLETION_REWARD` is 10 RP. POINT SEEKER (`rp_seeker`, was SHARD SEEKER) counts
`rp_collected` — pickups and boss rewards, not the performance bonus (GDD §14 #22). Persistent
progress and claimed dates live in SaveManager; the save v6 migration renames `shard_seeker` progress.

## Dependencies

Main supplies completed GameWorld summaries and persists the returned state through SaveManager.

## Rules & behaviour

- Redesign v1 layout: portal hero card, today's-best plate, three goal rows with progress bars and reward pills, one primary Play action.
- Local date alone selects the same three challenge definitions and daily seed offline.
- Daily challenges keep their wave goals (RIFT DIVER, wave 5): story runs end at wave 4, so only
  Endless and daily runs complete them.
- Progress never decreases; completed rewards are claimed once per date/challenge.
- Completing a daily run grants one 10 RP reward per date; missing a date has no penalty.
- Reward plates and the daily bonus line read `+15 RP` (`RiftPoints` formatting, spec 01).

## How to test

- Verify same date gives identical seed/rotation, another date changes them and rewards cannot repeat.

## Known issues / TODO

- Platform-clock rollback is treated as another local date; no server authority is intended.

## Change history

| Date | Change |
|---|---|
| 2026-09-15 | Rewards in Rift Points (`reward_points`, `+15 RP`); SHARD SEEKER → POINT SEEKER on `rp_collected` (spec 01) |
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
