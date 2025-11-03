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

// MARK: - Gradient Cache (Performance Optimization)
@MainActor
class GradientCache {
    static let shared = GradientCache()
    private var cache: [CacheKey: Gradient] = [:]

    struct CacheKey: Hashable {
        let style: BackgroundGradientStyle
        let theme: ThemeMode
    }

    func gradient(for style: BackgroundGradientStyle, theme: ThemeMode) -> Gradient? {
        let key = CacheKey(style: style, theme: theme)
        return cache[key]
    }

    func setGradient(_ gradient: Gradient, for style: BackgroundGradientStyle, theme: ThemeMode) {
        let key = CacheKey(style: style, theme: theme)
        cache[key] = gradient
    }

    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Gradient Background Component
struct GradientBackground: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let style: BackgroundGradientStyle
    let opacity: Double

    // MARK: - Computed Gradient Colors (Theme-Reactive)
    private func gradientForStyle(_ style: BackgroundGradientStyle, theme: ThemeMode) -> Gradient {
        // For sepia theme, no gradients (reading comfort)
        if !theme.supportsGradients {
            return Gradient(colors: [theme.backgroundColor, theme.backgroundColor])
        }

        // For night theme, use pure black (OLED optimization)
        if theme == .night {
            return Gradient(colors: [Color.black, Color.black])
        }

        // Use theme-appropriate gradient colors with safe opacity limits
        let isLight = theme == .light || theme == .sepia

        switch style {
        case .prayer:
            return Gradient(colors: [
                AppColors.primary.green.opacity(theme.gradientOpacity(for: AppColors.primary.green)),
                theme == .dark ? AppColors.primary.midnight.opacity(0.6) : theme.backgroundColor
            ])

        case .quran:
            return Gradient(colors: [
                AppColors.primary.gold.opacity(theme.gradientOpacity(for: AppColors.primary.gold)),
                theme == .dark ? AppColors.primary.midnight.opacity(0.7) : theme.backgroundColor
            ])

        case .home:
            return Gradient(colors: [
                AppColors.primary.teal.opacity(theme.gradientOpacity(for: AppColors.primary.teal)),
                AppColors.primary.green.opacity(theme.gradientOpacity(for: AppColors.primary.green))
            ])

        case .serenity:
            // Fixed: No cream on light backgrounds!
            if isLight {
                return Gradient(colors: [
                    Color.gray.opacity(0.08),  // Subtle gray instead of cream
                    Color.gray.opacity(0.03)
                ])
            } else {
                return Gradient(colors: [
                    AppColors.neutral.cream.opacity(0.15),
                    Color.gray.opacity(0.10)
                ])
            }

        case .night:
            return Gradient(colors: [
                AppColors.primary.midnight.opacity(0.3),
                Color.black
            ])

        case .settings:
            return Gradient(colors: [
                AppColors.primary.green.opacity(isLight ? 0.06 : 0.18),
                theme == .dark ? AppColors.primary.midnight.opacity(0.7) : theme.backgroundColor
            ])
        }
    }

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
        .opacity(effectiveOpacity)
        .drawingGroup()  // Render to offscreen buffer for performance
        .ignoresSafeArea()
    }

    // MARK: - Gradient Colors (Theme-Aware with Caching)
    private var gradientColors: Gradient {
        let theme = themeManager.currentTheme

        // Check cache first
        if let cached = GradientCache.shared.gradient(for: style, theme: theme) {
            return cached
        }

        // Compute and cache gradient
        let gradient = gradientForStyle(style, theme: theme)
        GradientCache.shared.setGradient(gradient, for: style, theme: theme)
        return gradient
    }

    // MARK: - Effective Opacity (Adjusted for Night Theme)
    private var effectiveOpacity: Double {
        // For night theme, suppress gradient almost entirely (pure black for OLED)
        if themeManager.currentTheme == .night {
            return 0.0  // No gradient overlay in night mode
        }
        return opacity
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

