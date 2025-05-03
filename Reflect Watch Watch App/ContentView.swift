//
//  ContentView.swift
//  Reflect Watch Watch App
//
//  Created by Mark Friedlander and ChatGPT on 5/1/25.
//
//  Reflect: Creative Sparks
//  Copyright © 2025 Mark Friedlander & OpenAI. All rights reserved.
//  This app is a collaborative effort between a human and an AI, developed to inspire creativity and reflection through randomly generated prompts.
//

import SwiftUI

struct ContentView: View {
    /// An array of creative prompts used to inspire reflection. A new one is shown on tap.
    let prompts = [
        "What is the question behind this",
        "Consider the lifespan of this idea",
        "Make it breathe",
        "What if gravity didn't apply here",
        "Find the hidden connections",
        "Embrace the pause",
        "Let go of the need for approval",
        "What would a child intuitively do",
        "Introduce a color that doesn't exist",
        "Make it move in an unexpected way",
        "Consider its impact on the environment",
        "What if time moved in reverse for this",
        "Find the poetry in the mundane",
        "Allow for complete silence in its expression",
        "What is its unspoken desire",
        "Make it echo something else entirely",
        "Consider the texture of the idea",
        "What if it had a smell",
        "Find the humor in the situation",
        "Make it fragile",
        "What is its shadow self",
        "Introduce an element of chance",
        "Consider its cultural context a different one",
        "What if it could speak? What would it say?",
        "Make it smaller than you think possible",
        "Find the lesson within the frustration",
        "What if it defied its purpose",
        "Introduce a rhythm that feels unnatural",
        "Consider its weight—literal or metaphorical",
        "What if it was a dream",
        "Find the beauty in its decay",
        "Make it magnetic",
        "What is its secret ingredient",
        "Introduce a feeling of nostalgia",
        "Consider its taste",
        "What if it was a message from the future",
        "Find the strength in its vulnerability",
        "Make it transparent",
        "What if it was a gift? Who is it for?",
        "Introduce a sense of urgency",
        "Consider its temperature",
        "What if it was a warning",
        "Find the extraordinary in the ordinary",
        "Make it disappear and then reappear",
        "What is its natural habitat",
        "Introduce a feeling of longing",
        "Consider its sound",
        "What if it was a memory",
        "Find the balance in its imbalance",
        "Make it grow",
        "What is its mythology",
        "Introduce a feeling of playfulness",
        "Consider its density",
        "What if it was a question with no answer",
        "Find the freedom in its constraints",
        "Make it float",
        "What is its hidden potential",
        "Introduce a feeling of surprise",
        "Consider its age",
        "What if it was a secret language",
        "Find the connection to something ancient",
        "Make it a hybrid of two unlike things",
        "What is its breaking point",
        "Introduce a feeling of wonder",
        "Consider its flexibility",
        "What if it was a reflection",
        "Find the story it wants to tell",
        "Make it a puzzle",
        "What is its source of energy",
        "Introduce a feeling of unease",
        "Consider its texture on a microscopic level",
        "What if it was a rumor",
        "Find the unexpected in the expected",
        "Make it a container for something else",
        "What is its purpose beyond the obvious",
        "Introduce a feeling of joy",
        "Consider its aroma",
        "What if it was a forgotten technology",
        "Find the resilience within its fragility",
        "Make it a gateway to another place",
        "What is its emotional core",
        "Introduce a feeling of mystery",
        "Consider its adaptability",
        "What if it was a piece of advice",
        "Find the harmony in its dissonance",
        "Make it a tool for connection",
        "What is its inherent rhythm",
        "Introduce a feeling of detachment",
        "Consider its scale relative to something vast",
        "What if it was a symbol of something lost",
        "Find the innovation in its tradition",
        "Make it a source of light",
        "What is its fundamental truth",
        "Introduce a feeling of anticipation",
        "Consider its internal structure",
        "What if it was a distortion of reality",
        "Find the potential for transformation within it",
        "Make it a reminder of something important",
        "What is its legacy",
        "Trust the emergent possibilities"
    ]

    /// The currently displayed prompt, initially set to "Reflect"
    @State private var currentPrompt = "Reflect"

    /// Controls the scaling animation of the prompt text
    @State private var scale: CGFloat = 1.0

    /// Controls whether the full title is shown on launch
    @State private var showFullTitle = true

    /// The main view for the watchOS app. Displays a title briefly, then a random prompt which updates on tap with haptic feedback.
    var body: some View {
        VStack {
            Spacer()
            if showFullTitle {
                Text("Reflect: Creative Sparks")
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .minimumScaleFactor(0.5)
                    .padding()
                    .transition(.opacity)
            } else {
                Text(currentPrompt)
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .minimumScaleFactor(0.5)
                    .padding()
                    .scaleEffect(scale)
                    .onChange(of: currentPrompt) { _ in
                        // Triggers a brief scale animation when the prompt changes
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = 0.95
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scale = 1.0
                            }
                        }
                    }
            }
            Spacer()
        }
        .onAppear {
            // Automatically fades out the title after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    showFullTitle = false
                }
            }
        }
        .contentShape(Rectangle()) // Makes the entire area tappable
        .onTapGesture {
            // When tapped, play a light haptic and update the prompt with a short scaling animation
            WKInterfaceDevice.current().play(.click)
            withAnimation(.easeInOut(duration: 0.3)) {
                let index = Int.random(in: 0..<prompts.count)
                currentPrompt = prompts[index]
            }
        }
    }
}

/// Provides a preview of the ContentView in Xcode canvas
#Preview {
    ContentView()
}
