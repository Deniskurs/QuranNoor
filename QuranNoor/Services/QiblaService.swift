//
//  QiblaService.swift
//  QuranNoor
//
//  Calculates Qibla direction and distance to Kaaba
//

import Foundation
import CoreLocation

// MARK: - Qibla Service
class QiblaService {
    // MARK: - Constants
    private let kaabaCoordinates = CLLocationCoordinate2D(
        latitude: 21.4225,
        longitude: 39.8262
    )

    // MARK: - Public Methods

    /// Calculate Qibla direction from user location
    /// - Parameter userLocation: User's current coordinates
    /// - Returns: Direction in degrees (0-360) where 0 is North
    func calculateQiblaDirection(from userLocation: LocationCoordinates) -> Double {
        let userLat = degreesToRadians(userLocation.latitude)
        let userLon = degreesToRadians(userLocation.longitude)
        let kaabaLat = degreesToRadians(kaabaCoordinates.latitude)
        let kaabaLon = degreesToRadians(kaabaCoordinates.longitude)

        let deltaLon = kaabaLon - userLon

        // Calculate bearing using formula
        let y = sin(deltaLon) * cos(kaabaLat)
        let x = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(deltaLon)

        var bearing = atan2(y, x)
        bearing = radiansToDegrees(bearing)

        // Normalize to 0-360
        bearing = (bearing + 360).truncatingRemainder(dividingBy: 360)

        return bearing
    }

    /// Calculate distance to Kaaba in kilometers
    /// - Parameter userLocation: User's current coordinates
    /// - Returns: Distance in kilometers
    func calculateDistanceToKaaba(from userLocation: LocationCoordinates) -> Double {
        let userCLLocation = CLLocation(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude
        )
        let kaabaLocation = CLLocation(
            latitude: kaabaCoordinates.latitude,
            longitude: kaabaCoordinates.longitude
        )

        // Distance in meters
        let distanceMeters = userCLLocation.distance(from: kaabaLocation)

        // Convert to kilometers
        return distanceMeters / 1000.0
    }

    /// Get cardinal direction from degrees
    /// - Parameter degrees: Direction in degrees
    /// - Returns: Cardinal direction string (e.g., "North-East")
    func getCardinalDirection(from degrees: Double) -> String {
        let normalizedDegrees = degrees.truncatingRemainder(dividingBy: 360)

        switch normalizedDegrees {
        case 0..<22.5, 337.5..<360:
            return "North"
        case 22.5..<67.5:
            return "North-East"
        case 67.5..<112.5:
            return "East"
        case 112.5..<157.5:
            return "South-East"
        case 157.5..<202.5:
            return "South"
        case 202.5..<247.5:
            return "South-West"
        case 247.5..<292.5:
            return "West"
        case 292.5..<337.5:
            return "North-West"
        default:
            return "Unknown"
        }
    }

    /// Format distance with appropriate unit
    /// - Parameter kilometers: Distance in kilometers
    /// - Returns: Formatted string with unit
    func formatDistance(_ kilometers: Double) -> String {
        if kilometers < 1 {
            return String(format: "%.0f m", kilometers * 1000)
        } else if kilometers < 100 {
            return String(format: "%.1f km", kilometers)
        } else {
            return String(format: "%.0f km", kilometers)
        }
    }

    // MARK: - Private Helpers

    private func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }

    private func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
}
