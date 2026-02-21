//
//  OnboardingContainerView.swift
//  QuranNoor
//
//  Main onboarding container with NavigationStack
//  3-screen flow: Welcome+Permissions → Prayer Setup → Theme & Launch

import SwiftUI

struct OnboardingContainerView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var coordinator: OnboardingCoordinator
    @State private var permissionManager = PermissionManager.shared
    @State private var navigationPath: [OnboardingCoordinator.OnboardingStep] = []

    // Audio & Haptic coordinator
    private let feedbackCoordinator = AudioHapticCoordinator.shared

    // MARK: - Initialization

    init(coordinator: OnboardingCoordinator? = nil) {
        _coordinator = State(initialValue: coordinator ?? OnboardingCoordinator())
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            GradientBackground(style: .home, opacity: 0.15)

            NavigationStack(path: $navigationPath) {
                // Root: Screen 1 - Welcome & Permissions
                WelcomePermissionsView(
                    coordinator: coordinator,
                    permissionManager: permissionManager
                )
                .navigationBarBackButtonHidden()
                .toolbar { stepIndicator }
                .navigationDestination(for: OnboardingCoordinator.OnboardingStep.self) { step in
                    destinationView(for: step)
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            // Back button
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    feedbackCoordinator.playBack()
                                    navigationPath.removeLast()
                                    coordinator.goBack()
                                } label: {
                                    Label("Back", systemImage: "chevron.left")
                                }
                                .tint(themeManager.currentTheme.accentMuted)
                            }

                            // Step indicator
                            stepIndicator
                        }
                }
            }
        }
        .interactiveDismissDisabled()
        .onChange(of: coordinator.currentStep) { oldStep, newStep in
            // Sync NavigationStack path when coordinator advances
            if newStep.rawValue > oldStep.rawValue && !navigationPath.contains(newStep) {
                navigationPath.append(newStep)
            }
        }
        .onChange(of: coordinator.isComplete) { _, isComplete in
            if isComplete {
                completeOnboarding()
            }
        }
    }

    // MARK: - Step Indicator

    @ToolbarContentBuilder
    private var stepIndicator: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            StepDotsView(
                currentStep: coordinator.currentStep.rawValue,
                totalSteps: OnboardingCoordinator.OnboardingStep.allCases.count,
                accentColor: themeManager.currentTheme.accent,
                inactiveColor: themeManager.currentTheme.textTertiary.opacity(0.4)
            )
        }
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for step: OnboardingCoordinator.OnboardingStep) -> some View {
        switch step {
        case .welcomePermissions:
            WelcomePermissionsView(
                coordinator: coordinator,
                permissionManager: permissionManager
            )
        case .prayerSetup:
            PrayerSetupView(
                coordinator: coordinator,
                permissionManager: permissionManager
            )
        case .themeAndLaunch:
            ThemeSelectionView(coordinator: coordinator)
        }
    }

    // MARK: - Completion

    /// Complete onboarding and transition to main app
    private func completeOnboarding() {
        // 1. Apply selected theme to ThemeManager
        if let theme = ThemeMode(rawValue: coordinator.selectedTheme) {
            themeManager.setTheme(theme)
        }

        // 2. Apply calculation method to UserDefaults (PrayerViewModel reads from here)
        let methodMapping: [String: String] = [
            "ISNA": "ISNA (North America)",
            "MWL": "Muslim World League",
            "Egypt": "Egyptian General Authority",
            "Egyptian": "Egyptian General Authority",
            "Makkah": "Umm al-Qura (Makkah)",
            "Umm al-Qura": "Umm al-Qura (Makkah)",
            "Karachi": "University of Islamic Sciences, Karachi",
            "Tehran": "Institute of Geophysics, Tehran",
            "Dubai": "Dubai",
            "Moonsighting": "Moonsighting Committee Worldwide"
        ]
        let methodKey = coordinator.selectedCalculationMethod
        let fullMethodName = methodMapping[methodKey] ?? methodKey
        UserDefaults.standard.set(fullMethodName, forKey: "selectedCalculationMethod")

        // 3. User name is saved by PrayerSetupView.saveName() — no action needed

        // Mark onboarding as complete
        coordinator.complete()

        // Play onboarding completion feedback
        feedbackCoordinator.playOnboardingComplete()

        // Update AppStorage to trigger app transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Step Dots View

struct StepDotsView: View {
    let currentStep: Int
    let totalSteps: Int
    let accentColor: Color
    let inactiveColor: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? accentColor : inactiveColor)
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
        .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView()
        .environment(ThemeManager())
}
