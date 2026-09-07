//
//  TripShareFormatter.swift
//  travelAid
//

import Foundation

enum TripShareFormatter {
    static func makeShareText(for trip: Trip) -> String {
        var lines: [String] = []
        lines.append("TravelAid Itinerary")
        lines.append("Destination: \(trip.destination)")
        lines.append("Start date: \(trip.startDate.formatted(date: .long, time: .omitted))")
        lines.append("Duration: \(trip.duration) \(trip.duration == 1 ? "day" : "days")")
        lines.append("Persona: \(trip.persona.rawValue.capitalized)")
        lines.append("Estimated Total: \(trip.totalTripCost.formatted(.currency(code: "INR")))")
        lines.append("")

        for day in trip.dayPlans.sorted(by: { $0.dayNumber < $1.dayNumber }) {
            lines.append("Day \(day.dayNumber) - \(day.weather.condition.rawValue.capitalized), \(day.weather.temperature)C")
            for activity in day.activities {
                let hours = String(format: "%.1f", activity.durationHours)
                lines.append("- \(activity.name) (\(hours)h, \(activity.cost.formatted(.currency(code: "INR"))))")
            }
            lines.append("Day total: \(day.totalDayCost.formatted(.currency(code: "INR")))")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
