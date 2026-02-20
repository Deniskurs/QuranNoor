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
    var accessibilityHelper = AccessibilityHelper.shared

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
                        .foregroundColor(themeManager.currentTheme.accentMuted)
                        .accessibilityHidden(true)

                    ThemedText("Choose Your Theme", style: .title)
                        .foregroundColor(themeManager.currentTheme.accent)
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
                                .foregroundColor(themeManager.currentTheme.textPrimary)
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
                .tint(themeManager.currentTheme.accent)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .accessibleElement(
                    label: "Get Started with \(selectedTheme.displayName) theme",
                    hint: "Double tap to complete onboarding and start using the app",
                    traits: .isButton
                )
            }
        }
        .accessibilityPageAnnouncement("Theme Selection. Step \(coordinator.currentStep.rawValue + 1) of \(OnboardingCoordinator.OnboardingStep.allCases.count). Choose your preferred theme for reading the Quran and viewing prayer times.")
    }

    // MARK: - Methods

    private func selectTheme(_ theme: ThemeMode) {
        withAnimation(accessibilityHelper.shouldAnimate ? .spring(response: 0.3) : nil) {
            selectedTheme = theme
            coordinator.selectedTheme = theme.rawValue
            // Don't change the entire app theme during selection — only update the preview
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
        // Apply the selected theme to the app now (on completion, not during browsing)
        themeManager.setTheme(selectedTheme)
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
    var accessibilityHelper = AccessibilityHelper.shared

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
                                    .stroke(theme.textPrimary.opacity(AccessibilityHelper.shared.opacity(0.3)), lineWidth: 1)
                            )

                        // Checkmark if selected
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.currentTheme.accent)
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
                                    isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textPrimary
                                )

                            if isSuggested {
                                Text("SUGGESTED")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(themeManager.currentTheme.backgroundColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(themeManager.currentTheme.accentMuted)
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
                        .foregroundColor(theme.accent)
                        .accessibilityHidden(true)
                }

                // Personality description
                if isSelected {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()

                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentMuted)

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
                                isSelected ? themeManager.currentTheme.accent : Color.clear,
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

    /// Accent color used in theme selection UI - delegates to accent from Colors.swift
    var accentColor: Color {
        accent
    }

    /// Creates a Theme struct for preview purposes, using the canonical color values from Colors.swift
    var theme: Theme {
        Theme(
            name: displayName,
            backgroundColor: backgroundColor,  // From Colors.swift
            cardColor: cardColor,              // From Colors.swift
            textColor: textPrimary,            // From Colors.swift
            accentColor: accent                // From Colors.swift
        )
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
