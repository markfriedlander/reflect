// ========== BLOCK: TVContentView.swift - START ==========
//
//  TVContentView.swift
//  Reflect: Creative Sparks — Apple TV (ambient)
//
//  Slow TV, but text. The prompt fades in, breathes for an unhurried
//  stretch of time, then fades to black. A second of stillness. Then the
//  next card. Remote-click advances early.
//
//  Variable dwell time is intentional: an unmoving cadence becomes
//  wallpaper. By varying when the next card appears — sometimes a quick
//  flip, sometimes a long contemplative hold — the eye keeps noticing.
//
//  Distribution (median ~3 minutes, but shaped):
//    19/24 chance: 2–5 minutes (the base rhythm)
//     3/24 chance: 6–9 minutes (long hold — let it sit)
//     2/24 chance: 60–90 seconds (quick flip — keeps you on your toes)
//
//  Idle timer disabled on appear so the screensaver doesn't kick in
//  while the app is foregrounded.
//
//  Accessibility:
//   - One focusable element, label = current prompt, trait .updatesFrequently
//     so VoiceOver announces changes as ambient cycles.
//   - Remote-select action advances early.
//   - Fade animations are suppressed under Reduce Motion.
//

#if os(tvOS)
import SwiftUI

struct TVContentView: View {

    @Environment(PromptEngine.self) private var engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentText: String = ""
    @State private var isVisible: Bool = false
    @State private var showLaunchTitle: Bool = true
    @State private var rotationTask: Task<Void, Never>? = nil

    private let fadeDuration: Double = 1.0
    private let blackHold: Double = 1.0
    private let launchTitleHold: Double = 2.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if showLaunchTitle {
                    Text("Reflect: Creative Sparks")
                        .font(.system(.largeTitle, design: .default).weight(.regular))
                } else {
                    Text(currentText)
                        .font(.system(.largeTitle, design: .default).weight(.regular))
                        .id(currentText)
                }
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 120)
            .frame(maxWidth: 1400)
            .opacity(isVisible ? 1 : 0)
            .animation(reduceMotion ? nil : .easeInOut(duration: fadeDuration),
                       value: isVisible)
        }
        .focusable()
        .focusEffectDisabled()
        .onTapGesture { advanceImmediately() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showLaunchTitle ? "Reflect: Creative Sparks"
                                            : (currentText.isEmpty ? "Reflect" : currentText))
        .accessibilityHint("Press the remote to show the next card.")
        .accessibilityAddTraits([.isButton, .updatesFrequently])
        .accessibilityAction { advanceImmediately() }
        .onAppear { startSequence() }
        .onDisappear {
            rotationTask?.cancel()
            rotationTask = nil
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Sequence

    private func startSequence() {
        UIApplication.shared.isIdleTimerDisabled = true
        rotationTask?.cancel()
        rotationTask = Task { @MainActor in
            // Launch title — fade in, hold, fade out.
            isVisible = true
            try? await Task.sleep(for: .seconds(launchTitleHold))
            if Task.isCancelled { return }
            isVisible = false
            try? await Task.sleep(for: .seconds(fadeDuration + blackHold))
            if Task.isCancelled { return }
            showLaunchTitle = false

            // Continuous rotation.
            await rotateForever()
        }
    }

    private func rotateForever() async {
        while !Task.isCancelled {
            currentText = engine.next()
            isVisible = true
            try? await Task.sleep(for: .seconds(nextDwellSeconds()))
            if Task.isCancelled { return }
            isVisible = false
            try? await Task.sleep(for: .seconds(fadeDuration + blackHold))
        }
    }

    private func advanceImmediately() {
        rotationTask?.cancel()
        rotationTask = Task { @MainActor in
            // If we're showing the launch title, just skip to prompts.
            if showLaunchTitle {
                isVisible = false
                try? await Task.sleep(for: .seconds(fadeDuration))
                if Task.isCancelled { return }
                showLaunchTitle = false
            } else if isVisible {
                isVisible = false
                try? await Task.sleep(for: .seconds(fadeDuration + blackHold))
                if Task.isCancelled { return }
            }
            await rotateForever()
        }
    }

    // MARK: - Dwell distribution

    /// Variable dwell shaped by a 24-sided roll. See header for distribution.
    private func nextDwellSeconds() -> Double {
        switch Int.random(in: 0..<24) {
        case 0..<2:  return Double.random(in: 60...90)        // quick flip
        case 2..<5:  return Double.random(in: 360...540)      // long hold
        default:     return Double.random(in: 120...300)      // base 2-5 min
        }
    }
}
#endif
// ========== BLOCK: TVContentView.swift - END ==========
