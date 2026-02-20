//
//  QiblaViewModel.swift
//  QuranNoor
//
//  ViewModel for Qibla compass with real-time direction
//

import Foundation
import CoreLocation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
class QiblaViewModel {
    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Observable Properties
    var qiblaDirection: Double = 0  // Direction to Qibla from North
    var distanceToKaaba: Double = 0
    var userLocation: String = "Locating..."
    var currentCoordinates: LocationCoordinates?
    var isLoading: Bool = true
    var showError: Bool = false
    var errorMessage: String?

    // Location management
    var showLocationPicker: Bool = false
    var savedLocations: [SavedLocation] = []
    var isUsingManualLocation: Bool = false

    // MARK: - Computed Properties

    /// Device compass heading — reads directly from LocationService (@Observable tracks this)
    var deviceHeading: Double {
        locationService.heading
    }

    /// Compass accuracy — derived from LocationService heading accuracy
    var compassAccuracy: String {
        let accuracy = locationService.headingAccuracy
        if accuracy < 0 {
            return "Calibrating..."
        } else if accuracy <= 5 {
            return "High"
        } else if accuracy <= 15 {
            return "Medium"
        } else {
            return "Low"
        }
    }

    /// Needle rotation - points to Qibla direction relative to device heading
    var needleRotation: Double {
        return qiblaDirection - deviceHeading
    }

    /// Check if device is aligned with Qibla (within ±5 degrees)
    var isAlignedWithQibla: Bool {
        let relativeAngle = (qiblaDirection - deviceHeading).truncatingRemainder(dividingBy: 360)
        let normalizedAngle = relativeAngle < 0 ? relativeAngle + 360 : relativeAngle
        return abs(normalizedAngle) < 5 || abs(normalizedAngle - 360) < 5
    }

    // MARK: - Private Properties
    private let locationService = LocationService.shared
    private let qiblaService = QiblaService()

    // UserDefaults keys
    private let savedLocationsKey = "saved_locations"
    private let manualLocationKey = "manual_location"

    // MARK: - Initialization
    init() {
        loadSavedLocations()
        loadManualLocationPreference()
    }

    // MARK: - Public Methods

    /// Initialize compass - request permissions and start updates
    func initialize() async {
        isLoading = true

        // Check if using manual location
        if isUsingManualLocation, let manualLoc = loadManualLocation() {
            userLocation = manualLoc.name
            currentCoordinates = manualLoc.coordinates
            await calculateQibla(from: manualLoc.coordinates)
            locationService.startHeadingUpdates()
            isLoading = false
            return
        }

        // Check if location services are available
        guard locationService.isLocationServicesEnabled() else {
            showErrorAlert("Location services are disabled. Please enable in Settings.")
            isLoading = false
            return
        }

        // Request permission if needed
        if !locationService.hasLocationPermission() {
            locationService.requestLocationPermission()
        }

        // Get location and calculate Qibla
        await updateQiblaDirection()

        // Start compass heading updates
        locationService.startHeadingUpdates()

        isLoading = false
    }

    /// Refresh current location and recalculate Qibla
    func refresh() async {
        isUsingManualLocation = false
        saveManualLocationPreference(false)
        await updateQiblaDirection()
    }

    /// Set manual location
    func setManualLocation(coordinates: LocationCoordinates, name: String) async {
        userLocation = name
        currentCoordinates = coordinates
        isUsingManualLocation = true

        // Save manual location
        let location = SavedLocation(name: name, coordinates: coordinates)
        saveManualLocation(location)
        saveManualLocationPreference(true)

        await calculateQibla(from: coordinates)
    }

    /// Use saved location
    func useSavedLocation(_ location: SavedLocation) async {
        userLocation = location.name
        currentCoordinates = location.coordinates
        isUsingManualLocation = true

        saveManualLocation(location)
        saveManualLocationPreference(true)

        await calculateQibla(from: location.coordinates)
    }

    /// Save current location for later use
    func saveCurrentLocation(withName name: String) {
        guard let coordinates = currentCoordinates else { return }

        let location = SavedLocation(name: name, coordinates: coordinates)
        var locations = savedLocations
        locations.append(location)
        savedLocations = locations

        saveSavedLocations(locations)
    }

    /// Delete saved location
    func deleteSavedLocation(_ location: SavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
        saveSavedLocations(savedLocations)
    }

    /// Use GPS location
    func useGPSLocation() async {
        isUsingManualLocation = false
        saveManualLocationPreference(false)
        await updateQiblaDirection()
    }

    /// Pause compass tracking (called when view disappears or tab is inactive)
    func pause() {
        locationService.stopHeadingUpdates()
    }

    /// Resume compass tracking (called when view appears or tab becomes active)
    func resume() {
        locationService.startHeadingUpdates()
    }

    // MARK: - Private Methods

    private func updateQiblaDirection() async {
        do {
            let (coordinates, city) = try await locationService.getCurrentLocationWithCity()
            userLocation = city
            currentCoordinates = coordinates

            await calculateQibla(from: coordinates)
        } catch {
            showErrorAlert(error.localizedDescription)
        }
    }

    private func calculateQibla(from location: LocationCoordinates) async {
        // Store current coordinates
        currentCoordinates = location

        // Calculate direction to Qibla
        qiblaDirection = qiblaService.calculateQiblaDirection(from: location)

        // Calculate distance
        distanceToKaaba = qiblaService.calculateDistanceToKaaba(from: location)
    }

    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }

    // MARK: - Helper Methods

    func getDirectionText() -> String {
        let cardinal = qiblaService.getCardinalDirection(from: qiblaDirection)
        return String(format: "%.0f° %@", qiblaDirection, cardinal)
    }

    func getDistanceText() -> String {
        return qiblaService.formatDistance(distanceToKaaba)
    }

    func getAlignmentInstruction() -> String {
        let relativeAngle = (qiblaDirection - deviceHeading).truncatingRemainder(dividingBy: 360)
        let normalizedAngle = relativeAngle < 0 ? relativeAngle + 360 : relativeAngle

        if normalizedAngle < 180 {
            return "Turn right \(Int(normalizedAngle))°"
        } else {
            return "Turn left \(Int(360 - normalizedAngle))°"
        }
    }

    // MARK: - Storage Methods

    private func loadSavedLocations() {
        guard let data = UserDefaults.standard.data(forKey: savedLocationsKey),
              let locations = try? Self.decoder.decode([SavedLocation].self, from: data) else {
            return
        }
        savedLocations = locations
    }

    private func saveSavedLocations(_ locations: [SavedLocation]) {
        if let encoded = try? Self.encoder.encode(locations) {
            UserDefaults.standard.set(encoded, forKey: savedLocationsKey)
        }
    }

    private func loadManualLocation() -> SavedLocation? {
        guard let data = UserDefaults.standard.data(forKey: manualLocationKey),
              let location = try? Self.decoder.decode(SavedLocation.self, from: data) else {
            return nil
        }
        return location
    }

    private func saveManualLocation(_ location: SavedLocation) {
        if let encoded = try? Self.encoder.encode(location) {
            UserDefaults.standard.set(encoded, forKey: manualLocationKey)
        }
    }

    private func loadManualLocationPreference() {
        isUsingManualLocation = UserDefaults.standard.bool(forKey: "is_using_manual_location")
    }

    private func saveManualLocationPreference(_ isManual: Bool) {
        UserDefaults.standard.set(isManual, forKey: "is_using_manual_location")
    }
}

// MARK: - SavedLocation Model
struct SavedLocation: Identifiable, Codable {
    let id: UUID
    let name: String
    let coordinates: LocationCoordinates
    let savedDate: Date

    init(name: String, coordinates: LocationCoordinates) {
        self.id = UUID()
        self.name = name
        self.coordinates = coordinates
        self.savedDate = Date()
    }
}
