// ========== BLOCK: ContentView.swift (iOS/iPadOS/Mac) - START ==========
//
//  ContentView.swift
//  Reflect: Creative Sparks
//
//  Interactive mode is the default — tap to advance, like pulling the next
//  card from a deck. A long press toggles auto / desk mode, which advances
//  on a 30-second cadence until tapped or toggled off.
//
//  No launch title on hand-held devices — splash screens age poorly and
//  the prompt is the entire product. Open straight to the first card.
//
//  Auto-advance uses a structured Task that's cancelled on view disappear
//  or mode toggle. No recursive asyncAfter.
//

import SwiftUI

struct ContentView: View {

    @Environment(PromptEngine.self) private var engine

    @AppStorage("isAutoModeEnabled") private var isAutoModeEnabled = false

    @State private var currentText: String = ""
    @State private var autoTask: Task<Void, Never>? = nil
    @State private var toastMessage: String = ""
    @State private var showToast = false

    private let fadeDuration: Double = 0.6
    private let autoIntervalSeconds: Double = 30

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text(currentText)
                .font(.system(.title2, design: .default).weight(.regular))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.vertical, 48)
                .frame(maxWidth: 640)
                .id(currentText)
                .transition(.opacity)

            VStack {
                Spacer()
                Text(toastMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 24)
                    .opacity(showToast ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6), value: showToast)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .onLongPressGesture(minimumDuration: 0.6) { toggleAutoMode() }
        .onAppear {
            advance()
            if isAutoModeEnabled { startAutoLoop() }
        }
        .onDisappear { stopAutoLoop() }
        .onChange(of: isAutoModeEnabled) { _, enabled in
            if enabled { startAutoLoop() } else { stopAutoLoop() }
        }
    }

    // MARK: - Interaction

    private func handleTap() {
        if isAutoModeEnabled {
            isAutoModeEnabled = false
            flashToast("Auto mode off")
        }
        advance()
    }

    private func toggleAutoMode() {
        isAutoModeEnabled.toggle()
        flashToast(isAutoModeEnabled ? "Auto mode on" : "Auto mode off")
    }

    // MARK: - Prompt rotation

    private func advance() {
        let next = engine.next()
        withAnimation(.easeInOut(duration: fadeDuration)) {
            currentText = next
        }
    }

    private func startAutoLoop() {
        autoTask?.cancel()
        autoTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(autoIntervalSeconds))
                if Task.isCancelled { break }
                advance()
            }
        }
    }

    private func stopAutoLoop() {
        autoTask?.cancel()
        autoTask = nil
    }

    // MARK: - Toast

    private func flashToast(_ message: String) {
        toastMessage = message
        showToast = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            showToast = false
        }
    }
}
// ========== BLOCK: ContentView.swift (iOS/iPadOS/Mac) - END ==========
