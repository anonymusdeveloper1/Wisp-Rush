import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { C, alpha } from "../style/palette";
import { F } from "../style/fonts";

type P = { x: number; y: number };

/**
 * Two-bone inverse kinematics: given a shoulder, a wrist target and the two limb lengths, solve
 * the elbow. This is the lesson of the whole puppet episode — author the endpoint you can read
 * off the painting, and let the maths find the joint angles you cannot.
 */
export const solveElbow = (s: P, target: P, l1: number, l2: number, flip = 1): P => {
  const dx = target.x - s.x;
  const dy = target.y - s.y;
  const d = Math.min(Math.max(Math.hypot(dx, dy), Math.abs(l1 - l2) + 0.001), l1 + l2 - 0.001);
  const a = Math.atan2(dy, dx);
  const cos = (d * d + l1 * l1 - l2 * l2) / (2 * d * l1);
  const theta = Math.acos(Math.min(1, Math.max(-1, cos)));
  const angle = a - flip * theta;
  return { x: s.x + Math.cos(angle) * l1, y: s.y + Math.sin(angle) * l1 };
};

/** Where a chain ends when each joint angle is typed in by hand instead of solved. */
const chainFromAngles = (s: P, l1: number, l2: number, a1: number, a2: number) => {
  const elbow = { x: s.x + Math.cos(a1) * l1, y: s.y + Math.sin(a1) * l1 };
  const wrist = { x: elbow.x + Math.cos(a1 + a2) * l2, y: elbow.y + Math.sin(a1 + a2) * l2 };
  return { elbow, wrist };
};

/**
 * The arm chain, drawn twice over the same body: once with hand-typed angles (the wrist lands
 * behind the head) and once solved from an authored wrist position. `progress` 0 shows the typed
 * version, 1 the solved one, and the diagram crossfades the labels with it.
 */
export const JointDiagram: React.FC<{
  /** 0 = typed angles, 1 = endpoint authored and joints solved. */
  progress?: number;
  /** Frames over which to animate from typed to solved; ignored if `progress` is given. */
  solveAt?: number;
  solveOver?: number;
}> = ({ progress, solveAt = 0, solveOver = 26 }) => {
  const frame = useCurrentFrame();
  const t =
    progress ??
    interpolate(frame - solveAt, [0, solveOver], [0, 1], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    });

  const shoulder: P = { x: 250, y: 250 };
  const L1 = 132;
  const L2 = 124;
  // The three rounds of eyeballed angles: the forearm folds back over the shoulder.
  const typed = chainFromAngles(shoulder, L1, L2, -2.5, -1.75);
  // The pose actually readable off the painting: the hand out in front, holding a fan.
  const target: P = { x: 452, y: 356 };
  const solvedElbow = solveElbow(shoulder, target, L1, L2, 1);

  const elbow: P = {
    x: interpolate(t, [0, 1], [typed.elbow.x, solvedElbow.x]),
    y: interpolate(t, [0, 1], [typed.elbow.y, solvedElbow.y]),
  };
  const wrist: P = {
    x: interpolate(t, [0, 1], [typed.wrist.x, target.x]),
    y: interpolate(t, [0, 1], [typed.wrist.y, target.y]),
  };
  const accent = t > 0.5 ? C.cyan : C.red;

  return (
    <svg
      viewBox="0 0 600 600"
      style={{ position: "absolute", left: "50%", top: "46%", transform: "translate(-50%, -50%)", width: 900, height: 900 }}
    >
      {/* The body the arm hangs off: a head and a torso, enough to read the mistake. */}
      <circle cx={250} cy={130} r={62} fill={alpha(C.slate, 0.7)} stroke={alpha(C.cyan, 0.5)} strokeWidth={3} />
      <path
        d="M195 205 L305 205 L322 400 L178 400 Z"
        fill={alpha(C.slate, 0.6)}
        stroke={alpha(C.cyan, 0.45)}
        strokeWidth={3}
      />

      {/* The wrist target, authored from the painting. It only lights up once it is being used. */}
      <circle
        cx={target.x}
        cy={target.y}
        r={26}
        fill="none"
        stroke={alpha(C.cyan, 0.35 + 0.65 * t)}
        strokeWidth={4}
        strokeDasharray="10 8"
      />
      <circle cx={target.x} cy={target.y} r={7} fill={alpha(C.cyan, 0.4 + 0.6 * t)} />

      {/* The chain itself. */}
      <line x1={shoulder.x} y1={shoulder.y} x2={elbow.x} y2={elbow.y} stroke={accent} strokeWidth={13} strokeLinecap="round" />
      <line x1={elbow.x} y1={elbow.y} x2={wrist.x} y2={wrist.y} stroke={accent} strokeWidth={13} strokeLinecap="round" />
      <circle cx={shoulder.x} cy={shoulder.y} r={15} fill={C.soul} />
      <circle cx={elbow.x} cy={elbow.y} r={13} fill={C.soul} />
      <circle cx={wrist.x} cy={wrist.y} r={16} fill={accent} stroke={C.soul} strokeWidth={4} />

      <text
        x={300}
        y={556}
        textAnchor="middle"
        fill={accent}
        style={{ fontFamily: F.bold, fontSize: 40, fontWeight: 700, letterSpacing: 3 }}
      >
        {t > 0.5 ? "SOLVED FROM THE HAND" : "ANGLES TYPED BY HAND"}
      </text>
    </svg>
  );
};
