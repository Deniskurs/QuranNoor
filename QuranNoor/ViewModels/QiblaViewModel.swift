//
//  QiblaViewModel.swift
//  QuranNoor
//
//  ViewModel for Qibla compass with real-time direction
//

import Foundation
import CoreLocation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class QiblaViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var qiblaDirection: Double = 0  // Direction to Qibla from North
    @Published var deviceHeading: Double = 0  // Current device compass heading
    @Published var distanceToKaaba: Double = 0
    @Published var userLocation: String = "Locating..."
    @Published var currentCoordinates: LocationCoordinates?
    @Published var isLoading: Bool = true
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var compassAccuracy: String = "Calibrating..."

    // Location management
    @Published var showLocationPicker: Bool = false
    @Published var savedLocations: [SavedLocation] = []
    @Published var isUsingManualLocation: Bool = false

    // MARK: - Computed Properties
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
    private var cancellables = Set<AnyCancellable>()
    private var previousAlignmentState = false

    #if canImport(UIKit)
    private let hapticGenerator = UINotificationFeedbackGenerator()
    #endif

    // UserDefaults keys
    private let savedLocationsKey = "saved_locations"
    private let manualLocationKey = "manual_location"

    // MARK: - Initialization
    init() {
        setupLocationObserver()
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

    // MARK: - Private Methods

    private func setupLocationObserver() {
        // Observe location updates
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { @MainActor [weak self] in
                    await self?.calculateQibla(from: location)
                }
            }
            .store(in: &cancellables)

        // Observe compass heading updates
        locationService.$heading
            .sink { [weak self] heading in
                guard let self = self else { return }
                self.deviceHeading = heading

                // Check alignment and trigger haptic feedback on state change
                let isNowAligned = self.isAlignedWithQibla
                if isNowAligned && !self.previousAlignmentState {
                    // Just became aligned - trigger success haptic
                    self.triggerAlignmentHaptic()
                }
                self.previousAlignmentState = isNowAligned
            }
            .store(in: &cancellables)

        // Observe heading accuracy updates
        locationService.$headingAccuracy
            .sink { [weak self] accuracy in
                guard let self = self else { return }
                self.updateCompassAccuracyFromCL(accuracy: accuracy)
            }
            .store(in: &cancellables)
    }

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

    private func updateCompassAccuracyFromCL(accuracy: CLLocationDirection) {
        // CLLocationDirection accuracy:
        // - Negative value means invalid
        // - 0-5 degrees: High accuracy
        // - 5-15 degrees: Medium accuracy
        // - >15 degrees: Low accuracy
        if accuracy < 0 {
            compassAccuracy = "Calibrating..."
        } else if accuracy <= 5 {
            compassAccuracy = "High"
        } else if accuracy <= 15 {
            compassAccuracy = "Medium"
        } else {
            compassAccuracy = "Low"
        }
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

    // MARK: - Storage Methods

    private func loadSavedLocations() {
        guard let data = UserDefaults.standard.data(forKey: savedLocationsKey),
              let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            return
        }
        savedLocations = locations
    }

    private func saveSavedLocations(_ locations: [SavedLocation]) {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: savedLocationsKey)
        }
    }

    private func loadManualLocation() -> SavedLocation? {
        guard let data = UserDefaults.standard.data(forKey: manualLocationKey),
              let location = try? JSONDecoder().decode(SavedLocation.self, from: data) else {
            return nil
        }
        return location
    }

    private func saveManualLocation(_ location: SavedLocation) {
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: manualLocationKey)
        }
    }

    private func loadManualLocationPreference() {
        isUsingManualLocation = UserDefaults.standard.bool(forKey: "is_using_manual_location")
    }

    private func saveManualLocationPreference(_ isManual: Bool) {
        UserDefaults.standard.set(isManual, forKey: "is_using_manual_location")
    }

    /// Trigger haptic feedback when device aligns with Qibla
    private func triggerAlignmentHaptic() {
        #if canImport(UIKit)
        hapticGenerator.notificationOccurred(.success)
        #endif
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
