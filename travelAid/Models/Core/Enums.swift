//
//  Enums.swift
//  travelAid
//

import Foundation

enum TravelerPersona: String, CaseIterable, Codable, Identifiable, Sendable {
    case backpacker
    case luxury
    case family

    var id: String { rawValue }
}

enum ActivityType: String, CaseIterable, Codable, Sendable {
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

enum CostLevel: String, CaseIterable, Codable, Sendable {
    case cheap
    case medium
    case expensive
}

enum MealType: String, Codable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
    case none
}

enum WeatherCondition: String, CaseIterable, Codable, Sendable {
    case sunny
    case cloudy
    case rainy
    case stormy
    case hot
    case cold
}
