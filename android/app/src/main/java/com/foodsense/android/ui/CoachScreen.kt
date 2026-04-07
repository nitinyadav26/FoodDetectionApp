package com.foodsense.android.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoGraph
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Quiz
import androidx.compose.material.icons.filled.Restaurant
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.services.AnalyticsService
import kotlinx.coroutines.launch

enum class CoachSubScreen {
    Main, Chat, MealPlan, Insights, Quiz, VoiceLog
}

@Composable
fun CoachScreen(app: FoodSenseApplication) {
    var subScreen by remember { mutableStateOf(CoachSubScreen.Main) }

    when (subScreen) {
        CoachSubScreen.Main -> CoachMainScreen(app, onNavigate = { subScreen = it })
        CoachSubScreen.Chat -> NutritionistChatScreen(app, onBack = { subScreen = CoachSubScreen.Main })
        CoachSubScreen.MealPlan -> MealPlanScreen(app, onBack = { subScreen = CoachSubScreen.Main })
        CoachSubScreen.Insights -> InsightsScreen(app, onBack = { subScreen = CoachSubScreen.Main })
        CoachSubScreen.Quiz -> QuizScreen(app, onBack = { subScreen = CoachSubScreen.Main })
        CoachSubScreen.VoiceLog -> VoiceLogScreen(app, onBack = { subScreen = CoachSubScreen.Main })
    }
}

@Composable
private fun CoachMainScreen(app: FoodSenseApplication, onNavigate: (CoachSubScreen) -> Unit) {
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

        Spacer(modifier = Modifier.height(8.dp))
        Text("AI Features", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            FeatureCard(
                icon = Icons.Default.Chat,
                label = "Chat",
                color = Color(0xFF60A5FA),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(CoachSubScreen.Chat) },
            )
            FeatureCard(
                icon = Icons.Default.Restaurant,
                label = "Meal Plans",
                color = Color(0xFF4ADE80),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(CoachSubScreen.MealPlan) },
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            FeatureCard(
                icon = Icons.Default.AutoGraph,
                label = "Insights",
                color = Color(0xFFFBBF24),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(CoachSubScreen.Insights) },
            )
            FeatureCard(
                icon = Icons.Default.Quiz,
                label = "Quiz",
                color = Color(0xFFF472B6),
                modifier = Modifier.weight(1f),
                onClick = { onNavigate(CoachSubScreen.Quiz) },
            )
        }

        FeatureCard(
            icon = Icons.Default.Mic,
            label = "Voice Log",
            color = Color(0xFFA78BFA),
            modifier = Modifier.fillMaxWidth(),
            onClick = { onNavigate(CoachSubScreen.VoiceLog) },
        )
    }
}

@Composable
private fun FeatureCard(
    icon: ImageVector,
    label: String,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    Card(
        modifier = modifier.clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(icon, contentDescription = label, tint = color, modifier = Modifier.size(32.dp))
            Text(label, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
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
