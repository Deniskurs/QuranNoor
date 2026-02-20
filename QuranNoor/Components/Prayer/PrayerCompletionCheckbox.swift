//
//  PrayerCompletionCheckbox.swift
//  QuranNoor
//
//  Checkbox component for prayer completion
//  Receives isCompleted from parent to avoid @Observable observation issues
//

import SwiftUI

/// Prayer completion checkbox with animations
/// Note: isCompleted is passed from parent to prevent gesture interference in SwipeablePrayerRow
struct PrayerCompletionCheckbox: View {
    // MARK: - Properties

    let prayerName: PrayerName
    let canCheckOff: Bool
    let isCurrentPrayer: Bool
    let isCompleted: Bool  // Passed from parent
    let onCompletionToggle: () -> Void

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    // Animation state
    @State private var scale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.8
    @State private var scaleTask: Task<Void, Never>?
    @State private var hapticTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        Button {
            // Scale animation on tap
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                scale = 0.95
            }

            // Spring back with delay using structured concurrency
            scaleTask?.cancel()
            scaleTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }

            // Trigger completion toggle
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onCompletionToggle()
            }

            // Success audio + haptic pattern when completing (not uncompleting)
            if !isCompleted {
                hapticTask?.cancel()
                hapticTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.15))
                    guard !Task.isCancelled else { return }
                    AudioHapticCoordinator.shared.playPrayerComplete()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(checkboxColor(isCompleted: isCompleted), lineWidth: 2.5)
                    .frame(width: 32, height: 32)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                        .shadow(color: themeManager.currentTheme.accent.opacity(0.5), radius: 4)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            // Checkmark pop animation
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                checkmarkScale = 1.0
                            }
                        }
                        .onDisappear {
                            checkmarkScale = 0.8
                        }
                }
            }
            .background(
                Circle()
                    .fill(isCompleted ? checkboxColor(isCompleted: isCompleted) : Color.clear)
                    .frame(width: 32, height: 32)
            )
            .frame(width: 60, height: 60) // Large tap target
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(.plain)
        .disabled(!canCheckOff)
        .scaleEffect(scale)
        .accessibilityLabel(accessibilityLabel(isCompleted: isCompleted))
        .accessibilityAddTraits(.isButton)
        .onDisappear {
            scaleTask?.cancel()
            hapticTask?.cancel()
        }
    }

    // MARK: - Computed Properties

    private func checkboxColor(isCompleted: Bool) -> Color {
        if !canCheckOff {
            // Future prayer - very dimmed
            return themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.disabledOpacity)
        } else if isCompleted {
            return themeManager.currentTheme.accent
        } else if isCurrentPrayer {
            return themeManager.currentTheme.accent
        } else {
            return themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.tertiaryOpacity)
        }
    }

    private func accessibilityLabel(isCompleted: Bool) -> String {
        let status = isCompleted ? "completed" : "not completed"
        let action = canCheckOff ? "Double tap to toggle" : "Cannot mark yet"
        return "\(prayerName.displayName) prayer, \(status). \(action)"
    }
}

// MARK: - Preview

#Preview("Checkbox States") {
    VStack(spacing: 20) {
        // Uncompleted, can check off
        PrayerCompletionCheckbox(
            prayerName: .fajr,
            canCheckOff: true,
            isCurrentPrayer: true,
            isCompleted: false,
            onCompletionToggle: {}
        )

        // Completed
        PrayerCompletionCheckbox(
            prayerName: .dhuhr,
            canCheckOff: true,
            isCurrentPrayer: false,
            isCompleted: true,
            onCompletionToggle: {}
        )

        // Future prayer - disabled
        PrayerCompletionCheckbox(
            prayerName: .asr,
            canCheckOff: false,
            isCurrentPrayer: false,
            isCompleted: false,
            onCompletionToggle: {}
        )
    }
    .padding()
    .background(Color(hex: "#1A2332"))
    .environment(ThemeManager())
}
