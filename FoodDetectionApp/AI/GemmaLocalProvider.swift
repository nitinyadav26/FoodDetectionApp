import Foundation
import UIKit
import llama

/// On-device AI provider using Gemma 4 E4B via llama.cpp (GGUF format).
/// The llama.xcframework provides the C inference engine; this file wraps
/// it in a Swift-friendly API that conforms to AIProvider.
final class GemmaLocalProvider: AIProvider {

    static let isInferenceAvailable = true

    let providerName = "On-Device AI"

    private let modelPath: String
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?

    init(modelPath: String) {
        self.modelPath = modelPath
    }

    deinit {
        if let sampler { llama_sampler_free(sampler) }
        if let context { llama_free(context) }
        if let model { llama_model_free(model) }
    }

    // MARK: - Model Loading (lazy)

    private func ensureLoaded() throws {
        guard model == nil else { return }

        llama_backend_init()

        var mparams = llama_model_default_params()
        mparams.n_gpu_layers = 99  // offload as many layers to GPU as possible

        guard let m = llama_model_load_from_file(modelPath, mparams) else {
            throw GemmaError.modelLoadFailed
        }
        model = m

        var cparams = llama_context_default_params()
        cparams.n_ctx = 4096
        cparams.n_batch = 512

        guard let c = llama_init_from_model(m, cparams) else {
            throw GemmaError.contextCreateFailed
        }
        context = c

        // Build a simple sampler chain: temperature + top-k + top-p + greedy
        let sparams = llama_sampler_chain_default_params()
        guard let chain = llama_sampler_chain_init(sparams) else {
            throw GemmaError.samplerCreateFailed
        }
        llama_sampler_chain_add(chain, llama_sampler_init_temp(0.7))
        llama_sampler_chain_add(chain, llama_sampler_init_top_k(40))
        llama_sampler_chain_add(chain, llama_sampler_init_top_p(0.9, 1))
        llama_sampler_chain_add(chain, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))
        sampler = chain
    }

    // MARK: - Core Generation

    private func generate(prompt: String, maxTokens: Int = 2048) async throws -> String {
        try ensureLoaded()
        guard let model, let context, let sampler else {
            throw GemmaError.notInitialized
        }

        // Tokenize the prompt
        let promptCStr = prompt.cString(using: .utf8)!
        let maxInputTokens = Int32(promptCStr.count + 256)
        var tokens = [llama_token](repeating: 0, count: Int(maxInputTokens))
        let nTokens = llama_tokenize(model, promptCStr, Int32(promptCStr.count - 1),
                                     &tokens, maxInputTokens, true, true)
        guard nTokens > 0 else {
            throw GemmaError.tokenizeFailed
        }
        tokens = Array(tokens.prefix(Int(nTokens)))

        // Clear KV cache for fresh generation
        let mem = llama_get_memory(context)
        llama_memory_clear(mem, true)
        llama_sampler_reset(sampler)

        // Decode the prompt in one batch
        var batch = llama_batch_get_one(&tokens, nTokens)
        guard llama_decode(context, batch) == 0 else {
            throw GemmaError.decodeFailed
        }

        // Generate token by token
        var result = ""
        var nDecoded: Int32 = nTokens

        for _ in 0..<maxTokens {
            let newToken = llama_sampler_sample(sampler, context, -1)

            // Check end-of-generation
            if llama_token_is_eog(model, newToken) { break }

            // Convert token to text
            var buf = [CChar](repeating: 0, count: 256)
            let len = llama_token_to_piece(model, newToken, &buf, 256, 0, false)
            if len > 0 {
                let piece = String(cString: buf)
                result += piece
            }

            // Prepare next batch (single token)
            var nextToken = newToken
            batch = llama_batch_get_one(&nextToken, 1)
            guard llama_decode(context, batch) == 0 else { break }
            nDecoded += 1
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - AIProvider

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        // Gemma 4 E4B supports vision but the llama.cpp C API vision path requires
        // mmproj (multimodal projector). For now, use text-only analysis with a
        // descriptive prompt. Image-based detection still uses the YOLO TFLite model.
        let prompt = PromptTemplates.analyzeFoodPrompt(forLocal: true)
        let response = try await generate(prompt: prompt)
        return try AIResponseParser.parseNutritionFromRawText(text: response, fallbackDish: "AI Detected Food")
    }

    func searchFood(query: String) async throws -> (name: String, info: NutritionInfo) {
        let prompt = PromptTemplates.searchFoodPrompt(query: query, forLocal: true)
        let response = try await generate(prompt: prompt)
        return try AIResponseParser.parseNutritionFromRawText(text: response, fallbackDish: query)
    }

    func getCoachAdvice(userStats: UserStats?, logs: [NutritionManager.FoodLog],
                        healthData: String, historyTOON: String, userQuery: String) async throws -> String {
        var ctx = "User Stats: "
        if let stats = userStats {
            ctx += "Age \(stats.age), \(stats.gender), \(stats.weight)kg, Goal: \(stats.goal). "
        }
        ctx += "\nHealth: \(healthData). Food:\n\(historyTOON)"
        let system = PromptTemplates.coachSystemPrompt(forLocal: true)
        let prompt = PromptTemplates.coachFullPrompt(systemPrompt: system, context: ctx, query: userQuery, forLocal: true)
        return try await generate(prompt: prompt, maxTokens: 1000)
    }

    func generateMealPlan(userStats: UserStats?, calorieBudget: Int) async throws -> [PlannedMeal] {
        var ctx = "Calorie budget: \(calorieBudget) kcal/day."
        if let stats = userStats {
            ctx += " User: \(stats.age)yo \(stats.gender), \(stats.weight)kg, goal: \(stats.goal)."
        }
        let prompt = PromptTemplates.mealPlanPrompt(context: ctx, forLocal: true)
        let response = try await generate(prompt: prompt, maxTokens: 2048)
        return try AIResponseParser.parseMealPlanFromRawText(text: response)
    }

    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double) {
        let prompt = PromptTemplates.portionEstimationPrompt(forLocal: true)
        let response = try await generate(prompt: prompt)
        let parsed = try AIResponseParser.parseNutritionFromRawText(text: response, fallbackDish: "Detected Food")
        let grams = AIResponseParser.extractPortionGramsFromRawText(text: response)
        return (parsed.name, parsed.info, grams)
    }

    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String {
        let prompt = PromptTemplates.beforeAfterPrompt(forLocal: true)
        return try await generate(prompt: prompt, maxTokens: 1000)
    }

    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        let prompt = PromptTemplates.ocrNutritionLabelPrompt(forLocal: true)
        let response = try await generate(prompt: prompt)
        return try AIResponseParser.parseNutritionFromRawText(text: response, fallbackDish: "Scanned Product")
    }

    func generateInsights(foodHistory: String, calorieBudget: Int, userStats: UserStats?) async throws -> String {
        let prompt = PromptTemplates.insightsPrompt(context: foodHistory, forLocal: true)
        return try await generate(prompt: prompt, maxTokens: 1000)
    }
}

// MARK: - Error Types

enum GemmaError: LocalizedError {
    case modelLoadFailed
    case contextCreateFailed
    case samplerCreateFailed
    case notInitialized
    case tokenizeFailed
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed: return "Failed to load on-device AI model. The file may be corrupted — try deleting and re-downloading."
        case .contextCreateFailed: return "Failed to initialize AI context. Your device may not have enough memory."
        case .samplerCreateFailed: return "Failed to create AI sampler."
        case .notInitialized: return "On-device AI is not initialized."
        case .tokenizeFailed: return "Failed to process the input text."
        case .decodeFailed: return "AI inference failed. Try again or switch to Gemini Cloud."
        }
    }
}
