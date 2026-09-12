# ADR-0001: Project structure and documentation system

> **Status:** Accepted · **Date:** 2026-09-11 · **Deciders:** owner + setup agent

## Context
Wisp Rush is built mostly by AI agents working in separate sessions with no shared memory. Each
agent must orient quickly, find the one authoritative place for any fact, and leave the project as
understandable as it found it. The repo started empty; the game design and assets arrive later.

## Options considered
1. **Type-based layout** (`sprites/`, `scripts/`, `scenes/` for everything) — familiar, but a
   feature's files scatter across the tree, which makes changes and reviews harder.
2. **Feature-based layout** (`scenes/<feature>/` holds scene + script + private sub-scenes; shared
   code in `scripts/`, raw media in `assets/`, data in `data/`) — each feature's files sit together;
   shared pieces are explicit.
3. Docs only in code comments — no drift problem, but no place for design intent, decisions or
   cross-cutting registries.

## Decision
- Godot project at the **repository root** (`res://` = repo root); GDScript only, static typing.
- **Feature-based layout** (option 2). Documented in `docs/PROJECT_CONTEXT.md` §3.
- **Documentation system with one home per fact:** `AGENTS.md` (how to work) → `docs/PROJECT_CONTEXT.md`
  (the map, registries, documentation rules) → `docs/GDD.md`, `docs/systems/`, `docs/decisions/`,
  `docs/ROADMAP.md`, `docs/DEVLOG.md`, `docs/ASSETS.md`, `docs/CONVENTIONS.md`, plus `##` doc comments
  in code.
- **Generated inventory** `docs/generated/PROJECT_MAP.md` built by `tools/project_map.mjs` from the
  actual files, so "what exists" can never drift from reality; hand-written docs record meaning.
- **Headless validation** `tools/validate.sh` (import, parse all scripts, boot main scene, refresh
  map) as the minimum gate for every change.
- `docs/` and `tools/` contain `.gdignore` so Godot doesn't import them.

## Consequences
- Every change carries doc updates (update-trigger table, PROJECT_CONTEXT §7.2); reviewers can
  reject changes that skip them.
- Node.js is required for the project map (already required for the Godot MCP server).
- Moving files requires reference updates (editor/MCP preferred) — see CONVENTIONS §9.
