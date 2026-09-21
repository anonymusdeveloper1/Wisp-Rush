import React from "react";
import { Img, interpolate, random, staticFile, useCurrentFrame, Easing } from "remotion";
import { C, alpha } from "../style/palette";

/**
 * A rigged character coming apart: every part PNG flies from the centre to its own place on a
 * ring, then holds as a wall of pieces. The count is the point, so the layout is a spiral that
 * stays readable at any N (56 for Ilyra).
 */
export const PartsScatter: React.FC<{
  /** Paths relative to the public dir. */
  files: string[];
  /** Frame the explosion starts. */
  at?: number;
  /** Frames the flight takes. */
  travel?: number;
  size?: number;
  radius?: number;
  y?: number;
}> = ({ files, at = 0, travel = 26, size = 108, radius = 420, y = 0.47 }) => {
  const frame = useCurrentFrame();
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      {files.map((file, i) => {
        const local = frame - at - i * 0.55;
        const p = interpolate(local, [0, travel], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: Easing.out(Easing.cubic),
        });
        // A phyllotaxis spiral: even coverage, no clumping, deterministic for a given index.
        const golden = i * 2.399963;
        const r = radius * Math.sqrt((i + 0.6) / files.length);
        const jitter = random(`p${i}`) * 0.5 + 0.75;
        // After landing every piece keeps breathing on its own phase, so the cloud is never a
        // still frame — the recipe allows no dead screen longer than about three seconds.
        const phase = random(`ph${i}`) * Math.PI * 2;
        const bobX = Math.sin(local * 0.021 + phase) * 11 * p;
        const bobY = Math.cos(local * 0.017 + phase * 1.3) * 13 * p;
        const bobSpin = Math.sin(local * 0.014 + phase) * 4 * p;
        const spin = (random(`s${i}`) - 0.5) * 90;
        return (
          <Img
            key={file}
            src={staticFile(file)}
            style={{
              position: "absolute",
              left: `calc(50% + ${Math.cos(golden) * r * jitter * p + bobX}px)`,
              top: `calc(${y * 100}% + ${Math.sin(golden) * r * jitter * 0.92 * p + bobY}px)`,
              width: size,
              height: size,
              objectFit: "contain",
              transform: `translate(-50%, -50%) rotate(${spin * p + bobSpin}deg) scale(${0.35 + 0.65 * p})`,
              opacity: interpolate(local, [0, 5], [0, 1], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
              filter: `drop-shadow(0 0 12px ${alpha(C.cyan, 0.25)})`,
            }}
          />
        );
      })}
    </div>
  );
};
