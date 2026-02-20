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

    func color(for theme: ThemeMode) -> Color {
        switch self {
        case .success: return theme.accent
        case .info: return theme.accent
        case .warning: return Color.orange
        case .error: return Color.red
        case .spiritual: return theme.accentMuted
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
    @State private var dismissTask: Task<Void, Never>?

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
                    .font(.title3.weight(.semibold))
                    .foregroundColor(style.color(for: themeManager.currentTheme))

                // Message
                ThemedText.body(message)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)

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
                            .foregroundColor(themeManager.currentTheme.accent)
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
                        color: themeManager.currentTheme.textPrimary.opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.color(for: themeManager.currentTheme).opacity(0.3), lineWidth: 1)
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

                // Auto-dismiss after delay using structured concurrency
                let delay: TimeInterval = showUndo ? 3.5 : 2.5
                dismissTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
                    guard !Task.isCancelled else { return }
                    dismissToast()
                }
            }
            .onDisappear {
                dismissTask?.cancel()
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
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
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
    /// Get a stable encouraging message for prayer completion
    /// Uses day of year + prayer name to provide variety without changing on every render
    /// Now includes prayer-specific messages for more meaningful feedback
    static func prayerComplete(prayerName: String) -> String {
        // Prayer-specific messages for more meaningful feedback
        let prayerSpecificMessages: [String: [String]] = [
            "fajr": [
                "\(prayerName) complete! May your day be blessed",
                "Alhamdulillah! \(prayerName) prayed on time",
                "\(prayerName) done - angels witnessed your prayer"
            ],
            "dhuhr": [
                "\(prayerName) complete! May Allah accept it",
                "Alhamdulillah! \(prayerName) prayed",
                "Masha'Allah! \(prayerName) completed"
            ],
            "asr": [
                "\(prayerName) complete! Blessed afternoon",
                "Alhamdulillah! \(prayerName) prayed",
                "\(prayerName) done - afternoon blessed"
            ],
            "maghrib": [
                "\(prayerName) complete! May it be accepted",
                "Alhamdulillah! \(prayerName) prayed",
                "Masha'Allah! Sunset prayer completed"
            ],
            "isha": [
                "\(prayerName) complete! Rest peacefully",
                "Alhamdulillah! Day's prayers completed",
                "\(prayerName) done - may you have blessed dreams"
            ]
        ]

        // Generic fallback messages
        let genericMessages = [
            "\(prayerName) complete! Alhamdulillah",
            "May Allah accept your \(prayerName)",
            "Masha'Allah! \(prayerName) prayed",
            "Barakallahu feek - \(prayerName) done"
        ]

        // Try to get prayer-specific messages first
        let messages = prayerSpecificMessages[prayerName.lowercased()] ?? genericMessages

        // Use stable selection based on day-of-year (deterministic)
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        // Create deterministic hash from prayer name characters
        let prayerHash = prayerName.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let index = (dayOfYear + prayerHash) % messages.count
        return messages[index]
    }

    /// Get time-specific message (legacy - kept for compatibility)
    static func timeSpecific(prayerName: String) -> String {
        // Now delegates to prayerComplete which handles prayer-specific messages
        return prayerComplete(prayerName: prayerName)
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
