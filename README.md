# Reflect: Creative Sparks

A minimal creative prompt app for iPhone, iPad, Mac, Apple Watch, and Apple TV — in the spirit of Brian Eno and Peter Schmidt's *Oblique Strategies*. Free, open source (MIT), zero network, zero accounts, zero analytics. **The prompt is the product.**

The app is live on the App Store as a single Universal Purchase listing: [Reflect: Creative Sparks](https://apps.apple.com/us/app/reflect-creative-sparks/id6745411935).

This README is for developers reading the source. If you're here to use the app, the App Store link is what you want.

---

## What it does

Reflect displays one creative prompt at a time, centered on a black screen. Tap (or wait, on TV) for the next one. That's the whole UI. The prompts are short, oblique, and lateral — not directive, not self-helpy. Each one is tagged with one of twelve **structural moves** (Subtraction, Inversion, Constraint, Displacement, Attention, Acceptance, Perspective, Time, Reduction, Courage, Process, Reality Check), and the engine avoids serving the same move back-to-back so the obliqueness keeps surprising you.

On capable devices (iOS 18.2+, iPhone 15 Pro or later, Apple Intelligence enabled), a small buffer of **Apple Foundation Models**–generated prompts is mixed in transparently. The user never knows which source a given card came from. On every other device, the curated library is the complete experience.

---

## Architecture

```
Reflect/
├── Shared/                       # platform-independent core (~860 lines)
│   ├── Move.swift                # the 12-move enum — single source of truth
│   ├── PromptCard.swift          # struct: text + moves
│   ├── Prompts.swift             # 200 curated cards, tagged by move
│   ├── PromptEngine.swift        # selection, history, cluster avoidance
│   └── AFMPromptGenerator.swift  # Apple Foundation Models integration
├── iOS/                          # iPhone / iPad / Mac (Designed-for-iPad)
├── tvOS/                         # ambient slow-TV display
├── Watch/                        # tap-to-advance watch app
├── Widget/                       # iOS Home Screen / Lock Screen widget
├── WatchWidget/                  # watchOS complication
└── Tools/                        # build helpers, harness scripts
```

**One codebase, five platforms, two extensions.** The Shared layer is pure Swift — no UIKit, no SwiftUI, no platform imports. Every view in iOS/tvOS/Watch/Widget/WatchWidget is a thin shell over `PromptEngine.next()`.

### The engine

`PromptEngine` is `@MainActor`, `@Observable`. Selection rules, in order:

1. **Prefer the AFM-generated buffer** when non-empty. Silent — no UI indication.
2. **Avoid the recent history** (last 30 cards).
3. **Avoid the same `primaryMove`** as the prompt just shown — back-to-back same-move repeats break the obliqueness.
4. **Loosen** to "just avoid history" if strict filtering yields nothing.
5. **Fall back** to anything if the deck is exhausted (unreachable in practice — 200 cards vs. 30-history).

After serving a card, the engine triggers AFM buffer refill in the background. Views call `next()`, get a `String`, never see the machinery.

### AFM integration

`AFMPromptGenerator` is gated on `SystemLanguageModel.default.isAvailable` and wrapped in `#if canImport(FoundationModels)` — so it compiles cleanly on every platform, but only ever produces output on capable iOS hardware.

The pipeline:

1. Maintain a buffer (target 5, refill threshold 2).
2. Pass ~10–15 curated examples to the model as `Instructions` (typed, separate from the user prompt).
3. Ask for one short prompt in the same grammar, biased toward an unused move.
4. **Two-layer safety validation**: a keyword filter (banned-word list, no medical/legal/financial directives) followed by a second-pass classifier prompt that the same model rejects on. Fail-safe to curated.
5. Discard silently on any failure. The engine doesn't even know it happened.

System prompt tuned via `Tools/AFMHarness.swift` across six iteration rounds against real macOS 26 AFM output. Tuning logs are in `Tools/runs/`.

### Per-platform behavior

| Platform | Default mode | Auto/Ambient | Interaction |
|----------|--------------|--------------|-------------|
| iPhone / iPad | Interactive (tap) | Long-press for desk mode (30s cycle) | Tap, long press |
| Mac | Same as iOS (runs as Designed-for-iPad on Mac, no Catalyst) | Auto mode toggle | Click |
| Apple TV | Ambient (always cycling) | Variable dwell 60–540s, median ~3 min, fade-to-black between cards | Remote click advances early |
| Apple Watch | Interactive (tap) | None | Tap + haptic + scale-bounce |
| Widget (iOS) | Curated only, refresh 40–70 min variable, App Intent tap-to-refresh | — | Tap to refresh |
| Complication (watchOS) | Curated only, refresh 40–70 min variable | — | Tap opens Watch app |

### Variable dwell on TV

Constant 3-minute cycles become wallpaper. The TV view rolls a 24-sided die:

- 19/24: 2–5 min (base rhythm)
- 3/24: 6–9 min (long hold — let it sit)
- 2/24: 60–90 sec (quick flip — keeps you on your toes)

Median lands near 3 minutes but the rhythm is shaped, so the eye keeps noticing.

### Privacy

- **No network calls.** Anywhere. AFM runs on-device. The curated library ships in the binary.
- **No accounts, no analytics, no telemetry, no tracking.** The App Store privacy nutrition label is literally "Data Not Collected."
- **No HealthKit, no sensors, no notifications.**
- The only persisted state is the user's auto-mode preference (`@AppStorage`).

---

## Targets and bundle structure

- **Reflect** (`com.MarkFriedlander.Reflect`) — primary target. iPhone, iPad, Mac, Apple Watch. Runs on Mac via "iPhone & iPad Apps on Mac" — no Catalyst, no separate Mac target.
- **Reflect TV** (`com.MarkFriedlander.Reflect`) — tvOS target sharing the same bundle ID for Universal Purchase. Same App Store listing.
- **Reflect Widget** (`com.MarkFriedlander.Reflect.widget`) — WidgetKit extension. Small/medium/large families.
- **Reflect Watch Complication** (`com.MarkFriedlander.Reflect.watchkitapp.widget`) — watchOS complication. accessoryRectangular/Inline/Circular families.

OS floor: iOS 18 / iPadOS 18 / tvOS 18 / watchOS 11. AFM additionally requires iOS 18.2 + Apple Intelligence + iPhone 15 Pro or later.

---

## Building it

Open `Reflect.xcodeproj` in Xcode 16 or later and pick the scheme:

- **Reflect** — iPhone, iPad, Mac
- **Reflect TV** — Apple TV
- **Reflect Watch Watch App** — Apple Watch

Three schemes, one project. The widget and complication targets build automatically as embedded extensions.

The project uses Xcode 16 synchronized folder groups (`PBXFileSystemSynchronizedRootGroup`) so files added to disk show up in the project without manual wiring. Several helper scripts live in `Tools/`:

- `Tools/wire_xcode.rb` — idempotent project file wiring (uses the `xcodeproj` gem)
- `Tools/add_widget_targets.rb` — adds the widget + complication targets
- `Tools/generate_icons.sh` — generates the full icon set from `Docs/temp images/reflect_icon_C_blend.svg`
- `Tools/mac_run.sh` — `./Tools/mac_run.sh build|run|stop` for the Mac runtime
- `Tools/AFMHarness.swift` — standalone harness for iterating on the AFM system prompt
- `Tools/EngineStress.swift` — 50-draw audit of `PromptEngine` to verify rule compliance

---

## What's worth copying

If you're forking for your own project, the parts most likely to be useful in isolation:

- **`Shared/PromptEngine.swift`** — clean pattern for "pick the next item with avoidance constraints," `@Observable`, no async/await, easy to swap in your own corpus.
- **`Shared/AFMPromptGenerator.swift`** — a working, defensively-coded reference for shipping Apple Foundation Models in production: availability gating, `Instructions`/`respond(to:)` usage, two-layer safety validation, buffer-with-refill pattern, silent fallback.
- **`Tools/AFMHarness.swift`** — pattern for iterating on a system prompt against real AFM output instead of guessing.
- **The accessibility wiring** in `iOS/ContentView.swift` — single focusable element with the content as label, custom VoiceOver action for mode toggle, Reduce Motion respected. About 30 lines of useful patterns.

---

## License

MIT. See [LICENSE](LICENSE). Use whatever helps you ship something quiet.

---

## Credits

Reflect is by Mark Friedlander, with collaboration between Strategic Claude (design partner) and Claude Code (builder). Inspired by Brian Eno and Peter Schmidt's *Oblique Strategies* (1975), without which none of this exists.
