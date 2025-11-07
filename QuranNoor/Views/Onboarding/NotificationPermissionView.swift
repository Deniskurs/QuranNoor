//
//  NotificationPermissionView.swift
//  QuranNoor
//
//  Notification permission request for onboarding
//

import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let coordinator: OnboardingCoordinator
    @ObservedObject var permissionManager: PermissionManager

    @State private var hasRequestedPermission = false
    @State private var isRequesting = false
    @State private var showSettingsAlert = false
    @State private var showPrimingView = true  // Show priming view first
    @State private var hasAutoAdvanced = false  // Prevent double-advance

    // MARK: - Body
    var body: some View {
        Group {
            if showPrimingView && !hasRequestedPermission && !permissionManager.notificationStatus.isGranted {
                // Show priming view first (contextual education)
                NotificationPrimingView(
                    onRequestPermission: {
                        withAnimation(.spring(response: 0.4)) {
                            showPrimingView = false
                        }
                        // Small delay to allow animation, then request
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            requestNotificationPermission()
                        }
                    },
                    onSkip: {
                        AudioHapticCoordinator.shared.playBack()
                        coordinator.advance()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Show permission status and actions
                ScrollView {
                    VStack(spacing: 32) {
                        // Status icon
                        ZStack {
                            Circle()
                                .fill(themeManager.currentTheme.accentSecondary.opacity(0.15))
                                .frame(width: 120, height: 120)

                            Image(systemName: permissionManager.notificationStatus.isGranted ? "checkmark.circle.fill" : "bell.badge.fill")
                                .font(.system(size: 60))
                                .foregroundColor(permissionManager.notificationStatus.isGranted ? themeManager.currentTheme.accentPrimary : themeManager.currentTheme.accentSecondary)
                                .symbolEffect(.bounce, value: permissionManager.notificationStatus.isGranted)
                        }
                        .padding(.top, 60)

                        // Content
                        VStack(spacing: 16) {
                            ThemedText(
                                permissionManager.notificationStatus.isGranted ? "Notifications Enabled" : "Prayer Reminders",
                                style: .title
                            )
                            .foregroundColor(themeManager.currentTheme.accentPrimary)

                            ThemedText.body(
                                permissionManager.notificationStatus.isGranted ?
                                "You'll receive timely reminders for your prayers" :
                                "Get notified before each prayer time so you never miss a salah"
                            )
                            .multilineTextAlignment(.center)
                            .opacity(0.8)
                            .padding(.horizontal, 40)
                        }

                        // Action buttons
                        VStack(spacing: 12) {
                            if !permissionManager.notificationStatus.isGranted {
                                Button {
                                    requestNotificationPermission()
                                } label: {
                                    if isRequesting {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        Label("Enable Notifications", systemImage: "bell.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .tint(themeManager.currentTheme.accentSecondary)
                                .disabled(isRequesting)
                            }

                            // Show "Open Settings" if denied
                            if permissionManager.notificationStatus.needsSettingsRedirect {
                                Button {
                                    showSettingsAlert = true
                                } label: {
                                    Label("Open Settings", systemImage: "gear")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .tint(themeManager.currentTheme.accentSecondary)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .alert("Notification Access Required", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                permissionManager.openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notification access in Settings to receive prayer reminders and never miss a salah.")
        }
        .task {
            // Check status when view appears
            _ = await permissionManager.checkNotificationStatus()
        }
        .onChange(of: permissionManager.notificationStatus) { oldStatus, newStatus in
            // Auto-continue when permission is granted
            if hasRequestedPermission && newStatus.isGranted && !hasAutoAdvanced {
                hasAutoAdvanced = true  // Prevent double-advance
                AudioHapticCoordinator.shared.playSuccess()
                coordinator.updateNotificationPermission(.granted)

                // Auto-advance after brief delay for UX
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                    coordinator.advance()
                }
            } else if hasRequestedPermission && newStatus == .denied {
                coordinator.updateNotificationPermission(.denied)
            } else if hasRequestedPermission && newStatus == .restricted {
                coordinator.updateNotificationPermission(.restricted)
            }
        }
    }

    // MARK: - Methods
    private func requestNotificationPermission() {
        hasRequestedPermission = true
        isRequesting = true
        AudioHapticCoordinator.shared.playConfirm()

        Task {
            let status = await permissionManager.requestNotificationPermission()

            await MainActor.run {
                isRequesting = false

                // Update coordinator with result
                switch status {
                case .granted:
                    coordinator.updateNotificationPermission(.granted)
                case .denied:
                    coordinator.updateNotificationPermission(.denied)
                case .restricted:
                    coordinator.updateNotificationPermission(.restricted)
                case .notDetermined:
                    // If still not determined after request, treat as denied
                    coordinator.updateNotificationPermission(.denied)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationPermissionView(
        coordinator: OnboardingCoordinator(),
        permissionManager: PermissionManager.shared
    )
    .environmentObject(ThemeManager())
}
