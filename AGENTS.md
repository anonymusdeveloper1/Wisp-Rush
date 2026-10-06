# AGENTS.md — Operating manual for AI agents

> Applies to **every** AI agent working on Wisp Rush (Claude Code, Codex, Cursor, …).
> Claude Code specifics are in [CLAUDE.md](CLAUDE.md). The project map and the documentation
> rules are in [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md).

## 0. STRICT RULES — the owner's, above everything else in this repo

These override every other instruction, workflow, skill and default (owner, 2026-09-25).

1. **Not sure? Ask — do not generate.** If you are not sure what the owner wants, did not fully
   understand the message, or are not sure what you are doing, **stop and ask the owner** for clear
   instructions before you write, change, generate, build or delete anything. Ask a short, concrete
   question (options plus your recommended one) and wait for the answer. Never guess and produce
   something to fill the gap.
2. **No bluffing. Never write anything the owner did not tell you or mention.** No invented rules,
   requirements, values, features, plans, explanations or "facts" — in code, docs, comments, art
   prompts or messages. Everything you write must come from the owner's words, the approved work,
   or something you actually did or measured and can show. (The pixel-art "outline" rule was
   invented this way; Patchvile, the approved example, never had one.)
3. **Docs: when you are not certain, ask first.** If you are not certain whether something belongs
   in the docs, or what it should say, **ask the owner before writing it**. The docs a requested
   change requires (the DEVLOG entry, the registries and pages the change touched) record only
   what was done, measured or decided by the owner — never guesses, and never an `ASSUMPTION:` the
   owner did not approve.
4. **Do only what was asked.** Anything beyond the request — an extra change or fix, a new file, a
   "while I'm here" improvement — is proposed and asked about, not done.
5. **A question gets an answer, not a change.** When the owner asks a question, answer it and wait.

## 1. Read order (before changing anything)

1. This file.
2. [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) — status, repo map, registries, **documentation rules (§7)**.
3. [docs/generated/PROJECT_MAP.md](docs/generated/PROJECT_MAP.md) — everything that exists (generated).
4. [docs/GDD.md](docs/GDD.md) — the sections relevant to your task.
5. `docs/systems/<system>.md` for each system you touch; [docs/CONVENTIONS.md](docs/CONVENTIONS.md) before writing code.
5b. **Touching UI, art or feel?** **The game is 2D pixel art**
   ([ADR-0018](docs/decisions/0018-pixel-art-direction.md), GDD §9): every new asset sits on a pixel
   grid with a limited palette, crisp edges and no anti-aliasing, gradients or blur (the UI is drawn
   with nearest filtering). **Characters are drawn exactly like Patchvile** (owner, 2026-09-25): no
   outline, and the colours and soft edges AutoSprite's pixel filter gives (character guide §3).
   There is no painterly art, and every image prompt must say so. There is no 3D art except
   arenas: **arenas may be 3D** and need not be pixel-rendered (owner, 2026-09-30,
   [ADR-0023](docs/decisions/0023-3d-arenas.md)); how a 3D arena is built: arena guide §5.
   Read [docs/systems/ui_design_system.md](docs/systems/ui_design_system.md)
   (theme type variations, `Palette`, the pixel UI kit in `concept_art/wisp_rush_pixel_ui_v1/`),
   `concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md` (palette and UX; its painterly style is
   superseded) and its six-screen board, plus [ADR-0005](docs/decisions/0005-visual-redesign-v1.md)
   (redesign, generated art pipeline) and [ADR-0006](docs/decisions/0006-inset-playfield-and-larger-sprites.md)
   (inset playfield, sprite/hitbox scale). **Adding or changing a playable character?** Start with
   [docs/guides/character_creation.md](docs/guides/character_creation.md) — the AutoSprite recipe
   (what to generate, packing, the states, the per-character shaders and effects; Patchvile is the
   worked example), and its **AutoSprite rules** for prompts and settings (§3). **Every character has Patchvile's pixel count** (owner, 2026-09-24): standing,
   194 px tall in AutoSprite's 256 px frame (776 px on Codex's 1024 first frame), every pose at one
   scale, packed with `"roster_scale": True`, and the packer's `ROSTER CHECK` must say `ok` (guide
   §3–§4). **Every character is the same size everywhere** (owner, 2026-09-26); Scarlet's sheets
   were made at 166 px, so her scene draws her 1.16× larger. **Every character, new or redesigned, stands centred on Home's
   platform** (owner, 2026-09-27): feet on the platform's centre, body centred over it; the scene's
   `menu_offset` fixes a storefront frame that does not (guide §6). New characters are **whole-frame sprites, not bone rigs** (owner, 2026-09-20); no rigged character is
   left since Morrow was removed (owner, 2026-10-05), so
   [docs/guides/character_rig_recipe.md](docs/guides/character_rig_recipe.md) is history. Then
   [docs/systems/playable_character_visuals.md](docs/systems/playable_character_visuals.md) and
   [ADR-0015](docs/decisions/0015-animated-playable-characters.md).
5c. **Making a devlog video (TikTok / YouTube Shorts)?** [docs/marketing/devlog_video_recipe.md](docs/marketing/devlog_video_recipe.md)
   (owner-approved recipe: rules, structures, Palmier Pro blueprint, QA), [docs/marketing/devlog_hooks.md](docs/marketing/devlog_hooks.md)
   (the hook library every episode picks from), [tools/video/README.md](tools/video/README.md)
   (commands) and [docs/marketing/devlog_video_brief.md](docs/marketing/devlog_video_brief.md) (what may be shown).
5d. **Making or changing the arena?** The game has one arena, **SIMULATION**, a board (owner, 2026-10-05,
   [ADR-0027](docs/decisions/0027-one-arena-simulation.md); [ADR-0025](docs/decisions/0025-sci-fi-board-and-arena-spawn-effects.md)):
   Codex's pixel-art kit in `concept_art/boards_v1/sci_fi_simulation_v1/` (`manifest.json`), copied into the
   game by `python tools/art/make_board.py sci_fi_simulation_v1` and laid out by `SciFiBoardVisual`
   ([docs/systems/endless_mode.md](docs/systems/endless_mode.md), [arena guide](docs/guides/arena_art.md) §6).
   The rest of the arena guide is the painted-arena contract of the removed arenas.
5e. **Adding or changing an enemy?** [docs/systems/enemies.md](docs/systems/enemies.md) — the Enemies v2
   enemies (five in the game since 2026-09-28): `WholeFrameEnemy` (moving, the swipe, lunge and shot
   attacks, the slice kill), `EnemyProjectile` (shots and the wall mark), what kills the Wisp, and the
   ramp that picks them ([docs/systems/wave_director.md](docs/systems/wave_director.md)). The design and
   the owner's decisions are in [docs/specs/enemies_v2/README.md](docs/specs/enemies_v2/README.md): the owner
   makes enemies one at a time, and no art, prompts or code for an enemy before the owner approves it
   there. An enemy's art is the owner's sheets (a move and an attack), copied unchanged into
   `concept_art/enemies_v2_autosprite_v1/raw/<enemy>/`, then cleaned of AutoSprite's white leftovers and
   packed by `python concept_art/enemies_v2_autosprite_v1/pack_enemies.py` (check its `review/`), then
   `tools/validate.sh`.
6. The newest 2–3 entries of [docs/DEVLOG.md](docs/DEVLOG.md) and the active milestone in [docs/ROADMAP.md](docs/ROADMAP.md).

## 2. Ground rules

- **The strict rules in §0 come first**: not sure → ask; never write what the owner did not say;
  do only what was asked. Check a documented rule against the approved work before you apply it.
- **Portrait only** (owner, 2026-10-02): the game is played vertically, never horizontally or in
  landscape. It is locked to portrait (`display/window/handheld/orientation=1` in `project.godot`; the
  Android build's `screenOrientation` is portrait) and does not rotate. Design every screen, arena and
  asset for portrait only; never add a landscape layout.
  The steps this manual requires for a change you *were* asked to make (validate, the docs it
  triggers, the DEVLOG entry) count as asked.
- **Codex as a tool** (owner, 2026-10-05): Codex may be used as a tool through its command line
  (§4). It may make **simple sprite sheets**; the other sprite sheets are made in AutoSprite.
- **Godot 4.7.2, GDScript only, static typing.** Use Godot 4 APIs; never Godot 3 syntax
  (`yield`, `onready var`, string-based `connect`). Unsure about an API? Check the 4.x class
  reference (docs.godotengine.org/en/stable) — don't guess signatures.
- **The GDD is authoritative for design.** Don't invent mechanics. If the GDD is silent, ask the
  owner, recommending the simplest option; don't choose for them. Record the answer in GDD §14.
- **Never** edit `.godot/`, hand-edit `*.import` files, or invent `uid://` values.
- **Small, verifiable steps.** Run `tools/validate.sh` after each meaningful edit, not just at the end.
- **Docs are part of the change.** Follow the update-trigger table in PROJECT_CONTEXT §7.2.
- **Stay in scope.** Note unrelated problems in your DEVLOG entry's follow-ups and tell the owner; don't fix them unasked.
- **Git:** don't commit or push unless the owner asks. Commit messages follow CONVENTIONS §12.

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
| Build + deploy the Android debug APK (device over USB) | `JAVA_HOME=$(/usr/libexec/java_home) "$GODOT" --headless --path . --export-debug "Android" build/android/wisp_rush_debug.apk` then `~/Library/Android/sdk/platform-tools/adb install -r -t build/android/wisp_rush_debug.apk` and `adb shell monkey -p com.cognitix.wisprush -c android.intent.category.LAUNCHER 1` (the activity is `GodotAppLauncher` and is **not exported**, so `am start -n` is denied). The export is a **Gradle build** since 2026-10-05 (the AdMob plugin needs it, ADR-0029): on a fresh machine add `--install-android-build-template` to the first export (installs Godot's template in the git-ignored `android/`); the first build downloads Gradle and Google's SDK. |
| Same, **on Windows** (this checkout at `D:\Wisp Rush`) | `GODOT_PATH=/d/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe` for every `tools/*.sh`; export with `JAVA_HOME="C:/Program Files/Android/Android Studio/jbr" "$GODOT" --headless --path . --export-debug "Android" build/android/wisp_rush_debug.apk`, then `"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" install -r -t build/android/wisp_rush_debug.apk` and the same `monkey` launch. Read the device log with `adb logcat -d -s godot` |
| Run Codex as a tool, **on Windows** (owner, 2026-10-05; sprite sheets only simple ones, §2) | The CLI comes with the Codex app and is not on the PATH: `codex.exe` in `C:\Program Files\WindowsApps\OpenAI.Codex_<version>_x64__2p2nqsd0c76g0\app\resources\` (`codex-cli 0.160.0` on 2026-10-05; the folder changes with each app update, and `Get-AppxPackage -Name OpenAI.Codex` gives it). `"$CODEX" exec -C "D:/Wisp Rush" --sandbox workspace-write -o <file> "<prompt>"` runs one task and writes Codex's last message to `<file>`; `-i <image>` attaches an image, `--json` prints its events. It uses the owner's ChatGPT login; image generation is on |
| Screenshot of what the game renders | `tools/screenshot.sh [res://scene.tscn] [frames] [size]` → `logs/screenshot.png` |
| Run the game (window) | `"$GODOT" --path .` |
| Devlog video (capture, voice, graphics, sounds; edit in Palmier Pro) | [tools/video/README.md](tools/video/README.md), recipe [docs/marketing/devlog_video_recipe.md](docs/marketing/devlog_video_recipe.md) |
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
absolute repo root: `/Users/dimitarslezenkovski/Desktop/Wisp Rush` on the Mac, `D:/Wisp Rush` on
the Windows checkout.

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
in `.mcp.json` are absolute to the Mac (node via nvm, Godot on the Desktop). The Windows checkout
does not edit `.mcp.json`; it overrides it with a **local-scope** server of the same name, `godot`, in
`~/.claude.json` under the `D:/Wisp Rush` project (local beats project scope):
command `C:\Program Files\nodejs\node.exe`, argument
`D:\Wisp Rush\tools\mcp\node_modules\@coding-solo\godot-mcp\build\index.js`, env `GODOT_PATH`
`D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`. MCP servers load when a session
starts, so start a new one after changing either. Reinstall the server with `cd tools/mcp && npm ci`
(`node_modules` is git-ignored, so a fresh checkout needs it).

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
- **`.tscn` and `.tres` have no comments.** A `#` line inside a `[node]` block is not ignored:
  the parser stops reading properties there, so everything below it is silently dropped and
  the node loads with defaults. Put the explanation in the script instead.
- **`ext_resource` ids must start with a number** (`14_aura`, not `aura`). Godot writes them that
  way and its text loader relies on it: a purely alphabetic id parses inconsistently and shows up
  as `Parse Error` on an unrelated line of the *same* file, or on another scene entirely.
- `load_steps` is `ext_resource` + `sub_resource` + 1. Too high is harmless (several scenes here
  carry an inflated one); never leave it too low.
- `parent="."` = child of root; deeper nodes use a path relative to root (`parent="Body/Arm"`).
- `id` values of `ext_resource` only need to be unique inside the file.
- After any hand edit: `tools/validate.sh`. When the change is structural, also re-save the scene
  (`save_scene` via MCP) so Godot normalises it.

## 6. Definition of Done

Copy of PROJECT_CONTEXT §7.8 — that section is authoritative:
`validate.sh` OK · behaviour verified by running the game · `##` docs on public API ·
§7.2 update triggers done · project map regenerated · DEVLOG entry written.

## 7. Asking the owner

Ask (briefly, with a recommended default) **before** doing anything the owner did not ask for,
whenever you are unsure what they want or what you are doing, whenever you are not certain
something belongs in the docs (§0), and whenever the design is ambiguous, an asset is missing, or
a change needs a new dependency/addon. Don't decide for the owner and keep moving: wait for the
answer, then record exactly what they decided (GDD §14 or an ADR).
