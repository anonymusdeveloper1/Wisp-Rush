# Conventions

> How code, scenes, files and commits must look in Wisp Rush. Based on the official
> [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
> plus project-specific rules. If a rule here conflicts with habit, this file wins; if it must
> change, record the reason in an ADR (`docs/decisions/`).

## 1. Language & engine

- **GDScript only** on Godot **4.7** (no C#, no GDExtension unless an ADR approves it).
- **Static typing everywhere.** Typed vars, params, returns, typed arrays/dictionaries.
  The project warns on untyped declarations (`debug/gdscript/warnings/untyped_declaration`).
  ```gdscript
  var speed: float = 220.0
  var enemies: Array[Enemy] = []
  var scores: Dictionary[StringName, int] = {}
  func take_damage(amount: int, source: Node = null) -> void:
  ```
  `:=` is fine when the type is obvious from the right-hand side (`var dir := Vector2.ZERO`).
- Use Godot 4 idioms: `@export`, `@onready`, `%UniqueName`, `signal.connect(callable)`,
  `await signal`, typed `StringName` literals (`&"jump"`). No Godot 3 syntax (`onready var`,
  `yield`, `connect("sig", obj, "method")`).

## 2. Naming

| Thing | Style | Example |
|---|---|---|
| Files & folders | `snake_case` | `wisp_player.tscn`, `wisp_player.gd` |
| `class_name` / inner classes | `PascalCase` | `class_name HealthComponent` |
| Nodes in scene tree | `PascalCase` | `HurtBox`, `DashTimer` |
| Functions, variables | `snake_case` | `apply_dash()`, `max_speed` |
| Private members | `_snake_case` | `_velocity`, `_on_hit()` |
| Constants & enum members | `CONSTANT_CASE` | `const MAX_LIVES := 3`, `State.RUNNING` |
| Enums | `PascalCase` | `enum State { IDLE, RUNNING }` |
| Signals | past-tense `snake_case` | `died`, `health_changed(old, new)` |
| Signal handlers | `_on_<node>_<signal>` | `_on_hurt_box_area_entered` |
| Input actions | verb `snake_case` | `move_left`, `jump`, `dash`, `pause` |
| Groups | plural `snake_case` | `enemies`, `pickups` |
| Resources (data) | `snake_case.tres` | `data/enemies/ember_imp.tres` |

Never rely on case differences to distinguish files — exports to case-sensitive platforms break.

## 3. Script layout (order inside a `.gd` file)

```gdscript
@tool                                  # only if needed
class_name WispPlayer                  # only if other code refers to the type
extends CharacterBody2D
## One-sentence summary (the project map shows this line).
##
## Longer description: responsibilities, collaborators, gotchas.

signal died                            # 1. signals
enum State { IDLE, RUNNING, DASHING }  # 2. enums
const DASH_TIME := 0.15                # 3. constants
@export var stats: PlayerStats         # 4. @export vars (use @export_group to organise)
var state: State = State.IDLE          # 5. public vars
var _dash_left: float = 0.0            # 6. private vars
@onready var _sprite: AnimatedSprite2D = %Sprite   # 7. @onready vars

func _init() -> void: ...              # 8. built-in virtuals, in lifecycle order:
func _ready() -> void: ...             #    _init, _enter_tree, _ready, _unhandled_input,
func _physics_process(delta: float) -> void: ...  # _process, _physics_process, _exit_tree
func apply_dash() -> void: ...         # 9. public methods
func _update_state() -> void: ...      # 10. private methods / signal handlers
```

- Two blank lines between functions; tabs for indentation; lines ≤ 100 chars.
- `class_name` only for types referenced elsewhere (components, resources, base classes).
  Scene-root scripts used only by their scene don't need it — fewer global names.

## 4. Scenes & nodes

- **One feature per folder** under `scenes/`: `scenes/player/player.tscn` + `player.gd` (+ its
  private sub-scenes). The scene and its root script share a basename.
- **Composition over inheritance.** Build behaviour from child component nodes
  (`scripts/components/`), e.g. `HealthComponent`, `HitboxComponent`, `VelocityComponent`.
- **Call down, signal up.** A node may call methods on its children; children never reach up
  (`get_parent()` chains, `../../` paths are forbidden). Siblings talk through their parent or the
  `EventBus` autoload.
- Nodes accessed from script get **scene-unique names** (`%Sprite`), so re-parenting doesn't break
  paths. Cross-scene references use `@export var target: Node2D`, not hard-coded paths.
- Prefer connecting signals in code inside `_ready()` — editor-wired connections are invisible
  to text search (the project map lists them, but code is clearer).
- Instanced sub-scenes are self-contained: they must work when run alone (F6) or fail loudly.
- Don't put gameplay logic in UI nodes; UI observes state via signals.

## 5. Data & tuning

- Balance values (speeds, damage, spawn rates, timings) live in custom `Resource` classes
  (`scripts/resources/*.gd` with `class_name`) instantiated as `.tres` in `data/`.
- No magic numbers in logic: name them as `const` or put them in a resource.
- Strings used as identifiers → `StringName` constants (`const ACTION_JUMP := &"jump"`).

## 6. Autoloads (singletons)

- Allowed only for true global services: `EventBus` (global signals), `GameState` (run/session
  data), `Audio` (music/SFX), `SceneLoader` (transitions). Anything else needs an ADR.
- Autoload scripts live in `scripts/autoload/`, are named after their singleton
  (`event_bus.gd` → `EventBus`), and must be registered in `docs/PROJECT_CONTEXT.md` §5.3.
- `EventBus` only declares signals — no state, no logic.

## 7. Input, physics, groups

- Never hard-code keys/buttons. Define actions in Project Settings → Input Map; query via
  `Input.is_action_pressed(&"jump")` / `_unhandled_input`.
- Name every physics layer you use (Project Settings → Layer Names). Never use unnamed layer bits.
- Every action, layer and group gets a row in `docs/PROJECT_CONTEXT.md` §5.

## 8. Errors, debugging, performance

- `assert()` for programmer errors (stripped in release); `push_error()` / `push_warning()` for
  recoverable runtime problems. Never swallow errors silently.
- Debug prints use a tag: `print("[Player] dash start")`. Remove noisy per-frame prints before
  committing.
- Movement & physics in `_physics_process`; visuals in `_process`. Avoid per-frame allocations
  in hot paths; pool frequently spawned objects (projectiles, particles) once counts get high.
- Use `get_tree().create_tween()` / `Tween` for juice instead of hand-rolled lerps in `_process`.

## 9. Files Godot owns — handle with care

- Never edit or commit `.godot/`. Never hand-edit `*.import` files (change import settings in the
  editor or via MCP).
- Commit `*.uid` files that Godot generates next to scripts/shaders (Godot 4.4+ uses them to keep
  references stable).
- **Moving/renaming** scenes, scripts or assets: prefer the Godot editor (it fixes references). If
  done on the filesystem, grep for the old `res://` path, update every reference, then run
  `tools/validate.sh`.
- Hand-editing `.tscn`/`.tres` is fine for small property tweaks. For structural changes prefer the
  editor or the Godot MCP tools. **Never invent `uid://` values** — omit the `uid` attribute and let
  Godot assign one.

## 10. Tests

- Tests live in `tests/` mirroring the source path (`tests/scripts/components/test_health_component.gd`).
- Framework: _TBD_ (candidate: GUT or GdUnit4 — decide by ADR when first tests are needed).
- Pure logic (damage math, scoring, spawn tables) should be testable without a running scene.

## 11. UI and art

- Style Controls **only** through the project Theme: set `theme_type_variation` (see
  [systems/ui_design_system.md](systems/ui_design_system.md)); never add per-node `StyleBoxFlat` or
  colour overrides. Colours in code come from `Palette`.
- Text is always rendered by Godot; never bake words into images.
- Runtime art in `assets/art/` is generated — change `tools/art/redesign_v1_slices.json` (or the
  pipeline) and re-run `python3 tools/art/extract_redesign.py`, then `tools/validate.sh`.
  `assets/legacy_v1/` is the ignored archive of the previous art; `concept_art/` holds read-only sources.
- Icons and small text must stay readable on a 390 pt phone: secondary text ≥ 22 px in the 1080-wide
  design space, touch targets ≥ 48 px.

## 12. Git

- Branch per task: `feat/<short-name>`, `fix/<short-name>`, `docs/<short-name>`.
- Conventional commits, scope = system or area:
  `feat(player): add dash with i-frames`, `fix(spawner): clamp wave index`, `docs(context): register dash input`.
- One logical change per commit, including its docs updates (see PROJECT_CONTEXT §7.2).
- Never commit with a failing `tools/validate.sh`.
