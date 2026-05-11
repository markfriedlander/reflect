# HANDOFF BRIEF — Reflect: Creative Sparks

## Current Status

**Code-complete. Builds clean across all four platforms + two new
extensions. Awaiting Mark's hands for the bundle ID change and
App Store Connect submission. Targeting morning ship.**

## What's Built

### Shared layer ([Shared/](../Shared/))
- `Move.swift`, `PromptCard.swift`, `Prompts.swift` (197 curated cards
  with sensitivity revisions applied), `PromptEngine.swift` (history
  window 30, cluster avoidance), `AFMPromptGenerator.swift` (Apple
  Foundation Models integration + two-layer safety pipeline).

### Platform views
- `iOS/ContentView.swift` + `iOS/ReflectApp.swift` — interactive,
  30s auto mode, accessibility complete.
- `tvOS/TVContentView.swift` — Button-based for proper remote SELECT
  binding, variable dwell (60–540s, median ~3 min), fade-to-black.
- `Watch/WatchContentView.swift` — tap + haptic + scale-bounce.

### Widget ([Widget/](../Widget/))
- Bundle ID: `com.MarkFriedlander.Reflect.widget`
- Families: small, medium, large
- Refresh: 40–70 min variable, App Intent tap-to-refresh in place
- Curated library only (no AFM in widget — battery + size considerations)

### Watch complication ([WatchWidget/](../WatchWidget/))
- Bundle ID: `com.MarkFriedlander.Reflect.watchkitapp.complication`
- Families: accessoryRectangular, accessoryInline, accessoryCircular
- Refresh: 40–70 min variable, ~20 refreshes/day (well under budget)
- Ambient only — tap opens the Watch app

### Icons + brand assets
- iOS legacy multi-size (20→1024), watchOS 1024 marketing, tvOS
  imagestacks (1280×768 + 400×240), Top Shelf (1920×720 + 2320×720).
- Regenerable via `Tools/generate_icons.sh` from
  `Docs/temp images/reflect_icon_C_blend.svg`.
- Widgets and complications need no separate icons (render from SwiftUI).

### App Store content ([Docs/AppStore/](AppStore/))
- `APP_STORE_CONTENT.md` — full submission copy: description, subtitle,
  keywords, What's New, category, copyright.

### Web pages (root)
- `privacy.html`, `support.html` — Pure Phase visual style (black bg,
  white type, wide-tracked uppercase headers). Live at GitHub Pages.

### Tooling ([Tools/](../Tools/))
- `wire_xcode.rb` — Xcode 16 synced-folder-group wiring (idempotent).
- `add_widget_targets.rb` — adds widget + complication targets.
- `generate_icons.sh` — full icon set from SVG sources.
- `mac_run.sh` — `./Tools/mac_run.sh build|run|stop` for Mac runtime.
- `AFMHarness.swift` — AFM iteration harness (6 rounds of tuning logs in `runs/`).
- `EngineStress.swift` — 50-draw engine audit (validates rule compliance).

## Build State
- All three schemes (Reflect / Reflect TV / Reflect Watch Watch App):
  **BUILD SUCCEEDED, zero warnings**.
- Widget `.appex` correctly embedded in `Reflect.app/PlugIns/`.
- Complication `.appex` correctly embedded in Watch app's `PlugIns/`.

## Open Items for Mark (morning of release)

### 1. Reflect TV bundle ID change (~5 min in Xcode)
Current: `com.MarkFriedlander.Reflect-TV`
Required: `com.MarkFriedlander.Reflect.tv`
For Universal Purchase under the iOS app's listing. Walkthrough in
[XCODE_WIRING.md](XCODE_WIRING.md).

### 2. App Store Connect submission (via Chrome, by Mark)
- Paste content from `Docs/AppStore/APP_STORE_CONTENT.md` into the
  iOS app's listing.
- Enable Universal Purchase, add the tvOS build.
- Submit for review.
- **After unified release ships and is downloadable**: delist the
  legacy standalone "Reflect TV" listing
  (Pricing & Availability → Remove from Sale).

### 3. Existing App Store screenshots
Decision: keep them. The visual language hasn't changed (black + white
centered text). Widget + complication shots can be added later in a
metadata-only update if desired — not required for submission.

## Open Decisions
- **Accent color** — none, or Strategic Claude's dim white-blue?
  Currently none (pure typography). Five-minute change either way.

## Confirmed Decisions (Not Open)
- MIT License, repo public at github.com/markfriedlander/reflect.
- iOS bundle ID `com.MarkFriedlander.Reflect` preserved (updates the
  existing listing in place).
- Watch app, widget, and complication: companion bundles inside the
  iOS bundle — no separate App Store listings.
- 197 cards in curated library after sensitivity revisions.
- History window 30, fade-to-black on TV, variable dwell median ~3 min.
- AFM safety pipeline: keyword validator + second-pass classifier.

## Future Scope (filed, not in v1.0)
- Variable-dwell tuning after real ambient observation.
- Curation pass v2 — promote best AFM-generated cards into library.
- Widget shots in App Store gallery (metadata-only update).
- Accent color decision if Mark chooses dim white-blue.
