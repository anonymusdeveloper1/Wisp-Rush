/** Canvas and safe-zone constants (recipe §6.5). Positions elsewhere are 0–1 of these. */
export const W = 1080;
export const H = 1920;
export const FPS = 60;

/**
 * TikTok furniture sits over these. Keep text out of them.
 * Top tabs, the right-hand action rail, and the description at the bottom.
 */
export const SAFE = {
  top: 0.09,
  bottom: 0.87,
  railX: 0.86,
  railTop: 0.45,
  railBottom: 0.87,
} as const;

/** Captions sit here; headlines live between 0.2 and 0.7. */
export const CAPTION_Y = 0.73;

/** Seconds → frames at the project rate. */
export const s = (seconds: number): number => Math.round(seconds * FPS);
