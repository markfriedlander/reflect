# HISTORY — Reflect: Creative Sparks

## May 2026 — Project Unification Begins
- Strategic Claude and Mark completed research and planning session.
- Reviewed existing codebase: iOS ContentView, tvOS ContentView, Watch
  ContentView, shared Prompts.swift.
- Decided on unified architecture: one project, two targets, shared
  PromptEngine.
- AFM integration planned: background buffer of pre-generated prompts,
  silent fallback.
- Platform behavior defined: TV ambient, iPhone/iPad interactive with
  desk mode, Watch tap-only.
- OS floor set: iOS 18 / tvOS 18 / watchOS 11.
- CLAUDE.md and project scaffold created.
- Claude Code first session initiated.

## 2026-05-08 — First implementation session (Claude Code)

**Phase 1 — Shared layer.**
- Created `Move.swift` (12-case enum, raw values aligned to AFM system
  prompt).
- Created `PromptCard.swift` — originally `Prompt`, renamed after Hal
  source code review revealed FoundationModels' public `Prompt` type
  would collide.
- Created `Prompts.swift` with all 200 cards from PROMPTS_FINAL.md.
  Strategic Claude approved deduping the 9 entries that appeared in both
  single-move and Mixed sections — kept the richer two-move tagging,
  dropped single-move duplicates. Final count: 191 unique cards.
- Created `PromptEngine.swift` — `@MainActor @Observable`, history of
  10, back-to-back same-move avoidance, three-tier fallback selection.
- Created `AFMPromptGenerator.swift` — first written speculatively to
  spec pseudo-code. Strategic Claude pushed back: verify against the
  actual API. Read Hal.swift's working integration and rewrote to match:
  `LanguageModelSession()` no-arg init, `streamResponse(options:) { Prompt(text) }`
  with FoundationModels' Prompt type, `snapshot.content` accumulation,
  `SystemLanguageModel.default.isAvailable` Bool gate. Buffer of 5,
  refill threshold 2, 3-retry cap per slot, banned-vocab + word-count
  + curated-dedup validation, silent on all failures.

**Phase 2 — Platform views.**
- Created `iOS/ReflectApp.swift` and `iOS/ContentView.swift`. Interactive
  default. Long-press toggles 30s auto mode. Structured Task-based loop
  replaces the legacy recursive asyncAfter pattern. Toast on mode
  toggle. No launch title (decided splash screens age poorly on
  hand-held devices).
- Created `tvOS/Reflect_TVApp.swift` and `tvOS/TVContentView.swift`.
  Ambient, fade-to-black between cards (Mark and Claude Code agreed
  this is the Eno-correct choice — silence between notes, not cross-fade).
  Variable dwell time per Mark's enthusiasm for the idea: 24-sided roll
  giving a base 2–5 min hold, ~13% chance of a 6–9 min long hold, ~8%
  chance of a 60–90s quick flip. Median ~3 min as spec'd, but with
  organic variation. Idle timer disabled, focus effect suppressed for
  clean ambient look.
- Created `iOS/WatchContentView.swift` and `Watch/ReflectWatchApp.swift`.
  Tap to advance, click haptic, scale-bounce kept from legacy.

**Phase 3 — Xcode wiring guide.**
- Created `Docs/XCODE_WIRING.md` — step-by-step for Mark to wire the new
  file structure into the existing `.xcodeproj`. Bundle-ID warning
  flagged as critical for the App Store update path.

**Phase 4 — Visual polish.**
- Created `Docs/VISUAL_NOTES.md` documenting all visual decisions:
  pure black + pure white, no accent color (open question), system font
  regular weight, fade timings (0.4s Watch, 0.6s iOS, 1.0s TV), 1-second
  black hold between TV cards.

**Creative input from Claude Code preserved in Docs/HANDOFF_BRIEF.md
"Future Scope":**
- Watch complication idea (rectangular family, passive prompt refresh).
  Mark and Claude Code identified this as the single most Eno-native
  surface for Reflect. Filed for post-unification work.

**Net change to repo:**
- Added: `Shared/`, `iOS/`, `tvOS/`, `Watch/` folders with all new code.
- Added: `Docs/XCODE_WIRING.md`, `Docs/VISUAL_NOTES.md`.
- Updated: `Docs/HANDOFF_BRIEF.md`, `Docs/NEXT.md`.
- Pending Xcode-side cleanup (Mark): remove legacy Swift files in
  `Reflect/`, `Reflect TV/`, `Reflect Watch Watch App/`.

## 2026-05-09 — AFM verification + iterative testing session

Strategic Claude pushed back on the AFM file: I had verified against
Hal.swift but not against Apple's actual docs, and a simpler one-shot
API likely existed. Both fair calls.

**API verification.** Read Apple's FoundationModels documentation
directly via the JSON endpoints. Findings:
- `LanguageModelSession(instructions:)` — convenience init exists.
- `respond(to: String, options:) async throws -> Response<String>` —
  non-streaming. Right call for our use case (3–9 word output, no
  benefit from streaming tokens).
- `GenerationOptions(temperature:, maximumResponseTokens:)` — caps
  output length cheaply. Set to 30 tokens.

**AFMPromptGenerator refactored** ([Shared/AFMPromptGenerator.swift](../Shared/AFMPromptGenerator.swift)):
- Dropped streaming + accumulation loop.
- Pass system prompt via `instructions:` parameter (clean role
  separation, model treats as system-weight not user-weight).
- Cap output via `maximumResponseTokens: 30`.

**Iterative testing harness** ([Tools/AFMHarness.swift](../Tools/AFMHarness.swift)):
Single-file Swift script runnable via `swift Tools/AFMHarness.swift [N]`.
Generates N prompts per move (default 3), validates each, dumps raw
output to `Tools/runs/<timestamp>.txt`. Macbook is on macOS 26.5 with
Apple Intelligence enabled — real generation ran successfully.

**Iteration history (logs in [Tools/runs/](../Tools/runs/)):**
| Round | Pass | Avg WC | Key issue |
|-------|------|--------|-----------|
| 1     | 75%  | 10.0   | Length creep (model writes paragraphs); 11/24 start with "Imagine"; domain leaks |
| 2     | 87%  | 5.5    | Few-shot examples dropped length dramatically; 1 guardrail violation on Courage |
| 3     | 86%  | 5.7    | Model copying examples verbatim ("What would a child say?" 3x) |
| 4     | 72%  | 6.8    | Anti-copy instruction caused new drift toward poetic imagery |
| 5     | —    | —      | **Pending run** — randomized example sampling from larger pool + directive/question form clarification |

**State at session pause:** Iteration 5 of harness fully written but
unrun. The production `AFMPromptGenerator.swift` still uses iteration
2's system prompt (the one in code right now); harness has the more
evolved iteration 5 system prompt. Once we land on a winning version,
port the system prompt + example-sampling logic from harness back into
the production file.

**Items NOT yet started this session:**
- Xcode wiring (do directly, not via guide)
- HIG + accessibility audit
- MIT LICENSE file + open-source acknowledgment in CLAUDE.md/HANDOFF_BRIEF
- GitHub push (this commit handles the push for safety, but the above
  three items remain on the list)
