//
//  PrayerViewModel.swift
//  QuranNoor
//
//  Coordinates prayer times, location, mosques, and notifications
//  Updated: Migrated to @Observable with PrayerPeriod integration
//

import Foundation
import Observation

@Observable
@MainActor
class PrayerViewModel {
    // MARK: - Prayer Times State (New Architecture)

    /// Current prayer period state (replaces nextPrayer + countdown logic)
    var currentPrayerPeriod: PrayerPeriod?

    /// Today's prayer times
    var todayPrayerTimes: DailyPrayerTimes?

    /// Tomorrow's prayer times (for midnight transition)
    var tomorrowPrayerTimes: DailyPrayerTimes?

    // MARK: - Location & Mosques

    var userLocation: String = "Unknown"
    var nearbyMosques: [Mosque] = []

    // MARK: - Settings

    var selectedCalculationMethod: CalculationMethod = .isna
    var selectedMadhab: Madhab = .shafi

    // MARK: - Loading States

    var isLoadingPrayerTimes: Bool = false
    var isLoadingLocation: Bool = false
    var isLoadingMosques: Bool = false

    // MARK: - Error Handling

    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Services

    private let locationService = LocationService.shared
    private let prayerTimeService = PrayerTimeService.shared
    private let mosqueFinderService = MosqueFinderService.shared
    let notificationService = NotificationService() // Public for notification toggle

    // MARK: - Urgent Notification Tracking

    /// Tracks which prayers have had urgent notifications scheduled (to prevent duplicates)
    private var urgentNotificationsScheduled: Set<String> = []

    // MARK: - UserDefaults

    private let userDefaults = UserDefaults.standard
    private let calculationMethodKey = "selectedCalculationMethod"
    private let madhabKey = "selectedMadhab"

    // MARK: - Computed Properties (Derived from PrayerPeriod)

    /// Current prayer name (if in a prayer period)
    var currentPrayer: PrayerName? {
        currentPrayerPeriod?.currentPrayer
    }

    /// Next prayer name and time (tuple)
    var nextPrayerTuple: (name: PrayerName, time: Date)? {
        currentPrayerPeriod?.nextPrayer
    }

    /// Next prayer as PrayerTime (for backward compatibility with views)
    var nextPrayer: PrayerTime? {
        guard let tuple = nextPrayerTuple else { return nil }
        return PrayerTime(name: tuple.name, time: tuple.time)
    }

    /// Countdown string (e.g., "02:30:15")
    var countdownString: String {
        currentPrayerPeriod?.countdownString ?? ""
    }

    /// Countdown string alias for backward compatibility
    var countdown: String {
        countdownString
    }

    /// Progress through current prayer period (0.0 to 1.0)
    var periodProgress: Double {
        currentPrayerPeriod?.periodProgress ?? 0.0
    }

    /// Whether current prayer is urgent (< 30 min to deadline)
    var isUrgent: Bool {
        currentPrayerPeriod?.isUrgent ?? false
    }

    /// Formatted time remaining with context
    var formattedTimeRemaining: String {
        currentPrayerPeriod?.formattedTimeRemaining ?? ""
    }

    /// Status text for UI
    var statusText: String {
        currentPrayerPeriod?.statusText ?? ""
    }

    /// Current prayer state description
    var stateDescription: String {
        currentPrayerPeriod?.state.description ?? "Loading..."
    }

    /// Current prayer times (for backward compatibility)
    var currentPrayerTimes: DailyPrayerTimes? {
        todayPrayerTimes
    }

    /// Get progress to next prayer (for backward compatibility)
    func getProgressToNextPrayer() -> Double {
        periodProgress
    }

    // MARK: - Notification Preferences Observer
    private var notificationPreferencesObserver: NSObjectProtocol?

    // MARK: - Initializer
    init() {
        loadCalculationMethod()
        loadMadhab()
        setupNotificationCategories()
        setupNotificationPreferencesObserver()
    }

    // Note: Observer cleanup is handled by NotificationCenter when object is deallocated
    // since we use addObserver with a closure that captures [weak self]

    /// Listen for notification preference changes and reschedule
    private func setupNotificationPreferencesObserver() {
        notificationPreferencesObserver = NotificationCenter.default.addObserver(
            forName: .notificationPreferencesChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.rescheduleNotifications()
            }
        }
    }

    // MARK: - Public Methods

    /// Initialize prayer times on app launch
    func initialize() async {
        await loadPrayerTimes()
        await loadTomorrowPrayerTimes()
        recalculatePeriod()
    }

    /// Load prayer times for current location
    func loadPrayerTimes() async {
        isLoadingPrayerTimes = true
        isLoadingLocation = true
        errorMessage = nil

        do {
            // Step 1: Request location permission if needed
            if !locationService.hasLocationPermission() {
                locationService.requestLocationPermission()

                // Wait efficiently for permission using exponential backoff (max 5 seconds)
                // Much more efficient than constant 0.3s polling
                var waitTime: UInt64 = 100_000_000  // Start at 0.1s
                let maxWaitTime: UInt64 = 1_000_000_000  // Max 1s between checks
                let deadline = Date().addingTimeInterval(5)

                while !locationService.hasLocationPermission() && Date() < deadline {
                    try await Task.sleep(nanoseconds: waitTime)
                    waitTime = min(waitTime * 2, maxWaitTime)  // Exponential backoff
                }

                guard locationService.hasLocationPermission() else {
                    throw LocationServiceError.permissionDenied
                }
            }

            // Step 2: Get location with city name
            let (coordinates, city) = try await locationService.getCurrentLocationWithCity()
            userLocation = city
            isLoadingLocation = false

            // Step 3: Calculate TODAY's prayer times
            let prayerTimes = try await prayerTimeService.calculatePrayerTimes(
                coordinates: coordinates,
                date: Date(), // Explicitly today
                method: selectedCalculationMethod,
                madhab: selectedMadhab
            )

            // Step 3.5: Apply manual adjustments (if any)
            let adjustedPrayerTimes = PrayerTimeAdjustmentService.shared.applyAdjustments(to: prayerTimes)
            todayPrayerTimes = adjustedPrayerTimes

            // Step 4: Schedule notifications (if enabled)
            if notificationService.isAuthorized && notificationService.notificationsEnabled {
                // Get location info for rich notifications
                let locationInfo = getLocationInfo()
                try await notificationService.schedulePrayerNotifications(
                    prayerTimes,
                    city: locationInfo.city,
                    countryCode: locationInfo.countryCode
                )
            }

            isLoadingPrayerTimes = false

        } catch {
            isLoadingPrayerTimes = false
            isLoadingLocation = false
            handleError(error)
        }
    }

    /// Load tomorrow's prayer times (for midnight transition)
    func loadTomorrowPrayerTimes() async {
        guard let coordinates = locationService.currentLocation else {
            print("⚠️ No location available, skipping tomorrow's prayer times")
            return
        }

        do {
            // Calculate TOMORROW's prayer times
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let tomorrowPrayers = try await prayerTimeService.calculatePrayerTimes(
                coordinates: coordinates,
                date: tomorrow,
                method: selectedCalculationMethod,
                madhab: selectedMadhab
            )

            // Apply manual adjustments (if any)
            let adjustedTomorrowPrayers = PrayerTimeAdjustmentService.shared.applyAdjustments(to: tomorrowPrayers)
            tomorrowPrayerTimes = adjustedTomorrowPrayers
            print("✅ Tomorrow's prayer times loaded successfully (with adjustments if configured)")

        } catch {
            print("⚠️ Failed to fetch tomorrow's prayers: \(error.localizedDescription)")
            // Not critical - will fetch when needed
        }
    }

    /// Recalculate the current prayer period
    func recalculatePeriod() {
        guard let today = todayPrayerTimes else {
            print("⚠️ Cannot recalculate period: no today's prayer times")
            return
        }

        currentPrayerPeriod = PrayerPeriodCalculator.calculate(
            today: today,
            tomorrow: tomorrowPrayerTimes
        )

        print("📅 Prayer period recalculated: \(currentPrayerPeriod?.state.description ?? "Unknown")")
        print("⏱️ Countdown: \(countdownString)")
        print("📊 Progress: \(String(format: "%.1f%%", periodProgress * 100))")
        print("🚨 Urgent: \(isUrgent)")

        // Check and schedule urgent notifications
        checkAndScheduleUrgentNotification()
    }

    /// Check if we need to schedule urgent notification (30 min before deadline)
    func checkAndScheduleUrgentNotification() {
        guard let period = currentPrayerPeriod,
              let today = todayPrayerTimes else {
            return
        }

        // Only schedule during active prayer periods
        guard case .inProgress(let prayer, let deadline) = period.state else {
            return
        }

        // Check if urgent notifications are enabled for this prayer
        let prefs = NotificationPreferencesService.shared
        guard prefs.isUrgentNotificationEnabled(for: prayer) else {
            print("⏭️ Skipping urgent notification for \(prayer.displayName) (disabled in preferences)")
            return
        }

        // Create unique identifier for this prayer+deadline combination
        let notificationKey = "\(prayer.rawValue)-\(deadline.timeIntervalSince1970)"

        // Don't schedule if already scheduled
        guard !urgentNotificationsScheduled.contains(notificationKey) else {
            return
        }

        // Calculate time until deadline
        let timeRemaining = deadline.timeIntervalSince(Date())

        // Only schedule if deadline is > 30 minutes away
        // (If < 30 min, notification time would be in the past)
        guard timeRemaining > 1800 else { // 30 minutes = 1800 seconds
            return
        }

        // Determine if this is midnight deadline (Isha)
        let isMidnight = prayer == .isha && today.midnight != nil

        // Schedule the notification
        Task {
            do {
                try await notificationService.scheduleUrgentNotification(
                    for: prayer,
                    deadline: deadline,
                    isMidnight: isMidnight
                )

                // Mark as scheduled
                urgentNotificationsScheduled.insert(notificationKey)

                print("🚨 Urgent notification scheduled for \(prayer.displayName) at \(deadline)")
            } catch {
                print("⚠️ Failed to schedule urgent notification: \(error.localizedDescription)")
            }
        }
    }

    /// Reset urgent notification tracking (call at midnight or when prayer completes)
    func resetUrgentNotificationTracking() {
        urgentNotificationsScheduled.removeAll()
    }

    /// Check if we need to transition to next day (called on foreground)
    func checkIfNeedsDayTransition() async {
        guard let today = todayPrayerTimes else { return }

        // If today's prayer times are no longer for today, reload
        if !Calendar.current.isDateInToday(today.date) {
            print("🌙 Day transition detected, reloading prayer times...")
            await loadPrayerTimes()
            await loadTomorrowPrayerTimes()
            recalculatePeriod()
        }
    }

    /// Refresh prayer times (called by pull-to-refresh)
    func refreshPrayerTimes() async {
        await loadPrayerTimes()
        await loadTomorrowPrayerTimes()
        recalculatePeriod()
    }

    /// Find mosques near current location
    func findNearbyMosques() async {
        guard let location = locationService.currentLocation else {
            errorMessage = "Location not available. Please enable location services."
            showError = true
            return
        }

        isLoadingMosques = true
        errorMessage = nil

        do {
            let mosques = try await mosqueFinderService.findNearbyMosques(
                coordinates: location,
                radiusInMeters: 5000 // 5km radius
            )
            nearbyMosques = mosques
            isLoadingMosques = false
        } catch {
            isLoadingMosques = false
            handleError(error)
        }
    }

    /// Change calculation method and recalculate
    func changeCalculationMethod(_ method: CalculationMethod) async {
        selectedCalculationMethod = method
        saveCalculationMethod()
        await loadPrayerTimes()
        await loadTomorrowPrayerTimes()
        recalculatePeriod()
    }

    /// Change madhab and recalculate
    func changeMadhab(_ madhab: Madhab) async {
        selectedMadhab = madhab
        saveMadhab()
        await loadPrayerTimes()
        await loadTomorrowPrayerTimes()
        recalculatePeriod()
    }

    /// Toggle prayer notifications (legacy - prefer setNotificationsEnabled for explicit state setting)
    func toggleNotifications() async {
        let newState = !notificationService.notificationsEnabled
        await setNotificationsEnabled(newState)
    }

    /// Set notifications enabled/disabled explicitly
    /// This method ALWAYS saves the preference, even if prayer times aren't loaded yet
    func setNotificationsEnabled(_ enabled: Bool) async {
        do {
            // Request permission if enabling and not yet authorized
            if enabled && !notificationService.isAuthorized {
                let granted = try await notificationService.requestPermission()
                if !granted {
                    throw NotificationError.permissionDenied
                }
            }

            // Set the state
            notificationService.notificationsEnabled = enabled

            // ALWAYS save the preference (this is critical!)
            notificationService.saveNotificationSettings()

            // Schedule or cancel notifications if we have prayer times
            if let prayerTimes = todayPrayerTimes {
                if enabled {
                    // Enable - schedule notifications
                    let locationInfo = getLocationInfo()
                    try await notificationService.schedulePrayerNotifications(
                        prayerTimes,
                        city: locationInfo.city,
                        countryCode: locationInfo.countryCode
                    )
                } else {
                    // Disable - cancel notifications
                    await notificationService.cancelPrayerNotifications()
                }
            }
        } catch {
            handleError(error)
        }
    }

    /// Reschedule notifications (called when preferences change)
    func rescheduleNotifications() async {
        guard notificationService.isAuthorized,
              notificationService.notificationsEnabled,
              let prayerTimes = todayPrayerTimes else {
            print("⏭️ Skipping reschedule: not authorized, not enabled, or no prayer times")
            return
        }

        let locationInfo = getLocationInfo()
        do {
            try await notificationService.schedulePrayerNotifications(
                prayerTimes,
                city: locationInfo.city,
                countryCode: locationInfo.countryCode
            )
            print("✅ Notifications rescheduled after preference change")
        } catch {
            print("⚠️ Failed to reschedule notifications: \(error.localizedDescription)")
        }
    }

    /// Get formatted location info for notifications
    /// - Returns: Tuple with (city, countryCode) for notification titles
    func getLocationInfo() -> (city: String, countryCode: String) {
        let city = locationService.cityName ?? userLocation
        let country = locationService.countryName ?? "Unknown"

        // Convert country name to code (simplified - can be enhanced)
        let countryCode = convertToCountryCode(country)

        return (city, countryCode)
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print("❌ PrayerViewModel error: \(error.localizedDescription)")
    }

    private func setupNotificationCategories() {
        notificationService.registerNotificationCategories()
    }

    /// Convert country name to 2-letter country code
    private func convertToCountryCode(_ countryName: String) -> String {
        // Common countries mapping
        let countryMappings: [String: String] = [
            "United Kingdom": "GB",
            "United States": "US",
            "Canada": "CA",
            "Australia": "AU",
            "Saudi Arabia": "SA",
            "United Arab Emirates": "AE",
            "Pakistan": "PK",
            "India": "IN",
            "Malaysia": "MY",
            "Indonesia": "ID",
            "Turkey": "TR",
            "Egypt": "EG",
            "Morocco": "MA",
            "Algeria": "DZ",
            "Tunisia": "TN",
            "France": "FR",
            "Germany": "DE",
            "Netherlands": "NL",
            "Belgium": "BE",
            "Sweden": "SE",
            "Norway": "NO",
            "Denmark": "DK"
        ]

        return countryMappings[countryName] ?? "Unknown"
    }

    // MARK: - UserDefaults

    private func loadCalculationMethod() {
        if let methodString = userDefaults.string(forKey: calculationMethodKey),
           let method = CalculationMethod(rawValue: methodString) {
            selectedCalculationMethod = method
        }
    }

    private func saveCalculationMethod() {
        userDefaults.set(selectedCalculationMethod.rawValue, forKey: calculationMethodKey)
    }

    private func loadMadhab() {
        if let madhabString = userDefaults.string(forKey: madhabKey),
           let saved = Madhab(rawValue: madhabString) {
            selectedMadhab = saved
        }
    }

    private func saveMadhab() {
        userDefaults.set(selectedMadhab.rawValue, forKey: madhabKey)
    }
}
