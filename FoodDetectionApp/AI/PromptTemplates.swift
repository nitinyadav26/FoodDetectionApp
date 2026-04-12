import Foundation

/// Centralized prompt strings extracted from APIService.
/// Each prompt has a `forLocal` parameter: when true, appends stricter JSON
/// formatting instructions for on-device models that lack `responseMimeType`.
struct PromptTemplates {

    private static let localJSONSuffix = "\nIMPORTANT: Return ONLY a valid JSON object. No markdown, no code fences, no explanation text before or after."

    // MARK: - Food Analysis (Image)

    static func analyzeFoodPrompt(forLocal: Bool = false) -> String {
        let prompt = """
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
        return forLocal ? prompt + localJSONSuffix : prompt
    }

    // MARK: - Food Search (Text)

    static func searchFoodPrompt(query: String, forLocal: Bool = false) -> String {
        let prompt = """
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
        return forLocal ? prompt + localJSONSuffix : prompt
    }

    // MARK: - Coach

    static func coachSystemPrompt(forLocal: Bool = false) -> String {
        return """
        You are a friendly and motivating professional health coach.
        You have access to the user's data for the last 30 days.
        Be concise (max 150 words).
        """
    }

    static func coachFullPrompt(systemPrompt: String, context: String, query: String, forLocal: Bool = false) -> String {
        return "System: \(systemPrompt)\n\nContext:\n\(context)\n\nUser Request: \(query)"
    }

    // MARK: - Meal Plan

    static func mealPlanPrompt(context: String, forLocal: Bool = false) -> String {
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
        return forLocal ? prompt + localJSONSuffix : prompt
    }

    // MARK: - Portion Estimation

    static func portionEstimationPrompt(forLocal: Bool = false) -> String {
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
        return forLocal ? prompt + localJSONSuffix : prompt
    }

    // MARK: - Before/After Comparison

    static func beforeAfterPrompt(forLocal: Bool = false) -> String {
        return """
        Compare these two food images (before and after eating).
        Analyze:
        1. What food was on the plate before
        2. How much was consumed (percentage estimate)
        3. Estimated calories consumed
        4. Nutritional assessment
        Be concise (max 150 words).
        """
    }

    // MARK: - OCR Nutrition Label

    static func ocrNutritionLabelPrompt(forLocal: Bool = false) -> String {
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
        return forLocal ? prompt + localJSONSuffix : prompt
    }

    // MARK: - Weekly Insights

    static func insightsPrompt(context: String, forLocal: Bool = false) -> String {
        return """
        Based on this nutrition data, provide 3-5 actionable insights and tips.
        Be specific, concise, and encouraging. Max 200 words.
        \(context)
        """
    }
}
