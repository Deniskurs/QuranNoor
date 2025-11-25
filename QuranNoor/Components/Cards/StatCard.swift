//
//  StatCard.swift
//  QuranNoor
//
//  Shared statistic display card component
//

import SwiftUI

/// Unified stat card component used across Progress, Tasbih, and Home views
struct StatCard: View {
    // MARK: - Properties

    let icon: String
    let title: String
    let value: String
    var subtitle: String? = nil
    var color: Color? = nil  // Uses theme featureAccent if nil

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    /// Resolved color: uses provided color or falls back to theme's featureAccent
    private var resolvedColor: Color {
        color ?? themeManager.currentTheme.featureAccent
    }

    // MARK: - Body

    var body: some View {
        LiquidGlassCardView(intensity: .subtle) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(resolvedColor.opacity(0.8))

                VStack(spacing: 4) {
                    ThemedText.caption(title)
                        .opacity(0.7)

                    ThemedText(value, style: .title)
                        .foregroundStyle(resolvedColor)

                    if let subtitle = subtitle {
                        ThemedText.caption(subtitle)
                            .opacity(0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview

#Preview("StatCard Variants") {
    VStack(spacing: 16) {
        // With subtitle
        StatCard(
            icon: "book.fill",
            title: "Verses Read",
            value: "1,234",
            subtitle: "Total progress",
            color: AppColors.primary.green
        )

        // Without subtitle
        StatCard(
            icon: "hands.sparkles.fill",
            title: "Sessions",
            value: "42",
            color: AppColors.primary.gold
        )

        // Grid layout example
        HStack(spacing: 12) {
            StatCard(
                icon: "flame.fill",
                title: "Streak",
                value: "7",
                subtitle: "Days",
                color: .orange
            )

            // Uses theme default color (no explicit color)
            StatCard(
                icon: "clock.fill",
                title: "Time",
                value: "45",
                subtitle: "Minutes"
            )
        }
    }
    .padding()
    .background(ThemeMode.light.backgroundColor)
    .environment(ThemeManager())
}
