package com.foodsense.android.services

import android.content.Context
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import com.foodsense.android.data.HealthDailyData
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class HealthDataManager(private val context: Context) {
    private val prefs = context.getSharedPreferences("foodsense", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }
    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE

    companion object {
        private const val TAG = "HealthDataManager"

        val PERMISSIONS = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(SleepSessionRecord::class),
            HealthPermission.getReadPermission(HydrationRecord::class),
        )
    }

    // --- Public observable state (same interface as before) ---

    var stepCount by mutableStateOf(0)
        private set
    var waterIntake by mutableStateOf(0.0)
        private set
    var sleepHours by mutableStateOf("0.0h")
        private set
    var activeCalories by mutableStateOf(0)
        private set

    var history by mutableStateOf<Map<LocalDate, HealthDailyData>>(emptyMap())
        private set

    var isAuthorized by mutableStateOf(false)
        private set

    // --- Health Connect availability ---

    var healthConnectAvailable by mutableStateOf(false)
        private set

    private var healthConnectClient: HealthConnectClient? = null

    init {
        healthConnectAvailable = checkHealthConnectAvailability()
        if (healthConnectAvailable) {
            healthConnectClient = HealthConnectClient.getOrCreate(context)
        }
        loadHistory()
        syncTodayFromHistory()
    }

    // --- Health Connect availability check ---

    private fun checkHealthConnectAvailability(): Boolean {
        val status = HealthConnectClient.getSdkStatus(context)
        return when (status) {
            HealthConnectClient.SDK_AVAILABLE -> true
            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> {
                Log.w(TAG, "Health Connect available but provider needs update")
                false
            }
            else -> {
                Log.w(TAG, "Health Connect not available on this device (status=$status)")
                false
            }
        }
    }

    // --- Permission handling ---

    /**
     * Returns a contract for requesting Health Connect permissions.
     * Use this to create an ActivityResultLauncher in your Activity/Composable.
     */
    fun createPermissionRequestContract() =
        PermissionController.createRequestPermissionResultContract()

    /**
     * Checks whether all required Health Connect permissions have been granted.
     */
    suspend fun hasAllPermissions(): Boolean {
        val client = healthConnectClient ?: return false
        val granted = client.permissionController.getGrantedPermissions()
        return PERMISSIONS.all { it in granted }
    }

    /**
     * Called by UI after Health Connect permissions result returns, or as a
     * manual-entry fallback when Health Connect is unavailable.
     * Maintains backward compatibility: callers that do not use Health Connect
     * still call this and it works via the local history fallback.
     */
    fun requestAuthorization() {
        if (healthConnectAvailable) {
            // When Health Connect is available, the actual permission grant
            // happens via the Activity result launcher. Here we just mark
            // authorized optimistically; refreshFromHealthConnect() will
            // verify and pull real data.
            isAuthorized = true
        } else {
            // Fallback: manual-entry mode (original behaviour)
            isAuthorized = true
        }
        fetchAllData()
    }

    /**
     * Call after the permission-result callback to update authorization state
     * and immediately pull data from Health Connect.
     */
    suspend fun onPermissionsResult() {
        isAuthorized = hasAllPermissions()
        if (isAuthorized) {
            refreshFromHealthConnect()
        }
    }

    // --- Data fetching ---

    fun fetchAllData() {
        syncTodayFromHistory()
    }

    /**
     * Reads today's health data from Health Connect and merges it with the
     * local history. Manual entries (water logged via logWater, metrics set
     * via setTodayMetrics) are preserved; Health Connect values overwrite
     * the corresponding fields when available.
     */
    suspend fun refreshFromHealthConnect() {
        val client = healthConnectClient ?: return
        if (!isAuthorized) return

        try {
            val today = LocalDate.now()
            val zone = ZoneId.systemDefault()
            val startOfDay = today.atStartOfDay(zone).toInstant()
            val endOfDay = today.atTime(LocalTime.MAX).atZone(zone).toInstant()
            val timeRange = TimeRangeFilter.between(startOfDay, endOfDay)

            val steps = readSteps(client, timeRange)
            val calories = readActiveCalories(client, timeRange)
            val sleep = readSleep(client, startOfDay, endOfDay)
            val water = readHydration(client, timeRange)

            // Merge with any existing manual entries for today
            val current = history[today] ?: HealthDailyData(0, 0.0, 0, 0.0)
            val updated = current.copy(
                steps = if (steps > 0) steps else current.steps,
                burn = if (calories > 0) calories else current.burn,
                sleep = if (sleep > 0.0) sleep else current.sleep,
                water = if (water > 0.0) water else current.water,
            )
            history = history + (today to updated)
            syncTodayFromHistory()
            saveHistory()

            Log.d(TAG, "Health Connect data refreshed: steps=$steps, cal=$calories, sleep=$sleep, water=$water")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read from Health Connect", e)
            // Graceful degradation: keep showing cached / manual data
        }
    }

    /**
     * Reads health data from Health Connect for a date range and returns it
     * merged with local history. Useful for the Coach and analytics screens.
     */
    suspend fun refreshHistoryFromHealthConnect(days: Int): Map<LocalDate, HealthDailyData> {
        val client = healthConnectClient ?: return fetchHistory(days)
        if (!isAuthorized) return fetchHistory(days)

        try {
            val today = LocalDate.now()
            val zone = ZoneId.systemDefault()
            val startDate = today.minusDays(days.toLong())

            for (dayOffset in 0L..days.toLong()) {
                val date = startDate.plusDays(dayOffset)
                val startOfDay = date.atStartOfDay(zone).toInstant()
                val endOfDay = date.atTime(LocalTime.MAX).atZone(zone).toInstant()
                val timeRange = TimeRangeFilter.between(startOfDay, endOfDay)

                val steps = readSteps(client, timeRange)
                val calories = readActiveCalories(client, timeRange)
                val sleep = readSleep(client, startOfDay, endOfDay)
                val water = readHydration(client, timeRange)

                val current = history[date] ?: HealthDailyData(0, 0.0, 0, 0.0)
                val updated = current.copy(
                    steps = if (steps > 0) steps else current.steps,
                    burn = if (calories > 0) calories else current.burn,
                    sleep = if (sleep > 0.0) sleep else current.sleep,
                    water = if (water > 0.0) water else current.water,
                )
                history = history + (date to updated)
            }
            saveHistory()
            syncTodayFromHistory()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read history from Health Connect", e)
        }

        return fetchHistory(days)
    }

    // --- Health Connect record readers ---

    private suspend fun readSteps(
        client: HealthConnectClient,
        timeRange: TimeRangeFilter,
    ): Int {
        val response = client.readRecords(
            ReadRecordsRequest(StepsRecord::class, timeRange)
        )
        return response.records.sumOf { it.count }.toInt()
    }

    private suspend fun readActiveCalories(
        client: HealthConnectClient,
        timeRange: TimeRangeFilter,
    ): Int {
        val response = client.readRecords(
            ReadRecordsRequest(ActiveCaloriesBurnedRecord::class, timeRange)
        )
        return response.records.sumOf { it.energy.inKilocalories }.toInt()
    }

    private suspend fun readSleep(
        client: HealthConnectClient,
        startTime: Instant,
        endTime: Instant,
    ): Double {
        // Sleep sessions can span midnight, so look back from the previous evening
        val extendedStart = startTime.minusSeconds(12 * 3600) // 12 hours before start of day
        val response = client.readRecords(
            ReadRecordsRequest(
                SleepSessionRecord::class,
                TimeRangeFilter.between(extendedStart, endTime),
            )
        )
        if (response.records.isEmpty()) return 0.0

        val totalMillis = response.records.sumOf { record ->
            val sessionStart = record.startTime
            val sessionEnd = record.endTime
            java.time.Duration.between(sessionStart, sessionEnd).toMillis()
        }
        return totalMillis / 3_600_000.0 // convert ms to hours
    }

    private suspend fun readHydration(
        client: HealthConnectClient,
        timeRange: TimeRangeFilter,
    ): Double {
        val response = client.readRecords(
            ReadRecordsRequest(HydrationRecord::class, timeRange)
        )
        // volume is in liters in Health Connect
        return response.records.sumOf { it.volume.inLiters }
    }

    // --- Local history persistence (unchanged from original) ---

    private fun loadHistory() {
        val raw = prefs.getString("healthHistory", null)
        if (raw.isNullOrBlank()) {
            history = emptyMap()
            return
        }

        runCatching {
            val decoded = json.decodeFromString(
                MapSerializer(String.serializer(), HealthDailyData.serializer()),
                raw,
            )
            history = decoded.mapKeys { LocalDate.parse(it.key, dateFormatter) }
        }
    }

    private fun saveHistory() {
        val encoded = json.encodeToString(
            MapSerializer(String.serializer(), HealthDailyData.serializer()),
            history.mapKeys { it.key.format(dateFormatter) },
        )
        prefs.edit().putString("healthHistory", encoded).apply()
    }

    private fun syncTodayFromHistory() {
        val today = LocalDate.now()
        val data = history[today] ?: HealthDailyData(0, 0.0, 0, 0.0)
        stepCount = data.steps
        waterIntake = data.water
        activeCalories = data.burn
        sleepHours = "%.1fh".format(data.sleep)
    }

    // --- Manual entry methods (fallback / supplementary) ---

    fun logWater(amountML: Double) {
        val today = LocalDate.now()
        val current = history[today] ?: HealthDailyData(0, 0.0, 0, 0.0)
        val updated = current.copy(water = current.water + (amountML / 1000.0))
        history = history + (today to updated)
        syncTodayFromHistory()
        saveHistory()
    }

    fun setTodayMetrics(steps: Int, burn: Int, sleepHoursValue: Double) {
        val today = LocalDate.now()
        val current = history[today] ?: HealthDailyData(0, 0.0, 0, 0.0)
        val updated = current.copy(steps = steps, burn = burn, sleep = sleepHoursValue)
        history = history + (today to updated)
        syncTodayFromHistory()
        saveHistory()
    }

    fun getData(date: LocalDate): HealthDailyData {
        if (date == LocalDate.now()) {
            val sleepValue = sleepHours.removeSuffix("h").toDoubleOrNull() ?: 0.0
            return HealthDailyData(stepCount, waterIntake, activeCalories, sleepValue)
        }
        return history[date] ?: HealthDailyData(0, 0.0, 0, 0.0)
    }

    suspend fun fetchHistory(days: Int): Map<LocalDate, HealthDailyData> {
        val start = LocalDate.now().minusDays(days.toLong())
        return history.filterKeys { !it.isBefore(start) }
    }
}
