import Foundation
import UIKit
import llama

/// On-device AI provider using Gemma 4 E2B via llama.cpp with vision support.
/// Uses the mtmd (multimodal) API for image analysis — the model can see food photos
/// and return nutrition data directly.
final class GemmaLocalProvider: AIProvider {

    static let isInferenceAvailable = true

    let providerName = "On-Device AI"

    private let modelPath: String
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var mtmdCtx: OpaquePointer?  // mtmd_context for vision

    init(modelPath: String) {
        self.modelPath = modelPath
    }

    deinit {
        if let sampler { llama_sampler_free(sampler) }
        if let context { llama_free(context) }
        if let model { llama_model_free(model) }
        if let mtmdCtx { mtmd_free(mtmdCtx) }
    }

    // MARK: - Model Loading (lazy)

    private func ensureLoaded() throws {
        guard model == nil else { return }

        llama_backend_init()

        var mparams = llama_model_default_params()
        mparams.n_gpu_layers = 99  // E2B Q4_K_M (~3.2 GB) fits entirely on GPU

        guard let m = llama_model_load_from_file(modelPath, mparams) else {
            throw GemmaError.modelLoadFailed
        }
        model = m

        var cparams = llama_context_default_params()
        cparams.n_ctx = 2048
        cparams.n_batch = 512

        guard let c = llama_init_from_model(m, cparams) else {
            throw GemmaError.contextCreateFailed
        }
        context = c

        // Build sampler chain
        let sparams = llama_sampler_chain_default_params()
        guard let chain = llama_sampler_chain_init(sparams) else {
            throw GemmaError.samplerCreateFailed
        }
        llama_sampler_chain_add(chain, llama_sampler_init_temp(0.7))
        llama_sampler_chain_add(chain, llama_sampler_init_top_k(40))
        llama_sampler_chain_add(chain, llama_sampler_init_top_p(0.9, 1))
        llama_sampler_chain_add(chain, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))
        sampler = chain

        // Initialize vision (mtmd) — use the mmproj from ModelDownloadManager
        let mmprojPath = ModelDownloadManager.shared.mmprojPath
        if ModelDownloadManager.shared.isMmprojAvailable {
            var mtmdParams = mtmd_context_params_default()
            mtmdCtx = mtmd_init_from_file(mmprojPath, m, mtmdParams)
        }
    }

    // MARK: - Gemma Chat Template

    private func formatPrompt(system: String? = nil, user: String) -> String {
        var formatted = ""
        if let system, !system.isEmpty {
            formatted += "<start_of_turn>system\n\(system)<end_of_turn>\n"
        }
        formatted += "<start_of_turn>user\n\(user)<end_of_turn>\n<start_of_turn>model\n"
        return formatted
    }

    // MARK: - Text Generation

    private func generate(prompt: String, system: String? = nil, maxTokens: Int = 1024) async throws -> String {
        let formattedPrompt = formatPrompt(system: system, user: prompt)

        try ensureLoaded()
        guard let model, let context, let sampler else {
            throw GemmaError.notInitialized
        }

        let vocab = llama_model_get_vocab(model)!

        // Tokenize
        let promptBytes = Array(formattedPrompt.utf8)
        let maxInputTokens = Int32(promptBytes.count + 256)
        var tokens = [llama_token](repeating: 0, count: Int(maxInputTokens))
        let nTokens = promptBytes.withUnsafeBufferPointer { buf in
            llama_tokenize(vocab, buf.baseAddress, Int32(buf.count),
                           &tokens, maxInputTokens, true, true)
        }
        guard nTokens > 0 else { throw GemmaError.tokenizeFailed }
        tokens = Array(tokens.prefix(Int(nTokens)))

        // Clear KV cache
        let mem = llama_get_memory(context)
        llama_memory_clear(mem, true)
        llama_sampler_reset(sampler)

        // Decode prompt in chunks
        let batchSize = Int(llama_n_batch(context))
        var offset = 0
        while offset < tokens.count {
            let chunkSize = min(batchSize, tokens.count - offset)
            var chunk = Array(tokens[offset..<(offset + chunkSize)])
            let batch = llama_batch_get_one(&chunk, Int32(chunkSize))
            guard llama_decode(context, batch) == 0 else { throw GemmaError.decodeFailed }
            offset += chunkSize
        }

        // Generate tokens
        var result = ""
        for _ in 0..<maxTokens {
            let newToken = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocab, newToken) { break }

            var buf = [CChar](repeating: 0, count: 256)
            let len = llama_token_to_piece(vocab, newToken, &buf, 256, 0, false)
            if len > 0 {
                buf[Int(len)] = 0
                result += String(cString: buf)
            }

            var nextToken = newToken
            let nextBatch = llama_batch_get_one(&nextToken, 1)
            guard llama_decode(context, nextBatch) == 0 else { break }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Vision Generation (image + text prompt)

    private func generateWithImage(prompt: String, system: String? = nil, image: UIImage, maxTokens: Int = 1024) async throws -> String {
        try ensureLoaded()

        // If no vision model loaded, fall back to text-only with image description
        guard let mtmdCtx else {
            let textPrompt = "The user showed a photo of food. \(prompt)"
            return try await generate(prompt: textPrompt, system: system, maxTokens: maxTokens)
        }

        guard let model, let context, let sampler else {
            throw GemmaError.notInitialized
        }

        let vocab = llama_model_get_vocab(model)!
        let formattedPrompt = formatPrompt(system: system, user: "\(mtmd_default_marker()!.pointee == 0 ? "<image>" : String(cString: mtmd_default_marker()!))\n\(prompt)")

        // Convert UIImage to JPEG bytes
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw GemmaError.decodeFailed
        }

        // Create bitmap from JPEG data
        let bitmap = jpegData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> OpaquePointer? in
            return mtmd_helper_bitmap_init_from_buf(mtmdCtx, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), jpegData.count)
        }
        guard let bitmap else {
            // Vision preprocessing failed, fall back to text
            return try await generate(prompt: prompt, system: system, maxTokens: maxTokens)
        }
        defer { mtmd_bitmap_free(bitmap) }

        // Tokenize with vision
        let chunks = mtmd_input_chunks_init()!
        defer { mtmd_input_chunks_free(chunks) }

        let textInput = formattedPrompt.withCString { cStr -> mtmd_input_text in
            return mtmd_input_text(text: cStr, add_special: true, parse_special: true)
        }

        var bitmapPtr: OpaquePointer? = bitmap
        var textInputVar = textInput
        let tokenizeResult = withUnsafeMutablePointer(to: &bitmapPtr) { ptr in
            return mtmd_tokenize(mtmdCtx, chunks, &textInputVar, ptr, 1)
        }

        guard tokenizeResult == 0 else {
            return try await generate(prompt: prompt, system: system, maxTokens: maxTokens)
        }

        // Clear KV cache
        let mem = llama_get_memory(context)
        llama_memory_clear(mem, true)
        llama_sampler_reset(sampler)

        // Evaluate all chunks (text + image embeddings)
        var newNPast: llama_pos = 0
        let evalResult = mtmd_helper_eval_chunks(mtmdCtx, context, chunks, 0, 0, 512, true, &newNPast)
        guard evalResult == 0 else {
            return try await generate(prompt: prompt, system: system, maxTokens: maxTokens)
        }

        // Generate tokens
        var result = ""
        for _ in 0..<maxTokens {
            let newToken = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocab, newToken) { break }

            var buf = [CChar](repeating: 0, count: 256)
            let len = llama_token_to_piece(vocab, newToken, &buf, 256, 0, false)
            if len > 0 {
                buf[Int(len)] = 0
                result += String(cString: buf)
            }

            var nextToken = newToken
            let nextBatch = llama_batch_get_one(&nextToken, 1)
            guard llama_decode(context, nextBatch) == 0 else { break }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - AIProvider

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        let prompt = PromptTemplates.analyzeFoodPrompt(forLocal: true)
        let response = try await generateWithImage(prompt: prompt, image: image)
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
        return try await generate(prompt: "Context:\n\(ctx)\n\nUser Request: \(userQuery)", system: system, maxTokens: 500)
    }

    func generateMealPlan(userStats: UserStats?, calorieBudget: Int) async throws -> [PlannedMeal] {
        var ctx = "Calorie budget: \(calorieBudget) kcal/day."
        if let stats = userStats {
            ctx += " User: \(stats.age)yo \(stats.gender), \(stats.weight)kg, goal: \(stats.goal)."
        }
        let prompt = PromptTemplates.mealPlanPrompt(context: ctx, forLocal: true)
        let response = try await generate(prompt: prompt, maxTokens: 1024)
        return try AIResponseParser.parseMealPlanFromRawText(text: response)
    }

    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double) {
        let prompt = PromptTemplates.portionEstimationPrompt(forLocal: true)
        let response = try await generateWithImage(prompt: prompt, image: image)
        let parsed = try AIResponseParser.parseNutritionFromRawText(text: response, fallbackDish: "Detected Food")
        let grams = AIResponseParser.extractPortionGramsFromRawText(text: response)
        return (parsed.name, parsed.info, grams)
    }

    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String {
        let prompt = PromptTemplates.beforeAfterPrompt(forLocal: true)
        return try await generateWithImage(prompt: prompt, image: before, maxTokens: 500)
    }

    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        let prompt = PromptTemplates.ocrNutritionLabelPrompt(forLocal: true)
        let response = try await generateWithImage(prompt: prompt, image: image)
        return try AIResponseParser.parseNutritionFromRawText(text: response, fallbackDish: "Scanned Product")
    }

    func generateInsights(foodHistory: String, calorieBudget: Int, userStats: UserStats?) async throws -> String {
        let prompt = PromptTemplates.insightsPrompt(context: foodHistory, forLocal: true)
        return try await generate(prompt: prompt, maxTokens: 500)
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
