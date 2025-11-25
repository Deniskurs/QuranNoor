//
//  ToastView.swift
//  QuranNoor
//
//  Toast notification component for encouraging messages and feedback
//

import SwiftUI

// MARK: - Toast Style
enum ToastStyle {
    case success
    case info
    case warning
    case error
    case spiritual  // Special style for Islamic messages

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .spiritual: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .success: return AppColors.primary.green
        case .info: return AppColors.primary.green  // Use emerald (softer than teal)
        case .warning: return Color.orange
        case .error: return Color.red
        case .spiritual: return AppColors.primary.gold
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let message: String
    let style: ToastStyle
    let showUndo: Bool
    let onUndo: (() -> Void)?

    @Binding var isPresented: Bool

    // Animation state
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    // MARK: - Initializer
    init(
        message: String,
        style: ToastStyle = .success,
        isPresented: Binding<Bool>,
        showUndo: Bool = false,
        onUndo: (() -> Void)? = nil
    ) {
        self.message = message
        self.style = style
        self._isPresented = isPresented
        self.showUndo = showUndo
        self.onUndo = onUndo
    }

    // MARK: - Body
    var body: some View {
        if isPresented {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: style.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(style.color)

                // Message
                ThemedText.body(message)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Spacer()

                // Undo button (optional)
                if showUndo, let onUndo = onUndo {
                    Button {
                        HapticManager.shared.trigger(.light)
                        onUndo()
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        ThemedText.body("Undo")
                            .foregroundColor(themeManager.currentTheme.featureAccent)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardColor)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.color.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .offset(y: offset)
            .opacity(opacity)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
            .onAppear {
                // Slide in from top with bounce
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    offset = 0
                    opacity = 1
                }

                // Auto-dismiss after delay (if no undo button)
                if !showUndo {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        dismissToast()
                    }
                } else {
                    // Longer delay if undo is available
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        dismissToast()
                    }
                }
            }
            .gesture(
                // Swipe up to dismiss early
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.height < -20 {
                            dismissToast()
                        }
                    }
            )
        }
    }

    // MARK: - Methods
    private func dismissToast() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = -100
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let style: ToastStyle
    let showUndo: Bool
    let onUndo: (() -> Void)?

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                ToastView(
                    message: message,
                    style: style,
                    isPresented: $isPresented,
                    showUndo: showUndo,
                    onUndo: onUndo
                )
                .padding(.top, 50)  // Below navigation bar

                Spacer()
            }
            .zIndex(999)  // Ensure toast appears above all content
        }
    }
}

// MARK: - View Extension
extension View {
    /// Show a toast message
    func toast(
        message: String,
        style: ToastStyle = .success,
        isPresented: Binding<Bool>,
        showUndo: Bool = false,
        onUndo: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            style: style,
            showUndo: showUndo,
            onUndo: onUndo
        ))
    }
}

// MARK: - Encouraging Messages Generator
struct EncouragingMessages {
    /// Get a random encouraging message for prayer completion
    static func prayerComplete(prayerName: String) -> String {
        let messages = [
            "Alhamdulillah",
            "May Allah accept your prayer",
            "Masha'Allah",
            "Barakallahu feek",
            "May your prayers be answered"
        ]
        return messages.randomElement() ?? "Alhamdulillah"
    }

    /// Get time-specific message
    static func timeSpecific(prayerName: String) -> String {
        switch prayerName.lowercased() {
        case "fajr":
            return "May Allah bless your early wake"
        case "maghrib":
            return "May your fast be accepted"  // Relevant during Ramadan
        case "isha":
            return "May Allah grant you restful sleep"
        default:
            return prayerComplete(prayerName: prayerName)
        }
    }

    /// Streak achievement messages
    static func streakAchieved(days: Int) -> String {
        switch days {
        case 3:
            return "🔥 3 days streak! Keep it up!"
        case 7:
            return "🔥 7 days streak! Masha'Allah!"
        case 14:
            return "🔥 Two weeks streak! Amazing!"
        case 30:
            return "🔥 30 days streak! Subhan'Allah!"
        case 100:
            return "🔥 100 days streak! Incredible!"
        default:
            return "🔥 \(days) days streak!"
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var showToast = true

    VStack(spacing: 20) {
        Button("Show Success Toast") {
            showToast = true
        }

        Button("Show Spiritual Toast") {
            showToast = true
        }
    }
    .toast(
        message: EncouragingMessages.prayerComplete(prayerName: "Fajr"),
        style: .spiritual,
        isPresented: $showToast,
        showUndo: true,
        onUndo: {
            print("Undo tapped")
        }
    )
    .environment(ThemeManager())
}
