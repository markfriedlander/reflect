// ========== BLOCK: Reflect_TVApp.swift - START ==========
//
//  Reflect_TVApp.swift
//  Reflect: Creative Sparks — Apple TV (ambient)
//
//  App entry point for the tvOS target. Owns the PromptEngine and
//  injects it into the environment. Forces dark color scheme since
//  the app is always-black-background by design.
//

#if os(tvOS)
import SwiftUI

@main
struct Reflect_TVApp: App {

    @State private var engine = PromptEngine()

    var body: some Scene {
        WindowGroup {
            TVContentView()
                .environment(engine)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
// ========== BLOCK: Reflect_TVApp.swift - END ==========
