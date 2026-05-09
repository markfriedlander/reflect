# HANDOFF BRIEF — Reflect: Creative Sparks

## Current Status
Phases 1–4 complete in code. Awaiting Mark's Xcode wiring pass and one
visual-identity decision (accent color or none).

## What's Built (this session)

### Shared layer ([Shared/](../Shared/))
- [Move.swift](../Shared/Move.swift) — 12-case enum, raw values match the
  AFM system prompt strings.
- [PromptCard.swift](../Shared/PromptCard.swift) — `struct PromptCard`
  (renamed from `Prompt` to avoid collision with FoundationModels'
  public `Prompt` type used in @PromptBuilder closures).
- [Prompts.swift](../Shared/Prompts.swift) — 191 unique curated cards
  (200 from PROMPTS_FINAL.md minus 9 duplicates per Strategic Claude's
  approved dedupe).
- [PromptEngine.swift](../Shared/PromptEngine.swift) — `@MainActor`
  `@Observable`, history of 10, back-to-back same-move avoidance,
  three-tier fallback (strict → loose → unrestricted). AFM-aware:
  prefers buffer when non-empty, falls back silently to curated.
- [AFMPromptGenerator.swift](../Shared/AFMPromptGenerator.swift) — Apple
  Foundation Models integration. **API verified against Hal.swift**:
  `LanguageModelSession()`, `streamResponse(options:) { Prompt(text) }`,
  `snapshot.content`, `SystemLanguageModel.default.isAvailable`.
  Buffer of 5, refill at ≤2, 3-retry cap per slot, full validation
  (word count 3–12, banned vocab, curated-dedup), silent on every
  failure path.

### Platform views
- [iOS/ReflectApp.swift](../iOS/ReflectApp.swift) + [iOS/ContentView.swift](../iOS/ContentView.swift)
  — interactive, tap to advance, long-press toggles auto mode (30s
  cadence), structured Task-based loop (no recursive asyncAfter).
- [tvOS/Reflect_TVApp.swift](../tvOS/Reflect_TVApp.swift) + [tvOS/TVContentView.swift](../tvOS/TVContentView.swift)
  — ambient, **variable dwell time** (Mark approved), fade-to-black
  between cards, idle timer disabled, remote-click advances.
- [iOS/WatchContentView.swift](../iOS/WatchContentView.swift) +
  [Watch/ReflectWatchApp.swift](../Watch/ReflectWatchApp.swift) —
  tap to advance, click haptic, scale-bounce.

### Documentation
- [XCODE_WIRING.md](XCODE_WIRING.md) — step-by-step for Mark to wire
  the new structure into the existing `.xcodeproj`.
- [VISUAL_NOTES.md](VISUAL_NOTES.md) — what's in the visual layer now
  and why.

## Immediate Next Step (for Claude Code, next session)
1. Resume AFM iteration loop. Iteration 5 of the harness is written
   but unrun (randomized example sampling + directive/question form
   clarification). Run `swift Tools/AFMHarness.swift 3`, read output,
   iterate until pass rate ≥80% AND qualitative read of outputs feels
   right. See HISTORY.md "AFM verification" section for the iteration
   table so far.
2. Once harness system prompt is dialed in, port back to
   [Shared/AFMPromptGenerator.swift](../Shared/AFMPromptGenerator.swift)
   (it's still on iteration 2's system prompt).
3. Then: Xcode wiring directly (not via guide), HIG + accessibility
   audit, MIT LICENSE + open-source notes, then build verification.

## Open Decisions (need Mark)
- **Accent color** — none, or Strategic Claude's proposed "dim
  white-blue, light on still water"? See VISUAL_NOTES.md.
- **App icon** — Strategic Claude is producing the spec separately.

## Confirmed Decisions (Not Open)
- Bundle ID: reuse existing iOS app bundle ID.
- Watch app: companion inside the iOS bundle.
- AFM buffer size: 5. Refill threshold: 2.
- TV dwell time: variable, median ~3 min (60s–540s range).
- 191 cards in curated library after dedupe.
- Fade-to-black between TV cards (not crossfade).
- No launch title on iPhone/iPad/Mac/Watch. Kept on TV.

## Future Scope (filed, not in this release)
- Watch complication (rectangular family) showing a passive prompt that
  refreshes a few times a day. The single best surface for Reflect.
- Possible "weighted prompts" idea (some cards breathe longer than
  others) — discussed and shelved as out of scope for v1.
