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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.INDBFood
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.ServingSize
import com.foodsense.android.services.AnalyticsService
import kotlinx.coroutines.launch

@Composable
fun ManualLogScreen(app: FoodSenseApplication, onClose: () -> Unit) {
    val foodDb = app.foodDatabase
    val apiService = app.apiService
    val scope = rememberCoroutineScope()

    var searchText by rememberSaveable { mutableStateOf("") }
    var remoteResults by remember { mutableStateOf<List<INDBFood>>(emptyList()) }
    var isSearchingRemote by remember { mutableStateOf(false) }
    var selectedFood by remember { mutableStateOf<INDBFood?>(null) }

    val localResults = remember(searchText, foodDb.foods) { foodDb.search(searchText) }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background,
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Log Food", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.weight(1f))
                IconButton(onClick = onClose) { Icon(Icons.Default.Close, contentDescription = "Close") }
            }

            OutlinedTextField(
                value = searchText,
                onValueChange = { searchText = it },
                label = { Text("Search for food") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
            )

            Spacer(modifier = Modifier.height(8.dp))

            LazyColumn(modifier = Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (searchText.isBlank()) {
                    item {
                        Text(
                            "Type to search for Indian dishes...",
                            modifier = Modifier.padding(horizontal = 16.dp),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                } else if (localResults.isEmpty()) {
                    item {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                        ) {
                            Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                if (isSearchingRemote) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                                        Spacer(modifier = Modifier.width(10.dp))
                                        Text("Searching online...")
                                    }
                                } else if (remoteResults.isNotEmpty()) {
                                    remoteResults.forEach { food ->
                                        TextButton(onClick = { selectedFood = food }) {
                                            Column(horizontalAlignment = Alignment.Start) {
                                                Text(food.name, textAlign = TextAlign.Start, modifier = Modifier.fillMaxWidth())
                                                Text(
                                                    "Adjusted by AI \u2022 ${food.baseCaloriesPer100g.toInt()} kcal/100g",
                                                    color = Color(0xFF4FC3F7),
                                                    fontSize = 12.sp,
                                                    modifier = Modifier.fillMaxWidth(),
                                                )
                                            }
                                        }
                                    }
                                } else {
                                    Button(
                                        onClick = {
                                            AnalyticsService.logManualSearch(searchText)
                                            scope.launch {
                                                isSearchingRemote = true
                                                runCatching {
                                                    val (name, info) = apiService.searchFood(searchText)
                                                    remoteResults = listOf(
                                                        INDBFood(
                                                            id = "remote-$name-${System.currentTimeMillis()}",
                                                            name = name,
                                                            baseCaloriesPer100g = info.calories.toDoubleOrNull() ?: 0.0,
                                                            baseProteinPer100g = info.protein.toDoubleOrNull() ?: 0.0,
                                                            baseCarbsPer100g = info.carbs.toDoubleOrNull() ?: 0.0,
                                                            baseFatPer100g = info.fats.toDoubleOrNull() ?: 0.0,
                                                            servings = listOf(
                                                                ServingSize("Standard Serving", 100.0),
                                                                ServingSize("Small Portion", 50.0),
                                                                ServingSize("Large Portion", 200.0),
                                                            ),
                                                        ),
                                                    )
                                                }
                                                isSearchingRemote = false
                                            }
                                        },
                                    ) {
                                        Text("Search online for '$searchText'")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    items(localResults, key = { it.id }) { food ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp)
                                .clickable { selectedFood = food },
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text(food.name, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
                                Text("${food.baseCaloriesPer100g.toInt()} kcal / 100g", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                            }
                        }
                    }
                }

                item { Spacer(modifier = Modifier.height(80.dp)) }
            }
        }
    }

    if (selectedFood != null) {
        FoodDetailDialog(
            food = selectedFood!!,
            app = app,
            onDismiss = { selectedFood = null },
            onAdd = {
                selectedFood = null
                onClose()
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FoodDetailDialog(food: INDBFood, app: FoodSenseApplication, onDismiss: () -> Unit, onAdd: () -> Unit) {
    val nutritionManager = app.nutritionManager
    val bluetoothManager = app.bluetoothScaleManager

    var quantity by rememberSaveable { mutableStateOf("1.0") }
    var selectedServingIndex by rememberSaveable { mutableStateOf(0) }
    var useCustomWeight by rememberSaveable { mutableStateOf(false) }
    var customWeight by rememberSaveable { mutableStateOf("100") }
    var useScaleWeight by rememberSaveable { mutableStateOf(false) }

    val currentWeight = when {
        useScaleWeight && bluetoothManager.isConnected -> bluetoothManager.currentWeight
        useCustomWeight -> customWeight.toDoubleOrNull() ?: 100.0
        food.servings.isNotEmpty() -> (food.servings.getOrNull(selectedServingIndex)?.weight ?: 100.0) * (quantity.toDoubleOrNull() ?: 1.0)
        else -> 100.0
    }

    val ratio = currentWeight / 100.0
    val calories = food.baseCaloriesPer100g * ratio
    val protein = food.baseProteinPer100g * ratio
    val carbs = food.baseCarbsPer100g * ratio
    val fats = food.baseFatPer100g * ratio

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(food.name) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (bluetoothManager.isConnected) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Scale, contentDescription = "Smart scale", tint = Color(0xFF4FC3F7))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Use SmartScale")
                        Spacer(modifier = Modifier.weight(1f))
                        Switch(
                            checked = useScaleWeight,
                            onCheckedChange = {
                                useScaleWeight = it
                                if (it) useCustomWeight = false
                            },
                        )
                    }
                    if (useScaleWeight) {
                        Text("Reading: ${"%.1f".format(bluetoothManager.currentWeight)} g", color = Color(0xFF4FC3F7))
                    }
                }

                if (!useScaleWeight) {
                    Text("Serving", fontWeight = FontWeight.SemiBold)
                    ChipSelector(
                        options = food.servings.mapIndexed { idx, serving -> "$idx:${serving.label} (${serving.weight.toInt()}g)" },
                        selected = food.servings.mapIndexed { idx, serving -> "$idx:${serving.label} (${serving.weight.toInt()}g)" }.getOrElse(selectedServingIndex) { "0" },
                        onSelect = {
                            selectedServingIndex = it.substringBefore(':').toIntOrNull() ?: 0
                            useCustomWeight = false
                        },
                    )

                    OutlinedTextField(
                        value = quantity,
                        onValueChange = { quantity = it },
                        label = { Text("Quantity") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.fillMaxWidth(),
                    )

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Enter Exact Grams")
                        Spacer(modifier = Modifier.weight(1f))
                        Switch(checked = useCustomWeight, onCheckedChange = { useCustomWeight = it })
                    }

                    if (useCustomWeight) {
                        OutlinedTextField(
                            value = customWeight,
                            onValueChange = { customWeight = it },
                            label = { Text("Weight (g)") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                }

                Divider()
                Text("Calories: ${calories.toInt()} kcal")
                Text("Protein: ${"%.1f".format(protein)}g")
                Text("Carbs: ${"%.1f".format(carbs)}g")
                Text("Fats: ${"%.1f".format(fats)}g")
            }
        },
        confirmButton = {
            Button(onClick = {
                val info = NutritionInfo(
                    calories = food.baseCaloriesPer100g.toInt().toString(),
                    recipe = "Manual Entry from INDB Database",
                    carbs = "%.1f".format(food.baseCarbsPer100g),
                    protein = "%.1f".format(food.baseProteinPer100g),
                    fats = "%.1f".format(food.baseFatPer100g),
                    source = "INDB",
                    micros = null,
                )
                nutritionManager.logFood(dish = food.name, info = info, weight = currentWeight)
                AnalyticsService.logFoodLogged(food.name, calories.toInt())
                onAdd()
            }) { Text("Add to Log") }
        },
        dismissButton = { OutlinedButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
