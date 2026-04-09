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

    // MARK: - Meal Plan Generation
    func generateMealPlan(userStats: UserStats?, calorieBudget: Int) async throws -> [PlannedMeal] {
        try checkRateLimit()

        var context = "Generate a 7-day meal plan. "
        if let stats = userStats {
            context += "User: \(stats.age)yo \(stats.gender), \(stats.weight)kg, goal: \(stats.goal). "
        }
        context += "Daily calorie budget: \(calorieBudget) kcal."

        let prompt = """
        \(context)
        Return a JSON array of 7 objects, each with:
        - "day": "Monday" through "Sunday"
        - "breakfast": meal description
        - "lunch": meal description
        - "dinner": meal description
        - "snack": snack description
        - "totalCalories": estimated total calories (number)
        Return ONLY the JSON array.
        """

        let (data, _) = try await sendGenericPrompt(prompt: prompt, useJSON: true)
        return try parseMealPlanResponse(data: data)
    }

    // MARK: - Portion Estimation
    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double) {
        try checkRateLimit()

        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }

        let prompt = """
        Analyze this food image and estimate the portion size in grams.
        Return a JSON object with:
        - "Dish": name of the food
        - "estimatedGrams": estimated weight in grams (number)
        - "Calories per 100g": calories per 100g (number as string)
        - "Carbohydrate per 100g": carbs per 100g (number as string)
        - "Protein per 100 gm": protein per 100g (number as string)
        - "Fats per 100 gm": fats per 100g (number as string)
        - "Healthier Recipe": brief healthier suggestion
        - "Source": "AI Portion Estimate"
        - "micros": dictionary of micronutrients
        Return ONLY the JSON.
        """

        let (data, _) = try await sendImagePrompt(imageBase64: base64Image, prompt: prompt)
        let parsed = try parseNutritionResponse(data: data, fallbackDish: "Detected Food")

        // Extract estimated grams
        var grams: Double = 100
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            let clean = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let jsonData = clean.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let g = dict["estimatedGrams"] as? Double {
                    grams = g
                } else if let g = dict["estimatedGrams"] as? Int {
                    grams = Double(g)
                }
            }
        }

        return (parsed.name, parsed.info, grams)
    }

    // MARK: - Before/After Comparison
    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String {
        try checkRateLimit()

        guard let beforeBase64 = before.jpegData(compressionQuality: 0.5)?.base64EncodedString(),
              let afterBase64 = after.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode images"])
        }

        let prompt = """
        Compare these two food images (before and after eating).
        Analyze:
        1. What food was on the plate before
        2. How much was consumed (percentage estimate)
        3. Estimated calories consumed
        4. Nutritional assessment
        Be concise (max 150 words).
        """

        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["before_image": beforeBase64, "after_image": afterBase64, "prompt": prompt]
            let (data, _) = try await postJSON(url: "\(proxyURL)/api/v1/compare-food", body: body)
            return parseCoachResponse(data: data)
        } else if let apiKey = directApiKey, !apiKey.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": beforeBase64]],
                    ["inline_data": ["mime_type": "image/jpeg", "data": afterBase64]]
                ]]],
                "generationConfig": ["maxOutputTokens": 1000, "temperature": 0.5]
            ]
            let (data, _) = try await postJSON(url: geminiURL(apiKey: apiKey), body: body)
            return parseCoachResponse(data: data)
        } else {
            throw NSError(domain: "ConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API configuration."])
        }
    }

    // MARK: - OCR Nutrition Label
    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        try checkRateLimit()

        guard let base64Image = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }

        let prompt = """
        Read this nutrition facts label using OCR.
        Return a JSON object with:
        - "Dish": product name if visible, else "Scanned Product"
        - "Calories per 100g": calories (number as string)
        - "Carbohydrate per 100g": carbs (number as string)
        - "Protein per 100 gm": protein (number as string)
        - "Fats per 100 gm": fats (number as string)
        - "Healthier Recipe": "Scanned from nutrition label"
        - "Source": "OCR Scan"
        - "micros": dictionary of any micronutrients found (e.g., vitamins, minerals)
        Return ONLY the JSON.
        """

        let (data, _) = try await sendImagePrompt(imageBase64: base64Image, prompt: prompt)
        return try parseNutritionResponse(data: data, fallbackDish: "Scanned Product")
    }

    // MARK: - Generate Insights
    func generateInsights(foodHistory: String, calorieBudget: Int, userStats: UserStats?) async throws -> String {
        try checkRateLimit()

        var context = "Calorie budget: \(calorieBudget) kcal/day. "
        if let stats = userStats {
            context += "User: \(stats.age)yo \(stats.gender), \(stats.weight)kg, goal: \(stats.goal). "
        }
        context += "\nFood history:\n\(foodHistory)"

        let prompt = """
        Based on this nutrition data, provide 3-5 actionable insights and tips.
        Be specific, concise, and encouraging. Max 200 words.
        \(context)
        """

        let (data, _) = try await sendGenericPrompt(prompt: prompt, useJSON: false)
        return parseCoachResponse(data: data)
    }

    // MARK: - Generic Prompt Helpers

    private func sendGenericPrompt(prompt: String, useJSON: Bool) async throws -> (Data, URLResponse) {
        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["prompt": prompt]
            return try await postJSON(url: "\(proxyURL)/api/v1/generate", body: body)
        } else if let apiKey = directApiKey, !apiKey.isEmpty {
            var config: [String: Any] = ["maxOutputTokens": 2000, "temperature": 0.7]
            if useJSON {
                config["responseMimeType"] = "application/json"
            }
            let body: [String: Any] = [
                "contents": [["parts": [["text": prompt]]]],
                "generationConfig": config
            ]
            return try await postJSON(url: geminiURL(apiKey: apiKey), body: body)
        } else {
            throw NSError(domain: "ConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API configuration."])
        }
    }

    private func sendImagePrompt(imageBase64: String, prompt: String) async throws -> (Data, URLResponse) {
        if let proxyURL = proxyBaseURL, !proxyURL.isEmpty {
            let body: [String: Any] = ["image_base64": imageBase64, "prompt": prompt]
            return try await postJSON(url: "\(proxyURL)/api/v1/analyze-image", body: body)
        } else if let apiKey = directApiKey, !apiKey.isEmpty {
            let body: [String: Any] = [
                "contents": [["parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": imageBase64]]
                ]]],
                "generationConfig": ["responseMimeType": "application/json"]
            ]
            return try await postJSON(url: geminiURL(apiKey: apiKey), body: body)
        } else {
            throw NSError(domain: "ConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API configuration."])
        }
    }

    private func parseMealPlanResponse(data: Data) throws -> [PlannedMeal] {
        var text = ""
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let t = parts.first?["text"] as? String {
            text = t
        }

        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = clean.data(using: .utf8),
              let arr = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse meal plan."])
        }

        return arr.compactMap { dict in
            guard let day = dict["day"] as? String,
                  let breakfast = dict["breakfast"] as? String,
                  let lunch = dict["lunch"] as? String,
                  let dinner = dict["dinner"] as? String,
                  let snack = dict["snack"] as? String else { return nil }

            var totalCals = 0
            if let c = dict["totalCalories"] as? Int { totalCals = c }
            else if let c = dict["totalCalories"] as? Double { totalCals = Int(c) }

            return PlannedMeal(day: day, breakfast: breakfast, lunch: lunch, dinner: dinner, snack: snack, totalCalories: totalCals)
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
