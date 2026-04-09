package com.foodsense.android

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

class FoodLoggingUITest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun dashboardTabIsSelectable() {
        composeTestRule.onNodeWithText("Dashboard").performClick()
        composeTestRule.onNodeWithText("Dashboard").assertIsDisplayed()
    }

    @Test
    fun scanTabIsSelectable() {
        composeTestRule.onNodeWithText("Scan").performClick()
    }

    @Test
    fun coachTabIsSelectable() {
        composeTestRule.onNodeWithText("AI Coach").performClick()
    }

    @Test
    fun profileTabIsSelectable() {
        composeTestRule.onNodeWithText("Profile").performClick()
    }

    @Test
    fun canNavigateAllTabs() {
        val tabs = listOf("Dashboard", "Scan", "AI Coach", "Pair Scale", "Profile")
        for (tab in tabs) {
            composeTestRule.onNodeWithText(tab).performClick()
        }
    }
}
