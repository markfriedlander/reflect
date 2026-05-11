// ========== BLOCK 4: PromptEngine.swift - START ==========
//
//  PromptEngine.swift
//  Reflect: Creative Sparks
//
//  The single source of truth for "what prompt do I show next?"
//
//  Selection rules:
//   1. Prefer the AFM-generated buffer when non-empty (silent — the user
//      never knows whether a prompt is curated or generated).
//   2. Avoid prompts already in the recent history (last 10).
//   3. Avoid the same primaryMove as the prompt just shown — back-to-back
//      same-move repeats break the obliqueness.
//
//  Views call `next()` and receive a String. They do not know about
//  AFM, history, moves, or any of the machinery. The prompt is the product.
//

import Foundation
import Observation
import os

@MainActor
@Observable
final class PromptEngine {

    private static let log = Logger(subsystem: "com.MarkFriedlander.Reflect", category: "engine")

    private let curated: [PromptCard]
    private let curatedTexts: Set<String>
    private let afm: AFMPromptGenerator?
    private let historyLimit = 30

    private(set) var recentHistory: [PromptCard] = []

    init(curated: [PromptCard] = curatedPrompts, afm: AFMPromptGenerator? = nil) {
        self.curated = curated
        self.curatedTexts = Set(curated.map(\.text))
        // Default afm to a fresh AFMPromptGenerator if none provided.
        // Constructed inside the MainActor-isolated init body to satisfy
        // Swift 6's actor-isolation rules for default arguments.
        self.afm = afm ?? AFMPromptGenerator(library: curated)
    }

    /// Returns the next prompt's text. Updates history and triggers AFM
    /// buffer refill in the background. Safe to call from any view event.
    func next() -> String {
        let (prompt, source) = chooseNext()
        record(prompt)
        Self.log.info("card #\(self.recentHistory.count) [\(source, privacy: .public)] [\(prompt.primaryMove?.rawValue ?? "?", privacy: .public)] \(prompt.text, privacy: .public)")
        afm?.refillIfNeeded(
            avoidingMoves: recentMoves(count: 3),
            avoidingTexts: curatedTexts
        )
        return prompt.text
    }

    // MARK: - Selection

    private func chooseNext() -> (PromptCard, String) {
        if let afm, let generated = afm.takeNext() {
            return (generated, "afm")
        }
        return (chooseFromCurated(), "curated")
    }

    private func chooseFromCurated() -> PromptCard {
        let lastMove = recentHistory.last?.primaryMove
        let recentTexts = Set(recentHistory.map(\.text))

        // Strict: not in recent history AND different primary move from last shown.
        let strict = curated.filter { p in
            !recentTexts.contains(p.text) &&
            (lastMove == nil || p.primaryMove != lastMove)
        }
        if let pick = strict.randomElement() { return pick }

        // Loosen: just avoid recent history.
        let loose = curated.filter { !recentTexts.contains($0.text) }
        if let pick = loose.randomElement() { return pick }

        // Deck exhausted — fall back to anything. (~191 prompts vs. 10-history
        // means this branch is unreachable in practice, but it keeps next()
        // total without an implicitly unwrapped optional.)
        return curated.randomElement() ?? PromptCard("Reflect", .process)
    }

    // MARK: - History

    private func record(_ prompt: PromptCard) {
        recentHistory.append(prompt)
        if recentHistory.count > historyLimit {
            recentHistory.removeFirst(recentHistory.count - historyLimit)
        }
    }

    /// The primary moves of the most recently shown prompts, newest last.
    /// Used by AFMPromptGenerator to bias generation toward an unused move.
    func recentMoves(count: Int) -> [Move] {
        recentHistory.suffix(count).compactMap(\.primaryMove)
    }
}
// ========== BLOCK 4: PromptEngine.swift - END ==========
