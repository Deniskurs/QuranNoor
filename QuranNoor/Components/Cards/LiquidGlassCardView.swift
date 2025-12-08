//
//  LiquidGlassCardView.swift
//  QuranNoor
//
//  Created by Claude Code
//  iOS 26 Liquid Glass card component with translucent materials
//

import SwiftUI

/// iOS 26 Liquid Glass card with translucent background and subtle border
struct LiquidGlassCardView<Content: View>: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let content: Content
    let showPattern: Bool
    let material: Material
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
        material: Material? = nil,
        intensity: GlassIntensity = .moderate,
        @ViewBuilder content: () -> Content
    ) {
        self.showPattern = showPattern
        self.material = material ?? intensity.materialStyle
        self.intensity = intensity
        self.content = content()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Liquid Glass background
            RoundedRectangle(cornerRadius: 20, style: .continuous) // iOS 26: larger radius for liquid feel
                .fill(material)
                .background(
                    // Subtle color tint behind the material
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(glassBackgroundTint)
                )
                .overlay(
                    // Glass edge highlight (refraction effect)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    glassEdgeHighlight.opacity(0.6),
                                    glassEdgeHighlight.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .compositingGroup() // Performance: Flatten layers before applying shadow
                .shadow(color: glassShadowColor, radius: 16, x: 0, y: 8) // Softer, unified shadow

            // Optional Islamic pattern watermark
            if showPattern {
                IslamicPatternView()
                    .opacity(0.04) // More subtle on glass
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .drawingGroup() // Performance: Render pattern to bitmap
            }

            // Content
            content
                .padding(Spacing.cardPadding) // 24pt padding
        }
    }

    // MARK: - Computed Colors

    /// Background tint color for glass effect
    private var glassBackgroundTint: Color {
        switch themeManager.currentTheme {
        case .light:
            return Color(hex: "#E8DCC8").opacity(intensity.tintOpacity * 0.5)  // Warm gold tint
        case .dark:
            return themeManager.currentTheme.featureAccent.opacity(intensity.tintOpacity * 0.7)
        case .night:
            return themeManager.currentTheme.featureAccent.opacity(intensity.tintOpacity * 0.5)
        case .sepia:
            return AppColors.primary.gold.opacity(intensity.tintOpacity)
        }
    }

    /// Glass edge highlight (light refraction effect)
    private var glassEdgeHighlight: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.white
        case .dark:
            return Color.white.opacity(0.3)
        case .night:
            return Color.white.opacity(0.2)
        }
    }

    /// Unified shadow for glass depth
    private var glassShadowColor: Color {
        switch themeManager.currentTheme {
        case .light:
            return Color.black.opacity(0.08)
        case .sepia:
            return Color.black.opacity(0.1)
        case .dark:
            return Color.black.opacity(0.3)
        case .night:
            return Color.black.opacity(0.5)
        }
    }
}

// MARK: - Islamic Pattern View (Reused)
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

#Preview("Liquid Glass - Light") {
    VStack(spacing: 24) {
        // Subtle glass
        LiquidGlassCardView(intensity: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prayer Times")
                    .font(.headline)
                Text("Next prayer in 15 minutes")
                    .font(.subheadline)
            }
        }

        // Moderate glass
        LiquidGlassCardView(intensity: .moderate) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fajr")
                    .font(.headline)
                Text("5:30 AM")
                    .font(.title)
            }
        }

        // Prominent glass with pattern
        LiquidGlassCardView(showPattern: true, intensity: .prominent) {
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
                    .foregroundColor(AppColors.primary.green)
            }
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color(hex: "#F8F4EA"), Color(hex: "#E5E0D5")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(ThemeManager())
}

#Preview("Liquid Glass - Dark") {
    VStack(spacing: 24) {
        LiquidGlassCardView(intensity: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prayer Times")
                    .font(.headline)
                Text("Next prayer in 15 minutes")
                    .font(.subheadline)
            }
        }

        LiquidGlassCardView(showPattern: true, intensity: .moderate) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fajr")
                    .font(.headline)
                Text("5:30 AM")
                    .font(.title)
            }
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color(hex: "#1A2332"), Color(hex: "#0D1419")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
}

#Preview("Liquid Glass - Night") {
    VStack(spacing: 24) {
        LiquidGlassCardView(intensity: .moderate) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prayer Times")
                    .font(.headline)
                Text("Next prayer in 15 minutes")
                    .font(.subheadline)
            }
        }

        LiquidGlassCardView(showPattern: true, intensity: .prominent) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT PRAYER")
                        .font(.caption)
                    Text("Asr")
                        .font(.title)
                }
                Spacer()
                Image(systemName: "clock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary.green)
            }
        }
    }
    .padding()
    .background(Color.black)
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.night)
        return manager
    }())
}
