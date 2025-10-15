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
    }
}
