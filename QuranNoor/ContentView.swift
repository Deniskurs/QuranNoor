//
//  ContentView.swift
//  QuranNoor
//
//  Root view with tab-based navigation
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(DeepLinkHandler.self) var deepLinkHandler
    @Environment(\.scenePhase) var scenePhase
    @State private var selectedTab = 0
    @State private var audioService = QuranAudioService.shared

    // Namespace for hero animation between mini and full player
    @Namespace private var playerNamespace

    // MARK: - Shared ViewModels (Single Source of Truth)
    // Created once here, shared across tabs that need the same data
    @State private var prayerVM = PrayerViewModel()
    @State private var quranVM = QuranViewModel()

    // MARK: - Body
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Home Tab
                HomeView(selectedTab: $selectedTab, prayerVM: prayerVM, quranVM: quranVM)
                    .miniPlayerInset(audioService: audioService, animationNamespace: playerNamespace)
                    .tabItem {
                        Label(NSLocalizedString("Home", comment: "Home tab label"), systemImage: "sun.horizon.fill")
                    }
                    .tag(0)

                // Quran Tab
                QuranReaderView(viewModel: quranVM)
                    .miniPlayerInset(audioService: audioService, animationNamespace: playerNamespace)
                    .tabItem {
                        Label(NSLocalizedString("Quran", comment: "Quran tab label"), systemImage: "text.book.closed.fill")
                    }
                    .tag(1)

                // Prayer Tab
                PrayerTimesView(viewModel: prayerVM)
                    .miniPlayerInset(audioService: audioService, animationNamespace: playerNamespace)
                    .tabItem {
                        Label(NSLocalizedString("Prayer", comment: "Prayer tab label"), systemImage: "moon.stars.fill")
                    }
                    .tag(2)

                // More Tab (includes Adhkar, Qibla, Settings, etc.)
                MoreView(prayerVM: prayerVM)
                    .miniPlayerInset(audioService: audioService, animationNamespace: playerNamespace)
                    .tabItem {
                        Label(NSLocalizedString("More", comment: "More tab label"), systemImage: "square.grid.2x2.fill")
                    }
                    .tag(3)
            }
            .tabViewStyle(.automatic) // iOS 26: Enable scroll minimize behavior
            .tint(themeManager.currentTheme.accent)

            // Full player overlay (replaces .sheet())
            if audioService.isFullPlayerPresented {
                // Dimming backdrop
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        HapticManager.shared.trigger(.light)
                        audioService.isFullPlayerPresented = false
                    }

                // Full player
                AudioPlayerView(animationNamespace: playerNamespace) {
                    audioService.isFullPlayerPresented = false
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: audioService.isFullPlayerPresented)
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
                print("Deep link navigation: \(destination.rawValue) -> Tab \(destination.tabIndex)")
                #endif
            }
        }
        // Listen for prayer tab navigation from notification tap
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToPrayerTab"))) { _ in
            selectedTab = 2
        }
        // Listen for Quick Action notifications
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("QuickActionTriggered"))) { notification in
            if let shortcutItem = notification.object as? UIApplicationShortcutItem {
                deepLinkHandler.handle(shortcutItem: shortcutItem)
            }
        }
        // Clear app icon badge when app comes to foreground
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Mini Player Safe Area Inset

/// Applied to each tab's root content so the mini player sits inside the tab's
/// safe area — naturally above the iOS 26 floating tab bar.
private struct MiniPlayerInsetModifier: ViewModifier {
    var audioService: QuranAudioService
    var animationNamespace: Namespace.ID

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if audioService.hasActivePlayback {
                    MiniAudioPlayerView(
                        animationNamespace: animationNamespace
                    ) {
                        audioService.isFullPlayerPresented = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
    }
}

extension View {
    func miniPlayerInset(audioService: QuranAudioService, animationNamespace: Namespace.ID) -> some View {
        modifier(MiniPlayerInsetModifier(audioService: audioService, animationNamespace: animationNamespace))
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(ThemeManager())
        .environment(DeepLinkHandler())
}
