//
//  OfflinePrayerCalculationService.swift
//  QuranNoor
//
//  Created by Claude Code
//  Offline prayer time calculations using Adhan Swift package
//
//  IMPORTANT: This file requires the Adhan Swift package to be installed.
//  See ADHAN_SWIFT_SETUP.md for installation instructions.
//

import Foundation
// MARK: - Uncomment after adding Adhan Swift package via SPM
// import Adhan

/// Service for offline prayer time calculations using Adhan Swift
@MainActor
final class OfflinePrayerCalculationService {

    // MARK: - Singleton
    static let shared = OfflinePrayerCalculationService()

    private init() {}

    // MARK: - Public Methods

    /// Calculate prayer times offline using Adhan Swift package
    /// - Parameters:
    ///   - coordinates: Location coordinates
    ///   - date: Date to calculate times for
    ///   - method: Calculation method
    ///   - madhab: Madhab for Asr calculation
    /// - Returns: DailyPrayerTimes
    func calculateOfflinePrayerTimes(
        coordinates: LocationCoordinates,
        date: Date = Date(),
        method: CalculationMethod = .muslimWorldLeague,
        madhab: Madhab = .shafi
    ) throws -> DailyPrayerTimes {

        // MARK: - IMPLEMENTATION READY FOR ADHAN SWIFT PACKAGE
        // Uncomment the code below after adding the Adhan Swift package

        /*
        // Create Adhan coordinates
        let adhanCoordinates = Coordinates(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )

        // Create date components for Adhan
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        // Get calculation parameters
        var params = mapCalculationMethod(method)
        params.madhab = mapMadhab(madhab)

        // Calculate prayer times using Adhan Swift
        guard let prayerTimes = PrayerTimes(
            coordinates: adhanCoordinates,
            date: dateComponents,
            calculationParameters: params
        ) else {
            throw PrayerTimeError.calculationFailed
        }

        // Get special times
        let sunnahTimes = SunnahTimes(from: prayerTimes)

        // Map to our DailyPrayerTimes model
        return DailyPrayerTimes(
            date: date,
            fajr: prayerTimes.fajr,
            sunrise: prayerTimes.sunrise,
            dhuhr: prayerTimes.dhuhr,
            asr: prayerTimes.asr,
            maghrib: prayerTimes.maghrib,
            isha: prayerTimes.isha,
            imsak: nil, // Adhan Swift doesn't provide Imsak
            sunset: prayerTimes.sunset,
            midnight: sunnahTimes?.middleOfTheNight,
            firstThird: nil,
            lastThird: sunnahTimes?.lastThirdOfTheNight
        )
        */

        // TEMPORARY: Throw error until package is installed
        throw PrayerTimeError.calculationFailed
    }

    /// Calculate Qibla direction
    /// - Parameter coordinates: User's location
    /// - Returns: Qibla direction in degrees from North
    func calculateQiblaDirection(coordinates: LocationCoordinates) -> Double {

        // MARK: - IMPLEMENTATION READY FOR ADHAN SWIFT PACKAGE
        // Uncomment after adding the Adhan Swift package

        /*
        let adhanCoordinates = Coordinates(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )

        return Qibla(coordinates: adhanCoordinates).direction
        */

        // TEMPORARY: Use basic calculation until package is installed
        return calculateQiblaBasic(coordinates: coordinates)
    }

    // MARK: - Private Methods

    /// Temporary basic Qibla calculation (less accurate than Adhan Swift)
    private func calculateQiblaBasic(coordinates: LocationCoordinates) -> Double {
        // Kaaba coordinates
        let kaabaLat = 21.4225
        let kaabaLon = 39.8262

        let lat1 = coordinates.latitude * .pi / 180
        let lon1 = coordinates.longitude * .pi / 180
        let lat2 = kaabaLat * .pi / 180
        let lon2 = kaabaLon * .pi / 180

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)

        // Convert to degrees and normalize to 0-360
        var degrees = bearing * 180 / .pi
        degrees = (degrees + 360).truncatingRemainder(dividingBy: 360)

        return degrees
    }

    // MARK: - Method Mapping
    // These methods will be used once Adhan Swift is installed

    /*
    private func mapCalculationMethod(_ method: CalculationMethod) -> CalculationParameters {
        switch method {
        case .muslimWorldLeague:
            return CalculationMethod.muslimWorldLeague.params
        case .isna:
            return CalculationMethod.northAmerica.params
        case .egyptian:
            return CalculationMethod.egyptian.params
        case .ummAlQura:
            return CalculationMethod.ummAlQura.params
        case .karachi:
            return CalculationMethod.karachi.params
        case .dubai:
            return CalculationMethod.dubai.params
        case .moonsightingCommittee:
            return CalculationMethod.moonsightingCommittee.params
        }
    }

    private func mapMadhab(_ madhab: Madhab) -> Madhab {
        switch madhab {
        case .shafi:
            return .shafi
        case .hanafi:
            return .hanafi
        }
    }
    */
}

// MARK: - Installation Instructions

/*
 TO ENABLE OFFLINE CALCULATIONS:

 1. Open QuranNoor.xcodeproj in Xcode
 2. Go to File → Add Package Dependencies
 3. Enter: https://github.com/batoulapps/adhan-swift
 4. Select branch: main
 5. Click Add Package
 6. Uncomment the import statement at the top of this file
 7. Uncomment the implementation code in the methods above
 8. Build and test

 See ADHAN_SWIFT_SETUP.md for detailed instructions.
 */
