import Foundation
import UIKit

class APIService {
    static let shared = APIService()

    // MARK: - Configuration
    // In production, set PROXY_BASE_URL to your Firebase Functions URL.
    // The proxy holds the Gemini key server-side so it never ships in the app.
    // For local development, set GEMINI_API_KEY in Secrets.xcconfig (git-ignored).
    private let proxyBaseURL: String? = {
        Bundle.main.infoDictionary?["PROXY_BASE_URL"] as? String
    }()

    private let directApiKey: String? = {
        Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
    }()

    private let modelName = "gemini-flash-latest"

    // MARK: - Rate Limiting
    private var lastRequestTime: Date?
    private var dailyRequestCount = 0
    private var dailyCountDate: String = ""

    private func checkRateLimit() throws {
        let now = Date()
        let today = ISO8601DateFormatter().string(from: now).prefix(10)

        if String(today) != dailyCountDate {
            dailyRequestCount = 0
            dailyCountDate = String(today)
        }

        if let last = lastRequestTime, now.timeIntervalSince(last) < 1.0 {
            throw NSError(domain: "RateLimit", code: 429, userInfo: [NSLocalizedDescriptionKey: "Please wait a moment between requests."])
        }

        if dailyRequestCount >= 100 {
            throw NSError(domain: "RateLimit", code: 429, userInfo: [NSLocalizedDescriptionKey: "Daily request limit reached. Try again tomorrow."])
        }

        dailyRequestCount += 1
        lastRequestTime = now
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
        throw lastError ?? NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request failed after retries"])
    }

    // MARK: - Analyze Food
    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        try checkRateLimit()

        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }

        let (data, _) = try await sendAnalyzeFoodRequest(imageBase64: base64Image)
        return try parseNutritionResponse(data: data, fallbackDish: "AI Detected Food")
    }

    // MARK: - Search Food (Text)
    func searchFood(query: String) async throws -> (name: String, info: NutritionInfo) {
        try checkRateLimit()

        let (data, _) = try await sendSearchFoodRequest(query: query)
        return try parseNutritionResponse(data: data, fallbackDish: query)
    }

    // MARK: - AI Coach
    func getCoachAdvice(userStats: UserStats?, logs: [NutritionManager.FoodLog], healthData: String, historyTOON: String, userQuery: String) async throws -> String {
        try checkRateLimit()

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

        let (data, _) = try await sendCoachRequest(context: context, query: userQuery)
        return parseCoachResponse(data: data)
    }

    // MARK: - Private Request Builders

    private func sendAnalyzeFoodRequest(imageBase64: String) async throws -> (Data, URLResponse) {
        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            // Use backend proxy (production)
            let body: [String: Any] = ["image_base64": imageBase64]
            return try await postJSON(url: "\(proxyURL)/api/v1/analyze-food", body: body)
        } else if let apiKey = directApiKey, !apiKey.isEmpty {
            // Direct Gemini call (development only)
            let promptText = """
            Analyze this food image. Identify the dish.
            Return a JSON object with these exact keys:
            - "Dish": Name of the dish
            - "Calories per 100g": Estimated calories (number as string)
            - "Carbohydrate per 100g": Estimated carbs (number as string)
            - "Protein per 100 gm": Estimated protein (number as string)
            - "Fats per 100 gm": Estimated fats (number as string)
            - "Healthier Recipe": A short advice to make it healthier
            - "Source": "AI Analysis"
            - "micros": A dictionary of key micronutrients (e.g., "Vitamin A": "10%", "Iron": "5mg")
            Return ONLY the JSON.
            """

            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": promptText],
                    ["inline_data": ["mime_type": "image/jpeg", "data": imageBase64]]
                ]]],
                "generationConfig": ["responseMimeType": "application/json"]
            ]

            return try await postJSON(url: geminiURL(apiKey: apiKey), body: body)
        } else {
            throw NSError(domain: "ConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API configuration. Set PROXY_BASE_URL or GEMINI_API_KEY."])
        }
    }

    private func sendSearchFoodRequest(query: String) async throws -> (Data, URLResponse) {
        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["query": query]
            return try await postJSON(url: "\(proxyURL)/api/v1/search-food", body: body)
        } else if let apiKey = directApiKey, !apiKey.isEmpty {
            let promptText = """
            Analyze this food query: "\(query)".
            Return a JSON object with these exact keys:
            - "Dish": Name of the dish (be specific based on query)
            - "Calories per 100g": Estimated calories (number as string)
            - "Carbohydrate per 100g": Estimated carbs (number as string)
            - "Protein per 100 gm": Estimated protein (number as string)
            - "Fats per 100 gm": Estimated fats (number as string)
            - "Healthier Recipe": A short advice to make it healthier
            - "Source": "AI Analysis"
            - "micros": A dictionary of key micronutrients
            Return ONLY the JSON.
            """

            let body: [String: Any] = [
                "contents": [["parts": [["text": promptText]]]],
                "generationConfig": ["responseMimeType": "application/json"]
            ]

            return try await postJSON(url: geminiURL(apiKey: apiKey), body: body)
        } else {
            throw NSError(domain: "ConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API configuration."])
        }
    }

    private func sendCoachRequest(context: String, query: String) async throws -> (Data, URLResponse) {
        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["context": context, "query": query]
            return try await postJSON(url: "\(proxyURL)/api/v1/coach-advice", body: body)
        } else if let apiKey = directApiKey, !apiKey.isEmpty {
            let systemPrompt = """
            You are a friendly and motivating professional health coach.
            You have access to the user's data for the last 30 days.
            Be concise (max 150 words).
            """
            let fullPrompt = "System: \(systemPrompt)\n\nContext:\n\(context)\n\nUser Request: \(query)"

            let body: [String: Any] = [
                "contents": [["parts": [["text": fullPrompt]]]],
                "generationConfig": ["maxOutputTokens": 1000, "temperature": 0.7]
            ]

            return try await postJSON(url: geminiURL(apiKey: apiKey), body: body)
        } else {
            throw NSError(domain: "ConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API configuration."])
        }
    }

    // MARK: - Helpers

    private func geminiURL(apiKey: String) -> String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
    }

    private func postJSON(url: String, body: [String: Any]) async throws -> (Data, URLResponse) {
        guard let endpoint = URL(string: url) else {
            throw NSError(domain: "URLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await performRequest(request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("API Error (\(httpResponse.statusCode)): \(errorMsg)")
            throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(httpResponse.statusCode)"])
        }

        return (data, response)
    }

    private func parseNutritionResponse(data: Data, fallbackDish: String) throws -> (name: String, info: NutritionInfo) {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {

            let cleanContent = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let jsonData = cleanContent.data(using: .utf8) {
                let info = try JSONDecoder().decode(NutritionInfo.self, from: jsonData)

                var dishName = fallbackDish
                if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let name = dict["Dish"] as? String {
                    dishName = name
                }

                return (dishName, info)
            }
        }

        throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }

    private func parseCoachResponse(data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            return "Coach Error: Unable to parse response."
        }

        var resultText: String?
        if let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            resultText = text
        }

        if let finishReason = firstCandidate["finishReason"] as? String {
            if finishReason == "MAX_TOKENS" {
                return (resultText ?? "") + " [Truncated]"
            }
            if finishReason == "SAFETY" || finishReason == "RECITATION" {
                return "Coach stopped due to Safety filters."
            }
        }

        return resultText ?? "Coach Error: Empty response."
    }
}
