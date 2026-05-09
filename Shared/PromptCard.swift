// ========== BLOCK: PromptCard.swift - START ==========
//
//  PromptCard.swift
//  Reflect: Creative Sparks
//
//  A single card from the deck — its text and the structural move(s) it
//  embodies. Most cards use one move; the Mixed cards combine two.
//  PromptEngine uses `primaryMove` for back-to-back avoidance.
//
//  Named PromptCard rather than Prompt to avoid collision with the
//  FoundationModels framework's public `Prompt` type, which is used
//  inside @PromptBuilder closures during AFM generation.
//

import Foundation

struct PromptCard: Hashable, Codable {
    let text: String
    let moves: [Move]

    var primaryMove: Move? { moves.first }

    init(_ text: String, _ moves: Move...) {
        self.text = text
        self.moves = moves
    }
}
// ========== BLOCK: PromptCard.swift - END ==========
