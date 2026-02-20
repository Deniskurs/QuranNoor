//
//  TimeOfDaySkyView.swift
//  QuranNoor
//
//  Animated sky gradient that shifts based on time of day
//  Supports all 4 themes with OLED optimization for night mode
//

import SwiftUI

/// Time of day periods for sky gradient calculation
enum TimeOfDayPeriod: CaseIterable {
    case preDawn      // 4:00 AM - 5:00 AM
    case dawn         // 5:00 AM - 6:30 AM
    case morning      // 6:30 AM - 12:00 PM
    case afternoon    // 12:00 PM - 5:00 PM
    case sunset       // 5:00 PM - 7:30 PM
    case night        // 7:30 PM - 4:00 AM

    /// Calculate current period from time
    static func current(from date: Date = Date()) -> TimeOfDayPeriod {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let totalMinutes = hour * 60 + minute

        switch totalMinutes {
        case 240..<300:     // 4:00 - 5:00
            return .preDawn
        case 300..<390:     // 5:00 - 6:30
            return .dawn
        case 390..<720:     // 6:30 - 12:00
            return .morning
        case 720..<1020:    // 12:00 - 17:00
            return .afternoon
        case 1020..<1170:   // 17:00 - 19:30
            return .sunset
        default:            // 19:30 - 4:00
            return .night
        }
    }

    /// Progress through current period (0.0 to 1.0)
    static func progress(from date: Date = Date()) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let totalMinutes = Double(hour * 60 + minute)

        let period = current(from: date)
        let (start, end): (Double, Double) = switch period {
        case .preDawn:   (240, 300)
        case .dawn:      (300, 390)
        case .morning:   (390, 720)
        case .afternoon: (720, 1020)
        case .sunset:    (1020, 1170)
        case .night:     (1170, 1680) // Wraps around midnight
        }

        if period == .night && totalMinutes < 240 {
            // Handle wrap-around (after midnight)
            let adjustedMinutes = totalMinutes + 1440 // Add 24 hours in minutes
            return min(1.0, max(0.0, (adjustedMinutes - 1170) / (1680 - 1170)))
        }

        return min(1.0, max(0.0, (totalMinutes - start) / (end - start)))
    }
}

/// Animated sky gradient view that changes based on time of day
struct TimeOfDaySkyView: View {
    // MARK: - Properties

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var currentPeriod: TimeOfDayPeriod = .current()
    @State private var periodProgress: Double = TimeOfDayPeriod.progress()

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient layer
                if themeManager.currentTheme != .sepia {
                    Canvas { context, size in
                        drawSkyGradient(context: context, size: size)
                    }
                    .drawingGroup() // Metal acceleration for gradient rendering
                } else {
                    // Solid color for sepia/non-gradient themes
                    Rectangle()
                        .fill(solidBackgroundColor)
                }

                // Subtle atmospheric particles (stars at night, dust in day)
                if !reduceMotion && shouldShowParticles {
                    AtmosphericParticlesView(period: currentPeriod)
                        .opacity(particleOpacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            updateTimeOfDay()
        }
        .task {
            // Periodically refresh time-of-day calculation every 60 seconds
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                updateTimeOfDay()
            }
        }
    }

    // MARK: - Drawing

    private func drawSkyGradient(context: GraphicsContext, size: CGSize) {
        let colors = gradientColors
        let gradient = Gradient(colors: colors)

        // Create vertical gradient from top to bottom
        let linearGradient = GraphicsContext.Shading.linearGradient(
            gradient,
            startPoint: CGPoint(x: size.width / 2, y: 0),
            endPoint: CGPoint(x: size.width / 2, y: size.height)
        )

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: linearGradient
        )

        // Add horizon glow for dawn/sunset
        if currentPeriod == .dawn || currentPeriod == .sunset {
            drawHorizonGlow(context: context, size: size)
        }
    }

    private func drawHorizonGlow(context: GraphicsContext, size: CGSize) {
        let glowColor = currentPeriod == .dawn
            ? Color(hex: "#FFB347").opacity(0.4)  // Warm orange for dawn
            : Color(hex: "#FF6B6B").opacity(0.3)   // Warm red for sunset

        let glowGradient = Gradient(colors: [
            glowColor,
            glowColor.opacity(0.1),
            Color.clear
        ])

        let radialGradient = GraphicsContext.Shading.radialGradient(
            glowGradient,
            center: CGPoint(x: size.width / 2, y: size.height * 0.85),
            startRadius: 0,
            endRadius: size.width * 0.8
        )

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: radialGradient
        )
    }

    // MARK: - Colors

    private var gradientColors: [Color] {
        switch themeManager.currentTheme {
        case .light:
            return lightThemeGradient
        case .dark:
            return darkThemeGradient
        case .night:
            return nightThemeGradient
        case .sepia:
            return [themeManager.currentTheme.backgroundColor] // Solid for sepia
        }
    }

    private var lightThemeGradient: [Color] {
        switch currentPeriod {
        case .preDawn:
            return [
                Color(hex: "#1A1A2E"),
                Color(hex: "#16213E"),
                Color(hex: "#2C3E50")
            ]
        case .dawn:
            return [
                Color(hex: "#2C3E50"),
                Color(hex: "#E8C4A0"),
                Color(hex: "#FFD4A0")
            ]
        case .morning:
            return [
                Color(hex: "#87CEEB"),
                Color(hex: "#E0F6FF"),
                Color(hex: "#F8F4EA")
            ]
        case .afternoon:
            return [
                Color(hex: "#5DADE2"),
                Color(hex: "#AED6F1"),
                Color(hex: "#F8F4EA")
            ]
        case .sunset:
            return [
                Color(hex: "#5D4E6D"),
                Color(hex: "#C88B4A"),
                Color(hex: "#FFB366")
            ]
        case .night:
            return [
                Color(hex: "#0F0F23"),
                Color(hex: "#1A1A2E"),
                Color(hex: "#2D2D44")
            ]
        }
    }

    private var darkThemeGradient: [Color] {
        switch currentPeriod {
        case .preDawn:
            return [
                Color(hex: "#0A0A15"),
                Color(hex: "#0D1419"),
                Color(hex: "#0D7377").opacity(0.3)
            ]
        case .dawn:
            return [
                Color(hex: "#0D1419"),
                Color(hex: "#1A2332"),
                Color(hex: "#C7A566").opacity(0.2)
            ]
        case .morning, .afternoon:
            return [
                Color(hex: "#1A2332"),
                Color(hex: "#14FFEC").opacity(0.1),
                Color(hex: "#1A2332")
            ]
        case .sunset:
            return [
                Color(hex: "#1A2332"),
                Color(hex: "#C7A566").opacity(0.15),
                Color(hex: "#0D1419")
            ]
        case .night:
            return [
                Color(hex: "#0A0A12"),
                Color(hex: "#0D1419"),
                Color(hex: "#1A2332")
            ]
        }
    }

    private var nightThemeGradient: [Color] {
        // OLED optimization: mostly pure black with subtle accent at horizon
        switch currentPeriod {
        case .preDawn, .dawn:
            return [
                Color.black,
                Color.black,
                Color(hex: "#FFD700").opacity(0.08)
            ]
        case .morning, .afternoon:
            return [
                Color.black,
                Color.black,
                Color(hex: "#14FFEC").opacity(0.05)
            ]
        case .sunset:
            return [
                Color.black,
                Color.black,
                Color(hex: "#FF6B6B").opacity(0.08)
            ]
        case .night:
            return [
                Color.black,
                Color.black,
                Color.black
            ]
        }
    }

    private var solidBackgroundColor: Color {
        themeManager.currentTheme.backgroundColor
    }

    private var shouldShowParticles: Bool {
        currentPeriod == .night || currentPeriod == .preDawn
    }

    private var particleOpacity: Double {
        switch currentPeriod {
        case .night: return 0.6
        case .preDawn: return 0.4
        default: return 0
        }
    }

    // MARK: - Updates

    private func updateTimeOfDay() {
        currentPeriod = TimeOfDayPeriod.current()
        periodProgress = TimeOfDayPeriod.progress()
    }
}

// MARK: - Atmospheric Particles (Stars)

private struct AtmosphericParticlesView: View {
    let period: TimeOfDayPeriod

    @State private var particles: [StarParticle] = []

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x * size.width,
                    y: particle.position.y * size.height,
                    width: particle.size,
                    height: particle.size
                )

                context.opacity = particle.opacity
                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white)
                )
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<30).map { _ in
            StarParticle(
                position: CGPoint(
                    x: Double.random(in: 0...1),
                    y: Double.random(in: 0...0.6) // Stars in upper portion
                ),
                size: Double.random(in: 1...3),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
}

private struct StarParticle {
    let position: CGPoint
    let size: Double
    let opacity: Double
}

// MARK: - Preview

#Preview("Light Theme - All Periods") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(TimeOfDayPeriod.allCases, id: \.self) { period in
                TimeOfDaySkyView()
                    .frame(height: 200)
                    .overlay(
                        Text(String(describing: period))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8),
                        alignment: .topLeading
                    )
            }
        }
    }
    .environment(ThemeManager())
}

#Preview("Dark Theme") {
    TimeOfDaySkyView()
        .frame(height: 300)
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
}

#Preview("Night Theme (OLED)") {
    TimeOfDaySkyView()
        .frame(height: 300)
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.night)
            return manager
        }())
}
