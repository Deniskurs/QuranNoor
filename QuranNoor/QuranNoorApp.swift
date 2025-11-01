//
//  QuranNoorApp.swift
//  QuranNoor
//
//  Islamic Companion iOS App
//  Main app entry point
//

import SwiftUI

@main
struct QuranNoorApp: App {
    // MARK: - Properties
    @StateObject private var themeManager = ThemeManager()

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
