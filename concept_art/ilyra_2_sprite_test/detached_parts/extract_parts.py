"""Extract Ilyra 2 puppet layers and storefront frames from generated sheets.

Run from the repository root:
    python concept_art/ilyra_2_sprite_test/detached_parts/extract_parts.py

The source sheets are intentionally kept beside this script. Outputs remain under
``concept_art`` and are not runtime assets until the game's normal art extraction
pipeline copies approved files into ``assets/art``.
"""

from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parent
ALPHA_THRESHOLD = 32
MIN_COMPONENT_AREA = 150
PADDING = 12


SECONDARY_NAMES = [
    "braid_a",
    "braid_b",
    "fan_closed",
    "fan_open_a",
    "fan_open_b",
    "crown_center",
    "crown_side_a",
    "crown_side_b",
    "waist_streamer_a",
    "waist_streamer_b",
    "skirt_panel_00",
    "skirt_panel_01",
    "skirt_panel_02",
    "skirt_panel_03",
    "skirt_panel_04",
    "skirt_panel_05",
    "skirt_panel_06",
    "chest_gem_glow",
    "dash_slash",
    "sparkle_pair",
    "sparkle_00",
    "sparkle_01",
]

UPPER_BODY_NAMES = [
    "torso",
    "head",
    "upper_arm_00",
    "upper_arm_01",
    "upper_arm_02",
    "upper_arm_03",
    "forearm_00",
    "forearm_01",
    "forearm_02",
    "forearm_03",
    "hand_open_a",
    "hand_grip_a",
    "hand_relaxed_b",
    "hand_open_b",
    "hand_relaxed_a",
    "hand_grip_b",
]

LOWER_BODY_NAMES = [
    "waist_armor",
    "hip_flap_a",
    "hip_flap_b",
    "upper_leg_a",
    "upper_leg_b",
    "lower_leg_boot_a",
    "lower_leg_boot_b",
    "underskirt",
]


def _components(
    source: Path,
) -> tuple[Image.Image, np.ndarray, list[tuple[int, tuple[int, int, int, int]]]]:
    image = Image.open(source).convert("RGBA")
    pixels = np.asarray(image)
    mask = (pixels[:, :, 3] > ALPHA_THRESHOLD).astype(np.uint8)
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, 8)

    components: list[tuple[int, tuple[int, int, int, int]]] = []
    for component in range(1, count):
        x, y, width, height, area = (int(value) for value in stats[component])
        if area >= MIN_COMPONENT_AREA:
            components.append((component, (x, y, x + width, y + height)))
    components.sort(key=lambda item: (item[1][1], item[1][0]))
    return image, labels, components


def _extract_components(source_name: str, output_name: str, names: list[str]) -> None:
    image, labels, components = _components(ROOT / source_name)
    if len(components) != len(names):
        raise RuntimeError(
            f"{source_name}: expected {len(names)} components, found {len(components)}"
        )

    source_pixels = np.asarray(image)
    output_dir = ROOT / "sprites" / output_name
    output_dir.mkdir(parents=True, exist_ok=True)
    for name, (component, (left, top, right, bottom)) in zip(
        names, components, strict=True
    ):
        component_mask = (labels == component).astype(np.uint8)
        # One-pixel fringe keeps antialiasing without admitting a nearby sprite.
        component_mask = cv2.dilate(component_mask, np.ones((3, 3), np.uint8))
        isolated_pixels = source_pixels.copy()
        isolated_pixels[:, :, 3] = np.where(
            component_mask > 0, source_pixels[:, :, 3], 0
        )
        isolated = Image.fromarray(isolated_pixels, "RGBA")
        crop_box = (
            max(0, left - PADDING),
            max(0, top - PADDING),
            min(image.width, right + PADDING),
            min(image.height, bottom + PADDING),
        )
        isolated.crop(crop_box).save(output_dir / f"{name}.png")


def _extract_storefront_frames() -> None:
    image = Image.open(ROOT / "02_storefront_loop_sheet.png").convert("RGBA")
    if image.width % 4 != 0:
        raise RuntimeError(
            f"Storefront sheet width {image.width} is not divisible into four equal frames"
        )

    pixels = np.asarray(image)
    alpha = pixels[:, :, 3]
    component_mask = (alpha > ALPHA_THRESHOLD).astype(np.uint8)
    component_count, labels, stats, centroids = cv2.connectedComponentsWithStats(
        component_mask, 8
    )

    output_dir = ROOT / "storefront_frames"
    output_dir.mkdir(parents=True, exist_ok=True)
    source_cell_width = image.width // 4
    output_width = 600
    frame_names = [
        "storefront_welcome",
        "storefront_blink",
        "storefront_flourish",
        "storefront_settle",
    ]
    for index, name in enumerate(frame_names):
        source_center_x = (index + 0.5) * source_cell_width
        selected_labels: list[int] = []
        for component in range(1, component_count):
            area = int(stats[component, cv2.CC_STAT_AREA])
            center_x = float(centroids[component, 0])
            if area >= MIN_COMPONENT_AREA and abs(center_x - source_center_x) < (
                source_cell_width / 2
            ):
                selected_labels.append(component)

        selected_mask = np.isin(labels, selected_labels).astype(np.uint8)
        # Recover the original antialiased fringe surrounding each selected component.
        selected_mask = cv2.dilate(selected_mask, np.ones((7, 7), np.uint8))
        isolated_pixels = pixels.copy()
        isolated_pixels[:, :, 3] = np.where(selected_mask > 0, alpha, 0)
        isolated = Image.fromarray(isolated_pixels, "RGBA")

        frame = Image.new("RGBA", (output_width, image.height), (0, 0, 0, 0))
        paste_x = int(round((output_width / 2) - source_center_x))
        frame.alpha_composite(isolated, (paste_x, 0))
        frame.save(output_dir / f"{name}.png")


def main() -> None:
    _extract_components(
        "01_secondary_motion_parts_raw.png", "secondary_motion", SECONDARY_NAMES
    )
    _extract_components(
        "03_upper_body_puppet_sheet.png", "upper_body", UPPER_BODY_NAMES
    )
    _extract_components(
        "04_lower_body_puppet_sheet.png", "lower_body", LOWER_BODY_NAMES
    )
    _extract_storefront_frames()
    print(
        "Extracted "
        f"{len(SECONDARY_NAMES) + len(UPPER_BODY_NAMES) + len(LOWER_BODY_NAMES)} "
        "puppet sprites and 4 storefront frames."
    )


if __name__ == "__main__":
    main()
