import Foundation
import UIKit

/// AIProvider implementation that calls the Gemini REST API (directly or via a backend proxy).
/// Extracted from `APIService` -- all HTTP/Gemini logic lives here.
class GeminiCloudProvider: AIProvider {

    // MARK: - Configuration

    let providerName = "Gemini Cloud"

    private let apiKey: String?
    private let proxyBaseURL: String?
    private let modelName = "gemini-flash-latest"

    // MARK: - Rate Limiting

    private struct RateLimitState {
        var lastRequestTime: Date?
        var dailyRequestCount: Int = 0
        var dailyCountDate: String = ""
    }

    private var rateLimit = RateLimitState()

    // MARK: - Init

    /// At least one of `apiKey` or `proxyBaseURL` must be non-nil.
    init(apiKey: String?, proxyBaseURL: String?) {
        precondition(apiKey != nil || proxyBaseURL != nil,
                     "GeminiCloudProvider requires at least one of apiKey or proxyBaseURL")
        self.apiKey = apiKey
        self.proxyBaseURL = proxyBaseURL
    }

    // MARK: - Rate Limiting

    private func checkRateLimit() throws {
        let now = Date()
        let today = ISO8601DateFormatter().string(from: now).prefix(10)

        if String(today) != rateLimit.dailyCountDate {
            rateLimit.dailyRequestCount = 0
            rateLimit.dailyCountDate = String(today)
        }

        if let last = rateLimit.lastRequestTime, now.timeIntervalSince(last) < 1.0 {
            throw NSError(domain: "RateLimit", code: 429,
                          userInfo: [NSLocalizedDescriptionKey: "Please wait a moment between requests."])
        }

        if rateLimit.dailyRequestCount >= 100 {
            throw NSError(domain: "RateLimit", code: 429,
                          userInfo: [NSLocalizedDescriptionKey: "Daily request limit reached. Try again tomorrow."])
        }

        rateLimit.dailyRequestCount += 1
        rateLimit.lastRequestTime = now
    }

    // MARK: - Retry Logic

    private func performRequest(_ request: URLRequest, retries: Int = 3) async throws -> (Data, URLResponse) {
        var lastError: Error?
        for attempt in 0..<retries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode >= 500 && attempt < retries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                    continue
                }
                return (data, response)
            } catch {
                lastError = error
                if attempt < retries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
            }
        }
        throw lastError ?? NSError(domain: "APIError", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Request failed after retries"])
    }

    // MARK: - AIProvider Methods

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        try checkRateLimit()

        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["image_base64": base64Image]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/analyze-food", body: body)
            return try AIResponseParser.parseNutritionFromGeminiEnvelope(data: data, fallbackDish: "AI Detected Food")
        } else if let key = apiKey, !key.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": PromptTemplates.analyzeFoodPrompt(forLocal: false)],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]]
                ]]],
                "generationConfig": ["responseMimeType": "application/json"]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            return try AIResponseParser.parseNutritionFromGeminiEnvelope(data: data, fallbackDish: "AI Detected Food")
        } else {
            throw configError()
        }
    }

    func searchFood(query: String) async throws -> (name: String, info: NutritionInfo) {
        try checkRateLimit()

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["query": query]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/search-food", body: body)
            return try AIResponseParser.parseNutritionFromGeminiEnvelope(data: data, fallbackDish: query)
        } else if let key = apiKey, !key.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": PromptTemplates.searchFoodPrompt(query: query, forLocal: false)]
                ]]],
                "generationConfig": ["responseMimeType": "application/json"]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            return try AIResponseParser.parseNutritionFromGeminiEnvelope(data: data, fallbackDish: query)
        } else {
            throw configError()
        }
    }

    func getCoachAdvice(userStats: UserStats?, logs: [NutritionManager.FoodLog],
                        healthData: String, historyTOON: String, userQuery: String) async throws -> String {
        try checkRateLimit()

        // Build context the same way APIService does
        var context = "User Stats: "
        if let stats = userStats {
            context += "Age \(stats.age), \(stats.gender), \(stats.weight)kg, Goal: \(stats.goal). "
        } else {
            context += "Goal: Stay healthy. "
        }

        context += "\nToday's Health: \(healthData)."

        context += "\nToday's Food: "
        if logs.isEmpty {
            context += "Nothing logged yet."
        } else {
            for log in logs.prefix(10) {
                context += "\(log.food) (\(log.calories)kcal), "
            }
        }

        context += "\n\nPast 30 Days History (TOON Format):\n"
        context += historyTOON

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["context": context, "query": userQuery]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/coach-advice", body: body)
            return AIResponseParser.parseTextFromGeminiEnvelope(data: data)
        } else if let key = apiKey, !key.isEmpty {
            let systemPrompt = PromptTemplates.coachSystemPrompt(forLocal: false)
            let fullPrompt = PromptTemplates.coachFullPrompt(systemPrompt: systemPrompt,
                                                              context: context,
                                                              query: userQuery,
                                                              forLocal: false)
            let body: [String: Any] = [
                "contents": [["parts": [["text": fullPrompt]]]],
                "generationConfig": ["maxOutputTokens": 1000, "temperature": 0.7]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            return AIResponseParser.parseTextFromGeminiEnvelope(data: data)
        } else {
            throw configError()
        }
    }

    func generateMealPlan(userStats: UserStats?, calorieBudget: Int) async throws -> [PlannedMeal] {
        try checkRateLimit()

        var context = "Generate a 7-day meal plan. "
        if let stats = userStats {
            context += "User: \(stats.age)yo \(stats.gender), \(stats.weight)kg, goal: \(stats.goal). "
        }
        context += "Daily calorie budget: \(calorieBudget) kcal."

        let prompt = PromptTemplates.mealPlanPrompt(context: context, forLocal: false)

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["prompt": prompt]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/generate", body: body)
            return try AIResponseParser.parseMealPlanFromGeminiEnvelope(data: data)
        } else if let key = apiKey, !key.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [["text": prompt]]]],
                "generationConfig": [
                    "responseMimeType": "application/json",
                    "maxOutputTokens": 2000,
                    "temperature": 0.7
                ]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            return try AIResponseParser.parseMealPlanFromGeminiEnvelope(data: data)
        } else {
            throw configError()
        }
    }

    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double) {
        try checkRateLimit()

        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }

        let prompt = PromptTemplates.portionEstimationPrompt(forLocal: false)

        let data: Data
        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["image_base64": base64Image, "prompt": prompt]
            let (d, _) = try await postJSON(url: "\(proxyURL)/api/v1/analyze-image", body: body)
            data = d
        } else if let key = apiKey, !key.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]]
                ]]],
                "generationConfig": ["responseMimeType": "application/json"]
            ]
            let (d, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            data = d
        } else {
            throw configError()
        }

        let parsed = try AIResponseParser.parseNutritionFromGeminiEnvelope(data: data, fallbackDish: "Detected Food")
        let grams = AIResponseParser.extractPortionGramsFromGeminiEnvelope(data: data)
        return (parsed.name, parsed.info, grams)
    }

    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String {
        try checkRateLimit()

        guard let beforeBase64 = before.jpegData(compressionQuality: 0.5)?.base64EncodedString(),
              let afterBase64 = after.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to encode images"])
        }

        let prompt = PromptTemplates.beforeAfterPrompt(forLocal: false)

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["before_image": beforeBase64, "after_image": afterBase64, "prompt": prompt]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/compare-food", body: body)
            return AIResponseParser.parseTextFromGeminiEnvelope(data: data)
        } else if let key = apiKey, !key.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": beforeBase64]],
                    ["inline_data": ["mime_type": "image/jpeg", "data": afterBase64]]
                ]]],
                "generationConfig": ["maxOutputTokens": 1000, "temperature": 0.5]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            return AIResponseParser.parseTextFromGeminiEnvelope(data: data)
        } else {
            throw configError()
        }
    }

    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        try checkRateLimit()

        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }

        let prompt = PromptTemplates.ocrNutritionLabelPrompt(forLocal: false)

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["image_base64": base64Image, "prompt": prompt]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/analyze-image", body: body)
            return try AIResponseParser.parseNutritionFromGeminiEnvelope(data: data, fallbackDish: "Scanned Product")
        } else if let key = apiKey, !key.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]]
                ]]],
                "generationConfig": ["responseMimeType": "application/json"]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            return try AIResponseParser.parseNutritionFromGeminiEnvelope(data: data, fallbackDish: "Scanned Product")
        } else {
            throw configError()
        }
    }

    func generateInsights(foodHistory: String, calorieBudget: Int, userStats: UserStats?) async throws -> String {
        try checkRateLimit()

        var context = "Calorie budget: \(calorieBudget) kcal/day. "
        if let stats = userStats {
            context += "User: \(stats.age)yo \(stats.gender), \(stats.weight)kg, goal: \(stats.goal). "
        }
        context += "\nFood history:\n\(foodHistory)"

        let prompt = PromptTemplates.insightsPrompt(context: context, forLocal: false)

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["prompt": prompt]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/generate", body: body)
            return AIResponseParser.parseTextFromGeminiEnvelope(data: data)
        } else if let key = apiKey, !key.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [["text": prompt]]]],
                "generationConfig": ["maxOutputTokens": 2000, "temperature": 0.7]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: key), body: body)
            return AIResponseParser.parseTextFromGeminiEnvelope(data: data)
        } else {
            throw configError()
        }
    }

    // MARK: - Helpers

    private func geminiURL(apiKey: String) -> String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
    }

    private func postJSON(url: String, body: [String: Any]) async throws -> (Data, URLResponse) {
        guard let endpoint = URL(string: url) else {
            throw NSError(domain: "URLError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await performRequest(request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("API Error (\(httpResponse.statusCode)): \(errorMsg)")
            throw NSError(domain: "APIError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "API Error: \(httpResponse.statusCode)"])
        }

        return (data, response)
    }

    private func configError() -> NSError {
        NSError(domain: "ConfigError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No API configuration. Set PROXY_BASE_URL or GEMINI_API_KEY."])
    }
}
