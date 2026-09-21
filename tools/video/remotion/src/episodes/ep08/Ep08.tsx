import React from "react";
import { AbsoluteFill, Audio, Img, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C, alpha } from "../../style/palette";
import { F } from "../../style/fonts";
import { Headline, Label, MarkerNote, AtY } from "../../components/Text";
import { Appear } from "../../components/Appear";
import { Dim, GridBackdrop, Matte, Vignette } from "../../components/Backdrops";
import { AiPill, Context, FollowCard, Question, Rule, SeriesTag } from "../../components/Furniture";
import { Footage, MusicBed, Sfx } from "../../components/Media";
import { BarCompare, MemoryMeter, NumbersRow, StepCard } from "../../components/NumbersBoard";
import { Captions } from "../../components/Captions";
import { CUES } from "./captions";
import { ROSTER } from "../ep05/roster";
import { slam } from "../../style/motion";

/**
 * Devlog #8 — "858 megabytes for a shop screen."
 *
 * Hook: H5 "I know your pain", on the question/challenge treatment — the one visual treatment in
 * recipe §3.1 that no finished episode has used. Rotation across this batch: EP05 H6 + roster
 * wall, EP06 H1 + speed flex, EP07 H8 + counter slam, EP08 H5 + question/challenge.
 *
 * Structure A (explainer), the shape of the owner-approved EP02: show the problem in the game,
 * explain it with motion graphics, show the fix, then the measured before/after. The closing beat
 * is deliberately not a victory — the DEVLOG records that Home still builds in ~261 ms against
 * ~37 ms before this character existed, so the episode says "still not free".
 */

// Beat frames, from video/voice/ep08/ep08_858_megabytes.{lines.json,srt}
const B = {
  hook: 0,
  pain: 6, // "If your game has ever run out of memory,"
  mine: 189, // "Mine wanted"
  slam858: 231, // "858 MB."
  forAShop: 349, // "For a shop screen."
  trap: 459, // "Here's the trap."
  onDisk: 502, // "On disk, my character art is a few megabytes."
  vram: 674, // "In video memory, a texture costs its full uncompressed size."
  always: 902, // "Always."
  thirteen: 940, // "Thirteen animated characters on one screen"
  gigabyte: 1086, // "is nearly a gigabyte."
  fixes: 1196, // "So, three fixes."
  one: 1270, // "One. Every character is split in two."
  two: 1523, // "Two. Only the card you're looking at is alive."
  eightOfEight: 1668, // "Eight of eight, down to two."
  three: 1767, // "Three. No sheet passes 4096 pixels."
  px4096: 1849,
  guarantees: 1970, // "That is what every phone guarantees."
  result: 2131, // "Opening the home screen went from 695 ms to 261 ms."
  from695: 2244,
  to261: 2387,
  honest: 2491, // "Still not free. But it opens."
  ai: 2618,
  question: 2907,
  follow: 3010,
  end: 3160,
} as const;

export const EP08_DURATION = B.end;

export const Ep08: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: C.matte }}>
    <Audio src={staticFile("voice/ep08/ep08_858_megabytes_master.wav")} />
    <Sequence from={B.trap} durationInFrames={B.result - B.trap}>
      <MusicBed durationInFrames={B.result - B.trap} />
    </Sequence>

    {/* 1. Hook: the question over the real screen, then the answer nobody expects */}
    <Sequence from={B.hook} durationInFrames={B.trap}>
      <Footage src="footage/tour_menus.mp4" startFrom={520} volume={0.05} blur={[[0, 0], [180, 0], [230, 16]]} />
      <Dim keys={[[0, 0.35], [180, 0.35], [231, 0.86]]} />
      <SeriesTag episode={8} y={0.135} />
      <Sequence durationInFrames={B.slam858}>
        <AtY y={0.42}>
          <Appear>
            <Headline color={C.soul} width={800} fontSize={82}>
              {"HOW MUCH MEMORY\nIS A SHOP SCREEN?"}
            </Headline>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.slam858}>
        <AtY y={0.44}>
          <Slam858 />
        </AtY>
      </Sequence>
      <Sequence from={B.forAShop}>
        <AtY y={0.565}>
          <Appear>
            <Label size={44} color={C.soul} tracking={7}>
              FOR A SHOP SCREEN
            </Label>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="ui_confirm" db={-13} />
      <Sequence from={B.slam858}>
        <Sfx id="reaper_hit" db={-11} />
      </Sequence>
      <Sequence from={B.forAShop}>
        <Sfx id="player_dissolve" db={-14} />
      </Sequence>
    </Sequence>

    {/* 2. The trap: disk size is not memory size */}
    <Sequence from={B.trap} durationInFrames={B.thirteen - B.trap}>
      <GridBackdrop />
      <AtY y={0.16}>
        <Appear>
          <Label size={40} color={C.label} tracking={6}>
            SAME ART. TWO PLACES.
          </Label>
        </Appear>
      </AtY>
      <Sequence from={B.onDisk - B.trap}>
        <BarCompare
          y={0.46}
          left={{ label: "ON DISK", value: "A FEW MB", fraction: 0.06, color: C.cyan }}
          right={{ label: "IN VIDEO MEMORY", value: "FULL SIZE", fraction: 1, color: C.red }}
          rightAt={B.vram - B.onDisk}
        />
      </Sequence>
      <Sequence from={B.always - B.trap}>
        <AtY y={0.73} x={0.56}>
          <Appear>
            <MarkerNote size={62} rotate={-7} color={C.amber}>
              uncompressed. always.
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.onDisk - B.trap}>
        <Sfx id="slice_step1" db={-13} />
      </Sequence>
      <Sequence from={B.vram - B.trap}>
        <Sfx id="reaper_windup" db={-12} />
      </Sequence>
      <Sequence from={B.always - B.trap}>
        <Sfx id="wall_impact" db={-12} />
      </Sequence>
    </Sequence>

    {/* 3. Thirteen of them, filling the meter */}
    <Sequence from={B.thirteen} durationInFrames={B.fixes - B.thirteen}>
      <GridBackdrop />
      <AtY y={0.145}>
        <Appear>
          <Label size={40} color={C.label} tracking={6}>
            THIRTEEN, ALL AWAKE AT ONCE
          </Label>
        </Appear>
      </AtY>
      <FillingRoster gigabyteAt={B.gigabyte - B.thirteen} />
      <Sfx id="slice_step3" db={-13} />
      <Sequence from={B.gigabyte - B.thirteen}>
        <Sfx id="reaper_hit" db={-11} />
      </Sequence>
    </Sequence>

    {/* 4. Three fixes, as step cards that stay up */}
    <Sequence from={B.fixes} durationInFrames={B.result - B.fixes}>
      <GridBackdrop />
      <AtY y={0.135}>
        <Appear>
          <Headline color={C.soul} width={620} fontSize={76}>
            THREE FIXES
          </Headline>
        </Appear>
      </AtY>
      <Sequence from={B.one - B.fixes}>
        <StepCard
          n={1}
          title="SPLIT IN TWO"
          body={"A run never loads\nthe menu art"}
          x={0.19}
          y={0.36}
        />
      </Sequence>
      <Sequence from={B.two - B.fixes}>
        <StepCard
          n={2}
          title="LAZY CARDS"
          body={"Only the card you\nare looking at is live"}
          x={0.5}
          y={0.36}
        />
      </Sequence>
      <Sequence from={B.three - B.fixes}>
        <StepCard
          n={3}
          title="4096 CAP"
          body={"The size every phone\nis guaranteed to take"}
          x={0.81}
          y={0.36}
        />
      </Sequence>
      <Sequence from={B.eightOfEight - B.fixes}>
        <LiveCardCount />
      </Sequence>
      <Sequence from={B.px4096 - B.fixes}>
        <AtY y={0.755}>
          <Appear>
            <Headline color={C.cyan} width={620} fontSize={104}>
              4096 PX
            </Headline>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.guarantees - B.fixes}>
        <AtY y={0.845}>
          <Appear>
            <Label size={38} color={C.label} tracking={5}>
              THE FLOOR EVERY PHONE GUARANTEES
            </Label>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.one - B.fixes}>
        <Sfx id="slice_step1" db={-12} />
      </Sequence>
      <Sequence from={B.two - B.fixes}>
        <Sfx id="slice_step3" db={-12} />
      </Sequence>
      <Sequence from={B.eightOfEight - B.fixes}>
        <Sfx id="level_up" db={-12} />
      </Sequence>
      <Sequence from={B.three - B.fixes}>
        <Sfx id="slice_step5" db={-12} />
      </Sequence>
      <Sequence from={B.px4096 - B.fixes}>
        <Sfx id="ui_confirm" db={-13} />
      </Sequence>
    </Sequence>

    {/* 5. What it actually bought, and what it did not */}
    <Sequence from={B.result} durationInFrames={B.ai - B.result}>
      <GridBackdrop />
      <AtY y={0.16}>
        <Appear>
          <Label size={38} color={C.label} tracking={6}>
            OPENING THE HOME SCREEN
          </Label>
        </Appear>
      </AtY>
      <Sequence from={B.from695 - B.result}>
        <NumbersRow
          label="BUILD TIME"
          before="695 MS"
          after="261 MS"
          y={0.42}
          at={{ label: 0, before: 6, strike: 96, after: 143 }}
          beforeSize={86}
          afterSize={98}
        />
      </Sequence>
      <Context y={0.55}>MEASURED ON A GALAXY S24</Context>
      <Sequence from={B.honest - B.result}>
        <AtY y={0.695}>
          <Appear>
            <Headline color={C.soul} width={700} fontSize={78}>
              STILL NOT FREE.
            </Headline>
          </Appear>
        </AtY>
        <AtY y={0.785}>
          <Appear delay={12}>
            <Headline color={C.cyan} width={640} fontSize={86}>
              BUT IT OPENS.
            </Headline>
          </Appear>
        </AtY>
        <Rule y={0.845} width={0.52} color={C.cyan} delay={20} />
      </Sequence>
      <Sequence from={B.from695 - B.result}>
        <Sfx id="slice_step1" db={-12} />
      </Sequence>
      <Sequence from={B.from695 - B.result + 96}>
        <Sfx id="slice" db={-12} />
      </Sequence>
      <Sequence from={B.from695 - B.result + 143}>
        <Sfx id="level_up" db={-11} />
      </Sequence>
      <Sequence from={B.honest - B.result}>
        <Sfx id="ui_back" db={-13} />
      </Sequence>
    </Sequence>

    {/* 6. Payoff, credit, question, follow */}
    <Sequence from={B.ai} durationInFrames={B.end - B.ai}>
      <Footage src="footage/tour_menus.mp4" startFrom={2160} volume={0.14} />
      <Vignette strength={0.45} />
      <Sequence durationInFrames={B.question - B.ai}>
        <AiPill y={0.2} />
      </Sequence>
      <Sequence from={B.question - B.ai} durationInFrames={B.follow - B.question}>
        <Dim keys={[[0, 0], [10, 0.55]]} />
        <Question top="WHAT SHOULD I" bottom="OPTIMISE NEXT?" />
      </Sequence>
      <Sequence from={B.follow - B.ai}>
        <FollowCard next={9} />
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
        [B.slam858 - 6, B.trap], // the number and its label own the screen
        [B.gigabyte, B.fixes], // the NEARLY A GIGABYTE headline says it
        [B.px4096 - 6, B.result], // "4096 PX" is already huge
        [B.from695 - 6, B.ai], // the board and the two-line card say it
        [B.question, B.end],
      ]}
    />
  </AbsoluteFill>
);

/** The number the episode opens on. Red, because it is the cost, not the win. */
const Slam858: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{ transform: `scale(${slam(frame)})` }}>
      <Headline color={C.red} width={820} fontSize={186} blur={50} glowAlpha={0.92}>
        858 MB
      </Headline>
    </div>
  );
};

/** Thirteen portraits waking one after another, with a meter filling behind them. */
const FillingRoster: React.FC<{ gigabyteAt: number }> = ({ gigabyteAt }) => {
  const frame = useCurrentFrame();
  const lit = Math.min(13, Math.floor(frame / 9));
  const fill = Math.min(1, lit / 13);
  const mb = Math.round(fill * 858);
  return (
    <>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: "37%",
          transform: "translateY(-50%)",
          display: "flex",
          flexWrap: "wrap",
          justifyContent: "center",
          gap: 14,
          padding: "0 90px",
        }}
      >
        {ROSTER.map((entry, i) => {
          const on = i < lit;
          return (
            <div
              key={entry.file}
              style={{
                width: 142,
                height: 142,
                borderRadius: 14,
                overflow: "hidden",
                background: alpha(C.deep, 0.85),
                border: `2px solid ${alpha(on ? C.red : C.cyan, on ? 0.8 : 0.16)}`,
                boxShadow: on ? `0 0 24px ${alpha(C.red, 0.3)}` : undefined,
              }}
            >
              <Img
                src={staticFile(`graphics/roster/${entry.file}`)}
                style={{
                  width: "100%",
                  height: "100%",
                  objectFit: "contain",
                  padding: 8,
                  filter: on ? undefined : "grayscale(1) brightness(0.35)",
                }}
              />
            </div>
          );
        })}
      </div>
      <MemoryMeter fill={fill} value={`${mb} MB`} y={0.6} />
      {frame >= gigabyteAt ? (
        <AtY y={0.845}>
          <Appear>
            <Headline color={C.red} width={680} fontSize={80} blur={40}>
              NEARLY A GIGABYTE
            </Headline>
          </Appear>
        </AtY>
      ) : null}
    </>
  );
};

/** The live-card count, before and after the lazy build. */
const LiveCardCount: React.FC = () => {
  const frame = useCurrentFrame();
  const swap = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <AtY y={0.6}>
      <div style={{ display: "flex", alignItems: "center", gap: 26 }}>
        <div
          style={{
            fontFamily: F.display,
            fontSize: 92,
            color: C.red,
            opacity: 1 - swap * 0.55,
            textDecoration: "line-through",
            textDecorationThickness: 8,
            textShadow: `0 0 24px ${alpha(C.red, 0.7)}`,
          }}
        >
          8 / 8
        </div>
        <div style={{ fontFamily: F.display, fontSize: 60, color: C.soul, opacity: swap }}>→</div>
        <div
          style={{
            fontFamily: F.display,
            fontSize: 104,
            color: C.cyan,
            opacity: swap,
            transform: `scale(${0.8 + swap * 0.2})`,
            textShadow: `0 0 30px ${alpha(C.cyan, 0.85)}`,
          }}
        >
          2 / 8
        </div>
      </div>
      <Label size={32} color={C.label} tracking={5} style={{ marginTop: 10 }}>
        LIVE PREVIEWS
      </Label>
    </AtY>
  );
};
