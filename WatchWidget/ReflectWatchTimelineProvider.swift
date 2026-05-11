// ========== BLOCK: ReflectWatchTimelineProvider.swift - START ==========
//
//  ReflectWatchTimelineProvider.swift
//  ReflectWatchWidget
//
//  Spaces entries 40–70 minutes apart, same cluster-avoidance applied
//  within the batch as the iOS widget. watchOS gives complications a
//  refresh budget; our spacing (median ~55 min, max 70) yields roughly
//  20–24 refreshes per day, well under the ~50/day budget floor.
//
//  Inline complication families have very short visual space, so we
//  truncate to the first ~4 words for `.accessoryInline`. The
//  rectangular family gets the whole prompt.
//

#if os(watchOS)
import WidgetKit
import Foundation

struct ReflectWatchEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct ReflectWatchTimelineProvider: TimelineProvider {

    private static let entriesPerTimeline = 12   // ~8–14 hours of coverage

    func placeholder(in context: Context) -> ReflectWatchEntry {
        ReflectWatchEntry(date: Date(), text: "Reflect")
    }

    func getSnapshot(in context: Context, completion: @escaping (ReflectWatchEntry) -> Void) {
        let text = curatedPrompts.randomElement()?.text ?? "Reflect"
        completion(ReflectWatchEntry(date: Date(), text: text))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReflectWatchEntry>) -> Void) {
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

        var entries: [ReflectWatchEntry] = []
        var t = Date()
        for _ in 0..<Self.entriesPerTimeline {
            entries.append(ReflectWatchEntry(date: t, text: pickNext().text))
            t = t.addingTimeInterval(Double.random(in: 40 * 60 ... 70 * 60))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
#endif
// ========== BLOCK: ReflectWatchTimelineProvider.swift - END ==========
