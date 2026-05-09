# Visual Decisions — Reflect Phase 4 Pass

What's in the code right now and why. Anything in here can be changed
in five minutes — flag it and we move on.

---

## Universal

- **Background:** `Color.black` (true black, #000000) on every surface.
- **Text:** pure white. No tint. No accent color in the code today.
- **Font:** system default, regular weight. No custom typeface.
- **Chrome:** none during prompt display. No buttons, no labels, no
  indicators, no progress bars. The card is the whole screen.

---

## Per-platform

| Surface | Font size            | Fade duration | Padding (h/v)  | Max width |
|---------|----------------------|---------------|----------------|-----------|
| iPhone  | `.title2` regular    | 0.6s          | 36 / 48        | 640pt     |
| iPad    | `.title2` regular    | 0.6s          | 36 / 48        | 640pt     |
| Mac     | `.title2` regular    | 0.6s          | 36 / 48        | 640pt     |
| TV      | `.largeTitle` regular| 1.0s          | 120 / —        | 1400pt    |
| Watch   | `.headline`          | 0.4s          | system default | n/a       |

Faster fades on Watch (small surface, taps need quick feedback). Slower
fades on TV (signage, the slowness is the point). Hand-held devices
sit in the middle.

---

## Launch behavior

- **iPhone / iPad / Mac / Watch:** no launch title. Open straight to
  the first card with a quick fade-in. Splash screens are an app idiom;
  Reflect is not behaving like an app there.
- **TV:** launch title `"Reflect: Creative Sparks"` fades in for 2.5s,
  fades out, full second of black, then prompts begin. The TV is signage
  and signage is allowed to introduce itself.

---

## Transitions on TV (the Eno question)

Between every TV card: fade out → **1 second of pure black** → fade in.
Not crossfade. The black between cards is the silence between notes.
Crossfading turns it into a screensaver; fade-to-black makes each card
land as its own thing.

This is the part of the visual design that earns the "ambient" word.

---

## Variable dwell time on TV (the new idea)

A fixed cadence becomes wallpaper. Reflect varies the hold time on each
card by rolling a 24-sided die:

| Roll  | Hold time   | Feel                          | Frequency |
|-------|-------------|-------------------------------|-----------|
| 0–1   | 60–90s      | quick flip                    | ~8%       |
| 2–4   | 360–540s    | long contemplative hold       | ~13%      |
| 5–23  | 120–300s    | base rhythm (2–5 min)         | ~79%      |

Median is around 3 minutes — matches CLAUDE.md's spec — but the eye
keeps catching change because the rhythm isn't predictable. *Music for
Airports* isn't on a metronome. Neither is this.

Tunable in [tvOS/TVContentView.swift](../tvOS/TVContentView.swift) under
`nextDwellSeconds()`.

---

## Toast (iPhone / iPad only)

When auto mode toggles on or off, a small caption-sized line at the
bottom — `"Auto mode on"` / `"Auto mode off"` — fades in at 60% white,
holds for 2.5s, fades out. The only UI text the user ever sees that
isn't a prompt.

Not on TV (no auto-mode toggle there — TV is always ambient).
Not on Watch (no auto mode there — Watch is always interactive).

---

## What's deliberately *not* in the visual layer

- No accent color anywhere in the code right now. Pure typography.
  Strategic Claude proposed "a very cool, dim white-blue, almost like
  light on still water" as a possibility, or no accent at all. **This
  is the one open visual decision and it's Mark's call.** If we add it,
  it would go on the toast text, possibly on the launch title, and
  nowhere else. Body prompts stay pure white either way.
- No app icon work in this pass. Strategic Claude is finalizing that
  separately.
- No animation beyond opacity. No motion. No springs. The prompts don't
  slide, swipe, scale (except the Watch tap-bounce, which is tactile
  feedback, not decoration).
- No haptics outside of the Watch tap-click. iPhone/iPad get no haptics
  — they would feel like notifications.

---

## How to make Reflect feel less like a designed app

If the visual layer ever feels too "designed" — too many opinions,
too much weight, too much intention — the answer is always to subtract.
More black. More silence. Larger margins. Slower fades. Less.

That's the discipline. Don't let it become more.
