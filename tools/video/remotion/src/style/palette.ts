/**
 * The devlog palette. Values come from tools/video/devlog_graphics.py, which in turn follows
 * GDD §9 — so graphics drawn here match the ones drawn for earlier episodes and the game's own UI.
 */
export const C = {
  /** Panel/ink near-black, the game's own frame colour. */
  void: "#111521",
  /** A step darker, for stacked panels. */
  deep: "#0A0D15",
  /** The canvas matte used for black beat cards and dims (recipe §6.3). */
  matte: "#07090F",
  slate: "#263D42",
  /** The signature accent. Everything "after", "fixed" or "new" is cyan. */
  cyan: "#62E8F2",
  /** Headline white with a faint cyan cast. */
  soul: "#EAFDFF",
  amber: "#F3A847",
  magenta: "#B14CD9",
  /** Reserved for the "before" / broken / bad number. Never decorative. */
  red: "#FF3B5C",
  ice: "#BEEEFF",
  grey: "#7A8494",
  /** Row labels on the numbers board. */
  label: "#9FB3C8",
  /** Context lines under a board ("measured on a Mac"). */
  context: "#8FA3B8",
  /** Outline under light text. */
  outline: "#0B0E16",
  /** Outline under red text. */
  outlineRed: "#2A0610",
  /** Pill backgrounds. */
  pill: "#1B2A30",
  pillDark: "#0B0E16",
} as const;

/** rgba() from a hex and an alpha, for glows and scrims. */
export const alpha = (hex: string, a: number): string => {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${a})`;
};
