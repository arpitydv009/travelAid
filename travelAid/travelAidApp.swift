//
//  travelAidApp.swift
//  travelAid
//
//  Created by arpit on 29/08/26.
//

import SwiftUI
import SwiftData

@main
struct travelAidApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Provide a model container for our SwiftData models
        .modelContainer(for: [Activity.self, DayPlan.self, Trip.self])
    }
}
