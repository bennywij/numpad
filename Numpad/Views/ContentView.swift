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
    @Query(sort: \QuantityType.lastUsedAt, order: .reverse) private var quantityTypes: [QuantityType]

    @StateObject private var quantityTypeViewModel: QuantityTypeViewModel
    @StateObject private var analyticsViewModel: AnalyticsViewModel

    @State private var showingAddEntry = false
    @State private var showingAddQuantityType = false
    @State private var selectedQuantityType: QuantityType?

    init() {
        // This will be properly initialized in the view body using the environment
        _quantityTypeViewModel = StateObject(wrappedValue: QuantityTypeViewModel(modelContext: ModelContext(ModelContainer(for: QuantityType.self))))
        _analyticsViewModel = StateObject(wrappedValue: AnalyticsViewModel(modelContext: ModelContext(ModelContainer(for: QuantityType.self))))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if quantityTypes.isEmpty {
                        emptyStateView
                    } else {
                        // Quick add to most recent
                        if let mostRecent = quantityTypes.first {
                            quickAddSection(mostRecent)
                        }

                        // All quantity types
                        LazyVStack(spacing: 12) {
                            ForEach(quantityTypes) { quantityType in
                                NavigationLink {
                                    EntryHistoryView(quantityType: quantityType, modelContext: modelContext)
                                } label: {
                                    QuantityTypeCard(
                                        quantityType: quantityType,
                                        total: calculateTotal(for: quantityType),
                                        onTap: {
                                            selectedQuantityType = quantityType
                                            showingAddEntry = true
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
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
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                if let quantityType = selectedQuantityType {
                    AddEntryView(quantityType: quantityType, modelContext: modelContext)
                }
            }
            .sheet(isPresented: $showingAddQuantityType) {
                AddQuantityTypeView(modelContext: modelContext)
            }
            .onAppear {
                // Seed default quantity types if none exist
                if quantityTypes.isEmpty {
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
                selectedQuantityType = quantityType
                showingAddEntry = true
            } label: {
                HStack {
                    Image(systemName: quantityType.icon)
                        .font(.title)
                        .foregroundColor(Color(hex: quantityType.colorHex))

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
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: quantityType.colorHex).opacity(0.1))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
            .padding(.horizontal)
        }
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
        }
        .padding()
    }

    private func calculateTotal(for quantityType: QuantityType) -> Double {
        let vm = AnalyticsViewModel(modelContext: modelContext)
        return vm.calculateTotal(for: quantityType)
    }
}
