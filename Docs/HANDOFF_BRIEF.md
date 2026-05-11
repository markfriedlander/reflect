# HANDOFF BRIEF — Reflect: Creative Sparks

## Current Status

**Builds clean on all three targets. Runs on iOS and tvOS simulators.
Ready for device testing and App Store prep.**

## What's Built

### Shared layer ([Shared/](../Shared/))
- `Move.swift` — 12-case enum, raw values aligned to AFM grammar.
- `PromptCard.swift` — `struct PromptCard(text, moves)`. Renamed from
  `Prompt` to avoid collision with FoundationModels' `Prompt` builder type.
- `Prompts.swift` — 191 unique curated cards.
- `PromptEngine.swift` — `@MainActor @Observable`, history of 10,
  back-to-back same-move avoidance, three-tier fallback selection.
- `AFMPromptGenerator.swift` — production-tuned via 6 rounds of harness
  iteration against real AFM output. Per-move semantics, sampled-from-pool
  examples, full validation. API verified directly against Apple's docs:
  `LanguageModelSession(instructions:)` + `respond(to:options:)` non-streaming +
  `maximumResponseTokens: 30`. Gated to iOS 26+ / macOS 26+ via `#available`.

### Platform views
- `iOS/ContentView.swift` + `iOS/ReflectApp.swift` — interactive,
  30s auto mode, structured Task loop, Reduce Motion respected.
- `tvOS/TVContentView.swift` + `tvOS/Reflect_TVApp.swift` — ambient,
  variable dwell (60s–540s, median ~3min), fade-to-black between cards,
  idle timer disabled.
- `Watch/WatchContentView.swift` + `Watch/ReflectWatchApp.swift` —
  tap to advance, click haptic, scale-bounce.

### Accessibility (all platforms)
- Single focusable element per screen, labeled with the current prompt.
- VoiceOver hint describes the tap interaction.
- Custom VoiceOver action "Turn ambient mode on/off" replaces long-press
  (which VO users can't easily trigger).
- All animations suppressed under Reduce Motion.
- TV marked `.updatesFrequently` so VO announces changes in ambient mode.
- Contrast 21:1 (pure white on pure black).
- Dynamic Type via semantic system fonts.

### Icons
All asset catalogs populated from `Docs/temp images/reflect_icon_C_blend.svg`
(and `reflect_topshelf.svg`) via `Tools/generate_icons.sh`. iOS legacy sizes
20–1024, watchOS 1024 marketing, tvOS App Icon imagestacks (1280×768 +
400×240, same flat image for all parallax layers), Top Shelf (1920×720)
and Top Shelf Wide (2320×720, padded with black on both sides).

### Tooling
- `Tools/AFMHarness.swift` — runnable harness for AFM iteration
  (`swift Tools/AFMHarness.swift [N]`).
- `Tools/wire_xcode.rb` — adds synchronized folder groups to the
  Xcode project and bumps deployment targets. Idempotent.
- `Tools/generate_icons.sh` — renders all icon assets from SVG.
- `Tools/runs/` — AFM harness output logs.
- `Tools/screenshots/` — simulator screenshots from QA pass.

### Xcode project state
- Three app targets (Reflect, Reflect TV, Reflect Watch Watch App), all
  using Xcode 16 synchronized folder groups.
- `Shared/` synced to all three targets.
- `iOS/`, `tvOS/`, `Watch/` synced to their respective targets.
- Legacy per-target source files removed.
- Watch deployment target bumped 9.6 → 11.0.
- Obsolete `PBXFileSystemSynchronizedBuildFileExceptionSet` entries (which
  used to share `Reflect/Prompts.swift` across targets) removed.
- **Builds clean, zero warnings on all three schemes.**

## Open Items for Mark

### 1. Reflect TV bundle ID change (Universal Purchase requirement)
Current: `com.MarkFriedlander.Reflect-TV` (legacy standalone format).
Required: `com.MarkFriedlander.Reflect.tv` (Universal Purchase child).
**Reason left for Mark:** changing this requires updating App Store Connect
records and may need new provisioning profile. Cannot be done safely
without verifying the legacy listing delist plan.

### 2. Accent color decision
Currently no accent (pure typography). Strategic Claude proposed a dim
white-blue or no accent. Decide and tell Claude Code if (b).

### 3. Real-device testing (and AFM verification)
- AFM **verified on Mark's iPhone 16 Plus** (real hardware, real AFM,
  buffer fills with safety pipeline active). See QA_REPORT.md.
- Mac runtime **verified end-to-end** via `./Tools/mac_run.sh`. Window
  renders, mouse-click advances cards.
- TV: variable dwell pattern best observed on real Apple TV (simulator
  was sped up for QA, full-rate timing only verifiable on hardware).
- Watch: haptic call verified firing 1:1 with taps in sim; the *feel*
  of it only verifiable on real wrist.

### 4. App Store Connect work
- Associate Reflect TV target with the iOS app record (Universal Purchase).
- Delist legacy standalone Reflect TV listing AFTER unified release ships.
- App Store metadata refresh per NEXT.md.

## Confirmed Decisions (Not Open)
- MIT License, repo public at github.com/markfriedlander/reflect.
- iOS bundle ID `com.MarkFriedlander.Reflect` preserved (updates the
  existing listing in place).
- Watch app: companion inside the iOS bundle.
- AFM buffer size: 5. Refill threshold: 2.
- TV dwell: variable, median ~3 min.
- 191 cards in curated library.
- Fade-to-black between TV cards.
- No launch title on iPhone/iPad/Mac/Watch. Kept on TV.

## Future Scope (filed, not in this release)
- Watch complication (rectangular family).
- Variable-dwell tuning after live observation.
- Curation pass v2 — promote best AFM-generated cards into the library.
