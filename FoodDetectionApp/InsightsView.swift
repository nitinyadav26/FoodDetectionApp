import SwiftUI
import Charts

struct InsightsView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var selectedPeriod = 7
    @State private var aiTips: String = ""
    @State private var isLoadingTips = false

    let periods = [7, 14, 30]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Nutrition Insights")
                            .font(.title2.bold())
                        Text("Trends and analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Period Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { p in
                        Text("\(p)D").tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Calorie Trend Chart
                if #available(iOS 16.0, *) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calorie Trend")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(calorieData, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Calories", item.calories)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Calories", item.calories)
                            )
                            .foregroundStyle(.green.opacity(0.1))
                            .interpolationMethod(.catmullRom)

                            if nutritionManager.calorieBudget > 0 {
                                RuleMark(y: .value("Budget", nutritionManager.calorieBudget))
                                    .foregroundStyle(.red.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }

                // Macro Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Macro Breakdown (Avg/Day)")
                        .font(.headline)

                    let avg = averageMacros
                    HStack(spacing: 16) {
                        MacroBar(label: "Protein", value: avg.protein, max: 200, color: .blue)
                        MacroBar(label: "Carbs", value: avg.carbs, max: 300, color: .orange)
                        MacroBar(label: "Fats", value: avg.fats, max: 100, color: .red)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                // Top Foods
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Foods")
                        .font(.headline)

                    ForEach(topFoods.prefix(5), id: \.name) { food in
                        HStack {
                            Text(food.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(food.count)x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(food.totalCals) kcal")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }

                    if topFoods.isEmpty {
                        Text("No food data for this period")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                // AI Tips
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("AI Tips")
                            .font(.headline)
                        Spacer()
                        Button(action: loadAITips) {
                            HStack(spacing: 4) {
                                if isLoadingTips {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                                Text(isLoadingTips ? "Loading..." : "Get Tips")
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                        }
                        .disabled(isLoadingTips)
                    }

                    if !aiTips.isEmpty {
                        Text(aiTips)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Data

    struct DayCalorie {
        let date: Date
        let calories: Int
    }

    var calorieData: [DayCalorie] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<selectedPeriod).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let summary = nutritionManager.summary(for: date)
            return DayCalorie(date: date, calories: summary.cals)
        }.reversed()
    }

    var averageMacros: (protein: Int, carbs: Int, fats: Int) {
        let data = calorieData
        guard !data.isEmpty else { return (0, 0, 0) }
        let calendar = Calendar.current
        let today = Date()
        var totalP = 0, totalC = 0, totalF = 0
        for offset in 0..<selectedPeriod {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let s = nutritionManager.summary(for: date)
                totalP += s.protein
                totalC += s.carbs
                totalF += s.fats
            }
        }
        let count = selectedPeriod
        return (totalP / count, totalC / count, totalF / count)
    }

    struct TopFood {
        let name: String
        let count: Int
        let totalCals: Int
    }

    var topFoods: [TopFood] {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod, to: today) ?? today

        let filtered = nutritionManager.logs.filter { $0.time >= startDate }
        let grouped = Dictionary(grouping: filtered, by: { $0.food })

        return grouped.map { (key, logs) in
            TopFood(name: key, count: logs.count, totalCals: logs.reduce(0) { $0 + $1.calories })
        }
        .sorted { $0.count > $1.count }
    }

    func loadAITips() {
        guard networkMonitor.isConnected else {
            aiTips = "No internet connection."
            return
        }

        isLoadingTips = true
        let history = nutritionManager.getHistory(days: selectedPeriod)

        Task {
            do {
                let tips = try await APIService.shared.generateInsights(
                    foodHistory: history,
                    calorieBudget: nutritionManager.calorieBudget,
                    userStats: nutritionManager.userStats
                )
                DispatchQueue.main.async {
                    self.aiTips = tips
                    self.isLoadingTips = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.aiTips = "Failed to load tips."
                    self.isLoadingTips = false
                }
            }
        }
    }
}

struct MacroBar: View {
    let label: String
    let value: Int
    let max: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)g")
                .font(.headline)
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(height: geo.size.height * CGFloat(min(Double(value) / Double(Swift.max(max, 1)), 1.0)))
                }
            }
            .frame(height: 80)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
