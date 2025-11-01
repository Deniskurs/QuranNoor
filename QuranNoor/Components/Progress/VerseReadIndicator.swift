//
//  VerseReadIndicator.swift
//  QuranNoor
//
//  Visual indicator showing if verse has been read with tap to toggle
//

import SwiftUI

struct VerseReadIndicator: View {
    let isRead: Bool
    let readDate: Date?
    let onToggle: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggle()
            }
        }) {
            HStack(spacing: 6) {
                // Checkmark icon
                ZStack {
                    Circle()
                        .fill(
                            isRead
                                ? AppColors.primary.green.opacity(0.15)
                                : themeManager.currentTheme.textColor.opacity(0.05)
                        )
                        .frame(width: 24, height: 24)

                    Image(systemName: isRead ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(
                            isRead
                                ? AppColors.primary.green
                                : themeManager.currentTheme.textColor.opacity(0.3)
                        )
                }
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

                // Relative date (if read)
                if let date = readDate, isRead {
                    Text(relativeDate(date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRead ? "Verse read" : "Verse unread")
        .accessibilityHint("Double tap to toggle read status")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days < 7 {
                return "\(days)d ago"
            } else if days < 30 {
                let weeks = days / 7
                return "\(weeks)w ago"
            } else {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
    }
}

// MARK: - Preview

#Preview("Read Verse") {
    VerseReadIndicator(
        isRead: true,
        readDate: Date(),
        onToggle: {
            print("Toggled")
        }
    )
    .environmentObject(ThemeManager())
    .padding()
}

#Preview("Unread Verse") {
    VerseReadIndicator(
        isRead: false,
        readDate: nil,
        onToggle: {
            print("Toggled")
        }
    )
    .environmentObject(ThemeManager())
    .padding()
}

#Preview("Read Yesterday") {
    VerseReadIndicator(
        isRead: true,
        readDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        onToggle: {
            print("Toggled")
        }
    )
    .environmentObject(ThemeManager())
    .padding()
}

#Preview("Read 5 Days Ago") {
    VerseReadIndicator(
        isRead: true,
        readDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
        onToggle: {
            print("Toggled")
        }
    )
    .environmentObject(ThemeManager())
    .padding()
}
