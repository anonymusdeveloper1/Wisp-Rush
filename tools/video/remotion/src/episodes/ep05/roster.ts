/**
 * Every character the game has had, in the order the wall shows them (rows of 5 / 4 / 4).
 * `retired` marks the six removed on 2026-09-20: four Wisp forms, Bram, and the bone-rigged Ilyra.
 * Portraits were recovered from git HEAD for the retired ones — see video/graphics/roster/.
 */
import type { RosterEntry } from "../../components/RosterWall";

export const ROSTER: RosterEntry[] = [
  { file: "r01_void.png", name: "VOID" },
  { file: "r02_ash.png", name: "ASH", retired: true },
  { file: "r03_venom.png", name: "VENOM", retired: true },
  { file: "r04_bloodmoon.png", name: "BLOODMOON", retired: true },
  { file: "r05_frost.png", name: "FROST", retired: true },
  { file: "r06_eclipse.png", name: "ECLIPSE" },
  { file: "r07_veyra.png", name: "VEYRA" },
  { file: "r08_rook.png", name: "ROOK" },
  { file: "r09_morrow.png", name: "MORROW" },
  { file: "r10_bram.png", name: "BRAM", retired: true },
  { file: "r11_ilyra_rig.png", name: "ILYRA", retired: true },
  { file: "r12_ilyra2.png", name: "ILYRA 2" },
  { file: "r13_noxen.png", name: "NOXEN" },
];

/** The 12 real frames of Verdant Shade's idle_hover loop, sliced from the packed run sheet. */
export const IDLE_FRAMES = Array.from(
  { length: 12 },
  (_, i) => `graphics/ep05/frames/idle_${String(i).padStart(2, "0")}.png`,
);

/** Every gameplay frame of one character, for the scrolling strip. */
export const STRIP_FRAMES = Array.from(
  { length: 34 },
  (_, i) => `graphics/ep05/strip/f${String(i).padStart(3, "0")}.png`,
);

/**
 * Ilyra's bone rig, part by part. 55 authored parts (the folder also holds preview.png,
 * the assembled portrait, which is not a part) — matching the DEVLOG's "55-part pack".
 */
export const RIG_PARTS = [
  "arm_ll",
  "arm_lr",
  "arm_ul",
  "arm_ur",
  "boot_l",
  "boot_r",
  "braid_l",
  "braid_r",
  "crown_shard_l",
  "crown_shard_r",
  "crown_star",
  "fan_handle",
  "fan_membrane",
  "fan_membrane_lit",
  "fan_rib_a",
  "fan_rib_b",
  "fan_rib_c",
  "fan_rib_d",
  "fan_rib_e",
  "hair_back",
  "hand_cup_l",
  "hand_cup_r",
  "hand_grip_l",
  "hand_grip_r",
  "hand_open_l",
  "hand_open_r",
  "head_blink",
  "head_focused",
  "head_joy",
  "head_neutral",
  "head_pain",
  "heart_core",
  "heart_glow",
  "leg_l",
  "leg_r",
  "sash_1",
  "sash_2",
  "sash_3",
  "sash_4",
  "shoulder_ornament_l",
  "shoulder_ornament_r",
  "skirt_panel_1",
  "skirt_panel_2",
  "skirt_panel_3",
  "skirt_panel_4",
  "skirt_panel_5",
  "skirt_panel_6",
  "torso",
  "vfx_bloom",
  "vfx_fan_arc",
  "vfx_mote",
  "vfx_petal",
  "vfx_ring",
  "vfx_star",
  "vfx_streak",
].map((n) => `graphics/rig_parts/${n}.png`);
