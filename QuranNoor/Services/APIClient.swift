//
//  APIClient.swift
//  QuranNoor
//
//  Generic network layer for Islamic APIs (AlQuran.cloud, Aladhan.com)
//

import Foundation


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

    // Cache duration: 24 hours for most data
    private let cacheExpirationInterval: TimeInterval = 86400

    // MARK: - Request Deduplication (Performance: prevent duplicate in-flight requests)
    private let requestDeduplicator = RequestDeduplicator()

    // MARK: - Concurrency Throttle (prevents API rate limiting)
    private let concurrencyThrottle = ConcurrencyThrottle(maxConcurrent: 2)

    // MARK: - File-Based Cache (replaces UserDefaults — proper for large data)
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB max cache

    // MARK: - Initialization
    private init() {
        let configuration = URLSessionConfiguration.default

        // Performance: Set reasonable timeout limits
        configuration.timeoutIntervalForRequest = 15 // 15 seconds per request (was 30)
        configuration.timeoutIntervalForResource = 30 // 30 seconds total (was 60)

        // Performance: Configure URL cache with size limits
        let memoryCapacity = 10 * 1024 * 1024 // 10MB memory cache
        let diskCapacity = 50 * 1024 * 1024 // 50MB disk cache
        configuration.urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        configuration.requestCachePolicy = .useProtocolCachePolicy

        // User-Agent header for API identification
        configuration.httpAdditionalHeaders = ["User-Agent": "QuranNoor/1.0.0 (iOS; com.qurannoor.app)"]

        // Performance: Limit concurrent connections
        configuration.httpMaximumConnectionsPerHost = 4

        self.session = URLSession(configuration: configuration)

        // Setup file-based cache directory
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = caches.appendingPathComponent("APICache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Clean up expired cache entries in background
        Task.detached(priority: .background) { [weak self] in
            self?.evictExpiredEntries()
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

    /// Fetch data with deduplication and concurrency throttling.
    /// Reuses in-flight requests for the same URL.
    /// Limits concurrent API requests to prevent 429 rate limiting.
    private func fetchDataDeduplicated(url: URL, requestKey: String) async throws -> Data {
        // Check if there's already an in-flight request for this URL
        if let existingTask = await requestDeduplicator.getExistingTask(for: requestKey) {
            #if DEBUG
            print("♻️ Reusing in-flight request for: \(requestKey.prefix(80))...")
            #endif
            return try await existingTask.value
        }

        // Create new task for this request with throttling + retry logic
        let task = Task<Data, Error> { [session, concurrencyThrottle] in
            // Wait for a concurrency slot before making the request
            await concurrencyThrottle.acquire()
            defer { Task { await concurrencyThrottle.release() } }

            var retryCount = 0
            let maxRetries = 3
            var lastError: Error?

            while retryCount < maxRetries {
                do {
                    let (data, response) = try await session.data(from: url)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }

                    // Handle 429 Too Many Requests with exponential backoff
                    if httpResponse.statusCode == 429 {
                        retryCount += 1

                        if retryCount >= maxRetries {
                            throw APIError.serverError(429)
                        }

                        // Try to extract Retry-After header (in seconds)
                        let retryAfter: TimeInterval
                        if let retryAfterHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                           let retrySeconds = TimeInterval(retryAfterHeader) {
                            retryAfter = retrySeconds
                        } else {
                            // Exponential backoff: 2^retryCount seconds
                            retryAfter = pow(2.0, Double(retryCount))
                        }

                        #if DEBUG
                        print("⏱️ Rate limited (429). Retry \(retryCount)/\(maxRetries) after \(retryAfter)s")
                        #endif

                        try await Task.sleep(for: .seconds(retryAfter))
                        continue
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw APIError.serverError(httpResponse.statusCode)
                    }

                    return data
                } catch {
                    lastError = error

                    // Only retry on network errors, not on decoding or other errors
                    if (error as? URLError) != nil && retryCount < maxRetries - 1 {
                        retryCount += 1
                        let backoffDelay = pow(2.0, Double(retryCount))
                        #if DEBUG
                        print("🔄 Network error. Retry \(retryCount)/\(maxRetries) after \(backoffDelay)s")
                        #endif
                        try await Task.sleep(for: .seconds(backoffDelay))
                        continue
                    }

                    throw error
                }
            }

            throw lastError ?? APIError.invalidResponse
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

    // MARK: - File-Based Cache Management

    /// Convert cache key to a safe filename
    private func cacheFileURL(forKey key: String) -> URL {
        // SHA256-like hash using simple deterministic approach for safe filenames
        let safeKey = key.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .prefix(128)
        return cacheDirectory.appendingPathComponent(String(safeKey) + ".cache")
    }

    /// Cache data to filesystem with expiration
    private func cacheData<T: Codable>(_ data: T, forKey key: String) {
        do {
            let encoded = try Self.encoder.encode(data)
            let cacheEntry = CacheEntry(data: encoded, expirationDate: Date().addingTimeInterval(cacheExpirationInterval))
            let entryData = try Self.encoder.encode(cacheEntry)
            try entryData.write(to: cacheFileURL(forKey: key), options: .atomic)
        } catch {
            #if DEBUG
            print("❌ Failed to cache data: \(error)")
            #endif
        }
    }

    /// Retrieve cached data from filesystem
    func getCachedData<T: Codable>(forKey key: String) -> T? {
        let fileURL = cacheFileURL(forKey: key)

        guard let entryData = try? Data(contentsOf: fileURL) else {
            return nil
        }

        do {
            let cacheEntry = try Self.decoder.decode(CacheEntry.self, from: entryData)

            // Check if cache is expired
            if Date() > cacheEntry.expirationDate {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }

            return try Self.decoder.decode(T.self, from: cacheEntry.data)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
    }

    /// Evict expired cache files (called on init in background)
    private nonisolated func evictExpiredEntries() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }

        var totalSize = 0
        var fileInfos: [(url: URL, date: Date, size: Int)] = []

        for file in files where file.pathExtension == "cache" {
            guard let entryData = try? Data(contentsOf: file),
                  let cacheEntry = try? JSONDecoder().decode(CacheEntry.self, from: entryData) else {
                // Corrupt file — remove it
                try? FileManager.default.removeItem(at: file)
                continue
            }

            if Date() > cacheEntry.expirationDate {
                try? FileManager.default.removeItem(at: file)
            } else {
                let size = entryData.count
                totalSize += size
                let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey])
                let date = attrs?.contentModificationDate ?? Date.distantPast
                fileInfos.append((file, date, size))
            }
        }

        // LRU eviction if over size limit
        if totalSize > maxCacheSize {
            let sorted = fileInfos.sorted { $0.date < $1.date } // oldest first
            for info in sorted {
                guard totalSize > maxCacheSize else { break }
                try? FileManager.default.removeItem(at: info.url)
                totalSize -= info.size
            }
        }
    }

    /// Clear all cached data
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Clear specific cache entry
    func clearCache(forKey key: String) {
        try? FileManager.default.removeItem(at: cacheFileURL(forKey: key))
    }

    /// Get current cache size in bytes
    var currentCacheSize: Int {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
    }
}

// MARK: - Cache Entry
private nonisolated struct CacheEntry: Codable, Sendable {
    let data: Data
    let expirationDate: Date
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

// MARK: - Concurrency Throttle (async semaphore to limit concurrent API requests)
private actor ConcurrencyThrottle {
    private let maxConcurrent: Int
    private var currentCount: Int = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrent: Int) {
        self.maxConcurrent = maxConcurrent
    }

    func acquire() async {
        if currentCount < maxConcurrent {
            currentCount += 1
            return
        }
        // No slot available — suspend until one is released
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        if let next = waiters.first {
            waiters.removeFirst()
            // Hand the slot directly to the next waiter (no count change)
            next.resume()
        } else {
            currentCount -= 1
        }
    }
}
