import React from "react";
import { AbsoluteFill, Audio, Img, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C, alpha } from "../../style/palette";
import { Headline, Label, MarkerNote, AtY } from "../../components/Text";
import { Appear } from "../../components/Appear";
import { Dim, GridBackdrop, Matte, Vignette } from "../../components/Backdrops";
import { AiPill, Context, FollowCard, Question, Rule, SeriesTag } from "../../components/Furniture";
import { Footage, MusicBed, Sfx } from "../../components/Media";
import { PartsScatter } from "../../components/PartsScatter";
import { HeadOnTorso, PartsGrid } from "../../components/PartsGrid";
import { JointDiagram } from "../../components/JointDiagram";
import { FrameLoop } from "../../components/RegistrationDemo";
import { Captions } from "../../components/Captions";
import { CUES } from "./captions";
import { ARM_INDICES, HEAD, PAINTING, PUPPET_PARTS, SPARE_ARM_INDICES, TORSO, WINNING_FRAMES } from "./assets";
import { slam } from "../../style/motion";

/**
 * Devlog #6 — "I built it, it worked, and I deleted it."
 *
 * Hook: H1 shortcut promise, on the speed-flex treatment — neither repeats EP05's H6 pattern
 * interrupt or its roster-wall strike-out. Structure B: the thing that was built → three mistakes,
 * each with the lesson under it → it worked anyway → it was deleted anyway.
 *
 * EP05 already spent the registration lesson, so this episode's takeaway is the other one:
 * author the endpoint you can read off the art, and let the maths find the joint.
 */

// Beat frames, from video/voice/ep06/ep06_built_then_deleted.{lines.json,srt}
const B = {
  hook: 0,
  bin: 58, // "in the bin"
  promise: 140, // "Here's what it taught me, in forty seconds."
  painting: 284, // "I was turning one painted character into a jointed puppet."
  pieces: 487, // "26 pieces."
  joints: 550, // "Shoulders, elbows, wrists."
  m1: 678, // "Mistake one."
  typed: 726, // "I typed the joint angles by hand."
  fists: 950, // "her fists were behind her head."
  authoring: 1101, // "authoring where the hand goes,"
  solving: 1188, // "and solving the angles from there."
  rule: 1310, // "Author the endpoint."
  maths: 1374, // "Let the maths find the joint."
  m2: 1493, // "Mistake two."
  chin: 1666, // "so her chin sat on her waist."
  measured: 1742, // the snap to where measuring puts it
  m3: 1796, // "Mistake three."
  fourArms: 1889, // "four arms."
  relaxed: 2032, // "two arms, relaxed."
  worked: 2136, // "It all worked in the end."
  deleted: 2217, // "Then I deleted it,"
  framesWon: 2287, // "because drawn frames won."
  ai: 2404,
  question: 2692,
  follow: 2800,
  end: 2950,
} as const;

export const EP06_DURATION = B.end;

export const Ep06: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: C.matte }}>
    <Audio src={staticFile("voice/ep06/ep06_built_then_deleted_master.wav")} />
    <Sequence from={B.painting} durationInFrames={B.worked - B.painting}>
      <MusicBed durationInFrames={B.worked - B.painting} />
    </Sequence>

    {/* 1. Hook: everything it was made of, thrown out in three seconds */}
    <Sequence from={B.hook} durationInFrames={B.painting}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 46%, ${alpha(C.slate, 0.4)} 0%, ${C.matte} 70%)`,
        }}
      />
      <BinnedParts binAt={B.bin} />
      <SeriesTag episode={6} y={0.115} />
      {/* The claim sits above the cloud so both stay readable — the parts are the evidence. */}
      <Sequence from={B.bin}>
        <AtY y={0.245}>
          <BinSlam />
        </AtY>
      </Sequence>
      <Sfx id="dash" db={-10} />
      <Sequence from={B.bin}>
        <Sfx id="reaper_hit" db={-11} />
      </Sequence>
      <Sequence from={B.promise}>
        <Sfx id="slice_step1" db={-13} />
      </Sequence>
    </Sequence>

    {/* 2. What it was: one painting, turned into a body with joints */}
    <Sequence from={B.painting} durationInFrames={B.pieces - B.painting}>
      <GridBackdrop />
      <AtY y={0.45}>
        <Appear>
          <Img
            src={staticFile(PAINTING)}
            style={{ width: 520, objectFit: "contain" }}
          />
        </Appear>
      </AtY>
      <AtY y={0.155}>
        <Appear>
          <Label size={40} color={C.label} tracking={6}>
            ONE PAINTING
          </Label>
        </Appear>
      </AtY>
      <Sequence from={120}>
        <AtY y={0.79}>
          <Appear>
            <MarkerNote size={58} rotate={-6} color={C.amber}>
              make it move
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="ui_confirm" db={-12} />
    </Sequence>

    {/* 3. The kit: 26 pieces in a grid, because a grid counts */}
    <Sequence from={B.pieces} durationInFrames={B.m1 - B.pieces}>
      <GridBackdrop />
      <PartsGrid files={PUPPET_PARTS} columns={6} cell={142} gap={12} y={0.5} stagger={1.4} />
      <PieceCount />
      <Sequence from={B.joints - B.pieces}>
        <AtY y={0.855}>
          <Appear>
            <Label size={38} color={C.cyan} tracking={5}>
              SHOULDERS. ELBOWS. WRISTS.
            </Label>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="slice_step3" db={-11} />
      <Sequence from={B.joints - B.pieces}>
        <Sfx id="slice_step5" db={-13} />
      </Sequence>
    </Sequence>

    {/* 4. Mistake one: typed angles never converge */}
    <Sequence from={B.m1} durationInFrames={B.rule - B.m1}>
      <GridBackdrop />
      <MistakeTag n="ONE" text="I TYPED THE ANGLES" />
      <Sequence from={B.typed - B.m1}>
        <JointDiagram solveAt={B.solving - B.typed} solveOver={30} />
      </Sequence>
      <Sequence from={B.fists - B.m1} durationInFrames={B.authoring - B.fists}>
        <AtY y={0.845} x={0.46}>
          <Appear life={B.authoring - B.fists}>
            <MarkerNote size={56} rotate={-7} color={C.red}>
              three rounds of guessing
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.authoring - B.m1}>
        <AtY y={0.845} x={0.5}>
          <Appear>
            <MarkerNote size={54} rotate={5} color={C.cyan}>
              author the hand, not the angles
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.typed - B.m1}>
        <Sfx id="ui_error" db={-14} />
      </Sequence>
      <Sequence from={B.fists - B.m1}>
        <Sfx id="player_damage" db={-14} />
      </Sequence>
      <Sequence from={B.solving - B.m1}>
        <Sfx id="level_up" db={-11} />
      </Sequence>
    </Sequence>

    {/* 5. The rule, as a card */}
    <Sequence from={B.rule} durationInFrames={B.m2 - B.rule}>
      <Matte />
      <AtY y={0.42}>
        <Appear>
          <Headline color={C.soul} width={760} fontSize={88}>
            AUTHOR THE ENDPOINT.
          </Headline>
        </Appear>
      </AtY>
      <Sequence from={B.maths - B.rule}>
        <AtY y={0.53}>
          <Appear>
            <Headline color={C.cyan} width={800} fontSize={88}>
              {"LET THE MATHS\nFIND THE JOINT."}
            </Headline>
          </Appear>
        </AtY>
        <Rule y={0.625} width={0.62} color={C.cyan} delay={10} />
      </Sequence>
      <Sfx id="slice_step3" db={-11} />
      <Sequence from={B.maths - B.rule}>
        <Sfx id="slice_step5" db={-12} />
      </Sequence>
    </Sequence>

    {/* 6. Mistake two: laying out a body before measuring it */}
    <Sequence from={B.m2} durationInFrames={B.m3 - B.m2}>
      <GridBackdrop />
      <MistakeTag n="TWO" text="I LAID IT OUT BY EYE" />
      <ChinGag snapAt={B.measured - B.m2} />
      <Sequence from={B.chin - B.m2} durationInFrames={B.measured - B.chin}>
        <AtY y={0.85} x={0.44}>
          <Appear life={B.measured - B.chin}>
            <MarkerNote size={58} rotate={-8} color={C.red}>
              chin on her waist
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.measured - B.m2}>
        <AtY y={0.85} x={0.52}>
          <Appear>
            <MarkerNote size={56} rotate={4} color={C.cyan}>
              measure first
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.chin - B.m2}>
        <Sfx id="ui_error" db={-14} />
      </Sequence>
      <Sequence from={B.measured - B.m2}>
        <Sfx id="level_up" db={-12} />
      </Sequence>
    </Sequence>

    {/* 7. Mistake three: the spare pair is the same pair */}
    <Sequence from={B.m3} durationInFrames={B.worked - B.m3}>
      <GridBackdrop />
      <MistakeTag n="THREE" text="I GAVE HER FOUR ARMS" />
      <PartsGrid
        files={ARM_INDICES.map((i) => PUPPET_PARTS[i])}
        columns={4}
        cell={202}
        gap={14}
        y={0.47}
        stagger={3}
        markedAt={B.relaxed - B.m3}
        marked={SPARE_ARM_INDICES.map((i) => ARM_INDICES.indexOf(i))}
      />
      <Sequence from={B.fourArms - B.m3}>
        <AtY y={0.665}>
          <Appear>
            <Label size={40} color={C.label} tracking={5}>
              FOUR UPPER ARMS IN THE KIT
            </Label>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.relaxed - B.m3}>
        <AtY y={0.755}>
          <Appear>
            <Headline color={C.amber} width={740} fontSize={72}>
              THE SAME TWO, RELAXED
            </Headline>
          </Appear>
        </AtY>
        <AtY y={0.845} x={0.5}>
          <Appear delay={12}>
            <MarkerNote size={54} rotate={-5} color={C.red}>
              I built a four-armed idol
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="slice_step1" db={-13} />
      <Sequence from={B.fourArms - B.m3}>
        <Sfx id="reaper_windup" db={-14} />
      </Sequence>
      <Sequence from={B.relaxed - B.m3}>
        <Sfx id="reaper_hit" db={-12} />
      </Sequence>
    </Sequence>

    {/* 8. It worked. It went anyway, because the frames won. */}
    <Sequence from={B.worked} durationInFrames={B.ai - B.worked}>
      <GridBackdrop />
      <Sequence durationInFrames={B.framesWon - B.worked}>
        <AtY y={0.45}>
          <Appear>
            <Img src={staticFile(PAINTING)} style={{ width: 460, objectFit: "contain" }} />
          </Appear>
        </AtY>
        <Sequence from={B.deleted - B.worked}>
          <DeleteStrike />
        </Sequence>
      </Sequence>
      <Sequence from={B.framesWon - B.worked}>
        <FrameLoop frames={WINNING_FRAMES} hold={7} size={620} y={0.45} />
        <AtY y={0.755}>
          <Appear>
            <Headline color={C.cyan} width={740} fontSize={84}>
              DRAWN FRAMES WON
            </Headline>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.deleted - B.worked}>
        <Sfx id="ui_back" db={-11} />
      </Sequence>
      <Sequence from={B.framesWon - B.worked}>
        <Sfx id="level_up" db={-11} />
      </Sequence>
    </Sequence>

    {/* 9. Payoff, credit, question, follow */}
    <Sequence from={B.ai} durationInFrames={B.end - B.ai}>
      <Footage src="footage/tour_menus.mp4" startFrom={2160} volume={0.12} />
      <Vignette strength={0.45} />
      <Sequence durationInFrames={B.question - B.ai}>
        <AiPill y={0.2} />
      </Sequence>
      <Sequence from={B.question - B.ai} durationInFrames={B.follow - B.question}>
        <Dim keys={[[0, 0], [10, 0.55]]} />
        <Question top="WOULD YOU HAVE" bottom="KEPT IT?" />
      </Sequence>
      <Sequence from={B.follow - B.ai}>
        <FollowCard next={7} />
      </Sequence>
      <Sfx id="slice_step1" db={-14} />
      <Sequence from={B.question - B.ai}>
        <Sfx id="upgrade_choice" db={-11} />
      </Sequence>
      <Sequence from={B.follow - B.ai}>
        <Sfx id="shard_pickup" db={-11} />
      </Sequence>
      <Sequence from={B.follow - B.ai + 8}>
        <Sfx id="slice_step8" db={-12} />
      </Sequence>
    </Sequence>

    <Captions
      cues={CUES}
      hide={[
        [B.bin - 6, B.promise], // "IN THE BIN" is already the whole screen; the promise line is not
        [B.rule, B.m2], // the rule card says it
        [B.relaxed, B.worked], // the punchline headline is already the screen
        [B.framesWon, B.ai], // "DRAWN FRAMES WON" is on screen
        [B.question, B.end],
      ]}
    />
  </AbsoluteFill>
);

/** The parts burst out, then drain of colour and sink as the claim lands. */
const BinnedParts: React.FC<{ binAt: number }> = ({ binAt }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame - binAt, [0, 30], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        filter: `grayscale(${t * 0.55}) brightness(${1 - 0.12 * t})`,
        transform: `translateY(${t * 46}px) scale(${1 - t * 0.04})`,
        opacity: 1 - t * 0.12,
      }}
    >
      <PartsScatter files={PUPPET_PARTS} at={0} travel={22} size={138} radius={392} y={0.55} />
    </div>
  );
};

/** "IN THE BIN" landing on the spoken word, with the house slam curve. */
const BinSlam: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{ transform: `scale(${slam(frame)})` }}>
      <Headline color={C.red} width={820} fontSize={142} blur={46} glowAlpha={0.9}>
        IN THE BIN
      </Headline>
    </div>
  );
};

/** The kit's size, landing on its spoken word. */
const PieceCount: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <>
      <AtY y={0.155}>
        <div style={{ transform: `scale(${slam(frame)})` }}>
          <Headline color={C.cyan} width={420} fontSize={160} blur={40}>
            26
          </Headline>
        </div>
      </AtY>
      <AtY y={0.235}>
        <Appear delay={10}>
          <Label size={42} color={C.soul} tracking={6}>
            PIECES
          </Label>
        </Appear>
      </AtY>
    </>
  );
};

/** The numbered mistake header this episode repeats three times. */
const MistakeTag: React.FC<{ n: string; text: string }> = ({ n, text }) => (
  <AtY y={0.135}>
    <Appear>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
        <Label size={34} color={C.red} tracking={8}>
          {`MISTAKE ${n}`}
        </Label>
        <Headline color={C.soul} width={760} fontSize={64}>
          {text}
        </Headline>
      </div>
    </Appear>
  </AtY>
);

/** Head dropped on the waist, then snapped to where measuring puts it. */
const ChinGag: React.FC<{ snapAt: number }> = ({ snapAt }) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame - snapAt, [0, 20], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return <HeadOnTorso torso={TORSO} head={HEAD} progress={p} y={0.48} />;
};

/** The working thing being thrown out: a red strike drawn across it. */
const DeleteStrike: React.FC = () => {
  const frame = useCurrentFrame();
  const w = interpolate(frame, [0, 12], [0, 640], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <>
      <div
        style={{
          position: "absolute",
          left: "50%",
          top: "45%",
          transform: "translate(-50%, -50%) rotate(-38deg)",
          width: w,
          height: 14,
          background: C.red,
          borderRadius: 8,
          boxShadow: `0 0 26px ${alpha(C.red, 0.9)}`,
        }}
      />
      <Context y={0.82}>IT WORKED. IT WENT ANYWAY.</Context>
    </>
  );
};
