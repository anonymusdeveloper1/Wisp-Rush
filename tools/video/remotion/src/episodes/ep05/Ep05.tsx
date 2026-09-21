import React from "react";
import { AbsoluteFill, Audio, Img, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C, alpha } from "../../style/palette";
import { F } from "../../style/fonts";
import { Headline, Label, MarkerNote, AtY } from "../../components/Text";
import { Appear } from "../../components/Appear";
import { Dim, GridBackdrop, Matte, Vignette } from "../../components/Backdrops";
import { AiPill, Context, FollowCard, Question, Rule, SeriesTag, WordCard } from "../../components/Furniture";
import { Footage, MusicBed, Sfx } from "../../components/Media";
import { RosterWall } from "../../components/RosterWall";
import { PartsScatter } from "../../components/PartsScatter";
import { FrameStrip, RegistrationDemo } from "../../components/RegistrationDemo";
import { Captions } from "../../components/Captions";
import { CUES } from "./captions";
import { IDLE_FRAMES, RIG_PARTS, ROSTER, STRIP_FRAMES } from "./roster";
import { slam } from "../../style/motion";

/**
 * Devlog #5 — "I deleted six characters from my game."
 *
 * Hook: H6 pattern interrupt, on a new visual treatment (roster wall strike-out).
 * Structure B (design change): the wall -> why rigs lost -> the frame contract -> the experiment
 * that took its rival's name -> what is in the game now -> the registration lesson -> payoff.
 *
 * Every beat frame below comes from the Kokoro line/cue timings, so a visual lands on its spoken
 * word (recipe 6.4). Re-voicing the script moves them: read video/voice/ep05/*.lines.json.
 */

// Beat frames, from video/voice/ep05/ep05_deleted_six.{lines.json,srt}
const B = {
  hook: 0,
  six: 38,          // "I deleted SIX"
  skeleton: 181,    // "Every one of them was a skeleton."
  skeletonWord: 237,
  rig: 313,         // "This one was cut into 55 separate pieces."
  explode: 330,
  slam55: 392,
  joints: 483,      // "Arms, ribbons, every joint animated in code."
  weeks: 644,       // "It took weeks, and it still moved like a puppet."
  puppet: 730,
  switch: 812,      // "So I stopped rigging, and started drawing."
  frames: 946,      // "108 frames per character. 16 animations. No skeleton at all."
  slam108: 949,
  slam16: 1080,
  noSkeleton: 1156,
  experiment: 1279, // "Then the experiment beat the thing it was testing, and took its name."
  nameSwap: 1444,
  tally: 1511,      // "Six retired. Eight left. Every one of them moves now."
  eightLeft: 1568,
  shop: 1620,
  cost: 1729,       // "Here's what cost me the most."
  demo: 1820,       // "12 frames ... beat four beautiful frames that drift."
  fourFrames: 1982,
  lesson: 2122,     // "Not the drawing. The registration."
  registration: 2191,
  ai: 2263,         // AI credit over the payoff
  question: 2552,
  follow: 2680,
  end: 2820,
} as const;

export const EP05_DURATION = B.end;

export const Ep05: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: C.matte }}>
    {/* Voice and bed */}
    <Audio src={staticFile("voice/ep05/ep05_deleted_six_master.wav")} />
    <Sequence from={B.rig} durationInFrames={B.cost - B.rig}>
      <MusicBed durationInFrames={B.cost - B.rig} />
    </Sequence>

    {/* 1. Hook: the wall of everyone the game has ever had */}
    <Sequence from={B.hook} durationInFrames={B.rig}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 42%, ${alpha(C.slate, 0.45)} 0%, ${C.matte} 68%)`,
        }}
      />
      <RosterWall roster={ROSTER} appearAt={2} strikeAt={B.six} tile={190} gap={16} y={0.5} />
      <SeriesTag episode={5} />
      <Sequence from={B.skeletonWord - B.hook}>
        <AtY y={0.845}>
          <Appear>
            <MarkerNote size={58} rotate={-4} color={C.red}>
              every one was a skeleton
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="ui_confirm" db={-12} />
      <Sequence from={B.six}>
        <Sfx id="slice" db={-10} />
      </Sequence>
      <Sequence from={B.six + 6}>
        <Sfx id="player_dissolve" db={-14} />
      </Sequence>
      <Sequence from={B.skeletonWord}>
        <Sfx id="reaper_windup" db={-13} />
      </Sequence>
    </Sequence>

    {/* 2. One rig, taken apart: 55 pieces */}
    <Sequence from={B.rig} durationInFrames={B.switch - B.rig}>
      <GridBackdrop />
      {/* The assembled character, before she comes apart. */}
      <Sequence durationInFrames={B.explode - B.rig + 14}>
        <AtY y={0.46}>
          <Appear>
            <Img
              src={staticFile("graphics/roster/r11_ilyra_rig.png")}
              style={{ width: 560, height: 560, objectFit: "contain" }}
            />
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.explode - B.rig}>
        <PartsScatter files={RIG_PARTS} at={0} travel={30} size={104} radius={410} y={0.53} />
      </Sequence>
      {/* The count sits above the cloud, not in it — the parts are the evidence, not the backdrop. */}
      <Sequence from={B.slam55 - B.rig}>
        <Slam55 />
      </Sequence>
      <Sequence from={B.weeks - B.rig} durationInFrames={B.puppet - B.weeks}>
        <AtY y={0.845} x={0.3}>
          <Appear life={B.puppet - B.weeks}>
            <MarkerNote size={62} rotate={-8} color={C.amber}>
              weeks. each.
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.puppet - B.rig}>
        <AtY y={0.845} x={0.6}>
          <Appear>
            <MarkerNote size={56} rotate={5} color={C.red}>
              still moved like a puppet
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.explode - B.rig}>
        <Sfx id="dash" db={-10} />
      </Sequence>
      <Sequence from={B.slam55 - B.rig}>
        <Sfx id="reaper_hit" db={-11} />
      </Sequence>
      <Sequence from={B.joints - B.rig}>
        <Sfx id="slice_step1" db={-13} />
      </Sequence>
      <Sequence from={B.puppet - B.rig}>
        <Sfx id="player_damage" db={-13} />
      </Sequence>
    </Sequence>

    {/* 3. The switch: frames instead of bones */}
    <Sequence from={B.switch} durationInFrames={B.experiment - B.switch}>
      <GridBackdrop />
      <Sequence from={0} durationInFrames={B.frames - B.switch}>
        <AtY y={0.46}>
          <Appear>
            <Headline width={780} color={C.soul}>
              {"STOPPED RIGGING.\nSTARTED DRAWING."}
            </Headline>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.frames - B.switch}>
        <FrameStrip frames={STRIP_FRAMES} y={0.44} size={196} speed={4.2} />
      </Sequence>
      <Sequence from={B.slam108 - B.switch} durationInFrames={B.slam16 - B.slam108}>
        <NumberBeat value="108" label="FRAMES PER CHARACTER" y={0.655} />
      </Sequence>
      <Sequence from={B.slam16 - B.switch}>
        <NumberBeat value="16" label="ANIMATIONS EACH" y={0.655} />
      </Sequence>
      <Sequence from={B.noSkeleton - B.switch}>
        <AtY y={0.845}>
          <Appear>
            <Label size={44} color={C.cyan} tracking={4}>
              NO SKELETON AT ALL
            </Label>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="ui_back" db={-12} />
      <Sequence from={B.frames - B.switch}>
        <Sfx id="dash" db={-11} />
      </Sequence>
      <Sequence from={B.slam108 - B.switch}>
        <Sfx id="slice_step3" db={-11} />
      </Sequence>
      <Sequence from={B.slam16 - B.switch}>
        <Sfx id="slice_step5" db={-12} />
      </Sequence>
    </Sequence>

    {/* 4. The experiment took its rival's name */}
    <Sequence from={B.experiment} durationInFrames={B.tally - B.experiment}>
      <GridBackdrop />
      <NameSwap swapAt={B.nameSwap - B.experiment} />
      <Sequence from={B.nameSwap - B.experiment}>
        <Sfx id="level_up" db={-11} />
      </Sequence>
    </Sequence>

    {/* 5. The tally, then what is actually in the game */}
    <Sequence from={B.tally} durationInFrames={B.cost - B.tally}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 42%, ${alpha(C.slate, 0.45)} 0%, ${C.matte} 68%)`,
        }}
      />
      <RosterWall
        roster={ROSTER}
        appearAt={0}
        strikeAt={0}
        removeAt={4}
        tile={190}
        gap={16}
        y={0.46}
        stagger={0}
      />
      <Sequence from={B.eightLeft - B.tally}>
        <AtY y={0.795}>
          <Appear>
            <Headline color={C.cyan} width={560} fontSize={104}>
              8 LEFT
            </Headline>
          </Appear>
        </AtY>
      </Sequence>
      {/* Cut to the real Shop: the carousel's eight dots are the claim, shown not said. */}
      <Sequence from={B.shop - B.tally}>
        <Footage src="footage/tour_menus.mp4" startFrom={520} volume={0.06} />
        <Vignette strength={0.5} />
      </Sequence>
      <Sfx id="slice" db={-11} />
      <Sequence from={B.eightLeft - B.tally}>
        <Sfx id="level_up" db={-11} />
      </Sequence>
      <Sequence from={B.shop - B.tally}>
        <Sfx id="ui_confirm" db={-12} />
      </Sequence>
    </Sequence>

    {/* 6. The lesson, as a black beat card then a diagram */}
    <Sequence from={B.cost} durationInFrames={B.demo - B.cost}>
      <WordCard word={"WHAT IT\nCOST ME"} color={C.soul} width={760} />
      <Sfx id="reaper_hit" db={-11} />
    </Sequence>

    <Sequence from={B.demo} durationInFrames={B.lesson - B.demo}>
      <GridBackdrop />
      <AtY y={0.155}>
        <Appear>
          <Label size={38} color={C.label} tracking={6}>
            SAME CHARACTER. SAME ART.
          </Label>
        </Appear>
      </AtY>
      <RegistrationDemo frames={IDLE_FRAMES} leftCount={12} rightCount={4} hold={7} drift={52} />
      <Sequence from={B.fourFrames - B.demo}>
        <AtY y={0.85} x={0.7}>
          <Appear>
            <MarkerNote size={52} rotate={5} color={C.red}>
              reads as a flip-book
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Context y={0.925}>THE DRIFT ON THE RIGHT IS ADDED TO SHOW THE EFFECT</Context>
      <Sfx id="slice_step1" db={-13} />
      <Sequence from={B.fourFrames - B.demo}>
        <Sfx id="ui_error" db={-15} />
      </Sequence>
    </Sequence>

    <Sequence from={B.lesson} durationInFrames={B.ai - B.lesson}>
      <Matte />
      <AtY y={0.42}>
        <Appear>
          <Headline color={C.soul} width={700} fontSize={92}>
            NOT THE DRAWING.
          </Headline>
        </Appear>
      </AtY>
      <Sequence from={B.registration - B.lesson}>
        <AtY y={0.53}>
          <Appear>
            <Headline color={C.cyan} width={800} fontSize={112}>
              THE REGISTRATION.
            </Headline>
          </Appear>
        </AtY>
        <Rule y={0.6} width={0.66} color={C.cyan} delay={8} />
      </Sequence>
      <Sequence from={B.registration - B.lesson}>
        <Sfx id="slice_step5" db={-11} />
      </Sequence>
    </Sequence>

    {/* 7. Payoff: the game, the credit, the question, the follow card */}
    <Sequence from={B.ai} durationInFrames={B.end - B.ai}>
      <Footage src="footage/tour_menus.mp4" startFrom={2160} volume={0.12} />
      <Vignette strength={0.45} />
      <Sequence durationInFrames={B.question - B.ai}>
        <AiPill y={0.2} />
      </Sequence>
      <Sequence from={B.question - B.ai} durationInFrames={B.follow - B.question}>
        <Dim keys={[[0, 0], [10, 0.55]]} />
        <Question top="WHICH ONE" bottom="SHOULD I DRAW?" />
      </Sequence>
      <Sequence from={B.follow - B.ai}>
        <FollowCard next={6} />
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

    {/* Captions last, always on top */}
    <Captions
      cues={CUES}
      hide={[
        [B.slam108 - 6, B.noSkeleton + 70], // the numbers are already huge on screen
        [B.cost, B.demo], // the black beat card says it
        [B.lesson, B.ai], // the two-line lesson card says it
        [B.question, B.end], // the question and follow card say it
      ]}
      lift={[[B.tally, B.cost, 0.66]]}
    />
  </AbsoluteFill>
);

/** The 55 landing hard on its spoken word, held above the cloud of parts so both stay readable. */
const Slam55: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <>
      <AtY y={0.145}>
        <div style={{ transform: `scale(${slam(frame)})` }}>
          <Headline color={C.red} width={420} fontSize={168} blur={44} glowAlpha={0.9}>
            55
          </Headline>
        </div>
      </AtY>
      <Sequence from={10}>
        <AtY y={0.225}>
          <Appear>
            <Label size={44} color={C.soul} tracking={6}>
              SEPARATE PIECES
            </Label>
          </Appear>
        </AtY>
      </Sequence>
    </>
  );
};

/** A number slamming in above its label — the series' standard "here is the figure" beat. */
const NumberBeat: React.FC<{ value: string; label: string; y: number }> = ({ value, label, y }) => {
  const frame = useCurrentFrame();
  return (
    <>
      <AtY y={y}>
        <div style={{ transform: `scale(${slam(frame)})` }}>
          <Headline color={C.cyan} width={560} fontSize={158} blur={40}>
            {value}
          </Headline>
        </div>
      </AtY>
      <AtY y={y + 0.075}>
        <Appear delay={8}>
          <Label size={38} color={C.label} tracking={6}>
            {label}
          </Label>
        </Appear>
      </AtY>
    </>
  );
};

/**
 * The twist, as a card: the experiment built only to compare took the name of the thing it was
 * tested against. ILYRA 2 becomes ILYRA, with the retired rig struck out beside it.
 */
const NameSwap: React.FC<{ swapAt: number }> = ({ swapAt }) => {
  const frame = useCurrentFrame();
  const swapped = frame >= swapAt;
  const fade = interpolate(frame - swapAt, [0, 14], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <>
      <AtY y={0.19}>
        <Appear>
          <Label size={38} color={C.label} tracking={6}>
            THE TEST BEAT WHAT IT WAS TESTING
          </Label>
        </Appear>
      </AtY>
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 40,
        }}
      >
        <NameCard
          file="r11_ilyra_rig.png"
          title="ILYRA"
          sub="BONE RIG"
          accent={C.red}
          struck
          dim={1 - fade * 0.55}
        />
        <NameCard
          file="r12_ilyra2.png"
          title={swapped ? "ILYRA" : "ILYRA 2"}
          sub={swapped ? "PROMOTED" : "THE EXPERIMENT"}
          accent={C.cyan}
          pulse={swapped ? fade : 0}
        />
      </div>
    </>
  );
};

const NameCard: React.FC<{
  file: string;
  title: string;
  sub: string;
  accent: string;
  struck?: boolean;
  dim?: number;
  pulse?: number;
}> = ({ file, title, sub, accent, struck, dim = 1, pulse = 0 }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
    <div
      style={{
        width: 420,
        height: 500,
        position: "relative",
        borderRadius: 22,
        overflow: "hidden",
        background: `linear-gradient(160deg, ${alpha(C.slate, 0.4)}, ${alpha(C.deep, 0.97)})`,
        border: `3px solid ${alpha(accent, 0.55 + pulse * 0.45)}`,
        boxShadow: `0 0 ${28 + pulse * 40}px ${alpha(accent, 0.22 + pulse * 0.4)}`,
        opacity: dim,
      }}
    >
      <Img
        src={staticFile(`graphics/roster/${file}`)}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "contain",
          padding: 20,
          filter: struck ? "grayscale(1) brightness(0.55)" : undefined,
        }}
      />
      {struck ? (
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div
            style={{
              width: 560,
              height: 10,
              background: C.red,
              transform: "rotate(-42deg)",
              boxShadow: `0 0 20px ${alpha(C.red, 0.9)}`,
            }}
          />
        </div>
      ) : null}
    </div>
    <div style={{ textAlign: "center" }}>
      <div
        style={
          {
            fontFamily: F.display,
            fontSize: 62,
            color: accent,
            WebkitTextStroke: `7px ${C.outline}`,
            paintOrder: "stroke fill",
            textShadow: `0 0 24px ${alpha(accent, 0.7)}`,
          } as React.CSSProperties
        }
      >
        {title}
      </div>
      <Label size={27} color={C.label} tracking={5}>
        {sub}
      </Label>
    </div>
  </div>
);
