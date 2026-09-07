//
//  DayPlan.swift
//  travelAid
//

import Foundation
import SwiftData

@Model final class DayPlan {
    var dayNumber: Int
    var activities: [Activity]
    var weather: Weather

    var totalDayCost: Double {
        activities.reduce(0) { $0 + $1.cost }
    }

    init(dayNumber: Int, activities: [Activity] = [], weather: Weather) {
        self.dayNumber = dayNumber
        self.activities = activities
        self.weather = weather
    }
}
