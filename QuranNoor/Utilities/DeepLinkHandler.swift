//
//  DeepLinkHandler.swift
//  QuranNoor
//
//  Deep linking system for Quick Actions, 3D Touch shortcuts, and URL schemes
//

import SwiftUI
import UIKit

// MARK: - Deep Link Destination
enum DeepLinkDestination: String, Hashable {
    case home = "home"
    case nextPrayer = "next-prayer"
    case quran = "read-quran"
    case qibla = "qibla"
    case prayer = "prayer"
    case settings = "settings"

    /// Map to tab index in ContentView
    /// Tabs: Home(0), Quran(1), Prayer(2), More(3)
    var tabIndex: Int {
        switch self {
        case .home:
            return 0
        case .quran:
            return 1
        case .prayer, .nextPrayer:
            return 2
        case .qibla, .settings:
            return 3  // Both navigate to More tab
        }
    }

    /// SF Symbol icon for the destination
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .nextPrayer, .prayer:
            return "clock.fill"
        case .quran:
            return "book.fill"
        case .qibla:
            return "location.north.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

// MARK: - Deep Link Handler
@MainActor
@Observable
class DeepLinkHandler {
    // MARK: - Properties

    /// Current active deep link destination (nil when no deep link is active)
    var activeDestination: DeepLinkDestination?

    /// Trigger for tab navigation (observed by ContentView)
    var pendingNavigation: DeepLinkDestination?

    // MARK: - Quick Action Handling

    /// Handle UIApplicationShortcutItem from 3D Touch
    func handle(shortcutItem: UIApplicationShortcutItem) {
        guard let action = shortcutItem.userInfo?["action"] as? String else {
            #if DEBUG
            print("No action found in shortcut item")
            #endif
            return
        }

        // Map action string to destination
        if let destination = DeepLinkDestination(rawValue: action) {
            navigate(to: destination)

            // Haptic feedback for shortcut activation
            HapticManager.shared.trigger(.medium)

            #if DEBUG
            print("🚀 Quick Action: \(destination.rawValue) -> Tab \(destination.tabIndex)")
            #endif
        }
    }

    // MARK: - URL Scheme Handling

    /// Handle custom URL scheme (e.g., qurannoor://next-prayer)
    func handle(url: URL) -> Bool {
        guard url.scheme == "qurannoor" else { return false }

        let action = url.host() ?? ""

        if let destination = DeepLinkDestination(rawValue: action) {
            navigate(to: destination)

            #if DEBUG
            print("🔗 URL Scheme: \(url.absoluteString) -> Tab \(destination.tabIndex)")
            #endif

            return true
        }

        return false
    }

    // MARK: - Navigation

    /// Navigate to a specific destination
    func navigate(to destination: DeepLinkDestination) {
        // Set active destination
        activeDestination = destination

        // Trigger navigation (ContentView will observe this)
        pendingNavigation = destination

        // Clear pending navigation after a short delay (allows ContentView to react)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 500ms
            pendingNavigation = nil
        }
    }

    /// Clear active destination (called when user manually switches tabs)
    func clearActiveDestination() {
        activeDestination = nil
    }
}
