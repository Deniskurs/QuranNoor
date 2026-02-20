//
//  NetworkMonitor.swift
//  QuranNoor
//
//  Monitors network connectivity using NWPathMonitor
//

import Foundation
import Network
import Observation

@Observable
@MainActor
final class NetworkMonitor {
    // MARK: - Singleton
    static let shared = NetworkMonitor()

    // MARK: - Properties
    var isConnected: Bool = true

    // MARK: - Private
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.qurannoor.networkmonitor")

    // MARK: - Init
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
