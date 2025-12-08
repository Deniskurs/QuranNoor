//
//  QiblaCompassDemo.swift
//  QuranNoor
//
//  Interactive Qibla compass demo for onboarding
//  Shows animated compass with distance to Makkah
//

import SwiftUI
import Combine

struct QiblaCompassDemo: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var compassRotation: Double = 0
    @State private var isCalibrating = false
    @State private var showAccuracyRing = true
    @State private var isViewVisible = false

    // Sample data
    private let qiblaDirection: Double = 45 // degrees from North
    private let distanceToMakkah = "7,234" // km
    private let locationName = "San Francisco, CA"

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "location.north.circle.fill")
                        .foregroundColor(themeManager.currentTheme.featureAccent)
                    ThemedText("Qibla Direction", style: .heading)
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle")
                        .font(.caption)
                    Text(locationName)
                        .font(.caption)
                }
                .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                themeManager.currentTheme.cardColor
                    .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.05), radius: 2, y: 2)
            )

            Divider()

            // Main compass area
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)

                    // Distance card
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme.accentSecondary)

                            Text("Holy Kaaba, Makkah")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }

                        HStack(spacing: 4) {
                            Text(distanceToMakkah)
                                .font(.title.weight(.bold).monospacedDigit())
                                .foregroundColor(themeManager.currentTheme.accentPrimary)

                            Text("km away")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.cardColor)
                    )
                    .padding(.horizontal, 24)

                    // Compass
                    ZStack {
                        // Outer accuracy ring
                        if showAccuracyRing {
                            Circle()
                                .stroke(
                                    themeManager.currentTheme.featureAccent.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                                )
                                .frame(width: 260, height: 260)
                                .scaleEffect(isCalibrating ? 1.1 : 1.0)
                                .opacity(isCalibrating ? 0.5 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCalibrating)
                        }

                        // Main compass circle
                        ZStack {
                            // Background
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            themeManager.currentTheme.cardColor,
                                            themeManager.currentTheme.backgroundColor
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 120
                                    )
                                )
                                .shadow(color: themeManager.currentTheme.featureAccent.opacity(0.3), radius: 20)

                            // Outer ring
                            Circle()
                                .stroke(themeManager.currentTheme.featureAccent.opacity(0.3), lineWidth: 3)

                            // Cardinal directions
                            ForEach([("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)], id: \.0) { direction in
                                Text(direction.0)
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(direction.0 == "N" ? themeManager.currentTheme.featureAccent : .secondary)
                                    .offset(y: -100)
                                    .rotationEffect(.degrees(-compassRotation))
                                    .rotationEffect(.degrees(direction.1))
                            }

                            // Degree markers
                            ForEach(0..<36) { index in
                                Rectangle()
                                    .fill(index % 3 == 0 ? Color.secondary : Color.secondary.opacity(0.3))
                                    .frame(width: 1, height: index % 3 == 0 ? 12 : 6)
                                    .offset(y: -105)
                                    .rotationEffect(.degrees(Double(index) * 10))
                            }

                            // Kaaba icon (pointing to Qibla)
                            VStack(spacing: 4) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(themeManager.currentTheme.accentSecondary)
                                    .shadow(color: themeManager.currentTheme.accentSecondary.opacity(0.5), radius: 8)

                                Text("QIBLA")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(themeManager.currentTheme.accentSecondary)
                            }
                            .offset(y: -70)
                            .rotationEffect(.degrees(-compassRotation))

                            // Center dot
                            Circle()
                                .fill(themeManager.currentTheme.featureAccent)
                                .frame(width: 12, height: 12)
                                .shadow(color: themeManager.currentTheme.featureAccent.opacity(0.5), radius: 4)

                            // Direction arrow (device heading)
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 40))
                                .foregroundColor(themeManager.currentTheme.featureAccent)
                                .offset(y: 60)
                                .rotationEffect(.degrees(-compassRotation))
                        }
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(compassRotation))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: compassRotation)
                    }
                    .frame(height: 280)

                    // Degree indicator
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(themeManager.currentTheme.featureAccent)

                            Text("\(Int(qiblaDirection))° North-East")
                                .font(.headline.monospacedDigit())
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }

                        Text("Turn your device to align the arrow with Qibla")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            calibrateCompass()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(isCalibrating ? "Calibrating..." : "Calibrate Compass")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(themeManager.currentTheme.featureAccent)
                        .disabled(isCalibrating)

                        // Demo hint
                        HStack(spacing: 6) {
                            Image(systemName: "hand.point.up.left.fill")
                                .font(.caption2)
                            Text("Live compass uses device sensors in real app")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 20)
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.1), radius: 8, y: 4)
        .onAppear {
            isViewVisible = true
        }
        .onDisappear {
            isViewVisible = false
            isCalibrating = false
        }
        .task {
            // Modern async timer - automatically cancels when view disappears
            while !Task.isCancelled && isViewVisible {
                try? await Task.sleep(for: .seconds(2))
                // Simulate compass rotation for demo
                if !isCalibrating && isViewVisible {
                    withAnimation(.spring(response: 0.6)) {
                        compassRotation = Double.random(in: -15...15)
                    }
                }
            }
        }
    }

    // MARK: - Methods
    private func calibrateCompass() {
        withAnimation {
            isCalibrating = true
            showAccuracyRing = true
        }

        HapticManager.shared.trigger(.selection)

        // Simulate calibration process (2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.5)) {
                isCalibrating = false
                compassRotation = qiblaDirection
                AudioHapticCoordinator.shared.playSuccess()
            }

            // Hide accuracy ring after calibration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showAccuracyRing = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    QiblaCompassDemo()
        .environment(ThemeManager())
        .frame(height: 700)
}
