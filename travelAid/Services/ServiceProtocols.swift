//
//  ServiceProtocols.swift
//  travelAid
//

import Foundation
import CoreLocation

struct Destination {
    let name: String
    let coordinates: CLLocationCoordinate2D
}

protocol LocationService: Sendable {
    func resolvePlace(named name: String) async throws -> Destination
}

protocol WeatherService: Sendable {
    func fetchWeatherForecast(for coordinates: CLLocationCoordinate2D, days: Int) async throws -> [Weather]
}

protocol ItineraryService: Sendable {
    func buildItinerary(destination: Destination, duration: Int, startDate: Date, persona: TravelerPersona, weather: [Weather]) async throws -> Trip
}

protocol AIService: Sendable {
    func enhance(trip: Trip) async throws -> Trip
}
