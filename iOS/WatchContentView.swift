// ========== BLOCK: WatchContentView.swift - START ==========
//
//  WatchContentView.swift
//  Reflect: Creative Sparks — Watch companion
//
//  Tap to advance, with a tactile click haptic. The Watch is the deck you
//  always have with you: one prompt, no chrome, no auto mode. A small
//  scale-bounce on tap confirms the gesture was received.
//
//  Uses the shared PromptEngine — same cluster avoidance and history as
//  every other surface. AFM is not available on watchOS; the engine
//  handles that silently.
//
//  This file is a member of the Watch app target (companion inside the
//  iOS bundle). It lives in iOS/ alongside the iPhone view because the
//  shared module structure flattens platform views into one folder.
//

#if os(watchOS)
import SwiftUI
import WatchKit

struct WatchContentView: View {

    @Environment(PromptEngine.self) private var engine

    @State private var currentText: String = ""
    @State private var scale: CGFloat = 1.0

    private let fadeDuration: Double = 0.4

    var body: some View {
        Text(currentText)
            .font(.headline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding()
            .scaleEffect(scale)
            .id(currentText)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .contentShape(Rectangle())
            .onTapGesture { handleTap() }
            .onAppear { advance() }
    }

    private func handleTap() {
        WKInterfaceDevice.current().play(.click)
        withAnimation(.easeInOut(duration: 0.15)) { scale = 1.08 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeInOut(duration: 0.15)) { scale = 1.0 }
        }
        advance()
    }

    private func advance() {
        let next = engine.next()
        withAnimation(.easeInOut(duration: fadeDuration)) {
            currentText = next
        }
    }
}
#endif
// ========== BLOCK: WatchContentView.swift - END ==========
