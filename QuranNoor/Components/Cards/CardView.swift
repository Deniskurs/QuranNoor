//
//  CardView.swift
//  QuranNoor
//
//  Backwards compatibility wrapper for LiquidGlassCardView
//  All cards now use iOS 26 Liquid Glass materials
//

import SwiftUI

/// Legacy CardView - now uses Liquid Glass materials (iOS 26)
/// This is a compatibility wrapper that redirects to LiquidGlassCardView
struct CardView<Content: View>: View {
    let content: Content
    let showPattern: Bool

    init(
        showPattern: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.showPattern = showPattern
        self.content = content()
    }

    var body: some View {
        // Use Liquid Glass with moderate intensity as default
        LiquidGlassCardView(showPattern: showPattern, intensity: .moderate) {
            content
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Basic card
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prayer Times")
                    .font(.headline)
                Text("Next prayer in 15 minutes")
                    .font(.subheadline)
            }
        }

        // Card with Islamic pattern
        CardView(showPattern: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fajr")
                    .font(.headline)
                Text("5:30 AM")
                    .font(.title)
            }
        }
    }
    .padding()
    .background(Color(hex: "#F8F4EA"))
    .environmentObject(ThemeManager())
}
