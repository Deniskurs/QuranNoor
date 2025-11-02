//
//  GradientBackground.swift
//  QuranNoor
//
//  Subtle gradient backgrounds for different screen moods and contexts
//

import SwiftUI

// MARK: - Gradient Style
public enum BackgroundGradientStyle: Hashable {
    case prayer     // Peaceful green-to-midnight for prayer times
    case quran      // Elegant gold-to-midnight for Quran reading
    case home       // Welcoming teal-to-green for home screen
    case serenity   // Soft cream-to-sepia for calm moments
    case night      // Deep midnight-to-black for night mode
    case settings   // Subtle gradient for settings screen
}

// MARK: - Gradient Background Component
struct GradientBackground: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let style: BackgroundGradientStyle
    let opacity: Double

    // Performance optimization: Precompute all gradients once
    private static let cachedGradients: [BackgroundGradientStyle: Gradient] = [
        .prayer: Gradient(colors: [
            AppColors.primary.green.opacity(0.4),
            AppColors.primary.midnight
        ]),
        .quran: Gradient(colors: [
            AppColors.primary.gold.opacity(0.3),
            AppColors.primary.midnight
        ]),
        .home: Gradient(colors: [
            AppColors.primary.teal.opacity(0.3),
            AppColors.primary.green.opacity(0.5)
        ]),
        .serenity: Gradient(colors: [
            AppColors.neutral.cream.opacity(0.6),
            Color.gray.opacity(0.4)
        ]),
        .night: Gradient(colors: [
            AppColors.primary.midnight,
            Color.black
        ]),
        .settings: Gradient(colors: [
            AppColors.primary.green.opacity(0.2),
            AppColors.primary.midnight.opacity(0.7)
        ])
    ]

    // MARK: - Initializer
    init(
        style: BackgroundGradientStyle = .home,
        opacity: Double = 0.3
    ) {
        self.style = style
        self.opacity = opacity
    }

    // MARK: - Body
    var body: some View {
        LinearGradient(
            gradient: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(opacity)
        .ignoresSafeArea()
    }

    // MARK: - Gradient Colors
    private var gradientColors: Gradient {
        // Use cached gradient for performance (avoids repeated color array creation)
        return Self.cachedGradients[style] ?? Self.cachedGradients[.home]!
    }
}

// MARK: - Radial Gradient Background
struct RadialGradientBackground: View {
    // MARK: - Properties
    let centerColor: Color
    let edgeColor: Color
    let opacity: Double

    // MARK: - Initializer
    init(
        centerColor: Color = AppColors.primary.green,
        edgeColor: Color = AppColors.primary.midnight,
        opacity: Double = 0.2
    ) {
        self.centerColor = centerColor
        self.edgeColor = edgeColor
        self.opacity = opacity
    }

    // MARK: - Body
    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                centerColor.opacity(opacity),
                edgeColor.opacity(opacity * 0.5)
            ]),
            center: .center,
            startRadius: 100,
            endRadius: 600
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mesh Gradient Background (iOS 18+)
struct MeshGradientBackground: View {
    var body: some View {
        // Fallback to linear gradient for now
        // MeshGradient requires iOS 18+, will be added when available
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.primary.green.opacity(0.2),
                AppColors.primary.teal.opacity(0.3),
                AppColors.primary.midnight.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    // MARK: - Properties
    @State private var animateGradient: Bool = false

    let colors: [Color]
    let duration: Double

    // MARK: - Initializer
    init(
        colors: [Color] = [
            AppColors.primary.green,
            AppColors.primary.teal,
            AppColors.primary.midnight
        ],
        duration: Double = 8.0
    ) {
        self.colors = colors
        self.duration = duration
    }

    // MARK: - Body
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .opacity(0.3)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .linear(duration: duration)
                    .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Theme-Aware Background
struct ThemeAwareBackground: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Base background color
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            // Subtle overlay gradient based on theme
            Group {
                switch themeManager.currentTheme {
                case .light:
                    GradientBackground(style: .home, opacity: 0.15)

                case .dark:
                    GradientBackground(style: .prayer, opacity: 0.2)

                case .night:
                    GradientBackground(style: .night, opacity: 0.8)

                case .sepia:
                    GradientBackground(style: .serenity, opacity: 0.3)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 0) {
            // Prayer gradient
            ZStack {
                GradientBackground(style: .prayer, opacity: 0.4)

                VStack(spacing: 16) {
                    ThemedText.title("Prayer Times")
                    ThemedText.body("Asr in 45 minutes")
                }
                .padding()
            }
            .frame(height: 200)

            // Quran gradient
            ZStack {
                GradientBackground(style: .quran, opacity: 0.4)

                VStack(spacing: 16) {
                    ThemedText.title("Al-Fatiha")
                    ThemedText.arabic("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                }
                .padding()
            }
            .frame(height: 200)

            // Home gradient
            ZStack {
                GradientBackground(style: .home, opacity: 0.4)

                VStack(spacing: 16) {
                    ThemedText.title("Welcome")
                    ThemedText.body("Assalamu Alaikum")
                }
                .padding()
            }
            .frame(height: 200)

            // Serenity gradient
            ZStack {
                GradientBackground(style: .serenity, opacity: 0.5)

                VStack(spacing: 16) {
                    ThemedText.title("Dhikr", italic: true)
                    ThemedText.body("SubhanAllah (33)")
                }
                .padding()
            }
            .frame(height: 200)

            // Radial gradient
            ZStack {
                RadialGradientBackground(
                    centerColor: AppColors.primary.teal,
                    edgeColor: AppColors.primary.midnight,
                    opacity: 0.3
                )

                VStack(spacing: 16) {
                    ThemedText.title("Qibla Compass")
                    ThemedText.body("245° NE")
                }
                .padding()
            }
            .frame(height: 200)

            // Animated gradient
            ZStack {
                AnimatedGradientBackground(duration: 5.0)

                VStack(spacing: 16) {
                    ThemedText.title("Live", italic: true)
                    ThemedText.body("Animated Background")
                }
                .padding()
            }
            .frame(height: 200)

            // Theme-aware background
            ZStack {
                ThemeAwareBackground()

                VStack(spacing: 16) {
                    ThemedText.title("Theme-Aware")
                    ThemedText.body("Changes with theme")
                }
                .padding()
            }
            .frame(height: 200)
            .environmentObject(ThemeManager())
        }
    }
    .background(Color.black)
}

