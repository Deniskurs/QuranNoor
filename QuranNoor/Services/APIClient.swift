//
//  APIClient.swift
//  QuranNoor
//
//  Generic network layer for Islamic APIs (AlQuran.cloud, Aladhan.com)
//

import Foundation
import Combine

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(Int)
    case noData
    case cacheError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .noData:
            return "No data received from server"
        case .cacheError:
            return "Failed to cache data"
        }
    }
}

// MARK: - API Endpoint
enum APIEndpoint {
    // AlQuran.cloud endpoints
    case quranEdition(String) // e.g., "quran/ar.alafasy" or "quran/en.sahih"
    case surah(Int, String) // surahNumber, edition
    case verse(String, Int, Int) // edition, surahNumber, verseNumber
    case editions(String, String) // format (text/audio), language
    case search(String, String) // query, surah

    // Aladhan.com endpoints
    case timings(Double, Double, String, String) // lat, lon, method, date
    case hijriCalendar(String) // date (DD-MM-YYYY)
    case hijriToGregorian(String) // hijri date
    case qiblaDirection(Double, Double) // lat, lon
    case asmaAlHusna

    var baseURL: String {
        switch self {
        case .quranEdition, .surah, .verse, .editions, .search:
            return "https://api.alquran.cloud/v1"
        case .timings, .hijriCalendar, .hijriToGregorian, .qiblaDirection, .asmaAlHusna:
            return "https://api.aladhan.com/v1"
        }
    }

    var path: String {
        switch self {
        case .quranEdition(let edition):
            return "/quran/\(edition)"
        case .surah(let number, let edition):
            return "/surah/\(number)/\(edition)"
        case .verse(let edition, let surahNumber, let verseNumber):
            return "/ayah/\(surahNumber):\(verseNumber)/\(edition)"
        case .editions(let format, let language):
            return "/edition?format=\(format)&language=\(language)"
        case .search(let query, let surah):
            return "/search/\(query)/\(surah)"
        case .timings(let lat, let lon, let method, let date):
            return "/timings/\(date)?latitude=\(lat)&longitude=\(lon)&method=\(method)"
        case .hijriCalendar(let date):
            return "/gToH/\(date)"
        case .hijriToGregorian(let date):
            return "/hToG/\(date)"
        case .qiblaDirection(let lat, let lon):
            return "/qibla/\(lat)/\(lon)"
        case .asmaAlHusna:
            return "/asmaAlHusna"
        }
    }

    var fullURL: String {
        return baseURL + path
    }
}

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let code: Int
    let status: String
    let data: T
}

// MARK: - API Client
class APIClient {
    // MARK: - Singleton
    static let shared = APIClient()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Properties
    private let session: URLSession
    private let cache = URLCache.shared
    private let userDefaults = UserDefaults.standard

    // Cache duration: 24 hours for most data
    private let cacheExpirationInterval: TimeInterval = 86400

    // MARK: - Request Deduplication (Performance: prevent duplicate in-flight requests)
    private let requestDeduplicator = RequestDeduplicator()

    // MARK: - LRU Cache Management (Performance: prevent unbounded cache growth)
    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB max cache
    private let cacheMetadataKey = "api_cache_metadata"
    private var cacheMetadata: CacheMetadata {
        get {
            guard let data = userDefaults.data(forKey: cacheMetadataKey),
                  let metadata = try? Self.decoder.decode(CacheMetadata.self, from: data) else {
                return CacheMetadata(entries: [:], totalSize: 0)
            }
            return metadata
        }
        set {
            if let data = try? Self.encoder.encode(newValue) {
                userDefaults.set(data, forKey: cacheMetadataKey)
            }
        }
    }

    // MARK: - Initialization
    private init() {
        let configuration = URLSessionConfiguration.default

        // Performance: Set reasonable timeout limits
        configuration.timeoutIntervalForRequest = 30 // 30 seconds per request
        configuration.timeoutIntervalForResource = 60 // 60 seconds total for resource

        // Performance: Configure URL cache with size limits
        let memoryCapacity = 10 * 1024 * 1024 // 10MB memory cache
        let diskCapacity = 50 * 1024 * 1024 // 50MB disk cache
        configuration.urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        configuration.requestCachePolicy = .returnCacheDataElseLoad

        // Performance: Limit concurrent connections
        configuration.httpMaximumConnectionsPerHost = 4

        self.session = URLSession(configuration: configuration)

        // Clean up expired cache entries on init
        Task.detached(priority: .background) { [weak self] in
            await self?.evictExpiredEntries()
        }
    }

    // MARK: - Generic Fetch Method

    /// Fetch data from API with automatic caching
    func fetch<T: Codable>(endpoint: APIEndpoint, cacheKey: String? = nil, forceRefresh: Bool = false) async throws -> T {
        // Check cache first if not forcing refresh
        if !forceRefresh, let cacheKey = cacheKey {
            if let cachedData: T = getCachedData(forKey: cacheKey) {
                return cachedData
            }
        }

        // Validate URL
        guard let url = URL(string: endpoint.fullURL) else {
            throw APIError.invalidURL
        }

        // Make deduplicated request
        let requestKey = endpoint.fullURL
        let data = try await fetchDataDeduplicated(url: url, requestKey: requestKey)

        // Decode response
        do {
            let result = try Self.decoder.decode(APIResponse<T>.self, from: data)

            // Cache the result if cache key provided
            if let cacheKey = cacheKey {
                cacheData(result.data, forKey: cacheKey)
            }

            return result.data
        } catch {
            // If APIResponse wrapper fails, try decoding T directly
            do {
                let result = try Self.decoder.decode(T.self, from: data)

                // Cache the result if cache key provided
                if let cacheKey = cacheKey {
                    cacheData(result, forKey: cacheKey)
                }

                return result
            } catch let directError {
                #if DEBUG
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed to decode JSON from endpoint: \(endpoint.fullURL)")
                    print("JSON Response (first 500 chars): \(String(jsonString.prefix(500)))")
                }
                #endif
                throw APIError.decodingError(directError)
            }
        }
    }

    /// Fetch data without response wrapper (for direct API responses)
    func fetchDirect<T: Codable>(url urlString: String, cacheKey: String? = nil, forceRefresh: Bool = false) async throws -> T {
        // Check cache first if not forcing refresh
        if !forceRefresh, let cacheKey = cacheKey {
            if let cachedData: T = getCachedData(forKey: cacheKey) {
                return cachedData
            }
        }

        // Validate URL
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        // Make deduplicated request
        let data = try await fetchDataDeduplicated(url: url, requestKey: urlString)

        // Decode response
        do {
            // Try with APIResponse wrapper first
            let result = try Self.decoder.decode(APIResponse<T>.self, from: data)

            // Cache the result if cache key provided
            if let cacheKey = cacheKey {
                cacheData(result.data, forKey: cacheKey)
            }

            return result.data
        } catch {
            // If APIResponse wrapper fails, try decoding T directly
            do {
                let result = try Self.decoder.decode(T.self, from: data)

                // Cache the result if cache key provided
                if let cacheKey = cacheKey {
                    cacheData(result, forKey: cacheKey)
                }

                return result
            } catch let directError {
                #if DEBUG
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed to decode JSON from URL: \(url)")
                    print("JSON Response (first 500 chars): \(String(jsonString.prefix(500)))")
                }
                #endif
                throw APIError.decodingError(directError)
            }
        }
    }

    // MARK: - Request Deduplication

    /// Fetch data with deduplication - reuses in-flight requests for the same URL
    private func fetchDataDeduplicated(url: URL, requestKey: String) async throws -> Data {
        // Check if there's already an in-flight request for this URL
        if let existingTask = await requestDeduplicator.getExistingTask(for: requestKey) {
            #if DEBUG
            print("♻️ Reusing in-flight request for: \(requestKey.prefix(80))...")
            #endif
            return try await existingTask.value
        }

        // Create new task for this request
        let task = Task<Data, Error> { [session] in
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            return data
        }

        await requestDeduplicator.setTask(task, for: requestKey)

        do {
            let data = try await task.value
            await requestDeduplicator.removeTask(for: requestKey)
            return data
        } catch {
            await requestDeduplicator.removeTask(for: requestKey)
            throw error
        }
    }

    // MARK: - Cache Management

    /// Cache data to UserDefaults with expiration and LRU eviction
    private func cacheData<T: Codable>(_ data: T, forKey key: String) {
        do {
            let encoded = try Self.encoder.encode(data)
            let entrySize = encoded.count

            // Evict old entries if needed to make room
            evictIfNeeded(forNewEntrySize: entrySize)

            let cacheEntry = CacheEntry(data: encoded, expirationDate: Date().addingTimeInterval(cacheExpirationInterval))
            let entryData = try Self.encoder.encode(cacheEntry)

            userDefaults.set(entryData, forKey: "cache_\(key)")

            // Update metadata
            var metadata = cacheMetadata
            metadata.entries[key] = CacheEntryMetadata(size: entryData.count, lastAccessed: Date())
            metadata.totalSize = metadata.entries.values.reduce(0) { $0 + $1.size }
            cacheMetadata = metadata
        } catch {
            print("Failed to cache data: \(error)")
        }
    }

    /// Retrieve cached data from UserDefaults with LRU tracking
    func getCachedData<T: Codable>(forKey key: String) -> T? {
        guard let entryData = userDefaults.data(forKey: "cache_\(key)") else {
            return nil
        }

        do {
            let cacheEntry = try Self.decoder.decode(CacheEntry.self, from: entryData)

            // Check if cache is expired
            if Date() > cacheEntry.expirationDate {
                // Cache expired, remove it
                removeCacheEntry(forKey: key)
                return nil
            }

            // Update last accessed time for LRU
            var metadata = cacheMetadata
            if metadata.entries[key] != nil {
                metadata.entries[key]?.lastAccessed = Date()
                cacheMetadata = metadata
            }

            // Decode and return data
            let result = try Self.decoder.decode(T.self, from: cacheEntry.data)
            return result
        } catch {
            print("Failed to retrieve cached data: \(error)")
            return nil
        }
    }

    /// Evict least recently used entries if cache exceeds size limit
    private func evictIfNeeded(forNewEntrySize newSize: Int) {
        var metadata = cacheMetadata

        // If adding this entry would exceed max size, evict LRU entries
        while metadata.totalSize + newSize > maxCacheSize && !metadata.entries.isEmpty {
            // Find least recently used entry
            guard let lruEntry = metadata.entries.min(by: { $0.value.lastAccessed < $1.value.lastAccessed }) else {
                break
            }

            // Remove LRU entry
            userDefaults.removeObject(forKey: "cache_\(lruEntry.key)")
            metadata.entries.removeValue(forKey: lruEntry.key)
            metadata.totalSize = metadata.entries.values.reduce(0) { $0 + $1.size }

            #if DEBUG
            print("🗑️ LRU evicted cache entry: \(lruEntry.key)")
            #endif
        }

        cacheMetadata = metadata
    }

    /// Evict all expired entries (called periodically)
    private func evictExpiredEntries() async {
        var metadata = cacheMetadata
        var keysToRemove: [String] = []

        for (key, _) in metadata.entries {
            guard let entryData = userDefaults.data(forKey: "cache_\(key)") else {
                keysToRemove.append(key)
                continue
            }

            if let cacheEntry = try? Self.decoder.decode(CacheEntry.self, from: entryData),
               Date() > cacheEntry.expirationDate {
                keysToRemove.append(key)
            }
        }

        for key in keysToRemove {
            userDefaults.removeObject(forKey: "cache_\(key)")
            metadata.entries.removeValue(forKey: key)
        }

        metadata.totalSize = metadata.entries.values.reduce(0) { $0 + $1.size }
        cacheMetadata = metadata

        #if DEBUG
        if !keysToRemove.isEmpty {
            print("🗑️ Evicted \(keysToRemove.count) expired cache entries")
        }
        #endif
    }

    /// Remove a specific cache entry and update metadata
    private func removeCacheEntry(forKey key: String) {
        userDefaults.removeObject(forKey: "cache_\(key)")
        var metadata = cacheMetadata
        metadata.entries.removeValue(forKey: key)
        metadata.totalSize = metadata.entries.values.reduce(0) { $0 + $1.size }
        cacheMetadata = metadata
    }

    /// Clear all cached data
    func clearCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        keys.filter { $0.hasPrefix("cache_") }.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        cacheMetadata = CacheMetadata(entries: [:], totalSize: 0)
    }

    /// Clear specific cache entry
    func clearCache(forKey key: String) {
        removeCacheEntry(forKey: key)
    }

    /// Get current cache size in bytes
    var currentCacheSize: Int {
        cacheMetadata.totalSize
    }
}

// MARK: - Cache Entry
private struct CacheEntry: Codable {
    let data: Data
    let expirationDate: Date
}

// MARK: - Cache Metadata for LRU Eviction
private struct CacheMetadata: Codable {
    var entries: [String: CacheEntryMetadata]
    var totalSize: Int
}

private struct CacheEntryMetadata: Codable {
    var size: Int
    var lastAccessed: Date
}

// MARK: - Request Deduplication Actor (Swift 6 async-safe)
private actor RequestDeduplicator {
    private var inFlightRequests: [String: Task<Data, Error>] = [:]

    func getExistingTask(for key: String) -> Task<Data, Error>? {
        inFlightRequests[key]
    }

    func setTask(_ task: Task<Data, Error>, for key: String) {
        inFlightRequests[key] = task
    }

    func removeTask(for key: String) {
        inFlightRequests.removeValue(forKey: key)
    }
}
