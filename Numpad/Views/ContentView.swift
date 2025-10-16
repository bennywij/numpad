//
//  ContentView.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // Separate queries for visible and hidden quantity types - this ensures proper reactivity
    @Query(
        filter: #Predicate<QuantityType> { !$0.isHidden },
        sort: \QuantityType.sortOrder,
        order: .forward
    ) private var visibleQuantityTypes: [QuantityType]

    @Query(
        filter: #Predicate<QuantityType> { $0.isHidden },
        sort: \QuantityType.name
    ) private var hiddenQuantityTypes: [QuantityType]

    // Query for most recently used (for Quick Add)
    @Query(
        filter: #Predicate<QuantityType> { !$0.isHidden },
        sort: \QuantityType.lastUsedAt,
        order: .reverse
    ) private var recentQuantityTypes: [QuantityType]

    @Query private var allQuantityTypes: [QuantityType]

    // Query ALL entries to trigger view updates when entries change
    @Query private var allEntries: [NumpadEntry]

    // Most recently used quantity (for Quick Add)
    private var mostRecentQuantity: QuantityType? {
        recentQuantityTypes.first
    }

    @State private var addEntryFor: QuantityType?
    @State private var showingAddQuantityType = false
    @State private var editQuantityType: QuantityType?

    var body: some View {
        NavigationStack {
            ScrollView {
                if visibleQuantityTypes.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 0) {
                        // Quick add section - shows most recently used visible quantity
                        if let mostRecent = mostRecentQuantity {
                            quickAddCard(mostRecent)
                                .padding(.top, 20)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }

                        // All quantity type cards (sorted by manual sort order)
                        VStack(spacing: 16) {
                            ForEach(visibleQuantityTypes) { quantityType in
                                QuantityTypeRow(
                                    quantityType: quantityType,
                                    total: calculateTotal(for: quantityType, in: allEntries),
                                    onAddEntry: {
                                        addEntryFor = quantityType
                                    },
                                    onEdit: {
                                        editQuantityType = quantityType
                                    },
                                    modelContext: modelContext
                                )
                            }
                            .onDelete(perform: deleteQuantityTypes)
                            .onMove(perform: moveQuantityTypes)
                        }
                        .padding(.horizontal, 16)

                        // Hidden quantity types section
                        if !hiddenQuantityTypes.isEmpty {
                            Divider()
                                .padding(.vertical, 24)
                                .padding(.horizontal, 16)

                            hiddenQuantitiesSection
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Numpad")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddQuantityType = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add quantity type")
                    .accessibilityHint("Create a new quantity to track")
                }
            }
            .sheet(item: $addEntryFor) { quantityType in
                AddEntryView(quantityType: quantityType, modelContext: modelContext)
            }
            .sheet(isPresented: $showingAddQuantityType) {
                AddQuantityTypeView(modelContext: modelContext)
            }
            .sheet(item: $editQuantityType) { quantityType in
                EditQuantityTypeView(quantityType: quantityType, modelContext: modelContext)
            }
            .task {
                // Seed default quantity types if none exist
                if allQuantityTypes.isEmpty {
                    let vm = QuantityTypeViewModel(modelContext: modelContext)
                    vm.seedDefaultQuantityTypes()
                }
            }
        }
    }

    // MARK: - Quick Add Card
    private func quickAddCard(_ quantityType: QuantityType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK ADD")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(0.5)

            Button {
                addEntryFor = quantityType
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: quantityType.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: quantityType.colorHex))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(quantityType.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Tap to log")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: quantityType.colorHex).opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Quick add to \(quantityType.name)")
            .accessibilityHint("Double tap to add a new entry")
        }
    }

    // MARK: - Hidden Quantities Section
    private var hiddenQuantitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HIDDEN")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(0.5)

            // Use VStack instead of ForEach to avoid duplication
            VStack(spacing: 8) {
                ForEach(Array(hiddenQuantityTypes.enumerated()), id: \.element.id) { index, quantityType in
                    Button {
                        editQuantityType = quantityType
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: quantityType.icon)
                                .font(.headline)
                                .foregroundColor(Color(hex: quantityType.colorHex))

                            Text(quantityType.name)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("Tap to edit")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Hidden: \(quantityType.name)")
                    .accessibilityHint("Double tap to edit and unhide")
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "number.square.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue.opacity(0.5))

            Text("No Quantity Types")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the + button to create your first quantity to track")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingAddQuantityType = true
            } label: {
                Text("Create Quantity Type")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .accessibilityLabel("Create your first quantity type")
            .accessibilityHint("Double tap to add a new quantity to track")
        }
        .padding()
    }

    // MARK: - Helper Methods
    /// Calculate total for a quantity type from the provided entries
    /// This approach uses @Query to reactively update when entries change
    private func calculateTotal(for quantityType: QuantityType, in entries: [NumpadEntry]) -> Double {
        let filteredEntries = entries.filter { $0.quantityType?.id == quantityType.id }
        let values = filteredEntries.map { $0.value }
        return quantityType.aggregationType.aggregate(values)
    }

    private func deleteQuantityTypes(at offsets: IndexSet) {
        for index in offsets {
            let quantityType = visibleQuantityTypes[index]
            modelContext.delete(quantityType)
        }
        try? modelContext.save()
    }

    private func moveQuantityTypes(from source: IndexSet, to destination: Int) {
        var updatedTypes = visibleQuantityTypes
        updatedTypes.move(fromOffsets: source, toOffset: destination)

        // Update sort orders
        for (index, type) in updatedTypes.enumerated() {
            type.sortOrder = index
        }
        try? modelContext.save()
    }
}

// MARK: - Quantity Type Row with Actions
struct QuantityTypeRow: View {
    let quantityType: QuantityType
    let total: Double
    let onAddEntry: () -> Void
    let onEdit: () -> Void
    let modelContext: ModelContext

    var body: some View {
        NavigationLink {
            AnalyticsView(quantityType: quantityType, modelContext: modelContext)
        } label: {
            QuantityTypeCard(
                quantityType: quantityType,
                total: total,
                onPlusButtonTap: onAddEntry
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
    }
}
