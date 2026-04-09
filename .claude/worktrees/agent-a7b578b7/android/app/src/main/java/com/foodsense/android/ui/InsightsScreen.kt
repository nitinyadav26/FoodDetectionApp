package com.foodsense.android.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.WeeklyInsight
import kotlinx.coroutines.launch

@Composable
fun InsightsScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    val apiService = app.apiService
    val nutritionManager = app.nutritionManager
    val healthManager = app.healthDataManager

    var insight by remember { mutableStateOf<WeeklyInsight?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    fun loadInsights() {
        isLoading = true
        errorMsg = null
        scope.launch {
            runCatching {
                val healthData = "Steps: ${healthManager.stepCount}, Sleep: ${healthManager.sleepHours}, Water: ${healthManager.waterIntake}L"
                val history = nutritionManager.getHistory(days = 7)
                apiService.getWeeklyInsights(
                    userStats = nutritionManager.userStats,
                    history = history,
                    healthData = healthData,
                )
            }.onSuccess {
                insight = it
            }.onFailure {
                errorMsg = "Could not load insights: ${it.message}"
            }
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        loadInsights()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back")
            }
            Text(
                "Weekly Insights",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f),
            )
        }

        if (isLoading) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                CircularProgressIndicator(modifier = Modifier.size(32.dp))
                Spacer(modifier = Modifier.height(8.dp))
                Text("Analyzing your week...")
            }
        }

        errorMsg?.let {
            Text(it, color = MaterialTheme.colorScheme.error)
            TextButton(onClick = { loadInsights() }) { Text("Retry") }
        }

        insight?.let { data ->
            // Calorie trend line chart
            if (data.dailyCalories.isNotEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text("Calorie Trend", fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(8.dp))
                        CalorieLineChart(
                            dailyCalories = data.dailyCalories,
                            lineColor = MaterialTheme.colorScheme.primary,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(140.dp),
                        )
                    }
                }
            }

            // Macro breakdown pie chart
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text("Average Daily Macros", fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        MacroPieChart(
                            protein = data.averageProtein,
                            carbs = data.averageCarbs,
                            fats = data.averageFats,
                            modifier = Modifier.size(120.dp),
                        )
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("${data.averageCalories} kcal/day", fontWeight = FontWeight.Bold)
                            LegendItem("Protein", "${data.averageProtein}g", Color(0xFF60A5FA))
                            LegendItem("Carbs", "${data.averageCarbs}g", Color(0xFFFBBF24))
                            LegendItem("Fats", "${data.averageFats}g", Color(0xFFFF6B6B))
                        }
                    }
                }
            }

            // Top foods
            if (data.topFoods.isNotEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text("Top Foods This Week", fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(6.dp))
                        data.topFoods.forEachIndexed { index, food ->
                            Text("${index + 1}. $food", fontSize = 14.sp)
                        }
                    }
                }
            }

            // AI tips
            if (data.tips.isNotEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text("AI Tips", fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(6.dp))
                        data.tips.forEach { tip ->
                            Text("- $tip", fontSize = 14.sp, modifier = Modifier.padding(vertical = 2.dp))
                        }
                    }
                }
            }

            // Trend
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text("Weekly Trend", fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(data.trend, fontSize = 14.sp)
                }
            }
        }
    }
}

@Composable
private fun CalorieLineChart(
    dailyCalories: List<Int>,
    lineColor: Color,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        if (dailyCalories.isEmpty()) return@Canvas
        val maxCal = (dailyCalories.maxOrNull() ?: 1).coerceAtLeast(1).toFloat()
        val minCal = (dailyCalories.minOrNull() ?: 0).toFloat()
        val range = (maxCal - minCal).coerceAtLeast(1f)
        val stepX = size.width / (dailyCalories.size - 1).coerceAtLeast(1)
        val paddingY = 8f

        for (i in 0 until dailyCalories.size - 1) {
            val x1 = i * stepX
            val y1 = paddingY + (1f - (dailyCalories[i] - minCal) / range) * (size.height - 2 * paddingY)
            val x2 = (i + 1) * stepX
            val y2 = paddingY + (1f - (dailyCalories[i + 1] - minCal) / range) * (size.height - 2 * paddingY)

            drawLine(
                color = lineColor,
                start = Offset(x1, y1),
                end = Offset(x2, y2),
                strokeWidth = 4f,
                cap = StrokeCap.Round,
            )
        }

        // Draw dots
        dailyCalories.forEachIndexed { i, cal ->
            val x = i * stepX
            val y = paddingY + (1f - (cal - minCal) / range) * (size.height - 2 * paddingY)
            drawCircle(color = lineColor, radius = 6f, center = Offset(x, y))
        }
    }
}

@Composable
private fun MacroPieChart(
    protein: Int,
    carbs: Int,
    fats: Int,
    modifier: Modifier = Modifier,
) {
    val total = (protein + carbs + fats).coerceAtLeast(1).toFloat()
    val proteinAngle = (protein / total) * 360f
    val carbsAngle = (carbs / total) * 360f
    val fatsAngle = (fats / total) * 360f

    Canvas(modifier = modifier) {
        var startAngle = -90f
        drawArc(
            color = Color(0xFF60A5FA),
            startAngle = startAngle,
            sweepAngle = proteinAngle,
            useCenter = true,
        )
        startAngle += proteinAngle
        drawArc(
            color = Color(0xFFFBBF24),
            startAngle = startAngle,
            sweepAngle = carbsAngle,
            useCenter = true,
        )
        startAngle += carbsAngle
        drawArc(
            color = Color(0xFFFF6B6B),
            startAngle = startAngle,
            sweepAngle = fatsAngle,
            useCenter = true,
        )
    }
}

@Composable
private fun LegendItem(label: String, value: String, color: Color) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Canvas(modifier = Modifier.size(10.dp)) {
            drawCircle(color = color)
        }
        Text("$label: $value", fontSize = 12.sp)
    }
}
