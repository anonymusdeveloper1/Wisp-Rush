---
name: new-system
description: Scaffold a new gameplay system in Wisp Rush the documented way — system doc first, then feature folder, scene + script, data resource, registries. Use when adding a mechanic or subsystem (player movement, spawner, scoring, HUD, audio…).
---

# New gameplay system

Input: the system name (snake_case, e.g. `wisp_dash`) and the GDD section it implements.

1. **Doc first.** Copy `docs/systems/_TEMPLATE.md` → `docs/systems/<name>.md`. Fill Purpose,
   planned Files, Public API, Data & tuning, Dependencies, Rules from the GDD. Status ⬜ planned.
   Add a row to `docs/PROJECT_CONTEXT.md` §5.1 and a task in `docs/ROADMAP.md`.
2. **Files.** Follow CONVENTIONS §3–5:
   - scene-owned → `scenes/<feature>/<thing>.tscn` + `<thing>.gd` (create the scene via
     `mcp__godot__create_scene` or as text per AGENTS.md §5);
   - reusable components → `scripts/components/<name>_component.gd` with `class_name`;
   - tuning → `scripts/resources/<name>_config.gd` (`class_name`, `extends Resource`, `@export`s)
     and an instance in `data/<name>/…tres`.
   - every script: `##` class doc (one-line summary first), `##` on public API, static types.
3. **Registries.** New input actions, physics layers, groups, autoloads or EventBus signals go in
   `project.godot` **and** the matching PROJECT_CONTEXT §5 table in the same change.
4. **Verify.** Use the `run-game` skill (validate → MCP run → screenshot if visual).
5. **Close out.** System doc status 🔄/✅ with change history; DEVLOG entry; ADR if you introduced
   an architectural pattern, autoload or dependency.
