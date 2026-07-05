//
//  AyahMedallion.swift
//  QuranNoor
//
//  Ornamental verse-number medallion — an eight-lobed rosette echoing the
//  ayah markers of printed mushafs. Pure vector, so it stays crisp at any
//  size and adapts to all four themes.
//

import SwiftUI

/// Scalloped rosette outline: `lobes` soft petals bulging out of a base
/// circle. Quad curves between evenly spaced base points keep the path cheap
/// (one segment per lobe — no per-frame work).
struct RosetteShape: Shape {
    var lobes: Int = 8
    /// Fraction of the base radius the petals bulge outward
    var bulge: CGFloat = 0.22

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // Size the base circle so the bulge still fits the rect
        let base = min(rect.width, rect.height) / 2 / (1 + bulge)
        let count = max(4, lobes)
        var path = Path()

        for i in 0...count {
            let angle = (CGFloat(i) / CGFloat(count)) * 2 * .pi - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * base,
                y: center.y + sin(angle) * base
            )
            if i == 0 {
                path.move(to: point)
                continue
            }
            // Control point overshoots so the curve apex lands near 1+bulge
            let midAngle = angle - .pi / CGFloat(count)
            let controlRadius = base * (1 + 2 * bulge)
            let control = CGPoint(
                x: center.x + cos(midAngle) * controlRadius,
                y: center.y + sin(midAngle) * controlRadius
            )
            path.addQuadCurve(to: point, control: control)
        }
        path.closeSubpath()
        return path
    }
}

/// Verse-number medallion used in the reader's verse rows.
/// Decorative only — callers own the accessibility label.
struct AyahMedallion: View {
    let number: Int
    var isPlaying: Bool = false

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @ScaledMetric(relativeTo: .footnote) private var size: CGFloat = 36

    var body: some View {
        let theme = themeManager.currentTheme
        let stroke = isPlaying ? theme.accent : theme.borderColor

        return ZStack {
            RosetteShape()
                .fill(isPlaying ? theme.accent.opacity(0.12) : theme.backgroundColor.opacity(0.5))
            RosetteShape()
                .stroke(stroke, lineWidth: isPlaying ? 1.5 : 1)
            // Inner ring echoes the double-ruled markers of printed mushafs
            Circle()
                .stroke(stroke.opacity(0.35), lineWidth: 0.5)
                .padding(size * 0.18)

            Text("\(number)")
                .font(.footnote.weight(.medium))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(size * 0.24)
                .foregroundColor(isPlaying ? theme.accent : theme.textSecondary)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        AyahMedallion(number: 7)
        AyahMedallion(number: 255, isPlaying: true)
    }
    .padding()
    .environment(ThemeManager())
}
