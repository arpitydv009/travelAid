//
//  HomeViewModelProtocol.swift
//  travelAid
//

import Combine

@MainActor
protocol HomeViewModelProtocol: ObservableObject {
    var destination: String { get set }
    var duration: Int { get set }
    var persona: TravelerPersona { get set }
    var isGenerating: Bool { get }
    var progressText: String? { get }
    var errorMessage: String? { get }
    var generatedTrip: Trip? { get }
    var canGenerate: Bool { get }

    func generateTrip()
    func cancelGeneration()
    func reset()
}
