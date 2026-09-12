# System: Tutorial

> **Status:** ✅ done · **Last updated:** 2026-09-11 · **GDD section:** §11

## Purpose

Teach the defining loop inside the live arena: first safe wall dash, one Soul Wisp slice, then a
three-enemy reap. Guidance floats over the world and never captures gameplay input.

## Files

| Path | Role |
|---|---|
| `res://scenes/tutorial/tutorial_overlay.tscn` | Safe-area guidance presentation |
| `res://scenes/tutorial/tutorial_overlay.gd` | Step text/progress and completion fade |
| `res://scenes/gameplay/game_world.gd` | Tutorial state and deterministic target placement |
| `res://scenes/main/main.gd` | Enables tutorial on the first run of this app session |

## Scene / node structure

```text
TutorialOverlay (Control)  tutorial_overlay.gd
└── GuideMargin
    └── %Panel
        ├── %StepLabel
        └── %InstructionLabel
```

## Public API

| Member | Kind | Description |
|---|---|---|
| `show_step(message, step, total)` | method | Display one non-blocking tutorial instruction. |
| `show_completion(message)` | method | Celebrate, then fade the guide away. |
| `GameWorld.tutorial_completed` | signal | Three-enemy lesson completed successfully. |
| `GameWorld.is_tutorial_complete()` | method | Test/read whether the lesson is disabled or complete. |

## Data & tuning

Script constants define the deterministic target line and short completion-to-training delay.
Tutorial targets use normal Soul Wisp data but disable movement after arrival.

## Dependencies

Player dash/wall signals, enemy kill signals, GameWorld formations and Game flow session state.

## Rules & behaviour

- Redesign v1: the lesson card uses the themed frame above the instruction band; the lesson steps and gating are unchanged.
- Step 1 has no enemies and completes on the first safe wall impact.
- Step 2 spawns one stationary Soul Wisp and completes when sliced.
- Step 3 spawns three stationary enemies on the Wisp's current edge-to-edge ray.
- Missing the triple reap rebuilds a readable three-target line from the new edge.
- Completion starts normal training formations and is remembered for this app session.

## How to test

- Fresh launch: complete wall dash → one slice → triple reap; normal formations begin.
- Restart in the same app session: tutorial stays hidden.
- UI remains clickable and swipe input is never consumed by the overlay.
- Automated: `tools/godot/test_tutorial_flow.gd` performs the complete three-step lesson.

## Known issues / TODO

- Cross-launch tutorial completion persists when the versioned SaveManager arrives in Milestone 3.

## Change history

| Date | Change |
|---|---|
| 2026-09-12 | Restyled to redesign v1 (ADR-0005) |
| 2026-09-11 | Implemented non-blocking three-step lesson, retry line and session gating |
| 2026-09-11 | Planned for the second Milestone 1 slice |
