//
//  LocationPickerView.swift
//  QuranNoor
//
//  Manual location picker for Qibla compass
//

import SwiftUI

struct LocationPickerView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: QiblaViewModel

    @State private var locationName = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .serenity, opacity: 0.2)

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Manual coordinates entry
                        coordinatesEntrySection

                        // Saved locations
                        if !viewModel.savedLocations.isEmpty {
                            savedLocationsSection
                        }

                        // Popular locations
                        popularLocationsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Set") {
                        setManualLocation()
                    }
                    .disabled(!isValidInput)
                }
            }
            .alert("Invalid Input", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Components

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "map.fill")
                .font(.system(size: 40))
                .foregroundColor(AppColors.primary.green)

            ThemedText("Choose Location", style: .heading)
                .foregroundColor(AppColors.primary.green)

            ThemedText.caption("Enter coordinates or select from saved locations")
                .multilineTextAlignment(.center)
                .opacity(0.7)
        }
        .padding(.top, 8)
    }

    private var coordinatesEntrySection: some View {
        CardView(showPattern: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(AppColors.primary.green)
                    ThemedText("Manual Coordinates", style: .heading)
                }

                IslamicDivider(style: .simple)

                // Location name
                VStack(alignment: .leading, spacing: 8) {
                    ThemedText.caption("LOCATION NAME")
                    TextField("e.g., Home, Office, Mosque", text: $locationName)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                }

                // Latitude
                VStack(alignment: .leading, spacing: 8) {
                    ThemedText.caption("LATITUDE")
                    TextField("e.g., 21.4225", text: $latitude)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                    ThemedText.caption("Range: -90 to 90")
                        .foregroundColor(AppColors.primary.teal)
                        .opacity(0.6)
                }

                // Longitude
                VStack(alignment: .leading, spacing: 8) {
                    ThemedText.caption("LONGITUDE")
                    TextField("e.g., 39.8262", text: $longitude)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                    ThemedText.caption("Range: -180 to 180")
                        .foregroundColor(AppColors.primary.teal)
                        .opacity(0.6)
                }
            }
        }
    }

    private var savedLocationsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppColors.primary.gold)
                    ThemedText("Saved Locations", style: .heading)
                }

                IslamicDivider(style: .simple)

                ForEach(viewModel.savedLocations) { location in
                    Button {
                        Task {
                            await viewModel.useSavedLocation(location)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                ThemedText.body(location.name)
                                ThemedText.caption("Lat: \(String(format: "%.4f", location.coordinates.latitude)), Lon: \(String(format: "%.4f", location.coordinates.longitude))")
                                    .foregroundColor(AppColors.primary.teal)
                                    .opacity(0.7)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteSavedLocation(location)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if location.id != viewModel.savedLocations.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var popularLocationsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(AppColors.primary.teal)
                    ThemedText("Popular Locations", style: .heading)
                }

                IslamicDivider(style: .simple)

                ForEach(popularLocations, id: \.name) { location in
                    Button {
                        Task {
                            await viewModel.setManualLocation(
                                coordinates: location.coordinates,
                                name: location.name
                            )
                            dismiss()
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                ThemedText.body(location.name)
                                ThemedText.caption(location.country)
                                    .foregroundColor(AppColors.primary.teal)
                                    .opacity(0.7)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    if location.name != popularLocations.last?.name {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private var isValidInput: Bool {
        guard !locationName.isEmpty,
              let lat = Double(latitude),
              let lon = Double(longitude),
              lat >= -90 && lat <= 90,
              lon >= -180 && lon <= 180 else {
            return false
        }
        return true
    }

    private func setManualLocation() {
        guard let lat = Double(latitude),
              let lon = Double(longitude) else {
            errorMessage = "Please enter valid coordinates"
            showError = true
            return
        }

        guard lat >= -90 && lat <= 90 else {
            errorMessage = "Latitude must be between -90 and 90"
            showError = true
            return
        }

        guard lon >= -180 && lon <= 180 else {
            errorMessage = "Longitude must be between -180 and 180"
            showError = true
            return
        }

        let coordinates = LocationCoordinates(latitude: lat, longitude: lon)

        Task {
            await viewModel.setManualLocation(coordinates: coordinates, name: locationName)
            dismiss()
        }
    }

    // MARK: - Popular Locations Data

    private var popularLocations: [(name: String, country: String, coordinates: LocationCoordinates)] {
        return [
            ("Makkah", "Saudi Arabia", LocationCoordinates(latitude: 21.4225, longitude: 39.8262)),
            ("Madinah", "Saudi Arabia", LocationCoordinates(latitude: 24.5247, longitude: 39.5692)),
            ("Jerusalem", "Palestine", LocationCoordinates(latitude: 31.7683, longitude: 35.2137)),
            ("Cairo", "Egypt", LocationCoordinates(latitude: 30.0444, longitude: 31.2357)),
            ("Istanbul", "Turkey", LocationCoordinates(latitude: 41.0082, longitude: 28.9784)),
            ("Dubai", "UAE", LocationCoordinates(latitude: 25.2048, longitude: 55.2708)),
            ("London", "United Kingdom", LocationCoordinates(latitude: 51.5074, longitude: -0.1278)),
            ("New York", "United States", LocationCoordinates(latitude: 40.7128, longitude: -74.0060)),
            ("Toronto", "Canada", LocationCoordinates(latitude: 43.6532, longitude: -79.3832)),
            ("Sydney", "Australia", LocationCoordinates(latitude: -33.8688, longitude: 151.2093))
        ]
    }
}

// MARK: - Preview
#Preview {
    LocationPickerView(viewModel: QiblaViewModel())
        .environmentObject(ThemeManager())
}
