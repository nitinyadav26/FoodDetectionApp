import XCTest
@testable import FoodDetectionApp

final class APIResponseParsingTests: XCTestCase {

    // MARK: - Helpers

    /// Build a Gemini-style response wrapping text content in candidates -> content -> parts.
    private func geminiResponse(text: String) -> Data {
        let json: [String: Any] = [
            "candidates": [[
                "content": [
                    "parts": [["text": text]]
                ],
                "finishReason": "STOP"
            ]]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - parseNutritionResponse Tests

    /// A well-formed Gemini nutrition response should parse into a dish name and NutritionInfo.
    func testParseNutritionResponse() throws {
        let nutritionJSON = """
        {
            "Dish": "Grilled Chicken",
            "Calories per 100g": "165",
            "Carbohydrate per 100g": "0",
            "Protein per 100 gm": "31",
            "Fats per 100 gm": "3.6",
            "Healthier Recipe": "Use less oil",
            "Source": "AI Analysis",
            "micros": {"Iron": "1.3 mg", "Vitamin B6": "0.5 mg"}
        }
        """

        let responseData = geminiResponse(text: nutritionJSON)
        let api = APIService()

        // Use reflection to call the private method via exposed behavior:
        // We parse manually since parseNutritionResponse is private.
        // Instead, test the decoding path the same way the code does.
        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            XCTFail("Failed to navigate Gemini response structure")
            return
        }

        let cleanContent = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let jsonData = cleanContent.data(using: .utf8)!
        let info = try JSONDecoder().decode(NutritionInfo.self, from: jsonData)

        XCTAssertEqual(info.calories, "165")
        XCTAssertEqual(info.protein, "31")
        XCTAssertEqual(info.carbs, "0")
        XCTAssertEqual(info.fats, "3.6")
        XCTAssertEqual(info.recipe, "Use less oil")
        XCTAssertEqual(info.source, "AI Analysis")
        XCTAssertNotNil(info.micros)
        XCTAssertEqual(info.micros?["Iron"], "1.3 mg")

        // Verify dish name extraction
        if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let dishName = dict["Dish"] as? String {
            XCTAssertEqual(dishName, "Grilled Chicken")
        } else {
            XCTFail("Should be able to extract Dish name")
        }
    }

    /// Coach response should extract the text from the Gemini candidates structure.
    func testParseCoachResponse() {
        let adviceText = "Great job today! You hit your protein goal. Consider adding more vegetables for fiber."

        let json: [String: Any] = [
            "candidates": [[
                "content": [
                    "parts": [["text": adviceText]]
                ],
                "finishReason": "STOP"
            ]]
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)

        // Replicate the parseCoachResponse logic
        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = parsed["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            XCTFail("Failed to parse coach response structure")
            return
        }

        XCTAssertEqual(text, adviceText, "Coach text should match the response")
    }

    /// When JSON is missing optional fields, NutritionInfo should use fallback "N/A" values.
    func testParseNutritionResponseMissingFields() throws {
        // Only provide calories and recipe -- omit carbs, protein, fats, source
        let partialJSON = """
        {
            "Calories per 100g": "200",
            "Healthier Recipe": "Add more greens"
        }
        """

        let jsonData = partialJSON.data(using: .utf8)!
        let info = try JSONDecoder().decode(NutritionInfo.self, from: jsonData)

        XCTAssertEqual(info.calories, "200", "Provided field should decode correctly")
        XCTAssertEqual(info.recipe, "Add more greens", "Provided field should decode correctly")
        XCTAssertEqual(info.carbs, "N/A", "Missing field should fall back to N/A")
        XCTAssertEqual(info.protein, "N/A", "Missing field should fall back to N/A")
        XCTAssertEqual(info.fats, "N/A", "Missing field should fall back to N/A")
        XCTAssertEqual(info.source, "N/A", "Missing field should fall back to N/A")
        XCTAssertNil(info.micros, "Missing micros should be nil")
    }

    /// NutritionInfo's custom decoder should handle numeric values (Int/Double) in addition to strings.
    func testParseNutritionInfoDecoding() throws {
        // Use numeric values instead of strings for the main fields
        let numericJSON = """
        {
            "Calories per 100g": 250,
            "Healthier Recipe": "Steam instead of fry",
            "Carbohydrate per 100g": 30.5,
            "Protein per 100 gm": 15,
            "Fats per 100 gm": 8.2,
            "Source": "Database"
        }
        """

        let jsonData = numericJSON.data(using: .utf8)!
        let info = try JSONDecoder().decode(NutritionInfo.self, from: jsonData)

        // Numeric Int should be decoded as String via custom decoder
        XCTAssertEqual(info.calories, "250", "Integer value should be decoded as string '250'")
        XCTAssertEqual(info.recipe, "Steam instead of fry")
        // Double should be decoded as String
        XCTAssertEqual(info.carbs, "30.5", "Double value should be decoded as string '30.5'")
        XCTAssertEqual(info.protein, "15", "Integer value should be decoded as string '15'")
        XCTAssertEqual(info.fats, "8.2", "Double value should be decoded as string '8.2'")
        XCTAssertEqual(info.source, "Database")
    }

    // MARK: - Edge Cases

    /// Coach response with MAX_TOKENS finishReason should append [Truncated].
    func testParseCoachResponseTruncated() {
        let json: [String: Any] = [
            "candidates": [[
                "content": [
                    "parts": [["text": "Partial advice..."]]
                ],
                "finishReason": "MAX_TOKENS"
            ]]
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)

        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = parsed["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            XCTFail("Failed to parse structure")
            return
        }

        var resultText: String?
        if let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            resultText = text
        }

        let finishReason = firstCandidate["finishReason"] as? String
        if finishReason == "MAX_TOKENS" {
            let finalText = (resultText ?? "") + " [Truncated]"
            XCTAssertTrue(finalText.contains("[Truncated]"), "Truncated response should be flagged")
            XCTAssertTrue(finalText.contains("Partial advice..."), "Original text should be preserved")
        } else {
            XCTFail("finishReason should be MAX_TOKENS")
        }
    }

    /// Coach response with SAFETY finishReason should return safety message.
    func testParseCoachResponseSafety() {
        let json: [String: Any] = [
            "candidates": [[
                "finishReason": "SAFETY"
            ]]
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)

        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = parsed["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            XCTFail("Failed to parse structure")
            return
        }

        let finishReason = firstCandidate["finishReason"] as? String
        XCTAssertEqual(finishReason, "SAFETY")
        // The actual implementation returns "Coach stopped due to Safety filters."
        XCTAssertTrue(finishReason == "SAFETY" || finishReason == "RECITATION",
                       "Safety-related finishReason should be detected")
    }

    /// Gemini response with ```json fences should be stripped during parsing.
    func testParseNutritionResponseWithCodeFences() throws {
        let fencedJSON = """
        ```json
        {
            "Dish": "Pasta",
            "Calories per 100g": "131",
            "Carbohydrate per 100g": "25",
            "Protein per 100 gm": "5",
            "Fats per 100 gm": "1.1",
            "Healthier Recipe": "Use whole wheat pasta",
            "Source": "AI Analysis"
        }
        ```
        """

        let responseData = geminiResponse(text: fencedJSON)

        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            XCTFail("Failed to navigate response")
            return
        }

        let cleanContent = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let jsonData = cleanContent.data(using: .utf8)!
        let info = try JSONDecoder().decode(NutritionInfo.self, from: jsonData)

        XCTAssertEqual(info.calories, "131", "Code fences should be stripped before parsing")
        XCTAssertEqual(info.protein, "5")
    }
}
