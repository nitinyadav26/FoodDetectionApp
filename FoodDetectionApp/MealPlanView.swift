import SwiftUI

struct PlannedMeal: Identifiable, Codable {
    var id = UUID()
    let day: String
    let breakfast: String
    let lunch: String
    let dinner: String
    let snack: String
    let totalCalories: Int
}

struct MealPlanView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var mealPlan: [PlannedMeal] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedMeal: PlannedMeal?

    private let storageKey = "saved_meal_plan"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("7-Day Meal Plan")
                            .font(.title2.bold())
                        Text("AI-generated based on your goals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: generatePlan) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGenerating ? "Generating..." : "Generate")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isGenerating ? Color.gray : Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isGenerating)
                    .accessibilityLabel("Generate meal plan")
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if mealPlan.isEmpty && !isGenerating {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No meal plan yet")
                            .font(.headline)
                        Text("Tap Generate to create a personalized 7-day plan")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                }

                // Meal Plan Cards
                ForEach(mealPlan) { meal in
                    Button(action: { selectedMeal = meal }) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(meal.day)
                                    .font(.headline)
                                Spacer()
                                Text("\(meal.totalCalories) kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            }

                            MealRow(icon: "sunrise.fill", label: "Breakfast", value: meal.breakfast, color: .orange)
                            MealRow(icon: "sun.max.fill", label: "Lunch", value: meal.lunch, color: .yellow)
                            MealRow(icon: "moon.fill", label: "Dinner", value: meal.dinner, color: .purple)
                            MealRow(icon: "leaf.fill", label: "Snack", value: meal.snack, color: .green)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(meal.day) meal plan, \(meal.totalCalories) calories")
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailSheet(meal: meal)
        }
        .onAppear(perform: loadPlan)
    }

    func generatePlan() {
        guard networkMonitor.isConnected else {
            errorMessage = "No internet connection."
            return
        }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let plan = try await APIService.shared.generateMealPlan(
                    userStats: nutritionManager.userStats,
                    calorieBudget: nutritionManager.calorieBudget
                )
                DispatchQueue.main.async {
                    self.mealPlan = plan
                    self.isGenerating = false
                    self.savePlan()
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to generate plan: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }

    func savePlan() {
        if let data = try? JSONEncoder().encode(mealPlan) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func loadPlan() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([PlannedMeal].self, from: data) {
            mealPlan = saved
        }
    }
}

struct MealRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
    }
}

struct MealDetailSheet: View {
    let meal: PlannedMeal
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(meal.day)
                        .font(.largeTitle.bold())

                    Text("Total: \(meal.totalCalories) kcal")
                        .font(.title3)
                        .foregroundColor(.green)

                    Group {
                        DetailMealSection(title: "Breakfast", icon: "sunrise.fill", color: .orange, content: meal.breakfast)
                        DetailMealSection(title: "Lunch", icon: "sun.max.fill", color: .yellow, content: meal.lunch)
                        DetailMealSection(title: "Dinner", icon: "moon.fill", color: .purple, content: meal.dinner)
                        DetailMealSection(title: "Snack", icon: "leaf.fill", color: .green, content: meal.snack)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DetailMealSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
        }
    }
}
