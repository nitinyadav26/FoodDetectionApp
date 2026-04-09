package com.foodsense.android.services

import android.content.Context
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.FoodLog
import com.foodsense.android.data.FoodLogEntity
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.UserStats
import com.foodsense.android.data.UserStatsEntity
import com.foodsense.android.data.parseNumber
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class NutritionManager(private val context: Context) {
    private val prefs = context.getSharedPreferences("foodsense", Context.MODE_PRIVATE)
    private val db by lazy { (context.applicationContext as FoodSenseApplication).database }
    private val scope = CoroutineScope(Dispatchers.IO)
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    var nutritionData by mutableStateOf<Map<String, NutritionInfo>>(emptyMap())
        private set

    var logs by mutableStateOf<List<FoodLog>>(emptyList())
        private set

    var userStats by mutableStateOf<UserStats?>(null)
        private set

    var calorieBudget by mutableStateOf(2000)
        private set

    init {
        loadNutritionData()
        loadUserStats()
        loadLogs()
        migrateSharedPrefsToRoom()
    }

    /**
     * One-time migration: if SharedPreferences has data and Room has not been populated yet,
     * copy all logs and user stats into Room, then set a flag so we don't migrate again.
     */
    private fun migrateSharedPrefsToRoom() {
        if (prefs.getBoolean("room_migration_done", false)) return

        scope.launch {
            try {
                // Migrate food logs
                if (logs.isNotEmpty()) {
                    val entities = logs.map { it.toEntity() }
                    db.foodLogDao().insertAll(entities)
                }

                // Migrate user stats
                userStats?.let { stats ->
                    db.userStatsDao().insertOrUpdate(stats.toEntity())
                }

                prefs.edit().putBoolean("room_migration_done", true).apply()
                Log.d("NutritionManager", "SharedPreferences -> Room migration complete")
            } catch (e: Exception) {
                Log.e("NutritionManager", "Migration failed", e)
            }
        }
    }

    private fun loadNutritionData() {
        runCatching {
            val raw = context.assets.open("nutrition_data.json").bufferedReader().use { it.readText() }
            nutritionData = json.decodeFromString(
                MapSerializer(String.serializer(), NutritionInfo.serializer()),
                raw,
            )
        }
    }

    private fun loadUserStats() {
        val raw = prefs.getString("userStats", null) ?: return
        runCatching {
            userStats = json.decodeFromString(UserStats.serializer(), raw)
            calculateBudget()
        }
    }

    private fun loadLogs() {
        val raw = prefs.getString("foodLogs", null) ?: return
        runCatching {
            logs = json.decodeFromString(ListSerializer(FoodLog.serializer()), raw)
        }
    }

    fun saveUserStats(stats: UserStats) {
        userStats = stats
        prefs.edit().putString("userStats", json.encodeToString(UserStats.serializer(), stats)).apply()
        scope.launch { db.userStatsDao().insertOrUpdate(stats.toEntity()) }
        calculateBudget()
    }

    fun calculateBudget() {
        val stats = userStats ?: return
        val s = if (stats.gender.equals("Male", ignoreCase = true)) 5.0 else -161.0
        val bmr = (10 * stats.weight) + (6.25 * stats.height) - (5 * stats.age) + s

        val activityMultiplier = when (stats.activityLevel) {
            "Light" -> 1.375
            "Moderate" -> 1.55
            "Active" -> 1.725
            else -> 1.2
        }

        var tdee = bmr * activityMultiplier
        when (stats.goal) {
            "Lose" -> tdee -= 500
            "Gain" -> tdee += 500
        }

        calorieBudget = tdee.toInt()
    }

    fun getNutrition(dish: String): NutritionInfo? = nutritionData[dish]

    fun calculateNutrition(info: NutritionInfo, weight: Double): NutritionInfo {
        val ratio = weight / 100.0

        fun scaled(value: String): String = "%.1f".format(parseNumber(value) * ratio)

        val scaledMicros = info.micros?.mapValues { (_, value) ->
            val numeric = parseNumber(value)
            val unit = value.replace(Regex("[-+]?\\d*\\.?\\d+"), "").trim()
            val scaledValue = "%.1f".format(numeric * ratio)
            if (unit.isNotEmpty()) "$scaledValue $unit" else scaledValue
        }

        return NutritionInfo(
            calories = scaled(info.calories),
            recipe = info.recipe,
            carbs = scaled(info.carbs),
            protein = scaled(info.protein),
            fats = scaled(info.fats),
            source = info.source,
            micros = scaledMicros,
        )
    }

    fun logFood(dish: String, info: NutritionInfo? = null, weight: Double = 100.0) {
        val base = info ?: getNutrition(dish) ?: NutritionInfo(
            calories = "0",
            recipe = "No recipe available.",
            carbs = "0",
            protein = "0",
            fats = "0",
            source = "Unknown",
            micros = null,
        )

        val scaled = if (weight == 100.0) base else calculateNutrition(base, weight)

        fun parseInt(value: String): Int = parseNumber(value).toInt()

        val log = FoodLog(
            food = dish,
            calories = parseInt(scaled.calories),
            protein = parseInt(scaled.protein),
            carbs = parseInt(scaled.carbs),
            fats = parseInt(scaled.fats),
            micros = scaled.micros,
            recipe = scaled.recipe,
        )

        logs = listOf(log) + logs
        saveLogs()
    }

    fun deleteLogById(id: String) {
        logs = logs.filterNot { it.id == id }
        saveLogs()
    }

    fun deleteLogsByIds(ids: Set<String>) {
        logs = logs.filterNot { ids.contains(it.id) }
        saveLogs()
    }

    private fun saveLogs() {
        prefs.edit().putString(
            "foodLogs",
            json.encodeToString(ListSerializer(FoodLog.serializer()), logs),
        ).apply()
        // Sync to Room: replace all rows with current in-memory list
        scope.launch {
            db.foodLogDao().deleteAll()
            db.foodLogDao().insertAll(logs.map { it.toEntity() })
        }
        // Update widget data in SharedPreferences so CalorieWidget can read it
        updateWidgetData()
    }

    private fun updateWidgetData() {
        val todayCals = todaySummary.cals
        prefs.edit()
            .putInt("widget_today_cals", todayCals)
            .putInt("widget_calorie_budget", calorieBudget)
            .apply()
    }

    fun logsFor(date: LocalDate): List<FoodLog> {
        return logs.filter {
            Instant.ofEpochMilli(it.timeEpochMillis).atZone(ZoneId.systemDefault()).toLocalDate() == date
        }
    }

    data class Summary(val cals: Int, val protein: Int, val carbs: Int, val fats: Int)

    fun summaryFor(date: LocalDate): Summary {
        val dayLogs = logsFor(date)
        return Summary(
            cals = dayLogs.sumOf { it.calories },
            protein = dayLogs.sumOf { it.protein },
            carbs = dayLogs.sumOf { it.carbs },
            fats = dayLogs.sumOf { it.fats },
        )
    }

    fun getHistory(days: Int): String {
        val cutoff = LocalDate.now().minusDays(days.toLong())
        val grouped = logs.groupBy {
            Instant.ofEpochMilli(it.timeEpochMillis).atZone(ZoneId.systemDefault()).toLocalDate()
        }
            .filterKeys { it >= cutoff }
            .toSortedMap(compareByDescending { it })

        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        return buildString {
            grouped.forEach { (date, dayLogs) ->
                val total = dayLogs.sumOf { it.calories }
                val foods = dayLogs.joinToString(", ") { "${it.food}(${it.calories})" }
                append("[${date.format(formatter)}] Cals: $total | Foods: $foods\n")
            }
        }
    }

    val todayLogs: List<FoodLog>
        get() = logsFor(LocalDate.now())

    val todaySummary: Summary
        get() = summaryFor(LocalDate.now())

    fun exportAllData(): String {
        val statsJson = userStats?.let { json.encodeToString(UserStats.serializer(), it) } ?: "null"
        val logsJson = json.encodeToString(ListSerializer(FoodLog.serializer()), logs)
        return """{"stats":$statsJson,"logs":$logsJson,"exportDate":"${Instant.now()}"}"""
    }

    fun deleteAllData() {
        logs = emptyList()
        userStats = null
        calorieBudget = 2000
        prefs.edit().clear().apply()
        scope.launch {
            db.foodLogDao().deleteAll()
            db.userStatsDao().deleteAll()
        }
    }
}

// ---- Conversion helpers between domain models and Room entities ----

private val microsJson = Json { ignoreUnknownKeys = true }

private fun FoodLog.toEntity(): FoodLogEntity = FoodLogEntity(
    id = id,
    food = food,
    calories = calories,
    protein = protein,
    carbs = carbs,
    fats = fats,
    micros = micros?.let { microsJson.encodeToString(MapSerializer(String.serializer(), String.serializer()), it) },
    recipe = recipe,
    timeEpochMillis = timeEpochMillis,
)

private fun FoodLogEntity.toDomain(): FoodLog = FoodLog(
    id = id,
    food = food,
    calories = calories,
    protein = protein,
    carbs = carbs,
    fats = fats,
    micros = micros?.let {
        runCatching { microsJson.decodeFromString(MapSerializer(String.serializer(), String.serializer()), it) }.getOrNull()
    },
    recipe = recipe,
    timeEpochMillis = timeEpochMillis,
)

private fun UserStats.toEntity(): UserStatsEntity = UserStatsEntity(
    id = 1,
    weight = weight,
    height = height,
    age = age,
    gender = gender,
    activityLevel = activityLevel,
    goal = goal,
)

private fun UserStatsEntity.toDomain(): UserStats = UserStats(
    weight = weight,
    height = height,
    age = age,
    gender = gender,
    activityLevel = activityLevel,
    goal = goal,
)
