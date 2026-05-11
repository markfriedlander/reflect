// ========== BLOCK: ReflectTimelineProvider.swift - START ==========
//
//  ReflectTimelineProvider.swift
//  ReflectWidget
//
//  Generates a timeline of prompt entries spaced 40–70 minutes apart.
//  WidgetKit's runtime advances through the entries in order, and re-
//  asks for a new timeline when we've reached `.atEnd`. A tap on the
//  widget fires `RefreshIntent`, which forces an immediate timeline
//  reload via WidgetCenter.
//
//  Same cluster-avoidance + recent-history logic as the main engine,
//  applied across the entries within a single timeline batch.
//

import WidgetKit
import Foundation

struct ReflectEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct ReflectTimelineProvider: TimelineProvider {

    private static let entriesPerTimeline = 8     // ~6–9 hours of coverage at 40–70 min spacing

    /// Static preview content for the widget gallery / placeholder.
    func placeholder(in context: Context) -> ReflectEntry {
        ReflectEntry(date: Date(), text: "Reflect")
    }

    func getSnapshot(in context: Context, completion: @escaping (ReflectEntry) -> Void) {
        let text = curatedPrompts.randomElement()?.text ?? "Reflect"
        completion(ReflectEntry(date: Date(), text: text))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReflectEntry>) -> Void) {
        // Mini-engine just for this timeline batch — same back-to-back-same-move
        // and recent-text avoidance as PromptEngine, but stateless across batches.
        var recent: [PromptCard] = []
        let historyLimit = 30

        func pickNext() -> PromptCard {
            let lastMove = recent.last?.primaryMove
            let recentTexts = Set(recent.map(\.text))
            let strict = curatedPrompts.filter { p in
                !recentTexts.contains(p.text) &&
                (lastMove == nil || p.primaryMove != lastMove)
            }
            let pick = strict.randomElement()
                ?? curatedPrompts.filter { !recentTexts.contains($0.text) }.randomElement()
                ?? curatedPrompts.randomElement()!
            recent.append(pick)
            if recent.count > historyLimit { recent.removeFirst() }
            return pick
        }

        var entries: [ReflectEntry] = []
        var t = Date()
        for _ in 0..<Self.entriesPerTimeline {
            entries.append(ReflectEntry(date: t, text: pickNext().text))
            t = t.addingTimeInterval(Double.random(in: 40 * 60 ... 70 * 60))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
// ========== BLOCK: ReflectTimelineProvider.swift - END ==========
