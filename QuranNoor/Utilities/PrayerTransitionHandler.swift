//
//  PrayerTransitionHandler.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  Handles automatic midnight transitions for prayer times
//

import Foundation

/// Notification posted when the Hijri date transitions at Maghrib
extension Notification.Name {
    static let hijriDateTransition = Notification.Name("hijriDateTransition")
}

/// Handles automatic day transitions at midnight
@MainActor
class PrayerTransitionHandler {

    // MARK: - Properties

    /// Weak reference to view model to avoid retain cycles
    private weak var viewModel: PrayerViewModel?

    /// Task for midnight transition (cancellable)
    private var dayTransitionTask: Task<Void, Never>?

    /// Task for periodic period recalculation
    private var recalculationTask: Task<Void, Never>?

    /// Task for Maghrib Hijri date transition
    private var maghribTransitionTask: Task<Void, Never>?

    // MARK: - Initialization

    init(viewModel: PrayerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Public Methods

    /// Start automatic midnight checking
    func start() {
        scheduleMidnightCheck()
        schedulePeriodicRecalculation()
        scheduleMaghribHijriTransition()
    }

    /// Stop all automatic tasks
    func stop() {
        dayTransitionTask?.cancel()
        recalculationTask?.cancel()
        maghribTransitionTask?.cancel()
    }

    // MARK: - Midnight Transition

    /// Schedule a task to run at midnight for day transition
    private func scheduleMidnightCheck() {
        // Cancel existing task
        dayTransitionTask?.cancel()

        // Calculate next midnight
        let calendar = Calendar.current
        let now = Date()

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return }

        // startOfDay(for:) returns non-optional Date
        let midnight = calendar.startOfDay(for: tomorrow)

        let timeUntilMidnight = midnight.timeIntervalSinceNow

        // Schedule task to run at midnight (with 5 second buffer)
        dayTransitionTask = Task {
            do {
                // Wait until midnight + 5 seconds
                let sleepDuration = UInt64((timeUntilMidnight + 5) * 1_000_000_000)
                try await Task.sleep(nanoseconds: sleepDuration)

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                // Perform transition
                await performDayTransition()

                // Reschedule for next midnight
                self.scheduleMidnightCheck()

            } catch {
                // Task was cancelled
            }
        }
    }

    /// Perform the actual day transition at midnight
    private func performDayTransition() async {
        guard let viewModel = viewModel else { return }

        // Step 1: Promote tomorrow's prayers to today
        if let tomorrow = viewModel.tomorrowPrayerTimes {
            viewModel.todayPrayerTimes = tomorrow
        } else {
            await viewModel.loadPrayerTimes()
        }

        // Step 2: Fetch new tomorrow's prayers
        await viewModel.loadTomorrowPrayerTimes()

        // Step 3: Recalculate prayer period
        viewModel.recalculatePeriod()

        // Step 3.5: Reset urgent notification tracking for new day
        viewModel.resetUrgentNotificationTracking()

        // Step 4: Update notifications for new day
        if viewModel.notificationService.isAuthorized &&
           viewModel.notificationService.notificationsEnabled,
           let todayPrayers = viewModel.todayPrayerTimes {
            do {
                // Get location info for rich notifications
                let locationInfo = viewModel.getLocationInfo()
                try await viewModel.notificationService.schedulePrayerNotifications(
                    todayPrayers,
                    city: locationInfo.city,
                    countryCode: locationInfo.countryCode
                )
            } catch {
                // Notification scheduling failed — non-critical
            }
        }
    }

    // MARK: - Maghrib Hijri Transition

    /// Schedule a task to post hijriDateTransition notification at Maghrib
    /// so views can refresh the Hijri date in real-time
    private func scheduleMaghribHijriTransition() {
        maghribTransitionTask?.cancel()

        guard let maghribTime = viewModel?.todayPrayerTimes?.maghrib else { return }

        let now = Date()
        // Only schedule if Maghrib is in the future
        guard maghribTime > now else { return }

        let timeUntilMaghrib = maghribTime.timeIntervalSince(now)

        maghribTransitionTask = Task {
            do {
                // Wait until Maghrib + 2 seconds
                let sleepDuration = UInt64((timeUntilMaghrib + 2) * 1_000_000_000)
                try await Task.sleep(nanoseconds: sleepDuration)

                guard !Task.isCancelled else { return }

                // Post notification so views refresh their Hijri date
                NotificationCenter.default.post(name: .hijriDateTransition, object: nil)
            } catch {
                // Task was cancelled
            }
        }
    }

    // MARK: - Periodic Recalculation

    /// Schedule periodic recalculation of prayer period (every 5 minutes)
    private func schedulePeriodicRecalculation() {
        // Cancel existing task
        recalculationTask?.cancel()

        // This ensures the prayer period stays accurate as time passes
        // Particularly important near prayer time boundaries
        recalculationTask = Task {
            while !Task.isCancelled {
                do {
                    // Wait 5 minutes
                    try await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)

                    guard !Task.isCancelled else { return }

                    // Recalculate period
                    viewModel?.recalculatePeriod()

                    // Check if day has changed (edge case: app was suspended)
                    await viewModel?.checkIfNeedsDayTransition()

                } catch {
                    // Task was cancelled or interrupted
                    return
                }
            }
        }

    }

    // MARK: - Cleanup

    deinit {
        // Cancel tasks directly (can't call stop() from deinit due to MainActor isolation)
        dayTransitionTask?.cancel()
        recalculationTask?.cancel()
        maghribTransitionTask?.cancel()
    }
}
