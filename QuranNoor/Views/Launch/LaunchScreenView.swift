//
//  LaunchScreenView.swift
//  QuranNoor
//
//  Launch screen displayed when app first opens
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color(hex: "#0D7377"),  // Emerald
                    Color(hex: "#14FFEC")   // Bright teal
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App Icon/Logo
                Image(systemName: "sparkles")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)

                // App Name - Arabic
                Text("نُورُ ٱلْقُرْآن")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)

                // App Name - English
                Text("Qur'an Noor")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(isAnimating ? 1.0 : 0.0)

                // Tagline
                Text("Light of the Qur'an")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(isAnimating ? 1.0 : 0.0)

                Spacer()

                // Loading Indicator (optional)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.2)
                    .opacity(isAnimating ? 0.7 : 0.0)

                Spacer()
                    .frame(height: 80)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
