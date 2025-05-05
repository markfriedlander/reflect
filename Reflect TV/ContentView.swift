//
//  ContentView.swift
//  Reflect TV
//
//  Created by Mark Friedlander & ChatGPT on 2025-05-02.
//

import SwiftUI

struct ContentView: View {
    /// Tracks whether the app is currently displaying the launch screen.
    /// Set to true on startup and toggled off once the first prompt is displayed.
    @State private var isLaunching: Bool = true
    /// Controls the fade animation for both the launch screen and each new prompt.
    /// Used to smoothly transition between prompts with opacity animation.
    @State private var fadeIn: Bool = false
    /// Stores the prompt currently being displayed on screen.
    /// Populated from the shared allPrompts array at launch and with each refresh.
    @State private var currentPrompt: String = ""
    
    /// Determines how long each prompt stays on screen before transitioning.
    /// Default is 60 seconds between prompt changes.
    var promptDuration: Double {
        return 60.0
    }
    
    /// Schedules the next prompt to appear after the current one fades out.
    /// Adds delay and fade-in/out animation between transitions.
    /// Recursively calls itself to cycle through prompts indefinitely.
    func scheduleNextPrompt() {
        // Start fade-out animation before replacing the prompt.
        DispatchQueue.main.asyncAfter(deadline: .now() + promptDuration) {
            withAnimation {
                fadeIn = false
            }
            // After fade-out delay, pick a new prompt and fade it in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                currentPrompt = allPrompts.randomElement() ?? ""
                withAnimation {
                    fadeIn = true
                }
                scheduleNextPrompt()
            }
        }
    }
    
    /// Main view for the Apple TV version of Reflect: Creative Sparks.
    /// Displays a black background and either the launch title or a rotating prompt.
    /// Animates fade transitions and schedules prompt cycling using timers.
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if isLaunching {
                Text("Reflect: Creative Sparks")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .opacity(fadeIn ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0), value: fadeIn)
            } else {
                Text(currentPrompt)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                    .opacity(fadeIn ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0), value: fadeIn)
            }
        }
        .onAppear {
            // Show the launch title briefly, then transition to the first prompt.
            // Kick off the prompt cycling sequence with fade animations.
            fadeIn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    fadeIn = false
                }
                // Wait while faded to black before switching to prompts
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isLaunching = false
                    currentPrompt = allPrompts.randomElement() ?? ""
                    withAnimation {
                        fadeIn = true
                    }
                    scheduleNextPrompt()
                }
            }
        }
    }
}
