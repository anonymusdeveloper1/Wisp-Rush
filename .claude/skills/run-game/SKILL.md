---
name: run-game
description: Run Wisp Rush and verify it works — headless validation, a live run through the Godot MCP server with debug output, and an optional screenshot. Use when asked to run, test, play or screenshot the game, or to confirm a change works in the real game.
---

# Run & verify Wisp Rush

Repo root: `/Users/dimitarslezenkovski/Desktop/Wisp Rush`.

1. **Validate headlessly.** `tools/validate.sh` → it must end with `VALIDATE: OK`. On failure, read
   `logs/errors.log`, fix, repeat. Don't go on to step 2 with a failing validation.
2. **Live run via MCP.**
   - `mcp__godot__run_project` with `projectPath` = repo root (add `scene` = `res://…tscn` to run
     one scene).
   - Wait 3–5 s, then `mcp__godot__get_debug_output`. Look for `SCRIPT ERROR`, `ERROR:`,
     `WARNING:` and the expected log lines (the bootstrap scene prints `[Main] boot ok`).
   - Always `mcp__godot__stop_project` at the end.
   - No MCP? Fall back to `"$GODOT" --headless --path . --quit-after 600` and read the output.
3. **Visual check (when visuals changed).** `tools/screenshot.sh [res://scene.tscn] [frames]` then
   Read `logs/screenshot.png`. Use more frames if things animate in.
4. **Hand-off to the owner (optional).** `mcp__godot__launch_editor` opens the editor so they can
   play it themselves.

Report: validation result, errors/warnings verbatim with file:line, what you observed, and
whether the change behaves as intended. For longer play sessions, delegate to the `playtester`
subagent.
