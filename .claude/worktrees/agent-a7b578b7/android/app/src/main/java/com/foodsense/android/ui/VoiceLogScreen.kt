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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.NutritionInfo
import kotlinx.coroutines.launch

@Composable
fun VoiceLogScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val voiceManager = app.voiceLoggingManager
    val apiService = app.apiService
    val nutritionManager = app.nutritionManager
    val scope = rememberCoroutineScope()

    var detectedFood by remember { mutableStateOf<String?>(null) }
    var nutritionInfo by remember { mutableStateOf<NutritionInfo?>(null) }
    var isSearching by remember { mutableStateOf(false) }
    var logged by remember { mutableStateOf(false) }

    DisposableEffect(Unit) {
        onDispose {
            voiceManager.stopListening()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
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
                "Voice Food Log",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
            )
        }

        Text(
            "Tap the microphone and say what you ate",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )

        Spacer(modifier = Modifier.height(24.dp))

        FloatingActionButton(
            onClick = {
                if (voiceManager.isListening) {
                    voiceManager.stopListening()
                } else {
                    detectedFood = null
                    nutritionInfo = null
                    logged = false
                    voiceManager.startListening()
                }
            },
            modifier = Modifier.size(80.dp),
            containerColor = if (voiceManager.isListening) {
                MaterialTheme.colorScheme.error
            } else {
                MaterialTheme.colorScheme.primary
            },
        ) {
            Icon(
                if (voiceManager.isListening) Icons.Default.MicOff else Icons.Default.Mic,
                contentDescription = if (voiceManager.isListening) "Stop" else "Start listening",
                modifier = Modifier.size(36.dp),
            )
        }

        if (voiceManager.isListening) {
            Text("Listening...", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
        }

        voiceManager.error?.let { err ->
            Text(err, color = MaterialTheme.colorScheme.error)
        }

        if (voiceManager.transcript.isNotBlank()) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("You said:", fontWeight = FontWeight.SemiBold)
                    Text(voiceManager.transcript, style = MaterialTheme.typography.bodyLarge)
                }
            }

            if (detectedFood == null && !isSearching) {
                Button(
                    onClick = {
                        isSearching = true
                        scope.launch {
                            runCatching {
                                apiService.searchFood(voiceManager.transcript)
                            }.onSuccess { (dish, info) ->
                                detectedFood = dish
                                nutritionInfo = info
                            }.onFailure {
                                voiceManager.clearTranscript()
                            }
                            isSearching = false
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Search Food")
                }
            }
        }

        if (isSearching) {
            CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
            Text("Analyzing food...")
        }

        if (detectedFood != null && nutritionInfo != null) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(detectedFood!!, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                    ) {
                        MacroRing("Cal", nutritionInfo!!.calories, MaterialTheme.colorScheme.primary)
                        MacroRing("Protein", nutritionInfo!!.protein, MaterialTheme.colorScheme.secondary)
                        MacroRing("Carbs", nutritionInfo!!.carbs, MaterialTheme.colorScheme.tertiary)
                        MacroRing("Fats", nutritionInfo!!.fats, MaterialTheme.colorScheme.error)
                    }
                }
            }

            if (!logged) {
                Button(
                    onClick = {
                        nutritionManager.logFood(detectedFood!!, nutritionInfo!!)
                        logged = true
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Log It")
                }
            } else {
                Text(
                    "Logged successfully!",
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}
