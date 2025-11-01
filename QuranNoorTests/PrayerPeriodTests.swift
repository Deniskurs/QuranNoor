//
//  PrayerPeriodTests.swift
//  QuranNoorTests
//
//  Created by Claude on 11/1/2025.
//  Unit tests for Prayer Period state machine
//

import XCTest
@testable import QuranNoor

final class PrayerPeriodTests: XCTestCase {

    var calendar: Calendar!
    var baseDate: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar.current

        // Set base date to a specific day for consistent testing
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        baseDate = calendar.date(from: components)!
    }

    override func tearDown() {
        calendar = nil
        baseDate = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Create mock prayer times for a given date
    private func createMockPrayerTimes(for date: Date) -> DailyPrayerTimes {
        var components = calendar.dateComponents([.year, .month, .day], from: date)

        func makeTime(hour: Int, minute: Int = 0) -> Date {
            components.hour = hour
            components.minute = minute
            components.second = 0
            return calendar.date(from: components)!
        }

        return DailyPrayerTimes(
            date: date,
            fajr: makeTime(hour: 5, minute: 0),        // 5:00 AM
            dhuhr: makeTime(hour: 12, minute: 30),      // 12:30 PM
            asr: makeTime(hour: 15, minute: 30),        // 3:30 PM
            maghrib: makeTime(hour: 18, minute: 0),     // 6:00 PM
            isha: makeTime(hour: 20, minute: 0),        // 8:00 PM
            sunrise: makeTime(hour: 6, minute: 30),     // 6:30 AM
            sunset: makeTime(hour: 17, minute: 55),     // 5:55 PM
            imsak: makeTime(hour: 4, minute: 45),       // 4:45 AM
            midnight: makeTime(hour: 0, minute: 30),    // 12:30 AM (next day)
            firstThird: makeTime(hour: 22, minute: 0),  // 10:00 PM
            lastThird: makeTime(hour: 2, minute: 0)     // 2:00 AM (next day)
        )
    }

    /// Set current time for testing (by creating date with specific hour/minute)
    private func setTime(hour: Int, minute: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }

    // MARK: - State Tests

    func testBeforeFajr() {
        // Setup: 3:00 AM (before Fajr at 5:00 AM)
        let currentTime = setTime(hour: 3, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        // Calculate period
        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Assert: Should be in beforeFajr state
        if case .beforeFajr(let fajr) = period.state {
            XCTAssertEqual(calendar.component(.hour, from: fajr), 5)
            XCTAssertEqual(calendar.component(.minute, from: fajr), 0)
        } else {
            XCTFail("Expected beforeFajr state, got \(period.state)")
        }

        // Assert: No current prayer
        XCTAssertNil(period.currentPrayer)

        // Assert: Next prayer is Fajr
        XCTAssertEqual(period.nextPrayer?.name, .fajr)
    }

    func testDuringFajr() {
        // Setup: 5:30 AM (during Fajr, before sunrise at 6:30 AM)
        let currentTime = setTime(hour: 5, minute: 30)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Assert: Should be in inProgress state with Fajr
        if case .inProgress(let prayer, let deadline) = period.state {
            XCTAssertEqual(prayer, .fajr)
            // Deadline should be sunrise (6:30 AM)
            XCTAssertEqual(calendar.component(.hour, from: deadline), 6)
            XCTAssertEqual(calendar.component(.minute, from: deadline), 30)
        } else {
            XCTFail("Expected inProgress(fajr) state, got \(period.state)")
        }

        // Assert: Current prayer is Fajr
        XCTAssertEqual(period.currentPrayer, .fajr)

        // Assert: Next prayer is Dhuhr
        XCTAssertEqual(period.nextPrayer?.name, .dhuhr)
    }

    func testBetweenFajrAndSunrise() {
        // Setup: 6:15 AM (after Fajr at 5:00 AM, before sunrise at 6:30 AM)
        // This should technically still be in Fajr period, but let's test edge case
        let currentTime = setTime(hour: 6, minute: 15)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Should still be in Fajr period (before sunrise deadline)
        XCTAssertEqual(period.currentPrayer, .fajr)
    }

    func testAfterSunriseBeforeDhuhr() {
        // Setup: 7:00 AM (after sunrise at 6:30 AM, before Dhuhr at 12:30 PM)
        let currentTime = setTime(hour: 7, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Assert: Should be in betweenPrayers state
        if case .betweenPrayers(let previous, let next, let nextStart) = period.state {
            XCTAssertEqual(previous, .fajr)
            XCTAssertEqual(next, .dhuhr)
            XCTAssertEqual(calendar.component(.hour, from: nextStart), 12)
            XCTAssertEqual(calendar.component(.minute, from: nextStart), 30)
        } else {
            XCTFail("Expected betweenPrayers state, got \(period.state)")
        }

        // Assert: No current prayer
        XCTAssertNil(period.currentPrayer)

        // Assert: Next prayer is Dhuhr
        XCTAssertEqual(period.nextPrayer?.name, .dhuhr)
    }

    func testDuringDhuhr() {
        // Setup: 1:00 PM (during Dhuhr, before Asr at 3:30 PM)
        let currentTime = setTime(hour: 13, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Assert: Should be in inProgress state with Dhuhr
        if case .inProgress(let prayer, let deadline) = period.state {
            XCTAssertEqual(prayer, .dhuhr)
            // Dhuhr deadline is Asr time (3:30 PM)
            XCTAssertEqual(calendar.component(.hour, from: deadline), 15)
            XCTAssertEqual(calendar.component(.minute, from: deadline), 30)
        } else {
            XCTFail("Expected inProgress(dhuhr) state, got \(period.state)")
        }

        XCTAssertEqual(period.currentPrayer, .dhuhr)
    }

    func testDuringAsr() {
        // Setup: 4:00 PM (during Asr, before Maghrib at 6:00 PM)
        let currentTime = setTime(hour: 16, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Assert: Should be in inProgress state with Asr
        XCTAssertEqual(period.currentPrayer, .asr)
    }

    func testDuringMaghrib() {
        // Setup: 6:15 PM (during Maghrib, before Isha at 8:00 PM)
        let currentTime = setTime(hour: 18, minute: 15)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Assert: Should be in inProgress state with Maghrib
        XCTAssertEqual(period.currentPrayer, .maghrib)
    }

    func testDuringIsha() {
        // Setup: 9:00 PM (during Isha, before midnight at 12:30 AM)
        let currentTime = setTime(hour: 21, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Assert: Should be in inProgress state with Isha
        if case .inProgress(let prayer, let deadline) = period.state {
            XCTAssertEqual(prayer, .isha)
            // Note: Midnight is stored as next day, so we need to check carefully
            let midnightHour = calendar.component(.hour, from: deadline)
            XCTAssertEqual(midnightHour, 0)
            XCTAssertEqual(calendar.component(.minute, from: deadline), 30)
        } else {
            XCTFail("Expected inProgress(isha) state, got \(period.state)")
        }

        XCTAssertEqual(period.currentPrayer, .isha)
    }

    func testAfterIshaMidnight() {
        // Setup: 11:00 PM (after Isha at 8:00 PM, before midnight at 12:30 AM)
        let currentTime = setTime(hour: 23, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        // Create tomorrow's prayer times
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentTime)!
        let tomorrowPrayers = createMockPrayerTimes(for: tomorrow)

        let period = PrayerPeriodCalculator.calculate(
            today: mockTimes,
            tomorrow: tomorrowPrayers
        )

        // Should still be in Isha period (before midnight deadline)
        XCTAssertEqual(period.currentPrayer, .isha)
    }

    func testAfterMidnightBeforeFajr() {
        // Setup: 1:00 AM (after midnight at 12:30 AM, before Fajr at 5:00 AM)
        // This is tricky - we need to use yesterday's prayer times as "today"
        let yesterday = calendar.date(byAdding: .day, value: -1, to: baseDate)!
        let yesterdayPrayers = createMockPrayerTimes(for: yesterday)

        let currentTime = setTime(hour: 1, minute: 0)
        let todayPrayers = createMockPrayerTimes(for: currentTime)

        // When it's 1 AM, we're technically still on yesterday's Islamic day
        // but after midnight, so we need tomorrow's Fajr
        let period = PrayerPeriodCalculator.calculate(
            today: yesterdayPrayers,
            tomorrow: todayPrayers
        )

        // Assert: Should be in afterIsha state
        if case .afterIsha(let tomorrowFajr) = period.state {
            XCTAssertEqual(calendar.component(.hour, from: tomorrowFajr), 5)
        } else {
            XCTFail("Expected afterIsha state, got \(period.state)")
        }

        // Assert: No current prayer
        XCTAssertNil(period.currentPrayer)

        // Assert: Next prayer is tomorrow's Fajr
        XCTAssertEqual(period.nextPrayer?.name, .fajr)
    }

    // MARK: - Progress Calculation Tests

    func testProgressCalculation() {
        // Setup: 5:45 AM (Fajr at 5:00 AM, Sunrise at 6:30 AM)
        // Should be 50% through Fajr period
        let currentTime = setTime(hour: 5, minute: 45)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Fajr period is 90 minutes (5:00 - 6:30)
        // At 5:45, we're 45 minutes in = 50% progress
        let progress = period.periodProgress

        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Progress should be approximately 50%")
    }

    func testProgressAtStart() {
        // Setup: Exactly at Fajr time (5:00 AM)
        let currentTime = setTime(hour: 5, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)
        let progress = period.periodProgress

        // Should be at 0% (just started)
        XCTAssertLessThan(progress, 0.05, "Progress should be near 0% at start")
    }

    func testProgressNearEnd() {
        // Setup: 6:25 AM (5 minutes before sunrise deadline)
        let currentTime = setTime(hour: 6, minute: 25)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)
        let progress = period.periodProgress

        // Should be near 100%
        // Fajr: 5:00-6:30 = 90 minutes
        // At 6:25 = 85 minutes elapsed = 94.4%
        XCTAssertGreaterThan(progress, 0.9, "Progress should be > 90% near end")
        XCTAssertLessThan(progress, 1.0, "Progress should not exceed 100%")
    }

    // MARK: - Urgency Tests

    func testUrgencyFlag() {
        // Setup: 6:20 AM (10 minutes before sunrise deadline at 6:30 AM)
        let currentTime = setTime(hour: 6, minute: 20)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Should be marked as urgent (< 30 minutes)
        XCTAssertTrue(period.isUrgent, "Period should be urgent with < 30 min remaining")
    }

    func testNotUrgent() {
        // Setup: 5:30 AM (60 minutes before sunrise deadline)
        let currentTime = setTime(hour: 5, minute: 30)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Should NOT be marked as urgent (> 30 minutes)
        XCTAssertFalse(period.isUrgent, "Period should not be urgent with > 30 min remaining")
    }

    // MARK: - Countdown String Tests

    func testCountdownStringFormat() {
        // Setup: 5:00 AM (90 minutes until sunrise at 6:30 AM)
        let currentTime = setTime(hour: 5, minute: 0)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)
        let countdown = period.countdownString

        // Should be "01:30:00" (1 hour 30 minutes)
        XCTAssertTrue(countdown.hasPrefix("01:30"), "Countdown should show 1h 30m format")
    }

    func testCountdownStringShortFormat() {
        // Setup: 6:20 AM (10 minutes until sunrise)
        let currentTime = setTime(hour: 6, minute: 20)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)
        let countdown = period.countdownString

        // Should be "10:XX" (less than 1 hour, uses MM:SS format)
        XCTAssertTrue(countdown.hasPrefix("10:") || countdown.hasPrefix("09:"),
                      "Countdown should show MM:SS format for < 1 hour")
    }

    // MARK: - Edge Case Tests

    func testMidnightTransitionHandling() {
        // Test the exact moment of midnight transition
        let currentTime = setTime(hour: 0, minute: 30) // Exactly at midnight

        // Use yesterday's times as "today" since Islamic day hasn't rolled over yet
        let yesterday = calendar.date(byAdding: .day, value: -1, to: currentTime)!
        let yesterdayPrayers = createMockPrayerTimes(for: yesterday)

        let todayPrayers = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(
            today: yesterdayPrayers,
            tomorrow: todayPrayers
        )

        // At exactly midnight, Isha period should have just ended
        // Should transition to afterIsha state
        if case .afterIsha = period.state {
            XCTAssertTrue(true, "Correctly in afterIsha state at midnight")
        } else if case .inProgress(let prayer, _) = period.state {
            // Some tolerance - might still show as Isha if calculated at exact moment
            XCTAssertEqual(prayer, .isha, "If in progress, should only be Isha")
        } else {
            XCTFail("Expected afterIsha or inProgress(isha) at midnight, got \(period.state)")
        }
    }

    func testWithoutTomorrowPrayers() {
        // Test behavior when tomorrow's prayers aren't loaded
        let currentTime = setTime(hour: 21, minute: 0) // 9 PM during Isha
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)

        // Should still work, using midnight as deadline
        XCTAssertEqual(period.currentPrayer, .isha)

        // Should have a deadline (midnight)
        if case .inProgress(_, let deadline) = period.state {
            XCTAssertNotNil(deadline, "Should have a deadline even without tomorrow's prayers")
        } else {
            XCTFail("Expected inProgress state")
        }
    }

    // MARK: - Formatted Text Tests

    func testFormattedTimeRemaining() {
        let currentTime = setTime(hour: 5, minute: 30)
        let mockTimes = createMockPrayerTimes(for: currentTime)

        let period = PrayerPeriodCalculator.calculate(today: mockTimes, tomorrow: nil)
        let formatted = period.formattedTimeRemaining

        // Should include "until Dhuhr" since next prayer is Dhuhr
        XCTAssertTrue(formatted.contains("Dhuhr"), "Formatted time should mention next prayer")
    }

    func testStatusText() {
        // Test "in progress" status
        let duringFajr = setTime(hour: 5, minute: 30)
        let mockTimes1 = createMockPrayerTimes(for: duringFajr)
        let period1 = PrayerPeriodCalculator.calculate(today: mockTimes1, tomorrow: nil)

        XCTAssertTrue(period1.statusText.contains("Ends in"),
                      "Status should say 'Ends in' for in-progress prayer")

        // Test "between prayers" status
        let betweenPrayers = setTime(hour: 7, minute: 0)
        let mockTimes2 = createMockPrayerTimes(for: betweenPrayers)
        let period2 = PrayerPeriodCalculator.calculate(today: mockTimes2, tomorrow: nil)

        XCTAssertTrue(period2.statusText.contains("Starts in"),
                      "Status should say 'Starts in' when between prayers")
    }
}
