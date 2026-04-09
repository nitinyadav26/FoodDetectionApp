package com.foodsense.android.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.foodsense.android.services.AuthManager
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(authManager: AuthManager) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isCreateAccount by remember { mutableStateOf(false) }
    var isProcessing by remember { mutableStateOf(false) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Icon(
                imageVector = Icons.Default.Restaurant,
                contentDescription = "FoodSense",
                modifier = Modifier.size(80.dp),
                tint = MaterialTheme.colorScheme.primary,
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "FoodSense",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = if (isCreateAccount) "Create Account" else "Sign In",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Spacer(modifier = Modifier.height(32.dp))

            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    isProcessing = true
                    scope.launch {
                        try {
                            if (isCreateAccount) {
                                authManager.createAccount(email, password)
                            } else {
                                authManager.signInWithEmail(email, password)
                            }
                        } catch (e: Exception) {
                            snackbarHostState.showSnackbar(
                                e.localizedMessage ?: "Authentication failed"
                            )
                        }
                        isProcessing = false
                    }
                },
                enabled = !isProcessing && email.isNotBlank() && password.isNotBlank(),
                modifier = Modifier.fillMaxWidth(),
            ) {
                if (isProcessing) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp,
                    )
                } else {
                    Text(if (isCreateAccount) "Create Account" else "Sign In")
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            TextButton(onClick = { isCreateAccount = !isCreateAccount }) {
                Text(
                    if (isCreateAccount) "Already have an account? Sign In"
                    else "Don't have an account? Create one"
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Divider(modifier = Modifier.padding(horizontal = 24.dp))

            Spacer(modifier = Modifier.height(16.dp))

            OutlinedButton(
                onClick = {
                    isProcessing = true
                    scope.launch {
                        try {
                            authManager.signInAnonymously()
                        } catch (e: Exception) {
                            snackbarHostState.showSnackbar(
                                e.localizedMessage ?: "Anonymous sign-in failed"
                            )
                        }
                        isProcessing = false
                    }
                },
                enabled = !isProcessing,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Continue as Guest")
            }
        }
    }
}
