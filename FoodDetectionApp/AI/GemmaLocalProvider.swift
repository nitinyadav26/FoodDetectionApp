import Foundation
import UIKit

/// On-device AI provider using Gemma 4 E4B via LiteRT-LM.
/// Currently stubbed — actual inference calls will be filled in when the LiteRT-LM pod is available.
final class GemmaLocalProvider: AIProvider {

    let providerName = "On-Device AI"

    private let modelPath: String

    init(modelPath: String) {
        self.modelPath = modelPath
    }

    // MARK: - AIProvider (stubbed — throws until LiteRT-LM is integrated)

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        let _ = PromptTemplates.analyzeFoodPrompt(forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    func searchFood(query: String) async throws -> (name: String, info: NutritionInfo) {
        let _ = PromptTemplates.searchFoodPrompt(query: query, forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    func getCoachAdvice(userStats: UserStats?, logs: [NutritionManager.FoodLog],
                        healthData: String, historyTOON: String, userQuery: String) async throws -> String {
        let system = PromptTemplates.coachSystemPrompt(forLocal: true)
        let _ = PromptTemplates.coachFullPrompt(systemPrompt: system, context: historyTOON, query: userQuery, forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    func generateMealPlan(userStats: UserStats?, calorieBudget: Int) async throws -> [PlannedMeal] {
        let context = "Calorie budget: \(calorieBudget) kcal/day."
        let _ = PromptTemplates.mealPlanPrompt(context: context, forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double) {
        let _ = PromptTemplates.portionEstimationPrompt(forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String {
        let _ = PromptTemplates.beforeAfterPrompt(forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        let _ = PromptTemplates.ocrNutritionLabelPrompt(forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    func generateInsights(foodHistory: String, calorieBudget: Int, userStats: UserStats?) async throws -> String {
        let _ = PromptTemplates.insightsPrompt(context: foodHistory, forLocal: true)
        // TODO: Replace with LiteRT-LM LlmInference call when pod is installed
        throw gemmaNotReadyError()
    }

    // MARK: - Private

    private func gemmaNotReadyError() -> NSError {
        NSError(
            domain: "GemmaError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "On-device AI model not yet initialized. Please ensure the model is downloaded."]
        )
    }
}
