package com.foodsense.android.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.data.UserStats
import com.foodsense.android.services.AnalyticsService
import kotlinx.coroutines.launch

private const val PAGE_COUNT = 4

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun OnboardingScreen(onComplete: (UserStats) -> Unit) {
    val pagerState = rememberPagerState()
    val coroutineScope = rememberCoroutineScope()

    // Profile state -- kept across pages via rememberSaveable
    var weight by rememberSaveable { mutableStateOf("") }
    var height by rememberSaveable { mutableStateOf("") }
    var age by rememberSaveable { mutableStateOf("") }
    var gender by rememberSaveable { mutableStateOf("Male") }
    var activityLevel by rememberSaveable { mutableStateOf("Moderate") }
    var goal by rememberSaveable { mutableStateOf("Maintain") }

    val genders = listOf("Male", "Female")
    val activityLevels = listOf("Sedentary", "Light", "Moderate", "Active")
    val goals = listOf("Lose", "Maintain", "Gain")

    val accentColor = Color(0xFF1DB954)

    Column(modifier = Modifier.fillMaxSize()) {
        // ---- Pager ----
        HorizontalPager(
            pageCount = PAGE_COUNT,
            state = pagerState,
            userScrollEnabled = false,
            modifier = Modifier.weight(1f),
        ) { page ->
            when (page) {
                0 -> WelcomePage(
                    accentColor = accentColor,
                    onGetStarted = {
                        coroutineScope.launch { pagerState.animateScrollToPage(1) }
                    },
                )

                1 -> PermissionsPage(
                    accentColor = accentColor,
                    onContinue = {
                        coroutineScope.launch { pagerState.animateScrollToPage(2) }
                    },
                )

                2 -> ProfilePage(
                    weight = weight,
                    onWeightChange = { weight = it },
                    height = height,
                    onHeightChange = { height = it },
                    age = age,
                    onAgeChange = { age = it },
                    gender = gender,
                    genders = genders,
                    onGenderSelect = { gender = it },
                    activityLevel = activityLevel,
                    activityLevels = activityLevels,
                    onActivityLevelSelect = { activityLevel = it },
                    goal = goal,
                    goals = goals,
                    onGoalSelect = { goal = it },
                    accentColor = accentColor,
                    onContinue = {
                        // Validate before advancing
                        val w = weight.toDoubleOrNull() ?: return@ProfilePage
                        val h = height.toDoubleOrNull() ?: return@ProfilePage
                        val a = age.toIntOrNull() ?: return@ProfilePage
                        coroutineScope.launch { pagerState.animateScrollToPage(3) }
                    },
                )

                3 -> AllSetPage(
                    accentColor = accentColor,
                    onStartTracking = {
                        val w = weight.toDoubleOrNull() ?: return@AllSetPage
                        val h = height.toDoubleOrNull() ?: return@AllSetPage
                        val a = age.toIntOrNull() ?: return@AllSetPage
                        AnalyticsService.logOnboardingComplete()
                        onComplete(
                            UserStats(
                                weight = w,
                                height = h,
                                age = a,
                                gender = gender,
                                activityLevel = activityLevel,
                                goal = goal,
                            ),
                        )
                    },
                )
            }
        }

        // ---- Page indicator dots ----
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 24.dp),
            horizontalArrangement = Arrangement.Center,
        ) {
            repeat(PAGE_COUNT) { index ->
                val color = if (index == pagerState.currentPage) accentColor else Color.Gray.copy(alpha = 0.4f)
                Box(
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(color),
                )
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Page 0 -- Welcome
// ---------------------------------------------------------------------------

@Composable
private fun WelcomePage(accentColor: Color, onGetStarted: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "FoodSense",
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Your AI-powered nutrition companion",
            color = Color.Gray,
            textAlign = TextAlign.Center,
        )

        Spacer(modifier = Modifier.height(40.dp))

        FeatureRow(icon = Icons.Default.CameraAlt, text = "Scan food with your camera")
        Spacer(modifier = Modifier.height(16.dp))
        FeatureRow(icon = Icons.Default.BarChart, text = "Track daily nutrition")
        Spacer(modifier = Modifier.height(16.dp))
        FeatureRow(icon = Icons.Default.Psychology, text = "Get personalized AI coaching")

        Spacer(modifier = Modifier.height(48.dp))

        Button(
            onClick = onGetStarted,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = accentColor),
        ) {
            Text("Get Started")
        }
    }
}

@Composable
private fun FeatureRow(icon: ImageVector, text: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color(0xFF1DB954),
            modifier = Modifier.size(28.dp),
        )
        Spacer(modifier = Modifier.width(12.dp))
        Text(text, fontSize = 16.sp)
    }
}

// ---------------------------------------------------------------------------
// Page 1 -- Permissions
// ---------------------------------------------------------------------------

@Composable
private fun PermissionsPage(accentColor: Color, onContinue: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "Quick Setup",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
        )

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "FoodSense uses your camera to scan and identify food. " +
                "Bluetooth is used to connect to a smart kitchen scale for precise measurements.",
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 8.dp),
        )

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = "Permissions will be requested when you first use each feature.",
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 8.dp),
        )

        Spacer(modifier = Modifier.height(48.dp))

        Button(
            onClick = onContinue,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = accentColor),
        ) {
            Text("Continue")
        }
    }
}

// ---------------------------------------------------------------------------
// Page 2 -- Profile Entry
// ---------------------------------------------------------------------------

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProfilePage(
    weight: String,
    onWeightChange: (String) -> Unit,
    height: String,
    onHeightChange: (String) -> Unit,
    age: String,
    onAgeChange: (String) -> Unit,
    gender: String,
    genders: List<String>,
    onGenderSelect: (String) -> Unit,
    activityLevel: String,
    activityLevels: List<String>,
    onActivityLevelSelect: (String) -> Unit,
    goal: String,
    goals: List<String>,
    onGoalSelect: (String) -> Unit,
    accentColor: Color,
    onContinue: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            "Your Profile",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
        )
        Text(
            "Set your profile to calculate your daily nutrition plan.",
            color = Color.LightGray,
        )

        OutlinedTextField(
            value = weight,
            onValueChange = onWeightChange,
            label = { Text("Weight (kg)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = height,
            onValueChange = onHeightChange,
            label = { Text("Height (cm)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = age,
            onValueChange = onAgeChange,
            label = { Text("Age") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.fillMaxWidth(),
        )

        Text("Gender", fontWeight = FontWeight.SemiBold)
        ChipSelector(options = genders, selected = gender, onSelect = onGenderSelect)

        Text("Activity Level", fontWeight = FontWeight.SemiBold)
        ChipSelector(options = activityLevels, selected = activityLevel, onSelect = onActivityLevelSelect)

        Text("Goal", fontWeight = FontWeight.SemiBold)
        ChipSelector(options = goals, selected = goal, onSelect = onGoalSelect)

        Spacer(modifier = Modifier.height(12.dp))
        Button(
            onClick = onContinue,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = accentColor),
        ) {
            Text("Continue")
        }
    }
}

// ---------------------------------------------------------------------------
// Page 3 -- All Set
// ---------------------------------------------------------------------------

@Composable
private fun AllSetPage(accentColor: Color, onStartTracking: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = "All set",
            tint = accentColor,
            modifier = Modifier.size(96.dp),
        )

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "You're all set!",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
        )

        Spacer(modifier = Modifier.height(48.dp))

        Button(
            onClick = onStartTracking,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = accentColor),
        ) {
            Text("Start Tracking")
        }
    }
}
