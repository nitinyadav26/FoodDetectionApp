package com.foodsense.android.ui

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.foodsense.android.FoodSenseApplication
import java.io.File

@Composable
fun SettingsScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    var showDeleteDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back")
            }
            Text("Settings", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Appearance
        SectionHeader("Appearance")
        val themePrefs = context.getSharedPreferences("foodsense", Context.MODE_PRIVATE)
        var currentTheme by remember { mutableStateOf(themePrefs.getString("appTheme", "system") ?: "system") }
        val themes = listOf("system" to "System Default", "light" to "Light", "dark" to "Dark")
        themes.forEach { (key, label) ->
            SettingsRow(
                title = label,
                textColor = if (currentTheme == key) MaterialTheme.colorScheme.primary else Color.Unspecified,
            ) {
                themePrefs.edit().putString("appTheme", key).apply()
                currentTheme = key
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Legal
        SectionHeader("Legal")
        SettingsRow("Privacy Policy") {
            uriHandler.openUri("https://foodsense-app.web.app/privacy-policy")
        }
        SettingsRow("Terms of Service") {
            uriHandler.openUri("https://foodsense-app.web.app/terms-of-service")
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Data
        SectionHeader("Data")
        SettingsRow("Export My Data") {
            exportData(context, app)
        }
        SettingsRow("Delete All Data", textColor = MaterialTheme.colorScheme.error) {
            showDeleteDialog = true
        }

        Spacer(modifier = Modifier.height(8.dp))

        // About
        SectionHeader("About")
        Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF161616))) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Version")
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "1.0",
                    color = Color.Gray,
                )
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete All Data?") },
            text = { Text("This will permanently delete all your food logs, stats, and preferences. This cannot be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    app.nutritionManager.deleteAllData()
                    showDeleteDialog = false
                }) {
                    Text("Delete Everything", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            },
        )
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        title,
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(vertical = 4.dp),
    )
    Divider()
}

@Composable
private fun SettingsRow(title: String, textColor: Color = Color.Unspecified, onClick: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Color(0xFF161616)),
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
    ) {
        Text(
            title,
            color = textColor,
            modifier = Modifier.padding(16.dp),
        )
    }
}

private fun exportData(context: Context, app: FoodSenseApplication) {
    val json = app.nutritionManager.exportAllData()
    val file = File(context.cacheDir, "foodsense_export.json")
    file.writeText(json)
    val uri = androidx.core.content.FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file,
    )
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "application/json"
        putExtra(Intent.EXTRA_STREAM, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(intent, "Export Data"))
}
