class_name SoulWardVisual
extends Node2D
## Crisp pixel-grid shell around a protected player, drawn below the character.

const CELL_SIZE: float = 4.0
const SHELL_SAMPLES: int = 256
## Protection shell radius in the same world coordinates as the Wisp.
var radius: float = 100.0:
	set(value):
		radius = value
		queue_redraw()


func _draw() -> void:
	for index: int in SHELL_SAMPLES:
		var angle: float = TAU * float(index) / float(SHELL_SAMPLES)
		var cell: Vector2 = (Vector2(cos(angle), sin(angle)) * radius / CELL_SIZE).round()
		draw_rect(Rect2(cell * CELL_SIZE, Vector2.ONE * CELL_SIZE), Palette.SOUL_CYAN)
	for index: int in [1, 3, 5, 7]:
		var angle: float = TAU * float(index) / 8.0
		var cell: Vector2 = (Vector2(cos(angle), sin(angle)) * radius / CELL_SIZE).round()
		draw_rect(Rect2(cell * CELL_SIZE, Vector2.ONE * CELL_SIZE), Palette.SOUL_WHITE)
