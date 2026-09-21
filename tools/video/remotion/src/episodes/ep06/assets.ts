/**
 * EP06 assets. The puppet pack is the 26 parts Ilyra's jointed menu body was built from — kept in
 * the repo after the build was reverted, which is the only reason this episode can be shot at all.
 */
const PUPPET_NAMES = [
  "head", "torso", "waist_armor", "underskirt",
  "upper_arm_00", "upper_arm_01", "upper_arm_02", "upper_arm_03",
  "forearm_00", "forearm_01", "forearm_02", "forearm_03",
  "hand_grip_a", "hand_grip_b", "hand_relaxed_a", "hand_relaxed_b",
  "upper_leg_a", "upper_leg_b", "lower_leg_boot_a", "lower_leg_boot_b",
  "hip_flap_a", "hip_flap_b", "braid_a", "braid_b",
  "fan_open_a", "fan_open_b",
];

export const PUPPET_PARTS = PUPPET_NAMES.map((n) => `graphics/ep06/puppet/${n}.png`);

/** The four upper arms — two of which turned out to be the same pair, relaxed. */
export const ARM_INDICES = [4, 5, 6, 7];
/** The spare pair: a relaxed alternate for the same two arms, not a second pair. */
export const SPARE_ARM_INDICES = [6, 7];

export const HEAD = "graphics/ep06/puppet/head.png";
export const TORSO = "graphics/ep06/puppet/torso.png";
/** The painting the puppet was supposed to replace, and which it was reverted back to. */
export const PAINTING = "graphics/ep06/storefront_welcome.png";

/** The 12 registered frames that won — the thing the puppet lost to. */
export const WINNING_FRAMES = Array.from(
  { length: 12 },
  (_, i) => `graphics/ep06/frames/idle_${String(i).padStart(2, "0")}.png`,
);
