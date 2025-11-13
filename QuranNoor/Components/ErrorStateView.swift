//
//  ErrorStateView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Fallback UI for error states
//

import SwiftUI

/// Reusable error state view with retry capability
struct ErrorStateView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let title: String
    let message: String
    let icon: String
    let actions: [ErrorAction]

    struct ErrorAction {
        let title: String
        let icon: String
        let action: () -> Void

        static func retry(_ action: @escaping () -> Void) -> ErrorAction {
            ErrorAction(title: "Try Again", icon: "arrow.clockwise", action: action)
        }

        static func dismiss(_ action: @escaping () -> Void) -> ErrorAction {
            ErrorAction(title: "Dismiss", icon: "xmark.circle", action: action)
        }

        static func openSettings() -> ErrorAction {
            ErrorAction(title: "Settings", icon: "gear") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    init(
        title: String = "Something Went Wrong",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        actions: [ErrorAction] = []
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actions = actions
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.orange)
                .symbolEffect(.pulse)

            // Title and Message
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(themeManager.primaryTextColor)

                Text(message)
                    .font(.body)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Actions
            if !actions.isEmpty {
                VStack(spacing: 12) {
                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        Button {
                            action.action()
                            AudioHapticCoordinator.shared.playButtonPress()
                        } label: {
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.title)
                            }
                            .font(.body.weight(.medium))
                            .foregroundStyle(index == 0 ? .white : themeManager.primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(index == 0 ? themeManager.accentColor : themeManager.cardBackground)
                            )
                        }
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

/// Empty state view (similar to error state but more positive)
struct EmptyStateView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        icon: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(themeManager.accentColor.opacity(0.6))

            // Title and Message
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(themeManager.primaryTextColor)

                Text(message)
                    .font(.body)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                    AudioHapticCoordinator.shared.playButtonPress()
                } label: {
                    Text(actionTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(themeManager.accentColor)
                        )
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

/// Loading state view with retry option
struct LoadingStateView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let message: String
    let canCancel: Bool
    let onCancel: (() -> Void)?

    init(
        message: String = "Loading...",
        canCancel: Bool = false,
        onCancel: (() -> Void)? = nil
    ) {
        self.message = message
        self.canCancel = canCancel
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.accentColor)

            Text(message)
                .font(.body)
                .foregroundStyle(themeManager.secondaryTextColor)

            if canCancel, let onCancel = onCancel {
                Button("Cancel") {
                    onCancel()
                    AudioHapticCoordinator.shared.playButtonPress()
                }
                .font(.subheadline)
                .foregroundStyle(themeManager.accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

// MARK: - Previews

#Preview("Error State") {
    ErrorStateView(
        title: "Prayer Times Unavailable",
        message: "We couldn't load prayer times for your location. Please check your internet connection and try again.",
        icon: "wifi.slash",
        actions: [
            .retry { print("Retry tapped") },
            .openSettings()
        ]
    )
    .environment(ThemeManager())
}

#Preview("Empty State") {
    EmptyStateView(
        title: "No Bookmarks Yet",
        message: "Save your favorite surahs and verses to access them quickly later.",
        icon: "bookmark.circle",
        actionTitle: "Browse Quran"
    ) {
        print("Browse tapped")
    }
    .environment(ThemeManager())
}

#Preview("Loading State") {
    LoadingStateView(
        message: "Calculating prayer times...",
        canCancel: true
    ) {
        print("Cancel tapped")
    }
    .environment(ThemeManager())
}
