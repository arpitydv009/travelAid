//
//  ContentView.swift
//  travelAid
//
//  Created by arpit on 29/08/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

private struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel(
        locationService: MapKitLocationService(),
        weatherService: OpenMeteoWeatherService(),
        itineraryService: DeterministicItineraryService(),
        aiService: nil
    )
    @StateObject private var autocomplete = DestinationAutocompleteService()

    @State private var showSavedTrips = false
    @FocusState private var destinationFieldFocused: Bool

    private var canGenerateTrip: Bool { viewModel.canGenerate }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    destinationSection
                    durationSection
                    startDateSection
                    personaSection
                    generateButton
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSavedTrips = true }) {
                        Image(systemName: "tray.full")
                    }
                    .accessibilityLabel("My Trips")
                }
            }
            .overlay {
                if viewModel.isGenerating {
                    ProgressView(viewModel.progressText ?? "Planning your trip...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                        .onTapGesture {
                            // allow tap to cancel for dev convenience
                            viewModel.cancelGeneration()
                        }
                }
            }
            .sheet(isPresented: $showSavedTrips) {
                MyTripsView()
            }
            .alert(
                "Trip generation issue",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.clearError() } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(
                isPresented: Binding(
                    get: { viewModel.generatedTrip != nil },
                    set: { newValue in if !newValue { viewModel.clearGeneratedTrip() } }
                ),
                content: {
                    if let trip = viewModel.generatedTrip {
                        ItineraryView(
                            trip: trip,
                            onSave: {
                                Task {
                                    do {
                                        let storage = SwiftDataStorageService(modelContext: modelContext)
                                        try await storage.saveTrip(trip)
                                        print("Trip saved: \(trip.destination)")
                                        viewModel.clearGeneratedTrip()
                                    } catch {
                                        print("Failed to save trip: \(error)")
                                    }
                                }
                            }
                        )
                    } else {
                        EmptyView()
                    }
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white, .blue)
                    .accessibilityHidden(true)

                Text("Travel Planner")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
            }

            Text("Build a trip around your destination, pace, and travel style.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Where are you going?", systemImage: "magnifyingglass")

                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2.crop.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)

                        TextField("Search for a city", text: $viewModel.destination)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused($destinationFieldFocused)
                            .onChange(of: viewModel.destination) { _, newValue in
                                autocomplete.updateQuery(newValue)
                            }
                    }

                    if destinationFieldFocused && !autocomplete.suggestions.isEmpty {
                        // suggestion list
                        VStack(spacing: 0) {
                            ForEach(autocomplete.suggestions, id: \.self) { suggestion in
                                Button {
                                    withAnimation {
                                        viewModel.destination = suggestion
                                        destinationFieldFocused = false
                                        autocomplete.clear()
                                    }
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                }
                                .buttonStyle(.plain)

                                Divider()
                            }
                        }
                        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(.quaternaryLabel), lineWidth: 0.5)
                        }
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            }
            .accessibilityLabel("Destination city")
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "How long are you staying?", systemImage: "calendar")

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(viewModel.duration)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text(viewModel.duration == 1 ? "day" : "days")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)

                }

                Slider(value: Binding(
                    get: { Double(viewModel.duration) },
                    set: { viewModel.duration = Int($0.rounded()) }
                ), in: 1...14, step: 1)
                .accessibilityLabel("Trip duration")
                .accessibilityValue("\(viewModel.duration) \(viewModel.duration == 1 ? "day" : "days")")

                HStack {
                    Text("Quick weekend")
                    Spacer()
                    Text("Two weeks")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "When does the trip start?", systemImage: "calendar.badge.clock")

            VStack(alignment: .leading, spacing: 12) {
                DatePicker(
                    "Start date",
                    selection: $viewModel.startDate,
                    in: Date.now...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()

                Text(viewModel.startDate.formatted(date: .long, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("This is the first day of the trip shown in the overview and itinerary.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var personaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "What kind of traveler are you?", systemImage: "person.crop.circle")

            VStack(spacing: 12) {
                ForEach(TravelerPersona.allCases) { persona in
                    PersonaOption(
                        persona: persona,
                        isSelected: viewModel.persona == persona
                    ) {
                        withAnimation(.snappy(duration: 0.2)) {
                            viewModel.persona = persona
                        }
                    }
                }
            }
        }
    }

    private var generateButton: some View {
        Button {
            viewModel.generateTrip()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .accessibilityHidden(true)
                Text("Generate Trip")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .controlSize(.large)
        .disabled(!canGenerateTrip)
        .accessibilityHint(canGenerateTrip ? "Prepares a future trip generation flow." : "Enter a destination city to continue.")
    }
}

private struct SectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

private struct PersonaOption: View {
    let persona: TravelerPersona
    let isSelected: Bool
    let action: () -> Void

    private var iconBackground: Color {
        isSelected ? persona.tint.opacity(0.18) : Color(.secondarySystemGroupedBackground)
    }

    private var iconColor: Color {
        isSelected ? persona.tint : .secondary
    }

    private var borderColor: Color {
        isSelected ? persona.tint.opacity(0.75) : .clear
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                personaIcon
                personaText

                Spacer(minLength: 12)

                selectionIcon
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(persona.accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var personaIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
                .frame(width: 46, height: 46)

            Image(systemName: persona.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconColor)
        }
        .accessibilityHidden(true)
    }

    private var personaText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(persona.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(persona.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var selectionIcon: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3.weight(.semibold))
            .foregroundStyle(isSelected ? persona.tint : Color(.tertiaryLabel))
            .accessibilityHidden(true)
    }
}

private extension TravelerPersona {
    var title: String {
        switch self {
        case .backpacker:
            "Backpacker"
        case .luxury:
            "Luxury"
        case .family:
            "Family"
        }
    }

    var subtitle: String {
        switch self {
        case .backpacker:
            "Budget-conscious and adventurous."
        case .luxury:
            "Premium and comfort-focused."
        case .family:
            "Family-friendly and practical."
        }
    }

    var systemImage: String {
        switch self {
        case .backpacker:
            "backpack.fill"
        case .luxury:
            "sparkles"
        case .family:
            "figure.2.and.child.holdinghands"
        }
    }

    var tint: Color {
        switch self {
        case .backpacker:
            .green
        case .luxury:
            .purple
        case .family:
            .orange
        }
    }

    var accessibilityLabel: String {
        "\(title), \(subtitle)"
    }
}

#Preview {
    ContentView()
}
