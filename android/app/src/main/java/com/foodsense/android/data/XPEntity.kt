package com.foodsense.android.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "user_xp")
data class XPEntity(
    @PrimaryKey
    val id: Int = 1,
    val totalXP: Int = 0,
    val level: Int = 1,
    val title: String = "Beginner",
    val lastUpdated: Long = System.currentTimeMillis(),
)
