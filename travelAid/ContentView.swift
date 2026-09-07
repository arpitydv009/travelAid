//
//  ContentView.swift
//  travelAid
//
//  Created by arpit on 29/08/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

private struct HomeView: View {
    @State private var destination = ""
    @State private var tripDuration = 5
    @State private var selectedPersona: TravelerPersona = .backpacker

    private var canGenerateTrip: Bool {
        !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    destinationSection
                    durationSection
                    personaSection
                    generateButton
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
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

            HStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField("Search for a city", text: $destination)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
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
                    Text("\(tripDuration)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text(tripDuration == 1 ? "day" : "days")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper("Trip duration", value: $tripDuration, in: 1...14)
                        .labelsHidden()
                }

                Slider(value: Binding(
                    get: { Double(tripDuration) },
                    set: { tripDuration = Int($0.rounded()) }
                ), in: 1...14, step: 1)
                .accessibilityLabel("Trip duration")
                .accessibilityValue("\(tripDuration) \(tripDuration == 1 ? "day" : "days")")

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

    private var personaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "What kind of traveler are you?", systemImage: "person.crop.circle")

            VStack(spacing: 12) {
                ForEach(TravelerPersona.allCases) { persona in
                    PersonaOption(
                        persona: persona,
                        isSelected: selectedPersona == persona
                    ) {
                        withAnimation(.snappy(duration: 0.2)) {
                            selectedPersona = persona
                        }
                    }
                }
            }
        }
    }

    private var generateButton: some View {
        Button {
            // Trip generation starts in a later phase.
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? persona.tint.opacity(0.18) : Color(.secondarySystemGroupedBackground))
                        .frame(width: 46, height: 46)

                    Image(systemName: persona.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSelected ? persona.tint : .secondary)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(persona.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? persona.tint : .tertiary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? persona.tint.opacity(0.75) : .quaternary, lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(persona.accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private enum TravelerPersona: String, CaseIterable, Identifiable {
    case backpacker
    case luxury
    case family

    var id: String { rawValue }

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
