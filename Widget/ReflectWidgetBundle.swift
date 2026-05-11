// ========== BLOCK: ReflectWidgetBundle.swift - START ==========
//
//  ReflectWidgetBundle.swift
//  ReflectWidget — iOS / iPadOS / Mac widget extension
//
//  The widget IS the visual: one prompt, centered, on pure black, no
//  chrome. Auto-cycles on WidgetKit's timeline (refresh every 40–70
//  minutes). Tapping the widget triggers an App Intent that refreshes
//  the timeline in place — no app launch.
//
//  Curated library only. No AFM in the widget — that would add startup
//  latency to every refresh and burn battery for no user-visible gain
//  on a surface this small.
//

import WidgetKit
import SwiftUI

@main
struct ReflectWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReflectWidget()
    }
}

struct ReflectWidget: Widget {
    let kind = "ReflectWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReflectTimelineProvider()) { entry in
            ReflectWidgetView(entry: entry)
        }
        .configurationDisplayName("Reflect")
        .description("Creative prompts that drift past on their own.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled() // full bleed — no system padding around the black field
    }
}
// ========== BLOCK: ReflectWidgetBundle.swift - END ==========
