//
//  MosqueFinderView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Enhanced mosque finder with SwiftUI Map integration
//

import SwiftUI
import MapKit

struct MosqueFinderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(LocationService.self) private var locationService: LocationService

    @State private var mosqueService = MosqueFinderService.shared
    @State private var mosques: [Mosque] = []
    @State private var selectedMosque: Mosque?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var selectedDistanceFilter: DistanceFilter = MosqueFinderService.shared.selectedDistanceFilter
    @State private var hasSearched: Bool = false

    /// Non-nil when an auto-expanding search had to widen past the user's
    /// preferred radius — surfaces as a small banner so the user understands
    /// why their picker value changed.
    @State private var autoExpandMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header is always visible — users who hit an empty
                    // state must be able to change the radius without
                    // leaving the screen. This was the core UX bug.
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, mosques.isEmpty ? 12 : 8)

                    if isLoading && mosques.isEmpty {
                        loadingView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if mosques.isEmpty && hasSearched {
                        emptyStateView
                    } else if mosques.isEmpty {
                        // First-frame while initial task kicks off
                        loadingView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("Find Mosques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await refreshWithAutoExpand() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Refresh search")
                }
            }
            .task {
                await initialSearch()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 0) {
            // Map View
            mapView
                .frame(height: 260)

            // Mosque List (picker lives in the always-visible header now)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(mosques) { mosque in
                        MosqueCard(
                            mosque: mosque,
                            isSelected: selectedMosque?.id == mosque.id,
                            onSelect: {
                                withAnimation(AppAnimation.fast) {
                                    selectedMosque = mosque
                                    // Update map to center on selected mosque
                                    mapPosition = .camera(
                                        MapCamera(
                                            centerCoordinate: CLLocationCoordinate2D(
                                                latitude: mosque.coordinates.latitude,
                                                longitude: mosque.coordinates.longitude
                                            ),
                                            distance: 1000
                                        )
                                    )
                                }
                                AudioHapticCoordinator.shared.playButtonPress()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Header (Always Visible)

    /// Persistent header with radius picker + contextual status line. Shown in
    /// every state (loading, empty, loaded) so users can always adjust the
    /// search distance without having to back out and retry.
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "location.magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.accent)

                Text("Search radius")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)

                Spacer()

                radiusMenu
            }

            statusLine
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous)
                .fill(themeManager.currentTheme.cardColor)
        )
    }

    private var radiusMenu: some View {
        Menu {
            ForEach(DistanceFilter.allCases) { filter in
                Button {
                    userSelectRadius(filter)
                } label: {
                    HStack {
                        Text(filter.displayName)
                        if filter == selectedDistanceFilter {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedDistanceFilter.displayName)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(themeManager.currentTheme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(themeManager.currentTheme.accent.opacity(0.15))
            )
        }
        .accessibilityLabel("Search radius")
        .accessibilityValue(selectedDistanceFilter.displayName)
        .accessibilityHint("Double-tap to change how far we search for mosques")
    }

    @ViewBuilder
    private var statusLine: some View {
        if let msg = autoExpandMessage {
            Label(msg, systemImage: "arrow.up.forward.circle.fill")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.accent)
                .transition(.opacity.combined(with: .move(edge: .top)))
        } else if !mosques.isEmpty {
            Text("\(mosques.count) mosque\(mosques.count == 1 ? "" : "s") within \(selectedDistanceFilter.displayName)")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        } else if hasSearched {
            Text("No mosques within \(selectedDistanceFilter.displayName)")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        } else if isLoading {
            Text("Searching within \(selectedDistanceFilter.displayName)…")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $mapPosition, selection: $selectedMosque) {
            // User location
            if let userCoords = locationService.currentLocation {
                Annotation("Your Location", coordinate: CLLocationCoordinate2D(
                    latitude: userCoords.latitude,
                    longitude: userCoords.longitude
                )) {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.accent.opacity(0.3))
                            .frame(width: 40, height: 40)

                        Circle()
                            .fill(themeManager.currentTheme.accent)
                            .frame(width: 16, height: 16)
                    }
                }
            }

            // Mosque markers
            ForEach(mosques) { mosque in
                Marker(
                    mosque.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: mosque.coordinates.latitude,
                        longitude: mosque.coordinates.longitude
                    )
                )
                .tint(selectedMosque?.id == mosque.id ? themeManager.currentTheme.accent : .orange)
                .tag(mosque)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onChange(of: selectedMosque) { _, newValue in
            if let mosque = newValue {
                withAnimation {
                    mapPosition = .camera(
                        MapCamera(
                            centerCoordinate: CLLocationCoordinate2D(
                                latitude: mosque.coordinates.latitude,
                                longitude: mosque.coordinates.longitude
                            ),
                            distance: 1000
                        )
                    )
                }
            }
        }
    }

    // MARK: - Empty State View

    /// Actionable empty state. Instead of a dead-end "Search Again" button
    /// that repeated the same zero-result query, the user now has concrete
    /// next steps: widen the radius, search Apple Maps, or refresh their
    /// GPS fix. The always-visible header picker also remains accessible
    /// above this view.
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Spacer().frame(height: Spacing.md)

                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(themeManager.currentTheme.textSecondary)

                VStack(spacing: 8) {
                    Text("No mosques within \(selectedDistanceFilter.displayName)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(emptyStateSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)
                }

                VStack(spacing: 10) {
                    if let nextFilter = nextWiderFilter {
                        Button {
                            userSelectRadius(nextFilter)
                        } label: {
                            Label("Widen search to \(nextFilter.displayName)", systemImage: "arrow.up.forward")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(themeManager.currentTheme.accent)
                                )
                        }
                    }

                    Button {
                        openAppleMapsSearch()
                    } label: {
                        Label("Search in Apple Maps", systemImage: "map.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(themeManager.currentTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                Capsule()
                                    .stroke(themeManager.currentTheme.accent, lineWidth: 1.5)
                            )
                    }

                    Button {
                        refreshLocation()
                    } label: {
                        Label("Refresh my location", systemImage: "location.circle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Spacer().frame(height: Spacing.md)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var emptyStateSubtitle: String {
        if nextWiderFilter != nil {
            return "Try a wider radius, or open Apple Maps to search further afield."
        } else {
            return "We searched up to 50 km and didn't find any mosques. Try Apple Maps for a wider area, or refresh your location if it looks off."
        }
    }

    private var nextWiderFilter: DistanceFilter? {
        let cases = DistanceFilter.allCases
        guard let idx = cases.firstIndex(of: selectedDistanceFilter) else { return cases.last }
        return idx + 1 < cases.count ? cases[idx + 1] : nil
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.currentTheme.accent)

            Text("Finding nearby mosques...")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        }
    }

    // MARK: - Helper Methods

    /// First search when the view appears. Uses auto-expanding search so
    /// users in low-density areas get *some* results rather than bouncing
    /// off an empty state.
    private func initialSearch() async {
        guard let location = locationService.currentLocation else {
            showError(message: "Location unavailable. Please enable location services.")
            hasSearched = true
            return
        }
        await performAutoExpandingSearch(at: location, forceRefresh: false)
    }

    /// Toolbar refresh button. Re-runs the auto-expanding search, bypassing
    /// the cache so freshly-opened mosques show up without waiting an hour.
    private func refreshWithAutoExpand() async {
        guard let location = locationService.currentLocation else {
            showError(message: "Location unavailable. Please enable location services.")
            return
        }
        await performAutoExpandingSearch(at: location, forceRefresh: true)
    }

    private func performAutoExpandingSearch(at location: LocationCoordinates, forceRefresh: Bool) async {
        isLoading = true
        let startFilter = selectedDistanceFilter
        withAnimation(AppAnimation.fast) { autoExpandMessage = nil }

        defer {
            isLoading = false
            hasSearched = true
        }

        do {
            let outcome = try await mosqueService.findNearbyMosquesAutoExpanding(
                coordinates: location,
                startingFilter: startFilter,
                forceRefresh: forceRefresh
            )
            mosques = outcome.results
            selectedDistanceFilter = outcome.matchedFilter

            if outcome.didExpand && !outcome.results.isEmpty {
                withAnimation(AppAnimation.fast) {
                    autoExpandMessage = "No mosques within \(startFilter.displayName) — expanded to \(outcome.matchedFilter.displayName)"
                }
                AudioHapticCoordinator.shared.playSelection()
            } else if !outcome.results.isEmpty {
                AudioHapticCoordinator.shared.playSuccess()
            }

            if let first = mosques.first {
                mapPosition = .camera(
                    MapCamera(
                        centerCoordinate: CLLocationCoordinate2D(
                            latitude: first.coordinates.latitude,
                            longitude: first.coordinates.longitude
                        ),
                        distance: max(outcome.matchedFilter.rawValue, 2000)
                    )
                )
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    /// User explicitly picked a radius from the menu — respect their choice
    /// and run a single-radius search (no auto-expansion).
    private func userSelectRadius(_ filter: DistanceFilter) {
        AudioHapticCoordinator.shared.playSelection()
        withAnimation(AppAnimation.fast) { autoExpandMessage = nil }

        selectedDistanceFilter = filter
        mosqueService.setDistanceFilter(filter)

        guard let location = locationService.currentLocation else {
            showError(message: "Location unavailable. Please enable location services.")
            return
        }

        Task {
            isLoading = true
            defer {
                isLoading = false
                hasSearched = true
            }
            do {
                mosques = try await mosqueService.findNearbyMosques(
                    coordinates: location,
                    radiusInMeters: filter.rawValue
                )
                if !mosques.isEmpty {
                    AudioHapticCoordinator.shared.playSuccess()
                }
            } catch {
                showError(message: error.localizedDescription)
            }
        }
    }

    /// Fallback to Apple Maps for users in areas truly outside our 50 km
    /// reach. Opens a location-aware query so Maps re-centres correctly.
    private func openAppleMapsSearch() {
        AudioHapticCoordinator.shared.playButtonPress()
        guard let location = locationService.currentLocation else {
            if let url = URL(string: "http://maps.apple.com/?q=mosque") {
                UIApplication.shared.open(url)
            }
            return
        }
        let urlString = "http://maps.apple.com/?q=mosque&sll=\(location.latitude),\(location.longitude)&z=11"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    /// Re-request the device GPS fix in case the user moved since the last
    /// search, then retry with auto-expanding search.
    private func refreshLocation() {
        AudioHapticCoordinator.shared.playButtonPress()
        locationService.requestLocationPermission()

        Task {
            // Small delay to let CoreLocation hand us a fresh fix before we
            // re-search. Non-blocking if the fix is already cached.
            try? await Task.sleep(nanoseconds: 500_000_000)
            if let location = locationService.currentLocation {
                await performAutoExpandingSearch(at: location, forceRefresh: true)
            }
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showingError = true
        AudioHapticCoordinator.shared.playWarning()
    }
}

// MARK: - Mosque Card

struct MosqueCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let mosque: Mosque
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Button {
                    onSelect()
                } label: {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(themeManager.currentTheme.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(mosque.name)
                                .font(.headline)
                                .foregroundStyle(themeManager.currentTheme.textPrimary)
                                .multilineTextAlignment(.leading)

                            Text(mosque.formattedDistance)
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                // Expanded Content
                if isSelected {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        // Address
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(themeManager.currentTheme.accent)

                            Text(mosque.address)
                                .font(.subheadline)
                                .foregroundStyle(themeManager.currentTheme.textSecondary)
                        }

                        // Action Buttons
                        HStack(spacing: 12) {
                            // Open in Maps Button
                            Button {
                                openInMaps(mosque)
                            } label: {
                                Label("Directions", systemImage: "map.fill")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(themeManager.currentTheme.accent)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous))
                            }

                            // Call Button (if phone number available)
                            if let phoneNumber = mosque.phoneNumber {
                                Button {
                                    callMosque(phoneNumber)
                                } label: {
                                    Label("Call", systemImage: "phone.fill")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.green)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous))
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .padding(16)
        }
        .animation(AppAnimation.fast, value: isSelected)
    }

    // MARK: - Actions

    private func openInMaps(_ mosque: Mosque) {
        // iOS 26+: Use new MKMapItem(location:address:) API
        let location = CLLocation(
            latitude: mosque.coordinates.latitude,
            longitude: mosque.coordinates.longitude
        )
        let address = MKAddress(fullAddress: mosque.address, shortAddress: nil)
        let mapItem = MKMapItem(location: location, address: address)
        mapItem.name = mosque.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])

        AudioHapticCoordinator.shared.playButtonPress()
    }

    private func callMosque(_ phoneNumber: String) {
        // Remove formatting characters
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if let url = URL(string: "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
            AudioHapticCoordinator.shared.playButtonPress()
            #if DEBUG
            print("📞 Calling mosque: \(phoneNumber)")
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    MosqueFinderView()
        .environment(ThemeManager())
        .environment(LocationService.shared)
}
