package com.foodsense.android.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class NutritionInfo(
    @SerialName("Calories per 100g")
    val calories: String = "0",
    @SerialName("Healthier Recipe")
    val recipe: String = "No recipe available.",
    @SerialName("Carbohydrate per 100g")
    val carbs: String = "0",
    @SerialName("Protein per 100 gm")
    val protein: String = "0",
    @SerialName("Fats per 100 gm")
    val fats: String = "0",
    @SerialName("Source")
    val source: String = "Unknown",
    val micros: Map<String, String>? = null,
)

@Serializable
data class UserStats(
    val weight: Double,
    val height: Double,
    val age: Int,
    val gender: String,
    val activityLevel: String,
    val goal: String,
)

@Serializable
data class FoodLog(
    val id: String = UUID.randomUUID().toString(),
    val food: String,
    val calories: Int,
    val protein: Int,
    val carbs: Int,
    val fats: Int,
    val micros: Map<String, String>? = null,
    val recipe: String? = null,
    val timeEpochMillis: Long = System.currentTimeMillis(),
)

@Serializable
data class ServingSize(
    val label: String,
    val weight: Double,
)

@Serializable
data class INDBFood(
    val id: String,
    val name: String,
    @SerialName("base_calories_per_100g")
    val baseCaloriesPer100g: Double,
    @SerialName("base_protein_per_100g")
    val baseProteinPer100g: Double,
    @SerialName("base_carbs_per_100g")
    val baseCarbsPer100g: Double,
    @SerialName("base_fat_per_100g")
    val baseFatPer100g: Double,
    val servings: List<ServingSize>,
)

@Serializable
data class HealthDailyData(
    val steps: Int,
    val water: Double,
    val burn: Int,
    val sleep: Double,
)

fun parseNumber(value: String): Double {
    val cleaned = value.filter { it.isDigit() || it == '.' }
    return cleaned.toDoubleOrNull() ?: 0.0
}
