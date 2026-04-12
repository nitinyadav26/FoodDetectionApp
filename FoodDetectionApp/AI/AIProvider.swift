import Foundation
import UIKit

/// Abstraction over AI inference backends (Gemini Cloud, Gemma On-Device).
/// Both `GeminiCloudProvider` and `GemmaLocalProvider` implement this.
protocol AIProvider {
    var providerName: String { get }

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo)
    func searchFood(query: String) async throws -> (name: String, info: NutritionInfo)
    func getCoachAdvice(userStats: UserStats?, logs: [NutritionManager.FoodLog],
                        healthData: String, historyTOON: String, userQuery: String) async throws -> String
    func generateMealPlan(userStats: UserStats?, calorieBudget: Int) async throws -> [PlannedMeal]
    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double)
    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String
    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo)
    func generateInsights(foodHistory: String, calorieBudget: Int, userStats: UserStats?) async throws -> String
}
