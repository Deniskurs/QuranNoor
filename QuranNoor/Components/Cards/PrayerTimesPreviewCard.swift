//
//  PrayerTimesPreviewCard.swift
//  QuranNoor
//
//  Live preview card showing prayer times in selected theme
//  Used in ThemeSelectionView to demonstrate theme appearance
//

import SwiftUI
import Combine

struct PrayerTimesPreviewCard: View {
    // MARK: - Properties
    let theme: Theme
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Sample prayer times
    private let prayers: [(name: String, time: String, icon: String)] = [
        ("Fajr", "05:42 AM", "sunrise.fill"),
        ("Dhuhr", "12:35 PM", "sun.max.fill"),
        ("Asr", "03:48 PM", "sun.haze.fill"),
        ("Maghrib", "06:22 PM", "sunset.fill"),
        ("Isha", "07:45 PM", "moon.stars.fill")
    ]

    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Prayers")
                        .font(.headline)
                        .foregroundColor(theme.textColor)

                    Text("San Francisco, CA")
                        .font(.caption)
                        .foregroundColor(theme.textColor.opacity(0.6))
                }

                Spacer()

                // Current time
                Text(timeString)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.textColor.opacity(0.7))
            }

            Divider()
                .background(theme.textColor.opacity(0.2))

            // Next prayer highlight
            VStack(spacing: 8) {
                HStack {
                    Text("NEXT PRAYER")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(theme.textColor.opacity(0.5))

                    Spacer()

                    Image(systemName: prayers[2].icon)
                        .foregroundColor(AppColors.primary.green)
                }

                HStack {
                    Text(prayers[2].name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppColors.primary.green)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(prayers[2].time)
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundColor(theme.textColor)

                        Text("in 1h 23m")
                            .font(.caption)
                            .foregroundColor(AppColors.primary.green)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.primary.green.opacity(0.1))
            )

            // Other prayers
            VStack(spacing: 10) {
                ForEach(prayers.indices.filter { $0 != 2 }, id: \.self) { index in
                    HStack {
                        Image(systemName: prayers[index].icon)
                            .font(.caption)
                            .foregroundColor(theme.textColor.opacity(0.6))
                            .frame(width: 20)

                        Text(prayers[index].name)
                            .font(.subheadline)
                            .foregroundColor(theme.textColor)

                        Spacer()

                        Text(prayers[index].time)
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(theme.textColor.opacity(0.8))

                        // Checkmark for completed
                        if index < 2 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(AppColors.primary.green)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardColor)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prayer times preview in \(theme.name) theme. Next prayer is Asr at 3:48 PM")
    }

    // MARK: - Computed Properties

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }
}

// MARK: - Preview
#Preview("Light Theme") {
    PrayerTimesPreviewCard(theme: Theme(
        name: "Light",
        backgroundColor: Color(hex: "#F8F4EA"),
        cardColor: .white,
        textColor: Color(hex: "#1A2332"),
        accentColor: AppColors.primary.teal
    ))
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Theme") {
    PrayerTimesPreviewCard(theme: Theme(
        name: "Dark",
        backgroundColor: Color(hex: "#1A2332"),
        cardColor: Color(hex: "#2A3442"),
        textColor: Color(hex: "#F8F4EA"),
        accentColor: AppColors.primary.green
    ))
    .padding()
    .background(Color(hex: "#1A2332"))
}

#Preview("Night Theme") {
    PrayerTimesPreviewCard(theme: Theme(
        name: "Night",
        backgroundColor: .black,
        cardColor: Color(hex: "#1A1A1A"),
        textColor: Color(hex: "#E5E5E5"),
        accentColor: AppColors.primary.gold
    ))
    .padding()
    .background(Color.black)
}

#Preview("Sepia Theme") {
    PrayerTimesPreviewCard(theme: Theme(
        name: "Sepia",
        backgroundColor: Color(hex: "#F4E8D0"),
        cardColor: Color(hex: "#FFF9E6"),
        textColor: Color(hex: "#5D4E37"),
        accentColor: Color(hex: "#C7A566")
    ))
    .padding()
    .background(Color(hex: "#F4E8D0"))
}
