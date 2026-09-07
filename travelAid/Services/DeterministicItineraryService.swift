//
//  DeterministicItineraryService.swift
//  travelAid
//

import Foundation
import CoreLocation

/// A simple deterministic itinerary builder for MVP/demo purposes.
/// Produces day-by-day plans, inserts meal placeholders when missing,
/// and orders activities into a readable daily flow so the UI can split
/// morning/afternoon/evening blocks.
struct DeterministicItineraryService: ItineraryService {
    func buildItinerary(
        destination: Destination,
        duration: Int,
        startDate: Date,
        persona: TravelerPersona,
        weather: [Weather]
    ) async throws -> Trip {
        let days = max(duration, 1)

        // Build a small pool of sample activities around the destination.
        let pool = sampleActivities(for: destination, persona: persona)

        var dayPlans: [DayPlan] = []

        for day in 1...days {
            let dayWeather = weather.indices.contains(day - 1) ? weather[day - 1] : Weather(temperature: 24, condition: .sunny, precipitationChance: 5, humidity: 45)

            // Simple scoring: prefer indoor on rainy/stormy, outdoor otherwise; prefer persona-suitable activities
            let sorted = pool.sorted { a, b in
                score(activity: a, for: persona, weather: dayWeather) > score(activity: b, for: persona, weather: dayWeather)
            }

            // Select top N candidates while ensuring variety
            var selected: [Activity] = []
            var usedNames = Set<String>()

            for candidate in sorted {
                if selected.count >= 5 { break }
                if usedNames.contains(candidate.name) { continue }
                selected.append(candidate)
                usedNames.insert(candidate.name)
            }

            // Ensure meals: breakfast, lunch, dinner, at least one snack
            ensureMeals(in: &selected, persona: persona)

            // Order activities into a readable flow: breakfast -> morning -> snack -> lunch -> afternoon -> dinner -> evening
            let ordered = orderDailyActivities(selected)

            let dayPlan = DayPlan(dayNumber: day, activities: ordered, weather: dayWeather)
            dayPlans.append(dayPlan)
        }

        return Trip(destination: destination.name, duration: duration, dayPlans: dayPlans, startDate: startDate, persona: persona)
    }

    // MARK: - Helpers

    private func score(activity: Activity, for persona: TravelerPersona, weather: Weather) -> Double {
        var s = activity.rating

        // persona preference: simple mapping
        switch persona {
        case .backpacker:
            if activity.costLevel == .cheap { s += 1.0 }
            if activity.type == .localExperience || activity.type == .market { s += 0.5 }
        case .luxury:
            if activity.costLevel == .expensive { s += 1.0 }
            if activity.type == .gallery || activity.type == .theater { s += 0.5 }
        case .family:
            if activity.type == .park || activity.type == .museum { s += 1.0 }
        }

        // weather adjustments
        switch weather.condition {
        case .rainy, .stormy:
            if activity.isIndoor {
                s += 1.2
            } else {
                s -= 2.0
            }
        case .hot:
            if !activity.isIndoor && activity.durationHours > 3.0 { s -= 1.0 }
            if activity.isIndoor { s += 0.5 }
        case .cold:
            if !activity.isIndoor { s -= 0.8 }
        default:
            break
        }

        // small cost preference
        switch persona {
        case .backpacker:
            if activity.costLevel == .cheap { s += 0.3 }
        case .luxury:
            if activity.costLevel == .expensive { s += 0.3 }
        default: break
        }

        return s
    }

    private func ensureMeals(in activities: inout [Activity], persona: TravelerPersona) {
        // Collect existing meal types
        var hasBreakfast = activities.contains { $0.mealType == .breakfast }
        var hasLunch = activities.contains { $0.mealType == .lunch }
        var hasDinner = activities.contains { $0.mealType == .dinner }
        var hasSnack = activities.contains { $0.mealType == .snack }

        if !hasBreakfast {
            activities.insert(mealPlaceholder(.breakfast, persona: persona), at: 0)
            hasBreakfast = true
        }

        if !hasLunch {
            // insert roughly middle
            let mid = max(1, activities.count / 2)
            activities.insert(mealPlaceholder(.lunch, persona: persona), at: mid)
            hasLunch = true
        }

        if !hasDinner {
            activities.append(mealPlaceholder(.dinner, persona: persona))
            hasDinner = true
        }

        if !hasSnack {
            // add snack between breakfast and lunch if possible
            let insertIndex = min(activities.count, 2)
            activities.insert(mealPlaceholder(.snack, persona: persona), at: insertIndex)
            hasSnack = true
        }
    }

    private func mealPlaceholder(_ meal: MealType, persona: TravelerPersona) -> Activity {
        let (name, cost, isIndoor): (String, Double, Bool) = {
            switch meal {
            case .breakfast:
                return ("Breakfast", mealCost(.breakfast, for: persona), true)
            case .lunch:
                return ("Lunch", mealCost(.lunch, for: persona), true)
            case .dinner:
                return ("Dinner", mealCost(.dinner, for: persona), true)
            case .snack:
                return ("Snack", mealCost(.snack, for: persona), false)
            case .none:
                return ("Meal", 0, true)
            }
        }()

        return Activity(
            name: name,
            type: .restaurant,
            isIndoor: isIndoor,
            rating: 4.0,
            costLevel: .medium,
            description: "Placeholder meal suggestion",
            durationHours: meal == .snack ? 0.25 : 0.75,
            latitude: 0,
            longitude: 0,
            address: "",
            mealType: meal,
            cost: cost
        )
    }

    private func mealCost(_ meal: MealType, for persona: TravelerPersona) -> Double {
        // Values interpreted as INR
        switch persona {
        case .backpacker:
            switch meal {
            case .breakfast: return 120
            case .lunch: return 220
            case .dinner: return 320
            case .snack: return 90
            case .none: return 0
            }
        case .family:
            switch meal {
            case .breakfast: return 300
            case .lunch: return 650
            case .dinner: return 950
            case .snack: return 180
            case .none: return 0
            }
        case .luxury:
            switch meal {
            case .breakfast: return 900
            case .lunch: return 1700
            case .dinner: return 2800
            case .snack: return 450
            case .none: return 0
            }
        }
    }

    private func orderDailyActivities(_ activities: [Activity]) -> [Activity] {
        // Aim to place breakfast before lunch before dinner
        var breakfast: [Activity] = activities.filter { $0.mealType == .breakfast }
        var lunch: [Activity] = activities.filter { $0.mealType == .lunch }
        var dinner: [Activity] = activities.filter { $0.mealType == .dinner }
        var snacks: [Activity] = activities.filter { $0.mealType == .snack }
        var others: [Activity] = activities.filter { $0.mealType == .none }

        // simple ordering: breakfast, some others, snack, lunch, others, dinner, evening others
        var ordered: [Activity] = []
        ordered.append(contentsOf: breakfast)

        // put first half of others as morning
        let half = others.count / 2
        if half > 0 { ordered.append(contentsOf: others.prefix(half)) }

        ordered.append(contentsOf: snacks)
        ordered.append(contentsOf: lunch)

        if others.count > half { ordered.append(contentsOf: others.suffix(from: half)) }

        ordered.append(contentsOf: dinner)

        // ensure uniqueness while preserving order
        var seen = Set<String>()
        let unique = ordered.filter { act in
            if seen.contains(act.name) { return false }
            seen.insert(act.name)
            return true
        }

        return unique
    }

    // Build a small sample pool — in production this would come from real POI data
    private func sampleActivities(for destination: Destination, persona: TravelerPersona) -> [Activity] {
        let lat = destination.coordinates.latitude
        let lon = destination.coordinates.longitude

        // A small variety of activities
        return [
            Activity(name: "City Museum", type: .museum, isIndoor: true, rating: 4.6, costLevel: .medium, description: "A highlight museum.", durationHours: 2.0, latitude: lat + 0.01, longitude: lon + 0.01, address: destination.name, mealType: .none, cost: 400),
            Activity(name: "Historic Market", type: .market, isIndoor: false, rating: 4.4, costLevel: .cheap, description: "Local market with food stalls.", durationHours: 2.5, latitude: lat - 0.008, longitude: lon + 0.015, address: destination.name, mealType: .none, cost: 180),
            Activity(name: "Scenic Park", type: .park, isIndoor: false, rating: 4.5, costLevel: .cheap, description: "Relaxing park.", durationHours: 1.5, latitude: lat + 0.012, longitude: lon - 0.01, address: destination.name, mealType: .none, cost: 0),
            Activity(name: "Local Cafe", type: .cafe, isIndoor: true, rating: 4.3, costLevel: .medium, description: "Cozy cafe for coffee and snacks.", durationHours: 1.0, latitude: lat - 0.004, longitude: lon - 0.012, address: destination.name, mealType: .snack, cost: 180),
            Activity(name: "Famous Gallery", type: .gallery, isIndoor: true, rating: 4.8, costLevel: .expensive, description: "Top-tier gallery.", durationHours: 2.5, latitude: lat + 0.007, longitude: lon + 0.018, address: destination.name, mealType: .none, cost: 1200),
            Activity(name: "Riverside Walk", type: .hiking, isIndoor: false, rating: 4.2, costLevel: .cheap, description: "Scenic walking stretch by the river.", durationHours: 1.8, latitude: lat - 0.011, longitude: lon + 0.006, address: destination.name, mealType: .none, cost: 0),
            Activity(name: "Evening Theater", type: .theater, isIndoor: true, rating: 4.7, costLevel: .expensive, description: "A highly rated evening performance.", durationHours: 2.2, latitude: lat + 0.003, longitude: lon - 0.017, address: destination.name, mealType: .none, cost: 2200),
        ]
    }
}
