//
//  OpenMeteoWeatherService.swift
//  travelAid
//

import CoreLocation
import Foundation

struct OpenMeteoWeatherService: WeatherService {
    func fetchWeatherForecast(for coordinates: CLLocationCoordinate2D, days: Int) async throws -> [Weather] {
        let safeDays = min(max(days, 1), 14)
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinates.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinates.longitude)),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,relative_humidity_2m_mean"),
            URLQueryItem(name: "forecast_days", value: String(safeDays)),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
        let daily = decoded.daily
        let count = min(
            daily.weatherCode.count,
            daily.temperatureMax.count,
            daily.temperatureMin.count,
            daily.precipitationProbabilityMax.count,
            daily.humidityMean.count
        )

        guard count > 0 else {
            throw URLError(.cannotParseResponse)
        }

        return (0..<count).map { index in
            let avgTemp = Int(((daily.temperatureMax[index] + daily.temperatureMin[index]) / 2.0).rounded())
            let baseCondition = mapCondition(weatherCode: daily.weatherCode[index])
            let condition: WeatherCondition
            if avgTemp >= 34 {
                condition = .hot
            } else if avgTemp <= 10 {
                condition = .cold
            } else {
                condition = baseCondition
            }

            return Weather(
                temperature: avgTemp,
                condition: condition,
                precipitationChance: Int(daily.precipitationProbabilityMax[index].rounded()),
                humidity: Int(daily.humidityMean[index].rounded())
            )
        }
    }

    private func mapCondition(weatherCode: Int) -> WeatherCondition {
        switch weatherCode {
        case 0, 1:
            return .sunny
        case 2, 3, 45, 48:
            return .cloudy
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return .rainy
        case 95, 96, 99:
            return .stormy
        case 71, 73, 75, 77, 85, 86:
            return .cold
        default:
            return .cloudy
        }
    }
}

private struct OpenMeteoForecastResponse: Decodable {
    let daily: Daily

    struct Daily: Decodable {
        let weatherCode: [Int]
        let temperatureMax: [Double]
        let temperatureMin: [Double]
        let precipitationProbabilityMax: [Double]
        let humidityMean: [Double]

        enum CodingKeys: String, CodingKey {
            case weatherCode = "weather_code"
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case humidityMean = "relative_humidity_2m_mean"
        }
    }
}
