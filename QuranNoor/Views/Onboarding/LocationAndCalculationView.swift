//
//  LocationAndCalculationView.swift
//  QuranNoor
//
//  Combined location permission and calculation method selection
//  Reduces friction by handling both in one intelligent flow
//

import SwiftUI
import CoreLocation
import MapKit

struct LocationAndCalculationView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var locationService = LocationService.shared

    let coordinator: OnboardingCoordinator
    var permissionManager: PermissionManager

    @State private var hasRequestedPermission = false
    @State private var isRequesting = false
    @State private var showSettingsAlert = false
    @State private var showMethodSelection = false
    @State private var showManualEntry = false
    @State private var showPrimingView = true  // Show priming view first
    @State private var detectedCountry: String?
    @State private var manualCity: String = ""
    @State private var hasAutoAdvanced = false  // Prevent double-advance

    // Calculation methods with detailed info and human-readable explanations
    private let methods: [(id: String, name: String, description: String, explanation: String, regions: String)] = [
        ("ISNA", "ISNA", "Islamic Society of North America",
         "Fajr at 15\u{00B0} / Isha at 15\u{00B0}. Standard in North America. Moderate timing \u{2014} good balance between early Fajr and late Isha.",
         "North America"),
        ("MWL", "Muslim World League", "Global standard calculation",
         "Fajr at 18\u{00B0} / Isha at 17\u{00B0}. Used across Europe and Asia. Earlier Fajr, slightly later Isha than ISNA.",
         "Europe, Far East, Parts of US"),
        ("Egypt", "Egyptian General Authority", "Egyptian authority standard",
         "Fajr at 19.5\u{00B0} / Isha at 17.5\u{00B0}. Common in Africa and the Middle East. Earliest Fajr times.",
         "Egypt, Sudan, Africa"),
        ("Makkah", "Umm al-Qura", "Used in Saudi Arabia",
         "Fajr at 18.5\u{00B0} / Isha 90 min after Maghrib. Official method of Saudi Arabia.",
         "Saudi Arabia, Middle East"),
        ("Karachi", "University of Islamic Sciences", "Standard for South Asia",
         "Fajr at 18\u{00B0} / Isha at 18\u{00B0}. Standard in South Asia (Pakistan, India, Bangladesh).",
         "Pakistan, India, Bangladesh, Afghanistan"),
        ("Tehran", "Institute of Geophysics", "Standard for Iran",
         "Fajr at 17.7\u{00B0} / Isha at 14\u{00B0}. Based on Institute of Geophysics, University of Tehran.",
         "Iran, Azerbaijan, parts of Russia")
    ]

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: permissionManager.locationStatus.isGranted ? "checkmark.circle.fill" : "location.fill")
                        .font(.system(size: 50))
                        .foregroundColor(permissionManager.locationStatus.isGranted ? themeManager.currentTheme.accent : themeManager.currentTheme.accentMuted)
                        .symbolEffect(.bounce, value: permissionManager.locationStatus.isGranted)

                    ThemedText(
                        permissionManager.locationStatus.isGranted ? "Location Enabled" : "Prayer Times Setup",
                        style: .title
                    )
                    .foregroundColor(themeManager.currentTheme.accent)

                    ThemedText.body(
                        permissionManager.locationStatus.isGranted ?
                        "Now let's configure your prayer calculation method" :
                        "We need your location to provide accurate prayer times for your area"
                    )
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.horizontal, 32)
                }
                .padding(.top, 20)

                // MARK: - Location Permission Section
                if !permissionManager.locationStatus.isGranted {
                    locationPermissionSection
                } else {
                    // MARK: - Calculation Method Section
                    calculationMethodSection
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .alert("Location Access Required", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                permissionManager.openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings to get accurate prayer times for your area.")
        }
        .alert("Enter Your City", isPresented: $showManualEntry) {
            TextField("City name", text: $manualCity)
                .textContentType(.addressCity)
            Button("Continue") {
                handleManualCityEntry()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your city name to get prayer times for your area.")
        }
        .task {
            // Check status when view appears
            _ = await permissionManager.checkLocationStatus()

            // If already granted, detect country for recommendation
            if permissionManager.locationStatus.isGranted {
                await detectCountryFromLocation()
            }
        }
        .onChange(of: permissionManager.locationStatus) { oldStatus, newStatus in
            // Auto-detect country when permission is granted
            if hasRequestedPermission && newStatus.isGranted && !hasAutoAdvanced {
                hasAutoAdvanced = true  // Prevent double-advance
                AudioHapticCoordinator.shared.playSuccess()
                coordinator.updateLocationPermission(.granted)

                // Detect country to recommend calculation method
                // User will select method and click Continue when ready
                Task {
                    await detectCountryFromLocation()
                }
            } else if hasRequestedPermission && newStatus == .denied {
                coordinator.updateLocationPermission(.denied)
                // Show manual entry option
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showManualEntry = true
                }
            } else if hasRequestedPermission && newStatus == .restricted {
                coordinator.updateLocationPermission(.restricted)
            }
        }
    }

    // MARK: - Location Permission Section
    private var locationPermissionSection: some View {
        Group {
            if showPrimingView && !hasRequestedPermission && !permissionManager.locationStatus.isGranted {
                // Show priming view first (contextual education)
                LocationPrimingView(
                    onRequestPermission: {
                        withAnimation(.spring(response: 0.4)) {
                            showPrimingView = false
                        }
                        // Small delay to allow animation, then request
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            requestLocationPermission()
                        }
                    },
                    onSkip: {
                        AudioHapticCoordinator.shared.playBack()
                        coordinator.advance()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Show permission status and actions
                VStack(spacing: 24) {
                    // Action buttons
                    VStack(spacing: 12) {
                        if !permissionManager.locationStatus.isGranted {
                            Button {
                                requestLocationPermission()
                            } label: {
                                if isRequesting {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(themeManager.currentTheme.backgroundColor)
                                        Text("Requesting...")
                                            .foregroundColor(themeManager.currentTheme.backgroundColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    Label("Enable Location", systemImage: "location.fill")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(themeManager.currentTheme.accentMuted)
                            .disabled(isRequesting)
                        }

                        // Show "Open Settings" if denied
                        if permissionManager.locationStatus.needsSettingsRedirect {
                            Button {
                                showSettingsAlert = true
                            } label: {
                                Label("Open Settings", systemImage: "gear")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .tint(themeManager.currentTheme.accentMuted)
                        }

                        // Manual entry option (only after denial)
                        if permissionManager.locationStatus == .denied {
                            Button {
                                showManualEntry = true
                            } label: {
                                Text("Enter City Manually")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                        }
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
    }

    // MARK: - Calculation Method Section
    private var calculationMethodSection: some View {
        VStack(spacing: 24) {
            // Detection info
            if let country = detectedCountry {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accent)

                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText("Detected Location", style: .body)
                            .fontWeight(.semibold)
                        ThemedText.caption(country)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.currentTheme.cardColor)
                )
            }

            // Recommended method
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ThemedText("Recommended Method", style: .body)
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: "info.circle")
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .onTapGesture {
                            // Show explanation
                        }
                }

                let recommendedMethodId = coordinator.recommendedCalculationMethod(for: detectedCountry)
                if let method = methods.first(where: { $0.id == recommendedMethodId }) {
                    MethodCard(
                        methodId: method.id,
                        name: method.name,
                        description: method.description,
                        explanation: method.explanation,
                        regions: method.regions,
                        isRecommended: true,
                        isSelected: coordinator.selectedCalculationMethod == method.id,
                        onSelect: {
                            withAnimation(.spring(response: 0.3)) {
                                coordinator.selectedCalculationMethod = method.id
                                AudioHapticCoordinator.shared.playSelection()
                            }
                        }
                    )
                }
            }

            // Expandable other methods
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showMethodSelection.toggle()
                    }
                } label: {
                    HStack {
                        ThemedText(showMethodSelection ? "Hide Other Methods" : "Use a Different Method", style: .body)
                            .foregroundColor(themeManager.currentTheme.accent)

                        Spacer()

                        Image(systemName: showMethodSelection ? "chevron.up" : "chevron.down")
                            .foregroundColor(themeManager.currentTheme.accent)
                            .font(.caption.weight(.semibold))
                    }
                }
                .buttonStyle(.plain)

                if showMethodSelection {
                    let recommendedMethodId = coordinator.recommendedCalculationMethod(for: detectedCountry)
                    let otherMethods = methods.filter { $0.id != recommendedMethodId }

                    VStack(spacing: 12) {
                        ForEach(otherMethods, id: \.id) { method in
                            MethodCard(
                                methodId: method.id,
                                name: method.name,
                                description: method.description,
                                explanation: method.explanation,
                                regions: method.regions,
                                isRecommended: false,
                                isSelected: coordinator.selectedCalculationMethod == method.id,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        coordinator.selectedCalculationMethod = method.id
                                        AudioHapticCoordinator.shared.playSelection()
                                    }
                                }
                            )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }

            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentMuted)
                    ThemedText("Why does this matter?", style: .body)
                        .fontWeight(.semibold)
                }

                ThemedText.body(
                    "Different Islamic organizations use slightly different astronomical calculations for prayer times, especially Fajr and Isha. The differences are usually 2-5 minutes. We recommend the method most commonly used in your region, but you can always change this in Settings."
                )
                .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.accentMuted.opacity(0.15))
            )

            // Continue button (only shown after calculation method selected)
            if !coordinator.selectedCalculationMethod.isEmpty {
                Button {
                    AudioHapticCoordinator.shared.playConfirm()
                    coordinator.advance()
                } label: {
                    Label {
                        Text("Continue")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(themeManager.currentTheme.accent)
            }
        }
    }

    // MARK: - Methods

    private func requestLocationPermission() {
        hasRequestedPermission = true
        isRequesting = true
        AudioHapticCoordinator.shared.playConfirm()

        Task {
            let status = await permissionManager.requestLocationPermission()

            await MainActor.run {
                isRequesting = false

                // Update coordinator with result
                switch status {
                case .granted:
                    coordinator.updateLocationPermission(.granted)
                case .denied:
                    coordinator.updateLocationPermission(.denied)
                case .restricted:
                    coordinator.updateLocationPermission(.restricted)
                case .notDetermined:
                    coordinator.updateLocationPermission(.denied)
                }
            }
        }
    }

    private func detectCountryFromLocation() async {
        guard let location = locationService.currentLocation else { return }

        // Use MapKit for reverse geocoding (iOS 26+ modern approach)
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )

        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            // Get country code from geocoded location
            // iOS 26 Note: placemark.countryCode is deprecated
            // Using device locale as recommended alternative since addressRepresentations
            // doesn't expose country codes directly
            if !response.mapItems.isEmpty {
                // Use device's region code (best approximation available in iOS 26)
                let countryCode = Locale.current.region?.identifier

                if let countryCode = countryCode {
                    await MainActor.run {
                        detectedCountry = countryCode
                        // Auto-select recommended method
                        let recommended = coordinator.recommendedCalculationMethod(for: countryCode)
                        coordinator.selectedCalculationMethod = recommended
                    }
                }
            }
        } catch {
            #if DEBUG
            print("MapKit search error: \(error)")
            #endif
        }
    }

    private func handleManualCityEntry() {
        guard !manualCity.isEmpty else { return }

        coordinator.updateLocationPermission(.denied)
        AudioHapticCoordinator.shared.playConfirm()

        // Set a default method if none selected
        if coordinator.selectedCalculationMethod.isEmpty {
            coordinator.selectedCalculationMethod = "MWL"
        }

        // Geocode city name to get coordinates (using MapKit -- CLGeocoder is deprecated in iOS 26)
        Task {
            if let geocodingRequest = MKGeocodingRequest(addressString: manualCity) {
                do {
                    let results = try await geocodingRequest.mapItems
                    if let mapItem = results.first {
                        let location = mapItem.location
                        await MainActor.run {
                            UserDefaults.standard.set(location.coordinate.latitude, forKey: "manualLatitude")
                            UserDefaults.standard.set(location.coordinate.longitude, forKey: "manualLongitude")
                            UserDefaults.standard.set(manualCity, forKey: "manualCityName")

                            // Detect country for calculation method recommendation
                            if let countryCode = mapItem.addressRepresentations?.region?.identifier {
                                let recommended = coordinator.recommendedCalculationMethod(for: countryCode)
                                coordinator.selectedCalculationMethod = recommended
                            }
                        }
                    }
                } catch {
                    #if DEBUG
                    print("Geocoding failed for '\(manualCity)': \(error)")
                    #endif
                }
            }

            // Always advance -- don't leave user stuck even if geocoding fails
            await MainActor.run {
                coordinator.advance()
            }
        }
    }
}

// MARK: - Method Card Component

struct MethodCard: View {
    let methodId: String
    let name: String
    let description: String
    let explanation: String
    let regions: String
    let isRecommended: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textTertiary,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(themeManager.currentTheme.accent)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: isSelected)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ThemedText(name, style: .body)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textPrimary
                            )

                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(themeManager.currentTheme.backgroundColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(themeManager.currentTheme.accent)
                                )
                        }
                    }

                    ThemedText.caption(description)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.leading)

                    // Human-readable explanation of the calculation angles
                    Text(explanation)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Image(systemName: "globe.americas.fill")
                            .font(.caption2)
                        ThemedText(regions, style: .caption)
                    }
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? themeManager.currentTheme.accent : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Benefit Row Component (with custom color)

struct BenefitRowWithColor: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
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
    LocationAndCalculationView(
        coordinator: OnboardingCoordinator(),
        permissionManager: PermissionManager.shared
    )
    .environment(ThemeManager())
}
