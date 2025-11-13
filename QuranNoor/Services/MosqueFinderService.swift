//
//  MosqueFinderService.swift
//  QuranNoor
//
//  Find nearby mosques using iOS MapKit (no API key required)
//

import Foundation
import MapKit
import Combine
import Observation

// MARK: - Distance Filter Options
enum DistanceFilter: Double, CaseIterable, Identifiable {
    case oneKm = 1000
    case threeKm = 3000
    case fiveKm = 5000
    case tenKm = 10000

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .oneKm: return "1 km"
        case .threeKm: return "3 km"
        case .fiveKm: return "5 km"
        case .tenKm: return "10 km"
        }
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
    case noResults
    case searchFailed
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No mosques found nearby. Try increasing the search radius."
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

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Set distance filter
    /// - Parameter filter: The distance filter to apply
    func setDistanceFilter(_ filter: DistanceFilter) {
        selectedDistanceFilter = filter
        print("📍 Distance filter set to: \(filter.displayName)")
    }

    /// Clear cached results
    func clearCache() {
        cachedSearch = nil
        print("🗑️ Mosque search cache cleared")
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
            print("📦 Using cached mosque search results")
            nearbyMosques = cached.mosques
            return cached.mosques
        }

        isSearching = true
        defer { isSearching = false }

        print("🔍 Searching for mosques within \(radius / 1000)km...")

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

            // Cache the results
            cachedSearch = CachedMosqueSearch(
                mosques: sortedMosques,
                location: coordinates,
                radius: radius,
                timestamp: Date()
            )

            print("✅ Found \(sortedMosques.count) mosques within \(radius / 1000)km")

            guard !sortedMosques.isEmpty else {
                throw MosqueFinderError.noResults
            }

            return sortedMosques

        } catch is MosqueFinderError {
            throw MosqueFinderError.noResults
        } catch {
            print("❌ Mosque search failed: \(error.localizedDescription)")
            throw MosqueFinderError.searchFailed
        }
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
