//
//  OnboardingContainerView.swift
//  QuranNoor
//
//  Main onboarding container with page navigation
//  Redesigned for iOS 26 with native buttons, audio feedback, and centralized state management
//

import SwiftUI

struct OnboardingContainerView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    // AppStorage binding to directly update completion status
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var coordinator: OnboardingCoordinator
    @State private var permissionManager = PermissionManager.shared

    // Audio & Haptic coordinator
    private let feedbackCoordinator = AudioHapticCoordinator.shared

    // MARK: - Initialization

    init(coordinator: OnboardingCoordinator? = nil) {
        _coordinator = State(initialValue: coordinator ?? OnboardingCoordinator())
    }

    // MARK: - Computed Properties

    /// Determines if Continue button should be shown
    /// Hidden on permission steps until permission is granted
    private var shouldShowContinueButton: Bool {
        let currentStepIndex = coordinator.currentStep.rawValue
        let totalSteps = OnboardingCoordinator.OnboardingStep.allCases.count

        // Don't show on last two steps (personalization and theme have their own buttons)
        guard currentStepIndex < totalSteps - 2 else {
            return false
        }

        // Step 1 = Location permission (locationAndCalculation)
        let isLocationStep = (currentStepIndex == 1)
        // Step 2 = Notification permission
        let isNotificationStep = (currentStepIndex == 2)

        // On permission steps, hide container button
        // Location step has embedded Continue button (after method selection)
        if isLocationStep {
            return false
        }
        // Notification step: show Continue only if permission granted
        else if isNotificationStep {
            return permissionManager.notificationStatus.isGranted
        }

        // On non-permission steps, always show Continue
        return true
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            GradientBackground(style: .home, opacity: 0.15)

            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressView(
                    currentStep: coordinator.currentStep.rawValue + 1,
                    totalSteps: OnboardingCoordinator.OnboardingStep.allCases.count
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Spacer for consistent top padding
                Spacer()
                    .frame(height: 44)

                // Page content - Map coordinator steps to views
                TabView(selection: Binding(
                    get: { coordinator.currentStep.rawValue },
                    set: { newValue in
                        if OnboardingCoordinator.OnboardingStep(rawValue: newValue) != nil {
                            // Manual swipe - update coordinator
                            if newValue > coordinator.currentStep.rawValue {
                                coordinator.advance()
                            } else if newValue < coordinator.currentStep.rawValue {
                                coordinator.goBack()
                            }
                        }
                    }
                )) {
                    // Step 0: Welcome
                    WelcomeView(coordinator: coordinator)
                        .tag(0)

                    // Step 1: Location & Calculation (combined view)
                    LocationAndCalculationView(
                        coordinator: coordinator,
                        permissionManager: permissionManager
                    )
                    .tag(1)

                    // Step 2: Notifications
                    NotificationPermissionView(
                        coordinator: coordinator,
                        permissionManager: permissionManager
                    )
                    .tag(2)

                    // Step 3: Personalization (name entry)
                    PersonalizationView(
                        coordinator: coordinator
                    )
                    .tag(3)

                    // Step 4: Theme Selection
                    ThemeSelectionView(
                        coordinator: coordinator
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Hide default page indicator
                .animation(.smooth(duration: 0.3), value: coordinator.currentStep)

                // Navigation buttons - Native iOS 26 style
                HStack(spacing: 16) {
                    // Back button (not on first page)
                    if coordinator.currentStep.rawValue > 0 {
                        Button {
                            previousPage()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.large)
                        .tint(themeManager.currentTheme.accentMuted)
                    }

                    Spacer()

                    // Next/Get Started button (conditionally shown)
                    // Hidden on permission steps until permission is granted
                    if shouldShowContinueButton {
                        Button {
                            nextPage()
                        } label: {
                            Label {
                                Text("Continue")
                            } icon: {
                                Image(systemName: "chevron.right")
                            }
                            .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(themeManager.currentTheme.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .padding(.bottom, 8)
            }
        }
        .interactiveDismissDisabled()  // Prevent swipe to dismiss
        .onChange(of: coordinator.currentStep) { oldStep, newStep in
            // Play selection haptic when step changes
            if oldStep != newStep {
                HapticManager.shared.trigger(.selection)
            }
        }
        .onChange(of: coordinator.isComplete) { _, isComplete in
            if isComplete {
                completeOnboarding()
            }
        }
    }

    // MARK: - Methods

    /// Navigate to next page with audio and haptic feedback
    private func nextPage() {
        withAnimation(.smooth(duration: 0.3)) {
            coordinator.advance()
            // Play confirm sound with haptic
            feedbackCoordinator.playConfirm()
        }
    }

    /// Navigate to previous page with audio and haptic feedback
    private func previousPage() {
        withAnimation(.smooth(duration: 0.3)) {
            coordinator.goBack()
            // Play back sound with haptic
            feedbackCoordinator.playBack()
        }
    }

    /// Skip to complete onboarding with audio and haptic feedback
    private func skipOnboarding() {
        // Play back sound for skipping
        feedbackCoordinator.playBack()

        // Skip remaining steps
        coordinator.skip()
    }

    /// Complete onboarding and transition to main app
    private func completeOnboarding() {
        // MARK: - Transfer coordinator selections to live services

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

        // 3. User name is already saved by PersonalizationView.saveName() — no action needed

        // Mark onboarding as complete (coordinator saves to storage)
        coordinator.complete()

        // Play onboarding completion feedback (success + startup sound)
        feedbackCoordinator.playOnboardingComplete()

        // Update AppStorage to trigger app transition
        // Brief delay allows startup sound to play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Progress View Component

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 4) {
            // Progress text
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textTertiary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeManager.currentTheme.textTertiary.opacity(0.3))
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeManager.currentTheme.accent)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.smooth(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
            .accessibilityLabel("Onboarding progress")
            .accessibilityValue("\(Int(progress * 100)) percent complete, step \(currentStep) of \(totalSteps)")
        }
        .padding(.vertical, 8)
    }

    private var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView()
        .environment(ThemeManager())
}
