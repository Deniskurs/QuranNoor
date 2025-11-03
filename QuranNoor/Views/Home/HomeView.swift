//
//  HomeView.swift
//  QuranNoor
//
//  Main home screen with quick access to core features
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @State private var prayerVM = PrayerViewModel()
    @State private var quranVM = QuranViewModel()

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Base theme background (ensures pure black in night mode for OLED)
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                // Gradient overlay (automatically suppressed in night mode)
                GradientBackground(style: .home, opacity: 0.3)

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Quick Stats
                        quickStatsSection

                        // Next Prayer Card
                        nextPrayerCard

                        // Reading Progress Card
                        readingProgressCard

                        // Quick Actions
                        quickActionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Home")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Components

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary.gold)

            ThemedText("Welcome to Qur'an Noor", style: .heading)
                .foregroundColor(AppColors.primary.gold)

            ThemedText.caption("Your spiritual companion")
                // Caption style already uses textTertiary - no additional opacity needed
        }
        .padding(.top, 8)
    }

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            // Reading streak
            HomeStatCard(
                icon: "flame.fill",
                value: "\(quranVM.readingProgress?.streakDays ?? 0)",
                label: "Day Streak",
                color: AppColors.primary.gold
            )

            // Verses read
            HomeStatCard(
                icon: "book.fill",
                value: "\(quranVM.readingProgress?.totalVersesRead ?? 0)",
                label: "Verses",
                color: AppColors.primary.green
            )
        }
    }

    private var nextPrayerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary.teal)

                    ThemedText("Next Prayer", style: .heading)

                    Spacer()
                }

                if let nextPrayer = prayerVM.nextPrayer {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            ThemedText(nextPrayer.name.displayName, style: .body)
                                .foregroundColor(AppColors.primary.green)

                            ThemedText.caption(nextPrayer.displayTime)
                                // Caption style already uses textTertiary - no additional opacity needed
                        }

                        Spacer()

                        ThemedText(prayerVM.countdown, style: .heading)
                            .foregroundColor(AppColors.primary.teal)
                    }
                } else {
                    ThemedText.caption("Loading prayer times...")
                        // Caption style already uses textTertiary - no additional opacity needed
                }
            }
        }
    }

    private var readingProgressCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary.gold)

                    ThemedText("Reading Progress", style: .heading)

                    Spacer()

                    ProgressRing(
                        progress: quranVM.getProgressPercentage() / 100,
                        lineWidth: 4,
                        size: 40,
                        showPercentage: false,
                        color: AppColors.primary.green
                    )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("VERSES READ")
                        ThemedText("\(quranVM.readingProgress?.totalVersesRead ?? 0)", style: .body)
                            .foregroundColor(AppColors.primary.green)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        ThemedText.caption("PROGRESS")
                        ThemedText("\(Int(quranVM.getProgressPercentage()))%", style: .body)
                            .foregroundColor(AppColors.primary.teal)
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Quick Actions", style: .heading)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "book.pages.fill",
                    title: "Continue Reading",
                    color: AppColors.primary.gold
                ) {
                    // Navigate to Quran tab
                }

                QuickActionButton(
                    icon: "location.north.fill",
                    title: "Find Qibla",
                    color: AppColors.primary.teal
                ) {
                    // Navigate to Qibla tab
                }
            }
        }
    }
}

// MARK: - Home Stat Card Component
struct HomeStatCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            ThemedText(value, style: .heading)
                .foregroundColor(color)

            ThemedText.caption(label)
                // Caption style already uses textTertiary - no additional opacity needed
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
    }
}

// MARK: - Quick Action Button Component
struct QuickActionButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)

                ThemedText.caption(title)
                    .foregroundColor(color)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(themeManager.currentTheme.gradientOpacity(for: color) * 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(themeManager.currentTheme.gradientOpacity(for: color) * 3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(ThemeManager())
}
