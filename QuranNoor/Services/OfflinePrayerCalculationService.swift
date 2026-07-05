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
            case .tehran:
                return MethodParameters(fajrAngle: 17.7, ishaAngle: 14.0, ishaInterval: nil)
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
        madhab: Madhab = .shafi,
        timeZone: TimeZone = .current
    ) throws -> DailyPrayerTimes {

        let params = MethodParameters.forMethod(method)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            throw PrayerTimeError.calculationFailed
        }

        let lat = coordinates.latitude
        let lng = coordinates.longitude
        let timeZoneOffset = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Julian date for the given day
        let jd = julianDate(year: year, month: month, day: day)

        // Solar position for the day
        let sunDeclination = sunDeclination(jd: jd)
        let equationOfTime = equationOfTime(jd: jd)

        // Dhuhr (solar noon) in local clock hours, normalized into 0..<24 so
        // extreme timezone/longitude combinations (e.g. Kiritimati at UTC+14)
        // don't push the whole day out of range.
        let rawDhuhr = 12.0 + timeZoneOffset - lng / 15.0 - equationOfTime
        let dhuhrHours = (rawDhuhr.truncatingRemainder(dividingBy: 24.0) + 24.0)
            .truncatingRemainder(dividingBy: 24.0)

        // Sunrise and Sunset (0.833° accounts for atmospheric refraction).
        // During polar day/night the sun never crosses the horizon; fall back
        // to the geometry of the nearest latitude where it does (aqrab
        // al-bilad convention, clamped to ±48°) so the app still produces
        // usable times everywhere on Earth.
        let effectiveLat: Double = hourAngle(lat: lat, decl: sunDeclination, angle: 0.833) != nil
            ? lat
            : (lat >= 0 ? 48.0 : -48.0)
        guard let sunriseHA = hourAngle(lat: effectiveLat, decl: sunDeclination, angle: 0.833) else {
            // Unreachable: the sun always crosses 0.833° below the horizon at 48°
            throw PrayerTimeError.calculationFailed
        }
        let sunriseHours = dhuhrHours - sunriseHA / 15.0
        let sunsetHours = dhuhrHours + sunriseHA / 15.0

        // Night duration (sunset → next sunrise) for high-latitude rules
        let nightDuration = 24.0 - (sunsetHours - sunriseHours)

        // Fajr — Moonsighting Committee uses season-adjusted twilight; other
        // methods fall back to the angle-based rule when the sun never reaches
        // the required depression angle (high latitudes in summer). The
        // angle-based rule matches Aladhan's ANGLE_BASED adjustment, so the
        // online and offline paths agree.
        let fajrHours: Double
        if method == .moonsightingCommittee {
            if abs(lat) >= 55 {
                // Moonsighting Committee prescribes 1/7 of the night above 55°
                fajrHours = sunriseHours - nightDuration / 7.0
            } else {
                let minutes = moonsightingFajrMinutes(latitude: lat, dayOfYear: dayOfYear, year: year)
                fajrHours = sunriseHours - minutes / 60.0
            }
        } else if let fajrHA = hourAngle(lat: effectiveLat, decl: sunDeclination, angle: params.fajrAngle) {
            fajrHours = dhuhrHours - fajrHA / 15.0
        } else {
            // Angle-based rule: twilight portion = (angle / 60) of the night
            fajrHours = sunriseHours - (params.fajrAngle / 60.0) * nightDuration
        }

        // Asr - shadow ratio depends on madhab
        let shadowRatio: Double = madhab == .hanafi ? 2.0 : 1.0
        let asrHours = dhuhrHours + asrHourAngle(lat: effectiveLat, decl: sunDeclination, shadowRatio: shadowRatio) / 15.0

        // Maghrib = sunset
        let maghribHours = sunsetHours

        // Isha — same policy as Fajr
        let ishaHours: Double
        if method == .moonsightingCommittee {
            if abs(lat) >= 55 {
                ishaHours = sunsetHours + nightDuration / 7.0
            } else {
                let minutes = moonsightingIshaMinutes(latitude: lat, dayOfYear: dayOfYear, year: year)
                ishaHours = sunsetHours + minutes / 60.0
            }
        } else if let ishaInterval = params.ishaInterval {
            ishaHours = maghribHours + ishaInterval / 60.0
        } else {
            let ishaAngle = params.ishaAngle ?? 17.0
            if let ishaHA = hourAngle(lat: effectiveLat, decl: sunDeclination, angle: ishaAngle) {
                ishaHours = dhuhrHours + ishaHA / 15.0
            } else {
                // Angle-based rule: twilight portion = (angle / 60) of the night
                ishaHours = sunsetHours + (ishaAngle / 60.0) * nightDuration
            }
        }

        // Imsak = 10 minutes before Fajr
        let imsakHours = fajrHours - 10.0 / 60.0

        // Islamic midnight = midpoint between sunset and sunrise (next day)
        let midnightHours = sunsetHours + nightDuration / 2.0

        // Night thirds
        let firstThirdHours = sunsetHours + nightDuration / 3.0
        let lastThirdHours = sunsetHours + 2.0 * nightDuration / 3.0

        // Convert hours to Date objects
        guard let baseDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            throw PrayerTimeError.calculationFailed
        }

        // Convert local clock hours (offset from local midnight of `date`) to
        // absolute instants. No wrapping: an Isha that crosses midnight must
        // land on the next calendar day as a correct future instant.
        func hoursToDate(_ hours: Double) -> Date {
            baseDate.addingTimeInterval(hours * 3600.0)
        }

        // Validate: every value must be finite (NaN would corrupt Date math)
        let coreHours = [fajrHours, sunriseHours, dhuhrHours, asrHours, maghribHours, ishaHours]
        guard coreHours.allSatisfy(\.isFinite) else {
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

    // MARK: - Moonsighting Committee (season-adjusted twilight)
    //
    // The Moonsighting Committee method does not use fixed depression angles.
    // Fajr/Isha are offsets from sunrise/sunset, piecewise-linearly
    // interpolated over days since the winter solstice, fitted to
    // moonsighting.com observational data. Constants match adhan-swift's
    // Astronomical.seasonAdjustedMorningTwilight / EveningTwilight
    // (general shafaq), which Aladhan's method 15 also implements.

    /// Minutes before sunrise for Moonsighting Committee Fajr
    private func moonsightingFajrMinutes(latitude: Double, dayOfYear: Int, year: Int) -> Double {
        let latFactor = abs(latitude) / 55.0
        return seasonalAdjustment(
            a: 75.0 + 28.65 * latFactor,
            b: 75.0 + 19.44 * latFactor,
            c: 75.0 + 32.74 * latFactor,
            d: 75.0 + 48.10 * latFactor,
            dayOfYear: dayOfYear, year: year, latitude: latitude
        )
    }

    /// Minutes after sunset for Moonsighting Committee Isha (general shafaq)
    private func moonsightingIshaMinutes(latitude: Double, dayOfYear: Int, year: Int) -> Double {
        let latFactor = abs(latitude) / 55.0
        return seasonalAdjustment(
            a: 75.0 + 25.60 * latFactor,
            b: 75.0 + 2.05 * latFactor,
            c: 75.0 - 9.21 * latFactor,
            d: 75.0 + 6.14 * latFactor,
            dayOfYear: dayOfYear, year: year, latitude: latitude
        )
    }

    /// Piecewise-linear seasonal interpolation between the four anchor values
    private func seasonalAdjustment(
        a: Double, b: Double, c: Double, d: Double,
        dayOfYear: Int, year: Int, latitude: Double
    ) -> Double {
        let dyy = Double(daysSinceSolstice(dayOfYear: dayOfYear, year: year, latitude: latitude))
        switch dyy {
        case ..<91:  return a + (b - a) / 91.0 * dyy
        case ..<137: return b + (c - b) / 46.0 * (dyy - 91)
        case ..<183: return c + (d - c) / 46.0 * (dyy - 137)
        case ..<229: return d + (c - d) / 46.0 * (dyy - 183)
        case ..<275: return c + (b - c) / 46.0 * (dyy - 229)
        default:     return b + (a - b) / 91.0 * (dyy - 275)
        }
    }

    /// Days elapsed since the nearest winter solstice (hemisphere-aware)
    private func daysSinceSolstice(dayOfYear: Int, year: Int, latitude: Double) -> Int {
        let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
        let daysInYear = isLeap ? 366 : 365
        if latitude >= 0 {
            var days = dayOfYear + 10
            if days >= daysInYear { days -= daysInYear }
            return days
        } else {
            var days = dayOfYear - (isLeap ? 173 : 172)
            if days < 0 { days += daysInYear }
            return days
        }
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
    /// - Returns: Hour angle in degrees, or nil if angle is unreachable at this latitude
    private func hourAngle(lat: Double, decl: Double, angle: Double) -> Double? {
        let latRad = lat.radians
        let declRad = decl.radians
        let angleRad = angle.radians

        let cosH = (sin(-angleRad) - sin(latRad) * sin(declRad)) /
                   (cos(latRad) * cos(declRad))

        // If cosH is outside [-1, 1], the angle is unreachable at this latitude
        guard cosH >= -1.0 && cosH <= 1.0 else {
            return nil
        }
        return acos(cosH).degrees
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
