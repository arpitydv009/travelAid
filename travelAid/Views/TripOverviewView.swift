//
//  TripOverviewView.swift
//  travelAid
//

// Development helper view for testing the generated trip handoff.

import SwiftUI

struct TripOverviewView: View {
    let trip: Trip
    let onSave: (() -> Void)?
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Destination", value: trip.destination)
                    LabeledContent("Start date", value: trip.startDate.formatted(date: .long, time: .omitted))
                    LabeledContent("Duration", value: "\(trip.duration) \(trip.duration == 1 ? "day" : "days")")
                    LabeledContent("Persona", value: trip.persona.rawValue.capitalized)
                    LabeledContent("Estimated cost", value: trip.totalTripCost.formatted(.currency(code: "INR")))
                    LabeledContent("Total activities", value: "\(trip.dayPlans.reduce(0) { $0 + $1.activities.count })")
                }

                if let firstWeather = trip.dayPlans.sorted(by: { $0.dayNumber < $1.dayNumber }).first?.weather {
                    Section("Weather Context") {
                        Label("\(firstWeather.condition.rawValue.capitalized)", systemImage: weatherSymbol(for: firstWeather.condition))
                        Text("Plan adjusted for \(firstWeather.condition.rawValue).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Day Plans") {
                    ForEach(trip.dayPlans.sorted { $0.dayNumber < $1.dayNumber }) { dayPlan in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Day \(dayPlan.dayNumber)")
                                .font(.headline)

                            Text(dayDate(for: dayPlan))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(dayPlan.weather.condition.rawValue.capitalized) • \(dayPlan.weather.temperature)°C")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(dayPlan.activities) { activity in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(activity.name)
                                    Spacer()
                                    Text(activity.cost.formatted(.currency(code: "INR")))
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }

                            Text("Day total: \(dayPlan.totalDayCost.formatted(.currency(code: "INR")))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    NavigationLink {
                        ItineraryView(trip: trip)
                    } label: {
                        Label("View Itinerary", systemImage: "list.bullet.rectangle")
                    }
                }
            }
            .navigationTitle("Trip Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: TripShareFormatter.makeShareText(for: trip)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to My Trips") {
                        onSave?()
                        onDone()
                    }
                }
            }
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

    private func dayDate(for dayPlan: DayPlan) -> String {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: dayPlan.dayNumber - 1, to: trip.startDate) else {
            return trip.startDate.formatted(date: .abbreviated, time: .omitted)
        }

        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    TripOverviewView(
        trip: Trip(
            destination: "Paris",
            duration: 1,
            dayPlans: [
                DayPlan(
                    dayNumber: 1,
                    activities: [
                        Activity(
                            name: "Local Walking Route",
                            type: .localExperience,
                            isIndoor: false,
                            rating: 4.7,
                            costLevel: .cheap,
                            description: "A preview activity.",
                            durationHours: 2.5,
                            latitude: 48.8566,
                            longitude: 2.3522,
                            address: "Paris",
                            mealType: .none,
                            cost: 15
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
        ),
        onSave: nil,
        onDone: {}
    )
}
