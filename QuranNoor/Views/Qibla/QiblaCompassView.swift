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

    // MARK: - Accessibility Environment
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @AccessibilityFocusState private var isCompassFocused: Bool

    // Normalized rotation angles to prevent glitching at 0°/360°
    @State private var normalizedCompassRotation: Double = 0
    @State private var normalizedNeedleRotation: Double = 0

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Base theme background (ensures pure black in night mode for OLED)
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            LoadingView(size: .large, message: "Finding Qibla direction...")
                        } else {
                            // Compass
    // Haptic feedback state for alignment
    @State private var wasAligned: Bool = false
    @State private var hasTriggeredAlignmentHaptic: Bool = false

    // Glass morphism glow effect state
    @State private var isGlowing = false

    // Particle effects state
    @State private var hasAlignedBefore = false
    @State private var showConfetti = false

    // Micro-interaction states
    @State private var cardinalOpacity: Double = 0
    @State private var cardinalScale: CGFloat = 0.8
    @State private var isPulsing = false
    @State private var menuTrigger = 0
    @State private var displayDistance: Double = 0
    @State private var distanceIconScale: CGFloat = 0.5
    @State private var locationIconScale: CGFloat = 0.5
    @State private var directionIconScale: CGFloat = 0.5

    // Dynamic gradient animation states (Phase 3.3)
    @State private var gradientRotation: Double = 0
    @State private var timeBasedGradient: [Color] = []
    @State private var searchPulse: Double = 1.0
    @State private var cardGradientOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.4
    @State private var shadowDepth: CGFloat = 20
    @State private var shimmerOffset: CGFloat = -1.0

    // Calibration UI states (Phase 4.1)
    @State private var isCalibrating = false
    @State private var accuracyRingScale: CGFloat = 1.0
    @State private var accuracyRingOpacity: Double = 1.0
    @State private var showCalibrationSuccess = false

    // Location modal state (Phase 4.2)
    @State private var showLocationModal = false

    // Tutorial overlay state (Phase 4.3)
    @State private var showTutorial = false

    // MARK: - Scaled Metrics for Dynamic Type
    @ScaledMetric private var compassSize: CGFloat = 280
    @ScaledMetric private var iconSize: CGFloat = 32

    // MARK: - Performance Optimizations
    // - Canvas-based particle rendering (GPU accelerated)
    // - Gradient animations use normalized angles to prevent glitches at 0°/360° boundary
    // - Lazy loading of saved locations in modal
    // - Timer cleanup handled by SwiftUI lifecycle
    // - Animations respect reduce motion accessibility preference
    // - DrawingGroup applied to complex compass layers for compositing

    // MARK: - Helper Functions

    /// Calculates the time-based gradient colors based on Islamic prayer times
    /// - Returns: Array of colors representing the current time period (dawn, morning, afternoon, etc.)
    /// - Note: This gradient is informational (shows time of day) and is always displayed regardless of reduce motion setting
    private func calculateTimeBasedGradient() -> [Color] {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5...7:  // Dawn (Fajr)
            return [
                AppColors.primary.teal.opacity(0.15),
                AppColors.primary.gold.opacity(0.1),
                themeManager.currentTheme.backgroundColor
            ]
        case 8...11:  // Morning
            return [
                AppColors.primary.gold.opacity(0.12),
                AppColors.primary.teal.opacity(0.08),
                themeManager.currentTheme.backgroundColor
            ]
        case 12...16:  // Afternoon (Dhuhr/Asr)
            return [
                AppColors.primary.green.opacity(0.1),
                themeManager.currentTheme.backgroundColor
            ]
        case 17...18:  // Evening (Maghrib)
            return [
                AppColors.primary.gold.opacity(0.15),
                Color.orange.opacity(0.08),
                themeManager.currentTheme.backgroundColor
            ]
        case 19...21:  // Night (Isha)
            return [
                AppColors.primary.teal.opacity(0.12),
                AppColors.primary.green.opacity(0.08),
                themeManager.currentTheme.backgroundColor
            ]
        default:  // Late night
            return [
                AppColors.primary.green.opacity(0.08),
                themeManager.currentTheme.backgroundColor
            ]
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            // Base theme background (ensures pure black in night mode for OLED)
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            // Time-based dynamic gradient background
            LinearGradient(
                colors: timeBasedGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.linear(duration: 2.0), value: timeBasedGradient)

            // Gradient overlay (automatically suppressed in night mode)
            GradientBackground(style: .serenity, opacity: 0.3)

            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    if viewModel.isLoading {
                        LoadingView(size: .large, message: "Finding Qibla direction...")
                    } else {
                        // Distance Card (moved to top for prominence)
                        distanceCard

                        // Compass with particle effects
                        ZStack {
                            compassSection

                            // Star particles (respect reduce motion preference)
                            if !reduceMotion {
                                ParticleEmitterView(
                                    isEmitting: viewModel.isAlignedWithQibla,
                                    center: CGPoint(x: 140, y: 140)
                                )
                                .frame(width: compassSize, height: compassSize)
                                .allowsHitTesting(false)
                            }

                            // Calibration accuracy ring
                            if isCalibrating {
                                Circle()
                                    .stroke(
                                        AppColors.primary.teal.opacity(0.4),
                                        style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                                    )
                                    .frame(width: 300, height: 300)
                                    .scaleEffect(accuracyRingScale)
                                    .opacity(accuracyRingOpacity)
                            }

                            // Loading overlay during calibration
                            if isCalibrating {
                                Circle()
                                    .fill(themeManager.currentTheme.backgroundColor.opacity(0.3))
                                    .frame(width: 280, height: 280)
                                    .overlay(
                                        ProgressView()
                                            .tint(AppColors.primary.teal)
                                            .scaleEffect(1.5)
                                    )
                            }
                        }

                        // Calibration button
                        calibrationButton
                            .padding(.horizontal, Spacing.screenPadding)

                        // Calibration success message
                        if showCalibrationSuccess {
                            calibrationSuccessView
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        }

                        // Direction Info
                        directionInfoSection

                        // Location Card
                        locationCard
                    }
                }
                .padding(Spacing.screenPadding)
            }

            // Confetti overlay (full screen, respect reduce motion)
            if showConfetti && !reduceMotion {
                ConfettiView(show: showConfetti)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Tutorial overlay (Phase 4.3)
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
            .task { await viewModel.initialize() }
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
            .onChange(of: viewModel.distanceToKaaba) { _, newValue in
                animateDistanceChange(to: newValue)
            }
            .onChange(of: viewModel.isLoading) { _, newValue in
                handleLoadingChange(newValue)
            }
            .onChange(of: isCalibrating) { _, newValue in
                handleCalibrationChange(newValue)
            }
    }

    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 4) {
                Image(systemName: "safari")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary.teal)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: AppColors.primary.teal.opacity(0.3), radius: 8, x: 0, y: 2)
                    .opacity(viewModel.isLoading ? searchPulse : 1.0)
                    .scaleEffect(viewModel.isLoading ? searchPulse : 1.0)

                Text("Qibla Direction")
                    .font(.headline.weight(.semibold))
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                HapticManager.shared.trigger(.light)
                showLocationModal = true
                menuTrigger += 1
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary.teal)
                    .symbolEffect(.bounce, value: menuTrigger)
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
    /// - Note: Uses incremental angle differences to ensure smooth rotation across 0°/360° boundary
    private func updateNeedleRotation() {
        let targetAngle = viewModel.qiblaDirection - viewModel.deviceHeading
        let diff = normalizeAngleDifference(current: normalizedNeedleRotation, target: targetAngle)
        normalizedNeedleRotation += diff
    }

    /// Animates distance change with smooth count-up effect
    /// - Parameter newValue: Target distance value in kilometers
    /// - Note: Uses 20 steps with 50ms intervals for smooth visual feedback
    private func animateDistanceChange(to newValue: Double) {
        let steps = 20
        let increment = (newValue - displayDistance) / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                displayDistance += increment
            }
        }
    }

    /// Setup animations and state when view appears
    private func setupViewOnAppear() {
        isGlowing = true
        displayDistance = viewModel.distanceToKaaba

        // Staggered icon bounce-in animations (respect reduce motion)
        if !reduceMotion {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                distanceIconScale = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) {
                locationIconScale = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                directionIconScale = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                cardinalOpacity = 1.0
                cardinalScale = 1.0
            }
        } else {
            distanceIconScale = 1.0
            locationIconScale = 1.0
            directionIconScale = 1.0
            cardinalOpacity = 1.0
            cardinalScale = 1.0
        }

        // Initialize time-based background gradient
        timeBasedGradient = calculateTimeBasedGradient()
        Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
            timeBasedGradient = calculateTimeBasedGradient()
        }

        // Decorative animations (only if reduce motion is off)
        if !reduceMotion {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                cardGradientOffset = 50
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                shadowDepth = 30
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 2.0
            }
        }

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
            if !reduceMotion {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    showConfetti = false
                }
            }
        }

        if !reduceMotion {
            if newValue {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.8
                }
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    glowIntensity = 0.4
                }
            }
        }

        if newValue {
            UIAccessibility.post(notification: .announcement, argument: "Aligned with Qibla")
        }
    }

    /// Handle loading state changes
    private func handleLoadingChange(_ newValue: Bool) {
        isPulsing = newValue

        if !reduceMotion {
            if newValue {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    searchPulse = 0.6
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    searchPulse = 1.0
                }
            }
        } else {
            searchPulse = 1.0
        }
    }

    /// Handle calibration state changes
    private func handleCalibrationChange(_ newValue: Bool) {
        if newValue {
            UIAccessibility.post(notification: .announcement, argument: "Updating location")
        } else {
            UIAccessibility.post(notification: .announcement, argument: "Location updated")
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
            // Alignment glow effect (appears when aligned) - with dynamic intensity
            if viewModel.isAlignedWithQibla {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.primary.gold.opacity(0.6),
                                AppColors.primary.gold.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 290, height: 290)
                    .blur(radius: 8)
                    .scaleEffect(isGlowing ? 1.05 : 1.0)
                    .opacity(isGlowing ? glowIntensity : 0.4)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
            }

            // Background with rotating angular gradient + radial gradient overlay
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: themeManager.currentTheme.cardColor, location: 0.0),
                            .init(color: themeManager.currentTheme.cardColor.opacity(0.95), location: 0.3),
                            .init(color: themeManager.currentTheme.backgroundColor.opacity(0.9), location: 0.7),
                            .init(color: themeManager.currentTheme.backgroundColor, location: 1.0)
                        ]),
                        center: .center,
                        angle: .degrees(gradientRotation)
                    )
                )
                .overlay(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: themeManager.currentTheme.cardColor.opacity(0.8), location: 0.0),
                            .init(color: Color.clear, location: 0.6)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                // Multi-layer shadows with animated depth
                .shadow(color: AppColors.primary.green.opacity(0.3), radius: shadowDepth, x: 0, y: 4)
                .shadow(color: AppColors.primary.green.opacity(0.15), radius: shadowDepth * 2, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.1), radius: shadowDepth * 3, x: 0, y: 20)

            // Outer ring - emerald green with pulse during updates
            Circle()
                .stroke(AppColors.primary.green.opacity(0.3), lineWidth: 3)
                .frame(width: 280, height: 280)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(
                    isPulsing ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                    value: isPulsing
                )
                .drawingGroup()  // Composite for performance

            // Inner glow on compass ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.primary.green.opacity(0.3),
                            AppColors.primary.green.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .blur(radius: 2)
                .frame(width: 258, height: 258)  // Slightly smaller for inner glow

            // Subtle Islamic geometric pattern on compass ring
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            AppColors.primary.green.opacity(0.05),
                            AppColors.primary.green.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 260, height: 260)
                .overlay(
                    // Subtle decorative marks every 45 degrees
                    ForEach(0..<8) { index in
                        let angle = Double(index) * 45
                        Rectangle()
                            .fill(AppColors.primary.green.opacity(0.1))
                            .frame(width: 1, height: 8)
                            .offset(y: -130)
                            .rotationEffect(.degrees(angle))
                    }
                )

            // Cardinal directions (N, E, S, W) - Stay upright during rotation with fade-in
            ForEach([("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)], id: \.0) { direction in
                Text(direction.0)
                    .font(.caption.weight(.bold))
                    .foregroundColor(direction.0 == "N" ? AppColors.primary.teal : themeManager.currentTheme.textSecondary)
                    .offset(y: -120)
                    .rotationEffect(.degrees(-normalizedCompassRotation))  // Counter-rotate to stay upright
                    .rotationEffect(.degrees(direction.1))
                    .opacity(cardinalOpacity)
                    .scaleEffect(cardinalScale)
            }

            // Degree markers (every 10 degrees) - enhanced detail
            ForEach(0..<36) { index in
                let angle = Double(index) * 10
                let isMainDegree = index % 3 == 0  // Every 30 degrees

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
            // Main needle pointing to Qibla - clean gradient
            QiblaNeedleShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.primary.gold,
                            AppColors.primary.gold.opacity(themeManager.currentTheme.secondaryOpacity)
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

                Text("🕋")
                    .font(.system(size: 18))
            // Enlarged Kaaba icon with QIBLA label - stays upright with pulse on alignment
            VStack(spacing: 4) {
                Image(systemName: "house.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.primary.gold)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: AppColors.primary.gold.opacity(0.5), radius: 4, x: 0, y: 2)
                    .shimmer(isActive: viewModel.isAlignedWithQibla)
                    .scaleEffect(viewModel.isAlignedWithQibla ? 1.1 : 1.0)
                    .animation(
                        viewModel.isAlignedWithQibla ?
                            .spring(response: 0.3, dampingFraction: 0.5).repeatCount(3, autoreverses: true) :
                            .spring(response: 0.3, dampingFraction: 0.8),
                        value: viewModel.isAlignedWithQibla
                    )

                Text("QIBLA")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AppColors.primary.gold)
                    .tracking(1)
            }
            .rotationEffect(.degrees(-normalizedNeedleRotation))  // Counter-rotate to stay upright
            .offset(y: -80)
        }
    }

    /// Center ornament
    private var centerOrnament: some View {
        ZStack {
            // Device heading indicator at bottom - stays upright and shows North
            Image(systemName: "location.north.fill")
                .font(.title3)
                .foregroundColor(AppColors.primary.teal)
                .rotationEffect(.degrees(-normalizedCompassRotation))  // Counter-rotate to stay pointing down
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

            VStack(alignment: .leading, spacing: 2) {
                ThemedText(viewModel.isAlignedWithQibla ? "Aligned with Qibla!" : "Rotate to align", style: .body)
                    .foregroundColor(viewModel.isAlignedWithQibla ? AppColors.primary.green : themeManager.currentTheme.textColor)
                    .fontWeight(viewModel.isAlignedWithQibla ? .bold : .regular)

                if !viewModel.isAlignedWithQibla {
                    ThemedText.caption(viewModel.getAlignmentInstruction())
                        // Caption style already uses textTertiary - no additional opacity needed
        let relativeAngle = (viewModel.qiblaDirection - viewModel.deviceHeading).truncatingRemainder(dividingBy: 360)
        let normalizedAngle = relativeAngle < 0 ? relativeAngle + 360 : relativeAngle
        let isAligned = abs(normalizedAngle) < 5 || abs(normalizedAngle - 360) < 5

        // Trigger haptic when alignment changes from false to true
        DispatchQueue.main.async {
            if isAligned && !wasAligned && !hasTriggeredAlignmentHaptic {
                HapticManager.shared.triggerPattern(.qiblaAligned)
                hasTriggeredAlignmentHaptic = true
            } else if !isAligned {
                // Reset haptic flag when not aligned (allow triggering again)
                if hasTriggeredAlignmentHaptic {
                    // Add delay to prevent spam if user is on the boundary
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        hasTriggeredAlignmentHaptic = false
                    }
                }
            }
            wasAligned = isAligned
        }

        return HStack(spacing: Spacing.sm) {
            Image(systemName: isAligned ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isAligned ? AppColors.primary.green : AppColors.primary.teal)
                .symbolEffect(.bounce, value: isAligned)
                .shadow(color: (isAligned ? AppColors.primary.green : AppColors.primary.teal).opacity(0.3), radius: 3, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 2) {
                ThemedText(isAligned ? "Aligned with Qibla!" : "Rotate to align", style: .body)
                    .foregroundColor(isAligned ? AppColors.primary.green : themeManager.currentTheme.textColor)
                    .fontWeight(isAligned ? .bold : .regular)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

                if !isAligned {
                    ThemedText.caption(getAlignmentInstruction(normalizedAngle))
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isAlignedWithQibla ? AppColors.primary.green.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.green) * 2) : themeManager.currentTheme.cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(viewModel.isAlignedWithQibla ? AppColors.primary.green : AppColors.primary.teal.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.teal) * 2), lineWidth: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isAlignedWithQibla)
            ZStack {
                if isAligned {
                    // Glass morphism for aligned state
                    RoundedRectangle(cornerRadius: BorderRadius.lg)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: BorderRadius.lg)
                        .fill(Color.green.opacity(0.15))

                    // Glow border
                    RoundedRectangle(cornerRadius: BorderRadius.lg)
                        .strokeBorder(
                            AppColors.primary.teal,
                            lineWidth: 1
                        )
                        .blur(radius: 2)
                } else {
                    // Regular card background
                    RoundedRectangle(cornerRadius: BorderRadius.lg)
                        .fill(themeManager.currentTheme.cardColor)
                }
            }
            .shadow(color: (isAligned ? AppColors.primary.teal : AppColors.primary.green).opacity(0.3), radius: 12, x: 0, y: 4)
            .shadow(color: (isAligned ? Color.green : Color.black).opacity(0.2), radius: 24, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(
                    isAligned ? AppColors.primary.green : AppColors.primary.teal.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.teal) * 2),
                    lineWidth: differentiateWithoutColor ? 3 : 2
                )
        )
        .scaleEffect(isAligned ? 1.0 : 0.98)
        .offset(y: isAligned ? 0 : 5)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAligned)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alignment status")
        .accessibilityValue(isAligned ? "Aligned with Qibla" : "Not aligned")
    }

    private func getAlignmentInstruction(_ angle: Double) -> String {
        if angle < 180 {
            return "Turn right \(Int(angle))°"
        } else {
            return "Turn left \(Int(360 - angle))°"
        }
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
    /// - Parameters:
    ///   - current: Current angle in degrees
    ///   - target: Target angle in degrees
    /// - Returns: Normalized difference angle (always within ±180°)
    /// - Note: Ensures rotation is always within ±180° for smooth animation across 0°/360° boundary
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
        HStack(spacing: Spacing.md) {
            // Qibla bearing section
            VStack(spacing: Spacing.xs) {
                Image(systemName: "safari.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary.teal)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: AppColors.primary.teal.opacity(0.3), radius: 3, x: 0, y: 1)
                    .scaleEffect(directionIconScale)

                VStack(spacing: 2) {
                    Text("\(Int(viewModel.qiblaDirection))°")
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.qiblaDirection)

                    Text(cardinalDirection)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: cardinalDirection)
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
                Image(systemName: "location.north.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary.teal)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: AppColors.primary.teal.opacity(0.3), radius: 3, x: 0, y: 1)

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
            ZStack {
                // Animated gradient overlay
                LinearGradient(
                    colors: [
                        AppColors.primary.green.opacity(0.05),
                        AppColors.primary.teal.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(x: cardGradientOffset, y: cardGradientOffset)
                .blur(radius: 30)

                // Frosted glass blur
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(.ultraThinMaterial)

                // Semi-transparent color overlay
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(themeManager.currentTheme.cardColor.opacity(0.8))

                // Subtle border stroke
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDark ? 0.1 : 0.3),
                                Color.black.opacity(isDark ? 0.2 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: AppColors.primary.green.opacity(0.1), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
        .noiseTexture(opacity: 0.05)
        .edgeHighlight(cornerRadius: BorderRadius.xl)
    }

    // Helper computed property for cardinal direction
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
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.primary.gold)
                        .symbolRenderingMode(.hierarchical)
                        .shadow(color: AppColors.primary.gold.opacity(0.5), radius: 4, x: 0, y: 2)
                        .scaleEffect(distanceIconScale)

                    Text("Holy Kaaba, Makkah")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                }

                // Distance row with animated count
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", displayDistance))
                        .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(AppColors.primary.green)
                        .contentTransition(.numericText())

                    Text("km away")
                        .font(.callout)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }
            .padding(Spacing.cardPadding)
            .frame(maxWidth: .infinity)
            .meshGradientBackground(cornerRadius: BorderRadius.xl)
            .background(
                ZStack {
                    // Animated gradient overlay
                    LinearGradient(
                        colors: [
                            AppColors.primary.green.opacity(0.05),
                            AppColors.primary.teal.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .offset(x: cardGradientOffset, y: cardGradientOffset)
                    .blur(radius: 30)

                    // Frosted glass blur
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .fill(.ultraThinMaterial)

                    // Semi-transparent color overlay
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .fill(themeManager.currentTheme.cardColor.opacity(0.8))

                    // Subtle border stroke
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? 0.1 : 0.3),
                                    Color.black.opacity(isDark ? 0.2 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: AppColors.primary.green.opacity(0.1), radius: 8, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
            )
            .overlay(
                // Shimmer effect
                LinearGradient(
                    colors: [
                        Color.clear,
                        AppColors.primary.gold.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset * 400)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
            )
            .noiseTexture(opacity: 0.05)
            .edgeHighlight(cornerRadius: BorderRadius.xl)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Distance to Kaaba")
        .accessibilityValue("\(Int(displayDistance)) kilometers from your location")
        .accessibilityAddTraits(.isStaticText)
        .accessibilityRemoveTraits(.isButton)
    }

    private var distanceCard: some View {
        CardView {
            HStack(spacing: 16) {
                Text("🕋")
                    .font(.system(size: 50))
    private var locationCard: some View {
        Button {
            // Future: show location details
        } label: {
            VStack(spacing: Spacing.md) {
                // Header with icon
                HStack {
                    Image(systemName: viewModel.isUsingManualLocation ? "mappin.circle.fill" : "location.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary.teal)
                        .symbolRenderingMode(.hierarchical)
                        .shadow(color: AppColors.primary.teal.opacity(0.3), radius: 3, x: 0, y: 1)
                        .scaleEffect(locationIconScale)
                        .opacity(viewModel.isLoading ? searchPulse : 1.0)
                        .scaleEffect(viewModel.isLoading ? searchPulse : 1.0)

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
                ZStack {
                    // Animated gradient overlay
                    LinearGradient(
                        colors: [
                            AppColors.primary.green.opacity(0.05),
                            AppColors.primary.teal.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .offset(x: cardGradientOffset, y: cardGradientOffset)
                    .blur(radius: 30)

                    // Frosted glass blur
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .fill(.ultraThinMaterial)

                    // Semi-transparent color overlay
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .fill(themeManager.currentTheme.cardColor.opacity(0.8))

                    // Subtle border stroke
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? 0.1 : 0.3),
                                    Color.black.opacity(isDark ? 0.2 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: AppColors.primary.green.opacity(0.1), radius: 8, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
            )
            .noiseTexture(opacity: 0.05)
            .edgeHighlight(cornerRadius: BorderRadius.xl)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isUsingManualLocation ? "Manual location" : "Current location")
        .accessibilityValue(viewModel.userLocation)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityRemoveTraits(.isButton)
    }

    // MARK: - Calibration Components

    /// Calibration button below compass
    private var calibrationButton: some View {
        Button {
            calibrateCompass()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isCalibrating ? "arrow.triangle.2.circlepath" : "location.north.circle.fill")
                    .symbolEffect(.rotate, isActive: isCalibrating)

                Text(isCalibrating ? "Calibrating..." : "Refresh Location")
                    .font(.callout.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.primary.teal)
        .disabled(isCalibrating)
        .opacity(isCalibrating ? 0.6 : 1.0)
        .accessibilityLabel(isCalibrating ? "Calibrating location" : "Refresh location")
        .accessibilityHint("Updates your current position for accurate Qibla direction")
    }

    /// Success indicator after calibration
    private var calibrationSuccessView: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.primary.green)

            Text("Location updated successfully")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BorderRadius.md)
                .fill(AppColors.primary.green.opacity(0.1))
        )
    }

    // MARK: - Calibration Methods

    /// Initiates compass calibration by refreshing location and showing visual feedback
    /// - Note: Disables calibration button during the process and plays success haptic when complete
    private func calibrateCompass() {
        // Start calibration state
        isCalibrating = true
        accuracyRingScale = 1.0
        accuracyRingOpacity = 1.0

        // Animate accuracy ring
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            accuracyRingScale = 1.1
            accuracyRingOpacity = 0.5
        }

        // Trigger location refresh
        Task {
            await viewModel.refresh()

            // Wait 2 seconds for visual feedback
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // Complete calibration
            completeCalibration()
        }
    }

    /// Completes calibration with success feedback (haptics and visual confirmation)
    /// - Note: Shows success message for 2 seconds before auto-dismissing
    private func completeCalibration() {
        // Stop calibration state
        isCalibrating = false
        accuracyRingScale = 1.0
        accuracyRingOpacity = 1.0

        // Play success feedback
        HapticManager.shared.trigger(.success)
        AudioHapticCoordinator.shared.playSuccess()

        // Show success message
        showCalibrationSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showCalibrationSuccess = false
        }
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
