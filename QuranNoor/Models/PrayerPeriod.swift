//
//  PrayerPeriod.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  Prayer period state machine for accurate prayer time tracking
//

import Foundation

// MARK: - Prayer Period State

/// Represents the current state of the prayer schedule
enum PrayerPeriodState: Equatable {
    /// Before Fajr time (e.g., 3 AM when Fajr is at 5 AM)
    case beforeFajr(nextFajr: Date)

    /// Currently in a prayer period with an optional deadline
    case inProgress(prayer: PrayerName, deadline: Date)

    /// Between two prayers (e.g., after sunrise, before Dhuhr)
    case betweenPrayers(previous: PrayerName, next: PrayerName, nextStartTime: Date)

    /// After Isha ends (past midnight, before next day's Fajr)
    case afterIsha(tomorrowFajr: Date)

    /// Whether this is an active prayer time
    var isActiveTime: Bool {
        switch self {
        case .inProgress:
            return true
        default:
            return false
        }
    }

    /// The next significant event time (prayer start or deadline)
    var nextEventTime: Date {
        switch self {
        case .beforeFajr(let fajr):
            return fajr
        case .inProgress(_, let deadline):
            return deadline
        case .betweenPrayers(_, _, let nextStart):
            return nextStart
        case .afterIsha(let fajr):
            return fajr
        }
    }

    /// Human-readable description of the current state
    var description: String {
        switch self {
        case .beforeFajr:
            return "Before Fajr"
        case .inProgress(let prayer, _):
            return "\(prayer.displayName) Period"
        case .betweenPrayers(let previous, let next, _):
            return "Between \(previous.displayName) and \(next.displayName)"
        case .afterIsha:
            return "After Isha"
        }
    }
}

// MARK: - Prayer Period

/// Represents the complete prayer schedule state at a given moment
struct PrayerPeriod {
    let state: PrayerPeriodState
    let todayPrayers: DailyPrayerTimes
    let tomorrowPrayers: DailyPrayerTimes?
    let calculatedAt: Date

    // MARK: - Computed Properties

    /// The current prayer if we're in a prayer period
    var currentPrayer: PrayerName? {
        switch state {
        case .inProgress(let prayer, _):
            return prayer
        default:
            return nil
        }
    }

    /// The next prayer and its time
    var nextPrayer: (name: PrayerName, time: Date)? {
        switch state {
        case .beforeFajr(let fajr):
            return (.fajr, fajr)
        case .betweenPrayers(_, let next, let time):
            return (next, time)
        case .afterIsha(let fajr):
            return (.fajr, fajr)
        case .inProgress(let current, _):
            // Find the next prayer after current
            let prayers = todayPrayers.prayerTimes
            if let currentIndex = prayers.firstIndex(where: { $0.name == current }),
               currentIndex + 1 < prayers.count {
                let next = prayers[currentIndex + 1]
                return (next.name, next.time)
            } else if let tomorrow = tomorrowPrayers {
                // Current is Isha, next is tomorrow's Fajr
                return (.fajr, tomorrow.fajr)
            }
            return nil
        }
    }

    /// Time remaining until next event (in seconds)
    var timeUntilNextEvent: TimeInterval {
        state.nextEventTime.timeIntervalSinceNow
    }

    /// Progress through current prayer period (0.0 to 1.0)
    var periodProgress: Double {
        switch state {
        case .inProgress(let prayer, let deadline):
            return calculateProgress(for: prayer, deadline: deadline)
        case .betweenPrayers(let previous, _, let nextStart):
            return calculateBetweenProgress(previous: previous, nextStart: nextStart)
        default:
            return 0.0
        }
    }

    /// Whether the prayer period is urgent (< 30 minutes to deadline)
    var isUrgent: Bool {
        guard case .inProgress = state else { return false }
        return timeUntilNextEvent < 1800 // 30 minutes
    }

    /// Formatted countdown string (e.g., "02:30:15" or "45:30")
    var countdownString: String {
        let interval = max(timeUntilNextEvent, 0)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Progress Calculations

    /// Calculate progress for an in-progress prayer period
    private func calculateProgress(for prayer: PrayerName, deadline: Date) -> Double {
        guard let startTime = todayPrayers.prayerTimes.first(where: { $0.name == prayer })?.time else {
            return 0
        }

        let now = Date()
        let totalDuration = deadline.timeIntervalSince(startTime)

        guard totalDuration > 0 else { return 0 }

        let elapsed = now.timeIntervalSince(startTime)

        // Clamp between 0 and 1
        return min(max(elapsed / totalDuration, 0), 1)
    }

    /// Calculate progress between two prayers
    private func calculateBetweenProgress(previous: PrayerName, nextStart: Date) -> Double {
        guard let prevTime = todayPrayers.prayerTimes.first(where: { $0.name == previous })?.time else {
            return 0
        }

        let now = Date()
        let totalDuration = nextStart.timeIntervalSince(prevTime)

        guard totalDuration > 0 else { return 0 }

        let elapsed = now.timeIntervalSince(prevTime)

        return min(max(elapsed / totalDuration, 0), 1)
    }
}

// MARK: - Prayer Period Calculator

/// Calculates the current prayer period from daily prayer times
struct PrayerPeriodCalculator {

    /// Calculate the current prayer period state
    /// - Parameters:
    ///   - today: Today's prayer times
    ///   - tomorrow: Tomorrow's prayer times (optional, for after-Isha handling)
    /// - Returns: The current prayer period
    static func calculate(
        today: DailyPrayerTimes,
        tomorrow: DailyPrayerTimes?
    ) -> PrayerPeriod {
        let now = Date()
        let prayers = today.prayerTimes

        // Check if we're before Fajr
        if now < prayers[0].time {
            return PrayerPeriod(
                state: .beforeFajr(nextFajr: prayers[0].time),
                todayPrayers: today,
                tomorrowPrayers: tomorrow,
                calculatedAt: now
            )
        }

        // Iterate through prayers to find current state
        for (index, prayer) in prayers.enumerated() {
            let nextIndex = index + 1

            // Are we past this prayer's start time?
            if now >= prayer.time {
                // Is this the last prayer (Isha)?
                if nextIndex >= prayers.count {
                    return handleIshaPeriod(
                        now: now,
                        today: today,
                        tomorrow: tomorrow
                    )
                }

                let nextPrayer = prayers[nextIndex]

                // Are we still before the next prayer?
                if now < nextPrayer.time {
                    // Determine deadline for this prayer
                    let deadline = getDeadline(
                        for: prayer.name,
                        in: today,
                        nextPrayerTime: nextPrayer.time
                    )

                    // Are we still within the prayer period?
                    if now < deadline {
                        return PrayerPeriod(
                            state: .inProgress(prayer: prayer.name, deadline: deadline),
                            todayPrayers: today,
                            tomorrowPrayers: tomorrow,
                            calculatedAt: now
                        )
                    } else {
                        // Between prayers (after deadline, before next prayer)
                        return PrayerPeriod(
                            state: .betweenPrayers(
                                previous: prayer.name,
                                next: nextPrayer.name,
                                nextStartTime: nextPrayer.time
                            ),
                            todayPrayers: today,
                            tomorrowPrayers: tomorrow,
                            calculatedAt: now
                        )
                    }
                }
            }
        }

        // Fallback (should never reach here, but handle gracefully)
        return PrayerPeriod(
            state: .beforeFajr(nextFajr: prayers[0].time),
            todayPrayers: today,
            tomorrowPrayers: tomorrow,
            calculatedAt: now
        )
    }

    // MARK: - Private Helpers

    /// Handle the special case of Isha period (last prayer of the day)
    private static func handleIshaPeriod(
        now: Date,
        today: DailyPrayerTimes,
        tomorrow: DailyPrayerTimes?
    ) -> PrayerPeriod {
        // Isha is the last prayer
        let ishaTime = today.isha

        // Check if we have Islamic Midnight (Isha deadline)
        if let midnight = today.midnight {
            // Are we still before midnight?
            if now < midnight {
                // In Isha period
                return PrayerPeriod(
                    state: .inProgress(prayer: .isha, deadline: midnight),
                    todayPrayers: today,
                    tomorrowPrayers: tomorrow,
                    calculatedAt: now
                )
            } else {
                // After midnight, before tomorrow's Fajr
                if let tomorrowFajr = tomorrow?.fajr {
                    return PrayerPeriod(
                        state: .afterIsha(tomorrowFajr: tomorrowFajr),
                        todayPrayers: today,
                        tomorrowPrayers: tomorrow,
                        calculatedAt: now
                    )
                } else {
                    // Fallback: treat as in-progress Isha
                    return PrayerPeriod(
                        state: .inProgress(
                            prayer: .isha,
                            deadline: now.addingTimeInterval(3600) // 1 hour fallback
                        ),
                        todayPrayers: today,
                        tomorrowPrayers: tomorrow,
                        calculatedAt: now
                    )
                }
            }
        } else {
            // No midnight time available, use tomorrow's Fajr as deadline
            if let tomorrowFajr = tomorrow?.fajr {
                if now < tomorrowFajr {
                    return PrayerPeriod(
                        state: .inProgress(prayer: .isha, deadline: tomorrowFajr),
                        todayPrayers: today,
                        tomorrowPrayers: tomorrow,
                        calculatedAt: now
                    )
                } else {
                    return PrayerPeriod(
                        state: .afterIsha(tomorrowFajr: tomorrowFajr),
                        todayPrayers: today,
                        tomorrowPrayers: tomorrow,
                        calculatedAt: now
                    )
                }
            } else {
                // Last resort: assume in Isha period with long deadline
                return PrayerPeriod(
                    state: .inProgress(
                        prayer: .isha,
                        deadline: ishaTime.addingTimeInterval(21600) // 6 hours
                    ),
                    todayPrayers: today,
                    tomorrowPrayers: tomorrow,
                    calculatedAt: now
                )
            }
        }
    }

    /// Get the deadline for a specific prayer
    private static func getDeadline(
        for prayer: PrayerName,
        in times: DailyPrayerTimes,
        nextPrayerTime: Date
    ) -> Date {
        switch prayer {
        case .fajr:
            // Fajr ends at sunrise (strict deadline)
            return times.sunrise

        case .isha:
            // Isha ends at Islamic midnight (if available)
            return times.midnight ?? nextPrayerTime

        case .dhuhr, .asr, .maghrib:
            // These prayers end when the next prayer starts
            return nextPrayerTime
        }
    }
}

// MARK: - Equatable Conformance

extension PrayerPeriod: Equatable {
    static func == (lhs: PrayerPeriod, rhs: PrayerPeriod) -> Bool {
        // Compare states
        guard lhs.state == rhs.state else { return false }

        // Compare today's prayer times (by date only, full comparison would be too complex)
        guard lhs.todayPrayers.date == rhs.todayPrayers.date else { return false }

        // Compare tomorrow's prayer times
        if let lhsTomorrow = lhs.tomorrowPrayers, let rhsTomorrow = rhs.tomorrowPrayers {
            guard lhsTomorrow.date == rhsTomorrow.date else { return false }
        } else if lhs.tomorrowPrayers != nil || rhs.tomorrowPrayers != nil {
            return false // One has tomorrow, other doesn't
        }

        // Compare calculation times (within 1 second tolerance)
        guard abs(lhs.calculatedAt.timeIntervalSince(rhs.calculatedAt)) < 1.0 else { return false }

        return true
    }
}

// MARK: - Extensions for Formatting

extension PrayerPeriod {

    /// Formatted time remaining with context (e.g., "2h 30m until Asr")
    var formattedTimeRemaining: String {
        let interval = timeUntilNextEvent
        guard interval > 0 else { return "Now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        var timeString = ""
        if hours > 0 {
            timeString += "\(hours)h "
        }
        if minutes > 0 || hours == 0 {
            timeString += "\(minutes)m"
        }

        // Add context
        switch state {
        case .inProgress(_, _):
            if let next = nextPrayer {
                return "\(timeString.trimmingCharacters(in: .whitespaces)) until \(next.name.displayName)"
            } else {
                return "\(timeString.trimmingCharacters(in: .whitespaces)) remaining"
            }

        case .betweenPrayers(_, let next, _):
            return "\(timeString.trimmingCharacters(in: .whitespaces)) until \(next.displayName)"

        case .beforeFajr:
            return "\(timeString.trimmingCharacters(in: .whitespaces)) until Fajr"

        case .afterIsha:
            return "\(timeString.trimmingCharacters(in: .whitespaces)) until Fajr"
        }
    }

    /// Short status text for UI (e.g., "Ends in 30m" or "Starts in 1h 15m")
    var statusText: String {
        switch state {
        case .inProgress:
            return "Ends in \(countdownString)"
        case .betweenPrayers, .beforeFajr, .afterIsha:
            return "Starts in \(countdownString)"
        }
    }
}
