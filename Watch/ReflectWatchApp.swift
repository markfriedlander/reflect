// ========== BLOCK: ReflectWatchApp.swift - START ==========
//
//  ReflectWatchApp.swift
//  Reflect: Creative Sparks — Watch companion entry point
//
//  Owns the PromptEngine for the Watch app target and injects it into
//  the environment. The Watch app ships as a companion inside the iOS
//  bundle (Universal Purchase) — no separate App Store listing.
//

#if os(watchOS)
import SwiftUI

@main
struct ReflectWatchApp: App {

    @State private var engine = PromptEngine()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(engine)
        }
    }
}
#endif
// ========== BLOCK: ReflectWatchApp.swift - END ==========
