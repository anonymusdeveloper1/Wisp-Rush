class_name ArenaSkinData
extends Resource
## One Endless arena: the scene a run is played on (an `ArenaVisual`). The game has one arena,
## SIMULATION (owner 2026-10-05, ADR-0027); the painted, layered and 3D arenas and the Shop's ARENAS
## tab were removed.

## Stable identifier stored in the save (`owned_arena_skins`, `equipped_arena_skin`).
@export var skin_id: StringName
## Player-facing arena name (the run loading screen's subheading, the daily seed line).
@export var display_name: String
## Short flavour text.
@export_multiline var description: String
## The arena's scene (an `ArenaVisual`), which a run shows and takes its floor from. A path, loaded
## only when a run starts ([method load_visual_scene]).
@export_file("*.tscn") var visual_scene_path: String = ""


## Whether the arena names a scene.
func has_visual_scene() -> bool:
	return not visual_scene_path.is_empty()


## Loads the arena's scene, or null when it has none.
func load_visual_scene() -> PackedScene:
	if not has_visual_scene() or not ResourceLoader.exists(visual_scene_path):
		return null
	return load(visual_scene_path) as PackedScene


## Returns authoring failures for this arena.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if skin_id.is_empty():
		failures.append("skin id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if not has_visual_scene() or not ResourceLoader.exists(visual_scene_path):
		failures.append("scene %s is missing" % visual_scene_path)
	return failures
