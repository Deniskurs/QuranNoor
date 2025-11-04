//
//  CardView.swift
//  QuranNoor
//
//  Neumorphic card component with dual shadows for 3D embossed effect
//

import SwiftUI

// MARK: - CardView Component
struct CardView<Content: View>: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let content: Content
    let showPattern: Bool

    // MARK: - Initializer
    init(
        showPattern: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.showPattern = showPattern
        self.content = content()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background with enhanced neumorphic shadows
            // Using drawingGroup() to rasterize and cache shadow rendering for better performance
            RoundedRectangle(cornerRadius: BorderRadius.xl, style: .continuous) // 16pt for sleeker look
                .fill(cardBackgroundColor)
                .shadow(
                    color: lightShadowColor,
                    radius: 12,    // Enhanced from 10
                    x: -6,         // Enhanced from -5
                    y: -6
                )
                .shadow(
                    color: darkShadowColor,
                    radius: 12,    // Enhanced from 10
                    x: 6,          // Enhanced from 5
                    y: 6
                )
                // Add subtle border for definition
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.xl, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 0.5)
                )
                // Note: .drawingGroup() removed - it caused square shadow artifacts on rounded corners

            // Optional Islamic pattern watermark
            if showPattern {
                IslamicPatternView()
                    .opacity(0.05)
                    .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl, style: .continuous))
            }

            // Content with enhanced padding
            content
                .padding(Spacing.cardPadding) // 24pt for better breathing room
        }
    }

    // MARK: - Theme-Aware Colors
    private var cardBackgroundColor: Color {
        themeManager.currentTheme.cardColor
    }

    private var lightShadowColor: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.white.opacity(0.7)
        case .dark:
            return Color.white.opacity(0.05)
        case .night:
            return Color.white.opacity(0.02)
        }
    }

    private var darkShadowColor: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.black.opacity(0.12) // Softer shadow (was 0.2)
        case .dark:
            return Color.black.opacity(0.5)  // Deeper shadow (was 0.4)
        case .night:
            return Color.black.opacity(0.7)  // More depth (was 0.6)
        }
    }

    private var borderColor: Color {
        switch themeManager.currentTheme {
        case .light:
            return Color.black.opacity(0.04)
        case .dark:
            return Color.white.opacity(0.06)
        case .night:
            return Color.white.opacity(0.03)
        case .sepia:
            return Color.black.opacity(0.05)
        }
    }
}

// MARK: - Islamic Pattern View
private struct IslamicPatternView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let spacing: CGFloat = 40
                let columns = Int(size.width / spacing) + 1
                let rows = Int(size.height / spacing) + 1

                for row in 0..<rows {
                    for col in 0..<columns {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        let center = CGPoint(x: x, y: y)

                        // Draw 8-point star pattern
                        drawEightPointStar(context: context, center: center, radius: 8)
                    }
                }
            }
        }
    }

    private func drawEightPointStar(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var path = Path()
        let points = 8
        let outerRadius = radius
        let innerRadius = radius * 0.4

        for i in 0..<points * 2 {
            let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        context.stroke(
            path,
            with: .color(AppColors.primary.gold),
            lineWidth: 1
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Basic card
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                ThemedText.heading("Prayer Times")
                ThemedText.body("Next prayer in 15 minutes")
            }
        }

        // Card with Islamic pattern
        CardView(showPattern: true) {
            VStack(alignment: .leading, spacing: 8) {
                ThemedText.heading("Fajr")
                ThemedText.title("5:30 AM", italic: false)
            }
        }

        // Complex content card
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    ThemedText.caption("NEXT PRAYER")
                    ThemedText.heading("Asr")
                    ThemedText.body("3:45 PM")
                }
                Spacer()
                Image(systemName: "clock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary.green)
            }
        }
    }
    .padding()
    .background(ThemeManager().currentTheme.backgroundColor)
    .environmentObject(ThemeManager())
}
