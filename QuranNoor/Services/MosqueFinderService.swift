//
//  MosqueFinderService.swift
//  QuranNoor
//
//  Find nearby mosques using iOS MapKit (no API key required)
//

import Foundation
import MapKit
import os

import Observation

// MARK: - Distance Filter Options
enum DistanceFilter: Double, CaseIterable, Identifiable {
    case oneKm = 1000
    case threeKm = 3000
    case fiveKm = 5000
    case tenKm = 10000
    case twentyFiveKm = 25000
    case fiftyKm = 50000

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .oneKm: return "1 km"
        case .threeKm: return "3 km"
        case .fiveKm: return "5 km"
        case .tenKm: return "10 km"
        case .twentyFiveKm: return "25 km"
        case .fiftyKm: return "50 km"
        }
    }

    /// Resolve from a persisted raw value, falling back to `.fiveKm`.
    static func from(rawValue: Double) -> DistanceFilter {
        DistanceFilter(rawValue: rawValue) ?? .fiveKm
    }
}

// MARK: - Cached Search Result
struct CachedMosqueSearch {
    let mosques: [Mosque]
    let location: LocationCoordinates
    let radius: Double
    let timestamp: Date

    var isExpired: Bool {
        // Cache expires after 1 hour
        Date().timeIntervalSince(timestamp) > 3600
    }

    func matches(location: LocationCoordinates, radius: Double) -> Bool {
        // Check if coordinates are within ~100m and radius matches
        let distance = location.distanceTo(other: self.location)
        return distance < 100 && abs(radius - self.radius) < 100
    }
}

// MARK: - Mosque Finder Error
enum MosqueFinderError: LocalizedError {
    /// Only thrown by keyword search — `findNearbyMosques` now returns `[]`
    /// instead of throwing so callers can render an empty state naturally.
    case noResults
    case searchFailed
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No mosques found matching that search."
        case .searchFailed:
            return "Failed to search for mosques. Please try again."
        case .locationUnavailable:
            return "Location unavailable. Please enable location services."
        }
    }
}

// MARK: - Mosque Finder Service
@Observable
@MainActor
final class MosqueFinderService {
    // MARK: - Singleton
    static let shared = MosqueFinderService()

    // MARK: - Published Properties
    private(set) var nearbyMosques: [Mosque] = []
    private(set) var isSearching: Bool = false
    private(set) var selectedDistanceFilter: DistanceFilter = .fiveKm

    // MARK: - Private Properties
    private var cachedSearch: CachedMosqueSearch?
    private let userDefaults = UserDefaults.standard
    private let preferredRadiusKey = "mosqueSearchRadius"

    // MARK: - Initialization
    private init() {
        let saved = userDefaults.double(forKey: preferredRadiusKey)
        if saved > 0 {
            selectedDistanceFilter = DistanceFilter.from(rawValue: saved)
        }
    }

    // MARK: - Public Methods

    /// Set distance filter and persist it as the user's preferred radius.
    func setDistanceFilter(_ filter: DistanceFilter) {
        selectedDistanceFilter = filter
        userDefaults.set(filter.rawValue, forKey: preferredRadiusKey)
    }

    /// Clear cached results
    func clearCache() {
        cachedSearch = nil
    }

    /// Find mosques near a location with caching
    /// - Parameters:
    ///   - coordinates: User's location coordinates
    ///   - radiusInMeters: Search radius (default: uses selectedDistanceFilter)
    ///   - forceRefresh: Force refresh even if cache is valid
    /// - Returns: Array of mosques sorted by distance
    func findNearbyMosques(
        coordinates: LocationCoordinates,
        radiusInMeters: Double? = nil,
        forceRefresh: Bool = false
    ) async throws -> [Mosque] {
        let radius = radiusInMeters ?? selectedDistanceFilter.rawValue

        // Check cache first
        if !forceRefresh,
           let cached = cachedSearch,
           !cached.isExpired,
           cached.matches(location: coordinates, radius: radius) {
            nearbyMosques = cached.mosques
            return cached.mosques
        }

        isSearching = true
        defer { isSearching = false }

        // Create search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "mosque"

        // Define search region
        let center = CLLocationCoordinate2D(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )
        let span = MKCoordinateSpan(
            latitudeDelta: radius / 111_000, // ~111km per degree
            longitudeDelta: radius / 111_000
        )
        request.region = MKCoordinateRegion(center: center, span: span)

        // Execute search
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            // Convert results to Mosque models
            let mosques = response.mapItems.compactMap { mapItem in
                Mosque(mapItem: mapItem, userLocation: coordinates)
            }

            // Filter by actual distance (MKLocalSearch can return results outside the region)
            let filteredMosques = mosques.filter { $0.distance <= radius }

            // Sort by distance (closest first)
            let sortedMosques = filteredMosques.sorted { $0.distance < $1.distance }

            // Update published property
            nearbyMosques = sortedMosques

            // Cache the results — including empty results, so repeated taps at
            // the same radius don't pound MKLocalSearch.
            cachedSearch = CachedMosqueSearch(
                mosques: sortedMosques,
                location: coordinates,
                radius: radius,
                timestamp: Date()
            )

            AppLogger.location.info("Mosque search at \(Int(radius))m returned \(sortedMosques.count) results")

            // Return results (possibly empty). Empty is a legitimate outcome
            // for low-density areas and should drive empty-state UI, not an
            // error alert.
            return sortedMosques

        } catch {
            AppLogger.location.error("Mosque search failed: \(error.localizedDescription, privacy: .public)")
            throw MosqueFinderError.searchFailed
        }
    }

    /// Search progressively widening radii until mosques are found or the
    /// largest radius is exhausted. Auto-updates (and persists) the selected
    /// filter to whichever tier succeeded so the UI reflects the actual
    /// search distance.
    ///
    /// - Parameters:
    ///   - coordinates: User location.
    ///   - startingFilter: Radius to start with (defaults to the current
    ///     persisted preference).
    ///   - forceRefresh: Bypass cache on the first attempt only; subsequent
    ///     tiers always hit MKLocalSearch since the radius differs.
    /// - Returns: `results` (may be empty), `matchedFilter` (the radius that
    ///   produced results, or the widest tier if nothing was found), and
    ///   `didExpand` — true when the search had to step past `startingFilter`.
    func findNearbyMosquesAutoExpanding(
        coordinates: LocationCoordinates,
        startingFilter: DistanceFilter? = nil,
        forceRefresh: Bool = false
    ) async throws -> (results: [Mosque], matchedFilter: DistanceFilter, didExpand: Bool) {
        let start = startingFilter ?? selectedDistanceFilter
        let tiers = DistanceFilter.allCases.filter { $0.rawValue >= start.rawValue }

        for (index, filter) in tiers.enumerated() {
            let force = forceRefresh && index == 0
            let results = try await findNearbyMosques(
                coordinates: coordinates,
                radiusInMeters: filter.rawValue,
                forceRefresh: force
            )
            if !results.isEmpty {
                if filter != selectedDistanceFilter {
                    setDistanceFilter(filter)
                }
                return (results, filter, filter != start)
            }
        }

        // Every tier empty — settle on the widest tier so the picker reflects
        // the furthest we actually searched.
        let widest = tiers.last ?? start
        if widest != selectedDistanceFilter {
            setDistanceFilter(widest)
        }
        return ([], widest, widest != start)
    }

    /// Search mosques by name or keyword
    /// - Parameters:
    ///   - query: Search query (e.g., "Islamic Center", "Masjid Al-Noor")
    ///   - coordinates: User's location for context
    ///   - radiusInMeters: Search radius
    /// - Returns: Array of matching mosques
    func searchMosques(
        query: String,
        near coordinates: LocationCoordinates,
        radiusInMeters: Double = 10000
    ) async throws -> [Mosque] {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(query) mosque"

        let center = CLLocationCoordinate2D(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )
        let span = MKCoordinateSpan(
            latitudeDelta: radiusInMeters / 111_000,
            longitudeDelta: radiusInMeters / 111_000
        )
        request.region = MKCoordinateRegion(center: center, span: span)

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            let mosques = response.mapItems.compactMap { mapItem in
                Mosque(mapItem: mapItem, userLocation: coordinates)
            }

            let sortedMosques = mosques.sorted { $0.distance < $1.distance }

            self.nearbyMosques = sortedMosques

            guard !sortedMosques.isEmpty else {
                throw MosqueFinderError.noResults
            }

            return sortedMosques

        } catch {
            throw MosqueFinderError.searchFailed
        }
    }

    /// Get the closest mosque
    func getClosestMosque(to coordinates: LocationCoordinates) async throws -> Mosque? {
        let mosques = try await findNearbyMosques(coordinates: coordinates)
        return mosques.first
    }

    /// Get map items for mosques (for MapKit integration)
    func getMapItems(from mosques: [Mosque]) -> [MKMapItem] {
        return mosques.map { mosque in
            let location = CLLocation(
                latitude: mosque.coordinates.latitude,
                longitude: mosque.coordinates.longitude
            )
            // iOS 26+: Use new MKMapItem(location:address:) initializer
            let address = MKAddress(fullAddress: mosque.address, shortAddress: nil)
            let mapItem = MKMapItem(location: location, address: address)
            mapItem.name = mosque.name
            mapItem.phoneNumber = mosque.phoneNumber
            return mapItem
        }
    }
}

// MARK: - LocationCoordinates Distance Extension
extension LocationCoordinates {
    /// Calculate distance to another coordinate in meters
    func distanceTo(other: LocationCoordinates) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}
