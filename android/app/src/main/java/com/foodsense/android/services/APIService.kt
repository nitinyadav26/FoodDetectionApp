package com.foodsense.android.services

import android.graphics.Bitmap
import com.foodsense.android.data.FoodLog
import com.foodsense.android.data.MealPlanDay
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.QuizQuestion
import com.foodsense.android.data.UserStats
import com.foodsense.android.data.WeeklyInsight
import com.foodsense.android.services.ai.AIProviderManager

// Thin facade that preserves the `app.apiService.xxx()` call convention used
// by all consumer screens. Internally delegates every call to the active
// AIProvider selected by AIProviderManager.
//
// Consumer screens do NOT need to change — they keep calling
// `apiService.analyzeFood(bitmap)` etc.
class APIService {

    private val provider
        get() = AIProviderManager.instance?.activeProvider
            ?: throw IllegalStateException(
                "No AI provider configured. Add a Gemini API key or download the on-device model in Settings."
            )

    suspend fun analyzeFood(image: Bitmap): Pair<String, NutritionInfo> =
        provider.analyzeFood(image)

    suspend fun searchFood(query: String): Pair<String, NutritionInfo> =
        provider.searchFood(query)

    suspend fun getCoachAdvice(
        userStats: UserStats?,
        logs: List<FoodLog>,
        healthData: String,
        historyToon: String,
        userQuery: String,
    ): String = provider.getCoachAdvice(userStats, logs, healthData, historyToon, userQuery)

    suspend fun generateMealPlan(
        userStats: UserStats?,
        calorieBudget: Int,
    ): List<MealPlanDay> = provider.generateMealPlan(userStats, calorieBudget)

    suspend fun getWeeklyInsights(
        userStats: UserStats?,
        history: String,
        healthData: String,
    ): WeeklyInsight = provider.getWeeklyInsights(userStats, history, healthData)

    suspend fun getQuizQuestion(): QuizQuestion =
        provider.getQuizQuestion()

    suspend fun predictWeight(
        userStats: UserStats?,
        history: String,
    ): String = provider.predictWeight(userStats, history)
}
