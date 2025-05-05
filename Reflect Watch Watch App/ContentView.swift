//
//  ContentView.swift
//  Reflect Watch Watch App
//
//  Created by Mark on May 4, 2025.
//
//  Displays random creative prompts with smooth scaling animation and haptic feedback.
//  Uses shared Prompts.swift file as the source for prompts.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    // Current prompt displayed on the watch face
    @State private var currentPrompt: String = allPrompts.randomElement() ?? "Tap to start"
    // Scale factor for the tap animation effect
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            Text(currentPrompt)
                .font(.headline)
                .padding()
                .scaleEffect(scale) // Apply scaling animation on tap
                .onTapGesture {
                    // Animate scaling up to provide visual tap feedback
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scale = 1.2
                    }
                    // Return scale to normal after animation delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = 1.0
                        }
                    }
                    // Play haptic tap feedback on the watch
                    WKInterfaceDevice.current().play(.click)
                    // Update prompt with a new random prompt from shared source
                    currentPrompt = allPrompts.randomElement() ?? "Tap to start"
                }
                .contentShape(Rectangle()) // Makes entire text tappable
        }
        .onAppear {
            // Initialize with a random prompt when view appears
            currentPrompt = allPrompts.randomElement() ?? "Tap to start"
        }
    }
}

// Preview for SwiftUI canvas and Xcode previews
#Preview {
    ContentView()
}
