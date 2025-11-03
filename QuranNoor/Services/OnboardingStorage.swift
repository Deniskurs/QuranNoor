//
//  OnboardingStorage.swift
//  QuranNoor
//
//  Created by Claude on 11/3/24.
//  Handles persistence of onboarding state using UserDefaults

import Foundation

/// Manages persistence of onboarding state
final class OnboardingStorage: OnboardingStorageProtocol {

    static let `default` = OnboardingStorage()

    // MARK: - Constants

    private let userDefaults: UserDefaults
    private let stateKey = "onboarding_state_v2"
    private let completionKey = "hasCompletedOnboarding"
    private let maxStateAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - State Management

    /// Save onboarding state to UserDefaults
    func save(_ state: OnboardingState) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            let encoded = try encoder.encode(state)
            userDefaults.set(encoded, forKey: stateKey)

            #if DEBUG
            print("💾 Onboarding state saved: step \(state.currentStep.rawValue)")
            #endif
        } catch {
            print("⚠️ Failed to save onboarding state: \(error)")
        }
    }

    /// Load onboarding state from UserDefaults
    func loadState() -> OnboardingState? {
        guard let data = userDefaults.data(forKey: stateKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let state = try decoder.decode(OnboardingState.self, from: data)

            // Check if state is stale (older than 7 days)
            if Date().timeIntervalSince(state.timestamp) > maxStateAge {
                #if DEBUG
                print("🗑️ Onboarding state is stale (>7 days), clearing")
                #endif
                clearState()
                return nil
            }

            // Don't resume if already completed
            if state.isComplete {
                return nil
            }

            #if DEBUG
            print("📂 Onboarding state loaded: step \(state.currentStep.rawValue)")
            #endif

            return state
        } catch {
            print("⚠️ Failed to load onboarding state: \(error)")
            clearState() // Clear corrupted data
            return nil
        }
    }

    /// Save onboarding completion status
    func saveCompletionStatus(_ completed: Bool) {
        userDefaults.set(completed, forKey: completionKey)

        #if DEBUG
        print("✅ Onboarding completion status saved: \(completed)")
        #endif
    }

    /// Check if onboarding has been completed
    func isCompleted() -> Bool {
        return userDefaults.bool(forKey: completionKey)
    }

    /// Clear saved onboarding state
    func clearState() {
        userDefaults.removeObject(forKey: stateKey)

        #if DEBUG
        print("🗑️ Onboarding state cleared")
        #endif
    }

    /// Reset onboarding completely (for testing/debugging)
    func resetOnboarding() {
        clearState()
        userDefaults.set(false, forKey: completionKey)

        #if DEBUG
        print("🔄 Onboarding completely reset")
        #endif
    }
}

// MARK: - User Defaults Migration

/// Handles migration of UserDefaults schema between versions
final class UserDefaultsMigrator {

    enum Version: Int {
        case v1 = 1  // Initial version
        case v2 = 2  // Added permission persistence
        case v3 = 3  // Added resume state and express mode

        static let current: Version = .v3
    }

    private let userDefaults: UserDefaults
    private let versionKey = "user_defaults_version"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Perform migration if needed
    func migrateIfNeeded() {
        let currentVersion = userDefaults.integer(forKey: versionKey)
        let targetVersion = Version.current.rawValue

        guard currentVersion < targetVersion else {
            return
        }

        print("📦 Migrating UserDefaults from v\(currentVersion) to v\(targetVersion)")

        // Apply migrations sequentially
        if currentVersion < Version.v2.rawValue {
            migrateToV2()
        }

        if currentVersion < Version.v3.rawValue {
            migrateToV3()
        }

        // Save new version
        userDefaults.set(targetVersion, forKey: versionKey)
        print("✅ UserDefaults migration complete")
    }

    private func migrateToV2() {
        print("📦 Migrating to v2: Adding permission persistence")

        // Migrate old permission flags if they exist
        _ = userDefaults.bool(forKey: "hasLocationPermission")
        _ = userDefaults.bool(forKey: "hasNotificationPermission")

        // These will be handled by PermissionManager going forward
        // Just clean up old keys
        userDefaults.removeObject(forKey: "hasLocationPermission")
        userDefaults.removeObject(forKey: "hasNotificationPermission")

        print("✅ v2 migration complete")
    }

    private func migrateToV3() {
        print("📦 Migrating to v3: Adding resume state")

        // No specific migration needed - new fields have defaults
        // Old OnboardingState will decode with missing fields as nil

        print("✅ v3 migration complete")
    }
}

// MARK: - Property Wrapper for Codable UserDefaults

/// Property wrapper for storing Codable types in UserDefaults
@propertyWrapper
struct UserDefaultsCodable<T: Codable> {
    let key: String
    let defaultValue: T
    let storage: UserDefaults

    init(
        key: String,
        defaultValue: T,
        storage: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: T {
        get {
            guard let data = storage.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                storage.set(encoded, forKey: key)
            }
        }
    }
}

// MARK: - Preferences Container

/// Container for all onboarding-related preferences
final class OnboardingPreferences {
    static let shared = OnboardingPreferences()

    private let userDefaults = UserDefaults.standard

    /// Selected prayer calculation method
    var calculationMethod: String {
        get { userDefaults.string(forKey: "prayerCalculationMethod") ?? "ISNA" }
        set { userDefaults.set(newValue, forKey: "prayerCalculationMethod") }
    }

    /// Selected theme mode
    var themeMode: String {
        get { userDefaults.string(forKey: "themeMode") ?? "light" }
        set { userDefaults.set(newValue, forKey: "themeMode") }
    }

    /// Enable Qadha counter
    var enableQadhaCounter: Bool {
        get { userDefaults.bool(forKey: "enableQadhaCounter") }
        set { userDefaults.set(newValue, forKey: "enableQadhaCounter") }
    }

    /// Use Hijri calendar by default
    var useHijriCalendar: Bool {
        get { userDefaults.bool(forKey: "useHijriCalendar") }
        set { userDefaults.set(newValue, forKey: "useHijriCalendar") }
    }

    /// Show transliteration
    var showTransliteration: Bool {
        get { userDefaults.bool(forKey: "showTransliteration") }
        set { userDefaults.set(newValue, forKey: "showTransliteration") }
    }

    /// Clear all onboarding preferences
    func clearAll() {
        userDefaults.removeObject(forKey: "prayerCalculationMethod")
        userDefaults.removeObject(forKey: "themeMode")
        userDefaults.removeObject(forKey: "enableQadhaCounter")
        userDefaults.removeObject(forKey: "useHijriCalendar")
        userDefaults.removeObject(forKey: "showTransliteration")
    }
}
