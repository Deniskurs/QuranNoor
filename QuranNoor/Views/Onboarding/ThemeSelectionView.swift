//
//  ThemeSelectionView.swift
//  QuranNoor
//
//  Screen 3: Theme selection with 2x2 grid, live preview, and launch CTA
//  Compact theme cards with swatch, icon, name, selected ring animation

import SwiftUI

struct ThemeSelectionView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    var accessibilityHelper = AccessibilityHelper.shared

    let coordinator: OnboardingCoordinator

    @State private var selectedTheme: ThemeMode

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.gridSpacing),
        GridItem(.flexible(), spacing: Spacing.gridSpacing)
    ]

    // MARK: - Initialization

    init(coordinator: OnboardingCoordinator) {
        self.coordinator = coordinator
        _selectedTheme = State(initialValue: ThemeMode(rawValue: coordinator.selectedTheme) ?? ThemeSelectionView.suggestedTheme())
    }

    // MARK: - Body
    var body: some View {
        let theme = themeManager.currentTheme

        ScrollView {
            VStack(spacing: Spacing.lg) {
                // MARK: - Header
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentMuted)

                    ThemedText("Choose Your Theme", style: .title)
                        .foregroundColor(theme.accent)

                    ThemedText.body("You can change this anytime in Settings")
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, Spacing.xl)

                // MARK: - 2x2 Theme Grid
                LazyVGrid(columns: columns, spacing: Spacing.gridSpacing) {
                    ForEach([ThemeMode.light, .dark, .night, .sepia], id: \.self) { mode in
                        ThemeGridCard(
                            theme: mode,
                            isSelected: selectedTheme == mode,
                            isSuggested: mode == Self.suggestedTheme(),
                            onSelect: {
                                selectTheme(mode)
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)

                // MARK: - Live Preview
                VStack(spacing: Spacing.xs) {
                    HStack {
                        ThemedText("Preview", style: .heading)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                    }

                    PrayerTimesPreviewCard(theme: selectedTheme.theme)
                        .animation(.smooth(duration: 0.3), value: selectedTheme)
                }
                .padding(.horizontal, Spacing.screenHorizontal)

                Spacer(minLength: Spacing.xxl + 60)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // MARK: - Launch CTA
            Button {
                completeOnboarding()
            } label: {
                Label("Bismillah, Let's Begin", systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(themeManager.currentTheme.accent)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.sm)
            .background(
                themeManager.currentTheme.backgroundColor
                    .opacity(0.95)
                    .ignoresSafeArea()
            )
        }
        .accessibilityPageAnnouncement("Theme Selection. Step 3 of 3. Choose your preferred theme for reading the Quran and viewing prayer times.")
    }

    // MARK: - Methods

    private func selectTheme(_ mode: ThemeMode) {
        withAnimation(accessibilityHelper.shouldAnimate ? .spring(response: 0.3, dampingFraction: 0.7) : nil) {
            selectedTheme = mode
            coordinator.selectedTheme = mode.rawValue
        }

        AudioHapticCoordinator.shared.playSelection()

        if accessibilityHelper.isVoiceOverRunning {
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(mode.displayName) theme selected. \(mode.personality)"
            )
        }
    }

    private func completeOnboarding() {
        coordinator.selectedTheme = selectedTheme.rawValue
        themeManager.setTheme(selectedTheme)
        coordinator.complete()
    }

    /// Returns suggested theme based on time of day
    static func suggestedTheme() -> ThemeMode {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<18:
            return .light
        case 18..<22:
            return .dark
        case 22..<24, 0..<6:
            return .night
        default:
            return .light
        }
    }
}

// MARK: - Theme Grid Card

struct ThemeGridCard: View {
    let theme: ThemeMode
    let isSelected: Bool
    let isSuggested: Bool
    let onSelect: () -> Void

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: Spacing.xxs) {
                // Color swatch
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(theme.backgroundColor)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(theme.textPrimary.opacity(0.15), lineWidth: 1)
                        )

                    Image(systemName: theme.icon)
                        .font(.system(size: 24))
                        .foregroundColor(theme.accent)
                }

                // Name
                Text(theme.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(
                        isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textPrimary
                    )

                // Suggested badge
                if isSuggested {
                    Text("Suggested")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.accentMuted)
                }
            }
            .padding(Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(themeManager.currentTheme.cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        isSelected ? themeManager.currentTheme.accent : Color.clear,
                        lineWidth: 2.5
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibleElement(
            label: "\(theme.displayName) theme. \(theme.description). \(isSuggested ? "Suggested for current time of day." : "")",
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
            backgroundColor: backgroundColor,
            cardColor: cardColor,
            textColor: textPrimary,
            accentColor: accent
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
