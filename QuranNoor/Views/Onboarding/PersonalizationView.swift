//
//  PersonalizationView.swift
//  QuranNoor
//
//  Name entry screen for personalized greeting
//

import SwiftUI

struct PersonalizationView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ObservedObject private var accessibilityHelper = AccessibilityHelper.shared

    let coordinator: OnboardingCoordinator

    @State private var userName: String = ""
    @State private var showPreview = true
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Initialization

    init(coordinator: OnboardingCoordinator) {
        self.coordinator = coordinator
        // Load existing name if available
        _userName = State(initialValue: UserDefaults.standard.string(forKey: "userName") ?? "")
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.currentTheme.accentSecondary)
                        .accessibilityHidden(true)

                    ThemedText("What's Your Name?", style: .title)
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                        .accessibilityAddTraits(.isHeader)

                    ThemedText.body("We'll use this to personalize your experience")
                        .multilineTextAlignment(.center)
                        .reducedTransparency(opacity: 0.8)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                // MARK: - Name Input
                VStack(spacing: 16) {
                    LiquidGlassCardView(showPattern: false, intensity: .moderate) {
                        VStack(alignment: .leading, spacing: 12) {
                            ThemedText.caption("YOUR NAME (OPTIONAL)")
                                .foregroundColor(themeManager.currentTheme.accentSecondary)

                            TextField("Enter your name", text: $userName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 18))
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.currentTheme.backgroundColor.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isTextFieldFocused ? themeManager.currentTheme.accentPrimary : themeManager.currentTheme.borderColor,
                                            lineWidth: isTextFieldFocused ? 2 : 1
                                        )
                                )
                                .focused($isTextFieldFocused)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)

                            ThemedText.caption("This helps us greet you personally throughout the app")
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                                .opacity(0.7)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // MARK: - Live Preview
                if showPreview {
                    VStack(spacing: 12) {
                        HStack {
                            ThemedText("Preview", style: .heading)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            Spacer()
                        }
                        .padding(.horizontal, 24)

                        GreetingPreviewCard(userName: userName.isEmpty ? nil : userName)
                            .padding(.horizontal, 24)
                            .transition(AccessibleTransition.scale)
                    }
                }

                // MARK: - Why Ask Section
                LiquidGlassCardView(showPattern: true, intensity: .subtle) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(themeManager.currentTheme.accentSecondary)
                            ThemedText("Why we ask", style: .heading)
                        }

                        IslamicDivider(style: .simple)

                        VStack(alignment: .leading, spacing: 12) {
                            BenefitRow(
                                icon: "heart.fill",
                                text: "Creates a personal connection with the app",
                                color: themeManager.currentTheme.accentPrimary
                            )

                            BenefitRow(
                                icon: "person.2.fill",
                                text: "Addressing by name is a Sunnah practice",
                                color: themeManager.currentTheme.accentSecondary
                            )

                            BenefitRow(
                                icon: "lock.fill",
                                text: "Your name stays private on your device",
                                color: themeManager.currentTheme.accentInteractive
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // MARK: - Continue Button
                Button {
                    saveName()
                    coordinator.advance()
                } label: {
                    Label(userName.isEmpty ? "Skip for Now" : "Continue", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(userName.isEmpty ? themeManager.currentTheme.accentSecondary : themeManager.currentTheme.accentPrimary)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .accessibleElement(
                    label: userName.isEmpty ? "Skip name entry" : "Continue with name \(userName)",
                    hint: "Double tap to \(userName.isEmpty ? "skip this step" : "continue to theme selection")",
                    traits: .isButton
                )
            }
        }
        .accessibilityPageAnnouncement("Personalization. Step 5 of 6. Enter your name for a personalized experience, or skip to continue.")
        .onAppear {
            // Delay focus to allow view to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Methods

    private func saveName() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            UserDefaults.standard.set(trimmedName, forKey: "userName")
            AudioHapticCoordinator.shared.playConfirm()
        } else {
            UserDefaults.standard.removeObject(forKey: "userName")
        }
    }
}

// MARK: - Greeting Preview Card

struct GreetingPreviewCard: View {
    let userName: String?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        LiquidGlassCardView(showPattern: true, intensity: .prominent) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(themeManager.currentTheme.accentSecondary)
                    ThemedText("How it will look", style: .caption)
                        .foregroundColor(themeManager.currentTheme.accentSecondary)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(greetingText)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ThemedText.caption("Home screen greeting")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .opacity(0.7)
                }
            }
        }
    }

    private var greetingText: String {
        if let name = userName, !name.isEmpty {
            return "As Salamu Alaykum, \(name)"
        } else {
            return "As Salamu Alaykum"
        }
    }
}

// MARK: - Benefit Row Component

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            ThemedText.caption(text)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    PersonalizationView(coordinator: OnboardingCoordinator())
        .environmentObject(ThemeManager())
}
