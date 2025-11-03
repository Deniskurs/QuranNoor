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

    // MARK: - Properties
    private let session: URLSession
    private let cache = URLCache.shared
    private let userDefaults = UserDefaults.standard

    // Cache duration: 24 hours for most data
    private let cacheExpirationInterval: TimeInterval = 86400

    // MARK: - Initialization
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: configuration)
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

        // Make request
        do {
            let (data, response) = try await session.data(from: url)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            // Decode response
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(APIResponse<T>.self, from: data)

                // Cache the result if cache key provided
                if let cacheKey = cacheKey {
                    cacheData(result.data, forKey: cacheKey)
                }

                return result.data
            } catch let wrapperError {
                // If APIResponse wrapper fails, try decoding T directly
                do {
                    let result = try decoder.decode(T.self, from: data)

                    // Cache the result if cache key provided
                    if let cacheKey = cacheKey {
                        cacheData(result, forKey: cacheKey)
                    }

                    return result
                } catch let directError {
                    // Log the actual JSON for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Failed to decode JSON from endpoint: \(endpoint.fullURL)")
                        print("JSON Response (first 500 chars): \(String(jsonString.prefix(500)))")
                        print("Wrapper decode error: \(wrapperError)")
                        print("Direct decode error: \(directError)")
                    }
                    throw APIError.decodingError(directError)
                }
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Fetch data without response wrapper (for direct API responses)
    func fetchDirect<T: Codable>(url: String, cacheKey: String? = nil, forceRefresh: Bool = false) async throws -> T {
        // Check cache first if not forcing refresh
        if !forceRefresh, let cacheKey = cacheKey {
            if let cachedData: T = getCachedData(forKey: cacheKey) {
                return cachedData
            }
        }

        // Validate URL
        guard let url = URL(string: url) else {
            throw APIError.invalidURL
        }

        // Make request
        do {
            let (data, response) = try await session.data(from: url)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            // Decode response
            let decoder = JSONDecoder()
            do {
                // Try with APIResponse wrapper first
                let result = try decoder.decode(APIResponse<T>.self, from: data)

                // Cache the result if cache key provided
                if let cacheKey = cacheKey {
                    cacheData(result.data, forKey: cacheKey)
                }

                return result.data
            } catch let wrapperError {
                // If APIResponse wrapper fails, try decoding T directly
                do {
                    let result = try decoder.decode(T.self, from: data)

                    // Cache the result if cache key provided
                    if let cacheKey = cacheKey {
                        cacheData(result, forKey: cacheKey)
                    }

                    return result
                } catch let directError {
                    // Log the actual JSON for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Failed to decode JSON from URL: \(url)")
                        print("JSON Response (first 500 chars): \(String(jsonString.prefix(500)))")
                        print("Wrapper decode error: \(wrapperError)")
                        print("Direct decode error: \(directError)")
                    }
                    throw APIError.decodingError(directError)
                }
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Cache Management

    /// Cache data to UserDefaults with expiration
    private func cacheData<T: Codable>(_ data: T, forKey key: String) {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)

            let cacheEntry = CacheEntry(data: encoded, expirationDate: Date().addingTimeInterval(cacheExpirationInterval))
            let entryData = try encoder.encode(cacheEntry)

            userDefaults.set(entryData, forKey: "cache_\(key)")
        } catch {
            print("Failed to cache data: \(error)")
        }
    }

    /// Retrieve cached data from UserDefaults
    func getCachedData<T: Codable>(forKey key: String) -> T? {
        guard let entryData = userDefaults.data(forKey: "cache_\(key)") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let cacheEntry = try decoder.decode(CacheEntry.self, from: entryData)

            // Check if cache is expired
            if Date() > cacheEntry.expirationDate {
                // Cache expired, remove it
                userDefaults.removeObject(forKey: "cache_\(key)")
                return nil
            }

            // Decode and return data
            let result = try decoder.decode(T.self, from: cacheEntry.data)
            return result
        } catch {
            print("Failed to retrieve cached data: \(error)")
            return nil
        }
    }

    /// Clear all cached data
    func clearCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        keys.filter { $0.hasPrefix("cache_") }.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }

    /// Clear specific cache entry
    func clearCache(forKey key: String) {
        userDefaults.removeObject(forKey: "cache_\(key)")
    }
}

// MARK: - Cache Entry
private struct CacheEntry: Codable {
    let data: Data
    let expirationDate: Date
}
