import Foundation

/// Centralized response parsing logic extracted from APIService.
/// Two parse paths per response type: one for cloud Gemini (envelope with
/// `candidates[0].content.parts[0].text`) and one for raw text (on-device Gemma).
struct AIResponseParser {

    // MARK: - Nutrition Parsing (Cloud Envelope)

    /// Unwraps the Gemini REST envelope, strips markdown fences, decodes NutritionInfo,
    /// and extracts the dish name from the "Dish" key.
    static func parseNutritionFromGeminiEnvelope(data: Data, fallbackDish: String) throws -> (name: String, info: NutritionInfo) {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {

            return try parseNutritionFromRawText(text: text, fallbackDish: fallbackDish)
        }

        throw NSError(domain: "AIResponseParser", code: -1,
                       userInfo: [NSLocalizedDescriptionKey: "Failed to parse nutrition response from Gemini envelope"])
    }

    // MARK: - Nutrition Parsing (Raw Text)

    /// Takes raw text (from on-device Gemma or pre-extracted), finds the JSON object
    /// between the first `{` and last `}`, strips markdown fences, and decodes NutritionInfo.
    static func parseNutritionFromRawText(text: String, fallbackDish: String) throws -> (name: String, info: NutritionInfo) {
        let cleanContent = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON object boundaries for extra robustness with local models
        var jsonString = cleanContent
        if let startIdx = cleanContent.firstIndex(of: "{"),
           let endIdx = cleanContent.lastIndex(of: "}") {
            jsonString = String(cleanContent[startIdx...endIdx])
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "AIResponseParser", code: -1,
                           userInfo: [NSLocalizedDescriptionKey: "Failed to convert cleaned text to data"])
        }

        let info = try JSONDecoder().decode(NutritionInfo.self, from: jsonData)

        var dishName = fallbackDish
        if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let name = dict["Dish"] as? String {
            dishName = name
        }

        return (dishName, info)
    }

    // MARK: - Text Parsing (Cloud Envelope)

    /// Unwraps the Gemini REST envelope for text responses (coach, insights, before/after).
    /// Handles finishReason: SAFETY, RECITATION, MAX_TOKENS.
    static func parseTextFromGeminiEnvelope(data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            return "Error: Unable to parse response."
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
                return "Response stopped due to Safety filters."
            }
        }

        return resultText ?? "Error: Empty response."
    }

    // MARK: - Text Parsing (Raw Text)

    /// For on-device Gemma: the text is already the final output; just trim whitespace.
    static func parseTextFromRawText(text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Meal Plan Parsing (Cloud Envelope)

    /// Unwraps the Gemini REST envelope, strips markdown fences, parses a JSON array
    /// of PlannedMeal objects.
    static func parseMealPlanFromGeminiEnvelope(data: Data) throws -> [PlannedMeal] {
        var text = ""
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let t = parts.first?["text"] as? String {
            text = t
        }

        return try parseMealPlanFromRawText(text: text)
    }

    // MARK: - Meal Plan Parsing (Raw Text)

    /// Takes raw text, strips markdown fences, finds and parses a JSON array of PlannedMeal.
    static func parseMealPlanFromRawText(text: String) throws -> [PlannedMeal] {
        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON array boundaries for robustness with local models
        var jsonString = clean
        if let startIdx = clean.firstIndex(of: "["),
           let endIdx = clean.lastIndex(of: "]") {
            jsonString = String(clean[startIdx...endIdx])
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let arr = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw NSError(domain: "AIResponseParser", code: -1,
                           userInfo: [NSLocalizedDescriptionKey: "Failed to parse meal plan."])
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

            return PlannedMeal(day: day, breakfast: breakfast, lunch: lunch,
                               dinner: dinner, snack: snack, totalCalories: totalCals)
        }
    }

    // MARK: - Portion Grams Extraction

    /// Extracts the `estimatedGrams` value from a Gemini cloud envelope.
    /// Falls back to 100g if not found.
    static func extractPortionGramsFromGeminiEnvelope(data: Data) -> Double {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return extractPortionGramsFromRawText(text: text)
        }
        return 100
    }

    /// Extracts the `estimatedGrams` value from raw text. Falls back to 100g.
    static func extractPortionGramsFromRawText(text: String) -> Double {
        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonData = clean.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            if let g = dict["estimatedGrams"] as? Double {
                return g
            } else if let g = dict["estimatedGrams"] as? Int {
                return Double(g)
            }
        }
        return 100
    }
}
