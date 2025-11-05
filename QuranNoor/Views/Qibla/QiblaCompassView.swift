//
//  QiblaCompassView.swift
//  QuranNoor
//
//  Qibla compass showing direction to Kaaba with real-time updates
//  Optimized for performance and battery life
//

import SwiftUI

struct QiblaCompassView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = QiblaViewModel()
    @State private var showSaveLocationAlert = false
    @State private var locationName = ""

    // MARK: - Accessibility Environment
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.scenePhase) var scenePhase
    @AccessibilityFocusState private var isCompassFocused: Bool

    // Normalized rotation angle to prevent glitching at 0°/360°
    @State private var normalizedCompassRotation: Double = 0

    // Simple state tracking
    @State private var hasAlignedBefore = false
    @State private var showLocationModal = false
    @State private var showTutorial = false
    @State private var isViewVisible = false

    // MARK: - Scaled Metrics for Dynamic Type
    @ScaledMetric private var compassSize: CGFloat = 240

    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            // Base theme background
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            // Simple gradient overlay
            GradientBackground(style: .serenity, opacity: 0.3)

            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        LoadingView(size: .large, message: "Finding Qibla direction...")
                    } else {
                        Spacer()
                            .frame(height: 16)

                        // Distance Card
                        distanceCard
                            .padding(.horizontal, Spacing.screenPadding)

                        // Compass Section - let it size naturally
                        compassSection
                            .padding(.horizontal, Spacing.screenPadding)
                            .padding(.top, 20)
                            .padding(.bottom, 8)

                        // Direction Info
                        directionInfoSection
                            .padding(.horizontal, Spacing.screenPadding)

                        // Location Card
                        locationCard
                            .padding(.horizontal, Spacing.screenPadding)

                        Spacer()
                            .frame(height: 24)
                    }
                }
            }

            // Tutorial overlay
            if showTutorial {
                QiblaTutorialOverlay(isPresented: $showTutorial)
                    .environmentObject(themeManager)
            }
        }
    }

    // MARK: - Configured Content with Lifecycle
    private var contentWithLifecycle: some View {
        mainContent
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .task {
                await viewModel.initialize()
                // Auto-refresh location
                await viewModel.refresh()
            }
            .onAppear {
                isViewVisible = true
                viewModel.resume()
                setupViewOnAppear()
            }
            .onDisappear {
                isViewVisible = false
                viewModel.pause()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    if isViewVisible {
                        viewModel.resume()
                    }
                case .inactive, .background:
                    viewModel.pause()
                @unknown default:
                    break
                }
            }
    }

    // MARK: - Content with Alerts
    private var contentWithAlerts: some View {
        contentWithLifecycle
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
                Button("Cancel", role: .cancel) { locationName = "" }
            } message: {
                Text("Enter a name for this location")
            }
    }

    // MARK: - Content with Sheets
    private var contentWithSheets: some View {
        contentWithAlerts
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLocationModal) {
                LocationManagementModal(viewModel: viewModel) {
                    showSaveLocationAlert = true
                }
                .environmentObject(themeManager)
            }
    }

    // MARK: - Configured Content
    private var configuredContent: some View {
        contentWithSheets
            .onChange(of: viewModel.deviceHeading) { _, newValue in
                handleDeviceHeadingChange(newValue)
            }
            .onChange(of: viewModel.isAlignedWithQibla) { _, newValue in
                handleAlignmentChange(newValue)
            }
    }

    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary.teal)
                Text("Qibla Direction")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                HapticManager.shared.trigger(.light)
                showLocationModal = true
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primary.teal)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Location settings")
            .accessibilityHint("Manage saved locations and GPS settings")
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            configuredContent
        }
    }

    // MARK: - Helper Methods

    /// Setup animations and state when view appears
    private func setupViewOnAppear() {
        // Check if tutorial should be shown
        if !UserDefaults.standard.bool(forKey: "hasSeenQiblaTutorial") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showTutorial = true
                }
            }
        }
    }

    /// Handle device heading changes
    private func handleDeviceHeadingChange(_ newValue: Double) {
        let diff = normalizeAngleDifference(current: normalizedCompassRotation, target: -newValue)
        normalizedCompassRotation += diff
    }

    /// Handle Qibla alignment changes
    private func handleAlignmentChange(_ newValue: Bool) {
        if newValue && !hasAlignedBefore {
            hasAlignedBefore = true
            HapticManager.shared.triggerPattern(.qiblaAligned)
            UIAccessibility.post(notification: .announcement, argument: "Aligned with Qibla")
        }
    }

    // MARK: - Components

    private var compassSection: some View {
        VStack(spacing: 20) {
            // Main Compass - fixed container size to accommodate all elements
            ZStack {
                // Compass ring rotates so N points to actual north
                // Qibla marker is part of the ring and rotates with it
                compassRingWithQiblaMarker
                    .rotationEffect(.degrees(normalizedCompassRotation))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: normalizedCompassRotation)

                // Fixed center needle (always points up - represents device direction)
                fixedCenterNeedle
            }
            .frame(width: 320, height: 320) // Fixed size to contain 240px compass + markers + glow
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Qibla compass")
            .accessibilityValue(getAccessibilityDescription())
            .accessibilityHint("Rotate your device to align the needle with Qibla marker")
            .accessibilityFocused($isCompassFocused)

            // Alignment indicator
            alignmentIndicator
        }
    }

    // MARK: - Compass Components

    /// Compass ring with cardinal directions, degree markers, and Qibla marker on the edge
    private var compassRingWithQiblaMarker: some View {
        ZStack {
            // Multi-layer glow effect - more prominent when aligned
            Circle()
                .stroke(AppColors.primary.teal, lineWidth: 5)
                .frame(width: 250, height: 250)
                .blur(radius: 24)
                .opacity(viewModel.isAlignedWithQibla ? 0.6 : 0.2)
                .animation(.easeInOut(duration: 0.4), value: viewModel.isAlignedWithQibla)

            Circle()
                .stroke(AppColors.primary.teal, lineWidth: 5)
                .frame(width: 250, height: 250)
                .blur(radius: 16)
                .opacity(viewModel.isAlignedWithQibla ? 0.7 : 0.25)
                .animation(.easeInOut(duration: 0.4), value: viewModel.isAlignedWithQibla)

            Circle()
                .stroke(AppColors.primary.gold, lineWidth: 5)
                .frame(width: 250, height: 250)
                .blur(radius: 8)
                .opacity(viewModel.isAlignedWithQibla ? 0.8 : 0.15)
                .animation(.easeInOut(duration: 0.4), value: viewModel.isAlignedWithQibla)

            // Background with radial gradient - FIXED SIZE
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.currentTheme.cardColor.opacity(0.8),
                            themeManager.currentTheme.backgroundColor
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .shadow(color: AppColors.primary.green.opacity(0.3), radius: 20)

            // Outer ring - thicker and more visible - FIXED SIZE
            Circle()
                .stroke(
                    viewModel.isAlignedWithQibla ?
                        AppColors.primary.gold.opacity(0.8) :
                        AppColors.primary.teal.opacity(0.6),
                    lineWidth: 5
                )
                .frame(width: 240, height: 240)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isAlignedWithQibla)

            // Cardinal directions (N, E, S, W) - bolder and larger
            ForEach([("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)], id: \.0) { direction in
                Text(direction.0)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(direction.0 == "N" ? AppColors.primary.teal : .secondary)
                    .offset(y: -105)
                    .rotationEffect(.degrees(-normalizedCompassRotation))
                    .rotationEffect(.degrees(direction.1))
            }

            // Degree markers (every 10 degrees) - more visible
            ForEach(0..<36) { index in
                let isMajor = index % 3 == 0
                Rectangle()
                    .fill(isMajor ? Color.secondary.opacity(0.8) : Color.secondary.opacity(0.4))
                    .frame(width: isMajor ? 2 : 1, height: isMajor ? 14 : 8)
                    .offset(y: -108)
                    .rotationEffect(.degrees(Double(index) * 10))
            }

            // Qibla marker positioned on ring edge at the calculated bearing
            qiblaMarker
                .rotationEffect(.degrees(viewModel.qiblaDirection))
        }
    }

    /// Qibla marker on ring edge - shows direction to Kaaba
    private var qiblaMarker: some View {
        VStack(spacing: 2) {
            Text("🕋")
                .font(.system(size: 20))
                .shadow(color: AppColors.primary.gold.opacity(0.6), radius: 8)
                .shadow(color: AppColors.primary.gold.opacity(0.8), radius: 16)

            Text("QIBLA")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(AppColors.primary.gold)
                .rotationEffect(.degrees(-viewModel.qiblaDirection - normalizedCompassRotation))
        }
        .offset(y: -135) // Position just outside the ring edge (120px radius + ~15px margin)
        // Pulsing glow animation
        .opacity(viewModel.isAlignedWithQibla ? 1.0 : 0.85)
        .scaleEffect(viewModel.isAlignedWithQibla ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isAlignedWithQibla)
    }

    /// Fixed center needle - always points up (represents device forward direction)
    private var fixedCenterNeedle: some View {
        ZStack {
            // Elegant compass needle pointing up
            VStack(spacing: 0) {
                // Needle triangle (pointing up)
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.teal, AppColors.primary.teal.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 12, height: 80)
                    .shadow(color: AppColors.primary.teal.opacity(0.4), radius: 4)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .offset(y: -30)

            // Center dot
            Circle()
                .fill(AppColors.primary.green)
                .frame(width: 12, height: 12)
                .shadow(color: AppColors.primary.green.opacity(0.5), radius: 4)
        }
    }

    /// Alignment indicator showing when device points toward Qibla
    private var alignmentIndicator: some View {
        VStack(spacing: 12) {
            // Main status indicator with liquid glass effect
            HStack(spacing: 12) {
                Image(systemName: viewModel.isAlignedWithQibla ? "checkmark.circle.fill" : "arrow.clockwise")
                    .font(.system(size: 26))
                    .foregroundColor(viewModel.isAlignedWithQibla ? AppColors.primary.green : AppColors.primary.teal)
                    .symbolEffect(.bounce, value: viewModel.isAlignedWithQibla)

                if viewModel.isAlignedWithQibla {
                    Text("Aligned with Qibla!")
                        .font(.headline.monospacedDigit())
                        .foregroundColor(AppColors.primary.green)
                        .fontWeight(.bold)
                } else {
                    HStack(spacing: 6) {
                        Text("\(abs(degreeOffset))°")
                            .font(.title3.monospacedDigit().weight(.bold))
                            .foregroundColor(AppColors.primary.teal)

                        Text("off")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Liquid glass blur effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            viewModel.isAlignedWithQibla ?
                                AppColors.primary.green.opacity(0.15) :
                                AppColors.primary.teal.opacity(0.08)
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        viewModel.isAlignedWithQibla ?
                            AppColors.primary.gold.opacity(0.8) :
                            AppColors.primary.teal.opacity(0.4),
                        lineWidth: viewModel.isAlignedWithQibla ? 2 : 1
                    )
            )
            .shadow(
                color: viewModel.isAlignedWithQibla ?
                    AppColors.primary.gold.opacity(0.4) :
                    AppColors.primary.teal.opacity(0.2),
                radius: 12,
                x: 0,
                y: 4
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isAlignedWithQibla)

            // Helper text with fixed frame to prevent layout shift
            Text(viewModel.isAlignedWithQibla ? "✓ You are facing the Kaaba" : "Turn your device to align with Qibla")
                .font(.subheadline.weight(.medium))
                .foregroundColor(viewModel.isAlignedWithQibla ? AppColors.primary.green : .secondary)
                .multilineTextAlignment(.center)
                .frame(height: 20) // Fixed height prevents jumping
                .animation(.easeInOut(duration: 0.3), value: viewModel.isAlignedWithQibla)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alignment status")
        .accessibilityValue(viewModel.isAlignedWithQibla ? "Aligned with Qibla" : "Not aligned")
    }

    private func getAccessibilityDescription() -> String {
        if viewModel.isAlignedWithQibla {
            return "Aligned with Qibla. The fixed needle is pointing at the Qibla marker. You are facing the direction of the Kaaba."
        } else {
            let offset = abs(degreeOffset)
            return "Qibla marker is at \(Int(viewModel.qiblaDirection)) degrees. You are \(offset) degrees off. Rotate your device to align the fixed needle with the Qibla marker on the ring."
        }
    }

    /// Normalizes angle difference to take shortest path (prevents 360° wrap glitch)
    private func normalizeAngleDifference(current: Double, target: Double) -> Double {
        let diff = target - current
        let normalized = diff.truncatingRemainder(dividingBy: 360)

        if normalized > 180 {
            return normalized - 360
        } else if normalized < -180 {
            return normalized + 360
        }
        return normalized
    }

    private var directionInfoSection: some View {
        CardView {
            HStack(spacing: 0) {
                // Qibla bearing section
                VStack(spacing: 10) {
                    Image(systemName: "safari")
                        .font(.system(size: 26))
                        .foregroundColor(AppColors.primary.green)

                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.qiblaDirection))°")
                            .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundStyle(themeManager.currentTheme.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.qiblaDirection)

                        Text(cardinalDirection)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(themeManager.currentTheme.textSecondary)

                        Text("To Qibla")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColors.primary.teal)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Qibla direction")
                .accessibilityValue("\(Int(viewModel.qiblaDirection)) degrees \(cardinalDirection)")

                // Vertical divider with gradient
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.textSecondary.opacity(0.1),
                                    themeManager.currentTheme.textSecondary.opacity(0.3),
                                    themeManager.currentTheme.textSecondary.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                }
                .frame(height: 80)
                .padding(.horizontal, 24)

                // Current heading section
                VStack(spacing: 10) {
                    Image(systemName: "location.north.line.fill")
                        .font(.system(size: 26))
                        .foregroundColor(AppColors.primary.teal)

                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.deviceHeading))°")
                            .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundStyle(themeManager.currentTheme.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.deviceHeading)

                        Text("Your Heading")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Your heading")
                .accessibilityValue("\(Int(viewModel.deviceHeading)) degrees")
            }
        }
        .environmentObject(themeManager)
    }

    private var cardinalDirection: String {
        let direction = viewModel.getDirectionText()
        // Extract just the cardinal direction (e.g., "45° NE" -> "NE")
        return direction.split(separator: " ").last.map(String.init) ?? ""
    }

    /// Calculate the degree difference between current heading and Qibla direction
    private var degreeOffset: Int {
        let diff = viewModel.qiblaDirection - viewModel.deviceHeading
        let normalized = diff.truncatingRemainder(dividingBy: 360)

        if normalized > 180 {
            return Int(normalized - 360)
        } else if normalized < -180 {
            return Int(normalized + 360)
        }
        return Int(normalized)
    }

    private var distanceCard: some View {
        CardView {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("🕋")
                        .font(.system(size: 24))

                    Text("Holy Kaaba, Makkah")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }

                HStack(spacing: 4) {
                    Text(String(format: "%.0f", viewModel.distanceToKaaba))
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundColor(AppColors.primary.green)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.distanceToKaaba)

                    Text("km away")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
        }
        .environmentObject(themeManager)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Distance to Kaaba")
        .accessibilityValue("\(Int(viewModel.distanceToKaaba)) kilometers from your location")
    }

    private var locationCard: some View {
        CardView {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: viewModel.isUsingManualLocation ? "mappin.circle.fill" : "location.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary.teal)

                    Text(viewModel.isUsingManualLocation ? "Manual Location" : "Current Location")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    Spacer()
                }

                Text(viewModel.userLocation)
                    .font(.body)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isUsingManualLocation {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppColors.primary.teal)

                        Text("Tap menu to change location")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.textTertiary)

                        Spacer()
                    }
                }
            }
        }
        .environmentObject(themeManager)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isUsingManualLocation ? "Manual location" : "Current location")
        .accessibilityValue(viewModel.userLocation)
    }

    // MARK: - Helper Properties

    /// Check if current theme is dark
    private var isDark: Bool {
        themeManager.currentTheme == .dark || themeManager.currentTheme == .night
    }
}

// MARK: - Card Press Style
/// Reusable button style for card press effects with subtle scale
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Triangle Shape
/// Custom triangle shape for compass needle
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
#Preview {
    QiblaCompassView()
        .environmentObject(ThemeManager())
}
