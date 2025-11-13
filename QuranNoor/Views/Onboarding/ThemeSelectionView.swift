//
//  ThemeSelectionView.swift
//  QuranNoor
//
//  Enhanced theme selection with live preview, personality descriptions,
//  and intelligent theme recommendations
//

import SwiftUI

struct ThemeSelectionView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ObservedObject private var accessibilityHelper = AccessibilityHelper.shared

    let coordinator: OnboardingCoordinator

    @State private var selectedTheme: ThemeMode
    @State private var showPreview = true

    // MARK: - Initialization

    init(coordinator: OnboardingCoordinator) {
        self.coordinator = coordinator
        // Initialize with current theme or suggested theme
        _selectedTheme = State(initialValue: ThemeMode(rawValue: coordinator.selectedTheme) ?? ThemeSelectionView.suggestedTheme())
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.currentTheme.accentSecondary)
                        .accessibilityHidden(true)

                    ThemedText("Choose Your Theme", style: .title)
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                        .accessibilityAddTraits(.isHeader)

                    ThemedText.body("Select your preferred reading mode. You can change this anytime in Settings")
                        .multilineTextAlignment(.center)
                        .reducedTransparency(opacity: 0.8)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                // MARK: - Live Preview
                if showPreview {
                    VStack(spacing: 12) {
                        HStack {
                            ThemedText("Preview", style: .heading)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            Spacer()
                        }
                        .padding(.horizontal, 24)

                        PrayerTimesPreviewCard(theme: selectedTheme.theme)
                            .padding(.horizontal, 24)
                            .transition(AccessibleTransition.scale)
                    }
                }

                // MARK: - Theme Options
                VStack(spacing: 16) {
                    ForEach([ThemeMode.light, ThemeMode.dark, ThemeMode.night, ThemeMode.sepia], id: \.self) { theme in
                        ThemeOptionCard(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            isSuggested: theme == Self.suggestedTheme(),
                            onSelect: {
                                selectTheme(theme)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // MARK: - Complete Button
                Button {
                    completeOnboarding()
                } label: {
                    Label("Get Started", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(themeManager.currentTheme.accentPrimary)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .accessibleElement(
                    label: "Get Started with \(selectedTheme.displayName) theme",
                    hint: "Double tap to complete onboarding and start using the app",
                    traits: .isButton
                )
            }
        }
        .accessibilityPageAnnouncement("Theme Selection. Step 5 of 5. Choose your preferred theme for reading the Quran and viewing prayer times.")
    }

    // MARK: - Methods

    private func selectTheme(_ theme: ThemeMode) {
        withAnimation(accessibilityHelper.shouldAnimate ? .spring(response: 0.3) : nil) {
            selectedTheme = theme
            themeManager.setTheme(theme)
            coordinator.selectedTheme = theme.rawValue
        }

        AudioHapticCoordinator.shared.playSelection()

        // Announce theme selection for VoiceOver
        if accessibilityHelper.isVoiceOverRunning {
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(theme.displayName) theme selected. \(theme.personality)"
            )
        }
    }

    private func completeOnboarding() {
        coordinator.selectedTheme = selectedTheme.rawValue
        coordinator.complete()
    }

    /// Returns suggested theme based on time of day
    static func suggestedTheme() -> ThemeMode {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<18:  // 6 AM to 6 PM
            return .light
        case 18..<22:  // 6 PM to 10 PM
            return .dark
        case 22..<24, 0..<6:  // 10 PM to 6 AM
            return .night
        default:
            return .light
        }
    }
}

// MARK: - Theme Option Card Component

struct ThemeOptionCard: View {
    let theme: ThemeMode
    let isSelected: Bool
    let isSuggested: Bool
    let onSelect: () -> Void

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @ObservedObject private var accessibilityHelper = AccessibilityHelper.shared

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // Theme preview circle
                    ZStack {
                        Circle()
                            .fill(theme.backgroundColor)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(theme.textColor.opacity(AccessibilityHelper.shared.opacity(0.3)), lineWidth: 1)
                            )

                        // Checkmark if selected
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.currentTheme.accentPrimary)
                                .transition(AccessibleTransition.scale)
                        }
                    }
                    .accessibilityHidden(true)

                    // Theme info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            ThemedText(theme.displayName, style: .body)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    isSelected ? themeManager.currentTheme.accentPrimary : themeManager.currentTheme.textColor
                                )

                            if isSuggested {
                                Text("SUGGESTED")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(themeManager.currentTheme.accentSecondary)
                                    )
                                    .transition(AccessibleTransition.scale)
                            }
                        }

                        ThemedText.caption(theme.description)
                            .reducedTransparency(opacity: 0.7)
                    }

                    Spacer()

                    // Theme icon
                    Image(systemName: theme.icon)
                        .font(.system(size: 24))
                        .foregroundColor(theme.accentColor)
                        .accessibilityHidden(true)
                }

                // Personality description
                if isSelected {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()

                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentSecondary)

                            ThemedText.caption(theme.personality)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .transition(
                        accessibilityHelper.shouldAnimate ?
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ) :
                            .opacity
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? themeManager.currentTheme.accentPrimary : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibleElement(
            label: "\(theme.displayName) theme. \(theme.description). \(theme.personality). \(isSuggested ? "Suggested for current time of day." : "")",
            hint: "Double tap to select this theme",
            traits: isSelected ? [.isButton, .isSelected] : .isButton
        )
    }
}

// MARK: - Theme Mode Extensions

extension ThemeMode {
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .night: return "Night (OLED)"
        case .sepia: return "Sepia"
        }
    }

    var description: String {
        switch self {
        case .light:
            return "Classic bright theme with cream background"
        case .dark:
            return "Comfortable dark theme for low-light environments"
        case .night:
            return "Pure black OLED theme for battery saving"
        case .sepia:
            return "Warm vintage theme easy on the eyes"
        }
    }

    var personality: String {
        switch self {
        case .light:
            return "Ideal for daytime reading with maximum clarity and traditional Islamic aesthetic"
        case .dark:
            return "Perfect for evening use, reduces eye strain while maintaining readability"
        case .night:
            return "Optimized for late-night reading with true black background that saves battery on OLED screens"
        case .sepia:
            return "Creates a calming, book-like reading experience reminiscent of traditional manuscripts"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .night: return "moon.stars.fill"
        case .sepia: return "book.closed.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .light: return AppColors.primary.teal
        case .dark: return AppColors.primary.green
        case .night: return AppColors.primary.gold
        case .sepia: return Color(hex: "#C7A566")
        }
    }

    var theme: Theme {
        switch self {
        case .light:
            return Theme(
                name: "Light",
                backgroundColor: Color(hex: "#F8F4EA"),
                cardColor: .white,
                textColor: Color(hex: "#1A2332"),
                accentColor: AppColors.primary.teal
            )
        case .dark:
            return Theme(
                name: "Dark",
                backgroundColor: Color(hex: "#1A2332"),
                cardColor: Color(hex: "#2A3442"),
                textColor: Color(hex: "#F8F4EA"),
                accentColor: AppColors.primary.green
            )
        case .night:
            return Theme(
                name: "Night",
                backgroundColor: .black,
                cardColor: Color(hex: "#1A1A1A"),
                textColor: Color(hex: "#E5E5E5"),
                accentColor: AppColors.primary.gold
            )
        case .sepia:
            return Theme(
                name: "Sepia",
                backgroundColor: Color(hex: "#F4E8D0"),
                cardColor: Color(hex: "#FFF9E6"),
                textColor: Color(hex: "#5D4E37"),
                accentColor: Color(hex: "#C7A566")
            )
        }
    }
}

// MARK: - Theme Model

struct Theme {
    let name: String
    let backgroundColor: Color
    let cardColor: Color
    let textColor: Color
    let accentColor: Color
}

// MARK: - Preview
#Preview {
    ThemeSelectionView(coordinator: OnboardingCoordinator())
        .environment(ThemeManager())
}
