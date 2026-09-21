/**
 * EP07 assets. Everything here is a WAV the game wrote for itself — `export_game_audio.gd` renders
 * `AudioSynth`'s output to disk so the edit can use the real sounds. The game ships none of them:
 * `find assets -name "*.wav" -o -name "*.ogg" -o -name "*.mp3"` returns nothing.
 */

/**
 * The 19 sound-effect ids `scripts/utils/audio_synth.gd` declares (its 22 ids minus the three
 * music layers). The 8 `slice_step*` pitches are the same slice, so they are not listed here.
 */
export const SFX_IDS = [
  "dash",
  "slice",
  "wall_impact",
  "shard_pickup",
  "soul_pulse",
  "level_up",
  "upgrade_choice",
  "player_damage",
  "player_dissolve",
  "aim_tension",
  "reaper_appear",
  "reaper_windup",
  "reaper_sweep",
  "reaper_hit",
  "reaper_defeat",
  "ui_confirm",
  "ui_back",
  "ui_error",
  "ui_purchase",
];

/** The three music layers that fade against each other. */
export const LAYERS = [
  { id: "pad", file: "audio/game/music/bed_calm.wav", label: "PAD", sub: "UNDERNEATH" },
  { id: "pulse", file: "audio/game/music/bed_run.wav", label: "PULSE", sub: "FOLLOWS YOUR COMBO" },
  { id: "boss", file: "audio/game/music/bed_boss.wav", label: "BOSS", sub: "WHEN SOMETHING BIG ARRIVES" },
];

/** The rising slice, one step per extra kill in a dash. */
export const SLICE_STEPS = [1, 2, 3, 4, 5];
