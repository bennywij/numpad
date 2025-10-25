//
//  QuantityTypeRow.swift
//  Numpad
//
//  Created on 2025-10-16.
//

import SwiftUI
import SwiftData
import UIKit

/// Row component for displaying a quantity type with navigation and context menu
struct QuantityTypeRow: View {
    let quantityType: QuantityType
    let total: Double
    let onAddEntry: () -> Void
    let onEdit: () -> Void
    let modelContext: ModelContext
    var isFocused: Bool = false

    var body: some View {
        NavigationLink {
            AnalyticsView(quantityType: quantityType, modelContext: modelContext)
        } label: {
            QuantityTypeCard(
                quantityType: quantityType,
                total: total,
                onPlusButtonTap: onAddEntry,
                isFocused: isFocused
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                toggleHidden()
            } label: {
                Label(quantityType.isHidden ? "Unhide" : "Hide", systemImage: quantityType.isHidden ? "eye" : "eye.slash")
            }
        }
        .transition(.asymmetric(
            insertion: .identity,
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.2), value: quantityType.isHidden)
    }

    private func toggleHidden() {
        // Provide haptic feedback for the hide/show action
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()

        quantityType.isHidden.toggle()
        try? modelContext.save()
    }
}
