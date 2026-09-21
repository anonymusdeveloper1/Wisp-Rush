import React from "react";
import { staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { useAudioData, visualizeAudio } from "@remotion/media-utils";
import { C, alpha } from "../style/palette";
import { F } from "../style/fonts";

/**
 * Bars driven by the real spectrum of a sound file, not a decorative loop. For this series the
 * file is always one the game synthesized itself, so the picture on screen is the thing being
 * talked about.
 */
export const SpectrumBars: React.FC<{
  /** Public-dir path, e.g. "audio/game/music/bed_calm.wav". */
  src: string;
  bars?: number;
  width?: number;
  height?: number;
  color?: string;
  /** Seconds into the file to read, if the clip does not start at its beginning. */
  offset?: number;
  style?: React.CSSProperties;
  /** Scales every bar; use to keep a quiet bed from looking flat. */
  gain?: number;
}> = ({ src, bars = 32, width = 900, height = 260, color = C.cyan, offset = 0, style, gain = 1 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const audioData = useAudioData(staticFile(src));

  // visualizeAudio only accepts a power of two, so sample at 64 and spread `bars` across the
  // lower two thirds of the spectrum — that is where a synth's body actually is.
  const SAMPLES = 64;
  const spectrum = audioData
    ? visualizeAudio({
        fps,
        frame: frame + Math.round(offset * fps),
        audioData,
        numberOfSamples: SAMPLES,
      })
    : new Array(SAMPLES).fill(0);
  // A synth's energy piles into the lowest bins, so spread the bars over the low half on a mild
  // curve and normalise each frame against its own peak. The shape still comes from the audio;
  // this only stops every bar but the first three from sitting on the floor.
  // Magnitudes roll off by orders of magnitude across the spectrum, so a linear bar chart is a
  // cliff followed by a flat line. Read them in decibels, the way every meter does, and map a
  // sensible window onto the lane height.
  const DB_FLOOR = -72;
  const DB_CEIL = -14;
  const values = Array.from({ length: bars }, (_, i) => {
    const t = bars < 2 ? 0 : i / (bars - 1);
    const bin = Math.min(SAMPLES - 1, Math.round(Math.pow(t, 1.2) * SAMPLES * 0.55));
    const db = 20 * Math.log10((spectrum[bin] ?? 0) + 1e-7);
    return Math.min(1, Math.max(0, (db - DB_FLOOR) / (DB_CEIL - DB_FLOOR)));
  });

  return (
    <div
      style={{
        width,
        height,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: Math.max(3, Math.round(width / bars / 5)),
        ...style,
      }}
    >
      {Array.from(values).map((v, i) => {
        const h = Math.max(6, Math.min(1, v * gain) * height);
        return (
          <div
            key={i}
            style={{
              width: width / bars - Math.max(3, Math.round(width / bars / 5)),
              height: h,
              borderRadius: 6,
              background: `linear-gradient(180deg, ${color}, ${alpha(color, 0.35)})`,
              boxShadow: `0 0 ${10 + h * 0.08}px ${alpha(color, 0.55)}`,
            }}
          />
        );
      })}
    </div>
  );
};

/** One named layer of the music, as its own lane — pad, pulse or boss. */
export const WaveLane: React.FC<{
  src: string;
  label: string;
  sub?: string;
  color?: string;
  active?: boolean;
  width?: number;
  height?: number;
  offset?: number;
  gain?: number;
}> = ({ src, label, sub, color = C.cyan, active = true, width = 860, height = 116, offset = 0, gain = 1 }) => (
  <div
    style={{
      display: "flex",
      alignItems: "center",
      gap: 22,
      opacity: active ? 1 : 0.5,
      filter: active ? undefined : "grayscale(0.55)",
      transition: "none",
    }}
  >
    <div style={{ width: 236, textAlign: "right" }}>
      <div
        style={{
          fontFamily: F.display,
          fontSize: 52,
          color,
          textShadow: active ? `0 0 22px ${alpha(color, 0.7)}` : undefined,
        }}
      >
        {label}
      </div>
      {sub ? (
        <div style={{ fontFamily: F.bold, fontWeight: 700, fontSize: 22, letterSpacing: 3, color: C.label }}>
          {sub}
        </div>
      ) : null}
    </div>
    <SpectrumBars
      src={src}
      bars={26}
      width={width - 258}
      height={height}
      color={color}
      offset={offset}
      gain={gain}
    />
  </div>
);

/**
 * The rising slice: one bar per extra kill in a dash, each taller and brighter than the last.
 * `step` is how many have landed so far.
 */
export const StepStairs: React.FC<{ step: number; steps?: number; width?: number; height?: number }> = ({
  step,
  steps = 5,
  width = 820,
  height = 420,
}) => (
  <div
    style={{
      width,
      height,
      display: "flex",
      alignItems: "flex-end",
      justifyContent: "center",
      gap: 26,
    }}
  >
    {Array.from({ length: steps }, (_, i) => {
      const on = i < step;
      const h = height * (0.3 + (0.7 * (i + 1)) / steps);
      return (
        <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
          <div
            style={{
              width: 110,
              height: on ? h : 14,
              borderRadius: 14,
              background: on
                ? `linear-gradient(180deg, ${C.cyan}, ${alpha(C.cyan, 0.3)})`
                : alpha(C.slate, 0.55),
              boxShadow: on ? `0 0 34px ${alpha(C.cyan, 0.55)}` : undefined,
            }}
          />
          <div
            style={{
              fontFamily: F.display,
              fontSize: 46,
              color: on ? C.soul : alpha(C.grey, 0.6),
              textShadow: on ? `0 0 18px ${alpha(C.cyan, 0.6)}` : undefined,
            }}
          >
            {i + 1}
          </div>
        </div>
      );
    })}
  </div>
);

/** Every synthesized effect id, as a wall of pills — the inventory the game ships no files for. */
export const SoundPills: React.FC<{
  ids: string[];
  /** Ids to light up rather than leaving dim. */
  litAt?: number;
  lit?: string[];
  width?: number;
}> = ({ ids, litAt, lit = [], width = 940 }) => {
  const frame = useCurrentFrame();
  return (
    <div
      style={{
        width,
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        gap: 12,
      }}
    >
      {ids.map((id, i) => {
        const on = litAt !== undefined && frame >= litAt && lit.includes(id);
        const local = frame - i * 1.6;
        const appear = Math.min(1, Math.max(0, local / 6));
        return (
          <div
            key={id}
            style={{
              fontFamily: F.bold,
              fontWeight: 700,
              fontSize: 27,
              letterSpacing: 1,
              color: on ? C.matte : C.label,
              background: on ? C.cyan : alpha(C.deep, 0.85),
              border: `2px solid ${alpha(on ? C.cyan : C.cyan, on ? 1 : 0.22)}`,
              borderRadius: 999,
              padding: "12px 20px",
              opacity: appear,
              transform: `scale(${0.85 + appear * 0.15})`,
              boxShadow: on ? `0 0 26px ${alpha(C.cyan, 0.6)}` : undefined,
            }}
          >
            {id}
          </div>
        );
      })}
    </div>
  );
};
