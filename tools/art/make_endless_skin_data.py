#!/usr/bin/env python3
"""Generate the Endless arena skin data from the art manifest (spec story_and_endless/05, ADR-0014).

Usage (repo root):
  python3 tools/art/make_endless_skin_data.py   then   tools/validate.sh

Writes data/endless/skins/<skin_id>.tres for every skin in
concept_art/wisp_rush_endless_v1/assets/skins_manifest.json and rewrites
data/endless/default_endless_catalog.tres (all skins in manifest order, default astral_observatory,
the frozen floor template polygon). Never hand-edit the outputs: change the tables below and re-run.

- PRICE_BY_TIER / PRICE_OVERRIDE: owner decision 2026-09-15 (GDD §14 #26).
- ACCENT: Palette colours only (scripts/utils/palette.gd hex values mirrored in PALETTE).
- Scenery (Legendary and Mythic only): ArenaSceneryData sub-resources built from the SCENERY table
  in tools/art/endless_scenery.py (zones, set piece, sweep, shooting stars, particle emitters with
  emission points sampled clear of the floor + rim tolerance). Run endless_scenery.py first so the
  masks exist.
No uid:// values are written; Godot adds them on its next save.
"""

import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import endless_scenery  # noqa: E402  (tools/art sibling: scenery table and emission points)

MANIFEST = "concept_art/wisp_rush_endless_v1/assets/skins_manifest.json"
TEMPLATE_JSON = "concept_art/wisp_rush_endless_v1/floor_template.json"
SKIN_DIR = "data/endless/skins"
CATALOG = "data/endless/default_endless_catalog.tres"
DEFAULT_SKIN = "astral_observatory"

TIERS = ["Simple", "Rare", "Legendary", "Mythic"]
PRICE_BY_TIER = {"Simple": 300, "Rare": 800, "Legendary": 2000, "Mythic": 3500}
PRICE_OVERRIDE = {"astral_observatory": 0, "drowned_sanctum": 800, "moonpetal_shrine": 1200}

PALETTE = {
    "SLATE_TEAL": "263D42",
    "SOUL_CYAN": "62E8F2",
    "SOUL_WHITE": "EAFDFF",
    "WARNING_AMBER": "F3A847",
    "MOSS_GREEN": "5E7D4C",
    "TEXT_MUTED": "8FB3BA",
    "STEEL_BORDER": "4C6670",
}

ACCENT = {
    "astral_observatory": "SOUL_CYAN", "drowned_sanctum": "MOSS_GREEN",
    "moonpetal_shrine": "SOUL_WHITE", "monastery_yard": "MOSS_GREEN",
    "dusk_sandstone": "WARNING_AMBER", "slate_cliffs": "TEXT_MUTED", "cold_forge": "WARNING_AMBER",
    "bamboo_deck": "MOSS_GREEN", "basalt_shore": "STEEL_BORDER", "windswept_hill": "TEXT_MUTED",
    "rain_rooftops": "SOUL_CYAN", "rootwood_clearing": "MOSS_GREEN",
    "clockwork_bastion": "WARNING_AMBER", "sky_harbor": "SOUL_CYAN", "quartz_grotto": "SOUL_WHITE",
    "fungal_hollow": "SOUL_WHITE", "library_of_echoes": "SOUL_CYAN",
    "old_colosseum": "WARNING_AMBER", "storm_lighthouse": "SOUL_CYAN",
    "lantern_market": "WARNING_AMBER", "titans_palm": "TEXT_MUTED", "clocktower_crown": "SOUL_WHITE",
    "storm_anvil": "SOUL_CYAN", "world_tree_crown": "MOSS_GREEN", "galleon_wreck": "WARNING_AMBER",
    "eclipse_sanctum": "SOUL_WHITE", "starforged_citadel": "SOUL_CYAN", "abyssal_gate": "SOUL_CYAN",
    "aurora_throne": "MOSS_GREEN", "dragon_skull_throne": "WARNING_AMBER",
}

def color(name, alpha=1.0):
    hex_value = PALETTE.get(name) or endless_scenery.COLORS[name]
    r, g, b = (int(hex_value[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return "Color(%.4g, %.4g, %.4g, %.4g)" % (r, g, b, alpha)


def tres_string(text):
    return '"%s"' % text.replace("\\", "\\\\").replace('"', '\\"')


def fmt(value):
    return "%.4g" % value


def vec2(pair):
    return "Vector2(%s, %s)" % (fmt(pair[0]), fmt(pair[1]))


def scenery_blocks(skin_id, table, points):
    """Sub-resource blocks (zones, emitters, scenery) and the ext_resource lines they need."""
    ext = [
        '[ext_resource type="Script" path="res://scripts/resources/arena_scenery_data.gd" id="3_scenery"]',
        '[ext_resource type="Script" path="res://scripts/resources/arena_scenery_zone.gd" id="4_zone"]',
        '[ext_resource type="Script" path="res://scripts/resources/arena_particle_emitter.gd"'
        ' id="5_emitter"]',
        '[ext_resource type="Texture2D" path="res://assets/art/environment/endless/masks/%s.png"'
        ' id="6_mask"]' % skin_id,
    ]
    blocks = []
    for number, spec in enumerate(table["zones"], 1):
        z = spec["params"]
        blocks.append("\n".join([
            '[sub_resource type="Resource" id="Zone_%d"]' % number,
            'script = ExtResource("4_zone")',
            "zone_name = %s" % tres_string(spec["name"]),
            "light_color = %s" % color(z["color"]),
            "light_alt_color = %s" % color(z["alt"] or z["color"]),
            "light_strength = %s" % fmt(z["strength"]),
            "breathe = %s" % fmt(z["breathe"]),
            "breathe_hz = %s" % fmt(z["breathe_hz"]),
            "flicker = %s" % fmt(z["flicker"]),
            "flicker_hz = %s" % fmt(z["flicker_hz"]),
            "flare_interval = %s" % fmt(z["flare_interval"]),
            "flare_boost = %s" % fmt(z["flare_boost"]),
            "flare_rise = %s" % fmt(z["flare_rise"]),
            "flare_fade = %s" % fmt(z["flare_fade"]),
            "flare_is_flash = %s" % ("true" if z["flash"] else "false"),
            "hue_cycle = %s" % fmt(z["hue_cycle"]),
            "hue_cycle_hz = %s" % fmt(z["hue_cycle_hz"]),
            "color_shift = %s" % fmt(z["shift"]),
            "color_shift_cycles = %s" % fmt(z["shift_cycles"]),
            "color_shift_hz = %s" % fmt(z["shift_hz"]),
            "twinkle = %s" % fmt(z["twinkle"]),
            "twinkle_hz = %s" % fmt(z["twinkle_hz"]),
            "travel = %s" % fmt(z["travel"]),
            "travel_cycles = %s" % fmt(z["travel_cycles"]),
            "travel_hz = %s" % fmt(z["travel_hz"]),
            "sweep_weight = %s" % fmt(z["sweep"]),
            "warp_mode = %d" % endless_scenery.WARP_MODES.index(z["warp_mode"]),
            "warp_px = %s" % fmt(z["warp_px"]),
            "warp_hz = %s" % fmt(z["warp_hz"]),
            "warp_cycles = %s" % fmt(z["warp_cycles"]),
        ]))
    emitters = table.get("emitters", [])
    for number, (spec, emitter_points) in enumerate(zip(emitters, points), 1):
        e = spec["values"]
        flat = ", ".join("%.4f, %.4f" % (u, v) for u, v in emitter_points)
        dx, dy = e["direction"]
        length = math.hypot(dx, dy) or 1.0
        blocks.append("\n".join([
            '[sub_resource type="Resource" id="Emitter_%d"]' % number,
            'script = ExtResource("5_emitter")',
            "emitter_name = %s" % tres_string(spec["name"]),
            "points_uv = PackedVector2Array(%s)" % flat,
            "amount = %d" % spec["amount"],
            "lifetime = %s" % fmt(e["lifetime"]),
            "direction = %s" % vec2((dx / length, dy / length)),
            "spread_degrees = %s" % fmt(e["spread"]),
            "speed_px = %s" % vec2(e["speed"]),
            "gravity_px = %s" % vec2(e["gravity"]),
            "size_px = %s" % vec2(e["size"]),
            "color = %s" % color(e["color"]),
            "end_color = %s" % color(e["end"]),
            "alpha = %s" % fmt(e["alpha"]),
            "pulses = %d" % e["pulses"],
            "additive = %s" % ("true" if e["additive"] else "false"),
            "sprite = %d" % endless_scenery.SPRITES.index(e["sprite"]),
            "spin_degrees = %s" % fmt(e["spin"]),
            "random_seed = %d" % (endless_scenery.skin_index(skin_id) * 100 + number),
        ]))
    grade = table["grade"]
    lines = [
        '[sub_resource type="Resource" id="Scenery"]',
        'script = ExtResource("3_scenery")',
        'mask = ExtResource("6_mask")',
        "scenery_saturation = %s" % fmt(grade["saturation"]),
        "scenery_contrast = %s" % fmt(grade["contrast"]),
        "scenery_exposure = %s" % fmt(grade["exposure"]),
        "shadow_lift = %s" % color(grade["shadow"][0]),
        "shadow_lift_amount = %s" % fmt(grade["shadow"][1]),
        "highlight_lift = %s" % color(grade["highlight"][0]),
        "highlight_lift_amount = %s" % fmt(grade["highlight"][1]),
        "floor_saturation = %s" % fmt(grade["floor_saturation"]),
        'zones = Array[ExtResource("4_zone")]([%s])' % ", ".join(
            'SubResource("Zone_%d")' % n for n in range(1, len(table["zones"]) + 1)),
    ]
    piece = table.get("piece")
    if piece:
        lines += [
            "piece_kind = %d" % endless_scenery.PIECE_KINDS.index(piece["kind"]),
            "piece_center_uv = %s" % vec2(piece["centre"]),
            "piece_radius_px = %s" % fmt(piece["radius_px"]),
            "piece_extent_px = %s" % fmt(piece.get("extent_px", 0.0)),
            "piece_color = %s" % color(piece["color"]),
            "piece_strength = %s" % fmt(piece["strength"]),
            "piece_rays = %d" % piece.get("rays", 0),
            "piece_ray_sharpness = %s" % fmt(piece.get("sharpness", 6.0)),
            "piece_speed = %s" % fmt(piece["speed"]),
            "piece_swirl_radians = %s" % fmt(piece.get("swirl_radians", 0.0)),
            "flare_interval = %s" % fmt(piece.get("flare_interval", 0.0)),
            "flare_length_px = %s" % fmt(piece.get("flare_length_px", 0.0)),
            "flare_width_degrees = %s" % fmt(piece.get("flare_width_deg", 10.0)),
            "flare_color = %s" % color(piece.get("flare_color", piece["color"])),
            "flare_boost = %s" % fmt(piece.get("flare_boost", 0.0)),
        ]
    sweep = table.get("sweep")
    if sweep:
        lines += [
            "sweep_color = %s" % color(sweep["color"]),
            "sweep_strength = %s" % fmt(sweep["strength"]),
            "sweep_angle_degrees = %s" % fmt(sweep["angle"]),
            "sweep_width_px = %s" % fmt(sweep["width_px"]),
            "sweep_period = %s" % fmt(sweep["period"]),
            "sweep_duty = %s" % fmt(sweep["duty"]),
        ]
    streaks = table.get("streaks")
    if streaks:
        u, v, w, h = streaks["region"]
        lines += [
            "streak_region_uv = Rect2(%s, %s, %s, %s)" % (fmt(u), fmt(v), fmt(w), fmt(h)),
            "streak_interval = %s" % fmt(streaks["interval"]),
            "streak_speed_px = %s" % fmt(streaks["speed_px"]),
            "streak_length_px = %s" % fmt(streaks["length_px"]),
            "streak_width_px = %s" % fmt(streaks["width_px"]),
            "streak_duration = %s" % fmt(streaks["duration"]),
            "streak_angle_degrees = %s" % vec2(streaks["angle"]),
            "streak_color = %s" % color(streaks["color"]),
            "streak_strength = %s" % fmt(streaks["strength"]),
        ]
    lines.append('emitters = Array[ExtResource("5_emitter")]([%s])' % ", ".join(
        'SubResource("Emitter_%d")' % n for n in range(1, len(emitters) + 1)))
    blocks.append("\n".join(lines))
    return ext, blocks


def write_skin(entry, distance, template):
    skin_id = entry["skin_id"]
    tier = entry["tier"]
    table = endless_scenery.SCENERY.get(skin_id)
    if table and tier not in ("Legendary", "Mythic"):
        raise SystemExit("%s: scenery is for Legendary and Mythic skins only" % skin_id)
    if not table and tier in ("Legendary", "Mythic"):
        raise SystemExit("%s: every Legendary and Mythic skin needs scenery" % skin_id)
    ext = [
        '[ext_resource type="Script" path="res://scripts/resources/arena_skin_data.gd" id="1_script"]',
        '[ext_resource type="Texture2D" path="res://assets/art/environment/endless/thumbnails/%s.png"'
        ' id="2_thumbnail"]' % skin_id,
    ]
    subs = []
    if table:
        if not os.path.exists(os.path.join(endless_scenery.MASK_DIR, skin_id + ".png")):
            raise SystemExit("%s: run tools/art/endless_scenery.py first (no mask)" % skin_id)
        points = endless_scenery.all_emission_points(skin_id, distance, template)
        scenery_ext, subs = scenery_blocks(skin_id, table, points)
        ext += scenery_ext
    lines = [
        '[gd_resource type="Resource" script_class="ArenaSkinData" load_steps=%d format=3]'
        % (len(ext) + len(subs) + 1),
        "",
        "\n".join(ext),
        "",
    ]
    for sub in subs:
        lines += [sub, ""]
    body = [
        "[resource]",
        'script = ExtResource("1_script")',
        'skin_id = &"%s"' % skin_id,
        "display_name = %s" % tres_string(entry["display_name"].upper()),
        "description = %s" % tres_string(entry["description"]),
        "tier = %d" % TIERS.index(tier),
        'background_path = "res://assets/art/environment/endless/%s.png"' % skin_id,
        'thumbnail = ExtResource("2_thumbnail")',
        "price = %d" % PRICE_OVERRIDE.get(skin_id, PRICE_BY_TIER[tier]),
        "accent = %s" % color(ACCENT[skin_id]),
    ]
    if table:
        body.append('scenery = SubResource("Scenery")')
    lines += body
    with open(os.path.join(SKIN_DIR, skin_id + ".tres"), "w") as handle:
        handle.write("\n".join(lines) + "\n")


def write_catalog(manifest, template):
    polygon = ", ".join("%.5g, %.5g" % (u, v) for u, v in template["polygon_uv"])
    ext = [
        '[ext_resource type="Script" path="res://scripts/resources/endless_catalog.gd" id="1_script"]',
        '[ext_resource type="Script" path="res://scripts/resources/arena_skin_data.gd" id="2_skin_script"]',
        '[ext_resource type="Resource" path="res://data/endless/default_endless_tuning.tres"'
        ' id="3_tuning"]',
    ]
    refs = []
    for number, entry in enumerate(manifest, 1):
        ext_id = "%d_%s" % (number + 3, entry["skin_id"])
        ext.append('[ext_resource type="Resource" path="res://data/endless/skins/%s.tres" id="%s"]'
                   % (entry["skin_id"], ext_id))
        refs.append('ExtResource("%s")' % ext_id)
    lines = [
        '[gd_resource type="Resource" script_class="EndlessCatalog" load_steps=%d format=3]'
        % (len(ext) + 1),
        "",
        "\n".join(ext),
        "",
        "[resource]",
        'script = ExtResource("1_script")',
        "floor_polygon = PackedVector2Array(%s)" % polygon,
        'skins = Array[ExtResource("2_skin_script")]([%s])' % ", ".join(refs),
        'default_skin_id = &"%s"' % DEFAULT_SKIN,
        'tuning = ExtResource("3_tuning")',
    ]
    with open(CATALOG, "w") as handle:
        handle.write("\n".join(lines) + "\n")


def main():
    with open(MANIFEST) as handle:
        manifest = json.load(handle)
    with open(TEMPLATE_JSON) as handle:
        template = json.load(handle)
    if manifest[0]["skin_id"] != DEFAULT_SKIN:
        raise SystemExit("the default skin must come first in the manifest")
    unknown = set(endless_scenery.SCENERY) - {entry["skin_id"] for entry in manifest}
    if unknown:
        raise SystemExit("scenery for unknown skins: %s" % sorted(unknown))
    os.makedirs(SKIN_DIR, exist_ok=True)
    distance = endless_scenery.floor_distance(template)
    for entry in manifest:
        write_skin(entry, distance, template)
    write_catalog(manifest, template)
    print("make_endless_skin_data: wrote %d skins and %s" % (len(manifest), CATALOG))
    return 0


if __name__ == "__main__":
    sys.exit(main())
