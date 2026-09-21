import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";
import { F } from "../style/fonts";
import { Headline, Label, AtY } from "./Text";
import { Appear } from "./Appear";
import { drawOn, slam } from "../style/motion";

/**
 * The series' "measured" beat (recipe §6.3): a row builds label → before (red) → strike → arrow →
 * after (cyan). Nothing goes on this board that is not a logged measurement, and the context line
 * under it always says where the number came from.
 */
export const NumbersRow: React.FC<{
  label: string;
  before: string;
  after: string;
  y: number;
  /** Frames, relative to this component, for each piece to land. */
  at?: { label: number; before: number; strike: number; after: number };
  beforeSize?: number;
  afterSize?: number;
}> = ({ label, before, after, y, at = { label: 0, before: 12, strike: 34, after: 48 }, beforeSize = 84, afterSize = 96 }) => {
  const frame = useCurrentFrame();
  return (
    <>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: `${(y - 0.072) * 100}%`,
          display: "flex",
          justifyContent: "center",
        }}
      >
        {frame >= at.label ? (
          <Appear delay={at.label}>
            <Label size={38} color={C.label} tracking={6}>
              {label}
            </Label>
          </Appear>
        ) : null}
      </div>

      {/* before, struck through */}
      <div style={{ position: "absolute", left: "8%", top: `${y * 100}%`, width: "34%", transform: "translateY(-50%)" }}>
        {frame >= at.before ? (
          <div style={{ position: "relative", transform: `scale(${slam(frame - at.before)})` }}>
            <Headline color={C.red} width={320} fontSize={beforeSize} blur={32}>
              {before}
            </Headline>
            {frame >= at.strike ? (
              <div
                style={{
                  position: "absolute",
                  left: "6%",
                  right: "6%",
                  top: "50%",
                  height: 9,
                  background: C.red,
                  borderRadius: 6,
                  boxShadow: `0 0 18px ${alpha(C.red, 0.9)}`,
                  clipPath: drawOn(frame - at.strike, 8, "left"),
                }}
              />
            ) : null}
          </div>
        ) : null}
      </div>

      {/* the arrow between them */}
      <div style={{ position: "absolute", left: "44%", top: `${y * 100}%`, width: "12%", transform: "translateY(-50%)" }}>
        {frame >= at.strike + 6 ? (
          <div
            style={{
              fontFamily: F.display,
              fontSize: 64,
              color: C.soul,
              textAlign: "center",
              opacity: interpolate(frame - at.strike - 6, [0, 8], [0, 1], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
            }}
          >
            →
          </div>
        ) : null}
      </div>

      {/* after */}
      <div style={{ position: "absolute", left: "58%", top: `${y * 100}%`, width: "34%", transform: "translateY(-50%)" }}>
        {frame >= at.after ? (
          <div style={{ transform: `scale(${slam(frame - at.after)})` }}>
            <Headline color={C.cyan} width={340} fontSize={afterSize} blur={36}>
              {after}
            </Headline>
          </div>
        ) : null}
      </div>
    </>
  );
};

/**
 * Two bars at true relative scale: what something costs in one place against what it costs in
 * another. Built for "a few megabytes on disk, 858 in video memory", where the whole point is
 * that the second bar does not fit on the screen the first one sits on.
 */
export const BarCompare: React.FC<{
  left: { label: string; value: string; fraction: number; color?: string };
  right: { label: string; value: string; fraction: number; color?: string };
  rightAt?: number;
  y?: number;
  width?: number;
}> = ({ left, right, rightAt = 0, y = 0.47, width = 880 }) => {
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
        flexDirection: "column",
        alignItems: "center",
        gap: 54,
      }}
    >
      <Bar {...left} width={width} grow={frame} />
      {frame >= rightAt ? <Bar {...right} width={width} grow={frame - rightAt} /> : <div style={{ height: 150 }} />}
    </div>
  );
};

const Bar: React.FC<{
  label: string;
  value: string;
  fraction: number;
  color?: string;
  width: number;
  grow: number;
}> = ({ label, value, fraction, color = C.cyan, width, grow }) => {
  const p = interpolate(grow, [0, 26], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div style={{ width, display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
        <Label size={34} color={C.label} tracking={5} style={{ textAlign: "left" }}>
          {label}
        </Label>
        <div
          style={{
            fontFamily: F.display,
            fontSize: 62,
            color,
            textShadow: `0 0 22px ${alpha(color, 0.7)}`,
          }}
        >
          {value}
        </div>
      </div>
      <div
        style={{
          width: "100%",
          height: 56,
          borderRadius: 12,
          background: alpha(C.deep, 0.8),
          border: `2px solid ${alpha(color, 0.3)}`,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            width: `${Math.min(1, fraction) * p * 100}%`,
            height: "100%",
            background: `linear-gradient(90deg, ${alpha(color, 0.55)}, ${color})`,
            boxShadow: `0 0 30px ${alpha(color, 0.6)}`,
          }}
        />
      </div>
    </div>
  );
};

/** A numbered step card, the explainer's workhorse (recipe §6.3). */
export const StepCard: React.FC<{
  n: number;
  title: string;
  body: string;
  x: number;
  y?: number;
  accent?: string;
}> = ({ n, title, body, x, y = 0.5, accent = C.cyan }) => (
  <div
    style={{
      position: "absolute",
      left: `${x * 100}%`,
      top: `${y * 100}%`,
      transform: "translate(-50%, -50%)",
      width: 300,
    }}
  >
    <Appear>
      <div
        style={{
          background: `linear-gradient(165deg, ${alpha(C.slate, 0.45)}, ${alpha(C.deep, 0.97)})`,
          border: `3px solid ${alpha(accent, 0.55)}`,
          borderRadius: 20,
          padding: "26px 20px 30px",
          boxShadow: `0 0 34px ${alpha(accent, 0.22)}`,
          textAlign: "center",
        }}
      >
        <div
          style={{
            fontFamily: F.display,
            fontSize: 74,
            color: accent,
            lineHeight: 1,
            textShadow: `0 0 24px ${alpha(accent, 0.8)}`,
          }}
        >
          {n}
        </div>
        <div
          style={{
            fontFamily: F.bold,
            fontWeight: 700,
            fontSize: 30,
            letterSpacing: 2,
            color: C.soul,
            margin: "12px 0 10px",
          }}
        >
          {title}
        </div>
        <div style={{ fontFamily: F.bold, fontWeight: 600, fontSize: 24, lineHeight: 1.35, color: C.label }}>
          {body}
        </div>
      </div>
    </Appear>
  </div>
);

/** A memory meter that fills as characters are added — the gigabyte, shown accumulating. */
export const MemoryMeter: React.FC<{
  /** 0–1 of the meter. */
  fill: number;
  value: string;
  y?: number;
  width?: number;
  danger?: number;
}> = ({ fill, value, y = 0.72, width = 860, danger = 0.8 }) => {
  const over = fill >= danger;
  const color = over ? C.red : C.cyan;
  return (
    <AtY y={y}>
      <div style={{ width, display: "flex", flexDirection: "column", gap: 14, alignItems: "center" }}>
        <div
          style={{
            width: "100%",
            height: 46,
            borderRadius: 10,
            background: alpha(C.deep, 0.85),
            border: `2px solid ${alpha(color, 0.35)}`,
            overflow: "hidden",
          }}
        >
          <div
            style={{
              width: `${Math.min(1, fill) * 100}%`,
              height: "100%",
              background: `linear-gradient(90deg, ${alpha(color, 0.5)}, ${color})`,
              boxShadow: `0 0 26px ${alpha(color, 0.6)}`,
            }}
          />
        </div>
        <div
          style={{
            fontFamily: F.display,
            fontSize: 72,
            color,
            textShadow: `0 0 26px ${alpha(color, 0.75)}`,
          }}
        >
          {value}
        </div>
      </div>
    </AtY>
  );
};
