import { interpolate, Easing } from "remotion";

/**
 * The house pop: 0.55 → 1.10 → 0.97 → 1.00 over 12 frames, opacity in over 5 (recipe §6.4).
 * Every card, pill, step and headline enters with this. `local` is frames since the element began.
 */
export const popScale = (local: number): number =>
  interpolate(local, [0, 5, 9, 12], [0.55, 1.1, 0.97, 1.0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

export const popOpacity = (local: number): number =>
  interpolate(local, [0, 5], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

/** Shrink out: 1.0 → 0.75 with opacity to 0 over the last 6 frames (recipe §6.4). */
export const shrinkOut = (local: number, duration: number) => {
  const start = duration - 6;
  return {
    scale: interpolate(local, [start, duration], [1, 0.75], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }),
    opacity: interpolate(local, [start, duration], [1, 0], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }),
  };
};

/** Combined enter+exit transform for an element that lives `duration` frames. */
export const popLife = (local: number, duration: number) => {
  const out = shrinkOut(local, duration);
  return {
    scale: popScale(local) * out.scale,
    opacity: Math.min(popOpacity(local), out.opacity),
  };
};

/**
 * A draw-on wipe, used for underlines, strike-throughs and marker arrows: the element is revealed
 * from one side over `frames` (recipe §6.3 uses 8–12).
 */
export const drawOn = (
  local: number,
  frames = 10,
  from: "left" | "right" | "top" | "bottom" = "left",
): string => {
  const p = interpolate(local, [0, frames], [100, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  const side = { left: "right", right: "left", top: "bottom", bottom: "top" }[from];
  return `inset(${side === "bottom" ? `0 0 ${p}% 0` : side === "top" ? `${p}% 0 0 0` : side === "right" ? `0 ${p}% 0 0` : `0 0 0 ${p}%`})`;
};

/** A hard slam: overshoots big and settles, for a number landing on its spoken word. */
export const slam = (local: number): number =>
  interpolate(local, [0, 4, 8, 13], [1.9, 0.92, 1.04, 1.0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.quad),
  });
