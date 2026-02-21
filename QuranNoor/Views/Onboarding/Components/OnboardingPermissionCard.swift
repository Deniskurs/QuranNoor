//
//  OnboardingPermissionCard.swift
//  QuranNoor
//
//  Reusable permission card for onboarding
//  Used for both location and notification permission requests inline

import SwiftUI

struct OnboardingPermissionCard: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let icon: String
    let title: String
    let subtitle: String
    let privacyNote: String
    let isGranted: Bool
    let isRequesting: Bool
    let onRequest: () -> Void
    let onOpenSettings: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String,
        privacyNote: String,
        isGranted: Bool,
        isRequesting: Bool = false,
        onRequest: @escaping () -> Void,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.privacyNote = privacyNote
        self.isGranted = isGranted
        self.isRequesting = isRequesting
        self.onRequest = onRequest
        self.onOpenSettings = onOpenSettings
    }

    // MARK: - Body
    var body: some View {
        let theme = themeManager.currentTheme

        CardView(showPattern: false, intensity: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Icon + Title row
                HStack(spacing: Spacing.xs) {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : icon)
                        .font(.system(size: 24))
                        .foregroundColor(isGranted ? theme.accent : theme.accentMuted)
                        .symbolEffect(.bounce, value: isGranted)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textPrimary)

                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    // Status indicator or action
                    if isGranted {
                        Text("Enabled")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.accent)
                    }
                }

                // Action button (when not granted)
                if !isGranted {
                    if isRequesting {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(theme.accent)
                            Text("Requesting...")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                        .padding(.vertical, Spacing.xxs)
                    } else {
                        Button {
                            onRequest()
                        } label: {
                            Text("Enable")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .tint(theme.accentMuted)

                        // Open Settings link (shown after denial)
                        if let onOpenSettings {
                            Button {
                                onOpenSettings()
                            } label: {
                                Label("Open Settings", systemImage: "gear")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .tint(theme.textTertiary)
                        }
                    }

                    // Privacy note
                    Text(privacyNote)
                        .font(.caption2)
                        .foregroundColor(theme.textTertiary)
                }
            }
        }
        .accessibleElement(
            label: "\(title). \(isGranted ? "Enabled" : "Not enabled"). \(subtitle)",
            hint: isGranted ? nil : "Double tap the enable button to grant permission",
            traits: .isStaticText
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        OnboardingPermissionCard(
            icon: "location.fill",
            title: "Location",
            subtitle: "For accurate prayer times",
            privacyNote: "Your location stays on your device",
            isGranted: false,
            onRequest: {}
        )

        OnboardingPermissionCard(
            icon: "bell.badge.fill",
            title: "Notifications",
            subtitle: "Never miss a prayer time",
            privacyNote: "You control which alerts you receive",
            isGranted: true,
            onRequest: {}
        )
    }
    .padding()
    .environment(ThemeManager())
}
