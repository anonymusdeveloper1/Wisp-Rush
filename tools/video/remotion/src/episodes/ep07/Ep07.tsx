import React from "react";
import { AbsoluteFill, Audio, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C, alpha } from "../../style/palette";
import { Headline, Label, MarkerNote, AtY } from "../../components/Text";
import { Appear } from "../../components/Appear";
import { Dim, GridBackdrop, Matte, Vignette } from "../../components/Backdrops";
import { AiPill, Context, FollowCard, Question, Rule, SeriesTag } from "../../components/Furniture";
import { Footage, Sfx } from "../../components/Media";
import { SoundPills, SpectrumBars, StepStairs, WaveLane } from "../../components/Waveform";
import { Captions } from "../../components/Captions";
import { CUES } from "./captions";
import { LAYERS, SFX_IDS } from "./assets";
import { slam } from "../../style/motion";

/**
 * Devlog #7 — "Zero sound files."
 *
 * Hook: H8 unexpected number, on a counter-slam treatment over a live spectrum of the game's own
 * audio. Neither repeats EP05 (H6 + roster wall) or EP06 (H1 + speed flex).
 *
 * Structure A (explainer). The episode's strongest move is that it demonstrates rather than
 * claims: the bars are the real spectrum of the game's synthesized output, and the counting beat
 * actually plays slice_step1..5 so the viewer hears the pitch climb.
 *
 * There is no music bed: the music IS the subject here, so it enters as its own beat instead.
 */

// Beat frames, from video/voice/ep07/ep07_zero_sound_files.{lines.json,srt}
const B = {
  hook: 0,
  zero: 4, // "Zero."
  soundFiles: 75, // "sound files"
  hearing: 168, // "You're hearing it anyway."
  maths: 265, // "Every sound is written as maths, and rendered the moment the game starts."
  effects: 498, // "19 effects."
  slice: 556, // "Plus one slice,"
  pitched: 614, // "pitched up a step for every extra kill in a dash."
  listen: 815, // "Listen."
  count: [856, 870, 884, 898, 912], // "One, two, three, four, five."
  music: 957, // "The music is three layers fading against each other."
  pad: 1127, // "A pad underneath."
  pulse: 1186, // "A pulse that follows your combo."
  boss: 1298, // "A boss layer when something big arrives."
  cost: 1473, // "All of it costs one and a third seconds on my phone,"
  seconds: 1530,
  megabytes: 1654, // "and zero megabytes in the download."
  meta: 1806, // "And here's the part I like."
  thisVideo: 1884, // "Every sound in this video is the game's own synth."
  ai: 2087,
  question: 2376,
  follow: 2470,
  end: 2620,
} as const;

export const EP07_DURATION = B.end;

export const Ep07: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: C.matte }}>
    <Audio src={staticFile("voice/ep07/ep07_zero_sound_files_master.wav")} />

    {/* 1. Hook: the number, over the real spectrum of the thing it is counting */}
    <Sequence from={B.hook} durationInFrames={B.maths}>
      <Matte />
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 62%, ${alpha(C.cyan, 0.1)} 0%, ${C.matte} 66%)`,
        }}
      />
      <SeriesTag episode={7} y={0.12} />
      <Sequence from={B.zero}>
        <AtY y={0.42}>
          <ZeroSlam />
        </AtY>
      </Sequence>
      <Sequence from={B.soundFiles}>
        <AtY y={0.565}>
          <Appear>
            <Label size={48} color={C.soul} tracking={8}>
              SOUND FILES
            </Label>
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.hearing}>
        <AtY y={0.655}>
          <Appear>
            <SpectrumBars src="audio/game/music/bed_run.wav" bars={30} width={900} height={190} gain={1} />
          </Appear>
        </AtY>
        <AtY y={0.855}>
          <Appear delay={10}>
            <MarkerNote size={54} rotate={-4} color={C.amber}>
              you're hearing it right now
            </MarkerNote>
          </Appear>
        </AtY>
      </Sequence>
      {/* The bed is the demonstration, so it plays loud enough to be the point. */}
      <Sequence from={B.hearing}>
        <Audio src={staticFile("audio/game/music/bed_run.wav")} volume={10 ** (-15 / 20)} />
      </Sequence>
      <Sequence from={B.zero}>
        <Sfx id="reaper_hit" db={-11} />
      </Sequence>
      <Sequence from={B.soundFiles}>
        <Sfx id="slice_step1" db={-13} />
      </Sequence>
    </Sequence>

    {/* 2. What "synthesized" means: a wave built from numbers, at boot */}
    <Sequence from={B.maths} durationInFrames={B.effects - B.maths}>
      <GridBackdrop />
      <AtY y={0.175}>
        <Appear>
          <Label size={40} color={C.label} tracking={6}>
            NO FILES. JUST MATHS.
          </Label>
        </Appear>
      </AtY>
      <OscillatorDiagram />
      <Sequence from={140}>
        <AtY y={0.815}>
          <Appear>
            <Label size={42} color={C.cyan} tracking={4}>
              RENDERED THE MOMENT THE GAME STARTS
            </Label>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="soul_pulse" db={-14} />
      <Sequence from={140}>
        <Sfx id="slice_step3" db={-13} />
      </Sequence>
    </Sequence>

    {/* 3. The inventory: 19 effect ids, then the one that gets pitched */}
    <Sequence from={B.effects} durationInFrames={B.listen - B.effects}>
      <GridBackdrop />
      <EffectCount />
      <AtY y={0.52}>
        <SoundPills ids={SFX_IDS} litAt={B.slice - B.effects} lit={["slice"]} />
      </AtY>
      <Sequence from={B.pitched - B.effects}>
        <AtY y={0.845}>
          <Appear>
            <Headline color={C.cyan} width={740} fontSize={58}>
              {"ONE SLICE,\nPITCHED PER KILL"}
            </Headline>
          </Appear>
        </AtY>
      </Sequence>
      <Sfx id="slice_step3" db={-12} />
      <Sequence from={B.slice - B.effects}>
        <Sfx id="slice" db={-12} />
      </Sequence>
    </Sequence>

    {/* 4. The demonstration: five kills, five pitches, actually played */}
    <Sequence from={B.listen} durationInFrames={B.music - B.listen}>
      <GridBackdrop />
      <AtY y={0.16}>
        <Appear>
          <Headline color={C.soul} width={460} fontSize={92}>
            LISTEN
          </Headline>
        </Appear>
      </AtY>
      <Stairs counts={B.count.map((f) => f - B.listen)} />
      {B.count.map((f, i) => (
        <Sequence key={i} from={f - B.listen}>
          <Sfx id={`slice_step${i + 1}`} db={-7} />
        </Sequence>
      ))}
      <Context y={0.9}>THE REAL SOUND, AT THE REAL PITCHES</Context>
    </Sequence>

    {/* 5. Three music layers, each its own lane */}
    <Sequence from={B.music} durationInFrames={B.cost - B.music}>
      <GridBackdrop />
      <AtY y={0.155}>
        <Appear>
          <Label size={40} color={C.label} tracking={6}>
            THE MUSIC IS THREE LAYERS
          </Label>
        </Appear>
      </AtY>
      <Lanes padAt={B.pad - B.music} pulseAt={B.pulse - B.music} bossAt={B.boss - B.music} />
      <Sequence from={B.pad - B.music}>
        <Sfx id="soul_pulse" db={-14} />
      </Sequence>
      <Sequence from={B.pulse - B.music}>
        <Sfx id="slice_step3" db={-14} />
      </Sequence>
      <Sequence from={B.boss - B.music}>
        <Sfx id="reaper_appear" db={-13} />
      </Sequence>
    </Sequence>

    {/* 6. What it costs: the two numbers that make the whole idea worth it */}
    <Sequence from={B.cost} durationInFrames={B.meta - B.cost}>
      <GridBackdrop />
      <AtY y={0.175}>
        <Appear>
          <Label size={38} color={C.label} tracking={6}>
            WHAT IT COSTS
          </Label>
        </Appear>
      </AtY>
      <Sequence from={B.seconds - B.cost}>
        <CostRow value="1.33 s" label="TO BUILD EVERY SOUND, AT BOOT" y={0.38} />
      </Sequence>
      <Sequence from={B.megabytes - B.cost}>
        <CostRow value="0 MB" label="OF AUDIO IN THE DOWNLOAD" y={0.6} />
        <Rule y={0.7} width={0.6} color={C.cyan} delay={12} />
      </Sequence>
      <Context y={0.83}>MEASURED ON A GALAXY S24</Context>
      <Sequence from={B.seconds - B.cost}>
        <Sfx id="slice_step3" db={-11} />
      </Sequence>
      <Sequence from={B.megabytes - B.cost}>
        <Sfx id="level_up" db={-11} />
      </Sequence>
    </Sequence>

    {/* 7. The meta beat: this video is scored with the game's own synth */}
    <Sequence from={B.meta} durationInFrames={B.ai - B.meta}>
      <Matte />
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 50%, ${alpha(C.cyan, 0.12)} 0%, ${C.matte} 68%)`,
        }}
      />
      <Sequence from={B.thisVideo - B.meta}>
        <AtY y={0.4}>
          <Appear>
            <Headline color={C.soul} width={800} fontSize={76}>
              {"EVERY SOUND IN\nTHIS VIDEO"}
            </Headline>
          </Appear>
        </AtY>
        <AtY y={0.545}>
          <Appear delay={16}>
            <Headline color={C.cyan} width={780} fontSize={92}>
              IS THE GAME
            </Headline>
          </Appear>
        </AtY>
        <AtY y={0.71}>
          <Appear delay={24}>
            <SpectrumBars src="audio/game/music/bed_boss.wav" bars={34} width={900} height={170} gain={1} />
          </Appear>
        </AtY>
      </Sequence>
      <Sequence from={B.thisVideo - B.meta}>
        <Audio src={staticFile("audio/game/music/bed_boss.wav")} volume={10 ** (-17 / 20)} />
        <Sfx id="ui_purchase" db={-12} />
      </Sequence>
    </Sequence>

    {/* 8. Payoff, credit, question, follow */}
    <Sequence from={B.ai} durationInFrames={B.end - B.ai}>
      <Footage src="footage/tour_menus.mp4" startFrom={2160} volume={0.16} />
      <Vignette strength={0.45} />
      <Sequence durationInFrames={B.question - B.ai}>
        <AiPill y={0.2} />
      </Sequence>
      <Sequence from={B.question - B.ai} durationInFrames={B.follow - B.question}>
        <Dim keys={[[0, 0], [10, 0.55]]} />
        <Question top="WHAT SHOULD I" bottom="BUILD NEXT?" />
      </Sequence>
      <Sequence from={B.follow - B.ai}>
        <FollowCard next={8} />
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
        [B.zero - 4, B.hearing], // the 0 and its label are the whole screen
        [B.listen, B.music], // the counting beat is meant to be heard, not read
        [B.cost, B.meta], // the cost rows say it
        [B.thisVideo, B.ai], // the meta card says it
        [B.question, B.end],
      ]}
    />
  </AbsoluteFill>
);

/** The number the whole episode hangs on. */
const ZeroSlam: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{ transform: `scale(${slam(frame)})` }}>
      <Headline color={C.cyan} width={420} fontSize={300} blur={54} glowAlpha={0.95}>
        0
      </Headline>
    </div>
  );
};

const EffectCount: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <>
      <AtY y={0.15}>
        <div style={{ transform: `scale(${slam(frame)})` }}>
          <Headline color={C.cyan} width={400} fontSize={158} blur={40}>
            19
          </Headline>
        </div>
      </AtY>
      <AtY y={0.235}>
        <Appear delay={10}>
          <Label size={42} color={C.soul} tracking={6}>
            EFFECTS, ALL SYNTHESIZED
          </Label>
        </Appear>
      </AtY>
    </>
  );
};

/** A wave drawn from a formula, growing left to right — what "rendered at boot" looks like. */
const OscillatorDiagram: React.FC = () => {
  const frame = useCurrentFrame();
  const drawn = interpolate(frame, [0, 90], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const W = 900;
  const H = 300;
  const points: string[] = [];
  for (let i = 0; i <= 260; i++) {
    const x = (i / 260) * W;
    // A carrier plus a decaying overtone: the shape of most of the game's one-shot effects.
    const env = Math.exp(-(i / 260) * 2.1);
    const y =
      H / 2 -
      env * (Math.sin(i * 0.19 + frame * 0.06) * 78 + Math.sin(i * 0.47 + frame * 0.09) * 34);
    points.push(`${x},${y}`);
  }
  return (
    <>
      <AtY y={0.46}>
        <svg width={W} height={H} style={{ overflow: "visible" }}>
          <line x1={0} y1={H / 2} x2={W} y2={H / 2} stroke={alpha(C.cyan, 0.2)} strokeWidth={2} />
          <polyline
            points={points.join(" ")}
            fill="none"
            stroke={C.cyan}
            strokeWidth={6}
            strokeLinecap="round"
            style={{ clipPath: `inset(0 ${(1 - drawn) * 100}% 0 0)`, filter: `drop-shadow(0 0 16px ${alpha(C.cyan, 0.7)})` }}
          />
        </svg>
      </AtY>
      <AtY y={0.64}>
        <Appear delay={20}>
          <Label size={34} color={C.context} tracking={4}>
            SINE + OVERTONE + DECAY → 16-BIT PCM
          </Label>
        </Appear>
      </AtY>
    </>
  );
};

/** The rising staircase, one step per landed kill. */
const Stairs: React.FC<{ counts: number[] }> = ({ counts }) => {
  const frame = useCurrentFrame();
  const step = counts.filter((c) => frame >= c).length;
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: "52%",
        transform: "translateY(-50%)",
        display: "flex",
        justifyContent: "center",
      }}
    >
      <StepStairs step={step} steps={counts.length} width={820} height={440} />
    </div>
  );
};

/** The three music lanes, each lighting up as it is named. */
const Lanes: React.FC<{ padAt: number; pulseAt: number; bossAt: number }> = ({
  padAt,
  pulseAt,
  bossAt,
}) => {
  const frame = useCurrentFrame();
  const at = [padAt, pulseAt, bossAt];
  const colors = [C.cyan, C.amber, C.magenta];
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: "48%",
        transform: "translateY(-50%)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 46,
      }}
    >
      {LAYERS.map((layer, i) => (
        <WaveLane
          key={layer.id}
          src={layer.file}
          label={layer.label}
          sub={layer.sub}
          color={colors[i]}
          active={frame >= at[i]}
          width={900}
          height={124}
          offset={6 + i * 4}
          gain={1}
        />
      ))}
    </div>
  );
};

/** One "what it costs" row: the figure, then what the figure is. */
const CostRow: React.FC<{ value: string; label: string; y: number }> = ({ value, label, y }) => {
  const frame = useCurrentFrame();
  return (
    <>
      <AtY y={y}>
        <div style={{ transform: `scale(${slam(frame)})` }}>
          <Headline color={C.cyan} width={640} fontSize={146} blur={40}>
            {value}
          </Headline>
        </div>
      </AtY>
      <AtY y={y + 0.085}>
        <Appear delay={10}>
          <Label size={36} color={C.label} tracking={5}>
            {label}
          </Label>
        </Appear>
      </AtY>
    </>
  );
};
