//
//  IslamicCalendarView.swift
//  QuranNoor
//
//  Main view for Islamic (Hijri) calendar and important dates
//

import SwiftUI

struct IslamicCalendarView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var calendarService = IslamicCalendarService()
    @State private var selectedEvent: IslamicEvent?
    @State private var showingEventDetail = false
    @State private var showingRamadanTracker = false
    @State private var searchText = ""
    @State private var selectedFilter: EventCategory?

    private var currentHijriDate: HijriDate {
        calendarService.convertToHijri()
    }

    private var filteredEvents: [IslamicEvent] {
        var events = calendarService.getAllEvents()

        // Apply category filter
        if let category = selectedFilter {
            events = calendarService.getEvents(for: category)
        }

        // Apply search filter
        if !searchText.isEmpty {
            events = calendarService.searchEvents(query: searchText)
        }

        return events
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Hijri Date Card
                    currentDateCard

                    // Ramadan Tracker Button (if in Ramadan)
                    if calendarService.isRamadan() {
                        ramadanTrackerButton
                    }

                    // Upcoming Events
                    upcomingEventsSection

                    // Category Filter
                    categoryFilterSection

                    // Events List
                    eventsListSection
                }
                .padding()
            }
            .navigationTitle("Islamic Calendar")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search events...")
            .sheet(isPresented: $showingEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(event: event, calendarService: calendarService)
                }
            }
            .sheet(isPresented: $showingRamadanTracker) {
                RamadanTrackerView(calendarService: calendarService)
            }
        }
    }

    // MARK: - Current Date Card

    private var currentDateCard: some View {
        VStack(spacing: 16) {
            // Gregorian Date
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Hijri Date (Large)
            VStack(spacing: 8) {
                Text(currentHijriDate.formattedArabic)
                    .font(.system(size: 32, weight: .bold))

                Text(currentHijriDate.formatted)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Current Month Info
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: calendarService.getCurrentHijriMonth().isSacred ? "star.fill" : "calendar")
                        .foregroundStyle(calendarService.getCurrentHijriMonth().isSacred ? .yellow : themeManager.currentTheme.featureAccent)

                    Text(calendarService.getCurrentHijriMonth().isSacred ? "Sacred Month" : "Islamic Month")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Text(calendarService.getCurrentHijriMonth().significance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    .linearGradient(
                        colors: [.green.opacity(0.1), .teal.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(calendarService.getCurrentHijriMonth().isSacred ? .yellow : .green, lineWidth: 2)
        )
    }

    // MARK: - Ramadan Tracker Button

    private var ramadanTrackerButton: some View {
        Button {
            showingRamadanTracker = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            .linearGradient(
                                colors: [themeManager.currentTheme.featureAccentSecondary, themeManager.currentTheme.featureAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ramadan Tracker")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Track your fasting and Qiyam")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Upcoming Events Section

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Events")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.horizontal, 4)

            let upcomingEvents = calendarService.getUpcomingEvents(limit: 5)

            if upcomingEvents.isEmpty {
                Text("No upcoming events in the next 30 days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            } else {
                ForEach(upcomingEvents) { event in
                    UpcomingEventCard(event: event, calendarService: calendarService) {
                        selectedEvent = event
                        showingEventDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Category Filter Section

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Categories
                CategoryFilterChip(
                    name: "All",
                    icon: "calendar",
                    color: .gray,
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }

                // Individual Categories
                ForEach(EventCategory.allCases) { category in
                    CategoryFilterChip(
                        name: category.displayName,
                        icon: category.icon,
                        color: categoryColor(for: category.color),
                        isSelected: selectedFilter == category
                    ) {
                        selectedFilter = category
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Events List Section

    private var eventsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedFilter?.displayName ?? "All Events")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(filteredEvents.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            if filteredEvents.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredEvents) { event in
                        EventCard(event: event, calendarService: calendarService) {
                            selectedEvent = event
                            showingEventDetail = true
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Events Found")
                .font(.headline)

            Text("Try a different search or filter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helper Methods

    private func categoryColor(for colorString: String) -> Color {
        themeManager.currentTheme.categoryColor(for: colorString)
    }
}

// MARK: - Supporting Views

struct UpcomingEventCard: View {
    @Environment(ThemeManager.self) var themeManager
    let event: IslamicEvent
    @Bindable var calendarService: IslamicCalendarService
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: event.category.icon)
                        .foregroundStyle(categoryColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(event.dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }

    private var categoryColor: Color {
        themeManager.currentTheme.categoryColor(for: event.category.color)
    }
}

struct EventCard: View {
    @Environment(ThemeManager.self) var themeManager
    let event: IslamicEvent
    @Bindable var calendarService: IslamicCalendarService
    let onTap: () -> Void

    private var isFavorite: Bool {
        calendarService.isFavorite(eventId: event.id)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: event.category.icon)
                        Text(event.category.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(categoryColor)

                    Spacer()

                    // Favorite button
                    Button {
                        withAnimation {
                            calendarService.toggleFavorite(eventId: event.id)
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Event name
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(event.nameArabic)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Date
                Text(event.dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Description
                Text(event.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Actions preview
                if !event.actions.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(event.actions.prefix(3), id: \.self) { action in
                            Text(action)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(categoryColor.opacity(0.2))
                                )
                                .foregroundStyle(categoryColor)
                        }

                        if event.actions.count > 3 {
                            Text("+\(event.actions.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFavorite ? .red.opacity(0.3) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var categoryColor: Color {
        themeManager.currentTheme.categoryColor(for: event.category.color)
    }
}

struct CategoryFilterChip: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : .clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IslamicCalendarView()
}
