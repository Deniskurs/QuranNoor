//
//  NotificationPrimingView.swift
//  QuranNoor
//
//  Contextual priming screen shown BEFORE iOS notification permission prompt
//  Educates users on notification benefits, increasing grant rate by 30-50%
//

import SwiftUI

struct NotificationPrimingView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let onRequestPermission: () -> Void
    let onSkip: () -> Void

    @State private var animateIcon = false
    @State private var showMockNotification = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // MARK: - Icon with animation
            ZStack {
                // Pulsing rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(AppColors.primary.gold.opacity(0.3), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                        .scaleEffect(animateIcon ? 1.2 : 0.8)
                        .opacity(animateIcon ? 0 : 0.6)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: animateIcon
                        )
                }

                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.primary.gold.opacity(0.3),
                                    AppColors.primary.gold.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary.gold)
                        .symbolEffect(.bounce, value: animateIcon)
                }
            }
            .onAppear {
                animateIcon = true
                // Show mock notification after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.5)) {
                        showMockNotification = true
                    }
                }
            }

            Spacer()
                .frame(height: 40)

            // MARK: - Title
            VStack(spacing: 12) {
                ThemedText("Never Miss a Prayer", style: .title)
                    .foregroundColor(AppColors.primary.green)
                    .multilineTextAlignment(.center)

                ThemedText.body("Get gentle reminders before each prayer time so you can pray on time, every time")
                    .multilineTextAlignment(.center)
                    .opacity(0.9)
                    .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 32)

            // MARK: - Mock Notification Preview
            if showMockNotification {
                mockNotificationCard
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }

            // MARK: - Benefits
            VStack(spacing: 20) {
                benefitRow(
                    icon: "clock.badge.checkmark",
                    text: "Timely reminders for all 5 daily prayers",
                    color: AppColors.primary.gold
                )

                benefitRow(
                    icon: "speaker.wave.3.fill",
                    text: "Beautiful Adhan call to prayer (optional)",
                    color: AppColors.primary.gold
                )

                benefitRow(
                    icon: "slider.horizontal.3",
                    text: "Fully customizable notification settings",
                    color: AppColors.primary.gold
                )

                benefitRow(
                    icon: "moon.stars.fill",
                    text: "Special reminders for Tahajjud and Witr",
                    color: AppColors.primary.gold
                )
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 32)

            // MARK: - Privacy Assurance
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("You're Always in Control")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)

                    Text("Customize which prayers to be notified about, or turn them off anytime in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primary.teal.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.primary.teal.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)

            Spacer()

            // MARK: - Actions
            VStack(spacing: 12) {
                Button {
                    onRequestPermission()
                } label: {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Enable Notifications")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppColors.primary.gold)

                Button {
                    onSkip()
                } label: {
                    Text("I'll Set Up Later")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(themeManager.currentTheme.backgroundColor)
    }

    // MARK: - Mock Notification Card
    private var mockNotificationCard: some View {
        HStack(spacing: 12) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.green, AppColors.primary.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }

            // Notification content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Qur'an Noor")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(themeManager.currentTheme.textColor)

                    Text("now")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text("Maghrib prayer in 15 minutes")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textColor)

                Text("Prayer time at 6:22 PM • San Francisco")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
    }

    // MARK: - Benefit Row
    @ViewBuilder
    private func benefitRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)

            ThemedText.body(text)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationPrimingView(
        onRequestPermission: { print("Request permission") },
        onSkip: { print("Skip") }
    )
    .environmentObject(ThemeManager())
}
