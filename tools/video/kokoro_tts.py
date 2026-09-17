"""Devlog voiceover for Wisp Rush: a script file becomes a WAV with the local Kokoro TTS model.

Runs offline with kokoro-onnx (Kokoro-82M v1.0) from the git-ignored venv and models in tools/video/.
One line of the script is one spoken beat; lines are voiced separately and joined with short gaps,
a blank line adds a longer pause, and lines starting with `#` are notes. `{shown|spoken}` voices the
spoken text but captions the shown text, e.g. `{Wisp Rush|Wisp, Rush}` (the comma keeps Kokoro from
slurring the name into "Wisp Brush"). Next to the WAV it writes `<name>.lines.json` (each beat's
start/end seconds, to cut footage to the voice) and `<name>.srt` (1-3 word caption cues for Palmier's
add_captions subtitleMediaRef).

The SRT exists because Palmier's local transcription placed captions 0.4-0.8 s before the words on
Kokoro audio. Here line starts are exact, phrase breaks snap to the pauses in the audio, and words
inside a phrase are spaced by their length, so cues land within about 0.1 s of the speech.

Usage (from the repo root):
  tools/video/.venv/bin/python tools/video/kokoro_tts.py video/voice/ep01.txt video/voice/ep01.wav
  tools/video/.venv/bin/python tools/video/kokoro_tts.py SCRIPT OUT --voice am_puck --speed 1.1
  tools/video/.venv/bin/python tools/video/kokoro_tts.py SCRIPT OUT --captions-only --offset 0.1
  tools/video/.venv/bin/python tools/video/kokoro_tts.py --audition "One swipe." video/voice/audition
  tools/video/.venv/bin/python tools/video/kokoro_tts.py --list-voices
`--voice` also takes a blend such as `am_puck:0.7,am_michael:0.3`. `--offset` shifts the SRT by the
voiceover clip's start on the timeline (seconds); `--captions-only` rebuilds the SRT from an existing
WAV and lines.json without re-voicing.
"""

import argparse
import json
import re
import sys
from pathlib import Path

import numpy as np
import soundfile as sf

HERE = Path(__file__).resolve().parent
MODEL = HERE / "models" / "kokoro-v1.0.onnx"
VOICES = HERE / "models" / "voices-v1.0.bin"
# Owner choice 2026-09-15: a young male voice. am_puck is the default; the audition compares these.
DEFAULT_VOICE = "am_puck"
AUDITION_VOICES = ["am_puck", "am_michael", "am_fenrir", "am_liam", "am_echo", "bm_fable"]
LINE_GAP_SECONDS = 0.16
PARAGRAPH_GAP_SECONDS = 0.55
# Captions: at most this many words / characters per cue; a line's last cue stays up this long.
# 15 characters is one line of uppercase Poppins Bold at 66 px on the 1080 px canvas (EP01 style).
CUE_MAX_WORDS = 3
CUE_MAX_CHARS = 15
CUE_HOLD_SECONDS = 0.25
# Audio analysis in 10 ms windows: speech starts above ONSET_LEVEL of the peak; a pause is a run
# below PAUSE_LEVEL lasting PAUSE_MIN_SECONDS, snapped to a phrase break within PAUSE_SNAP_SECONDS.
ENVELOPE_STEP = 0.01
ONSET_LEVEL = 0.05
PAUSE_LEVEL = 0.04
PAUSE_MIN_SECONDS = 0.05
PAUSE_SNAP_SECONDS = 0.4
GROUP = re.compile(r"\{([^|{}]+)\|([^|{}]+)\}")
PHRASE_END = re.compile(r"[,.!?;:]$")
# A cue that fills up never ends on one of these; the word opens the next cue instead.
WEAK_WORDS = {
    "a", "an", "the", "and", "or", "but", "so", "to", "of", "on", "in", "at", "with", "for", "from",
    "is", "are", "was", "it", "its", "i'm", "can", "that", "you", "my", "every", "your", "this",
}


def load_kokoro():
    from kokoro_onnx import Kokoro

    if not MODEL.exists() or not VOICES.exists():
        sys.exit(f"Kokoro model files missing in {MODEL.parent} (see tools/video/README.md)")
    return Kokoro(str(MODEL), str(VOICES))


def resolve_voice(kokoro, spec: str):
    """A voice name, or a weighted blend `name:weight,name:weight` as a style array."""
    if ":" not in spec:
        return spec
    style = None
    total = 0.0
    for part in spec.split(","):
        name, weight = part.split(":")
        vector = kokoro.get_voice_style(name.strip()) * float(weight)
        style = vector if style is None else style + vector
        total += float(weight)
    return style / total


def read_beats(script: Path) -> list:
    """Script lines as {text, pause}: the markup line and the silence before it (seconds)."""
    beats = []
    pause = 0.0
    for raw in script.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line.startswith("#"):
            continue
        if not line:
            pause = PARAGRAPH_GAP_SECONDS
            continue
        beats.append({"text": line, "pause": pause if beats else 0.0})
        pause = LINE_GAP_SECONDS
    return beats


def spoken(text: str) -> str:
    return GROUP.sub(lambda match: match.group(2), text)


def synthesize(kokoro, beats: list, voice, speed: float):
    chunks = []
    lines = []
    cursor = 0.0
    sample_rate = 24000
    for beat in beats:
        samples, sample_rate = kokoro.create(spoken(beat["text"]), voice=voice, speed=speed, lang="en-us")
        if beat["pause"] > 0.0:
            chunks.append(np.zeros(int(beat["pause"] * sample_rate), dtype=np.float32))
            cursor += beat["pause"]
        duration = len(samples) / sample_rate
        lines.append({"text": spoken(beat["text"]), "start": round(cursor, 3), "end": round(cursor + duration, 3)})
        chunks.append(samples.astype(np.float32))
        cursor += duration
    return np.concatenate(chunks), sample_rate, lines


def envelope(audio: np.ndarray, rate: int) -> np.ndarray:
    if audio.ndim > 1:
        audio = audio.mean(axis=1)
    window = int(rate * ENVELOPE_STEP)
    count = len(audio) // window
    return np.sqrt((audio[: count * window].reshape(count, window) ** 2).mean(axis=1))


def speech_onset(env: np.ndarray, start: float, end: float) -> float:
    first, last = int(start / ENVELOPE_STEP), min(int(end / ENVELOPE_STEP), len(env))
    loud = np.nonzero(env[first:last] > env.max() * ONSET_LEVEL)[0]
    return start if len(loud) == 0 else start + loud[0] * ENVELOPE_STEP


def pauses_inside(env: np.ndarray, start: float, end: float) -> list:
    """Quiet runs strictly inside [start, end] as (start, end) seconds."""
    level = env.max() * PAUSE_LEVEL
    first, last = int(start / ENVELOPE_STEP), min(int(end / ENVELOPE_STEP), len(env))
    found = []
    run = None
    for index in range(first, last):
        quiet = env[index] < level
        if quiet and run is None:
            run = index
        elif not quiet and run is not None:
            if run > first and (index - run) * ENVELOPE_STEP >= PAUSE_MIN_SECONDS:
                found.append((run * ENVELOPE_STEP, index * ENVELOPE_STEP))
            run = None
    return found


def caption_units(text: str) -> list:
    """Word units as (shown, spoken); a {shown|spoken} group is one unit; punctuation stays attached."""
    pieces = []
    position = 0
    for match in GROUP.finditer(text):
        pieces += [(word, word) for word in text[position:match.start()].split()]
        pieces.append((match.group(1), match.group(2)))
        position = match.end()
    pieces += [(word, word) for word in text[position:].split()]
    units = []
    for shown_word, spoken_word in pieces:
        if units and not re.search(r"\w", shown_word):
            units[-1] = (units[-1][0] + shown_word, units[-1][1] + spoken_word)
        else:
            units.append((shown_word, spoken_word))
    return units


def weight(word: str) -> float:
    return len(re.sub(r"\W", "", word)) + 2.0


def time_words(units: list, start: float, end: float, env: np.ndarray) -> list:
    """(shown, start, end, ends_phrase) per unit: phrases snap to audio pauses, words spread by length."""
    phrases = [[]]
    for unit in units:
        phrases[-1].append(unit)
        if PHRASE_END.search(unit[1]):
            phrases.append([])
    phrases = [phrase for phrase in phrases if phrase]
    weights = [sum(weight(unit[1]) for unit in phrase) for phrase in phrases]
    total = sum(weights)
    candidates = pauses_inside(env, start, end)
    spans = []
    cursor = start
    elapsed = 0.0
    for index, phrase_weight in enumerate(weights[:-1]):
        elapsed += phrase_weight
        expected = start + (end - start) * elapsed / total
        nearest = min(candidates, key=lambda pause: abs((pause[0] + pause[1]) / 2 - expected), default=None)
        if nearest is not None and abs((nearest[0] + nearest[1]) / 2 - expected) <= PAUSE_SNAP_SECONDS:
            candidates.remove(nearest)
            spans.append((cursor, nearest[0]))
            cursor = nearest[1]
        else:
            spans.append((cursor, expected))
            cursor = expected
    spans.append((cursor, end))
    timed = []
    for phrase, (phrase_start, phrase_end) in zip(phrases, spans):
        phrase_weight = sum(weight(unit[1]) for unit in phrase)
        word_start = phrase_start
        for position, (shown_word, spoken_word) in enumerate(phrase):
            length = (phrase_end - phrase_start) * weight(spoken_word) / phrase_weight
            timed.append((shown_word, word_start, word_start + length, position == len(phrase) - 1))
            word_start += length
    return timed


def build_cues(beats: list, lines: list, env: np.ndarray, offset: float) -> list:
    cues = []
    for beat, line in zip(beats, lines):
        start = speech_onset(env, line["start"], line["end"])
        words = time_words(caption_units(beat["text"]), start, line["end"], env)
        chunk = []
        for index, (word, word_start, word_end, ends_phrase) in enumerate(words):
            chunk.append((word, word_start, word_end))
            text = " ".join(item[0] for item in chunk)
            upcoming = words[index + 1][0] if index + 1 < len(words) else None
            full = upcoming is not None and (
                len(chunk) >= CUE_MAX_WORDS or len(text) + 1 + len(upcoming) > CUE_MAX_CHARS
            )
            if ends_phrase or upcoming is None or full:
                carried = []
                if full and not ends_phrase:
                    # Hand trailing weak words to the next cue while a strong word stays behind.
                    while len(chunk) > 1 and chunk[-1][0].lower() in WEAK_WORDS and any(
                        item[0].lower() not in WEAK_WORDS for item in chunk[:-1]
                    ):
                        carried.insert(0, chunk.pop())
                    text = " ".join(item[0] for item in chunk)
                cues.append({"text": text, "start": chunk[0][1], "end": chunk[-1][2], "last": upcoming is None})
                chunk = carried
    for index, cue in enumerate(cues):
        following = cues[index + 1]["start"] if index + 1 < len(cues) else None
        if not cue["last"] and following is not None:
            cue["end"] = following
        elif following is not None:
            cue["end"] = min(cue["end"] + CUE_HOLD_SECONDS, following - 0.02)
        else:
            cue["end"] += CUE_HOLD_SECONDS
    return [(cue["text"], cue["start"] + offset, cue["end"] + offset) for cue in cues]


def srt_time(seconds: float) -> str:
    milliseconds = int(round(max(seconds, 0.0) * 1000))
    hours, milliseconds = divmod(milliseconds, 3_600_000)
    minutes, milliseconds = divmod(milliseconds, 60_000)
    secs, milliseconds = divmod(milliseconds, 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{milliseconds:03d}"


def write_srt(cues: list, path: Path) -> None:
    blocks = [f"{index}\n{srt_time(start)} --> {srt_time(end)}\n{text}\n" for index, (text, start, end) in enumerate(cues, 1)]
    path.write_text("\n".join(blocks), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("script", nargs="?", help="script .txt, or the text itself with --audition")
    parser.add_argument("out", nargs="?", help="output .wav (or a folder with --audition)")
    parser.add_argument("--voice", default=DEFAULT_VOICE)
    parser.add_argument("--speed", type=float, default=1.1)
    parser.add_argument("--offset", type=float, default=0.0, help="SRT shift: the voiceover's timeline start")
    parser.add_argument("--captions-only", action="store_true", help="rebuild the SRT from OUT and its lines.json")
    parser.add_argument("--audition", action="store_true", help="voice one line in every AUDITION_VOICES voice")
    parser.add_argument("--list-voices", action="store_true")
    args = parser.parse_args()

    if args.list_voices:
        print(" ".join(sorted(load_kokoro().get_voices())))
        return
    if not args.script or not args.out:
        parser.error("script and out are required")
    out = Path(args.out)

    if args.audition:
        kokoro = load_kokoro()
        out.mkdir(parents=True, exist_ok=True)
        for voice in AUDITION_VOICES:
            audio, rate, _ = synthesize(kokoro, [{"text": args.script, "pause": 0.0}], voice, args.speed)
            target = out / f"{voice}.wav"
            sf.write(str(target), audio, rate)
            print(f"{target}  {len(audio) / rate:.2f}s")
        return

    beats = read_beats(Path(args.script))
    if not beats:
        sys.exit("the script has no spoken lines")
    timing = out.with_suffix(".lines.json")
    if args.captions_only:
        audio, rate = sf.read(str(out))
        lines = json.loads(timing.read_text())["lines"]
    else:
        kokoro = load_kokoro()
        audio, rate, lines = synthesize(kokoro, beats, resolve_voice(kokoro, args.voice), args.speed)
        out.parent.mkdir(parents=True, exist_ok=True)
        sf.write(str(out), audio, rate)
        timing.write_text(json.dumps({"voice": args.voice, "speed": args.speed, "lines": lines}, indent=2))
        print(f"{out}  {len(audio) / rate:.2f}s  {len(lines)} lines  voice={args.voice} speed={args.speed}")
    cues = build_cues(beats, lines, envelope(np.asarray(audio), rate), args.offset)
    srt = out.with_suffix(".srt")
    write_srt(cues, srt)
    print(f"{srt}  {len(cues)} cues  offset={args.offset}")
    for text, start, end in cues:
        print(f"  {start:6.2f}-{end:6.2f}  {text}")


if __name__ == "__main__":
    main()
