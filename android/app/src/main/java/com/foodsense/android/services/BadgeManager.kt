package com.foodsense.android.services

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.AllBadges
import com.foodsense.android.data.BadgeEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class BadgeManager(
    private val context: Context,
    private val socialManager: SocialManager,
    private val authManager: AuthManager,
) {
    private val app by lazy { context.applicationContext as FoodSenseApplication }
    private val db by lazy { app.database }
    private val scope = CoroutineScope(Dispatchers.IO)

    var unlockedKeys by mutableStateOf<Set<String>>(emptySet())
        private set

    var unlockedCount by mutableStateOf(0)
        private set

    init {
        scope.launch {
            val saved = db.badgeDao().getAll()
            unlockedKeys = saved.map { it.badgeKey }.toSet()
            unlockedCount = saved.size
        }
    }

    /** Evaluate all badges and unlock any newly earned ones. Awards 25 XP per new badge. */
    fun evaluate() {
        val streakManager = app.streakManager
        val nutritionManager = app.nutritionManager
        val healthManager = app.healthDataManager
        val xpManager = app.xpManager

        val logs = nutritionManager.logs
        val totalLogs = logs.size
        val longestStreak = streakManager.longestStreak
        val currentStreak = streakManager.currentStreak
        val today = LocalDate.now()
        val todayLogs = nutritionManager.logsFor(today)
        val todaySummary = nutritionManager.summaryFor(today)
        val healthData = healthManager.getData(today)
        val calorieBudget = nutritionManager.calorieBudget

        val newlyUnlocked = mutableListOf<String>()

        fun tryUnlock(key: String, condition: Boolean) {
            if (condition && key !in unlockedKeys) {
                newlyUnlocked.add(key)
            }
        }

        // Streak badges
        tryUnlock("streak_3", longestStreak >= 3)
        tryUnlock("streak_7", longestStreak >= 7)
        tryUnlock("streak_14", longestStreak >= 14)
        tryUnlock("streak_21", longestStreak >= 21)
        tryUnlock("streak_30", longestStreak >= 30)
        tryUnlock("streak_60", longestStreak >= 60)
        tryUnlock("streak_90", longestStreak >= 90)
        tryUnlock("streak_180", longestStreak >= 180)
        tryUnlock("streak_365", longestStreak >= 365)
        // Comeback: had a streak before (longest > current and current >= 3)
        tryUnlock("streak_comeback", longestStreak > currentStreak && currentStreak >= 3)

        // Logging badges
        tryUnlock("log_1", totalLogs >= 1)
        tryUnlock("log_10", totalLogs >= 10)
        tryUnlock("log_25", totalLogs >= 25)
        tryUnlock("log_50", totalLogs >= 50)
        tryUnlock("log_100", totalLogs >= 100)
        tryUnlock("log_250", totalLogs >= 250)
        tryUnlock("log_500", totalLogs >= 500)
        tryUnlock("log_1000", totalLogs >= 1000)
        tryUnlock("log_3meals", todayLogs.size >= 3)
        tryUnlock("log_5meals", todayLogs.size >= 5)

        // Nutrition badges
        tryUnlock("cal_under_budget", todaySummary.cals in 1 until calorieBudget)
        // For 7-day budget tracking we check the last 7 days
        val last7Under = (0L..6L).all { offset ->
            val day = today.minusDays(offset)
            val daySummary = nutritionManager.summaryFor(day)
            daySummary.cals in 1 until calorieBudget
        }
        tryUnlock("cal_under_7days", last7Under)
        tryUnlock("protein_100", todaySummary.protein >= 100)
        tryUnlock("protein_150", todaySummary.protein >= 150)
        tryUnlock("balanced_meal", todayLogs.any { it.protein > 0 && it.carbs > 0 && it.fats > 0 })
        tryUnlock("low_fat_day", todaySummary.fats in 1..40)
        tryUnlock("high_fiber", todayLogs.any { log ->
            log.micros?.keys?.any { it.contains("fiber", ignoreCase = true) } == true
        })
        val uniqueFoods = todayLogs.map { it.food.lowercase() }.toSet().size
        tryUnlock("variety_5", uniqueFoods >= 5)
        tryUnlock("variety_10", uniqueFoods >= 10)
        // Clean eater: logged food today and all calories < 300 per item (heuristic)
        tryUnlock("zero_junk", todayLogs.isNotEmpty() && todayLogs.all { it.calories < 300 })

        // Health badges
        tryUnlock("water_2l", healthData.water >= 2.0)
        tryUnlock("water_3l", healthData.water >= 3.0)
        tryUnlock("steps_5k", healthData.steps >= 5000)
        tryUnlock("steps_10k", healthData.steps >= 10000)
        tryUnlock("steps_15k", healthData.steps >= 15000)
        tryUnlock("sleep_7h", healthData.sleep >= 7.0)
        tryUnlock("sleep_8h", healthData.sleep >= 8.0)
        tryUnlock("burn_300", healthData.burn >= 300)
        tryUnlock("burn_500", healthData.burn >= 500)
        tryUnlock("all_health", healthData.water >= 2.0 && healthData.steps >= 10000 && healthData.sleep >= 7.0)

        // Social badges
        val currentUserId = authManager.currentUser.value?.uid
        tryUnlock("social_share", socialManager.feedPosts.value.any { it.userId == currentUserId })
        tryUnlock("social_invite", socialManager.friends.value.isNotEmpty())
        val prefs = context.getSharedPreferences("foodsense", Context.MODE_PRIVATE)
        tryUnlock("social_review", prefs.getBoolean("has_left_review", false))
        tryUnlock("social_feedback", prefs.getBoolean("has_given_feedback", false))
        tryUnlock("social_community", socialManager.challenges.value.any { it.isJoined })

        // Milestone badges
        tryUnlock("level_10", xpManager.level >= 10)
        tryUnlock("level_25", xpManager.level >= 25)
        tryUnlock("level_50", xpManager.level >= 50)
        val totalUnlocked = unlockedKeys.size + newlyUnlocked.size
        tryUnlock("badges_10", totalUnlocked >= 10)
        tryUnlock("badges_25", totalUnlocked >= 25)

        if (newlyUnlocked.isNotEmpty()) {
            unlockedKeys = unlockedKeys + newlyUnlocked
            unlockedCount = unlockedKeys.size

            scope.launch {
                newlyUnlocked.forEach { key ->
                    val badge = AllBadges.byKey[key] ?: return@forEach
                    db.badgeDao().insert(
                        BadgeEntity(
                            badgeKey = key,
                            unlockedAt = System.currentTimeMillis(),
                            category = badge.category.name,
                        ),
                    )
                }
            }

            // Award 25 XP per new badge
            xpManager.awardXP(newlyUnlocked.size * 25)
        }
    }
}
