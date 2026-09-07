//
//  MyTripsView.swift
//  travelAid
//

import SwiftUI
import SwiftData

struct MyTripsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Trip.startDate, order: .reverse)]) private var trips: [Trip]

    @State private var isShowingDetail: Bool = false
    @State private var selectedTrip: Trip?
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if trips.isEmpty {
                    Text("No saved trips yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(trips) { trip in
                        Button(action: {
                            selectedTrip = trip
                            isShowingDetail = true
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(trip.destination)
                                        .font(.headline)
                                    Text(trip.startDate, format: .dateTime.year().month().day())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(trip.totalTripCost.formatted(.currency(code: "INR")))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowSeparator(.visible)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await delete(trip)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Trips")
            .sheet(isPresented: $isShowingDetail) {
                if let trip = selectedTrip {
                    ItineraryView(trip: trip)
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func delete(_ trip: Trip) async {
        do {
            try await MainActor.run {
                modelContext.delete(trip)
                try modelContext.save()
            }
        } catch {
            errorMessage = "Unable to delete trip. Try again."
        }
    }
}

#Preview {
    MyTripsView()
}
