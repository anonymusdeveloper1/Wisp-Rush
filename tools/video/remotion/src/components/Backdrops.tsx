import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";

/** The void matte — black beat cards, dims and scrims all come from this one colour. */
export const Matte: React.FC<{ opacity?: number; color?: string }> = ({
  opacity = 1,
  color = C.matte,
}) => <AbsoluteFill style={{ backgroundColor: color, opacity }} />;

/**
 * A dim that fades in and out over footage so text or step cards read (recipe §6.3).
 * `keys` are [frame, opacity] pairs, clip-relative.
 */
export const Dim: React.FC<{ keys: [number, number][] }> = ({ keys }) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(
    frame,
    keys.map((k) => k[0]),
    keys.map((k) => k[1]),
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  return <Matte opacity={opacity} />;
};

/**
 * The explainer grid: every motion-graphics explanation in the series sits on this, so the viewer
 * knows instantly that they have left the game and entered the diagram (recipe §6.3).
 */
export const GridBackdrop: React.FC<{ cell?: number; drift?: boolean }> = ({
  cell = 90,
  drift = true,
}) => {
  const frame = useCurrentFrame();
  const shift = drift ? (frame * 0.18) % cell : 0;
  return (
    <AbsoluteFill style={{ backgroundColor: C.matte, overflow: "hidden" }}>
      <AbsoluteFill
        style={{
          backgroundImage: `linear-gradient(${alpha(C.cyan, 0.085)} 2px, transparent 2px), linear-gradient(90deg, ${alpha(C.cyan, 0.085)} 2px, transparent 2px)`,
          backgroundSize: `${cell}px ${cell}px`,
          backgroundPosition: `${shift}px ${shift}px`,
        }}
      />
      {/* A soft centre lift so headlines sit on something, not on flat black. */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 45%, ${alpha(C.cyan, 0.1)} 0%, transparent 62%)`,
        }}
      />
    </AbsoluteFill>
  );
};

/** A vignette that pushes the eye to the centre; used over busy footage under a headline. */
export const Vignette: React.FC<{ strength?: number }> = ({ strength = 0.62 }) => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(ellipse at 50% 50%, transparent 38%, rgba(0,0,0,${strength}) 100%)`,
    }}
  />
);
