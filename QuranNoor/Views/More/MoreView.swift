//
//  MoreView.swift
//  QuranNoor
//
//  More tab containing Settings, Bookmarks, and other features
//

import SwiftUI

struct MoreView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    var prayerVM: PrayerViewModel

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

                        // MARK: Spiritual Tools
                        moreSectionCard(title: "Spiritual Tools") {
                            NavigationLink {
                                AdhkarView()
                            } label: {
                                MoreMenuItem(
                                    icon: "sparkles",
                                    title: "Adhkar",
                                    subtitle: "Daily remembrances"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider().padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                NamesOfAllahView()
                            } label: {
                                MoreMenuItem(
                                    icon: "text.book.closed.fill",
                                    title: "99 Names of Allah",
                                    subtitle: "Al-Asma al-Husna"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider().padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                TasbihCounterView()
                            } label: {
                                MoreMenuItem(
                                    icon: "hand.tap.fill",
                                    title: "Tasbih Counter",
                                    subtitle: "Digital dhikr counter"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // MARK: Daily Tools
                        moreSectionCard(title: "Daily Tools") {
                            NavigationLink {
                                QiblaCompassView()
                            } label: {
                                MoreMenuItem(
                                    icon: "location.north.fill",
                                    title: "Qibla Direction",
                                    subtitle: "Find direction to Makkah"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider().padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                BookmarksView()
                            } label: {
                                MoreMenuItem(
                                    icon: "bookmark.fill",
                                    title: "Bookmarks",
                                    subtitle: "Saved verses and inspiration",
                                    badge: bookmarkBadge
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // MARK: App
                        moreSectionCard(title: "App") {
                            NavigationLink {
                                SettingsView(prayerVM: prayerVM)
                            } label: {
                                MoreMenuItem(
                                    icon: "gearshape.fill",
                                    title: "Settings",
                                    subtitle: "Preferences and customization"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider().padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                AboutView()
                            } label: {
                                MoreMenuItem(
                                    icon: "info.circle.fill",
                                    title: "About",
                                    subtitle: "App information"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider().padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                HelpView()
                            } label: {
                                MoreMenuItem(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    subtitle: "Get assistance"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
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
        VStack(spacing: Spacing.xxxs) {
            Text("Qur'an Noor")
                .font(.system(size: FontSizes.lg + 2, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text("Light of the Qur'an")
                .font(.system(size: FontSizes.sm))
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Section Card Helper

    private func moreSectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Section header
            Text(title)
                .font(.system(size: FontSizes.sm, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, Spacing.screenHorizontal + Spacing.xs)

            VStack(spacing: Spacing.sm) {
                content()
            }
            .padding(Spacing.sm)
            .background(themeManager.currentTheme.cardColor)
            .cornerRadius(BorderRadius.xl)
            .padding(.horizontal, Spacing.screenHorizontal)
        }
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
    var badge: Int? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.accentTint)
                    .frame(width: Spacing.xxl, height: Spacing.xxl)

                Image(systemName: icon)
                    .font(.system(size: FontSizes.lg + 2))
                    .foregroundColor(themeManager.currentTheme.accent)
            }

            // Text
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.system(size: FontSizes.base, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: FontSizes.sm - 1))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            // Badge or chevron
            if let badge = badge {
                Text("\(badge)")
                    .font(.system(size: FontSizes.sm, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xxs + 2)
                    .padding(.vertical, Spacing.xxxs)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.accentMuted)
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: FontSizes.sm, weight: .semibold))
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
                    .font(.system(size: FontSizes.xl, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text("Version 1.0.0")
                    .font(.system(size: FontSizes.base))
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                Text("A premium Islamic companion app for prayer times, Qur'an reading, and spiritual growth.")
                    .font(.system(size: FontSizes.sm))
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
                    .font(.system(size: FontSizes.xl, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text("For assistance, please contact:")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                Text("support@qurannoor.app")
                    .font(.system(size: FontSizes.base, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.accent)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("More View") {
    MoreView(prayerVM: PrayerViewModel())
        .environment(ThemeManager())
}

#Preview("Dark Mode") {
    MoreView(prayerVM: PrayerViewModel())
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
}
