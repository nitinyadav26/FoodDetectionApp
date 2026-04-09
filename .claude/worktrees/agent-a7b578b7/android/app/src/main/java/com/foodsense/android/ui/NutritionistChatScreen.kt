package com.foodsense.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.ChatMessage
import com.foodsense.android.data.ChatMessageEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun NutritionistChatScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    val apiService = app.apiService
    val nutritionManager = app.nutritionManager
    val healthManager = app.healthDataManager
    val db = app.database

    val sessionId = "default_session"
    var messages by remember { mutableStateOf<List<ChatMessage>>(emptyList()) }
    var inputText by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    // Load persisted messages on launch
    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) {
            val entities = db.chatMessageDao().getBySession(sessionId)
            messages = entities.map { ChatMessage(role = it.role, content = it.content, timestamp = it.timestamp) }
        }
        if (messages.isEmpty()) {
            val welcome = ChatMessage(
                role = "assistant",
                content = "Hello! I'm your AI nutritionist. Ask me anything about diet, nutrition, or healthy eating habits.",
            )
            messages = listOf(welcome)
            scope.launch(Dispatchers.IO) {
                db.chatMessageDao().insert(
                    ChatMessageEntity(sessionId = sessionId, role = welcome.role, content = welcome.content, timestamp = welcome.timestamp)
                )
            }
        }
    }

    // Auto-scroll to bottom when messages change
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
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
                "AI Nutritionist Chat",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f),
            )
            IconButton(onClick = {
                scope.launch(Dispatchers.IO) {
                    db.chatMessageDao().deleteBySession(sessionId)
                }
                messages = emptyList()
            }) {
                Icon(Icons.Default.DeleteSweep, contentDescription = "Clear chat")
            }
        }

        // Messages list
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(horizontal = 12.dp),
            state = listState,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(messages) { message ->
                ChatBubble(message)
            }
            if (isLoading) {
                item {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                        Text("Thinking...", fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }

        // Input row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedTextField(
                value = inputText,
                onValueChange = { inputText = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text("Ask about nutrition...") },
                singleLine = true,
            )
            IconButton(
                onClick = {
                    val text = inputText.trim()
                    if (text.isBlank() || isLoading) return@IconButton

                    val userMsg = ChatMessage(role = "user", content = text)
                    messages = messages + userMsg
                    inputText = ""
                    isLoading = true

                    scope.launch {
                        // Persist user message
                        withContext(Dispatchers.IO) {
                            db.chatMessageDao().insert(
                                ChatMessageEntity(sessionId = sessionId, role = userMsg.role, content = userMsg.content, timestamp = userMsg.timestamp)
                            )
                        }

                        val healthData = "Steps: ${healthManager.stepCount}, Sleep: ${healthManager.sleepHours}, Water: ${healthManager.waterIntake}L"
                        val historyString = nutritionManager.getHistory(days = 7)

                        val response = runCatching {
                            apiService.getCoachAdvice(
                                userStats = nutritionManager.userStats,
                                logs = nutritionManager.todayLogs,
                                healthData = healthData,
                                historyToon = historyString,
                                userQuery = text,
                            )
                        }.getOrElse { "Sorry, I couldn't process your request. (${it.message})" }

                        val assistantMsg = ChatMessage(role = "assistant", content = response)
                        messages = messages + assistantMsg

                        // Persist assistant message
                        withContext(Dispatchers.IO) {
                            db.chatMessageDao().insert(
                                ChatMessageEntity(sessionId = sessionId, role = assistantMsg.role, content = assistantMsg.content, timestamp = assistantMsg.timestamp)
                            )
                        }
                        isLoading = false
                    }
                },
                enabled = inputText.isNotBlank() && !isLoading,
            ) {
                Icon(Icons.Default.Send, contentDescription = "Send", tint = MaterialTheme.colorScheme.primary)
            }
        }
    }
}

@Composable
private fun ChatBubble(message: ChatMessage) {
    val isUser = message.role == "user"
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start,
    ) {
        Box(
            modifier = Modifier
                .widthIn(max = 300.dp)
                .clip(
                    RoundedCornerShape(
                        topStart = 16.dp,
                        topEnd = 16.dp,
                        bottomStart = if (isUser) 16.dp else 4.dp,
                        bottomEnd = if (isUser) 4.dp else 16.dp,
                    ),
                )
                .background(
                    if (isUser) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.surfaceVariant
                )
                .padding(12.dp),
        ) {
            Text(
                text = message.content,
                color = if (isUser) MaterialTheme.colorScheme.onPrimary
                else MaterialTheme.colorScheme.onSurface,
                fontSize = 14.sp,
            )
        }
    }
}
