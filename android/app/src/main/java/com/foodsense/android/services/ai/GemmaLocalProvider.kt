package com.foodsense.android.services.ai

import android.graphics.Bitmap
import com.foodsense.android.data.FoodLog
import com.foodsense.android.data.MealPlanDay
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.QuizQuestion
import com.foodsense.android.data.UserStats
import com.foodsense.android.data.WeeklyInsight

// Stub implementation of AIProvider for on-device inference using Gemma 4 E4B via LiteRT-LM.
// Each method builds the appropriate prompt via PromptTemplates but throws because the
// LiteRT-LM runtime dependency is not yet available. Once the dependency ships, replace
// the throw with actual inference calls.
class GemmaLocalProvider(
    @Suppress("unused") private val modelPath: String
) : AIProvider {

    override val providerName = "On-Device AI"

    override suspend fun analyzeFood(image: Bitmap): Pair<String, NutritionInfo> {
        @Suppress("unused")
        val prompt = PromptTemplates.analyzeFoodPrompt(forLocal = true)
        // TODO: Replace with LiteRT-LM inference when dependency is available
        throw IllegalStateException(NOT_INITIALIZED_MSG)
    }

    override suspend fun searchFood(query: String): Pair<String, NutritionInfo> {
        @Suppress("unused")
        val prompt = PromptTemplates.searchFoodPrompt(query, forLocal = true)
        // TODO: Replace with LiteRT-LM inference when dependency is available
        throw IllegalStateException(NOT_INITIALIZED_MSG)
    }

    override suspend fun getCoachAdvice(
        userStats: UserStats?,
        logs: List<FoodLog>,
        healthData: String,
        historyToon: String,
        userQuery: String
    ): String {
        val context = buildString {
            append("User Stats: ")
            if (userStats != null) {
                append("Age ${userStats.age}, ${userStats.gender}, ${userStats.weight}kg, Goal: ${userStats.goal}. ")
            } else {
                append("Goal: Stay healthy. ")
            }
            append("\nToday's Health: $healthData.")
            append("\nToday's Food: ")
            if (logs.isEmpty()) {
                append("Nothing logged yet.")
            } else {
                logs.take(10).forEach { append("${it.food} (${it.calories}kcal), ") }
            }
            append("\n\nPast 30 Days History (TOON Format):\n")
            append(historyToon)
        }
        @Suppress("unused")
        val prompt = PromptTemplates.coachFullPrompt(context, userQuery)
        // TODO: Replace with LiteRT-LM inference when dependency is available
        throw IllegalStateException(NOT_INITIALIZED_MSG)
    }

    override suspend fun generateMealPlan(
        userStats: UserStats?,
        calorieBudget: Int
    ): List<MealPlanDay> {
        val context = buildString {
            append("Calorie budget: $calorieBudget kcal/day. ")
            if (userStats != null) {
                append("User: Age ${userStats.age}, ${userStats.gender}, ${userStats.weight}kg, Goal: ${userStats.goal}.")
            }
        }
        @Suppress("unused")
        val prompt = PromptTemplates.mealPlanPrompt(context, forLocal = true)
        // TODO: Replace with LiteRT-LM inference when dependency is available
        throw IllegalStateException(NOT_INITIALIZED_MSG)
    }

    override suspend fun getWeeklyInsights(
        userStats: UserStats?,
        history: String,
        healthData: String
    ): WeeklyInsight {
        val context = buildString {
            if (userStats != null) {
                append("User: Age ${userStats.age}, ${userStats.gender}, ${userStats.weight}kg, Goal: ${userStats.goal}. ")
            }
            append("Health: $healthData. ")
            append("Food history:\n$history")
        }
        @Suppress("unused")
        val prompt = PromptTemplates.weeklyInsightsPrompt(context, forLocal = true)
        // TODO: Replace with LiteRT-LM inference when dependency is available
        throw IllegalStateException(NOT_INITIALIZED_MSG)
    }

    override suspend fun getQuizQuestion(): QuizQuestion {
        @Suppress("unused")
        val prompt = PromptTemplates.quizQuestionPrompt(forLocal = true)
        // TODO: Replace with LiteRT-LM inference when dependency is available
        throw IllegalStateException(NOT_INITIALIZED_MSG)
    }

    override suspend fun predictWeight(
        userStats: UserStats?,
        history: String
    ): String {
        val context = buildString {
            if (userStats != null) {
                append("User: ${userStats.weight}kg, Goal: ${userStats.goal}. ")
            }
            append("Recent food history:\n$history")
        }
        @Suppress("unused")
        val prompt = PromptTemplates.weightPredictionPrompt(context)
        // TODO: Replace with LiteRT-LM inference when dependency is available
        throw IllegalStateException(NOT_INITIALIZED_MSG)
    }

    companion object {
        private const val NOT_INITIALIZED_MSG =
            "On-device AI model not yet initialized. Please ensure the model is downloaded."
    }
}
