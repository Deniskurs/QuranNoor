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

    // Normalized rotation angles to prevent glitching at 0°/360°
    @State private var normalizedCompassRotation: Double = 0
    @State private var normalizedNeedleRotation: Double = 0

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
                VStack(spacing: Spacing.lg) {
                    if viewModel.isLoading {
                        LoadingView(size: .large, message: "Finding Qibla direction...")
                    } else {
                        Spacer()
                            .frame(height: 20)

                        // Distance Card
                        distanceCard

                        // Compass Section
                        compassSection
                            .frame(height: 280)

                        // Direction Info
                        directionInfoSection

                        // Location Card
                        locationCard

                        Spacer()
                            .frame(height: 20)
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
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
            .onChange(of: viewModel.qiblaDirection) { _, _ in
                updateNeedleRotation()
            }
            .onChange(of: viewModel.isAlignedWithQibla) { _, newValue in
                handleAlignmentChange(newValue)
            }
    }

    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text("🧭")
                        .font(.title3)
                    ThemedText("Qibla Direction", style: .heading)
                        .foregroundColor(AppColors.primary.green)
                }

                HStack(spacing: 4) {
                    Text("📍")
                        .font(.caption)
                    Text(viewModel.userLocation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                HapticManager.shared.trigger(.light)
                showLocationModal = true
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary.teal)
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

    /// Updates the needle rotation to point at Qibla, using normalized angles to prevent 360° wrap glitch
    private func updateNeedleRotation() {
        let targetAngle = viewModel.qiblaDirection - viewModel.deviceHeading
        let diff = normalizeAngleDifference(current: normalizedNeedleRotation, target: targetAngle)
        normalizedNeedleRotation += diff
    }

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
        updateNeedleRotation()
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
        VStack(spacing: Spacing.md) {
            // Main Compass
            ZStack {
                // Compass ring rotates so N points to actual north
                compassRing
                    .rotationEffect(.degrees(normalizedCompassRotation))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: normalizedCompassRotation)

                // Qibla needle rotates to point at Qibla direction (from north)
                qiblaNeedle
                    .rotationEffect(.degrees(normalizedNeedleRotation))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: normalizedNeedleRotation)

                // Center ornament
                centerOrnament
            }
            .frame(width: compassSize, height: compassSize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Qibla compass")
            .accessibilityValue(getAccessibilityDescription())
            .accessibilityHint("Rotate your device to align the needle with Qibla direction")
            .accessibilityFocused($isCompassFocused)

            // Alignment indicator
            alignmentIndicator
        }
    }

    // MARK: - Compass Components

    /// Fixed compass ring with cardinal directions and degree markers
    private var compassRing: some View {
        ZStack {
            // Background with radial gradient (matches onboarding demo)
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
                .shadow(color: AppColors.primary.green.opacity(0.3), radius: 20)

            // Outer ring
            Circle()
                .stroke(AppColors.primary.green.opacity(0.3), lineWidth: 3)

            // Cardinal directions (N, E, S, W)
            ForEach([("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)], id: \.0) { direction in
                Text(direction.0)
                    .font(.caption.weight(.bold))
                    .foregroundColor(direction.0 == "N" ? AppColors.primary.teal : .secondary)
                    .offset(y: -100)
                    .rotationEffect(.degrees(-normalizedCompassRotation))
                    .rotationEffect(.degrees(direction.1))
            }

            // Degree markers (every 10 degrees)
            ForEach(0..<36) { index in
                Rectangle()
                    .fill(index % 3 == 0 ? Color.secondary : Color.secondary.opacity(0.3))
                    .frame(width: 1, height: index % 3 == 0 ? 12 : 6)
                    .offset(y: -105)
                    .rotationEffect(.degrees(Double(index) * 10))
            }
        }
    }

    /// Rotating needle that points to Qibla
    private var qiblaNeedle: some View {
        // Kaaba emoji pointing to Qibla
        VStack(spacing: 4) {
            Text("🕋")
                .font(.system(size: 32))
                .shadow(color: AppColors.primary.gold.opacity(0.5), radius: 8)
                .scaleEffect(viewModel.isAlignedWithQibla ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isAlignedWithQibla)

            Text("QIBLA")
                .font(.caption2.weight(.bold))
                .foregroundColor(AppColors.primary.gold)
        }
        .offset(y: -70)
        .rotationEffect(.degrees(-normalizedNeedleRotation))
    }

    /// Center ornament
    private var centerOrnament: some View {
        ZStack {
            // Center dot
            Circle()
                .fill(AppColors.primary.green)
                .frame(width: 12, height: 12)
                .shadow(color: AppColors.primary.green.opacity(0.5), radius: 4)

            // North indicator (device heading)
            Text("⬆️")
                .font(.system(size: 40))
                .offset(y: 60)
                .rotationEffect(.degrees(-normalizedCompassRotation))
        }
    }

    /// Alignment indicator showing when device points toward Qibla
    private var alignmentIndicator: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isAlignedWithQibla ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(viewModel.isAlignedWithQibla ? AppColors.primary.green : AppColors.primary.teal)
                    .symbolEffect(.bounce, value: viewModel.isAlignedWithQibla)

                Text(viewModel.isAlignedWithQibla ? "Aligned with Qibla!" : "\(Int(viewModel.qiblaDirection))° \(viewModel.getDirectionText().split(separator: " ").last ?? "")")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(themeManager.currentTheme.textColor)
            }

            if !viewModel.isAlignedWithQibla {
                Text("Turn your device to align with Qibla")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alignment status")
        .accessibilityValue(viewModel.isAlignedWithQibla ? "Aligned with Qibla" : "Not aligned")
    }

    private func getAccessibilityDescription() -> String {
        if viewModel.isAlignedWithQibla {
            return "Aligned with Qibla. You are facing the direction of the Kaaba."
        } else {
            let instruction = viewModel.getAlignmentInstruction()
            return "Qibla is at \(viewModel.getDirectionText()). \(instruction) to align."
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
        HStack(spacing: Spacing.md) {
            // Qibla bearing section
            VStack(spacing: 8) {
                Text("🧭")
                    .font(.title3)

                VStack(spacing: 2) {
                    Text("\(Int(viewModel.qiblaDirection))°")
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.qiblaDirection)

                    Text(cardinalDirection)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Qibla direction")
            .accessibilityValue("\(Int(viewModel.qiblaDirection)) degrees \(cardinalDirection)")

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1, height: 60)

            // Current heading section
            VStack(spacing: 8) {
                Text("⬆️")
                    .font(.title3)

                VStack(spacing: 2) {
                    Text("\(Int(viewModel.deviceHeading))°")
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.deviceHeading)

                    Text("Your Heading")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your heading")
            .accessibilityValue("\(Int(viewModel.deviceHeading)) degrees")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
    }

    private var cardinalDirection: String {
        let direction = viewModel.getDirectionText()
        // Extract just the cardinal direction (e.g., "45° NE" -> "NE")
        return direction.split(separator: " ").last.map(String.init) ?? ""
    }

    private var distanceCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("🕋")
                    .font(.title3)

                Text("Holy Kaaba, Makkah")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }

            HStack(spacing: 4) {
                Text(String(format: "%.0f", viewModel.distanceToKaaba))
                    .font(.title.weight(.bold).monospacedDigit())
                    .foregroundColor(AppColors.primary.green)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.distanceToKaaba)

                Text("km away")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Distance to Kaaba")
        .accessibilityValue("\(Int(viewModel.distanceToKaaba)) kilometers from your location")
    }

    private var locationCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.isUsingManualLocation ? "📍" : "🕋")
                    .font(.title3)

                Text(viewModel.isUsingManualLocation ? "Manual Location" : "Current Location")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)

                Spacer()
            }

            Text(viewModel.userLocation)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isUsingManualLocation {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)

                    Text("Tap menu to change location")
                        .font(.caption)
                        .foregroundStyle(.blue)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
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

// MARK: - Preview
#Preview {
    QiblaCompassView()
        .environmentObject(ThemeManager())
}
