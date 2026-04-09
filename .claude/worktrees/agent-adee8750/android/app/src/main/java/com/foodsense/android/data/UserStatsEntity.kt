package com.foodsense.android.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "user_stats")
data class UserStatsEntity(
    @PrimaryKey
    val id: Int = 1, // Single row
    val weight: Double,
    val height: Double,
    val age: Int,
    val gender: String,
    val activityLevel: String,
    val goal: String,
)
