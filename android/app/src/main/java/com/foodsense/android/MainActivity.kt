package com.foodsense.android

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.ui.CoachScreen
import com.foodsense.android.ui.DashboardScreen
import com.foodsense.android.ui.LoginScreen
import com.foodsense.android.ui.OnboardingScreen
import com.foodsense.android.ui.PairScaleScreen
import com.foodsense.android.ui.ProfileScreen
import com.foodsense.android.ui.ScanScreen
import com.foodsense.android.ui.SettingsScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val app = application as FoodSenseApplication
            FoodSenseApp(app)
        }
    }
}

enum class AppTab(val label: String) {
    Dashboard("Dashboard"),
    Scan("Scan"),
    Coach("AI Coach"),
    Pair("Pair Scale"),
    Profile("Profile"),
}

@Composable
private fun FoodSenseApp(app: FoodSenseApplication) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember { context.getSharedPreferences("foodsense", Context.MODE_PRIVATE) }
    var hasOnboarded by rememberSaveable { mutableStateOf(prefs.getBoolean("hasOnboarded", false)) }
    var selectedTab by rememberSaveable { mutableStateOf(AppTab.Dashboard) }
    var showSettings by rememberSaveable { mutableStateOf(false) }
    val isConnected by app.networkMonitor.isConnected.collectAsState()
    val isSignedIn by app.authManager.isSignedIn.collectAsState()
    val themePref = prefs.getString("appTheme", "system") ?: "system"
    val isDark = when (themePref) {
        "light" -> false
        "dark" -> true
        else -> isSystemInDarkTheme()
    }

    LaunchedEffect(Unit) {
        app.foodDatabase.loadData()
        app.healthDataManager.requestAuthorization()
    }

    val darkColors = androidx.compose.material3.darkColorScheme(
        primary = Color(0xFF1DB954),
        secondary = Color(0xFF4FC3F7),
        tertiary = Color(0xFFFF9800),
        surface = Color(0xFF111111),
        background = Color(0xFF000000),
    )
    val lightColors = androidx.compose.material3.lightColorScheme(
        primary = Color(0xFF1DB954),
        secondary = Color(0xFF0288D1),
        tertiary = Color(0xFFE65100),
        surface = Color(0xFFF5F5F5),
        background = Color(0xFFFFFFFF),
    )

    val colorScheme = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && themePref == "system" ->
            if (isDark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        isDark -> darkColors
        else -> lightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
    ) {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
            if (!hasOnboarded) {
                OnboardingScreen(
                    onComplete = { stats ->
                        app.nutritionManager.saveUserStats(stats)
                        prefs.edit().putBoolean("hasOnboarded", true).apply()
                        hasOnboarded = true
                    },
                )
            } else if (!isSignedIn) {
                LoginScreen(authManager = app.authManager)
            } else if (showSettings) {
                SettingsScreen(app, onBack = { showSettings = false })
            } else {
                Column {
                    if (!isConnected) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color(0xFFFF9800))
                                .padding(vertical = 6.dp),
                            horizontalArrangement = androidx.compose.foundation.layout.Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text("No Internet Connection", color = Color.White, fontSize = 12.sp, textAlign = TextAlign.Center)
                        }
                    }
                    Scaffold(
                        bottomBar = {
                            NavigationBar {
                                val items = listOf(
                                    AppTab.Dashboard to Icons.Default.BarChart,
                                    AppTab.Scan to Icons.Default.CameraAlt,
                                    AppTab.Coach to Icons.Default.Psychology,
                                    AppTab.Pair to Icons.Default.Bluetooth,
                                    AppTab.Profile to Icons.Default.Person,
                                )
                                items.forEach { (tab, icon) ->
                                    NavigationBarItem(
                                        selected = selectedTab == tab,
                                        onClick = { selectedTab = tab },
                                        icon = { Icon(icon, contentDescription = tab.label) },
                                        label = { Text(tab.label, maxLines = 1) },
                                    )
                                }
                            }
                        },
                    ) { padding ->
                        Box(modifier = Modifier.padding(padding)) {
                            when (selectedTab) {
                                AppTab.Dashboard -> DashboardScreen(app)
                                AppTab.Scan -> ScanScreen(app)
                                AppTab.Coach -> CoachScreen(app)
                                AppTab.Pair -> PairScaleScreen(app)
                                AppTab.Profile -> ProfileScreen(app, onSettingsClick = { showSettings = true })
                            }
                        }
                    }
                }
            }
        }
    }
}
