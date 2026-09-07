//
//  MapKitLocationService.swift
//  travelAid
//

import Combine
import Foundation
import MapKit

struct MapKitLocationService: LocationService {
    func resolvePlace(named name: String) async throws -> Destination {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name
        request.resultTypes = .address

        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw NSError(domain: "LocationService", code: 404)
        }

        let title = item.placemark.locality ?? item.name ?? name
        return Destination(name: title, coordinates: item.placemark.coordinate)
    }
}

@MainActor
final class DestinationAutocompleteService: NSObject, ObservableObject {
    @Published private(set) var suggestions: [String] = []

    private lazy var completer = MKLocalSearchCompleter()
    private var debounceTask: Task<Void, Never>?
    private var lastSubmittedQuery: String = ""

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            debounceTask?.cancel()
            suggestions = []
            completer.queryFragment = ""
            lastSubmittedQuery = ""
            return
        }

        guard normalized.count >= 2 else {
            debounceTask?.cancel()
            suggestions = []
            completer.queryFragment = ""
            lastSubmittedQuery = normalized
            return
        }

        guard normalized != lastSubmittedQuery else { return }

        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                self.lastSubmittedQuery = normalized
                self.completer.queryFragment = normalized
            }
        }
    }

    func clear() {
        debounceTask?.cancel()
        suggestions = []
        completer.queryFragment = ""
        lastSubmittedQuery = ""
    }
}

extension DestinationAutocompleteService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.prefix(6).map { result in
            let subtitle = result.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if subtitle.isEmpty {
                return result.title
            }
            return "\(result.title), \(subtitle)"
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
