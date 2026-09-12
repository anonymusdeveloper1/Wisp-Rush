---
name: update-docs
description: End-of-task documentation pass for Wisp Rush — apply the PROJECT_CONTEXT §7.2 update triggers, regenerate the project map, close documentation gaps and write the DEVLOG entry. Use before declaring any change done, or when docs seem out of date.
---

# Update docs

1. `tools/validate.sh` (also regenerates `docs/generated/PROJECT_MAP.md`). Fix failures first.
2. List what changed: `git status --porcelain` + `git diff --stat`.
3. Walk the trigger table in `docs/PROJECT_CONTEXT.md` §7.2 row by row and update every file
   it names for the changes you found. Common ones:
   - §5 registries ↔ `project.godot` (autoloads, input actions, layer names, groups);
   - `docs/systems/<name>.md` Files / Public API / Data / change history;
   - `docs/GDD.md` when behaviour or controls changed (+ change-history row);
   - `docs/ASSETS.md` for any new file under `assets/`;
   - `docs/ROADMAP.md` statuses and PROJECT_CONTEXT §2 when a milestone moved;
   - new ADR for architectural choices or new dependencies.
4. Open the map's **Documentation gaps** section: add the missing `##` class docs.
5. Write the `docs/DEVLOG.md` entry (format: PROJECT_CONTEXT §7.6), newest first.
6. Re-run `node tools/project_map.mjs --check` → must say up to date.

For large changes, delegate steps 3–5 to the `docs-keeper` subagent and review what it wrote.
