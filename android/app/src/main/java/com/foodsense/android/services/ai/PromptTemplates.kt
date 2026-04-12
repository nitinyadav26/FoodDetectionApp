package com.foodsense.android.services.ai

object PromptTemplates {

    private const val LOCAL_JSON_SUFFIX =
        "\nIMPORTANT: Return ONLY a valid JSON object. No markdown, no code fences, no explanation text."

    fun analyzeFoodPrompt(forLocal: Boolean): String {
        val base = """
            Analyze this food image. Identify the dish.
            Return a JSON object with these exact keys:
            - "Dish": Name of the dish
            - "Calories per 100g": Estimated calories (number as string)
            - "Carbohydrate per 100g": Estimated carbs (number as string)
            - "Protein per 100 gm": Estimated protein (number as string)
            - "Fats per 100 gm": Estimated fats (number as string)
            - "Healthier Recipe": A short advice to make it healthier
            - "Source": "AI Analysis"
            - "micros": A dictionary of key micronutrients
            Return ONLY the JSON.
        """.trimIndent()
        return if (forLocal) base + LOCAL_JSON_SUFFIX else base
    }

    fun searchFoodPrompt(query: String, forLocal: Boolean): String {
        val base = """
            Analyze this food query: "$query".
            Return a JSON object with these exact keys:
            - "Dish": Name of the dish
            - "Calories per 100g": Estimated calories (number as string)
            - "Carbohydrate per 100g": Estimated carbs (number as string)
            - "Protein per 100 gm": Estimated protein (number as string)
            - "Fats per 100 gm": Estimated fats (number as string)
            - "Healthier Recipe": A short advice to make it healthier
            - "Source": "AI Analysis"
            - "micros": A dictionary of key micronutrients
            Return ONLY the JSON.
        """.trimIndent()
        return if (forLocal) base + LOCAL_JSON_SUFFIX else base
    }

    fun coachFullPrompt(context: String, query: String): String {
        val systemPrompt = """
            You are a friendly and motivating professional health coach.
            You have access to the user's data for the last 30 days.
            Be concise (max 150 words).
        """.trimIndent()

        return "System: $systemPrompt\n\nContext:\n$context\n\nUser Request: $query"
    }

    fun mealPlanPrompt(context: String, forLocal: Boolean): String {
        val base = """
            $context
            Generate a 7-day meal plan. Return a JSON array with 7 objects, each with:
            - "day": day name (e.g. "Monday")
            - "breakfast": {"name":"...", "calories":N, "protein":N, "carbs":N, "fats":N, "description":"..."}
            - "lunch": same format
            - "dinner": same format
            - "snack": same format
            Return ONLY the JSON array.
        """.trimIndent()
        return if (forLocal) base + LOCAL_JSON_SUFFIX else base
    }

    fun weeklyInsightsPrompt(context: String, forLocal: Boolean): String {
        val base = """
            Analyze this user's weekly nutrition data and return a JSON object with:
            - "averageCalories": int
            - "averageProtein": int
            - "averageCarbs": int
            - "averageFats": int
            - "topFoods": list of top 5 food names
            - "tips": list of 3-4 short tips
            - "trend": one sentence summary
            - "dailyCalories": list of 7 ints (daily calorie totals, estimate if needed)

            Data: $context
            Return ONLY the JSON.
        """.trimIndent()
        return if (forLocal) base + LOCAL_JSON_SUFFIX else base
    }

    fun quizQuestionPrompt(forLocal: Boolean): String {
        val base = """
            Generate a nutrition/health trivia question. Return a JSON object with:
            - "question": the question text
            - "options": array of exactly 4 answer strings
            - "correctIndex": index (0-3) of the correct answer
            - "explanation": short explanation of the correct answer
            Return ONLY the JSON.
        """.trimIndent()
        return if (forLocal) base + LOCAL_JSON_SUFFIX else base
    }

    fun weightPredictionPrompt(context: String): String {
        return """
            Based on this user's data, predict their weight trend for the next 4 weeks.
            Be concise (max 100 words). $context
        """.trimIndent()
    }
}
