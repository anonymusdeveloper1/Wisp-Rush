class_name ModelArenaLayout
extends Resource
## Where things are on a 3D arena's model: its playable floor, its eye, its flames and skulls.
##
## Generated with the model by the arena's build script (for the CHAINED COLOSSUS 3D:
## `concept_art/arenas_v2/chained_colossus_3d/build_colossus.py`), never hand-edited, and read by
## [ModelArenaVisual]. Everything is in the model's own space, in Godot's axes (Y up, the model
## facing +Z), in model units.

## The flat playable floor on the model's board: x and y of its lower-left corner and its size. The
## floor faces the camera, so it is drawn as an exact rectangle.
@export var floor_rect: Rect2 = Rect2()
## Depth (z) of the floor's plane.
@export var floor_z: float = 0.0
## Centre of the glowing eye, on the surface, with the head at rest.
@export var eye: Vector3 = Vector3.ZERO
## The skeleton bone that turns the head.
@export var head_bone: StringName = &"head"
## Points on the model's silhouette and the board's outline where the flames start, away from the
## floor.
@export var flame_points: PackedVector3Array = PackedVector3Array()
## Where the glowing skulls float.
@export var skull_points: PackedVector3Array = PackedVector3Array()
