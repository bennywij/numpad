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

    // Query visible quantity types (not hidden), sorted by manual sort order
    @Query(
        filter: #Predicate<QuantityType> { !$0.isHidden },
        sort: \QuantityType.sortOrder,
        order: .forward
    ) private var visibleQuantityTypes: [QuantityType]

    // Query hidden quantity types, sorted by name
    @Query(
        filter: #Predicate<QuantityType> { $0.isHidden },
        sort: \QuantityType.name
    ) private var hiddenQuantityTypes: [QuantityType]

    // Query all quantity types (for seeding check)
    @Query private var allQuantityTypes: [QuantityType]

    // Query ALL entries to trigger view updates when entries change
    @Query private var allEntries: [NumpadEntry]

    // Repository for efficient database queries
    @State private var repository: QuantityRepository?

    // Cache of calculated totals (keyed by quantity type ID)
    @State private var totals: [UUID: Double] = [:]

    @State private var addEntryFor: QuantityType?
    @State private var showingAddQuantityType = false
    @State private var editQuantityType: QuantityType?
    @State private var showingResetConfirmation = false
    @State private var exportFileURL: URL?
    @State private var showingExportError = false
    @State private var navigationPath = NavigationPath()
    @State private var deepLinkQuantityID: UUID?

    // MARK: - Computed Properties

    // Most recently used visible quantity (for Quick Add)
    private var mostRecentQuantity: QuantityType? {
        visibleQuantityTypes
            .sorted { $0.lastUsedAt > $1.lastUsedAt }
            .first
    }

    // Should we show the Quick Add card?
    // Show if there's at least one visible quantity with a recent usage
    private var shouldShowQuickAdd: Bool {
        mostRecentQuantity != nil
    }

    // Main list of quantities to render - ALWAYS show ALL visible quantities
    // Quick Add is just a convenient shortcut, not a replacement
    // De-duplicate by ID in case there's corrupt data in the database
    private var mainListQuantities: [QuantityType] {
        var seen = Set<UUID>()
        return visibleQuantityTypes.filter { quantityType in
            let isNew = seen.insert(quantityType.id).inserted
            if !isNew {
                print("⚠️ Duplicate ID detected: \(quantityType.id) for \(quantityType.name)")
            }
            return isNew
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                if visibleQuantityTypes.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        // Quick Add section (only if we have a recent quantity)
                        if shouldShowQuickAdd, let mostRecent = mostRecentQuantity {
                            quickAddSection(for: mostRecent)
                                .padding(.bottom, 8)
                        }

                        // Main quantity cards
                        mainQuantitiesSection
                            .padding(.top, shouldShowQuickAdd ? 0 : 8)

                        // Hidden quantities section
                        if !hiddenQuantityTypes.isEmpty {
                            hiddenQuantitiesSection
                        }

                        // Export button at bottom (subtle, rarely used)
                        if !allEntries.isEmpty {
                            exportButton
                                .padding(.top, 40)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Numpad")
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Reset all data")
                    .accessibilityHint("Delete all quantity types and entries (Debug only)")
                }
                #endif

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
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset and Delete Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all quantity types and entries. This action cannot be undone and will also remove data from iCloud.")
            }
            .sheet(item: Binding(
                get: { exportFileURL.map { ExportFile(url: $0) } },
                set: { exportFileURL = $0?.url }
            )) { exportFile in
                ActivityViewController(activityItems: [exportFile.url])
            }
            .alert("Export Failed", isPresented: $showingExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Unable to export data. Please try again.")
            }
            .task {
                // Initialize repository for efficient database queries
                repository = QuantityRepository(modelContext: modelContext)

                // Calculate initial totals
                recalculateTotals()

                // Seed default quantity types if none exist
                if allQuantityTypes.isEmpty {
                    let vm = QuantityTypeViewModel(modelContext: modelContext)
                    vm.seedDefaultQuantityTypes()
                }
            }
            .navigationDestination(for: QuantityType.self) { quantityType in
                AnalyticsView(quantityType: quantityType, modelContext: modelContext)
            }
            .onOpenURL { url in
                handleDeepLink(url: url)
            }
            .onChange(of: deepLinkQuantityID) { oldValue, newValue in
                if let quantityID = newValue {
                    // Find the quantity type and navigate to it
                    if let quantityType = allQuantityTypes.first(where: { $0.id == quantityID }) {
                        navigationPath.append(quantityType)
                    }
                    // Clear the deep link ID after handling
                    deepLinkQuantityID = nil
                }
            }
            .onChange(of: allEntries.count) { _, _ in
                // Recalculate totals when entries are added/removed
                recalculateTotals()
            }
            .onChange(of: visibleQuantityTypes.count) { _, _ in
                // Recalculate totals when quantity types are added/removed
                recalculateTotals()
            }
        }
    }

    // MARK: - Quick Add Section

    private func quickAddSection(for quantityType: QuantityType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("QUICK ADD")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            Button {
                addEntryFor = quantityType
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: quantityType.icon)
                        .font(.title3)
                        .foregroundColor(Color(hex: quantityType.colorHex))
                        .frame(width: 24)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(quantityType.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text("Tap to log")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary.opacity(0.5))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: quantityType.colorHex).opacity(0.08))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Quick add to \(quantityType.name)")
            .accessibilityHint("Double tap to add a new entry")
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Main Quantities Section

    private var mainQuantitiesSection: some View {
        VStack(spacing: 16) {
            ForEach(mainListQuantities) { quantityType in
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
        .padding(.horizontal, 16)
    }

    // MARK: - Hidden Quantities Section

    // De-duplicated hidden quantities
    private var uniqueHiddenQuantities: [QuantityType] {
        var seen = Set<UUID>()
        return hiddenQuantityTypes.filter { quantityType in
            let isNew = seen.insert(quantityType.id).inserted
            if !isNew {
                print("⚠️ Duplicate hidden ID detected: \(quantityType.id) for \(quantityType.name)")
            }
            return isNew
        }
    }

    private var hiddenQuantitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 20)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("HIDDEN")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    ForEach(uniqueHiddenQuantities) { quantityType in
                        Button {
                            editQuantityType = quantityType
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: quantityType.icon)
                                    .font(.body)
                                    .foregroundColor(Color(hex: quantityType.colorHex))
                                    .frame(width: 20)

                                Text(quantityType.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Hidden: \(quantityType.name)")
                        .accessibilityHint("Double tap to edit and unhide")
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button {
            exportData()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                Text("Export Data")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .accessibilityLabel("Export all data to CSV")
        .accessibilityHint("Share your data as a CSV file")
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

    /// Calculate total for a quantity type using database-level filtering
    /// Returns cached value or 0 if not yet calculated
    private func calculateTotal(for quantityType: QuantityType) -> Double {
        return totals[quantityType.id] ?? 0
    }

    /// Recalculate all totals using the repository
    private func recalculateTotals() {
        guard let repo = repository else { return }

        var newTotals: [UUID: Double] = [:]
        for quantityType in visibleQuantityTypes {
            newTotals[quantityType.id] = repo.calculateTotal(for: quantityType)
        }
        totals = newTotals
    }

    private func deleteQuantityTypes(at offsets: IndexSet) {
        for index in offsets {
            let quantityType = mainListQuantities[index]
            modelContext.delete(quantityType)
        }
        try? modelContext.save()
    }

    private func moveQuantityTypes(from source: IndexSet, to destination: Int) {
        // Simple reordering - mainListQuantities is the same as visibleQuantityTypes
        var updatedTypes = visibleQuantityTypes
        updatedTypes.move(fromOffsets: source, toOffset: destination)

        // Update sort orders
        for (index, type) in updatedTypes.enumerated() {
            type.sortOrder = index
        }

        try? modelContext.save()
    }

    private func exportData() {
        print("📤 Exporting \(allEntries.count) entries...")

        guard let csvContent = CSVExporter.exportAllData(entries: allEntries) else {
            print("⚠️ No data to export")
            showingExportError = true
            return
        }

        guard let fileURL = CSVExporter.createTemporaryFile(csvContent: csvContent) else {
            print("❌ Failed to create export file")
            showingExportError = true
            return
        }

        print("✅ Export file created: \(fileURL.lastPathComponent)")
        exportFileURL = fileURL
    }

    private func resetAllData() {
        print("🔄 Starting data reset...")
        print("   Total entries: \(allEntries.count)")
        print("   Total quantity types: \(allQuantityTypes.count)")

        // Check for duplicates before deleting
        let uniqueIDs = Set(allQuantityTypes.map { $0.id })
        if uniqueIDs.count < allQuantityTypes.count {
            print("⚠️ Found \(allQuantityTypes.count - uniqueIDs.count) duplicate quantity types!")
        }

        // Delete all entries first (to maintain referential integrity)
        for entry in allEntries {
            modelContext.delete(entry)
        }

        // Delete all quantity types (including duplicates)
        for quantityType in allQuantityTypes {
            modelContext.delete(quantityType)
        }

        // Save changes - this will sync to iCloud and remove the data there too
        do {
            try modelContext.save()
            print("✅ All data deleted successfully")

            // Re-seed default quantity types after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let vm = QuantityTypeViewModel(modelContext: modelContext)
                vm.seedDefaultQuantityTypes()
            }
        } catch {
            print("❌ Failed to delete data: \(error)")
        }
    }

    /// Handle deep links from widgets to navigate to specific quantity analytics
    private func handleDeepLink(url: URL) {
        print("🔗 Deep link received: \(url)")

        // Expected format: numpad://quantity/{uuid}
        guard url.scheme == "numpad",
              url.host == "quantity",
              let uuidString = url.pathComponents.dropFirst().first,
              let quantityID = UUID(uuidString: uuidString) else {
            print("⚠️ Invalid deep link format: \(url)")
            return
        }

        print("✅ Parsed quantity ID: \(quantityID)")
        deepLinkQuantityID = quantityID
    }
}
