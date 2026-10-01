# Enemies v2 — six enemies and three bosses (design)

> **Status:** 🔄 five enemies and the first boss, Grimgrin, in the game (2026-09-28 and 2026-09-27;
> owner phone test pending) · the sixth enemy and two bosses still to make ·
> **GDD:** §5.3, §5.4, §5.5, §14 #58, #62 · **Replaced:** every old enemy and the enemy mixes' enemies
> (2026-09-28); the old bosses stay until the new ones exist
>
> **For every agent:** this folder is where the new enemies are being designed with the owner. Read
> this file for what is decided and what is still open, and
> [autosprite_workflow.md](autosprite_workflow.md) for how the art is made (AutoSprite only). Do not
> make art, prompts or code for an enemy until the owner has approved it here.

## Where we are (2026-09-28)

- **Now:** the melee boss, **Grimgrin, the Hollow Ronin** ([boss_melee.md](boss_melee.md)), a hooded
  ninja hunter with two katanas. Name, look and fight decided; **his base is generated and picked** in
  AutoSprite (vibe HD Pixel Art, no reference image).
- **Next:** his animation list is decided (floor idle, right-wall idle, two-katana planting for the
  floor and the side walls, dash attack, death; flipped and mirrored for the other walls; Death's Grin as
  effects in the second half; the throw is gone). He can be hit any time (several hits), harder while
  both katanas are planted. **His pose and animation prompts are written** (about 110 credits); the owner
  generates them. Then then the next boss or enemy, one at a time.
- **Built (2026-09-27):** the owner's six sheets are packed and **Grimgrin is in the game** as the first
  boss of every Endless run ([systems/grimgrin_boss.md](../../systems/grimgrin_boss.md)), for the owner's
  phone test. The new enemies spawn in his fight since 2026-09-28. **2026-09-28 (owner):** his
  fast attack (unhittable, kills even mid-dash, crimson warning) and a strike on every dash hit are in,
  for the owner's phone test ([boss_melee.md](boss_melee.md) §2).
- **Drafts kept:** the six enemy descriptions with suggested roles and the first three boss drafts, in
  [prompt_drafts.md](prompt_drafts.md) (none approved).
- **Enemies built (2026-09-28, owner):** the owner's five enemies — **Bone Witch, Claw Ghost, Hooded
  Scribe, Root Mask, Stone Golem** — a move and an attack sheet each (AutoSprite exports), their
  white leftovers cleaned, are in the game ([systems/enemies.md](../../systems/enemies.md)), for
  the owner's phone test. Their attacks are in §5 below.
- **Old set:** every old enemy is removed (2026-09-28, owner), and the five mixes no longer change the
  enemies. The old bosses stay for now (owner), spawning the new enemies, until the two new bosses
  exist.

## 1. Owner decisions

**2026-09-27, the set and the plan**
- **Remove everything and redesign.** All current enemies (Soul Wisp, Shard Wraith, Bone Mote,
  Cinder Shade, Warden, Rift Spawn, Frost Wisp, Court Shade, Echo, Slag Hulk), all current bosses
  (Reaper, Reaper Ascended, Cinder Maw, Hollow Choir, The Fracture) and the five enemy mixes named
  after the old Rifts go. They are removed when the new set replaces them, in one step, so the game is
  never left without enemies.
- **Start small, then add more:** 6 enemies and 3 bosses; more are added later.
- **Play till you die, never boring:** Endless has no end; what keeps it fresh is that every enemy and
  every boss is different and the game mixes them at random, run after run.
- **No upgrade ranks.** Rather than small visual upgrades of one enemy, every enemy is its own design.
- **Animated with sprite sheets, not rigs.** The owner makes the art; Claude slices, cleans and packs
  the sheets and ties every animation to what the enemy is doing, as for the characters
  ([character_creation.md](../../guides/character_creation.md)).
- **Look:** the game's pixel art ([ADR-0018](../../decisions/0018-pixel-art-direction.md)), in the
  Wisp theme; some enemies may leave the theme out, or carry it in a way that is not very visible.

**2026-09-27, the owner's answers** (the owner's words, lightly cleaned)
- **What they are:** corrupted spirits and beasts. Some can be like Patchvile in spirit, but not a
  copy of him ("Patchvile is a character, this is an enemy"); a broken wisp or spirit inside a body;
  undead: bones and ghosts; beasts "for sure": bats, moths and crows; and a mix of all of these. **Not**
  cursed objects like lanterns.
- **What they do** — the roles the owner picked:
  - **Hunter:** chases you across the walls, and it is fast.
  - **Shooter:** the owner likes this one.
  - **Trickster:** fun, something you can dodge.
  - **Trapper.**
  - **Swarm:** for the satisfying feel of killing many at once.
  - **No tank:** the player must never struggle to kill one enemy.
- **Feel:** all of them fast, easy to kill and fun. Most die in one hit; some take two, at most three.
  A kill must feel like **slicing** the enemy, not flying through it — slice effects (shaders, effects)
  on the kill.
- **Attacks:** enemies go around the Wisp on the sides, and when one gets close it attacks; they can
  attack **while the Wisp is mid-dash**. An attack that reaches the Wisp kills it: instant death, no
  revive.
- **Later, not now:** items that enemies drop and the player can use to avoid dying (the owner's
  example: the skateboard in Subway Surfers).
- **Bosses:** three, each its own design (no families of enemies). One boss summons enemies — any
  enemy it wants, at random. The other two do not summon, and while they are fought no regular enemies
  may spawn at all. Bosses are hard and have good attack animations.
- **Looks:** the owner will collect references (Pinterest) for the enemies and bosses and give
  variants before any prompt is written.
- **Tools:** there is no Codex quota; the enemies are made with AutoSprite, including its (paid)
  generator — see [autosprite_workflow.md](autosprite_workflow.md).

## 2. Rules every enemy keeps

From the GDD (§2, §5.3, §5.4, §5.5, §9) unless marked as the owner's change:
- The Wisp dashes in straight lines from edge to edge and slices what it crosses; enemies are designed
  around that.
- Arrivals are warned for at least 450–700 ms, and nothing spawns on the Wisp.
- Collision circles are slightly smaller than the art.
- There is always at least one viable dash and a safe edge.
- Difficulty rises through combinations and decision time, not unrestricted random flooding.
- One life: the Wisp starts on one fragment, the first contact ends the run, no revive (already the
  game's rule since 2026-09-24).
- **Changed by the owner (2026-09-27):** today a successful dash is safe from enemies (GDD §5.3);
  the new enemies can attack and kill the Wisp **mid-dash**.
- **Attacks are visible (owner, 2026-09-27):** what hurts the Wisp is drawn and animated — the enemy,
  its weapon, its projectile, a visibly corrupted wall — never abstract warning lines like the current
  bosses' (the Reaper's, for example). A warning is still given before an attack lands, through that
  visible thing (a wind-up, a wall starting to rot).
- Colour meaning: magenta is enemy cores, bosses and selection; amber is warnings and rewards; cyan is
  friendly and navigation.

## 3. Animations

One set of sheets per enemy and per boss (no second look).

**Enemy**

| State | What it shows | Kind | Who needs it |
|---|---|---|---|
| `move` | its normal life on screen: flying, crawling, chasing | loop | every enemy |
| `attack` | its special move, the wind-up first (a readable warning), then the strike | plays once | enemies that attack |
| `death` | the kill | plays once | every enemy |

Done in code, with no sheets: appearing (the warning ring, a quick fade and pop-in), a hit that does
not kill (a white flash, a small knock-back, a shake) and the slice effect on the kill.

**Boss**

| State | What it shows | Kind |
|---|---|---|
| `idle` | floating or waiting | loop |
| `attack_1`, `attack_2` (`attack_3`) | each attack with its wind-up | plays once each |
| `summon` | calling enemies (only the boss that summons) | plays once |
| `stunned` | the window when it can be hit | loop |
| `death` | the finish | plays once |

Done in code: the entrance and the phase change (shake, flash, colour shift).

Frame counts, frame size, the view (front-facing or side) and on-screen sizes: to be set with the
owner on the first enemy.

## 4. How a run uses them

A proposal the owner agreed with in principle (2026-09-27); the numbers are set when the enemies are:
- **Random, in order.** Each run shuffles which enemies and bosses appear and in which combinations,
  inside a ramp: it starts with one or two easy enemies, adds another every so often, sends more at
  once and faster the longer the player survives, and brings a boss at set points, picked at random
  from the three.
- **Combinations are the variety.** Enemies with different rules pair up in many ways; every enemy
  added later multiplies the combinations.

## 5. The six enemies

**Owner, 2026-09-27:** six references for the six small enemies (Pinterest, inspiration only), and
**no legs**: "how would they walk in the arena?" — every enemy is redesigned to float or fly.

The references, described (Claude's working labels):

| Ref | What it shows | Redesigned without legs as |
|---|---|---|
| Golem | a golem of dark stone chunks held together by glowing lime-green energy, floating rock fists | the body breaks into hovering rock shards below the chest |
| Doppelganger | a grey sheet ghost with glowing eyes, very long pale clawed arms, leather wrist cuffs and belt | the torn sheet trails into wisps |
| Cultist | a hooded figure in a tattered grey robe, glowing yellow eyes, holding a book leaking black smoke | the robe ends in drifting tatters |
| Eye beast | a purple, magenta-blotched beast with one huge yellow eye, fangs and golden spikes, on four legs | two clawed arms and a spiked tail |
| Wood mask | a grey wooden, mossy creature with a plank mask with three eye holes and long root-claw arms | the body ends in hanging roots |
| Witch | a skeleton witch with a pointed hat, a staff and a spellbook burning with green fire | the robe ends in tatters and smoke |

AutoSprite descriptions for all six were drafted (2026-09-27), with a suggested role each, in
[prompt_drafts.md](prompt_drafts.md); which reference takes which role is not decided yet.

| # | Role | Owner's words | Reference | Hits | Status |
|---|---|---|---|---|---|
| 1 | Hunter | chases you across the walls, fast | — | 1–3 | role picked |
| 2 | Shooter | "I really like the idea of a shooter" | — | 1–3 | role picked |
| 3 | Trickster | a fun one you can dodge | — | 1–3 | role picked |
| 4 | Trapper | picked | — | 1–3 | role picked |
| 5 | Swarm | the satisfying feel of killing many at once | — | 1–3 | role picked |
| 6 | — | not chosen yet (the owner ruled out a tank) | — | — | open |

**Built 2026-09-28** (the owner's sheets; the reference each came from, by its look):

| Enemy | Reference | Attack | Hits |
|---|---|---|---|
| Bone Witch | Witch | a bolt; where it hits a wall it leaves a small purple area the Wisp cannot touch (owner) | 1 |
| Claw Ghost | Doppelganger | swipes when close (owner, from Claude's options) | 1 |
| Hooded Scribe | Cultist | a rune that follows the Wisp "for 2 or 3 seconds", then disappears (owner) | 1 |
| Root Mask | Wood mask | lunges from a short distance (owner, from Claude's options); drawn from above | 1 |
| Stone Golem | Golem | a stone shard straight at the Wisp (owner, from Claude's options) | 1 |

Every enemy dies in one hit (owner, 2026-09-28). The melee wind-ups glow before the strike (owner: a
shader). Which role each fills was not set; the eye beast is not made yet.

## 6. The three bosses

**Owner, 2026-09-27:** one melee boss, one that attacks from a distance, and one that spawns enemies,
each from a reference the owner found (Pinterest; used as inspiration for the AutoSprite descriptions,
never uploaded — [autosprite_workflow.md](autosprite_workflow.md) §7).

| # | Role | Owner's reference | Summons? | Regular enemies during the fight | Status |
|---|---|---|---|---|---|
| 1 | **Melee: Grimgrin, the Hollow Ronin** — dashes fast and unpredictably from wall to wall, swiping (after the first phone test his dash no longer kills: it is the time to hit him, with a warning flare before it and a glow through it); sometimes makes the Wisp's wall "ill" (leave it or die); Death's Grin (effects only); no throw animation; hit any time, harder while his katanas are planted; **keeps his legs** (owner, 2026-09-27) | a hooded **ninja hunter with two katanas** (owner: "not a reaper ... more like a ninja feel or a hunter with two katanas"): crimson hood and tattered cape, black face with round glowing orange eyes and a jagged glowing grin, glowing orange ribcage and spine, limbs wrapped in off-white bandages with crimson guards and boots, curved katanas with jagged dark teal blades. Claude first misread him as a reaper with a scythe | no | **spawn at random** (no summon animation; owner, 2026-09-27) | in the game 2026-09-27; owner phone test pending |
| 2 | **Ranged** — attacks from a distance | a hooded skeleton necromancer in a long tattered dark robe with green-glowing armour, a staff topped with a lantern of green fire, green ghost skulls around him ("the green guy") | no | none may spawn | description drafted |
| 3 | **Spawner** — spawns enemies | a black stone humanoid with tall cat-like ears and glowing orange cracks, one heavy rune-block arm ("like the cat"), **really redesigned so it feels like a boss that spawns enemies** | yes — any enemy, at random | the ones it summons | description drafted |

The owner makes them **one at a time** (2026-09-27). Boss 1's full package — a proposed name, the
fight, and every AutoSprite prompt — is in [boss_melee.md](boss_melee.md).

Every boss has its own, different animations (owner, 2026-09-27). The owner tested the first three
descriptions in AutoSprite and they were not what they wanted; the melee one was redone in detail,
the other two are kept as drafts in [prompt_drafts.md](prompt_drafts.md). Still to define for each: name, its attacks (two or three), when it can be hit
(`stunned`), and its sheets.

## 7. Open questions for the owner

- The sixth enemy's role, and which reference takes which role.
- Whether the ranged and spawner bosses keep their legs or float (the melee boss keeps his).
- The enemies' size on screen (Claude's values for the phone test; the owner drew them front-facing,
  the Root Mask from above, in 256 px frames).

## Change history

| Date | Change |
|---|---|
| 2026-09-28 | Five enemies in the game from the owner's sheets (cleaned); every old enemy removed, the mixes' enemies with them; the old bosses stay for now (owner) |
| 2026-09-27 | Grimgrin in the game from the owner's six AutoSprite sheets (`GrimgrinBoss`), the first boss of every Endless run |
| 2026-09-27 | Grimgrin: the throw is gone, Death's Grin in the second half (owner); his six pose and six animation prompts written |
| 2026-09-27 | Grimgrin can be hit any time (several hits), more damage while both katanas are planted (owner) |
| 2026-09-27 | Grimgrin's animations (owner): floor idle, right-wall idle, two-katana planting for the floor and the sides, dash attack, death; flipped and mirrored for the other walls; Death's Grin as effects; no throw animation (hit window open again) |
| 2026-09-27 | Melee boss named **Grimgrin, the Hollow Ronin**; he throws one katana at a time; his base generated and picked |
| 2026-09-27 | Melee boss corrected: a ninja hunter with two katanas, not a reaper (Claude's misreading); detailed base description (1,540 characters), no reference image for the first test; the scythe prompts deleted; "Where we are" section and `prompt_drafts.md` added before the owner compacts the session |
| 2026-09-27 | Melee boss: Scythe Throw and Death's Grin added, hit only while his scythe is away, deadly unpredictable wall-to-wall dashes; his base description and settings (HD Pixel Art, Patchvile as the style reference) |
| 2026-09-27 | Attacks must be visible, not warning lines (owner); the melee boss moves wall to wall and only sometimes makes a wall ill |
| 2026-09-27 | Melee boss's attacks set by the owner: the ill wall, wall-to-wall dashes with swipes; regular enemies spawn at random in his fight |
| 2026-09-27 | `boss_melee.md`: the melee boss's package (name proposal Grimgrin, the fight, five poses, six animations, cost) |
| 2026-09-27 | Melee boss corrected to the hooded reaper with the scythe: keeps his legs, dashes toward the Wisp and across the arena; description redrafted |
| 2026-09-27 | The six enemy references; no legs for enemies (owner); six AutoSprite descriptions drafted |
| 2026-09-27 | The three bosses: melee, ranged and spawner, each from an owner's reference; AutoSprite descriptions drafted |
| 2026-09-27 | The owner's answers: themes, the five roles (hunter, shooter, trickster, trapper, swarm; no tank), feel and hits, mid-dash attacks, the bosses' summoning rules, references to come, AutoSprite only; moved into this folder with `autosprite_workflow.md` |
| 2026-09-27 | Created: the owner's decisions, the rules, the animation states and the run plan |
