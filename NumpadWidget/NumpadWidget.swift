//
//  NumpadWidget.swift
//  NumpadWidget
//
//  Created by Benny Wijatno on 10/15/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
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
        SimpleEntry(date: Date(), quantityTypes: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), quantityTypes: fetchQuantityTypes(count: widgetCount(for: context.family)))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let count = widgetCount(for: context.family)
        let quantityTypes = fetchQuantityTypes(count: count)

        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, quantityTypes: quantityTypes)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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

    private func fetchQuantityTypes(count: Int) -> [QuantityTypeData] {
        // Use shared container for better performance
        guard let container = Self.sharedContainer else {
            print("❌ Widget: ModelContainer not available")
            return []
        }

        do {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<QuantityType>(
                predicate: #Predicate { !$0.isHidden },
                sortBy: [SortDescriptor(\.sortOrder)]
            )

            let quantityTypes = try context.fetch(descriptor)

            return quantityTypes.prefix(count).map { qt in
                let entries = (qt.entries ?? []).map { $0.value }
                let total = qt.aggregationType.aggregate(entries)

                return QuantityTypeData(
                    name: qt.name,
                    icon: qt.icon,
                    colorHex: qt.colorHex,
                    total: total,
                    valueFormat: qt.valueFormat,
                    aggregationType: qt.aggregationType
                )
            }
        } catch {
            print("Error fetching quantity types: \(error)")
            return []
        }
    }
}

struct QuantityTypeData: Identifiable {
    let id = UUID()
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
        .padding()
    }
}

struct LargeWidgetView: View {
    let quantityTypes: [QuantityTypeData]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(quantityTypes.prefix(6)) { qt in
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
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
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
    SimpleEntry(date: .now, quantityTypes: [
        QuantityTypeData(name: "Water", icon: "drop.fill", colorHex: "#007AFF", total: 8, valueFormat: .integer, aggregationType: .sum)
    ])
}

#Preview(as: .systemMedium) {
    NumpadWidget()
} timeline: {
    SimpleEntry(date: .now, quantityTypes: [
        QuantityTypeData(name: "Water", icon: "drop.fill", colorHex: "#007AFF", total: 8, valueFormat: .integer, aggregationType: .sum),
        QuantityTypeData(name: "Reading", icon: "book.fill", colorHex: "#FF9500", total: 120, valueFormat: .duration, aggregationType: .sum),
        QuantityTypeData(name: "Steps", icon: "figure.walk", colorHex: "#34C759", total: 8542, valueFormat: .integer, aggregationType: .sum)
    ])
}
