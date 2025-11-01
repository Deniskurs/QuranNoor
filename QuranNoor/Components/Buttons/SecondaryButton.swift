//
//  SecondaryButton.swift
//  QuranNoor
//
//  Outline button with gold border for secondary actions
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Secondary Button Style Type
enum SecondaryButtonStyleType {
    case gold       // Gold border
    case green      // Green border
    case neutral    // Theme-aware border
}

// MARK: - Secondary Button Component
struct SecondaryButton: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    let icon: String?
    let style: SecondaryButtonStyleType
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool

    @State private var isPressed: Bool = false

    // MARK: - Initializer
    init(
        _ title: String,
        icon: String? = nil,
        style: SecondaryButtonStyleType = .gold,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
        self.isDisabled = isDisabled
        self.isLoading = isLoading
    }

    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: borderColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
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

    // MARK: - Style Computed Properties
    private var borderColor: Color {
        switch style {
        case .gold:
            return AppColors.primary.gold
        case .green:
            return AppColors.primary.green
        case .neutral:
            return themeManager.currentTheme.textColor.opacity(0.3)
        }
    }

    private var textColor: Color {
        switch style {
        case .gold:
            return AppColors.primary.gold
        case .green:
            return AppColors.primary.green
        case .neutral:
            return themeManager.currentTheme.textColor
        }
    }

    private var backgroundColor: Color {
        isPressed ? borderColor.opacity(0.1) : Color.clear
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

// MARK: - Tertiary Button (Text-Only)
struct TertiaryButton: View {
    // MARK: - Properties
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void

    @State private var isPressed: Bool = false

    // MARK: - Initializer
    init(
        _ title: String,
        icon: String? = nil,
        color: Color = AppColors.primary.green,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(color)
            .opacity(isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Haptic Feedback
    private func handleTap() {
        #if canImport(UIKit)
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        #endif
        action()
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            // Gold outline (default)
            SecondaryButton("Browse Duas") {
                print("Browse tapped")
            }

            // Green outline
            SecondaryButton("Set Location", style: .green) {
                print("Location tapped")
            }

            // Neutral outline
            SecondaryButton("Cancel", style: .neutral) {
                print("Cancel tapped")
            }

            // With icons
            SecondaryButton("Share", icon: "square.and.arrow.up", style: .gold) {
                print("Share tapped")
            }

            SecondaryButton("Download", icon: "arrow.down.circle", style: .green) {
                print("Download tapped")
            }

            // Loading state
            SecondaryButton("Loading...", style: .gold, isLoading: true) {
                print("Won't fire")
            }

            // Disabled state
            SecondaryButton("Disabled", style: .green, isDisabled: true) {
                print("Won't fire")
            }

            Divider()
                .padding(.vertical)

            // Tertiary buttons (text-only)
            VStack(alignment: .leading, spacing: 16) {
                ThemedText.caption("TERTIARY BUTTONS (TEXT ONLY)")

                TertiaryButton("Learn More", icon: "arrow.right") {
                    print("Learn more")
                }

                TertiaryButton("Skip for now", color: .secondary) {
                    print("Skip")
                }

                TertiaryButton("View Details", icon: "chevron.right", color: AppColors.primary.gold) {
                    print("Details")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .padding(.vertical)

            // Usage examples in context
            VStack(spacing: 12) {
                PrimaryButton("Confirm Prayer Time") {
                    print("Confirm")
                }

                SecondaryButton("Customize Settings", icon: "gearshape") {
                    print("Settings")
                }

                TertiaryButton("Skip", color: .secondary) {
                    print("Skip")
                }
            }
        }
        .padding()
    }
    .background(ThemeManager().currentTheme.backgroundColor)
    .environmentObject(ThemeManager())
}
