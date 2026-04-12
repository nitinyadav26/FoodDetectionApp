package com.foodsense.android.services.ai

import android.graphics.Bitmap
import com.foodsense.android.data.FoodLog
import com.foodsense.android.data.MealPlanDay
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.QuizQuestion
import com.foodsense.android.data.UserStats
import com.foodsense.android.data.WeeklyInsight

interface AIProvider {
    val providerName: String

    suspend fun analyzeFood(image: Bitmap): Pair<String, NutritionInfo>
    suspend fun searchFood(query: String): Pair<String, NutritionInfo>
    suspend fun getCoachAdvice(
        userStats: UserStats?, logs: List<FoodLog>,
        healthData: String, historyToon: String, userQuery: String
    ): String
    suspend fun generateMealPlan(userStats: UserStats?, calorieBudget: Int): List<MealPlanDay>
    suspend fun getWeeklyInsights(userStats: UserStats?, history: String, healthData: String): WeeklyInsight
    suspend fun getQuizQuestion(): QuizQuestion
    suspend fun predictWeight(userStats: UserStats?, history: String): String
}
