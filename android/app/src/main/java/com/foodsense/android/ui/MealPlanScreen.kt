package com.foodsense.android.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.MealPlanDay
import com.foodsense.android.data.MealPlanEntity
import com.foodsense.android.data.PlannedMeal
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

@Composable
fun MealPlanScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    val apiService = app.apiService
    val nutritionManager = app.nutritionManager
    val db = app.database
    val json = remember {
        Json {
            ignoreUnknownKeys = true
            isLenient = true
            explicitNulls = false
        }
    }

    var mealPlan by remember { mutableStateOf<List<MealPlanDay>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    // Load saved plan
    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) {
            val saved = db.mealPlanDao().getLatest()
            if (saved != null) {
                runCatching {
                    mealPlan = json.decodeFromString<List<MealPlanDay>>(saved.planJson)
                }
            }
        }
    }

    fun generatePlan() {
        isLoading = true
        errorMsg = null
        scope.launch {
            runCatching {
                apiService.generateMealPlan(
                    userStats = nutritionManager.userStats,
                    calorieBudget = nutritionManager.calorieBudget,
                )
            }.onSuccess { days ->
                mealPlan = days
                // Save to Room
                withContext(Dispatchers.IO) {
                    val planJson = json.encodeToString(kotlinx.serialization.builtins.ListSerializer(MealPlanDay.serializer()), days)
                    db.mealPlanDao().insert(
                        MealPlanEntity(
                            weekStart = java.time.LocalDate.now().toString(),
                            planJson = planJson,
                        )
                    )
                }
            }.onFailure {
                errorMsg = "Could not generate meal plan: ${it.message}"
            }
            isLoading = false
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back")
            }
            Text(
                "7-Day Meal Plan",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f),
            )
            IconButton(onClick = { generatePlan() }, enabled = !isLoading) {
                Icon(Icons.Default.Refresh, contentDescription = "Regenerate")
            }
        }

        if (mealPlan.isEmpty() && !isLoading) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text("No meal plan yet", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { generatePlan() }) {
                    Text("Generate My Meal Plan")
                }
            }
        }

        if (isLoading) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                CircularProgressIndicator(modifier = Modifier.size(32.dp))
                Spacer(modifier = Modifier.height(12.dp))
                Text("Generating personalized meal plan...")
            }
        }

        errorMsg?.let {
            Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(16.dp))
        }

        if (mealPlan.isNotEmpty() && !isLoading) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(mealPlan) { day ->
                    DayCard(day)
                }
                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
        }
    }
}

@Composable
private fun DayCard(day: MealPlanDay) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(day.day, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
            MealRow("Breakfast", day.breakfast)
            MealRow("Lunch", day.lunch)
            MealRow("Dinner", day.dinner)
            MealRow("Snack", day.snack)
        }
    }
}

@Composable
private fun MealRow(label: String, meal: PlannedMeal) {
    Column {
        Text("$label: ${meal.name}", fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
        Text(
            "${meal.calories} kcal | P:${meal.protein}g C:${meal.carbs}g F:${meal.fats}g",
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (meal.description.isNotBlank()) {
            Text(meal.description, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
