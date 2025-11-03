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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundGradient)
            .cornerRadius(16)
            .shadow(
                color: AppColors.primary.green.opacity(0.3),
                radius: isPressed ? 5 : 10,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(isDisabled || isLoading)
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

    // MARK: - Background Gradient
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.primary.green,
                AppColors.primary.teal.opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
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
    .environmentObject(ThemeManager())
}
