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

    private var theme: ThemeMode { themeManager.currentTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                GradientBackground(style: .serenity, opacity: 0.15)

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
                                    subtitle: "Daily remembrances",
                                    iconColor: theme.accentMuted
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())

                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                NamesOfAllahView()
                            } label: {
                                MoreMenuItem(
                                    icon: "text.book.closed.fill",
                                    title: "99 Names of Allah",
                                    subtitle: "Al-Asma al-Husna",
                                    iconColor: theme.accentMuted
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())

                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                TasbihCounterView()
                            } label: {
                                MoreMenuItem(
                                    icon: "hand.tap.fill",
                                    title: "Tasbih Counter",
                                    subtitle: "Digital dhikr counter",
                                    iconColor: theme.accentMuted
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())

                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                FortressDuasView()
                            } label: {
                                MoreMenuItem(
                                    icon: "shield.fill",
                                    title: "Fortress of the Muslim",
                                    subtitle: "Authentic daily supplications",
                                    iconColor: theme.accentMuted
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())
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
                            .buttonStyle(MenuItemButtonStyle())

                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                IslamicCalendarView()
                            } label: {
                                MoreMenuItem(
                                    icon: "calendar.badge.clock",
                                    title: "Islamic Calendar",
                                    subtitle: "Hijri dates & events"
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())

                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.sm)

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
                            .buttonStyle(MenuItemButtonStyle())
                        }

                        // MARK: App
                        moreSectionCard(title: "App") {
                            NavigationLink {
                                SettingsView(prayerVM: prayerVM)
                            } label: {
                                MoreMenuItem(
                                    icon: "gearshape.fill",
                                    title: "Settings",
                                    subtitle: "Preferences and customization",
                                    iconColor: theme.textSecondary
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())

                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                AboutView()
                            } label: {
                                MoreMenuItem(
                                    icon: "info.circle.fill",
                                    title: "About",
                                    subtitle: "App information",
                                    iconColor: theme.textSecondary
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())

                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.sm)

                            NavigationLink {
                                HelpView()
                            } label: {
                                MoreMenuItem(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    subtitle: "Get assistance",
                                    iconColor: theme.textSecondary
                                )
                            }
                            .buttonStyle(MenuItemButtonStyle())
                        }
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("نور القرآن")
                .font(.system(size: 34, weight: .regular, design: .default))
                .foregroundColor(theme.accent)

            Text("LIGHT OF THE QURAN")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(theme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
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
                .foregroundColor(theme.textTertiary)
                .textCase(.uppercase)
                .padding(.horizontal, Spacing.screenHorizontal + Spacing.xs)

            CardView(intensity: .subtle) {
                VStack(spacing: Spacing.sm) {
                    content()
                }
            }
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

// MARK: - Menu Item Button Style

private struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - More Menu Item

private struct MoreMenuItem: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let icon: String
    let title: String
    let subtitle: String
    var badge: Int? = nil
    var iconColor: Color? = nil

    private var theme: ThemeMode { themeManager.currentTheme }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill((iconColor ?? theme.accent).opacity(0.12))
                    .frame(width: Spacing.xxl, height: Spacing.xxl)

                Image(systemName: icon)
                    .font(.system(size: FontSizes.lg + 2))
                    .foregroundColor(iconColor ?? theme.accent)
            }

            // Text
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.system(size: FontSizes.base, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text(subtitle)
                    .font(.system(size: FontSizes.sm - 1))
                    .foregroundColor(theme.textSecondary)
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
                            .fill(theme.accentMuted)
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: FontSizes.sm, weight: .semibold))
                .foregroundColor(theme.textTertiary)
        }
        .padding(Spacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Placeholder Views

struct AboutView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    private var theme: ThemeMode { themeManager.currentTheme }

    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            GradientBackground(style: .serenity, opacity: 0.15)

            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Hero section
                    heroSection

                    // Description card
                    descriptionCard

                    // Features card
                    featuresCard

                    // Footer
                    footerSection
                }
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.sm) {
            // App icon representation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.accentMuted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: theme.accent.opacity(0.3), radius: 16)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }

            Text("Qur'an Noor")
                .font(.system(size: FontSizes.xxl, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .tracking(1.0)

            Text("نور القرآن")
                .font(.custom("KFGQPCHAFSUthmanicScript-Regular", size: 24, relativeTo: .title2))
                .foregroundColor(theme.accent)

            // Version badge
            Text("Version 1.0.0")
                .font(.system(size: FontSizes.xs, weight: .semibold))
                .foregroundColor(theme.accentMuted)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxxs)
                .background(
                    Capsule()
                        .fill(theme.accentTint)
                )
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Description Card

    private var descriptionCard: some View {
        CardView(intensity: .subtle) {
            VStack(spacing: Spacing.sm) {
                Text("About")
                    .font(.system(size: FontSizes.base, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("A premium Islamic companion app designed for Muslims worldwide. Qur'an Noor provides accurate prayer times, complete Quran with translations and audio recitations, Qibla direction, daily adhkar, and tools for spiritual growth — all in a clean, ad-free experience.")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Features Card

    private var featuresCard: some View {
        CardView(intensity: .subtle) {
            VStack(spacing: Spacing.sm) {
                Text("Features")
                    .font(.system(size: FontSizes.base, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                featureRow(icon: "book.fill", title: "Complete Quran", subtitle: "With translations and audio recitations")

                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 0.5)

                featureRow(icon: "clock.fill", title: "Prayer Times", subtitle: "Accurate calculations for your location")

                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 0.5)

                featureRow(icon: "location.north.fill", title: "Qibla Compass", subtitle: "Find the direction to Makkah")

                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 0.5)

                featureRow(icon: "sparkles", title: "Adhkar & Duas", subtitle: "Daily remembrances and supplications")
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(theme.accentTint)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: FontSizes.sm + 1))
                    .foregroundColor(theme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: FontSizes.sm, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text(subtitle)
                    .font(.system(size: FontSizes.xs))
                    .foregroundColor(theme.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Spacing.xxs) {
            Text("Made with love for the Ummah")
                .font(.system(size: FontSizes.xs, weight: .medium))
                .foregroundColor(theme.textTertiary)

            Text("بسم الله الرحمن الرحيم")
                .font(.custom("KFGQPCHAFSUthmanicScript-Regular", size: 16, relativeTo: .caption))
                .foregroundColor(theme.accentMuted)
        }
        .padding(.vertical, Spacing.md)
    }
}

struct HelpView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    private var theme: ThemeMode { themeManager.currentTheme }

    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            GradientBackground(style: .serenity, opacity: 0.15)

            ScrollView {
                VStack(spacing: Spacing.md) {
                    // FAQ Section
                    faqSection

                    // Contact Section
                    contactSection
                }
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Frequently Asked Questions")
                .sectionHeaderStyle()
                .foregroundColor(theme.textTertiary)
                .padding(.horizontal, Spacing.screenHorizontal + Spacing.xs)

            CardView(intensity: .subtle) {
                VStack(spacing: Spacing.sm) {
                    faqItem(
                        question: "How do I change the prayer calculation method?",
                        answer: "Go to Settings > Prayer Settings and select your preferred calculation method from the available options."
                    )

                    Rectangle().fill(theme.divider).frame(height: 0.5)

                    faqItem(
                        question: "How do I bookmark a verse?",
                        answer: "While reading the Quran, tap the bookmark icon on any verse to save it. Access your bookmarks from the More tab."
                    )

                    Rectangle().fill(theme.divider).frame(height: 0.5)

                    faqItem(
                        question: "Can I listen to Quran offline?",
                        answer: "Yes, downloaded surahs are available for offline listening. Playback will use cached audio when available."
                    )

                    Rectangle().fill(theme.divider).frame(height: 0.5)

                    faqItem(
                        question: "How do I change the app theme?",
                        answer: "Go to Settings > Appearance to choose between Light, Dark, Night (OLED), and Sepia themes."
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .top, spacing: Spacing.xxs) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.accent)
                    .padding(.top, 2)

                Text(question)
                    .font(.system(size: FontSizes.sm, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(answer)
                .font(.system(size: FontSizes.sm - 1))
                .foregroundColor(theme.textSecondary)
                .lineSpacing(3)
                .padding(.leading, FontSizes.sm + Spacing.xxs)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Contact Us")
                .sectionHeaderStyle()
                .foregroundColor(theme.textTertiary)
                .padding(.horizontal, Spacing.screenHorizontal + Spacing.xs)

            CardView(intensity: .subtle) {
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(theme.accentTint)
                                .frame(width: 36, height: 36)

                            Image(systemName: "envelope.fill")
                                .font(.system(size: FontSizes.sm + 1))
                                .foregroundColor(theme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email Support")
                                .font(.system(size: FontSizes.sm, weight: .semibold))
                                .foregroundColor(theme.textPrimary)

                            Text("support@qurannoor.app")
                                .font(.system(size: FontSizes.sm - 1))
                                .foregroundColor(theme.accent)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: FontSizes.xs, weight: .semibold))
                            .foregroundColor(theme.textTertiary)
                    }

                    Rectangle().fill(theme.divider).frame(height: 0.5)

                    Text("We value your feedback and strive to make Qur'an Noor the best Islamic companion app. Don't hesitate to reach out with suggestions or questions.")
                        .font(.system(size: FontSizes.sm - 1))
                        .foregroundColor(theme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
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
