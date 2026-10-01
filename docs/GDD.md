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
>
> **2026-09-25 (owner): the story Rifts are removed from the game** (§14 #48). What this document
> says about Rift levels, the Rift Map, Rift twists and Rift progress is kept as **history**; Endless
> keeps the Rifts' enemy mixes and bosses as its own (`EndlessRoster`).

## 1. Pitch

Wisp Rush is a fast, one-finger portrait survival game. Swipe and release to launch a small
purple Wisp in a straight line, slice every enemy along that line, stop at the physical screen
edge, then immediately redirect to build ricochet chains and survive escalating waves. Chase scores
in Endless on arenas you unlock with Rift Points. (History: until 2026-09-25 the pitch also had five
story Rifts, cleared level by level.)

## 2. Pillars

1. **Precise supernatural motion** — every swipe produces a fast, predictable edge-to-edge dash.
2. **Readable skill expression** — planning multi-kill lines and safe edge positions beats clutter.
3. **Immediate momentum** — aim, rush, slice, impact and restart all happen with minimal delay.

## 3. Core loop

- **Seconds:** aim → release → slice along the dash segment → wall impact → short focus → redirect.
- **Minutes (Endless):** waves with no end; build score/combo, gain XP and choose run mutations; a
  boss from the Endless boss pool arrives every four waves, and each victory makes the next cycle
  harder. (History: the removed Rift levels were four waves and one boss that cleared the level.)
- **Sessions:** earn Rift Points, unlock characters and Endless arenas, climb the Trials and play the
  daily run.

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

The Wisp begins with **one** Soul Fragment and **death is final** — there is no revive (a rewarded-ad
revive is the only one ever planned, and it is unbuilt). Contact damage removes one fragment, resets
combo and grants 750–1,000 ms invulnerability. At zero, play the death dissolve before results.
Crowded hits reform the player at a safe edge.

Nothing in a run adds a fragment (owner decision 2026-09-24): the rare **Soul Vessel** drop that
added one was removed from the game, and with it **Reaper's Gift**, whose heal had nothing left to
restore. One fragment, one life: the first contact ends the run. Only the Tutorial tops the Wisp
up, so its lessons never end in death.

### 5.4 Enemies and hazards

| Content | Role |
|---|---|
| Claw Ghost | Closes in from the side and swipes its claws when close |
| Root Mask | Crawls in and lunges at the Wisp from a short distance |
| Hooded Scribe | Keeps its distance; its rune follows the Wisp for about 2–3 s, then disappears |
| Bone Witch | Keeps its distance; its bolt flies straight and, where it hits a wall, leaves a small purple area the Wisp must not touch |
| Stone Golem | Keeps its distance; its stone shard flies straight at the Wisp |
| Split void crystal | Narrow indestructible route blocker |
| Spike bloom | Pulses before alternating safe/active states |
| Blade ring | Fixed rotating hazard with dangerous blades only |
| Void portal | Linked, visible entrances that preserve or predictably rotate dash direction |
| Obsidian pillar | Taught separately as a dash stop/bounce obstacle |

**Enemies v2** (owner, 2026-09-28, §14 #62): the five enemies above, from the owner's AutoSprite
sheets (a move and an attack each). Every one dies in one hit and the kill is a slice. They go around
the Wisp and attack; a strike, a shot or a wall mark that reaches the Wisp kills it, even mid-dash. The
melee wind-ups glow before the strike. The first set (Soul Wisp, Shard Wraith, Bone Mote and the Rift
enemies) is removed. Design: [specs/enemies_v2/](specs/enemies_v2/README.md).

Enemy arrivals telegraph for at least 450–700 ms, never spawn on the Wisp and use collision circles
slightly smaller than the art. Obstacles remain sparse and formation validation preserves at least
one viable dash and safe edge.

### 5.5 Waves, upgrades and boss

An endless threat-budget director uses at least 20 handcrafted normalized formations with mirrored
and rotated variants. Formations say where enemies arrive; which enemies come follows the Enemies v2
ramp: each run shuffles the enemies, starts with a few and adds another every few waves, drawing at
random (§14 #62). Difficulty rises through combinations and decision time,
not unrestricted random flooding.

Kills fill XP; each level-up offers three uncapped choices from six: Wide Reap, Soul Hunger, Death
Pulse, Soul Link, Cold Wake and Void Velocity. (Soul Vessel left the cards on 2026-09-19 and the game
on 2026-09-24; Reaper's Gift left on 2026-09-24.)

**Upgrade offer rules** (owner decision 2026-09-15 — upgrades came too fast and cut the player off):
- **Level-ups are banked and never interrupt.** Several can bank. A glowing **UPGRADE button** (×N for
  several) appears under the pause button, top-left; tapping it opens the cards at once. The cards also still open
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
- Same in Endless and the daily run. Banked levels not picked by the end of a run are
  lost; only picked levels count as run level.

The Reaper stops normal spawning and uses three readable phases: scythe sweep, teleport hunt and
death corridors. Its core takes at most one hit per dash and is vulnerable only during exposed
windows. Victory awards 1,500 points plus Rift Points; play continues at a harder cycle.

**Grimgrin, the Hollow Ronin** (Enemies v2, owner 2026-09-27, §14 #59) fights from the walls: he dashes
fast and unpredictably from wall to wall, swiping; his dash does not hurt the Wisp and is the time to
hit him: his eyes and glow flare before each dash and he glows through the flight (§14 #60). Sometimes
his dash is his **fast attack** instead: its own warning, a longer crimson flare, then a fast flight in
which he cannot be hit and touching him kills the Wisp, even mid-dash (§14 #61). Sometimes
(not every time) he goes to the Wisp's wall and plants both katanas: the wall visibly rots, then turns
deadly, and a Wisp still on it dies. In the second half, Death's Grin (effects only) marks the Wisp and
the next wall it lands on rots at once. Regular enemies spawn at random through his fight. He can be hit
any time (several hits); a hit while both katanas are planted counts more. Attacks are visible, with no
warning lines. Design: [specs/enemies_v2/boss_melee.md](specs/enemies_v2/boss_melee.md).

### 5.6 RUSH mode, momentum and finishers

Owner decision 2026-09-15: four base mechanics make a run feel faster, with no new buttons
([spec](specs/rush_and_feel/README.md)). They work the same in Endless and the daily run.
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

**Rifts — story mode** — **removed from the game on 2026-09-25** (owner, §14 #48). Kept here as
history; it had been out of the first release since 2026-09-24 (§14 #44).
- Five Rifts in order: Obsidian Garden → Shattered Rift → Ember Hollow → Frozen Choir → Reaper's Court.
  Each keeps its own floor shape, rule twist, enemy roster and boss ([rifts.md](systems/rifts.md)).
- Each Rift has 8 levels. A run plays one level; clearing it banks the level. Level 1 of every Rift
  starts at threat 1.0 and later levels climb that Rift's ladder
  ([ADR-0008](decisions/0008-rift-levels-and-difficulty-ladder.md)).
- Clearing level 1 of a Rift opens the next Rift. After level 8 the Rift is *mastered* and replays level 8.
- Story runs start from RIFTS → the Rift Map (or a Results follow-up), never from PLAY; a newly opened
  Rift becomes the Rift Map's selection.

**Endless**
- **PLAY always starts Endless**, open from the first launch (owner decision 2026-09-15). Every enemy
  mix and boss can appear from the start (owner decision 2026-09-15).
  Plays until death on the shared floor template
  ([ADR-0014](decisions/0014-endless-arenas-share-one-floor-template.md)) with the equipped arena skin;
  no rule twists.
- Each wave uses one of Endless's five enemy mixes (`EndlessRoster`, named after and taken from the
  removed Rifts); each boss (every 4 waves) comes from those mixes' boss pool. Beating a boss starts a
  harder cycle. Endless owns the best score and wave.
- Endless and the daily run pay the one-time depth milestones (waves 5/10/15/20/25).

**Daily run** — Endless rules with the date seed, the base roster and the Reaper only, and an arena of
the day that rotates through every Endless arena, owned or not. Missing days have no penalty.

**Rift Points (RP)** — the only currency; earned only by playing, never bought.
- Sources: pickups; a performance bonus from the run's score; level-clear bonuses (full on the first
  clear, reduced on repeats); boss rewards; Trials; daily challenges and the daily reward; depth
  milestones; the opt-in "double RP" rewarded ad.
- Spent only in the Shop. There is **no permanent power**: the Soul Sanctum is removed, and permanent
  progress is content access and cosmetics. Run-only power is the six mutations.

**Shop** — cosmetics only; nothing changes scale, anchor, hitbox, timing or rules. Prices live in `data/`.

| Tab | Items | Paid with |
|---|---|---|
| Characters | **Patchvile** (the default character, always owned; §14 #47). Whole-frame sprite characters: Patchvile, Shade, Scarlet, Mothmere and Rook, the Bonewing (a rig until 2026-09-27, §14 #56). Animated rig: Morrow, the Runebound. Card order: Patchvile, Shade, Scarlet, Morrow, Rook, Mothmere. No character has a tier (§14 #53). Ilyra was replaced by Scarlet on 2026-09-26 (§14 #52). Every character plays exactly like the Wisp and costs 0 RP while the owner reviews them (§14 #31). Void, Eclipse, Veyra and Noxen were removed on 2026-09-25 (§14 #47) | RP |
| Dashes | Trail styles: Soul (default) plus tints of the existing trail, never led by warning amber or rift magenta | RP |
| Arenas | Painted Endless arenas, one image each to the arena contract (ADR-0017): the Quarry Titan, free and the default; the Stitched Doll Jungle, kept as painted with its own floor (ADR-0020), free for now (§14 #63). Stitchwarden's Vigil, a layered, animated arena (ADR-0021) with revised art and floor (ADR-0022), free (§14 #66). The Chained Colossus, kept as painted with its own floor, free for now (§14 #67). The Chained Colossus 3D, the owner's model live in 3D with its floor a little bigger than the Vigil's, free for now (§14 #68, ADR-0023). The 3D ZOOM ARENA, the same scene opening on the whole arena and zooming in until its floor fills the whole screen, a test slot (§14 #69–#70). Prices for later arenas _TBD_ (§14 #39) | RP |
| No Ads | Remove Ads (no currency inside) and Restore Purchases | Real money ([ADR-0012](decisions/0012-store-surface-before-billing.md)) |

**Local goals** — Endless best score and wave, highest combo, the collection, Trials and three
rotating daily challenges.

## 7. Win / lose conditions & scoring

- **Endless and daily run:** no victory; death at zero Soul Fragments ends the run, and a boss victory
  is a beat, not the end.

Track score, bests (Endless, daily), combo/highest combo, kills, multi-kill dashes, wave,
bosses and Rift Points separately. Combo decay begins after 2.2 seconds without a kill; wall impact
does not reset it and damage does. Multi-kill bonuses are stepped or quadratic so alignment matters.

## 8. Game feel

- Emotional beat: focus → direction → 65 ms anticipation → explosive dash → slice → impact → breath.
- Idle animation is 3–4 FPS with gentle hover; impact is 100–180 ms; enemy dissolve 220–350 ms;
  Wisp death 450–650 ms; reform 350–500 ms.
- Aim previews and telegraphs always outrank particles. No floaty movement, muddy effects, constant
  shake, unavoidable damage or long input locks.
- Every dash hit on an enemy or a boss shows a hit animation: a short pixel-art strike where the dash
  hits, in the character's colour (owner, 2026-09-28, §14 #61).
- Reduced motion lowers shake, flashes and heavy transitions without reducing gameplay clarity.

## 9. Art direction

**The game is 2D pixel art** (owner, 2026-09-24, [ADR-0018](decisions/0018-pixel-art-direction.md)).
This covers the characters, arenas and backdrops, enemies, bosses, VFX sprites, icons, the logo, the
UI and the HUD. Everything sits on a fixed pixel grid of whole-pixel blocks with limited palettes,
crisp outlines, no anti-aliasing, gradients or blur, and nearest filtering. There is no painterly
art, and no 3D art except arenas: **arenas may be 3D** (owner, 2026-09-30, §14 #68,
[ADR-0023](decisions/0023-3d-arenas.md)), and a 3D arena does not have to be pixel-rendered. Painted
assets still in the game are legacy until redrawn.

The palette and information colours come from redesign v1 (owner-approved 2026-09-11,
[ADR-0005](decisions/0005-visual-redesign-v1.md), `concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md`);
its painterly rendering is superseded.

- Thesis: a living soul-flame cuts through an obsidian garden suspended over the void. Detailed pixel
  art at the perimeter, crisp readable silhouettes in combat; the Wisp is always the brightest small
  object on screen.
- Palette: void charcoal `#111521`, slate teal `#263D42`, soul cyan `#62E8F2`, soul white `#EAFDFF`,
  warning amber `#F3A847`, rift magenta `#B14CD9`, moss green `#5E7D4C`. Cyan, amber and magenta are
  information colours (friendly/navigation, telegraphs/rewards, enemy cores/boss/selection).
- Top-down arena with ≥ 75 % uninterrupted floor; tall scenery only in the outer 12 %.
- UI: the menus and HUD use the pixel-art component kit (`concept_art/wisp_rush_pixel_ui_v1/`,
  integrated 2026-09-24): dark stone frames with warm stitched ivory, amber actions/rewards,
  restrained cyan focus/friendly accents and magenta selected/boss accents, on the 4 px grid with
  nearest filtering. Keep dominant primary actions bottom-reachable and all text code-rendered
  ([ui_design_system.md](systems/ui_design_system.md)).
- Hierarchy: Wisp (cyan-white core) → Soul Wisp → Shard Wraith → Bone Mote → Reaper (tallest,
  darkest). Cosmetic forms keep scale, anchor and collision silhouette.
- Playable characters ([ADR-0015](decisions/0015-animated-playable-characters.md)) are whole-frame
  pixel-art sprites: five animations each, made with the AutoSprite recipe in
  [character_creation.md](guides/character_creation.md) (Patchvile is the worked example), on the same
  collision circle for everyone. **They are drawn exactly like Patchvile** (§14 #46): no outline, and
  the colours and soft edges AutoSprite's pixel filter gives, so the outline, palette and
  anti-aliasing rules above do not apply to them. The owner is reworking the whole roster onto it (2026-09-24). Until
  then Morrow is still a bone rig. Patchvile, Shade, Mothmere, Scarlet and Rook (2026-09-27) are on the recipe.
- Runtime art is generated from the concept sheets by `tools/art/extract_redesign.py`; the previous
  violet art is archived in `assets/legacy_v1/` and never ships.
- Floors: every Endless arena is one pixel-art image to the arena contract, with the floor always in the same
  place ([ADR-0017](decisions/0017-painted-arenas-with-bleed.md), [arena_art.md](guides/arena_art.md)).
  The drawn rim marks the playable area, with no code-drawn edge line.

## 10. Audio direction

Minimal dark electronic ambience grows with threat/combo; boss music deepens without medieval or
metal styling. Separate Master, Music, SFX and UI buses. Required cues cover aim, dash, slice and
multi-kill pitch steps, impact, pickup, damage/death, upgrades, Reaper actions and UI feedback. If
final files remain unavailable, use carefully tuned runtime synthesis rather than placeholder beeps.

## 11. UI & screen flow

`Loading → (first launch) Tutorial → Home → Endless run → Upgrade/Pause overlays → Results →
Play again / Home`. Home also reaches the Shop, Trials, Daily, Statistics and Settings.

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
Afterwards it is replayable from Settings → REPLAY TUTORIAL (Home-level Settings only, not the in-run
overlay), returning Home. Reduced
Motion stills the decoration; the hand gesture still plays because it is information.

**Home** (owner decision 2026-09-13, revised the same day; content updated by ADR-0013 on 2026-09-14):
pixel-art dark stone with restrained warm stitching, amber light and cyan rune accents; no bottom navigation.
- **Top:** slim top bar (Rift Points, best, Statistics, Settings) and the logo. Best is the Endless best.
- **Middle:** the equipped character rests above the central stone dais in an empty stage pocket; **tapping it opens the Shop's Characters tab**. Left column: Trials,
  Daily. Right column: Shop, Remove Ads (hidden once ads are removed).
- **Under the character**, at least 50 px below its lowest animated pixel: a caption (`ENDLESS`, or
  `ENDLESS • BEST WAVE n`), then a large animated PLAY (not full width), centred, that starts
  Endless. The pair sits a further 80 px down where the screen has room (owner, 2026-09-24: "move the
  play button a little lower"). There is no separate ENDLESS button (owner decision 2026-09-15). The
  RIFTS button beside PLAY was removed on 2026-09-24, and the story Rifts on 2026-09-25.
- **Motion:** the character keeps its authored sprite loop or menu video, with no extra whole-body float, breath or sway; its glow pulses while soul motes orbit it;
  the background comes alive (brazier flicker, rune pulse, mist, rising motes) over the pixel-art stone plate;
  PLAY breathes with a glow pulse and a periodic light sweep. No
  animation ever passes over a button. Reduced Motion stills it all.
- **Shop** has three tabs: Characters, Arenas (Endless arenas, the same card pager) and No Ads (Dashes was removed
  2026-09-19 — a dash belongs to its character). The first two spend
  Rift Points; No Ads (Remove Ads + Restore Purchases) stays disabled until billing exists
  ([ADR-0012](decisions/0012-store-surface-before-billing.md)).

**Shop tabs** are vertical card pickers: one big tall focused card in the centre, raised and framed,
neighbours peeking in dimmed; swipe sideways to browse; a description and one main button below.
Locked items stay previewable.

**Results:** Endless and the daily run show wave, score and best and the Rift Points breakdown, with
PLAY AGAIN first.

HUD (owner decision 2026-09-24): pause top-left, with the UPGRADE button under it when a level-up is
banked. Top-right: the Rift Points counter with its icon on the right, and the score under it with no
frame. Centred at the very top: the SOUL LEVEL (XP) bar with its label, then the RUSH bar, then the
boss line. There is no wave line, no "ENDLESS · WAVE n · THREAT n" (owner, 2026-09-24); wave and
boss beats are the centre callouts. There is no lives readout, since a run has exactly one fragment.
Contextual combo and focus callouts sit in the arena. Only UI respects safe-area insets; the world continues behind cutouts. All controls are
large, focusable and have visible desktop/controller focus styling.

## 12. Platforms & technical targets

- Godot 4.7.2, typed GDScript, 2D Forward+ during development.
- Android and iOS portrait release; desktop debug controls. **Portrait only**: the game is played
  vertically, never horizontally or in landscape, and the screen never rotates (owner, 2026-10-02,
  §14 #71).
- 1080×1920 design coordinates, `canvas_items` + `expand`, full physical display with no letterbox,
  card, border or fixed SubViewport. Edge-to-edge means the *presentation*: since redesign v1 the
  dashable playfield is inset to the painted stone floor ([ADR-0006](decisions/0006-inset-playfield-and-larger-sprites.md)).
- Walls: every Endless arena paints its floor in
  the one shared place (`EndlessCatalog.floor_rect`, ADR-0017), so an arena can never change the playfield.
- Stable 60 FPS on a mid-range Android phone and recent iPhone; interactive Home appears quickly.
- Offline base game, no account/backend/data collection; versioned local save under `user://`.
- QA sizes (phones only — owner decision 2026-09-11): 320×568, 360×800, 375×812, 390×844, 412×915.
  Tablets and desktop are not targets; desktop stays a debug convenience.

## 13. Scope

| Release MVP | Explicitly later / provider-dependent |
|---|---|
| Tutorial; Endless mode with painted arenas; 20+ formations; 3+ enemies; 3+ hazards; 6 mutations; 3-phase boss encounters; Rift Points Shop (6 characters: Patchvile, the default, Shade, Scarlet, Rook, Morrow and Mothmere; arena skins); daily/challenges; complete screen flow; local save/statistics/settings; final feedback; unsigned Android/iOS export configuration | Real ads, analytics, IAP/store verification, cloud saves, accounts, backend, signed store builds; paid cosmetics (custom Wisps, characters); Endless events built from the Rift twists; **Rift story mode (5 Rifts × 8 levels)** — removed from the game 2026-09-25 (§14 #48) |

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
| 6 | ASSUMPTION: taking damage resets the kill streak used by Reaper's Gift, matching combo risk/reward. | Superseded 2026-09-24: Reaper's Gift and the kill streak were removed (#45) |
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
| 19 | Owner decision 2026-09-15 (was an ASSUMPTION of three skins): the Endless catalog is the 30 skins of `concept_art/wisp_rush_endless_v1/assets/skins_manifest.json`, in manifest order, all on the one floor template; Astral Observatory is the free default; Endless (and so every skin) is open from the first launch. | Implemented 2026-09-15 (spec 05); **superseded 2026-09-23 by #39** |
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
| 31 | ASSUMPTION (playable characters, owner request 2026-09-17): Veyra, Rook and Morrow are cosmetic — same collision, controls, dash, health and scoring as the Wisp, and their dash is their attack; they cost 0 RP until the owner sets prices; the Shop's Wisps tab is called Characters (owner: "they are not just wisps but characters") and every card is animated (the six single-image forms idle on a shared rig); in a run a character dives along its dash, turns feet-first to land standing on whatever wall it hits (hanging from the ceiling included), coils as a pre-attack while the aim arrow is up, and plays spawn, hit, death and victory reactions; a card coming into focus or being equipped plays a selected flourish and a purchase an unlock flourish; the HUD keeps each character's still portrait. | Implemented 2026-09-17 (ADR-0015); owner approval, prices and a device pass pending; art licence as #21. The selected and unlock flourishes were removed 2026-09-21 (#38) |
| 32 | Owner decision 2026-09-18: add owner-approved **Ilyra, the Astral Dancer** (Mythic, high-detail four-arm rig) and **Bram, the Rift Knight** (Legendary, deliberately simpler full-body rig), in that implementation order. They extend ADR-0015's presentation-only character architecture, keep the common hitbox and all gameplay values, and use `STANDARD` / `LEGENDARY` / `MYTHIC` as display metadata only. Both stay 0 RP for review until the owner sets prices. | Implemented 2026-09-18 (ADR-0015 addendum): both rigs, `FormData.tier` and the Shop badge; catalog at eleven characters; owner approval of the motion, prices and a device pass pending; art licence as #21 · 2026-09-26: tiers removed (#53) |
| 33 | Owner decision 2026-09-20: turn the final blue/cyan handless concept into a rigged playable character with the same architecture and animation vocabulary as Morrow and Rook. **Noxen, the Veilflame** uses cloak fins, two flame horns and skinned root-flame ribbons; the dash narrows the whole body into a leading flame spear and the contact is its attack. ASSUMPTION: Legendary display tier and 0 RP while the owner reviews it. It is presentation-only and keeps the common hitbox and every gameplay value. | Basic rig, generated-art pipeline, catalog/save entry and Blade Arc dash signature implemented 2026-09-20; owner motion review, price and phone pass pending; art licence as #21 |
| 34 | Owner decision 2026-09-20: **playable characters are whole-frame sprites, not bone rigs** — rigs need too much authoring per character. The roster is cut to seven: the first and last Wisp forms (Void, Eclipse), the four existing rigs (Veyra, Rook, Morrow, Noxen) and **Ilyra**, which is the whole-frame sprite character formerly shipped as the `ilyra_2` experiment, promoted and renamed. Retired outright: Ash, Venom, Bloodmoon and Frost (Wisp forms), Bram (rig) and the previous bone-rigged Ilyra. A save naming a retired character falls back to Void; `ilyra_2` maps to `ilyra` so the experiment's owners keep it. The four surviving rigs stay until they are re-cut as frames. | Implemented 2026-09-20: catalog at seven, `RETIRED_FORM_IDS`, art and scenes removed; frame contract in `docs/guides/character_sprite_frames.md` · 2026-09-25: Void, Eclipse, Veyra and Noxen removed too (#47); five characters remain |
| 35 | ASSUMPTION (Shade, 2026-09-20): the green hooded creature ships as a playable whole-frame sprite character, the first built end to end to the contract in `docs/guides/character_sprite_frames.md`. It is presentation-only — same collision, controls, dash, health and scoring as every other character — and its dash is its attack, with a green `SOUL_FLARE` signature whose tints sit 92-94 deg clear of the reserved telegraph hues. **`STANDARD` tier and 0 RP are placeholders for owner review.** The owner shortened the display name to **SHADE** on 2026-09-20; the id stays `verdant_shade` so saves and the generated art paths keep working. `wall_right` is `wall_left` mirrored at runtime and `aim_charge` is deliberately absent, so holding the aim arrow does not change the character. | Implemented 2026-09-20: frame intake, packed sheets, two frame sets, catalog and save entry, lazy Shop cards; cut to the five animations of #36 the same day; owner sign-off on the name, tier, price and motion pending; art licence as #21 · 2026-09-25: rebuilt on the AutoSprite recipe (Patchvile's pixel count, one-shot dash attack, its own ceiling sheet) |
| 47 | Owner decision 2026-09-25: **Void, Eclipse, Veyra and Noxen are removed from the game**, with their scenes, data, runtime art, tests and source art. **Patchvile is the default character**: every new save owns and equips him, and a save that names a removed character falls back to him (no migration: unknown ids are dropped). The old Patchvile and Shade source packs are removed too (the owner's original reference images, Patchvile's particle pieces and Shade's first-frame sources are kept in the current packs), and so is the old per-frame guide. | Implemented 2026-09-25 |
| 48 | Owner decision 2026-09-25: **the story Rifts are removed from the game**: story mode, the Rift Map, the five Rifts with their rule twists (portals, shrinking floor, drift, boss rush), painted backdrops and floor polygons, level clears and bonuses, and the Rift progress in saves (save v9 drops `selected_rift`, `rift_bests`, `rift_levels`). The docs keep them as history. **Endless keeps playing exactly as before**: the Rifts' five enemy mixes and boss pool moved into `EndlessRoster`s in the same order. The currency keeps its name, Rift Points. The player-facing texts that still used the word "Rift" got owner-approved wording on 2026-09-25, applied the same day: pause `PAUSED`; Daily `DAILY RUN`, `PLAY TODAY'S RUN`, `DAILY SEED`; Results `RUN SCORE`; statistics `TIME PLAYED`; Trials `REAP THE HORDE`, `BOSS BREAKER`, `ARENA SOVEREIGN`; daily challenge `DEEP DIVER`; the Endless mix `SHATTERED WASTES`; the fallback wave callout `WAVE nn`; tutorial "The arena is yours." (internal ids keep their names). | Implemented 2026-09-25 |
| 49 | Owner decision 2026-09-25: **Mothmere keeps his outline.** The new character's Codex images carry a thin dark outline around the cream cloak; the owner chose to keep it, so he is the one exception to #46 (no outline). Everything else follows the recipe: first frames at AutoSprite's 256 px frame, 4× nearest at 1024, up to 256 colours, 194 px standing. | Implemented 2026-09-25: first frames and the owner's four AutoSprite sheets (`concept_art/mothmere_autosprite_v1/`); Mothmere is in the game. His look (owner, same day): Shop text "A moth-pale cloak, a quiet step, and a flame that reaps red.", red dash effects, a red trail instead of costume pieces, dust landing; free and Standard like the roster |
| 50 | Owner decisions 2026-09-25: **Settings scrolls on phones**: the header stays fixed and everything under it scrolls; cards and buttons pass a swipe to the scroll (a tap still presses); a swipe that starts on a slider keeps moving the slider; no scroll bar is drawn. | Implemented 2026-09-25 (`settings_screen.tscn`, `docs/systems/settings.md`) |
| 51 | Owner decision 2026-09-26: **characters share Patchvile's pixel size, not his height.** Some characters are smaller than others, and in gameplay they act the same: a character is cosmetic, so the hitbox and the attack are the same for everyone. Patchvile is the example for the pixel block size and how a character is made. Every character is drawn at AutoSprite's 256 px frame and packed at his scale (`roster_scale`); its **height is its own**, set by the owner and recorded as its pack's `standing`, which the packer's ROSTER CHECK holds the frames to (past ±5 % it warns, past ±10 % it refuses). Patchvile, Shade and Mothmere stand 194 px. Changes the height part of #43. | Implemented 2026-09-26: character guide §3–§4, ADR-0018 addendum, AGENTS.md §1, `tools/art/extract_playable_characters.py` (`standing` per pack) · **reverted the same day (#54)** |
| 52 | Owner decisions 2026-09-26: **Scarlet replaces Ilyra.** A new playable character from the owner's four Codex images (storefront, floor crouch, right wall, dash). **Ilyra is removed completely** and Scarlet is a new character with her own everything (id `scarlet`); her landing is the same as Ilyra's (a splash); her Shop text is Claude's line on the owner's "create": "A blue fan, a golden crown, and a wind that cuts."; her dash look is Ilyra's effects, larger, in her blue, from her own frames (approved suggestion D5). She **switches her fan from hand to hand** (no fixed weapon hand); in the floor crouch her fan is held by her hidden hand; she **stands 166 px** (fan top to feet), smaller than Patchvile; each pose is scaled so her head matches the storefront's (right wall ×1.22, dash ×1.38), and her fan's size then differs between poses, which is fine. The owner describes her animations, the dash included, later. | Her size: #54 (drawn 1.16× larger, the same size as everyone). Implemented 2026-09-26: the owner's four AutoSprite sheets (`concept_art/scarlet_autosprite_v1/raw/`), sliced and cleaned (the owner asked: the fan's rib gaps AutoSprite filled with grey or white, the reap's black tips), packed at `standing` 166; `ScarletVisual`, her data and effects. Ilyra's scene, art, menu video, data, tests and source art went to the Recycle Bin; a save naming her falls back to Patchvile |
| 46 | Owner decision 2026-09-25: **playable characters are drawn exactly like Patchvile**: no outline, and the colours and soft edges AutoSprite's pixel filter gives (up to 256 colours; its paletted export), at the roster size. The one-pixel outline, the 48-colour palette and hard edges in the character recipe were never owner rules and are gone. Same day: agents ask the owner before doing anything the owner did not ask for (AGENTS.md §2). | Implemented 2026-09-25: character guide §3, ADR-0018 addendum, Shade's first frames rebuilt without an outline |
| 45 | Owner decision 2026-09-24: **the Soul Vessel is removed from the game** (no drop, no pickup, no callout), and the run HUD is rearranged: pause and UPGRADE top-left, Rift Points (icon on the right) with the unframed score under it top-right, the SOUL LEVEL and RUSH bars at the very top, no lives readout. ASSUMPTION (simplest choice): **Reaper's Gift leaves the upgrade pool** (six mutations), because it heals a missing fragment and a one-fragment run never has one. The DANGER lesson now reads "One touch of the spikes ends a run. Stay clear." and points at nothing. | Implemented 2026-09-24 |
| 44 | Owner decisions 2026-09-24: **the story Rifts are not in the first release** (the RIFTS button leaves Home; the mode stays in the build, dormant), **a pixel font**, and **PLAY a little lower**. ASSUMPTIONS (simplest choices): the tutorial replay moves to Settings → REPLAY TUTORIAL (Home-level only) and returns Home. The four Trials that counted Rift level clears, which Endless can never finish (they would lock the ladder at tier 2), become Endless goals: GO DEEPER wave 6 (tier 2) and wave 8 (tier 3), which are the wave goals they replaced on 2026-09-15, and BOSS HUNTER 6 and RIFT BREAKER 9 bosses in total (tiers 6–7). The font is **Pixelify Sans** (OFL). Only its regular weight is drawn, because bolder weights thicken strokes to fractions of a pixel, and every size is a multiple of 11, one font pixel per 11 units of size. PLAY moves 64 px lower. | Implemented 2026-09-24; restoring the Rifts means putting the button back and deciding whether the level-clear Trials return |
| 54 | Owner decisions 2026-09-26, later: **every character is the same size**, in the game, the store and everywhere; #51 is reverted, so Patchvile's pixel count (194 px standing in the 256 px frame) holds for everyone again. On Home Scarlet stood above the platform's centre because she was smaller; of three options offered (draw her 1.16× bigger, only move her down, new sheets at full size) the owner chose the first, "make her bigger ... and also do that same in the game": her sheets stay at 166 px and her scene draws her 1.16× larger (`art_scale` 1.38 in a run, `menu_art_scale` 1.45 on Home and the Shop), so her pixels are 16 % larger than Patchvile's. | Implemented 2026-09-26: `scarlet_visual.tscn`; the packer's ROSTER CHECK back to 194 for everyone (Scarlet's pack keeps `standing` 166); guide, AGENTS.md, ADR-0018, PROJECT_CONTEXT and system docs reverted |
| 55 | Owner decisions 2026-09-27: **Rook moves to the AutoSprite recipe**, from the owner's five Codex images (storefront, floor crouch, right wall, a ceiling hang like a bat, the dash flying left). **He keeps his outline** (the dark rim around his bone, as Mothmere keeps his, #49) and **gets his own ceiling animation** instead of the floor flipped. | First frames delivered 2026-09-27 (`concept_art/rook_autosprite_v1/`): the images already meet the recipe (1024², 4 × 4 blocks, 90–109 colours, 776 px standing, margins ≥ 60 px), so they are copied unchanged · the owner's five AutoSprite sheets implemented 2026-09-27 (#56) |
| 56 | Owner decisions 2026-09-27: Rook's five AutoSprite sheets go into the game and **replace his bone rig**, which is removed (scene, script and body-part art). The white AutoSprite's background remover left in his frames is cleaned frame by frame (the owner reviewed the result and accepted it). His dash attack uses cells 3, 5, 7, 8, 9, 11, 14 and 17 of its sheet (flight, push, dive, tail raised, the tail swing, the swing held), with the hit on cell 9. He **keeps his current dash look** (the violet dust wake, his dust-mote and streak particles, no attack glow). The storefront is used as delivered (his wings open wide in frames 4–8). | Implemented 2026-09-27: `concept_art/rook_autosprite_v1/slice_sheet.py`, `SHEET_PACKS["rook"]` (ROSTER CHECK 202 px, +4 %), `rook_visual.*` on `WholeFrameCharacterVisual`, `test_rook_visual.gd`; owner phone test pending |
| 57 | Owner decision 2026-09-27: **every character, new or redesigned, stands centred on Home's platform** — its feet on the platform's centre and its body centred over it. | Implemented 2026-09-27: `WholeFrameCharacterVisual.menu_offset` (moves the storefront on Home and the Shop card only); Rook's (2.7, 62.5) puts his feet on the platform's centre (y 1166 in the 1080 × 1920 Home) and his body's centre line at x 540; rule in `docs/guides/character_creation.md` §6 and AGENTS.md |
| 58 | Owner decisions 2026-09-27: **every current enemy, boss and enemy mix is removed and the enemies are redesigned from scratch** — to start, **6 enemies and 3 bosses**, more added later; every enemy and boss is its own design (no upgrade ranks), and Endless mixes them at random so a play-till-you-die run never gets boring; they are animated from sprite sheets the owner makes (Codex first frame, AutoSprite sheets), not rigs; pixel art, in the Wisp theme, which some may leave out or carry only subtly. The old set is removed when the new one replaces it. | In design: [specs/enemies_v2/](specs/enemies_v2/README.md) — the owner's answers recorded 2026-09-27 (roles: hunter, shooter, trickster, trapper, swarm, no tank; one to three hits; enemies can kill the Wisp mid-dash; one boss summons, the other two fight alone; made with AutoSprite only, [autosprite_workflow.md](specs/enemies_v2/autosprite_workflow.md)); looks wait for the owner's references |
| 59 | Owner decisions 2026-09-27: **Grimgrin, the Hollow Ronin**, the first boss of the new set (#58): dashes wall to wall, fast and unpredictable, swiping, and touching him mid-dash kills the Wisp; sometimes (not every time) he makes the Wisp's wall ill (it rots, then kills a Wisp still on it); Death's Grin in the second half, done with effects (eyes flare, a mark on the Wisp); no throw; hit any time (several hits), more damage while both katanas are planted; regular enemies spawn at random during his fight, with no spawn animation; attacks visible, no warning lines; he keeps his legs. His animations: floor idle, right-wall idle, floor and wall planting, dash, death; the ceiling and left wall flipped and mirrored. | Implemented 2026-09-27 from the owner's six AutoSprite sheets (`concept_art/grimgrin_autosprite_v1/`, `GrimgrinBoss`, `BossActor`, [ADR-0019](decisions/0019-bosses-with-their-own-scene.md), `test_grimgrin_boss`). Claude's choices for the phone test, not the owner's: every number in `grimgrin_tuning.tres` (a hit while planted counts 2), he is the first boss of every Endless run (`EndlessTuning.opening_boss_id`; the daily run and the Tutorial keep the Reaper), the phase names WALL TO WALL / DEATH'S GRIN, the rot and mark drawn in code, the old enemies (Soul Wisp, Shard Wraith, Bone Mote, through the mix) spawn until the new ones exist, the Reaper's sounds · owner phone test pending |
| 60 | Owner decisions 2026-09-27, after the first phone test ("i cant beat him he killes me instantly when he dashes"): **Grimgrin's dash no longer hurts the Wisp; while he dashes is when you attack him**, and he can still be hit on his walls (a planted hit still counts double). **An indicator:** before each dash his eyes and glow flare as a warning, and he glows the whole flight. **His dash is about half as fast.** Replaces #59's "touching him mid-dash kills the Wisp". | Implemented 2026-09-27: `GrimgrinBoss` state `WARN`, `dash_warning_duration` 0.5 s (Claude's value), `dash_speed` 1500 → 750; `dash_radius_ratio` removed |
| 61 | Owner decisions 2026-09-28: **Grimgrin gets a fast attack** — "he goes fast from wall to wall and at that attack you cant hit him, he also can attack you while you dash". From Claude's options the owner picked: an **extra** attack (his slow dash of #60 stays, the time to hit him; sometimes he does the fast attack instead, at the first test's speed); touching him in it **kills the Wisp even mid-dash**, and a dash through him does not hurt him; **its own warning**, a crimson flare instead of the orange, held longer than the slow dash's. **A hit animation whenever the character hits something:** a short pixel-art strike where the dash hits an enemy or a boss, in the character's colour, drawn in code (no new art). | Implemented 2026-09-28: `GrimgrinBoss` (`is_fast_attack`, `get_dangerous_circles` in the fast flight only), `GrimgrinTuning` "The fast attack" group, `StrikeFx`. Claude's choices for the phone test: the chance (0.3), cooldowns (4 s, first after 3 s), warning 0.8 s, `fast_dash_speed` 1500, danger radius 0.25 of his height, he still glows crimson through the fast flight, an ill-wall dash is never the fast attack; the strike's look (a diagonal cut and eight sparks over four frames, 0.18 s) |
| 62 | Owner decisions 2026-09-28: **the Enemies v2 enemies are in and every old enemy is removed.** The owner's five AutoSprite enemies (Bone Witch, Claw Ghost, Hooded Scribe, Root Mask, Stone Golem), a move and an attack sheet each; the sheets had white parts, cleaned first. The range enemies' shots are done in code with the owner's shot pictures: the Hooded Scribe's follows the Wisp "for 2 or 3 seconds" and disappears; the Bone Witch's, where it hits a wall, makes a small purple area the Wisp cannot touch. From Claude's options the owner picked: the old bosses stay for now (they and Grimgrin spawn the new enemies) and the Tutorial uses the new enemies standing still; the Stone Golem shoots straight at the Wisp; the Claw Ghost swipes when close and the Root Mask lunges from a short distance, both glowing before the strike (a shader outline); every enemy dies in one hit. | Implemented 2026-09-28: `WholeFrameEnemy`, `EnemyProjectile`, `EnemyRamp`, `concept_art/enemies_v2_autosprite_v1/pack_enemies.py`; the old enemies to the Recycle Bin; the five mixes' enemy swaps and callouts removed (their rosters only carry the old bosses). Claude's choices for the phone test: every speed, size, range, cooldown and shot value, the rune's 2.5 s, the mark's size and 4 s, the ramp (two kinds, one more every two waves), the amber warning glow, the Tutorial's Hooded Scribe, the slice's look |
| 71 | Owner direction 2026-10-02: **the game is played vertically only, never horizontally or in landscape**; record it in the agent / project files or make the game not rotate. **The board:** the game is played on a full-screen board like the owner's reference image (`concept_art/boards_v1/board_01/reference/`), in pixel art with "not too big pixels"; **the HUD is in the board** — RUSH, soul level, the boss indicator, the Rift Points counter, the score and the pause button; **the upgrades open when the character is tapped**, the board shows that an upgrade is available and the character has a little light on him. Codex makes every piece as pixel art from a prompt, stored where Claude can find it. | Portrait: already locked (`orientation=1`; the APK's `screenOrientation` is portrait, read with `aapt`), now written in AGENTS.md §2, PROJECT_CONTEXT §1 and §12 here. Board: the Codex prompt `concept_art/boards_v1/board_01/CODEX_PROMPT.md` (2026-10-02). Claude's choices in it, for the owner to change: 1 art pixel = 2 game pixels (the board 540 art pixels wide), posts 36 and beams 64 / 28 art pixels, a 96-pixel floor tile kept mid-dark per the arena guide plus a light variant like the reference to compare, the slots (pause top-left, boss plate or crest in the top beam's centre, score over Rift Points top-right, soul gauge on the left post, RUSH on the right, four corner lanterns that glow for an upgrade, a count tag) and the gauge colours (soul cyan, RUSH ivory, boss magenta). Not built in the game yet |
| 70 | Owner feedback 2026-10-02 on the 3D ZOOM ARENA: "overall, I like it"; the arena's textures "should be much more polished". Changes: the HUD stays where it is, and **the arena fills the whole screen** ("let's say like that for now"), replacing #69's floor under the HUD; and **playing again from the run's dialog does not replay the zoom** — "just make the user come back and play"; from Home it still plays. | Implemented 2026-10-02: `ModelArenaVisual.play_fills_screen` (the floor as big as the whole screen allows, centred, the HUD over it: about 1080 × 2338 on 1080 × 2340); Main's restart (`_restart_run`: Results' PLAY AGAIN and the pause menu's restart) builds the run with `GameWorld.play_arena_intro` off. The texture polish is not done (how to be decided) |
| 69 | Owner direction 2026-10-01: "the whole lore of it would be you play the game in a simulation"; the owner will design the first arena; the plan for release is one arena and fewer bosses, with more bosses and enemies added before release, and what is not redesigned will be removed later — "but for now, keep it like this" (nothing removed). **The zoom intro:** a run first shows the whole arena (the holder and the scenery), then slowly zooms in until the playable area is "basically big as the screen", on a new arena slot to test it, from the 3D arena already in the game. From Claude's options the owner picked: the slot **3D ZOOM ARENA** (the CHAINED COLOSSUS 3D stays as it is); the character and enemies **grow with the floor**; the floor **fills the space under the HUD**; the zoom plays **every run, a tap skips it**. | Implemented 2026-10-01 ([ADR-0023](decisions/0023-3d-arenas.md) Addendum): `ArenaVisual` opening shot, `ModelArenaVisual.zoom_intro`, GameWorld plays it before the waves, `scenes/arenas/zoom_arena_3d.tscn`, `data/endless/skins/zoom_arena_3d.tres`, catalog, save ids, `test_endless_catalog`. Free; tier Simple and the amber accent like the other test arenas. Claude's values for the phone test are in the Addendum; Reduced Motion cuts straight to the zoomed-in floor (Claude's) |
| 68 | Owner decisions 2026-09-30: **arenas may be 3D** — asked to make an arena 3D instead of 2D pixel art; from Claude's options the owner picked "arenas may be 3D" (characters, enemies and the UI stay 2D pixel art), and then: "it doesnt have to be pixel rendered". **The Chained Colossus in 3D:** the owner's Meshy model (the colossus holding the arena board) and an image of how the arena shall look: "implement the 3d model in the arena create the background scinery and add the blue flames with godot, then rig the head and make the head move not big movements just slow and stedy breathing like movements, dont make the arena with the 3d model too small make it little bigger then the patchvile looking arena". From Claude's options the owner picked: bigger than **Stitchwarden's Vigil**; **keep both** (the CHAINED COLOSSUS image arena stays, the 3D one is added as CHAINED COLOSSUS 3D); the image's **glowing skulls** too. | Implemented 2026-09-30 ([ADR-0023](decisions/0023-3d-arenas.md)): `ArenaVisual`, `ModelArenaVisual`, `ModelArenaLayout`, `scenes/arenas/chained_colossus_3d.*`, `concept_art/arenas_v2/chained_colossus_3d/build_colossus.py`, the ghost-fire, skull, glow, sky and cloud shaders, `render_arena_still.gd`, `data/endless/skins/chained_colossus_3d.tres`, catalog, save ids, `test_endless_catalog` (the floor bigger than the Vigil's on 1080-wide phones). Free for now (as the image arena, #67). Claude's choices for the phone test: every number and look in ADR-0023's Consequences, the name CHAINED COLOSSUS 3D, the Shop line, tier Simple, the amber accent |
| 67 | Owner decisions 2026-09-30: **the Chained Colossus arena** — the owner's image (a hooded stone colossus holding a chained stone slab above the clouds, teal ghost fire, a moon), to be implemented as an image for now: "every arena has a different playable area for now because we're testing and I want to test what better feels as an image, then we can start implementing real 3D models". From Claude's options the owner picked the name **CHAINED COLOSSUS**, **free for now**, and the image **kept exactly as sent** (a black sky, which the owner thinks would feel good, waits for the 3D version). | Implemented 2026-09-30: `concept_art/arenas_v2/chained_colossus/`, `data/endless/skins/chained_colossus.tres` with its own floor ([ADR-0020](decisions/0020-an-arena-may-bring-its-own-floor.md)), the catalog and the save's arena ids. Floor x 282–667, y 470–1277 of 941 × 1672, the best-fit rectangle of a painted floor that widens slightly downward (Claude's); tier Simple, the amber accent and the Shop line are Claude's. The floor's painted emblem, the hand's shadow, the rubble and the brackets and chain over its edges are kept as painted |
| 66 | Owner revision 2026-09-30 for **Stitchwarden's Vigil** after seeing the first run: match the supplied dark pixel-art image more closely; make the board narrow with a mild tilted perspective impression while keeping rectangular playable walls; place the doll's body and both hands as in the image; move the *entire* hood and face together, with the scarf and other clothes responding; place living fire along the scythe blade. The floor should match the target image's smaller proportions but be a little bigger than the floor visible there. This replaces #65's instruction to make the Vigil floor bigger than the Stitched Doll Jungle's; the two existing arenas remain unchanged. | Implemented 2026-09-30 ([ADR-0022](decisions/0022-vigil-art-and-floor-revision.md)): revised `source_v2/` art, 120 × 264-texel rectangular floor (about 453 × 996 on 1080 × 2340), frame, moonlit jungle backdrop, separate scythe and fire, `HeadRig` for hood and face, responsive cloth shaders; Shop still and catalog floor updated. |
| 65 | Owner decisions 2026-09-30 for **Stitchwarden's Vigil**, with the kit: "Fit this as a new arena" and the two existing arenas stay as they are; it is animated, "not just an image"; "don't make the arena the playable area really small make it a little bit bigger than the arena you have just done" (the Stitched Doll Jungle) — replaces #64's narrower, smaller board; write a prompt for Codex for anything needed. Later: "there would not be 16:9 just vertical play" — replaces #64's side scenery on larger devices; and an example image of how it should look. Floor size later revised by #66. | Implemented 2026-09-30 ([ADR-0021](decisions/0021-layered-arenas.md)): `LayeredArenaVisual`, `scenes/arenas/stitchwarden_vigil.*`, `pack_vigil.py`, `ArenaSkinData.visual_scene_path`, GameWorld takes the arena rect and walls from the drawn floor, `data/endless/skins/stitchwarden_vigil.tres`, catalog, save ids, `test_endless_catalog`. Free (the kit's handoff). Claude's first choices: the floor 608 × 1216 on a 1080-wide phone (4 × 8 of the kit's tiles; the jungle's is 580 × 1142 there), the board rebuilt around it, the body behind the board with the kit's grip hands, the scythe the largest that clears the pause and UPGRADE buttons, the head 150 px under the HUD's top, the motion values, tier Simple, the amber accent, the Shop line from the kit README's words. This first floor and pose were revised by #66. |
| 64 | Owner direction 2026-09-30 for a **separate layered dark stitched-doll arena**: make the board narrower and smaller than the earlier full-height image, with a mild perspective impression but rectangular playable walls; the doll holds it from the top and watches the run; cloth waves smoothly, weapon fire visibly burns, lanterns flicker; jungle scenery includes wisps, low fog and flying creatures. On larger devices the whole arena grows and more side scenery appears; smaller devices still show the full doll and board. At the owner's request Codex named this version **Stitchwarden's Vigil**. The existing painted Stitched Doll Jungle stays. | Source kit and Claude implementation handoff in `concept_art/arenas_v2/stitched_doll_pixel_kit/`. Implemented 2026-09-30 with the owner's later changes (#65) |
| 63 | Owner decisions 2026-09-30: **the Stitched Doll Jungle arena** — the owner's night image (a giant stitched doll with a burning scythe holding the floor over jungle ruins), placed in `concept_art/arenas_v2/stitched_doll_jungle/` by Codex: "it won't be changed. Keep this arena like this for now". Its floor is not the shared one, so from Claude's options the owner picked **its own floor**: while it is equipped the walls follow its frame, the play area is narrower and the character and enemies are drawn smaller there. Name **STITCHED DOLL JUNGLE**; **free for now**. | Implemented 2026-09-30: `ArenaSkinData.floor_rect`, `EndlessArenaRules` floor getters ([ADR-0020](decisions/0020-an-arena-may-bring-its-own-floor.md)), `data/endless/skins/stitched_doll_jungle.tres`, the catalog and the save's arena ids. Measured floor x 265–679, y 450–1266 of 941 × 1672; tier Simple and the amber accent are Claude's. **Correction (ADR-0021):** the character and enemies are not drawn smaller there — GameWorld still widens the layout rect past the painted floor (756 × 1170 on 1080 × 2340), and sizes, formation placement and Grimgrin's walls follow that rect; only the walls follow the frame |
| 53 | Owner decision 2026-09-26: **characters have no tiers** — "those would not be in the game", every character is the same. The Legendary and Mythic labels (`FormData.tier`) and the Shop's tier badge are removed. Arena tiers are not affected. | Implemented 2026-09-26 (`form_data.gd`, `shop_screen.*`, the character `.tres` files, `test_form_catalog`) |
| 43 | Owner decision 2026-09-24: **the game is 2D pixel art**, not painted art: characters, arenas, enemies, bosses, VFX, icons, logo, UI and HUD, with no painterly or 3D art. The Blender tooling and the 3D character model were removed the same day. **Character pixel count (owner, same day): every character has Patchvile's.** Standing, the whole figure is 194 px tall in its 256 px AutoSprite frame (76 %). Codex draws every first frame at that share of its canvas, AutoSprite keeps it, and the packer packs every character at his scale (`roster_scale`, [character_creation.md](guides/character_creation.md) §3–§4). A rule of 2 design px per art pixel was set and dropped the same day. | Decided 2026-09-24 ([ADR-0018](decisions/0018-pixel-art-direction.md)); painted assets stay as legacy until redrawn · 2026-09-26: #51 let heights differ; reverted the same day (#54) |
| 42 | Owner decision 2026-09-24: the replacement UI component kit covers menus and the gameplay HUD in true pixel art, with the new Home's dark stone and warm stitched/amber palette, restrained cyan focus/friendly accents and magenta selected/boss accents. Deliver individual text-free PNGs and integration metadata as source only; Claude will implement the game UI separately. | Source kit delivered 2026-09-24; integrated into every menu and the HUD the same day (theme rebuilt from the kit); owner phone review pending |
| 41 | Owner decision 2026-09-23: Home uses pixel-art dark stone with warm stitched repairs and amber light, a separate pixel-art Wisp Rush wordmark, and an empty central dais for any equipped character. Remove the shared procedural idle body wobble in runs, Home and Shop; keep authored sprite loops and menu videos. | Implemented 2026-09-23; portrait screenshot reviewed, phone review pending |
| 40 | Owner decision 2026-09-23: **Patchvile's dash is one attack, not a loop** — it plays once from the launch, then the wall animation takes over on landing, and the attack is made visible with shaders (a glowing outline while dashing, a flash on the slash frame and on a kill, fading afterimages). Presentation only; the dash itself is unchanged. ASSUMPTION: the glow is pale cream, because amber is reserved for telegraphs. | Implemented 2026-09-23 (`WholeFrameCharacterVisual` attack look, `test_patchvile_visual`) first on placeholder frames; his AutoSprite dash attack replaced them 2026-09-24, and Patchvile is owner-approved as built |
| 39 | Owner decision 2026-09-23: **the thirty Endless skins are removed** and arenas are single painted images, starting with the Quarry Titan (a mining mech holding the stone floor), picked in a Shop card pager like Characters. An arena image must fit every phone without bars, blur, stretching or cropping anything that matters: it is painted 1080 × 2400 with sky and ground bleed around a 1080 × 1920 safe zone, and every arena paints the floor in the same place, so an arena stays cosmetic. ASSUMPTION: prices of later arenas follow the old tier bands until the owner sets them. | Implemented 2026-09-23 (ADR-0017, `docs/guides/arena_art.md`); the Quarry Titan still needs its 1080 × 2400 re-delivery |
| 38 | Owner decision 2026-09-21: **no bounce when a character is picked.** Focusing a Shop card, buying a character or equipping one plays no flourish, on the Shop or on Home; the card keeps its idle or its menu video. Presentation only. | Implemented 2026-09-21: the Shop and Home no longer trigger `character_selected` / `character_unlocked`; the Shop tests assert neither plays |
| 37 | Owner decision 2026-09-21: a character's **Home and Shop performance may be a pre-rendered video** generated by an image-to-video model instead of the `storefront_idle` sprite loop, starting with Shade. Menus only — gameplay stays on sprite frames. Presentation only. ASSUMPTION: Reduced Motion shows the sprite loop's held first frame rather than the video. | Implemented 2026-09-21 (ADR-0016) for Shade and Ilyra (her ready stance, owner-approved take 2); owner review on the phone pending; licence and AI-label questions as #21 · 2026-09-25: Shade's menus play its AutoSprite storefront instead; Ilyra keeps her video |
| 36 | Owner decision 2026-09-20: **a drawn character is five animations** — `dash_loop` (which is also the attack, one frame being the contact), the three wall loops `wall_bottom` / `wall_top` / `wall_left` (`wall_right` mirrored), and one `storefront_idle` for Home and the Shop card. Owner: holding the phone to aim shows only the arrow; releasing plays the dash, which is the same animation as the attack; landing shows the wall animation whichever wall it is; and there is no death or spawn animation - a killed character blinks as before and its position resets. Cut as art and carried by the controller instead: `aim_charge`, `dash_start`, `dash_end`, `attack`, `move_fly`, `hit_reaction`, `death`, `revive_spawn`, `victory`, the gameplay `idle_hover` and both storefront reactions. Presentation only; no gameplay value changes. The four bone rigs still animate the full thirteen-state vocabulary, because generating it costs them nothing. | Implemented 2026-09-20: `WholeFrameCharacterVisual._target_animation()`, the packer's two-sheet layout, Void / Eclipse / Shade re-packed at 40 frames each, Ilyra on the same rule, tests and the review board; owner review of how the run reads without the cut beats pending |

## Change history

| Date | Change | Source |
|---|---|---|
| 2026-10-02 | Portrait only, never landscape (§12); the full-screen board with the HUD built into it, upgrades by tapping the character; Codex prompt for its pixel-art pieces (§14 #71) | Owner |
| 2026-10-02 | The zoom arena fills the whole screen under the HUD it keeps; playing again from the run's dialogs skips the zoom (§14 #70) | Owner |
| 2026-10-01 | The zoom intro: a run opens on the whole arena and zooms in until the floor fills the screen under the HUD, tested on the new 3D ZOOM ARENA slot; the lore direction "you play the game in a simulation" (§6, §14 #69; ADR-0023 Addendum) | Owner |
| 2026-09-30 | Arenas may be 3D, not pixel-rendered; the Chained Colossus 3D, the owner's model live in 3D with a breathing head, blue fire, skulls and a night sky of clouds (§6, §9, §14 #68; ADR-0023) | Owner |
| 2026-09-30 | The Chained Colossus arena, the owner's image kept as sent with its own floor, free for now (§6, §14 #67; ADR-0020) | Owner |
| 2026-09-30 | Stitchwarden's Vigil revised to the owner's target image: smaller narrow floor, doll gripping the board with its whole hood and face turning, clothes responding and flame along the scythe (§14 #66; ADR-0022) | Owner |
| 2026-09-30 | Stitchwarden's Vigil in the game: the first layered, animated arena, its playable area a little bigger than the Stitched Doll Jungle's, vertical play only (§6, §14 #65; ADR-0021) | Owner |
| 2026-09-30 | Stitchwarden's Vigil layered arena direction and source kit; runtime implementation pending (§14 #64) | Owner direction; name chosen by Codex at owner's request |
| 2026-09-30 | The Stitched Doll Jungle arena, kept as painted with its own floor, free for now (§6, §14 #63; ADR-0020) | Owner |
| 2026-09-28 | Enemies v2 in the game: five enemies and their attacks; every old enemy removed (§5.4, §5.5, §14 #62) | Owner |
| 2026-09-28 | Grimgrin's fast attack (unhittable, kills even mid-dash, crimson warning); a strike on every dash hit (§5.5, §8, §14 #61) | Owner |
| 2026-09-27 | Grimgrin's dash no longer kills; it is the time to hit him, with a warning flare and a glow; half speed (§5.5, §14 #60) | Owner |
| 2026-09-27 | Grimgrin, the Hollow Ronin, in the game: his fight (§5.5, §14 #59) | Owner |
| 2026-09-27 | Enemies redesigned from scratch: 6 enemies and 3 bosses to start, sprite-sheet animated, mixed at random; the current set removed when it is replaced (§14 #58) | Owner |
| 2026-09-27 | Every character, new or redesigned, stands centred on Home's platform; Rook centred (§14 #57) | Owner |
| 2026-09-27 | Rook in the game as a whole-frame character from his AutoSprite sheets; his bone rig removed (§3, §14 #56) | Owner |
| 2026-09-27 | Rook to the AutoSprite recipe: his outline kept, his own ceiling animation (§14 #55) | Owner |
| 2026-09-26 | Every character the same size again, #51 reverted; Scarlet drawn 1.16× larger (§14 #54) | Owner |
| 2026-09-26 | Scarlet in the game; Ilyra removed completely (§6, §9, §13, §14 #52); character tiers removed (§6, §14 #53) | Owner |
| 2026-09-26 | Characters share Patchvile's pixel size but each has its own height (§14 #51, ADR-0018 addendum); Scarlet replaces Ilyra, her first frames approved at 166 px (§14 #52) | Owner |
| 2026-09-25 | Settings scrolls with no scroll bar (§14 #50); Mothmere's look recorded (§14 #49) | Owner |
| 2026-09-25 | Mothmere joins the roster (6 characters; §13 scope row, §14 #49) | Owner |
| 2026-09-25 | Mothmere keeps his outline, the one exception to the no-outline rule (§14 #49) | Owner |
| 2026-09-25 | Player-facing "Rift" texts reworded (pause, Daily, Results, statistics, Trials, daily challenge, Endless mix, wave callout, tutorial); the currency stays Rift Points (§14 #48) | Owner |
| 2026-09-25 | Story Rifts removed; Endless keeps their enemy mixes and bosses; Rift sections kept as history (§1, §3, §6, §7, §9, §11, §12, §14 #48) | Owner |
| 2026-09-25 | Roster cut to five (Void, Eclipse, Veyra, Noxen removed); Patchvile is the default character (§6, §9, §13, §14 #47) | Owner |
| 2026-09-25 | Shade rebuilt on the AutoSprite recipe; its menus play the storefront instead of the video (§9, §14 #35, #37) | Owner |
| 2026-09-25 | Playable characters drawn exactly like Patchvile: no outline, AutoSprite's colours and soft edges (§9, §14 #46, ADR-0018 addendum) | Owner |
| 2026-09-24 | Run HUD: the wave line (`ENDLESS · WAVE n · THREAT n`) removed (§11) | Owner |
| 2026-09-24 | Soul Vessel removed; Reaper's Gift out of the pool (six mutations); run HUD rearranged (§5.3, §5.5, §6, §11, §13, §14 #45) | Owner |
| 2026-09-24 | Story Rifts out of the first release (RIFTS button removed; tutorial replay in Settings; level-clear Trials become Endless goals); pixel font; PLAY lower (§6, §11, §13, §14 #44) | Owner |
| 2026-09-24 | The game is 2D pixel art; painterly and 3D art superseded (§9, §14 #43, ADR-0018) | Owner |
| 2026-09-24 | Pixel-art menu and HUD component source kit delivered for later integration (§9, §14 #42) | Owner |
| 2026-09-23 | Pixel-art Home stage and wordmark; authored character motion retained while procedural idle body wobble is removed (§11, §14 #41) | Owner |
| 2026-09-23 | Patchvile's dash is a one-shot attack with an attack look (outline, flash, afterimages) (§14 #40) | Owner |
| 2026-09-23 | Endless arenas: thirty skins removed, one painted arena (Quarry Titan), arena image contract with bleed, Shop ARENAS a card pager (§6, §14 #39; ADR-0017) | Owner |
| 2026-09-21 | No pick, buy or equip bounce on character cards or the Home hero (§14 #38; supersedes the flourishes in #31) | Owner |
| 2026-09-21 | Home and Shop may play a pre-rendered character video instead of the storefront sprite loop (§14 #37, ADR-0016) | Owner |
| 2026-09-20 | A drawn character is **five animations**: the dash (which is the attack), three wall loops and one storefront idle. Eleven animations cut as art and carried by the controller instead (§14 #36) | Owner |
| 2026-09-20 | Noxen, the Veilflame added from the approved blue/cyan handless concept as a presentation-only Legendary rig; temporary 0 RP review price (§14 #33) | Owner request; tier/price ASSUMPTION #33 |
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
| 2026-09-19 | §5.3: a run starts on **one** Soul Fragment, death is final, and fragments are found as rare **Soul Vessel** drops with no cap (SOUL VESSEL left the upgrade tray). Shop dropped to three tabs — a dash belongs to its character | Owner decision 2026-09-19 |
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
