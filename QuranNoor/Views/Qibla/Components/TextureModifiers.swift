//
//  TextureModifiers.swift
//  QuranNoor
//
//  Premium texture and depth effects for Qibla view
//

import SwiftUI

// MARK: - Noise Texture Modifier

/// Adds a subtle noise texture overlay for premium feel
struct NoiseTextureModifier: ViewModifier {
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Canvas { context, size in
                        // Create noise pattern with random pixels
                        // Use a reasonable density to balance visual effect and performance
                        let pixelCount = Int(size.width * size.height / 4)

                        for _ in 0..<pixelCount {
                            let x = CGFloat.random(in: 0...size.width)
                            let y = CGFloat.random(in: 0...size.height)
                            let rect = CGRect(x: x, y: y, width: 1, height: 1)
                            context.fill(
                                Path(rect),
                                with: .color(.white.opacity(opacity))
                            )
                        }
                    }
                }
                .allowsHitTesting(false)
            )
    }
}

// MARK: - Edge Highlight Modifier

/// Adds subtle edge lighting to cards for premium depth
struct EdgeHighlightModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.clear,
                                Color.black.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .padding(1)  // Inset slightly for inner edge effect
            )
    }
}

// MARK: - Mesh Gradient Background Modifier

/// Adds a sophisticated mesh gradient background for premium depth
/// Falls back to radial gradient on iOS 17 and earlier
struct MeshGradientBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Mesh gradient (iOS 18+ or fallback to radial)
                    if #available(iOS 18.0, *) {
                        MeshGradient(
                            width: 2,
                            height: 2,
                            points: [
                                .init(0, 0), .init(0.5, 0),
                                .init(0, 0.5), .init(1, 1)
                            ],
                            colors: [
                                themeManager.currentTheme.accentPrimary.opacity(0.1),
                                themeManager.currentTheme.accentSecondary.opacity(0.05),
                                themeManager.currentTheme.accentInteractive.opacity(0.05),
                                themeManager.currentTheme.cardColor.opacity(0.5)
                            ]
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    } else {
                        // Fallback for iOS 17
                        RadialGradient(
                            colors: [
                                themeManager.currentTheme.accentPrimary.opacity(0.08),
                                themeManager.currentTheme.cardColor.opacity(0.5)
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a subtle noise texture overlay
    /// - Parameter opacity: Opacity of the noise (default: 0.05)
    func noiseTexture(opacity: Double = 0.05) -> some View {
        modifier(NoiseTextureModifier(opacity: opacity))
    }

    /// Applies subtle edge highlighting for premium depth
    /// - Parameter cornerRadius: Corner radius matching the view's shape
    func edgeHighlight(cornerRadius: CGFloat) -> some View {
        modifier(EdgeHighlightModifier(cornerRadius: cornerRadius))
    }

    /// Applies a mesh gradient background for sophisticated depth
    /// - Parameter cornerRadius: Corner radius matching the view's shape
    func meshGradientBackground(cornerRadius: CGFloat) -> some View {
        modifier(MeshGradientBackgroundModifier(cornerRadius: cornerRadius))
    }
}
