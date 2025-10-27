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
            #if DEBUG
            print("⚠️ CloudKit unavailable, using local storage: \(error)")
            #endif
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                // Final fallback to in-memory storage (data won't persist, but app won't crash)
                #if DEBUG
                print("⚠️ Local storage failed, using in-memory storage: \(error)")
                #endif
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    // This should never happen with in-memory storage
                    fatalError("❌ Critical: Could not create ModelContainer: \(error)")
                }
            }
        }
    }()

    @FocusedValue(\.newQuantityAction) private var newQuantityAction
    @FocusedValue(\.addEntryAction) private var addEntryAction
    @FocusedValue(\.nextQuantityAction) private var nextQuantityAction
    @FocusedValue(\.previousQuantityAction) private var previousQuantityAction
    @FocusedValue(\.dismissSheetAction) private var dismissSheetAction
    @FocusedValue(\.showKeyboardShortcutsAction) private var showKeyboardShortcutsAction

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            // Keyboard shortcuts for iPad
            CommandMenu("Quantity") {
                Button("New Quantity Type") {
                    newQuantityAction?()
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(newQuantityAction == nil)

                Divider()

                Button("Add Entry") {
                    addEntryAction?()
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(addEntryAction == nil)

                Button("Quick Add Entry") {
                    addEntryAction?()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(addEntryAction == nil)

                Divider()

                Button("Next Quantity") {
                    nextQuantityAction?()
                }
                .keyboardShortcut(.downArrow, modifiers: [])
                .disabled(nextQuantityAction == nil)

                Button("Previous Quantity") {
                    previousQuantityAction?()
                }
                .keyboardShortcut(.upArrow, modifiers: [])
                .disabled(previousQuantityAction == nil)

                Divider()

                Button("Next Quantity (Tab)") {
                    nextQuantityAction?()
                }
                .keyboardShortcut(.tab, modifiers: [])
                .disabled(nextQuantityAction == nil)

                Button("Previous Quantity (Shift+Tab)") {
                    previousQuantityAction?()
                }
                .keyboardShortcut(.tab, modifiers: .shift)
                .disabled(previousQuantityAction == nil)

                Divider()

                Button("Dismiss Sheet") {
                    dismissSheetAction?()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .disabled(dismissSheetAction == nil)
            }

            CommandMenu("Help") {
                Button("Keyboard Shortcuts") {
                    showKeyboardShortcutsAction?()
                }
                .keyboardShortcut("/", modifiers: .command)
                .disabled(showKeyboardShortcutsAction == nil)
            }
        }
    }
}
