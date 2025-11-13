//
//  IconButton.swift
//  QuranNoor
//
//  Circular neumorphic icon button with haptic feedback
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Icon Button Style
enum IconButtonStyle {
    case primary    // Green gradient
    case secondary  // Card color with neumorphic shadows
    case accent     // Gold accent
}

// MARK: - Icon Button Component
struct IconButton: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let icon: String
    let style: IconButtonStyle
    let size: CGFloat
    let action: () -> Void
    let isDisabled: Bool

    @State private var isPressed: Bool = false

    // MARK: - Initializer
    init(
        icon: String,
        style: IconButtonStyle = .secondary,
        size: CGFloat = 44,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(
                        color: lightShadowColor,
                        radius: isPressed ? 5 : 8,
                        x: isPressed ? -2 : -4,
                        y: isPressed ? -2 : -4
                    )
                    .shadow(
                        color: darkShadowColor,
                        radius: isPressed ? 5 : 8,
                        x: isPressed ? 2 : 4,
                        y: isPressed ? 2 : 4
                    )

                // Icon
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .frame(width: size, height: size)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(isDisabled)
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

    // MARK: - Style Computed Properties
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppColors.primary.green
        case .secondary:
            return themeManager.currentTheme.cardColor
        case .accent:
            return AppColors.primary.gold
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary, .accent:
            return .white
        case .secondary:
            return themeManager.currentTheme.textColor
        }
    }

    private var borderColor: Color {
        style == .secondary ? Color.clear : Color.clear
    }

    private var borderWidth: CGFloat {
        0
    }

    private var iconSize: CGFloat {
        size * 0.45 // Icon is 45% of button size
    }

    // MARK: - Neumorphic Shadows
    private var lightShadowColor: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.white.opacity(0.7)
        case .dark:
            return Color.white.opacity(0.05)
        case .night:
            return Color.white.opacity(0.02)
        }
    }

    private var darkShadowColor: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.black.opacity(0.2)
        case .dark:
            return Color.black.opacity(0.4)
        case .night:
            return Color.black.opacity(0.6)
        }
    }

    // MARK: - Haptic Feedback
    private func handleTap() {
        triggerHapticFeedback()
        action()
    }

    private func triggerHapticFeedback() {
        #if canImport(UIKit)
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        haptic.impactOccurred()
        #endif
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        // Different styles
        HStack(spacing: 24) {
            IconButton(icon: "heart.fill", style: .primary) {
                print("Primary tapped")
            }

            IconButton(icon: "bookmark.fill", style: .secondary) {
                print("Secondary tapped")
            }

            IconButton(icon: "star.fill", style: .accent) {
                print("Accent tapped")
            }
        }

        // Different sizes
        HStack(spacing: 24) {
            IconButton(icon: "play.fill", size: 36) {
                print("Small")
            }

            IconButton(icon: "pause.fill", size: 52) {
                print("Medium")
            }

            IconButton(icon: "stop.fill", size: 64) {
                print("Large")
            }
        }

        // Common use cases
        HStack(spacing: 16) {
            IconButton(icon: "location.fill") {
                print("Location")
            }

            IconButton(icon: "bell.fill") {
                print("Notifications")
            }

            IconButton(icon: "gearshape.fill") {
                print("Settings")
            }

            IconButton(icon: "arrow.clockwise") {
                print("Refresh")
            }
        }

        // Disabled state
        IconButton(icon: "lock.fill", isDisabled: true) {
            print("Won't fire")
        }
    }
    .padding()
    .background(ThemeManager().currentTheme.backgroundColor)
    .environment(ThemeManager())
}
