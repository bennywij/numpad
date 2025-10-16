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

    @Query private var allQuantityTypes: [QuantityType]

    @State private var addEntryFor: QuantityType?
    @State private var showingAddQuantityType = false
    @State private var editQuantityType: QuantityType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if visibleQuantityTypes.isEmpty {
                        emptyStateView
                    } else {
                        // Quick add to most recent
                        if let mostRecent = visibleQuantityTypes.first {
                            quickAddSection(mostRecent)
                        }

                        // All quantity types
                        LazyVStack(spacing: 12) {
                            ForEach(visibleQuantityTypes) { quantityType in
                                QuantityTypeRow(
                                    quantityType: quantityType,
                                    total: calculateTotal(for: quantityType),
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
                        .padding(.horizontal)

                        // Hidden quantity types section
                        if !hiddenQuantityTypes.isEmpty {
                            hiddenQuantitiesSection
                        }
                    }
                }
                .padding(.vertical)
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

    private func quickAddSection(_ quantityType: QuantityType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button {
                addEntryFor = quantityType
            } label: {
                HStack {
                    Image(systemName: quantityType.icon)
                        .font(.title)
                        .foregroundColor(Color(hex: quantityType.colorHex))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading) {
                        Text(quantityType.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Tap to log")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: quantityType.colorHex).opacity(0.1))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
            .padding(.horizontal)
            .accessibilityLabel("Quick add to \(quantityType.name)")
            .accessibilityHint("Double tap to add a new entry")
        }
    }

    private var hiddenQuantitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hidden")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            LazyVStack(spacing: 12) {
                ForEach(hiddenQuantityTypes) { quantityType in
                    Button {
                        editQuantityType = quantityType
                    } label: {
                        HStack {
                            Image(systemName: quantityType.icon)
                                .font(.title2)
                                .foregroundColor(Color(hex: quantityType.colorHex))

                            VStack(alignment: .leading) {
                                Text(quantityType.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Hidden • Tap to edit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 20)
    }

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

    private func calculateTotal(for quantityType: QuantityType) -> Double {
        let vm = AnalyticsViewModel(modelContext: modelContext)
        return vm.calculateTotal(for: quantityType)
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
