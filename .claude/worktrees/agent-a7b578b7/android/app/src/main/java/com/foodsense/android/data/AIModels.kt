package com.foodsense.android.data

import kotlinx.serialization.Serializable

@Serializable
data class ChatMessage(
    val role: String,
    val content: String,
    val timestamp: Long = System.currentTimeMillis(),
)

@Serializable
data class PlannedMeal(
    val name: String,
    val calories: Int,
    val protein: Int,
    val carbs: Int,
    val fats: Int,
    val description: String = "",
)

@Serializable
data class MealPlanDay(
    val day: String,
    val breakfast: PlannedMeal,
    val lunch: PlannedMeal,
    val dinner: PlannedMeal,
    val snack: PlannedMeal,
)

@Serializable
data class WeeklyInsight(
    val averageCalories: Int,
    val averageProtein: Int,
    val averageCarbs: Int,
    val averageFats: Int,
    val topFoods: List<String>,
    val tips: List<String>,
    val trend: String,
    val dailyCalories: List<Int> = emptyList(),
)

@Serializable
data class QuizQuestion(
    val question: String,
    val options: List<String>,
    val correctIndex: Int,
    val explanation: String,
)
