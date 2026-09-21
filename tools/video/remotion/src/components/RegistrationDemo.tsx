import React from "react";
import { Img, interpolate, random, staticFile, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";
import { Label } from "./Text";

/**
 * The lesson of the whole frame-animation switch, as a diagram: the same real frames played twice,
 * left on one anchor pixel and right with a few pixels of drift per frame. The left reads as
 * motion; the right reads as a flip-book. Only the right panel is synthetic — the drift is added
 * here to show what unregistered art does. The frames themselves are the game's own.
 */
export const RegistrationDemo: React.FC<{
  /** Public-dir paths of one looping animation's frames. */
  frames: string[];
  /** How many of them the left panel is labelled as using. */
  leftCount?: number;
  /** How many the right panel shows — the "four beautiful frames" case. */
  rightCount?: number;
  /** Frames each drawing is held for (12 frames ≈ 5 fps reads as a loop, not a slideshow). */
  hold?: number;
  drift?: number;
}> = ({ frames, leftCount = 12, rightCount = 4, hold = 7, drift = 46 }) => {
  const frame = useCurrentFrame();
  const left = frames.slice(0, leftCount);
  // The right panel takes frames spread across the loop, so they are genuinely different drawings.
  const right = Array.from({ length: rightCount }, (_, i) =>
    frames[Math.floor((i * frames.length) / rightCount)],
  );

  const li = Math.floor(frame / hold) % left.length;
  const ri = Math.floor(frame / hold) % right.length;
  const dx = (random(`dx${ri}`) - 0.5) * drift;
  const dy = (random(`dy${ri}`) - 0.5) * drift;

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 24,
      }}
    >
      <Panel
        title={`${leftCount} FRAMES`}
        subtitle="ONE ANCHOR"
        accent={C.cyan}
        src={left[li]}
        dx={0}
        dy={0}
        showAnchor
      />
      <Panel
        title={`${rightCount} FRAMES`}
        subtitle="DRIFTING"
        accent={C.red}
        src={right[ri]}
        dx={dx}
        dy={dy}
        showAnchor
      />
    </div>
  );
};

const Panel: React.FC<{
  title: string;
  subtitle: string;
  accent: string;
  src: string;
  dx: number;
  dy: number;
  showAnchor?: boolean;
}> = ({ title, subtitle, accent, src, dx, dy, showAnchor }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
    <div
      style={{
        width: 478,
        height: 478,
        position: "relative",
        borderRadius: 20,
        overflow: "hidden",
        background: `linear-gradient(160deg, ${alpha(C.slate, 0.4)}, ${alpha(C.deep, 0.96)})`,
        border: `3px solid ${alpha(accent, 0.75)}`,
        boxShadow: `0 0 36px ${alpha(accent, 0.25)}`,
      }}
    >
      {showAnchor ? <Anchor accent={accent} /> : null}
      <Img
        src={staticFile(src)}
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
          objectFit: "contain",
          transform: `translate(${dx}px, ${dy}px)`,
        }}
      />
    </div>
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
      <Label size={40} color={accent} tracking={3}>
        {title}
      </Label>
      <Label size={27} color={C.label} tracking={5}>
        {subtitle}
      </Label>
    </div>
  </div>
);

/** The anchor pixel, drawn as a cross so the drift on the right panel is visible against it. */
const Anchor: React.FC<{ accent: string }> = ({ accent }) => (
  <>
    <div
      style={{
        position: "absolute",
        left: "50%",
        top: 0,
        bottom: 0,
        width: 2,
        background: alpha(accent, 0.3),
      }}
    />
    <div
      style={{
        position: "absolute",
        top: "58%",
        left: 0,
        right: 0,
        height: 2,
        background: alpha(accent, 0.3),
      }}
    />
  </>
);

/** A strip of frames that scrolls past — "108 of these" without saying it twice. */
export const FrameStrip: React.FC<{
  frames: string[];
  y?: number;
  size?: number;
  speed?: number;
  at?: number;
}> = ({ frames, y = 0.46, size = 190, speed = 4.4, at = 0 }) => {
  const frame = useCurrentFrame();
  const local = Math.max(0, frame - at);
  const shift = local * speed;
  const total = frames.length * (size + 10);
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: `${y * 100}%`,
        transform: "translateY(-50%)",
        height: size + 26,
        overflow: "hidden",
        borderTop: `2px solid ${alpha(C.cyan, 0.25)}`,
        borderBottom: `2px solid ${alpha(C.cyan, 0.25)}`,
        background: alpha(C.deep, 0.55),
      }}
    >
      <div
        style={{
          display: "flex",
          gap: 10,
          padding: "13px 0",
          transform: `translateX(${-(shift % total)}px)`,
        }}
      >
        {[...frames, ...frames, ...frames].map((f, i) => (
          <Img
            key={i}
            src={staticFile(f)}
            style={{
              width: size,
              height: size,
              objectFit: "contain",
              flexShrink: 0,
              background: alpha(C.void, 0.5),
              borderRadius: 10,
            }}
          />
        ))}
      </div>
    </div>
  );
};

/** One animation's frames playing as a loop, at a given hold — the drawn-frames answer. */
export const FrameLoop: React.FC<{
  frames: string[];
  hold?: number;
  size?: number;
  y?: number;
  at?: number;
}> = ({ frames, hold = 7, size = 620, y = 0.46, at = 0 }) => {
  const frame = useCurrentFrame();
  const i = Math.floor(Math.max(0, frame - at) / hold) % frames.length;
  return (
    <Img
      src={staticFile(frames[i])}
      style={{
        position: "absolute",
        left: "50%",
        top: `${y * 100}%`,
        transform: "translate(-50%, -50%)",
        width: size,
        height: size,
        objectFit: "contain",
      }}
    />
  );
};
