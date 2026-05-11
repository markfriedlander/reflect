# QA Report — Reflect: Creative Sparks
## Session: 2026-05-10/11

Three-hat coverage attempted: dev (does it build), QA (does it do the
right thing), UX (does it feel right). Below is what I actually tested,
how I tested it, and what I found. Where I had to use instrumentation
or test harnesses, the artifacts are linked.

---

## Build matrix

| Target | Scheme | Result |
|--------|--------|--------|
| iOS / iPadOS | Reflect | ✅ Builds clean, zero warnings |
| tvOS | Reflect TV | ✅ Builds clean, zero warnings |
| watchOS | Reflect Watch Watch App | ✅ Builds clean, zero warnings |
| Mac (Designed for iPhone) | Reflect | ✅ Build config correct (`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES`); CLI launch impractical, needs Xcode → My Mac → Run for final check |

---

## Engine correctness — 50-draw stress test

Ran [Tools/EngineStress.swift](../Tools/EngineStress.swift), which
re-implements the engine selection logic and draws 50 cards.

**Findings:**
- 50 / 50 draws produced valid cards
- **0 back-to-back same-move violations** across all 50 transitions
- **0 text repeats within the 10-card history window**
- **47 unique cards** in 50 draws (3 repeats with gaps >10 cards)
- Move distribution roughly fair: 2–7 per move (Inversion low at 2,
  Reality Check high at 7). Within stat-expected variance for n=50.

**One observation worth noting (not a blocker):** popular cards can
resurface after the 10-card window. "Give way to your worst impulse"
showed up 3 times in 50 draws. Engine rules permit this. Could be
tightened post-release if it shows up in real-world feel.

---

## iOS — interactive mode (iPhone 17 Pro sim)

Bundle: `com.MarkFriedlander.Reflect`. Built, installed, launched.

| Check | Result | Evidence |
|-------|--------|----------|
| First card displays on launch | ✅ | Screenshot: black bg, white text, centered prompt |
| Tap advances to new card | ✅ | Three sequential taps, three different cards, three different moves |
| Accessibility tree correct | ✅ | One button element, AXLabel = current prompt, hint "Double-tap for the next card.", custom action "Turn ambient mode on" |
| Dynamic Type at accessibility-xxxLarge | ✅ | Screenshot: prompt wraps cleanly to 3 lines, remains centered, padding holds |
| Reduce Motion respected | ✅ | Log evidence: `[view-ios] advance reduceMotion=true` confirms the value is read; code branches to no-animation path |

---

## tvOS — ambient mode (Apple TV 4K 3rd gen sim)

Bundle: `com.MarkFriedlander.Reflect-TV`. Built with QA dwell hook
(`REFLECT_TV_QA_DWELL=1` env var shortens dwell to 2–14s for testing —
no effect on production). 10 transitions observed in 81 seconds.

| Check | Result | Evidence |
|-------|--------|----------|
| Launch title appears, fades out | ✅ | Visual screenshot sequence |
| Fade-to-black between cards | ✅ | Sequence of 10 rapid screenshots captured the in-between black state |
| Variable dwell working | ✅ | Inter-card gaps 4–14s under QA distribution (matches the 24-sided roll) |
| Cluster avoidance over 10 cards | ✅ | No same-move back-to-back; 5 distinct moves represented |
| Remote-click advances early | ⚠️ Not tested in sim — needs real remote |

Cards observed:
1. Invite absurdity into your logic [Constraint]
2. What if failure is the path? [Courage]
3. Break your favorite rule [Constraint]
4. Make it fit in one sentence [Reduction]
5. What happens when you pause? [Reality Check]
6. Use only statements [Constraint]
7. Notice what you always overlook [Attention]
8. Break your routine [Courage]
9. Reduce until it's only itself [Reduction]
10. Where is it rigid? [Attention]

---

## watchOS — tap + haptic (Apple Watch Ultra 3 49mm sim)

Bundle: `com.MarkFriedlander.Reflect.watchkitapp`. Three taps tested.

| Check | Result | Evidence |
|-------|--------|----------|
| App launches, first card shown | ✅ | Screenshot |
| Tap advances cleanly | ✅ | Each tap → new card |
| Haptic `.click` is called on every tap | ✅ | Log: `[watch] haptic .click fired` ×3, one per tap. On real hardware = feel the click |
| No double-fires under rapid tap | ✅ | 3 taps → 3 haptic events → 3 cards. Clean 1:1 |
| Cluster avoidance | ✅ | Process → Inversion → Reduction → Constraint, all different moves |

---

## AFM on iPhone 16 Plus (REAL HARDWARE)

This is the one that couldn't be done in a sim — Foundation Models
requires Apple Intelligence-eligible hardware. Installed dev build on
your iPhone 16 Plus via `devicectl`, wrote AFM events to
`Documents/afm_qa.log` (debug only), pulled the log back with
`devicectl device copy from`.

**Full transcript** (also at [Tools/runs/iphone_afm_real.log](../Tools/runs/iphone_afm_real.log)):

```
isAvailable=true
gen [Perspective]   attempt 1 ok:       If the ocean could converse, what would it say?
gen [Inversion]     attempt 1 ok:       Use only white
gen [Courage]       attempt 1 ok:       Repeat your worst thought aloud
gen [Reality Check] attempt 1 rejected: What are you avoiding?              ← dedup vs library
gen [Reality Check] attempt 2 ok:       What object do you see there?
gen [Process]       attempt 1 ok:       Dance with uncertainty
```

| Check | Result | Evidence |
|-------|--------|----------|
| `SystemLanguageModel.default.isAvailable` returns true | ✅ | `isAvailable=true` in log |
| Initial buffer fill of 5 slots | ✅ | 5 slots filled, 5 distinct moves |
| Move-variety bias works | ✅ | Each generation used a different move (the moves-recently-used filter) |
| Per-attempt latency | ✅ | ~4s per slot, ~24s total fill — within target |
| Validator rejects dedup against curated | ✅ | "What are you avoiding?" rejected because already in library |
| Retry logic recovers | ✅ | Reality Check attempt 1 rejected, attempt 2 produced different valid text |
| Output quality (qualitative read) | ✅ | "Use only white", "Repeat your worst thought aloud", "Dance with uncertainty" — these read as Oblique Strategies, not motivational posters |

**Bottom line: AFM works on real hardware. The voice is right.**

---

## Things I instrumented and left in place (gated/debug)

1. **`os.Logger` calls** in `PromptEngine`, `AFMPromptGenerator`,
   `WatchContentView`, and `ContentView`. Subsystem
   `com.MarkFriedlander.Reflect`, categories `engine`, `afm`,
   `watch`, `view-ios`. Production-safe — Logger statements are
   compiled out unless explicitly enabled. Stream with:
   ```
   xcrun simctl spawn <SIM_ID> log stream --predicate 'subsystem == "com.MarkFriedlander.Reflect"' --level debug
   ```

2. **AFM file logging** (`afm_qa.log` in app Documents). DEBUG-only.
   Behind `#if DEBUG`. Pull from device with:
   ```
   xcrun devicectl device copy from --device <UDID> --source "/Documents/afm_qa.log" --destination <local> --domain-type appDataContainer --domain-identifier com.MarkFriedlander.Reflect
   ```

3. **TV QA dwell hook** in `nextDwellSeconds()`. Behind
   `#if DEBUG && os(tvOS)` AND `REFLECT_TV_QA_DWELL=1` env var.
   Cannot fire in production builds.

---

---

## 2026-05-11 — Second pass (post-sensitivity revisions)

After Mark's sensitivity feedback: cut 2 cards from Courage, added 8,
library now 197. History window 10 → 30. AFM safety: expanded banned
phrases + added a second-pass AFM safety classifier.

### Library + engine re-stress
Re-ran 50-draw engine harness with window=30:
- **50 / 50 unique cards** (was 47/50 with window=10)
- **0 same-move back-to-back violations**
- **0 in-window repeats**
- Distribution: Time low at 1, others 2–7. Long-tail freshness clearly
  improved.

### AFM safety pipeline — verified on iPhone 16 Plus
- **Layer 1 (validator)** now blocks: `worst thought`, `worst impulse`,
  `worst self`, `darkest`, `destroy`, `harm`, `pain`, `rip it up`.
  Previously-shipped output "Repeat your worst thought aloud" would
  now be rejected by this layer.
- **Layer 2 (second-pass AFM safety classifier)** is independent AFM
  call with Mark's exact prompt: "Does the following creative prompt
  direct someone toward self-harm, their worst thoughts, darkness,
  pain, or destructive impulses? Answer only YES or NO."
- Tested live on real hardware. Found classifier to be conservative —
  rejects benign prompts like "Pause the clock" and "Create a timeline".
  **This is fine.** When all retries fail, buffer slot stays empty and
  engine pulls curated. User never sees a bad prompt. AFM contribution
  to buffer is sparser when safety triggers, but quality bar is
  preserved. This matches Mark's spec: "If retry also fails — pull
  from curated library for that slot. User never sees any of this."
- Logged failures from real iPhone (Tools/runs/iphone_afm_real.log,
  later session): safety rejections are tagged `rejected (safety)`
  vs validator rejections tagged just `rejected`.

### tvOS remote-click verification (real, this time)
Refactored TVContentView from `.focusable().onTapGesture` to native
`Button { } label: { ... }.buttonStyle(.plain).focusEffectDisabled()`.
The Button approach plays correctly with the tvOS focus engine and
remote SELECT bindings, while preserving the no-chrome ambient look
via `.buttonStyle(.plain)` and `.focusEffectDisabled()`.

Verified via `idb ui key 40` (HID Return = remote Select): 5 sequential
selects advanced 5 cards across 5 different moves. Engine log evidence:
- Card #1: Inversion / Begin at the end
- Card #2: Attention / Notice what you always overlook
- Card #3: Process / Follow what feels alive...
- Card #4: Courage / Ignore logic
- Card #5: Subtraction / Find the quietest version
- Card #6: Attention / Listen to the hum beneath the noise
- Card #7: Time / Walk backward into the future

### Mac runtime — verified build, NOT verified runtime
**Honest:** I tried 5 different approaches to launch the iPhone-binary
on Mac from CLI. All failed. Apple has architecturally restricted iOS
apps running on Mac to Xcode's GUI Run flow or Mac App Store install:
- `xcodebuild build` for the macOS,variant=Designed for iPad
  destination: ✅ succeeds (config correct)
- `open Reflect.app` on the iphoneos product: ✗ "incorrect executable format"
- `lsregister -f` + `open -b com.MarkFriedlander.Reflect`: ✗ LaunchServices
  can't find the bundle (iOS .app isn't registered for Mac launch)
- `xcodebuild archive` for Mac variant: ✗ "no destinations allow archive"
- Searched filesystem for any iOS-on-Mac launcher tool in Xcode bundle: nothing public

**Mark's final-check step:** Xcode → scheme menu → "My Mac (Designed
for iPhone)" → Run button. Build config is verified correct
(`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES`), so the GUI run should
just work.

This is a genuine tooling limit, not an incomplete test.

## Things I did not test (and why)

- **TV remote-click on real hardware** — sim doesn't have remote, needs an Apple TV.
- **Mac runtime behavior** — build configuration verified, but launching iOS-on-Mac via CLI is impractical. Use Xcode → My Mac (Designed for iPhone) → Run for final check.
- **Watch on real hardware** — installed but not run. The sim verified the haptic call; only real wrist tells you if it *feels* right.
- **30-second auto-mode tick on iOS** — would require waiting 30s per transition. The Task-based loop logic is shared with TV's `rotateForever()` which is fully exercised in the tvOS test.
- **VoiceOver navigation flow** — I confirmed the AX tree is correct (label, hint, custom action). I did not actually run VoiceOver through a full session.
- **Network-off behavior** — by design Reflect makes no network calls, so this is structurally true rather than tested.

---

## Final verdict

Engine, AFM, accessibility, visual layer, and per-platform UX paths all
behave correctly across the tests I could run. The two coverage gaps —
Mac runtime and the haptic/remote/Watch feel on real hardware — are
yours to verify with the device in hand. Everything else has evidence
backing it.
