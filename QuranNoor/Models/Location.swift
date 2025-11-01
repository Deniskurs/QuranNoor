//
//  Location.swift
//  QuraanNoor
//
//  Location data model
//

import Foundation
import CoreLocation

// MARK: - Location Coordinates
struct LocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let accuracy: Double?

    init(latitude: Double, longitude: Double, altitude: Double? = nil, accuracy: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
    }

    init(from clLocation: CLLocation) {
        self.latitude = clLocation.coordinate.latitude
        self.longitude = clLocation.coordinate.longitude
        self.altitude = clLocation.altitude
        self.accuracy = clLocation.horizontalAccuracy
    }
}

// MARK: - Location Info
struct LocationInfo: Codable {
    let coordinates: LocationCoordinates
    let city: String?
    let country: String?
    let timezone: String?
    let lastUpdated: Date

    init(coordinates: LocationCoordinates, city: String? = nil, country: String? = nil, timezone: String? = nil) {
        self.coordinates = coordinates
        self.city = city
        self.country = country
        self.timezone = timezone
        self.lastUpdated = Date()
    }
}

// MARK: - Qibla Info
struct QiblaInfo {
    let direction: Double  // Degrees from north (0-360)
    let distance: Double   // Kilometers to Kaaba

    // Kaaba coordinates
    static let kaabaCoordinates = LocationCoordinates(
        latitude: 21.4225,
        longitude: 39.8262
    )
}
