//
//  CardView.swift
//  QuranNoor
//
//  Unified card component with iOS 26 Liquid Glass materials
//  Merged from CardView + LiquidGlassCardView into a single clean component
//

import SwiftUI

/// Unified glass card component with translucent background and subtle border
struct CardView<Content: View>: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let content: Content
    let showPattern: Bool
    let intensity: GlassIntensity

    enum GlassIntensity {
        case subtle
        case moderate
        case prominent

        var materialStyle: Material {
            switch self {
            case .subtle:
                return .ultraThinMaterial
            case .moderate:
                return .thinMaterial
            case .prominent:
                return .regularMaterial
            }
        }

        var tintOpacity: Double {
            switch self {
            case .subtle:
                return 0.05
            case .moderate:
                return 0.08
            case .prominent:
                return 0.12
            }
        }
    }

    // MARK: - Initializer
    init(
        showPattern: Bool = false,
        intensity: GlassIntensity = .moderate,
        @ViewBuilder content: () -> Content
    ) {
        self.showPattern = showPattern
        self.intensity = intensity
        self.content = content()
    }

    // MARK: - Body
    var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(intensity.materialStyle)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(glassBackgroundTint(for: theme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    glassEdgeHighlight(for: theme).opacity(0.6),
                                    glassEdgeHighlight(for: theme).opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .compositingGroup()
                .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, x: 0, y: 8)

            // Optional Islamic pattern watermark
            if showPattern {
                IslamicPatternView(patternColor: theme.accentMuted)
                    .opacity(0.04)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .drawingGroup()
            }

            // Content
            content
                .padding(Spacing.cardPadding)
        }
    }

    // MARK: - Computed Colors

    private func glassBackgroundTint(for theme: ThemeMode) -> Color {
        switch theme {
        case .light:
            return Color(hex: "#E8DCC8").opacity(intensity.tintOpacity * 0.5)
        case .dark:
            return theme.accent.opacity(intensity.tintOpacity * 0.7)
        case .night:
            return theme.accent.opacity(intensity.tintOpacity * 0.5)
        case .sepia:
            return theme.accentMuted.opacity(intensity.tintOpacity)
        }
    }

    private func glassEdgeHighlight(for theme: ThemeMode) -> Color {
        switch theme {
        case .light, .sepia:
            return Color.white
        case .dark:
            return Color.white.opacity(0.3)
        case .night:
            return Color.white.opacity(0.2)
        }
    }
}

// MARK: - Islamic Pattern View
private struct IslamicPatternView: View {
    let patternColor: Color

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
            let r = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        context.stroke(
            path,
            with: .color(patternColor),
            lineWidth: 1
        )
    }
}

// MARK: - Backward Compatibility
/// Typealias for legacy code referencing LiquidGlassCardView
typealias LiquidGlassCardView = CardView

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prayer Times")
                    .font(.headline)
                Text("Next prayer in 15 minutes")
                    .font(.subheadline)
            }
        }

        CardView(showPattern: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fajr")
                    .font(.headline)
                Text("5:30 AM")
                    .font(.title)
            }
        }

        CardView(showPattern: true, intensity: .prominent) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT PRAYER")
                        .font(.caption)
                    Text("Asr")
                        .font(.title)
                    Text("3:45 PM")
                        .font(.body)
                }
                Spacer()
                Image(systemName: "clock.fill")
                    .font(.system(size: 40))
            }
        }
    }
    .padding()
    .background(Color(hex: "#F8F4EA"))
    .environment(ThemeManager())
}
