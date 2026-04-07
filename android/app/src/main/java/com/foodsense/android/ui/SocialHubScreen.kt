package com.foodsense.android.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.R

@Composable
fun SocialHubScreen(app: FoodSenseApplication) {
    var selectedTab by rememberSaveable { mutableStateOf(0) }
    val tabTitles = listOf(
        stringResource(R.string.social_friends),
        stringResource(R.string.social_feed),
        stringResource(R.string.social_challenges),
        stringResource(R.string.social_leaderboard),
    )

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = stringResource(R.string.tab_social),
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(16.dp),
        )

        TabRow(selectedTabIndex = selectedTab) {
            tabTitles.forEachIndexed { index, title ->
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = { Text(title, maxLines = 1) },
                )
            }
        }

        when (selectedTab) {
            0 -> FriendsScreen(app.socialManager)
            1 -> FeedScreen(app.socialManager)
            2 -> ChallengesScreen(app.socialManager)
            3 -> LeaderboardScreen(app.socialManager)
        }
    }
}
