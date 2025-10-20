//
//  NumpadWidget.swift
//  NumpadWidget
//
//  Created by Benny Wijatno on 10/15/25.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Provider: AppIntentTimelineProvider {
    // Shared container to avoid expensive recreation on every widget refresh
    private static let sharedContainer: ModelContainer? = {
        do {
            return try ModelContainer(
                for: QuantityType.self, NumpadEntry.self,
                configurations: ModelConfiguration(
                    groupContainer: .identifier("group.com.bennywijatno.numpad.app"),
                    cloudKitDatabase: .none
                )
            )
        } catch {
            print("❌ Widget: Failed to create ModelContainer: \(error)")
            return nil
        }
    }()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), quantityTypes: [], configuration: SelectQuantityTypesIntent())
    }

    func snapshot(for configuration: SelectQuantityTypesIntent, in context: Context) async -> SimpleEntry {
        let quantityTypes = fetchQuantityTypes(
            count: widgetCount(for: context.family),
            selectedIDs: configuration.effectiveQuantityTypes
        )
        return SimpleEntry(date: Date(), quantityTypes: quantityTypes, configuration: configuration)
    }

    func timeline(for configuration: SelectQuantityTypesIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let count = widgetCount(for: context.family)
        let quantityTypes = fetchQuantityTypes(
            count: count,
            selectedIDs: configuration.effectiveQuantityTypes
        )

        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, quantityTypes: quantityTypes, configuration: configuration)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func widgetCount(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 3
        case .systemLarge:
            return 6
        default:
            return 1
        }
    }

    /// Calculate total using database-level filtering (same logic as QuantityRepository)
    private func calculateTotal(for quantityType: QuantityType, context: ModelContext) -> Double {
        let quantityTypeID = quantityType.id
        let aggregationPeriod = quantityType.aggregationPeriod

        // Build predicate combining quantity type filter and optional time filter
        let descriptor: FetchDescriptor<NumpadEntry>

        // Get the time filter if needed
        let periodStartDate: Date? = {
            let calendar = Calendar.current
            let now = Date()

            switch aggregationPeriod {
            case .allTime:
                return nil
            case .daily:
                return calendar.startOfDay(for: now)
            case .weekly:
                return calendar.dateInterval(of: .weekOfYear, for: now)?.start
            case .monthly:
                return calendar.dateInterval(of: .month, for: now)?.start
            }
        }()

        // Build single predicate combining quantity type filter and optional time filter
        if let startDate = periodStartDate {
            descriptor = FetchDescriptor<NumpadEntry>(
                predicate: #Predicate<NumpadEntry> { entry in
                    entry.quantityType?.id == quantityTypeID && entry.timestamp >= startDate
                }
            )
        } else {
            descriptor = FetchDescriptor<NumpadEntry>(
                predicate: #Predicate<NumpadEntry> { entry in
                    entry.quantityType?.id == quantityTypeID
                }
            )
        }

        do {
            let entries = try context.fetch(descriptor)
            let values = entries.map { $0.value }
            return quantityType.aggregationType.aggregate(values)
        } catch {
            print("❌ Widget.calculateTotal: Failed to fetch entries for \(quantityType.name) - \(error.localizedDescription)")
            return 0
        }
    }

    private func fetchQuantityTypes(count: Int, selectedIDs: [String]) -> [QuantityTypeData] {
        print("➡️ Widget: Starting fetchQuantityTypes (count: \(count), selectedIDs: \(selectedIDs.count))")
        // Use shared container for better performance
        guard let container = Self.sharedContainer else {
            print("❌ Widget: ModelContainer not available")
            return []
        }

        do {
            print("➡️ Widget: ModelContainer available, fetching...")
            let context = ModelContext(container)

            // Fetch all non-hidden quantity types
            let descriptor = FetchDescriptor<QuantityType>(
                predicate: #Predicate { !$0.isHidden },
                sortBy: [SortDescriptor(\.sortOrder)]
            )

            let allQuantityTypes = try context.fetch(descriptor)
            print("➡️ Widget: Fetched \(allQuantityTypes.count) quantity types")

            // Filter based on user selection if provided
            let filteredQuantityTypes: [QuantityType]
            if selectedIDs.isEmpty {
                // No selection = use default behavior (top N by sort order)
                filteredQuantityTypes = Array(allQuantityTypes.prefix(count))
                print("➡️ Widget: No selection, using top \(count) by sort order")
            } else {
                // User has selected specific types - show those (in selection order, up to count limit)
                let selectedUUIDs = selectedIDs.compactMap { UUID(uuidString: $0) }
                filteredQuantityTypes = selectedUUIDs.compactMap { selectedID in
                    allQuantityTypes.first { $0.id == selectedID }
                }.prefix(count).map { $0 }
                print("➡️ Widget: Using \(filteredQuantityTypes.count) user-selected types")
            }

            // Use efficient database-level queries (no in-memory filtering!)
            return filteredQuantityTypes.map { qt in
                let total = self.calculateTotal(for: qt, context: context)
                print("  - Processing \(qt.name): total = \(total) (period: \(qt.aggregationPeriod.displayName))")

                return QuantityTypeData(
                    id: qt.id,
                    name: qt.name,
                    icon: qt.icon,
                    colorHex: qt.colorHex,
                    total: total,
                    valueFormat: qt.valueFormat,
                    aggregationType: qt.aggregationType
                )
            }
        } catch {
            print("❌ Widget: Error fetching quantity types: \(error)")
            return []
        }
    }
}

struct QuantityTypeData: Identifiable {
    let id: UUID // Actual ID from the QuantityType model
    let name: String
    let icon: String
    let colorHex: String
    let total: Double
    let valueFormat: ValueFormat
    let aggregationType: AggregationType

    var formattedTotal: String {
        valueFormat.format(total)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let quantityTypes: [QuantityTypeData]
    let configuration: SelectQuantityTypesIntent
}

struct NumpadWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(quantityType: entry.quantityTypes.first)
        case .systemMedium:
            MediumWidgetView(quantityTypes: entry.quantityTypes)
        case .systemLarge:
            LargeWidgetView(quantityTypes: entry.quantityTypes)
        default:
            SmallWidgetView(quantityType: entry.quantityTypes.first)
        }
    }
}

struct SmallWidgetView: View {
    let quantityType: QuantityTypeData?

    var body: some View {
        if let qt = quantityType {
            VStack(spacing: 8) {
                Image(systemName: qt.icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: qt.colorHex))

                Text(qt.name)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(qt.formattedTotal)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: qt.colorHex))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(URL(string: "numpad://quantity/\(qt.id.uuidString)"))
        } else {
            VStack {
                Image(systemName: "plus.circle")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No quantities")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MediumWidgetView: View {
    let quantityTypes: [QuantityTypeData]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(quantityTypes.prefix(3)) { qt in
                Link(destination: URL(string: "numpad://quantity/\(qt.id.uuidString)")!) {
                    VStack(spacing: 4) {
                        Image(systemName: qt.icon)
                            .font(.title2)
                            .foregroundColor(Color(hex: qt.colorHex))

                        Text(qt.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text(qt.formattedTotal)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: qt.colorHex))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let quantityTypes: [QuantityTypeData]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(quantityTypes.prefix(6)) { qt in
                Link(destination: URL(string: "numpad://quantity/\(qt.id.uuidString)")!) {
                    HStack {
                        Image(systemName: qt.icon)
                            .font(.title3)
                            .foregroundColor(Color(hex: qt.colorHex))
                            .frame(width: 30)

                        Text(qt.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()

                        Text(qt.formattedTotal)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: qt.colorHex))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct NumpadWidget: Widget {
    let kind: String = "NumpadWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectQuantityTypesIntent.self, provider: Provider()) { entry in
            NumpadWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Numpad")
        .description("View your quantity totals at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    NumpadWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        quantityTypes: [
            QuantityTypeData(id: UUID(), name: "Water", icon: "drop.fill", colorHex: "#007AFF", total: 8, valueFormat: .integer, aggregationType: .sum)
        ],
        configuration: SelectQuantityTypesIntent()
    )
}

#Preview(as: .systemMedium) {
    NumpadWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        quantityTypes: [
            QuantityTypeData(id: UUID(), name: "Water", icon: "drop.fill", colorHex: "#007AFF", total: 8, valueFormat: .integer, aggregationType: .sum),
            QuantityTypeData(id: UUID(), name: "Reading", icon: "book.fill", colorHex: "#FF9500", total: 120, valueFormat: .duration, aggregationType: .sum),
            QuantityTypeData(id: UUID(), name: "Steps", icon: "figure.walk", colorHex: "#34C759", total: 8542, valueFormat: .integer, aggregationType: .sum)
        ],
        configuration: SelectQuantityTypesIntent()
    )
}
