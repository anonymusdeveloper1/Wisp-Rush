import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";
import { F } from "../style/fonts";
import { Headline, Label, AtY } from "./Text";
import { Appear } from "./Appear";
import { Matte } from "./Backdrops";
import { drawOn } from "../style/motion";

/** The series tag that brands the hook of every episode (recipe §6.3). */
export const SeriesTag: React.FC<{ episode: number; y?: number }> = ({ episode, y = 0.175 }) => (
  <AtY y={y}>
    <Appear>
      <div
        style={{
          fontFamily: F.display,
          fontSize: 76,
          lineHeight: 0.86,
          color: C.soul,
          textAlign: "center",
          letterSpacing: 1,
          WebkitTextStroke: `8px ${C.void}`,
          paintOrder: "stroke fill",
          textShadow: `0 0 26px ${alpha(C.cyan, 0.75)}`,
        } as React.CSSProperties}
      >
        WISP RUSH
        <br />
        <span style={{ fontSize: 60 }}>DEVLOG #{episode}</span>
      </div>
    </Appear>
  </AtY>
);

/** A bordered pill — the AI credit, a context header, a mode label. */
export const Pill: React.FC<{
  children: React.ReactNode;
  y?: number;
  size?: number;
  accent?: string;
  bg?: string;
}> = ({ children, y = 0.215, size = 40, accent = C.cyan, bg = C.pillDark }) => (
  <AtY y={y}>
    <Appear>
      <div
        style={{
          fontFamily: F.bold,
          fontWeight: 700,
          fontSize: size,
          letterSpacing: 2,
          color: C.soul,
          textAlign: "center",
          lineHeight: 1.28,
          background: alpha(bg, 0.96),
          border: `3px solid ${accent}`,
          borderRadius: 20,
          padding: "22px 40px",
          boxShadow: `0 0 34px ${alpha(accent, 0.3)}`,
        }}
      >
        {children}
      </div>
    </Appear>
  </AtY>
);

/**
 * The required AI disclosure, said once in the voice and shown once as a pill (recipe §1).
 * Never call the art hand-made.
 */
export const AiPill: React.FC<{ y?: number }> = ({ y = 0.215 }) => (
  <Pill y={y}>
    AI CODING AGENTS BUILD THIS GAME
    <br />
    <span style={{ color: C.label, fontSize: 32 }}>ART IS AI-GENERATED FROM MY CONCEPTS</span>
  </Pill>
);

/** A one-word black beat card: the hardest cut in the series (recipe §3.1 black word card). */
export const WordCard: React.FC<{
  word: string;
  color?: string;
  y?: number;
  width?: number;
}> = ({ word, color = C.soul, y = 0.47, width = 820 }) => (
  <AbsoluteFill>
    <Matte />
    <AtY y={y}>
      <Appear>
        <Headline color={color} width={width} blur={40} glowAlpha={0.85}>
          {word}
        </Headline>
      </Appear>
    </AtY>
  </AbsoluteFill>
);

/** An underline or strike that draws itself on (recipe §6.3). */
export const Rule: React.FC<{
  y: number;
  width?: number;
  color?: string;
  thickness?: number;
  frames?: number;
  delay?: number;
  x?: number;
}> = ({ y, width = 0.7, color = C.amber, thickness = 10, frames = 10, delay = 0, x = 0.5 }) => {
  const local = useCurrentFrame() - delay;
  if (local < 0) return null;
  return (
    <div
      style={{
        position: "absolute",
        left: `${(x - width / 2) * 100}%`,
        top: `${y * 100}%`,
        width: `${width * 100}%`,
        height: thickness,
        background: color,
        borderRadius: thickness,
        boxShadow: `0 0 22px ${alpha(color, 0.8)}`,
        clipPath: drawOn(local, frames, "left"),
      }}
    />
  );
};

/** The closing question, then the follow card — the series' fixed ending (recipe §3). */
export const Question: React.FC<{ top: string; bottom: string }> = ({ top, bottom }) => (
  <>
    <AtY y={0.41}>
      <Appear>
        <Headline width={760} fontSize={78}>
          {top}
        </Headline>
      </Appear>
    </AtY>
    <AtY y={0.5}>
      <Appear delay={10}>
        <Headline color={C.cyan} width={800} fontSize={118}>
          {bottom}
        </Headline>
      </Appear>
    </AtY>
  </>
);

export const FollowCard: React.FC<{ next: number }> = ({ next }) => {
  const frame = useCurrentFrame();
  const dim = interpolate(frame, [0, 12], [0, 0.62], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <>
      <Matte opacity={dim} />
      <AtY y={0.43}>
        <Appear>
          <Headline color={C.cyan} fontSize={80} width={700}>
            FOLLOW FOR
          </Headline>
        </Appear>
      </AtY>
      <AtY y={0.52}>
        <Appear delay={8}>
          <Headline fontSize={108} width={800}>
            {`DEVLOG #${next}`}
          </Headline>
        </Appear>
      </AtY>
    </>
  );
};

/** A small grey context line, for "measured on a Galaxy S24" under a number. */
export const Context: React.FC<{ children: React.ReactNode; y?: number }> = ({
  children,
  y = 0.665,
}) => (
  <AtY y={y}>
    <Appear>
      <Label size={26} color={C.context} tracking={2}>
        {children}
      </Label>
    </Appear>
  </AtY>
);
