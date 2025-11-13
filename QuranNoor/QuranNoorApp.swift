//
//  QuranNoorApp.swift
//  QuranNoor
//
//  Islamic Companion iOS App
//  Main app entry point
//

import SwiftUI
import UserNotifications

@main
struct QuranNoorApp: App {
    // MARK: - Properties
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var themeManager = ThemeManager()
    @State private var deepLinkHandler = DeepLinkHandler()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - Initializer
    init() {
        // Migrate UserDefaults schema if needed
        // This ensures smooth upgrades between app versions
        UserDefaultsMigrator().migrateIfNeeded()

        // Register notification categories at app launch
        // This ensures categories exist before any notifications are scheduled
        let notificationService = NotificationService()
        notificationService.registerNotificationCategories()

        // Initialize AudioService early to preload sound effects
        // This ensures zero-latency audio playback for UI interactions
        _ = AudioService.shared

        #if DEBUG
        // DEVELOPMENT ONLY: Uncomment the line below to reset onboarding for testing
        // UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        #endif
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    // Main app - scales up and fades in
                    ContentView()
                        .environment(themeManager)
                        .environment(deepLinkHandler)
                        .preferredColorScheme(themeManager.colorScheme)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 1.05).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            )
                        )
                        .zIndex(1)
                } else {
                    // Onboarding - scales down and fades out when dismissed
                    OnboardingContainerView()
                        .environment(themeManager)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 1.0).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            )
                        )
                        .zIndex(2)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
            // Handle custom URL schemes (e.g., qurannoor://next-prayer)
            .onOpenURL { url in
                _ = deepLinkHandler.handle(url: url)
            }
            // Handle 3D Touch Quick Actions
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                if let url = userActivity.webpageURL {
                    _ = deepLinkHandler.handle(url: url)
                }
            }
        }
    }
}

// MARK: - App Delegate Adapter for Quick Actions and Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Register Quick Actions programmatically (for auto-generated Info.plist projects)
        registerQuickActions(application)
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate Methods

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if this is a prayer time notification
        let userInfo = notification.request.content.userInfo
        if let notificationType = userInfo["type"] as? String, notificationType == "prayer_time" {
            // Play Adhan audio when prayer time arrives (foreground)
            Task { @MainActor in
                if let prayerName = userInfo["prayer"] as? String {
                    print("🕌 Prayer time notification received in foreground: \(prayerName)")
                    await AdhanAudioService.shared.playAdhan()
                }
            }
        }

        // Still show the notification banner in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap/interaction
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification actions
        switch response.actionIdentifier {
        case "MARK_PRAYED_ACTION":
            // User marked prayer as completed from notification
            if let prayerName = userInfo["prayer"] as? String,
               let prayer = PrayerName(rawValue: prayerName) {
                Task { @MainActor in
                    PrayerCompletionService.shared.toggleCompletion(prayer)
                    print("✅ Marked \(prayer.displayName) as prayed from notification")
                }
            }

        case "SNOOZE_ACTION":
            // User snoozed the notification (could reschedule for 5 minutes later)
            print("⏰ Prayer notification snoozed")

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification (default action)
            // Play Adhan and navigate to prayer tab
            Task { @MainActor in
                if let prayerName = userInfo["prayer"] as? String {
                    print("🕌 Opening app from prayer notification: \(prayerName)")
                    await AdhanAudioService.shared.playAdhan()

                    // Post notification to navigate to prayer tab
                    NotificationCenter.default.post(
                        name: Notification.Name("NavigateToPrayerTab"),
                        object: nil
                    )
                }
            }

        default:
            break
        }

        completionHandler()
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Handle Quick Action shortcut items at launch
        if let shortcutItem = options.shortcutItem {
            Task { @MainActor in
                // Get the deep link handler from the environment
                // This will be handled by SceneDelegate
                NotificationCenter.default.post(
                    name: Notification.Name("QuickActionTriggered"),
                    object: shortcutItem
                )
            }
        }

        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    // MARK: - Quick Actions Registration
    private func registerQuickActions(_ application: UIApplication) {
        // Next Prayer shortcut
        let nextPrayerShortcut = UIApplicationShortcutItem(
            type: "com.qurannoor.next-prayer",
            localizedTitle: "Next Prayer",
            localizedSubtitle: "View prayer times",
            icon: UIApplicationShortcutIcon(type: .time),
            userInfo: ["action": "next-prayer" as NSSecureCoding]
        )

        // Qibla Direction shortcut
        let qiblaShortcut = UIApplicationShortcutItem(
            type: "com.qurannoor.qibla",
            localizedTitle: "Qibla Direction",
            localizedSubtitle: "Find direction to Mecca",
            icon: UIApplicationShortcutIcon(type: .location),
            userInfo: ["action": "qibla" as NSSecureCoding]
        )

        // Read Quran shortcut
        let quranShortcut = UIApplicationShortcutItem(
            type: "com.qurannoor.read-quran",
            localizedTitle: "Read Quran",
            localizedSubtitle: "Continue reading",
            icon: UIApplicationShortcutIcon(type: .bookmark),
            userInfo: ["action": "read-quran" as NSSecureCoding]
        )

        // Set shortcuts
        application.shortcutItems = [nextPrayerShortcut, qiblaShortcut, quranShortcut]
    }
}

// MARK: - Scene Delegate for Quick Actions
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        // Handle Quick Action when app is already running
        Task { @MainActor in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               windowScene.windows.first?.rootViewController != nil {

                // Find DeepLinkHandler from the SwiftUI view hierarchy
                // Post notification that will be caught by ContentView
                NotificationCenter.default.post(
                    name: Notification.Name("QuickActionTriggered"),
                    object: shortcutItem
                )

                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
}
