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

    // MARK: - Initializer
    init() {
        // Register notification categories at app launch
        // This ensures categories exist before any notifications are scheduled
        let notificationService = NotificationService()
        notificationService.registerNotificationCategories()
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
