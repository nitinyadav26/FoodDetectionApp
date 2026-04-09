package com.foodsense.android.services

import android.content.Context
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.foodsense.android.data.FoodLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.time.Instant
import java.time.format.DateTimeFormatter

class SyncManager(
    private val context: Context,
    private val networkService: NetworkService,
    private val nutritionManager: NutritionManager,
) {
    var isSyncing by mutableStateOf(false)
        private set
    var lastSyncTimeMillis by mutableStateOf(0L)
        private set

    private val scope = CoroutineScope(Dispatchers.IO)
    private val prefs = context.getSharedPreferences("sync_prefs", Context.MODE_PRIVATE)
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    init {
        lastSyncTimeMillis = prefs.getLong("lastSyncTimeMillis", 0L)
    }

    fun syncIfNeeded() {
        if (isSyncing) return

        scope.launch {
            isSyncing = true
            try {
                pushLocalLogs()
                pullRemoteLogs()

                val now = System.currentTimeMillis()
                lastSyncTimeMillis = now
                prefs.edit().putLong("lastSyncTimeMillis", now).apply()
            } catch (e: Exception) {
                Log.w(TAG, "sync failed: ${e.message}")
            } finally {
                isSyncing = false
            }
        }
    }

    private suspend fun pushLocalLogs() {
        val logs = nutritionManager.logs
        if (logs.isEmpty()) return

        val logsArray = buildJsonArray {
            for (log in logs) {
                add(buildJsonObject {
                    put("clientId", log.id)
                    put("dishName", log.food)
                    put("calories", log.calories)
                    put("proteinG", log.protein)
                    put("carbsG", log.carbs)
                    put("fatsG", log.fats)
                    if (log.micros != null) {
                        put("micronutrients", buildJsonObject {
                            for ((k, v) in log.micros) put(k, v)
                        })
                    }
                    if (log.recipe != null) put("healthierRecipe", log.recipe)
                    put("loggedAt", epochMillisToIso(log.timeEpochMillis))
                })
            }
        }

        val body = buildJsonObject { put("logs", logsArray) }
        networkService.post("/api/sync/push", body)
    }

    private suspend fun pullRemoteLogs() {
        val path = if (lastSyncTimeMillis > 0) {
            "/api/sync/pull?since=${epochMillisToIso(lastSyncTimeMillis)}"
        } else {
            "/api/sync/pull"
        }

        val responseText = networkService.get(path)
        val response = json.decodeFromString(SyncPullResponse.serializer(), responseText)
        if (response.data.isEmpty()) return

        val existingIds = nutritionManager.logs.map { it.id }.toSet()
        val newLogs = response.data
            .filter { it.id !in existingIds }
            .map { remote ->
                FoodLog(
                    id = remote.id,
                    food = remote.dishName,
                    calories = remote.calories?.toInt() ?: 0,
                    protein = remote.proteinG?.toInt() ?: 0,
                    carbs = remote.carbsG?.toInt() ?: 0,
                    fats = remote.fatsG?.toInt() ?: 0,
                    micros = remote.micronutrients,
                    recipe = remote.healthierRecipe,
                    timeEpochMillis = isoToEpochMillis(remote.loggedAt),
                )
            }

        if (newLogs.isNotEmpty()) {
            nutritionManager.addSyncedLogs(newLogs)
        }
    }

    private fun epochMillisToIso(millis: Long): String =
        DateTimeFormatter.ISO_INSTANT.format(Instant.ofEpochMilli(millis))

    private fun isoToEpochMillis(iso: String): Long =
        try { Instant.parse(iso).toEpochMilli() } catch (_: Exception) { System.currentTimeMillis() }

    companion object {
        private const val TAG = "SyncManager"
    }
}

@Serializable
private data class SyncPullResponse(
    val success: Boolean,
    val data: List<RemoteFoodLog>,
)

@Serializable
private data class RemoteFoodLog(
    val id: String,
    val dishName: String,
    val calories: Double? = null,
    val proteinG: Double? = null,
    val carbsG: Double? = null,
    val fatsG: Double? = null,
    val micronutrients: Map<String, String>? = null,
    val healthierRecipe: String? = null,
    val loggedAt: String,
)
