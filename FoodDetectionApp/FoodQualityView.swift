import SwiftUI

struct FoodQualityView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Food Quality Score")
                            .font(.title2.bold())
                        Text("How healthy is your diet today?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                let score = computeQualityScore()

                // Circular Gauge
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 16)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.total) / 100.0)
                        .stroke(
                            scoreColor(score.total),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: score.total)

                    VStack(spacing: 4) {
                        Text("\(score.total)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor(score.total))
                        Text("out of 100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(scoreLabel(score.total))
                            .font(.caption.bold())
                            .foregroundColor(scoreColor(score.total))
                    }
                }
                .frame(width: 200, height: 200)
                .padding()

                // Score Breakdown
                VStack(alignment: .leading, spacing: 14) {
                    Text("Score Breakdown")
                        .font(.headline)

                    ScoreRow(label: "Macro Balance", score: score.macroScore, maxScore: 30,
                             description: "Balanced protein, carbs, and fats")
                    ScoreRow(label: "Protein Intake", score: score.proteinScore, maxScore: 20,
                             description: "Adequate protein for your goals")
                    ScoreRow(label: "Low Sugar/Fat", score: score.lowSugarScore, maxScore: 15,
                             description: "Controlled sugar and excess fat intake")
                    ScoreRow(label: "Fiber & Variety", score: score.fiberScore, maxScore: 15,
                             description: "Dietary fiber and food variety")
                    ScoreRow(label: "Micronutrients", score: score.microsScore, maxScore: 20,
                             description: "Vitamins and minerals from logged foods")
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                // Tips
                VStack(alignment: .leading, spacing: 10) {
                    Text("How to Improve")
                        .font(.headline)

                    ForEach(score.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
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

    // MARK: - Scoring

    struct QualityScore {
        let total: Int
        let macroScore: Int
        let proteinScore: Int
        let lowSugarScore: Int
        let fiberScore: Int
        let microsScore: Int
        let tips: [String]
    }

    func computeQualityScore() -> QualityScore {
        let logs = nutritionManager.todayLogs
        let summary = nutritionManager.todaySummary
        let budget = nutritionManager.calorieBudget

        guard !logs.isEmpty else {
            return QualityScore(total: 0, macroScore: 0, proteinScore: 0, lowSugarScore: 0, fiberScore: 0, microsScore: 0,
                                tips: ["Log some food to see your quality score!"])
        }

        var tips: [String] = []

        // 1. Macro Balance (max 30)
        let totalCals = max(summary.cals, 1)
        let proteinPct = Double(summary.protein * 4) / Double(totalCals) * 100
        let carbPct = Double(summary.carbs * 4) / Double(totalCals) * 100
        let fatPct = Double(summary.fats * 9) / Double(totalCals) * 100

        var macroScore = 0
        // Ideal: protein 20-35%, carbs 40-55%, fat 20-35%
        if proteinPct >= 15 && proteinPct <= 40 { macroScore += 10 }
        if carbPct >= 30 && carbPct <= 60 { macroScore += 10 }
        if fatPct >= 15 && fatPct <= 40 { macroScore += 10 }
        if macroScore < 30 { tips.append("Try to balance your macros: aim for 20-35% protein, 40-55% carbs, 20-35% fat.") }

        // 2. Protein Intake (max 20)
        let proteinTarget = (nutritionManager.userStats?.weight ?? 70) * 1.2
        let proteinRatio = Double(summary.protein) / max(proteinTarget, 1)
        var proteinScore = min(Int(proteinRatio * 20), 20)
        proteinScore = max(proteinScore, 0)
        if proteinScore < 15 { tips.append("Increase protein intake. Aim for at least \(Int(proteinTarget))g per day.") }

        // 3. Low Sugar/Excess Fat (max 15)
        var lowSugarScore = 15
        let fatRatio = Double(summary.fats * 9) / Double(max(totalCals, 1))
        if fatRatio > 0.40 {
            lowSugarScore -= 8
            tips.append("Your fat intake is high. Consider lower-fat alternatives.")
        }
        let calorieDiff = abs(summary.cals - budget)
        if calorieDiff > 500 {
            lowSugarScore -= 7
            tips.append("You're significantly over or under your calorie budget.")
        }
        lowSugarScore = max(lowSugarScore, 0)

        // 4. Fiber & Variety (max 15)
        let uniqueFoods = Set(logs.map { $0.food }).count
        var fiberScore = min(uniqueFoods * 3, 15)
        if uniqueFoods < 3 { tips.append("Eat a wider variety of foods for better nutrition.") }
        fiberScore = max(fiberScore, 0)

        // 5. Micronutrients (max 20)
        let logsWithMicros = logs.filter { $0.micros != nil && !($0.micros?.isEmpty ?? true) }
        var microsScore = 0
        if !logsWithMicros.isEmpty {
            let allMicroKeys = Set(logsWithMicros.flatMap { $0.micros?.keys ?? Dictionary<String, String>().keys })
            microsScore = min(allMicroKeys.count * 3, 20)
        }
        if microsScore < 10 { tips.append("Include more nutrient-dense foods rich in vitamins and minerals.") }

        let total = macroScore + proteinScore + lowSugarScore + fiberScore + microsScore

        if tips.isEmpty { tips.append("Great job! Keep maintaining your balanced diet.") }

        return QualityScore(total: min(total, 100), macroScore: macroScore, proteinScore: proteinScore,
                            lowSugarScore: lowSugarScore, fiberScore: fiberScore, microsScore: microsScore, tips: tips)
    }

    func scoreColor(_ score: Int) -> Color {
        if score >= 75 { return .green }
        if score >= 50 { return .orange }
        return .red
    }

    func scoreLabel(_ score: Int) -> String {
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        if score >= 40 { return "Fair" }
        if score > 0 { return "Needs Work" }
        return "No Data"
    }
}

struct ScoreRow: View {
    let label: String
    let score: Int
    let maxScore: Int
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(score)/\(maxScore)")
                    .font(.subheadline)
                    .foregroundColor(score >= maxScore / 2 ? .green : .orange)
            }
            ProgressView(value: Double(score), total: Double(maxScore))
                .tint(score >= maxScore / 2 ? .green : .orange)
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
