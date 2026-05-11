// ========== BLOCK: RefreshIntent.swift - START ==========
//
//  RefreshIntent.swift
//  ReflectWidget
//
//  App Intent that fires when the user taps the widget. It tells
//  WidgetCenter to throw away the current timeline and ask the
//  provider for a fresh one — which produces a new prompt without
//  ever opening the host app.
//

import AppIntents
import WidgetKit

struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Show another prompt"
    static var description = IntentDescription("Refreshes the widget with a different card.")
    static var isDiscoverable: Bool = false  // private — only the widget surfaces it

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "ReflectWidget")
        return .result()
    }
}
// ========== BLOCK: RefreshIntent.swift - END ==========
