//
//  ContentView.swift
//  QuranNoor
//
//  Root view with tab-based navigation
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(DeepLinkHandler.self) var deepLinkHandler
    @State private var selectedTab = 0

    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Quran Tab
            QuranReaderView()
                .tabItem {
                    Label("Quran", systemImage: "book.fill")
                }
                .tag(1)

            // Prayer Tab
            PrayerTimesView()
                .tabItem {
                    Label("Prayer", systemImage: "clock.fill")
                }
                .tag(2)

            // Qibla Tab
            QiblaCompassView()
                .tabItem {
                    Label("Qibla", systemImage: "location.north.fill")
                }
                .tag(3)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(themeManager.currentTheme.accentColor)  // Use theme-aware accent color
        .onChange(of: selectedTab) { oldValue, newValue in
            // Tab switching haptic feedback
            HapticManager.shared.trigger(.selection)

            // Clear active deep link when user manually switches tabs
            if deepLinkHandler.activeDestination?.tabIndex != newValue {
                deepLinkHandler.clearActiveDestination()
            }
        }
        // Handle deep link navigation
        .onChange(of: deepLinkHandler.pendingNavigation) { _, destination in
            if let destination = destination {
                selectedTab = destination.tabIndex

                #if DEBUG
                print("🧭 Deep link navigation: \(destination.rawValue) -> Tab \(destination.tabIndex)")
                #endif
            }
        }
        // Listen for Quick Action notifications
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("QuickActionTriggered"))) { notification in
            if let shortcutItem = notification.object as? UIApplicationShortcutItem {
                deepLinkHandler.handle(shortcutItem: shortcutItem)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
