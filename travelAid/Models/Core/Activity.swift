//
//  Activity.swift
//  travelAid
//

import Foundation
import SwiftData

@Model final class Activity {
    var name: String
    var type: ActivityType
    var isIndoor: Bool
    var rating: Double
    var costLevel: CostLevel
    var activityDescription: String
    var durationHours: Double
    var latitude: Double
    var longitude: Double
    var address: String
    var mealType: MealType
    var cost: Double

    init(
        name: String,
        type: ActivityType,
        isIndoor: Bool,
        rating: Double,
        costLevel: CostLevel,
        description: String,
        durationHours: Double,
        latitude: Double,
        longitude: Double,
        address: String,
        mealType: MealType,
        cost: Double
    ) {
        self.name = name
        self.type = type
        self.isIndoor = isIndoor
        self.rating = rating
        self.costLevel = costLevel
        self.activityDescription = description
        self.durationHours = durationHours
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.mealType = mealType
        self.cost = cost
    }
}
