//
//  QiblaCompassView.swift
//  QuranNoor
//
//  Qibla compass showing direction to Kaaba with real-time updates
//

import SwiftUI

struct QiblaCompassView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = QiblaViewModel()
    @State private var showSaveLocationAlert = false
    @State private var locationName = ""

    // Normalized rotation angles to prevent glitching at 0°/360°
    @State private var normalizedCompassRotation: Double = 0
    @State private var normalizedNeedleRotation: Double = 0

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                GradientBackground(style: .serenity, opacity: 0.3)

                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            LoadingView(size: .large, message: "Finding Qibla direction...")
                        } else {
                            // Compass
                            compassSection

                            // Direction Info
                            directionInfoSection

                            // Distance Card
                            distanceCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Qibla")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Refresh GPS location
                        Button {
                            Task {
                                await viewModel.refresh()
                            }
                        } label: {
                            Label("Refresh GPS Location", systemImage: "location.fill")
                        }

                        Divider()

                        // Manual location
                        Button {
                            viewModel.showLocationPicker = true
                        } label: {
                            Label("Set Manual Location", systemImage: "location.circle")
                        }

                        // Saved locations submenu
                        if !viewModel.savedLocations.isEmpty {
                            Menu {
                                ForEach(viewModel.savedLocations) { location in
                                    Button {
                                        Task {
                                            await viewModel.useSavedLocation(location)
                                        }
                                    } label: {
                                        Label(location.name, systemImage: "mappin.circle.fill")
                                    }
                                }
                            } label: {
                                Label("Saved Locations (\(viewModel.savedLocations.count))", systemImage: "star.fill")
                            }
                        }

                        Divider()

                        // Save current location
                        Button {
                            showSaveLocationAlert = true
                        } label: {
                            Label("Save Current Location", systemImage: "bookmark.fill")
                        }
                        .disabled(viewModel.currentCoordinates == nil)

                        // GPS indicator
                        if viewModel.isUsingManualLocation {
                            Button {
                                Task {
                                    await viewModel.useGPSLocation()
                                }
                            } label: {
                                Label("Switch to GPS", systemImage: "location.circle.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await viewModel.initialize()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Save Location", isPresented: $showSaveLocationAlert) {
                TextField("Location Name", text: $locationName)
                Button("Save") {
                    if !locationName.isEmpty {
                        viewModel.saveCurrentLocation(withName: locationName)
                        locationName = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    locationName = ""
                }
            } message: {
                Text("Enter a name for this location")
            }
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(viewModel: viewModel)
            }
            .onChange(of: viewModel.deviceHeading) { oldValue, newValue in
                // Update compass ring rotation (normalize to prevent glitch at 0°/360°)
                let diff = normalizeAngleDifference(current: normalizedCompassRotation, target: -newValue)
                normalizedCompassRotation += diff

                // Also update needle rotation since it depends on device heading
                updateNeedleRotation()
            }
            .onChange(of: viewModel.qiblaDirection) { oldValue, newValue in
                // Update needle rotation when Qibla direction changes
                updateNeedleRotation()
            }
        }
    }

    // MARK: - Helper Methods

    /// Update the needle rotation to point at Qibla, using normalized angles
    private func updateNeedleRotation() {
        let targetAngle = viewModel.qiblaDirection - viewModel.deviceHeading
        let diff = normalizeAngleDifference(current: normalizedNeedleRotation, target: targetAngle)
        normalizedNeedleRotation += diff
    }

    // MARK: - Components

    private var compassSection: some View {
        VStack(spacing: 16) {
            // Main Compass
            ZStack {
                // Compass ring rotates so N points to actual north
                compassRing
                    .rotationEffect(.degrees(normalizedCompassRotation))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: normalizedCompassRotation)

                // Qibla needle rotates to point at Qibla direction (from north)
                qiblaNeedle
                    .rotationEffect(.degrees(normalizedNeedleRotation))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: normalizedNeedleRotation)

                // Center ornament
                centerOrnament
            }
            .frame(width: 280, height: 280)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Qibla Compass")
            .accessibilityValue(getAccessibilityDescription())
            .accessibilityHint("Rotate your device to align the needle with Qibla direction")

            // Alignment indicator
            alignmentIndicator
        }
    }

    // MARK: - Compass Components

    /// Fixed compass ring with cardinal directions and degree markers
    private var compassRing: some View {
        ZStack {
            // Background fill - clean and simple
            Circle()
                .fill(themeManager.currentTheme.cardColor.opacity(0.7))
                .frame(width: 260, height: 260)

            // Single outer ring - emerald green
            Circle()
                .stroke(AppColors.primary.green.opacity(0.5), lineWidth: 3)
                .frame(width: 260, height: 260)

            // Inner subtle ring
            Circle()
                .stroke(AppColors.primary.green.opacity(0.2), lineWidth: 1)
                .frame(width: 200, height: 200)

            // Cardinal directions (N, E, S, W) - Clean and minimal
            ForEach(["N", "E", "S", "W"], id: \.self) { direction in
                VStack(spacing: 2) {
                    ThemedText(direction, style: .heading)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(direction == "N" ? AppColors.primary.gold : themeManager.currentTheme.textColor.opacity(0.6))

                    if direction == "N" {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.primary.gold)
                    }
                }
                .offset(y: direction == "N" || direction == "S" ? (direction == "N" ? -115 : 115) : 0)
                .offset(x: direction == "E" || direction == "W" ? (direction == "E" ? 115 : -115) : 0)
            }

            // Degree markers (every 30 degrees) - subtle
            ForEach(0..<12) { index in
                let angle = Double(index) * 30
                let isCardinal = index % 3 == 0

                Rectangle()
                    .fill(AppColors.primary.green.opacity(isCardinal ? 0.5 : 0.2))
                    .frame(width: isCardinal ? 2 : 1, height: isCardinal ? 16 : 10)
                    .offset(y: -130)
                    .rotationEffect(.degrees(angle))
            }
        }
    }

    /// Rotating needle that points to Qibla
    private var qiblaNeedle: some View {
        ZStack {
            // Main needle pointing to Qibla - clean gradient
            QiblaNeedleShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.primary.gold,
                            AppColors.primary.gold.opacity(0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 170)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)

            // Kaaba icon at the tip - minimal
            ZStack {
                Circle()
                    .fill(AppColors.primary.green)
                    .frame(width: 32, height: 32)

                Image(systemName: "house.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .shadow(color: AppColors.primary.green.opacity(0.3), radius: 4, x: 0, y: 2)
            .offset(y: -85)
        }
    }

    /// Center ornament
    private var centerOrnament: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.gold)
                .frame(width: 24, height: 24)

            Circle()
                .stroke(themeManager.currentTheme.cardColor, lineWidth: 2)
                .frame(width: 24, height: 24)
        }
        .shadow(color: AppColors.primary.gold.opacity(0.3), radius: 4, x: 0, y: 0)
    }

    /// Alignment indicator showing when device points toward Qibla
    private var alignmentIndicator: some View {
        let relativeAngle = (viewModel.qiblaDirection - viewModel.deviceHeading).truncatingRemainder(dividingBy: 360)
        let normalizedAngle = relativeAngle < 0 ? relativeAngle + 360 : relativeAngle
        let isAligned = abs(normalizedAngle) < 5 || abs(normalizedAngle - 360) < 5

        return HStack(spacing: 12) {
            Image(systemName: isAligned ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isAligned ? AppColors.primary.green : AppColors.primary.teal)
                .symbolEffect(.bounce, value: isAligned)

            VStack(alignment: .leading, spacing: 2) {
                ThemedText(isAligned ? "Aligned with Qibla!" : "Rotate to align", style: .body)
                    .foregroundColor(isAligned ? AppColors.primary.green : themeManager.currentTheme.textColor)
                    .fontWeight(isAligned ? .bold : .regular)

                if !isAligned {
                    ThemedText.caption(getAlignmentInstruction(normalizedAngle))
                        .opacity(0.7)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAligned ? AppColors.primary.green.opacity(0.1) : themeManager.currentTheme.cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAligned ? AppColors.primary.green : AppColors.primary.teal.opacity(0.3), lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isAligned)
    }

    private func getAlignmentInstruction(_ angle: Double) -> String {
        if angle < 180 {
            return "Turn right \(Int(angle))°"
        } else {
            return "Turn left \(Int(360 - angle))°"
        }
    }

    private func getAccessibilityDescription() -> String {
        let relativeAngle = (viewModel.qiblaDirection - viewModel.deviceHeading).truncatingRemainder(dividingBy: 360)
        let normalizedAngle = relativeAngle < 0 ? relativeAngle + 360 : relativeAngle
        let isAligned = abs(normalizedAngle) < 5 || abs(normalizedAngle - 360) < 5

        if isAligned {
            return "Aligned with Qibla. You are facing the direction of the Kaaba."
        } else {
            let instruction = getAlignmentInstruction(normalizedAngle)
            return "Qibla is at \(viewModel.getDirectionText()). \(instruction) to align."
        }
    }

    /// Normalize angle difference to take shortest path (prevent 360° wrap glitch)
    /// Ensures rotation is always within ±180° for smooth animation across 0°/360° boundary
    private func normalizeAngleDifference(current: Double, target: Double) -> Double {
        let diff = target - current
        let normalized = diff.truncatingRemainder(dividingBy: 360)

        // Ensure shortest path: if difference > 180°, go the other way
        if normalized > 180 {
            return normalized - 360
        } else if normalized < -180 {
            return normalized + 360
        }
        return normalized
    }

    private var directionInfoSection: some View {
        CardView(showPattern: true) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("QIBLA DIRECTION")
                        ThemedText(viewModel.getDirectionText(), style: .heading)
                            .foregroundColor(AppColors.primary.green)
                    }

                    Spacer()

                    Image(systemName: "safari")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primary.green.opacity(0.6))
                }

                IslamicDivider(style: .simple)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("YOUR LOCATION")
                        ThemedText.body(viewModel.userLocation)
                            .foregroundColor(AppColors.primary.teal)
                    }

                    Spacer()

                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary.teal)
                }
            }
        }
    }

    private var distanceCard: some View {
        CardView {
            HStack(spacing: 16) {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.primary.gold)

                VStack(alignment: .leading, spacing: 4) {
                    ThemedText.caption("DISTANCE TO MAKKAH")
                    ThemedText(viewModel.getDistanceText(), style: .heading)
                        .foregroundColor(AppColors.primary.gold)
                    ThemedText.caption("From your location")
                        .opacity(0.6)
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Distance to Makkah")
        .accessibilityValue("\(viewModel.getDistanceText()) from your location")
    }
}

// MARK: - Qibla Needle Shape
struct QiblaNeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midX = rect.midX
        let midY = rect.midY

        // Top pointer (Qibla direction) - pointed arrow shape
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: midX - width * 0.35, y: rect.minY + height * 0.15))
        path.addLine(to: CGPoint(x: midX - width * 0.2, y: rect.minY + height * 0.15))
        path.addLine(to: CGPoint(x: midX - width * 0.2, y: midY - height * 0.05))

        // Curve to center
        path.addQuadCurve(
            to: CGPoint(x: midX, y: midY),
            control: CGPoint(x: midX - width * 0.15, y: midY - height * 0.025)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX + width * 0.2, y: midY - height * 0.05),
            control: CGPoint(x: midX + width * 0.15, y: midY - height * 0.025)
        )

        path.addLine(to: CGPoint(x: midX + width * 0.2, y: rect.minY + height * 0.15))
        path.addLine(to: CGPoint(x: midX + width * 0.35, y: rect.minY + height * 0.15))
        path.closeSubpath()

        // Bottom counterweight (smaller, opposite direction)
        path.move(to: CGPoint(x: midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: midX - width * 0.15, y: midY + height * 0.05))
        path.addQuadCurve(
            to: CGPoint(x: midX, y: midY),
            control: CGPoint(x: midX - width * 0.1, y: midY + height * 0.025)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX + width * 0.15, y: midY + height * 0.05),
            control: CGPoint(x: midX + width * 0.1, y: midY + height * 0.025)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview
#Preview {
    QiblaCompassView()
        .environmentObject(ThemeManager())
}
