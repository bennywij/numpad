//
//  AppShortcuts.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import AppIntents

struct NumpadShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogEntryIntent(),
            phrases: [
                "Log to \(.applicationName)",
                "Add entry to \(.applicationName)",
                "Track in \(.applicationName)"
            ],
            shortTitle: "Log Entry",
            systemImageName: "number.square.fill"
        )
        AppShortcut(
            intent: LogEntryForChosenQuantityIntent(),
            phrases: [
                "Log to a specific quantity in \(.applicationName)"
            ],
            shortTitle: "Log to a specific quantity",
            systemImageName: "number.square.fill"
        )
    }
}
