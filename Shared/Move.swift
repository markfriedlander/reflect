// ========== BLOCK 1: Move.swift - START ==========
//
//  Move.swift
//  Reflect: Creative Sparks
//
//  The 12 structural moves that underlie every prompt — curated and generated.
//  Derived from analysis of all three editions of Eno & Schmidt's
//  Oblique Strategies. See Docs/AFM_SPEC.md for the full grammar.
//
//  Raw values match the names the AFM system prompt expects, so the same
//  enum is the single source of truth for both PromptEngine selection
//  and AFMPromptGenerator move-substitution.
//

import Foundation

enum Move: String, CaseIterable, Hashable, Codable {
    case subtraction   = "Subtraction"
    case inversion     = "Inversion"
    case constraint    = "Constraint"
    case displacement  = "Displacement"
    case attention     = "Attention"
    case acceptance    = "Acceptance"
    case perspective   = "Perspective"
    case time          = "Time"
    case reduction     = "Reduction"
    case courage       = "Courage"
    case process       = "Process"
    case realityCheck  = "Reality Check"
}
// ========== BLOCK 1: Move.swift - END ==========
