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
    @State private var selectedDistanceFilter: DistanceFilter = .fiveKm

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if mosques.isEmpty {
                    emptyStateView
                } else {
                    contentView
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
                        searchMosques(forceRefresh: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
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
                .frame(height: 300)

            // Distance Filter
            distanceFilterPicker
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            // Mosque List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(mosques) { mosque in
                        MosqueCard(
                            mosque: mosque,
                            isSelected: selectedMosque?.id == mosque.id,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                .padding(.vertical, 16)
            }
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

    // MARK: - Distance Filter Picker

    private var distanceFilterPicker: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(themeManager.currentTheme.accent)

                Text("Search Radius")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)

                Spacer()

                Text("\(mosques.count) found")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }

            Picker("Distance", selection: $selectedDistanceFilter) {
                ForEach(DistanceFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedDistanceFilter) { _, newValue in
                mosqueService.setDistanceFilter(newValue)
                searchMosques()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 64))
                .foregroundStyle(themeManager.currentTheme.textSecondary)

            Text("No Mosques Found")
                .font(.title3.weight(.semibold))
                .foregroundStyle(themeManager.currentTheme.textPrimary)

            Text("Try increasing the search radius or check your location settings.")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                searchMosques(forceRefresh: true)
            } label: {
                Label("Search Again", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.accent)
                    )
            }
        }
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

    private func initialSearch() async {
        guard let location = locationService.currentLocation else {
            showError(message: "Location unavailable. Please enable location services.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            mosques = try await mosqueService.findNearbyMosques(
                coordinates: location
            )

            // Set initial map position
            if let firstMosque = mosques.first {
                mapPosition = .camera(
                    MapCamera(
                        centerCoordinate: CLLocationCoordinate2D(
                            latitude: firstMosque.coordinates.latitude,
                            longitude: firstMosque.coordinates.longitude
                        ),
                        distance: 5000
                    )
                )
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func searchMosques(forceRefresh: Bool = false) {
        guard let location = locationService.currentLocation else {
            showError(message: "Location unavailable. Please enable location services.")
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                mosques = try await mosqueService.findNearbyMosques(
                    coordinates: location,
                    forceRefresh: forceRefresh
                )
                AudioHapticCoordinator.shared.playSuccess()
            } catch {
                showError(message: error.localizedDescription)
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
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .padding(16)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
