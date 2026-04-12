package com.foodsense.android.ui

import android.os.Build
import android.os.StatFs
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.services.ai.ModelDownloadManager.DownloadState
import kotlinx.coroutines.launch

@Composable
fun ModelDownloadScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val downloadManager = remember { app.aiProviderManager.modelDownloadManager }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    val downloadState by downloadManager.downloadState
    val progress by downloadManager.downloadProgress
    val isAvailable by downloadManager.isModelAvailable

    // Check OS version requirement (Android 12+)
    val meetsOsRequirement = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S

    // Compute available disk space
    val statFs = remember { StatFs(context.filesDir.absolutePath) }
    val availableBytes = remember { statFs.availableBytes }
    val availableGB = remember { String.format("%.1f", availableBytes / (1024.0 * 1024 * 1024)) }

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
                "On-Device AI Model",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
        }

        // Model info card
        Card(
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            ),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    "Gemma 4 E4B",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    "On-device AI model for food analysis and nutrition insights. " +
                        "Runs entirely on your device with no internet required.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Model size: ~3.7 GB",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    "Available storage: $availableGB GB",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (isAvailable) {
                    val sizeOnDisk = downloadManager.modelSizeOnDisk()
                    val sizeMB = String.format("%.1f", sizeOnDisk / (1024.0 * 1024))
                    Text(
                        "Downloaded: $sizeMB MB",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }

        // OS version warning
        if (!meetsOsRequirement) {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Warning,
                        contentDescription = "Warning",
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        "On-device AI requires Android 12 or later. " +
                            "Your device is running Android ${Build.VERSION.SDK_INT}.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        // State-dependent UI
        when (downloadState) {
            DownloadState.IDLE -> {
                Button(
                    onClick = {
                        scope.launch {
                            app.aiProviderManager.startModelDownload()
                        }
                    },
                    enabled = meetsOsRequirement,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Download Model")
                }
            }

            DownloadState.DOWNLOADING -> {
                Text(
                    "Downloading... ${(progress * 100).toInt()}%",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                LinearProgressIndicator(
                    progress = progress,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(4.dp))
                OutlinedButton(
                    onClick = { downloadManager.cancelDownload() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Cancel")
                }
            }

            DownloadState.VERIFYING -> {
                Text(
                    "Verifying download...",
                    style = MaterialTheme.typography.bodyMedium
                )
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            }

            DownloadState.COMPLETE -> {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "Ready",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "Model Ready",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                OutlinedButton(
                    onClick = {
                        app.aiProviderManager.deleteLocalModel()
                    },
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        Icons.Default.Delete,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Delete Model")
                }
            }

            DownloadState.FAILED -> {
                Text(
                    "Download failed. Check your connection and try again.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error
                )
                Button(
                    onClick = {
                        scope.launch {
                            app.aiProviderManager.startModelDownload()
                        }
                    },
                    enabled = meetsOsRequirement,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Retry Download")
                }
            }
        }
    }
}
