// ========== BLOCK: ReflectWatchComplicationView.swift - START ==========
//
//  ReflectWatchComplicationView.swift
//  ReflectWatchWidget
//
//  Renders the same prompt across three complication families:
//    .accessoryRectangular  — full prompt, multiple lines
//    .accessoryInline       — first words only, single line
//    .accessoryCircular     — three words max, centered (small)
//
//  No tap interaction beyond opening the app — watchOS forwards taps
//  on accessory complications to the host app automatically.
//

#if os(watchOS)
import WidgetKit
import SwiftUI

struct ReflectWatchComplicationView: View {
    let entry: ReflectWatchEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            Text(short(entry.text, maxWords: 6))
        case .accessoryCircular:
            Text(short(entry.text, maxWords: 3))
                .font(.caption2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
        default:
            Text(entry.text)
        }
    }

    private var rectangular: some View {
        Text(entry.text)
            .font(.system(.caption, design: .default).weight(.regular))
            .multilineTextAlignment(.leading)
            .minimumScaleFactor(0.7)
            .lineLimit(3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetAccentable()
    }

    /// Truncate to N words. Used for inline (single-line) and circular
    /// (very small) families where the full prompt won't fit.
    private func short(_ text: String, maxWords: Int) -> String {
        let words = text.split(whereSeparator: { $0.isWhitespace })
        guard words.count > maxWords else { return text }
        return words.prefix(maxWords).joined(separator: " ") + "…"
    }
}
#endif
// ========== BLOCK: ReflectWatchComplicationView.swift - END ==========
