//
//  SwipeablePrayerRow.swift
//  QuranNoor
//
//  Swipe-to-complete with rubber band, haptics, and smooth animations
//  Drag state stored outside SwiftUI to survive TimelineView updates
//

import SwiftUI

/// Stores drag offsets outside of SwiftUI view lifecycle
/// Note: Not a singleton anymore - each row has its own instance
private final class SwipeDragState {
    private var offset: CGFloat = 0

    func getOffset() -> CGFloat {
        offset
    }

    func setOffset(_ value: CGFloat) {
        offset = value
    }

    func reset() {
        offset = 0
    }
}

/// Wrapper that adds swipe-to-complete gesture to prayer rows
struct SwipeablePrayerRow: View {
    let prayer: PrayerTime
    let isCurrentPrayer: Bool
    let isNextPrayer: Bool
    let relatedSpecialTimes: [SpecialTime]
    let canCheckOff: Bool
    let isCompleted: Bool
    let onCompletionToggle: () -> Void

    // Force view updates when dragging
    @State private var dragTick: Int = 0
    @State private var hasTriggeredThresholdHaptic: Bool = false
    @State private var displayOffset: CGFloat = 0

    // Directional lock to avoid fighting with ScrollView vertical scrolling
    @State private var isDragDirectionLocked: Bool = false
    @State private var isHorizontalDrag: Bool = false

    // Thresholds
    private let threshold: CGFloat = 80
    private let maxSwipe: CGFloat = 140
    private let velocityThreshold: CGFloat = -400

    // Instance-level drag state to avoid cross-row interference
    private let dragState = SwipeDragState()

    private var currentOffset: CGFloat {
        dragState.getOffset()
    }

    private var swipeProgress: CGFloat {
        min(abs(currentOffset) / threshold, 1.0)
    }

    private var isPastThreshold: Bool {
        abs(currentOffset) >= threshold
    }

    var body: some View {
        let _ = dragTick // Subscribe to updates

        ZStack(alignment: .trailing) {
            // Green action background
            if canCheckOff && !isCompleted && currentOffset < 0 {
                actionBackground
            }

            // Main row content
            EnhancedPrayerRow(
                prayer: prayer,
                isCurrentPrayer: isCurrentPrayer,
                isNextPrayer: isNextPrayer,
                relatedSpecialTimes: relatedSpecialTimes,
                canCheckOff: canCheckOff,
                isCompleted: isCompleted,
                onCompletionToggle: onCompletionToggle
            )
            .offset(x: displayOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .simultaneousGesture(swipeGesture)
        .onChange(of: currentOffset) { _, newValue in
            // Sync display offset without animation during drag
            displayOffset = newValue
        }
    }

    // MARK: - Action Background

    private var actionBackground: some View {
        HStack(spacing: 8) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .scaleEffect(isPastThreshold ? 1.1 : 0.9)

            if isPastThreshold {
                Text("Complete")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.green)
        )
        .opacity(swipeProgress)
        .animation(.easeOut(duration: 0.15), value: isPastThreshold)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                guard canCheckOff && !isCompleted else { return }

                // Directional lock: determine if this is a horizontal or vertical drag
                if !isDragDirectionLocked {
                    let absW = abs(value.translation.width)
                    let absH = abs(value.translation.height)
                    let totalMovement = absW + absH

                    // Wait until we have enough movement to decide direction
                    guard totalMovement > 10 else { return }

                    isDragDirectionLocked = true
                    isHorizontalDrag = absW > absH
                }

                // If this is a vertical drag, bail out completely — let ScrollView handle it
                guard isHorizontalDrag else { return }

                let translation = value.translation.width

                // Only allow left swipe
                guard translation < 0 else { return }

                // Calculate offset with rubber band effect past threshold
                let absTranslation = abs(translation)
                let offset: CGFloat

                if absTranslation > threshold {
                    // Rubber band: diminishing returns past threshold
                    let excess = absTranslation - threshold
                    let dampened = threshold + (excess * 0.3)
                    offset = -min(dampened, maxSwipe)
                } else {
                    offset = translation
                }

                dragState.setOffset(offset)
                dragTick += 1

                // Haptic feedback when crossing threshold
                if abs(offset) >= threshold && !hasTriggeredThresholdHaptic {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    hasTriggeredThresholdHaptic = true
                } else if abs(offset) < threshold {
                    hasTriggeredThresholdHaptic = false
                }
            }
            .onEnded { value in
                let wasHorizontalDrag = isHorizontalDrag

                // Reset directional lock for next gesture
                isDragDirectionLocked = false
                isHorizontalDrag = false

                guard canCheckOff && !isCompleted else { return }

                // Only process completion/snap-back if this was a confirmed horizontal swipe
                guard wasHorizontalDrag else { return }

                let translation = value.translation.width
                let velocity = value.velocity.width

                // Complete if past threshold OR quick flick
                let pastThreshold = translation < -threshold
                let quickFlick = translation < 0 && velocity < velocityThreshold

                if pastThreshold || quickFlick {
                    // Success haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    onCompletionToggle()
                }

                // Animated snap-back
                hasTriggeredThresholdHaptic = false
                dragState.reset()
                dragTick += 1

                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    displayOffset = 0
                }
            }
    }
}

// MARK: - Preview

#Preview("Swipeable Rows") {
    let now = Date()
    let times = DailyPrayerTimes(
        date: now,
        fajr: now.addingTimeInterval(-3600 * 10),
        sunrise: now.addingTimeInterval(-3600 * 9),
        dhuhr: now.addingTimeInterval(-3600 * 5),
        asr: now.addingTimeInterval(-1800),
        maghrib: now.addingTimeInterval(3600),
        isha: now.addingTimeInterval(3600 * 3),
        imsak: nil,
        sunset: now.addingTimeInterval(3600 - 300),
        midnight: nil,
        firstThird: nil,
        lastThird: nil
    )

    ScrollView {
        VStack(spacing: 12) {
            ForEach(times.prayerTimes) { prayer in
                SwipeablePrayerRow(
                    prayer: prayer,
                    isCurrentPrayer: prayer.name == .asr,
                    isNextPrayer: prayer.name == .maghrib,
                    relatedSpecialTimes: [],
                    canCheckOff: prayer.hasStarted,
                    isCompleted: false,
                    onCompletionToggle: { print("Toggle \(prayer.name)") }
                )
            }
        }
        .padding()
    }
    .background(Color(hex: "#1A2332"))
    .environment(ThemeManager())
}
