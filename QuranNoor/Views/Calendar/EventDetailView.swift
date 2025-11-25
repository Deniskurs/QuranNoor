//
//  EventDetailView.swift
//  QuranNoor
//
//  Detail view for individual Islamic event
//

import SwiftUI

struct EventDetailView: View {
    @Environment(ThemeManager.self) var themeManager
    let event: IslamicEvent
    @Bindable var calendarService: IslamicCalendarService

    @Environment(\.dismiss) private var dismiss

    private var isFavorite: Bool {
        calendarService.isFavorite(eventId: event.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Badge
                    categoryBadge

                    // Event Name
                    eventNameSection

                    // Date
                    dateSection

                    // Description
                    descriptionSection

                    // Significance
                    significanceSection

                    // Recommended Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            calendarService.toggleFavorite(eventId: event.id)
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .primary)
                    }
                }
            }
        }
    }

    // MARK: - Category Badge

    private var categoryBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: event.category.icon)
                .foregroundStyle(categoryColor)

            Text(event.category.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(categoryColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(categoryColor.opacity(0.1))
        )
    }

    // MARK: - Event Name Section

    private var eventNameSection: some View {
        VStack(spacing: 12) {
            Text(event.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(event.nameArabic)
                .font(.system(size: 28))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(categoryColor)
                Text("Date")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Hijri:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(event.dateStringArabic)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("English:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(event.dateString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                if event.isAnnual {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundStyle(.green)
                        Text("Occurs annually")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(categoryColor.opacity(0.1))
        )
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(themeManager.currentTheme.featureAccent)
                Text("Description")
                    .font(.headline)
                Spacer()
            }

            Text(event.description)
                .font(.body)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.featureBackgroundTint)
        )
    }

    // MARK: - Significance Section

    private var significanceSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Significance")
                    .font(.headline)
                Spacer()
            }

            Text(event.significance)
                .font(.body)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.yellow.opacity(0.1))
        )
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.green)
                Text("Recommended Actions")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(Array(event.actions.enumerated()), id: \.offset) { index, action in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.2))
                                .frame(width: 30, height: 30)

                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(categoryColor)
                        }

                        Text(action)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Share Button
            Button {
                shareEvent()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Event")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            .linearGradient(
                                colors: [categoryColor, categoryColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.green.opacity(0.1))
        )
    }

    // MARK: - Helper Properties

    private var categoryColor: Color {
        themeManager.currentTheme.categoryColor(for: event.category.color)
    }

    // MARK: - Actions

    private func shareEvent() {
        var text = """
        \(event.name)
        \(event.nameArabic)

        Date: \(event.dateString)

        \(event.description)

        Significance: \(event.significance)

        Recommended Actions:
        """

        for (index, action) in event.actions.enumerated() {
            text += "\n\(index + 1). \(action)"
        }

        text += "\n\n#IslamicCalendar #\(event.name.replacingOccurrences(of: " ", with: ""))"

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    EventDetailView(
        event: IslamicEvent(
            name: "Eid al-Fitr",
            nameArabic: "عِيد ٱلْفِطْر",
            day: 1,
            month: .shawwal,
            category: .eid,
            description: "Festival of Breaking the Fast",
            significance: "Celebrates the completion of Ramadan fasting. Muslims pray Eid prayer, give Zakat al-Fitr, and celebrate with family and community.",
            actions: ["Pray Eid prayer", "Give Zakat al-Fitr", "Visit family and friends", "Wear best clothes"]
        ),
        calendarService: IslamicCalendarService()
    )
}
