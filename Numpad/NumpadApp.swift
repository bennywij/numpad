//
//  NumpadApp.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

@main
struct NumpadApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            QuantityType.self,
            Entry.self,
        ])

        // Try CloudKit first, fallback to local storage if unavailable
        let cloudKitConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            // Try with CloudKit first
            return try ModelContainer(for: schema, configurations: [cloudKitConfig])
        } catch {
            // Fallback to local storage
            print("CloudKit unavailable, using local storage: \(error)")
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
