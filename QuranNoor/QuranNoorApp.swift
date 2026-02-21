//
//  QuranNoorApp.swift
//  QuranNoor
//
//  Islamic Companion iOS App
//  Main app entry point
//

import SwiftUI
import SwiftData
import UserNotifications

// TODO: Add crash reporting framework (e.g., Firebase Crashlytics or Sentry) before production release.
// TODO: NetworkMonitor.swift exists but is not wired to the UI. Add offline indicators in views that require network access.
@main
struct QuranNoorApp: App {
    // MARK: - Properties
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var themeManager = ThemeManager()
    @State private var deepLinkHandler = DeepLinkHandler()
    @State private var localizationManager = LocalizationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    // SwiftData Model Container
    let modelContainer: ModelContainer

    // MARK: - Initializer
    init() {
        // Ensure Application Support directory exists before SwiftData init
        // Prevents CoreData "Failed to stat path" errors on first launch
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        // Initialize SwiftData ModelContainer with versioned schema
        do {
            // Use the versioned schema for safe migrations across app updates
            let schema = Schema(versionedSchema: QuranNoorSchemaV1.self)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            do {
                // Create container with migration plan to handle schema evolution
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: QuranNoorMigrationPlan.self,
                    configurations: [modelConfiguration]
                )
            } catch {
                // Fallback to in-memory store if persistent storage fails
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                do {
                    modelContainer = try ModelContainer(
                        for: schema,
                        migrationPlan: QuranNoorMigrationPlan.self,
                        configurations: [fallbackConfig]
                    )
                } catch {
                    fatalError("Failed to initialize even in-memory ModelContainer: \(error)")
                }
            }
        }

        // Migrate UserDefaults schema if needed
        // This ensures smooth upgrades between app versions
        UserDefaultsMigrator().migrateIfNeeded()

        // Register notification categories at app launch
        // This ensures categories exist before any notifications are scheduled
        NotificationService.shared.registerNotificationCategories()

        // AudioService now uses lazy initialization — sounds are preloaded
        // on first play() call, not at app startup. This avoids blocking launch
        // with disk I/O and AVAudioSession activation.

        #if DEBUG
        // DEVELOPMENT ONLY: Uncomment the line below to reset onboarding for testing
        // UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        #endif
    }

    // MARK: - SwiftData Setup & Migration
    @MainActor
    private func setupSwiftDataServices() async {
        let context = modelContainer.mainContext

        // First, migrate any existing UserDefaults data to SwiftData
        await DataMigrationService.shared.migrateIfNeeded(context: context)

        // Then, configure QuranService with SwiftData context
        QuranService.shared.setupWithContext(context)
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Immediate themed background — fills the window on the very first
                // frame so there is never a bare black/white system background visible
                // while child views are still loading.
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                if hasCompletedOnboarding {
                    // Main app - scales up and fades in
                    ContentView()
                        .environment(themeManager)
                        .environment(deepLinkHandler)
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
            .preferredColorScheme(themeManager.colorScheme)
            // Apply RTL layout direction based on current language (Arabic, Urdu)
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .environment(localizationManager)
            // Inject SwiftData model container
            .modelContainer(modelContainer)
            .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
            // Setup SwiftData services and perform migration on first launch
            .task {
                await setupSwiftDataServices()
            }
            // Handle custom URL schemes (e.g., qurannoor://next-prayer)
            .onOpenURL { url in
                _ = deepLinkHandler.handle(url: url)
            }
            // Handle scene phase changes
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    // Clear badge count when app becomes active
                    UNUserNotificationCenter.current().setBadgeCount(0)
                case .background:
                    // Placeholder for future background tasks
                    break
                case .inactive:
                    break
                @unknown default:
                    break
                }
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
                if let _ = userInfo["prayer"] as? String {
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
                }
            }

        case "SNOOZE_ACTION":
            // Reschedule notification for 5 minutes later
            if let prayerName = userInfo["prayer"] as? String {
                let content = UNMutableNotificationContent()
                content.title = "Prayer Reminder"
                content.body = "Time for \(prayerName) prayer"
                content.sound = .default
                content.userInfo = userInfo
                content.categoryIdentifier = "PRAYER_TIME"

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "snooze_\(prayerName)_\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: trigger
                )
                Task {
                    try? await UNUserNotificationCenter.current().add(request)
                }
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification (default action)
            // Play Adhan and navigate to prayer tab
            Task { @MainActor in
                if let _ = userInfo["prayer"] as? String {
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
