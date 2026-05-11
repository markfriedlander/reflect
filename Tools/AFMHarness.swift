// AFMHarness.swift
//
// Standalone test harness for Reflect's AFM prompt generation.
// Runs the same system-prompt + validation logic that ships in
// AFMPromptGenerator.swift, but cycles through every move type N
// times so we can read actual model output and iterate the prompt
// until quality is consistently high.
//
// Run with:
//   swift Tools/AFMHarness.swift [N]
// where N is generations per move (default 3).
//
// Requires:
//   - macOS 26+ (FoundationModels framework)
//   - Apple Intelligence enabled in System Settings
//   - On-device model downloaded (happens automatically on first run,
//     may take a moment)

import Foundation
import FoundationModels

// MARK: - Move grammar (mirrored from Shared/Move.swift)

enum Move: String, CaseIterable {
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

// MARK: - Move semantics (what each move actually *does*)

let moveSemantics: [Move: String] = [
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

// MARK: - Example pools per move (drawn from curated library, sampled per call)

let moveExamplePools: [Move: [String]] = [
    .subtraction: [
        "Take one part away", "Strip it down", "Use fewer elements", "Remove the expected",
        "Find the quietest version", "Simple subtraction", "Only one element of each kind",
        "Reduce until it breaks", "What's left when you take everything away?"
    ],
    .inversion: [
        "Turn it upside down", "Tell it backward", "Reverse it", "Tell the opposite story",
        "What if the opposite were true?", "Make it boring on purpose", "Find the worst version",
        "Abandon your plan", "Stick to the plan"
    ],
    .constraint: [
        "Use a limitation", "Use the wrong tool", "Use no words", "Limit the tools",
        "Use only questions", "Use only statements", "Add a rule", "Use an unexpected material",
        "Use a cliché", "Break your favorite rule", "Make it for a stranger",
        "Use only what's already here"
    ],
    .displacement: [
        "Change the time period", "Change the location", "Change the genre", "Change the tone",
        "Change the format", "Give it a soundtrack", "Make it mechanical", "Make it fictional",
        "Tell it with a symbol", "Tell it with color", "Make it a riddle", "Make it a protest"
    ],
    .attention: [
        "Notice what you're avoiding", "What's too obvious?", "Where is the tension?",
        "What would an expert ignore?", "Where is it rigid?", "Find the contradiction",
        "What is its shadow?", "Trace the unseen lines", "What's hiding in plain sight?",
        "What is the question behind the question?", "Listen to the hum beneath the noise",
        "Honor what you've been dismissing", "Notice what you always overlook"
    ],
    .acceptance: [
        "Make it feel accidental", "Ruin it a little", "Start with a mistake",
        "Find the pattern beneath chaos", "Allow it to be unfinished",
        "Make friends with emptiness", "What remains when everything changes?",
        "Find beauty in contradiction", "Make it broken", "Find beauty in what repels you"
    ],
    .perspective: [
        "What would a child say?", "What would nature do?", "Inhabit someone else's certainty",
        "Make yourself a stranger", "What would your closest friend do?", "Who would disapprove?",
        "Who else is affected?", "What would the work say about you?"
    ],
    .time: [
        "Start with an ending", "Start with a sound", "Start with a fear", "Make it ephemeral",
        "Make it fragile", "What's its history?", "What's its future?",
        "Describe a memory you don't have", "Unravel a memory backward",
        "Walk backward into the future", "What exists before the beginning?",
        "Return to what you've abandoned"
    ],
    .reduction: [
        "Make one thing", "Find the irreducible part", "Not the whole — just one brick",
        "What is the smallest true version?", "Do one thing completely", "Find the atom of it",
        "What is the single most important element?", "Make it fit in one sentence",
        "Reduce until it's only itself", "Name the one thing that cannot be removed"
    ],
    .courage: [
        "Try the impossible", "Ignore logic", "Make it shout",
        "Break your routine", "Make it for no one", "Go to the extreme",
        "Do the thing you keep not doing", "What if failure is the path?",
        "What would you create if you couldn't fail?", "Speak your desire without editing",
        "Stop asking permission", "Make the brave choice", "Drop your defenses"
    ],
    .process: [
        "Just carry on", "Make it feel inevitable", "Build a bridge to nowhere",
        "Follow the idea that won't leave you alone", "Once you begin, something will be found",
        "Let the work lead", "Don't wait for permission", "The next step is enough",
        "Begin before you're ready", "Follow what feels alive, not what feels correct",
        "Trust the process, not the plan", "Motion is the method"
    ],
    .realityCheck: [
        "What are you actually making?", "Is it finished?", "What rules are you following?",
        "What are you avoiding?", "State the problem as simply as possible",
        "What is actually here?", "What would happen if you said yes?", "What's the real question?",
        "Name the feeling", "What are you really doing right now?"
    ],
]

/// Sample 4 examples from the move's pool. Each call returns a different
/// random subset so the model can't fixate on copying any particular one.
func sampleExamples(for move: Move) -> [String] {
    let pool = moveExamplePools[move] ?? []
    return Array(pool.shuffled().prefix(4))
}

/// The flat list of every curated prompt — used as a dedup set so the model
/// can't satisfy validation by echoing any card from the deck.
let allCuratedTexts: Set<String> = {
    var s = Set<String>()
    for (_, pool) in moveExamplePools { s.formUnion(pool) }
    return s
}()

func systemPrompt(for move: Move, examples: [String]) -> String {
    let exampleBlock = examples.map { "- \($0)" }.joined(separator: "\n")
    let semantics = moveSemantics[move] ?? ""

    return """
    You write single-line creative prompts in the style of Brian Eno and Peter Schmidt's Oblique Strategies — short, oblique cards that disrupt a creative person's habitual thinking. The prompts work for any creative discipline (music, visual art, writing, software, cooking, design).

    THIS PROMPT MUST EMBODY THE "\(move.rawValue)" MOVE.
    What that means: \(semantics)
    A reader should be able to feel that semantic in the prompt without being told the move name.

    FORM: A prompt is almost always one of two things:
    - A short directive starting with a verb ("Take one part away", "Use the wrong tool")
    - A short question ("What is its shadow?", "What's hiding in plain sight?")
    A prompt is NOT a poetic image, NOT a metaphor, NOT a description, NOT a scene.

    Below are 4 reference prompts that all use the \(move.rawValue) move. Read them to absorb the voice — then write a DIFFERENT one that captures the same spirit. Do NOT copy. Do NOT paraphrase. Do NOT write a tiny variation. Write something genuinely new.

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

let bannedWords: Set<String> = [
    "journey", "transform", "embrace", "soul", "authentic",
    "growth", "heal", "manifest", "radical", "surrender", "self-care"
]

// MARK: - Cleaning + validation (mirrored from AFMPromptGenerator)

func clean(_ raw: String) -> String {
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

enum FailReason: String {
    case empty = "empty"
    case tooShort = "too-short"
    case tooLong = "too-long"
    case banned = "banned-word"
    case namedMove = "named-move"
    case startsWithImagine = "starts-with-imagine"
    case domainAssumed = "domain-assumed"
    case multipleSentences = "multiple-sentences"
    case cliche = "cliche"
    case copiedExample = "copied-example"
}

// Words that name a creative medium and would violate domain-agnostic rule.
// "writing", "drawing", "painting" are too generic to flag (could be metaphors).
let domainWords: Set<String> = [
    "poem", "poetry", "song", "novel", "story", "paragraph", "stanza", "chapter", "essay",
    "canvas", "painting", "paint", "sketch", "sculpture", "palette", "brush", "ink", "page",
    "meal", "dish", "recipe", "ingredients", "ingredient", "flavor",
    "code", "function", "algorithm", "program", "script",
    "melody", "chord", "lyric", "lyrics", "instrument", "drum", "symphony", "composition",
    "writing", "narrative", "manuscript", "draft",
    "drawing", "drawings", "photograph"
]

let clicheTokens: [String] = [
    "step outside the box",
    "think outside the box",
    "push your boundaries",
    "find your voice",
    "follow your bliss",
    "get out of your comfort zone",
    "trust the process"
]

func validate(text: String, exampleSet: Set<String>) -> FailReason? {
    if text.isEmpty { return .empty }
    let words = text.split(whereSeparator: { $0.isWhitespace })
    if words.count < 3 { return .tooShort }
    if words.count > 12 { return .tooLong }

    let lower = text.lowercased()
    if lower.hasPrefix("imagine ") { return .startsWithImagine }
    if text.contains(". ") || text.contains("; ") { return .multipleSentences }

    for banned in bannedWords where lower.contains(banned) {
        return .banned
    }
    let moveNames = ["subtraction", "inversion", "constraint", "displacement",
                     "attention", "acceptance", "perspective",
                     "reduction", "courage", "process", "reality check"]
    for name in moveNames where lower.contains(name) {
        return .namedMove
    }
    let tokens = lower.split(whereSeparator: { !$0.isLetter }).map(String.init)
    let tokenSet = Set(tokens)
    for domain in domainWords where tokenSet.contains(domain) {
        return .domainAssumed
    }
    for cliche in clicheTokens where lower.contains(cliche) {
        return .cliche
    }
    // Reject if the output matches any curated prompt (entire library, not
    // just the few examples we sampled this call).
    if allCuratedTexts.contains(text) { return .copiedExample }
    if exampleSet.contains(text) { return .copiedExample }
    return nil
}

// MARK: - Result record

struct GenerationResult {
    let move: Move
    let attempt: Int
    let raw: String
    let cleaned: String
    let wordCount: Int
    let fail: FailReason?
    let elapsed: TimeInterval
}

// MARK: - Single generation

func generate(move: Move, options: GenerationOptions) async -> (raw: String, elapsed: TimeInterval, error: String?, examples: [String]) {
    let examples = sampleExamples(for: move)
    let instructions = systemPrompt(for: move, examples: examples)
    let session = LanguageModelSession(instructions: instructions)
    let start = Date()
    do {
        let response = try await session.respond(to: "Write the prompt now.", options: options)
        return (response.content, Date().timeIntervalSince(start), nil, examples)
    } catch {
        return ("", Date().timeIntervalSince(start), "\(error)", examples)
    }
}

// MARK: - Main (top-level script)

func runHarness() async {
    let n = CommandLine.arguments.count > 1 ? (Int(CommandLine.arguments[1]) ?? 3) : 3

        print("=== Reflect AFM Harness ===")
        print("Generations per move: \(n)")
        print("Total runs: \(n * Move.allCases.count)\n")

        // Availability check
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            print("❌ SystemLanguageModel.default.isAvailable is false.")
            print("   Enable Apple Intelligence in System Settings, ensure")
            print("   the on-device model has finished downloading, then re-run.")
            exit(1)
        }
        print("✅ Apple Intelligence available, model ready\n")

        let options = GenerationOptions(
            sampling: nil,
            temperature: 0.9,
            maximumResponseTokens: 30
        )

        var results: [GenerationResult] = []

        for move in Move.allCases {
            print("--- \(move.rawValue) ---")
            for attempt in 1...n {
                let result = await generate(move: move, options: options)
                if let error = result.error {
                    print(String(format: "  [%d] ERROR (%.2fs): %@", attempt, result.elapsed, error))
                    continue
                }
                let cleaned = clean(result.raw)
                let wordCount = cleaned.split(whereSeparator: { $0.isWhitespace }).count
                let exampleSet = Set(result.examples)
                let fail = validate(text: cleaned, exampleSet: exampleSet)
                let raw = result.raw
                let elapsed = result.elapsed
                let mark = fail == nil ? "✓" : "✗"
                let reason = fail.map { " [\($0.rawValue)]" } ?? ""
                print(String(format: "  [%d] %@ (%.1fs, %dw)%@: %@",
                              attempt, mark, elapsed, wordCount, reason, cleaned))
                results.append(GenerationResult(
                    move: move, attempt: attempt, raw: raw, cleaned: cleaned,
                    wordCount: wordCount, fail: fail, elapsed: elapsed
                ))
            }
            print("")
        }

        // Summary
        let total = results.count
        let passed = results.filter { $0.fail == nil }.count
        let pct = total > 0 ? Double(passed) / Double(total) * 100 : 0

        print("=== Summary ===")
        print(String(format: "Pass rate: %d / %d (%.1f%%)", passed, total, pct))
        print("Avg latency: \(String(format: "%.2fs", results.map(\.elapsed).reduce(0, +) / Double(max(total, 1))))")
        print("Avg word count: \(String(format: "%.1f", Double(results.map(\.wordCount).reduce(0, +)) / Double(max(total, 1))))")

        var byReason: [String: Int] = [:]
        for r in results {
            if let fail = r.fail {
                byReason[fail.rawValue, default: 0] += 1
            }
        }
        if !byReason.isEmpty {
            print("Failures by reason:")
            for (reason, count) in byReason.sorted(by: { $0.value > $1.value }) {
                print("  \(reason): \(count)")
            }
        }

        // Per-move pass rate
        print("\nPer-move pass rate:")
        for move in Move.allCases {
            let movResults = results.filter { $0.move == move }
            let movPassed = movResults.filter { $0.fail == nil }.count
            let movTotal = movResults.count
            print("  \(move.rawValue.padding(toLength: 16, withPad: " ", startingAt: 0)): \(movPassed)/\(movTotal)")
        }

        // Dump full output to file
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let outPath = "Tools/runs/\(timestamp).txt"
        var dump = "Reflect AFM Harness — \(timestamp)\n"
        dump += "N per move: \(n), pass rate: \(passed)/\(total)\n\n"
        for move in Move.allCases {
            dump += "=== \(move.rawValue) ===\n"
            for r in results.filter({ $0.move == move }) {
                let mark = r.fail == nil ? "✓" : "✗ \(r.fail!.rawValue)"
                dump += "  [\(r.attempt)] \(mark) (\(r.wordCount)w): \(r.cleaned)\n"
                if r.cleaned != r.raw.trimmingCharacters(in: .whitespacesAndNewlines) {
                    dump += "      raw: \(r.raw.trimmingCharacters(in: .whitespacesAndNewlines))\n"
                }
            }
            dump += "\n"
        }
    try? dump.write(toFile: outPath, atomically: true, encoding: .utf8)
    print("\nFull dump: \(outPath)")
}

await runHarness()
