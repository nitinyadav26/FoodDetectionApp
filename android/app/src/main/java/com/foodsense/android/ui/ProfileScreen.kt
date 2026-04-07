package com.foodsense.android.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.UserStats

@Composable
fun ProfileScreen(app: FoodSenseApplication, onSettingsClick: () -> Unit = {}) {
    val manager = app.nutritionManager

    var isEditing by rememberSaveable { mutableStateOf(false) }
    var weight by rememberSaveable { mutableStateOf((manager.userStats?.weight ?: 70.0).toString()) }
    var height by rememberSaveable { mutableStateOf((manager.userStats?.height ?: 170.0).toString()) }
    var age by rememberSaveable { mutableStateOf((manager.userStats?.age ?: 25).toString()) }
    var gender by rememberSaveable { mutableStateOf(manager.userStats?.gender ?: "Male") }
    var activityLevel by rememberSaveable { mutableStateOf(manager.userStats?.activityLevel ?: "Moderate") }
    var goal by rememberSaveable { mutableStateOf(manager.userStats?.goal ?: "Maintain") }

    val genders = listOf("Male", "Female", "Other")
    val activityLevels = listOf("Sedentary", "Light", "Moderate", "Active")
    val goals = listOf("Lose", "Maintain", "Gain")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Your Profile", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.weight(1f))
            IconButton(onClick = onSettingsClick) {
                Icon(Icons.Default.Settings, contentDescription = "Settings")
            }
            TextButton(onClick = {
                if (isEditing) {
                    manager.saveUserStats(
                        UserStats(
                            weight = weight.toDoubleOrNull() ?: 70.0,
                            height = height.toDoubleOrNull() ?: 170.0,
                            age = age.toIntOrNull() ?: 25,
                            gender = gender,
                            activityLevel = activityLevel,
                            goal = goal,
                        ),
                    )
                }
                isEditing = !isEditing
            }) {
                Text(if (isEditing) "Save" else "Edit")
            }
        }

        OutlinedTextField(
            value = weight,
            onValueChange = { weight = it },
            enabled = isEditing,
            label = { Text("Weight (kg)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = height,
            onValueChange = { height = it },
            enabled = isEditing,
            label = { Text("Height (cm)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = age,
            onValueChange = { age = it },
            enabled = isEditing,
            label = { Text("Age") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.fillMaxWidth(),
        )

        Text("Gender", fontWeight = FontWeight.SemiBold)
        ChipSelector(options = genders, selected = gender, onSelect = { if (isEditing) gender = it })

        Text("Activity Level", fontWeight = FontWeight.SemiBold)
        ChipSelector(options = activityLevels, selected = activityLevel, onSelect = { if (isEditing) activityLevel = it })

        Text("Goal", fontWeight = FontWeight.SemiBold)
        ChipSelector(options = goals, selected = goal, onSelect = { if (isEditing) goal = it })

        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
            Row(modifier = Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("Daily Calorie Budget")
                Spacer(modifier = Modifier.weight(1f))
                Text("${manager.calorieBudget} kcal", color = Color(0xFF1DB954), fontWeight = FontWeight.Bold)
            }
        }
    }
}
