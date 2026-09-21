"""Remove neighboring-cell edge debris from generated Ilyra 2 pose-sheet crops.

The source pose sheets are intentionally retained. This script writes a separate `final_sprites`
directory and never mutates the generated images or the first-pass crops.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "sprites"
OUTPUT = ROOT / "final_sprites"
ALPHA_THRESHOLD = 8
EDGE_COMPONENT_MIN_PIXELS = 8_000

SPRITES = [
    "idle_hover",
    "idle_blink",
    "move_fly_00",
    "move_fly_01",
    "aim_charge",
    "dash_start_00",
    "dash_start_01",
    "dash_loop_00",
    "dash_loop_01_attack",
    "dash_end",
    "wall_left",
    "wall_right",
    "hit_reaction",
    "death",
    "revive_spawn",
    "victory",
    "character_selected",
    "character_unlocked",
]


def clean(source: Path, destination: Path) -> tuple[int, int]:
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    alpha = image.getchannel("A")
    opaque = bytearray(1 if value > ALPHA_THRESHOLD else 0 for value in alpha.get_flattened_data())
    visited = bytearray(width * height)
    removed_components = 0
    removed_pixels = 0

    for start in range(width * height):
        if not opaque[start] or visited[start]:
            continue
        queue = deque([start])
        visited[start] = 1
        component: list[int] = []
        touches_edge = False
        while queue:
            index = queue.popleft()
            component.append(index)
            x = index % width
            y = index // width
            touches_edge = touches_edge or x == 0 or y == 0 or x == width - 1 or y == height - 1
            for ny in range(max(0, y - 1), min(height, y + 2)):
                row = ny * width
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = row + nx
                    if opaque[neighbor] and not visited[neighbor]:
                        visited[neighbor] = 1
                        queue.append(neighbor)
        if touches_edge and len(component) < EDGE_COMPONENT_MIN_PIXELS:
            removed_components += 1
            removed_pixels += len(component)
            for index in component:
                opaque[index] = 0

    pixels = list(image.get_flattened_data())
    cleaned = [pixel if opaque[index] else (pixel[0], pixel[1], pixel[2], 0) for index, pixel in enumerate(pixels)]
    image.putdata(cleaned)
    image.save(destination)
    return removed_components, removed_pixels


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    jobs = [(name, name) for name in SPRITES]
    jobs.append(("wall_bottom_v2", "wall_bottom"))
    jobs.append(("wall_top_v2", "wall_top"))
    for source_name, output_name in jobs:
        removed_components, removed_pixels = clean(
            SOURCE / f"{source_name}.png", OUTPUT / f"{output_name}.png"
        )
        print(
            f"{output_name}: removed {removed_components} edge component(s), "
            f"{removed_pixels} pixel(s)"
        )


if __name__ == "__main__":
    main()
