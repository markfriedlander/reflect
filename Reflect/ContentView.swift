//
//  ContentView.swift
//  Reflect: Creative Sparks
//
//  Created by Mark Friedlander in collaboration with ChatGPT on 2025-04-27.
//
//  © 2025 Mark Friedlander and OpenAI. All rights reserved.
//
//  This file is part of Reflect: Creative Sparks, a creative prompt app designed
//  to inspire fresh thinking and new perspectives.
//
import Foundation
import SwiftUI


struct ContentView: View {
    // Tracks whether auto mode is enabled using persistent storage
    @AppStorage("isAutoModeEnabled") private var isAutoModeEnabled = false
    // Holds the currently displayed prompt text
    @State private var currentPrompt = "Reflect"
    // Controls animation scaling for prompt transitions (currently unused)
    @State private var scale: CGFloat = 1.0
    // Controls display of the full title ("Reflect: Creative Sparks")
    @State private var showFullTitle = true
    // Controls visibility of the toast message
    @State private var showToast = false
    // Holds the message shown in the toast
    @State private var toastMessage = ""

    var body: some View {
        // Background and main layout container
        ZStack {
            Color.black.ignoresSafeArea()

            // Prompt display and animated title
            VStack {
                Spacer()
                if showFullTitle {
                    Text("Reflect:\nCreative Sparks")
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    showFullTitle = false
                                }
                            }
                        }
                } else {
                    Text(currentPrompt)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .transition(.opacity)
                        .id(currentPrompt) // force transition on change
                }
                Spacer()
            }
            .contentShape(Rectangle())
            // Tap gesture: disables auto mode if active and updates prompt
            .onTapGesture {
                if isAutoModeEnabled {
                    isAutoModeEnabled = false
                    showToastMessage("Auto mode off")
                }
                updatePrompt()
            }
            // Long press gesture: toggles auto mode and shows toast
            .onLongPressGesture {
                isAutoModeEnabled.toggle()
                showToastMessage(isAutoModeEnabled ? "Auto mode on" : "Auto mode off")
            }

            // Toast message view shown at bottom of screen (always in hierarchy, animates opacity)
            VStack {
                Spacer()
                Text(toastMessage)
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(showToast ? 0.8 : 0.0)
                    .padding(.bottom, 20)
            }
            .animation(.easeInOut(duration: 1.0), value: showToast)
        }
        // Start auto mode (looped prompt updates) if enabled
        .onAppear {
            startAutoModeIfNeeded()
        }
        // Restart auto mode loop if toggled on again
        .onChange(of: isAutoModeEnabled) {
            if isAutoModeEnabled {
                startAutoModeIfNeeded()
            }
        }
    }

    // Selects a new random prompt from the list
    private func updatePrompt() {
        let index = Int.random(in: 0..<allPrompts.count)
        currentPrompt = allPrompts[index]
    }

    // Recursively schedules prompt updates every 6 seconds while auto mode is active
    private func startAutoModeIfNeeded() {
        guard isAutoModeEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if isAutoModeEnabled {
                updatePrompt()
                startAutoModeIfNeeded()
            }
        }
    }

    // Displays a fading toast message with optional animation
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 1.0)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                showToast = false
            }
        }
    }
}
