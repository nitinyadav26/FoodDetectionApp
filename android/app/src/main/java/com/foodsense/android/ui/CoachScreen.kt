package com.foodsense.android.ui

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.services.AnalyticsService
import kotlinx.coroutines.launch

@Composable
fun CoachScreen(app: FoodSenseApplication) {
    val nutritionManager = app.nutritionManager
    val healthManager = app.healthDataManager
    val apiService = app.apiService
    val scope = rememberCoroutineScope()

    var advice by remember { mutableStateOf("Tap a button to get personalized advice!") }
    var isLoading by remember { mutableStateOf(false) }
    var historyString by remember { mutableStateOf("Loading history...") }
    var showHistory by remember { mutableStateOf(false) }

    fun loadHistory() {
        scope.launch {
            val foodHist = nutritionManager.getHistory(days = 7)
            val healthHist = healthManager.fetchHistory(days = 7)

            val merged = buildString {
                append("--- Health Data (Steps, Water, Burn, Sleep) ---\n")
                healthHist.toSortedMap(compareByDescending { it }).forEach { (date, h) ->
                    append("[$date] Steps:${h.steps} Water:${"%.1f".format(h.water)} Burn:${h.burn} Sleep:${"%.1f".format(h.sleep)}\n")
                }
                append("\n--- Food Data ---\n")
                append(foodHist)
            }
            historyString = merged
        }
    }

    fun getAdvice(query: String) {
        if (!app.networkMonitor.isConnected.value) {
            advice = "You're offline. AI Coach requires an internet connection."
            return
        }
        isLoading = true
        AnalyticsService.logCoachQuery(query)
        val healthData = "Steps: ${healthManager.stepCount}, Sleep: ${healthManager.sleepHours}, Water: ${healthManager.waterIntake}L, Burn: ${healthManager.activeCalories}"

        scope.launch {
            runCatching {
                apiService.getCoachAdvice(
                    userStats = nutritionManager.userStats,
                    logs = nutritionManager.todayLogs,
                    healthData = healthData,
                    historyToon = historyString,
                    userQuery = query,
                )
            }.onSuccess {
                advice = it
            }.onFailure {
                advice = "Coach is busy. (${it.message ?: "Unknown error"})"
            }
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        loadHistory()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text("AI Health Coach", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                Text("Your 30-day health companion", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Icon(Icons.Default.Psychology, contentDescription = "AI Health Coach", tint = Color(0xFFB388FF), modifier = Modifier.size(42.dp))
        }

        CoachActionChips(
            onAction = { query ->
                getAdvice(query)
            },
        )

        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
            Column(modifier = Modifier.fillMaxWidth().padding(14.dp)) {
                if (isLoading) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                        Spacer(modifier = Modifier.width(10.dp))
                        Text("Analyzing 30 days of data...")
                    }
                } else {
                    Text(advice)
                }
            }
        }

        TextButton(onClick = { showHistory = !showHistory }) {
            Text(if (showHistory) "Hide Data Context" else "View Data Context")
        }

        if (showHistory) {
            Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
                Text(
                    historyString,
                    modifier = Modifier.padding(12.dp),
                    fontSize = 11.sp,
                    lineHeight = 15.sp,
                )
            }
        }
    }
}

@Composable
fun CoachActionChips(onAction: (String) -> Unit) {
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        AssistChip(
            onClick = { onAction("Give me a healthy recipe using ingredients I eat often.") },
            label = { Text("Healthy Recipe") },
            leadingIcon = { Icon(Icons.Default.Add, contentDescription = "Get recipe suggestion") },
        )
        AssistChip(
            onClick = { onAction("What should I eat for my next meal based on my nutrition today?") },
            label = { Text("What to Eat") },
            leadingIcon = { Icon(Icons.Default.Add, contentDescription = "Get meal suggestion") },
        )
        AssistChip(
            onClick = { onAction("Analyze my last 30 days of health data. How am I doing?") },
            label = { Text("Health Check") },
            leadingIcon = { Icon(Icons.Default.Add, contentDescription = "Run health check") },
        )
        AssistChip(
            onClick = { onAction("Give me some general motivation.") },
            label = { Text("Motivation") },
            leadingIcon = { Icon(Icons.Default.Star, contentDescription = "Get motivation") },
        )
    }
}
