//
//  MoreView.swift
//  QuranNoor
//
//  More tab containing Settings, Bookmarks, and other features
//

import SwiftUI

struct MoreView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var adhkarService = AdhkarService()
    private var tasbihService: TasbihService { TasbihService.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Header
                        headerSection

                        // Worship & Remembrance section
                        worshipSection

                        // Main sections
                        VStack(spacing: Spacing.sm) {
                            // Bookmarks
                            NavigationLink {
                                BookmarksView()
                            } label: {
                                MoreMenuItem(
                                    icon: "bookmark.fill",
                                    title: "Bookmarks",
                                    subtitle: "Saved verses and inspiration",
                                    accentColor: AppColors.primary.gold,
                                    badge: bookmarkBadge
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()
                                .padding(.horizontal, Spacing.sm)

                            // Settings
                            NavigationLink {
                                SettingsView()
                            } label: {
                                MoreMenuItem(
                                    icon: "gearshape.fill",
                                    title: "Settings",
                                    subtitle: "Preferences and customization",
                                    accentColor: themeManager.currentTheme.featureAccent
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(Spacing.sm)
                        .background(themeManager.currentTheme.cardColor)
                        .cornerRadius(BorderRadius.xl)
                        .padding(.horizontal, Spacing.screenHorizontal)

                        // Additional sections
                        additionalSection
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.xs) {
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            Text("Qur'an Noor")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text("Light of the Qur'an")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Worship & Remembrance Section

    private var worshipSection: some View {
        VStack(spacing: Spacing.sm) {
            // Section header
            HStack {
                Text("Worship & Remembrance")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .textCase(.uppercase)

                Spacer()
            }
            .padding(.horizontal, Spacing.screenHorizontal + Spacing.xxxs)

            // Dashboard card
            todayActivityCard

            // Tool links
            VStack(spacing: Spacing.sm) {
                // Daily Adhkar
                NavigationLink {
                    AdhkarView()
                } label: {
                    MoreMenuItem(
                        icon: "sparkles",
                        title: "Daily Adhkar",
                        subtitle: "Morning, evening & prayer remembrances",
                        accentColor: .orange,
                        badge: adhkarTodayBadge
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.horizontal, Spacing.sm)

                // Fortress of the Muslim
                NavigationLink {
                    FortressDuasView()
                } label: {
                    MoreMenuItem(
                        icon: "book.closed.fill",
                        title: "Fortress of the Muslim",
                        subtitle: "Duas for every life situation",
                        accentColor: AppColors.primary.green
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.horizontal, Spacing.sm)

                // 99 Names of Allah
                NavigationLink {
                    NamesOfAllahView()
                } label: {
                    MoreMenuItem(
                        icon: "moon.stars.fill",
                        title: "99 Names of Allah",
                        subtitle: "Learn the beautiful names",
                        accentColor: .purple
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.horizontal, Spacing.sm)

                // Tasbih Counter
                NavigationLink {
                    TasbihCounterView()
                } label: {
                    MoreMenuItem(
                        icon: "hand.tap.fill",
                        title: "Tasbih Counter",
                        subtitle: "Digital counting beads",
                        accentColor: themeManager.currentTheme.featureAccent
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(Spacing.sm)
            .background(themeManager.currentTheme.cardColor)
            .cornerRadius(BorderRadius.xl)
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    // MARK: - Today's Activity Card

    private var todayActivityCard: some View {
        HStack(spacing: 0) {
            // Adhkar completed today
            VStack(spacing: 4) {
                Text("\(adhkarCompletedToday)/\(adhkarTotalToday)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(adhkarCompletedToday > 0 ? AppColors.primary.green : themeManager.currentTheme.textPrimary)

                Text("Adhkar")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(themeManager.currentTheme.divider)
                .frame(width: 1, height: 32)

            // Tasbih today
            VStack(spacing: 4) {
                Text("\(tasbihService.statistics.todayCount)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(tasbihService.statistics.todayCount > 0 ? themeManager.currentTheme.featureAccent : themeManager.currentTheme.textPrimary)

                Text("Tasbih")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(themeManager.currentTheme.divider)
                .frame(width: 1, height: 32)

            // Streak
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text("\(adhkarService.progress.streak)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(adhkarService.progress.streak > 0 ? .orange : themeManager.currentTheme.textPrimary)

                    if adhkarService.progress.streak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }

                Text("Streak")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(themeManager.currentTheme.cardColor)
        .cornerRadius(BorderRadius.xl)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Additional Section

    private var additionalSection: some View {
        VStack(spacing: Spacing.sm) {
            // About
            NavigationLink {
                AboutView()
            } label: {
                MoreMenuItem(
                    icon: "info.circle.fill",
                    title: "About",
                    subtitle: "App information",
                    accentColor: AppColors.primary.green
                )
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.horizontal, Spacing.sm)

            // Help & Support
            NavigationLink {
                HelpView()
            } label: {
                MoreMenuItem(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get assistance",
                    accentColor: themeManager.currentTheme.featureAccent
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(Spacing.sm)
        .background(themeManager.currentTheme.cardColor)
        .cornerRadius(BorderRadius.xl)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Computed Properties

    private var bookmarkBadge: Int? {
        let quranCount = QuranService.shared.getBookmarks().count
        let spiritualCount = SpiritualBookmarkService.shared.totalCount
        let total = quranCount + spiritualCount

        return total > 0 ? total : nil
    }

    private var adhkarCompletedToday: Int {
        adhkarService.allAdhkar.filter { adhkarService.isCompleted(dhikrId: $0.id) }.count
    }

    private var adhkarTotalToday: Int {
        adhkarService.allAdhkar.count
    }

    private var adhkarTodayBadge: Int? {
        let completed = adhkarCompletedToday
        return completed > 0 ? completed : nil
    }
}

// MARK: - More Menu Item

private struct MoreMenuItem: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    var badge: Int? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            // Badge or chevron
            if let badge = badge {
                Text("\(badge)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.primary.gold)
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .padding(Spacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Placeholder Views

struct AboutView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Text("About Qur'an Noor")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text("Version 1.0.0")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                Text("A premium Islamic companion app for prayer times, Qur'an reading, and spiritual growth.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.horizontal, Spacing.lg)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Text("Help & Support")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text("For assistance, please contact:")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                Text("support@qurannoor.app")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.accentInteractive)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("More View") {
    MoreView()
        .environment(ThemeManager())
}

#Preview("Dark Mode") {
    MoreView()
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
}
