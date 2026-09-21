import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";
import { F } from "../style/fonts";
import { CAPTION_Y } from "../style/layout";

export type Cue = { from: number; to: number; text: string };

/**
 * The caption track (recipe §6.6): Poppins-Bold 66, uppercase, white with the last word popping
 * cyan, at y 0.73. Cues come from the Kokoro SRT, so they land within ~0.1 s of the speech —
 * never from automatic transcription, which sits 0.4–0.8 s early on synthesized voice.
 *
 * `hide` drops the cues a headline is already showing, so the screen never says the same words
 * twice. `lift` moves them up over a shot where 0.73 would cover something that matters.
 */
export const Captions: React.FC<{
  cues: Cue[];
  hide?: [number, number][];
  lift?: [number, number, number][];
}> = ({ cues, hide = [], lift = [] }) => {
  const frame = useCurrentFrame();
  const cue = cues.find((c) => frame >= c.from && frame < c.to);
  if (!cue) return null;
  if (hide.some(([a, b]) => cue.from >= a && cue.from < b)) return null;

  const lifted = lift.find(([a, b]) => cue.from >= a && cue.from < b);
  const y = lifted ? lifted[2] : CAPTION_Y;

  const local = frame - cue.from;
  const pop = interpolate(local, [0, 4], [0.88, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const words = cue.text.split(" ");

  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: `${y * 100}%`,
        transform: `translateY(-50%) scale(${pop})`,
        display: "flex",
        justifyContent: "center",
        gap: 14,
        flexWrap: "wrap",
        padding: "0 74px",
      }}
    >
      {words.map((w, i) => (
        <span
          key={i}
          style={{
            fontFamily: F.bold,
            fontWeight: 700,
            fontSize: 66,
            letterSpacing: 1,
            textTransform: "uppercase",
            color: i === words.length - 1 ? C.cyan : "#FFFFFF",
            WebkitTextStroke: `9px ${C.pillDark}`,
            paintOrder: "stroke fill",
            textShadow: `0 5px 14px ${alpha("#000000", 0.55)}`,
          } as React.CSSProperties}
        >
          {w}
        </span>
      ))}
    </div>
  );
};
