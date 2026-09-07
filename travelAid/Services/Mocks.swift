//
//  Mocks.swift
//  travelAid
//

// DEV MOCKS — Replace with real services before production.

import CoreLocation
import Foundation

struct MockLocationService: LocationService {
    func resolvePlace(named name: String) async throws -> Destination {
        Destination(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            coordinates: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        )
    }
}

struct MockWeatherService: WeatherService {
    func fetchWeatherForecast(for coordinates: CLLocationCoordinate2D, days: Int) async throws -> [Weather] {
        Array(
            repeating: Weather(
                temperature: 24,
                condition: .sunny,
                precipitationChance: 5,
                humidity: 45
            ),
            count: max(days, 1)
        )
    }
}

struct MockItineraryService: ItineraryService {
    func buildItinerary(
        destination: Destination,
        duration: Int,
        persona: TravelerPersona,
        weather: [Weather]
    ) async throws -> Trip {
        let dayPlans = (1...max(duration, 1)).map { dayNumber in
            let activity = Activity(
                name: sampleActivityName(for: persona, dayNumber: dayNumber),
                type: sampleActivityType(for: persona),
                isIndoor: false,
                rating: 4.7,
                costLevel: sampleCostLevel(for: persona),
                description: "A development-only sample activity for testing the trip flow.",
                durationHours: 2.5,
                latitude: destination.coordinates.latitude,
                longitude: destination.coordinates.longitude,
                address: destination.name,
                mealType: .none,
                cost: sampleCost(for: persona)
            )

            return DayPlan(
                dayNumber: dayNumber,
                activities: [activity],
                weather: weather.indices.contains(dayNumber - 1) ? weather[dayNumber - 1] : defaultWeather
            )
        }

        return Trip(
            destination: destination.name,
            duration: duration,
            dayPlans: dayPlans,
            startDate: Date(),
            persona: persona
        )
    }

    private var defaultWeather: Weather {
        Weather(
            temperature: 24,
            condition: .sunny,
            precipitationChance: 5,
            humidity: 45
        )
    }

    private func sampleActivityName(for persona: TravelerPersona, dayNumber: Int) -> String {
        switch persona {
        case .backpacker:
            "Local Walking Route Day \(dayNumber)"
        case .luxury:
            "Curated City Experience Day \(dayNumber)"
        case .family:
            "Family-Friendly Highlight Day \(dayNumber)"
        }
    }

    private func sampleActivityType(for persona: TravelerPersona) -> ActivityType {
        switch persona {
        case .backpacker:
            .localExperience
        case .luxury:
            .gallery
        case .family:
            .park
        }
    }

    private func sampleCostLevel(for persona: TravelerPersona) -> CostLevel {
        switch persona {
        case .backpacker:
            .cheap
        case .luxury:
            .expensive
        case .family:
            .medium
        }
    }

    private func sampleCost(for persona: TravelerPersona) -> Double {
        switch persona {
        case .backpacker:
            15
        case .luxury:
            120
        case .family:
            45
        }
    }
}
