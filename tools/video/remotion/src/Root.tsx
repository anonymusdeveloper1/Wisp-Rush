import React from "react";
import { Composition } from "remotion";
import { Ep05, EP05_DURATION } from "./episodes/ep05/Ep05";
import { Ep06, EP06_DURATION } from "./episodes/ep06/Ep06";
import { Ep07, EP07_DURATION } from "./episodes/ep07/Ep07";
import { Ep08, EP08_DURATION } from "./episodes/ep08/Ep08";
import { FPS, H, W } from "./style/layout";
import "./style/fonts";

/**
 * One composition per episode. Everything shares the style modules in src/style and the
 * components in src/components, so each new episode is a script, its assets and a timeline —
 * not a new look.
 */
export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="ep05-deleted-six"
      component={Ep05}
      durationInFrames={EP05_DURATION}
      fps={FPS}
      width={W}
      height={H}
    />
    <Composition
      id="ep06-built-then-deleted"
      component={Ep06}
      durationInFrames={EP06_DURATION}
      fps={FPS}
      width={W}
      height={H}
    />
    <Composition
      id="ep08-858-megabytes"
      component={Ep08}
      durationInFrames={EP08_DURATION}
      fps={FPS}
      width={W}
      height={H}
    />
    <Composition
      id="ep07-zero-sound-files"
      component={Ep07}
      durationInFrames={EP07_DURATION}
      fps={FPS}
      width={W}
      height={H}
    />
  </>
);
