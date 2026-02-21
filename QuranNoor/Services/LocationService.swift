//
//  LocationService.swift
//  QuranNoor
//
//  Manages device location using CoreLocation for prayer time calculations
//

import Foundation
import CoreLocation
import MapKit
import Observation

// Using MapKit (MKReverseGeocodingRequest) for reverse geocoding to obtain city and country

// MARK: - Location Service Error
enum LocationServiceError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .locationUnavailable:
            return "Unable to determine your location. Please check your device settings."
        case .geocodingFailed:
            return "Failed to determine city name from location."
        }
    }
}

// MARK: - Location Service
@Observable
@MainActor
class LocationService: NSObject {
    // MARK: - Singleton
    static let shared = LocationService()

    // MARK: - Observable Properties
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: LocationCoordinates?
    var cityName: String?
    var countryName: String?

    // Compass heading
    var heading: Double = 0
    var headingAccuracy: CLLocationDirection = -1

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard

    // UserDefaults keys
    private let lastLocationKey = "lastKnownLocation"
    private let lastCityKey = "lastKnownCity"
    private let lastCountryKey = "lastKnownCountry"

    // MARK: - Heading Throttle (Performance: reduce CPU usage from high-frequency updates)
    private var lastHeadingUpdateTime: Date = .distantPast
    private let headingUpdateInterval: TimeInterval = 0.1 // 10fps max, sufficient for smooth compass
    private var lastReportedHeading: Double = 0
    private let headingChangeThreshold: Double = 1.0 // Only update if changed by at least 1 degree

    // MARK: - Continuation
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: - Initializer
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus

        // Load cached location
        loadCachedLocation()
    }

    // MARK: - Public Methods

    /// Convenience: whether the app is currently authorized for location access
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// Request location permission from user
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get current device location
    func getCurrentLocation() async throws -> LocationCoordinates {
        // Check authorization
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationServiceError.permissionDenied
        }

        // Request location
        let location: CLLocation = try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation?.resume(throwing: CancellationError())
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }

        // Convert to LocationCoordinates
        return LocationCoordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    /// Get current location with city name (reverse geocoding)
    func getCurrentLocationWithCity() async throws -> (coordinates: LocationCoordinates, city: String) {
        let coordinates = try await getCurrentLocation()
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)

        // Try geocoding — retry up to 3 times with backoff on timeout
        for attempt in 1...3 {
            if let city = await reverseGeocode(location: location) {
                return (coordinates, city)
            }
            // Backoff: 1s, 2s between retries
            if attempt < 3 {
                try? await Task.sleep(for: .seconds(attempt))
            }
        }

        // All attempts failed — use cached city if available
        if let cachedCity = self.cityName {
            return (coordinates, cachedCity)
        }

        return (coordinates, "Unknown City")
    }

    /// Reverse geocode using MKReverseGeocodingRequest (iOS 26)
    private func reverseGeocode(location: CLLocation) async -> String? {
        do {
            guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
            let mapItems = try await request.mapItems

            if let addressRep = mapItems.first?.addressRepresentations {
                let city = addressRep.cityName ?? "Unknown City"
                let country = addressRep.regionName ?? ""

                self.cityName = city
                self.countryName = country
                cacheLocation(LocationCoordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), city: city, country: country)

                return city
            }
        } catch {
            #if DEBUG
            print("⚠️ Reverse geocoding failed (will retry): \(error.localizedDescription)")
            #endif
        }
        return nil
    }

    /// Check if location services are enabled (derived from authorization status to avoid blocking calls on main thread)
    func isLocationServicesEnabled() -> Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .restricted, .denied:
            // If we have a concrete status, Core Location services are available at the system level
            return true
        case .notDetermined:
            // Not determined yet — treat as enabled so UI can prompt for permission
            return true
        @unknown default:
            return true
        }
    }

    /// Check if app has location permission
    func hasLocationPermission() -> Bool {
        return isAuthorized
    }

    /// Start receiving compass heading updates
    func startHeadingUpdates() {
        guard CLLocationManager.headingAvailable() else {
            #if DEBUG
            print("⚠️ Heading not available on this device")
            #endif
            return
        }
        locationManager.startUpdatingHeading()
    }

    /// Stop receiving compass heading updates
    func stopHeadingUpdates() {
        locationManager.stopUpdatingHeading()
    }

    // MARK: - Private Methods

    private func loadCachedLocation() {
        // Load cached location
        if let locationData = userDefaults.data(forKey: lastLocationKey),
           let location = try? Self.decoder.decode(LocationCoordinates.self, from: locationData) {
            currentLocation = location
        }

        // Load cached city names
        cityName = userDefaults.string(forKey: lastCityKey)
        countryName = userDefaults.string(forKey: lastCountryKey)
    }

    private func cacheLocation(_ coordinates: LocationCoordinates, city: String, country: String) {
        // Cache location
        if let encoded = try? Self.encoder.encode(coordinates) {
            userDefaults.set(encoded, forKey: lastLocationKey)
        }

        // Cache city names
        userDefaults.set(city, forKey: lastCityKey)
        userDefaults.set(country, forKey: lastCountryKey)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            let coordinates = LocationCoordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            currentLocation = coordinates
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: LocationServiceError.locationUnavailable)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            // Throttle updates for performance (max 10fps)
            let now = Date()
            let timeSinceLastUpdate = now.timeIntervalSince(lastHeadingUpdateTime)
            guard timeSinceLastUpdate >= headingUpdateInterval else { return }

            // Use magnetic heading (trueHeading requires location permission and GPS)
            let magneticHeading = newHeading.magneticHeading

            // Only update if heading is valid (>= 0) and changed significantly
            if magneticHeading >= 0 {
                let headingChange = abs(magneticHeading - lastReportedHeading)
                // Account for wrap-around at 360 degrees
                let normalizedChange = min(headingChange, 360 - headingChange)

                if normalizedChange >= headingChangeThreshold {
                    heading = magneticHeading
                    headingAccuracy = newHeading.headingAccuracy
                    lastReportedHeading = magneticHeading
                    lastHeadingUpdateTime = now
                }
            }
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Return true to allow iOS to display the calibration screen when needed
        // This shows the "figure-8" motion prompt to calibrate the compass
        return true
    }
}

