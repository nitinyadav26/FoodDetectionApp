// FoodSenseWidget.swift
//
// Daily Calorie Progress Widget for iOS using WidgetKit.
//
// SETUP INSTRUCTIONS:
// 1. In Xcode, go to File > New > Target and select "Widget Extension".
// 2. Name the target "FoodSenseWidget".
// 3. Enable "App Groups" for both the main app target and this widget extension
//    (e.g., group.com.foodsense.shared).
// 4. Replace the generated widget code with this file.
// 5. The main app should write calorie data to the shared UserDefaults suite
//    using the same App Group identifier.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct CalorieEntry: TimelineEntry {
    let date: Date
    let calories: Int
    let budget: Int

    var remaining: Int {
        max(budget - calories, 0)
    }

    var progress: Double {
        guard budget > 0 else { return 0 }
        return min(Double(calories) / Double(budget), 1.0)
    }
}

// MARK: - Timeline Provider

struct CalorieProvider: TimelineProvider {
    private let appGroupID = "group.com.foodsense.shared"

    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), calories: 1200, budget: 2000)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = fetchEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> CalorieEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let calories = defaults?.integer(forKey: "widget_today_cals") ?? 0
        let budget = defaults?.integer(forKey: "widget_calorie_budget") ?? 2000
        return CalorieEntry(date: Date(), calories: calories, budget: budget)
    }
}

// MARK: - Widget Entry View

struct CalorieWidgetEntryView: View {
    var entry: CalorieEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1)

            VStack(spacing: 6) {
                Text("FoodSense")
                    .font(.caption2)
                    .foregroundColor(Color(red: 0.114, green: 0.725, blue: 0.329))

                if family == .systemMedium {
                    // Medium widget: show a progress bar
                    ProgressView(value: entry.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.114, green: 0.725, blue: 0.329)))
                        .padding(.horizontal, 16)
                }

                Text("\(entry.calories) / \(entry.budget) kcal")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("\(entry.remaining) kcal remaining")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(12)
        }
    }
}

// MARK: - Widget Configuration

@main
struct FoodSenseWidget: Widget {
    let kind: String = "FoodSenseCalorieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            CalorieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calorie Progress")
        .description("Track your daily calorie intake at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

struct FoodSenseWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalorieWidgetEntryView(entry: CalorieEntry(date: Date(), calories: 1350, budget: 2000))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

        CalorieWidgetEntryView(entry: CalorieEntry(date: Date(), calories: 1350, budget: 2000))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
