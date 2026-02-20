//
//  OfflinePrayerCalculationService.swift
//  QuranNoor
//
//  Pure-Swift astronomical prayer time calculations
//  No external dependencies required — uses standard solar position algorithms
//
//  Based on the well-documented prayer time calculation methods used by:
//  - Muslim World League (MWL)
//  - Islamic Society of North America (ISNA)
//  - Egyptian General Authority of Survey
//  - Umm al-Qura University, Makkah
//  - University of Islamic Sciences, Karachi
//

import Foundation

/// Service for offline prayer time calculations using astronomical formulas
@MainActor
final class OfflinePrayerCalculationService {

    // MARK: - Singleton
    static let shared = OfflinePrayerCalculationService()

    private init() {}

    // MARK: - Calculation Parameters per Method

    /// Fajr and Isha angles (degrees below horizon) for each calculation method
    private struct MethodParameters {
        let fajrAngle: Double
        let ishaAngle: Double?       // nil = use isha interval instead
        let ishaInterval: Double?    // minutes after Maghrib (for Umm al-Qura)

        static func forMethod(_ method: CalculationMethod) -> MethodParameters {
            switch method {
            case .muslimWorldLeague:
                return MethodParameters(fajrAngle: 18.0, ishaAngle: 17.0, ishaInterval: nil)
            case .isna:
                return MethodParameters(fajrAngle: 15.0, ishaAngle: 15.0, ishaInterval: nil)
            case .egyptian:
                return MethodParameters(fajrAngle: 19.5, ishaAngle: 17.5, ishaInterval: nil)
            case .ummAlQura:
                return MethodParameters(fajrAngle: 18.5, ishaAngle: nil, ishaInterval: 90)
            case .karachi:
                return MethodParameters(fajrAngle: 18.0, ishaAngle: 18.0, ishaInterval: nil)
            case .dubai:
                return MethodParameters(fajrAngle: 18.2, ishaAngle: 18.2, ishaInterval: nil)
            case .moonsightingCommittee:
                return MethodParameters(fajrAngle: 18.0, ishaAngle: 18.0, ishaInterval: nil)
            }
        }
    }

    // MARK: - Public Methods

    /// Calculate prayer times offline using astronomical formulas
    /// - Parameters:
    ///   - coordinates: Location coordinates (latitude, longitude)
    ///   - date: Date to calculate times for
    ///   - method: Calculation method determining Fajr/Isha angles
    ///   - madhab: Madhab for Asr shadow ratio (Shafi=1x, Hanafi=2x)
    /// - Returns: DailyPrayerTimes with all five prayers and special times
    func calculateOfflinePrayerTimes(
        coordinates: LocationCoordinates,
        date: Date = Date(),
        method: CalculationMethod = .muslimWorldLeague,
        madhab: Madhab = .shafi
    ) throws -> DailyPrayerTimes {

        let params = MethodParameters.forMethod(method)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            throw PrayerTimeError.calculationFailed
        }

        let lat = coordinates.latitude
        let lng = coordinates.longitude
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600.0

        // Julian date for the given day
        let jd = julianDate(year: year, month: month, day: day)

        // Solar position for the day
        let sunDeclination = sunDeclination(jd: jd)
        let equationOfTime = equationOfTime(jd: jd)

        // Dhuhr (solar noon) in hours
        let dhuhrHours = 12.0 + timeZoneOffset - lng / 15.0 - equationOfTime

        // Sunrise and Sunset
        let sunriseHours = dhuhrHours - hourAngle(lat: lat, decl: sunDeclination, angle: 0.833) / 15.0
        let sunsetHours = dhuhrHours + hourAngle(lat: lat, decl: sunDeclination, angle: 0.833) / 15.0

        // Fajr
        let fajrHours = dhuhrHours - hourAngle(lat: lat, decl: sunDeclination, angle: params.fajrAngle) / 15.0

        // Asr - shadow ratio depends on madhab
        let shadowRatio: Double = madhab == .hanafi ? 2.0 : 1.0
        let asrHours = dhuhrHours + asrHourAngle(lat: lat, decl: sunDeclination, shadowRatio: shadowRatio) / 15.0

        // Maghrib = sunset
        let maghribHours = sunsetHours

        // Isha
        let ishaHours: Double
        if let ishaAngle = params.ishaAngle {
            ishaHours = dhuhrHours + hourAngle(lat: lat, decl: sunDeclination, angle: ishaAngle) / 15.0
        } else if let ishaInterval = params.ishaInterval {
            ishaHours = maghribHours + ishaInterval / 60.0
        } else {
            ishaHours = dhuhrHours + hourAngle(lat: lat, decl: sunDeclination, angle: 17.0) / 15.0
        }

        // Imsak = 10 minutes before Fajr
        let imsakHours = fajrHours - 10.0 / 60.0

        // Islamic midnight = midpoint between sunset and sunrise (next day)
        let nightDuration = 24.0 - sunsetHours + sunriseHours
        let midnightHours = sunsetHours + nightDuration / 2.0

        // Night thirds
        let firstThirdHours = sunsetHours + nightDuration / 3.0
        let lastThirdHours = sunsetHours + 2.0 * nightDuration / 3.0

        // Convert hours to Date objects
        guard let baseDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            throw PrayerTimeError.calculationFailed
        }

        func hoursToDate(_ hours: Double) -> Date {
            var normalizedHours = hours
            if normalizedHours >= 24.0 { normalizedHours -= 24.0 }
            if normalizedHours < 0.0 { normalizedHours += 24.0 }
            let totalSeconds = normalizedHours * 3600.0
            return baseDate.addingTimeInterval(totalSeconds)
        }

        // Validate: all times should be reasonable
        guard fajrHours > 0, fajrHours < 24,
              sunriseHours > 0, sunriseHours < 24,
              dhuhrHours > 0, dhuhrHours < 24,
              asrHours > 0, asrHours < 24,
              maghribHours > 0, maghribHours < 24,
              ishaHours > 0, ishaHours < 48 else {
            throw PrayerTimeError.calculationFailed
        }

        return DailyPrayerTimes(
            date: date,
            fajr: hoursToDate(fajrHours),
            sunrise: hoursToDate(sunriseHours),
            dhuhr: hoursToDate(dhuhrHours),
            asr: hoursToDate(asrHours),
            maghrib: hoursToDate(maghribHours),
            isha: hoursToDate(ishaHours),
            imsak: hoursToDate(imsakHours),
            sunset: hoursToDate(sunsetHours),
            midnight: hoursToDate(midnightHours),
            firstThird: hoursToDate(firstThirdHours),
            lastThird: hoursToDate(lastThirdHours)
        )
    }

    /// Calculate Qibla direction from a given location
    /// - Parameter coordinates: User's location
    /// - Returns: Qibla direction in degrees from North (clockwise)
    func calculateQiblaDirection(coordinates: LocationCoordinates) -> Double {
        // Kaaba coordinates (Masjid al-Haram, Makkah)
        let kaabaLat = 21.4225
        let kaabaLon = 39.8262

        let lat1 = coordinates.latitude.radians
        let lon1 = coordinates.longitude.radians
        let lat2 = kaabaLat.radians
        let lon2 = kaabaLon.radians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)

        // Convert to degrees and normalize to 0-360
        var degrees = bearing.degrees
        degrees = (degrees + 360.0).truncatingRemainder(dividingBy: 360.0)

        return degrees
    }

    // MARK: - Astronomical Calculations

    /// Calculate Julian Date number for a given Gregorian date
    private func julianDate(year: Int, month: Int, day: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        let d = Double(day)

        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = floor(y / 100.0)
        let b = 2.0 - a + floor(a / 4.0)

        return floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + d + b - 1524.5
    }

    /// Calculate sun's declination angle for a given Julian date
    /// Returns declination in degrees
    private func sunDeclination(jd: Double) -> Double {
        let d = jd - 2451545.0 // Days since J2000.0

        // Mean longitude of the sun (degrees)
        let meanLongitude = (280.46646 + 0.9856474 * d)
            .truncatingRemainder(dividingBy: 360.0)

        // Mean anomaly (degrees)
        let meanAnomaly = (357.52911 + 0.98560028 * d)
            .truncatingRemainder(dividingBy: 360.0)

        // Equation of center
        let mRad = meanAnomaly.radians
        let equationOfCenter = 1.9146 * sin(mRad) + 0.02 * sin(2.0 * mRad) + 0.0003 * sin(3.0 * mRad)

        // Sun's ecliptic longitude
        let eclipticLongitude = meanLongitude + equationOfCenter

        // Obliquity of the ecliptic
        let obliquity = 23.439 - 0.00000036 * d

        // Sun's declination
        let declination = asin(sin(obliquity.radians) * sin(eclipticLongitude.radians))

        return declination.degrees
    }

    /// Calculate equation of time (difference between solar time and clock time)
    /// Returns value in hours
    private func equationOfTime(jd: Double) -> Double {
        let d = jd - 2451545.0

        let meanLongitude = (280.46646 + 0.9856474 * d)
            .truncatingRemainder(dividingBy: 360.0)
        let meanAnomaly = (357.52911 + 0.98560028 * d)
            .truncatingRemainder(dividingBy: 360.0)

        let mRad = meanAnomaly.radians
        let equationOfCenter = 1.9146 * sin(mRad) + 0.02 * sin(2.0 * mRad)
        let eclipticLongitude = meanLongitude + equationOfCenter

        let obliquity = 23.439 - 0.00000036 * d

        // Right ascension
        let ra = atan2(
            cos(obliquity.radians) * sin(eclipticLongitude.radians),
            cos(eclipticLongitude.radians)
        ).degrees

        // Equation of time in minutes, then convert to hours
        var eot = meanLongitude - ra
        // Normalize to -180...180
        while eot > 180 { eot -= 360 }
        while eot < -180 { eot += 360 }

        return eot / 15.0 // Convert degrees to hours (15° per hour)
    }

    /// Calculate the hour angle for when the sun is at a given angle below the horizon
    /// - Parameters:
    ///   - lat: Observer latitude in degrees
    ///   - decl: Sun declination in degrees
    ///   - angle: Sun angle below horizon in degrees (positive = below)
    /// - Returns: Hour angle in degrees
    private func hourAngle(lat: Double, decl: Double, angle: Double) -> Double {
        let latRad = lat.radians
        let declRad = decl.radians
        let angleRad = angle.radians

        let cosH = (sin(-angleRad) - sin(latRad) * sin(declRad)) /
                   (cos(latRad) * cos(declRad))

        // Clamp to valid range for acos
        let clampedCosH = max(-1.0, min(1.0, cosH))
        return acos(clampedCosH).degrees
    }

    /// Calculate the hour angle for Asr prayer
    /// Asr = when shadow length = shadowRatio * object height + noonday shadow
    /// - Parameters:
    ///   - lat: Observer latitude in degrees
    ///   - decl: Sun declination in degrees
    ///   - shadowRatio: 1 for Shafi/Maliki/Hanbali, 2 for Hanafi
    /// - Returns: Hour angle in degrees from solar noon
    private func asrHourAngle(lat: Double, decl: Double, shadowRatio: Double) -> Double {
        let latRad = lat.radians
        let declRad = decl.radians

        // Asr sun altitude based on shadow ratio and latitude-declination difference
        let asrAltitude = atan(1.0 / (shadowRatio + tan(abs(latRad - declRad))))

        let cosH = (sin(asrAltitude) - sin(latRad) * sin(declRad)) /
                   (cos(latRad) * cos(declRad))

        let clampedCosH = max(-1.0, min(1.0, cosH))
        return acos(clampedCosH).degrees
    }
}

// MARK: - Angle Conversion Helpers

private extension Double {
    /// Convert degrees to radians
    var radians: Double { self * .pi / 180.0 }

    /// Convert radians to degrees
    var degrees: Double { self * 180.0 / .pi }
}
