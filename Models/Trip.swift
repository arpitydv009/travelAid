//
//  Trip.swift
//  travelAid
//

import SwiftUI
import SwiftData

@Model final class Trip {
    var destination: String
    var duration: Int
    var dayPlans: [DayPlan]
    var startDate: Date
    var persona: TravelerPersona

    var totalTripCost: Double {
        dayPlans.reduce(0) { $0 + $1.totalDayCost }
    }

    init(
        destination: String,
        duration: Int,
        dayPlans: [DayPlan] = [],
        startDate: Date,
        persona: TravelerPersona
    ) {
        self.destination = destination
        self.duration = duration
        self.dayPlans = dayPlans
        self.startDate = startDate
        self.persona = persona
    }
}
