// ========== BLOCK: AFMPromptGenerator.swift - START ==========
//
//  AFMPromptGenerator.swift
//  Reflect: Creative Sparks
//
//  Apple Foundation Models integration. On capable devices, keeps a small
//  buffer of pre-generated cards that follow the same 12-move grammar as
//  the curated library. The user never knows whether a given card came
//  from the buffer or the deck.
//
//  Hard rules (see Docs/AFM_SPEC.md):
//   - Only call AFM when SystemLanguageModel.default.isAvailable.
//   - Buffer target: 5. Refill threshold: 2 or below. Refill in background.
//   - Validate every generated card; discard silently on failure.
//   - On any error, swallow it and let the engine fall back to curated.
//
//  API surface verified directly against Apple's FoundationModels docs
//  (LanguageModelSession, GenerationOptions, Instructions):
//   - LanguageModelSession(instructions:) — convenience init that takes
//     the system prompt as a typed Instructions value, separate from the
//     user prompt that follows. Cleaner role separation than concatenating.
//   - session.respond(to: String, options:) async throws -> Response<String>
//     Non-streaming. We're generating ~5 words; streaming buys us nothing
//     except complexity.
//   - GenerationOptions(temperature:, maximumResponseTokens:) — cap output
//     length to 30 tokens (well above our 12-word ceiling) to bound latency
//     and discourage rambling.
//   - SystemLanguageModel.default.isAvailable — Bool gate.
//
//  System prompt tuned via the Tools/AFMHarness.swift iteration loop
//  (6 rounds, real macOS 26 AFM output). Tuning notes in HISTORY.md.
//
//  Compiles on systems without the FoundationModels framework via
//  canImport — on those builds (tvOS, watchOS, older Macs), isAvailable
//  is false forever and takeNext() always returns nil.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class AFMPromptGenerator {

    // MARK: - Tunables

    private let bufferTarget = 5
    private let refillThreshold = 2
    private static let maxRetriesPerSlot = 3
    private static let temperature: Double = 0.9
    private static let maximumResponseTokens: Int = 30
    private static let examplesPerCall = 4

    // MARK: - State

    private var buffer: [PromptCard] = []
    private var isRefilling = false

    /// Per-move pool of example prompts, built from the curated library at
    /// init time. A random subset is sampled into the system prompt on each
    /// generation so the model can't fixate on copying any single example.
    private let examplePools: [Move: [String]]

    // MARK: - Init

    init(library: [PromptCard] = curatedPrompts) {
        var pools: [Move: [String]] = [:]
        for move in Move.allCases {
            pools[move] = library
                .filter { $0.moves.contains(move) }
                .map(\.text)
        }
        self.examplePools = pools
    }

    // MARK: - Move semantics
    //
    // What each move actually does. Included in the system prompt so the
    // model understands the meaning of the move, not just the surface form
    // of its example outputs.

    private static let moveSemantics: [Move: String] = [
        .subtraction:  "Remove something. Strip to essence. What remains when you take the obvious away?",
        .inversion:    "Flip the polarity. Run it backward. Do the opposite of what seems right.",
        .constraint:   "Impose an arbitrary rule that closes the obvious path and forces a new one.",
        .displacement: "Move the problem sideways into a different medium, domain, speed, or scale.",
        .attention:    "Direct focus to what's being ignored, avoided, or taken for granted.",
        .acceptance:   "Reframe a perceived problem as a resource. Work with what's actually there.",
        .perspective:  "Inhabit a genuinely alien point of view. A complete transplant, not a slight shift.",
        .time:         "Disrupt the temporal relationship to the work. Change when you are in it.",
        .reduction:    "Find the smallest irreducible unit. Make just one thing. Work only from there.",
        .courage:      "Remove the permission-seeking. Dissolve hesitation. Do the avoided thing.",
        .process:      "Dissolve perfectionism by focusing on motion rather than destination.",
        .realityCheck: "Cut through abstraction. Look at what's actually there. Name the real thing.",
    ]

    // MARK: - Banned vocabulary

    private static let bannedWords: Set<String> = [
        "journey", "transform", "embrace", "soul", "authentic",
        "growth", "heal", "manifest", "radical", "surrender", "self-care"
    ]

    /// Tokens that name a single creative medium and therefore violate the
    /// domain-agnostic rule (rule #8 in the system prompt).
    private static let domainWords: Set<String> = [
        "poem", "poetry", "song", "novel", "story", "paragraph", "stanza", "chapter", "essay",
        "canvas", "painting", "paint", "sketch", "sculpture", "palette", "brush", "ink", "page",
        "meal", "dish", "recipe", "ingredients", "ingredient", "flavor",
        "code", "function", "algorithm", "program", "script",
        "melody", "chord", "lyric", "lyrics", "instrument", "drum", "symphony", "composition",
        "writing", "narrative", "manuscript", "draft",
        "drawing", "drawings", "photograph"
    ]

    /// Multi-word clichés the model reaches for when uncertain.
    private static let clicheTokens: [String] = [
        "step outside the box",
        "think outside the box",
        "push your boundaries",
        "find your voice",
        "follow your bliss",
        "get out of your comfort zone",
        "trust the process"
    ]

    // MARK: - System prompt builder

    private func buildSystemPrompt(for move: Move, examples: [String]) -> String {
        let exampleBlock = examples.map { "- \($0)" }.joined(separator: "\n")
        let semantics = Self.moveSemantics[move] ?? ""

        return """
        You write single-line creative prompts in the style of Brian Eno and Peter Schmidt's Oblique Strategies — short, oblique cards that disrupt a creative person's habitual thinking. The prompts work for any creative discipline (music, visual art, writing, software, cooking, design).

        THIS PROMPT MUST EMBODY THE "\(move.rawValue)" MOVE.
        What that means: \(semantics)
        A reader should be able to feel that semantic in the prompt without being told the move name.

        FORM: A prompt is almost always one of two things:
        - A short directive starting with a verb ("Take one part away", "Use the wrong tool")
        - A short question ("What is its shadow?", "What's hiding in plain sight?")
        A prompt is NOT a poetic image, NOT a metaphor, NOT a description, NOT a scene.

        Below are reference prompts that use the \(move.rawValue) move. Read them to absorb the voice — then write a DIFFERENT one that captures the same spirit. Do NOT copy. Do NOT paraphrase. Do NOT write a tiny variation. Write something genuinely new.

        Reference (DO NOT reproduce — voice study only):
        \(exampleBlock)

        Examples of BAD output (never write anything like these):
        - Write a short poem about a cat (BAD: assumes a creative domain)
        - Cook a meal with only five ingredients (BAD: assumes a creative domain)
        - Create a melody with a drum (BAD: assumes a creative domain)
        - Imagine a universe where colors have no shape (BAD: starts with "Imagine"; abstract not oblique)
        - A river whispers secrets through reeds (BAD: poetic image, not a directive)
        - Embrace your authentic creative journey (BAD: motivational vocabulary)
        - Step outside the box (BAD: cliché)
        - Reverse it (BAD: too short, too generic; many moves have a "reverse" flavor)
        - Reverse the narrative / Reverse the composition (BAD: lazy "Reverse X" pattern)
        - Move: \(move.rawValue) (BAD: echoes the move name)

        Hard rules:
        1. Length: 3 to 7 words. Hard maximum 9. Count.
        2. Form: directive or question. Not an image. Not a sentence describing a scene.
        3. Domain-agnostic. Forbidden: poem, canvas, song, meal, code, story, palette, melody, instrument, chord, brush, lyric, recipe, paint, sculpture, painting, novel, paragraph, ink, page, drum, symphony, composition, writing, narrative, drawing.
        4. No motivational/wellness words: journey, transform, embrace, soul, authentic, growth, heal, manifest, radical, surrender, self-care.
        5. No clichés ("step outside the box", "think outside the box", "trust the process").
        6. Do not start with "Imagine".
        7. Do not name or echo the move ("\(move.rawValue)").
        8. Do not copy any reference prompt. Do not write a near-trivial variation.
        9. Output ONLY the prompt text — no quotation marks, no labels, no preamble, no bullet, no number.
        10. No terminal punctuation except "?" if it's a question.

        Now write ONE new \(move.rawValue) prompt — 3 to 7 words, directive or question, that captures: \(semantics)
        """
    }

    // MARK: - Availability

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
        #else
        return false
        #endif
    }

    // MARK: - Public API

    /// Pulls the next generated card off the buffer, if any.
    /// Returns nil when the buffer is empty — engine falls back to curated.
    func takeNext() -> PromptCard? {
        guard !buffer.isEmpty else { return nil }
        return buffer.removeFirst()
    }

    /// Kicks off a background refill if the buffer has dropped to the
    /// threshold. Returns immediately. Never blocks. Silent on failure.
    func refillIfNeeded(avoidingMoves: [Move], avoidingTexts: Set<String>) {
        guard !isRefilling,
              buffer.count <= refillThreshold,
              Self.isAvailable else { return }

        isRefilling = true
        let needed = bufferTarget - buffer.count
        let recentMoves = avoidingMoves
        let curatedTexts = avoidingTexts

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            for _ in 0..<needed {
                if let card = await self.generateOne(
                    avoidingMoves: recentMoves,
                    avoidingTexts: curatedTexts
                ) {
                    self.buffer.append(card)
                }
            }
            self.isRefilling = false
        }
    }

    // MARK: - Generation

    private func generateOne(
        avoidingMoves recentMoves: [Move],
        avoidingTexts curatedTexts: Set<String>
    ) async -> PromptCard? {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, *) else { return nil }

        let candidates = Move.allCases.filter { !recentMoves.contains($0) }
        let move = candidates.randomElement() ?? Move.allCases.randomElement()!

        let pool = examplePools[move] ?? []
        let examples = Array(pool.shuffled().prefix(Self.examplesPerCall))
        let instructions = buildSystemPrompt(for: move, examples: examples)
        let userPrompt = "Write the prompt now."

        let options = GenerationOptions(
            sampling: nil,
            temperature: Self.temperature,
            maximumResponseTokens: Self.maximumResponseTokens
        )

        for _ in 0..<Self.maxRetriesPerSlot {
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: userPrompt, options: options)
                let text = Self.clean(response.content)
                if Self.validate(text: text, curatedTexts: curatedTexts) {
                    return PromptCard(text, move)
                }
            } catch {
                // Silent fallback per spec — engine pulls from curated instead.
                continue
            }
        }
        return nil
        #else
        return nil
        #endif
    }

    // MARK: - Cleaning + validation

    /// Trim whitespace, strip wrapping quotes, drop terminal punctuation
    /// other than '?'. The model occasionally adds these despite the rules.
    private static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip leading list-bullet artifacts ("1. ", "- ", "* ").
        let prefixesToStrip = ["- ", "* ", "1. ", "2. ", "3. "]
        for p in prefixesToStrip where text.hasPrefix(p) {
            text.removeFirst(p.count)
        }

        if let first = text.first, first == "\"" || first == "\u{201C}" {
            text.removeFirst()
        }
        if let last = text.last, last == "\"" || last == "\u{201D}" {
            text.removeLast()
        }
        if let last = text.last, last == "." || last == "!" || last == ";" || last == ":" {
            text.removeLast()
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func validate(text: String, curatedTexts: Set<String>) -> Bool {
        guard !text.isEmpty else { return false }
        let wordCount = text.split(whereSeparator: { $0.isWhitespace }).count
        guard (3...12).contains(wordCount) else { return false }

        let lower = text.lowercased()

        // Starts-with-"Imagine" is the model's most common drift pattern.
        if lower.hasPrefix("imagine ") { return false }

        // Multiple sentences = the model wrote prose, not a card.
        if text.contains(". ") || text.contains("; ") { return false }

        // Banned vocabulary (motivational/wellness).
        for banned in bannedWords where lower.contains(banned) {
            return false
        }

        // The model occasionally names the move it was given.
        let moveNames = ["subtraction", "inversion", "constraint", "displacement",
                         "attention", "acceptance", "perspective",
                         "reduction", "courage", "process", "reality check"]
        for name in moveNames where lower.contains(name) {
            return false
        }

        // Domain-agnostic check — reject if it names a single creative medium.
        let tokens = Set(lower.split(whereSeparator: { !$0.isLetter }).map(String.init))
        for domain in domainWords where tokens.contains(domain) {
            return false
        }

        // Multi-word cliché check.
        for cliche in clicheTokens where lower.contains(cliche) {
            return false
        }

        // Dedupe against the entire curated library (whatever the engine passed).
        if curatedTexts.contains(text) { return false }

        return true
    }
}
// ========== BLOCK: AFMPromptGenerator.swift - END ==========
