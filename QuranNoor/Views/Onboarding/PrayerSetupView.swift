//
//  PrayerSetupView.swift
//  QuranNoor
//
//  Screen 2: Calculation method selection + name entry
//  Native Picker with auto-detected recommendation, DisclosureGroup for details,
//  and optional name field with live greeting preview

import SwiftUI
import CoreLocation
import MapKit

struct PrayerSetupView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let coordinator: OnboardingCoordinator
    var permissionManager: PermissionManager

    @State private var locationService = LocationService.shared
    @State private var detectedCountry: String?
    @State private var userName: String
    @State private var showMethodInfo = false
    @FocusState private var isNameFieldFocused: Bool

    // Feedback
    private let feedbackCoordinator = AudioHapticCoordinator.shared

    // Calculation methods with region tags
    private let methods: [(id: String, name: String, description: String, regions: String)] = [
        ("ISNA", "ISNA (North America)", "Fajr 15° / Isha 15°", "US, Canada"),
        ("MWL", "Muslim World League", "Fajr 18° / Isha 17°", "Europe, Far East"),
        ("Egyptian", "Egyptian General Authority", "Fajr 19.5° / Isha 17.5°", "Egypt, Africa"),
        ("Makkah", "Umm al-Qura", "Fajr 18.5° / Isha 90min after Maghrib", "Saudi Arabia"),
        ("Karachi", "University of Islamic Sciences", "Fajr 18° / Isha 18°", "Pakistan, India"),
        ("Tehran", "Institute of Geophysics", "Fajr 17.7° / Isha 14°", "Iran")
    ]

    // MARK: - Initialization

    init(coordinator: OnboardingCoordinator, permissionManager: PermissionManager) {
        self.coordinator = coordinator
        self.permissionManager = permissionManager
        _userName = State(initialValue: UserDefaults.standard.string(forKey: "userName") ?? "")
    }

    // MARK: - Body
    var body: some View {
        let theme = themeManager.currentTheme

        ScrollView {
            VStack(spacing: Spacing.lg) {
                // MARK: - Header
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentMuted)

                    ThemedText("Prayer Times Setup", style: .title)
                        .foregroundColor(theme.accent)

                    ThemedText.body("Choose your calculation method and personalize your experience")
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, Spacing.lg)
                }
                .padding(.top, Spacing.xl)

                // MARK: - Detected Location
                if let country = detectedCountry {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(theme.accent)
                        Text("Detected: \(country)")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }

                // MARK: - Calculation Method Picker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Calculation Method")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)

                    // Native menu picker
                    Picker("Method", selection: Binding(
                        get: { coordinator.selectedCalculationMethod },
                        set: { newValue in
                            coordinator.selectedCalculationMethod = newValue
                            feedbackCoordinator.playSelection()
                        }
                    )) {
                        ForEach(methods, id: \.id) { method in
                            VStack(alignment: .leading) {
                                Text(method.name)
                                Text(method.regions)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(method.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(theme.accent)

                    // Recommended badge
                    if let recommended = recommendedMethodName {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("Recommended: \(recommended)")
                                .font(.caption)
                        }
                        .foregroundColor(theme.accentMuted)
                    }

                    // About calculation methods
                    DisclosureGroup("About calculation methods") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Different Islamic organizations use slightly different astronomical calculations for prayer times, especially Fajr and Isha. The differences are usually 2-5 minutes.")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)

                            Text("We recommend the method most commonly used in your region. You can always change this later in Settings.")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.top, Spacing.xxs)
                    }
                    .tint(theme.accentMuted)
                    .font(.subheadline)
                }
                .padding(Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(theme.cardColor)
                )
                .padding(.horizontal, Spacing.screenHorizontal)

                // MARK: - Name Entry
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Name")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)

                    Text("Optional — for a personalized greeting")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)

                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17))
                        .foregroundColor(theme.textPrimary)
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(theme.backgroundColor.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(
                                    isNameFieldFocused ? theme.accent : theme.borderColor,
                                    lineWidth: isNameFieldFocused ? 2 : 1
                                )
                        )
                        .focused($isNameFieldFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)

                    // Live greeting preview
                    if !userName.trimmingCharacters(in: .whitespaces).isEmpty {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(theme.accentMuted)
                            Text("As Salamu Alaykum, \(userName.trimmingCharacters(in: .whitespaces))")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(theme.textPrimary)
                        }
                        .padding(.top, Spacing.xxxs)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.smooth(duration: 0.2), value: userName)
                    }
                }
                .padding(Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(theme.cardColor)
                )
                .padding(.horizontal, Spacing.screenHorizontal)

                Spacer(minLength: Spacing.xxl + 60)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // MARK: - Continue Button
            Button {
                saveName()
                feedbackCoordinator.playConfirm()
                coordinator.advance()
            } label: {
                Label("Continue", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(themeManager.currentTheme.accent)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.sm)
            .background(
                themeManager.currentTheme.backgroundColor
                    .opacity(0.95)
                    .ignoresSafeArea()
            )
        }
        .task {
            // Auto-detect country for recommendation
            if permissionManager.locationStatus.isGranted {
                await detectCountryFromLocation()
            }
        }
        .accessibilityPageAnnouncement("Prayer Times Setup. Step 2 of 3. Choose your calculation method and optionally enter your name.")
    }

    // MARK: - Computed Properties

    private var recommendedMethodName: String? {
        let recommended = coordinator.recommendedCalculationMethod(for: detectedCountry)
        return methods.first(where: { $0.id == recommended })?.name
    }

    // MARK: - Methods

    private func saveName() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            UserDefaults.standard.set(trimmedName, forKey: "userName")
        } else {
            UserDefaults.standard.removeObject(forKey: "userName")
        }
    }

    private func detectCountryFromLocation() async {
        guard let location = locationService.currentLocation else { return }

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

            if !response.mapItems.isEmpty {
                let countryCode = Locale.current.region?.identifier

                if let countryCode {
                    await MainActor.run {
                        detectedCountry = countryCode
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
}

// MARK: - Preview
#Preview {
    PrayerSetupView(
        coordinator: OnboardingCoordinator(),
        permissionManager: PermissionManager.shared
    )
    .environment(ThemeManager())
}
