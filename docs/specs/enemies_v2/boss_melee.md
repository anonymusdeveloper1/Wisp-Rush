# Boss 1 — Grimgrin, the Hollow Ronin (melee)

> **Status:** 📝 in design (2026-09-27) · name, look and fight decided by the owner · **base generated
> and picked in AutoSprite** · his pose and animation prompts are written (below) · the owner's six
> sheets delivered and **in the game 2026-09-27** ([systems/grimgrin_boss.md](../../systems/grimgrin_boss.md)),
> owner phone test pending ·
> Part of [Enemies v2](README.md) · how the art is made: [autosprite_workflow.md](autosprite_workflow.md)

The owner makes the bosses and enemies **one at a time**, each with its own time (2026-09-27). This is
the first.

## 1. Who he is

- **Look:** the owner's reference (Pinterest, inspiration only, never uploaded): **"more like a ninja
  feel, or a hunter with two katanas"** (owner, 2026-09-27). A slim hooded figure: a crimson hood and
  tattered crimson cape, a pitch-black face with two round glowing orange eyes and a wide jagged glowing
  grin, a glowing orange ribcage and spine, arms and legs wrapped in off-white bandages with crimson
  bracers, knee and shin guards and tall crimson boots, and curved katanas with jagged dark teal blades
  and round dark guards.
- **Correction:** Claude's earlier descriptions called him a reaper with a scythe; that was a misreading
  of the reference (owner: "the character is not a reaper"). Every scythe-based prompt was dropped.
- **Role:** the **melee** boss (owner). He **keeps his legs** (owner, 2026-09-27).
- **Name: Grimgrin, the Hollow Ronin** (owner, 2026-09-27, from Claude's options): *Grimgrin* for his
  glowing grin, *ronin* for a masterless samurai with katanas, *hollow* for the glowing bones behind his
  black body.

## 2. The fight (owner, 2026-09-27)

- **How he moves:** he dashes fast from wall to wall as his normal movement, **swiping as he dashes**.
  His movement is **unpredictable** to the player. (This replaced Claude's first proposal, a dash
  straight at the Wisp: "it would have a feeling of following".)
  - **Changed after the first phone test (owner, 2026-09-27):** his dash no longer kills the Wisp ("i
    cant beat him he killes me instantly when he dashes"); **while he dashes is when you attack him**.
    An **indicator**: before each dash his eyes and glow flare (the warning), and he glows the whole
    flight. His dash is **about half as fast**, so the flight lasts longer.
  - **The fast attack (owner, 2026-09-28):** "he has one attack that he goes fast from wall to wall and
    at that attack you cant hit him, he also can attack you while you dash". From Claude's options the
    owner picked: an **extra** attack, the slow dash stays the time to hit him and sometimes he does the
    fast attack instead, at the first test's speed; touching him in it **kills the Wisp even mid-dash**,
    and a dash through him does not hurt him; **its own warning**, a crimson flare instead of the orange,
    held longer than the slow dash's. In the game: [systems/grimgrin_boss.md](../../systems/grimgrin_boss.md).
  - **A hit animation (owner, 2026-09-28):** whenever the character hits something, a short pixel-art
    strike where the dash hits, in the character's colour, drawn in code (the owner picked it from
    Claude's options; GDD §8).
- **The ill wall:** after landing, he goes to the wall the Wisp is on and makes it "ill" — **not every
  time**. If the Wisp is still on that wall, it dies. It must be **visible**: the wall is seen to rot
  (Claude's proposal: crimson rot spreading from where his blade struck, first spreading as the warning,
  then the whole wall deadly; the rot would be its own small effect animation).
- **Attacks are visible:** what hurts is drawn and animated — him, his blades, the rotting wall — never
  abstract warning lines like the current Reaper boss's. No path lines on the floor.
- **One more attack:**
  - **Death's Grin:** he grins and marks the Wisp; the next wall it lands on starts turning ill at once.
    **Only in the second half of the fight** (owner, 2026-09-27). **Done in the game with effects, no
    sprite sheet** (owner): his eyes flare more and he marks the Wisp.
- **When he can be hit (owner, 2026-09-27):** **any time**, on his walls and while he dashes (the
  dash is the main time to hit him, confirmed after the first phone test), except in his fast attack
  (owner, 2026-09-28); he takes several hits to kill. **While both
  his katanas are planted in the wall** (the ill wall), a hit **deals more damage**. How many hits and how
  much more are tuning. (This replaced "only while his thrown katana is away": there is no throw
  animation.)
- **The katana throw is gone** (owner, 2026-09-27).
- **Regular enemies spawn at random** during his fight; he has no animation for spawning them.
- Every boss has different attacks and different animations.

## 3. What to make in AutoSprite, in order

**Step 1 — the base (Discover with AI, advanced mode).** The owner's settings, 2026-09-27:
- **Vibe: HD Pixel Art** (Claude's recommendation; the other choice is 16-Bit Pixel Art). The game's
  characters (Patchvile's first frames) have many colours and no dithering; AutoSprite describes HD Pixel
  Art as clean pixel clusters without dithering and more colours than 16-bit; 16-Bit Pixel Art is 16–32
  colours with dithering.
- **Reference image: none, for the first test** (owner). A reference steers the whole result: Patchvile's
  could lend him Patchvile's colours and features, and the Pinterest image is another artist's work
  (their signature is on it; GDD §14 #21) in a painted, outlined style. The design comes from the
  description, the pixel style from the vibe. If the design is right but the pixels do not match the
  characters, Patchvile's storefront first frame
  (`concept_art/patchvile_autosprite_v1/codex_reference/patchvile_storefront.png`) is the next try, as a
  style reference.
- **Base colour:** AutoSprite's documentation does not say what it does. If it is the image's background,
  a flat colour that is nowhere on him (bright green); if it is his main colour, crimson.
- Name `Boss_Grimgrin` · Guild `Enemies` · **Humanoid ON** (he has legs) · generate 4, pick the closest,
  pose correction (1 credit) if the pick is not a calm standing pose.
- Character description (100 characters at most): `a hooded ninja hunter with two katanas and a glowing ribcage`
- The description field takes more than the API's 600 characters (owner, 2026-09-27), so the description
  is detailed (1540 characters):

```text
A slim, agile ninja hunter boss with two katanas, standing calmly, facing the viewer, full body, a katana held low in each hand. HOOD AND FACE: a deep crimson pointed hood casts his whole face into pitch-black shadow. Inside the black face there is no nose and no mouth shape, only two big round glowing orange eyes with bright yellow-orange centres, and below them a wide grin of sharp, jagged, triangular glowing orange teeth. CAPE: a long tattered crimson cape hangs from the hood down to his knees, its bottom edge torn into ragged points. BODY: a slim black body; through his chest and belly a glowing orange ribcage and spine show, like bones lit from inside. A crimson leather belt with a small pouch sits at his waist. ARMS: black arms wrapped in strips of off-white cloth bandage, with crimson leather bracers on the forearms and crimson gloves. LEGS: black legs wrapped in the same off-white bandages, crimson knee guards and shin guards, and tall crimson boots with dark grey soles and toe caps. A few loose bandage ends hang and flutter from his arms and legs. KATANAS: two long curved katanas, one in each hand, both blades of dark teal steel with a jagged, notched cutting edge, each with a round dark iron disc guard and a crimson-wrapped hilt. The blades point down and slightly outward at his sides. COLOURS: crimson and dark maroon, black, off-white bandages, glowing orange, and dark teal steel. STYLE: dark fantasy HD pixel art game sprite, crisp pixels, limited palette, bold readable silhouette; not painterly, not 3D.
```

It says both katanas are drawn. In the reference, one hand holds the jagged teal blade and the raised
hand a long curved crimson piece that may be the second katana in its scabbard; the owner decides.

**The base the owner picked (2026-09-27):** a front-facing, symmetrical, full-body standing pose on a
white background: the tall pointed crimson hood with stitch marks and a crimson scarf, the black face with
round glowing orange eyes and a jagged grin, the glowing orange ribcage and spine, a belt with a silver
buckle and a brown pouch, bandaged arms with crimson bracers and **black gloves** (the description asked
for crimson; kept), loose bandage ends, rounded crimson knee pads, bandaged shins, laced crimson boots with
dark grey toe caps, a tattered crimson cape to the shins, and two long curved teal katanas with notched
edges, round dark guards and crimson hilts, pointing down and outward. With the blades he is about as
wide as he is tall (about 940 × 920 px on the delivered image).

**Step 2 — poses, Step 3 — animations: the owner's list (2026-09-27).** Like the characters, he rests on
whichever wall he is on, and the game flips or mirrors a sheet for the matching wall:

| # | Animation | First frame | Last frame | Loops | Tier and clip | Covers |
|---|---|---|---|---|---|---|
| 1 | `floor_idle` | the base | the base | yes | turbo, 2 s (ultra if it comes out wrong) | floor idle; the ceiling is it flipped |
| 2 | `right_wall_idle` | `Grimgrin_RightWall` | `Grimgrin_RightWall` | yes | turbo, 2 s (ultra if it comes out wrong) | right-wall idle; the left wall is it mirrored |
| 3 | `plant_floor` | the base | `Grimgrin_PlantFloor` | no | ultra, 2 s | the ill wall on the floor; the ceiling is it flipped |
| 4 | `plant_wall` | `Grimgrin_RightWall` | `Grimgrin_PlantWall` | no | ultra, 2 s | the ill wall on a side wall; the other side is it mirrored |
| 5 | `dash` | `Grimgrin_Dash` | `Grimgrin_DashEnd` | no | ultra, 1–2 s | the dash attack; the game turns it toward each dash |
| 6 | `death` | the base | `Grimgrin_DeathEnd` | no | ultra, 2 s | his defeat |
| — | Death's Grin | — | — | — | **no sheet**: effects in the game (his eyes flare more, the mark on the Wisp) | second half of the fight |

No throw (gone). The ill-wall rot is a separate effect. Getting hit and his entrance are done in code.

**Settings for every animation:** custom animation, one at a time, preview before exporting; first and last
frames from the base or his Poses library as in the table; background removal **Ultra**; the same
pixel-art filter setting as the characters; frame size **512** (Claude's proposal: bosses are drawn larger
than the characters; frames can be re-extracted at another size for free); Humanoid ON.

**Step 2 — six poses (Generate pose),** each from the base character (all under 600 characters). In AutoSprite the reference is always Grimgrin's own base image.

**The right-wall pose, fixed (2026-09-27).** The first version (both boots flat on the wall, upright) came out with three legs, standing on the floor, a brick wall and grey background drawn, one katana missing and a grey blade. It now uses one clear move: he hangs from the hilt of one katana stabbed into the wall, one boot braced, the other leg hanging, the second katana free; the prompts say to draw only him, no wall or floor, exactly two arms and two legs, both blades dark teal. **Second try** (owner: "his legs are not positioned good and there is still a wall"): two legs and the katana hang came out right, but a brick wall was still drawn and the legs were bent up and tangled. The prompts now never say "wall" (image generators tend to draw what is named, even after "no"); they say "the right edge of the picture", and the legs hang below him, the near boot flat against the edge below his hips, the other leg straight down. If a wall is still drawn, it is a straight strip at the right, which the slicer can cut out of every frame. **The wall-planting end pose, third try** (owner: "it doesn't look like a wall pose, make him put his feet on the wall"; it came out standing on the floor in a lunge, pushing both hilts sideways): he now perches on the edge like a climber, side-on with his head turned to the viewer, both katanas in the edge at chest height, both boots flat on the edge below his hips, leaning back; `plant_wall` swings his hanging leg up as the second katana goes in. The wall planting now drives the second katana in beside the first; `right_wall_idle`, `plant_wall` and `Grimgrin_PlantWall` were rewritten to match.

**`Grimgrin_RightWall`**

```text
The same ninja hunter hanging high up at the right edge of the picture, off the ground, on a plain empty background. He faces the viewer. His hand nearest the right edge grips the hilt of a katana driven into the right edge, and he hangs from it, his body straight below the hilt. His legs hang beneath him: the leg nearest the right edge slightly bent, its boot sole pressed flat against the right edge below his hips; the other leg hanging straight down. His other hand holds the second katana low. Exactly two arms and two legs; both blades dark teal. Full body, same size as the reference.
```

**`Grimgrin_PlantFloor`**

```text
The same ninja hunter down on one knee on the floor, facing the viewer, having just driven both katanas point-first into the floor in front of him, one on each side, gripping both hilts, head bowed, his eyes and grin glowing brighter, his cape spread behind him. The floor is not drawn: the part of each blade inside the floor is hidden. Full body, the same size as the reference.
```

**`Grimgrin_PlantWall`**

```text
The same ninja hunter perched on the right edge of the picture like a climber, off the ground, on a plain empty background. His body is side-on, turned toward the right edge, his head turned to look at the viewer. Both katanas are driven into the right edge at chest height, part of each blade still showing, and he grips both hilts. Both boot soles are planted flat against the right edge below his hips, knees bent, his body leaning back, held by his arms. His eyes and grin glow brighter. Exactly two arms and two legs; both blades dark teal. Full body, same size as the reference.
```

**`Grimgrin_Dash`**

```text
The same ninja hunter seen from the side, flying fast toward the left in a straight line, no floor: body stretched out low and forward, head leading, both katanas held back along his sides with the blades trailing, his hood, scarf, cape and loose bandage ends streaming behind him, legs tucked back. Full body, the same size as the reference.
```

**`Grimgrin_DashEnd`**

```text
The same ninja hunter seen from the side, still flying toward the left, no floor, at the end of a double slash: both katanas swung all the way through in front of him and crossed low near his hips, his body twisted from the swing, his cape whipping around him. Full body, the same size as the reference.
```

**`Grimgrin_DeathEnd`**

```text
The same ninja hunter collapsed on his knees on the floor, facing the viewer, body slumped forward, both katanas fallen on the floor beside him, the glow of his eyes, grin and ribcage gone dark, thin crimson smoke rising from him. The floor is not drawn. Full body, the same size as the reference.
```

**Step 3 — six animations** (Claude's prompts, 2026-09-27; the owner's format CHARACTER / POSE / MOTION / TIMING / DO NOT / STYLE):

**`floor_idle`** (1785 characters)

```text
CHARACTER: Grimgrin, a slim hooded ninja hunter boss, exactly as in the reference image: a tall pointed crimson hood with stitch marks and a crimson scarf; a pitch-black face with two round glowing orange eyes and a jagged glowing orange grin; a glowing orange ribcage and spine on a black body; a belt with a silver buckle and a brown pouch; bandaged arms with crimson bracers and black gloves; loose bandage ends; rounded crimson knee pads, bandaged shins and laced crimson boots with dark grey toe caps; a tattered crimson cape to his shins; and two long curved dark teal katanas with notched edges, round dark guards and crimson hilts, one in each hand.
POSE: standing on the floor facing the viewer, both katanas held low at his sides, exactly as in the first frame.
MOTION: a menacing, alert breathing idle, not an action.
1. Breathing is the main motion: his chest and shoulders rise and fall slowly, and the glowing ribcage brightens with each breath in and dims with each breath out.
2. His eyes and grin pulse gently with the breath.
3. The cape, the tip of the hood, the scarf and the loose bandage ends sway slightly, as in a faint breeze.
4. His grip tightens on the hilts and the katanas tilt a little with his wrists, then settle back.
5. He is ready to attack: his weight shifts slightly from one foot to the other, knees soft.
TIMING: two full breaths over the loop; every movement returns to the starting pose; the last frame matches the first exactly.
DO NOT: walk, step, jump, attack, raise or swing the katanas, turn around or move across the frame; no new objects, no effects around him, no floor or shadow.
STYLE: keep his look, colours and proportions exactly as in the reference, the same size in every frame; HD pixel art, crisp pixels; not painterly, not 3D.
```

**`right_wall_idle`** (2129 characters)

```text
CHARACTER: Grimgrin, a slim hooded ninja hunter boss, exactly as in the reference image: a tall pointed crimson hood with stitch marks and a crimson scarf; a pitch-black face with two round glowing orange eyes and a jagged glowing orange grin; a glowing orange ribcage and spine on a black body; a belt with a silver buckle and a brown pouch; bandaged arms with crimson bracers and black gloves; loose bandage ends; rounded crimson knee pads, bandaged shins and laced crimson boots with dark grey toe caps; a tattered crimson cape to his shins; and two long curved dark teal katanas with notched edges, round dark guards and crimson hilts, one in each hand.
POSE: hanging high up at the right edge of the picture, off the ground, facing the viewer: he hangs from the hilt of one katana driven into the right edge, his body straight below it; the leg nearest the edge slightly bent, its boot pressed flat against the edge below his hips; the other leg hanging straight down; the second katana held low in his other hand, exactly as in the first frame.
MOTION: a menacing, alert breathing idle while he hangs, not an action.
1. Breathing is the main motion: his chest and shoulders rise and fall slowly, and the glowing ribcage brightens with each breath in and dims with each breath out.
2. His eyes and grin pulse gently with the breath; his head turns slightly, watching.
3. The cape hangs and sways slightly; the hanging leg sways a little; the scarf and the loose bandage ends flutter.
4. His bent knee flexes a little, like a spring ready to push off.
5. The free katana tilts a little with his wrist and settles back.
TIMING: two full breaths over the loop; every movement returns to the starting pose; the last frame matches the first exactly.
DO NOT: let go of the hilt, pull the katana out, move the pressed boot, jump, attack or move across the frame; exactly two arms and two legs; draw only him on a plain empty background; no new objects, no effects around him.
STYLE: keep his look, colours and proportions exactly as in the reference, the same size in every frame; HD pixel art, crisp pixels; not painterly, not 3D.
```

**`plant_floor`** (1708 characters)

```text
CHARACTER: Grimgrin, a slim hooded ninja hunter boss, exactly as in the reference image: a tall pointed crimson hood with stitch marks and a crimson scarf; a pitch-black face with two round glowing orange eyes and a jagged glowing orange grin; a glowing orange ribcage and spine on a black body; a belt with a silver buckle and a brown pouch; bandaged arms with crimson bracers and black gloves; loose bandage ends; rounded crimson knee pads, bandaged shins and laced crimson boots with dark grey toe caps; a tattered crimson cape to his shins; and two long curved dark teal katanas with notched edges, round dark guards and crimson hilts, one in each hand.
POSE: starts standing on the floor facing the viewer, both katanas low; ends down on one knee with both katanas planted point-first in the floor in front of him, as in the last frame.
MOTION: he stabs both katanas into the floor, one clear action.
1. A short, readable wind-up: he raises both katanas high over his head, blades pointing down, and his eyes and grin flare brighter.
2. He drops to one knee and drives both blades point-first deep into the floor in front of him, one on each side, in one hard motion.
3. The impact jolts through his body; his cape flares out and settles; he keeps both hands on the hilts, head bowed.
TIMING: the wind-up quick but clear, the stab fast, then a hold on the end pose.
DO NOT: move across the frame or pull the katanas out; the floor is not drawn (the part of each blade inside it is hidden); no cracks, no rot, no effects on the floor or around him.
STYLE: keep his look, colours and proportions exactly as in the reference, the same size in every frame; HD pixel art, crisp pixels; not painterly, not 3D.
```

**`plant_wall`** (2121 characters)

```text
CHARACTER: Grimgrin, a slim hooded ninja hunter boss, exactly as in the reference image: a tall pointed crimson hood with stitch marks and a crimson scarf; a pitch-black face with two round glowing orange eyes and a jagged glowing orange grin; a glowing orange ribcage and spine on a black body; a belt with a silver buckle and a brown pouch; bandaged arms with crimson bracers and black gloves; loose bandage ends; rounded crimson knee pads, bandaged shins and laced crimson boots with dark grey toe caps; a tattered crimson cape to his shins; and two long curved dark teal katanas with notched edges, round dark guards and crimson hilts, one in each hand.
POSE: starts hanging high up at the right edge of the picture from the hilt of one katana driven into the right edge, the near boot pressed against the edge, the other leg hanging, the second katana low in his other hand; ends perched on the right edge like a climber, side-on with his head turned to the viewer, both katanas driven into the edge at chest height, both boots planted flat on the edge below his hips, knees bent, leaning back, as in the last frame.
MOTION: he stabs the second katana into the right edge and sets both feet on it, one clear action.
1. A short, readable wind-up: he draws the free katana back across his body, away from the edge, and his eyes and grin flare brighter.
2. He drives it point-first into the right edge beside the first one in one hard motion, and swings his hanging leg up so both boots plant flat on the edge.
3. The impact jolts through his body; he leans back on both hilts, knees bent; his cape swings and settles.
TIMING: the wind-up quick but clear, the stab and the feet landing together and fast, then a hold on the end pose.
DO NOT: let go, move across the frame or pull the katanas out; exactly two arms and two legs; draw only him on a plain empty background (the part of each blade inside the edge is hidden); no cracks, no rot, no effects around him.
STYLE: keep his look, colours and proportions exactly as in the reference, the same size in every frame; HD pixel art, crisp pixels; not painterly, not 3D.
```

**`dash`** (1681 characters)

```text
CHARACTER: Grimgrin, a slim hooded ninja hunter boss, exactly as in the reference image: a tall pointed crimson hood with stitch marks and a crimson scarf; a pitch-black face with two round glowing orange eyes and a jagged glowing orange grin; a glowing orange ribcage and spine on a black body; a belt with a silver buckle and a brown pouch; bandaged arms with crimson bracers and black gloves; loose bandage ends; rounded crimson knee pads, bandaged shins and laced crimson boots with dark grey toe caps; a tattered crimson cape to his shins; and two long curved dark teal katanas with notched edges, round dark guards and crimson hilts, one in each hand.
POSE: seen from the side, flying fast toward the left, body stretched out low, both katanas held back along his sides, as in the first frame; ends at the end of a double slash, both katanas crossed low in front of him, as in the last frame.
MOTION: a high-speed dash attack that stays in the centre of the frame (the game moves him).
1. He streaks forward, his hood, scarf, cape and bandage ends streaming hard behind him.
2. Mid-flight he swings both katanas forward in one fast crossing double slash in front of his body.
3. He ends with both blades crossed low near his hips, his body twisted from the swing, as in the last frame.
TIMING: a short flight, the slash fast in the middle of the clip, then a hold on the end pose.
DO NOT: land, stand up, turn around or travel across the frame; no floor, no wall, no speed lines, no slash trails, no effects around him.
STYLE: keep his look, colours and proportions exactly as in the reference, the same size in every frame; HD pixel art, crisp pixels; not painterly, not 3D.
```

**`death`** (1582 characters)

```text
CHARACTER: Grimgrin, a slim hooded ninja hunter boss, exactly as in the reference image: a tall pointed crimson hood with stitch marks and a crimson scarf; a pitch-black face with two round glowing orange eyes and a jagged glowing orange grin; a glowing orange ribcage and spine on a black body; a belt with a silver buckle and a brown pouch; bandaged arms with crimson bracers and black gloves; loose bandage ends; rounded crimson knee pads, bandaged shins and laced crimson boots with dark grey toe caps; a tattered crimson cape to his shins; and two long curved dark teal katanas with notched edges, round dark guards and crimson hilts, one in each hand.
POSE: starts standing on the floor facing the viewer, both katanas low; ends collapsed on his knees, the katanas on the floor beside him, all his glow gone dark, as in the last frame.
MOTION: his defeat, one continuous fall.
1. He jolts as the final blow lands, head thrown back, and the glow of his eyes, grin and ribcage flickers.
2. Both katanas slip from his hands and fall to the floor.
3. He drops to his knees and slumps forward.
4. The glow of his eyes, grin and ribcage fades out completely, and thin crimson smoke rises from him.
TIMING: the jolt sudden, the fall slower, the fade last; hold the collapsed pose at the end.
DO NOT: get back up, fight or move across the frame; the floor is not drawn; no explosion, no effects around him beyond the thin smoke.
STYLE: keep his look, colours and proportions exactly as in the reference, the same size in every frame; HD pixel art, crisp pixels; not painterly, not 3D.
```

**Cost, from AutoSprite's published prices:** six poses × 3 = 18; the two idles on turbo 2 × 5 = 10; the
two plantings, the dash and the death on ultra 2 s, 4 × 20 = 80; **about 110 credits** before redos.

## 4. After the art

The owner sends the exports; Claude checks and cleans every frame, packs them, and builds the fight.
The AutoSprite rules of the character guide ([character_creation.md](../../guides/character_creation.md)
§3) apply.
