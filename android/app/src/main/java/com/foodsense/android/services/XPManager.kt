package com.foodsense.android.services

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.XPEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class XPManager(private val context: Context) {
    private val db by lazy { (context.applicationContext as FoodSenseApplication).database }
    private val scope = CoroutineScope(Dispatchers.IO)

    var totalXP by mutableStateOf(0)
        private set

    var level by mutableStateOf(1)
        private set

    var title by mutableStateOf("Beginner")
        private set

    init {
        scope.launch {
            val saved = db.xpDao().get()
            if (saved != null) {
                totalXP = saved.totalXP
                level = saved.level
                title = saved.title
            }
        }
    }

    /** XP required to reach a given level: level * 100 */
    fun xpForLevel(lvl: Int): Int = lvl * 100

    /** Total XP needed from 0 to reach a given level */
    fun totalXPForLevel(lvl: Int): Int {
        // Sum of 1*100 + 2*100 + ... + (lvl-1)*100
        return (1 until lvl).sumOf { it * 100 }
    }

    /** XP progress within current level */
    val currentLevelXP: Int
        get() = totalXP - totalXPForLevel(level)

    /** XP needed to complete current level */
    val xpToNextLevel: Int
        get() = xpForLevel(level)

    /** Progress fraction 0..1 within current level */
    val progress: Float
        get() = if (level >= MAX_LEVEL) 1f
        else (currentLevelXP.toFloat() / xpToNextLevel).coerceIn(0f, 1f)

    fun awardXP(amount: Int) {
        if (amount <= 0) return
        totalXP += amount
        recalculateLevel()
        persist()
    }

    private fun recalculateLevel() {
        var newLevel = 1
        var accumulated = 0
        while (newLevel < MAX_LEVEL) {
            val needed = xpForLevel(newLevel)
            if (accumulated + needed > totalXP) break
            accumulated += needed
            newLevel++
        }
        level = newLevel
        title = titleForLevel(newLevel)
    }

    private fun persist() {
        scope.launch {
            db.xpDao().insertOrUpdate(
                XPEntity(
                    id = 1,
                    totalXP = totalXP,
                    level = level,
                    title = title,
                    lastUpdated = System.currentTimeMillis(),
                ),
            )
        }
    }

    companion object {
        const val MAX_LEVEL = 50

        val TITLES = listOf(
            1 to "Beginner",
            5 to "Apprentice",
            10 to "Tracker",
            20 to "Expert",
            30 to "Master",
            40 to "Champion",
            50 to "Legend",
        )

        fun titleForLevel(lvl: Int): String {
            return TITLES.lastOrNull { lvl >= it.first }?.second ?: "Beginner"
        }
    }
}
