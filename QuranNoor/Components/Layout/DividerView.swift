//
//  DividerView.swift
//  QuranNoor
//
//  Islamic geometric pattern dividers for visual separation
//

import SwiftUI

// MARK: - Divider Style
enum IslamicDividerStyle {
    case simple       // Single line
    case ornamental   // Line with center ornament
    case geometric    // Repeating geometric pattern
    case crescent     // Crescent moon accent
}

// MARK: - Divider View Component
struct IslamicDivider: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let style: IslamicDividerStyle
    let color: Color?

    // MARK: - Initializer
    init(
        style: IslamicDividerStyle = .simple,
        color: Color? = nil
    ) {
        self.style = style
        self.color = color
    }

    // MARK: - Body
    var body: some View {
        Group {
            switch style {
            case .simple:
                SimpleDivider(color: dividerColor)

            case .ornamental:
                OrnamentalDivider(color: dividerColor)

            case .geometric:
                GeometricDivider(color: dividerColor)

            case .crescent:
                CrescentDivider(color: dividerColor)
            }
        }
    }

    // MARK: - Theme-Aware Color
    private var dividerColor: Color {
        color ?? themeManager.currentTheme.textColor.opacity(0.2)
    }
}

// MARK: - Simple Divider
private struct SimpleDivider: View {
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
    }
}

// MARK: - Ornamental Divider
private struct OrnamentalDivider: View {
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // Left line
            Rectangle()
                .fill(color)
                .frame(height: 1)

            // Center ornament (8-point star)
            StarOrnament(color: color)
                .frame(width: 20, height: 20)

            // Right line
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
    }
}

// MARK: - Geometric Divider
private struct GeometricDivider: View {
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { index in
                DiamondShape()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .rotationEffect(.degrees(45))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Crescent Divider
private struct CrescentDivider: View {
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // Left line
            Rectangle()
                .fill(color)
                .frame(height: 1)

            // Center crescent and star
            HStack(spacing: 4) {
                CrescentShape()
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: 12, height: 12)

                StarOrnament(color: color)
                    .frame(width: 8, height: 8)
            }

            // Right line
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
    }
}

// MARK: - Star Ornament Shape
private struct StarOrnament: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2

            var path = Path()
            let points = 8
            let outerRadius = radius
            let innerRadius = radius * 0.4

            for i in 0..<points * 2 {
                let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2
                let currentRadius = i % 2 == 0 ? outerRadius : innerRadius
                let x = center.x + cos(angle) * currentRadius
                let y = center.y + sin(angle) * currentRadius

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()

            context.fill(path, with: .color(color))
        }
    }
}

// MARK: - Crescent Shape
private struct CrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2

        // Outer circle
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        // Inner circle offset
        let offsetX = radius * 0.25
        let innerCenter = CGPoint(x: center.x + offsetX, y: center.y)
        let innerRadius = radius * 0.8

        path.addArc(
            center: innerCenter,
            radius: innerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: true
        )

        return path
    }
}

// MARK: - Diamond Shape
private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Section Divider
struct SectionDivider: View {
    let title: String?

    var body: some View {
        VStack(spacing: 12) {
            IslamicDivider(style: .ornamental)

            if let title = title {
                ThemedText(title, style: .caption)
                    .opacity(0.6)
            }

            IslamicDivider(style: .ornamental)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 32) {
            // Simple divider
            VStack(alignment: .leading, spacing: 8) {
                ThemedText.caption("SIMPLE")
                IslamicDivider(style: .simple)
            }

            // Ornamental divider
            VStack(alignment: .leading, spacing: 8) {
                ThemedText.caption("ORNAMENTAL")
                IslamicDivider(style: .ornamental)
            }

            // Geometric divider
            VStack(alignment: .leading, spacing: 8) {
                ThemedText.caption("GEOMETRIC")
                IslamicDivider(style: .geometric)
            }

            // Crescent divider
            VStack(alignment: .leading, spacing: 8) {
                ThemedText.caption("CRESCENT")
                IslamicDivider(style: .crescent)
            }

            Divider()
                .padding(.vertical)

            // Usage in context
            VStack(spacing: 16) {
                ThemedText.heading("Morning Prayers")

                IslamicDivider(style: .ornamental)

                ThemedText.body("Fajr - 5:30 AM")
                ThemedText.body("Dhuhr - 12:45 PM")

                IslamicDivider(style: .crescent, color: AppColors.primary.gold)

                ThemedText.heading("Evening Prayers")

                IslamicDivider(style: .ornamental)

                ThemedText.body("Asr - 3:45 PM")
                ThemedText.body("Maghrib - 6:20 PM")
            }

            Divider()
                .padding(.vertical)

            // Section divider with title
            SectionDivider(title: "PRAYER TIMES")

            // Different colors
            VStack(spacing: 16) {
                IslamicDivider(style: .ornamental, color: AppColors.primary.green)
                IslamicDivider(style: .crescent, color: AppColors.primary.gold)
                IslamicDivider(style: .geometric, color: AppColors.primary.teal)
            }
        }
        .padding()
    }
    .background(ThemeManager().currentTheme.backgroundColor)
    .environmentObject(ThemeManager())
}
