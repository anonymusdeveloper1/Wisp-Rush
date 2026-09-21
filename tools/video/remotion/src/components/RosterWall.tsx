import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";
import { popScale, popOpacity } from "../style/motion";

export type RosterEntry = { file: string; name: string; retired?: boolean };

/**
 * The wall of every character the game has ever had, laid out 5/4/4. Portraits pop in on a
 * stagger; `strikeAt` draws a red strike across every retired one and drains its colour.
 * This is the episode's signature shot — the roster is the story, so it gets the whole screen.
 */
export const RosterWall: React.FC<{
  roster: RosterEntry[];
  /** Frame the portraits start popping in. */
  appearAt?: number;
  /** Frame the retired ones get struck out; omit to leave the wall intact. */
  strikeAt?: number;
  /** Frame the retired ones fade away entirely; omit to keep them struck but present. */
  removeAt?: number;
  tile?: number;
  gap?: number;
  y?: number;
  /** Stagger between portraits, in frames. */
  stagger?: number;
}> = ({
  roster,
  appearAt = 0,
  strikeAt,
  removeAt,
  tile = 190,
  gap = 18,
  y = 0.5,
  stagger = 2,
}) => {
  const frame = useCurrentFrame();
  const rows = [roster.slice(0, 5), roster.slice(5, 9), roster.slice(9, 13)];
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: `${y * 100}%`,
        transform: "translateY(-50%)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap,
      }}
    >
      {rows.map((row, r) => (
        <div key={r} style={{ display: "flex", gap }}>
          {row.map((entry, i) => {
            const index = rows.slice(0, r).reduce((n, x) => n + x.length, 0) + i;
            const local = frame - appearAt - index * stagger;
            if (local < 0) return <div key={entry.file} style={{ width: tile, height: tile }} />;

            const struck =
              entry.retired && strikeAt !== undefined ? frame - strikeAt - (index % 3) * 2 : -1;
            const isStruck = struck >= 0;
            const gone =
              entry.retired && removeAt !== undefined
                ? interpolate(frame - removeAt - (index % 3) * 3, [0, 16], [1, 0], {
                    extrapolateLeft: "clamp",
                    extrapolateRight: "clamp",
                  })
                : 1;

            return (
              <div
                key={entry.file}
                style={{
                  width: tile,
                  height: tile,
                  position: "relative",
                  transform: `scale(${popScale(local) * (0.85 + 0.15 * gone)})`,
                  opacity: popOpacity(local) * gone,
                  borderRadius: 16,
                  overflow: "hidden",
                  background: `linear-gradient(160deg, ${alpha(C.slate, 0.55)}, ${alpha(C.deep, 0.95)})`,
                  border: `2px solid ${isStruck ? alpha(C.red, 0.85) : alpha(C.cyan, 0.32)}`,
                  boxShadow: isStruck
                    ? `0 0 26px ${alpha(C.red, 0.35)}`
                    : `0 0 22px ${alpha(C.cyan, 0.16)}`,
                }}
              >
                <Img
                  src={staticFile(`graphics/roster/${entry.file}`)}
                  style={{
                    width: "100%",
                    height: "100%",
                    objectFit: "contain",
                    padding: 8,
                    filter: isStruck
                      ? `grayscale(${0.9 * Math.min(1, struck / 8)}) brightness(${1 - 0.36 * Math.min(1, struck / 8)})`
                      : undefined,
                  }}
                />
                {isStruck ? <Strike local={struck} size={tile} /> : null}
              </div>
            );
          })}
        </div>
      ))}
    </div>
  );
};

/** The red diagonal that draws itself across a retired portrait in 8 frames. */
const Strike: React.FC<{ local: number; size: number }> = ({ local, size }) => {
  const p = interpolate(local, [0, 8], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const len = size * 1.42;
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div
        style={{
          width: len * p,
          height: 9,
          background: C.red,
          borderRadius: 6,
          transform: "rotate(-45deg)",
          transformOrigin: "center",
          boxShadow: `0 0 20px ${alpha(C.red, 0.9)}`,
        }}
      />
    </div>
  );
};
