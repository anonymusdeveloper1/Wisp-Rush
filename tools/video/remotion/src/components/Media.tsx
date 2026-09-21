import React from "react";
import { AbsoluteFill, Audio, Img, OffthreadVideo, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C } from "../style/palette";

/**
 * A footage clip. `startFrom`/`endAt` trim it, `speed` slows UI that is too fast to read
 * (recipe §6.3 uses 0.35–0.5), `punch` is a 1.0–1.3 push-in, and `blur` keyframes the hook's
 * focus pull. Footage is 540×960; the canvas is 1080×1920, so it is scaled 2× and stays sharp
 * enough because the source is a clean render rather than a camera.
 */
export const Footage: React.FC<{
  src: string;
  startFrom?: number;
  speed?: number;
  punch?: number;
  /** [frame, px] pairs, clip-relative. */
  blur?: [number, number][];
  volume?: number;
  style?: React.CSSProperties;
  /** Shift the visible window; 0.5 is centred. */
  focusY?: number;
}> = ({ src, startFrom = 0, speed = 1, punch = 1, blur, volume = 0, style, focusY = 0.5 }) => {
  const frame = useCurrentFrame();
  const blurPx = blur
    ? interpolate(
        frame,
        blur.map((b) => b[0]),
        blur.map((b) => b[1]),
        { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
      )
    : 0;
  return (
    <AbsoluteFill style={{ overflow: "hidden", backgroundColor: C.matte }}>
      <OffthreadVideo
        src={staticFile(src)}
        startFrom={startFrom}
        playbackRate={speed}
        volume={volume}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          objectPosition: `50% ${focusY * 100}%`,
          transform: `scale(${punch})`,
          filter: blurPx > 0.1 ? `blur(${blurPx}px)` : undefined,
          ...style,
        }}
      />
    </AbsoluteFill>
  );
};

/** A still from the game or a graphic piece, fitted rather than cropped. */
export const Still: React.FC<{
  src: string;
  fit?: "cover" | "contain";
  style?: React.CSSProperties;
}> = ({ src, fit = "cover", style }) => (
  <AbsoluteFill style={{ overflow: "hidden" }}>
    <Img
      src={staticFile(src)}
      style={{ width: "100%", height: "100%", objectFit: fit, ...style }}
    />
  </AbsoluteFill>
);

/**
 * One of the game's own synthesized sounds, placed on the frame its visual lands (recipe §6.7).
 * Levels follow the recipe's table: one-shots −9 dB, slams −11, anything under a spoken word −15.
 */
export const Sfx: React.FC<{ id: string; db?: number }> = ({ id, db = -9 }) => (
  <Audio src={staticFile(`audio/game/sfx/${id}.wav`)} volume={10 ** (db / 20)} />
);

/** The calm music bed, under explanations only (recipe §6.7: −22 dB, fades). */
export const MusicBed: React.FC<{ id?: string; db?: number; fadeOut?: number; durationInFrames: number }> = ({
  id = "bed_calm",
  db = -22,
  fadeOut = 60,
  durationInFrames,
}) => (
  <Audio
    src={staticFile(`audio/game/music/${id}.wav`)}
    volume={(f) =>
      10 ** (db / 20) *
      interpolate(f, [0, 20, durationInFrames - fadeOut, durationInFrames], [0, 1, 1, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    }
  />
);
