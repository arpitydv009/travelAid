//
//  HomeViewModel.swift
//  travelAid
//

import Combine
import Foundation

@MainActor
final class HomeViewModel: HomeViewModelProtocol, ObservableObject {
    @Published var destination: String
    @Published var duration: Int
    @Published var startDate: Date
    @Published var persona: TravelerPersona
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var progressText: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var generatedTrip: Trip?

    private let locationService: LocationService
    private let weatherService: WeatherService
    private let itineraryService: ItineraryService
    private let aiService: AIService?
    private var generationTask: Task<Void, Never>?

    var canGenerate: Bool {
        !normalizedDestination.isEmpty && !isGenerating
    }

    init(
        destination: String = "",
        duration: Int = 5,
        startDate: Date = .now,
        persona: TravelerPersona = .backpacker,
        locationService: LocationService,
        weatherService: WeatherService,
        itineraryService: ItineraryService,
        aiService: AIService? = nil
    ) {
        self.destination = destination
        self.duration = duration
        self.startDate = startDate
        self.persona = persona
        self.locationService = locationService
        self.weatherService = weatherService
        self.itineraryService = itineraryService
        self.aiService = aiService
    }

    deinit {
        generationTask?.cancel()
    }

    func generateTrip() {
        let query = normalizedDestination

        guard !query.isEmpty else {
            errorMessage = "Enter a destination city to continue."
            return
        }

        guard duration >= 1 else {
            errorMessage = "Trip duration must be at least 1 day."
            return
        }

        generationTask?.cancel()
        isGenerating = true
        progressText = "Resolving destination..."
        errorMessage = nil
        generatedTrip = nil

        let requestedDuration = duration
        let requestedStartDate = startDate
        let requestedPersona = persona

        generationTask = Task { [weak self] in
            guard let self else { return }

            do {
                let destination = try await resolveDestination(named: query)
                guard !Task.isCancelled else {
                    finishCancelledGeneration()
                    return
                }

                progressText = "Checking the weather..."
                let weather = await fetchWeather(
                    for: destination,
                    days: requestedDuration
                )
                guard !Task.isCancelled else {
                    finishCancelledGeneration()
                    return
                }

                progressText = "Building the itinerary..."
                let basicTrip = try await buildItinerary(
                    destination: destination,
                    duration: requestedDuration,
                    startDate: requestedStartDate,
                    persona: requestedPersona,
                    weather: weather
                )
                guard !Task.isCancelled else {
                    finishCancelledGeneration()
                    return
                }

                let finalTrip = await enhanceTripIfPossible(basicTrip)
                guard !Task.isCancelled else {
                    finishCancelledGeneration()
                    return
                }

                generatedTrip = finalTrip
                finishGeneration()
            } catch is CancellationError {
                finishCancelledGeneration()
            } catch let error as HomeViewModelError {
                errorMessage = error.userMessage
                finishGeneration()
            } catch {
                errorMessage = userMessage(for: error)
                finishGeneration()
            }
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        finishCancelledGeneration()
    }

    func clearError() {
        errorMessage = nil
    }

    func clearGeneratedTrip() {
        generatedTrip = nil
    }

    func reset() {
        cancelGeneration()
        destination = ""
        duration = 5
        persona = .backpacker
        errorMessage = nil
        generatedTrip = nil
    }

    private var normalizedDestination: String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolveDestination(named name: String) async throws -> Destination {
        do {
            return try await withTimeout(seconds: 5) {
                try await self.locationService.resolvePlace(named: name)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw HomeViewModelError.locationFailed(name)
        }
    }

    private func fetchWeather(for destination: Destination, days: Int) async -> [Weather] {
        do {
            return try await withTimeout(seconds: 5) {
                try await self.weatherService.fetchWeatherForecast(
                    for: destination.coordinates,
                    days: days
                )
            }
        } catch is CancellationError {
            return defaultWeatherForecast(days: days)
        } catch {
            errorMessage = "Weather unavailable; continuing with defaults."
            return defaultWeatherForecast(days: days)
        }
    }

    private func buildItinerary(
        destination: Destination,
        duration: Int,
        startDate: Date,
        persona: TravelerPersona,
        weather: [Weather]
    ) async throws -> Trip {
        do {
            return try await withTimeout(seconds: 8) {
                try await self.itineraryService.buildItinerary(
                    destination: destination,
                    duration: duration,
                    startDate: startDate,
                    persona: persona,
                    weather: weather
                )
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw HomeViewModelError.itineraryFailed
        }
    }

    private func enhanceTripIfPossible(_ trip: Trip) async -> Trip {
        guard let aiService else { return trip }

        progressText = "Personalizing recommendations..."

        do {
            return try await withTimeout(seconds: 4) {
                try await aiService.enhance(trip: trip)
            }
        } catch {
            print("AI enhancement failed: \(error.localizedDescription)")
            return trip
        }
    }

    private func finishGeneration() {
        isGenerating = false
        progressText = nil
        generationTask = nil
    }

    private func finishCancelledGeneration() {
        isGenerating = false
        progressText = nil
        generationTask = nil
    }

    private func defaultWeatherForecast(days: Int) -> [Weather] {
        let forecastDays = max(days, 1)

        return Array(
            repeating: Weather(
                temperature: 22,
                condition: .cloudy,
                precipitationChance: 0,
                humidity: 50
            ),
            count: forecastDays
        )
    }

    private func userMessage(for error: Error) -> String {
        if error is CancellationError {
            return "Trip generation was cancelled."
        }

        return "Something went wrong while planning your trip. Please try again."
    }

    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                let nanoseconds = UInt64(seconds * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
                throw HomeViewModelError.timeout
            }

            guard let result = try await group.next() else {
                throw HomeViewModelError.timeout
            }

            group.cancelAll()
            return result
        }
    }
}

private enum HomeViewModelError: Error {
    case timeout
    case locationFailed(String)
    case itineraryFailed

    var userMessage: String {
        switch self {
        case .timeout:
            "The request took too long. Please try again."
        case .locationFailed(let destination):
            "Couldn't locate \(destination). Try a different query."
        case .itineraryFailed:
            "Unable to build itinerary right now."
        }
    }
}
