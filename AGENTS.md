# AGENTS.md — Operating manual for AI agents

> Applies to **every** AI agent working on Wisp Rush (Claude Code, Codex, Cursor, …).
> Claude Code specifics are in [CLAUDE.md](CLAUDE.md). The project map and the documentation
> rules are in [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md).

## 1. Read order (before changing anything)

1. This file.
2. [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) — status, repo map, registries, **documentation rules (§7)**.
3. [docs/generated/PROJECT_MAP.md](docs/generated/PROJECT_MAP.md) — everything that exists (generated).
4. [docs/GDD.md](docs/GDD.md) — the sections relevant to your task.
5. `docs/systems/<system>.md` for each system you touch; [docs/CONVENTIONS.md](docs/CONVENTIONS.md) before writing code.
5b. **Touching UI, art or feel?** [docs/systems/ui_design_system.md](docs/systems/ui_design_system.md)
   (theme type variations, `Palette`), `concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md` (art/UX
   authority) and its six-screen board, plus [ADR-0005](docs/decisions/0005-visual-redesign-v1.md)
   (redesign, generated art pipeline) and [ADR-0006](docs/decisions/0006-inset-playfield-and-larger-sprites.md)
   (inset playfield, sprite/hitbox scale).
6. The newest 2–3 entries of [docs/DEVLOG.md](docs/DEVLOG.md) and the active milestone in [docs/ROADMAP.md](docs/ROADMAP.md).

## 2. Ground rules

- **Godot 4.7.2, GDScript only, static typing.** Use Godot 4 APIs; never Godot 3 syntax
  (`yield`, `onready var`, string-based `connect`). Unsure about an API? Check the 4.x class
  reference (docs.godotengine.org/en/stable) — don't guess signatures.
- **The GDD is authoritative for design.** Don't invent mechanics. If the GDD is silent, ask the
  owner, or choose the simplest option, mark it `ASSUMPTION:` and list it in GDD §14.
- **Never** edit `.godot/`, hand-edit `*.import` files, or invent `uid://` values.
- **Small, verifiable steps.** Run `tools/validate.sh` after each meaningful edit, not just at the end.
- **Docs are part of the change.** Follow the update-trigger table in PROJECT_CONTEXT §7.2.
- **Stay in scope.** Note unrelated problems in your DEVLOG entry's follow-ups or the ROADMAP backlog instead of fixing them silently.
- **Git:** don't commit or push unless the owner asks. Commit messages follow CONVENTIONS §11.

## 3. Task workflow

1. **Orient** — follow the read order; find the system(s) and files involved.
2. **Plan** — list the files you'll touch and the doc updates the change triggers. A new system
   gets its `docs/systems/<name>.md` (status ⬜ planned) *before* code.
3. **Implement** — scene + script side by side in `scenes/<feature>/`; shared code in `scripts/`;
   tuning in `data/*.tres`.
4. **Verify** —
   - `tools/validate.sh` → must print `VALIDATE: OK`; `tools/run_tests.sh` → 0 failed.
   - Run the game through the Godot MCP (`run_project` → play for a few seconds → `get_debug_output`
     → `stop_project`) and check there are no errors and the expected log lines appear.
   - Visual changes: `tools/screenshot.sh [scene] [frames]`, then read `logs/screenshot.png`.
5. **Document** — PROJECT_CONTEXT registries, system doc, `##` doc comments, GDD/ADR if relevant.
6. **Log** — add a `docs/DEVLOG.md` entry (format in PROJECT_CONTEXT §7.6).

## 4. Commands & tools

`GODOT=/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot` · run commands from the repo root.

| Task | Command |
|---|---|
| Headless check: import, parse all scripts, boot main scene, refresh map | `tools/validate.sh` (`FRAMES=600` to boot longer) |
| Refresh / check the project map | `node tools/project_map.mjs` · `--check` |
| Run all headless tests (`tools/godot/test_*.gd`, 120 s timeout each) | `tools/run_tests.sh [name-filter]` → `TESTS: N passed, 0 failed` |
| Render a fixture (pause menu, Reaper, upgrades…) | `tools/godot/render_*_showcase.gd` — command in each file header |
| Performance overlay (debug builds) | F3 in the running game: FPS, frame times, draw calls, nodes, entities |
| Phone layout QA (real windows, 5 phone aspect ratios) | `tools/qa_matrix.sh [home forms …]` → Read `logs/qa/<screen>_sheet.png` |
| Frame-time benchmark | `"$GODOT" --headless --path . --script res://tools/godot/bench_stress.gd` |
| Regenerate runtime art (never hand-edit `assets/art/`) | `python3 tools/art/extract_redesign.py` → `tools/validate.sh` |
| Style UI | use theme type variations (`docs/systems/ui_design_system.md`) and `Palette`; no per-node StyleBoxFlat/colour overrides |
| Build + deploy the Android debug APK (device over USB) | `JAVA_HOME=$(/usr/libexec/java_home) "$GODOT" --headless --path . --export-debug "Android" build/android/wisp_rush_debug.apk` then `~/Library/Android/sdk/platform-tools/adb install -r -t build/android/wisp_rush_debug.apk` and `adb shell am start -n com.cognitix.wisprush/com.godot.game.GodotApp` |
| Screenshot of what the game renders | `tools/screenshot.sh [res://scene.tscn] [frames] [size]` → `logs/screenshot.png` |
| Run the game (window) | `"$GODOT" --path .` |
| Run one scene | `"$GODOT" --path . res://scenes/<feature>/<thing>.tscn` |
| Run headless with collision debug etc. | `"$GODOT" --headless --path . --quit-after 300` |
| Open the editor | `open -a ~/Desktop/Godot.app --args --path "$PWD" --editor` |
| Export `##` docs as XML | `"$GODOT" --headless --path . --doctool docs/generated/api --gdscript-docs res://scripts` |

Logs from the tools land in `logs/` (git-ignored): `import.log`, `check_scripts.log`, `boot.log`,
`errors.log`, `screenshot.log`, `tests/<name>.log`.

**Save isolation:** `validate.sh`, `screenshot.sh` and every `--script` test/fixture write to
`user://test_runs/`, never the owner's real save (`SaveManagerService.uses_isolated_storage()`).
MCP `run_project` and manual runs use the real save — that is playing the game. Tests that drive
`Main` must reuse the `/root/SaveManager` autoload (see `test_game_flow.gd`), not create a second one.

### Godot MCP server

Server **`godot`** (configured in [.mcp.json](.mcp.json)) = [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)
**0.1.1**, pinned in `tools/mcp/` (why: [ADR-0002](docs/decisions/0002-godot-mcp-server.md)).
It drives the Godot binary directly; no editor plugin is needed. `projectPath` is always the
absolute repo root: `/Users/dimitarslezenkovski/Desktop/Wisp Rush`.

| Tool | Use it to |
|---|---|
| `run_project` / `get_debug_output` / `stop_project` | Play the game and read stdout + errors (the main verification loop) |
| `launch_editor` | Open the editor for the owner (visual inspection, manual play) |
| `get_project_info` · `get_godot_version` · `list_projects` | Sanity checks |
| `create_scene` | New `.tscn` with a root node type |
| `add_node` | Add a child node (type, parent path, basic properties) to a scene |
| `load_sprite` | Assign a texture to a `Sprite2D` node |
| `save_scene` | Re-save a scene (e.g. to normalise it after text edits) |
| `get_uid` · `update_project_uids` | Resolve UIDs / repair UID references after moving files |
| `export_mesh_library` | 3D only: export a scene as a MeshLibrary for GridMap |

**Limitations.** There are no screenshot, input-simulation or live-editor tools — use
`tools/screenshot.sh` for visuals. Scene tools edit files through headless Godot, so if the owner
has the editor open, it may need to reload the scene. Attaching scripts, signals and complex
properties is easier by writing the `.gd` file and editing the `.tscn` text (see §5), then running
`tools/validate.sh`.

**If the server isn't connected:** check `claude mcp list` in a terminal from the repo root. Paths
in `.mcp.json` are absolute to this machine (node via nvm, Godot on the Desktop). Reinstall with
`cd tools/mcp && npm install`.

## 5. Editing Godot text files (cheat sheet)

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/player/player.gd" id="1_player"]
[ext_resource type="PackedScene" path="res://scenes/wisp/wisp.tscn" id="2_wisp"]

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_player")

[node name="Sprite" type="AnimatedSprite2D" parent="."]
unique_name_in_owner = true

[node name="Wisp" parent="." instance=ExtResource("2_wisp")]

[connection signal="timeout" from="DashTimer" to="." method="_on_dash_timer_timeout"]
```

- Leave out `uid="uid://…"` attributes on new entries — Godot fills them in on the next save/import.
- `parent="."` = child of root; deeper nodes use a path relative to root (`parent="Body/Arm"`).
- `id` values of `ext_resource` only need to be unique inside the file.
- After any hand edit: `tools/validate.sh`. When the change is structural, also re-save the scene
  (`save_scene` via MCP) so Godot normalises it.

## 6. Definition of Done

Copy of PROJECT_CONTEXT §7.8 — that section is authoritative:
`validate.sh` OK · behaviour verified by running the game · `##` docs on public API ·
§7.2 update triggers done · project map regenerated · DEVLOG entry written.

## 7. Asking the owner

Ask (briefly, with a recommended default) when: the design is ambiguous in a way that changes
the player experience, an asset is missing, or a change needs a new dependency/addon. Otherwise
decide, record it (ASSUMPTION or ADR), and keep moving.
