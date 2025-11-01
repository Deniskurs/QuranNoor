//
//  PrayerTransitionHandler.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  Handles automatic midnight transitions for prayer times
//

import Foundation

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

    // MARK: - Initialization

    init(viewModel: PrayerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Public Methods

    /// Start automatic midnight checking
    func start() {
        scheduleMidnightCheck()
        schedulePeriodicRecalculation()
        print("✅ Prayer transition handler started")
    }

    /// Stop all automatic tasks
    func stop() {
        dayTransitionTask?.cancel()
        recalculationTask?.cancel()
        print("🛑 Prayer transition handler stopped")
    }

    // MARK: - Midnight Transition

    /// Schedule a task to run at midnight for day transition
    private func scheduleMidnightCheck() {
        // Cancel existing task
        dayTransitionTask?.cancel()

        // Calculate next midnight
        let calendar = Calendar.current
        let now = Date()

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            print("❌ Failed to calculate next midnight - could not get tomorrow's date")
            return
        }

        // startOfDay(for:) returns non-optional Date
        let midnight = calendar.startOfDay(for: tomorrow)

        let timeUntilMidnight = midnight.timeIntervalSinceNow

        print("⏰ Midnight check scheduled for \(midnight.formatted(date: .omitted, time: .shortened)) (\(Int(timeUntilMidnight / 60)) minutes)")

        // Schedule task to run at midnight (with 5 second buffer)
        dayTransitionTask = Task {
            do {
                // Wait until midnight + 5 seconds
                let sleepDuration = UInt64((timeUntilMidnight + 5) * 1_000_000_000)
                try await Task.sleep(nanoseconds: sleepDuration)

                // Check if task was cancelled
                guard !Task.isCancelled else {
                    print("⚠️ Midnight transition task cancelled")
                    return
                }

                // Perform transition
                await performDayTransition()

                // Reschedule for next midnight
                self.scheduleMidnightCheck()

            } catch {
                print("⚠️ Midnight transition sleep interrupted: \(error)")
            }
        }
    }

    /// Perform the actual day transition at midnight
    private func performDayTransition() async {
        print("🌙 Performing midnight transition...")

        guard let viewModel = viewModel else {
            print("❌ View model is nil, cannot perform transition")
            return
        }

        // Step 1: Promote tomorrow's prayers to today
        if let tomorrow = viewModel.tomorrowPrayerTimes {
            viewModel.todayPrayerTimes = tomorrow
            print("✅ Promoted tomorrow's prayers to today")
        } else {
            print("⚠️ No tomorrow's prayers to promote, fetching today instead")
            await viewModel.loadPrayerTimes()
        }

        // Step 2: Fetch new tomorrow's prayers
        await viewModel.loadTomorrowPrayerTimes()

        // Step 3: Recalculate prayer period
        viewModel.recalculatePeriod()

        // Step 4: Update notifications for new day
        if viewModel.notificationService.isAuthorized &&
           viewModel.notificationService.notificationsEnabled,
           let todayPrayers = viewModel.todayPrayerTimes {
            do {
                try await viewModel.notificationService.schedulePrayerNotifications(todayPrayers)
                print("✅ Notifications updated for new day")
            } catch {
                print("⚠️ Failed to update notifications: \(error)")
            }
        }

        print("✅ Midnight transition complete")
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

        print("✅ Periodic recalculation scheduled (every 5 minutes)")
    }

    // MARK: - Cleanup

    deinit {
        // Cancel tasks directly (can't call stop() from deinit due to MainActor isolation)
        dayTransitionTask?.cancel()
        recalculationTask?.cancel()
        print("🧹 Prayer transition handler deinitialized")
    }
}
