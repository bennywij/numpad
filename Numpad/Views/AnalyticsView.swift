//
//  AnalyticsView.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    let quantityType: QuantityType
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel: AnalyticsViewModel
    @State private var selectedPeriod: GroupingPeriod = .day

    init(quantityType: QuantityType, modelContext: ModelContext) {
        self.quantityType = quantityType
        self._viewModel = StateObject(wrappedValue: AnalyticsViewModel(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with total
                VStack(spacing: 8) {
                    Image(systemName: quantityType.icon)
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: quantityType.colorHex))

                    Text(quantityType.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(quantityType.valueFormat.format(viewModel.calculateTotal(for: quantityType)))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(quantityType.aggregationType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Period selector
                Picker("Group By", selection: $selectedPeriod) {
                    ForEach(GroupingPeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Grouped totals
                let groupedTotals = viewModel.calculateGroupedTotals(
                    for: quantityType,
                    groupedBy: selectedPeriod
                )

                if groupedTotals.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(groupedTotals) { group in
                            GroupedTotalRow(
                                group: group,
                                format: quantityType.valueFormat
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    EntryHistoryView(quantityType: quantityType, modelContext: modelContext)
                } label: {
                    Label("History", systemImage: "list.bullet")
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No entries yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Add some entries to see analytics")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct GroupedTotalRow: View {
    let group: GroupedTotal
    let format: ValueFormat

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.periodLabel)
                    .font(.headline)

                Text("\(group.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(format.format(group.total))
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}
