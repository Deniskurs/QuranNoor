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
        .accentColor(AppColors.primary.green)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
