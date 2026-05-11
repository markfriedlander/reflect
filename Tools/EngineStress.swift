// EngineStress.swift
//
// Stress-tests PromptEngine selection logic over N draws.
// Reports: full sequence, move distribution, back-to-back move violations,
// text-repeat violations within history window.
//
// Inlines the necessary types so it can run as a standalone script.

import Foundation

// --- Move (mirrors Shared/Move.swift) ---
enum Move: String, CaseIterable, Hashable {
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

struct Card: Hashable {
    let text: String
    let moves: [Move]
    var primaryMove: Move? { moves.first }
}

// --- Load curated library from Shared/Prompts.swift via simple parsing ---
let promptsURL = URL(fileURLWithPath: "Shared/Prompts.swift")
let promptsSrc = try String(contentsOf: promptsURL, encoding: .utf8)

func parseLibrary(_ src: String) -> [Card] {
    var cards: [Card] = []
    let moveLookup: [String: Move] = Dictionary(uniqueKeysWithValues: Move.allCases.map {
        let k = ".\(String(describing: $0))"
        return (k, $0)
    })
    let regex = try! NSRegularExpression(pattern: #"PromptCard\("(.+?)"((?:,\s*\.\w+)+)\)"#)
    let ns = src as NSString
    let matches = regex.matches(in: src, range: NSRange(location: 0, length: ns.length))
    for m in matches {
        let text = ns.substring(with: m.range(at: 1))
        let moveStrs = ns.substring(with: m.range(at: 2))
        let tokens = moveStrs.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var ms: [Move] = []
        for t in tokens where !t.isEmpty {
            if let m = moveLookup[t] { ms.append(m) }
        }
        cards.append(Card(text: text, moves: ms))
    }
    return cards
}

let library = parseLibrary(promptsSrc)
print("Loaded \(library.count) cards from Shared/Prompts.swift\n")

// --- Engine logic (mirrors Shared/PromptEngine.swift) ---
final class Engine {
    let curated: [Card]
    var history: [Card] = []
    let historyLimit = 30

    init(_ curated: [Card]) { self.curated = curated }

    func next() -> Card {
        let pick = choose()
        history.append(pick)
        if history.count > historyLimit { history.removeFirst() }
        return pick
    }
    private func choose() -> Card {
        let lastMove = history.last?.primaryMove
        let recentTexts = Set(history.map(\.text))
        let strict = curated.filter { c in
            !recentTexts.contains(c.text) &&
            (lastMove == nil || c.primaryMove != lastMove)
        }
        if let p = strict.randomElement() { return p }
        let loose = curated.filter { !recentTexts.contains($0.text) }
        if let p = loose.randomElement() { return p }
        return curated.randomElement()!
    }
}

// --- Run ---
let N = 50
let engine = Engine(library)
var sequence: [Card] = []
for _ in 0..<N { sequence.append(engine.next()) }

// --- Report ---
print("=== Sequence ===")
for (i, c) in sequence.enumerated() {
    let num = String(format: "%2d", i + 1)
    let move = c.primaryMove?.rawValue ?? "?"
    print("  \(num). [\(move)] \(c.text)")
}

print("\n=== Audit ===")

// Move distribution
var moveCount: [Move: Int] = [:]
for c in sequence { if let m = c.primaryMove { moveCount[m, default: 0] += 1 } }
print("Move distribution:")
for m in Move.allCases {
    let n = moveCount[m] ?? 0
    let bar = String(repeating: "█", count: n)
    let name = m.rawValue.padding(toLength: 15, withPad: " ", startingAt: 0)
    let count = String(format: "%2d", n)
    print("  \(name) \(count) \(bar)")
}

// Back-to-back same primary move violations
var backToBack = 0
for i in 1..<sequence.count {
    if let a = sequence[i-1].primaryMove,
       let b = sequence[i].primaryMove, a == b {
        backToBack += 1
        print("BACK-TO-BACK SAME MOVE at #\(i-1)→#\(i): \(a.rawValue)")
    }
}
print("Back-to-back same-move violations: \(backToBack)")

// Text repeats within history window
var repeats = 0
for i in 0..<sequence.count {
    let lo = max(0, i - 30)
    for j in lo..<i {
        if sequence[i].text == sequence[j].text {
            repeats += 1
            print("REPEAT within window at #\(j) and #\(i): \(sequence[i].text)")
        }
    }
}
print("Text repeats within history window: \(repeats)")

// Unique texts
let unique = Set(sequence.map(\.text)).count
print("Unique cards in \(N) draws: \(unique) / \(N)")
