# ADR-0003: Local SaveManager autoload

> **Status:** Accepted
> **Date:** 2026-09-11 · **Deciders:** owner prompt v2 / Codex

## Context

Tutorial state, statistics, Soul Shards, forms and challenge progress must survive every screen and
application restart. Scene-owned or duplicated state would make important writes easy to miss.

## Options considered

1. **One SaveManager autoload with validated JSON and atomic rotation** — one authority and simple
   screen access; introduces a carefully bounded global service.
2. **Main-owned state passed into every screen** — no global, but persistence/lifecycle handling
   becomes coupled to the current composition root.
3. **ConfigFile per system** — convenient settings API, but fragments migrations and atomicity.

## Decision

Register one `SaveManager` Node autoload. It owns a versioned JSON-compatible Dictionary, validation,
migration, atomic temp/main/backup writes and progression mutation methods. Gameplay remains
run-local; only completed or explicitly important progression crosses this boundary.

## Consequences

Persistent state has one testable authority and can save on interruption. New schema fields require
validation and migration. SaveManager must not become a general event bus or hold active scene nodes.
