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
import androidx.compose.material.icons.filled.People
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
import com.foodsense.android.ui.SocialHubScreen

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
    Social("Social"),
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

    // Dark theme: high contrast with bright text on dark backgrounds
    val darkColors = androidx.compose.material3.darkColorScheme(
        primary = Color(0xFF4ADE80),         // bright green
        onPrimary = Color(0xFF003314),
        secondary = Color(0xFF60A5FA),        // bright blue
        onSecondary = Color(0xFF002952),
        tertiary = Color(0xFFFBBF24),         // bright amber
        onTertiary = Color(0xFF3D2800),
        surface = Color(0xFF1C1C1E),          // iOS-style dark surface
        onSurface = Color(0xFFF5F5F5),        // bright white text
        surfaceVariant = Color(0xFF2C2C2E),
        onSurfaceVariant = Color(0xFFD1D1D6), // light gray text
        background = Color(0xFF000000),
        onBackground = Color(0xFFF5F5F5),
        outline = Color(0xFF636366),
        error = Color(0xFFFF6B6B),
    )
    // Light theme: dark text on light backgrounds
    val lightColors = androidx.compose.material3.lightColorScheme(
        primary = Color(0xFF16A34A),          // green
        onPrimary = Color(0xFFFFFFFF),
        secondary = Color(0xFF2563EB),        // blue
        onSecondary = Color(0xFFFFFFFF),
        tertiary = Color(0xFFD97706),         // amber
        onTertiary = Color(0xFFFFFFFF),
        surface = Color(0xFFF9FAFB),
        onSurface = Color(0xFF111827),        // near-black text
        surfaceVariant = Color(0xFFF3F4F6),
        onSurfaceVariant = Color(0xFF4B5563), // dark gray text
        background = Color(0xFFFFFFFF),
        onBackground = Color(0xFF111827),
        outline = Color(0xFFD1D5DB),
        error = Color(0xFFDC2626),
    )

    // Always use our custom colors for consistent contrast (Material You can produce bad contrast)
    val colorScheme = if (isDark) darkColors else lightColors

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
                                    AppTab.Social to Icons.Default.People,
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
                                AppTab.Social -> SocialHubScreen(app)
                                AppTab.Profile -> ProfileScreen(app, onSettingsClick = { showSettings = true })
                            }
                        }
                    }
                }
            }
        }
    }
}
