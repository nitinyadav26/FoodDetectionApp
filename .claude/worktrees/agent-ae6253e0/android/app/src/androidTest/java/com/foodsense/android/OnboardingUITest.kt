package com.foodsense.android

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import org.junit.Rule
import org.junit.Test

class OnboardingUITest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun welcomeScreenIsDisplayed() {
        composeTestRule.onNodeWithText("FoodSense").assertIsDisplayed()
    }

    @Test
    fun canNavigateThroughOnboarding() {
        // Welcome page
        composeTestRule.onNodeWithText("Get Started").assertIsDisplayed()
        composeTestRule.onNodeWithText("Get Started").performClick()

        // Permissions page
        composeTestRule.onNodeWithText("Continue").assertIsDisplayed()
        composeTestRule.onNodeWithText("Continue").performClick()

        // Profile page — fill in fields
        composeTestRule.onNodeWithText("Weight (kg)").performTextInput("70")
        composeTestRule.onNodeWithText("Height (cm)").performTextInput("175")
        composeTestRule.onNodeWithText("Age").performTextInput("28")
        composeTestRule.onNodeWithText("Continue").performClick()

        // All Set page
        composeTestRule.onNodeWithText("Start Tracking").assertIsDisplayed()
    }
}
