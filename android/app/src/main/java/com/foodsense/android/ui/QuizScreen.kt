package com.foodsense.android.ui

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.QuizQuestion
import kotlinx.coroutines.launch

@Composable
fun QuizScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    val apiService = app.apiService

    var question by remember { mutableStateOf<QuizQuestion?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var selectedIndex by remember { mutableStateOf(-1) }
    var showFeedback by remember { mutableStateOf(false) }
    var errorMsg by remember { mutableStateOf<String?>(null) }
    var score by remember { mutableStateOf(0) }
    var totalAnswered by remember { mutableStateOf(0) }

    fun loadQuestion() {
        isLoading = true
        errorMsg = null
        selectedIndex = -1
        showFeedback = false
        scope.launch {
            runCatching {
                apiService.getQuizQuestion()
            }.onSuccess {
                question = it
            }.onFailure {
                errorMsg = "Could not load question: ${it.message}"
            }
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        loadQuestion()
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
                "Nutrition Quiz",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f),
            )
            Text(
                "Score: $score/$totalAnswered",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary,
            )
        }

        if (isLoading) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                CircularProgressIndicator(modifier = Modifier.size(32.dp))
                Spacer(modifier = Modifier.height(8.dp))
                Text("Loading question...")
            }
        }

        errorMsg?.let {
            Text(it, color = MaterialTheme.colorScheme.error)
            Button(onClick = { loadQuestion() }) {
                Text("Try Again")
            }
        }

        question?.let { q ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(q.question, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                }
            }

            q.options.forEachIndexed { index, option ->
                val isCorrect = index == q.correctIndex
                val isSelected = index == selectedIndex
                val borderColor = when {
                    !showFeedback -> MaterialTheme.colorScheme.outline
                    isCorrect -> Color(0xFF4ADE80)
                    isSelected -> Color(0xFFFF6B6B)
                    else -> MaterialTheme.colorScheme.outline
                }
                val bgColor = when {
                    !showFeedback && isSelected -> MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                    showFeedback && isCorrect -> Color(0xFF4ADE80).copy(alpha = 0.15f)
                    showFeedback && isSelected && !isCorrect -> Color(0xFFFF6B6B).copy(alpha = 0.15f)
                    else -> Color.Transparent
                }

                OutlinedButton(
                    onClick = {
                        if (!showFeedback) {
                            selectedIndex = index
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    border = BorderStroke(2.dp, borderColor),
                    colors = ButtonDefaults.outlinedButtonColors(containerColor = bgColor),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            option,
                            modifier = Modifier.weight(1f),
                            color = MaterialTheme.colorScheme.onSurface,
                        )
                        if (showFeedback && isCorrect) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = "Correct",
                                tint = Color(0xFF4ADE80),
                                modifier = Modifier.size(20.dp),
                            )
                        } else if (showFeedback && isSelected && !isCorrect) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = "Wrong",
                                tint = Color(0xFFFF6B6B),
                                modifier = Modifier.size(20.dp),
                            )
                        }
                    }
                }
            }

            if (!showFeedback && selectedIndex >= 0) {
                Button(
                    onClick = {
                        showFeedback = true
                        totalAnswered++
                        if (selectedIndex == q.correctIndex) {
                            score++
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Submit Answer")
                }
            }

            if (showFeedback) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = if (selectedIndex == q.correctIndex) {
                            Color(0xFF4ADE80).copy(alpha = 0.1f)
                        } else {
                            Color(0xFFFF6B6B).copy(alpha = 0.1f)
                        }
                    ),
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text(
                            if (selectedIndex == q.correctIndex) "Correct!" else "Incorrect",
                            fontWeight = FontWeight.Bold,
                            color = if (selectedIndex == q.correctIndex) Color(0xFF16A34A) else Color(0xFFDC2626),
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(q.explanation, fontSize = 14.sp)
                    }
                }

                Button(
                    onClick = { loadQuestion() },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                    Text("  Next Question")
                }
            }
        }
    }
}
