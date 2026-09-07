//
//  Weather.swift
//  travelAid
//

import SwiftUI

struct Weather: Codable {
    let temperature: Int
    let condition: WeatherCondition
    let precipitationChance: Int
    let humidity: Int
}
