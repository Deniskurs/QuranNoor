//
//  ErrorStateView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Reusable error state component with retry functionality
//

import SwiftUI

/// Reusable error state component
struct ErrorStateView: View {
    @EnvironmentObject var themeManager: ThemeManager

    let icon: String
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    let secondaryAction: (() -> Void)?
    let secondaryActionLabel: String?

    init(
        icon: String = "exclamationmark.triangle",
        title: String,
        message: String,
        retryAction: (() -> Void)? = nil,
        secondaryAction: (() -> Void)? = nil,
        secondaryActionLabel: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.retryAction = retryAction
        self.secondaryAction = secondaryAction
        self.secondaryActionLabel = secondaryActionLabel
    }

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .padding(.bottom, 8)

            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Actions
            VStack(spacing: 12) {
                // Retry button
                if let retryAction = retryAction {
                    Button(action: {
                        HapticManager.shared.trigger(.light)
                        retryAction()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primary.teal)
                        .cornerRadius(12)
                    }
                }

                // Secondary button
                if let secondaryAction = secondaryAction, let label = secondaryActionLabel {
                    Button(action: {
                        HapticManager.shared.trigger(.light)
                        secondaryAction()
                    }) {
                        Text(label)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppColors.primary.teal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(themeManager.currentTheme.cardColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.primary.teal, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Convenience Initializers

extension ErrorStateView {
    /// Network error state
    static func network(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "wifi.exclamationmark",
            title: "Connection Issue",
            message: "We couldn't connect to the server. Please check your internet connection and try again.",
            retryAction: retryAction
        )
    }

    /// Location permission error
    static func locationPermission(openSettings: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "location.slash",
            title: "Location Access Needed",
            message: "To calculate accurate prayer times for your area, please enable location access in Settings.",
            retryAction: nil,
            secondaryAction: openSettings,
            secondaryActionLabel: "Open Settings"
        )
    }

    /// Generic load failure
    static func loadFailed(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            icon: "exclamationmark.triangle",
            title: "Couldn't Load Content",
            message: "Something went wrong while loading this content. Please try again.",
            retryAction: retryAction
        )
    }

    /// Offline mode
    static func offline() -> ErrorStateView {
        ErrorStateView(
            icon: "antenna.radiowaves.left.and.right.slash",
            title: "You're Offline",
            message: "Some features require an internet connection. You can still use offline features.",
            retryAction: nil
        )
    }
}

// MARK: - Preview

#Preview("Network Error") {
    ErrorStateView.network {
        print("Retry tapped")
    }
    .environmentObject(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Location Permission") {
    ErrorStateView.locationPermission {
        print("Open settings tapped")
    }
    .environmentObject(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Load Failed") {
    ErrorStateView.loadFailed {
        print("Retry tapped")
    }
    .environmentObject(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Offline") {
    ErrorStateView.offline()
        .environmentObject(ThemeManager())
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    ErrorStateView.network {
        print("Retry tapped")
    }
    .environmentObject({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .background(Color(hex: "#1A2332"))
}
