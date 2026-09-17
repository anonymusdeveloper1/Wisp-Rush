# Devlog hook library

> **Where every agent picks the hook for a Wisp Rush devlog video.** The owner chose three
> hook-teaching TikToks as the source (2026-09-16): "Use these hook ideas … do not take the design of
> the video, the look in action, just the hook ideas and how they are explained and what they do."
> So this file keeps only the **ideas**: the words, the structure and why they work. The look of
> every episode stays ours ([devlog_video_recipe.md](devlog_video_recipe.md) §3.1 visual
> treatments, §6 build). Templates below are paraphrased, not copied.

## 1. Sources

All three were watched to the end in Palmier (`inspect_media`: overview, then 12-frame windows plus the
transcript). Local copies are `video/references/hook1–3.mp4` (git-ignored). To re-download:
`yt-dlp -S "vcodec:h264,res,br" --merge-output-format mp4 -o "video/references/hookN.%(ext)s" <url>`.

| Ref | Video | What it teaches |
|---|---|---|
| HOOK-A | [@devinjatho "5 Viral Hooks"](https://www.tiktok.com/@devinjatho/video/7513580044904680747) (49 s) | Five fill-in-the-blank hook templates. Each is shown as a template with a blank word, then as a real viral video that used it |
| HOOK-B | [@kallaway.marketing, the "triple hook" method](https://www.tiktok.com/@kallaway.marketing/video/7649748540092058911) (134 s) | The test every hook must pass, in three steps: context → lean → contrarian snapback (§2) |
| HOOK-C | [@socialcontentking "3 hooks"](https://www.tiktok.com/@socialcontentking/video/7662693621451263253) (40 s) | Pattern interrupt, personal callout, unexpected number. Each is named, shown in an example, then boiled down to a one-line rule |

## 2. The test every hook passes (HOOK-B)

Read the first one or two lines on their own and check three things.

1. **Context, at once.** People only watch topics they care about, so the first line says what the
   video is about. Say it in the voice, show it in the picture and write it on screen, ideally all
   three. HOOK-B's claim: even moving the context to the second half of the first sentence makes
   skips go up sharply. For us, the game and the topic ("my arenas", "my game froze") come in the
   first words, and the series tag is on screen.
2. **Lean.** Make the viewer curious in one direction so they lean in instead of scrolling. There are
   three ways:
   - proof or a number that backs up the claim that's coming;
   - a specific pain the viewer has, or a benefit they want;
   - something surprising.
3. **Snapback.** Then pull them the other way ("but…", "except…", "actually…"). HOOK-B compares it to
   fishing: set the hook while the fish swims one way, then yank the line the other way. The new
   direction opens a question that keeps them watching. **Pay it off later in the video** and call
   back to it on screen.

Two more rules from HOOK-C:
- **Say "you" early.** It makes the viewer the subject.
- **Specifics beat vague every time.** "576 ms", not "a long time".

## 3. Spoken hook ideas

Pick **one** idea per episode (§4) and use its template so it is recognizable. Owner, 2026-09-16: a
hook that only passed the §2 test ("My arenas just got a huge glow-up. But one thing never changed.")
was rejected with "use one idea from the hook ideas I have given you". The §2 triple hook is the
check you run on the chosen idea; it is not an idea on its own. Example lines must stay true:
numbers only from [devlog_video_brief.md](devlog_video_brief.md) §4, and the footage must show the
promise straight away.

| # | Idea (source) | Template (paraphrased) | What it does | Wisp Rush lines | Best for |
|---|---|---|---|---|---|
| H1 | **Shortcut promise** (HOOK-A 1) | "[Big effort] went into [X]. You get it in under a minute." | Makes staying feel like a bargain: tiny cost (seconds) for a lot of work; also sets how long the video is | "My AI agents rebuilt all 30 arenas. Here's the whole tour in 40 seconds." | content drops, big refactors |
| H2 | **Never-again warning** (HOOK-A 2) | "Never, ever [do X] (again / without [Y])." | A hard command plus fear of a mistake the viewer might be making; they stay to learn why | "Never, ever draw effects on top of your game art. I learned that the hard way." (EP03) · "Never build a whole screen inside one frame." | rules, lessons, fixes, design mistakes |
| H3 | **Nobody shows how** (HOOK-A 3) | "Everyone says [common advice]. Nobody shows you how." | Starts from advice the viewer already knows (instant context), then points at the gap the video fills | "Everyone says 'make it juicy'. Nobody shows what that means for one swipe." | game feel, polish |
| H4 | **Can't-stop promise** (HOOK-A 4) | "How I made [X] so [good] you can't stop [doing it]." | Promises a feeling or a transformation; the payoff shot must be on screen at once | "How I made one swipe feel so good you want one more run." | game feel, mechanics |
| H5 | **I know your pain** (HOOK-A 5) | "If you've had [problem], I know the pain, and I know the fix." | Empathy builds trust; the promised fix is the reason to stay; dev viewers recognise the pain | "If your game freezes when you tap Play, I know the pain. I also know the fix." | bug fixes, performance |
| H6 | **Pattern interrupt** (HOOK-C 1) | Open on a line or picture that makes no sense until the video explains it | The contradiction breaks the scroll reflex; the brain waits for the explanation | "I deleted a whole system, and the game got better." · "My game has zero sound files. You're hearing it anyway." (all SFX and music are synthesized at runtime; re-check before using) | removals, surprises |
| H7 | **You callout** (HOOK-C 2) | Start with "you" and name something the viewer does or has noticed | "You" makes the viewer the subject, so they check whether it's about them | "You probably never noticed, but all 30 arenas share one floor." · "If you've ever missed a dash by a pixel, this one's for you." | fairness, feel, player-facing changes |
| H8 | **Unexpected number** (HOOK-C 3) | A precise, surprising number, best with a question | Specifics sound true and new; vague claims sound like ads | "576 milliseconds. That's how long my game froze on every Play tap." · "30 arenas. 3.7 megabytes. How?" | fixes, performance, content size |
| H9 | **Numbered promise** (how HOOK-A and HOOK-C open) | "[N] [things] that [result]." | Says exactly what's coming and keeps viewers until item N; number each item on screen | "Three tricks that make one swipe feel good." | lists of changes, feel |

**Topic → first choices.**

| Topic | First choices |
|---|---|
| Bug fix / performance | H5, H8, H2 |
| Design / visual change | H2, H6, H1 |
| Game feel / mechanics | H4, H3, H9, H7 |
| Content drop (skins, arenas, bosses) | H8, H1, H9 |
| Something removed or rebuilt | H6, H2, H1 |

## 4. Writing the hook

1. **Pick.** Choose one spoken idea (§3) and one visual treatment (recipe §3.1), neither used by the
   previous episode (§6 log).
2. **Write** one to three lines. The first line is at most ~3 s of voice, with the context in its
   first words. Show the same thing and put it on screen too: series tag, headline or caption.
3. **Test.** Run the §2 check: context? lean? snapback or an open loop? If a loop is opened, write
   the payoff line and plan an on-screen callback for it.
4. **Truth check.**
   - Numbers come only from brief §4.
   - Promises are shown in the same shot.
   - Comment cards follow the recipe §3.1 rules (generic viewer, never a real creator).
5. **Voice** it and read Palmier's transcript for mishearings (recipe §4).

## 5. What not to take from the sources

- **Their look:**
  - the talking head at a desk;
  - phone-screen mockups with view-count pills;
  - their title cards, fonts, colours and glow styles;
  - blurred freeze frames.
  Our look is recipe §6.
- **Their example clips** (real creators) and any view or like numbers.
- **The "comment a word and I'll send it to you" ending** (HOOK-B). We have nothing to send. Our ending
  is the question plus the follow card (recipe §3).

## 6. Hook log

Update this in the same session an episode is exported.

| EP | Spoken idea | Visual treatment (recipe §3.1) | Lines |
|---|---|---|---|
| 01 | — (older style) | — | — |
| 02 | Viewer comment answered with pain + fix (close to H5) | Viewer comment | "Why does your game freeze every time I tap Play?" → "Fair enough. It froze for over half a second." |
| 03 | H2 never-again warning | Black word card ("NEVER, / EVER.") → the old sticker effects, ringed and struck through → hurt-Wisp joke beat | "Never, ever draw effects on top of your game art." → "I learned that the hard way." (paid off at "my first effects were just shapes, drawn on top of the painting" with a "never do this!" marker note). Draft 1 opened with a glow-up wipe plus a triple-hook line and was replaced at the owner's request |
| 04 | H9 numbered promise + an open loop | Payoff first (the 8-kill slow-motion dash under a giant "4") | "Four little tricks make one swipe feel this good." → "Number four almost broke my game." (paid off by the RUSH bug: "But my first RUSH never ended.") |
