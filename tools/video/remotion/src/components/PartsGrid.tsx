import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";
import { popOpacity, popScale } from "../style/motion";

/**
 * An inventory of parts: every PNG in its own cell, popping in on a stagger. A grid reads as
 * "this is the whole kit" where a scatter reads as "it came apart" — use this one for counting.
 */
export const PartsGrid: React.FC<{
  files: string[];
  columns?: number;
  cell?: number;
  gap?: number;
  y?: number;
  stagger?: number;
  /** Indices to dim and mark, for "these two are not what you think". */
  markedAt?: number;
  marked?: number[];
}> = ({ files, columns = 7, cell = 132, gap = 10, y = 0.5, stagger = 1.5, markedAt, marked = [] }) => {
  const frame = useCurrentFrame();
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: `${y * 100}%`,
        transform: "translateY(-50%)",
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        alignContent: "center",
        gap,
        maxWidth: columns * (cell + gap),
        margin: "0 auto",
      }}
    >
      {files.map((file, i) => {
        const local = frame - i * stagger;
        const isMarked = markedAt !== undefined && frame >= markedAt && marked.includes(i);
        const mark = isMarked
          ? interpolate(frame - markedAt!, [0, 12], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            })
          : 0;
        return (
          <div
            key={file}
            style={{
              width: cell,
              height: cell,
              borderRadius: 12,
              background: alpha(C.deep, 0.75),
              border: `2px solid ${alpha(isMarked ? C.amber : C.cyan, 0.22 + mark * 0.6)}`,
              boxShadow: mark > 0 ? `0 0 ${24 * mark}px ${alpha(C.amber, 0.5 * mark)}` : undefined,
              transform: `scale(${popScale(local) * (1 + mark * 0.06)})`,
              opacity: popOpacity(local),
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Img
              src={staticFile(file)}
              style={{ width: "86%", height: "86%", objectFit: "contain" }}
            />
          </div>
        );
      })}
    </div>
  );
};

/**
 * Two parts placed against each other, for the layout mistakes: a head dropped onto a waist
 * because the body was laid out before anything was measured, then snapped to where measuring
 * puts it. `progress` 0 is the mistake, 1 is the fix.
 */
export const HeadOnTorso: React.FC<{
  torso: string;
  head: string;
  /** 0 = the eyeballed layout, 1 = the measured one. */
  progress: number;
  y?: number;
}> = ({ torso, head, progress, y = 0.47 }) => {
  // Eyeballed: the head sits at the waist. Measured: it sits above the shoulders.
  const headTop = interpolate(progress, [0, 1], [436, 20]);
  const headScale = interpolate(progress, [0, 1], [0.6, 1]);
  return (
    <div
      style={{
        position: "absolute",
        left: "50%",
        top: `${y * 100}%`,
        transform: "translate(-50%, -50%)",
        width: 560,
        height: 780,
      }}
    >
      <Img
        src={staticFile(torso)}
        style={{ position: "absolute", left: 110, top: 210, width: 340, objectFit: "contain" }}
      />
      <Img
        src={staticFile(head)}
        style={{
          position: "absolute",
          left: interpolate(progress, [0, 1], [168, 120]),
          top: headTop,
          width: 320 * headScale,
          objectFit: "contain",
          filter: `drop-shadow(0 0 22px ${alpha(progress > 0.5 ? C.cyan : C.red, 0.5)})`,
        }}
      />
    </div>
  );
};
