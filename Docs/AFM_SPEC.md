# Reflect: AFM Prompt Generation Spec
## For use with Apple Foundation Models — FoundationModels framework

---

## Overview

On capable devices (iOS 18+, Apple Intelligence enabled, iPhone 15 Pro or later),
Reflect uses Apple Foundation Models to generate fresh prompts in the background,
maintaining a buffer of 5 pre-generated prompts. When the buffer runs low, it
refills silently. The user never knows whether a prompt is curated or generated.
On incapable devices, the curated library is the complete experience.

---

## The Generation Grammar

All prompts — curated and generated — are built on 12 structural moves.
The AFM system prompt must instruct the model using this grammar explicitly,
not by example-matching alone. This ensures generated prompts have the same
oblique quality as the curated set rather than drifting toward generic
inspirational language.

### The 12 Moves

**1. SUBTRACTION** — Remove something. Strip to essence. What remains when you take the obvious away?
*Examples: "Take one part away" / "Find the quietest version" / "Only one element of each kind"*

**2. INVERSION** — Flip the polarity. Run it backward. Do the opposite of what seems right.
*Examples: "Tell the opposite story" / "What if the opposite were true?" / "Tell it backward"*

**3. CONSTRAINT** — Impose an arbitrary rule that closes the obvious path and forces a new one.
*Examples: "Use the wrong tool" / "Use no words" / "Make it for a stranger"*

**4. DISPLACEMENT** — Move the problem sideways into a different medium, domain, speed, or scale.
*Examples: "Imagine it in another medium" / "Change the genre" / "Speak in colors instead of words"*

**5. ATTENTION** — Direct focus to what's being ignored, avoided, or taken for granted.
*Examples: "Notice what you're avoiding" / "What's too obvious?" / "Trace the unseen lines"*

**6. ACCEPTANCE** — Reframe a perceived problem as a resource. Work with what's actually there.
*Examples: "Start with a mistake" / "Find beauty in contradiction" / "Ruin it a little"*

**7. PERSPECTIVE** — Inhabit a genuinely alien point of view. Not a slight shift — a complete transplant.
*Examples: "Consider the lives of inanimate objects" / "Inhabit someone else's certainty" / "What would nature do?"*

**8. TIME** — Disrupt the temporal relationship to the work. Change when you are in it.
*Examples: "Start with an ending" / "Describe a memory you don't have" / "What exists before the beginning?"*

**9. REDUCTION** — Find the smallest irreducible unit. Make just one thing. Work only from there.
*Examples: "Make one thing" / "Find the atom of it" / "Not the whole — just one brick"*

**10. COURAGE** — Remove the permission-seeking. Dissolve hesitation. Do the avoided thing.
*Examples: "Try the impossible" / "Give way to your worst impulse" / "Do the thing you keep not doing"*

**11. PROCESS** — Dissolve perfectionism by focusing on motion rather than destination.
*Examples: "Just carry on" / "Begin before you're ready" / "Once you begin, something will be found"*

**12. REALITY CHECK** — Cut through abstraction. Look at what's actually there. Name the real thing.
*Examples: "Is it finished?" / "What are you actually making?" / "State the problem as simply as possible"*

---

## The AFM System Prompt

Use this as the `systemPrompt` parameter in your `LanguageModelSession`:

```
You generate creative prompts for a tool called Reflect. These prompts are inspired by Brian Eno and Peter Schmidt's Oblique Strategies — a deck of cards designed to break creative blocks through lateral thinking.

Your prompts must follow these rules:

RULES:
1. Each prompt uses exactly one of these 12 structural moves: Subtraction, Inversion, Constraint, Displacement, Attention, Acceptance, Perspective, Time, Reduction, Courage, Process, or Reality Check.
2. Do not name the move in the output. The move is the hidden structure, not the content.
3. Length: 3 to 9 words. Shorter is almost always better.
4. Voice: oblique, not direct. Suggest a direction, never issue an order.
5. Never use: "journey", "transform", "embrace", "soul", "authentic", "growth", "heal", "manifest", "radical", "surrender", "self-care", or any therapy/wellness vocabulary.
6. Never be encouraging or motivational. The prompt is not a coach. It is a disruptor.
7. The prompt should feel unexpected. If it sounds like something from a motivational poster, discard it and try again.
8. Domain-agnostic: the prompt should work for a musician, a painter, a writer, a software engineer, a chef. Never assume a domain.

OUTPUT FORMAT:
Return only the prompt text. No punctuation at the end unless it is a question mark. No quotation marks. No explanation.

MOVE TO USE THIS TIME: [INSERT MOVE NAME]
```

---

## Swift Implementation Notes

### Selecting a Move
Before calling AFM, select a move type at random — but weight away from moves
already represented in the recent prompt history. The `PromptEngine` tracks
the last 10 prompts shown; the `AFMPromptGenerator` should request a move
type that hasn't appeared in the last 3 generated prompts.

```swift
// Pseudo-code
let recentMoves = promptEngine.recentGeneratedMoves(count: 3)
let availableMoves = Move.allCases.filter { !recentMoves.contains($0) }
let selectedMove = availableMoves.randomElement() ?? Move.allCases.randomElement()!
let systemPrompt = baseSystemPrompt.replacingOccurrences(
    of: "[INSERT MOVE NAME]",
    with: selectedMove.rawValue
)
```

### Availability Gating
```swift
import FoundationModels

func isAFMAvailable() -> Bool {
    return SystemLanguageModel.default.availability == .available
}
```

Only call AFM when `.available`. Every other case — `.deviceNotEligible`,
`.appleIntelligenceNotEnabled`, any future cases — falls back to curated
library silently. No user messaging about which source is being used.

### Buffer Management
- Buffer target size: 5
- Refill threshold: when buffer drops to 2 or below
- Refill asynchronously using a detached Task
- If generation fails for any reason, catch silently and draw from curated library
- Never block the UI waiting for generation

```swift
// Pseudo-code for buffer refill
private func refillBufferIfNeeded() {
    guard buffer.count <= 2, isAFMAvailable() else { return }
    Task.detached(priority: .background) {
        let needed = 5 - self.buffer.count
        for _ in 0..<needed {
            if let prompt = try? await self.generateOne() {
                await MainActor.run { self.buffer.append(prompt) }
            }
        }
    }
}
```

### Validation
Before adding a generated prompt to the buffer, validate:
- Length: between 3 and 12 words
- Not a duplicate of anything in the curated library (simple string match)
- Not a duplicate of anything currently in the buffer
- Does not contain any of the banned vocabulary words

If validation fails, discard silently and generate another.

---

## Quality Notes for Future Prompt Curation

When adding new prompts to the curated library, apply the same 12-move grammar.
Tag each prompt with its primary move type. Aim for roughly equal distribution
across all 12 moves. The curated library should always be the backbone —
AFM extends it, never replaces it.

Prompts that work best are:
- Surprising on first read
- Immediately applicable to whatever the user is doing
- Impossible to comply with literally — they require interpretation
- Domain-agnostic
- Short enough to land before the brain starts analyzing

Prompts that fail:
- Sound like instructions ("Do X to achieve Y")
- Assume a specific medium or domain
- Use emotional or therapeutic language
- Are longer than one thought

---

*Reflect: Creative Sparks — AFM Generation Spec*
*Drafted by Strategic Claude in collaboration with Mark, May 2026*
