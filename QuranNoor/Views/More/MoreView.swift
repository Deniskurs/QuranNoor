//
//  MoreView.swift
//  QuranNoor
//
//  More tab containing Settings, Bookmarks, and other features
//

import SwiftUI

struct MoreView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

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
