package com.foodsense.android.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "food_logs")
data class FoodLogEntity(
    @PrimaryKey
    val id: String,
    val food: String,
    val calories: Int,
    val protein: Int,
    val carbs: Int,
    val fats: Int,
    val micros: String? = null, // JSON-encoded Map<String, String>
    val recipe: String? = null,
    val timeEpochMillis: Long,
)
