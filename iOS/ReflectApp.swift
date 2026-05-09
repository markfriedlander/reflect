// ========== BLOCK: ReflectApp.swift (iOS/iPadOS/Mac) - START ==========
//
//  ReflectApp.swift
//  Reflect: Creative Sparks
//
//  App entry point for the unified iOS / iPadOS / Mac (iPhone-binary)
//  target. Owns the single PromptEngine instance and injects it into
//  the environment so ContentView (and any future view) can pull cards
//  from the same source of truth.
//

import SwiftUI

@main
struct ReflectApp: App {

    @State private var engine = PromptEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
                .preferredColorScheme(.dark)
        }
    }
}
// ========== BLOCK: ReflectApp.swift (iOS/iPadOS/Mac) - END ==========
