//
//  WelcomePermissionsView.swift
//  QuranNoor
//
//  Screen 1: Welcome + inline permission requests
//  Bismillah entrance with PhaseAnimator, feature highlights,
//  and two permission cards for location and notifications

import SwiftUI

struct WelcomePermissionsView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let coordinator: OnboardingCoordinator
    var permissionManager: PermissionManager

    @State private var isLocationRequesting = false
    @State private var isNotificationRequesting = false
    @State private var showLocationSettings = false
    @State private var showNotificationSettings = false
    @State private var animationPhase: AnimationPhase = .initial

    // Feedback
    private let feedbackCoordinator = AudioHapticCoordinator.shared

    // MARK: - Animation Phase
    enum AnimationPhase: CaseIterable {
        case initial
        case visible

        var bismillahOpacity: Double {
            switch self {
            case .initial: return 0
            case .visible: return 1
            }
        }

        var bismillahScale: Double {
            switch self {
            case .initial: return 0.95
            case .visible: return 1.0
            }
        }
    }

    // MARK: - Body
    var body: some View {
        let theme = themeManager.currentTheme

        ScrollView {
            VStack(spacing: Spacing.lg) {
                Spacer()
                    .frame(height: Spacing.xl)

                // MARK: - Bismillah (Visual Centerpiece)
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                    .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 28))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(animationPhase.bismillahOpacity)
                    .scaleEffect(animationPhase.bismillahScale)
                    .padding(.horizontal, Spacing.screenHorizontal)

                // MARK: - App Identity
                VStack(spacing: Spacing.xxs) {
                    ThemedText.title("Qur'an Noor", italic: false)
                        .foregroundColor(theme.accent)

                    Text("Light of the Qur'an")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(theme.textSecondary)
                }

                // MARK: - Feature Highlights
                VStack(spacing: Spacing.sm) {
                    FeatureRow(
                        icon: "clock.fill",
                        title: "Accurate Prayer Times",
                        description: "Never miss a prayer with precise timings"
                    )

                    FeatureRow(
                        icon: "book.fill",
                        title: "Complete Quran",
                        description: "Read with translations and audio recitations"
                    )

                    FeatureRow(
                        icon: "location.north.fill",
                        title: "Qibla Direction",
                        description: "Find the direction to Mecca anywhere"
                    )
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .opacity(animationPhase == .visible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: animationPhase)

                // MARK: - Permission Cards
                VStack(spacing: Spacing.sm) {
                    // Location Permission
                    OnboardingPermissionCard(
                        icon: "location.fill",
                        title: "Location",
                        subtitle: "For accurate prayer times",
                        privacyNote: "Your location stays on your device",
                        isGranted: permissionManager.locationStatus.isGranted,
                        isRequesting: isLocationRequesting,
                        onRequest: {
                            requestLocationPermission()
                        },
                        onOpenSettings: permissionManager.locationStatus.needsSettingsRedirect ? {
                            showLocationSettings = true
                        } : nil
                    )

                    // Notification Permission
                    OnboardingPermissionCard(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        subtitle: "Never miss a prayer time",
                        privacyNote: "You control which alerts you receive",
                        isGranted: permissionManager.notificationStatus.isGranted,
                        isRequesting: isNotificationRequesting,
                        onRequest: {
                            requestNotificationPermission()
                        },
                        onOpenSettings: permissionManager.notificationStatus.needsSettingsRedirect ? {
                            showNotificationSettings = true
                        } : nil
                    )
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .opacity(animationPhase == .visible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: animationPhase)

                Spacer(minLength: Spacing.xxl + 60) // Room for button
            }
        }
        .safeAreaInset(edge: .bottom) {
            // MARK: - Continue Button (always enabled)
            Button {
                feedbackCoordinator.playConfirm()
                coordinator.advance()
            } label: {
                Label("Continue", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(themeManager.currentTheme.accent)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.sm)
            .background(
                themeManager.currentTheme.backgroundColor
                    .opacity(0.95)
                    .ignoresSafeArea()
            )
        }
        .alert("Location Access", isPresented: $showLocationSettings) {
            Button("Open Settings") { permissionManager.openSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings for accurate prayer times.")
        }
        .alert("Notification Access", isPresented: $showNotificationSettings) {
            Button("Open Settings") { permissionManager.openSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to receive prayer reminders.")
        }
        .task {
            // Check current permission statuses
            _ = await permissionManager.checkLocationStatus()
            _ = await permissionManager.checkNotificationStatus()
        }
        .onAppear {
            // Animate entrance
            withAnimation(.easeOut(duration: 0.8)) {
                animationPhase = .visible
            }
        }
        .accessibilityPageAnnouncement("Welcome to Qur'an Noor. Step 1 of 3. Set up your permissions to get started.")
    }

    // MARK: - Permission Requests

    private func requestLocationPermission() {
        isLocationRequesting = true
        feedbackCoordinator.playConfirm()

        Task {
            let status = await permissionManager.requestLocationPermission()

            await MainActor.run {
                isLocationRequesting = false

                switch status {
                case .granted:
                    coordinator.updateLocationPermission(.granted)
                    feedbackCoordinator.playSuccess()
                case .denied:
                    coordinator.updateLocationPermission(.denied)
                case .restricted:
                    coordinator.updateLocationPermission(.restricted)
                case .notDetermined:
                    coordinator.updateLocationPermission(.denied)
                }
            }
        }
    }

    private func requestNotificationPermission() {
        isNotificationRequesting = true
        feedbackCoordinator.playConfirm()

        Task {
            let status = await permissionManager.requestNotificationPermission()

            await MainActor.run {
                isNotificationRequesting = false

                switch status {
                case .granted:
                    coordinator.updateNotificationPermission(.granted)
                    feedbackCoordinator.playSuccess()
                case .denied:
                    coordinator.updateNotificationPermission(.denied)
                case .restricted:
                    coordinator.updateNotificationPermission(.restricted)
                case .notDetermined:
                    coordinator.updateNotificationPermission(.denied)
                }
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        let theme = themeManager.currentTheme

        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(theme.accent)
                .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomePermissionsView(
        coordinator: OnboardingCoordinator(),
        permissionManager: PermissionManager.shared
    )
    .environment(ThemeManager())
}
