//
//  ToastView.swift
//  QuranNoor
//
//  Toast notification component with undo support
//

import SwiftUI

// MARK: - Toast Configuration
struct ToastConfig {
    let message: String
    let icon: String
    let color: Color
    let duration: TimeInterval
    let showUndo: Bool
    let onUndo: (() -> Void)?

    init(
        message: String,
        icon: String = "checkmark.circle.fill",
        color: Color = AppColors.primary.green,
        duration: TimeInterval = 3.0,
        showUndo: Bool = false,
        onUndo: (() -> Void)? = nil
    ) {
        self.message = message
        self.icon = icon
        self.color = color
        self.duration = duration
        self.showUndo = showUndo
        self.onUndo = onUndo
    }
}

// MARK: - Toast View
struct ToastView: View {
    let config: ToastConfig
    let onDismiss: () -> Void

    @State private var progress: Double = 1.0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: config.icon)
                .font(.system(size: 20))
                .foregroundColor(config.color)

            // Message
            Text(config.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // Undo button
            if config.showUndo, let onUndo = config.onUndo {
                Button {
                    onUndo()
                    onDismiss()
                } label: {
                    Text("Undo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(config.color)
                }
            }

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)

                // Progress bar at bottom
                VStack {
                    Spacer()
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(config.color.opacity(0.3))
                            .frame(width: geometry.size.width * progress, height: 3)
                    }
                    .frame(height: 3)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        let interval = 0.05
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.linear(duration: interval)) {
                progress -= interval / config.duration

                if progress <= 0 {
                    timer?.invalidate()
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let config: ToastConfig

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    ToastView(config: config) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)

                    Spacer()
                }
                .zIndex(999)
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func toast(isPresented: Binding<Bool>, config: ToastConfig) -> some View {
        modifier(ToastModifier(isPresented: isPresented, config: config))
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
    .toast(
        isPresented: .constant(true),
        config: ToastConfig(
            message: "Progress reset for Al-Fatihah",
            icon: "arrow.counterclockwise.circle.fill",
            color: AppColors.primary.teal,
            showUndo: true,
            onUndo: {
                print("Undo tapped")
            }
        )
    )
}
