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
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var viewModel = QiblaViewModel()
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

    // MARK: - Theme shorthand
    private var theme: ThemeMode { themeManager.currentTheme }

    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            GradientBackground(style: .prayer, opacity: 0.25)

            ScrollView {
                VStack(spacing: Spacing.md) {
                    if viewModel.isLoading {
                        LoadingView(size: .large, message: "Finding Qibla direction...")
                    } else {
                        Spacer()
                            .frame(height: Spacing.xxs)

                        // Distance to Kaaba
                        distanceCard
                            .padding(.horizontal, Spacing.screenHorizontal)

                        // Compass
                        compassSection
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.sm)

                        // Direction info
                        directionInfoSection
                            .padding(.horizontal, Spacing.screenHorizontal)

                        // Location
                        locationCard
                            .padding(.horizontal, Spacing.screenHorizontal)

                        Spacer()
                            .frame(height: Spacing.md)
                    }
                }
            }

            if showTutorial {
                QiblaTutorialOverlay(isPresented: $showTutorial)
                    .environment(themeManager)
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
                .environment(themeManager)
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
                    .foregroundColor(theme.accentMuted)
                Text("Qibla Direction")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                HapticManager.shared.trigger(.light)
                showLocationModal = true
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundColor(theme.accentMuted)
            }
            .frame(minWidth: Spacing.tapTarget, minHeight: Spacing.tapTarget)
            .accessibilityLabel("Location settings")
            .accessibilityHint("Manage saved locations and GPS settings")
        }
    }

    // MARK: - Body
    var body: some View {
        configuredContent
    }

    // MARK: - Helper Methods

    private func setupViewOnAppear() {
        if !UserDefaults.standard.bool(forKey: "hasSeenQiblaTutorial") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(AppAnimation.standard) {
                    showTutorial = true
                }
            }
        }
    }

    private func handleDeviceHeadingChange(_ newValue: Double) {
        let diff = normalizeAngleDifference(current: normalizedCompassRotation, target: -newValue)
        normalizedCompassRotation += diff
    }

    private func handleAlignmentChange(_ newValue: Bool) {
        if newValue && !hasAlignedBefore {
            hasAlignedBefore = true
            HapticManager.shared.triggerPattern(.qiblaAligned)
            UIAccessibility.post(notification: .announcement, argument: "Aligned with Qibla")
        }
    }

    // MARK: - Compass Section

    private var compassSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Ambient glow behind compass — single efficient layer
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (viewModel.isAlignedWithQibla ? theme.accent : theme.accentMuted).opacity(0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 80,
                            endRadius: 180
                        )
                    )
                    .frame(width: 340, height: 340)
                    .animation(AppAnimation.standard, value: viewModel.isAlignedWithQibla)

                // Compass dial (rotates)
                compassDial
                    .rotationEffect(.degrees(normalizedCompassRotation))
                    .animation(AppAnimation.compass, value: normalizedCompassRotation)

                // Fixed center needle (doesn't rotate)
                fixedCenterNeedle
            }
            .frame(width: 320, height: 320)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Qibla compass")
            .accessibilityValue(getAccessibilityDescription())
            .accessibilityHint("Rotate your device to align the needle with Qibla marker")
            .accessibilityFocused($isCompassFocused)

            alignmentIndicator
        }
    }

    // MARK: - Compass Dial (rotates with device)

    private var compassDial: some View {
        ZStack {
            // Outer ring — thick, with material depth
            Circle()
                .fill(theme.cardColor.opacity(0.6))
                .frame(width: 244, height: 244)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            theme.accentMuted.opacity(0.3),
                            theme.accent.opacity(0.6),
                            theme.accentMuted.opacity(0.3),
                            theme.accent.opacity(0.6),
                            theme.accentMuted.opacity(0.3)
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 244, height: 244)

            // Inner ring
            Circle()
                .stroke(theme.borderColor.opacity(0.2), lineWidth: 1)
                .frame(width: 200, height: 200)

            // Degree tick marks (every 10°)
            ForEach(0..<36, id: \.self) { index in
                let isMajor = index % 9 == 0  // N, E, S, W
                let isMinor = index % 3 == 0   // every 30°
                tickMark(isMajor: isMajor, isMinor: isMinor && !isMajor)
                    .rotationEffect(.degrees(Double(index) * 10))
            }

            // Degree numbers (every 30°)
            ForEach(0..<12, id: \.self) { index in
                let degrees = index * 30
                if degrees != 0 && degrees != 90 && degrees != 180 && degrees != 270 {
                    Text("\(degrees)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textTertiary)
                        // Undo both the ring position and parent compass rotation
                        .rotationEffect(.degrees(-Double(degrees) - normalizedCompassRotation))
                        .offset(y: -88)
                        .rotationEffect(.degrees(Double(degrees)))
                }
            }

            // Cardinal directions
            ForEach([
                ("N", 0.0, theme.accent, Font.Weight.black),
                ("E", 90.0, theme.textSecondary, Font.Weight.bold),
                ("S", 180.0, theme.textSecondary, Font.Weight.bold),
                ("W", 270.0, theme.textSecondary, Font.Weight.bold)
            ], id: \.0) { dir in
                Text(dir.0)
                    .font(.system(size: dir.0 == "N" ? 20 : 16, weight: dir.3, design: .rounded))
                    .foregroundColor(dir.2)
                    // Undo both the ring position and parent compass rotation
                    .rotationEffect(.degrees(-dir.1 - normalizedCompassRotation))
                    .offset(y: -88)
                    .rotationEffect(.degrees(dir.1))
            }

            // Qibla marker on ring edge
            qiblaMarker
                .rotationEffect(.degrees(viewModel.qiblaDirection))
        }
    }

    private func tickMark(isMajor: Bool, isMinor: Bool) -> some View {
        Rectangle()
            .fill(isMajor ? theme.accent.opacity(0.8) : (isMinor ? theme.textSecondary.opacity(0.5) : theme.textTertiary.opacity(0.3)))
            .frame(width: isMajor ? 2.5 : (isMinor ? 1.5 : 1), height: isMajor ? 16 : (isMinor ? 10 : 6))
            .offset(y: -114)
    }

    // MARK: - Qibla Marker
    // Lives inside compassDial so it inherits the same spring animation.
    // Counter-rotates text so it stays upright while the dial spins.

    private var qiblaMarker: some View {
        VStack(spacing: 2) {
            // "Qibla" pill label — counter-rotates to stay upright
            Text("Qibla")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
                .tracking(0.5)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(theme.cardColor.opacity(0.9))
                )
                .overlay(
                    Capsule()
                        .stroke(theme.accent.opacity(0.3), lineWidth: 0.5)
                )
                .rotationEffect(.degrees(-viewModel.qiblaDirection - normalizedCompassRotation))

            // Kaaba emoji — counter-rotates to always face user upright
            Text("🕋")
                .font(.system(size: 26))
                .shadow(color: theme.accent.opacity(0.4), radius: 4)
                .rotationEffect(.degrees(-viewModel.qiblaDirection - normalizedCompassRotation))

            // Small pointer connecting marker to the ring
            Triangle()
                .fill(theme.accent.opacity(0.4))
                .frame(width: 6, height: 8)
        }
        .offset(y: -140)
        .scaleEffect(viewModel.isAlignedWithQibla ? 1.1 : 1.0)
        .animation(AppAnimation.standard, value: viewModel.isAlignedWithQibla)
    }

    // MARK: - Center Needle

    private var fixedCenterNeedle: some View {
        ZStack {
            // Needle pointing up
            VStack(spacing: 0) {
                // North half (accent colored)
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.accent.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 70)
                    .shadow(color: theme.accent.opacity(0.3), radius: 6)

                // South half (muted)
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [theme.textTertiary.opacity(0.4), theme.textTertiary.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 70)
                    .rotationEffect(.degrees(180))
            }
            .offset(y: -2)

            // Center pivot circle — layered for depth
            Circle()
                .fill(theme.cardColor)
                .frame(width: 18, height: 18)
                .shadow(color: .black.opacity(0.15), radius: 2)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accent, theme.accent.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 6
                    )
                )
                .frame(width: 12, height: 12)

            Circle()
                .fill(.white.opacity(0.4))
                .frame(width: 4, height: 4)
                .offset(x: -1, y: -1)
        }
    }

    // MARK: - Alignment Indicator

    private var alignmentIndicator: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: viewModel.isAlignedWithQibla ? "checkmark.circle.fill" : "arrow.clockwise")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.isAlignedWithQibla ? theme.accent : theme.accentMuted)
                    .symbolEffect(.bounce, value: viewModel.isAlignedWithQibla)

                if viewModel.isAlignedWithQibla {
                    Text("Aligned with Qibla")
                        .font(.headline)
                        .foregroundColor(theme.accent)
                } else {
                    HStack(spacing: 4) {
                        Text("\(abs(degreeOffset))°")
                            .font(.title3.monospacedDigit().weight(.bold))
                            .foregroundColor(theme.accentMuted)
                        Text("off")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.xl, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl, style: .continuous)
                    .stroke(
                        viewModel.isAlignedWithQibla ?
                            theme.accent.opacity(0.6) :
                            theme.borderColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .animation(AppAnimation.standard, value: viewModel.isAlignedWithQibla)

            Text(viewModel.isAlignedWithQibla ? "You are facing the Kaaba" : "Rotate your device toward Qibla")
                .font(.subheadline.weight(.medium))
                .foregroundColor(viewModel.isAlignedWithQibla ? theme.accent : theme.textTertiary)
                .frame(height: 20)
                .animation(AppAnimation.gentle, value: viewModel.isAlignedWithQibla)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alignment status")
        .accessibilityValue(viewModel.isAlignedWithQibla ? "Aligned with Qibla" : "\(abs(degreeOffset)) degrees off")
    }

    // MARK: - Direction Info

    private var directionInfoSection: some View {
        CardView {
            HStack(spacing: 0) {
                directionColumn(
                    icon: "safari",
                    iconColor: theme.accent,
                    value: "\(Int(viewModel.qiblaDirection))°",
                    label: cardinalDirection,
                    caption: "To Qibla",
                    animationValue: viewModel.qiblaDirection,
                    accessLabel: "Qibla direction",
                    accessValue: "\(Int(viewModel.qiblaDirection)) degrees \(cardinalDirection)"
                )

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.borderColor.opacity(0.05),
                                theme.borderColor.opacity(0.2),
                                theme.borderColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1, height: 80)

                directionColumn(
                    icon: "location.north.line.fill",
                    iconColor: theme.accentMuted,
                    value: "\(Int(viewModel.deviceHeading))°",
                    label: nil,
                    caption: "Your Heading",
                    animationValue: viewModel.deviceHeading,
                    accessLabel: "Your heading",
                    accessValue: "\(Int(viewModel.deviceHeading)) degrees"
                )
            }
        }
        .environment(themeManager)
    }

    private func directionColumn(
        icon: String, iconColor: Color, value: String,
        label: String?, caption: String,
        animationValue: Double,
        accessLabel: String, accessValue: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            VStack(spacing: 3) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(AppAnimation.standard, value: animationValue)

                if let label {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                }

                Text(caption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessLabel)
        .accessibilityValue(accessValue)
    }

    // MARK: - Distance Card

    private var distanceCard: some View {
        CardView {
            VStack(spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xxs) {
                    Text("🕋")
                        .font(.system(size: 24))

                    Text("Holy Kaaba, Makkah")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                }

                HStack(spacing: 4) {
                    Text(String(format: "%.0f", viewModel.distanceToKaaba))
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundColor(theme.accent)
                        .contentTransition(.numericText())
                        .animation(AppAnimation.standard, value: viewModel.distanceToKaaba)

                    Text("km away")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .environment(themeManager)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Distance to Kaaba")
        .accessibilityValue("\(Int(viewModel.distanceToKaaba)) kilometers from your location")
    }

    // MARK: - Location Card

    private var locationCard: some View {
        CardView {
            VStack(spacing: Spacing.xxs) {
                HStack {
                    Image(systemName: viewModel.isUsingManualLocation ? "mappin.circle.fill" : "location.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(theme.accentMuted)

                    Text(viewModel.isUsingManualLocation ? "Manual Location" : "Current Location")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    Spacer()
                }

                Text(viewModel.userLocation)
                    .font(.body)
                    .foregroundStyle(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isUsingManualLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(theme.accentMuted)
                        Text("Tap menu to change location")
                            .font(.caption)
                            .foregroundStyle(theme.textTertiary)
                        Spacer()
                    }
                }
            }
        }
        .environment(themeManager)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isUsingManualLocation ? "Manual location" : "Current location")
        .accessibilityValue(viewModel.userLocation)
    }

    // MARK: - Computed Properties

    private var cardinalDirection: String {
        let direction = viewModel.getDirectionText()
        return direction.split(separator: " ").last.map(String.init) ?? ""
    }

    private var degreeOffset: Int {
        let diff = viewModel.qiblaDirection - viewModel.deviceHeading
        let normalized = diff.truncatingRemainder(dividingBy: 360)
        if normalized > 180 { return Int(normalized - 360) }
        else if normalized < -180 { return Int(normalized + 360) }
        return Int(normalized)
    }

    private func getAccessibilityDescription() -> String {
        if viewModel.isAlignedWithQibla {
            return "Aligned with Qibla. You are facing the direction of the Kaaba."
        } else {
            return "Qibla is at \(Int(viewModel.qiblaDirection)) degrees. You are \(abs(degreeOffset)) degrees off."
        }
    }

    private func normalizeAngleDifference(current: Double, target: Double) -> Double {
        let diff = target - current
        let normalized = diff.truncatingRemainder(dividingBy: 360)
        if normalized > 180 { return normalized - 360 }
        else if normalized < -180 { return normalized + 360 }
        return normalized
    }

    private var isDark: Bool {
        theme == .dark || theme == .night
    }
}

// MARK: - Card Press Style
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppAnimation.bouncy, value: configuration.isPressed)
    }
}

// MARK: - Triangle Shape
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
        .environment(ThemeManager())
}
