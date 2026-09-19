# Wisp Rush — Game Design Document

> Source of truth for **what the game is**. Implementation lives in
> [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) and `docs/systems/`.
>
> **Status: 🔄 release MVP specified; implementation in progress.** Source: owner-supplied
> `WISP-RUSH-GODOT-RELEASE-MVP-PROMPT-v2.md` (SHA-256 `c174ff79…60b`).
>
> **2026-09-14 restructure (owner direction):** Rift story levels, a cosmetic Endless mode and
> earned-only Rift Points ([ADR-0013](decisions/0013-rift-story-levels-endless-mode-and-rift-points.md),
> [ADR-0014](decisions/0014-endless-arenas-share-one-floor-template.md)). §3, §5.5, §6, §7, §9 and §11–§14
> describe the target; the build order is [docs/specs/story_and_endless/](specs/story_and_endless/README.md),
> so until it lands the game still plays as before.

## 1. Pitch

Wisp Rush is a fast, one-finger portrait survival game. Swipe and release to launch a small
purple Wisp in a straight line, slice every enemy along that line, stop at the physical screen
edge, then immediately redirect to build ricochet chains and survive escalating waves. Clear five
Rifts level by level, then chase scores in Endless on arenas you unlock with Rift Points.

## 2. Pillars

1. **Precise supernatural motion** — every swipe produces a fast, predictable edge-to-edge dash.
2. **Readable skill expression** — planning multi-kill lines and safe edge positions beats clutter.
3. **Immediate momentum** — aim, rush, slice, impact and restart all happen with minimal delay.

## 3. Core loop

- **Seconds:** aim → release → slice along the dash segment → wall impact → short focus → redirect.
- **Minutes (Rift level):** survive four 18–25 second waves, build score/combo, gain XP and choose run
  mutations, then beat the Rift's boss around 55–75 seconds to clear the level — or die and retry.
- **Minutes (Endless):** the same waves with no end; a boss from a cleared Rift arrives every four
  waves, and each victory makes the next cycle harder.
- **Sessions:** clear levels, open new Rifts and Endless, earn Rift Points, unlock characters, dash
  styles and Endless arenas, climb the Trials and play the daily run.

This is explicitly **not** orbit, tap-to-reverse, ring-gap or slingshot movement.

## 4. Player & controls

| Action | Touch / mouse | Keyboard debug | Notes |
|---|---|---|---|
| Aim | Hold and drag / click-drag | WASD or arrows | A small direction arrow beside the Wisp (no path line — owner 2026-09-15); enemies that dash would slice light up cyan, `×N` when 2+ (AIM ARROW, on by default; §5.1) |
| Dash | Release after ≥ 28 dp | Space | Swipe direction is travel direction (bent ≤ 6° by AIM ASSIST, §5.1); length does not change power |
| Redirect | Swipe again while dashing | Direction + Space | Turns the live dash from wherever the Wisp is |
| Pause / back | HUD button | Escape | Closes the top overlay first |

Input actions must match [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) §5.4. Only the first active
pointer controls aiming; UI consumes its own input; interruptions cancel an active swipe.

## 5. Mechanics

### 5.1 Wisp state and dash

State machine: `SPAWNING → WAITING_AT_EDGE → AIMING → WINDUP → DASHING → WALL_IMPACT`, plus
`HURT`, `DEAD`, and `VICTORY`. Starting windup is 65 ms. A normalized direction produces constant
speed, initially tuned to cross 1080 px in about 180–260 ms. The first ray/arena intersection is
calculated before launch; movement stops exactly at it. Outward edge swipes reflect inward.

**Flow** (owner decision 2026-09-12):
- **Mid-dash redirect.** A swipe while dashing turns the dash from the Wisp's current position; a
  dash no longer has to run wall to wall. Each redirect is a new dash for hit purposes, so enemies
  passed on one leg can be hit on the next; the leg that ended is still scored.
- **No lost input.** A touch is tracked in every live state. A swipe released during the windup, a
  hurt reaction or a reform is buffered for 0.3 s and fires as soon as the Wisp can act; a swipe
  during the 140 ms landing reaction launches immediately instead of waiting it out, and a swipe
  during the 65 ms windup re-aims that dash.
- **Launch burst.** Each dash starts at 1.4× speed and eases to cruise over about 0.1 s.
- **Chain momentum.** A dash launched within 0.35 s of landing, or any redirect, adds +8 % speed up
  to +25 %. A slow restart or taking damage resets it.

**Aim help** (owner decision 2026-09-15 — players missed enemies and lost combos through aim precision,
not dash speed):
- **Target highlight.** While aiming (hold, keyboard aim, re-aiming in flight or windup) the arrow
  shows the resolved dash direction (no path line — removed by the owner 2026-09-15); the dash is
  cast to where it will stop (the wall, or a dash-blocking hazard such as a split void crystal). Every regular enemy that dash would hit lights
  up with a soft cyan ring (static under Reduced Motion); two or more show a small `×N` just past the
  arrow tip. Counted exactly as combat hits (corridor, run modifiers, Warden shield, Rift Spawn tether).
  Clears on release, cancel, damage, pause and run end; AIM ARROW off hides it all.
- **Gentle aim assist.** On release (launch and redirect, touch and keyboard) directions within ±6°
  of the swipe are sampled every 1°; if one slices more enemies than the raw swipe, the dash bends to
  the best (ties → closest to the swipe). Never bends when the swipe already hits the most, never past
  6°, never toward zero hits; the preview shows the assisted result. AIM ASSIST setting, default ON;
  tuning `PlayerTuning.aim_assist_degrees` / `aim_assist_step_degrees`. Dash speed, collision, scoring
  and momentum are unchanged.

Every dash has a unique `dash_id`. Collision uses the swept segment between physics positions,
not a point sample. Each enemy can be damaged once per dash.

### 5.2 Edge impact and focus

Gameplay reaches all four physical display edges; a small scale-dependent collision inset only
keeps the sprite visible and never forms a visible frame. Impact briefly compresses the Wisp,
flashes the wall, emits a ring, adds a subtle 2–4 px kick and starts 250–400 ms of Wisp Focus at
0.25–0.40× enemy/hazard speed. Player input remains responsive and the slowdown expires even if
the player waits.

### 5.3 Combat, health and failure

The dash corridor is the Wisp radius plus a configurable blade bonus. Normal enemies are sliced
without stopping the Wisp and cannot deal contact damage during a successful dash. Kills award
score, XP, combo and possible currency immediately. Multi-kill dashes escalate feedback. Normal
kills use at most 20–35 ms hit-stop; heavy/boss hits may use 50–80 ms.

The Wisp begins with three Soul Fragments. Contact damage removes one, resets combo and grants
750–1,000 ms invulnerability. At zero, play the death dissolve before results. Crowded hits reform
the player at a safe edge.

### 5.4 Enemies and hazards

| Content | Role |
|---|---|
| Soul Wisp | One-hit, slow steering enemy that creates early chain lines |
| Shard Wraith | Faster angular enemy with two-hit/shield behaviour and a telegraphed move |
| Bone Mote | Heavy enemy with a readable charge toward the last edge position |
| Split void crystal | Narrow indestructible route blocker |
| Spike bloom | Pulses before alternating safe/active states |
| Blade ring | Fixed rotating hazard with dangerous blades only |
| Void portal | Linked, visible entrances that preserve or predictably rotate dash direction |
| Obsidian pillar | Taught separately as a dash stop/bounce obstacle |

Enemy arrivals telegraph for at least 450–700 ms, never spawn on the Wisp and use collision circles
slightly smaller than the art. Obstacles remain sparse and formation validation preserves at least
one viable dash and safe edge.

### 5.5 Waves, upgrades and boss

An endless threat-budget director uses at least 20 handcrafted normalized formations with mirrored
and rotated variants. Waves introduce Soul Wisps, diagonal chains, Shard Wraiths, one obstacle at a
time, then Bone Motes and mixed formations. Difficulty rises through combinations and decision time,
not unrestricted random flooding.

Kills fill XP; each level-up offers three uncapped choices: Wide Reap, Soul Hunger, Death Pulse, Soul
Link, Cold Wake, Void Velocity, Soul Vessel and Reaper's Gift.

**Upgrade offer rules** (owner decision 2026-09-15 — upgrades came too fast and cut the player off):
- **Level-ups are banked and never interrupt.** Several can bank. A glowing **UPGRADE button** (×N for
  several) appears under the pause button; tapping it opens the cards at once. The cards also still open
  by themselves at calm moments. The offer itself is just the cards and a timer (owner 2026-09-15).
- **Cards are offered only at a calm moment:** a new wave starting, a boss just defeated (after the
  victory beat), or the field clear of regular enemies — and only when it is free play (a tutorial
  lesson only when it asks), no boss is active or pending, RUSH is off, the game is not paused, the
  run is not over, the Wisp rests at an edge and no combo is running. Once the player sends the cards
  away they return only at the next calm moment, so they never nag.
- **No pause: slow-motion cards.** A compact card tray slides up from the bottom and the world runs
  in slow motion (×0.3) while it is up. Enemies and hazards still move and can hurt; the pause menu
  still works and hides the tray until Resume. Tap a card to take it (if more are banked, the next
  three slide in at once, otherwise time returns to normal), or just keep playing: a swipe on the arena
  sends the tray away and the level stays banked. The tray also leaves on its own after 6 seconds.
  Card taps never dash and swipes never pick a card. Reduced Motion: the tray appears without sliding
  and the world keeps normal speed.
- Same in Rift levels, Endless and the daily run. Banked levels not picked by the end of a run are
  lost; only picked levels count as run level.

The Reaper stops normal spawning and uses three readable phases: scythe sweep, teleport hunt and
death corridors. Its core takes at most one hit per dash and is vulnerable only during exposed
windows. Victory awards 1,500 points plus Rift Points. In a Rift, beating the level's final boss
clears the level and ends the run; in Endless and the daily run, play continues at a harder cycle.

### 5.6 RUSH mode, momentum and finishers

Owner decision 2026-09-15: four base mechanics make a run feel faster, with no new buttons
([spec](specs/rush_and_feel/README.md)). They work the same in Rift levels, Endless and the daily run.
- **Momentum you can see.** Chain momentum (§5.1) shows on the Wisp: a longer, brighter trail and a
  slightly higher dash sound per step, with faint speed lines at maximum. No extra HUD text. Damage
  and slow restarts clear it at once.
- **Auto-collect.** Rift Point shards still on the floor fly to the Wisp when a new wave or a boss
  encounter starts, when a boss falls, and right before a run ends, so none are ever lost.
- **Slow-motion finisher.** About 0.4 s of slow motion with a light flash when one dash reaches five
  kills, when a kill clears the field (at most once every 6 s), and on a boss's killing blow. Chain
  momentum counts game time, so slow motion never breaks a chain.
- **RUSH.** Kills fill a RUSH meter; multi-kill dashes and boss hits fill it faster. When it is full,
  RUSH starts on its own: for 6 s dashes are 30 % faster, score doubles, the combo timer freezes, the
  Wisp takes no damage and the music peaks. Then the meter empties. RUSH never starts during a pause
  or while the upgrade cards are up; it waits for them to close. In the Tutorial screen only the RUSH lesson has a
  live meter.
- Reduced Motion keeps every mechanic but drops slow motion, speed lines, the RUSH screen glow and
  the soul-orb flights.

## 6. Progression & content

Direction set by the owner on 2026-09-14 ([ADR-0013](decisions/0013-rift-story-levels-endless-mode-and-rift-points.md)).

**Rifts — story mode**
- Five Rifts in order: Obsidian Garden → Shattered Rift → Ember Hollow → Frozen Choir → Reaper's Court.
  Each keeps its own floor shape, rule twist, enemy roster and boss ([rifts.md](systems/rifts.md)).
- Each Rift has 8 levels. A run plays one level; clearing it banks the level. Level 1 of every Rift
  starts at threat 1.0 and later levels climb that Rift's ladder
  ([ADR-0008](decisions/0008-rift-levels-and-difficulty-ladder.md)).
- Clearing level 1 of a Rift opens the next Rift. After level 8 the Rift is *mastered* and replays level 8.
- Story runs start from RIFTS → the Rift Map (or a Results follow-up), never from PLAY; a newly opened
  Rift becomes the Rift Map's selection.

**Endless**
- **PLAY always starts Endless**, open from the first launch (owner decision 2026-09-15). Every Rift's
  enemies and bosses can appear from the start; story progress never limits Endless (owner decision 2026-09-15).
  Plays until death on the shared floor template
  ([ADR-0014](decisions/0014-endless-arenas-share-one-floor-template.md)) with the equipped arena skin;
  no rule twists.
- Each wave uses the enemy roster of one Rift whose level 1 is cleared; each boss (every 4 waves) is
  one such Rift's boss. Beating a boss starts a harder cycle. Endless owns the best score and wave.
- Endless and the daily run are the only runs that pass wave 4, so they pay the one-time depth
  milestones (waves 5/10/15/20/25).

**Daily run** — Endless rules with the date seed, the base roster and the Reaper only, and an arena of
the day that rotates through every Endless skin, owned or not. Missing days have no penalty.

**Rift Points (RP)** — the only currency; earned only by playing, never bought.
- Sources: pickups; a performance bonus from the run's score; level-clear bonuses (full on the first
  clear, reduced on repeats); boss rewards; Trials; daily challenges and the daily reward; depth
  milestones; the opt-in "double RP" rewarded ad.
- Spent only in the Shop. There is **no permanent power**: the Soul Sanctum is removed, and permanent
  progress is content access and cosmetics. Run-only power is the eight mutations.

**Shop** — cosmetics only; nothing changes scale, anchor, hitbox, timing or rules. Prices live in `data/`.

| Tab | Items | Paid with |
|---|---|---|
| Characters | Wisp forms: Void (default), Ash (250), Venom (500), Bloodmoon (800), Frost (1,200), Eclipse (2,000 plus first boss victory). Animated characters: Veyra, the Last Wisp; Rook, the Bonewing; Morrow, the Runebound; Ilyra, the Astral Dancer (Mythic); Bram, the Rift Knight (Legendary) (0 while the owner reviews them, §14 #31). Every character plays exactly like the Wisp | RP |
| Dashes | Trail styles: Soul (default) plus tints of the existing trail, never led by warning amber or rift magenta | RP |
| Arenas | 30 Endless skins in four tiers: Astral Observatory (free default), Drowned Sanctum 800, Moonpetal Shrine 1,200, the rest Simple 300 · Rare 800 · Legendary 2,000 · Mythic 3,500; Legendary skins have light animated scenery, Mythic skins rich animated scenery (never over the floor) | RP |
| No Ads | Remove Ads (no currency inside) and Restore Purchases | Real money ([ADR-0012](decisions/0012-store-surface-before-billing.md)) |

**Local goals** — Rift levels and mastery, per-Rift bests, Endless best score and wave, highest combo,
the collection, Trials and three rotating daily challenges.

## 7. Win / lose conditions & scoring

- **Rift level:** victory when the level's final boss is beaten; defeat at zero Soul Fragments. Either
  way the run ends.
- **Endless and daily run:** no victory; death at zero Soul Fragments ends the run, and a boss victory
  is a beat, not the end.

Track score, bests (per Rift, Endless, daily), combo/highest combo, kills, multi-kill dashes, wave,
bosses and Rift Points separately. Combo decay begins after 2.2 seconds without a kill; wall impact
does not reset it and damage does. Multi-kill bonuses are stepped or quadratic so alignment matters.

## 8. Game feel

- Emotional beat: focus → direction → 65 ms anticipation → explosive dash → slice → impact → breath.
- Idle animation is 3–4 FPS with gentle hover; impact is 100–180 ms; enemy dissolve 220–350 ms;
  Wisp death 450–650 ms; reform 350–500 ms.
- Aim previews and telegraphs always outrank particles. No floaty movement, muddy effects, constant
  shake, unavoidable damage or long input locks.
- Reduced motion lowers shake, flashes and heavy transitions without reducing gameplay clarity.

## 9. Art direction

Redesign v1 (owner-approved 2026-09-11, [ADR-0005](decisions/0005-visual-redesign-v1.md)); the full
authority is `concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md`.

- Thesis: a living soul-flame cuts through an obsidian garden suspended over the void. Painterly
  depth at the perimeter, crisp readable silhouettes in combat; the Wisp is always the brightest
  small object on screen.
- Palette: void charcoal `#111521`, slate teal `#263D42`, soul cyan `#62E8F2`, soul white `#EAFDFF`,
  warning amber `#F3A847`, rift magenta `#B14CD9`, moss green `#5E7D4C`. Cyan, amber and magenta are
  information colours (friendly/navigation, telegraphs/rewards, enemy cores/boss/selection).
- Top-down arena with ≥ 75 % uninterrupted floor; tall scenery only in the outer 12 %.
- UI: engraved stone frames with cyan inlays, stepped corners, near-black panel interiors,
  dominant bottom-reachable primary actions; all text code-rendered.
- Hierarchy: Wisp (cyan-white core) → Soul Wisp → Shard Wraith → Bone Mote → Reaper (tallest,
  darkest). Cosmetic forms keep scale, anchor and collision silhouette.
- Playable characters ([ADR-0015](decisions/0015-animated-playable-characters.md)): Veyra, Rook,
  Morrow, Ilyra and Bram are layered rigs animated in code — a full state set from idle to death, springy
  appendages, a restrained particle trail each — drawn inside the Wisp's visual box on the same
  collision circle. Their layers are generated from the owner's concept sheets
  (`concept_art/wisp_rush_playable_characters_v1/`).
- Runtime art is generated from the concept sheets by `tools/art/extract_redesign.py`; the previous
  violet art is archived in `assets/legacy_v1/` and never ships.
- Floors: each Rift's wall follows its own painted floor ([ADR-0011](decisions/0011-polygon-playfield-from-art.md)).
  Every Endless arena skin is new art painted to the one shared floor template
  ([ADR-0014](decisions/0014-endless-arenas-share-one-floor-template.md)), generated with the layout image
  attached (`concept_art/wisp_rush_endless_v1/GENERATION_PROMPTS.md`); the painted rim marks the playable
  area, with no code-drawn edge line.

## 10. Audio direction

Minimal dark electronic ambience grows with threat/combo; boss music deepens without medieval or
metal styling. Separate Master, Music, SFX and UI buses. Required cues cover aim, dash, slice and
multi-kill pitch steps, impact, pickup, damage/death, upgrades, Reaper actions and UI feedback. If
final files remain unavailable, use carefully tuned runtime synthesis rather than placeholder beeps.

## 11. UI & screen flow

`Loading → (first launch) Tutorial → Home → Rift level / Endless run → Upgrade/Pause overlays → Results →
Next level, Retry or Play again / Home`. Home also reaches the Shop, Rift Map, Trials, Daily, Statistics
and Settings.

**Tutorial** (owner decision 2026-09-15; replaces the in-run first-run lesson — real runs never teach):
a separate screen that teaches every base mechanic, easiest first — aim & dash, slice, chain,
mid-dash redirect, blockers, danger & Soul Fragments, Rift Points & XP with the upgrade choice, RUSH,
and a boss with reduced health. Each lesson shows, then you try: a ghost hand demonstrates the gesture
(press, drag with the aim arrow, release) while the real Wisp performs it in a placeholder arena (the
Endless floor template under the default skin); then the player repeats it, and the lesson passes
only on success (short callout and sound). One-line caption, step counter and progress dots; a miss or
hit simply retries, and the tutorial never ends in death. SKIP is always visible and asks "SKIP THE
TUTORIAL?" (Android back / Escape open the same confirm). First launch (tutorial not completed): after
Loading the Tutorial opens instead of Home, and finishing or skipping marks it completed and goes Home.
Afterwards it is replayable only from the Rift Map's TUTORIAL button, returning to the Rift Map. Reduced
Motion stills the decoration; the hand gesture still plays because it is information.

**Home** (owner decision 2026-09-13, revised the same day; content updated by ADR-0013 on 2026-09-14):
stone-and-cyan, no bottom navigation.
- **Top:** slim top bar (Rift Points, best, Statistics, Settings) and the logo. Best is the Endless best.
- **Middle:** the equipped character, alive; **tapping it opens the Shop's Characters tab**. Left column: Trials,
  Daily. Right column: Shop, Remove Ads (hidden once ads are removed).
- **Under the Wisp**, at least 50 px below its lowest animated pixel: a caption (`ENDLESS`, or
  `ENDLESS • BEST WAVE n`), then a large animated PLAY (not full width) that starts Endless, with the
  Rifts button beside it — the only way into the story Rifts. There is no separate ENDLESS button
  (owner decision 2026-09-15).
- **Motion:** the Wisp floats, breathes and sways with a pulsing glow while soul motes orbit it;
  the background comes alive (brazier flicker, rune pulse, mist, rising motes) over unchanged art;
  PLAY breathes with a glow pulse and a periodic light sweep; the Rifts portal icon turns. No
  animation ever passes over a button. Reduced Motion stills it all.
- **Shop** has four tabs: Characters, Dashes, Arenas (Endless skins) and No Ads. The first three spend
  Rift Points; No Ads (Remove Ads + Restore Purchases) stays disabled until billing exists
  ([ADR-0012](decisions/0012-store-surface-before-billing.md)).

**Shop tabs and the Rift Map** are vertical card pickers: one big tall focused card in the centre,
raised and framed, neighbours peeking in dimmed; swipe sideways to browse; a description and one main
button below. Locked items and Rifts stay previewable; a locked Rift can never be entered.

**Results:** a Rift level shows CLEARED or FAILED, the Rift Points breakdown and any new unlock, with
ENTER <NEW RIFT>, NEXT LEVEL or RETRY first. Endless and the daily run show wave, score and best, with
PLAY AGAIN first.

HUD places
score top-centre, health/currency top-left, pause top-right, contextual wave/combo information and a
slim XP bar. Only UI respects safe-area insets; the world continues behind cutouts. All controls are
large, focusable and have visible desktop/controller focus styling.

## 12. Platforms & technical targets

- Godot 4.7.2, typed GDScript, 2D Forward+ during development.
- Android and iOS portrait release; desktop debug controls.
- 1080×1920 design coordinates, `canvas_items` + `expand`, full physical display with no letterbox,
  card, border or fixed SubViewport. Edge-to-edge means the *presentation*: since redesign v1 the
  dashable playfield is inset to the painted stone floor ([ADR-0006](decisions/0006-inset-playfield-and-larger-sprites.md)).
- Walls: Rifts use polygons derived from their art (ADR-0011); every Endless skin uses the one frozen
  floor template in texture UV (ADR-0014), so skins can never change the playfield.
- Stable 60 FPS on a mid-range Android phone and recent iPhone; interactive Home appears quickly.
- Offline base game, no account/backend/data collection; versioned local save under `user://`.
- QA sizes (phones only — owner decision 2026-09-11): 320×568, 360×800, 375×812, 390×844, 412×915.
  Tablets and desktop are not targets; desktop stays a debug convenience.

## 13. Scope

| Release MVP | Explicitly later / provider-dependent |
|---|---|
| Tutorial; Rift story mode (5 Rifts × 8 levels); Endless mode with template arena skins; 20+ formations; 3+ enemies; 3+ hazards; 8 mutations; 3-phase boss encounters; Rift Points Shop (6 Wisp forms and 3 animated characters, dash styles, arena skins); daily/challenges; complete screen flow; local save/statistics/settings; final feedback; unsigned Android/iOS export configuration | Real ads, analytics, IAP/store verification, cloud saves, accounts, backend, signed store builds; paid cosmetics (custom Wisps, characters); Endless events built from the Rift twists |

Release contains no dead buttons, placeholder/debug panels, fake purchases, required network calls
or legacy art. Monetisation integration stays hidden unless backed by a real platform provider —
except the Shop and Remove Ads entry points, visible with purchases disabled during development
(ADR-0012); a release must wire them to real billing or hide them.

## 14. Open questions & assumptions

| # | Question / ASSUMPTION | Status |
|---|---|---|
| 1 | Confirm the owner-supplied artwork's production/distribution license. | Open; not supplied in ZIP |
| 2 | `com.cognitix.wisprush` is configured in the Android debug export preset for on-device testing; iOS bundle id and store/release config stay deferred. | Partly settled |
| 3 | ASSUMPTION: no audio files were supplied, so the prompt's runtime-synthesis fallback ships (ADR-0004); supplied files can replace any sound id later. | Implemented in Milestone 4; owner may supply files |
| 4 | Confirm current store target SDK/deployment requirements at release time. | Open; verify during release milestone |
| 5 | Resolved: tutorial completion, best score, Soul Shards and all progression persist locally via SaveManager (ADR-0003). | Resolved in Milestone 3 |
| 6 | ASSUMPTION: taking damage resets the kill streak used by Reaper's Gift, matching combo risk/reward. | Implemented; owner may retune |
| 7 | ASSUMPTION: a boss arrives every four waves (first at wave 4, about 66 seconds). In a Rift the level's final boss ends the run (#12); in Endless and the daily run each victory resumes a harder cycle. | Milestone 3 default; revised 2026-09-14 (ADR-0013) |
| 8 | ASSUMPTION: a completed daily run grants 10 Rift Points once per local date; three date-seeded challenges grant 10–25 once each and accumulate across that date's runs. | Milestone 3 default; currency renamed 2026-09-14 |
| 9 | ASSUMPTION: five Rifts, each with one rule twist (portals, shrinking floor, drift, boss rush). The GDD never specified arenas. Their wave gates 0/5/10/15/20 are superseded by level clears (#13). | Ladder, map and twists shipped ([ADR-0007](decisions/0007-rifts-as-rule-variant-arenas.md)); unlock rule superseded 2026-09-14 |
| 11 | Monetisation model chosen: free with opt-in rewarded video (revive, double Rift Points, upgrade reroll) plus one Remove Ads IAP with no currency inside; never interstitials. Plumbing ships behind a null provider, so §12's offline/no-data-collection promise still holds today. §12 and §13 must be amended **before** a build with a real ad SDK ships. Home's Shop and Remove Ads open a Shop whose purchases stay disabled until then. | Settled 2026-09-12 ([ADR-0009](decisions/0009-monetisation-model.md), Shop surface [ADR-0012](decisions/0012-store-surface-before-billing.md)); shard pack removed 2026-09-14 ([ADR-0013](decisions/0013-rift-story-levels-endless-mode-and-rift-points.md)); SDK, privacy policy and store config still owner-side |
| 10 | ASSUMPTION: three new enemies (Cinder Shade splits on death, Warden is shielded on one face, Rift Spawn is a tethered pair) and a second boss (The Hollow Choir, a static three-core structure) extend the roster. Invented to fill the M8 art pack; not in the owner prompt. | Art generated only — no tuning, behaviour or scene; owner may reject or redesign |
| 12 | ASSUMPTION: a Rift run plays exactly one level and ends on the level's final boss (victory) or on death. The owner split "story" Rifts from Endless; finite levels keep the two modes distinct. | Owner approved 2026-09-15 · implemented 2026-09-15 (phase 2) |
| 13 | ASSUMPTION: Rift N+1 opens after Rift N level 1 is cleared; ~~Endless opens after Obsidian Garden level 1~~ superseded 2026-09-15: Endless is PLAY and always open; a newly opened Rift becomes the selection. | Owner approved 2026-09-15 · Rift chain implemented 2026-09-15 (phase 2); Endless unlock implemented 2026-09-15 (phase 3) |
| 14 | ASSUMPTION: Endless v1 has no rule twists; each wave takes one cleared Rift's roster and each boss one cleared Rift's boss, with no immediate repeats, harder per boss cycle. | Designed 2026-09-14; implemented 2026-09-15 (spec 03); Endless events from the twists are backlog |
| 15 | ASSUMPTION: the daily run uses Endless rules with the base roster and the Reaper only, plus an arena of the day drawn from all skins, and is available from first launch. | Designed 2026-09-14; implemented 2026-09-15 (spec 03) |
| 16 | ASSUMPTION: Rift Points pacing targets 35–45 RP for a median early run; first level clears pay the full clear bonus, repeats 25 %. Starting values in `EconomyTuning`. | Designed 2026-09-14; performance bonus live 2026-09-15 with a bot estimate ([shop.md](systems/shop.md)); calibrate on device |
| 17 | ASSUMPTION: the save migration refunds Sanctum spend in Rift Points, and wave-gated Rift unlocks are not grandfathered (pre-release). | Designed 2026-09-14; refund implemented 2026-09-15 (save v6) |
| 18 | ASSUMPTION: dash styles are tints of the existing trail art (Soul default, then Moonsilver, Verdant, Abyssal), never led by warning amber or rift magenta. | Designed 2026-09-14; implemented 2026-09-15 (spec 04) |
| 19 | Owner decision 2026-09-15 (was an ASSUMPTION of three skins): the Endless catalog is the 30 skins of `concept_art/wisp_rush_endless_v1/assets/skins_manifest.json`, in manifest order, all on the one floor template; Astral Observatory is the free default; Endless (and so every skin) is open from the first launch. | Implemented 2026-09-15 (spec 05) |
| 20 | Paid cosmetics (custom Wisps, characters) through store billing are planned but unspecified; they need an ADR superseding ADR-0009's one-product rule and must keep scale, anchor and hitbox. | Open; owner direction 2026-09-14 |
| 21 | Confirm the licence of generated art before selling any cosmetic made from it (see #1). | Open |
| 22 | ASSUMPTION: goals that counted Soul Shards now count the Rift Points a run *collects* (`rp_collected`: pickups, multi-reaps, bosses), not the performance bonus — the HOARDER trial ("Collect 40 Rift Points in a single run") and the POINT SEEKER daily challenge (was SHARD SEEKER, "Collect 8 Rift Points") — so their targets keep today's difficulty. Spec 01 named the trial metric `rift_points`; trial metrics are run-summary keys, so it reads the renamed `rp_collected` instead. | Implemented 2026-09-15 (spec 01); owner may retune |
| 23 | ASSUMPTION (spec 02 simplest choices): the Rift Map's ENTER always plays the focused Rift's next level — there is no picker for earlier levels, and a mastered Rift replays level 8; (superseded 2026-09-15: the first-run lesson is now the Tutorial screen, §11); until spec 03 the daily run plays Obsidian Garden whatever Rift is selected; Trials that a 4-wave story run can't reach become cumulative level-clear goals (`level_clears`: 2, 4, 8, 12 in tiers 2, 3, 6, 7), and deeper GO DEEPER wave goals read "in Endless". | Implemented 2026-09-15 (spec 02); owner may retune |
| 24 | ASSUMPTION (spec 03 simplest choices): Endless's NEW badge clears when the first Endless run *starts*; a boss wave (and its summons) keeps the roster of the wave before it; every enemy now moves at its arena's speed (`RiftData.enemy_speed_scale` was authored but never applied; story Rifts now run 1.00–1.20, Endless per cycle); the arena of the day skips `placeholder` skins when real ones exist; Endless Results compare against the Endless best and daily Results against today's daily best, and both offer only HOME besides PLAY AGAIN; Restart of an Endless run rebuilds the pool from the save; Statistics' "HIGHEST RIFT" is renamed "HIGHEST WAVE". | Implemented 2026-09-15 (spec 03); owner may retune |
| 25 | ASSUMPTION (spec 04 simplest choices): SOUL keeps today's look by playing the equipped form's tint (`DashStyleData.uses_form_tint`), and its authored tints only colour the Shop preview; `burst_tint` colours the short launch trail and `trail_tint` the long impact trail; equipping (not only buying) plays `ui_confirm`; a Shop opened from Results goes Back to the same Results (re-shown, nothing banked again); the SHOP button remembers the last tab viewed, including tabs opened by the Wisp tap or NO ADS; the Shop tab bar reuses `NavBar` + `NavButton` instead of new `ShopTab` variations; form and arena-skin ids in the save stay listed in SaveManager (their catalogs load art at boot), while dash style ids come from the catalog. | Implemented 2026-09-15 (spec 04); owner may retune |
| 26 | Owner decision 2026-09-15: arena prices 0 / 800 / 1,200 for the first three, then by tier Simple 300 · Rare 800 · Legendary 2,000 · Mythic 3,500 RP; no placeholder art remains; Legendary skins get light and Mythic skins rich code-rendered scenery ambience (glows, flicker, mist, motes, stars, aurora, soft lightning at most every 6 s) confined outside the floor + rim tolerance, still under Reduced Motion; the 30 backgrounds import lossy (quality 0.8). ASSUMPTION: descriptions come from the manifest and accents are Palette colours chosen per skin; the arena of the day draws from all 30; saves owning or equipping `placeholder_void_slate` move to `astral_observatory` during sanitizing, with no schema bump. | Implemented 2026-09-15 (spec 05) |

| 27 | ASSUMPTION (RUSH and feel starting values, `RunFeelTuning`): RUSH meter 100, +4 per kill, +4 per extra kill in the same dash, +10 per boss core hit, no decay and no drain on damage; RUSH lasts 6 s at ×1.3 dash speed and ×2 score and blocks all damage, boss attacks included; finisher 0.4 s at ×0.3 time with a 5-kill threshold and a 6 s cooldown for field clears; shards sweep to the Wisp in 0.35 s. | Designed 2026-09-15; implemented 2026-09-15; tune on device |
| 28 | ASSUMPTION (RUSH and feel build, simplest choices): a pause or upgrade choice freezes a running RUSH (its 6 s are game time) — only run end and leaving the run end it; the meter does not fill while RUSH runs and the bar drains with the time left; a "boss core hit" is any boss health loss, the killing blow included; Soul Link kills count toward a dash's 5 kills, Death Pulse kills do not; a field clear is a kill that leaves no regular enemy alive (split children count) during waves with no boss pending or alive; on death the shards sweep at the fatal hit (during the dissolve) and any left collect instantly before the summary; the finisher is refused after run end, and a hit-stop during it dips lower (lowest time scale wins); Reduced Motion keeps the RUSH start shake (already scaled to 30 %) and the warning flicker; the RUSH row (label + Soul White `RushProgressBar`) sits under SOUL LEVEL and pushes the boss panel and callouts 34 px down; dash pitch follows real momentum steps, not RUSH's full visuals. | Implemented 2026-09-15; owner may revise |
| 29 | ASSUMPTION (Tutorial screen build, simplest choices): the ghost hand is code-drawn placeholder art (ROADMAP M6); the boss lesson's demo shows the hand and caption only (the real Wisp does not strike, so the fight is the player's); the danger lesson's demo forces its hit as the demo dash nears the spikes (so the Soul Fragment loss and blink always show), and Soul Fragments refill 0.6 s after any hit (at once if one more would kill); the Rift Points & XP lesson's demo fills the XP bar and the ghost hand taps a card once the tray slides up (§5.5), and the player's kills (topped up once every soul is reaped) bank the level whose cards slide up at the lesson's calm moment; RUSH starts at 90 % so two kills fire it, and fresh targets appear when RUSH starts; a redirect lesson counts a kill on a leg started mid-dash; misses in the chain, redirect, XP and RUSH lessons rebuild the lesson; the pause menu is off in the tutorial (focus loss does not pause); the TUTORIAL button on the Rift Map is a SecondaryButton between BACK and ENTER; Settings' REPLAY TUTORIAL is removed; lesson captions and placements live in `data/tutorial/default_tutorial.tres`. | Implemented 2026-09-15; owner may retune |
| 30 | ASSUMPTION (upgrade offer build, simplest choices under §5.5): a calm moment stays open 4 game seconds (longer than the 2.2 s combo timeout, so a field clear can still offer once the combo runs out); a hit while the cards are up does not send them away; picks are refused while the cards are still sliding in (no accidental double pick), and the next banked set slides in again from below; the 6 s timeout is real time and restarts for each new set; a boss arriving closes the tray and a pending boss waits for an open tray; Back/Escape pause as usual with the cards up and Resume shows them again in slow motion; the indicator sits right of the XP bar under the pause button, a `PanelPlate` with the upgrades icon and an amber ×N; cards never take keyboard focus; in the tutorial the tray rests above the caption band, a dimmed hand taps a card once as a hint, and swiping or timing out asks for another lesson calm moment. All values in `RunProgressionTuning` (Upgrade offer). | Implemented 2026-09-15; tune on device |
| 31 | ASSUMPTION (playable characters, owner request 2026-09-17): Veyra, Rook and Morrow are cosmetic — same collision, controls, dash, health and scoring as the Wisp, and their dash is their attack; they cost 0 RP until the owner sets prices; the Shop's Wisps tab is called Characters (owner: "they are not just wisps but characters") and every card is animated (the six single-image forms idle on a shared rig); in a run a character dives along its dash, turns feet-first to land standing on whatever wall it hits (hanging from the ceiling included), coils as a pre-attack while the aim arrow is up, and plays spawn, hit, death and victory reactions; a card coming into focus or being equipped plays a selected flourish and a purchase an unlock flourish; the HUD keeps each character's still portrait. | Implemented 2026-09-17 (ADR-0015); owner approval, prices and a device pass pending; art licence as #21 |
| 32 | Owner decision 2026-09-18: add owner-approved **Ilyra, the Astral Dancer** (Mythic, high-detail four-arm rig) and **Bram, the Rift Knight** (Legendary, deliberately simpler full-body rig), in that implementation order. They extend ADR-0015's presentation-only character architecture, keep the common hitbox and all gameplay values, and use `STANDARD` / `LEGENDARY` / `MYTHIC` as display metadata only. Both stay 0 RP for review until the owner sets prices. | Implemented 2026-09-18 (ADR-0015 addendum): both rigs, `FormData.tier` and the Shop badge; catalog at eleven characters; owner approval of the motion, prices and a device pass pending; art licence as #21 |

## Change history

| Date | Change | Source |
|---|---|---|
| 2026-09-18 | Ilyra and Bram built as animated rigs; collectible tier shown on the focused Shop card (§6, §9, §11, §14 #32; ADR-0015 addendum) | ASSUMPTION #32 |
| 2026-09-18 | Approved Mythic Ilyra and Legendary Bram as presentation-only playable characters; implementation order Ilyra then Bram (§14 #32) | Owner |
| 2026-09-17 | Playable characters Veyra, Rook and Morrow (animated rigs, cosmetic only); Wisps tab renamed Characters with animated cards (§3, §6, §9, §11, §13, §14 #31; ADR-0015) | Owner request; ASSUMPTION #31 |
| 2026-09-16 | Animated Legendary/Mythic scenery rebuilt on the painting (masks, scenery shader, glow particles, Mythic set pieces): more vibrant scenery, floor only a luminance-kept saturation lift; Reduced Motion static (§6, §8, §9) | Owner feedback 2026-09-15 (device test) |
| 2026-09-15 | 30 Endless arena skins with tiers and prices; animated Legendary/Mythic scenery (§6, §14 #19, #26) | Owner decision 2026-09-15 |
| 2026-09-15 | Upgrade tray simplified to three cards and a timeout bar; UPGRADE READY indicator removed (§5.5) | Owner |
| 2026-09-15 | Upgrade offer rules: banked level-ups, UPGRADE READY indicator, cards only at calm moments, no pause — slow-motion bottom card tray with swipe/timeout dismiss; tutorial XP lesson uses it (§5.5, §5.6, §14 #29, #30) | Owner decision 2026-09-15; ASSUMPTION #30 |
| 2026-09-15 | Aim path line removed; arrow, lit targets and ×N kept (§4, §5.1) | Owner |
| 2026-09-15 | Aim help: dash-path line, lit target enemies with ×N, gentle ±6° release aim assist (AIM ASSIST, default ON); tutorial slice/chain lessons teach it (§4, §5.1) | Owner decision 2026-09-15 |
| 2026-09-15 | Tutorial screen replaces the in-run first-run lesson: nine show-then-try lessons, first launch opens it after Loading, SKIP with confirm, replay only from the Rift Map (§5.6, §11, §14 #23, #29) | Owner decision 2026-09-15; ASSUMPTION #29 |
| 2026-09-15 | RUSH and fast feel built (§5.6; §14 #27 implemented; #28 build assumptions) | Spec rush_and_feel; ASSUMPTION #28 |
| 2026-09-15 | RUSH mode, visible chain momentum, auto-collected Rift Points and slow-motion finishers (§5.6, §14 #27); Essences not planned | Owner |
| 2026-09-15 | Endless pool is every Rift's roster and boss regardless of clears (§6) | Owner |
| 2026-09-15 | PLAY starts Endless (always open); story Rifts only via RIFTS; ENDLESS button, NEW badge and arena-skin Endless gate removed (§6, §11, §14 #13) | Owner |
| 2026-09-15 | Spec 04 built: four-tab RP Shop, dash styles, Forms screen retired (§14 #18 implemented; #25) | Owner-approved plan; ASSUMPTION #25 |
| 2026-09-15 | Spec 02 built: one level per Rift run ending in victory, level-1 clears open the next Rift, victory/defeat Results, story Trials audit (§14 #12–#13 owner approved; #23) | Owner-approved plan; ASSUMPTION #23 |
| 2026-09-15 | Spec 01 built: Rift Points replace Soul Shards, Soul Sanctum removed with a refund, performance bonus; goals that counted shards count collected Rift Points (§14 #22) | Owner-approved plan; ASSUMPTION #22 |
| 2026-09-14 | Restructure: Rift story levels, cosmetic Endless mode on one floor template, earned-only Rift Points, Soul Sanctum removed, Rift Points Shop tabs, daily run on Endless rules (§1, §3, §5.5, §6, §7, §9, §11–§14; ADR-0013, ADR-0014) | Owner direction; details ASSUMPTION #12–#19 |
| 2026-09-13 | Home without bottom nav: tap the Wisp for Forms, Trials/Daily/Sanctum and Shop/Remove Ads columns, animated PLAY + Rifts under the Wisp; disabled Shop before billing (§11, §13, ADR-0012) | Owner |
| 2026-09-13 | Home redesign (animated hero + living background, PLAY with Rift caption, bottom nav); Forms and Rift Map as portrait card carousels (§11) | Owner |
| 2026-09-12 | Movement flow: mid-dash redirect, input buffering, landing-lock cancel, launch burst, chain momentum; aim line replaced by a direction arrow (§4, §5.1) | Owner |
| 2026-09-12 | Monetisation model settled: opt-in rewarded video + one Remove Ads IAP, no interstitials (ADR-0009, §14 #11) | Owner |
| 2026-09-12 | Permanent progression added: Soul Sanctum, Trials ladder, depth milestones | Owner request |
| 2026-09-12 | Rifts: five rule-variant arenas, derived unlock ladder and map UI (ADR-0007); new enemy/boss art assumed (§14 #9–10) | Owner request |
| 2026-09-12 | Playfield inset to the painted floor; sprites and hitboxes ×1.3–1.45 (ADR-0006) | Owner |
| 2026-09-11 | Art direction replaced by redesign v1 (ADR-0005) | Owner |
| 2026-09-11 | Phones-only QA; planned id `com.cognitix.wisprush`; release deferred for polish | Owner |
| 2026-09-11 | Audio ships as runtime synthesis (assumption 3) | Milestone 4 |
| 2026-09-11 | Resolved assumption 5: progression now persists locally | Milestone 3 completion |
| 2026-09-11 | Defined recurring Reaper cadence and offline daily/challenge reward defaults | Milestone 3 implementation |
| 2026-09-11 | Expanded temporary session state and defined Reaper's Gift damage reset | Milestone 2 implementation |
| 2026-09-11 | Recorded temporary session-only tutorial completion assumption | Milestone 1 implementation |
| 2026-09-11 | Replaced template with complete release-MVP design and starting tuning | Owner prompt v2 |
| 2026-09-11 | Template created | Setup |
