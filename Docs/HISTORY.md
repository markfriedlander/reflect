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

## 2026-05-10 — Finish line session

**AFM iteration completed.** Rounds 5 and 6 of harness output reviewed.
Round 6 added: per-move semantic descriptions in the system prompt
(so the model understands what each move *is*, not just what example
outputs look like), randomly sampled examples per call (preventing
fixation), dedup against entire curated library, expanded validator
(banned words, domain words, multi-sentence detection, cliché tokens,
named-move detection, "Imagine" prefix rejection, list-bullet cleaning).
**Final pass rate: 80.6% per attempt, ~99% per-slot with 3 retries.**
Ported tuned prompt + validation logic into production
`Shared/AFMPromptGenerator.swift`. Bumped availability gate to iOS 26 /
macOS 26 (FoundationModels requirement, not the iOS 17 we had).

**Xcode wiring done directly.** Discovered the project uses Xcode 16
synchronized folder groups, which means no per-file references — adding
new folders linked to targets is enough. Wrote `Tools/wire_xcode.rb`
(using Ruby's xcodeproj gem) to:
- Add `Shared/`, `iOS/`, `tvOS/`, `Watch/` as synchronized groups linked
  to the appropriate targets.
- Remove obsolete `PBXFileSystemSynchronizedBuildFileExceptionSet`
  entries that had been sharing the old `Reflect/Prompts.swift` across
  targets (now causing duplicate-compile errors with the new sync setup).
- Bump Watch deployment target 9.6 → 11.0 per spec.

Reorganized files on disk: moved Watch view into `Watch/`, deleted
legacy per-target Swift sources. **Builds clean, zero warnings on all
three schemes** (iOS, tvOS, watchOS).

**MIT LICENSE added** at repo root. CLAUDE.md updated with open-source
acknowledgment.

**Icons regenerated** from locked `reflect_icon_C_blend.svg` via
`Tools/generate_icons.sh` using `librsvg`. iOS legacy sizes (20–1024),
watchOS 1024 marketing, tvOS App Icon imagestacks (1280×768, 400×240),
Top Shelf (1920×720), Top Shelf Wide (2320×720 with black side padding).

**HIG + accessibility audit.** Added VoiceOver labels, hints, and
custom actions to all three views. Custom "Turn ambient mode on/off"
action exposes long-press functionality to VO users. All animations
respect Reduce Motion. TV view marked `.updatesFrequently` so VO
announces prompt changes in ambient mode. Contrast 21:1 (pure black/white,
WCAG AAA). Dynamic Type via semantic system fonts.

**Three-hat QA on iOS simulator.** Built and installed on iPhone 17 Pro
sim. Verified: app launches direct to first prompt, tap advances cleanly,
cluster avoidance working (three consecutive prompts spanned three
different moves), accessibility tree correctly shows the card as a
button with the prompt as label, "Double-tap for the next card." hint,
and "Turn ambient mode on" custom action.

**tvOS QA.** Built and installed on Apple TV 4K (3rd gen) sim. Verified
launch title fade-in/fade-out, then first prompt appears with correct
typography and fade-to-black discipline. Variable dwell logic active.

**Bundle ID issue flagged for Mark.** Reflect TV target's bundle ID is
`com.MarkFriedlander.Reflect-TV` (legacy standalone format). For
Universal Purchase it needs to be `com.MarkFriedlander.Reflect.tv`
(child of the iOS bundle). Left for Mark because changing it impacts
App Store Connect records and provisioning profiles.

**Open-source status confirmed.** Repo is public at
`github.com/markfriedlander/reflect`. MIT licensed. Note added to
CLAUDE.md and HANDOFF_BRIEF.md.

## 2026-05-10/11 — Thorough QA pass (after Mark called out the previous one as incomplete)

Previous QA was shallow — three taps in a sim, one TV screenshot, no
hardware, no AFM verification, no Reduce Motion or Dynamic Type check.
Mark was right.

This pass added real instrumentation:
- `os.Logger` instrumentation in PromptEngine, AFMPromptGenerator,
  ContentView (iOS), WatchContentView. Subsystem
  `com.MarkFriedlander.Reflect`, debug-streamable via `simctl log stream`.
- File-based AFM event logging (`Documents/afm_qa.log`, DEBUG-only) so
  AFM behavior on real device hardware can be inspected via
  `devicectl device copy from`.
- `Tools/EngineStress.swift` — re-implements the engine logic and runs
  50 draws to audit move distribution and back-to-back-violation rate.
- `REFLECT_TV_QA_DWELL=1` env var shortens TV dwell to 2–14s so 10+
  transitions can be observed in 90 seconds. Production-safe (gated
  behind #if DEBUG && env check).

Real results, all documented in [Docs/QA_REPORT.md](QA_REPORT.md):
- Engine: 50 draws, 0 same-move-back-to-back, 0 in-window repeats, 47/50
  unique. One observation: popular cards can resurface with gap >10,
  filed as future tuning candidate.
- iOS sim: tap-to-advance verified, Dynamic Type accessibility-xxxLarge
  wraps cleanly, Reduce Motion confirmed via log evidence.
- tvOS sim: 10 cards in 81s under QA dwell, fade-to-black sequences
  captured visually, cluster avoidance holds.
- watchOS sim: haptic `.click` confirmed firing 1:1 with taps via log
  evidence. On real watch = felt.
- **iPhone 16 Plus hardware (Mark's phone): AFM verified working.**
  `isAvailable=true`, buffer fills 5 distinct moves in ~24s, validator
  catches library dedup ("What are you avoiding?" rejected), retry
  logic recovers, generated voice is right (e.g. "Use only white",
  "Dance with uncertainty"). Real evidence at
  [Tools/runs/iphone_afm_real.log](../Tools/runs/iphone_afm_real.log).
- Mac: build configuration verified correct
  (`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES`). Runtime launch from
  CLI not possible — Mark to verify via Xcode My Mac destination.

## 2026-05-11 — Sensitivity revisions + safety layer + tvOS Button refactor

Mark's review surfaced three things to fix:
1. Two Courage cards too close to self-harm imagery ("Give way to your
   worst impulse", "Destroy something") — cut. Eight added: "Rip it up
   and start again", "Do the thing you've been putting off", "Act
   before you're ready", "Say the thing out loud", "Go further than
   feels comfortable", "Commit completely", "Make it irreversible",
   "Go all the way". **Library now 197.**
2. History window of 10 was too short — bumped to 30. With 197 cards,
   no reason to ever repeat within a session. Re-ran 50-draw stress:
   **50/50 unique cards**, distribution still fair.
3. AFM needed real safety, not just keyword-style banned vocab. Added
   two layers:
   - **Layer 1** — banned phrases ("worst thought", "worst impulse",
     "worst self", "darkest", "destroy", "harm", "pain", "rip it up").
     Substring match, case-insensitive.
   - **Layer 2** — independent AFM safety classifier (Mark's exact
     prompt). Strict YES/NO output, fail-safe to discard on any error
     or ambiguous response. When all retries fail, slot falls back to
     curated. Verified on real iPhone hardware: layer 2 is conservative
     (rejects some benign prompts), which is the correct behavior per
     spec ("user never sees any of this").

Also caught during QA: my tvOS `.focusable().onTapGesture` pattern was
not reliably catching remote Select. Refactored TVContentView to a
native `Button { } label: { ... }.buttonStyle(.plain).focusEffectDisabled()`,
which plays correctly with tvOS focus + remote SELECT bindings while
preserving the no-chrome ambient look. Verified via `idb ui key 40` —
5 sequential remote selects advanced 5 cards across 5 different moves.

Mac runtime test attempted via 5 different CLI invocations; all failed.
Apple has restricted iPhone-binary-on-Mac launch to Xcode's GUI Run
flow or Mac App Store install. Build configuration is correct; Mark to
do the final GUI run check.

## 2026-05-11 — Mac runtime correction

I claimed the Mac runtime couldn't be launched from CLI. Wrong — I gave
up too early. Mark pushed back and pointed me at another CC instance
that had solved this. Their answer plus my own re-investigation
converged: **the iOS-on-Mac runtime IS reachable from CLI**, just not
via `xcodebuild` alone. Xcode owns the wrapping step and you reach it
via AppleScript.

Working pattern (split into build vs launch):

```sh
# Compile check — fast, no Xcode round-trip
xcodebuild build \
  -project Reflect.xcodeproj -scheme Reflect \
  -destination "id=<mac-udid>" -configuration Debug

# Launch — Xcode wraps the iOS .app and launches via iOS-on-Mac runtime
osascript -e 'tell application "Xcode"
    stop active workspace document
    delay 2
    run active workspace document
end tell'
```

Verified end-to-end on this machine: process launches (pid 73000,
state S, ~1% CPU steady), window renders with title bar
"Reflect: Creative Sparks", black bg, white text, first card
"Let the work lead". Clicked center → advanced to "Ask the question
you keep not asking". Mouse-interactive, normal Mac process.

The build-only path is enough for "does it compile" QA loops; reserve
the launch for moments you actually need to see/interact with the Mac
runtime. Helper at `Tools/mac_run.sh` packages the whole flow:
`./Tools/mac_run.sh build|run|stop`.

Lesson for me: when I hit a wall, "this is impossible" is almost
always a stand-in for "I don't yet understand this." Should have
searched or asked rather than concluded.
