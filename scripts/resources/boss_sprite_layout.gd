class_name BossSpriteLayout
extends Resource
## Where a whole-frame boss's feet and wall grip sit in its packed frames, measured by its packer.
##
## Every value is in packed-frame pixels. A "floor" animation is drawn standing on a floor below the
## figure (its feet on one line); a "wall" animation is drawn holding on to a wall on the figure's
## right (its grip on one line). The packer aligns every frame of an animation to that line, so the
## boss only has to put the line on the arena wall. Generated: never edit by hand, re-run the packer.

## Side of one packed frame.
@export var cell_size: float = 256.0
## Height of the figure standing, feet to the top of the head: the boss's size reference.
@export var standing_height: float = 180.0
## Frame centre to the feet line of a floor animation.
@export var floor_contact_depth: float = 116.0
## Feet line to the boss's body centre on a floor.
@export var floor_body_depth: float = 90.0
## Frame centre to the grip line of a wall animation.
@export var wall_contact_depth: float = 122.0
## Grip line to the boss's body centre on a wall.
@export var wall_body_depth: float = 84.0
