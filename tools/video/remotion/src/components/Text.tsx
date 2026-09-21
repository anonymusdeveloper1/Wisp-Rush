import React from "react";
import { fitText } from "@remotion/layout-utils";
import { C, alpha } from "../style/palette";
import { F } from "../style/fonts";
import { W } from "../style/layout";

/** Centred text wider than this wraps and stops reading as one slab (recipe §6.5). */
const MAX_TEXT_WIDTH = 800;

type HeadlineProps = {
  children: string;
  /** Fill colour. Cyan = the good/after value, red = the bad/before one. */
  color?: string;
  /** Glow colour; defaults to the fill. */
  glow?: string;
  glowAlpha?: number;
  blur?: number;
  outline?: number;
  outlineColor?: string;
  /** Target width in px; the size is solved to fit it. */
  width?: number;
  /** Or force a size and skip fitting. */
  fontSize?: number;
  style?: React.CSSProperties;
};

/**
 * An Anton headline with the house outline-and-glow treatment: the stroke paints behind the fill
 * so it reads as an outline rather than eating the glyph, and the glow is an offsetless shadow.
 */
export const Headline: React.FC<HeadlineProps> = ({
  children,
  color = C.soul,
  glow,
  glowAlpha = 0.85,
  blur = 34,
  outline = 9,
  outlineColor,
  width = MAX_TEXT_WIDTH,
  fontSize,
  style,
}) => {
  const glowColor = glow ?? (color === C.red ? C.red : color === C.cyan ? C.cyan : C.cyan);
  const stroke = outlineColor ?? (color === C.red ? C.outlineRed : C.outline);
  const size =
    fontSize ??
    fitText({ text: children, withinWidth: width, fontFamily: F.display, fontWeight: 400 })
      .fontSize;
  return (
    <div
      style={{
        fontFamily: F.display,
        fontSize: Math.min(size, 260),
        color,
        lineHeight: 0.98,
        textAlign: "center",
        whiteSpace: "pre",
        WebkitTextStroke: `${outline}px ${stroke}`,
        paintOrder: "stroke fill",
        textShadow: `0 0 ${blur}px ${alpha(glowColor, glowAlpha)}, 0 0 ${Math.round(blur * 0.45)}px ${alpha(glowColor, glowAlpha * 0.7)}`,
        ...style,
      } as React.CSSProperties}
    >
      {children}
    </div>
  );
};

/** Poppins-Bold, for labels, rules, pills and anything that is not a slam. */
export const Label: React.FC<{
  children: React.ReactNode;
  size?: number;
  color?: string;
  tracking?: number;
  weight?: number;
  style?: React.CSSProperties;
}> = ({ children, size = 44, color = C.label, tracking = 4, weight = 700, style }) => (
  <div
    style={{
      fontFamily: F.bold,
      fontWeight: weight,
      fontSize: size,
      letterSpacing: tracking,
      color,
      textAlign: "center",
      lineHeight: 1.18,
      textShadow: `0 4px 14px rgba(0,0,0,0.55)`,
      ...style,
    }}
  >
    {children}
  </div>
);

/** A handwritten margin note, always slightly rotated — the devlog's aside voice. */
export const MarkerNote: React.FC<{
  children: React.ReactNode;
  size?: number;
  color?: string;
  rotate?: number;
  style?: React.CSSProperties;
}> = ({ children, size = 54, color = C.amber, rotate = -7, style }) => (
  <div
    style={{
      fontFamily: F.marker,
      fontSize: size,
      color,
      transform: `rotate(${rotate}deg)`,
      textShadow: `0 0 18px ${alpha(color, 0.5)}, 0 3px 10px rgba(0,0,0,0.6)`,
      whiteSpace: "pre",
      ...style,
    }}
  >
    {children}
  </div>
);

/** Centres a block on the canvas at a 0–1 vertical position. */
export const AtY: React.FC<{
  y: number;
  children: React.ReactNode;
  x?: number;
  style?: React.CSSProperties;
}> = ({ y, x = 0.5, children, style }) => (
  <div
    style={{
      position: "absolute",
      left: `${x * 100}%`,
      top: `${y * 100}%`,
      transform: "translate(-50%, -50%)",
      width: W,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      ...style,
    }}
  >
    {children}
  </div>
);
