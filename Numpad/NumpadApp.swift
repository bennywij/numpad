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
            NumpadEntry.self,
        ])

        // Try CloudKit first with App Group, fallback to local storage if unavailable
        // App Group enables data sharing with widget extension
        let cloudKitConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.bennywijatno.numpad.app"),
            cloudKitDatabase: .automatic
        )

        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.bennywijatno.numpad.app"),
            cloudKitDatabase: .none
        )

        let inMemoryConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            // Try with CloudKit first
            return try ModelContainer(for: schema, configurations: [cloudKitConfig])
        } catch {
            // Fallback to local storage
            print("⚠️ CloudKit unavailable, using local storage: \(error)")
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                // Final fallback to in-memory storage (data won't persist, but app won't crash)
                print("⚠️ Local storage failed, using in-memory storage: \(error)")
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    // This should never happen with in-memory storage
                    fatalError("❌ Critical: Could not create ModelContainer: \(error)")
                }
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
