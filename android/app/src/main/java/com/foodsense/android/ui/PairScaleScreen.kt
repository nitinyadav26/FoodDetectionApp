package com.foodsense.android.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.services.AnalyticsService

@Composable
fun PairScaleScreen(app: FoodSenseApplication) {
    val manager = app.bluetoothScaleManager

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { granted ->
        if (granted.values.all { it }) {
            manager.startScanning()
        }
    }

    LaunchedEffect(Unit) {
        if (manager.hasRequiredPermissions()) {
            manager.startScanning()
        }
    }

    LaunchedEffect(manager.isConnected) {
        if (manager.isConnected) {
            AnalyticsService.logScaleConnected()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Spacer(modifier = Modifier.height(20.dp))
        Icon(
            Icons.Default.Bluetooth,
            contentDescription = if (manager.isConnected) "Bluetooth connected" else "Bluetooth searching",
            tint = if (manager.isConnected) Color(0xFF4FC3F7) else Color.Gray,
            modifier = Modifier.size(110.dp),
        )

        Text(if (manager.isConnected) "Scale Connected" else "Searching for Scale...", style = MaterialTheme.typography.titleLarge)
        Text(manager.statusMessage, color = Color.Gray, textAlign = TextAlign.Center)

        if (manager.isConnected) {
            Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF161616))) {
                Column(modifier = Modifier.padding(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Current Weight", color = Color.Gray)
                    Text("${"%.0f".format(manager.currentWeight)} g", fontSize = 40.sp, fontWeight = FontWeight.Bold)
                }
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        if (!manager.hasRequiredPermissions()) {
            Button(onClick = { permissionLauncher.launch(manager.requiredPermissions()) }, modifier = Modifier.fillMaxWidth()) {
                Text("Grant Bluetooth Permission")
            }
        }

        if (!manager.isConnected) {
            Button(onClick = { manager.startScanning() }, modifier = Modifier.fillMaxWidth()) {
                Text("Scan Again")
            }
        }
    }
}
