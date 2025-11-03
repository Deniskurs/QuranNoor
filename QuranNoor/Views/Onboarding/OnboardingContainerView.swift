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
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var coordinator: OnboardingCoordinator
    @StateObject private var permissionManager = PermissionManager.shared

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

            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressView(
                    currentStep: coordinator.currentStep.rawValue + 1,
                    totalSteps: OnboardingCoordinator.OnboardingStep.allCases.count
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Skip button (visible until last step) - Native iOS 26 style
                if coordinator.currentStep.rawValue < OnboardingCoordinator.OnboardingStep.allCases.count - 1 {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            skipOnboarding()
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                    .frame(height: 44) // Standard iOS touch target
                } else {
                    Spacer()
                        .frame(height: 44)
                }

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

                    // Step 1: Value Proposition (interactive demos)
                    ValuePropositionView(coordinator: coordinator)
                        .tag(1)

                    // Step 2: Location & Calculation (combined view)
                    LocationAndCalculationView(
                        coordinator: coordinator,
                        permissionManager: permissionManager
                    )
                    .tag(2)

                    // Step 3: Notifications
                    NotificationPermissionView(
                        coordinator: coordinator,
                        permissionManager: permissionManager
                    )
                    .tag(3)

                    // Step 4: Personalization (using ThemeSelectionView temporarily)
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
                        .tint(AppColors.primary.teal)
                    }

                    Spacer()

                    // Next/Get Started button
                    if coordinator.currentStep.rawValue < OnboardingCoordinator.OnboardingStep.allCases.count - 1 {
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
                        .tint(AppColors.primary.green)
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
        // Play onboarding completion feedback (success + startup sound)
        feedbackCoordinator.playOnboardingComplete()

        // Dismiss onboarding after brief delay to allow startup sound to play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                dismiss()
            }
        }
    }
}

// MARK: - Progress View Component

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 4) {
            // Progress text
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)

                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.primary.green)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.smooth(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
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
        .environmentObject(ThemeManager())
}
