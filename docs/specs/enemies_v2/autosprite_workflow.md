# Making enemies and bosses with AutoSprite only

> **Why:** there is no Codex quota, so the owner makes the enemies with AutoSprite, including its paid
> character generator (owner, 2026-09-27). This is the research the owner asked for: what AutoSprite
> offers, and how to make an enemy or a boss with it alone. **Researched 2026-09-27** from AutoSprite's
> documentation, API reference, pricing page and its own guides (sources at the end). Facts are marked
> with their source; everything under "Proposal" is a recommendation, not a decision. Nothing has been
> generated.

## 1. What AutoSprite offers (facts)

| Feature | What it does | Cost | Source |
|---|---|---|---|
| **Upload** | Your image becomes the character; the base for every animation | free | API characters, deep-dive guide |
| **Discover with AI** | Generates a character from a text description: **4 variations** per generation; "Load More" for 4 more | 1 credit per 4 (turbo); pro 3, ultra 10 | deep-dive guide, pricing |
| **12 art styles** (Discover) | Random, **16-Bit Pixel Art** (SNES look: 16–32 colours, dithering, chunky pixels), **HD Pixel Art** (modern indie: Celeste, Dead Cells, Hyper Light Drifter; clean clusters, no dithering), Isometric Pixel, Retro 8-Bit, Anime, Chibi, Painterly, Flat Vector, Stylized 3D, Cinematic Realism, Realistic Portrait | — | deep-dive guide |
| **Description length** | Discover prompt up to 600 characters; `usePromptTemplate` (on by default) adds framing and background itself | — | API characters |
| **Pose correction** | Puts the character into a neutral stance for animation (fixes turned heads, crossed arms, awkward poses) | 1 credit, optional | deep-dive guide, pricing |
| **Character description** | Up to 100 characters; "especially important for non-humanoid characters" ("a blob" animates differently from "a knight") | — | deep-dive guide |
| **Humanoid toggle** | On: two legs, walks upright. Off: blobs, animals, vehicles, objects, "anything that doesn't walk on two legs". Getting it wrong is "the #1 cause of weird animations" | — | deep-dive guide |
| **Generate pose** | A new image of the same character in a described position (prompt up to 600 characters), saved in the character's Poses library; used as an animation's **first** or **last** frame | 3 credits (pricing page); the API page says 5 | pricing, API poses |
| **Custom first frame** | Generate, upload or import a pose as an animation's start | 1, or 3 with the Pro model | pricing, advanced mode |
| **Last frame** | "For non-looping animations (attacks, jumps, one-shot actions), generate a distinct ending pose" | 1 credit | advanced mode |
| **Animations** | Presets (idle, walk, run, jump, attack) or **custom** from a prompt (up to 600 characters); Motion Library (~100 clips); storyboard for multi-beat clips; Edit Animation to restyle or extend | see tiers | animation types, API spritesheets |
| **Tiers** | turbo 2 s, 5 · pro 4/6 s, 10/15 · ultra 1–6 s, 10 per second · max 4/6 s, 35/53. Free accounts are turbo only; all tiers from the Starter plan | credits | pricing |
| **Export settings** | frames 2–64 (default 25), frame size 32–512 px (default 256), background removal default or **ultra**, pixel-art filter | — | API spritesheets, advanced mode |
| **Regenerate** | Re-extract an existing animation with a new frame count, frame size, background removal, sharpening or compression | free | API spritesheets |
| **Plans** | Free: 15 credits, turbo only. Starter $12/month: 500 credits. Pro $29/month: 1,500. Extra packs: 100 for $5; 400 for $9 (subscribers) | — | pricing |

**Seen by the owner in AutoSprite, 2026-09-27** (not in AutoSprite's documentation): Discover in
advanced mode has a **vibe** setting (with 16-Bit Pixel Art and HD Pixel Art among its choices), a
**base colour** setting, and a **reference image**; its description field takes more than the API's 600
characters. What the base colour does is not documented.

AutoSprite's own tips for a generated or uploaded base (deep-dive guide): full body visible, no
cropping; a clear silhouette; a plain or transparent background; one character per image; bold,
distinct colours (they are kept more consistently than subtle grey on grey); describe **what it looks
like**, not its lore; mention important props ("with glowing eyes"). For animations: describe the exact
motion, not "attacks" (custom animations guide).

## 2. Proposal: one enemy, start to finish

1. **Base (Discover).** Style: the same pixel-art style for every enemy (see §5 on picking it). Write
   the description from the template in §3. Generate 4, look at all 4 before paying for more.
2. **Pick one.** Skip pose correction for creatures (it is for a neutral stance); use it only if the
   chosen image is in an awkward pose.
3. **Set it up.** Name `Enemy_<Name>`, guild `Enemies`, the character description (≤ 100 characters,
   what it is: "a bat", "a ghost", "a skeleton"), humanoid **off** for bats, moths, crows, ghosts, wisps
   and swarms, **on** only for two-legged undead.
4. **Poses** (Generate pose), only where an animation needs them:
   - the **end of the attack** (the attack's last frame, rule A2 of the character guide);
   - the **end of the death**, if the death should finish on a particular picture.
5. **Animations**, each with the prompt template in §4:
   - `move`: a loop, first and last frame the base; turbo first, a higher tier only if it comes out wrong.
   - `attack`: plays once, last frame the attack-end pose; ultra (1–2 s) or max (rule A1).
   - `death`: plays once.
   - Background removal **Ultra** (A5); the same pixel-art filter setting for every enemy; the same frame
     size for every enemy.
6. **Preview before exporting** (A8), then export the PNG sheets and send them. Claude cuts, cleans and
   packs them, as for the characters.

The character guide's AutoSprite rules (A1–A9 from AutoSprite's docs, B1–B6 learned on the characters,
[character_creation.md](../../guides/character_creation.md) §3) apply to enemies too.

## 3. Proposal: writing the base description (Discover)

AutoSprite adds the framing and background itself, so the description is only the creature. Keep one
**style line** and paste it unchanged into every enemy's description, so the roster looks like one game
(a consistency tip from sprite-generation guides: different style words per character make them look
like they come from different games).

Template (placeholders in brackets; the real descriptions are written from the owner's references):

```text
[what it is, in a few words], [the 2–3 features that identify it], [its colours, 2–3 bold ones],
[the Wisp theme: a trapped soul flame, glowing magenta core, cracked mask… or none], facing the viewer,
full body, [its rest pose: hovering, crouched, perched]. [STYLE LINE, the same for every enemy]
```

- Colours: the game's meaning (ADR-0018) — **magenta** for enemy cores and bosses, **amber** only for
  warnings, **cyan** is the player's side, so enemies avoid cyan as a main colour.
- Distinct, bold colours per enemy make each one readable at a glance in a fast arena, and AutoSprite
  keeps bold colours more consistently.
- A small, clear silhouette with one standout shape (big wings, a skull, a long tail) reads best at
  enemy size.

## 4. Proposal: animation prompts for enemies

The owner's format (CHARACTER / POSE / MOTION / TIMING / DO NOT / STYLE, rule B3) works here too, but
shorter: enemy animations are 600 characters at most in AutoSprite. Enemy-specific points:

- **In place.** The game moves the enemy around the arena; the sprite must animate in place: "stays in
  the centre of the frame, does not travel across it".
- **`move`:** the motion that keeps it alive — wings beating, body bobbing, a flicker — a whole number
  of cycles, the last frame matching the first (B4).
- **`attack`:** the wind-up must be readable before the strike, because the game warns the player with
  it: describe the wind-up first ("pulls back and glows brighter"), then the strike ("lunges forward and
  snaps"), one action only (A4).
- **`death`:** describe how it comes apart in place ("bursts into feathers and a fading soul flame"); the
  slice itself is added in code.

## 5. Proposal: bosses

The same steps with more states (idle, two or three attacks, summon for the boss that summons,
stunned, death). Bosses are bigger and their attacks are the show: ultra or max for every attack, a
last-frame pose for each attack, and storyboard mode (multi-beat) if an attack has several beats. The
larger size means a larger frame for bosses than for enemies; set on the first boss.

## 6. Proposal: keeping the roster consistent

- One style choice, one style line, one frame size, one pixel-filter setting and background removal
  Ultra for every enemy; bosses the same, at their own frame size.
- Pick the style once, with a small test: the first enemy's description generated in **HD Pixel Art**
  and in **16-Bit Pixel Art** (1 credit each), compared next to Patchvile and the arena in the game.
- Make the first enemy completely (base, poses, three sheets) and see it in the game before making the
  other five.

## 7. Proposal: the owner's references

Use the Pinterest references as **inspiration for the descriptions**, not as uploaded bases: an
uploaded image becomes the character, so someone else's artwork would end up in the game (the licence
question, GDD §14 #21). Discover generates an original character from the description instead.

## 8. Rough cost, from the published prices (proposal)

| Item | Credits |
|---|---|
| One enemy: Discover 1–3, poses 2 × 3, `move` turbo 5, `attack` ultra 2 s 20, `death` turbo 5 | about 40 |
| Six enemies | about 240 |
| One boss: Discover 1–3, 3–4 poses, `idle` 5, three attacks ultra 20 each, `stunned` 5, `death` 10–20 | about 100 |
| Three bosses | about 300 |
| Retries (redo when something comes out wrong) | extra |

About 550 credits for the set, before retries: the Starter plan's 500 a month plus a pack, or the Pro
plan's 1,500.

## 9. Morrow the same way (option)

> Morrow was removed from the game on 2026-10-05 (owner), with his prompt pack; this section is history.

Morrow's first frames were to come from Codex (`concept_art/morrow_autosprite_v1/PROMPTS.md`). Without
Codex, the same AutoSprite features can make them: upload his portrait (free) as the base and use
**Generate pose** for each state (floor, right wall, ceiling, dash). Not decided; the owner chooses.

## 10. Sources (checked 2026-09-27)

- [Create a Character](https://www.autosprite.io/docs/guide-create-character)
- [Custom Animations](https://www.autosprite.io/docs/guide-advanced-creation)
- [Advanced Mode](https://www.autosprite.io/docs/guide-advanced-mode)
- [Animation Types](https://www.autosprite.io/docs/reference-animation-types)
- [Credits & Pricing](https://www.autosprite.io/docs/reference-credits)
- [FAQ](https://www.autosprite.io/docs/faq)
- [API: Characters](https://www.autosprite.io/docs/api-characters),
  [API: Poses](https://www.autosprite.io/docs/api-poses),
  [API: Spritesheets](https://www.autosprite.io/docs/api-spritesheets)
- [Deep Dive: Creating Characters in AutoSprite](https://www.autosprite.io/blog/deep-dive-character-creation)
- [The Full AutoSprite Workflow](https://www.autosprite.io/blog/autosprite-full-workflow)
- [Character Consistency in AI Sprite Generation](https://www.autosprite.io/blog/character-consistency-ai-sprites)
- [AI sprite prompts that actually work](https://www.sprite-ai.art/blog/advanced-prompting-tips) (the
  shared style-keyword tip)
