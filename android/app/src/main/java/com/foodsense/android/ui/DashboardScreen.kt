package com.foodsense.android.ui

import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.AllBadges
import com.foodsense.android.data.FoodLog
import com.foodsense.android.services.AnalyticsService
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun DashboardScreen(app: FoodSenseApplication, onViewBadges: () -> Unit = {}) {
    val nutritionManager = app.nutritionManager
    val healthManager = app.healthDataManager
    val streakManager = app.streakManager
    val xpManager = app.xpManager
    val badgeManager = app.badgeManager
    var selectedDate by rememberSaveable { mutableStateOf(LocalDate.now()) }
    var showManualLog by rememberSaveable { mutableStateOf(false) }
    var selectedLog by remember { mutableStateOf<FoodLog?>(null) }

    val summary = nutritionManager.summaryFor(selectedDate)
    val healthData = healthManager.getData(selectedDate)
    val logs = nutritionManager.logsFor(selectedDate)

    // Evaluate badges when dashboard loads
    remember {
        badgeManager.evaluate()
        true
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("FoodSense", fontSize = 28.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.weight(1f))
            IconButton(onClick = { showManualLog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add", tint = MaterialTheme.colorScheme.secondary)
            }
        }

        DateSlider(selectedDate = selectedDate, onSelectDate = { selectedDate = it })

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text(
                            if (selectedDate == LocalDate.now()) "Nutrition Today" else "Nutrition for ${selectedDate.format(DateTimeFormatter.ofPattern("MMM d"))}",
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface,
                        )
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
                            StatRing("Cals", summary.cals, nutritionManager.calorieBudget, Color(0xFF1DB954))
                            StatRing("Prot", summary.protein, 150, Color(0xFF4FC3F7))
                            StatRing("Carb", summary.carbs, 250, Color(0xFFFF9800))
                            StatRing("Fat", summary.fats, 70, Color(0xFFF44336))
                        }
                    }
                }
            }

            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text(
                            if (selectedDate == LocalDate.now()) "Activity & Health (Today)" else "Activity & Health (${selectedDate.format(DateTimeFormatter.ofPattern("MMM d"))})",
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface,
                        )

                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            HealthCard("Steps", "${healthData.steps}", Color(0xFFFF9800), Modifier.weight(1f))
                            HealthCard("Sleep", "${"%.1f".format(healthData.sleep)}h", Color(0xFFB388FF), Modifier.weight(1f))
                            HealthCard("Burn", "${healthData.burn} kcal", Color(0xFFF44336), Modifier.weight(1f))
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("Water: ${"%.1f".format(healthData.water)} L", fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
                            Spacer(modifier = Modifier.weight(1f))
                            if (selectedDate == LocalDate.now()) {
                                AssistChip(onClick = {
                            healthManager.logWater(250.0)
                            AnalyticsService.logWaterLogged(250)
                        }, label = { Text("+ 250ml") })
                            }
                        }
                    }
                }
            }

            // XP & Level card
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                "Lv ${xpManager.level}",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = Color(0xFFFFD700),
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                xpManager.title,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurface,
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            Text(
                                "${xpManager.totalXP} XP",
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontSize = 13.sp,
                            )
                        }
                        LinearProgressIndicator(
                            progress = xpManager.progress,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(6.dp)
                                .clip(RoundedCornerShape(3.dp)),
                            color = Color(0xFFFFD700),
                            trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                        )
                    }
                }
            }

            // Streak card (updated without old badges)
            item {
                streakManager.updateStreak()
                StreakCard(
                    currentStreak = streakManager.currentStreak,
                    longestStreak = streakManager.longestStreak,
                    recentBadgeKeys = badgeManager.unlockedKeys,
                    onViewBadges = onViewBadges,
                )
            }

            item {
                Text(
                    "Log History",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                )
            }

            if (logs.isEmpty()) {
                item {
                    Text(
                        "No food logged for this day",
                        modifier = Modifier.padding(horizontal = 16.dp),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            } else {
                items(logs, key = { it.id }) { log ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp)
                            .clickable { selectedLog = log },
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Column {
                                Text(log.food, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
                                Text(
                                    Instant.ofEpochMilli(log.timeEpochMillis)
                                        .atZone(ZoneId.systemDefault())
                                        .toLocalTime()
                                        .format(DateTimeFormatter.ofPattern("hh:mm a")),
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    fontSize = 12.sp,
                                )
                            }
                            Spacer(modifier = Modifier.weight(1f))
                            Text("${log.calories} kcal", color = Color(0xFF1DB954), fontWeight = FontWeight.Bold)
                            IconButton(onClick = { nutritionManager.deleteLogById(log.id) }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete")
                            }
                        }
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }

    if (selectedLog != null) {
        LogDetailDialog(log = selectedLog!!, onDismiss = { selectedLog = null })
    }

    if (showManualLog) {
        ManualLogScreen(app = app, onClose = { showManualLog = false })
    }
}

@Composable
fun StreakCard(
    currentStreak: Int,
    longestStreak: Int,
    recentBadgeKeys: Set<String>,
    onViewBadges: () -> Unit = {},
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("\uD83D\uDD25", fontSize = 24.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Column {
                    Text(
                        "$currentStreak Day Streak",
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                    Text(
                        "Longest: $longestStreak days",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 12.sp,
                    )
                }
            }

            // Show up to 5 recently unlocked badges
            val recentBadges = AllBadges.list.filter { it.key in recentBadgeKeys }.take(5)
            if (recentBadges.isNotEmpty()) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    recentBadges.forEach { badge ->
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.Star,
                                contentDescription = badge.name,
                                tint = Color(0xFFFFD700),
                                modifier = Modifier.size(14.dp),
                            )
                            Spacer(modifier = Modifier.width(2.dp))
                            Text(badge.name, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }

            TextButton(onClick = onViewBadges) {
                Text("View All Badges (${recentBadgeKeys.size}/${AllBadges.list.size})")
            }
        }
    }
}

@Composable
fun LogDetailDialog(log: FoodLog, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = { TextButton(onClick = onDismiss) { Text("Close") } },
        title = { Text(log.food) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Calories: ${log.calories}")
                Text("Protein: ${log.protein}g")
                Text("Carbs: ${log.carbs}g")
                Text("Fats: ${log.fats}g")
                log.recipe?.let {
                    Divider(modifier = Modifier.padding(vertical = 6.dp))
                    Text("Healthier Advice")
                    Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (!log.micros.isNullOrEmpty()) {
                    Divider(modifier = Modifier.padding(vertical = 6.dp))
                    Text("Micronutrients")
                    log.micros.forEach { (k, v) -> Text("$k: $v", color = MaterialTheme.colorScheme.onSurfaceVariant) }
                }
            }
        },
    )
}
