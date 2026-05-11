// ========== BLOCK: ReflectWidgetView.swift - START ==========
//
//  ReflectWidgetView.swift
//  ReflectWidget
//
//  Same visual discipline as the rest of Reflect — black field, white
//  text, system font, centered, generous padding, nothing else.
//
//  Tap target wraps the whole view via a Button bound to RefreshIntent,
//  so any tap inside the widget rect triggers a refresh in place.
//
//  Font size scales with family because the available real estate
//  differs by ~3× between small and large. minimumScaleFactor keeps
//  longer prompts readable on the small family.
//

import WidgetKit
import SwiftUI

struct ReflectWidgetView: View {
    let entry: ReflectEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Button(intent: RefreshIntent()) {
            ZStack {
                Color.black
                Text(entry.text)
                    .font(promptFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.plain)
        .containerBackground(.black, for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.text)
        .accessibilityHint("Double-tap for a different prompt.")
        .accessibilityAddTraits(.isButton)
    }

    private var promptFont: Font {
        switch family {
        case .systemSmall:  return .system(.subheadline).weight(.regular)
        case .systemMedium: return .system(.title3).weight(.regular)
        case .systemLarge:  return .system(.title2).weight(.regular)
        default:            return .system(.body).weight(.regular)
        }
    }

    private var horizontalPadding: CGFloat {
        switch family {
        case .systemSmall:  return 12
        case .systemMedium: return 20
        case .systemLarge:  return 32
        default:            return 16
        }
    }

    private var verticalPadding: CGFloat {
        switch family {
        case .systemSmall:  return 8
        case .systemMedium: return 16
        case .systemLarge:  return 24
        default:            return 12
        }
    }
}
// ========== BLOCK: ReflectWidgetView.swift - END ==========
