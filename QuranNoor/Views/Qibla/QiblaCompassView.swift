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
    @AccessibilityFocusState private var isCompassFocused: Bool

    // Normalized rotation angles to prevent glitching at 0°/360°
    @State private var normalizedCompassRotation: Double = 0
    @State private var normalizedNeedleRotation: Double = 0

    // Simple state tracking
    @State private var hasAlignedBefore = false
    @State private var showLocationModal = false
    @State private var showTutorial = false

    // MARK: - Scaled Metrics for Dynamic Type
    @ScaledMetric private var compassSize: CGFloat = 280
    @ScaledMetric private var iconSize: CGFloat = 32

    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            // Base theme background
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            // Simple gradient overlay
            GradientBackground(style: .serenity, opacity: 0.3)

            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    if viewModel.isLoading {
                        LoadingView(size: .large, message: "Finding Qibla direction...")
                    } else {
                        // Distance Card
                        distanceCard

                        // Compass Section
                        compassSection

                        // Direction Info
                        directionInfoSection

                        // Location Card
                        locationCard
                    }
                }
                .padding(Spacing.screenPadding)
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
            .onAppear { setupViewOnAppear() }
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
                Text("🧭")
                    .font(.title3)

                Text("Qibla Direction")
                    .font(.headline.weight(.semibold))
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
            // Simple alignment glow when aligned
            if viewModel.isAlignedWithQibla {
                Circle()
                    .stroke(AppColors.primary.gold.opacity(0.4), lineWidth: 4)
                    .frame(width: 290, height: 290)
                    .blur(radius: 8)
            }

            // Simple background circle
            Circle()
                .fill(themeManager.currentTheme.cardColor)
                .frame(width: 280, height: 280)
                .shadow(color: AppColors.primary.green.opacity(0.2), radius: 12, x: 0, y: 4)

            // Outer ring
            Circle()
                .stroke(AppColors.primary.green.opacity(0.3), lineWidth: 3)
                .frame(width: 280, height: 280)

            // Cardinal directions (N, E, S, W)
            ForEach([("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)], id: \.0) { direction in
                Text(direction.0)
                    .font(.caption.weight(.bold))
                    .foregroundColor(direction.0 == "N" ? AppColors.primary.teal : themeManager.currentTheme.textSecondary)
                    .offset(y: -120)
                    .rotationEffect(.degrees(-normalizedCompassRotation))
                    .rotationEffect(.degrees(direction.1))
            }

            // Degree markers (every 10 degrees)
            ForEach(0..<36) { index in
                let angle = Double(index) * 10
                let isMainDegree = index % 3 == 0

                Rectangle()
                    .fill(themeManager.currentTheme.textSecondary.opacity(isMainDegree ? 0.5 : 0.3))
                    .frame(width: 2, height: isMainDegree ? 12 : 8)
                    .offset(y: -130)
                    .rotationEffect(.degrees(angle))
            }
        }
    }

    /// Rotating needle that points to Qibla
    private var qiblaNeedle: some View {
        ZStack {
            // Main needle pointing to Qibla
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

            // Kaaba emoji pointing to Qibla
            VStack(spacing: 4) {
                Text("🕋")
                    .font(.system(size: 32))
                    .scaleEffect(viewModel.isAlignedWithQibla ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isAlignedWithQibla)

                Text("QIBLA")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AppColors.primary.gold)
                    .tracking(1)
            }
            .rotationEffect(.degrees(-normalizedNeedleRotation))
            .offset(y: -80)
        }
    }

    /// Center ornament
    private var centerOrnament: some View {
        ZStack {
            // North indicator at bottom
            Text("⬆️")
                .font(.title3)
                .rotationEffect(.degrees(-normalizedCompassRotation))
                .offset(y: 90)

            // Center dot
            Circle()
                .fill(AppColors.primary.green)
                .frame(width: 12, height: 12)
                .shadow(color: AppColors.primary.green.opacity(0.5), radius: 4)
        }
    }

    /// Alignment indicator showing when device points toward Qibla
    private var alignmentIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.isAlignedWithQibla ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(viewModel.isAlignedWithQibla ? AppColors.primary.green : AppColors.primary.teal)
                .symbolEffect(.bounce, value: viewModel.isAlignedWithQibla)

            VStack(alignment: .leading, spacing: 2) {
                ThemedText(viewModel.isAlignedWithQibla ? "Aligned with Qibla!" : "Rotate to align", style: .body)
                    .foregroundColor(viewModel.isAlignedWithQibla ? AppColors.primary.green : themeManager.currentTheme.textColor)
                    .fontWeight(viewModel.isAlignedWithQibla ? .bold : .regular)

                if !viewModel.isAlignedWithQibla {
                    ThemedText.caption(viewModel.getAlignmentInstruction())
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .fill(viewModel.isAlignedWithQibla ?
                      AppColors.primary.green.opacity(0.15) :
                      themeManager.currentTheme.cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(
                    viewModel.isAlignedWithQibla ? AppColors.primary.green : AppColors.primary.teal.opacity(0.3),
                    lineWidth: differentiateWithoutColor ? 3 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
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
            VStack(spacing: Spacing.xs) {
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
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Qibla direction")
            .accessibilityValue("\(Int(viewModel.qiblaDirection)) degrees \(cardinalDirection)")

            // Divider
            Rectangle()
                .fill(themeManager.currentTheme.textSecondary.opacity(0.2))
                .frame(width: 1, height: 60)

            // Current heading section
            VStack(spacing: Spacing.xs) {
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
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your heading")
            .accessibilityValue("\(Int(viewModel.deviceHeading)) degrees")
        }
        .padding(Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: BorderRadius.xl)
                .fill(themeManager.currentTheme.cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.xl)
                .stroke(AppColors.primary.teal.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var cardinalDirection: String {
        viewModel.getDirectionText()
    }

    private var distanceCard: some View {
        Button {
            // Future: show detailed distance info
        } label: {
            VStack(spacing: Spacing.sm) {
                // Icon + Title row
                HStack(spacing: Spacing.xs) {
                    Text("🕋")
                        .font(.title2)

                    Text("Holy Kaaba, Makkah")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                }

                // Distance row
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", viewModel.distanceToKaaba))
                        .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(AppColors.primary.green)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.distanceToKaaba)

                    Text("km away")
                        .font(.callout)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }
            .padding(Spacing.cardPadding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(themeManager.currentTheme.cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(AppColors.primary.gold.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Distance to Kaaba")
        .accessibilityValue("\(Int(viewModel.distanceToKaaba)) kilometers from your location")
        .accessibilityAddTraits(.isStaticText)
        .accessibilityRemoveTraits(.isButton)
    }

    private var locationCard: some View {
        Button {
            // Future: show location details
        } label: {
            VStack(spacing: Spacing.md) {
                // Header with icon
                HStack {
                    Text(viewModel.isUsingManualLocation ? "📍" : "🕋")
                        .font(.title3)

                    Text(viewModel.isUsingManualLocation ? "Manual Location" : "Current Location")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    Spacer()
                }

                // Location name
                Text(viewModel.userLocation)
                    .font(.body)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Manual location hint
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
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(themeManager.currentTheme.cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(AppColors.primary.teal.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isUsingManualLocation ? "Manual location" : "Current location")
        .accessibilityValue(viewModel.userLocation)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityRemoveTraits(.isButton)
    }

    // MARK: - Helper Properties

    /// Check if current theme is dark
    private var isDark: Bool {
        themeManager.currentTheme == .dark || themeManager.currentTheme == .night
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

        // Top pointer (Qibla direction)
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

        // Bottom counterweight
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

// MARK: - Card Press Style
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
