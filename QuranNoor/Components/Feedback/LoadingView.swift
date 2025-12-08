//
//  LoadingView.swift
//  QuranNoor
//
//  Animated loading indicator with Islamic crescent moon
//

import SwiftUI

// MARK: - Loading Size
enum LoadingSize {
    case small   // 24pt
    case large   // 48pt

    var dimension: CGFloat {
        switch self {
        case .small: return 24
        case .large: return 48
        }
    }
}

// MARK: - Loading View Component
struct LoadingView: View {
    // MARK: - Properties
    let size: LoadingSize
    let message: String?

    @State private var isRotating: Bool = false
    @State private var isViewVisible: Bool = false

    // MARK: - Initializer
    init(
        size: LoadingSize = .large,
        message: String? = nil
    ) {
        self.size = size
        self.message = message
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Crescent moon animation
            CrescentMoonShape()
                .stroke(AppColors.primary.gold, lineWidth: size == .small ? 2 : 3)
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                .animation(
                    isViewVisible ?
                        .linear(duration: 2.0).repeatForever(autoreverses: false) :
                        .default,
                    value: isRotating
                )
                .onAppear {
                    isViewVisible = true
                    isRotating = true
                }
                .onDisappear {
                    isViewVisible = false
                    isRotating = false
                }

            // Optional message
            if let message = message {
                ThemedText.caption(message)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Crescent Moon Shape
private struct CrescentMoonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = min(width, height) / 2

        // Outer circle (full moon)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        // Inner circle offset (creates crescent)
        let offsetX = radius * 0.3
        let innerCenter = CGPoint(x: center.x + offsetX, y: center.y)
        let innerRadius = radius * 0.85

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

// MARK: - Full Screen Loading Overlay
struct LoadingOverlay: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Semi-transparent background
            themeManager.currentTheme.backgroundColor
                .opacity(0.95)
                .ignoresSafeArea()

            // Loading indicator
            LoadingView(size: .large, message: "Loading...")
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 48) {
        // Small loader
        LoadingView(size: .small)

        // Large loader
        LoadingView(size: .large)

        // Loader with message
        LoadingView(size: .large, message: "Calculating prayer times...")

        // Full screen overlay preview
        ZStack {
            // Mock content
            VStack {
                ThemedText.heading("Home Screen")
                ThemedText.body("Some content here")
            }

            // Loading overlay
            LoadingOverlay()
                .environment(ThemeManager())
        }
        .frame(height: 200)
    }
    .padding()
    .background(ThemeManager().currentTheme.backgroundColor)
    .environment(ThemeManager())
}
