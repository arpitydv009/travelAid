//
//  StorageService.swift
//  travelAid
//

import Foundation
import SwiftData

// Protocol to abstract persistence behind a service interface.
protocol StorageService: Sendable {
    func saveTrip(_ trip: Trip) async throws
    func fetchTrips() async throws -> [Trip]
    func deleteTrip(_ trip: Trip) async throws
}

// SwiftData-backed implementation of StorageService.
// Notes:
// - This implementation defensively copies the incoming Trip into managed model instances
//   to avoid inserting unmanaged objects into the ModelContext.
// - All methods are async and may throw; callers should present user-friendly errors.
final class SwiftDataStorageService: StorageService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveTrip(_ trip: Trip) async throws {
        try await MainActor.run {
            // Create managed copies of activities, day plans and the trip
            var managedDayPlans: [DayPlan] = []

            for day in trip.dayPlans {
                var managedActivities: [Activity] = []
                for activity in day.activities {
                    let managedActivity = Activity(
                        name: activity.name,
                        type: activity.type,
                        isIndoor: activity.isIndoor,
                        rating: activity.rating,
                        costLevel: activity.costLevel,
                        description: activity.activityDescription,
                        durationHours: activity.durationHours,
                        latitude: activity.latitude,
                        longitude: activity.longitude,
                        address: activity.address,
                        mealType: activity.mealType,
                        cost: activity.cost
                    )
                    modelContext.insert(managedActivity)
                    managedActivities.append(managedActivity)
                }

                let managedDay = DayPlan(dayNumber: day.dayNumber, activities: managedActivities, weather: day.weather)
                modelContext.insert(managedDay)
                managedDayPlans.append(managedDay)
            }

            let managedTrip = Trip(
                destination: trip.destination,
                duration: trip.duration,
                dayPlans: managedDayPlans,
                startDate: trip.startDate,
                persona: trip.persona
            )

            modelContext.insert(managedTrip)

            try modelContext.save()
        }
    }

    func fetchTrips() async throws -> [Trip] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<Trip>(sortBy: [
                SortDescriptor(
                    \Trip.startDate,
                    order: .reverse
                )
            ])
            return try modelContext.fetch(descriptor)
        }
    }

    func deleteTrip(_ trip: Trip) async throws {
        try await MainActor.run {
            modelContext.delete(trip)
            try modelContext.save()
        }
    }
}
