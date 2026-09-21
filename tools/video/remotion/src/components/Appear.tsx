import React from "react";
import { useCurrentFrame } from "remotion";
import { popLife, popScale, popOpacity } from "../style/motion";

/**
 * The house entrance. Wrap anything that pops in — cards, pills, headlines, step cards — so the
 * whole episode shares one curve (recipe §6.4). `life` adds the 6-frame shrink-out at the end.
 */
export const Appear: React.FC<{
  children: React.ReactNode;
  /** Frames the element is on screen; omit for "stays until its Sequence ends". */
  life?: number;
  delay?: number;
  style?: React.CSSProperties;
}> = ({ children, life, delay = 0, style }) => {
  const local = useCurrentFrame() - delay;
  const { scale, opacity } = life
    ? popLife(local, life)
    : { scale: popScale(local), opacity: popOpacity(local) };
  if (local < 0) return null;
  return (
    <div style={{ ...style, transform: `scale(${scale})`, opacity }}>{children}</div>
  );
};
