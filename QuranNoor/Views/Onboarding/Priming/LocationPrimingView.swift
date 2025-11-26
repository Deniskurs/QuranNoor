//
//  LocationPrimingView.swift
//  QuranNoor
//
//  Contextual priming screen shown BEFORE iOS location permission prompt
//  Educates users on why location is needed, increasing grant rate by 30-50%
//

import SwiftUI

struct LocationPrimingView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let onRequestPermission: () -> Void
    let onSkip: () -> Void

    @State private var animateIcon = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // MARK: - Icon with animation
            ZStack {
                // Pulsing rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(themeManager.currentTheme.featureAccent.opacity(0.3), lineWidth: 2)
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
                                    themeManager.currentTheme.featureAccent.opacity(0.3),
                                    themeManager.currentTheme.featureAccent.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.featureAccent)
                        .symbolEffect(.pulse, value: animateIcon)
                }
            }
            .onAppear {
                animateIcon = true
            }

            Spacer()
                .frame(height: 40)

            // MARK: - Title
            VStack(spacing: 12) {
                ThemedText("See Your Exact Prayer Times", style: .title)
                    .foregroundColor(themeManager.currentTheme.accentPrimary)
                    .multilineTextAlignment(.center)

                ThemedText.body("We use your location once to calculate accurate prayer times for your area")
                    .multilineTextAlignment(.center)
                    .opacity(0.9)
                    .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 32)

            // MARK: - Benefits
            VStack(spacing: 20) {
                benefitRow(
                    icon: "clock.badge.checkmark.fill",
                    text: "Precise prayer times based on your exact location",
                    color: themeManager.currentTheme.featureAccent
                )

                benefitRow(
                    icon: "location.north.fill",
                    text: "Accurate Qibla direction to Mecca",
                    color: themeManager.currentTheme.featureAccent
                )

                benefitRow(
                    icon: "bell.badge.fill",
                    text: "Location-aware prayer notifications",
                    color: themeManager.currentTheme.featureAccent
                )
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 32)

            // MARK: - Privacy Assurance
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.currentTheme.accentSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Privacy is Protected")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)

                    Text("Your location stays on your device and is never shared or tracked")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.accentSecondary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentTheme.accentSecondary.opacity(0.3), lineWidth: 1)
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
                        Image(systemName: "location.fill")
                        Text("Enable Location")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(themeManager.currentTheme.featureAccent)

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
    LocationPrimingView(
        onRequestPermission: { print("Request permission") },
        onSkip: { print("Skip") }
    )
    .environment(ThemeManager())
}
