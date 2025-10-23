//
//  KeyboardShortcutsHelpView.swift
//  Numpad
//
//  Created on 2025-10-21.
//

import SwiftUI

/// View displaying all available keyboard shortcuts
struct KeyboardShortcutsHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    shortcutSection(
                        title: "Quantity Management",
                        shortcuts: [
                            ("⌘N", "New Quantity Type"),
                            ("⌘E", "Add Entry to Focused Quantity"),
                            ("↩︎", "Quick Add Entry"),
                        ]
                    )

                    shortcutSection(
                        title: "Navigation",
                        shortcuts: [
                            ("↓", "Next Quantity"),
                            ("↑", "Previous Quantity"),
                            ("⇥", "Next Quantity (Tab)"),
                            ("⇧⇥", "Previous Quantity (Shift+Tab)"),
                        ]
                    )

                    shortcutSection(
                        title: "General",
                        shortcuts: [
                            ("⎋", "Dismiss Sheet"),
                            ("⌘/", "Show/Hide This Help"),
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("Keyboard Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func shortcutSection(title: String, shortcuts: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                ForEach(shortcuts, id: \.0) { shortcut in
                    HStack(spacing: 16) {
                        Text(shortcut.0)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        Text(shortcut.1)
                            .font(.body)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

#Preview {
    KeyboardShortcutsHelpView()
}
