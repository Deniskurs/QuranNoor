//
//  OnboardingCoordinator.swift
//  QuranNoor
//
//  Created by Claude on 11/3/24.
//  Manages onboarding state, navigation, and persistence

import SwiftUI
import Observation

// MARK: - Cached Formatter (Performance: avoid repeated allocation)
private let onboardingISOFormatter = ISO8601DateFormatter()

/// Centralized coordinator for onboarding flow using @Observable pattern
@Observable
final class OnboardingCoordinator {

    // MARK: - Onboarding Steps

    enum OnboardingStep: Int, Codable, CaseIterable, Identifiable {
        case welcome = 0
        case valueProposition = 1
        case locationAndCalculation = 2
        case notifications = 3
        case personalization = 4
        case themeSelection = 5

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .welcome:
                return "Welcome"
            case .valueProposition:
                return "Discover Features"
            case .locationAndCalculation:
                return "Prayer Times Setup"
            case .notifications:
                return "Prayer Reminders"
            case .personalization:
                return "Personalize"
            case .themeSelection:
                return "Choose Theme"
            }
        }

        var accessibilityDescription: String {
            switch self {
            case .welcome:
                return "Welcome to Qur'an Noor, your spiritual companion"
            case .valueProposition:
                return "Explore the app's key features interactively"
            case .locationAndCalculation:
                return "Set up your location for accurate prayer times"
            case .notifications:
                return "Enable notifications to never miss a prayer"
            case .personalization:
                return "Customize your app experience with your name"
            case .themeSelection:
                return "Select your preferred reading theme"
            }
        }
    }

    // MARK: - Permission States

    enum PermissionState: String, Codable {
        case notRequested
        case granted
        case denied
        case restricted

        var isGranted: Bool {
            self == .granted
        }

        var canRetry: Bool {
            self == .notRequested
        }

        var needsSettingsRedirect: Bool {
            self == .denied
        }

        var description: String {
            rawValue
        }
    }

    // MARK: - State Properties

    /// Current step in onboarding flow
    var currentStep: OnboardingStep

    /// Location permission status
    var locationPermission: PermissionState

    /// Notification permission status
    var notificationPermission: PermissionState

    /// Selected prayer calculation method
    var selectedCalculationMethod: String

    /// Selected theme mode
    var selectedTheme: String

    /// Enable Qadha counter
    var enableQadhaCounter: Bool

    /// Use Hijri calendar by default
    var useHijriCalendar: Bool

    /// Show transliteration
    var showTransliteration: Bool

    /// Onboarding completion status
    var isComplete: Bool

    /// Express mode (skip optional steps)
    var isExpressMode: Bool

    // MARK: - Tracking Properties

    /// Timestamp when onboarding started
    private(set) var startTime: Date

    /// Duration spent on each step
    private var stepDurations: [OnboardingStep: TimeInterval] = [:]

    /// Timestamp when current step was entered
    private var currentStepStartTime: Date

    // MARK: - Dependencies

    private let storage: OnboardingStorageProtocol
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - Initialization

    init(
        storage: OnboardingStorageProtocol = OnboardingStorage.default,
        analyticsService: AnalyticsServiceProtocol = MockAnalyticsService.shared
    ) {
        self.storage = storage
        self.analyticsService = analyticsService

        // Load persisted state or use defaults
        if let savedState = storage.loadState() {
            self.currentStep = savedState.currentStep
            self.locationPermission = savedState.locationPermission
            self.notificationPermission = savedState.notificationPermission
            self.selectedCalculationMethod = savedState.calculationMethod
            self.selectedTheme = savedState.theme
            self.enableQadhaCounter = savedState.enableQadhaCounter
            self.useHijriCalendar = savedState.useHijriCalendar
            self.showTransliteration = savedState.showTransliteration
            self.isComplete = savedState.isComplete
            self.isExpressMode = savedState.isExpressMode
            self.startTime = savedState.startTime
        } else {
            // Initialize with defaults
            self.currentStep = .welcome
            self.locationPermission = .notRequested
            self.notificationPermission = .notRequested
            self.selectedCalculationMethod = "ISNA"
            self.selectedTheme = "light"
            self.enableQadhaCounter = true
            self.useHijriCalendar = false
            self.showTransliteration = false
            self.isComplete = false
            self.isExpressMode = false
            self.startTime = Date()
        }

        self.currentStepStartTime = Date()

        // Track onboarding start
        if !isComplete {
            trackOnboardingStarted()
        }
    }

    // MARK: - Navigation

    /// Advance to next step in onboarding
    func advance() {
        guard !isComplete else { return }

        // Track step completion
        let duration = Date().timeIntervalSince(currentStepStartTime)
        stepDurations[currentStep] = duration
        trackStepCompleted(currentStep, duration: duration)

        // Determine next step
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
            currentStepStartTime = Date()
            trackStepViewed(currentStep)
        } else {
            // Reached end of flow
            complete()
        }

        saveState()
    }

    /// Go back to previous step
    func goBack() {
        guard currentStep.rawValue > 0 else { return }

        if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previousStep
            currentStepStartTime = Date()
            saveState()

            analyticsService.track(event: .onboardingNavigatedBack, properties: [
                "from_step": currentStep.title,
                "to_step": previousStep.title
            ])
        }
    }

    /// Skip remaining onboarding and use defaults
    func skip() {
        analyticsService.track(event: .onboardingSkipped, properties: [
            "from_step": currentStep.title,
            "step_index": "\(currentStep.rawValue)"
        ])
        complete()
    }

    /// Start express mode (use defaults, skip optional steps)
    func startExpressMode() {
        isExpressMode = true
        analyticsService.track(event: .onboardingExpressModeSelected, properties: [:])

        // Jump to first required step (location)
        currentStep = .locationAndCalculation
        saveState()
    }

    /// Mark onboarding as complete
    func complete() {
        isComplete = true

        let totalDuration = Date().timeIntervalSince(startTime)
        let stepsCompleted = currentStep.rawValue + 1

        trackOnboardingCompleted(
            totalDuration: totalDuration,
            stepsCompleted: stepsCompleted
        )

        storage.saveCompletionStatus(true)
        storage.clearState() // Clear saved progress
    }

    // MARK: - Permission Management

    /// Update location permission status
    /// Note: Views are responsible for calling advance() after permission is granted
    func updateLocationPermission(_ status: PermissionState) {
        locationPermission = status
        saveState()

        analyticsService.track(event: .permissionChanged, properties: [
            "type": "location",
            "status": status.description
        ])
    }

    /// Update notification permission status
    /// Note: Views are responsible for calling advance() after permission is granted
    func updateNotificationPermission(_ status: PermissionState) {
        notificationPermission = status
        saveState()

        analyticsService.track(event: .permissionChanged, properties: [
            "type": "notification",
            "status": status.description
        ])
    }

    // MARK: - Calculation Method

    /// Get recommended calculation method based on location
    func recommendedCalculationMethod(for countryCode: String?) -> String {
        guard let country = countryCode?.uppercased() else {
            return "MWL" // Default fallback
        }

        switch country {
        case "US", "CA":
            return "ISNA"
        case "SA":
            return "Umm al-Qura"
        case "EG", "SD":
            return "Egyptian"
        case "PK", "IN", "BD":
            return "Karachi"
        case "IR":
            return "Tehran"
        case "GB", "FR", "DE", "IT", "ES":
            return "MWL"
        default:
            return "MWL"
        }
    }

    // MARK: - Theme

    /// Get suggested theme based on time of day
    func suggestedTheme() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 6 && hour < 18 {
            return "light"
        } else if hour >= 22 || hour < 5 {
            return "night" // OLED for battery saving
        } else {
            return "dark"
        }
    }

    // MARK: - State Persistence

    private func saveState() {
        let state = OnboardingState(
            currentStep: currentStep,
            locationPermission: locationPermission,
            notificationPermission: notificationPermission,
            calculationMethod: selectedCalculationMethod,
            theme: selectedTheme,
            enableQadhaCounter: enableQadhaCounter,
            useHijriCalendar: useHijriCalendar,
            showTransliteration: showTransliteration,
            isComplete: isComplete,
            isExpressMode: isExpressMode,
            startTime: startTime
        )
        storage.save(state)
    }

    // MARK: - Analytics Tracking

    private func trackOnboardingStarted() {
        analyticsService.track(event: .onboardingStarted, properties: [
            "timestamp": onboardingISOFormatter.string(from: Date())
        ])
    }

    private func trackStepViewed(_ step: OnboardingStep) {
        analyticsService.track(event: .onboardingStepViewed, properties: [
            "step_index": "\(step.rawValue)",
            "step_name": step.title
        ])
    }

    private func trackStepCompleted(_ step: OnboardingStep, duration: TimeInterval) {
        analyticsService.track(event: .onboardingStepCompleted, properties: [
            "step_index": "\(step.rawValue)",
            "step_name": step.title,
            "duration_seconds": "\(Int(duration))"
        ])
    }

    private func trackOnboardingCompleted(totalDuration: TimeInterval, stepsCompleted: Int) {
        analyticsService.track(event: .onboardingCompleted, properties: [
            "total_duration_seconds": "\(Int(totalDuration))",
            "steps_completed": "\(stepsCompleted)",
            "total_steps": "\(OnboardingStep.allCases.count)",
            "completion_rate": String(format: "%.2f", Double(stepsCompleted) / Double(OnboardingStep.allCases.count)),
            "location_permission": locationPermission.description,
            "notification_permission": notificationPermission.description,
            "calculation_method": selectedCalculationMethod,
            "theme": selectedTheme,
            "express_mode": "\(isExpressMode)"
        ])
    }
}

// MARK: - Onboarding State Model

struct OnboardingState: Codable {
    let currentStep: OnboardingCoordinator.OnboardingStep
    let locationPermission: OnboardingCoordinator.PermissionState
    let notificationPermission: OnboardingCoordinator.PermissionState
    let calculationMethod: String
    let theme: String
    let enableQadhaCounter: Bool
    let useHijriCalendar: Bool
    let showTransliteration: Bool
    let isComplete: Bool
    let isExpressMode: Bool
    let startTime: Date
    let timestamp: Date

    init(
        currentStep: OnboardingCoordinator.OnboardingStep,
        locationPermission: OnboardingCoordinator.PermissionState,
        notificationPermission: OnboardingCoordinator.PermissionState,
        calculationMethod: String,
        theme: String,
        enableQadhaCounter: Bool,
        useHijriCalendar: Bool,
        showTransliteration: Bool,
        isComplete: Bool,
        isExpressMode: Bool,
        startTime: Date
    ) {
        self.currentStep = currentStep
        self.locationPermission = locationPermission
        self.notificationPermission = notificationPermission
        self.calculationMethod = calculationMethod
        self.theme = theme
        self.enableQadhaCounter = enableQadhaCounter
        self.useHijriCalendar = useHijriCalendar
        self.showTransliteration = showTransliteration
        self.isComplete = isComplete
        self.isExpressMode = isExpressMode
        self.startTime = startTime
        self.timestamp = Date()
    }
}

// MARK: - Protocol Definitions

/// Protocol for onboarding storage (enables testing with mocks)
protocol OnboardingStorageProtocol {
    func save(_ state: OnboardingState)
    func loadState() -> OnboardingState?
    func saveCompletionStatus(_ completed: Bool)
    func isCompleted() -> Bool
    func clearState()
}

/// Protocol for analytics service (enables testing with mocks)
protocol AnalyticsServiceProtocol {
    func track(event: AnalyticsEvent, properties: [String: String])
}

/// Analytics events for onboarding
enum AnalyticsEvent {
    case onboardingStarted
    case onboardingStepViewed
    case onboardingStepCompleted
    case onboardingSkipped
    case onboardingCompleted
    case onboardingNavigatedBack
    case onboardingExpressModeSelected
    case permissionChanged
    case themeSelected
    case calculationMethodSelected

    var name: String {
        switch self {
        case .onboardingStarted: return "onboarding_started"
        case .onboardingStepViewed: return "onboarding_step_viewed"
        case .onboardingStepCompleted: return "onboarding_step_completed"
        case .onboardingSkipped: return "onboarding_skipped"
        case .onboardingCompleted: return "onboarding_completed"
        case .onboardingNavigatedBack: return "onboarding_navigated_back"
        case .onboardingExpressModeSelected: return "onboarding_express_mode_selected"
        case .permissionChanged: return "permission_changed"
        case .themeSelected: return "theme_selected"
        case .calculationMethodSelected: return "calculation_method_selected"
        }
    }
}

/// Mock analytics service for development (replace with real implementation later)
final class MockAnalyticsService: AnalyticsServiceProtocol {
    static let shared = MockAnalyticsService()

    private(set) var trackedEvents: [(event: AnalyticsEvent, properties: [String: String])] = []

    func track(event: AnalyticsEvent, properties: [String: String]) {
        trackedEvents.append((event, properties))
        #if DEBUG
        print("📊 Analytics: \(event.name) - \(properties)")
        #endif
    }
}
