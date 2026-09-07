//
//  Weather.swift
//  travelAid
//

import Foundation

struct Weather: Codable, Sendable {
    let temperature: Int
    let condition: WeatherCondition
    let precipitationChance: Int
    let humidity: Int
}
