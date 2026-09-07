//
//  ItineraryView.swift
//  travelAid
//

import CoreLocation
import MapKit
import SwiftUI

struct ItineraryView: View {
    let trip: Trip
    let onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Int = 1

    init(trip: Trip, onSave: (() -> Void)? = nil) {
        self.trip = trip
        self.onSave = onSave
    }

    private var orderedDays: [DayPlan] {
        trip.dayPlans.sorted { $0.dayNumber < $1.dayNumber }
    }

    private var currentDay: DayPlan? {
        orderedDays.first { $0.dayNumber == selectedDay }
    }

    private var annotations: [ActivityMapPoint] {
        guard let day = currentDay else { return [] }
        return day.activities.compactMap { activity in
            guard activity.latitude != 0 || activity.longitude != 0 else { return nil }
            return ActivityMapPoint(activity: activity)
        }
    }

    private var totalActivitiesCount: Int {
        trip.dayPlans.reduce(0) { $0 + $1.activities.count }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    heroCard
                    daySelectorCard

                    if let day = currentDay {
                        weatherCard(for: day)
                        activitiesCard(for: day)

                        if !annotations.isEmpty {
                            mapCard(for: day)
                            travelInfoCard(for: day)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close itinerary")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: TripShareFormatter.makeShareText(for: trip)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share trip")
                }

                if onSave != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add to My Trips") {
                            onSave?()
                        }
                    }
                }
            }
        }
        .navigationTitle("Itinerary")
        .onAppear {
            if selectedDay == 1, let first = orderedDays.first?.dayNumber {
                selectedDay = first
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.destination)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(dayDateRangeLabel())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: trip.persona == .luxury ? "sparkles" : trip.persona == .family ? "figure.2.and.child.holdinghands" : "backpack.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(personaTint)
                    .padding(12)
                    .background(personaTint.opacity(0.12), in: Circle())
            }

            HStack(spacing: 10) {
                summaryChip(title: "Days", value: "\(trip.duration)")
                summaryChip(title: "Activities", value: "\(totalActivitiesCount)")
                summaryChip(title: "Budget", value: trip.totalTripCost.formatted(.currency(code: "INR")))
            }

            Text("Plan adjusted for \(trip.persona.rawValue.capitalized) travel style.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.16), Color(.secondarySystemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var daySelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Select day", systemImage: "calendar")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(orderedDays, id: \.dayNumber) { day in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDay = day.dayNumber
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Day \(day.dayNumber)")
                                    .font(.headline)
                                Text(dayDateLabel(for: day))
                                    .font(.caption)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .foregroundStyle(selectedDay == day.dayNumber ? .white : .primary)
                            .background(selectedDay == day.dayNumber ? Color.accentColor : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func weatherCard(for day: DayPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Weather", systemImage: weatherSymbol(for: day.weather.condition))
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                weatherMetric(value: "\(day.weather.temperature)°C", label: "Temp")
                weatherMetric(value: "\(day.weather.precipitationChance)%", label: "Rain")
                weatherMetric(value: "\(day.weather.humidity)%", label: "Humidity")
                weatherMetric(value: day.weather.condition.rawValue.capitalized, label: "Sky")
            }

            Text("\(day.weather.condition.rawValue.capitalized) weather is shaping the activity mix for this day.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func activitiesCard(for day: DayPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day plan")
                        .font(.headline)
                    Text("\(dayDateLabel(for: day)) • \(day.activities.count) stops")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(day.totalDayCost.formatted(.currency(code: "INR")))
                    .font(.headline)
            }

            VStack(spacing: 12) {
                ForEach(day.activities) { activity in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(activity.name)
                                .font(.headline)
                            Spacer()
                            Text(activity.cost.formatted(.currency(code: "INR")))
                                .foregroundStyle(.secondary)
                        }

                        Text(activity.activityDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)

                        HStack(spacing: 8) {
                            activityTag(activity.isIndoor ? "Indoor" : "Outdoor", systemImage: activity.isIndoor ? "house.fill" : "sun.max.fill")
                            activityTag("\(String(format: "%.1f", activity.durationHours))h", systemImage: "clock")
                            if activity.mealType != .none {
                                activityTag(activity.mealType.rawValue.capitalized, systemImage: "fork.knife")
                            }
                        }
                        .font(.caption.weight(.medium))
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func mapCard(for day: DayPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Map", systemImage: "map")
                .font(.headline)

            Map {
                ForEach(annotations) { point in
                    Marker(point.activity.name, coordinate: point.coordinate)
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func travelInfoCard(for day: DayPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Travel info", systemImage: "figure.walk")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(distanceRows(for: day), id: \.self) { row in
                    Text(row)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func weatherMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activityTag(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color(.systemBackground), in: Capsule())
            .overlay {
                Capsule().stroke(.quaternary, lineWidth: 0.8)
            }
    }

    private func weatherSymbol(for condition: WeatherCondition) -> String {
        switch condition {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .hot: return "thermometer.high"
        case .cold: return "thermometer.low"
        }
    }

    private var personaTint: Color {
        switch trip.persona {
        case .backpacker: return .green
        case .luxury: return .purple
        case .family: return .orange
        }
    }

    private func dayDateRangeLabel() -> String {
        guard let lastDay = orderedDays.last else {
            return trip.startDate.formatted(date: .abbreviated, time: .omitted)
        }

        return "\(dayDateLabel(for: orderedDays.first ?? lastDay)) – \(dayDateLabel(for: lastDay))"
    }

    private func distanceRows(for day: DayPlan) -> [String] {
        let activities = day.activities.filter { $0.latitude != 0 || $0.longitude != 0 }
        guard activities.count > 1 else { return [] }

        return zip(activities, activities.dropFirst()).map { first, second in
            let start = CLLocation(latitude: first.latitude, longitude: first.longitude)
            let end = CLLocation(latitude: second.latitude, longitude: second.longitude)
            let meters = start.distance(from: end)
            let km = meters / 1000
            let minutes = Int((km / 4.5) * 60)
            return "\(first.name) -> \(second.name): \(String(format: "%.1f", km)) km • \(max(minutes, 1)) min walk"
        }
    }

    private func dayDateLabel(for day: DayPlan) -> String {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: day.dayNumber - 1, to: trip.startDate) else {
            return trip.startDate.formatted(date: .abbreviated, time: .omitted)
        }

        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct ActivityMapPoint: Identifiable {
    let id = UUID()
    let activity: Activity

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: activity.latitude, longitude: activity.longitude)
    }
}

#Preview {
    ItineraryView(
        trip: Trip(
            destination: "Paris",
            duration: 1,
            dayPlans: [
                DayPlan(
                    dayNumber: 1,
                    activities: [
                        Activity(
                            name: "Louvre Morning Visit",
                            type: .museum,
                            isIndoor: true,
                            rating: 4.9,
                            costLevel: .expensive,
                            description: "Spend the morning with world-class art and iconic exhibits.",
                            durationHours: 3.0,
                            latitude: 48.8606,
                            longitude: 2.3376,
                            address: "Louvre Museum, Paris",
                            mealType: .none,
                            cost: 1200
                        )
                    ],
                    weather: Weather(
                        temperature: 24,
                        condition: .sunny,
                        precipitationChance: 5,
                        humidity: 45
                    )
                )
            ],
            startDate: Date(),
            persona: .backpacker
        )
    )
}
