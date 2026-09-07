//
//  Enums.swift
//  travelAid
//

import SwiftUI

enum TravelerPersona: String, CaseIterable, Codable, Identifiable {
    case backpacker
    case luxury
    case family

    var id: String { rawValue }
}

enum ActivityType: String, CaseIterable, Codable {
    case museum
    case restaurant
    case park
    case beach
    case nightlife
    case temple
    case cafe
    case shopping
    case hiking
    case adventure
    case gallery
    case market
    case theater
    case historicalSite
    case viewpoint
    case localExperience
}

enum CostLevel: String, CaseIterable, Codable {
    case cheap
    case medium
    case expensive
}

enum MealType: String, Codable {
    case breakfast
    case lunch
    case dinner
    case snack
    case none
}

enum WeatherCondition: String, CaseIterable, Codable {
    case sunny
    case cloudy
    case rainy
    case stormy
    case hot
    case cold
}
