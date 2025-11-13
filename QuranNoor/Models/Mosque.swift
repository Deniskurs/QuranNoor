//
//  Mosque.swift
//  QuranNoor
//
//  Data model for mosque locations
//

import Foundation
import MapKit

// MARK: - Mosque Model
struct Mosque: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let coordinates: LocationCoordinates
    let distance: Double // meters from user
    let phoneNumber: String?
    let website: String?

    /// Distance in kilometers
    var distanceInKm: Double {
        distance / 1000.0
    }

    /// Distance in miles
    var distanceInMiles: Double {
        distance / 1609.34
    }

    /// Formatted distance string (km)
    var formattedDistance: String {
        if distanceInKm < 1 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distanceInKm)
        }
    }

    // MARK: - Equatable
    static func == (lhs: Mosque, rhs: Mosque) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Mosque from MKMapItem
extension Mosque {
    /// Initialize from MapKit search result
    init?(mapItem: MKMapItem, userLocation: LocationCoordinates) {
        guard let name = mapItem.name else { return nil }

        self.name = name

        // Address (iOS 26+ uses addressRepresentations)
        if let addressReps = mapItem.addressRepresentations,
           let fullAddr = addressReps.fullAddress(includingRegion: true, singleLine: true) {
            self.address = fullAddr
        } else {
            self.address = "Address unavailable"
        }

        // Coordinates (iOS 26+ uses mapItem.location - not optional)
        let location = mapItem.location
        self.coordinates = LocationCoordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        // Calculate distance from user
        let userCLLocation = CLLocation(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude
        )
        self.distance = userCLLocation.distance(from: location)

        // Contact info
        self.phoneNumber = mapItem.phoneNumber
        self.website = mapItem.url?.absoluteString
    }
}
