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

    // Keyboard navigation state
    @State private var focusedQuantityID: UUID?
    @State private var showingKeyboardShortcuts = false

    // User preference: should widget tap open entry card or analytics?
    @AppStorage("widgetOpensEntryCard") private var widgetOpensEntryCard = true

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
    private var mainListQuantities: [QuantityType] {
        visibleQuantityTypes
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Toggle("Widget Opens Entry Card", isOn: $widgetOpensEntryCard)

                        #if DEBUG
                        Divider()

                        Button(role: .destructive) {
                            showingResetConfirmation = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash")
                        }
                        #endif
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Access app settings and options")
                }

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
            .sheet(isPresented: $showingKeyboardShortcuts) {
                KeyboardShortcutsHelpView()
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
                    // Find the quantity type
                    if let quantityType = allQuantityTypes.first(where: { $0.id == quantityID }) {
                        // Check user preference for widget tap behavior
                        if widgetOpensEntryCard {
                            // Open entry card for quick data entry
                            addEntryFor = quantityType
                        } else {
                            // Navigate to analytics view
                            navigationPath.append(quantityType)
                        }
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
            .modifier(KeyboardShortcutsFocusedValues(
                newQuantityAction: handleNewQuantityShortcut,
                addEntryAction: handleAddEntryShortcut,
                nextQuantityAction: selectNextQuantity,
                previousQuantityAction: selectPreviousQuantity,
                dismissSheetAction: dismissSheet,
                showKeyboardShortcutsAction: showKeyboardShortcuts
            ))
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

    @ViewBuilder
    private var mainQuantitiesSection: some View {
        AdaptiveGrid(
            items: mainListQuantities,
            onDelete: deleteQuantityTypes,
            onMove: moveQuantityTypes
        ) { quantityType in
            QuantityTypeRow(
                quantityType: quantityType,
                total: calculateTotal(for: quantityType),
                onAddEntry: {
                    addEntryFor = quantityType
                },
                onEdit: {
                    editQuantityType = quantityType
                },
                modelContext: modelContext,
                isFocused: isFocused(quantityType)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Hidden Quantities Section

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
                    ForEach(hiddenQuantityTypes) { quantityType in
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

        // Delete all entries first (to maintain referential integrity)
        for entry in allEntries {
            modelContext.delete(entry)
        }

        // Delete all quantity types
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

    // MARK: - Keyboard Shortcuts

    /// Get currently focused quantity type, or first visible if none focused
    private var focusedQuantity: QuantityType? {
        if let focusedID = focusedQuantityID,
           let quantity = visibleQuantityTypes.first(where: { $0.id == focusedID }) {
            return quantity
        }
        return visibleQuantityTypes.first
    }

    /// Handle new quantity type shortcut (Cmd+N)
    private func handleNewQuantityShortcut() {
        showingAddQuantityType = true
    }

    /// Handle add entry shortcut (Cmd+E or Return)
    private func handleAddEntryShortcut() {
        guard let quantity = focusedQuantity else { return }
        addEntryFor = quantity
    }

    /// Navigate to next quantity type (Down arrow)
    private func selectNextQuantity() {
        guard !visibleQuantityTypes.isEmpty else { return }

        if let currentIndex = visibleQuantityTypes.firstIndex(where: { $0.id == focusedQuantityID }) {
            let nextIndex = (currentIndex + 1) % visibleQuantityTypes.count
            focusedQuantityID = visibleQuantityTypes[nextIndex].id
        } else {
            focusedQuantityID = visibleQuantityTypes.first?.id
        }
    }

    /// Navigate to previous quantity type (Up arrow)
    private func selectPreviousQuantity() {
        guard !visibleQuantityTypes.isEmpty else { return }

        if let currentIndex = visibleQuantityTypes.firstIndex(where: { $0.id == focusedQuantityID }) {
            let previousIndex = currentIndex == 0 ? visibleQuantityTypes.count - 1 : currentIndex - 1
            focusedQuantityID = visibleQuantityTypes[previousIndex].id
        } else {
            focusedQuantityID = visibleQuantityTypes.last?.id
        }
    }

    /// Check if a quantity type is currently focused
    private func isFocused(_ quantityType: QuantityType) -> Bool {
        quantityType.id == focusedQuantityID
    }

    /// Dismiss any currently presented sheet (Escape key handler)
    private func dismissSheet() {
        showingAddQuantityType = false
        addEntryFor = nil
        editQuantityType = nil
        showingKeyboardShortcuts = false
    }

    /// Show keyboard shortcuts help dialog (CMD+/ handler)
    private func showKeyboardShortcuts() {
        showingKeyboardShortcuts.toggle()
    }
}

// MARK: - Keyboard Shortcuts Focused Values Modifier

/// Custom ViewModifier to apply all keyboard shortcut focused values at once
/// This helps reduce SwiftUI type-checking complexity
struct KeyboardShortcutsFocusedValues: ViewModifier {
    let newQuantityAction: () -> Void
    let addEntryAction: () -> Void
    let nextQuantityAction: () -> Void
    let previousQuantityAction: () -> Void
    let dismissSheetAction: () -> Void
    let showKeyboardShortcutsAction: () -> Void

    func body(content: Content) -> some View {
        content
            .focusedValue(\.newQuantityAction, newQuantityAction)
            .focusedValue(\.addEntryAction, addEntryAction)
            .focusedValue(\.nextQuantityAction, nextQuantityAction)
            .focusedValue(\.previousQuantityAction, previousQuantityAction)
            .focusedValue(\.dismissSheetAction, dismissSheetAction)
            .focusedValue(\.showKeyboardShortcutsAction, showKeyboardShortcutsAction)
    }
}

// MARK: - Adaptive Grid for iPad

/// Adaptive grid layout that intelligently adjusts column count based on available space
/// - iPhone: 1 column with swipe-to-delete and drag-to-reorder
/// - iPad Portrait: 2 columns
/// - iPad Landscape: 3 columns on larger iPads, 2 on smaller
/// - iPad Split View: Adapts from 1-3 columns based on available width
struct AdaptiveGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let onDelete: ((IndexSet) -> Void)?
    let onMove: ((IndexSet, Int) -> Void)?
    let content: (Item) -> Content

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        items: [Item],
        onDelete: ((IndexSet) -> Void)? = nil,
        onMove: ((IndexSet, Int) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.onDelete = onDelete
        self.onMove = onMove
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let columnCount = determineColumnCount(for: geometry.size.width)
            let spacing: CGFloat = 16

            if columnCount > 1 {
                // iPad: Multi-column grid layout (onDelete/onMove not supported - would need custom implementation)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount), spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
            } else {
                // iPhone or narrow iPad Split View: Single column with edit support
                VStack(spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                    }
                    .onDelete(perform: onDelete)
                    .onMove(perform: onMove)
                }
            }
        }
    }

    /// Determines optimal column count based on available width
    /// - Parameter width: Available width in points
    /// - Returns: Number of columns (1-3)
    private func determineColumnCount(for width: CGFloat) -> Int {
        // Minimum card width for good UX (approximately)
        let minCardWidth: CGFloat = 300
        let spacing: CGFloat = 16
        let horizontalPadding: CGFloat = 32 // 16pt on each side

        let availableWidth = width - horizontalPadding

        // Calculate how many columns can comfortably fit
        if availableWidth >= minCardWidth * 3 + spacing * 4 {
            return 3  // iPad Pro 12.9" landscape
        } else if availableWidth >= minCardWidth * 2 + spacing * 3 {
            return 2  // iPad portrait, iPad Air/Pro landscape, Split View 2/3
        } else {
            return 1  // iPhone, Split View 1/3, Slide Over
        }
    }
}
