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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.ClickableText
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.foodsense.android.FoodSenseApplication
import kotlinx.coroutines.launch

@Composable
fun APIKeyEntryScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val apiKeyManager = remember { app.aiProviderManager.apiKeyManager }
    val scope = rememberCoroutineScope()
    val uriHandler = LocalUriHandler.current

    var apiKey by remember { mutableStateOf("") }
    var isValidating by remember { mutableStateOf(false) }
    var validationResult by remember { mutableStateOf<Boolean?>(null) }
    var existingKeyMasked by remember { mutableStateOf<String?>(null) }
    var showKey by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        val saved = apiKeyManager.getApiKey()
        if (saved != null) {
            val suffix = if (saved.length >= 4) saved.takeLast(4) else saved
            existingKeyMasked = "****$suffix"
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back")
            }
            Text(
                "Gemini API Key",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
        }

        Text(
            "Enter your Google AI Studio API key to use Gemini Cloud for food analysis and AI features.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        // Link to get an API key
        val linkText = AnnotatedString.Builder("Get a free API key at aistudio.google.com").apply {
            addStyle(
                SpanStyle(
                    color = MaterialTheme.colorScheme.primary,
                    textDecoration = TextDecoration.Underline
                ),
                0,
                length
            )
        }.toAnnotatedString()

        ClickableText(
            text = linkText,
            style = MaterialTheme.typography.bodyMedium,
            onClick = { uriHandler.openUri("https://aistudio.google.com/app/apikey") }
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Show existing key info
        if (existingKeyMasked != null) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = "Key saved",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    "Saved key: $existingKeyMasked",
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            OutlinedButton(
                onClick = {
                    app.aiProviderManager.clearApiKey()
                    existingKeyMasked = null
                    validationResult = null
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Clear Key")
            }

            Spacer(modifier = Modifier.height(8.dp))
        }

        // Key input
        OutlinedTextField(
            value = apiKey,
            onValueChange = {
                apiKey = it
                validationResult = null
            },
            label = { Text("API Key") },
            placeholder = { Text("AIza...") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            visualTransformation = if (showKey) VisualTransformation.None else PasswordVisualTransformation(),
            trailingIcon = {
                IconButton(onClick = { showKey = !showKey }) {
                    Icon(
                        if (showKey) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = if (showKey) "Hide key" else "Show key"
                    )
                }
            }
        )

        // Validate & Save button
        Button(
            onClick = {
                scope.launch {
                    isValidating = true
                    validationResult = null
                    val valid = apiKeyManager.validateApiKey(apiKey)
                    if (valid) {
                        app.aiProviderManager.setApiKey(apiKey)
                        val suffix = if (apiKey.length >= 4) apiKey.takeLast(4) else apiKey
                        existingKeyMasked = "****$suffix"
                    }
                    validationResult = valid
                    isValidating = false
                }
            },
            enabled = apiKey.isNotBlank() && !isValidating,
            modifier = Modifier.fillMaxWidth()
        ) {
            if (isValidating) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Validating...")
            } else {
                Text("Validate & Save")
            }
        }

        // Result indicator
        validationResult?.let { valid ->
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (valid) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "Valid",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "Key is valid and saved.",
                        color = MaterialTheme.colorScheme.primary
                    )
                } else {
                    Icon(
                        Icons.Default.Error,
                        contentDescription = "Invalid",
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "Invalid key. Check the format and try again.",
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
}
