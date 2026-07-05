//
//  PrimaryButton.swift
//  QuranNoor
//
//  Premium button with gradient, spring animation, and haptic feedback
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Primary Button Component
struct PrimaryButton: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let title: String
    let icon: String?
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool
    let playSound: Bool

    @State private var isPressed: Bool = false

    // MARK: - Initializer
    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        playSound: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.playSound = playSound
    }

    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.onAccent))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }

                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundColor(themeManager.currentTheme.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            // Accent-tinted interactive Liquid Glass. Replacing the old
            // accent→accentMuted gradient also removes its mid-tone contrast
            // dip — onAccent is contrast-computed against the pure accent.
            .glassEffect(
                .regular.tint(themeManager.currentTheme.accent).interactive(),
                in: .rect(cornerRadius: BorderRadius.xl, style: .continuous)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(AppAnimation.fast, value: isPressed)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isLoading ? "Loading" : "")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }


    // MARK: - Audio & Haptic Feedback
    private func handleTap() {
        if playSound {
            AudioHapticCoordinator.shared.playButtonTap()
        } else {
            // Haptic only if sound is disabled
            HapticManager.shared.trigger(.medium)
        }
        action()
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Default button
        PrimaryButton("Continue") {
            print("Button tapped")
        }

        // Button with icon
        PrimaryButton("Set Location", icon: "location.fill") {
            print("Location tapped")
        }

        // Loading button
        PrimaryButton("Loading...", isLoading: true) {
            print("This won't fire")
        }

        // Disabled button
        PrimaryButton("Disabled", isDisabled: true) {
            print("This won't fire")
        }
    }
    .padding()
    .background(ThemeManager().currentTheme.backgroundColor)
    .environment(ThemeManager())
}
