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
//  Accessibility:
//   - One focusable element labeled with the current prompt.
//   - Default action = advance to next card.
//   - Scale-bounce and fade suppressed under Reduce Motion.
//

#if os(watchOS)
import SwiftUI
import WatchKit

struct WatchContentView: View {

    @Environment(PromptEngine.self) private var engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(currentText.isEmpty ? "Reflect" : currentText)
            .accessibilityHint("Double-tap for the next card.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { handleTap() }
            .onAppear { advance() }
    }

    private func handleTap() {
        WKInterfaceDevice.current().play(.click)
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.15)) { scale = 1.08 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeInOut(duration: 0.15)) { scale = 1.0 }
            }
        }
        advance()
    }

    private func advance() {
        let next = engine.next()
        if reduceMotion {
            currentText = next
        } else {
            withAnimation(.easeInOut(duration: fadeDuration)) {
                currentText = next
            }
        }
    }
}
#endif
// ========== BLOCK: WatchContentView.swift - END ==========
