# CLAUDE.md

@AGENTS.md

## Claude Code specifics

- **MCP:** server `godot` from `.mcp.json` (macOS paths), approved in `.claude/settings.json`. The
  Windows checkout overrides it with a local-scope `godot` entry of the same name that has Windows
  paths (AGENTS.md §4). Its tools appear as `mcp__godot__<tool>` (tool guide: AGENTS.md §4). Video
  work uses `palmier-pro` (Palmier Pro's own server, registered in the local Claude config; the app
  must be open) — `tools/video/README.md`. Blender is not an MCP server here: a 3D arena's model is
  built by a script run with Blender headless (`D:\Blender\blender.exe` on the Windows checkout;
  ADR-0023, arena guide §5).
- **Codex** (owner, 2026-10-05): Claude Code may use Codex as a tool by running its CLI
  (`codex exec`; the rule in AGENTS.md §2, the command in §4). It may make simple sprite sheets;
  the other sprite sheets are made in AutoSprite.
- **Pre-approved commands** (`.claude/settings.json`): `tools/validate.sh`,
  `node tools/project_map.mjs`, the Godot binary, read-only git plus `git add`, and all `godot` MCP
  tools. Edits to `.godot/` are denied.
- **SessionStart hook:** reports whether `docs/generated/PROJECT_MAP.md` is stale. If it is, run
  `tools/validate.sh` before relying on the map.
- **Subagents** (`.claude/agents/`) — delegate to keep the main context lean:
  - `playtester` — runs the game via MCP and reports errors, warnings and observed behaviour.
  - `gdscript-reviewer` — reviews changed GDScript/scenes against CONVENTIONS and Godot 4.7 APIs.
  - `docs-keeper` — syncs PROJECT_CONTEXT registries, system docs, DEVLOG after a change.
- **Skills** (`.claude/skills/`): `run-game` (run + verify loop), `new-system` (scaffold a gameplay
  system with its doc), `update-docs` (end-of-task documentation pass), `devlog-video` (make a
  TikTok / Shorts devlog in Palmier Pro by the owner-approved recipe).
- **Current look: 2D pixel art** (owner, 2026-09-24, ADR-0018). All new art sits on a pixel grid
  with limited palettes, crisp edges and nearest filtering, except characters, which are drawn
  exactly like Patchvile (no outline, AutoSprite's colours and soft edges; owner, 2026-09-25);
  there is no painterly art, and no 3D art except arenas, which may be 3D (owner, 2026-09-30,
  ADR-0023). Painted assets still in the game are legacy until redrawn. UI styling comes from the project Theme's type
  variations and `Palette`, built from the pixel UI kit (`concept_art/wisp_rush_pixel_ui_v1/`).
  Runtime art under `assets/art/` is generated (never hand-edit it): by the `tools/art/` scripts, or
  by a source pack's own packer (`concept_art/grimgrin_autosprite_v1/pack_grimgrin.py`,
  `concept_art/enemies_v2_autosprite_v1/pack_enemies.py` for the enemies, AGENTS.md 5e); the first art
  is archived in `assets/legacy_v1/`. See `docs/systems/ui_design_system.md`, ADR-0005
  (palette), ADR-0006 and ADR-0018.
- **Memory vs docs:** anything another agent needs goes in the repo docs, not in Claude's
  personal memory. Memory is only for owner preferences and cross-session context.
