// ========== BLOCK: ReflectWatchWidgetBundle.swift - START ==========
//
//  ReflectWatchWidgetBundle.swift
//  ReflectWatchWidget — watchOS complication
//
//  Ambient single-prompt complication that drifts on its own. No user
//  interaction — tap the complication to open the watch app, that's it.
//  Refresh schedule sits comfortably above watchOS's complication
//  refresh budget floor.
//
//  The deck you always have with you, in its most passive form. Look
//  down to check the time, get a card.
//

#if os(watchOS)
import WidgetKit
import SwiftUI

@main
struct ReflectWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReflectWatchWidget()
    }
}

struct ReflectWatchWidget: Widget {
    let kind = "ReflectWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReflectWatchTimelineProvider()) { entry in
            ReflectWatchComplicationView(entry: entry)
        }
        .configurationDisplayName("Reflect")
        .description("Creative prompts on your wrist.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
        ])
    }
}
#endif
// ========== BLOCK: ReflectWatchWidgetBundle.swift - END ==========
