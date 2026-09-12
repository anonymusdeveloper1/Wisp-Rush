# System: Daily run and local challenges

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §6, §20

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
| `ChallengeTracker.apply_run(summary, challenge_state, daily_state, key, is_daily)` | static method | Update progress and return rewards/state. |
| `DailyScreen.play_daily_requested(date, seed)` | signal | Start today's deterministic run. |

## Data & tuning

Challenge definitions and modest 10–25 Soul Shard rewards are constants in ChallengeTracker.
Persistent progress and claimed dates live in SaveManager.

## Dependencies

Main supplies completed GameWorld summaries and persists the returned state through SaveManager.

## Rules & behaviour

- Redesign v1 layout: portal hero card, today's-best plate, three goal rows with progress bars and reward pills, one primary Play action.
- Local date alone selects the same three challenge definitions and daily seed offline.
- Progress never decreases; completed rewards are claimed once per date/challenge.
- Completing a daily run grants one 10-shard reward per date; missing a date has no penalty.

## How to test

- Verify same date gives identical seed/rotation, another date changes them and rewards cannot repeat.

## Known issues / TODO

- Platform-clock rollback is treated as another local date; no server authority is intended.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Planned for Milestone 3 |
| 2026-09-11 | Implemented; verified by headless tests and visual QA — Milestone 3 complete |
