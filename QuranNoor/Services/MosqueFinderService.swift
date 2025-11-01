//
//  MosqueFinderService.swift
//  QuranNoor
//
//  Find nearby mosques using iOS MapKit (no API key required)
//

import Foundation
import MapKit
import Combine

// MARK: - Mosque Finder Error
enum MosqueFinderError: LocalizedError {
    case noResults
    case searchFailed

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No mosques found nearby. Try increasing the search radius."
        case .searchFailed:
            return "Failed to search for mosques. Please try again."
        }
    }
}

// MARK: - Mosque Finder Service
@MainActor
class MosqueFinderService: ObservableObject {
    // MARK: - Published Properties
    @Published var nearbyMosques: [Mosque] = []
    @Published var isSearching: Bool = false

    // MARK: - Public Methods

    /// Find mosques near a location
    /// - Parameters:
    ///   - coordinates: User's location coordinates
    ///   - radiusInMeters: Search radius (default: 5000m = 5km)
    /// - Returns: Array of mosques sorted by distance
    func findNearbyMosques(
        coordinates: LocationCoordinates,
        radiusInMeters: Double = 5000
    ) async throws -> [Mosque] {
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
            latitudeDelta: radiusInMeters / 111_000, // ~111km per degree
            longitudeDelta: radiusInMeters / 111_000
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

            // Sort by distance (closest first)
            let sortedMosques = mosques.sorted { $0.distance < $1.distance }

            // Update published property
            self.nearbyMosques = sortedMosques

            guard !sortedMosques.isEmpty else {
                throw MosqueFinderError.noResults
            }

            return sortedMosques

        } catch {
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
}
