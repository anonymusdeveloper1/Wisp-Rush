# System: <Name>

> **Status:** ⬜ planned · 🔄 in progress · ✅ done — pick one ·
> **Last updated:** YYYY-MM-DD · **GDD section:** §N
>
> Copy this file to `docs/systems/<system_name>.md` (snake_case), fill it, and add a row to
> `docs/PROJECT_CONTEXT.md` §5.1. Keep it under ~150 lines; link instead of repeating.

## Purpose
One to three sentences: what this system does for the player and for other systems.

## Files
| Path | Role |
|---|---|
| `res://scenes/<feature>/<thing>.tscn` | |
| `res://scenes/<feature>/<thing>.gd` | |

## Scene / node structure
```
Thing (CharacterBody2D)  thing.gd
├── %Sprite (AnimatedSprite2D)
├── %HurtBox (Area2D)
└── HealthComponent       scripts/components/health_component.gd
```

## Public API
What other systems may use. Anything not listed here is private.

| Member | Kind | Description |
|---|---|---|
| `died` | signal | Emitted once when health reaches 0. |
| `apply_damage(amount: int)` | method | |

## Data & tuning
Where balance values live (Resource class + `.tres` paths) and their starting values.

## Dependencies
Autoloads, other systems, input actions, physics layers, groups this system relies on.

## Rules & behaviour
Bullet list of the rules, including edge cases and ordering assumptions.

## How to test
- Manual: steps to reproduce in-game (scene to run, what to press, what you should see).
- Automated: test files, if any.

## Known issues / TODO
- 

## Change history
| Date | Change |
|---|---|
| YYYY-MM-DD | Created |
