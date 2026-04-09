package com.foodsense.android.services

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

data class Badge(
    val name: String,
    val icon: String,
    val requirement: Int,
    val earned: Boolean,
)

class StreakManager(
    private val context: Context,
    private val nutritionManager: NutritionManager,
) {
    private val prefs = context.getSharedPreferences("streak_prefs", Context.MODE_PRIVATE)

    var currentStreak by mutableStateOf(0)
        private set

    var longestStreak by mutableStateOf(prefs.getInt("longestStreak", 0))
        private set

    var badges by mutableStateOf(defaultBadges(longestStreak))
        private set

    init {
        updateStreak()
    }

    /** Recalculate the current streak from NutritionManager logs. */
    fun updateStreak() {
        currentStreak = calculateStreak(nutritionManager.logs)

        if (currentStreak > longestStreak) {
            longestStreak = currentStreak
            prefs.edit().putInt("longestStreak", longestStreak).apply()
        }

        badges = defaultBadges(longestStreak)
    }

    companion object {
        /** Walk backwards from today counting consecutive days with at least one log. */
        fun calculateStreak(logs: List<com.foodsense.android.data.FoodLog>): Int {
            val loggedDays: Set<LocalDate> = logs.map {
                Instant.ofEpochMilli(it.timeEpochMillis)
                    .atZone(ZoneId.systemDefault())
                    .toLocalDate()
            }.toSet()

            var streak = 0
            var checkDate = LocalDate.now()

            while (loggedDays.contains(checkDate)) {
                streak++
                checkDate = checkDate.minusDays(1)
            }

            return streak
        }

        fun defaultBadges(longestStreak: Int): List<Badge> = listOf(
            Badge("Week Warrior", "flame", 7, longestStreak >= 7),
            Badge("Monthly Master", "star", 30, longestStreak >= 30),
            Badge("Century Champion", "trophy", 100, longestStreak >= 100),
        )
    }
}
