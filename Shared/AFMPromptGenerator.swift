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

    private static let bannedWords: Set<String> = [
        "journey", "transform", "embrace", "soul", "authentic",
        "growth", "heal", "manifest", "radical", "surrender", "self-care"
    ]

    // MARK: - State

    private var buffer: [PromptCard] = []
    private var isRefilling = false

    // MARK: - System prompt

    private static let baseSystemPrompt = """
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
    """

    // MARK: - Availability

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 17.0, macOS 14.0, *) {
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
            for _ in 0..<needed {
                if let card = await Self.generateOne(
                    avoidingMoves: recentMoves,
                    avoidingTexts: curatedTexts
                ) {
                    self?.buffer.append(card)
                }
            }
            self?.isRefilling = false
        }
    }

    // MARK: - Generation

    private static func generateOne(
        avoidingMoves recentMoves: [Move],
        avoidingTexts curatedTexts: Set<String>
    ) async -> PromptCard? {
        #if canImport(FoundationModels)
        guard #available(iOS 17.0, macOS 14.0, *) else { return nil }

        let candidates = Move.allCases.filter { !recentMoves.contains($0) }
        let move = candidates.randomElement() ?? Move.allCases.randomElement()!
        let instructions = baseSystemPrompt + "\n\nMOVE TO USE THIS TIME: " + move.rawValue
        let userPrompt = "Generate one prompt now."
        let options = GenerationOptions(
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )

        for _ in 0..<maxRetriesPerSlot {
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: userPrompt, options: options)
                let text = clean(response.content)
                if validate(text: text, avoidingTexts: curatedTexts) {
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

    // MARK: - Validation

    /// Trim whitespace, strip wrapping quotes, drop terminal punctuation
    /// other than '?'. The model occasionally adds these despite the rules.
    private static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private static func validate(text: String, avoidingTexts: Set<String>) -> Bool {
        guard !text.isEmpty else { return false }
        let wordCount = text.split(whereSeparator: { $0.isWhitespace }).count
        guard (3...12).contains(wordCount) else { return false }
        if avoidingTexts.contains(text) { return false }
        let lower = text.lowercased()
        for banned in bannedWords where lower.contains(banned) {
            return false
        }
        return true
    }
}
// ========== BLOCK: AFMPromptGenerator.swift - END ==========
