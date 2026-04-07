import SwiftUI
import Charts

struct PredictionView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared

    @State private var weeks: Int = 4

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Weight Prediction")
                            .font(.title2.bold())
                        Text("Based on your calorie intake")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Weeks Picker
                Picker("Projection", selection: $weeks) {
                    Text("4 Weeks").tag(4)
                    Text("8 Weeks").tag(8)
                    Text("12 Weeks").tag(12)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // On Track Indicator
                let prediction = computePrediction()

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", prediction.currentWeight))
                            .font(.title3.bold())
                    }

                    Image(systemName: prediction.onTrack ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(prediction.onTrack ? .green : .orange)

                    VStack(spacing: 4) {
                        Text("Projected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", prediction.projectedWeight))
                            .font(.title3.bold())
                            .foregroundColor(prediction.onTrack ? .green : .orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                // Status
                VStack(spacing: 8) {
                    Text(prediction.onTrack ? "On Track" : "Off Track")
                        .font(.headline)
                        .foregroundColor(prediction.onTrack ? .green : .orange)

                    Text(prediction.summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                // Weight Projection Chart
                if #available(iOS 16.0, *) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight Projection")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(prediction.chartData, id: \.week) { item in
                            LineMark(
                                x: .value("Week", item.week),
                                y: .value("Weight", item.weight)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Week", item.week),
                                y: .value("Weight", item.weight)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }

                // Details
                VStack(alignment: .leading, spacing: 10) {
                    Text("Calculation Details")
                        .font(.headline)

                    DetailRow(label: "TDEE (estimated)", value: "\(prediction.tdee) kcal/day")
                    DetailRow(label: "Avg Intake (7d)", value: "\(prediction.avgCals) kcal/day")
                    DetailRow(label: "Daily Surplus/Deficit", value: "\(prediction.dailyDiff) kcal")
                    DetailRow(label: "Weekly Change", value: String(format: "%.2f kg/week", prediction.weeklyChange))
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

    struct PredictionData {
        let currentWeight: Double
        let projectedWeight: Double
        let onTrack: Bool
        let summary: String
        let tdee: Int
        let avgCals: Int
        let dailyDiff: Int
        let weeklyChange: Double
        let chartData: [WeekPoint]
    }

    struct WeekPoint {
        let week: Int
        let weight: Double
    }

    func computePrediction() -> PredictionData {
        let stats = nutritionManager.userStats
        let currentWeight = stats?.weight ?? 70.0
        let goal = stats?.goal ?? "Maintain"

        // Calculate TDEE
        let age = stats?.age ?? 25
        let gender = stats?.gender ?? "Male"
        let height = stats?.height ?? 170.0
        let s = gender == "Male" ? 5.0 : -161.0
        let bmr = (10 * currentWeight) + (6.25 * height) - (5 * Double(age)) + s

        var activityMultiplier = 1.2
        switch stats?.activityLevel {
        case "Light": activityMultiplier = 1.375
        case "Moderate": activityMultiplier = 1.55
        case "Active": activityMultiplier = 1.725
        default: activityMultiplier = 1.2
        }

        let tdee = Int(bmr * activityMultiplier)

        // Average calories over last 7 days
        let calendar = Calendar.current
        let today = Date()
        var totalCals = 0
        var daysWithData = 0
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                let summary = nutritionManager.summary(for: date)
                if summary.cals > 0 {
                    totalCals += summary.cals
                    daysWithData += 1
                }
            }
        }
        let avgCals = daysWithData > 0 ? totalCals / daysWithData : tdee
        let dailyDiff = avgCals - tdee

        // weeklyChange = (avgCal - TDEE) * 7 / 7700
        let weeklyChange = Double(dailyDiff) * 7.0 / 7700.0

        // Generate chart data
        var chartData: [WeekPoint] = [WeekPoint(week: 0, weight: currentWeight)]
        for w in 1...weeks {
            let projected = currentWeight + (weeklyChange * Double(w))
            chartData.append(WeekPoint(week: w, weight: projected))
        }

        let projectedWeight = currentWeight + (weeklyChange * Double(weeks))

        // On track check
        var onTrack = false
        switch goal {
        case "Lose": onTrack = weeklyChange < -0.1
        case "Gain": onTrack = weeklyChange > 0.1
        default: onTrack = abs(weeklyChange) < 0.15
        }

        var summary = ""
        if goal == "Lose" {
            summary = onTrack
                ? "You're on track to lose weight. Keep up the good work!"
                : "You may need to reduce calorie intake or increase activity to meet your weight loss goal."
        } else if goal == "Gain" {
            summary = onTrack
                ? "You're on track to gain weight. Great job with your nutrition!"
                : "Consider increasing your calorie intake to meet your weight gain goal."
        } else {
            summary = onTrack
                ? "Your weight is stable. You're maintaining well!"
                : "Your intake seems off for maintenance. Consider adjusting."
        }

        return PredictionData(
            currentWeight: currentWeight,
            projectedWeight: projectedWeight,
            onTrack: onTrack,
            summary: summary,
            tdee: tdee,
            avgCals: avgCals,
            dailyDiff: dailyDiff,
            weeklyChange: weeklyChange,
            chartData: chartData
        )
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
