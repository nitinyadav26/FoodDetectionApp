import Foundation
import UIKit

/// Thin facade that preserves the `APIService.shared.xxx()` call convention
/// used by all consumer views. Internally delegates every call to the active
/// `AIProvider` selected by `AIProviderManager`.
///
/// Consumer views do NOT need to change — they keep calling
/// `APIService.shared.analyzeFood(image:)` etc.
class APIService {
    static let shared = APIService()

    private var provider: AIProvider {
        get throws {
            guard let p = AIProviderManager.shared.activeProvider else {
                throw NSError(
                    domain: "AIProviderError", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No AI provider configured. Add a Gemini API key or download the on-device model in Settings."]
                )
            }
            return p
        }
    }

    private init() {}

    // MARK: - Food Analysis

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        try await provider.analyzeFood(image: image)
    }

    // MARK: - Food Search (Text)

    func searchFood(query: String) async throws -> (name: String, info: NutritionInfo) {
        try await provider.searchFood(query: query)
    }

    // MARK: - AI Coach

    func getCoachAdvice(userStats: UserStats?, logs: [NutritionManager.FoodLog], healthData: String, historyTOON: String, userQuery: String) async throws -> String {
        try await provider.getCoachAdvice(userStats: userStats, logs: logs, healthData: healthData, historyTOON: historyTOON, userQuery: userQuery)
    }

    // MARK: - Meal Plan

    func generateMealPlan(userStats: UserStats?, calorieBudget: Int) async throws -> [PlannedMeal] {
        try await provider.generateMealPlan(userStats: userStats, calorieBudget: calorieBudget)
    }

    // MARK: - Portion Estimation

    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double) {
        try await provider.estimatePortion(image: image)
    }

    // MARK: - Before/After Comparison

    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String {
        try await provider.compareBeforeAfter(before: before, after: after)
    }

    // MARK: - OCR Nutrition Label

    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        try await provider.ocrNutritionLabel(image: image)
    }

    // MARK: - Generate Insights

    func generateInsights(foodHistory: String, calorieBudget: Int, userStats: UserStats?) async throws -> String {
        try await provider.generateInsights(foodHistory: foodHistory, calorieBudget: calorieBudget, userStats: userStats)
    }
}
