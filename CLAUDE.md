# CLAUDE.md — Reflect Operational Reference
*Read this at the start of every session. Every session. No exceptions.*

---

## What This Project Is

Reflect: Creative Sparks is a free iOS, iPadOS, tvOS, watchOS, and macOS app that displays creative prompts in the spirit of Brian Eno and Peter Schmidt's Oblique Strategies. It is a minimal, privacy-first creative tool — no accounts, no subscriptions, no analytics, no network calls. The prompt is the entire product.

On capable devices (iPhone 15 Pro+, iOS 18+, Apple Intelligence enabled), Apple Foundation Models generates fresh prompts on-device using the curated library as stylistic input. On all other devices, a large curated prompt library ships with the app and serves as the complete experience.

The aesthetic is minimal and intentional — black background, white typography, generous breathing room. Think slow TV, but text. The TV version is ambient art. The iPhone/iPad version is an interactive deck or desk companion. The Watch version is a glanceable tap-to-advance card.

---

## The Collaboration Structure

**Mark** — product owner, creative director, final decision maker on all UX and scope questions. Asks questions before committing to directions. Hobby project — keep scope tight and clean.

**Strategic Claude** (claude.ai) — the thinking partner. Design decisions, architecture discussions, spec writing, and reviewing Claude Code's output happen there. When something is ambiguous or consequential, check this document or ask Mark before proceeding.

**Claude Code (you)** — the builder. You implement what has been specified and discussed. You do not invent scope. You do not make consequential decisions alone. You read before you write, you ask before you assume, and you deliver complete implementations.

---

## Working Rules

**1. Read before touching.**
Read every relevant file before modifying anything. Understanding existing code before changing it is not optional.

**2. Discuss before building anything consequential.**
A sentence describing your plan costs nothing. A misaligned implementation costs hours. On anything non-trivial, state your approach and wait for confirmation before writing code.

**3. Complete implementations only.**
No stubs. No placeholders. No `// TODO` comments left in delivered code. If something can't be completed in a session, say so explicitly and document the stopping point in HANDOFF_BRIEF.md.

**4. Use the LEGO Block System for all file delivery.**
All files are delivered in clearly marked blocks:
```
// ========== BLOCK N: DESCRIPTION - START ==========
[code]
// ========== BLOCK N: DESCRIPTION - END ==========
```
Maximum ~100 lines per block. Announce block count before starting. Wait for confirmation before proceeding to next block if Mark requests it.

**5. Update documents as part of every session.**
HANDOFF_BRIEF.md gets updated at the end of every meaningful work session. HISTORY.md gets a new entry for every meaningful change. NEXT.md gets updated to reflect current priority order. Code without document updates is an incomplete session.

**6. Flag uncertainty before building.**
If something in the spec is unclear, ask. If two approaches are equally valid and the choice matters, present them and ask. Confident wrong implementations are more expensive than clarifying questions.

**7. Zero warnings policy.**
Compiler warnings are not acceptable in committed code. Fix every warning. Do not suppress warnings with flags, pragmas, or `// swiftlint:disable` comments. If a warning genuinely cannot be fixed, document exactly why in a code comment and bring it to Mark for explicit approval.

**8. These documents are ground truth.**
When code and documents disagree, the code gets fixed. When you are uncertain about scope or direction, this document wins. When this document is silent, ask Mark.

**9. Ask before inventing.**
If something isn't specified, don't invent it. Ask. This is especially important for: UI layout details, prompt timing, animation specifics, and anything touching AFM integration.

---

## App Architecture

### Targets

Two Xcode targets sharing one codebase:

- **Reflect** (iOS/iPadOS/macOS) — primary target. iPhone and iPad share identical behavior. Mac runs the iPhone binary natively via "iPhone & iPad Apps on Mac" — no Catalyst. Full-screen mode supported on Mac. Single App Store listing covers iPhone, iPad, and Mac.
- **Reflect TV** (tvOS) — ambient display target. Same prompt engine, different UX. Listed under Universal Purchase on the same App Store listing. The legacy standalone TV app listing will be delisted.

### Shared Code

All prompt logic, AFM integration, and the prompt engine live in shared Swift files compiled into both targets. Platform-specific views are gated with `#if os(tvOS)` / `#if os(iOS)` where needed.

### File Structure

```
Reflect/
├── Shared/
│   ├── Prompts.swift           — curated prompt library
│   ├── PromptEngine.swift      — selection logic, history, cluster avoidance
│   └── AFMPromptGenerator.swift — Foundation Models integration + buffer
├── iOS/
│   ├── ReflectApp.swift
│   ├── ContentView.swift       — interactive mode + desk/auto mode
│   └── WatchContentView.swift  — Watch target view
├── tvOS/
│   ├── Reflect_TVApp.swift
│   └── TVContentView.swift     — ambient slow-display mode
└── Docs/
    ├── CLAUDE.md               — this file
    ├── HANDOFF_BRIEF.md
    ├── HISTORY.md
    └── NEXT.md
```

---

## Platform Behavior

| Platform | Default Mode | Auto/Ambient Mode | Interaction |
|----------|-------------|-------------------|-------------|
| iPhone | Interactive (tap to advance) | Desk mode via long press or setting | Tap, long press |
| iPad | Interactive (tap to advance) | Ambient mode available in settings | Tap, long press |
| Mac | Interactive (click to advance) | Auto mode available, full-screen supported | Click |
| Apple TV | Ambient (auto-cycling) | Always on | Remote click to advance |
| Watch | Interactive (tap to advance) | None | Tap + haptic |

---

## Prompt Engine

### Curated Library
Ships with the app. `Prompts.swift` contains the full library. The engine:
- Selects randomly but avoids repeating the same cluster back-to-back
- Maintains a short recent history to avoid immediate repeats
- Is the complete experience on non-AFM devices

### AFM Integration
On capable devices (iOS 18+, Apple Intelligence enabled, iPhone 15 Pro or later):
- A small buffer (3–5 prompts) is pre-generated silently in the background
- The curated library is passed as stylistic context/examples in the system prompt
- AFM is instructed to return a single short prompt in the same register — oblique, lateral, under ~8 words where possible
- Output is a single `String`, no extra formatting
- If AFM is unavailable or generation fails, falls back to curated library silently
- Never tell the user which source a prompt came from

### AFM System Prompt Principle
The model should be given ~10-15 example prompts from the curated library and instructed to generate one new prompt in the same spirit: short, oblique, lateral, not directive, not self-helpy. The obliqueness is the mechanism — prompts should disrupt, not guide.

---

## Timing

| Platform | Interactive | Auto/Ambient Default |
|----------|-------------|---------------------|
| iPhone/iPad | Tap only | 30 seconds (desk mode) |
| Mac | Click only | 30 seconds (auto mode) |
| Apple TV | N/A | 3–5 minutes per prompt |
| Watch | Tap only | N/A |

TV dwell time should feel like slow TV — unhurried. 3 minutes is a reasonable default.

---

## Visual Design Principles

- Black background always
- White text, high contrast
- Single prompt centered on screen, generous padding
- No UI chrome during prompt display — no buttons, labels, or indicators visible
- Smooth opacity fade between prompts (1 second)
- Typography: system font, large, readable at a distance on TV
- On TV: the prompt IS the entire screen. Nothing else.
- Toast messages (e.g. "Auto mode on") in small caption text, fading after 2.5 seconds

---

## What This Project Does Not Build

Do not add any of the following without explicit discussion and approval from Mark:

- User accounts or sign-in
- Push notifications or reminders
- HealthKit or any sensor integration
- Subscription or paywall logic
- Analytics, telemetry, or tracking of any kind
- iCloud sync
- Social or sharing features
- Onboarding flows or tutorials
- In-app purchases
- Anything that requires a network connection

---

## App Store Details

- **Display name (Springboard):** Reflect
- **Full name (App Store):** Reflect: Creative Sparks
- **Bundle ID:** Reuse the existing iOS app bundle ID. This ensures the unified app updates the existing listing rather than creating a new one.
- **Listing strategy:** One Universal Purchase listing covering iOS, iPadOS, macOS, tvOS. Watch app ships as a companion inside the iOS bundle — no separate listing.
- **Legacy TV app:** Has its own separate bundle ID and listing. To be delisted once the new unified app is live with tvOS support.

---

## OS Floor

- iOS 18 / iPadOS 18 / tvOS 18 / watchOS 11
- macOS: via iPhone & iPad Apps on Mac (no separate Catalyst target)
- AFM requires iOS 18 + Apple Intelligence + iPhone 15 Pro or later — gate with availability check, fall back silently to curated library

---

## Image Handling Rule (HARD)

**Never use the Read tool on image files** (.png, .jpg, .jpeg, .gif, .heic, .webp) except thumbnails explicitly named `-thumb.png`.

Reading full-size images pipes large byte payloads through the conversation and can break the session. If visual verification is needed:
1. Ask Mark to look at the file directly
2. Generate a thumbnail with `sips -Z 400 input.png --out input-thumb.png` and read only the thumb
3. Trust the code — if parameters are correct, output is correct

---

## Reference Documents

- **HANDOFF_BRIEF.md** — read first each session. Current state and immediate next step.
- **HISTORY.md** — chronological log of what was built and when.
- **NEXT.md** — current priorities for the next session.
- **CLAUDE.md** — this file. Collaboration rules and architecture reference.

---

*Reflect: Creative Sparks*
*CLAUDE.md drafted in collaboration between Mark and Strategic Claude, May 2026.*
