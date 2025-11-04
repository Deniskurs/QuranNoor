//
//  LocationManagementModal.swift
//  QuranNoor
//
//  Premium modal sheet for location management with beautiful UI
//

import SwiftUI

struct LocationManagementModal: View {
    // MARK: - Properties
    @ObservedObject var viewModel: QiblaViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var locationToDelete: SavedLocation?

    // Callback to trigger save location alert from parent
    var onSaveCurrentLocation: (() -> Void)?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.sectionSpacing) {
                        // Current Location Section
                        currentLocationSection

                        // Save Current Location Button
                        if !viewModel.isUsingManualLocation && viewModel.currentCoordinates != nil {
                            saveCurrentLocationButton
                        }

                        // Saved Locations Section
                        if !viewModel.savedLocations.isEmpty {
                            savedLocationsSection
                        }

                        // Manual Location Hint
                        manualLocationHint
                    }
                    .padding(Spacing.screenPadding)
                }
            }
            .navigationTitle("Location Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppColors.primary.teal)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search locations")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("Delete Location", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let location = locationToDelete {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.deleteSavedLocation(location)
                    }
                    locationToDelete = nil
                }
            }
        } message: {
            if let location = locationToDelete {
                Text("Are you sure you want to delete \(location.name)?")
            }
        }
    }

    // MARK: - Save Current Location Button
    private var saveCurrentLocationButton: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .light)
            dismiss()
            // Trigger callback after modal dismisses
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSaveCurrentLocation?()
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "bookmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary.gold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Save Current Location")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    Text("Add to your saved locations")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.gold.opacity(0.1),
                                AppColors.primary.gold.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.xl)
                            .strokeBorder(
                                AppColors.primary.gold.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: AppColors.primary.gold.opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(CardPressStyle())
    }

    // MARK: - Current Location Section
    private var currentLocationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Current Location", icon: "location.circle.fill")

            Button {
                HapticManager.shared.triggerImpact(style: .medium)
                Task {
                    await viewModel.useGPSLocation()
                    dismiss()
                }
            } label: {
                LocationCardView(
                    name: viewModel.isUsingManualLocation ? "Use GPS Location" : viewModel.userLocation,
                    subtitle: viewModel.isUsingManualLocation ? "Switch to automatic" : "GPS Active",
                    icon: viewModel.isUsingManualLocation ? "location.circle" : "location.circle.fill",
                    isSelected: !viewModel.isUsingManualLocation,
                    showChevron: false,
                    themeManager: themeManager
                )
            }
            .buttonStyle(CardPressStyle())
            .disabled(!viewModel.isUsingManualLocation && viewModel.currentCoordinates != nil)
        }
    }

    // MARK: - Saved Locations Section
    private var savedLocationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Saved Locations", icon: "star.fill")

            ForEach(filteredLocations) { location in
                Button {
                    HapticManager.shared.triggerImpact(style: .medium)
                    Task {
                        await viewModel.useSavedLocation(location)
                        dismiss()
                    }
                } label: {
                    LocationCardView(
                        name: location.name,
                        subtitle: formatDate(location.savedDate),
                        icon: "mappin.circle.fill",
                        isSelected: viewModel.isUsingManualLocation && viewModel.userLocation == location.name,
                        showChevron: true,
                        themeManager: themeManager
                    )
                }
                .buttonStyle(CardPressStyle())
                .contextMenu {
                    Button(role: .destructive) {
                        locationToDelete = location
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Manual Location Hint
    private var manualLocationHint: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .light)
            viewModel.showLocationPicker = true
            dismiss()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Manual Location")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    Text("Set a custom location manually")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(themeManager.currentTheme.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.xl)
                            .strokeBorder(
                                AppColors.primary.teal.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(CardPressStyle())
    }

    // MARK: - Helper Methods

    /// Filter locations based on search text
    private var filteredLocations: [SavedLocation] {
        if searchText.isEmpty {
            return viewModel.savedLocations
        }
        return viewModel.savedLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Format saved date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Saved \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - Section Header Component
struct SectionHeader: View {
    let title: String
    let icon: String

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary.teal)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(themeManager.currentTheme.textPrimary)
        }
    }
}

// MARK: - Location Card View Component
struct LocationCardView: View {
    let name: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let showChevron: Bool
    let themeManager: ThemeManager

    // Animation state
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isSelected ? AppColors.primary.teal : AppColors.primary.green)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.primary.teal.opacity(0.15) : AppColors.primary.green.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? AppColors.primary.teal.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: isSelected ? AppColors.primary.teal.opacity(0.2) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 2
                )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Trailing indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.primary.teal)
                    .font(.title3)
                    .symbolEffect(.bounce, value: isSelected)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(Spacing.cardPadding)
        .background(
            ZStack {
                // Base glass morphism layer
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(.ultraThinMaterial)

                // Color overlay with theme
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(themeManager.currentTheme.cardColor.opacity(0.8))

                // Selected state glow
                if isSelected {
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.primary.teal.opacity(0.1),
                                    AppColors.primary.teal.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .strokeBorder(AppColors.primary.teal, lineWidth: 2)
                }

                // Normal state border
                if !isSelected {
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
            }
        )
        .shadow(
            color: isSelected ? AppColors.primary.teal.opacity(0.2) : Color.black.opacity(0.05),
            radius: isSelected ? 12 : 8,
            x: 0,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }

    /// Check if current theme is dark
    private var isDark: Bool {
        themeManager.currentTheme == .dark || themeManager.currentTheme == .night
    }
}

// MARK: - Preview
#Preview {
    LocationManagementModal(viewModel: QiblaViewModel())
        .environmentObject(ThemeManager())
}
