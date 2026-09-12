# ADR-0002: Godot MCP server

> **Status:** Accepted · **Date:** 2026-09-11 · **Deciders:** owner + setup agent

## Context
Agents must drive Godot from Claude Code: run the game, read errors, and create or edit scenes.
The machine has Godot 4.7.2 at `~/Desktop/Godot.app`, Node 22 via nvm, and only Python 3.7 with no
`uv`. The owner asked for a quick setup rather than a long evaluation.

## Options considered
1. **Coding-Solo/godot-mcp** (npm `@coding-solo/godot-mcp`) — the most widely used and recommended
   option. It's a standalone Node stdio server that calls the Godot binary directly; no editor plugin.
   Tools: run/stop project, debug output, launch editor, create scenes, add nodes, load sprites,
   UID tools. No screenshots, input simulation or live editor control.
2. **hi-godot/godot-ai** — editor-dock plugin + local Python server over WebSocket. Richer (live
   editor, screenshots), supports 4.7+, very active. Needs a modern Python toolchain (`uvx`),
   which this machine doesn't have.
3. **GDAI MCP** and other editor-addon servers — richer, but paid or less proven.

## Decision
Use **Coding-Solo/godot-mcp 0.1.1**, installed as a pinned local dependency in `tools/mcp/`
(`package.json` + lockfile, `node_modules` git-ignored). It's registered in `.mcp.json` as server
`godot`, using absolute paths to nvm's node and to the Godot binary (`GODOT_PATH`). Verified on
2026-09-11: `get_godot_version` returns `4.7.2.stable.official.ed1daf0bf`, and
`run_project` + `get_debug_output` show the bootstrap scene's `[Main] boot ok` line.

## Consequences
- `project.godot` sets `application/run/flush_stdout_on_print=true`. Without it, `print()` output
  is buffered and never reaches `get_debug_output` while the game runs. Keep this setting.
- Screenshots come from `tools/screenshot.sh` (Godot `--write-movie`), not the MCP.
- Scene edits go through headless Godot; if the editor is open on the same scene, it has to reload.
- `.mcp.json` is machine-specific (absolute paths). If node or Godot moves, update it; reinstall with
  `cd tools/mcp && npm install`.
- Revisit option 2 (godot-ai) if live-editor control or in-editor screenshots become important:
  install `uv`, add its addon to `addons/`, and write a superseding ADR.
